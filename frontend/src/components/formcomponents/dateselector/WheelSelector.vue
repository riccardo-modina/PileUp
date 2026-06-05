<script setup>
import { ref, computed, watch, nextTick } from 'vue'

const props = defineProps({
  day: Number,
  month: Number, // 0-indexed
  year: Number,
  allowFuture: Boolean,
  lastProgrammaticScrollTime: Number,
  pickerMode: String
})

const emit = defineEmits(['update:day', 'update:month', 'update:year'])

const today = new Date()
today.setHours(0,0,0,0)

const dayWheel = ref(null)
const monthWheel = ref(null)
const yearWheel = ref(null)

const monthsNames = [
  'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
  'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
]

// Years list: current year down to 10 years ago
const yearsList = computed(() => {
  const currentYear = today.getFullYear()
  return Array.from({ length: 11 }, (_, i) => currentYear - i)
})

// Days list based on current selection
const tempDaysList = computed(() => {
  const y = props.year
  const m = props.month
  const daysInMonth = new Date(y, m + 1, 0).getDate()
  const todayY = today.getFullYear()
  const todayM = today.getMonth()
  if (!props.allowFuture && y === todayY && m === todayM) {
    const maxDay = Math.min(daysInMonth, today.getDate())
    return Array.from({ length: maxDay }, (_, i) => i + 1)
  }
  return Array.from({ length: daysInMonth }, (_, i) => i + 1)
})

// Months list based on current selection
const tempMonthsList = computed(() => {
  const todayY = today.getFullYear()
  const todayM = today.getMonth()
  if (!props.allowFuture && props.year === todayY) {
    return monthsNames
      .map((name, value) => ({ name, value }))
      .slice(0, todayM + 1)
  }
  return monthsNames.map((name, value) => ({ name, value }))
})

// Scroll handler
function handleScroll(e, type) {
  if (props.pickerMode === 'calendar' || Date.now() - props.lastProgrammaticScrollTime < 300) return
  const container = e.target
  const scrollTop = container.scrollTop
  const index = Math.round(scrollTop / 40)
  
  if (type === 'day') {
    const val = tempDaysList.value[index]
    if (val && props.day !== val) {
      emit('update:day', val)
    }
  } else if (type === 'month') {
    const val = tempMonthsList.value[index]?.value
    if (val !== undefined && props.month !== val) {
      emit('update:month', val)
    }
  } else if (type === 'year') {
    const val = yearsList.value[index]
    if (val && props.year !== val) {
      emit('update:year', val)
    }
  }
}

// Watch tempDaysList to clamp day if needed
watch(tempDaysList, (newList) => {
  if (props.day > newList.length) {
    emit('update:day', newList.length)
    scrollToValue('day', newList.length)
  }
})

function scrollToValue(type, value) {
  nextTick(() => {
    if (type === 'day') {
      const idx = tempDaysList.value.indexOf(value)
      if (idx !== -1 && dayWheel.value) {
        dayWheel.value.scrollTop = idx * 40
      }
    } else if (type === 'month') {
      const idx = tempMonthsList.value.findIndex(m => m.value === value)
      if (idx !== -1 && monthWheel.value) {
        monthWheel.value.scrollTop = idx * 40
      }
    } else if (type === 'year') {
      const idx = yearsList.value.indexOf(value)
      if (idx !== -1 && yearWheel.value) {
        yearWheel.value.scrollTop = idx * 40
      }
    }
  })
}

defineExpose({
  scrollToValue
})
</script>

<template>
  <div class="wheels-container flex justify-center items-center h-[200px] rounded-2xl relative overflow-hidden my-4 border px-2">
    <!-- Center Selection Overlay Highlight -->
    <div class="selection-highlight absolute left-0 right-0 top-[80px] h-10 border-t border-b pointer-events-none"></div>

    <!-- Giorno Wheel -->
    <div 
      ref="dayWheel" 
      class="w-16 h-full wheel-container"
      @scroll="handleScroll($event, 'day')"
    >
      <div class="h-[80px] pointer-events-none"></div>
      <div 
        v-for="d in tempDaysList" 
        :key="d" 
        class="wheel-item flex items-center justify-center transition-all select-none p-0 m-0"
        :class="d === props.day ? 'active' : 'inactive'"
      >
        {{ d }}
      </div>
      <div class="h-[80px] pointer-events-none"></div>
    </div>

    <!-- Divider -->
    <div class="divider-slash font-bold text-lg select-none px-1">/</div>

    <!-- Mese Wheel -->
    <div 
      ref="monthWheel" 
      class="w-28 h-full wheel-container"
      @scroll="handleScroll($event, 'month')"
    >
      <div class="h-[80px] pointer-events-none"></div>
      <div 
        v-for="m in tempMonthsList" 
        :key="m.value" 
        class="wheel-item flex items-center justify-center transition-all truncate px-1 select-none p-0 m-0"
        :class="m.value === props.month ? 'active' : 'inactive'"
      >
        {{ m.name }}
      </div>
      <div class="h-[80px] pointer-events-none"></div>
    </div>

    <!-- Divider -->
    <div class="divider-slash font-bold text-lg select-none px-1">/</div>

    <!-- Anno Wheel -->
    <div 
      ref="yearWheel" 
      class="w-20 h-full wheel-container"
      @scroll="handleScroll($event, 'year')"
    >
      <div class="h-[80px] pointer-events-none"></div>
      <div 
        v-for="y in yearsList" 
        :key="y" 
        class="wheel-item flex items-center justify-center transition-all select-none p-0 m-0"
        :class="y === props.year ? 'active' : 'inactive'"
      >
        {{ y }}
      </div>
      <div class="h-[80px] pointer-events-none"></div>
    </div>
  </div>
</template>

<style scoped>
.wheel-container {
  height: 200px;
  scroll-snap-type: y mandatory;
  overflow-y: scroll;
  scrollbar-width: none; /* Firefox */
  -ms-overflow-style: none;  /* IE and Edge */
}
.wheel-container::-webkit-scrollbar {
  display: none; /* Chrome, Safari, Opera */
}
.wheel-item {
  height: 40px;
  scroll-snap-align: center;
}

.wheels-container {
  background: var(--wheel-container-bg);
  border-color: var(--wheel-modal-border);
}

.selection-highlight {
  border-color: var(--wheel-highlight-border);
  background: var(--wheel-highlight-bg);
}

.divider-slash {
  color: var(--divider-color);
}

.wheel-item.active {
  color: var(--wheel-modal-text);
  font-weight: 700;
  font-size: 1.125rem;
}

.wheel-item.inactive {
  color: var(--wheel-modal-text-muted);
  font-size: 0.875rem;
}
</style>
