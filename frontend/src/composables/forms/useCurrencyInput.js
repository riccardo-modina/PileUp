import { ref, computed } from 'vue'

export function useCurrencyInput({
  amountRef,
  currencyFormat = 'it-IT',
  currencySymbol = 'EUR',
  maxAmount = 10000000,
  maxDecimals = 4,
  onInvalidInput = null
}) {
  const displayValue = ref('')
  const showNumericError = ref(false)
  const showDecimalError = ref(false)
  const showLimitError = ref(false)
  const showZeroError = ref(false)

  // Configure number formatter based on current system format
  const formatter = computed(() => {
    try {
      return new Intl.NumberFormat(currencyFormat, {
        style: 'currency',
        currency: currencySymbol,
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      })
    } catch (e) {
      return new Intl.NumberFormat('it-IT', {
        style: 'currency',
        currency: 'EUR',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      })
    }
  })

  // Extract decimal and thousands separators
  const formatParts = computed(() => {
    try {
      return formatter.value.formatToParts(1234567.89)
    } catch (e) {
      return []
    }
  })

  const decimalSep = computed(() => formatParts.value.find(p => p.type === 'decimal')?.value || '.')
  const groupSep = computed(() => formatParts.value.find(p => p.type === 'group')?.value || ',')
  const currencySymbolStr = computed(() => formatParts.value.find(p => p.type === 'currency')?.value || currencySymbol)

  const _escapeRegex = (s = '') => s.replace(/[-/\\^$*+?.()|[\]{}]/g, '\\$&')

  // Strips formatting to show raw number for editing
  function onFocus() {
    if (displayValue.value !== '') {
      let v = String(displayValue.value)
      
      const sym = currencySymbolStr.value
      if (sym) {
        v = v.replace(new RegExp(_escapeRegex(sym), 'g'), '')
      }
      
      v = v.replace(/\s+/g, '')

      if (groupSep.value && groupSep.value !== decimalSep.value) {
        v = v.split(groupSep.value).join('')
      } else {
        v = v.replace(/\./g, '')
      }

      if (decimalSep.value && decimalSep.value !== '.') {
        v = v.split(decimalSep.value).join('.')
      }

      const parsed = parseFloat(v)
      if (!isNaN(parsed)) {
        if (Number.isInteger(parsed)) {
          displayValue.value = String(Math.trunc(parsed))
        } else {
          let s = String(parsed)
          if (s.indexOf('.') > -1) {
            s = s.replace(/(\.\d*?[1-9])0+$/, '$1')
            s = s.replace(/\.0+$/, '')
          }
          displayValue.value = s
        }
      } else {
        displayValue.value = v
      }
    }
  }

  // Real-time input constraints (numbers and single dot/comma only, decimal limit)
  function onAmountInput(e) {
    const original = e.target.value
    let normalized = original.replace(',', '.')
    
    const hasInvalidChars = /[^0-9.]/.test(normalized)
    const dotsCount = (normalized.match(/\./g) || []).length
    const hasMultipleDots = dotsCount > 1

    const decimalPart = normalized.split('.')[1]
    const hasTooManyDecimals = decimalPart && decimalPart.length > maxDecimals

    const parsed = parseFloat(normalized)
    const isTooLarge = !isNaN(parsed) && parsed > maxAmount

    if (hasInvalidChars || hasMultipleDots || hasTooManyDecimals || isTooLarge) {
      showNumericError.value = hasInvalidChars || hasMultipleDots
      showDecimalError.value = hasTooManyDecimals
      showLimitError.value = isTooLarge
      
      if (onInvalidInput) onInvalidInput()
      e.target.value = displayValue.value
    } else {
      showNumericError.value = false
      showDecimalError.value = false
      showLimitError.value = false
      displayValue.value = normalized

      if (!isNaN(parsed)) {
        showZeroError.value = (parsed <= 0)
        amountRef.value = parsed
      } else {
        amountRef.value = ''
        showZeroError.value = false
      }
    }
  }

  // Formats to locale currency string on blur
  function onBlur() {
    const num = parseFloat(String(displayValue.value).replace(/\s+/g, ''))
    if (!isNaN(num)) {
      amountRef.value = num
      displayValue.value = formatter.value.format(num)
    } else {
      displayValue.value = ''
      amountRef.value = ''
    }
  }

  function setDisplayValue(val) {
    displayValue.value = formatter.value.format(val)
  }

  function clearDisplayValue() {
    displayValue.value = ''
  }

  return {
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
  }
}
