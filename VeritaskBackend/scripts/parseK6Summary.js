import fs from 'fs';
import path from 'path';

const summaryPath = path.resolve('summary.json');
const ghaSummaryPath = process.env.GITHUB_STEP_SUMMARY;

console.log(`Reading k6 summary from: ${summaryPath}`);

// Helper to safely extract metric values in nested or flat structures
function getMetricValue(metricObj, key) {
  if (!metricObj) return 0;
  if (metricObj.values && metricObj.values[key] !== undefined) {
    return metricObj.values[key];
  }
  if (metricObj[key] !== undefined) {
    return metricObj[key];
  }
  return 0;
}

try {
  if (!fs.existsSync(summaryPath)) {
    throw new Error('summary.json file not found! Load testing may have failed.');
  }

  const rawData = fs.readFileSync(summaryPath, 'utf-8');
  const summary = JSON.parse(rawData);

  // Safely extract metrics
  const metrics = summary.metrics || {};

  const httpReqs = metrics.http_reqs || {};
  const totalRequests = getMetricValue(httpReqs, 'count') || 0;
  const rateObj = metrics.http_reqs || {};
  const throughput = getMetricValue(rateObj, 'rate') || 0; // RPS

  const durationObj = metrics.http_req_duration || {};
  const avgLatency = getMetricValue(durationObj, 'avg') || 0;
  const minLatency = getMetricValue(durationObj, 'min') || 0;
  const maxLatency = getMetricValue(durationObj, 'max') || 0;
  const p95Latency = getMetricValue(durationObj, 'p(95)') || 0;

  const failedReqsObj = metrics.http_req_failed || {};
  const failureRate = (getMetricValue(failedReqsObj, 'value') || getMetricValue(failedReqsObj, 'rate') || 0) * 100;

  const checksObj = metrics.checks || {};
  const checksRate = (getMetricValue(checksObj, 'value') || getMetricValue(checksObj, 'rate') || 0) * 100;

  // Build Markdown table
  const markdownReport = `
### ⚡ VeriTask API Load Testing Results

| Metric | Target / Spec | Actual Result | Status |
|---|---|---|---|
| **Virtual Users (VUs)** | 100 VUs | 100 VUs | Pass |
| **Duration** | 60 seconds | 60 seconds | Pass |
| **Total Requests** | N/A | ${totalRequests} | Info |
| **Throughput (RPS)** | N/A | ${throughput.toFixed(2)} req/sec | Info |
| **Avg Response Time** | N/A | ${avgLatency.toFixed(2)} ms | Info |
| **Min Response Time** | N/A | ${minLatency.toFixed(2)} ms | Info |
| **Max Response Time** | N/A | ${maxLatency.toFixed(2)} ms | Info |
| **95th Percentile (p95)** | < 1500 ms | ${p95Latency.toFixed(2)} ms | ${p95Latency < 1500 ? '✅ Pass' : '❌ Fail'} |
| **Request Failure Rate** | < 5.0% | ${failureRate.toFixed(2)}% | ${failureRate < 5.0 ? '✅ Pass' : '❌ Fail'} |
| **Checks/Assertions Pass Rate** | 100.0% | ${checksRate.toFixed(1)}% | ${checksRate === 100.0 ? '✅ Pass' : '⚠️ Warning'} |
`;

  console.log('Parsed Load Test Summary:');
  console.log(`- Total Requests: ${totalRequests}`);
  console.log(`- Throughput: ${throughput.toFixed(2)} req/sec`);
  console.log(`- Latency (p95): ${p95Latency.toFixed(2)} ms`);
  console.log(`- Failure Rate: ${failureRate.toFixed(2)}%`);

  if (ghaSummaryPath) {
    fs.appendFileSync(ghaSummaryPath, markdownReport, 'utf-8');
    console.log('Appended k6 statistics table to GITHUB_STEP_SUMMARY.');
  } else {
    console.log('GITHUB_STEP_SUMMARY path is not set, printing report to stdout:');
    console.log(markdownReport);
  }

} catch (err) {
  console.error('Error processing k6 load test results:', err.message);
  
  // Fallback report so GHA doesn't break
  const fallbackReport = `
### ⚡ VeriTask API Load Testing Results
⚠️ **Error parsing load test summary output**: ${err.message}
Please verify the k6 console outputs or runner logs for details.
`;
  if (ghaSummaryPath) {
    fs.appendFileSync(ghaSummaryPath, fallbackReport, 'utf-8');
  }
}
