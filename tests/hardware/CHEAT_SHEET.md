# Deployment Cheat Sheet

## 🚀 Quick Commands

### Deploy Your Local Code
```bash
./deploy --local
```
- Pi: **Your local directory** ✅
- Analyzer: GitHub `main`

### Deploy from GitHub
```bash
./deploy
```
- Pi: GitHub `dev`
- Analyzer: GitHub `main` (unchanged)

### Update Both from Dev
```bash
./deploy --update --branch dev --analyzer-branch dev
```
- Pi: GitHub `dev` ✅
- Analyzer: GitHub `dev` ✅

---

## 📊 Decision Tree

```
Want to test local changes?
├─ YES → ./deploy --local
└─ NO → Want specific GitHub branch?
        ├─ YES → ./deploy --branch <name> --analyzer-branch <name>
        └─ NO → ./deploy (defaults: Pi=dev, Analyzer=main)
```

---

## 🎯 Common Scenarios

| What You Want | Command |
|--------------|---------|
| Test my local code | `./deploy --local` |
| Test dev branch | `./deploy --branch dev` |
| Test feature branch | `./deploy --branch feature/x` |
| Test both from dev | `./deploy --branch dev --analyzer-branch dev` |
| Fresh install | `./deploy --install` |
| Reinstall everything | `./deploy --reinstall` |
| Check status | `./deploy --status` |
| Uninstall | `./deploy --uninstall` |

---

## 🔧 Options

```bash
--branch <name>              # Pi branch (default: dev)
--analyzer-branch <name>     # Analyzer branch (default: main)
--local / --deploy           # Deploy from local directory
--install                    # Fresh install
--update                     # Git pull update
--no-backup                  # Skip backup
--no-restart                 # Don't restart services
-v                           # Verbose output
```

---

## 📁 What Gets Deployed

### Local Deploy (`--local`)
✅ Python scripts  
✅ Shell scripts  
✅ PHP files  
✅ Templates  
✅ Configs  
✅ **Services reinstalled**  
✅ **Dependencies updated**  
✅ **Database created (if missing)**  
❌ Git history  
❌ Virtual env (uses existing on Pi)  
❌ Databases (preserved)  

### GitHub Deploy (default)
✅ Everything from branch  
✅ Git history (shallow)  
✅ Services installed  
❌ Your uncommitted changes  

---

## 🎓 Example Session

```bash
# 1. Make changes locally
git checkout feature/audio-fix
# Edit files...

# 2. Deploy to Pi
./deploy --local

# 3. Test
pytest tests/hardware/test_audio.py -v

# 4. Check status
./deploy --status

# 5. Deploy to production when ready
./deploy --install --branch main --analyzer-branch main
```

---

**Full docs:** See `DEPLOYMENT_GUIDE.md` and `DEPLOYMENT_MODES.md`

---

## ❓ Does `--local` Setup Services?

### ✅ **YES!**

When you run `./deploy --local`:

1. ✅ Stops services
2. ✅ Syncs your local files
3. ✅ Updates Python dependencies
4. ✅ **Reinstalls services** (calls `install_services.sh`)
5. ✅ Creates database (if missing)
6. ✅ Sets up config (if missing)
7. ✅ Restarts services

**Fresh install?**
```bash
./deploy --install --local
```

**See:** `SERVICES_SETUP.md` for complete details
