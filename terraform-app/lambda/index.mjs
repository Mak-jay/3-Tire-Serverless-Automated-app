import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, ScanCommand, PutCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);
const TABLE_NAME = process.env.TABLE_NAME;

export const handler = async (event) => {
  const method = event.requestContext?.httpMethod || event.httpMethod;

  try {
    if (method === "GET") {
      const result = await docClient.send(new ScanCommand({ TableName: TABLE_NAME }));
      return response(200, result.Items ?? []);
    }

    if (method === "POST") {
      const body = JSON.parse(event.body || "{}");
      const item = { id: body.id || Date.now().toString(), ...body };
      await docClient.send(new PutCommand({ TableName: TABLE_NAME, Item: item }));
      return response(201, item);
    }

    return response(405, { message: "Method not allowed" });
  } catch (err) {
    console.error(err);
    return response(500, { message: "Internal server error" });
  }
};

function response(statusCode, body) {
  return {
    statusCode,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  };
}
