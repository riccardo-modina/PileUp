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
const incomes = ref([]);
const page = ref(1);
const loading = ref(false);
const hasMore = ref(true);
const selectedCategoryId = ref('');


async function fetchIncomes(reset = false, loadAll = false) {
  if (reset) {
    page.value = 1;
    incomes.value = [];
    hasMore.value = true;
  }
  loading.value = true;
  try {
    const { year, month } = parseDataPeriod(settings.dataPeriod);
    const filters = { tipo: 'entrata' };
    if (selectedCategoryId.value) filters.categoria = selectedCategoryId.value;
    
    const pageSize = loadAll ? 'all' : 20;
    const res = await getMovimenti(page.value, pageSize, year, month, filters);
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
      incomes.value = mapped;
      hasMore.value = false;
    } else {
      incomes.value = reset ? mapped : [...incomes.value, ...mapped];
      // Check if there are more pages
      if (res.next) {
        page.value++;
        hasMore.value = true;
      } else {
        hasMore.value = false;
      }
    }
  } catch (err) {
    console.error("Error fetching incomes:", err);
  } finally {
    loading.value = false;
  }
}

const unclassifiedCount = computed(() => {
  return incomes.value.filter(m => 
    (m.categoria && m.categoria.is_system) || 
    (m.conto && m.conto.is_system)
  ).length;
});

watch(() => settings.dataPeriod, () => fetchIncomes(true));
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
  fetchIncomes();
});


</script>

<template>
  <MainComponent
  :mainComponent="Detail"
  :mainProps="{ 
    desc: 'Dettagli Entrate', 
    serie: incomes, 
    categories: financials.cashFlowCategories.filter(c => c.tipo === 'entrata'),
    hasMore: hasMore,
    selectedCategory: selectedCategoryId,
    unclassifiedCount: unclassifiedCount,
    year: parseDataPeriod(settings.dataPeriod).year,
    month: parseDataPeriod(settings.dataPeriod).month
  }"
  :showTopSection=true
  topSectionTitle="Dettagli Entrate"
  :showAddButton=true
  :showTimeButton=true
  :listen="{
    'delete-movement': handleDelete,
    'load-more': () => fetchIncomes(),
    'load-all': () => fetchIncomes(true, true),
    'filter-category': (val) => selectedCategoryId = val
  }"
  />
</template>

