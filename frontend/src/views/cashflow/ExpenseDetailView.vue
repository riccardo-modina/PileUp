<script setup>
import { ref, onMounted, watch, computed } from 'vue';
import Detail from '@/components/maincomponents/cashflow/detail/Detail.vue';
import MainComponent from '@/components/maincomponents/MainComponent.vue';
import { getMovimenti, deleteMovimento } from '@/apicalls/apiCalls';
import { useFinancialsStore } from '@/stores/financials';
import { useSettingsStore } from '@/stores/settings';
import { parseDataPeriod } from '@/helpers/dateUtils';

const financials = useFinancialsStore();
const settings = useSettingsStore();
const expenses = ref([]);
const page = ref(1);
const loading = ref(false);
const hasMore = ref(true);
const selectedCategoryId = ref('');


async function fetchExpenses(reset = false, loadAll = false) {
  if (reset) {
    page.value = 1;
    expenses.value = [];
    hasMore.value = true;
  }
  loading.value = true;
  try {
    const { year, month } = parseDataPeriod(settings.dataPeriod);
    const filters = { tipo: 'uscita' };
    if (selectedCategoryId.value) filters.categoria = selectedCategoryId.value;
    
    // If loadAll is true, we use page_size='all'
    const pageSize = loadAll ? 'all' : 20;
    const res = await getMovimenti(page.value, pageSize, year, month, filters);
    
    // When pageSize is 'all', res is likely the array itself or res.results is undefined depending on API
    // But based on apiCalls.js, it handles res.results or res as array.
    const data = res.results || res;
    
    const mapped = data
      .map(m => ({
        ...m,
        date: new Date(m.data).toLocaleDateString('it-IT'),
        amount: Number(m.importo),
        title: m.titolo,
        category: m.categoria ? m.categoria.nome : 'Nessuna',
        categoryColor: m.categoria ? m.categoria.color : '#ccc'
      }));
    
    if (loadAll) {
      expenses.value = mapped;
      hasMore.value = false;
    } else {
      expenses.value = reset ? mapped : [...expenses.value, ...mapped];
      // Check if there are more pages
      if (res.next) {
        page.value++;
        hasMore.value = true;
      } else {
        hasMore.value = false;
      }
    }
  } catch (err) {
    console.error("Error fetching expenses:", err);
  } finally {
    loading.value = false;
  }
}

const unclassifiedCount = computed(() => {
  return expenses.value.filter(m => 
    (m.categoria && m.categoria.is_system) || 
    (m.conto && m.conto.is_system)
  ).length;
});

watch(() => settings.dataPeriod, () => fetchExpenses(true));
watch(selectedCategoryId, () => fetchExpenses(true));

async function handleDelete(mv) {
  try {
    await deleteMovimento(mv.id);
    expenses.value = expenses.value.filter(item => item.id !== mv.id);
  } catch (err) {
    console.error("Error deleting movement:", err);
  }
}

onMounted(() => {
  if (financials.cashFlowCategories.length === 0) {
    financials.fetchAll();
  }
  fetchExpenses();
});


</script>

<template>
  <MainComponent
  :mainComponent="Detail"
  :mainProps="{ 
    desc: 'Dettagli Spese', 
    serie: expenses, 
    categories: financials.cashFlowCategories.filter(c => c.tipo === 'uscita'),
    hasMore: hasMore,
    selectedCategory: selectedCategoryId,
    unclassifiedCount: unclassifiedCount,
    year: parseDataPeriod(settings.dataPeriod).year,
    month: parseDataPeriod(settings.dataPeriod).month
  }"
  :showTopSection=true
  topSectionTitle="Dettagli Spese"
  :showAddButton=true
  :showTimeButton=true
  :listen="{
    'delete-movement': handleDelete,
    'load-more': () => fetchExpenses(),
    'load-all': () => fetchExpenses(true, true),
    'filter-category': (val) => selectedCategoryId = val
  }"
  />
</template>

