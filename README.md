# Deploy Node.js Application - Lab Documentation

**Student:** Balint Lojt
**Date:** 20/07/2026

---

## Deployment Process

1. Installed Node.js via `sudo dnf install -y nodejs`
2. Created the Express application (`app.js`) with two routes: `/`
   (returns hostname, uptime, environment) and `/health` (health check
   endpoint)
3. Installed PM2 globally and created an `ecosystem.config.js` defining
   the app, setting `NODE_ENV=production` and `PORT=8080`
4. Started the app under PM2 (`pm2 start ecosystem.config.js`) and
   verified it showed `online` with restart count 0
5. Configured PM2 to survive reboots - ran `pm2 startup`, executed the
   printed systemd registration command, then `pm2 save` to snapshot
   the process list. Verified with `systemctl is-enabled pm2-ec2-user`
   returning `enabled`
6. Installed and configured Nginx as a reverse proxy, forwarding port 80
   to the app on port 8080
7. Verified the full chain worked both locally (`curl localhost/health`)
   and externally from my laptop (`curl http://<public-ip>/health`)
8. Tested crash recovery by force-killing the app process and confirming
   PM2 restarted it automatically
9. Tested reboot survival by rebooting the instance and confirming the
   app came back online with no manual intervention

## Why PM2 Instead of `node app.js &`

Running an app with `node app.js &` ties the process to the current shell
session - it dies the moment that SSH session ends, doesn't restart if it
crashes, and doesn't come back after a reboot. PM2 solves all three
problems: it manages the process independently of any shell session,
automatically restarts it on a crash, and - once registered with systemd
via `pm2 startup` - automatically starts it again on every boot, with no
manual intervention needed.

## How I Proved the App Survives a Reboot

I ran `sudo reboot` on the instance, waited approximately 2 minutes for
it to fully restart, then reconnected via SSH. Without running any
manual commands, `pm2 list` immediately showed myapp as online, and
curl localhost:8080/health returned a healthy response - confirming the
PM2 startup service (registered with systemd in Step 4) correctly
restored the application on boot with zero manual intervention. This is
the actual proof the deployment is production-ready, unlike the original
`node app.js &` approach that would never have survived a reboot at all.

## Troubleshooting

### Nginx serving default 404 instead of proxying to the app

Nginx initially served its own default 404 page instead of proxying to
the app, despite the custom config in conf.d/app.conf appearing correct.
The root cause was the stock server block in nginx.conf still listening
on port 80 (both IPv4 and IPv6 directives) and winning by load order,
since nginx processes the main config before conf.d includes. Two
attempts to remove the stock listen line failed because the sed pattern
didn't exactly match the actual whitespace/text in the file. Resolved by
checking the actual file content directly with grep before writing the
sed command, then removing both the IPv4 and IPv6 listen directives
specifically.

### EC2 volume accidentally detached during instance restart

While restarting an instance from a previous lab to reuse for this one,
selected an option to detach its EBS volume, which replaced it with a
blank volume on reattachment. Diagnosed by checking volume creation
timestamps via the CLI, located the original volume still intact in an
"available" state, and correctly reattached it. Given the accumulated
complexity (stale security group rules from a prior lab, leftover
ProxyJump config), ultimately opted to launch a fresh instance with a
clean, minimal security group instead of continuing to untangle the
existing one.

### SSH connectivity lost while traveling

Lost SSH access mid-lab after changing networks (home WiFi to mobile
data at an airport). Diagnosed as an IP change - the security group's
SSH rule was scoped to the old IP. Mobile/carrier data typically uses
Carrier-Grade NAT, meaning no stable public IP was available to add to
the security group. Temporarily opened SSH to 0.0.0.0/0 to unblock the
lab, with a plan to revoke this and re-scope to a specific IP once back
on stable network.

## Real-World Application

Manually managing a Node.js process with a bare `node app.js &` command
is fragile and unsuitable for anything beyond quick local testing. In a
real deployment, tools like PM2 (or systemd services directly) combined
with a reverse proxy like Nginx are standard practice - they provide
automatic recovery from crashes, survive reboots without manual
intervention, and separate the public-facing web server from the
application logic itself.