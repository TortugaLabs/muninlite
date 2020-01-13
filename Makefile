PLUGINS=$(wildcard plugins/*.sh)
MUNIN_NODE = munin-node

$(MUNIN_NODE): VERSION munin-node.in $(PLUGINS)
	@VERSION=$$(cat VERSION); \
	echo "Making munin-node for muninlite version $$VERSION"; \
	( sed -e "s/\@\@VERSION\@\@/$$VERSION/" munin-node.in ; \
	  cat plugins/*.sh ; \
	  echo main_loop) > $(MUNIN_NODE)
	@chmod +x $(MUNIN_NODE)
	
	
#~ 	PLSTR=""; \
#~ 	for PLGIN in $(PLUGINS); \
#~ 	do \
#~ 	  echo "Adding plugin $$PLGIN"; \
#~ 	  PLSTR=$$(echo "$$PLSTR"; grep -v '^#' plugins/$$PLGIN); \
#~ 	done; \
#~ 	PLSTR=$$(echo "$$PLSTR" | sed -e 's/\\/\\\\/g' \
#~ 		      	            -e 's/\//\\\//g' \
#~ 				    -e 's/\$$/\\$$/g'); \
#~ 	perl -p -e \
#~ 	  "s/\@\@VERSION\@\@/$$VERSION/;s/\@\@CONF\@\@/$$CONF/;s/\@\@PLUGINS\@\@/$(PLUGINS)/;s/\@\@PLSTR\@\@/$$PLSTR/;" \
#~ 	  munin-node.in > $(MUNIN_NODE)
#~ 	@chmod +x $(MUNIN_NODE)

	
all: $(MUNIN_NODE)
     
clean-node:
	@echo "Removing munin-node"
	@rm -f $(MUNIN_NODE)

clean-tgz: 
	@echo "Old releases"
	@rm -rf releases

clean: clean-node
	
clean-all: clean-node clean-tgz

tgz: clean-node
	@VERSION=$$(cat VERSION); \
 	echo "Building release/muninlite-$$VERSION.tar.gz"; \
	mkdir -p releases; \
	cp -ra . releases/muninlite-$$VERSION 2>/dev/null || true; \
	cd releases; \
	rm -rf muninlite-$$VERSION/releases; \
	rm -rf muninlite-$$VERSION/.svn; \
	tar zcvf muninlite-$$VERSION.tar.gz muninlite-$$VERSION >/dev/null; \
	rm -rf  muninlite-$$VERSION;
