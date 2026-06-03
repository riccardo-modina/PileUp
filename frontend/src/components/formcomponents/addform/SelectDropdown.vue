<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import CreateCategoryModal from '@/components/modals/CreateCategoryModal.vue'
import CreateAccountModal from '@/components/modals/CreateAccountModal.vue'

const props = defineProps({
  items: { type: Array, default: () => [] },
  modelValue: { type: [String, Number], default: '' },
  placeholder: { type: String, default: 'Select' },
  itemLabel: { type: String, default: 'name' },
  showColor: { type: Boolean, default: false },
  clearable: { type: Boolean, default: true },
  searchEnabled: { type: Boolean, default: true },
  required: { type: Boolean, default: false },

  allowCreateCategory: { type: Boolean, default: false },
  allowCreateAccount: { type: Boolean, default: false },
  filterSystemItems: { type: Boolean, default: true },
  disabled: { type: Boolean, default: false },
  initialType: { type: String, default: 'uscita' }
})

const emit = defineEmits(['update:modelValue', 'select', 'clear', 'item-created'])

const open = ref(false)
const search = ref('')

const containerRef = ref(null)
const showCreateModal = ref(false)

const filtered = computed(() => {
  let list = props.items || []
  if (props.filterSystemItems) {
    list = list.filter(i => !i.is_system)
  }
  if (!props.searchEnabled || !search.value) return list
  const q = String(search.value).toLowerCase()
  return list.filter(i => (String(i[props.itemLabel] || '')).toLowerCase().includes(q))
})

const selectedItem = computed(() => {
  const val = String(props.modelValue)
  return (props.items || []).find(i => String(i.id) === val || String(i.nome) === val) || null
})

function toggle() { open.value = !open.value }

function choose(item) {
  // If it's a new item (backend response mapping 'nome' to 'id')
  const val = item.id || item.nome;
  emit('update:modelValue', val)
  emit('select', item)
  search.value = ''
  open.value = false
}

function clearSelection(e) {
  e && e.stopPropagation()
  emit('update:modelValue', '')
  emit('clear')
  search.value = ''
  open.value = false
}

function onClickOutside(e) {
  if (!containerRef.value) return
  if (!containerRef.value.contains(e.target)) open.value = false
}

function onKeydown(e) {
  if (e.key === 'Escape') open.value = false
}

onMounted(() => {
  document.addEventListener('click', onClickOutside)
  document.addEventListener('keydown', onKeydown)
})
onUnmounted(() => {
  document.removeEventListener('click', onClickOutside)
  document.removeEventListener('keydown', onKeydown)
})
</script>

<template>
  <div class="relative" ref="containerRef">
    <button type="button" @click="!props.disabled && toggle()" :aria-expanded="open" aria-haspopup="listbox"
            :disabled="props.disabled"
            :class="[
              'w-full px-3 py-2 border rounded-md focus:outline-none transition-all flex items-center justify-between gap-2',
              props.disabled 
                ? 'bg-gray-50 border-gray-200 text-gray-400 cursor-not-allowed' 
                : 'bg-white border-gray-300 text-gray-700 focus:ring-2 focus:ring-primary-light'
            ]">
       <div class="flex items-center gap-3">
        <span v-if="selectedItem && props.showColor && selectedItem.color" :style="{ backgroundColor: selectedItem.color }" class="w-3.5 h-3.5 rounded-full inline-block"></span>
        <span
          class="block whitespace-normal text-left"
          :title="selectedItem ? selectedItem[props.itemLabel] : placeholder"
        >
          {{ selectedItem ? selectedItem[props.itemLabel] : placeholder }}
        </span>
      </div>

      <div class="flex items-center gap-2">
        <button v-if="selectedItem && props.clearable" @click.stop="clearSelection" type="button" class="text-gray-400 hover:text-gray-600 px-1">×</button>
        <i :class="['pi pi-chevron-down text-sm transition-transform', open ? 'rotate-180' : 'rotate-0']" />
      </div>
    </button>

    <transition name="fade">
      <div v-if="open" class="absolute z-50 w-full mt-2 bg-white border border-gray-200 rounded-md shadow-lg">
        <div v-if="props.searchEnabled" class="p-2">
          <input v-model="search" type="search" placeholder="Cerca..."
                 class="w-full px-3 py-2 border border-gray-100 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-light" />
        </div>

        <ul role="listbox" class="max-h-56 overflow-y-auto divide-y divide-gray-100">
          <li v-if="(filtered || []).length === 0" class="px-3 py-2 text-sm text-gray-500">Nessuna voce trovata</li>
          <li v-for="item in filtered" :key="item.id || item.nome" @click="choose(item)"
              class="px-3 py-2 cursor-pointer flex items-center justify-between hover:bg-10"
              :aria-selected="selectedItem && (selectedItem.id === item.id || selectedItem.nome === item.nome)">
            <div class="flex items-center gap-3">
              <span v-if="props.showColor && item.color" :style="{ backgroundColor: item.color }" class="w-3.5 h-3.5 rounded-full inline-block"></span>
              <span class="text-sm text-text">{{ item[props.itemLabel] }}</span>
            </div>
            <span v-if="selectedItem && (selectedItem.id === item.id || selectedItem.nome === item.nome)" class="text-primary"><i class="pi pi-check text-xs" /></span>
          </li>
        </ul>

        <div v-if="props.allowCreateCategory || props.allowCreateAccount" class="group p-2 border-t border-gray-100 flex items-center justify-center">
          <div class="flex items-center justify-center gap-2  text-sm text-text">
            <button type="button" @click.stop="showCreateModal = true" class=" cursor-pointer flex items-center gap-2 justify-center transition-colors hover:bg-primary/10 rounded-lg px-3 py-2">
                <i class="pi pi-plus text-xs" />
                <span>{{ props.allowCreateCategory ? 'Crea nuova categoria' : 'Crea nuovo conto' }}</span>
            </button>
          </div>
        </div>
      </div>
    </transition>
    
    <CreateCategoryModal 
      v-if="props.allowCreateCategory"
      :is-open="showCreateModal" 
      :initialType="props.initialType"
      @close="showCreateModal = false"
      @created="(newItem) => { 
        emit('item-created', newItem); 
        choose(newItem); 
        showCreateModal = false; 
      }" 
    />

    <CreateAccountModal 
      v-if="props.allowCreateAccount"
      :is-open="showCreateModal" 
      @close="showCreateModal = false"
      @created="(newItem) => { 
        emit('item-created', newItem); 
        choose(newItem); 
        showCreateModal = false; 
      }" 
    />
  </div>
</template>

<style scoped>
.fade-enter-active, .fade-leave-active { 
    transition: opacity .15s ease, transform .15s ease;
}
.fade-enter-from, .fade-leave-to {
    opacity: 0; transform: translateY(-4px); 
}
.truncate { 
    max-width: calc(100% - 3rem); display: inline-block; overflow: hidden; white-space: nowrap; text-overflow: ellipsis; 
}
</style>
