const fs = require('fs');
const path = require('path');

function generateHtmlReport(results) {
  const total = results.length;
  const passed = results.filter(r => r.status === 'PASSED').length;
  const failed = total - passed;
  const passRate = total > 0 ? ((passed / total) * 100).toFixed(1) : '0.0';

  const categories = {};
  results.forEach(r => {
    if (!categories[r.category]) {
      categories[r.category] = { total: 0, passed: 0, failed: 0 };
    }
    categories[r.category].total += 1;
    if (r.status === 'PASSED') {
      categories[r.category].passed += 1;
    } else {
      categories[r.category].failed += 1;
    }
  });

  let categoriesHtml = '';
  Object.entries(categories).forEach(([catName, metrics]) => {
    const rate = ((metrics.passed / metrics.total) * 100).toFixed(1);
    categoriesHtml += `
      <div class="category-card">
        <div class="category-header">
          <span class="category-name">${catName}</span>
          <span class="category-rate">${rate}% Passed</span>
        </div>
        <div class="progress-bar-container">
          <div class="progress-bar" style="width: ${rate}%;"></div>
        </div>
        <div class="category-metrics">
          <span>Total: ${metrics.total}</span>
          <span class="text-passed">Pass: ${metrics.passed}</span>
          <span class="text-failed">Fail: ${metrics.failed}</span>
        </div>
      </div>
    `;
  });

  let testRowsHtml = '';
  results.forEach((r, idx) => {
    const statusClass = r.status === 'PASSED' ? 'status-passed' : 'status-failed';
    testRowsHtml += `
      <tr class="test-row" onclick="toggleDetails(${idx})">
        <td class="col-id">${r.id}</td>
        <td class="col-cat"><span class="badge-cat">${r.category}</span></td>
        <td class="col-scen">${r.scenario}</td>
        <td class="col-status"><span class="badge-status ${statusClass}">${r.status}</span></td>
        <td class="col-dur">${r.duration} ms</td>
        <td class="col-method">${r.method}</td>
      </tr>
      <tr id="details-${idx}" class="details-row" style="display: none;">
        <td colspan="6">
          <div class="details-content">
            <p><strong>Steps:</strong></p>
            <pre>${r.steps}</pre>
            <p><strong>Expected Result:</strong></p>
            <pre>${r.expected}</pre>
            <p><strong>Actual Result:</strong></p>
            <pre>${r.actual}</pre>
            <p><strong>Remarks / Logs:</strong></p>
            <pre>${r.remarks}</pre>
          </div>
        </td>
      </tr>
    `;
  });

  const htmlContent = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>VeriTask E2E Test Execution Report</title>
  <style>
    :root {
      --bg-color: #0b0f19;
      --card-bg: #111827;
      --border-color: #1f2937;
      --text-main: #f3f4f6;
      --text-muted: #9ca3af;
      --primary: #0f766e;
      --primary-hover: #14b8a6;
      --passed: #10b981;
      --failed: #ef4444;
      --font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    }
    
    body {
      background-color: var(--bg-color);
      color: var(--text-main);
      font-family: var(--font-family);
      margin: 0;
      padding: 0;
    }

    header {
      background-color: var(--card-bg);
      border-bottom: 1px solid var(--border-color);
      padding: 20px 40px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .logo-section h1 {
      margin: 0;
      font-size: 1.5rem;
      color: #fff;
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .logo-section h1 span {
      background: linear-gradient(135deg, var(--primary) 0%, var(--primary-hover) 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }

    .timestamp {
      color: var(--text-muted);
      font-size: 0.9rem;
    }

    main {
      max-width: 1400px;
      margin: 40px auto;
      padding: 0 20px;
    }

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 20px;
      margin-bottom: 40px;
    }

    .stat-card {
      background-color: var(--card-bg);
      border: 1px solid var(--border-color);
      border-radius: 12px;
      padding: 24px;
      text-align: center;
      transition: transform 0.2s;
    }

    .stat-card:hover {
      transform: translateY(-2px);
    }

    .stat-card h3 {
      margin: 0 0 10px 0;
      color: var(--text-muted);
      font-size: 0.9rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }

    .stat-val {
      font-size: 2.5rem;
      font-weight: 700;
      margin: 0;
    }

    .stat-val.passed { color: var(--passed); }
    .stat-val.failed { color: var(--failed); }
    .stat-val.rate { color: var(--primary-hover); }

    .dashboard-sections {
      display: grid;
      grid-template-columns: 1fr 3fr;
      gap: 30px;
    }

    .categories-panel {
      display: flex;
      flex-direction: column;
      gap: 16px;
      max-height: 800px;
      overflow-y: auto;
      padding-right: 5px;
    }

    .category-card {
      background-color: var(--card-bg);
      border: 1px solid var(--border-color);
      border-radius: 8px;
      padding: 16px;
    }

    .category-header {
      display: flex;
      justify-content: space-between;
      margin-bottom: 8px;
    }

    .category-name {
      font-weight: 600;
      font-size: 0.9rem;
    }

    .category-rate {
      font-size: 0.8rem;
      color: var(--text-muted);
    }

    .progress-bar-container {
      background-color: var(--border-color);
      height: 6px;
      border-radius: 3px;
      overflow: hidden;
      margin-bottom: 8px;
    }

    .progress-bar {
      background-color: var(--primary-hover);
      height: 100%;
    }

    .category-metrics {
      display: flex;
      justify-content: space-between;
      font-size: 0.8rem;
      color: var(--text-muted);
    }

    .text-passed { color: var(--passed); }
    .text-failed { color: var(--failed); }

    .test-cases-panel {
      background-color: var(--card-bg);
      border: 1px solid var(--border-color);
      border-radius: 12px;
      padding: 24px;
      overflow-x: auto;
    }

    .test-cases-panel h2 {
      margin-top: 0;
      font-size: 1.25rem;
      margin-bottom: 20px;
    }

    table {
      width: 100%;
      border-collapse: collapse;
      text-align: left;
    }

    th {
      padding: 12px 16px;
      border-bottom: 2px solid var(--border-color);
      color: var(--text-muted);
      font-weight: 600;
      font-size: 0.85rem;
      text-transform: uppercase;
    }

    .test-row {
      border-bottom: 1px solid var(--border-color);
      cursor: pointer;
      transition: background-color 0.2s;
    }

    .test-row:hover {
      background-color: rgba(255, 255, 255, 0.02);
    }

    td {
      padding: 14px 16px;
      font-size: 0.9rem;
      vertical-align: middle;
    }

    .col-id {
      font-family: monospace;
      font-weight: 600;
      color: var(--text-muted);
    }

    .badge-cat {
      background-color: rgba(15, 118, 110, 0.15);
      color: var(--primary-hover);
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 0.75rem;
      font-weight: 600;
    }

    .badge-status {
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 0.75rem;
      font-weight: 700;
      text-transform: uppercase;
    }

    .badge-status.status-passed {
      background-color: rgba(16, 185, 129, 0.15);
      color: var(--passed);
    }

    .badge-status.status-failed {
      background-color: rgba(239, 68, 68, 0.15);
      color: var(--failed);
    }

    .details-row td {
      padding: 0 16px;
    }

    .details-content {
      background-color: #0d1117;
      border-left: 3px solid var(--primary-hover);
      padding: 16px;
      margin: 10px 0;
      border-radius: 4px;
    }

    .details-content p {
      margin: 0 0 8px 0;
      font-size: 0.85rem;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }

    .details-content pre {
      margin: 0 0 16px 0;
      font-family: monospace;
      white-space: pre-wrap;
      word-wrap: break-word;
      font-size: 0.9rem;
      color: #c9d1d9;
    }

    .details-content pre:last-child {
      margin-bottom: 0;
    }
  </style>
</head>
<body>

  <header>
    <div class="logo-section">
      <h1><span>VeriTask</span> E2E Automation</h1>
    </div>
    <div class="timestamp">
      Run Completed: ${new Date().toLocaleString()}
    </div>
  </header>

  <main>
    <div class="stats-grid">
      <div class="stat-card">
        <h3>Total Tests</h3>
        <p class="stat-val">${total}</p>
      </div>
      <div class="stat-card">
        <h3>Passed</h3>
        <p class="stat-val passed">${passed}</p>
      </div>
      <div class="stat-card">
        <h3>Failed</h3>
        <p class="stat-val failed">${failed}</p>
      </div>
      <div class="stat-card">
        <h3>Pass Rate</h3>
        <p class="stat-val rate">${passRate}%</p>
      </div>
    </div>

    <div class="dashboard-sections">
      <div class="categories-panel">
        <h3 style="margin-top:0; font-size:1.1rem; color:var(--text-muted)">Categories Breakdown</h3>
        ${categoriesHtml}
      </div>

      <div class="test-cases-panel">
        <h2>Executed Test Cases Details</h2>
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Category</th>
              <th>Test Scenario</th>
              <th>Status</th>
              <th>Duration</th>
              <th>Method</th>
            </tr>
          </thead>
          <tbody>
            ${testRowsHtml}
          </tbody>
        </table>
      </div>
    </div>
  </main>

  <script>
    function toggleDetails(index) {
      const detailsRow = document.getElementById('details-' + index);
      if (detailsRow.style.display === 'none') {
        detailsRow.style.display = 'table-row';
      } else {
        detailsRow.style.display = 'none';
      }
    }
  </script>
</body>
</html>`;

  const outDir = path.resolve('Test_Results/HTML');
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(path.join(outDir, 'execution-report.html'), htmlContent, 'utf-8');
}

module.exports = { generateHtmlReport };
