const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, ScanCommand } = require('@aws-sdk/lib-dynamodb');
const crypto = require('crypto');

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);
const tableName = process.env.POSTS_TABLE;

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Credentials': true,
};

module.exports.createPost = async (event) => {
    try {
        const body = JSON.parse(event.body);
        if (!body.content || body.content.length > 140) {
            return {
                statusCode: 400,
                headers: corsHeaders,
                body: JSON.stringify({ message: "Content is required and must be max 140 characters." }),
            };
        }

        // Get claims from JWT populated by HTTP API Authorizer
        const claims = event.requestContext?.authorizer?.jwt?.claims || {};
        const authorId = claims.sub || 'unknown';
        const authorName = claims.name || claims.nickname || claims.email || authorId;

        const post = {
            id: crypto.randomUUID(),
            content: body.content,
            authorId: authorId,
            authorName: authorName,
            timestamp: new Date().toISOString()
        };

        await dynamo.send(new PutCommand({
            TableName: tableName,
            Item: post
        }));

        return {
            statusCode: 201,
            headers: corsHeaders,
            body: JSON.stringify(post),
        };
    } catch (error) {
        console.error(error);
        return {
            statusCode: 500,
            headers: corsHeaders,
            body: JSON.stringify({ message: "Internal server error" }),
        };
    }
};

module.exports.getStream = async (event) => {
    try {
        const result = await dynamo.send(new ScanCommand({
            TableName: tableName
        }));

        // Sort posts descending by timestamp
        const posts = result.Items || [];
        posts.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

        return {
            statusCode: 200,
            headers: corsHeaders,
            body: JSON.stringify(posts),
        };
    } catch (error) {
        console.error(error);
        return {
            statusCode: 500,
            headers: corsHeaders,
            body: JSON.stringify({ message: "Internal server error" }),
        };
    }
};

module.exports.getUser = async (event) => {
    try {
        // HTTP API JWT Authorizer automatically passes claims
        const claims = event.requestContext?.authorizer?.jwt?.claims || {};
        
        return {
            statusCode: 200,
            headers: corsHeaders,
            body: JSON.stringify(claims),
        };
    } catch (error) {
        console.error(error);
        return {
            statusCode: 500,
            headers: corsHeaders,
            body: JSON.stringify({ message: "Internal server error" }),
        };
    }
};
