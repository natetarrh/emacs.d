BATCH = emacs -Q --batch

LOADDEFS = nt-emacs-autoloads.el
ELS = $(shell find lisp -maxdepth 1 \
	-type f \( -name "*.el" -and ! -name "$(LOADDEFS)" \) -print)

lisp/$(LOADDEFS): $(ELS)
	cd lisp && $(BATCH) -l package --eval \
	  '(package-generate-autoloads "nt-emacs" default-directory)'
