module.exports = {
    plugins: ['prettier-plugin-apex', '@prettier/plugin-xml'],
    overrides: [
        { files: '*.cls', options: { parser: 'apex' } },
        { files: '*.html', options: { parser: 'lwc' } },
        { files: '*.xml', options: { parser: 'xml' } },
    ],
    printWidth: 120,
    singleQuote: true,
    tabWidth: 4,
};
