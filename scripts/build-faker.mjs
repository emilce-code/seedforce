import { build } from 'esbuild';

await build({
    entryPoints: ['scripts/faker-entry.js'],
    bundle: true,
    minify: true,
    format: 'iife',
    outfile: 'force-app/main/default/staticresources/seedforceFaker.js',
});
