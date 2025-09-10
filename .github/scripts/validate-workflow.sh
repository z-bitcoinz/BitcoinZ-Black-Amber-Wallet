#!/bin/bash
set -e

# BitcoinZ Mobile Wallet - Workflow Validation Script
# Validates the GitHub Actions setup locally

echo "🔍 Validating GitHub Actions workflow setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check functions
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅ $1 exists${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 missing${NC}"
        return 1
    fi
}

check_executable() {
    if [ -x "$1" ]; then
        echo -e "${GREEN}✅ $1 is executable${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 is not executable${NC}"
        return 1
    fi
}

check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✅ $1 is available${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  $1 is not available${NC}"
        return 1
    fi
}

# Track validation results
ERRORS=0

echo -e "${BLUE}📋 Checking GitHub Actions workflow files...${NC}"

# Check workflow files
check_file ".github/workflows/build-multiplatform.yml" || ((ERRORS++))

echo -e "${BLUE}📋 Checking build scripts...${NC}"

# Check build scripts
check_file ".github/scripts/build-rust-android.sh" || ((ERRORS++))
check_file ".github/scripts/build-rust-ios.sh" || ((ERRORS++))
check_file ".github/scripts/build-rust-macos.sh" || ((ERRORS++))
check_file ".github/scripts/build-rust-linux.sh" || ((ERRORS++))
check_file ".github/scripts/build-rust-windows.bat" || ((ERRORS++))
check_file ".github/scripts/setup-rust-targets.sh" || ((ERRORS++))

echo -e "${BLUE}🔐 Checking script permissions...${NC}"

# Check script permissions
check_executable ".github/scripts/build-rust-android.sh" || ((ERRORS++))
check_executable ".github/scripts/build-rust-ios.sh" || ((ERRORS++))
check_executable ".github/scripts/build-rust-macos.sh" || ((ERRORS++))
check_executable ".github/scripts/build-rust-linux.sh" || ((ERRORS++))
check_executable ".github/scripts/setup-rust-targets.sh" || ((ERRORS++))

echo -e "${BLUE}🛠️  Checking local development tools...${NC}"

# Check development tools
check_command "flutter" || echo -e "${YELLOW}   Install: https://flutter.dev/docs/get-started/install${NC}"
check_command "dart" || echo -e "${YELLOW}   Comes with Flutter${NC}"
check_command "rustc" || echo -e "${YELLOW}   Install: https://rustup.rs/${NC}"
check_command "cargo" || echo -e "${YELLOW}   Comes with Rust${NC}"

# Platform-specific checks
echo -e "${BLUE}🖥️  Checking platform-specific tools...${NC}"

if [[ "$OSTYPE" == "darwin"* ]]; then
    check_command "lipo" || echo -e "${YELLOW}   Install Xcode Command Line Tools${NC}"
    check_command "xcodebuild" || echo -e "${YELLOW}   Install Xcode${NC}"
    echo -e "${GREEN}ℹ️  macOS: Can build iOS and macOS targets${NC}"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    check_command "pkg-config" || echo -e "${YELLOW}   Install: sudo apt-get install pkg-config${NC}"
    echo -e "${GREEN}ℹ️  Linux: Can build Linux and Android targets${NC}"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo -e "${GREEN}ℹ️  Windows: Can build Windows and Android targets${NC}"
fi

echo -e "${BLUE}📁 Checking project structure...${NC}"

# Check Flutter project structure
check_file "flutter_app/pubspec.yaml" || ((ERRORS++))
check_file "flutter_app/rust/Cargo.toml" || ((ERRORS++))
check_file "flutter_app/lib/main.dart" || ((ERRORS++))

# Check platform directories
[ -d "flutter_app/android" ] && echo -e "${GREEN}✅ Android directory exists${NC}" || echo -e "${YELLOW}⚠️  Android directory missing${NC}"
[ -d "flutter_app/ios" ] && echo -e "${GREEN}✅ iOS directory exists${NC}" || echo -e "${YELLOW}⚠️  iOS directory missing${NC}"
[ -d "flutter_app/macos" ] && echo -e "${GREEN}✅ macOS directory exists${NC}" || echo -e "${YELLOW}⚠️  macOS directory missing${NC}"
[ -d "flutter_app/linux" ] && echo -e "${GREEN}✅ Linux directory exists${NC}" || echo -e "${YELLOW}⚠️  Linux directory missing${NC}"
[ -d "flutter_app/windows" ] && echo -e "${GREEN}✅ Windows directory exists${NC}" || echo -e "${YELLOW}⚠️  Windows directory missing${NC}"

echo -e "${BLUE}🔧 Testing workflow syntax...${NC}"

# Validate YAML syntax if yamllint is available
if command -v yamllint &> /dev/null; then
    if yamllint .github/workflows/build-multiplatform.yml; then
        echo -e "${GREEN}✅ Workflow YAML syntax is valid${NC}"
    else
        echo -e "${RED}❌ Workflow YAML syntax errors${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${YELLOW}⚠️  yamllint not available, skipping YAML validation${NC}"
fi

echo ""
echo -e "${BLUE}📊 Validation Summary${NC}"
echo "=================="

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}🎉 All validations passed!${NC}"
    echo ""
    echo -e "${GREEN}✅ Your GitHub Actions workflow is ready to use${NC}"
    echo ""
    echo -e "${BLUE}🚀 Next Steps:${NC}"
    echo "1. Commit and push your changes to trigger the workflow"
    echo "2. Check the Actions tab in your GitHub repository"
    echo "3. Monitor build progress and download artifacts"
    echo ""
    echo -e "${BLUE}💡 Local Testing:${NC}"
    echo "- Run './.github/scripts/setup-rust-targets.sh' to install targets"
    echo "- Test individual build scripts for your platform"
    echo "- Use 'flutter build <platform>' to test Flutter builds"
else
    echo -e "${RED}❌ Found $ERRORS issues that need to be resolved${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Common fixes:${NC}"
    echo "- Run 'chmod +x .github/scripts/*.sh' to fix permissions"
    echo "- Install missing development tools"
    echo "- Check file paths and project structure"
    exit 1
fi