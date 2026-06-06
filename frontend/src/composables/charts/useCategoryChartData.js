import { computed, unref } from 'vue'
import { mapSerie } from '@/helpers/mappers/expenseIncomeMapper.js'

/**
 * Composable to parse transaction series and lookup categories/colors.
 * 
 * Supports:
 * - reactive getters: () => props.serie
 * - Vue refs: ref(serie)
 * - raw objects (non-reactive fallback)
 */
export function useCategoryChartData(serieGetter, categoriesGetter, yearGetter, monthGetter) {
  const parsed = computed(() => {
    const s = typeof serieGetter === 'function' ? serieGetter() : unref(serieGetter)
    const y = typeof yearGetter === 'function' ? yearGetter() : unref(yearGetter)
    const m = typeof monthGetter === 'function' ? monthGetter() : unref(monthGetter)
    return mapSerie(s || [], y, m)
  })

  const months = computed(() => parsed.value.months)
  const categoryMap = computed(() => parsed.value.categoryMap)

  const categoryLookup = computed(() => {
    const map = {}
    const src = typeof categoriesGetter === 'function' ? categoriesGetter() : unref(categoriesGetter) || {}

    if (Array.isArray(src)) {
      src.forEach(c => {
        if (!c) return
        if (c.nome) map[c.nome] = c
        if (c.name) map[c.name] = map[c.name] || c
        if (c.label) map[c.label] = map[c.label] || c
        if (c.id !== undefined) map[String(c.id)] = map[String(c.id)] || c
      })
    } else if (typeof src === 'object') {
      Object.keys(src).forEach(k => {
        const v = src[k]
        if (typeof v === 'string') {
          map[k] = { color: v }
        } else if (v) {
          map[k] = v
        }
      })
    }

    // add lowercase keys to support case-insensitive matching
    Object.keys(map).forEach(k => {
      map[String(k).toLowerCase()] = map[k]
    })

    return map
  })

  return {
    months,
    categoryMap,
    categoryLookup
  }
}
