<script setup>
import { ref, watch, nextTick } from 'vue'

import ConfirmModal from '../../modals/ConfirmModal.vue'
// Note: We pass the entire reactive form object as a prop to step components
// to enable direct two-way binding (e.g., v-model) within them.
import StepCategory from './formsteps/StepCategory.vue'
import StepAmount from './formsteps/StepAmount.vue'
import StepDetails from './formsteps/StepDetails.vue'

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
} = useFormControls(form, originalFormState, isSubmitting)

// Input UI Element DOM references
const detailsStepRef = ref(null)

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
      amountInputRef.value?.focusInput()
    }, 50)
  }
}

function handleStep2Completion() {
  if (isCard2Valid.value) {
    activeStep.value = 3
    setTimeout(() => {
      detailsStepRef.value?.focusTitle()
    }, 50)
  }
}

function handleStep3Completion() {
  if (isCard3Valid.value) {
    setTimeout(() => {
      detailsStepRef.value?.focusNotes()
    }, 50)
  }
}

function handleCategorySelect(cat) {
  onCategorySelect(cat)
  if (isCard1Valid.value) {
    activeStep.value = 2
    setTimeout(() => {
      amountInputRef.value?.focusInput()
    }, 50)
  }
}
</script>

<template>
        <div class="w-full flex justify-center px-1">
            <div class="flex flex-col gap-4 mt-6 mb-10 md:mb-6 max-w-xl w-full">
                    <div class="flex flex-col gap-1 pb-2 px-1">
                        <div class="flex items-center gap-2">
                            <i class="pi pi-plus-circle text-primary text-lg" />
                            <h2 class="text-lg font-bold text-text uppercase tracking-widest">{{ isNewMovement ? 'Aggiungi Movimento' : 'Modifica Movimento' }}</h2>
                        </div>
                        <p class="text-[10px] text-gray-500 uppercase tracking-wider">Registra una nuova entrata o spesa</p>
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

                            <StepCategory
                              :form="form"
                              :activeStep="activeStep"
                              :isCard1Valid="isCard1Valid"
                              :validationError="validationError"
                              :movementTypes="movementTypes"
                              :filteredCategories="filteredCategories"
                              :categorie="props.categorie"
                              @update-active-step="(step) => activeStep = step"
                              @set-movement-type="setMovementType"
                              @category-select="onCategorySelect"
                              @category-clear="onCategoryClear"
                              @new-category-created="(c) => emit('newCategoryCreated', c)"
                              @set-validation-error="(err) => validationError = err"
                              @complete-step1="handleStep1Completion"
                            />

                            <StepAmount
                              ref="amountInputRef"
                              :form="form"
                              :activeStep="activeStep"
                              :isCard2Valid="isCard2Valid"
                              :displayValue="displayValue"
                              :shakeAmount="shakeAmount"
                              :showNumericError="showNumericError"
                              :showDecimalError="showDecimalError"
                              :showZeroError="showZeroError"
                              :showLimitError="showLimitError"
                              :currency="props.currency"
                              @update-active-step="(step) => activeStep = step"
                              @amount-input="onAmountInput"
                              @amount-focus="onFocus"
                              @amount-blur="onBlur"
                              @amount-enter="handleStep2Completion"
                            />

                            <StepDetails
                              ref="detailsStepRef"
                              :form="form"
                              :activeStep="activeStep"
                              :isCard3Valid="isCard3Valid"
                              :validationError="validationError"
                              :titlePlaceholder="titlePlaceholder"
                              :shakeTitle="shakeTitle"
                              :shakeDescription="shakeDescription"
                              :showFutureWarning="showFutureWarning"
                              :conti="props.conti"
                              @update-active-step="(step) => activeStep = step"
                              @account-select="onAccountSelect"
                              @account-clear="onAccountClear"
                              @new-account-created="(a) => emit('newAccountCreated', a)"
                              @trigger-shake="triggerShake"
                              @complete-step3="handleStep3Completion"
                            />
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
                              <span class="uppercase tracking-widest text-sm font-bold">Salvataggio...</span>
                            </template>
                            <template v-else>
                              <i class="pi pi-check-circle text-lg" />
                              <span class="uppercase tracking-widest text-sm font-bold">{{ isNewMovement ? 'Aggiungi Movimento' : 'Salva Movimento' }}</span>
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
