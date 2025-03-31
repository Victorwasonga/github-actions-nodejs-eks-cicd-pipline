# Dockerfile
FROM node:16

# Set working directory
WORKDIR /app

# Copy only production nodejs dependencies in Docker image
COPY package*.json ./
RUN npm install --only=production
COPY . .

# Expose port 3000 and start the app
EXPOSE 3000
# command to start the container
CMD ["npm", "start"]
