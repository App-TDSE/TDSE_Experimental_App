const { dynamo, tableName } = require('./db');
const { ScanCommand } = require('@aws-sdk/lib-dynamodb');

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Credentials': true,
};

module.exports.getStream = async (event) => {
    try {
        const result = await dynamo.send(new ScanCommand({
            TableName: tableName
        }));

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
            body: JSON.stringify({ message: 'Internal server error' }),
        };
    }
};
