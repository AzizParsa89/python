from django.db import models
from django.contrib.auth.models import User

class Sentence(models.Model):
    text = models.TextField()
    language = models.CharField(max_length=10)  # e.g., 'fa' for Farsi, 'en' for English
    difficulty = models.CharField(max_length=10)  # e.g., 'easy', 'medium', 'hard'

    def __str__(self):
        return f"{self.language} ({self.difficulty}): {self.text[:50]}"

class TypingAttempt(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    sentence = models.ForeignKey(Sentence, on_delete=models.CASCADE)
    typed_text = models.TextField()
    time_taken_seconds = models.FloatField()
    accuracy = models.FloatField()  # Percentage of correct characters
    wpm = models.IntegerField()  # Words per minute
    submitted_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.sentence.text[:20]}... - WPM: {self.wpm}"
