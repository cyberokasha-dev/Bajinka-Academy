// Comparison rules are selected by an authored test; source text is never compared.
function compareOutput(actual, expected, rule = {}) {
  const mode = rule.comparison || 'normalized';
  const received = String(actual), wanted = String(expected);
  if (mode === 'exact') return received === wanted;
  if (mode === 'numeric') {
    const number = /^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:e[+-]?\d+)?$/i;
    if (!number.test(received.trim()) || !number.test(wanted.trim())) return false;
    const a = Number(received.trim()), b = Number(wanted.trim());
    const tolerance = rule.tolerance == null ? 0.000001 : Number(rule.tolerance);
    return Number.isFinite(a) && Number.isFinite(b) && Number.isFinite(tolerance) && tolerance >= 0 && Math.abs(a - b) <= tolerance;
  }
  if (mode !== 'normalized') return false;
  return received.replace(/\r\n/g, '\n').trimEnd() === wanted.replace(/\r\n/g, '\n').trimEnd();
}
if (typeof module !== 'undefined') module.exports = {compareOutput};
