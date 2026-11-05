SUMMARY = "Serve a single picture over HTTP"
DESCRIPTION = "Small Python HTTP server that serves one picture file."
LICENSE = "CLOSED"

SRC_URI = "file://serve_picture.py \
           file://tinyhorse.jpg \
           file://picture-server.init"

S = "${WORKDIR}"
inherit allarch update-rc.d

INITSCRIPT_NAME = "picture-server"
INITSCRIPT_PARAMS = "defaults 90"

RDEPENDS:${PN} += "python3-core python3-netclient python3-netserver python3-html"

do_install() {
    install -d ${D}${bindir} ${D}${datadir}/picture-server ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/serve_picture.py ${D}${bindir}/serve-picture
    install -m 0644 ${WORKDIR}/tinyhorse.jpg ${D}${datadir}/picture-server/tinyhorse.jpg
    install -m 0755 ${WORKDIR}/picture-server.init ${D}${sysconfdir}/init.d/picture-server
}
