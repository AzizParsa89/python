from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Sentence, TypingAttempt

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username', 'password')
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        user = User.objects.create_user(**validated_data)
        return user

class SentenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Sentence
        fields = '__all__'

class TypingAttemptSerializer(serializers.ModelSerializer):
    class Meta:
        model = TypingAttempt
        fields = '__all__'
        read_only_fields = ('user', 'accuracy', 'wpm', 'submitted_at')
