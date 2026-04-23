const { dynamo, tableName } = require('./db');
const { PutCommand } = require('@aws-sdk/lib-dynamodb');
const crypto = require('crypto');

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
                body: JSON.stringify({ message: 'Content is required and must be max 140 characters.' }),
            };
        }

        // Claims are injected by the HTTP API JWT Authorizer
        const claims = event.requestContext?.authorizer?.jwt?.claims || {};
        const authorId = claims.sub || 'unknown';
        const authorName = claims.name || claims.nickname || claims.email || authorId;

        const post = {
            id: crypto.randomUUID(),
            content: body.content,
            authorId: authorId,
            authorName: authorName,
            timestamp: new Date().toISOString(),
        };

        await dynamo.send(new PutCommand({
            TableName: tableName,
            Item: post,
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
            body: JSON.stringify({ message: 'Internal server error' }),
        };
    }
};
