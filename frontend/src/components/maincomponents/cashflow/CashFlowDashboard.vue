<script setup>
import { ref, computed } from 'vue';
import CashFlowMainData from './CashFlowMainData.vue';
import ChartSection from '../../cards/charts/ChartSection.vue';
import MonthlyNetChart from '../../cards/charts/types/MonthlyNetChart.vue'
import CumulativeExpInc from '../../cards/charts/types/CumulativeExpIncChart.vue'
import ChartDetailModal from '../../modals/ChartDetailModal.vue';
import { useSettingsStore } from '../../../stores/settings';
import { parseDataPeriod } from '../../../helpers/dateUtils';

const settings = useSettingsStore();

const showDetailModal = ref(false);
const detailYear = ref('');
const detailMonth = ref(null);


const chartTitle = computed(() => {
  const { year, month } = parseDataPeriod(settings.dataPeriod);
  let base = '';
  if (month) base = 'CashFlow Giornaliero';
  else if (year === 'Totale') base = 'CashFlow Annuale';
  else base = 'CashFlow Mensile';
  return base.toUpperCase();
});

const cumulativeTitle = computed(() => {
  const { year, month } = parseDataPeriod(settings.dataPeriod);
  let base = '';
  if (month) base = 'Cumulativo Giornaliero';
  else if (year === 'Totale') base = 'Cumulativo Annuale';
  else base = 'Cumulativo Mensile';
  return base.toUpperCase();
});

const handleChartClick = () => {
  const { year, month } = parseDataPeriod(settings.dataPeriod);
  if (year !== 'Totale') return;
  detailYear.value = year;
  detailMonth.value = month;
  showDetailModal.value = true;
};

const chartEvents = computed(() => {
  const { year } = parseDataPeriod(settings.dataPeriod);
  return year === 'Totale' ? { click: handleChartClick } : {};
});

const props = defineProps({
  financeData: {
    type: Object,
    required: true
  }
})

</script>

<template>
  <div class="flex flex-col gap-6 md:gap-10">
    <!-- main -->
    <section class="flex 2xl:min-h-60 justify-center items-center pt-10">
      <CashFlowMainData 
        :income="props.financeData.monthlyIncome"
        :expense="props.financeData.monthlyExpense"
      />
    </section>

    <!-- graphs -->
    <section class="flex-1 h-full 2xl:pb-20">
      <ChartSection
        :leftChart="{ 
          component: MonthlyNetChart, 
          props: { 
            income: props.financeData.income, 
            spending: props.financeData.spending,
            title: chartTitle,
            year: parseDataPeriod(settings.dataPeriod).year,
            month: parseDataPeriod(settings.dataPeriod).month
          },
          on: chartEvents
        }"
        :rightChart="{ 
          component: CumulativeExpInc, 
          props: { 
            income: props.financeData.income, 
            spending: props.financeData.spending,
            title: cumulativeTitle,
            year: parseDataPeriod(settings.dataPeriod).year,
            month: parseDataPeriod(settings.dataPeriod).month
          },
          on: chartEvents
        }"
        height="h-full"
        />
    </section>

    <!-- detail modal -->
    <ChartDetailModal 
      :show="showDetailModal"
      :year="detailYear"
      :month="detailMonth"
      @close="showDetailModal = false"
    />

  </div>
</template>
