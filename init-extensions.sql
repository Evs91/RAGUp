-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgvector;
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS http;
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS pgmp;

-- Create a schema for RAG-related objects
CREATE SCHEMA IF NOT EXISTS rag_schema;

-- Create a table for vector embeddings
CREATE TABLE IF NOT EXISTS rag_schema.document_embeddings (
    id SERIAL PRIMARY KEY,
    document_text TEXT NOT NULL,
    embedding vector(1536),  -- Assuming OpenAI's embedding dimension
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create an index for efficient vector search
CREATE INDEX IF NOT EXISTS idx_document_embeddings 
ON rag_schema.document_embeddings 
USING ivfflat (embedding vector_cosine_ops);

-- Optional: Create a function for semantic search
CREATE OR REPLACE FUNCTION rag_schema.semantic_search(
    query_embedding vector(1536), 
    similarity_threshold float DEFAULT 0.7, 
    max_results int DEFAULT 10
)
RETURNS TABLE (
    document_text TEXT, 
    similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        de.document_text, 
        1 - (de.embedding <=> query_embedding) AS similarity
    FROM rag_schema.document_embeddings de
    WHERE 1 - (de.embedding <=> query_embedding) > similarity_threshold
    ORDER BY similarity DESC
    LIMIT max_results;
END;
$$;
