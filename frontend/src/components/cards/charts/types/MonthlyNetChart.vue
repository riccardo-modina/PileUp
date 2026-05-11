<script setup>
import { computed } from 'vue'

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
  }
})

const emit = defineEmits(['click'])

const onClick = (params) => {
  emit('click', params)
}

// derive months from income and spending (unique, preserving order)
const months = computed(() => {
  const inc = (props.income || []).map(i => i.month)
  const exp = (props.spending || []).map(s => s.month)
  return [...new Set([...inc, ...exp])]
})

// align series to months (if a month is missing in income/spending, use 0)
const incomeSeries = computed(() =>
  months.value.map(m => {
    const item = (props.income || []).find(i => i.month === m)
    return Number(item?.amount || 0)
  })
)

const spendingSeries = computed(() =>
  months.value.map(m => {
    const item = (props.spending || []).find(s => s.month === m)
    return Number(item?.amount || 0)
  })
)

// net cash flow
const netSeries = computed(() =>
  months.value.map((_, i) => (incomeSeries.value[i] || 0) - (spendingSeries.value[i] || 0))
)

const option = computed(() => ({
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
    trigger: 'axis'
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
      data: incomeSeries.value,
      itemStyle: { color: '#41B646' }
    },
    {
      name: 'Uscite',
      type: 'line',
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
  <div class="h-96 w-full">
    <v-chart :option="option" autoresize @click="onClick" />
  </div>
</template>

