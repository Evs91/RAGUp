FROM postgres:17

# Set environment variables
ENV POSTGRES_DB=ragdb
ENV POSTGRES_USER=raguser
ENV POSTGRES_PASSWORD=ragpassword
ENV POSTGRES_HOST=localhost
ENV POSTGRES_PORT=5432

# Install necessary build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    cmake \
    postgresql-server-dev-17 \
    libcurl4-openssl-dev \
    python3 \
    python3-pip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install pgvector for vector storage and operations
RUN git clone --branch v0.5.1 https://github.com/pgvector/pgvector.git \
    && cd pgvector \
    && make \
    && make install \
    && cd .. \
    && rm -rf pgvector

# Install pgai for alternate vector scheduling ## Not sure if I'll need it or not but here it is
RUN git clone https://github.com/timescale/pgai.git --branch extension-0.6.0 \
    && cd pgai \
	&& python3 projects/extension/build.py install 
    
# Install pg_cron for background job scheduling
RUN git clone https://github.com/citusdata/pg_cron.git \
    && cd pg_cron \
    && make \
    && make install \
    && cd .. \
    && rm -rf pg_cron

# Install PostgreSQL HTTP extension
RUN git clone https://github.com/pramsey/pgsql-http.git \
    && cd pgsql-http \
    && make \
    && make install \
    && cd .. \
    && rm -rf pgsql-http

# Install timescaledb for time-series data support
RUN git clone https://github.com/timescale/timescaledb.git \
    && cd timescaledb \
    && ./bootstrap \
    && cd build \
    && make \
    && make install \
    && cd ../.. \
    && rm -rf timescaledb

# Install pgmp for mathematical operations
RUN git clone https://gitlab.com/dealfonso/pgmp.git \
    && cd pgmp \
    && make \
    && make install \
    && cd .. \
    && rm -rf pgmp

# Copy custom PostgreSQL configuration
COPY postgresql.conf /etc/postgresql/postgresql.conf
COPY pg_hba.conf /etc/postgresql/pg_hba.conf

# Copy initialization scripts
COPY init-extensions.sql /docker-entrypoint-initdb.d/

# Expose PostgreSQL default port
EXPOSE 5432

