<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import CashFlowDashboard from '../../components/maincomponents/cashflow/CashFlowDashboard.vue';
import MainComponent from '../../components/maincomponents/MainComponent.vue';
import { getMonthlyStats } from '../../apicalls/apiCalls';
import { useFinancialsStore } from '../../stores/financials';
import { useSettingsStore } from '../../stores/settings';
import { parseDataPeriod } from '../../helpers/dateUtils';

const financials = useFinancialsStore();
const settings = useSettingsStore();

const financeData = ref({
  income: [],
  spending: [],
  monthlyIncome: 0,
  monthlyExpense: 0
});
const loading = ref(true);


const fetchData = async () => {
  loading.value = true;
  try {
    const { year, month } = parseDataPeriod(settings.dataPeriod);
    const res = await getMonthlyStats(year, month);
    financeData.value = res;
  } catch (err) {
    console.error("Error loading dashboard stats:", err);
  } finally {
    loading.value = false;
  }
};

watch(() => settings.dataPeriod, fetchData);

onMounted(async () => {
  // Load categories and accounts if not loaded
  if (financials.cashFlowCategories.length === 0) {
    financials.fetchAll();
  }
  await fetchData();
});

</script>

<template>
  <MainComponent
  :mainComponent="CashFlowDashboard"
  :mainProps="{ financeData: financeData }"
  :showTopSection= true
  topSectionTitle="Riepilogo Movimenti"
  :showAddButton= true
  :showTimeButton= true
  /> 
</template>


