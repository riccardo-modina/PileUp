<script setup>
import { ref, onMounted, watch, computed } from 'vue';
import Detail from '@/components/maincomponents/cashflow/detail/Detail.vue';
import MainComponent from '@/components/maincomponents/MainComponent.vue';
import { getMovimenti, deleteMovimento, getMonthlyStats } from '@/apicalls/apiCalls';
import { useFinancialsStore } from '@/stores/financials';
import { useSettingsStore } from '@/stores/settings';
import { parseDataPeriod } from '@/helpers/dateUtils';

const financials = useFinancialsStore();
const settings = useSettingsStore();
const incomes = ref([]);
const periodTotalValue = ref(null);

const periodTotal = computed(() => {
  if (periodTotalValue.value !== null) {
    return new Intl.NumberFormat("it-IT", { 
      style: "currency", 
      currency: "EUR",
      maximumFractionDigits: 2 
    }).format(periodTotalValue.value);
  }
  return history.state?.periodTotal || null;
});

const loading = ref(false);
const loadingBackground = ref(false);
const hasMore = ref(true);
const selectedCategoryId = ref('');

// To prevent overlapping background fetches
let currentFetchId = 0;

function mapMovement(m) {
  return {
    ...m,
    date: new Date(m.data).toLocaleDateString('it-IT'),
    amount: Number(m.importo),
    title: m.titolo,
    category: m.categoria ? m.categoria.nome : 'Nessuna',
    categoryColor: m.categoria ? m.categoria.color : '#ccc'
  };
}

async function fetchIncomes(reset = false) {
  const fetchId = ++currentFetchId;
  
  if (reset) {
    incomes.value = [];
    hasMore.value = true;
    loadingBackground.value = false;
  }
  
  loading.value = true;
  try {
    const { year, month } = parseDataPeriod(settings.dataPeriod);
    const filters = { tipo: 'entrata' };
    if (selectedCategoryId.value) filters.categoria = selectedCategoryId.value;
    
    // First Page: 500 items for immediate feedback
    const res = await getMovimenti(1, 500, year, month, filters);
    
    // If a new fetch has started, abort this one
    if (fetchId !== currentFetchId) return;

    const data = res.results || res;
    incomes.value = data.map(mapMovement);
    
    if (res.next) {
      hasMore.value = true;
      // Start background fetching the rest in chunks of 5000 
      // If we got 500, and there is more, we just fetch page 2 with size 5000.
      fetchRemainingIncomes(fetchId, 2, 5000, year, month, filters);
    } else {
      hasMore.value = false;
    }
  } catch (err) {
    console.error("Error fetching incomes:", err);
  } finally {
    if (fetchId === currentFetchId) loading.value = false;
  }
}

async function fetchRemainingIncomes(fetchId, startPage, pageSize, year, month, filters) {
  loadingBackground.value = true;
  let page = startPage;
  let more = true;

  while (more && fetchId === currentFetchId) {
    try {
      const res = await getMovimenti(page, pageSize, year, month, filters);
      if (fetchId !== currentFetchId) break;

      const data = res.results || res;
      const mapped = data.map(mapMovement);
      
      incomes.value = [...incomes.value, ...mapped];
      
      if (res.next) {
        page++;
      } else {
        more = false;
        hasMore.value = false;
      }
    } catch (err) {
      console.error("Error in background fetch:", err);
      more = false;
    }
  }
  
  if (fetchId === currentFetchId) loadingBackground.value = false;
}

const unclassifiedCount = computed(() => {
  return incomes.value.filter(m => 
    (m.categoria && m.categoria.is_system) || 
    (m.conto && m.conto.is_system)
  ).length;
});

async function fetchPeriodTotal() {
  try {
    const { year, month } = parseDataPeriod(settings.dataPeriod);
    const stats = await getMonthlyStats(year, month);
    periodTotalValue.value = stats.monthlyIncome;
  } catch (err) {
    console.error("Error fetching stats:", err);
  }
}

watch(() => settings.dataPeriod, () => {
  fetchPeriodTotal();
  fetchIncomes(true);
});
watch(selectedCategoryId, () => fetchIncomes(true));

async function handleDelete(mv) {
  try {
    await deleteMovimento(mv.id);
    incomes.value = incomes.value.filter(item => item.id !== mv.id);
  } catch (err) {
    console.error("Error deleting movement:", err);
  }
}

onMounted(() => {
  if (financials.cashFlowCategories.length === 0) {
    financials.fetchAll();
  }
  fetchIncomes(true);
});


</script>

<template>
  <MainComponent
  :mainComponent="Detail"
  :mainProps="{ 
    desc: 'Movimenti', 
    serie: incomes, 
    categories: financials.cashFlowCategories.filter(c => c.tipo === 'entrata'),
    hasMore: hasMore,
    selectedCategory: selectedCategoryId,
    unclassifiedCount: unclassifiedCount,
    year: parseDataPeriod(settings.dataPeriod).year,
    month: parseDataPeriod(settings.dataPeriod).month,
    loadingBackground: loadingBackground,
    periodTotal: periodTotal
  }"
  :showTopSection=true
  topSectionTitle="Dettaglio Entrate"
  :showAddButton=true
  :showTimeButton=true
  :listen="{
    'delete-movement': handleDelete,
    'load-more': () => {}, // Disable manual load more as it's now automatic
    'filter-category': (val) => selectedCategoryId = val
  }"
  />
</template>

