<script setup>
import { computed } from 'vue'
import { fillTimelineGaps } from '@/helpers/charts/gapFiller.js'

const props = defineProps({
  chart: Object,
  chartProps: {
    type: Object,
    default: () => ({})
  },
  chartEvents: {
    type: Object,
    default: () => ({})
  }
})

const processedProps = computed(() => {
  const p = { ...props.chartProps }
  if (p.income) p.income = fillTimelineGaps(p.income)
  if (p.spending) p.spending = fillTimelineGaps(p.spending)
  return p
})
</script>

<template>
  <div 
    @click="props.chartEvents.click?.()"
    class="bg-card-background rounded-2xl flex items-center justify-center h-full min-h-80 shadow-sm border border-menuborder/50 cursor-pointer hover:border-primary/30 transition-colors"
  >
    <!-- We use @click.stop on the component to avoid double clicks if both capture the event, 
         but we ensure that clicking on the chart itself opens the modal -->
    <component 
      :is="chart" 
      class="flex w-full h-full p-6"  
      v-bind="processedProps" 
      @click.stop="props.chartEvents.click?.()"
    />
  </div>
</template>
