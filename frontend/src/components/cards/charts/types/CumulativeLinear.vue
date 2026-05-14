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
    default: 'Cumulative Linear Chart'
  },
  // allow array or object and normalize later
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

const parsed = computed(() => mapSerie(props.serie, props.year, props.month))

const months = computed(() => parsed.value.months)
const categoryMap = computed(() => parsed.value.categoryMap)

// build a robust lookup from props.categories (supports array or object)
const categoryLookup = computed(() => {
  const map = {}
  const src = props.categories || {}

  if (Array.isArray(src)) {
    src.forEach(c => {
      if (!c) return
      // prefer explicit keys if present
      if (c.nome) map[c.nome] = c
      if (c.name) map[c.name] = map[c.name] || c
      if (c.label) map[c.label] = map[c.label] || c
      if (c.id !== undefined) map[String(c.id)] = map[String(c.id)] || c
    })
  } else if (typeof src === 'object') {
    Object.keys(src).forEach(k => {
      const v = src[k]
      if (typeof v === 'string') {
        // object form: { categoryName: '#hex' }
        map[k] = { color: v }
      } else if (v) {
        map[k] = v
      }
    })
  }

  // add lowercase keys to support case-insensitive matching
  Object.keys(map).forEach(k => {
    map[String(k).toLowerCase()] = map[k]
  })

  return map
})

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
  title: { text: props.title },
  tooltip: { trigger: 'axis' },
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
  <div class="h-96 w-full">
    <v-chart :option="option" autoresize />
  </div>
</template>
