# -*- coding: utf-8; mode: makefile-gmake -*-

include utils/makefile.include
include utils/makefile.python
include utils/makefile.sphinx

GIT_URL   = https://github.com/return42/handsOn.git
SLIDES    = docs/slides
#PYOBJECTS = xxxx

all: clean pylint pytest build docs

PHONY += help
help:
	@echo  '  docs	- build documentation'
	@echo  '  clean	- remove most generated files'
	@echo  '  rqmts	- info about build requirements'
	@echo  ''
	@$(MAKE) -s -f utils/makefile.include make-help
	@echo  ''
	@$(MAKE) -s -f utils/makefile.sphinx docs-help

PHONY += docs
docs:  sphinx-doc slides
	$(call cmd,sphinx,html,docs,docs)

PHONY += slides
slides: git-slide cdb-slide
	cd $(DOCS_DIST)/slides; zip -r git.zip git
	cd $(DOCS_DIST)/slides; zip -r cdb.zip cdb

PHONY += git-slide
git-slide:  sphinx-doc
	$(call cmd,sphinx,html,$(SLIDES)/git,$(SLIDES)/git,slides/git)

PHONY += cdb-slide
cdb-slide:  sphinx-doc
	$(call cmd,sphinx,html,$(SLIDES)/cdb,$(SLIDES)/cdb,slides/cdb)

PHONY += clean
clean: pyclean docs-clean
	$(call cmd,common_clean)

PHONY += rqmts
rqmts: msg-python-exe msg-virtualenv-exe

.PHONY: $(PHONY)
