import { APIGatewayProxyHandler } from "aws-lambda";

/**
 * ================================================================
 * Lambda Function: Hello World / Sample Handler
 * ================================================================
 * Description:
 * - This is a template handler for AWS Lambda functions integrated
 *   with Lex bot intents.
 * - Logs incoming event for debugging.
 * - Returns a structured JSON response.
 *
 * Notes:
 * - Replace the body logic with your actual intent processing.
 * - Ensure the function name matches your fulfillment_lambda_name
 *   in bot-config.json for Lex integration.
 * ================================================================
 */
export const handler: APIGatewayProxyHandler = async (event) => {
  console.log("Received event:", JSON.stringify(event, null, 2));

  try {
    // Your business logic goes here
    const responsePayload = {
      message: "Hello from Lambda! Replace this with actual logic.",
      input: event,
    };

    return {
      statusCode: 200,
      body: JSON.stringify(responsePayload),
    };
  } catch (error) {
    console.error("Error processing Lambda event:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: "Internal Server Error",
        error: error instanceof Error ? error.message : error,
      }),
    };
  }
};