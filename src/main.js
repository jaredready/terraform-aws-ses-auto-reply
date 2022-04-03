const fs = require("fs")

const AWS = require("aws-sdk");
const ses = new AWS.SES();

const replyFrom = process.env.REPLY_FROM;

const fromAddressRegex = /(?<=<).*(?=>)/

exports.handler = (event, context) => {
  const from = event.Records[0].ses.mail.headers
    .find((header) => header.name == "From").value.match(fromAddressRegex)[0];
  const subject = event.Records[0].ses.mail.commonHeaders.subject;

  const responseBody = fs.readFileSync("response.html").toString();

  const sendEmailParameters = {
    Destination: {
      ToAddresses: [from]
    },
    Message: {
      Body: {
        Html: {
          Charset: "utf-8",
          Data: responseBody
        }
      },
      Subject: {
        Charset: 'UTF-8',
        Data: `Re: ${subject}`
      }
    },
    Source: replyFrom
  }

  ses.sendEmail(sendEmailParameters, (err, data) => {
    console.log(err);
    console.log(data);
  });
}
