<script setup>
import { ref, watch, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'

import { onBeforeRouteLeave } from 'vue-router'
import { useFinancialsStore } from '@/stores/financials'
import ConfirmModal from '../../modals/ConfirmModal.vue'
import DatePicker from 'primevue/datepicker';
import SelectDropdown from '../../formcomponents/SelectDropdown.vue'
import InputError from '../../formcomponents/InputError.vue'

const props = defineProps({
  categorie: { type: Array, default: () => [] },
  conti: { type: Array, default: () => [] },
  currency: { type: String, default: '€' },
  currencyFormat: { type: String, default: 'it-IT' },
  currencySymbol: { type: String, default: 'EUR'},
  prefillMovement: { type: Object, default: null }
})



const form = ref({
  date: new Date(),
  amount: '',
  category: '', //id will be the value
  account: '', //id will be the value
  description: '',
  title: '',
  movementType: '' // 'income', 'expense', 'transfer'
})

const movementTypes = computed(() => financials.movementTypes)

const filteredCategories = computed(() => {
  if (!form.value.movementType) return []
  return (props.categorie || []).filter(c => c.tipo === form.value.movementType)
})

const validationError = ref('')
const isSubmitting = ref(false)
const originalFormState = ref('')
const financials = useFinancialsStore()

const datepickerRef = ref(null)  // ref del DatePicker
const showFutureWarning = ref(false) // new: briefly show UI warning when a future date is attempted

// money object to format currency input
const displayValue = ref('')

const formatter = computed(() => {
  try {
    return new Intl.NumberFormat(props.currencyFormat, {
      style: 'currency',
      currency: props.currencySymbol,
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })
  } catch (e) {
    // fallback
    return new Intl.NumberFormat('it-IT', {
      style: 'currency',
      currency: 'EUR',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })
  }
})

// derive decimal/group separators and currency symbol from formatToParts
const formatParts = computed(() => {
  try {
    return formatter.value.formatToParts(1234567.89)
  } catch (e) {
    return []
  }
})
const decimalSep = computed(() => formatParts.value.find(p => p.type === 'decimal')?.value || '.')
const groupSep = computed(() => formatParts.value.find(p => p.type === 'group')?.value || ',')
const currencySymbolStr = computed(() => formatParts.value.find(p => p.type === 'currency')?.value || props.currencySymbol)

const selectedCategoryName = ref('') // synced for hidden required input
const selectedAccountName = ref('')  // synced for hidden required input

// Custom Modal Navigation Logic
const showConfirmModal = ref(false)
let pendingNavigationNext = null

const isDirty = computed(() => {
  if (isSubmitting.value) return false
  return JSON.stringify(form.value) !== originalFormState.value
})

onBeforeRouteLeave((to, from, next) => {
  if (isDirty.value) {
    showConfirmModal.value = true
    pendingNavigationNext = next
  } else {
    next()
  }
})

function handleConfirmNavigation() {
  showConfirmModal.value = false
  if (pendingNavigationNext) pendingNavigationNext()
}

function handleCancelNavigation() {
  showConfirmModal.value = false
  if (pendingNavigationNext) pendingNavigationNext(false)
}


const resetForm = () => {
  form.value = {
    date: new Date(),
    amount: '',
    category: '', 
    account: '', 
    description: '',
    title: '',
    movementType: ''
  }

  displayValue.value = ''
}


// Determine if we are adding a new movement or modifying an existing one, check based on prefillMovement prop
const isNewMovement = computed(() => props.prefillMovement === null || props.prefillMovement.id === undefined);


// prefill from prop (preferred) or route query if provided
const route = useRoute()

function initPrefill() {
  const historyState = window.history.state;
  const storedMovement = financials.editingMovement;
  
  console.log("AddModifyCashFlow - Prop prefillMovement:", props.prefillMovement);
  console.log("AddModifyCashFlow - Store/Storage editingMovement:", storedMovement);
  
  if (route.query.new === '1') {
    financials.editingMovement = null;
    resetForm()
    return
  }

  const target = props.prefillMovement || storedMovement || historyState?.movement;
  if (target) {
    console.log("AddModifyCashFlow - Target found, applying prefill:", target);
    applyPrefill(target)
  } else {
    const payload = route.query?.data
    if (payload) {
      try {
        const raw = JSON.parse(decodeURIComponent(String(payload)))
        applyPrefill(raw)
      } catch (e) {
        console.warn('Invalid prefill data for AddModifyCashFlow', e)
      }
    }
  }
}

onMounted(() => {
  initPrefill()
})

// Watch for prop changes to re-apply prefill (handles async loading)
watch(() => props.prefillMovement, (newVal) => {
  if (newVal) applyPrefill(newVal)
}, { immediate: true })

// Watch for categories/accounts loading to re-apply prefill if necessary
watch([() => props.categorie, () => props.conti], () => {
  if (props.prefillMovement || route.query.data) {
    initPrefill()
  }
}, { deep: true })

// Capture original state for dirty check, but only after prefill settles
watch(form, () => {
  if (!originalFormState.value && !isSubmitting.value) {
     setTimeout(() => {
       if (!originalFormState.value) originalFormState.value = JSON.stringify(form.value)
     }, 800)
  }
}, { once: true })

function applyPrefill(raw) {
  if (!raw) return

  // 1. Date
  if (raw.data || raw.date) {
    const dateVal = raw.data || raw.date
    // Handle both YYYY-MM-DD (ISO) and DD/MM/YYYY (Italian)
    if (typeof dateVal === 'string' && dateVal.includes('/')) {
      const parts = dateVal.split('/')
      form.value.date = new Date(parts[2], parts[1] - 1, parts[0])
    } else {
      form.value.date = new Date(dateVal)
    }
  }

  // 2. Amount
  if (raw.importo !== undefined || raw.amount !== undefined) {
    const amt = raw.importo !== undefined ? raw.importo : raw.amount
    form.value.amount = Number(amt) || 0
    displayValue.value = formatter.value.format(form.value.amount)
  }

  // 3. Title & Description
  if (raw.titolo || raw.title) form.value.title = raw.titolo || raw.title
  if (raw.descrizione || raw.description) form.value.description = raw.descrizione || raw.description
  
  // 4. Category
  // We check both the nested object and the flattened property
  const catObj = raw.categoria || {};
  const catName = raw.category || catObj.nome || '';
  const catId = catObj.id || (typeof raw.category === 'number' ? raw.category : null);
  
  const isSystemName = (n) => n && String(n).toLowerCase().includes('riassociare');
  const isSystem = catObj.is_system || isSystemName(catName);

  if (catId || catName) {
    const found = (props.categorie || []).find(c => 
      (catId && String(c.id) === String(catId)) || 
      (catName && String(c.nome).toLowerCase() === String(catName).toLowerCase())
    );

    if (found) {
      if (!found.is_system && !isSystemName(found.nome)) {
        form.value.category = found.id;
        selectedCategoryName.value = found.nome;
      } else {
        // System category detected: reset to empty to force user classification
        form.value.category = '';
        selectedCategoryName.value = '';
      }
      form.value.movementType = found.tipo;
    } else {
      // Fallback if categories not yet loaded or not found in list
      if (!isSystem) {
        form.value.category = catId || catName;
        selectedCategoryName.value = catName || catId;
      } else {
        form.value.category = '';
        selectedCategoryName.value = '';
      }
    }
  }

  // Set movementType explicitly if available in raw
  if (raw.tipo) {
    form.value.movementType = raw.tipo;
  }

  // 5. Account
  const accObj = raw.conto || {};
  const accName = raw.account || accObj.nome || '';
  const accId = accObj.id || (typeof raw.account === 'number' ? raw.account : null);
  const isAccSystem = accObj.is_system || isSystemName(accName);

  if (accId || accName) {
    const found = (props.conti || []).find(c => 
      (accId && String(c.id) === String(accId)) || 
      (accName && String(c.nome).toLowerCase() === String(accName).toLowerCase())
    );

    if (found) {
      if (!found.is_system && !isSystemName(found.nome)) {
        form.value.account = found.id;
        selectedAccountName.value = found.nome;
      } else {
        form.value.account = '';
        selectedAccountName.value = '';
      }
    } else {
      if (!isAccSystem) {
        form.value.account = accId || accName;
        selectedAccountName.value = accName || accId;
      } else {
        form.value.account = '';
        selectedAccountName.value = '';
      }
    }
  }

  // 6. ID for update
  if (raw.id) form.value.id = raw.id
}




function openDatePicker() {
  datepickerRef.value?.$el?.querySelector('input')?.focus();
}




// helper to escape regex special chars
const _escapeRegex = (s = '') => s.replace(/[-/\\^$*+?.()|[\]{}]/g, '\\$&')

// on focus: normalize the displayed string to a plain numeric string
const onFocus = () => {
  if (displayValue.value !== '') {
    let v = String(displayValue.value)
  
    // remove currency symbol occurrences
    const sym = currencySymbolStr.value
    if (sym) {
      v = v.replace(new RegExp(_escapeRegex(sym), 'g'), '')
    }

    // remove spaces and NBSP
    v = v.replace(/\s+/g, '')

    // remove group separators (only if different from decimal separator)
    if (groupSep.value && groupSep.value !== decimalSep.value) {
      v = v.split(groupSep.value).join('')
    } else {
      // common fallback: remove dots used as thousands sep
      v = v.replace(/\./g, '')
    }

    // replace locale decimal separator with '.' for JS parseFloat
    if (decimalSep.value && decimalSep.value !== '.') {
      v = v.split(decimalSep.value).join('.')
    }

    // Normalize numeric display: if number is integer show "12" not "12.00"
    const parsed = parseFloat(v)
    if (!isNaN(parsed)) {
      if (Number.isInteger(parsed)) {
        displayValue.value = String(Math.trunc(parsed))
      } else {
        // keep minimal decimal representation (remove trailing zeros)
        // toLocaleString can reintroduce locale separators; keep plain JS string
        let s = String(parsed)
        // ensure dot as decimal separator in edit mode
        if (s.indexOf('.') > -1) {
          // trim trailing zeros
          s = s.replace(/(\.\d*?[1-9])0+$/,'$1')
          // if becomes "12." remove dot
          s = s.replace(/\.0+$/,'')
        }
        displayValue.value = s
      }
    } else {
      displayValue.value = v
    }
  }
}

const showNumericError = ref(false)
const showDecimalError = ref(false)
const showLimitError = ref(false)
const showZeroError = ref(false)
const shakeTitle = ref(false)
const shakeDescription = ref(false)
const shakeAmount = ref(false)

function triggerShake(type) {
  if (type === 'title') shakeTitle.value = true
  if (type === 'description') shakeDescription.value = true
  if (type === 'amount') shakeAmount.value = true
  
  setTimeout(() => {
    if (type === 'title') shakeTitle.value = false
    if (type === 'description') shakeDescription.value = false
    if (type === 'amount') shakeAmount.value = false
  }, 300)
}

function onAmountInput(e) {
  const original = e.target.value
  let normalized = original.replace(',', '.')
  
  // Detect invalid characters (anything not 0-9 or dot)
  const hasInvalidChars = /[^0-9.]/.test(normalized)
  // Detect multiple dots
  const dotsCount = (normalized.match(/\./g) || []).length
  const hasMultipleDots = dotsCount > 1

  // Detect too many decimal places (limit to 4)
  const decimalPart = normalized.split('.')[1]
  const hasTooManyDecimals = decimalPart && decimalPart.length > 4

  // Detect amount too large (limit to 10M)
  const parsed = parseFloat(normalized)
  const isTooLarge = !isNaN(parsed) && parsed > 10000000

  if (hasInvalidChars || hasMultipleDots || hasTooManyDecimals || isTooLarge) {
    showNumericError.value = hasInvalidChars || hasMultipleDots
    showDecimalError.value = hasTooManyDecimals
    showLimitError.value = isTooLarge
    triggerShake('amount')
    // Revert the input field value to the last valid state
    e.target.value = displayValue.value
  } else {
    showNumericError.value = false
    showDecimalError.value = false
    showLimitError.value = false
    displayValue.value = normalized

    if (!isNaN(parsed)) {
      showZeroError.value = (parsed <= 0)
      form.value.amount = parsed
    } else {
      form.value.amount = ''
      showZeroError.value = false
    }
  }
}

const onBlur = () => {
  const num = parseFloat(String(displayValue.value).replace(/\s+/g, ''))
  if (!isNaN(num)) {
    form.value.amount = num
    displayValue.value = formatter.value.format(num)
  } else {
    displayValue.value = ''
    form.value.amount = ''
  }
}







// handlers for SelectDropdown events
function onCategorySelect(cat) {
  // cat is the full item object
  selectedCategoryName.value = cat.nome || ''
  form.value.category = cat.id || cat.nome
  
  // if title is empty, derive it from the selected category
  if (!form.value.title || form.value.title.trim() === '') {
    form.value.title = cat.nome || ''
  }
}

function onCategoryClear() {
  if (form.value.title === selectedCategoryName.value) {
    form.value.title = ''
  }
  selectedCategoryName.value = ''
  form.value.category = ''
}

function onAccountSelect(acc) {
  selectedAccountName.value = acc.nome || ''
  form.value.account = acc.id || acc.nome
}

function onAccountClear() {
  selectedAccountName.value = ''
  form.value.account = ''
}





// Emit event on submission
const emit = defineEmits(['submit', 'newCategoryCreated', 'newAccountCreated'])

function submitForm() {
  validationError.value = ''

  if (!form.value.movementType) {
    validationError.value = 'Seleziona prima il tipo di movimento'
    return
  }

  // 1. Trim strings
  form.value.title = form.value.title.trim()
  form.value.description = form.value.description.trim()

  if (!form.value.amount && form.value.amount !== 0) {
    validationError.value = 'Inserisci un importo valido'
    triggerShake('amount')
    return
  }
  // 3. Zero/Negative amount check
  if (form.value.amount <= 0) {
    showZeroError.value = true
    triggerShake('amount')
    return
  }
  showZeroError.value = false
  if (form.value.amount > 10000000) {
    validationError.value = 'L\'importo massimo consentito è 10.000.000'
    triggerShake('amount')
    return
  }
  if (!form.value.category) {
    validationError.value = 'Seleziona una categoria'
    return
  }

  if (!form.value.title) {
    form.value.title = selectedCategoryName.value || 'Nuovo Movimento'
  }
  if (!form.value.account) {
    validationError.value = 'Seleziona un conto'
    return
  }

  if (form.value.date) {
    const sel = new Date(form.value.date)
    sel.setHours(0,0,0,0)
    if (sel > today) {
      form.value.date = new Date(today)
      showFutureWarning.value = true
      setTimeout(() => (showFutureWarning.value = false), 3000)
      return
    }
  }

  // 2. Disable submit during loading
  isSubmitting.value = true

  emit('submit', { 
    ...form.value, 
    type: isNewMovement.value ? 'add' : 'edit',
  })
  
  // Note: we don't reset isSubmitting here because the parent usually navigates away
  // If there's an error, the parent would need to handle it or we'd need a prop.
  // For now, we'll keep it simple.
}







const formattedDate = computed(() => {
  if (!form.value.date) return ''
  const d = new Date(form.value.date)
  const yyyy = d.getFullYear()
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const dd = String(d.getDate()).padStart(2, '0')
  return `${yyyy}-${mm}-${dd}`
})


// Add a normalized "today" (midnight) for comparisons and DatePicker max binding
const today = new Date()
today.setHours(0,0,0,0)



// Watch and clamp form.date if user picks or types a future date
watch(() => form.value.date, (newDate) => {
  if (!newDate) return
  const d = new Date(newDate)
  d.setHours(0,0,0,0)
  if (d > today) {
    // clamp to today and show a brief warning
    form.value.date = new Date(today)
    showFutureWarning.value = true
    setTimeout(() => (showFutureWarning.value = false), 3000)
  }
})

// Reset category if it doesn't match the selected type
watch(() => form.value.movementType, (newType) => {
  if (!newType) {
    form.value.category = ''
    selectedCategoryName.value = ''
    return
  }
  
  // If we have a category, check if its type matches
  if (form.value.category) {
    const cat = (props.categorie || []).find(c => String(c.id) === String(form.value.category))
    if (cat && cat.tipo !== newType) {
      form.value.category = ''
      selectedCategoryName.value = ''
    }
  }
})

function setMovementType(type) {
  form.value.movementType = type
  if (validationError.value.includes('tipo')) {
    validationError.value = ''
  }
}

// keep selectedCategoryName in sync if parent sets form.category directly
watch(() => form.value.category, (val) => {
  if (!val) {
    selectedCategoryName.value = ''
    return
  }
  const found = (props.categorie || []).find(c => String(c.id) === String(val))
  if (found) selectedCategoryName.value = found.nome || ''
})


//reset form when route changes with new=1 query param
watch(
  () => route.fullPath,
  (newVal, oldVal) => {
    const wasNew = oldVal.includes("?new=1")
    const isNew = newVal.includes("?new=1")

    if (!wasNew && isNew) {
      resetForm()
    }
  }
)

</script>

<template>
        <section class="flex-1 h-full justify-center overflow-auto">
            <div class = "flex flex-col p-4 gap-4 bg-white mt-10 mb-20 md:mb-6 rounded-[10px] min-h-40 shadow-sm">
                    <div class="flex items-center gap-2">
                        <i class="pi pi-plus-circle text-primary text-xl" />
                        <h2 class="text-xl font-bold text-text">{{ isNewMovement ? 'Aggiungi Movimento' : 'Modifica Movimento' }}</h2>
                    </div>

                    <!-- wrap fields in a native form to enable browser required validation -->
                    <form @submit.prevent="submitForm" class="flex flex-col gap-4">
                      <!-- off-screen inputs used to enforce required validation for custom controls -->
                      <input type="text" :value="formattedDate" aria-hidden="true"
                             style="position:absolute; left:-9999px; width:1px; height:1px; overflow:hidden;"/>
                      <input type="text" v-model="selectedCategoryName" aria-hidden="true"
                             style="position:absolute; left:-9999px; width:1px; height:1px; overflow:hidden;"/>
                      <input type="text" v-model="selectedAccountName" aria-hidden="true"
                             style="position:absolute; left:-9999px; width:1px; height:1px; overflow:hidden;"/>

                    <div class="flex flex-col gap-1">
                        <label class="text-sm font-semibold text-text text-center md:text-left">Data</label>
                            <button @click="openDatePicker" type="button" class="w-full border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-light text-left cursor-pointer">
                                <div class="relative max-w-80">
                                    <DatePicker
                                        ref="datepickerRef"
                                        v-model="form.date"
                                        :maxDate="today"
                                        append-to="body"
                                        dateFormat="dd/mm/yy"
                                        input-class="w-full px-3 py-2 focus:outline-none"
                                        :pt="{
                                            panel: 'flex-1 bg-white shadow-md border border-gray-200 rounded-xl p-3 mt-4',
                                            header: 'flex justify-between items-center text-text mb-2',
                                            title: 'text-md flex items-center gap-1',
                                            prevbutton: 'text-gray-500 hover:text-primary hover:bg-gray-100 rounded p-1 transition',
                                            nextbutton: 'text-gray-500 hover:text-primary hover:bg-gray-100 rounded p-1 transition',
                                            month: 'flex-1 px-2 py-1 hover:bg-primary hover:text-white rounded cursor-pointer transition m-4',
                                            monthSelected: 'bg-primary text-white font-bold rounded',
                                            year: 'flex-1 px-2 py-1 hover:bg-primary hover:text-white rounded cursor-pointer transition m-4',
                                            yearSelected: 'bg-primary text-white font-bold rounded',
                                            day: ({ context }) => [
                                                'w-10.5 h-9 flex items-center justify-center text-sm rounded cursor-pointer transition',
                                                
                                                { 
                                                    'hover:bg-primary-light hover:text-white': !context.selected && !context.disabled && !context.dayOtherMonth,
                                                    'text-gray-500 cursor-not-allowed': context.dayOtherMonth,
                                                    'border border-primary text-primary font-semibold bg-primary/20': context.dayToday && !context.selected,
                                                    'bg-primary-light text-white font-bold rounded-full hover:bg-primary': context.selected,
                                                    'text-gray-300 cursor-not-allowed opacity-50': context.disabled && !context.dayOtherMonth
                                                }
                                            ],
                                        }"
                                        />
                                 </div>

                                <!-- warning shown when user attempts to pick a future date -->
                                <InputError 
                                  :message="showFutureWarning ? 'Non è possibile selezionare una data futura — impostata la data di oggi.' : ''"
                                  type="error"
                                  :animate="true"
                                />

                            </button>
                    </div>




                    <div class="flex flex-col gap-1">
                    <label class="text-sm font-semibold text-text text-center md:text-left">Importo ({{ props.currency }})</label>
                    <input
                      type="text"
                      :value="displayValue"
                      @input="onAmountInput"
                      @focus="onFocus"
                      @blur="onBlur"
                      inputmode="decimal"
                      placeholder="0.00 (max 10M)"
                      :class="[
                        'px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-light transition-all',
                        { 'text-red-600 border-red-300 bg-red-50': form.amount > 10000000 || showZeroError },
                        { 'animate-shake border-red-400': shakeAmount }
                      ]"
                    />
                    <div class="flex flex-col mt-1">
                      <InputError :message="showNumericError ? 'Sono consentiti solo numeri e un separatore decimale' : ''" type="warning" />
                      <InputError :message="showDecimalError ? 'Massimo 4 cifre decimali consentite' : ''" type="warning" />
                      <InputError :message="showZeroError ? 'L\'importo deve essere maggiore di zero' : ''" />
                      <InputError :message="showLimitError ? 'Limite massimo di 10M superato!' : ''" />
                      <span class="text-[10px] text-gray-500 mt-0.5">Usa il punto (.) o la virgola (,) per i decimali.</span>
                    </div>
                    </div>

                    <div class="flex flex-col gap-1">
                      <label class="text-sm font-semibold text-text text-center md:text-left">Tipo Movimento</label>
                      
                      <!-- Mobile: Buttons -->
                      <div class="flex gap-2 md:hidden">
                        <button 
                          v-for="type in movementTypes"
                          :key="type.id"
                          type="button" 
                          @click="setMovementType(type.id)"
                          :class="[
                            'flex-1 py-2 px-4 rounded-md border transition-all text-sm font-medium cursor-pointer',
                            form.movementType === type.id 
                              ? `${type.bgClass} text-white ${type.borderClass} shadow-sm` 
                              : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
                          ]"
                        >
                          {{ type.label }}
                        </button>
                      </div>

                      <!-- Desktop: Dropdown -->
                      <div class="hidden md:block">
                        <SelectDropdown
                          :items="movementTypes"
                          v-model="form.movementType"
                          itemLabel="label"
                          placeholder="Seleziona tipo movimento"
                          :searchEnabled="false"
                          :clearable="false"
                          :showColor="true"
                          @select="(val) => setMovementType(val.id)"
                        />
                      </div>
                    </div>

                    <div class="flex flex-col gap-1">
                      <label class="text-sm font-semibold text-text text-center md:text-left">Categoria</label>
                      <div class="relative group">
                        <SelectDropdown
                          :items="filteredCategories"
                          v-model="form.category"
                          itemLabel="nome"
                          :showColor="true"
                          :placeholder="!form.movementType ? 'Seleziona prima il tipo di movimento (Es. Uscita, Entrata, Giroconto)' : 'Seleziona categoria'"
                          @select="onCategorySelect"
                          @clear="onCategoryClear"
                          :required="true"
                          :allowCreateCategory="true"
                          :initialType="form.movementType"
                          :disabled="!form.movementType"
                          @item-created="(c) => emit('newCategoryCreated', c)"
                        />
                        <div v-if="!form.movementType" class="absolute inset-0 z-10 cursor-not-allowed" @click="validationError = 'Seleziona prima il tipo di movimento'"></div>
                      </div>
                      <InputError 
                        :message="validationError === 'Seleziona prima il tipo di movimento' ? 'Per favore, seleziona prima se è una Spesa, un\'Entrata o un Giroconto' : ''" 
                        :animate="true"
                      />
                      <InputError :message="validationError === 'Seleziona una categoria' ? 'Seleziona una categoria' : ''" />
                    </div>

                    <div class="flex flex-col gap-1">
                      <label class="text-sm font-semibold text-text text-center md:text-left">Conto</label>
                      <SelectDropdown
                        :items="props.conti"
                        v-model="form.account"
                        itemLabel="nome"
                        placeholder="Seleziona conto"
                        :showColor="true"
                        @select="onAccountSelect"
                        @clear="onAccountClear"
                        :required="true"
                        :allowCreateAccount="true"
                        @item-created="(a) => emit('newAccountCreated', a)"
                      />
                      <InputError :message="validationError === 'Seleziona un conto' ? 'Seleziona un conto' : ''" />
                    </div>

                    <div class="flex flex-col gap-1">
                      <label class="text-sm font-semibold text-text text-center md:text-left flex items-center gap-2">
                        Titolo
                        <span :class="['text-[10px] font-normal transition-colors', form.title.length >= 50 ? 'text-red-500 font-bold' : 'text-gray-400']">
                          ({{ form.title.length }}/50)
                          <span v-if="form.title.length >= 50"> - Limite raggiunto!</span>
                        </span>
                      </label>
                      <input
                          v-model="form.title"
                          maxlength="50"
                          type="text"
                          @keydown="(e) => { if (form.title.length >= 50 && e.key.length === 1) triggerShake('title') }"
                          placeholder="es. Acquisto Libri (opzionale, se vuoto verrà derivato dalla categoria)"
                          :class="[
                            'px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-light transition-all',
                            { 'animate-shake border-red-400': shakeTitle }
                          ]"
                      />
                    </div>

                    <div class="flex flex-col gap-1">
                    <label class="text-sm font-semibold text-text text-center md:text-left flex items-center gap-2">
                      Descrizione
                      <span :class="['text-[10px] font-normal transition-colors', form.description.length >= 200 ? 'text-red-500 font-bold' : 'text-gray-400']">
                        ({{ form.description.length }}/200)
                        <span v-if="form.description.length >= 200"> - Limite raggiunto!</span>
                      </span>
                    </label>
                    <textarea
                        v-model="form.description"
                        maxlength="200"
                        rows="3"
                        @keydown="(e) => { if (form.description.length >= 200 && e.key.length === 1) triggerShake('description') }"
                        placeholder="Aggiungi dettagli (opzionale)..."
                        :class="[
                            'px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-light transition-all',
                            { 'animate-shake border-red-400': shakeDescription }
                        ]"
                    ></textarea>
                    </div>

                    <div v-if="validationError && !['Seleziona prima il tipo di movimento', 'Seleziona una categoria', 'Seleziona un conto'].includes(validationError)" class="bg-red-50 text-red-600 p-3 rounded-md text-sm font-medium border border-red-100">
                      {{ validationError }}
                    </div>

                    <button
                      type="submit"
                      :disabled="isSubmitting"
                      :class="[
                        'flex items-center justify-center gap-2 px-4 py-2 rounded-md transition duration-300',
                        isSubmitting ? 'bg-gray-400 cursor-not-allowed' : 'bg-primary-light text-white hover:bg-primary cursor-pointer'
                      ]"
                    >
                      <template v-if="isSubmitting">
                        <svg class="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        Salvataggio...
                      </template>
                      <template v-else>
                        <i class="pi pi-check text-lg" />
                        Salva Movimento
                      </template>
                    </button>

                    </form>
            </div>
        </section>

        <!-- Custom Confirm Modal -->
        <ConfirmModal 
          :show="showConfirmModal"
          title="Modifiche non salvate"
          message="Hai inserito dei dati che non sono ancora stati salvati. Se esci ora, perderai queste modifiche. Vuoi davvero procedere?"
          confirmText="Sì, esci"
          cancelText="No, resta qui"
          type="warning"
          @confirm="handleConfirmNavigation"
          @cancel="handleCancelNavigation"
        />
</template>

<style scoped>
@keyframes shake {
  0%, 100% { transform: translateX(0); }
  25% { transform: translateX(-5px); }
  50% { transform: translateX(5px); }
  75% { transform: translateX(-5px); }
}

.animate-shake {
  animation: shake 0.2s ease-in-out;
}
</style>
