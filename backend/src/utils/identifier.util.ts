/**
 * Builds a consistent `@samagra.in` login identifier from a base string and school code.
 * Preserves explicit `@` identifiers if already provided.
 */
export function buildSamagraIdentifier(
  base: string,
  schoolCode: string,
  fallbackBase = 'user'
): string {
  const trimmed = (base || '').toString().trim();
  if (trimmed.includes('@')) {
    return trimmed;
  }
  const baseSlug = trimmed.toLowerCase().replace(/[^a-z0-9]/g, '') || fallbackBase;
  const codeSlug = (schoolCode || 'school').toString().toLowerCase().replace(/[^a-z0-9]/g, '') || 'school';
  return `${baseSlug}.${codeSlug}@samagra.in`;
}
