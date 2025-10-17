local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node

return {
  s('cssreset', {
    t {
      '*, *::before, *::after {',
      '  box-sizing: border-box;',
      '}',
      '',
      '* {',
      '  margin: 0;',
      '}',
      '',
      'body {',
      '  line-height: 1.5;',
      '  -webkit-font-smoothing: antialiased;',
      '}',
      '',
      'img, picture, video, canvas, svg {',
      '  display: block;',
      '  max-width: 100%;',
      '}',
      '',
      'input, button, textarea, select {',
      '  font: inherit;',
      '}',
      '',
      'p, h1, h2, h3, h4, h5, h6 {',
      '  overflow-wrap: break-word;',
      '}',
    },
  }),
  s('flexcen', {
    t {
      'display: flex;',
      'justify-content: center;',
      'align-items: center;',
    },
  }),
  s('flexcol', {
    t {
      'display: flex;',
      'flex-direction: column;',
    },
  }),
  s('flexbetween', {
    t {
      'display: flex;',
      'justify-content: space-between;',
      'align-items: center;',
    },
  }),
  s('grid', {
    t {
      'display: grid;',
      'grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));',
      'gap: 1rem;',
    },
  }),
  s('cardshadow', {
    t {
      'box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);',
      'transition: box-shadow 0.3s ease;',
    },
  }),

  s('cardhover', {
    t {
      'box-shadow: 0 10px 20px rgba(0, 0, 0, 0.15);',
    },
  }),
}
