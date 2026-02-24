FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

# Create data directory if it doesn't exist
RUN mkdir -p data feeds

# Copy example OPML if follow.opml doesn't exist
RUN if [ ! -f feeds/follow.opml ]; then \
    cp feeds/follow.example.opml feeds/follow.opml 2>/dev/null || true; \
    fi

# Expose port
EXPOSE 8080

# Create startup script
RUN echo '#!/bin/bash\n\
set -e\n\
echo "Updating news data..."\n\
if [ -f feeds/follow.opml ]; then\n\
    python scripts/update_news.py --output-dir data --window-hours 24 --rss-opml feeds/follow.opml\n\
else\n\
    python scripts/update_news.py --output-dir data --window-hours 24\n\
fi\n\
echo "Starting web server on port 8080..."\n\
python -m http.server 8080\n\
' > /app/start.sh && chmod +x /app/start.sh

CMD ["/app/start.sh"]
