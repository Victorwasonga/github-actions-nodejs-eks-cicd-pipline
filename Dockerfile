# Dockerfile
FROM node:16

# Set working directory
WORKDIR /app

# Copy application files
COPY package*.json ./
RUN npm install
COPY . .

# Expose port 3000 and start the app
EXPOSE 3000
CMD ["node", "index.js"]
