const AWS = require('aws-sdk');
const dynamo = new AWS.DynamoDB.DocumentClient();

const tableName = process.env.TABLE_NAME;

exports.handler = async () => {
    const params = {
        TableName: tableName
    };

    try {
        const data = await dynamo.scan(params).promise();
        return {
            statusCode: 200,
            body: JSON.stringify(data.Items)
        };
    } catch (err) {
        console.error("Error reading data: ", err);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: "Could not retrieve data." })
        };
    }
};
