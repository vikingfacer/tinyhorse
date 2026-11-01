SUMMARY = "Serve a single picture over HTTP"
DESCRIPTION = "Small Python HTTP server that serves one picture file."
LICENSE = "CLOSED"

SRC_URI = "file://serve_picture.py"

S = "${WORKDIR}"
PACKAGE_ARCH = "all"

RDEPENDS:${PN} += "python3-core python3-netclient python3-netserver python3-html"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/serve_picture.py ${D}${bindir}/serve-picture
}
