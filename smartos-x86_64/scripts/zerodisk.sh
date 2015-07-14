#!/bin/bash

# # Zero out the free space to save space in the final image:
# dd if=/dev/zero of=/var/tmp/EMPTY bs=1M
# rm -f /var/tmp/EMPTY

# # Sync to ensure that the delete completes before this moves on.
# sync
# sync
# sync