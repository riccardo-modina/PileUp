<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  modelValue: {
    type: [Date, String, null],
    default: null
  },
  maxDate: {
    type: Date,
    default: () => {
      const d = new Date()
      d.setHours(0,0,0,0)
      return d
    }
  },
  allowFuture: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['update:modelValue', 'focus'])

const today = new Date()
today.setHours(0,0,0,0)

// Device detection
const isMobile = ref(false)

// Custom dropdown open states (for PC layout)
const dayOpen = ref(false)
const monthOpen = ref(false)
const yearOpen = ref(false)

const dayRef = ref(null)
const monthRef = ref(null)
const yearRef = ref(null)

// 3-Field Date Selection state
const selectedDay = ref(today.getDate())
const selectedMonth = ref(today.getMonth()) // 0-indexed (0 = January)
const selectedYear = ref(today.getFullYear())

const monthsNames = [
  'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
  'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
]

// Years list: current year down to 10 years ago
const yearsList = computed(() => {
  const currentYear = today.getFullYear()
  return Array.from({ length: 11 }, (_, i) => currentYear - i)
})

// Dynamic months list to prevent future months in current year (if future not allowed)
const monthsList = computed(() => {
  const todayY = today.getFullYear()
  const todayM = today.getMonth()
  if (!props.allowFuture && selectedYear.value === todayY) {
    return monthsNames
      .map((name, value) => ({ name, value }))
      .slice(0, todayM + 1)
  }
  return monthsNames.map((name, value) => ({ name, value }))
})

// Dynamic days list to handle different month lengths and future clamping
const daysList = computed(() => {
  const y = selectedYear.value
  const m = selectedMonth.value
  if (y === null || m === null) return []
  
  const daysInMonth = new Date(y, m + 1, 0).getDate()
  
  const todayY = today.getFullYear()
  const todayM = today.getMonth()
  if (!props.allowFuture && y === todayY && m === todayM) {
    const maxDay = Math.min(daysInMonth, today.getDate())
    return Array.from({ length: maxDay }, (_, i) => i + 1)
  }
  return Array.from({ length: daysInMonth }, (_, i) => i + 1)
})

// Custom selectors toggle and select helpers
function toggleDay() {
  dayOpen.value = !dayOpen.value
  monthOpen.value = false
  yearOpen.value = false
}

function toggleMonth() {
  monthOpen.value = !monthOpen.value
  dayOpen.value = false
  yearOpen.value = false
}

function toggleYear() {
  yearOpen.value = !yearOpen.value
  dayOpen.value = false
  monthOpen.value = false
}

function selectDayVal(val) {
  selectedDay.value = val
  dayOpen.value = false
}

function selectMonthVal(val) {
  selectedMonth.value = val
  monthOpen.value = false
}

function selectYearVal(val) {
  selectedYear.value = val
  yearOpen.value = false
}

function handleClickOutside(e) {
  if (dayRef.value && !dayRef.value.contains(e.target)) dayOpen.value = false
  if (monthRef.value && !monthRef.value.contains(e.target)) monthOpen.value = false
  if (yearRef.value && !yearRef.value.contains(e.target)) yearOpen.value = false
}

// Watch selectedYear and selectedMonth to clamp values if they become invalid
watch([selectedYear, selectedMonth], ([newYear, newMonth]) => {
  const todayY = today.getFullYear()
  const todayM = today.getMonth()

  // 1. Clamp month if year is current year and selected month is in the future
  if (!props.allowFuture && newYear === todayY && newMonth > todayM) {
    selectedMonth.value = todayM
    return
  }

  // 2. Clamp day if selectedDay exceeds days available in the month/year
  const daysInMonth = new Date(newYear, newMonth + 1, 0).getDate()
  let maxDay = daysInMonth
  if (!props.allowFuture && newYear === todayY && newMonth === todayM) {
    maxDay = Math.min(daysInMonth, today.getDate())
  }

  if (selectedDay.value > maxDay) {
    selectedDay.value = maxDay
  }
})

// Sync internal state to parent modelValue
watch([selectedDay, selectedMonth, selectedYear], ([d, m, y]) => {
  if (d === null || m === null || y === null) return
  
  const parentVal = props.modelValue ? new Date(props.modelValue) : null
  if (parentVal && !isNaN(parentVal.getTime())) {
    if (parentVal.getFullYear() !== y || parentVal.getMonth() !== m || parentVal.getDate() !== d) {
      emit('update:modelValue', new Date(y, m, d))
    }
  } else {
    emit('update:modelValue', new Date(y, m, d))
  }
})

// Sync parent modelValue to internal state
watch(() => props.modelValue, (newVal) => {
  if (!newVal) return
  const d = new Date(newVal)
  if (isNaN(d.getTime())) return
  
  // Clamp if future date is not allowed
  if (!props.allowFuture && d > props.maxDate) {
    emit('update:modelValue', new Date(props.maxDate))
    return
  }
  
  const y = d.getFullYear()
  const m = d.getMonth()
  const day = d.getDate()
  
  if (selectedYear.value !== y) selectedYear.value = y
  if (selectedMonth.value !== m) selectedMonth.value = m
  if (selectedDay.value !== day) selectedDay.value = day
}, { immediate: true })

