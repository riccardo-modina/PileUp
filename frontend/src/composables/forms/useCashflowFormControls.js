import { ref, computed, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useFinancialsStore } from '@/stores/financials'

export function useCashflowFormControls(props, emit, { setAmountDisplayValue, clearAmountDisplayValue }) {
  const financials = useFinancialsStore()
  const route = useRoute()

  const form = ref({
    date: new Date(),
    amount: '',
    category: '', // id
    account: '', // id
    description: '',
    title: '',
    movementType: '' // 'income', 'expense', 'transfer'
  })

  const activeStep = ref(1)
  const validationError = ref('')
  const isSubmitting = ref(false)
  const originalFormState = ref('')
  const showFutureWarning = ref(false)
  
  const selectedCategoryName = ref('')
  const selectedAccountName = ref('')

  const movementTypes = computed(() => financials.movementTypes)

  const filteredCategories = computed(() => {
    if (!form.value.movementType) return []
    return (props.categorie || []).filter(c => c.tipo === form.value.movementType)
  })

  const titlePlaceholder = computed(() => {
    if (selectedCategoryName.value) {
      return `${selectedCategoryName.value} (da categoria)`
    }
    return 'es. Acquisto Libri (opzionale)'
  })

  const today = new Date()
  today.setHours(0,0,0,0)

  // Reset form to default values
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
    selectedCategoryName.value = ''
    selectedAccountName.value = ''
    clearAmountDisplayValue()
  }

  const isNewMovement = computed(() => props.prefillMovement === null || props.prefillMovement.id === undefined)

  function applyPrefill(raw) {
    if (!raw) return

    // 1. Date
    if (raw.data || raw.date) {
      const dateVal = raw.data || raw.date
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
      setAmountDisplayValue(form.value.amount)
    }

    // 3. Title & Description
    if (raw.titolo || raw.title) form.value.title = raw.titolo || raw.title
    if (raw.descrizione || raw.description) form.value.description = raw.descrizione || raw.description
    
    // 4. Category
    const catObj = raw.categoria || {}
    const catName = raw.category || catObj.nome || ''
    const catId = catObj.id || (typeof raw.category === 'number' ? raw.category : null)
    
    const isSystemName = (n) => n && String(n).toLowerCase().includes('riassociare')
    const isSystem = catObj.is_system || isSystemName(catName)

    if (catId || catName) {
      const found = (props.categorie || []).find(c => 
        (catId && String(c.id) === String(catId)) || 
        (catName && String(c.nome).toLowerCase() === String(catName).toLowerCase())
      )

      if (found) {
        if (!found.is_system && !isSystemName(found.nome)) {
          form.value.category = found.id
          selectedCategoryName.value = found.nome
        } else {
          form.value.category = ''
          selectedCategoryName.value = ''
        }
        form.value.movementType = found.tipo
      } else {
        if (!isSystem) {
          form.value.category = catId || catName
          selectedCategoryName.value = catName || catId
        } else {
          form.value.category = ''
          selectedCategoryName.value = ''
        }
      }
    }

    if (raw.tipo) {
      form.value.movementType = raw.tipo
    }

    // 5. Account
    const accObj = raw.conto || {}
    const accName = raw.account || accObj.nome || ''
    const accId = accObj.id || (typeof raw.account === 'number' ? raw.account : null)
    const isAccSystem = accObj.is_system || isSystemName(accName)

    if (accId || accName) {
      const found = (props.conti || []).find(c => 
        (accId && String(c.id) === String(accId)) || 
        (accName && String(c.nome).toLowerCase() === String(accName).toLowerCase())
      )

      if (found) {
        if (!found.is_system && !isSystemName(found.nome)) {
          form.value.account = found.id
          selectedAccountName.value = found.nome
        } else {
          form.value.account = ''
          selectedAccountName.value = ''
        }
      } else {
        if (!isAccSystem) {
          form.value.account = accId || accName
          selectedAccountName.value = accName || accId
        } else {
          form.value.account = ''
          selectedAccountName.value = ''
        }
      }
    }

    if (raw.id) form.value.id = raw.id
  }

  function initPrefill() {
    const historyState = window.history.state
    const storedMovement = financials.editingMovement
    
    if (route.query.new === '1') {
      financials.editingMovement = null
      resetForm()
      return
    }

    const target = props.prefillMovement || storedMovement || historyState?.movement
    if (target) {
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

  // Watch for prop changes to re-apply prefill
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

  // Watch and clamp form.date if user picks or types a future date
  watch(() => form.date, (newDate) => {
    if (!newDate) return
    const d = new Date(newDate)
    d.setHours(0,0,0,0)
    if (d > today) {
      form.date = new Date(today)
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
    
    if (form.value.category) {
      const cat = (props.categorie || []).find(c => String(c.id) === String(form.value.category))
      if (cat && cat.tipo !== newType) {
        form.value.category = ''
        selectedCategoryName.value = ''
      }
    }
  })

  // Keep selectedCategoryName in sync if parent sets form.category directly
  watch(() => form.value.category, (val) => {
    if (!val) {
      selectedCategoryName.value = ''
      return
    }
    const found = (props.categorie || []).find(c => String(c.id) === String(val))
    if (found) selectedCategoryName.value = found.nome || ''
  })

  // Reset form when route changes with new=1 query param
  watch(
    () => route.fullPath,
    (newVal, oldVal) => {
      const wasNew = oldVal?.includes("?new=1")
      const isNew = newVal?.includes("?new=1")

      if (!wasNew && isNew) {
        resetForm()
      }
    }
  )

  function setMovementType(type) {
    form.value.movementType = type
    if (validationError.value.includes('tipo')) {
      validationError.value = ''
    }
  }

  function onCategorySelect(cat) {
    selectedCategoryName.value = cat.nome || ''
    form.value.category = cat.id || cat.nome
  }

  function onCategoryClear() {
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

  // Stepper validation states
  const isCard1Valid = computed(() => {
    return !!form.value.movementType && !!form.value.category
  })

  const isCard2Valid = computed(() => {
    return Number(form.value.amount) > 0
  })

  const isCard3Valid = computed(() => {
    return !!form.value.account && !!form.value.date
  })

  function submitForm() {
    validationError.value = ''

    if (!form.value.movementType) {
      validationError.value = 'Seleziona prima il tipo di movimento'
      return
    }

    form.value.title = form.value.title.trim()
    form.value.description = form.value.description.trim()

    if (!form.value.amount && form.value.amount !== 0) {
      validationError.value = 'Inserisci un importo valido'
      return
    }

    if (form.value.amount <= 0) {
      validationError.value = 'Inserisci un importo valido maggiore di zero'
      return
    }

    if (form.value.amount > 10000000) {
      validationError.value = "L'importo massimo consentito è 10.000.000"
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

    isSubmitting.value = true

    emit('submit', { 
      ...form.value, 
      type: isNewMovement.value ? 'add' : 'edit',
    })
  }

  const humanReadableDate = computed(() => {
    if (!form.value.date) return ''
    try {
      return new Date(form.value.date).toLocaleDateString('it-IT', {
        day: 'numeric',
        month: 'long',
        year: 'numeric'
      })
    } catch (e) {
      return String(form.value.date)
    }
  })

  const formattedDate = computed(() => {
    if (!form.value.date) return ''
    const d = new Date(form.value.date)
    const yyyy = d.getFullYear()
    const mm = String(d.getMonth() + 1).padStart(2, '0')
    const dd = String(d.getDate()).padStart(2, '0')
    return `${yyyy}-${mm}-${dd}`
  })

  return {
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
    submitForm,
    humanReadableDate,
    formattedDate
  }
}
