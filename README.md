# NucleiAiFuzzer
# Nuclei AI Scanning Script by Kdairatchi
(Nuclei-AI-Prompts)[https://github.com/reewardius/Nuclei-AI-Prompts]
**fuzzer.sh** is a comprehensive Bash script leveraging [Nuclei’s](https://github.com/projectdiscovery/nuclei) **AI-based scanning feature** (`-ai`) for automated reconnaissance and vulnerability detection. It reads from a curated list of queries grouped by category in `ai_queries.txt`, prompting the user to select which categories to run, then automatically scanning the specified targets.  

![Nuclei AI Screenshot](https://user-images.githubusercontent.com/placeholder/screenshot.png)  
<sup>*(Sample placeholder image – replace with an actual screenshot of your terminal if desired.)*</sup>

## Features

1. **Interactive Category Selection**  
   - Groups AI queries (e.g., `reconnaissance`, `low-hanging-fruits`, `advanced-mixed-testing`, `sensitive-data-exposure`, `advanced-security-checks`) and allows the user to pick which to run.
2. **Reads AI Queries from File**  
   - No need to modify the script to add or remove queries – simply edit `ai_queries.txt`.
3. **Automatic Template Updates** (`-cup`)  
   - Toggles the `-cup` option to always fetch the latest Nuclei templates (can be disabled).
4. **Retry on Transient Failures**  
   - Handles occasional network/API timeouts by automatically retrying scans.
5. **Colorful Output**  
   - Terminal messages are color-coded (errors in red, successes in green, etc.) for better readability.
6. **Logs to a File**  
   - Outputs everything to both the terminal **and** a timestamped logfile, making it easy to review results later.
7. **Flexible Settings**  
   - Adjustable concurrency, timeouts, and maximum number of scans to run in each session.
8. **By kdairatchi**  
   - Showcasing an automated security scanning tool for bug-bounty or reconnaissance workflows.

## Installation

1. **Install Nuclei**  
   - Ensure you have [Nuclei](https://github.com/projectdiscovery/nuclei) installed on your system.  
   - Also confirm you can run `nuclei --version` successfully.
2. **Clone this Repository**  
   ```bash
   git clone https://github.com/kdairatchi/NucleiAiFuzzer.git
   cd NucleiAiFuzzer
   ```
3. **Make the Script Executable**  
   ```bash
   chmod +x fuzzer.sh
   ```

## Usage

1. **Add or Edit Queries in `ai_queries.txt`**  
   - Each category is marked with `# [category]`  
   - Each line under that header is an AI query string.

2. **Run the Script with Your Targets**  
   ```bash
   ./fuzzer.sh -f targets.txt
   ```
   - You’ll be prompted to **choose categories** (e.g., 1, 2, 3, or 6 for all).
   - The script then runs each AI query in sequence, storing results in `./nuclei_results/`.

### Command-Line Options

- **`-f <file>`**: Path to your list of targets (required).  
- **`-t <timeout>`**: Timeout in seconds for each request (default: 10).  
- **`-n <max_runs>`**: Max number of AI queries to run (0 = unlimited).  
- **`--cup / --no-cup`**: Toggles auto-updating Nuclei templates.  
- **`-o <outdir>`**: Output directory (default: `nuclei_results`).  
- **`-c <concur>`**: Concurrency level (default: 10).  
- **`-r <retries>`**: Number of retries on failure (default: 2).  
- **`-h, --help`**: Show usage.

### Example Command

```bash
# Running with concurrency=20, 30s timeout, 3 retries, no -cup
./fuzzer.sh \
  -f targets.txt \
  -t 30 \
  -c 20 \
  -r 3 \
  --no-cup
```

## File Structure

```
.
├── fuzzer.sh  # Main script
├── ai_queries.txt           # AI queries grouped by category
├── targets.txt              # Example input file of subdomains/URLs (not committed)
└── nuclei_results/          # Output directory (auto-created)
```

## Output

- **Logs**: A file named `nuclei_scan_YYYYmmdd_HHMMSS.log` is created in the current directory, containing all console output.  
- **Results**: Each AI query writes to a separate file named `ai_query_<N>.txt` in `nuclei_results/`.

## Troubleshooting

- **Connection/Timeout Errors**: If you see messages like “Failed to send HTTP request,” it could be a network issue or hitting the ProjectDiscovery AI rate limit. The script will retry automatically a few times.  
- **No Queries Found**: Make sure the categories in `ai_queries.txt` exactly match what you typed at the category prompt.  
- **Permission Denied**: If you get a permission error, remember to run `chmod +x fuzzer.sh`.

## Contributing

1. **Fork** this repository  
2. **Create** a feature branch (`git checkout -b feature-XYZ`)  
3. **Commit** your changes (`git commit -m "Add new AI queries"`)  
4. **Push** to your branch (`git push origin feature-XYZ`)  
5. **Open** a Pull Request

## License

This project is licensed under [MIT License](LICENSE).

## Credits

- **Script Author**: [**kdairatchi**](https://github.com/kdairatchi)  
- **Nuclei** by [ProjectDiscovery](https://github.com/projectdiscovery).  
- **References & Citations**:  
  - [Nuclei Official Docs](https://docs.projectdiscovery.io/tools/nuclei/overview)  
  - [ProjectDiscovery Blog](https://projectdiscovery.io/blog/ultimate-nuclei-guide)  
  - [Various InfoSec write-ups on Nuclei AI usage](https://infosecwriteups.com/nuclei-the-ultimate-guide-to-fast-and-customizable-vulnerability-scanning-c86c50168798)  

---

**Happy Hunting!**  
