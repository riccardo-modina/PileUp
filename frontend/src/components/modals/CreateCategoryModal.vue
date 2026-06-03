<script setup>
import { ref, onMounted, onBeforeUnmount, computed, watch } from 'vue'
import BaseButton from '@/components/buttons/BaseButton.vue'
import SelectDropdown from '@/components/formcomponents/addform/SelectDropdown.vue'
import { createCategoria } from '@/apicalls/apiCalls'
import { useFinancialsStore } from '@/stores/financials'

const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false
  },
  initialType: {
    type: String,
    default: 'uscita'
  },
  category: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['close', 'created', 'updated'])
const financials = useFinancialsStore()
const movementTypes = computed(() => financials.movementTypes)

const form = ref({
  name: '',
  type: props.initialType || 'uscita',
  color: '#1FBC9C'
})

const loading = ref(false)
const error = ref('')

const isMobile = ref(false)

function updateIsMobile() {
  isMobile.value = window.innerWidth < 640
}

watch(() => props.category, (newVal) => {
  if (newVal) {
    form.value = {
      name: newVal.nome,
      type: newVal.tipo,
      color: newVal.color || '#1FBC9C'
    }
  } else {
    resetForm()
  }
}, { immediate: true })

onMounted(() => {
  updateIsMobile()
  window.addEventListener('resize', updateIsMobile)
})

onBeforeUnmount(() => {
  window.removeEventListener('resize', updateIsMobile)
})


function resetForm() {
  form.value = {
    name: '',
    type: props.initialType || 'uscita',
    color: '#1FBC9C'
  }
  error.value = ''
}

async function save() {
  if (!form.value.name) {
    error.value = 'Il nome è obbligatorio'
    return
  }

  loading.value = true
  error.value = ''

  try {
    if (props.category) {
      // Update
      const res = await financials.updateCategoria(props.category.id, {
        nome: form.value.name,
        tipo: form.value.type,
        color: form.value.color
      })
      emit('updated', res)
    } else {
      // Create
      const res = await financials.createCategoria({
        nome: form.value.name,
        tipo: form.value.type,
        color: form.value.color
      })
      emit('created', res)
    }
    resetForm()
    emit('close')
  } catch (err) {
    console.error('Error saving category:', err)
    let displayMsg = 'Errore durante il salvataggio. Riprova più tardi.'
    
    if (err.response) {
      const data = err.response.data
      console.log('API Error Data:', data)
      
      if (data && typeof data === 'object') {
        const allMessages = Object.entries(data).flatMap(([field, msgs]) => {
          if (Array.isArray(msgs)) return msgs
          return [msgs]
        })
        
        const combinedText = allMessages.join(' ').toLowerCase()
        if (
          combinedText.includes('unique') || 
          combinedText.includes('esiste') || 
          combinedText.includes('already exists') ||
          combinedText.includes('set unico')
        ) {
          displayMsg = 'Esiste già una categoria con questo nome per il tipo selezionato'
        } else if (allMessages.length > 0) {
          displayMsg = String(allMessages[0])
        }
      } else if (typeof data === 'string' && data.length > 0) {
        displayMsg = data
      }
    } else if (err.request) {
      displayMsg = 'Nessuna risposta dal server. Controlla la tua connessione.'
    } else if (err.message) {
      displayMsg = `Errore: ${err.message}`
    }
    
    error.value = displayMsg
  } finally {
    loading.value = false
  }
}


function close() {
  resetForm()
  emit('close')
}
</script>

<template>
  <Teleport to="body">
    <div v-if="isOpen" class="fixed inset-0 z-[9999] flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" @click="close"></div>
      <div class="relative bg-white rounded-lg shadow-xl p-6 w-full max-w-md z-10 transform transition-all">
        <h3 class="text-lg font-semibold mb-4 text-gray-900">{{ category ? 'Modifica Categoria' : 'Nuova Categoria' }}</h3>

        <form @submit.prevent="save" class="space-y-4">

          <!-- Name -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Nome</label>
            <input v-model="form.name" type="text" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-light" placeholder="Es. Viaggi" />
          </div>

          <!-- Type -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Tipo</label>
            <SelectDropdown
              v-model="form.type"
              :items="movementTypes"
              itemLabel="label"
              placeholder="Seleziona tipo"
              :search-enabled="false"
              :clearable="false"
              class="w-full"
            />
          </div>

          <!-- Color -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Colore</label>
            <div class="flex items-center">
                <VSwatches
                v-model="form.color"
                :inline="isMobile"
                class="flex py-2 justify-center items-center"
              />
            </div>
          </div>

          <!-- Error -->
          <div v-if="error" class="text-red-500 text-sm">{{ error }}</div>

          <!-- Buttons -->
          <div class="flex flex-col-reverse sm:flex-row justify-end gap-3 mt-6">
            <button type="button" class="w-full sm:w-auto px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-md transition-colors cursor-pointer" @click="close">
              Annulla
            </button>
            <button type="submit" :disabled="loading" class="w-full sm:w-auto px-4 py-2 bg-primary hover:bg-primary-dark text-white rounded-md transition-colors cursor-pointer">
              {{ loading ? 'Salvataggio...' : 'Salva' }}
            </button>
          </div>

        </form>
      </div>
    </div>
  </Teleport>
</template>
