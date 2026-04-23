const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Credentials': true,
};

module.exports.getUser = async (event) => {
    try {
        // HTTP API JWT Authorizer automatically injects validated claims
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
            body: JSON.stringify({ message: 'Internal server error' }),
        };
    }
};
