const apiBase = 'https://your-api-gateway-url.com'; // Replace with actual base URL

// Handle form submission (POST)
const form = document.getElementById('submission-form');
if (form) {
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const messageBox = document.getElementById('message');

        const formData = {
            name: form.name.value,
            age: form.age.value,
            profession: form.profession.value,
            experience: form.experience.value
        };

        try {
            const res = await fetch(`${apiBase}/submit`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(formData)
            });

            if (res.ok) {
                messageBox.textContent = 'Submission successful!';
                messageBox.style.color = 'green';
                form.reset();
            } else {
                messageBox.textContent = 'Failed to submit. Try again.';
                messageBox.style.color = 'red';
            }
        } catch (err) {
            console.error('Error:', err);
            messageBox.textContent = 'Network error. Try again later.';
            messageBox.style.color = 'red';
        }
    });
}

// Load entries (GET)
const entriesDiv = document.getElementById('entries');
if (entriesDiv) {
    window.addEventListener('DOMContentLoaded', async () => {
        try {
            const res = await fetch(`${apiBase}/list`);
            const data = await res.json();

            if (!Array.isArray(data) || data.length === 0) {
                entriesDiv.innerHTML = "<p>No entries found.</p>";
                return;
            }

            const html = data.map(entry => `
        <div class="entry-card">
          <p><strong>Name:</strong> ${entry.name}</p>
          <p><strong>Age:</strong> ${entry.age}</p>
          <p><strong>Profession:</strong> ${entry.profession}</p>
          <p><strong>Experience:</strong> ${entry.experience} years</p>
        </div>
      `).join('');

            entriesDiv.innerHTML = html;
        } catch (err) {
            console.error('Error loading data:', err);
            entriesDiv.innerHTML = "<p>Error loading entries.</p>";
        }
    });
}

