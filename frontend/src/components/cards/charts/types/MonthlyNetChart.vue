<script setup>
import { computed } from 'vue'
import { fillTimelineGaps } from '@/helpers/charts/gapFiller.js'
import { formatAmount } from '@/helpers/dateUtils'

const props = defineProps({
  income: {
    type: Array,
    default: () => []
  },
  spending: {
    type: Array,
    default: () => []
  },
  title: {
    type: String,
    default: 'CashFlow Mensile'
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

const emit = defineEmits(['click'])

const onClick = (params) => {
  emit('click', params)
}

// derive months from income and spending (unique, preserving order)
const months = computed(() => {
  // If we have explicit year, we can generate a full timeline
  if (props.year && props.year !== 'Totale') {
    if (props.month) {
      // Daily view: all days of the month
      const labels = []
      const numDays = new Date(Number(props.year), props.month, 0).getDate()
      for (let d = 1; d <= numDays; d++) {
        labels.push(`${String(d).padStart(2, '0')}/${String(props.month).padStart(2, '0')}`)
      }
      return labels
    } else {
      // Yearly view: all 12 months (Match backend Italian abbreviations)
      const months_it = ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic']
      return months_it
    }
  }

  const incLabels = (props.income || []).map(i => i.month)
  const expLabels = (props.spending || []).map(s => s.month)
  const allLabels = [...new Set([...incLabels, ...expLabels])]
  
  // Sort and fill gaps based on all present labels
  // We use a dummy amount: 0 for the helper
  const dummyData = allLabels.map(l => ({ month: l, amount: 0 }))
  const filledData = fillTimelineGaps(dummyData)
  return filledData.map(d => d.month)
})

// align series to months (if a month is missing in income/spending, use 0)
const incomeSeries = computed(() => {
  const map = new Map(props.income.map(i => [i.month, i.amount]))
  return months.value.map(m => Number(map.get(m) || 0))
})

const spendingSeries = computed(() => {
  const map = new Map(props.spending.map(s => [s.month, s.amount]))
  return months.value.map(m => Number(map.get(m) || 0))
})

// net cash flow
const netSeries = computed(() =>
  months.value.map((_, i) => (incomeSeries.value[i] || 0) - (spendingSeries.value[i] || 0))
)

const option = computed(() => ({
  textStyle: {
    fontFamily: 'Montserrat, sans-serif'
  },
  title: {
    text: props.title,
    padding: [
      0,  // up
      0, // right
      5,  // down
      0, // left
    ]
  },
  tooltip: {
    trigger: 'axis',
    valueFormatter: (value) => '€ ' + formatAmount(value)
  },
  legend: {
    type: 'scroll',
    bottom: 0,
    data: ['Entrate', 'Uscite', 'Netto']
  },
  grid: {
    top: 60,
    bottom: 60,
    left: '3%',
    right: '4%',
    containLabel: true
  },
  xAxis: {
    type: 'category',
    data: months.value
  },
  yAxis: [
    { type: 'value', name: 'Euro' }
  ],
  series: [
    {
      name: 'Entrate',
      type: 'line',
      symbol: 'circle',
      symbolSize: 8,
      data: incomeSeries.value,
      itemStyle: { color: '#41B646' }
    },
    {
      name: 'Uscite',
      type: 'line',
      symbol: 'circle',
      symbolSize: 8,
      data: spendingSeries.value,
      itemStyle: { color: '#D6455D' }
    },
    {
      name: 'Netto',
      type: 'bar',
      data: netSeries.value,
      barWidth: '30%',
      itemStyle: { color: '#3A6C8A' }
    }
  ]
}))
</script>

<template>
  <div class="h-full w-full">
    <v-chart :option="option" autoresize @click="onClick" />
  </div>
</template>

