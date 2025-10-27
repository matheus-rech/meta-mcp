# Claude Desktop Configuration

## Installation Steps

### 1. Build the Project

```bash
cd ~/Documents/cochrane-meta-mcp
./build.sh
```

Or manually:
```bash
npm install
npm run build
```

### 2. Locate Claude Desktop Config

The configuration file is at:
```
~/.config/claude/claude_desktop_config.json
```

On macOS, you can also check:
```
~/Library/Application Support/Claude/claude_desktop_config.json
```

### 3. Add MCP Server Configuration

Edit the configuration file and add:

```json
{
  "mcpServers": {
    "cochrane-meta": {
      "command": "node",
      "args": [
        "/Users/YOUR_USERNAME/Documents/cochrane-meta-mcp/dist/index.js"
      ]
    }
  }
}
```

**Important**: Replace `YOUR_USERNAME` with your actual username!

### 4. Full Configuration Example

If you have other MCP servers, your config might look like:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/YOUR_USERNAME/Documents"]
    },
    "cochrane-meta": {
      "command": "node",
      "args": [
        "/Users/YOUR_USERNAME/Documents/cochrane-meta-mcp/dist/index.js"
      ]
    }
  }
}
```

### 5. Restart Claude Desktop

After adding the configuration:
1. Quit Claude Desktop completely
2. Relaunch Claude Desktop
3. The Cochrane Meta-Analysis tools should now be available

## Verification

To verify the server is working, ask Claude Code:

```
What MCP tools are available for meta-analysis?
```

Claude should list:
- `import_revman_data`
- `validate_cochrane_data`
- `perform_meta_analysis`
- `generate_forest_plot`
- `assess_publication_bias`
- `generate_cochrane_report`

## Troubleshooting

### Server Not Appearing

1. Check the config file path is correct
2. Verify JSON syntax (no trailing commas, proper quotes)
3. Ensure the path to `index.js` is absolute and correct
4. Check that the build completed successfully (`dist/index.js` exists)

### R-Related Errors

If you see errors about R packages:

```r
install.packages(c("metafor", "meta", "ggplot2", "jsonlite"))
```

### Permission Errors

Make sure the index.js is executable:
```bash
chmod +x ~/Documents/cochrane-meta-mcp/dist/index.js
```

### Viewing Logs

Check the MCP server logs:
```bash
tail -f ~/Documents/cochrane-meta-mcp/cochrane-meta-mcp.log
```

For errors:
```bash
tail -f ~/Documents/cochrane-meta-mcp/cochrane-meta-mcp-error.log
```

## Environment Variables

Optional environment variables you can set:

```json
{
  "mcpServers": {
    "cochrane-meta": {
      "command": "node",
      "args": [
        "/Users/YOUR_USERNAME/Documents/cochrane-meta-mcp/dist/index.js"
      ],
      "env": {
        "LOG_LEVEL": "debug",
        "NODE_ENV": "development"
      }
    }
  }
}
```

Available `LOG_LEVEL` values:
- `error` - Only errors
- `warn` - Warnings and errors
- `info` - General information (default)
- `debug` - Detailed debugging information

## Alternative: Using npm Link

For development, you can use npm link:

```bash
cd ~/Documents/cochrane-meta-mcp
npm link
```

Then in Claude Desktop config:

```json
{
  "mcpServers": {
    "cochrane-meta": {
      "command": "cochrane-meta-mcp"
    }
  }
}
```

## Testing Without Claude Desktop

You can test the server directly:

```bash
cd ~/Documents/cochrane-meta-mcp
echo '{"method":"tools/list","params":{}}' | node dist/index.js
```

This should output the list of available tools in JSON format.
