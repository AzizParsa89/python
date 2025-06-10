from django.urls import path
from .views import UserRegistrationView, SentenceListView, SubmitAttemptView, LeaderboardView

urlpatterns = [
    path('register/', UserRegistrationView.as_view(), name='user-register'),
    path('sentences/', SentenceListView.as_view(), name='sentence-list'),
    path('attempts/submit/', SubmitAttemptView.as_view(), name='submit-attempt'),
    path('leaderboard/', LeaderboardView.as_view(), name='leaderboard'),
]