onMounted(() => {
  isMobile.value = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>

<template>
  <div class="flex gap-2 mt-1 w-full relative" @focusin="emit('focus')">
    
    <!-- MOBILE VIEW: Native selects for system wheel scroller -->
    <template v-if="isMobile">
      <!-- Giorno -->
      <div class="flex-1 min-w-[70px]">
        <select
          v-model="selectedDay"
          class="w-full px-3 py-2.5 border border-gray-200 rounded-xl bg-gray-50/50 hover:bg-gray-50 focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary-light text-sm font-medium text-text cursor-pointer"
        >
          <option v-for="d in daysList" :key="d" :value="d">{{ d }}</option>
        </select>
      </div>

      <!-- Mese -->
      <div class="flex-[2] min-w-[120px]">
        <select
          v-model="selectedMonth"
          class="w-full px-3 py-2.5 border border-gray-200 rounded-xl bg-gray-50/50 hover:bg-gray-50 focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary-light text-sm font-medium text-text cursor-pointer"
        >
          <option v-for="m in monthsList" :key="m.value" :value="m.value">{{ m.name }}</option>
        </select>
      </div>

      <!-- Anno -->
      <div class="flex-1 min-w-[85px]">
        <select
          v-model="selectedYear"
          class="w-full px-3 py-2.5 border border-gray-200 rounded-xl bg-gray-50/50 hover:bg-gray-50 focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary-light text-sm font-medium text-text cursor-pointer"
        >
          <option v-for="y in yearsList" :key="y" :value="y">{{ y }}</option>
        </select>
      </div>
    </template>

    <!-- DESKTOP VIEW: Custom compact styled dropdown popovers -->
    <template v-else>
      <!-- Giorno -->
      <div class="flex-1 min-w-[75px] relative" ref="dayRef">
        <button
          type="button"
          @click="toggleDay"
          class="w-full px-3 py-2.5 border border-gray-200 rounded-xl bg-gray-50/50 hover:bg-gray-50 focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary-light text-sm font-medium text-text text-left flex items-center justify-between cursor-pointer"
        >
          <span>{{ selectedDay }}</span>
          <i class="pi pi-chevron-down text-[10px] text-gray-400" />
        </button>
        <transition name="fade">
          <div v-if="dayOpen" class="absolute z-50 w-full mt-1 bg-white border border-gray-200 rounded-xl shadow-lg overflow-hidden">
            <ul class="py-1" style="max-height: 120px; overflow-y: auto;">
              <li
                v-for="d in daysList"
                :key="d"
                @click="selectDayVal(d)"
                :class="[
                  'px-3 py-1.5 text-sm cursor-pointer hover:bg-primary/10 transition-colors text-text',
                  selectedDay === d ? 'bg-primary/5 text-primary font-bold' : ''
                ]"
              >
                {{ d }}
              </li>
            </ul>
          </div>
        </transition>
      </div>

      <!-- Mese -->
      <div class="flex-[2] min-w-[130px] relative" ref="monthRef">
        <button
          type="button"
          @click="toggleMonth"
          class="w-full px-3 py-2.5 border border-gray-200 rounded-xl bg-gray-50/50 hover:bg-gray-50 focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary-light text-sm font-medium text-text text-left flex items-center justify-between cursor-pointer"
        >
          <span>{{ monthsNames[selectedMonth] }}</span>
          <i class="pi pi-chevron-down text-[10px] text-gray-400" />
        </button>
        <transition name="fade">
          <div v-if="monthOpen" class="absolute z-50 w-full mt-1 bg-white border border-gray-200 rounded-xl shadow-lg overflow-hidden">
            <ul class="py-1" style="max-height: 120px; overflow-y: auto;">
              <li
                v-for="m in monthsList"
                :key="m.value"
                @click="selectMonthVal(m.value)"
                :class="[
                  'px-3 py-1.5 text-sm cursor-pointer hover:bg-primary/10 transition-colors text-text',
                  selectedMonth === m.value ? 'bg-primary/5 text-primary font-bold' : ''
                ]"
              >
                {{ m.name }}
              </li>
            </ul>
          </div>
        </transition>
      </div>

      <!-- Anno -->
      <div class="flex-1 min-w-[90px] relative" ref="yearRef">
        <button
          type="button"
          @click="toggleYear"
          class="w-full px-3 py-2.5 border border-gray-200 rounded-xl bg-gray-50/50 hover:bg-gray-50 focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary-light text-sm font-medium text-text text-left flex items-center justify-between cursor-pointer"
        >
          <span>{{ selectedYear }}</span>
          <i class="pi pi-chevron-down text-[10px] text-gray-400" />
        </button>
        <transition name="fade">
          <div v-if="yearOpen" class="absolute z-50 w-full mt-1 bg-white border border-gray-200 rounded-xl shadow-lg overflow-hidden">
            <ul class="py-1" style="max-height: 120px; overflow-y: auto;">
              <li
                v-for="y in yearsList"
                :key="y"
                @click="selectYearVal(y)"
                :class="[
                  'px-3 py-1.5 text-sm cursor-pointer hover:bg-primary/10 transition-colors text-text',
                  selectedYear === y ? 'bg-primary/5 text-primary font-bold' : ''
                ]"
              >
                {{ y }}
              </li>
            </ul>
          </div>
        </transition>
      </div>
    </template>
  </div>
</template>

<style scoped>
.fade-enter-active, .fade-leave-active { 
    transition: opacity .15s ease, transform .15s ease;
}
.fade-enter-from, .fade-leave-to {
    opacity: 0; transform: translateY(-4px); 
}
</style>
