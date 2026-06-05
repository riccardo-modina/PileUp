<script setup>
import { ref, watch, nextTick } from 'vue'

import ConfirmModal from '../../modals/ConfirmModal.vue'
import SelectDropdown from '../../formcomponents/addform/SelectDropdown.vue'
import InputError from '../../formcomponents/addform/InputError.vue'
import DateSelector from '../../formcomponents/dateselector/DateSelector.vue'

// Import form composables
import { useFormControls } from '@/composables/forms/useFormControls'
import { useCurrencyInput } from '@/composables/forms/useCurrencyInput'
import { useCashflowFormControls } from '@/composables/forms/useCashflowFormControls'

const props = defineProps({
  categorie: { type: Array, default: () => [] },
  conti: { type: Array, default: () => [] },
  currency: { type: String, default: '€' },
  currencyFormat: { type: String, default: 'it-IT' },
  currencySymbol: { type: String, default: 'EUR'},
  prefillMovement: { type: Object, default: null }
})

const emit = defineEmits(['submit', 'newCategoryCreated', 'newAccountCreated'])

// Presentation UI Shaking Effects refs
const amountInputRef = ref(null)
const shakeAmount = ref(false)

const triggerShakeAmount = () => {
  shakeAmount.value = true
  setTimeout(() => (shakeAmount.value = false), 300)
}

// 1. Currency Formatting Composable
const formAmount = ref('')
const {
  displayValue,
  showNumericError,
  showDecimalError,
  showLimitError,
  showZeroError,
  onFocus,
  onBlur,
  onAmountInput,
  setDisplayValue,
  clearDisplayValue
} = useCurrencyInput({
  amountRef: formAmount,
  currencyFormat: props.currencyFormat,
  currencySymbol: props.currencySymbol,
  onInvalidInput: triggerShakeAmount
})

// 2. Cashflow Form Controls Composable
const {
  form,
  activeStep,
  validationError,
  isSubmitting,
  originalFormState,
  showFutureWarning,
  selectedCategoryName,
  selectedAccountName,
  movementTypes,
  filteredCategories,
  titlePlaceholder,
  isNewMovement,
  isCard1Valid,
  isCard2Valid,
  isCard3Valid,
  setMovementType,
  onCategorySelect,
  onCategoryClear,
  onAccountSelect,
  onAccountClear,
  submitForm: originalSubmitForm,
  humanReadableDate,
  formattedDate
} = useCashflowFormControls(props, emit, {
  setAmountDisplayValue: setDisplayValue,
  clearAmountDisplayValue: clearDisplayValue
})

// Sync the local raw amount with the composable's form.amount
watch(formAmount, (newVal) => {
  form.value.amount = newVal
})
watch(() => form.value.amount, (newVal) => {
  if (newVal === '') {
    formAmount.value = ''
    clearDisplayValue()
  } else if (formAmount.value !== newVal) {
    formAmount.value = newVal
    setDisplayValue(newVal)
  }
})

// 3. Routing Guard Composable
const {
  showConfirmModal,
  handleConfirmNavigation,
  handleCancelNavigation
} = useFormControls(form, originalFormState)

// Input UI Element DOM references
const titleInputRef = ref(null)
const notesInputRef = ref(null)

const shakeTitle = ref(false)
const shakeDescription = ref(false)

function triggerShake(type) {
  if (type === 'title') shakeTitle.value = true
  if (type === 'description') shakeDescription.value = true
  
  setTimeout(() => {
    if (type === 'title') shakeTitle.value = false
    if (type === 'description') shakeDescription.value = false
  }, 300)
}

// Wrapper around submission to trigger amount shake if validation fails on amount
function submitForm() {
  originalSubmitForm()
  if (validationError.value) {
    if (validationError.value.includes('importo') || validationError.value.includes('valido')) {
      triggerShakeAmount()
    }
  }
}

// Stepper Step completion transition handlers (with focus management)
function handleStep1Completion() {
  if (isCard1Valid.value) {
    activeStep.value = 2
    setTimeout(() => {
      amountInputRef.value?.focus()
    }, 50)
  }
}

function handleStep2Completion() {
  if (isCard2Valid.value) {
    activeStep.value = 3
    setTimeout(() => {
      titleInputRef.value?.focus()
    }, 50)
  }
}

function handleStep3Completion() {
  if (isCard3Valid.value) {
    setTimeout(() => {
      notesInputRef.value?.focus()
    }, 50)
  }
}

