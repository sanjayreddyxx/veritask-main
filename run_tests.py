import sys
import os
import subprocess
import time
import socket

# Check if port 8080 is already in use
def is_port_in_use(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('localhost', port)) == 0

def main():
    print("==================================================")
    print("       VeriTask E2E Test Suite Orchestrator       ")
    print("==================================================")
    
    # 1. Build Verification
    web_dir = os.path.join("build", "web")
    if not os.path.exists(web_dir) or not os.path.exists(os.path.join(web_dir, "index.html")):
        print("Error: build/web/index.html not found! Please run 'flutter build web' first.")
        sys.exit(1)
        
    print("Flutter web build verified. Preparing local server...")
    
    # 2. Port conflict check & Server Startup
    port = 8080
    if is_port_in_use(port):
        print(f"Warning: Port {port} is already in use. Attempting to run tests on that instance...")
        server_process = None
    else:
        print(f"Starting Python HTTP server on port {port} pointing to {web_dir}...")
        # Start server in background
        server_process = subprocess.Popen(
            [sys.executable, "-m", "http.server", str(port), "--directory", web_dir],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        # Give server a moment to initialize
        time.sleep(2)
        print("Local web server is running.")

    try:
        # Import and execute Selenium E2E tests
        print("\n--- Step 1: Running Selenium E2E Tests ---")
        sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "scripts")))
        from scripts.run_e2e_tests import run_tests
        run_tests()
        
        # Import and execute Excel report generator
        print("\n--- Step 2: Generating Excel Test Report ---")
        from scripts.generate_report import generate_report
        generate_report()
        
        print("\n==================================================")
        print("SUCCESS: Test execution completed.")
        print("Generated file: E2E_Test_Report_VeriTask.xlsx")
        print("==================================================")
        
    except Exception as e:
        print(f"\nExecution failed with error: {e}")
    finally:
        # 3. Cleanup background server
        if server_process:
            print(f"Shutting down local server on port {port}...")
            server_process.terminate()
            server_process.wait()
            print("Server stopped cleanly.")

if __name__ == "__main__":
    main()
