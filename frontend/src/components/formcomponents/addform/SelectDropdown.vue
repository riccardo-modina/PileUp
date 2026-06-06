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
              'w-full px-3.5 py-2.5 border rounded-xl focus:outline-none transition-all flex items-center justify-between gap-2 text-sm',
              props.disabled 
                ? 'bg-gray-100 border-gray-200 text-gray-400 cursor-not-allowed' 
                : 'bg-gray-50/50 border-gray-200 text-text hover:bg-gray-50 focus:bg-white focus:ring-2 focus:ring-primary-light/50 focus:border-primary-light'
            ]">
       <div class="flex items-center gap-3">
        <span v-if="selectedItem && props.showColor && selectedItem.color" :style="{ backgroundColor: selectedItem.color }" class="w-3 h-3 rounded-full inline-block"></span>
        <span
          class="block whitespace-normal text-left text-sm"
          :title="selectedItem ? selectedItem[props.itemLabel] : placeholder"
        >
          {{ selectedItem ? selectedItem[props.itemLabel] : placeholder }}
        </span>
      </div>

      <div class="flex items-center gap-2">
        <button v-if="selectedItem && props.clearable" @click.stop="clearSelection" type="button" class="text-gray-400 hover:text-gray-600 px-1 font-bold text-sm">×</button>
        <i :class="['pi pi-chevron-down text-xs transition-transform text-gray-500', open ? 'rotate-180' : 'rotate-0']" />
      </div>
    </button>

    <transition name="fade">
      <div v-if="open" class="absolute z-50 w-full mt-2 bg-white border border-gray-100 rounded-2xl shadow-xl p-1.5">
        <div v-if="props.searchEnabled" class="p-1.5">
          <input v-model="search" type="search" placeholder="Cerca..."
                 class="w-full px-3.5 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-light transition-all text-xs bg-gray-50/50 hover:bg-gray-50 focus:bg-white" />
        </div>

        <ul role="listbox" class="max-h-56 overflow-y-auto p-1 flex flex-col gap-0.5 custom-scrollbar">
          <li v-if="(filtered || []).length === 0" class="px-3.5 py-2.5 text-xs text-gray-400 italic">Nessuna voce trovata</li>
          <li v-for="item in filtered" :key="item.id || item.nome" @click="choose(item)"
              :class="[
                'px-3.5 py-2.5 rounded-xl cursor-pointer flex items-center justify-between text-xs transition-all duration-150',
                (selectedItem && (selectedItem.id === item.id || selectedItem.nome === item.nome))
                  ? 'bg-primary/5 text-primary font-semibold'
                  : 'hover:bg-gray-50 text-text'
              ]"
              :aria-selected="selectedItem && (selectedItem.id === item.id || selectedItem.nome === item.nome)">
            <div class="flex items-center gap-3">
              <span v-if="props.showColor && item.color" :style="{ backgroundColor: item.color }" class="w-3 h-3 rounded-full inline-block"></span>
              <span>{{ item[props.itemLabel] }}</span>
            </div>
            <span v-if="selectedItem && (selectedItem.id === item.id || selectedItem.nome === item.nome)" class="text-primary-light">
              <i class="pi pi-check text-[10px] font-bold" />
            </span>
          </li>
        </ul>

        <div v-if="props.allowCreateCategory || props.allowCreateAccount" class="p-1.5 border-t border-gray-100 flex items-center justify-center">
          <button type="button" @click.stop="showCreateModal = true" 
                  class="w-full cursor-pointer flex items-center gap-2 justify-center transition-all duration-200 text-[10px] font-bold uppercase tracking-wider text-primary bg-primary/5 hover:bg-primary/10 rounded-xl py-2.5">
              <i class="pi pi-plus text-[10px]" />
              <span>{{ props.allowCreateCategory ? 'Nuova Categoria' : 'Nuovo Conto' }}</span>
          </button>
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
