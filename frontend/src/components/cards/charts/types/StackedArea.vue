<script setup>
import { computed } from 'vue'
import { mapSerie } from '@/helpers/mappers/expenseIncomeMapper.js'

const props = defineProps({
  serie: {
    type: Array,
    default: () => []
  },
  title: {
    type: String,
    default: 'Stacked Area Percentuale'
  },
  categories: {
    type: Object,
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

const parsed = computed(() => mapSerie(props.serie, props.year, props.month))

const months = computed(() => parsed.value.months)
const categoryMap = computed(() => parsed.value.categoryMap)


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
    if (props.categories) {
      // array of category objects (e.g. { id, nome, color })
      if (Array.isArray(props.categories)) {
        const found = props.categories.find(c => c.nome === cat || c.name === cat || c.label === cat)
        if (found && found.color) color = found.color
      } else if (typeof props.categories === 'object') {
        // object mapping name -> { color } or name -> color
        if (props.categories[cat]) {
          if (typeof props.categories[cat] === 'string') color = props.categories[cat]
          else if (props.categories[cat].color) color = props.categories[cat].color
        }
      }
    }
    
    const serieObj = {
      name: cat,
      type: 'line',
      stack: 'total',
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
  title: { text: props.title },
  tooltip: {
    trigger: 'axis',
    valueFormatter: v => v.toFixed(1) + '%'
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
  <div class="h-96 w-full">
    <v-chart :option="option" autoresize />
  </div>
</template>
