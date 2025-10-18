FROM nixos/nix:2.31.2 AS builder

# Update Nix channels and enable experimental features for flakes
RUN nix-channel --update && echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

# Set the working directory for the application
WORKDIR /app

# Copy necessary files for the Nix Flake
COPY flake.nix flake.lock ./

# Cache dependencies using Nix
RUN nix develop .

# Copy the entire application source code
COPY . .

# Build the application using the Nix Flake
RUN nix build .

# Specify the command to run the built binary
ENTRYPOINT ["/app/result/bin/invoice"]
