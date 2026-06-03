<script setup>
import { ref, computed, watch, nextTick } from 'vue'

const props = defineProps({
  show: {
    type: Boolean,
    default: false
  },
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

const emit = defineEmits(['update:modelValue', 'close'])

const today = new Date()
today.setHours(0,0,0,0)

const dayWheel = ref(null)
const monthWheel = ref(null)
const yearWheel = ref(null)

const tempDay = ref(today.getDate())
const tempMonth = ref(today.getMonth()) // 0-indexed
const tempYear = ref(today.getFullYear())

const monthsNames = [
  'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
  'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
]

// Years list: current year down to 10 years ago
const yearsList = computed(() => {
  const currentYear = today.getFullYear()
  return Array.from({ length: 11 }, (_, i) => currentYear - i)
})

// Mobile temporary dynamic lists (based on temporary selection in the wheel modal)
const tempDaysList = computed(() => {
  const y = tempYear.value
  const m = tempMonth.value
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

const tempMonthsList = computed(() => {
  const todayY = today.getFullYear()
  const todayM = today.getMonth()
  if (!props.allowFuture && tempYear.value === todayY) {
    return monthsNames
      .map((name, value) => ({ name, value }))
      .slice(0, todayM + 1)
  }
  return monthsNames.map((name, value) => ({ name, value }))
})

// Watch props.show to sync temp variables from props.modelValue when modal opens
watch(() => props.show, (newVal) => {
  if (newVal) {
    const d = props.modelValue ? new Date(props.modelValue) : new Date()
    tempDay.value = d.getDate()
    tempMonth.value = d.getMonth()
    tempYear.value = d.getFullYear()
    
    nextTick(() => {
      scrollToValue('day', tempDay.value)
      scrollToValue('month', tempMonth.value)
      scrollToValue('year', tempYear.value)
    })
  }
})

// Scroll handler
function handleScroll(e, type) {
  const container = e.target
  const scrollTop = container.scrollTop
  const index = Math.round(scrollTop / 40)
  
  if (type === 'day') {
    const val = tempDaysList.value[index]
    if (val && tempDay.value !== val) {
      tempDay.value = val
    }
  } else if (type === 'month') {
    const val = tempMonthsList.value[index]?.value
    if (val !== undefined && tempMonth.value !== val) {
      tempMonth.value = val
    }
  } else if (type === 'year') {
    const val = yearsList.value[index]
    if (val && tempYear.value !== val) {
      tempYear.value = val
    }
  }
}

// Watch tempDaysList to clamp tempDay if needed
watch(tempDaysList, (newList) => {
  if (tempDay.value > newList.length) {
    tempDay.value = newList.length
    scrollToValue('day', tempDay.value)
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

function confirmSelection() {
  const newDate = new Date(tempYear.value, tempMonth.value, tempDay.value)
  emit('update:modelValue', newDate)
  emit('close')
}

function resetToToday() {
  const d = new Date()
  tempDay.value = d.getDate()
  tempMonth.value = d.getMonth()
  tempYear.value = d.getFullYear()
  
  scrollToValue('day', tempDay.value)
  scrollToValue('month', tempMonth.value)
  scrollToValue('year', tempYear.value)
}
</script>

<template>
  <Teleport to="body">
    <transition name="fade">
      <div v-if="props.show" class="fixed inset-0 z-[999] flex items-center justify-center p-4 bg-black/35 backdrop-blur-md">
        <!-- Modal Card (iOS style with blur and automatic dark/light theme support) -->
        <div class="wheel-picker-modal w-[320px] rounded-[30px] p-5 shadow-2xl flex flex-col border backdrop-blur-md">
          
          <!-- Modal Title / Date Preview -->
          <div class="text-center pt-2 pb-2">
            <h4 class="title-label text-xs font-semibold uppercase tracking-wider">Seleziona Data</h4>
            <div class="date-preview text-lg font-bold mt-1 capitalize">
              {{ tempDay }} {{ monthsNames[tempMonth] }} {{ tempYear }}
            </div>
          </div>

          <!-- Wheels (Grid of scroll-snapping columns) -->
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
                :class="d === tempDay ? 'active' : 'inactive'"
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
                :class="m.value === tempMonth ? 'active' : 'inactive'"
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
                :class="y === tempYear ? 'active' : 'inactive'"
              >
                {{ y }}
              </div>
              <div class="h-[80px] pointer-events-none"></div>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="flex items-center justify-between mt-4 px-2 pb-2">
            <!-- Reset Button -->
            <button
              type="button"
              @click="resetToToday"
              class="btn-reset font-semibold py-2.5 px-6 rounded-2xl text-sm transition cursor-pointer"
            >
              Reset
            </button>

            <!-- Cancel Button -->
            <button
              type="button"
              @click="emit('close')"
              class="btn-cancel font-medium text-sm transition cursor-pointer px-3"
            >
              Annulla
            </button>

            <!-- Confirm Checkmark Button -->
            <button
              type="button"
              @click="confirmSelection"
              class="bg-primary text-white w-12 h-12 rounded-full flex items-center justify-center cursor-pointer hover:bg-primary-dark transition shadow-md"
            >
              <i class="pi pi-check text-xl font-bold" />
            </button>
          </div>

        </div>
      </div>
    </transition>
  </Teleport>
</template>

<style scoped>
.fade-enter-active, .fade-leave-active { 
    transition: opacity .15s ease, transform .15s ease;
}
.fade-enter-from, .fade-leave-to {
    opacity: 0; transform: translateY(-4px); 
}

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

/* Glassmorphism theme styling for Mobile & Desktop Wheel picker */
.wheel-picker-modal {
  --wheel-modal-bg: rgba(255, 255, 255, 0.85);
  --wheel-modal-border: rgba(0, 0, 0, 0.08);
  --wheel-modal-text: #1c1c1e;
  --wheel-modal-text-muted: #8e8e93;
  --wheel-container-bg: rgba(0, 0, 0, 0.03);
  --wheel-highlight-border: rgba(0, 0, 0, 0.1);
  --wheel-highlight-bg: rgba(0, 0, 0, 0.03);
  --wheel-reset-bg: #e5e5ea;
  --wheel-reset-text: #1c1c1e;
  --wheel-reset-hover: #d1d1d6;
  --title-color: #8e8e93;
  --divider-color: #d1d1d6;
  
  background: var(--wheel-modal-bg);
  border-color: var(--wheel-modal-border);
  color: var(--wheel-modal-text);
}

.title-label {
  color: var(--title-color);
}

.date-preview {
  color: var(--wheel-modal-text);
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

.btn-reset {
  background: var(--wheel-reset-bg);
  color: var(--wheel-reset-text);
}
.btn-reset:hover {
  background: var(--wheel-reset-hover);
}

.btn-cancel {
  color: var(--wheel-modal-text-muted);
}
.btn-cancel:hover {
  color: var(--wheel-modal-text);
}
</style>
