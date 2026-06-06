<script setup>
import { computed } from 'vue'
import { useCategoryChartData } from '@/composables/charts/useCategoryChartData.js'

const props = defineProps({
  serie: {
    type: Array,
    default: () => []
  },
  title: {
    type: String,
    default: 'Category Trend (Percentage)'
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
 * sum of values to get percentages
 */
const monthlyTotals = computed(() => {
  return months.value.map(month => {
    let sum = 0
    for (const cat in categoryMap.value) {
      sum += categoryMap.value[cat][month] || 0
    }
    return sum
  })
})

/**
 * percentages and stacked area series
 */
const dynamicSeries = computed(() => {
  const series = []

  for (const cat in categoryMap.value) {
    const rawMonthlyValues = months.value.map(m => categoryMap.value[cat][m] || 0)

    // trasformo in percentuali
    const percValues = rawMonthlyValues.map((v, i) => {
      const total = monthlyTotals.value[i]
      return total > 0 ? (v / total) * 100 : 0
    })

    // resolve color from props.categories (support array or object)
    let color = undefined
    if (categoryLookup.value) {
      const key = cat == null ? '' : String(cat)
      const found = categoryLookup.value[key] || categoryLookup.value[key.toLowerCase()]
      if (found) {
        if (typeof found === 'string') color = found
        else if (found.color) color = found.color
      }
    }
    
    const serieObj = {
      name: cat,
      type: 'line',
      stack: 'total',
      symbol: 'circle',
      symbolSize: 6,
      areaStyle: {},
      emphasis: { focus: 'series' },
      data: percValues,
      smooth: true
    }

    if (color) {
      // apply color to line and area
      serieObj.itemStyle = { color }
      serieObj.areaStyle = { color }
    }

    series.push(serieObj)
  }

  return series
})

/**
 * Opzione finale ECharts
 */
const option = computed(() => ({
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
    valueFormatter: v => v.toFixed(2) + '%'
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
  yAxis: {
    type: 'value',
    name: '%',
    min: 0,
    max: 100
  },
  series: dynamicSeries.value
}))
</script>

<template>
  <div class="h-full w-full">
    <v-chart :option="option" autoresize />
  </div>
</template>
