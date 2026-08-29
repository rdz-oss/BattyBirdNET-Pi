# Answer: Which Version Gets Installed?

## Your Question
> Which version of BattyBirdNET-Analyzer will then be installed? For BattyBirdNET-Pi, it would be from the local machine's dev branch, right?

## Answer

It depends on **which deployment mode** you use:

---

## 🎯 Default Behavior (`./deploy`)

**BattyBirdNET-Pi:** 
- ❌ **NOT** from your local machine
- ✅ From **GitHub** `dev` branch
- Command: `git clone -b dev https://github.com/rdz-oss/BattyBirdNET-Pi.git`

**BattyBirdNET-Analyzer:**
- ✅ From **GitHub** `main` branch (default)
- Command: `git clone -b main https://github.com/rdz-oss/BattyBirdNET-Analyzer.git`

---

## 🔄 To Deploy Local Code

If you want to deploy **your local development version**:

```bash
# Deploy your local BattyBirdNET-Pi code
./deploy --local

# or equivalently
./deploy --deploy
```

**Result:**
- **BattyBirdNET-Pi:** ✅ From your **local directory** (rsync)
- **BattyBirdNET-Analyzer:** From GitHub `main` branch

---

## 📊 All Options

| Command | BattyBirdNET-Pi | BattyBirdNET-Analyzer |
|---------|----------------|----------------------|
| `./deploy` | GitHub `dev` branch | GitHub `main` branch |
| `./deploy --branch feature/x` | GitHub `feature/x` | GitHub `main` (unchanged) |
| `./deploy --branch dev --analyzer-branch dev` | GitHub `dev` | GitHub `dev` |
| `./deploy --local` | **Your local directory** ✅ | GitHub `main` |
| `./deploy --local --analyzer-branch dev` | **Your local directory** ✅ | GitHub `dev` |
| `./deploy --deploy` | **Your local directory** ✅ | GitHub `main` |

---

## 🎯 Recommended Workflows

### For Local Development
```bash
# 1. Make changes locally
cd ~/dev/BattyBirdNET-Pi
# Edit files...

# 2. Deploy to Pi for testing
./deploy --local

# 3. Run tests
pytest tests/hardware/ -v
```

### For Testing Branches
```bash
# Test dev branch
./deploy --branch dev --analyzer-branch dev

# Test feature branch
./deploy --branch feature/my-feature
```

### For Production
```bash
# Install from main (stable)
./deploy --install --branch main --analyzer-branch main
```

---

## 🔍 What Gets Synced with `--local`

When you use `./deploy --local`, these files are synced from your Mac to Pi:

**Included:**
- ✅ All Python scripts (`scripts/*.py`)
- ✅ Shell scripts (`scripts/*.sh`)
- ✅ PHP files (`homepage/*.php`)
- ✅ HTML templates
- ✅ Configuration files
- ✅ Tests

**Excluded:**
- ❌ `.git/` directory
- ❌ `venv/`, `birdnet/` (virtual environments)
- ❌ `*.db` (databases - preserved on Pi)
- ❌ `__pycache__/`, `*.pyc`
- ❌ Test artifacts (`.pytest_cache/`, `reports/`)

---

## 📝 Summary

**Default (`./deploy`):**
- Both from GitHub
- Pi from `dev`, Analyzer from `main`

**Local development (`./deploy --local`):**
- Pi from **your local directory** ✅
- Analyzer from GitHub `main`

**Custom branches:**
- Use `--branch` and `--analyzer-branch` flags

---

## 🎯 Quick Reference

```bash
# Deploy your local changes
./deploy --local

# Deploy from GitHub dev branch
./deploy --branch dev

# Deploy both from dev
./deploy --branch dev --analyzer-branch dev

# Fresh install with local Pi code
./deploy --install --local

# Update from GitHub
./deploy --update --branch dev
```

**See Also:**
- `DEPLOYMENT_MODES.md` - Detailed deployment modes
- `DEPLOYMENT_GUIDE.md` - Full documentation
- `./deploy --help` - Command line options