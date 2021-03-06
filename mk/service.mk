.if exists(vars.mk)
.include <vars.mk>
.endif

UID ?= 1001
GID ?= 1001
DOMAIN ?= my.domain
CBSD_WORKDIR!=sysrc -n cbsd_workdir

.MAIN: up

up: setup
	@sudo cbsd jcreate jconf=${PWD}/cbsd.conf || true
.if defined(EXTRA_FSTAB)
	@sudo cp ${EXTRA_FSTAB} ${CBSD_WORKDIR}/jails-fstab/fstab.${SERVICE}.local
.endif
.if !exists(${CBSD_WORKDIR}/jails-system/${SERVICE}/master_poststart.d/register.sh)
	@sudo cp /usr/local/share/reggae/templates/register.sh ${CBSD_WORKDIR}/jails-system/${SERVICE}/master_poststart.d/register.sh
	@sudo chmod 755 ${CBSD_WORKDIR}/jails-system/${SERVICE}/master_poststart.d/register.sh
.endif
.if !exists(${CBSD_WORKDIR}/jails-system/${SERVICE}/master_poststop.d/deregister.sh)
	@sudo cp /usr/local/share/reggae/templates/deregister.sh ${CBSD_WORKDIR}/jails-system/${SERVICE}/master_poststop.d/deregister.sh
	@sudo chmod 755 ${CBSD_WORKDIR}/jails-system/${SERVICE}/master_poststop.d/deregister.sh
.endif
	@sudo cbsd jstart ${SERVICE} || true
	@sudo chown ${UID}:${GID} cbsd.conf
.if !exists(.provisioned)
	@${MAKE} ${MAKEFLAGS} provision
.endif

provision:
	@touch .provisioned
.if target(do_provision)
	@${MAKE} ${MAKEFLAGS} do_provision
.endif

down: setup
	@sudo cbsd jstop ${SERVICE} || true

destroy: down
	@rm -f cbsd.conf vars.mk .provisioned
	@sudo cbsd jremove ${SERVICE}
.if target(do_clean)
	@${MAKE} ${MAKEFLAGS} do_clean
.endif

setup:
	@sed -e "s:SERVICE:${SERVICE}:g" -e "s:DOMAIN:${DOMAIN}:g" ${REGGAE_PATH}/templates/cbsd.conf.tpl >cbsd.conf
.if target(do_setup)
	@${MAKE} ${MAKEFLAGS} do_setup
.endif

login:
	@sudo cbsd jlogin ${SERVICE}

exec:
	@sudo cbsd jexec jname=${SERVICE} ${command}

export: down
.if !exists(build)
	@mkdir build
.endif
	@echo -n "Exporting jail ... "
	@sudo cbsd jexport jname=${SERVICE}
	@sudo mv ${CBSD_WORKDIR}/export/${SERVICE}.img build/
	@sudo chown ${UID}:${GID} build/${SERVICE}.img
