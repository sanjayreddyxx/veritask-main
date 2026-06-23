import http from 'http';
import { URL } from 'url';
import fs from 'fs';

const targetUrl = process.env.TEST_BASE_URL || 'http://127.0.0.1:5173/Veritask-project/';
console.log(`Starting VeriTask Load Test targeting: ${targetUrl}`);
console.log(`Configuration: 100 concurrent users | Duration: 60 seconds\n`);

const parsedUrl = new URL(targetUrl);
const options = {
  hostname: parsedUrl.hostname,
  port: parsedUrl.port || (parsedUrl.protocol === 'https:' ? 443 : 80),
  path: parsedUrl.pathname + parsedUrl.search,
  method: 'GET',
  headers: {
    'User-Agent': 'VeriTask-LoadTester/1.0'
  },
  agent: new http.Agent({ keepAlive: true, maxSockets: 150 })
};

let totalRequests = 0;
let successfulRequests = 0;
let failedRequests = 0;
const responseTimes = [];
let keepRunning = true;

const startTime = Date.now();
const testDurationMs = 60000; // 1 minute

// Worker function representing 1 virtual user
async function virtualUserWorker() {
  while (keepRunning) {
    const reqStart = Date.now();
    totalRequests++;
    
    await new Promise((resolve) => {
      const req = http.request(options, (res) => {
        let body = '';
        res.on('data', (chunk) => { body += chunk; });
        res.on('end', () => {
          const duration = Date.now() - reqStart;
          responseTimes.push(duration);
          if (res.statusCode >= 200 && res.statusCode < 400) {
            successfulRequests++;
          } else {
            failedRequests++;
          }
          resolve();
        });
      });

      req.on('error', (err) => {
        const duration = Date.now() - reqStart;
        responseTimes.push(duration);
        failedRequests++;
        resolve();
      });

      req.end();
    });

    // Small delay (e.g. 5ms) to prevent absolute CPU thrashing
    await new Promise(r => setTimeout(r, 5));
  }
}

// Spawn 100 concurrent virtual users
const workers = [];
for (let i = 0; i < 100; i++) {
  workers.push(virtualUserWorker());
}

// Schedule termination after 60 seconds
setTimeout(() => {
  keepRunning = false;
  const actualDurationMs = Date.now() - startTime;
  const actualDurationSec = actualDurationMs / 1000;

  Promise.all(workers).then(() => {
    console.log('==================================================');
    console.log('            LOAD TEST RESULTS SUMMARY             ');
    console.log('==================================================');
    
    const rps = (totalRequests / actualDurationSec).toFixed(1);
    
    let avg = 0, min = 0, max = 0;
    if (responseTimes.length > 0) {
      const sum = responseTimes.reduce((a, b) => a + b, 0);
      avg = (sum / responseTimes.length).toFixed(1);
      min = Math.min(...responseTimes);
      max = Math.max(...responseTimes);
    }

    console.log(`Target URL:         ${targetUrl}`);
    console.log(`Total Duration:     ${actualDurationSec.toFixed(1)} seconds`);
    console.log(`Requests Sent:      ${totalRequests}`);
    console.log(`Successful (2xx):   ${successfulRequests}`);
    console.log(`Failed/Errors:      ${failedRequests}`);
    console.log(`Pass Rate:          ${((successfulRequests / totalRequests) * 100).toFixed(2)}%`);
    console.log(`\nRequests per second (RPS):  ${rps} req/sec`);
    console.log(`\nResponse Time:`);
    console.log(`  Average:          ${avg}ms`);
    console.log(`  Minimum:          ${min}ms`);
    console.log(`  Maximum:          ${max}ms`);
    console.log('==================================================');

    // Also write a markdown summary file for GHA step summaries
    const summaryMd = `### 📈 VeriTask Baseline Load Test Report

- **Target URL**: \`${targetUrl}\`
- **Concurrency**: \`100 Virtual Users\`
- **Test Duration**: \`${actualDurationSec.toFixed(1)} seconds\`
- **Requests Sent**: \`${totalRequests}\`
- **Requests per Second (RPS)**: \`${rps} req/sec\`
- **Pass Rate**: \`${((successfulRequests / totalRequests) * 100).toFixed(2)}%\`

#### Response Time Metrics
- **Average**: \`${avg} ms\`
- **Minimum**: \`${min} ms\`
- **Maximum**: \`${max} ms\`
`;
    fs.writeFileSync('load-test-summary.md', summaryMd, 'utf-8');
    process.exit(0);
  });
}, testDurationMs);
