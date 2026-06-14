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
    :class="[
      'bg-card-background rounded-2xl flex items-center justify-center h-full min-h-80 shadow-sm border border-menuborder/50 transition-all relative overflow-hidden group',
      props.chartEvents.click ? 'cursor-pointer hover:border-primary/30 hover:shadow-md' : ''
    ]"
  >
    <!-- We use @click.stop on the component to avoid double clicks if both capture the event, 
         but we ensure that clicking on the chart itself opens the modal -->
    <component 
      :is="chart" 
      class="flex w-full h-full p-6 relative z-10"  
      v-bind="processedProps" 
      @click.stop="props.chartEvents.click?.()"
    />
    
    <!-- Click Hint Badge -->
    <div 
      v-if="props.chartEvents.click"
      class="absolute top-2 right-2 sm:top-4 sm:right-4 bg-primary/10 text-primary w-8 h-8 sm:w-auto sm:h-auto sm:px-3 sm:py-1.5 rounded-full text-xs font-bold font-sans flex items-center justify-center sm:justify-start gap-1.5 opacity-80 md:opacity-60 group-hover:opacity-100 transition-opacity z-20"
      title="Apri Dettaglio"
    >
      <i class="pi pi-search-plus text-sm"></i> 
      <span class="hidden sm:inline">Apri Dettaglio</span>
    </div>
  </div>
</template>
