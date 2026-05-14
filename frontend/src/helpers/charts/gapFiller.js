/**
 * Utility to fill gaps in chart timelines
 * Handles DD/MM (daily) and MM/YY (monthly) formats.
 * Skips YYYY (yearly) format.
 */

export function fillTimelineGaps(data, labelKey = 'month') {
  if (!data || data.length === 0) return data;

  const labels = data.map(item => item[labelKey]);
  const firstLabel = labels[0];

  // Detect format
  // Daily: DD/MM (e.g. 01/05)
  // Monthly: MM/YY (e.g. 05/24)
  // Yearly: YYYY (e.g. 2024)

  if (firstLabel.length === 4 && !firstLabel.includes('/')) {
    // Yearly format - skipped
    return data;
  }

  // Gap detection based on labels sequence

  const map = new Map(data.map(item => [item[labelKey], item.amount]));
  const newLabels = [];

  const parts = firstLabel.split('/');
  if (parts.length === 2) {

    const parsed = labels.map(l => {
      const [a, b] = l.split('/').map(Number);
      return { a, b, original: l };
    });

    if (parsed.every(p => p.b === parsed[0].b)) {
      const month = parsed[0].b;
      const days = parsed.map(p => p.a).sort((a, b) => a - b);
      const minDay = days[0];
      const maxDay = days[days.length - 1];

      for (let d = minDay; d <= maxDay; d++) {
        newLabels.push(`${String(d).padStart(2, '0')}/${String(month).padStart(2, '0')}`);
      }
    } else {
      const monthYears = parsed.map(p => ({ m: p.a, y: p.b })).sort((a, b) => {
        if (a.y !== b.y) return a.y - b.y;
        return a.m - b.m;
      });

      let curr = monthYears[0];
      const end = monthYears[monthYears.length - 1];

      while (curr.y < end.y || (curr.y === end.y && curr.m <= end.m)) {
        newLabels.push(`${String(curr.m).padStart(2, '0')}/${String(curr.y).padStart(2, '0')}`);
        curr.m++;
        if (curr.m > 12) {
          curr.m = 1;
          curr.y++;
        }
      }
    }
  } else if (firstLabel.match(/^\d{4}-\d{2}$/)) {
    // Monthly format (YYYY-MM)
    const parsed = labels.map(l => {
      const [y, m] = l.split('-').map(Number)
      return { y, m, original: l }
    }).sort((a, b) => {
      if (a.y !== b.y) return a.y - b.y
      return a.m - b.m
    })

    let curr = { ...parsed[0] }
    const end = parsed[parsed.length - 1]

    while (curr.y < end.y || (curr.y === end.y && curr.m <= end.m)) {
      const l = `${curr.y}-${String(curr.m).padStart(2, '0')}`
      newLabels.push(l)
      curr.m++
      if (curr.m > 12) {
        curr.m = 1
        curr.y++
      }
    }
  } else {
    // Other formats (like Yearly) - skip
    return data
  }

  return newLabels.map(l => ({
    [labelKey]: l,
    amount: map.get(l) || 0
  }));
}
