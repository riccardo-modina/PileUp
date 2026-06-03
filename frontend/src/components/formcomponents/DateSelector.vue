<script setup>
import { ref, computed } from 'vue'
import WheelDatePickerModal from './WheelDatePickerModal.vue'

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

const showWheelModal = ref(false)

function openWheelModal() {
  emit('focus')
  showWheelModal.value = true
}

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
</script>

<template>
  <div class="flex mt-1 w-full relative" @focusin="emit('focus')">
    <div class="relative w-full">
      <!-- Unified button trigger for both Mobile and Desktop -->
      <button 
        type="button" 
        @click="openWheelModal"
        class="w-full px-4 py-3 border border-gray-200 rounded-2xl bg-gray-50/50 focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary-light text-sm font-semibold text-text flex items-center justify-between shadow-sm cursor-pointer min-h-[46px]"
      >
        <span class="capitalize">{{ formattedDateMobile }}</span>
        <i class="pi pi-calendar text-primary text-base" />
      </button>

      <!-- Reusable Wheel Date Picker Modal component -->
      <WheelDatePickerModal
        :show="showWheelModal"
        :modelValue="props.modelValue"
        :maxDate="props.maxDate"
        :allowFuture="props.allowFuture"
        @update:modelValue="emit('update:modelValue', $event)"
        @close="showWheelModal = false"
      />
    </div>
  </div>
</template>
