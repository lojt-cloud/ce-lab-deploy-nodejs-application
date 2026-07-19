## Step-by-Step Instructions

### Step 1: Install Node.js

```bash
sudo dnf install -y nodejs   # Amazon Linux 2023 has Node.js (and npm) in its repos
node -v                      # print the installed version to confirm it worked
```

**Expected outcome:** A version number prints.

---

### Step 2: Create the Application

```bash
mkdir -p ~/app && cd ~/app   # create the project directory and move into it
npm init -y                  # generate a default package.json
npm install express          # install the Express web framework
```

Create the application file. `cat > app.js <<'EOF' ... EOF` writes everything between the markers into `app.js`:

```bash
cat > app.js <<'EOF'
const express = require('express');
const os = require('os');                          // used to read the machine's hostname
const app = express();
const port = process.env.PORT || 8080;             // use PORT from the environment, else default to 8080

// Root route: returns basic info about the running instance as JSON
app.get('/', (req, res) => {
  res.json({
    message: 'Week 2 Deployment Lab',
    hostname: os.hostname(),                        // this instance's hostname
    uptime: process.uptime(),                       // seconds since the app started
    environment: process.env.NODE_ENV || 'development'  // set to 'production' by PM2 in Step 3
  });
});

// Health check route: a lightweight endpoint monitors/load balancers can poll
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date() });
});

// Start listening for HTTP requests on the chosen port
app.listen(port, () => console.log(`Server running on port ${port}`));
EOF
```

`uptime` resets to near zero after a reboot (used in Step 8), and `environment` shows `development` until `NODE_ENV` is set in Step 3.

---

### Step 3: Install and Start PM2

Install PM2, then define the app in a PM2 ecosystem file. This file is your **PM2 configuration** deliverable, and its `env` block sets `NODE_ENV` cleanly:

```bash
sudo npm install -g pm2   # install PM2 globally so the `pm2` command is available system-wide

cat > ~/app/ecosystem.config.js <<'EOF'
module.exports = {
  apps: [{
    name: 'myapp',                                 // the name PM2 shows in `pm2 list`
    script: 'app.js',                              // the file PM2 runs
    env: { NODE_ENV: 'production', PORT: 8080 }    // environment variables passed to the app
  }]
};
EOF

cd ~/app
pm2 start ecosystem.config.js   # start the app defined in the ecosystem file (applies the env block)
pm2 list                        # show all PM2-managed processes and their status
```

**Expected outcome:** `status` is `online`.

> If the restart count (`↺`) keeps rising, the app is crash-looping. Check `pm2 logs myapp --lines 50`.

Verify locally:
```bash
curl localhost:8080/health   # {"status":"healthy",...}
curl localhost:8080/         # "environment":"production"
```

---

### 📸 Screenshot Required

**Filename**

```
screenshots/01-pm2-list-online.png
```

**Capture**

`pm2 list` showing `myapp` as `online` with a restart count of 0.

**Purpose**

Confirms the app runs under PM2 rather than as a bare background process.

---

### Step 4: Configure the Application to Survive a Reboot

```bash
pm2 startup
```

`pm2 startup` does not configure anything itself - it **prints** a command you must copy and run, like:

```
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ec2-user --hp /home/ec2-user
```

Run that command, then save the process list and verify:

```bash
pm2 save                            # snapshot the current process list so it is restored on boot
systemctl is-enabled pm2-ec2-user   # confirm the PM2 boot service is registered; should print: enabled
```

**Expected outcome:** `enabled`. If it says `disabled` or errors, you skipped the printed `sudo env PATH=...` command.

---

### 📸 Screenshot Required

**Filename**

```
screenshots/02-pm2-startup-enabled.png
```

**Capture**

`systemctl is-enabled pm2-ec2-user` returning `enabled`.

**Purpose**

Proves the PM2 startup service is registered with systemd - what makes the app survive a reboot.

---

### Step 5: Configure Nginx

Put Nginx in front of the app so public traffic on port 80 is proxied to the app on 8080. Your block must be the `default_server`, and the stock one in `nginx.conf` must be removed, or `nginx -t` fails with "duplicate default server".

```bash
sudo dnf install -y nginx

# Write the proxy config. `tee` writes the heredoc contents to the file (sudo needed for /etc)
sudo tee /etc/nginx/conf.d/app.conf <<'EOF'
server {
    listen 80 default_server;              # handle port 80 traffic; be the default for unmatched hosts
    server_name _;                         # catch-all server name
    location / {                           # for every path...
        proxy_pass http://127.0.0.1:8080;  # ...forward the request to the app on port 8080
        proxy_http_version 1.1;
        proxy_set_header Host $host;        # pass the original Host header to the app
    }
}
EOF

sudo sed -i '/listen       80 default_server;/d' /etc/nginx/nginx.conf   # drop the stock default_server so ours wins
sudo nginx -t                        # validate the configuration before applying it
sudo systemctl enable --now nginx    # start Nginx now and on every boot
```

**Expected outcome:** `nginx -t` passes.

---

### Step 6: Test the Full Chain

```bash
curl localhost/health              # on the instance, through Nginx
curl http://YOUR_PUBLIC_IP/health  # from your laptop
```

**Expected outcome:** Both return `{"status":"healthy",...}`, and `curl http://YOUR_PUBLIC_IP/` shows `"environment":"production"`.

---

### 📸 Screenshot Required

**Filename**

```
screenshots/03-health-endpoint.png
```

**Capture**

The `/health` response at `http://YOUR_PUBLIC_IP/health` (browser or `curl`), showing `{"status":"healthy",...}`.

**Purpose**

Shows the health endpoint is reachable through Nginx from outside the instance.

---

### Step 7: Verify Automatic Restart After a Crash

```bash
pm2 list                    # note the current restart count
kill -9 $(pm2 pid myapp)    # force-kill the app process to simulate a crash
sleep 2                     # give PM2 a moment to detect the exit and restart it
pm2 list                    # restart count increased; status back to online
```

**Expected outcome:** PM2 restarts the process automatically.

---

### 📸 Screenshot Required

**Filename**

```
screenshots/05-crash-recovery.png
```

**Capture**

`pm2 list` after the `kill -9`, showing the incremented restart count (`↺`) and `online` status.

**Purpose**

Proves PM2 restarts the app after a crash.

---

### Step 8: Verify the Application Survives a Reboot

```bash
sudo reboot   # reboot the instance to test that the app comes back on its own
```

Wait ~60 seconds, reconnect, then - without starting anything:

```bash
pm2 list              # myapp should be online
curl localhost/health # should respond
```

**Expected outcome:** The app is running with no manual start. If not, the printed `pm2 startup` command from Step 4 was never run.

---

### 📸 Screenshot Required

**Filename**

```
screenshots/04-after-reboot.png
```

**Capture**

`pm2 list` after reconnecting from the reboot, showing `myapp` online.

**Purpose**

Proves the app returned automatically after a reboot - the lab's core success criterion.

---

