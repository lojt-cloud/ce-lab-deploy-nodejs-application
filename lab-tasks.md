# Lab M2.07 - Deploy Node.js Application

**Repository:** [https://github.com/cloud-engineering-bootcamp/ce-lab-deploy-nodejs-app](https://github.com/cloud-engineering-bootcamp/ce-lab-deploy-nodejs-app)

**Activity Type:** Individual  
**Estimated Time:** 45-60 minutes

## Learning Objectives

- [ ] Deploy complete Node.js application to EC2
- [ ] Configure environment variables securely
- [ ] Set up application as systemd service
- [ ] Implement health checks
- [ ] Monitor application with PM2

## Prerequisites

- [ ] EC2 instance running Amazon Linux 2023
- [ ] SSH access to the instance
- [ ] Security group allows HTTP (80)

---

## Introduction

Running an app with `node app.js &` is not a deployment - it dies when the SSH session ends, does not restart after a crash, and does not return after a reboot. A real deployment restarts automatically, survives a reboot, runs in a defined environment, and exposes a health check. This lab uses PM2 and Nginx to provide all of this.

## Scenario

An application has been running as a backgrounded shell process and has gone down twice - once when an SSH session closed, once after a reboot. You have been asked to deploy it properly and verify it survives a reboot before closing the task.

---

## Your Task

Deploy a production-ready Node.js Express application:
1. Install Node.js and dependencies
2. Create the application code
3. Configure environment variables
4. Set up PM2 process manager
5. Configure Nginx reverse proxy
6. Add health check endpoint

## 📤 What to Submit

**Submission Type:** GitHub Repository

Create a **public** GitHub repository named `ce-lab-deploy-nodejs` containing:

1. **Application code** - `app.js`, `package.json`
2. **Deployment script** - `deploy.sh` capturing the commands you ran
3. **Nginx configuration** - `app.conf`
4. **PM2 configuration** - `ecosystem.config.js`
5. **Screenshots** (in `screenshots/`):
   - `01-pm2-list-online.png` - app online under PM2
   - `02-pm2-startup-enabled.png` - startup service enabled
   - `03-health-endpoint.png` - `/health` response
   - `04-after-reboot.png` - app online after reboot
   - `05-crash-recovery.png` - restart count after `kill -9`
6. **README.md**:
   - Deployment process
   - Why PM2 instead of `node app.js &`
   - How you proved the app survives a reboot

## Screenshot Checklist

Before submitting, verify these are present in the `screenshots/` folder:

- [ ] `screenshots/01-pm2-list-online.png`
- [ ] `screenshots/02-pm2-startup-enabled.png`
- [ ] `screenshots/03-health-endpoint.png`
- [ ] `screenshots/04-after-reboot.png`
- [ ] `screenshots/05-crash-recovery.png`

---

## Grading Rubric

| Criteria | Points |
|----------|--------|
| **Application deployed and publicly accessible** | 30 |
| **PM2 configured** (incl. startup persistence verified) | 20 |
| **Nginx proxy working** | 20 |
| **Health check endpoint** | 15 |
| **Documentation** (incl. reboot proof) | 15 |
| **Total** | **100** |

---

**Great work deploying a production-ready application!** 🚀

**Time limit:** 45-60 minutes