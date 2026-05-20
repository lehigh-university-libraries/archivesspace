// Javascript to apply some extra CSS only to index.html
    if (window.location.pathname === '/' || window.location.pathname === '/index.html') {
        // Create a new link element
        const cssLink = document.createElement('link');

        // Set attributes for the new CSS file
        cssLink.rel = 'stylesheet';
        cssLink.type = 'text/css';
        cssLink.href = 'lehigh-libraries-homepage-only.css'; // Update with your CSS file path

        // Append the new link to the <head>
        document.head.appendChild(cssLink);
    }
