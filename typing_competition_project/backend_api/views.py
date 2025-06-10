from django.contrib.auth.models import User
from rest_framework import generics
from rest_framework.permissions import AllowAny
from .models import Sentence, TypingAttempt
from .serializers import UserSerializer, SentenceSerializer, TypingAttemptSerializer
from django.db.models import Avg, F, Window
from django.db.models.functions import Rank

class UserRegistrationView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = (AllowAny,)

class SentenceListView(generics.ListAPIView):
    queryset = Sentence.objects.all()
    serializer_class = SentenceSerializer

class SubmitAttemptView(generics.CreateAPIView):
    queryset = TypingAttempt.objects.all()
    serializer_class = TypingAttemptSerializer

    def perform_create(self, serializer):
        # TODO: Calculate accuracy and WPM before saving
        # This is a placeholder, actual calculation will be more complex
        # For now, we'll save it with dummy values or values from request
        # accuracy = calculate_accuracy(serializer.validated_data['typed_text'], serializer.validated_data['sentence'].text)
        # wpm = calculate_wpm(serializer.validated_data['typed_text'], serializer.validated_data['time_taken_seconds'])
        serializer.save(user=self.request.user) #, accuracy=accuracy, wpm=wpm)

class LeaderboardView(generics.ListAPIView):
    serializer_class = TypingAttemptSerializer # Or a dedicated LeaderboardSerializer

    def get_queryset(self):
        # Example: Top 10 attempts by WPM for a specific sentence (if sentence_id is passed as query param)
        sentence_id = self.request.query_params.get('sentence_id')
        queryset = TypingAttempt.objects.all()

        if sentence_id:
            queryset = queryset.filter(sentence_id=sentence_id)

        # Order by WPM descending, then by time_taken_seconds ascending
        queryset = queryset.order_by('-wpm', 'time_taken_seconds')
        return queryset[:10] # Return top 10

# TODO: Helper functions for accuracy and WPM calculation
# def calculate_accuracy(typed_text, original_text):
#     correct_chars = 0
#     for i in range(min(len(typed_text), len(original_text))):
#         if typed_text[i] == original_text[i]:
#             correct_chars += 1
#     return (correct_chars / len(original_text)) * 100 if len(original_text) > 0 else 0

# def calculate_wpm(typed_text, time_taken_seconds):
#     if time_taken_seconds == 0:
#         return 0
#     words = len(typed_text.split())
#     minutes = time_taken_seconds / 60
#     return int(words / minutes) if minutes > 0 else 0
