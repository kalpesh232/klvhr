document.addEventListener('DOMContentLoaded', function() {
    const chatbox = document.getElementById('chatbox');
    const userInput = document.getElementById('user-input');
    const sendButton = document.getElementById('send-button');

    sendButton.addEventListener('click', sendMessage);
    userInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            sendMessage();
        }
    });

    function sendMessage() {
        const question = userInput.value.trim();
        if (question === '') return;

        // Display user's question
        appendMessage('You', question);

        // Send the question to your backend
        fetch('http://192.168.22.90:5000/ask', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ question: question }),
        })
        .then(response => response.json())
        .then(data => {
            // Display the response from the backend
            appendMessage('Bot', data.answer);
        })
        .catch(error => {
            console.error('Error:', error);
            appendMessage('Bot', 'Sorry, something went wrong.');
        });

        userInput.value = '';
    }

    function appendMessage(sender, message) {
        const messageElement = document.createElement('div');
        messageElement.innerHTML = `<strong>${sender}:</strong> ${message}`;
        chatbox.appendChild(messageElement);
        chatbox.scrollTop = chatbox.scrollHeight;
    }
});
