<script setup>
import { ref, computed, watch, nextTick } from 'vue'
import WheelSelector from './WheelSelector.vue'
import CalendarSelector from './CalendarSelector.vue'

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

const showModal = ref(false)
const pickerMode = ref('wheel') // 'wheel' or 'calendar'
const lastProgrammaticScrollTime = ref(0)

const today = new Date()
today.setHours(0,0,0,0)

const tempDay = ref(today.getDate())
const tempMonth = ref(today.getMonth()) // 0-indexed
const tempYear = ref(today.getFullYear())

const wheelSelectorRef = ref(null)

const monthsNames = [
  'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
  'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
]

const tempDate = computed({
  get() {
    return new Date(tempYear.value, tempMonth.value, tempDay.value)
  },
  set(val) {
    if (val && !isNaN(val.getTime())) {
      tempDay.value = val.getDate()
      tempMonth.value = val.getMonth()
      tempYear.value = val.getFullYear()
      syncWheels()
    }
  }
})

function syncWheels() {
  lastProgrammaticScrollTime.value = Date.now()
  nextTick(() => {
    wheelSelectorRef.value?.scrollToValue('day', tempDay.value)
    wheelSelectorRef.value?.scrollToValue('month', tempMonth.value)
    wheelSelectorRef.value?.scrollToValue('year', tempYear.value)
  })
}

// Watch props.show/showModal to sync temp variables from props.modelValue when modal opens
watch(showModal, (newVal) => {
  if (newVal) {
    emit('focus')
    const d = props.modelValue ? new Date(props.modelValue) : new Date()
    tempDay.value = d.getDate()
    tempMonth.value = d.getMonth()
    tempYear.value = d.getFullYear()
    syncWheels()
  }
})

// Watch pickerMode to prevent layout-triggered scroll events from corrupting date when transitioning
watch(pickerMode, (newVal) => {
  if (newVal === 'wheel') {
    syncWheels()
  }
})

const formattedDateMobile = computed(() => {
  if (!props.modelValue) return 'Seleziona data'
  try {
    return new Date(props.modelValue).toLocaleDateString('it-IT', {
      day: 'numeric',
      month: 'long',
      year: 'numeric'
    })
  } catch (e) {
    return 'Seleziona data'
  }
})

function confirmSelection() {
  const newDate = new Date(tempYear.value, tempMonth.value, tempDay.value)
  emit('update:modelValue', newDate)
  showModal.value = false
}

function resetToToday() {
  const d = new Date()
  tempDay.value = d.getDate()
  tempMonth.value = d.getMonth()
  tempYear.value = d.getFullYear()
  syncWheels()
}
</script>

<template>
  <div class="flex mt-1 w-full relative" @focusin="emit('focus')">
    <div class="relative w-full">
      <!-- Unified button trigger for both Mobile and Desktop -->
      <button 
        type="button" 
        @click="showModal = true"
        class="w-full px-4 py-3 border border-gray-200 rounded-2xl bg-gray-50/50 focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary-light text-sm font-semibold text-text flex items-center justify-between shadow-sm cursor-pointer min-h-[46px]"
      >
        <span class="capitalize">{{ formattedDateMobile }}</span>
        <i class="pi pi-calendar text-primary text-base" />
      </button>

      <!-- Reusable Date Picker Modal -->
      <Teleport to="body">
        <transition name="fade">
          <div v-if="showModal" class="fixed inset-0 z-[999] flex items-center justify-center p-4 bg-black/35 backdrop-blur-md">
            <!-- Modal Card (iOS style with blur and automatic dark/light theme support) -->
            <div class="wheel-picker-modal w-[320px] rounded-[30px] p-5 shadow-2xl flex flex-col border backdrop-blur-md">
              
              <!-- Mode Switcher -->
              <div class="flex gap-2 p-1 bg-black/5 rounded-xl mb-4 border border-black/5">
                <button
                  type="button"
                  class="flex-1 py-1.5 rounded-lg text-xs font-semibold cursor-pointer transition-all"
                  :class="pickerMode === 'wheel' ? 'bg-primary text-white shadow-sm' : 'text-gray-500 hover:text-gray-700'"
                  @click="pickerMode = 'wheel'"
                >
                  Ruota
                </button>
                <button
                  type="button"
                  class="flex-1 py-1.5 rounded-lg text-xs font-semibold cursor-pointer transition-all"
                  :class="pickerMode === 'calendar' ? 'bg-primary text-white shadow-sm' : 'text-gray-500 hover:text-gray-700'"
                  @click="pickerMode = 'calendar'"
                >
                  Calendario
                </button>
              </div>

              <!-- Modal Title / Date Preview -->
              <div class="text-center pt-2 pb-2">
                <h4 class="title-label text-xs font-semibold uppercase tracking-wider">Seleziona Data</h4>
                <div class="date-preview text-lg font-bold mt-1 capitalize">
                  {{ tempDay }} {{ monthsNames[tempMonth] }} {{ tempYear }}
                </div>
              </div>

              <!-- Wheel Selector Sub-component -->
              <WheelSelector
                v-show="pickerMode === 'wheel'"
                ref="wheelSelectorRef"
                v-model:day="tempDay"
                v-model:month="tempMonth"
                v-model:year="tempYear"
                :allow-future="props.allowFuture"
                :picker-mode="pickerMode"
                :last-programmatic-scroll-time="lastProgrammaticScrollTime"
              />

              <!-- Calendar Selector Sub-component -->
              <CalendarSelector
                v-show="pickerMode === 'calendar'"
                v-model="tempDate"
                :max-date="props.maxDate"
              />

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
                  @click="showModal = false"
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
    </div>
  </div>
</template>

<style scoped>
.fade-enter-active, .fade-leave-active { 
    transition: opacity .15s ease, transform .15s ease;
}
.fade-enter-from, .fade-leave-to {
    opacity: 0; transform: translateY(-4px); 
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
