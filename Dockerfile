# Use official Python image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy code into container
COPY . /app

# Install Flask
RUN pip install flask

# Expose the port Flask runs on
EXPOSE 5000

# Run the app
CMD ["python", "app.py"]