function handleCategorySelect(cat) {
  onCategorySelect(cat)
  if (isCard1Valid.value) {
    activeStep.value = 2
    setTimeout(() => {
      amountInputRef.value?.focus()
    }, 50)
  }
}
</script>

<template>
        <div class="w-full flex justify-center px-1">
            <div class="flex flex-col gap-4 mt-6 mb-10 md:mb-6 max-w-xl w-full">
                    <div class="flex flex-col gap-1 pb-2 px-1">
                        <div class="flex items-center gap-2">
                            <i class="pi pi-plus-circle text-primary text-xl" />
                            <h2 class="text-xl font-bold text-text">{{ isNewMovement ? 'Aggiungi Movimento' : 'Modifica Movimento' }}</h2>
                        </div>
                        <p class="text-xs text-gray-500">Registra una nuova entrata o spesa</p>
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
                      
                      <!-- SINGLE UNIFIED CARD WITH TIMELINE STEPPER -->
                      <div class="bg-white rounded-3xl border border-gray-100 shadow-md p-4 sm:p-6 md:p-8 relative">
                                                <!-- Stepper flex container (no absolute timeline on card parent) -->
                         <div class="flex flex-col gap-6 sm:gap-10 relative">

                           <!-- Horizontal Stepper for Mobile (visible only on mobile) -->
                           <div class="sticky top-0 bg-white flex sm:hidden items-center justify-between px-6 py-4 border-b border-gray-100 z-40 -mx-4 -mt-4 rounded-t-3xl shadow-xs">
                             <!-- Step 1 Badge -->
                             <div 
                               class="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold transition-all duration-300 border-2 flex-shrink-0"
                               :class="[
                                 isCard1Valid 
                                   ? 'bg-green-500 text-white border-green-500 shadow-sm' 
                                   : activeStep === 1 
                                     ? 'bg-primary text-white border-primary shadow-md scale-110' 
                                     : 'bg-white text-gray-400 border-gray-200',
                                 activeStep === 1 && isCard1Valid ? 'scale-110' : ''
                               ]"
                             >
                               <i v-if="isCard1Valid" class="pi pi-check text-[10px]" />
                               <span v-else>1</span>
                             </div>

                             <!-- Line 1-2 -->
                             <div class="h-0.5 flex-1 mx-3 bg-gray-100 rounded-full">
                               <div 
                                 class="h-full bg-primary transition-all duration-500 rounded-full" 
                                 :style="{ width: isCard1Valid ? '100%' : '0%' }"
                               ></div>
                             </div>

                             <!-- Step 2 Badge -->
                             <div 
                               class="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold transition-all duration-300 border-2 flex-shrink-0"
                               :class="[
                                 isCard2Valid 
                                   ? 'bg-green-500 text-white border-green-500 shadow-sm' 
                                   : activeStep === 2 
                                     ? 'bg-primary text-white border-primary shadow-md scale-110' 
                                     : 'bg-white text-gray-400 border-gray-200',
                                 activeStep === 2 && isCard2Valid ? 'scale-110' : ''
                               ]"
                             >
                               <i v-if="isCard2Valid" class="pi pi-check text-[10px]" />
                               <span v-else>2</span>
                             </div>

                             <!-- Line 2-3 -->
                             <div class="h-0.5 flex-1 mx-3 bg-gray-100 rounded-full">
                               <div 
                                 class="h-full bg-primary transition-all duration-500 rounded-full" 
                                 :style="{ width: isCard2Valid ? '100%' : '0%' }"
                               ></div>
                             </div>

                             <!-- Step 3 Badge -->
                             <div 
                               class="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold transition-all duration-300 border-2 flex-shrink-0"
                               :class="[
                                 isCard3Valid 
                                   ? 'bg-green-500 text-white border-green-500 shadow-sm' 
                                   : activeStep === 3 
                                     ? 'bg-primary text-white border-primary shadow-md scale-110' 
                                     : 'bg-white text-gray-400 border-gray-200',
                                 activeStep === 3 && isCard3Valid ? 'scale-110' : ''
                               ]"
                             >
                               <i v-if="isCard3Valid" class="pi pi-check text-[10px]" />
                               <span v-else>3</span>
                             </div>
                           </div>

                           <!-- STEP 1: Movimento -->
                          <div 
                            class="flex gap-3 sm:gap-6 relative transition-all duration-300"
                            :class="[activeStep === 1 ? 'z-30' : 'z-10']"
                          >
                            
                            <!-- Left Column: Badge and Timeline Line -->
                            <div class="hidden sm:flex flex-col items-center relative w-6 sm:w-8 flex-shrink-0 z-10">
                              <!-- Badge -->
                              <div 
                                class="w-6 h-6 sm:w-8 sm:h-8 rounded-full flex items-center justify-center text-xs sm:text-sm font-bold transition-all duration-300 border-2 z-20"
                                :class="[
                                  isCard1Valid 
                                    ? 'bg-green-500 text-white border-green-500 shadow-sm' 
                                    : activeStep === 1 
                                      ? 'bg-primary text-white border-primary shadow-md' 
                                      : 'bg-white text-gray-400 border-gray-200'
                                ]"
                              >
                                <i v-if="isCard1Valid" class="pi pi-check text-xs" />
                                <span v-else>1</span>
                              </div>
                              <!-- Line Segment 1 (Connecting to Step 2) -->
                              <div class="w-0.5 bg-gray-100 absolute left-1/2 -translate-x-1/2 top-6 sm:top-8 bottom-[-40px] z-0">
                                <div 
                                  class="w-full bg-primary transition-all duration-500 rounded-full" 
                                  :style="{ height: isCard1Valid ? '100%' : '0%' }"
                                ></div>
                              </div>
                            </div>

                            <!-- Right Column: Content -->
                            <div 
                              class="flex-1 flex flex-col gap-5 transition-all duration-300 p-4 sm:p-5 rounded-2xl border"
                              :class="[
                                activeStep === 1 
                                  ? 'bg-primary/5 border-primary/10 opacity-100 scale-[1.005]' 
                                  : 'bg-transparent border-transparent opacity-60 hover:opacity-85'
                              ]"
                              @click="activeStep = 1"
                            >
                              <h3 class="text-base font-bold text-text h-8 flex items-center">
                                <span class="sm:hidden mr-1">1.</span>Tipo movimento
                              </h3>
                              
                              <!-- 1. Tipo Movimento -->
                              <div class="flex flex-col gap-3">
                                
                                <!-- Mobile: Buttons -->
                                <div class="flex gap-1.5 md:hidden mt-1">
                                  <button 
                                    v-for="type in movementTypes"
                                    :key="type.id"
                                    type="button" 
                                    @click="() => { setMovementType(type.id); handleStep1Completion(); }"
                                    :class="[
                                      'flex-1 py-2 px-1 rounded-xl border transition-all text-xs sm:text-sm font-semibold cursor-pointer flex items-center justify-center gap-1',
                                      form.movementType === type.id 
                                        ? type.id === 'entrata'
                                          ? 'bg-green-50 text-green-700 border-green-200 shadow-sm scale-[1.02]'
                                          : type.id === 'uscita'
                                            ? 'bg-red-50 text-red-700 border-red-200 shadow-sm scale-[1.02]'
                                            : 'bg-indigo-50 text-indigo-700 border-indigo-200 shadow-sm scale-[1.02]'
                                        : 'bg-white text-gray-500 border-gray-100 hover:bg-gray-50'
                                    ]"
                                  >
                                    <i :class="[
                                      'pi text-[10px] sm:text-xs',
                                      type.id === 'entrata' ? 'pi-arrow-down-left' : type.id === 'uscita' ? 'pi-arrow-up-right' : 'pi-sync'
                                    ]" />
                                    {{ type.label }}
                                  </button>
                                </div>

                                <!-- Desktop: Dropdown -->
                                <div class="hidden md:block" @focusin="activeStep = 1">
                                  <SelectDropdown
                                    :items="movementTypes"
                                    v-model="form.movementType"
                                    itemLabel="label"
                                    placeholder="Seleziona tipo movimento"
                                    :searchEnabled="false"
                                    :clearable="false"
                                    :showColor="true"
                                    @select="(val) => { setMovementType(val.id); handleStep1Completion(); }"
                                  />
                                </div>
                              </div>

                              <!-- Divisore -->
                              <div class="h-px bg-gray-100 w-full"></div>

                              <!-- 2. Categoria -->
                              <div class="flex flex-col gap-3">
                                <div class="flex items-center gap-3">
                                  <div class="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary">
                                    <i class="pi pi-tag text-sm sm:text-lg" />
                                  </div>
                                  <span class="text-sm font-semibold text-text">Categoria</span>
                                </div>
                                <div class="relative group mt-1" @focusin="activeStep = 1">
                                  <SelectDropdown
                                    :items="filteredCategories"
                                    v-model="form.category"
                                    itemLabel="nome"
                                    :showColor="true"
                                    :placeholder="!form.movementType ? 'Scegli prima il tipo di movimento' : 'Seleziona categoria'"
                                    @select="handleCategorySelect"
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
                            </div>
                          </div>

                           <!-- STEP 2: Importo -->
                           <div 
                             class="flex gap-3 sm:gap-6 relative transition-all duration-300"
                             :class="[activeStep === 2 ? 'z-30' : 'z-10']"
                           >
                             
                             <!-- Left Column: Badge and Timeline Line -->
                             <div class="hidden sm:flex flex-col items-center relative w-6 sm:w-8 flex-shrink-0 z-10">
                               <!-- Badge -->
                               <div 
                                 class="w-6 h-6 sm:w-8 sm:h-8 rounded-full flex items-center justify-center text-xs sm:text-sm font-bold transition-all duration-300 border-2 z-20"
                                 :class="[
                                   isCard2Valid 
                                     ? 'bg-green-500 text-white border-green-500 shadow-sm' 
                                     : activeStep === 2 
                                       ? 'bg-primary text-white border-primary shadow-md' 
                                       : 'bg-white text-gray-400 border-gray-200'
                                 ]"
                               >
                                 <i v-if="isCard2Valid" class="pi pi-check text-xs" />
                                 <span v-else>2</span>
                               </div>
                               <!-- Line Segment 2 (Connecting to Step 3) -->
                               <div class="w-0.5 bg-gray-100 absolute left-1/2 -translate-x-1/2 top-6 sm:top-8 bottom-[-40px] z-0">
                                 <div 
                                   class="w-full bg-primary transition-all duration-500 rounded-full" 
                                   :style="{ height: isCard2Valid ? '100%' : '0%' }"
                                 ></div>
                               </div>
                             </div>

                             <!-- Right Column: Content -->
                             <div 
                               class="flex-1 flex flex-col gap-5 transition-all duration-300 p-4 sm:p-5 rounded-2xl border"
                               :class="[
                                 activeStep === 2 
                                   ? 'bg-primary/5 border-primary/10 opacity-100 scale-[1.005]' 
                                   : 'bg-transparent border-transparent opacity-60 hover:opacity-85'
                               ]"
                               @click="activeStep = 2"
                             >
                               <h3 class="text-base font-bold text-text h-8 flex items-center">
                                 <span class="sm:hidden mr-1">2.</span>Importo
                               </h3>
                               <!-- 3. Importo -->
                               <div class="flex flex-col gap-2">
                                 
                                 <div class="flex items-center gap-3 px-3 py-2.5 sm:px-4 sm:py-3.5 border border-gray-200 rounded-xl bg-gray-50/50 focus-within:bg-white focus-within:ring-2 focus-within:ring-primary-light focus-within:border-primary-light transition-all mt-1">
                                   <span class="text-xl sm:text-2xl font-bold text-gray-400 select-none">{{ props.currency }}</span>
                                   <input
                                     ref="amountInputRef"
                                     type="text"
                                     :value="displayValue"
                                     @input="onAmountInput"
                                     @focus="() => { onFocus(); activeStep = 2; }"
                                     @blur="() => { onBlur(); handleStep2Completion(); }"
                                     @keyup.enter="handleStep2Completion"
                                     inputmode="decimal"
                                     placeholder="0.00"
                                     autocomplete="off"
                                     data-1p-ignore="true"
                                     data-lpignore="true"
                                     :class="[
                                       'w-full text-2xl sm:text-3xl font-bold bg-transparent border-none outline-none focus:ring-0 focus:outline-none p-0 text-text transition-all',
                                       { 'text-red-600': form.amount > 10000000 || showZeroError },
                                       { 'animate-shake': shakeAmount }
                                     ]"
                                   />
                                 </div>
                                 
                                 <div class="flex flex-col mt-1 border-t border-gray-50 pt-2 gap-1">
                                   <InputError :message="showNumericError ? 'Sono consentiti solo numeri e un separatore decimale' : ''" type="warning" />
                                   <InputError :message="showDecimalError ? 'Massimo 4 cifre decimali consentite' : ''" type="warning" />
                                   <InputError :message="showZeroError ? 'L\'importo deve essere maggiore di zero' : ''" />
                                   <InputError :message="showLimitError ? 'Limite massimo di 10M superato!' : ''" />
                                   <span class="text-[11px] text-gray-400 font-normal">Max: 10.000.000 {{ props.currency }}</span>
                                 </div>
                               </div>
                             </div>

                           </div>

                          <!-- STEP 3: Dettagli -->
                          <div 
                            class="flex gap-3 sm:gap-6 relative transition-all duration-300"
                            :class="[activeStep === 3 ? 'z-30' : 'z-10']"
                          >
                            
                            <!-- Left Column: Badge and Timeline Line (No line since it's the last step) -->
                            <div class="hidden sm:flex flex-col items-center relative w-6 sm:w-8 flex-shrink-0 z-10">
                              <!-- Badge -->
                              <div 
                                class="w-6 h-6 sm:w-8 sm:h-8 rounded-full flex items-center justify-center text-xs sm:text-sm font-bold transition-all duration-300 border-2 z-20"
                                :class="[
                                  isCard3Valid 
                                    ? 'bg-green-500 text-white border-green-500 shadow-sm' 
                                    : activeStep === 3 
                                      ? 'bg-primary text-white border-primary shadow-md' 
                                      : 'bg-white text-gray-400 border-gray-200'
                                ]"
                              >
                                <i v-if="isCard3Valid" class="pi pi-check text-xs" />
                                <span v-else>3</span>
                              </div>

                            </div>

                            <!-- Right Column: Content -->
                            <div 
                              class="flex-1 flex flex-col gap-5 transition-all duration-300 p-4 sm:p-5 rounded-2xl border"
                              :class="[
                                activeStep === 3 
                                  ? 'bg-primary/5 border-primary/10 opacity-100 scale-[1.005]' 
                                  : 'bg-transparent border-transparent opacity-60 hover:opacity-85'
                              ]"
                              @click="activeStep = 3"
                            >
                              <h3 class="text-base font-bold text-text h-8 flex items-center">
                                <span class="sm:hidden mr-1">3.</span>Dettagli movimento
                              </h3>
                              
                              <!-- 4. Descrizione (Titolo) -->
                              <div class="flex flex-col gap-3">
                                <div class="flex items-center justify-between">
                                  <div class="flex items-center gap-3">
                                    <div class="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary">
                                      <i class="pi pi-pencil text-sm sm:text-lg" />
                                    </div>
                                    <div class="flex flex-col">
                                      <span class="text-sm font-semibold text-text">Descrizione</span>
                                      <span class="text-[11px] text-gray-400 font-normal">Se vuoto, rimarrà il nome della categoria</span>
                                    </div>
                                  </div>
                                  <span :class="['text-[10px] font-normal transition-colors', form.title.length >= 50 ? 'text-red-500 font-bold' : 'text-gray-400']">
                                    {{ form.title.length }}/50
                                  </span>
                                </div>
                                <div class="mt-1 relative">
                                  <input
                                      ref="titleInputRef"
                                      v-model="form.title"
                                      maxlength="50"
                                      type="text"
                                      @focus="activeStep = 3"
                                      @keydown="(e) => { if (form.title.length >= 50 && e.key.length === 1) triggerShake('title') }"
                                      :placeholder="titlePlaceholder"
                                      :class="[
                                        'w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-light transition-all text-sm bg-gray-50/50 hover:bg-gray-50 focus:bg-white',
                                        { 'animate-shake border-red-400': shakeTitle }
                                      ]"
                                  />
                                  <span v-if="form.title.length >= 50" class="text-[10px] text-red-500 mt-1 block">Limite raggiunto!</span>
                                </div>
                              </div>

                              <!-- Divisore -->
                              <div class="h-px bg-gray-100 w-full"></div>

                              <!-- 5. Data -->
                              <div class="flex flex-col gap-3">
                                <div class="flex items-center gap-3">
                                  <div class="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary">
                                    <i class="pi pi-calendar text-sm sm:text-lg" />
                                  </div>
                                  <div class="flex flex-col">
                                    <span class="text-sm font-semibold text-text">Data</span>
                                    <span class="text-xs text-gray-400 font-normal">Seleziona giorno, mese e anno</span>
                                  </div>
                                </div>

                                <DateSelector
                                  v-model="form.date"
                                  @focus="activeStep = 3"
                                />
                                
                                <InputError 
                                  :message="showFutureWarning ? 'Non è possibile selezionare una data futura — impostata la data di oggi.' : ''"
                                  type="error"
                                  :animate="true"
                                />
                              </div>

                              <!-- Divisore -->
                              <div class="h-px bg-gray-100 w-full"></div>

                              <!-- 6. Conto -->
                              <div class="flex flex-col gap-3">
                                <div class="flex items-center gap-3">
                                  <div class="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary">
                                    <i class="pi pi-credit-card text-sm sm:text-lg" />
                                  </div>
                                  <span class="text-sm font-semibold text-text">Conto</span>
                                </div>
                                <div class="mt-1" @focusin="activeStep = 3">
                                  <SelectDropdown
                                    :items="props.conti"
                                    v-model="form.account"
                                    itemLabel="nome"
                                    placeholder="Seleziona conto"
                                    :showColor="true"
                                    @select="(acc) => { onAccountSelect(acc); handleStep3Completion(); }"
                                    @clear="onAccountClear"
                                    :required="true"
                                    :allowCreateAccount="true"
                                    @item-created="(a) => emit('newAccountCreated', a)"
                                  />
                                </div>
                                <InputError :message="validationError === 'Seleziona un conto' ? 'Seleziona un conto' : ''" />
                              </div>

                              <!-- Divisore -->
                              <div class="h-px bg-gray-100 w-full"></div>

                              <!-- 7. Note -->
                              <div class="flex flex-col gap-3">
                                  <div class="flex items-center justify-between">
                                    <div class="flex items-center gap-3">
                                      <div class="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary">
                                        <i class="pi pi-file text-sm sm:text-lg" />
                                      </div>
                                    <div class="flex items-baseline gap-1.5">
                                      <span class="text-sm font-semibold text-text">Note</span>
                                      <span class="text-xs text-gray-400 font-normal">(opzionale)</span>
                                    </div>
                                  </div>
                                  <span :class="['text-[10px] font-normal transition-colors flex-shrink-0', form.description.length >= 200 ? 'text-red-500 font-bold' : 'text-gray-400']">
                                    {{ form.description.length }}/200
                                  </span>
                                </div>
                                <div class="mt-1 relative">
                                  <textarea
                                      ref="notesInputRef"
                                      v-model="form.description"
                                      maxlength="200"
                                      rows="3"
                                      @focus="activeStep = 3"
                                      @keydown="(e) => { if (form.description.length >= 200 && e.key.length === 1) triggerShake('description') }"
                                      placeholder="Aggiungi note (opzionale)..."
                                      :class="[
                                          'w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-light transition-all text-sm bg-gray-50/50 hover:bg-gray-50 focus:bg-white',
                                          { 'animate-shake border-red-400': shakeDescription }
                                      ]"
                                  ></textarea>
                                  <span v-if="form.description.length >= 200" class="text-[10px] text-red-500 mt-1 block">Limite raggiunto!</span>
                                </div>
                              </div>
                            </div>

                          </div>



                        </div>

                        <!-- Validation Error & Submit Button -->
                        <div class="mt-8 flex flex-col gap-4 border-t border-gray-100 pt-6 relative z-10">
                          <div v-if="validationError && !['Seleziona prima il tipo di movimento', 'Seleziona una categoria', 'Seleziona un conto'].includes(validationError)" class="bg-red-50 text-red-600 p-4 rounded-2xl text-sm font-medium border border-red-100 shadow-sm">
                            {{ validationError }}
                          </div>

                          <button
                            type="submit"
                            :disabled="isSubmitting"
                            @focus="activeStep = 3"
                            :class="[
                              'w-full flex items-center justify-center gap-2 px-4 py-3.5 rounded-2xl transition duration-300 font-semibold shadow-md',
                              isSubmitting 
                                ? 'bg-gray-400 text-white cursor-not-allowed' 
                                : 'bg-primary text-white hover:bg-primary-dark hover:shadow-lg hover:scale-[1.01] active:scale-[0.99] cursor-pointer'
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
                              <i class="pi pi-check-circle text-lg" />
                              {{ isNewMovement ? 'Aggiungi Movimento' : 'Salva Movimento' }}
                            </template>
                          </button>
                        </div>

                      </div>

                    </form>
            </div>
        </div>

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
