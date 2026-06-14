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
    <div v-if="isOpen" class="fixed inset-0 z-[9999] flex items-center justify-center p-4 transition-all duration-300">
      <div class="absolute inset-0 bg-background/80 backdrop-blur-xl transition-opacity" @click="close"></div>
      <div class="relative bg-card-background rounded-3xl shadow-2xl p-8 w-full max-w-md z-10 border border-menuborder hover:border-primary/20 transition-all duration-300 animate-fade-in-up">
        <h3 class="text-xl font-bold mb-6 text-text uppercase tracking-widest font-sans animate-tracking-in">{{ category ? 'Modifica Categoria' : 'Nuova Categoria' }}</h3>

        <form @submit.prevent="save" class="space-y-5 animate-fade-in-delayed">

          <!-- Name -->
          <div class="space-y-1.5">
            <label class="block text-text font-semibold text-xs uppercase tracking-wider mb-1 font-sans">Nome</label>
            <input v-model="form.name" type="text" class="w-full px-4 py-3 rounded-xl border border-neutral/30 bg-primary-clear text-text placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent transition-all font-sans" placeholder="Es. Viaggi" />
          </div>

          <!-- Type -->
          <div class="space-y-1.5">
            <label class="block text-text font-semibold text-xs uppercase tracking-wider mb-1 font-sans">Tipo</label>
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
          <div class="space-y-1.5">
            <label class="block text-text font-semibold text-xs uppercase tracking-wider mb-1 font-sans">Colore</label>
            <div class="flex items-center">
                <VSwatches
                v-model="form.color"
                :inline="isMobile"
                class="flex py-2 justify-center items-center"
              />
            </div>
          </div>

          <!-- Error -->
          <transition name="fade">
            <div v-if="error" class="bg-red-50 border border-red-200 text-red-600 rounded-xl p-3.5 text-xs font-semibold flex items-center gap-2.5 animate-shake">
                <i class="pi pi-exclamation-circle text-base"></i>
                <span class="font-sans">{{ error }}</span>
            </div>
          </transition>

          <!-- Buttons -->
          <div class="flex flex-col-reverse sm:flex-row justify-end gap-3 mt-8">
            <button type="button" class="w-full sm:w-auto px-5 py-2.5 bg-neutral/30 hover:bg-neutral/50 text-text rounded-xl transition-colors font-bold cursor-pointer font-sans" @click="close">
              Annulla
            </button>
            <button type="submit" :disabled="loading" class="w-full sm:w-auto px-5 py-2.5 bg-primary hover:bg-primary-hover active:scale-[0.98] shadow-md shadow-primary/10 text-white rounded-xl transition-all font-bold cursor-pointer font-sans">
              {{ loading ? 'Salvataggio...' : 'Salva' }}
            </button>
          </div>

        </form>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
@keyframes shake {
  0%, 100% { transform: translateX(0); }
  20%, 60% { transform: translateX(-4px); }
  40%, 80% { transform: translateX(4px); }
}

.animate-shake {
  animation: shake 0.4s ease-in-out;
}

@keyframes tracking-in-expand {
  0% {
    letter-spacing: -0.05em;
    filter: blur(6px);
    opacity: 0;
  }
  100% {
    letter-spacing: 0.1em;
    filter: blur(0);
    opacity: 1;
  }
}

.animate-tracking-in {
  animation: tracking-in-expand 0.8s cubic-bezier(0.25, 1, 0.5, 1) forwards;
}

@keyframes fade-in-up {
  from {
    opacity: 0;
    transform: translateY(12px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fade-in-up {
  animation: fade-in-up 0.7s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
}

.animate-fade-in-delayed {
  opacity: 0;
  animation: fade-in 0.8s ease forwards;
  animation-delay: 0.25s;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
