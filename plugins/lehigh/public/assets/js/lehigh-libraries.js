// Javascript to apply some extra CSS only to index.html
    if (window.location.pathname === '/' || window.location.pathname === '/index.html') {
        // Create a new link element
        const cssLink = document.createElement('link');

        // Set attributes for the new CSS file
        cssLink.rel = 'stylesheet';
        cssLink.type = 'text/css';
        cssLink.href = '/assets/css/lehigh-libraries-homepage-only.css'; // Update with your CSS file path

        // Append the new link to the <head>
        document.head.appendChild(cssLink);
    }

// Javascript for dropdown browse menu in header
document.addEventListener("DOMContentLoaded", function () {
  const dropdownToggle = document.querySelector(".dropdown-toggle");
  const dropdownMenu = document.querySelector(".dropdown-menu");

  dropdownToggle.addEventListener("click", function (event) {
    event.preventDefault(); // Prevent default anchor behavior
    dropdownMenu.classList.toggle("show");
  });

  // Hide dropdown when clicking outside
  document.addEventListener("click", function (event) {
    if (!dropdownToggle.contains(event.target) && !dropdownMenu.contains(event.target)) {
      dropdownMenu.classList.remove("show");
    }
  });
});
