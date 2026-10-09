# Global agent instructions

- Always follow the OpenSpec workflow unless instructed otherwise
- Keep repositories and project files under `/workspace`; use `/home/paseo` for user configuration and persistent agent state.
- Build container images using `buildctl` which is mounted at `/builder/bin/buildctl`

