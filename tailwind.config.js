/** @type {import('tailwindcss').Config}*/
export default {
  content: [
    "./src/**/*.{js,elm,ts,css,html}",
    "./.elm-land/**/*.{js,elm,ts,css,html}",
  ],
  future: {
    hoverOnlyWhenSupported: true,
  },
  theme: {
    extend: {
      screens: {
        xsm: "400px",
      },
      colors: {
        "background-main": "#f7f8f8",
        "border-main": "#e7e7e7",
      },
    },
    typography: {
      DEFAULT: {
        css: {
          a: {
            "text-decoration": "none",
          },
          blockquote: {
            "font-style": "normal",
            "border-left": "none",
            "padding-left": "0",
            "border-radius": "1rem",
            padding: "0.5rem",
            "background-color": "grey",
            p: {
              margin: "0.5rem",
            },
            "p:first-of-type::before": {
              content: "none",
            },
            "p:first-of-type::after": {
              content: "none",
            },
          },
        },
      },
    },
  },
  plugins: [require("@tailwindcss/typography")],
};
