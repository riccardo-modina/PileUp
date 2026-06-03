<script setup>
import { ref, computed, watch, nextTick } from 'vue'

const props = defineProps({
  show: {
    type: Boolean,
    default: false
  },
  timeFrame: {
    type: String,
    default: 'Totale'
  }
})

const emit = defineEmits(['updateYear', 'updateMonthYear', 'updatePreset', 'close'])

const today = new Date()
const tempYear = ref(today.getFullYear())
const tempMonth = ref(today.getMonth()) // 0-indexed

const mode = ref('monthYear') // 'year' or 'monthYear'

const monthsNames = [
  'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
  'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
]

// Years list: current year down to 10 years ago
const yearsList = computed(() => {
  const currentYear = today.getFullYear()
  return Array.from({ length: 11 }, (_, i) => currentYear - i)
})

// Dynamic months list based on temporary year selection
const tempMonthsList = computed(() => {
  const todayY = today.getFullYear()
  const todayM = today.getMonth()
  if (tempYear.value === todayY) {
    return monthsNames
      .map((name, value) => ({ name, value }))
      .slice(0, todayM + 1)
  }
  return monthsNames.map((name, value) => ({ name, value }))
})

// Watch props.show to sync temp variables from props.timeFrame when modal opens
watch(() => props.show, (newVal) => {
  if (newVal) {
    const tf = props.timeFrame
    if (!tf || tf === 'Totale') {
      tempYear.value = today.getFullYear()
      tempMonth.value = today.getMonth()
      mode.value = 'monthYear'
    } else if (tf.includes('/')) {
      const [mStr, yStr] = tf.split('/')
      tempYear.value = parseInt(yStr) || today.getFullYear()
      tempMonth.value = (parseInt(mStr) - 1) || today.getMonth()
      mode.value = 'monthYear'
    } else {
      const y = parseInt(tf)
      if (!isNaN(y)) {
        tempYear.value = y
        mode.value = 'year'
      } else {
        tempYear.value = today.getFullYear()
        mode.value = 'year'
      }
    }

    nextTick(() => {
      if (mode.value === 'monthYear') {
        scrollToValue('month', tempMonth.value)
      }
      scrollToValue('year', tempYear.value)
    })
  }
})

const monthWheel = ref(null)
const yearWheel = ref(null)

// Scroll handler
function handleScroll(e, type) {
  const container = e.target
  const scrollTop = container.scrollTop
  const index = Math.round(scrollTop / 40)
  
  if (type === 'month') {
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

// Watch tempMonthsList to clamp tempMonth if needed
watch(tempMonthsList, (newList) => {
  const maxIdx = newList.length - 1
  if (tempMonth.value > maxIdx) {
    tempMonth.value = newList[maxIdx]?.value || 0
    scrollToValue('month', tempMonth.value)
  }
})

function scrollToValue(type, value) {
  nextTick(() => {
    if (type === 'month') {
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
  if (mode.value === 'year') {
    emit('updateYear', tempYear.value)
  } else {
    emit('updateMonthYear', {
      month: tempMonth.value + 1,
      year: tempYear.value
    })
  }
  emit('close')
}

function selectTotale() {
  emit('updatePreset', 'Totale')
  emit('close')
}

function changeMode(newMode) {
  if (mode.value !== newMode) {
    mode.value = newMode
    nextTick(() => {
      if (mode.value === 'monthYear') {
        scrollToValue('month', tempMonth.value)
      }
      scrollToValue('year', tempYear.value)
    })
  }
}
</script>

<template>
  <Teleport to="body">
    <transition name="fade">
      <div v-if="props.show" @click="emit('close')" class="fixed inset-0 z-[999] flex items-center justify-center p-4 bg-black/35 backdrop-blur-md md:items-start md:justify-end md:p-6 md:bg-transparent md:backdrop-blur-none">
        <!-- Modal Card (iOS style with blur and automatic dark/light theme support) -->
        <div @click.stop class="wheel-picker-modal w-[320px] rounded-[30px] p-5 shadow-2xl flex flex-col border backdrop-blur-md md:mt-20 md:mr-8 md:shadow-lg md:border-gray-200">
          
          <!-- Mode Switcher -->
          <div class="flex gap-2 p-1 bg-black/5 rounded-xl mb-4 border border-black/5">
            <button
              type="button"
              class="flex-1 py-1.5 rounded-lg text-xs font-semibold cursor-pointer transition-all"
              :class="mode === 'year' ? 'bg-primary text-white shadow-sm' : 'text-gray-500 hover:text-gray-700'"
              @click="changeMode('year')"
            >
              Anno
            </button>
            <button
              type="button"
              class="flex-1 py-1.5 rounded-lg text-xs font-semibold cursor-pointer transition-all"
              :class="mode === 'monthYear' ? 'bg-primary text-white shadow-sm' : 'text-gray-500 hover:text-gray-700'"
              @click="changeMode('monthYear')"
            >
              Mese / Anno
            </button>
          </div>

          <!-- Modal Title / Date Preview -->
          <div class="text-center pt-2 pb-2">
            <h4 class="title-label text-xs font-semibold uppercase tracking-wider">Seleziona Periodo</h4>
            <div class="date-preview text-lg font-bold mt-1 capitalize">
              <span v-if="mode === 'monthYear'">{{ monthsNames[tempMonth] }} </span>{{ tempYear }}
            </div>
          </div>

          <!-- Wheels (Grid of scroll-snapping columns) -->
          <div class="wheels-container flex justify-center items-center h-[200px] rounded-2xl relative overflow-hidden my-4 border px-2">
            <!-- Center Selection Overlay Highlight -->
            <div class="selection-highlight absolute left-0 right-0 top-[80px] h-10 border-t border-b pointer-events-none"></div>

            <!-- Mese Wheel (only in monthYear mode) -->
            <div 
              v-show="mode === 'monthYear'"
              ref="monthWheel" 
              class="w-28 h-full wheel-container transition-all duration-300"
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

            <!-- Divider (only in monthYear mode) -->
            <div v-show="mode === 'monthYear'" class="divider-slash font-bold text-lg select-none px-2">/</div>

            <!-- Anno Wheel -->
            <div 
              ref="yearWheel" 
              class="w-20 h-full wheel-container transition-all duration-300"
              :class="mode === 'year' ? 'w-full' : 'w-20'"
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
            <!-- Totale Button -->
            <button
              type="button"
              @click="selectTotale"
              class="btn-reset font-semibold py-2.5 px-6 rounded-2xl text-sm transition cursor-pointer"
            >
              Totale
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
