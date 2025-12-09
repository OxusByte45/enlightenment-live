# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson
[ "${PV}" = 9999 ] && inherit git-r3

DESCRIPTION="Entrance - An EFL based display manager."
HOMEPAGE="https://github.com/OxusByte45/entrance"
EGIT_REPO_URI="https://github.com/OxusByte45/${PN}.git"
[ "${PV}" = 9999 ] || SRC_URI="https://github.com/OxusByte45/${PN}/archive/v${P}.tar.gz"

LICENSE="GPL-3"
[ "${PV}" = 9999 ] || KEYWORDS="~amd64 ~x86"
SLOT="0"

IUSE="debug nls pam systemd elogind wayland"
REQUIRED_USE="^^ ( elogind systemd )"

RDEPEND="
	dev-libs/efl[X]
	wayland? ( dev-libs/efl[wayland] )
	nls? ( sys-devel/gettext )
	pam? ( sys-libs/pam )
	systemd? ( sys-apps/systemd )
	elogind? ( sys-auth/elogind )
"

BDEPEND="${RDEPEND}
	dev-build/meson"

src_configure() {
	local logind_enabled=false
	use systemd && logind_enabled=true
	use elogind && logind_enabled=true
	
	local emesonargs=(
	    --prefix /usr
	    --bindir /usr/share/bin
	    --sbindir /usr/sbin
	    --datadir /usr/share
	    --sysconfdir /etc
		-Ddebug=$(usex debug true false)
		-Dnls=$(usex nls true false)
		-Dpam=$(usex pam true false)
		-Dlogind=${logind_enabled}
	)
	meson_src_configure
}

src_install() {
	meson_src_install

	if use systemd; then
	    systemctl daemon-reload
	fi
}

pkg_postinst() {
	if use systemd; then
	    einfo "Systemd detected."
	    einfo "Before proceeding you may have to disable the current display manager. If you have lightdm:"
	    einfo "> systemctl disable lightdm.service"
	    einfo ""
	    einfo "Please, run the following command to enable entrance:"
	    einfo "> systemctl enable entrance.service"
	elif use elogind; then
	    einfo "elogind detected (OpenRC)."
	    einfo ""
	    einfo "To enable entrance, edit /etc/conf.d/display-manager:"
	    einfo "  DISPLAYMANAGER=\"entrance\""
	    einfo ""
	    einfo "Then ensure xdm (or display-manager) is in your default runlevel:"
	    einfo "> rc-update add xdm default"
	    einfo ""
	    einfo "Note: entrance binary installs to /usr/sbin/entrance"
	else
	    einfo "Enable entrance by customising your rc.conf file"
	fi
	einfo ""
	einfo "Entrance supports both X11 and Wayland sessions."
	einfo "Make sure your session files are in:"
	einfo "  X11: /usr/share/xsessions/"
	einfo "  Wayland: /usr/share/wayland-sessions/"
}
