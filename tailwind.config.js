/** @type {import('tailwindcss').Config} */
export default {
    content: ["./index.html", "./src/**/*.elm"],
    future: {
        hoverOnlyWhenSupported: true,
    },
    theme: {
        extend: {
            screens: {
                xsm: "400px",
            },
        },
        typography: {
            DEFAULT: {
                css: {
                    a: {
                        "text-decoration": "underline",
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
}
