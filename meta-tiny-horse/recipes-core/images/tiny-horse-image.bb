SUMMARY = "Tiny Horse minimal console image"
DESCRIPTION = "A minimal, console-only image for the Tiny Horse distribution."

require recipes-core/images/core-image-minimal.bb

IMAGE_INSTALL:append = " picture-server"
