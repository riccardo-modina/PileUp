<script setup>
import { ref, watch, computed } from 'vue'
import WheelYearMonthPickerModal from '@/components/formcomponents/timeframe/WheelYearMonthPickerModal.vue'
import PrimaryButton from '@/components/buttons/primarybuttons/PrimaryButton.vue';

const props = defineProps({
  dataPeriod: {
    type: String,
    default: new Date().getFullYear().toString()
  }
})

const isOpen = ref(false)
const buttonDesc = ref(props.dataPeriod)

const emit = defineEmits(['timeFrameUpdate', 'buttonToggled'])

function toggle() {
  isOpen.value = !isOpen.value
}

function timeFrameUpdated(timeFrame, source) {
  emit('timeFrameUpdate', timeFrame, source)

  if (source === 'monthYear') {
    let label = timeFrame.month.toString().padStart(2, '0') + '/' + timeFrame.year
    buttonDesc.value = label
  } else if (source === 'preset') {
    buttonDesc.value = timeFrame
  } else {
    buttonDesc.value = timeFrame.toString()
  }

  isOpen.value = false
}

// Watch for dataPeriod prop changes to update the button label
watch(() => props.dataPeriod, (newVal) => {
  buttonDesc.value = newVal
}, { immediate: true })

// Watch isOpen to sync the parent MainComponent state
watch(isOpen, (newVal) => {
  emit('buttonToggled', newVal)
})

const isNextDisabled = computed(() => {
  const period = props.dataPeriod
  if (!period || period === 'Totale') return true

  const today = new Date()
  const todayY = today.getFullYear()
  const todayM = today.getMonth() + 1

  if (period.includes('/')) {
    const [mStr, yStr] = period.split('/')
    const m = parseInt(mStr)
    const y = parseInt(yStr)
    if (y > todayY) return true
    if (y === todayY && m >= todayM) return true
  } else {
    const y = parseInt(period)
    if (y >= todayY) return true
  }
  return false
})

function adjustPeriod(direction) {
  const period = props.dataPeriod
  if (!period || period === 'Totale') return

  if (period.includes('/')) {
    const [mStr, yStr] = period.split('/')
    const m = parseInt(mStr)
    const y = parseInt(yStr)
    const date = new Date(y, m - 1, 1)
    date.setMonth(date.getMonth() + direction)
    
    const newMonth = date.getMonth() + 1
    const newYear = date.getFullYear()
    
    // Validate we don't adjust into the future
    const today = new Date()
    if (newYear > today.getFullYear() || (newYear === today.getFullYear() && newMonth > today.getMonth() + 1)) {
      return
    }

    timeFrameUpdated({ month: newMonth, year: newYear }, 'monthYear')
  } else {
    const y = parseInt(period)
    if (isNaN(y)) return
    const newYear = y + direction
    
    // Validate we don't adjust into the future
    const today = new Date()
    if (newYear > today.getFullYear()) {
      return
    }

    timeFrameUpdated(newYear, 'year')
  }
}
</script>

<template>
  <div class="flex items-center gap-1.5">
    <!-- Indietro (Previous) Button -->
    <button 
      type="button"
      @click="adjustPeriod(-1)"
      :disabled="props.dataPeriod === 'Totale'"
      class="h-8 w-8 rounded-[10px] bg-primary-light/10 border-2 border-primary-light/30 text-primary md:hover:bg-primary-light/20 md:hover:border-primary-light/45 flex items-center justify-center transition-all cursor-pointer disabled:opacity-30 disabled:cursor-not-allowed active:scale-95 flex-shrink-0"
      title="Periodo precedente"
    >
      <i class="pi pi-chevron-left text-xs font-bold" />
    </button>

    <div class="relative inline-block">
      <!-- Trigger -->
      <PrimaryButton 
          @click="toggle"
          :aria-expanded="isOpen"
          class="h-8 w-25 flex gap-2 items-center justify-center px-3 font-medium"
      >
        <i class="pi pi-calendar text-lg" />
        {{ buttonDesc }}
      </PrimaryButton>

      <WheelYearMonthPickerModal
        :show="isOpen"
        :timeFrame="props.dataPeriod"
        @close="isOpen = false"
        @updateYear="(val) => timeFrameUpdated(val, 'year')"
        @updateMonthYear="(val) => timeFrameUpdated(val, 'monthYear')"
        @updatePreset="(val) => timeFrameUpdated(val, 'preset')"
      />
    </div>

    <!-- Avanti (Next) Button -->
    <button 
      type="button"
      @click="adjustPeriod(1)"
      :disabled="isNextDisabled"
      class="h-8 w-8 rounded-[10px] bg-primary-light/10 border-2 border-primary-light/30 text-primary md:hover:bg-primary-light/20 md:hover:border-primary-light/45 flex items-center justify-center transition-all cursor-pointer disabled:opacity-30 disabled:cursor-not-allowed active:scale-95 flex-shrink-0"
      title="Periodo successivo"
    >
      <i class="pi pi-chevron-right text-xs font-bold" />
    </button>
  </div>
</template>
