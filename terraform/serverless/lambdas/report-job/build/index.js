"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = void 0;
const AWS = __importStar(require("aws-sdk"));
const pg_1 = require("pg");
const mongodb_1 = require("mongodb");
const fs = __importStar(require("fs"));
const util_1 = require("util");
const secretsManager = new AWS.SecretsManager();
const rdsProxyEndpoint = process.env.RDS_PROXY_ENDPOINT;
const rdsSecretArn = process.env.RDS_SECRET_ARN;
const documentDbSecretArn = process.env.DOCUMENTDB_SECRET_ARN;
const documentDBEndpoint = process.env.DOCUMENTDB_ENDPOINT;
const documentDBDatabaseName = process.env.DOCUMENTDB_DATABASE_NAME;
const rdsDatabaseName = process.env.RDS_DATABASE_NAME;
const bucketName = process.env.BUCKET_NAME;
const documentDbCertObjectKey = process.env.DOCUMENTDB_CERT_OBJECT_KEY;
const handler = async (event, _) => {
    console.log(event);
    /* Recuperando Secret do Banco de Dados RDS */
    const rdsSecret = await getSecretJson(rdsSecretArn);
    const documentDbSecret = await getSecretJson(documentDbSecretArn);
    /* Conectando no Banco de Dados RDS */
    const rdsClient = new pg_1.Client({
        host: rdsProxyEndpoint,
        user: rdsSecret.username,
        password: rdsSecret.password,
        database: rdsDatabaseName,
        ssl: true,
        port: 5432,
    });
    const s3 = new AWS.S3();
    // Download the certificate file from S3
    const params = {
        Bucket: bucketName,
        Key: documentDbCertObjectKey
    };
    const { Body } = await s3.getObject(params).promise();
    const certFilePath = '/tmp/certificate.pem';
    const writeFileAsync = (0, util_1.promisify)(fs.writeFile);
    await writeFileAsync(certFilePath, Body?.toString());
    /* Conectando no Banco de Dados DocumentDB */
    /* username e password precisam ser percent-encoded: a senha gerada pelo
       Secrets Manager pode conter caracteres reservados de URI (%, :, ?, #, [, ]) */
    const mongoUser = encodeURIComponent(documentDbSecret.username);
    const mongoPassword = encodeURIComponent(documentDbSecret.password);
    const mongoConnectionString = `mongodb://${mongoUser}:${mongoPassword}@${documentDBEndpoint}:27017`;
    const documentDBClient = new mongodb_1.MongoClient(mongoConnectionString, {
        tls: true,
        tlsCAFile: certFilePath,
        retryWrites: false,
    });
    try {
        await rdsClient.connect();
        await documentDBClient.connect();
        /* Query RDS Database for necessary data */
        const queryResult = await rdsClient.query(`
        SELECT
            p."Id" AS "ProductId",
            p."Name" AS "ProductName",
            COUNT(o."ProductId") AS "TotalOrders",
          SUM(o."Quantity") AS "TotalOrdered",
          SUM(o."Quantity" * p."Price") AS "TotalSold"
        FROM
            public."Order" o
        JOIN
            public."Product" p ON o."ProductId" = p."Id"
        GROUP BY
            p."Id", p."Name";
      `);
        /* Save data to DocumentDB */
        const db = documentDBClient.db(documentDBDatabaseName);
        const collection = db.collection("reports");
        await collection.deleteMany({});
        // Iterate through query results and insert each record into DocumentDB
        for (const row of queryResult.rows) {
            await collection.insertOne({
                productId: row.ProductId,
                productName: row.ProductName,
                totalOrders: row.TotalOrders,
                totalOrdered: row.TotalOrdered,
                totalSold: row.TotalSold,
            });
        }
        return { statusCode: 200, body: "Data saved successfully." };
    }
    catch (error) {
        console.error("Failed to update Order:", error);
        throw error;
    }
    finally {
        await rdsClient.end();
    }
};
exports.handler = handler;
async function getSecretJson(secretArn) {
    const data = await secretsManager
        .getSecretValue({ SecretId: secretArn })
        .promise();
    if ("SecretString" in data) {
        return JSON.parse(data.SecretString);
    }
    throw new Error("Secret not found");
}
