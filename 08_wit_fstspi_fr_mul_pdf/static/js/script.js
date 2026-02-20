document.addEventListener('DOMContentLoaded', function() {
    const askButton = document.getElementById('ask-button');
    alert(askButton);
    const questionInput = document.getElementById('question-input');
    const answerBox = document.getElementById('answer-box');

    // Ask a question
    askButton.addEventListener('click', async function() {
        const question = questionInput.value.trim();
        console.log('question : ', question)
        if (question === '') {
            alert('Please enter a question.');
            return;
        }

        try {
            const response = await fetch('/ask/', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: `question=${encodeURIComponent(question)}`,
            });

            const result = await response.json();
            answerBox.innerHTML = `<p>${result.answer}</p>`;
        } catch (error) {
            console.error('Error asking question:', error);
            answerBox.innerHTML = `<p>Error asking question. Check the console for details.</p>`;
        }
    });
});
