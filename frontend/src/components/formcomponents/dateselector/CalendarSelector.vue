<script setup>
import { computed } from 'vue'
import DatePicker from 'primevue/datepicker'

const props = defineProps({
  modelValue: Date,
  maxDate: Date
})

const emit = defineEmits(['update:modelValue'])

const tempDate = computed({
  get() {
    return props.modelValue
  },
  set(val) {
    emit('update:modelValue', val)
  }
})
</script>

<template>
  <div class="my-4 min-h-[200px] flex items-center justify-center w-full">
    <DatePicker
      v-model="tempDate"
      inline
      :maxDate="props.maxDate"
      :pt="{
        root: 'w-full flex justify-center',
        panel: 'w-full bg-transparent p-0 flex flex-col items-center select-none',
        header: 'w-full flex justify-between items-center text-text mb-2 px-1',
        title: 'text-sm font-bold flex items-center gap-1 text-text capitalize',
        prevbutton: 'text-gray-500 hover:text-primary hover:bg-gray-100/50 rounded-xl p-2 transition cursor-pointer flex items-center justify-center w-8 h-8',
        nextbutton: 'text-gray-500 hover:text-primary hover:bg-gray-100/50 rounded-xl p-2 transition cursor-pointer flex items-center justify-center w-8 h-8',
        calendarContainer: 'w-full',
        calendar: 'w-full table-fixed border-collapse',
        weekHeader: 'text-gray-400 font-semibold text-xs',
        weekHeaderRow: '',
        weekHeaderCell: 'text-center text-[11px] font-bold text-gray-400/80 capitalize p-1',
        weekdays: '',
        week: '',
        dayCell: 'p-1 text-center',
        day: ({ context }) => [
          'w-8 h-8 mx-auto flex items-center justify-center text-xs rounded-full cursor-pointer transition font-medium',
          { 
            'hover:bg-primary/10 hover:text-primary': !context.selected && !context.disabled && !context.dayOtherMonth,
            'text-gray-300 opacity-20 pointer-events-none': context.dayOtherMonth,
            'border border-primary text-primary font-semibold bg-primary/10': context.dayToday && !context.selected,
            'bg-primary text-white font-bold hover:bg-primary-hover shadow-sm': context.selected,
            'text-gray-300 cursor-not-allowed opacity-50': context.disabled && !context.dayOtherMonth
          }
        ]
      }"
    />
  </div>
</template>
