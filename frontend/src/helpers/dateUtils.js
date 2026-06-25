/**
 * Date utility functions for PileUp
 */

/**
 * Parse a period string (e.g. "05/2024", "2024", "Totale") into { year, month }
 * used for period selection and data fetching context.
 * 
 * @param {String} period 
 * @returns {Object} { year: String|Number, month: Number|null }
 */
export function parseDataPeriod(period) {
  if (!period || period === 'Totale') return { year: 'Totale', month: null };
  const pStr = String(period);
  if (pStr.includes('/')) {
    const [month, year] = pStr.split('/');
    return { year, month: parseInt(month) };
  }
  return { year: pStr, month: null };
}

/**
 * Extract YYYY-MM from an Italian date (DD/MM/YYYY)
 * 
 * @param {String} dateIt 
 * @returns {String} YYYY-MM
 */
export function extractMonthYear(dateIt) {
  if (!dateIt || typeof dateIt !== 'string') return dateIt;
  const parts = dateIt.split('/');
  if (parts.length !== 3) return dateIt;
  const [day, month, year] = parts;
  return `${year}-${month.padStart(2, '0')}`;
}

/**
 * Format a number as a currency string (Euro)
 * 
 * @param {Number|String} v 
 * @returns {String}
 */
export function formatAmount(v) {
  const val = typeof v === 'string' ? parseFloat(v) : v;
  if (isNaN(val)) return v;
  return val.toFixed(2);
}
