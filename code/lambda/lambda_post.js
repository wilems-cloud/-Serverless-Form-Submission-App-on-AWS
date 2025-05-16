const AWS = require('aws-sdk');
const dynamo = new AWS.DynamoDB.DocumentClient();
const sns = new AWS.SNS();

const tableName = process.env.TABLE_NAME;
const topicArn = process.env.SNS_TOPIC;

exports.handler = async (event) => {
    const data = JSON.parse(event.body);

    const params = {
        TableName: tableName,
        Item: {
            name: data.name,
            email: data.email,
            message: data.message,
            timestamp: new Date().toISOString()
        }
    };

    try {
        await dynamo.put(params).promise();

        const snsMessage = {
            Subject: "New Form Submission",
            Message: `New submission received:\n\nName: ${data.name}\nEmail: ${data.email}\nMessage: ${data.message}`,
            TopicArn: topicArn
        };

        await sns.publish(snsMessage).promise();

        return {
            statusCode: 200,
            body: JSON.stringify({ message: "Data saved and notification sent." })
        };
    } catch (err) {
        console.error("Error saving data: ", err);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: "Could not save data." })
        };
    }
};
