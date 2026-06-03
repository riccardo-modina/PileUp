<script setup>
import { ref, watch } from 'vue'
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
</script>

<template>
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
</template>
