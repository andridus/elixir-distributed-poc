# Bank Project

Elixir application deployed using Docker Swarm.

## Prerequisites

- Docker
- Docker Swarm (will be initialized automatically)

## Available Make Commands

### `make up`
Initializes Docker Swarm, builds the application image, and deploys the bank application stack.
- Initializes Docker Swarm if not already active
- Creates overlay network `swarm_bank_net` if it doesn't exist
- Builds the Docker image from `deploy/Dockerfile`
- Deploys the application using `deploy/docker-stack.yml`

### `make status`
Shows the status of all services in the bank stack.

### `make logs`
Tails the logs from the bank service in real-time.
- Use Ctrl+C to stop following logs

### `make shell`
Connects to the first running bank application instance via remote Elixir shell.
- Provides interactive access to the running application
- Use Ctrl+D to exit the shell

### `make list`
Lists all running bank application containers with their IDs, IP addresses, and names.

### `make scale <number>`
Scales the bank service to the specified number of replicas.
- Example: `make scale 3` to run 3 instances

### `make down`
Removes the entire bank stack and stops all services.

### `make help`
Shows all available make targets and their descriptions.

## Quick Start

1. Deploy the application:
   ```bash
   make up
   ```

2. Check service status:
   ```bash
   make status
   ```

3. View logs:
   ```bash
   make logs
   ```

4. Scale the service:
   ```bash
   make scale 2
   ```

5. Stop the application:
   ```bash
   make down
   ```

## Project Structure

- `lib/` - Elixir application source code
- `deploy/` - Docker deployment files
- `config/` - Application configuration
- `test/` - Test files
