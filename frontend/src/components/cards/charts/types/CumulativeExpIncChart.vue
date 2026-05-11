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
    default: 'Cumulativo Entrate e Uscite'
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

// cumulative calculations based on aligned series
const incomeCumulative = computed(() =>
  incomeSeries.value.map((val, i) =>
    val + (i > 0 ? incomeSeries.value.slice(0, i).reduce((a, b) => a + b, 0) : 0)
  )
)

const spendingCumulative = computed(() =>
  spendingSeries.value.map((val, i) =>
    val + (i > 0 ? spendingSeries.value.slice(0, i).reduce((a, b) => a + b, 0) : 0)
  )
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
    data: ['Entrate cumulative', 'Uscite cumulative']
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
  yAxis: {
    type: 'value',
    name: 'Euro',
    nameTextStyle: {
      fontSize: 12
    }
  },
  series: [
    {
      name: 'Entrate cumulative',
      type: 'line',
      data: incomeCumulative.value,
      smooth: true,
      itemStyle: { color: '#41B646' }
    },
    {
      name: 'Uscite cumulative',
      type: 'line',
      data: spendingCumulative.value,
      smooth: true,
      itemStyle: { color: '#D6455D' }
    }
  ]
}))
</script>

<template>
  <div class="h-96 w-full">
    <v-chart :option="option" autoresize @click="onClick" />
  </div>
</template>
