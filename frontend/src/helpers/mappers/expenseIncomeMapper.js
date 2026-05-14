/**
 * Maps raw expense and income data to chart-friendly format
 * 
 * used to parse an array of expense/income objects into the series gouped by category and month
 * 
 * @paramm {Arrray} serie - array of object containing date, amount and category
 * 
 * @return {Object} - mapped data ready to be used in charts
 * 
 * Example input:
 * [
 *    { date: "10/01/2024", amount: 20, category: "Car" },
 *    { date: "12/01/2024", amount: 60, category: "Food" },
 *    { date: "05/02/2024", amount: 40, category: "Car" },
 *    { date: "10/02/2024", amount: 100, category: "Shopping" },
 *    { date: "15/02/2024", amount: 20, category: "Food" }
 * ]
 *
 * 
 * Example output:
 * {
 *  months: ["2024-01", "2024-02"],
 *  categoryMap: {
 *    Car: {
 *      "2024-01": 20,
 *     "2024-02": 40
 *    },
 *    Food: {
 *      "2024-01": 60,
 *      "2024-02": 20
 *    },
 *    Shopping: {
 *      "2024-02": 100
 *    }
 *  }
 *}
 *       
 */

import { extractMonthYear } from '@/helpers/dateUtils'
import { fillTimelineGaps } from '@/helpers/charts/gapFiller.js'

/**
 * Maps raw expense/income data by category and month/day
 * 
 * @param {Array} serie - array of objects: { date, amount, category }
 * @param {String|Number} year - optional year context
 * @param {Number} month - optional month context
 * @returns {Object} { months: Array<string>, categoryMap: Object }
 */
export function mapSerie(serie = [], year = null, month = null) {
  const grain = (month && year && year !== 'Totale') ? 'day' : 'month'
  const labelsSet = new Set()
  const categoryMap = {}

  serie.forEach(item => {
    let label
    if (grain === 'day') {
      const [d, m] = item.date.split('/')
      label = `${d.padStart(2, '0')}/${m.padStart(2, '0')}`
    } else {
      label = extractMonthYear(item.date)
    }
    const cat = item.category

    labelsSet.add(label)

    if (!categoryMap[cat]) categoryMap[cat] = {}
    if (!categoryMap[cat][label]) categoryMap[cat][label] = 0

    categoryMap[cat][label] += item.amount
  })

  let labels = []
  if (grain === 'day') {
    const numDays = new Date(Number(year), month, 0).getDate()
    for (let d = 1; d <= numDays; d++) {
      labels.push(`${String(d).padStart(2, '0')}/${String(month).padStart(2, '0')}`)
    }
  } else if (year && year !== 'Totale') {
    // Yearly view: all 12 months (YYYY-MM format)
    for (let m = 1; m <= 12; m++) {
      labels.push(`${year}-${String(m).padStart(2, '0')}`)
    }
  } else {
    const rawLabels = Array.from(labelsSet).sort()
    // Fill gaps in months (YYYY-MM format)
    const dummyData = rawLabels.map(l => ({ month: l, amount: 0 }))
    const filledData = fillTimelineGaps(dummyData)
    labels = filledData.map(d => d.month)
  }

  return {
    months: labels,
    categoryMap
  }
}
