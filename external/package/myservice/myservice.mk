################################################################################
#
# MyService
#
################################################################################

MYSERVICE_VERSION = v0.1.0
MYSERVICE_SITE = https://project_XXX_bot:$(MYSERVICE_ACCESS_TOKEN)@gitlab.querdenkerengineering.de/master/customer/project/myservice.git
MYSERVICE_SITE_METHOD = git
MYSERVICE_LICENSE = QDE

define MYSERVICE_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 0555 $(MYSERVICE_PKGDIR)/S50MyService \
		$(TARGET_DIR)/etc/init.d/S50MyService
endef

$(eval $(cmake-package))
