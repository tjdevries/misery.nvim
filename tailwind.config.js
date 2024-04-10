/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./mixery/**/*.*ex", "./**/*.html.heex", "./**/*.html"],
  theme: {
    extend: {
      colors: {
        brand: "#FD4F00",
      },
    },
  },
};
