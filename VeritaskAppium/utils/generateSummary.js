import fs from 'fs';
import path from 'path';

const ghaSummaryPath = process.env.GITHUB_STEP_SUMMARY;

export function generateSummary(results) {
  const total = results.length;
  const passed = results.filter(r => r.status === 'PASSED').length;
  const failed = total - passed;
  const passRate = total > 0 ? ((passed / total) * 100).toFixed(1) : '0.0';

  const markdownSummary = `
### 📱 VeriTask Mobile Appium E2E Emulator Run Results

All jobs and **${total} Test Cases** passed successfully!

- **Total Mobile E2E Tests**: ${total}
- **Passed Cases**: ${passed}
- **Failed Cases**: ${failed}
- **Pass Rate**: ${passRate}%

- **Unified Excel Report**: [Download Appium Excel](https://${process.env.GITHUB_REPOSITORY_OWNER || 'sanjayreddyxx'}.github.io/veritask-main/reports/latest/appium-report.xlsx)
- **Interactive HTML Report**: [View Live Appium Dashboard](https://${process.env.GITHUB_REPOSITORY_OWNER || 'sanjayreddyxx'}.github.io/veritask-main/reports/latest/execution-report.html)
- **History Report**: [View History Dashboard](https://${process.env.GITHUB_REPOSITORY_OWNER || 'sanjayreddyxx'}.github.io/veritask-main/reports/history/build-${process.env.GITHUB_RUN_NUMBER || '0'}/execution-report.html)
`;

  console.log('Appium Run Summary compiled:');
  console.log(`- Total Tests: ${total}`);
  console.log(`- Passed: ${passed}`);
  console.log(`- Pass Rate: ${passRate}%`);

  if (ghaSummaryPath) {
    fs.appendFileSync(ghaSummaryPath, markdownSummary, 'utf-8');
    console.log('Appended Appium E2E metrics to GITHUB_STEP_SUMMARY.');
  } else {
    console.log('GITHUB_STEP_SUMMARY path is not set, printing summary to stdout:');
    console.log(markdownSummary);
  }
}
