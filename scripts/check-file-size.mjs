// Puerta de calidad: ningún archivo del frontend escrito a mano supera el máximo de líneas de código
// (sin contar líneas en blanco). Umbral del Anexo C del informe técnico.
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, extname } from 'node:path';

const MAX_LINES = 500;
const ROOT = new URL('../frontend/src', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
const EXTENSIONS = new Set(['.ts', '.html', '.scss']);

function* walk(dir) {
  for (const name of readdirSync(dir)) {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) yield* walk(path);
    else if (EXTENSIONS.has(extname(path))) yield path;
  }
}

const offenders = [];
for (const file of walk(ROOT)) {
  const lines = readFileSync(file, 'utf8').split('\n').filter((line) => line.trim() !== '').length;
  if (lines > MAX_LINES) offenders.push(`${file}: ${lines} líneas (máximo ${MAX_LINES})`);
}

if (offenders.length > 0) {
  console.error(offenders.join('\n'));
  process.exit(1);
}
console.log(`Frontend: ningún archivo supera ${MAX_LINES} líneas.`);
