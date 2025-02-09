# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set environment variables to avoid buffering and bytecode creation
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set the working directory
WORKDIR /app

# Copy requirements file and install dependencies
COPY docker/requirements.txt /app/
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Copy only the app.py file from the docker folder to the working directory
COPY docker/app.py /app/

# Expose port 5000 (adjust if your Flask app listens on another port)
EXPOSE 5000

# Command to run the Flask application
CMD ["python", "app.py"]
