include $(TOPDIR)/rules.mk
PKG_NAME:=demo-core
PKG_VERSION:=@VERSION@
PKG_RELEASE:=@REVISION@
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
include $(INCLUDE_DIR)/package.mk

define Package/demo-app
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=demo-core canonical CI experiment
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) $(TOPDIR)/recipes/demo-core/src/. $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) -fPIC -shared $(PKG_BUILD_DIR)/core.c -Wl,-soname,libdemo-core.so -o $(PKG_BUILD_DIR)/libdemo-core.so
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) $(PKG_BUILD_DIR)/core-main.c -L$(PKG_BUILD_DIR) -ldemo-core -o $(PKG_BUILD_DIR)/demo-core
endef

define Package/demo-app/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/demo-core $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/libdemo-core.so $(1)/usr/lib/
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/core.h $(1)/usr/include/demo-core.h
	$(CP) $(PKG_BUILD_DIR)/libdemo-core.so $(1)/usr/lib/
endef

$(eval $(call BuildPackage,demo-app))
