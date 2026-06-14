<script setup>
import { computed } from 'vue'
import { useCategoryChartData } from '@/composables/charts/useCategoryChartData.js'
import { formatAmount } from '@/helpers/dateUtils'

const props = defineProps({
  serie: {
    type: Array,
    default: () => []
  },
  title: {
    type: String,
    default: 'Category Trend (Absolute)'
  },
  categories: {
    type: [Array, Object],
    default: () => ({})
  },
  year: {
    type: [String, Number],
    default: null
  },
  month: {
    type: Number,
    default: null
  }
})

const { months, categoryMap, categoryLookup } = useCategoryChartData(
  () => props.serie,
  () => props.categories,
  () => props.year,
  () => props.month
)

/**
 * individual series per category with ECharts stacking
 */
const dynamicSeries = computed(() => {
  const series = []

  for (const cat in categoryMap.value) {
    const monthlyValues = months.value.map(m => categoryMap.value[cat][m] || 0)

    // resolve color using normalized lookup (case-insensitive)
    let color = undefined
    if (categoryLookup.value) {
      const key = cat == null ? '' : String(cat)
      const found = categoryLookup.value[key] || categoryLookup.value[key.toLowerCase()]
      if (found) {
        if (typeof found === 'string') color = found
        else if (found.color) color = found.color
      }
    }

    // treat empty string as undefined to let chart use defaults
    if (color === '') color = undefined

    const serieObj = {
      name: cat,
      type: 'line',
      stack: 'total', // stack visually
      symbol: 'circle',
      symbolSize: 6,
      areaStyle: {},  // filled area for stacked chart
      emphasis: { focus: 'series' },
      data: monthlyValues, // pass original values
      smooth: true
    }

    if (color) {
      serieObj.itemStyle = { color }
      serieObj.areaStyle = { color }
    }

    series.push(serieObj)
  }

  return series
})

/**
 * Echart option
 */
const option = computed(() => ({
  textStyle: {
    fontFamily: 'system-ui, -apple-system, sans-serif'
  },
  title: { 
    text: props.title,
    left: 'center',
    textStyle: {
      fontSize: 18,
      fontWeight: 'bold'
    }
  },
  tooltip: { 
    trigger: 'axis',
    valueFormatter: (value) => '€ ' + formatAmount(value)
  },
  legend: { 
    type: 'scroll',
    bottom: 0,
    data: Object.keys(categoryMap.value) 
  },
  grid: {
    top: 60,
    bottom: 60,
    left: '3%',
    right: '4%',
    containLabel: true
  },
  xAxis: { type: 'category', data: months.value },
  yAxis: [{ type: 'value', name: 'Euro' }],
  series: dynamicSeries.value
}))
</script>

<template>
  <div class="h-full w-full">
    <v-chart :option="option" autoresize />
  </div>
</template>
