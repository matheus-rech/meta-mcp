#!/bin/bash

echo "Building Cochrane Meta-Analysis MCP Server..."

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed"
    exit 1
fi

# Check for npm
if ! command -v npm &> /dev/null; then
    echo "Error: npm is not installed"
    exit 1
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

# Build TypeScript
echo "Compiling TypeScript..."
npx tsc

# Make executable
if [ -f "dist/index.js" ]; then
    chmod +x dist/index.js
    echo "✓ Build successful!"
    echo "✓ Executable: dist/index.js"
else
    echo "✗ Build failed - dist/index.js not found"
    exit 1
fi

# Check R installation
echo ""
echo "Checking R installation..."
if command -v Rscript &> /dev/null; then
    R_VERSION=$(Rscript --version 2>&1 | head -1)
    echo "✓ R found: $R_VERSION"

    # Check R packages
    echo "Checking R packages..."
    Rscript -e "
    packages <- c('metafor', 'meta', 'ggplot2', 'jsonlite')
    missing <- packages[!sapply(packages, requireNamespace, quietly = TRUE)]
    if (length(missing) > 0) {
        cat('Missing R packages:', paste(missing, collapse=', '), '\n')
        cat('Install with: install.packages(c(\"', paste(missing, collapse='\", \"'), '\"))\n', sep='')
    } else {
        cat('✓ All required R packages installed\n')
    }
    "
else
    echo "⚠ R not found. Install R to use meta-analysis features."
    echo "  Visit: https://www.r-project.org/"
fi

echo ""
echo "Next steps:"
echo "1. Add server to Claude Desktop config:"
echo "   ~/.config/claude/claude_desktop_config.json"
echo ""
echo "2. Add this configuration:"
echo '   {'
echo '     "mcpServers": {'
echo '       "cochrane-meta": {'
echo '         "command": "node",'
echo "         \"args\": [\"$(pwd)/dist/index.js\"]"
echo '       }'
echo '     }'
echo '   }'
echo ""
echo "3. Restart Claude Desktop"
