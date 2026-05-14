<script setup>
import { computed } from 'vue'
import { fillTimelineGaps } from '@/helpers/charts/gapFiller.js'

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
      // Yearly view: all 12 months
      const labels = []
      const shortYear = String(props.year).slice(-2)
      for (let m = 1; m <= 12; m++) {
        labels.push(`${String(m).padStart(2, '0')}/${shortYear}`)
      }
      return labels
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
