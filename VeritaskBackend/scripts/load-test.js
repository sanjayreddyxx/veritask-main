import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 100,
  duration: '1m',
  thresholds: {
    http_req_failed: ['rate<0.05'], // failure rate < 5%
    http_req_duration: ['p(95)<1500'], // 95th-percentile response time < 1.5s
  },
};

export default function () {
  const url = __ENV.BACKEND_URL || 'https://veritask-backend-demo.herokuapp.com';
  const res = http.get(url);
  
  check(res, {
    'status is 200': (r) => r.status === 200,
  });

  sleep(1);
}
