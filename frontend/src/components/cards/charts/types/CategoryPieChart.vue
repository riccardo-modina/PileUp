<script setup>
import { computed } from 'vue'
import { formatAmount } from '@/helpers/dateUtils'

const props = defineProps({
  serie: {
    type: Array,
    default: () => []
  },
  title: {
    type: String,
    default: 'Category Breakdown'
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

// Design Note: Unlike line/area charts, the pie chart only shows categories with
// non-zero transactions (which are already present in props.serie).
// Consequently, there is no need to pass the full 'categories' prop.
const pieData = computed(() => {
  const totals = {}

  props.serie.forEach(item => {
    const cat = item.category || 'Nessuna'
    const amt = Number(item.amount) || 0
    const color = item.categoryColor || '#ccc'

    if (!totals[cat]) {
      totals[cat] = {
        value: 0,
        color: color
      }
    }
    totals[cat].value += amt
  })

  return Object.keys(totals).map(cat => {
    return {
      name: cat,
      value: totals[cat].value,
      itemStyle: {
        color: totals[cat].color
      }
    }
  }).sort((a, b) => b.value - a.value)
})

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
    show: window.innerWidth >= 768,
    trigger: 'item',
    formatter: (params) => {
      return `${params.marker} <b>${params.name}</b>: € ${formatAmount(params.value)} (${params.percent}%)`
    }
  },
  legend: {
    type: 'scroll',
    bottom: 0,
    left: 'center'
  },
  series: [
    {
      name: props.title,
      type: 'pie',
      radius: ['35%', '65%'],
      avoidLabelOverlap: true,
      itemStyle: {
        borderRadius: 8,
        borderColor: '#fff',
        borderWidth: 2
      },
      label: {
        show: false,
        position: 'center'
      },
      emphasis: {
        label: {
          show: true,
          fontSize: 14,
          fontWeight: 'bold',
          formatter: (params) => {
            return `${params.name}\n${params.percent}%`
          }
        }
      },
      labelLine: {
        show: false
      },
      data: pieData.value
    }
  ]
}))
</script>

<template>
  <div class="h-full w-full">
    <v-chart :option="option" autoresize />
  </div>
</template>
