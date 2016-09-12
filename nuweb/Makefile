all : myscrapexamp.pdf
.PHONY : all



NUWEB=/usr/local/bin/nuweb
.SUFFIXES: .pdf .w .tex .html .aux .log .php

FIGFILES=fileschema

FIGFILENAMES=$(foreach fil,$(FIGFILES), $(fil).fig)
PDFT_NAMES=$(foreach fil,$(FIGFILES), $(fil).pdftex_t)
PDF_FIG_NAMES=$(foreach fil,$(FIGFILES), $(fil).pdftex)
PST_NAMES=$(foreach fil,$(FIGFILES), $(fil).pstex_t)
PS_FIG_NAMES=$(foreach fil,$(FIGFILES), $(fil).pstex)

W2PDF=../nuweb/bin/w2pdf
HTML_PS_FIG_NAMES=$(foreach fil,$(FIGFILES), m4_htmldocdir/$(fil).pstex)
HTML_PST_NAMES=$(foreach fil,$(FIGFILES), m4_htmldocdir/$(fil).pstex_t)
MKDIR = mkdir -p

 

%.eps: %.fig
	fig2dev -L eps $< > $@

%.pstex: %.fig
	fig2dev -L pstex $< > $@

.PRECIOUS : %.pstex
%.pstex_t: %.fig %.pstex
	fig2dev -L pstex_t -p $*.pstex $< > $@

%.pdftex: %.fig
	fig2dev -L pdftex $< > $@

.PRECIOUS : %.pdftex
%.pdftex_t: %.fig %.pstex
	fig2dev -L pdftex_t -p $*.pdftex $< > $@

%.pdf : %.w $(W2PDF)  $(PDF_FIG_NAMES) $(PDFT_NAMES)
	chmod 775 $(W2PDF)
	$(W2PDF) $*

m4_htmldocdir/%.pstex : %.pstex
	cp  $< $@

m4_htmldocdir/%.pstex_t : %.pstex_t
	cp  $< $@


m4_myscrapexamp.w : a_myscrapexamp.w
	gawk '{if(match($$0, "@%")) {printf("%s", substr($$0,1,RSTART-1))} else print}' a_myscrapexamp.w \
          | gawk '{gsub(/[\\][\$$]/, "$$");print}'  > m4_myscrapexamp.w

myscrapexamp.w : m4_myscrapexamp.w
	m4 -P m4_myscrapexamp.w > myscrapexamp.w

bibfile : myscrapexamp.aux /home/paul/bin/mkportbib
	/home/paul/bin/mkportbib myscrapexamp litprog

.PHONY : bibfile
$(W2PDF) : myscrapexamp.w
	$(NUWEB) myscrapexamp.w
m4_htmlsource : myscrapexamp.w
	cp  myscrapexamp.w m4_htmlsource

m4_4htfildest : m4_4htfilsource
	cp m4_4htfilsource m4_4htfildest

m4_htmlbibfil : m4_anuwebdir/myscrapexamp.bib
	cp m4_anuwebdir/myscrapexamp.bib m4_htmlbibfil

m4_htmltarget : m4_htmlsource m4_4htfildest $(HTML_PS_FIG_NAMES) $(HTML_PST_NAMES) m4_htmlbibfil
	cp w2html /home/paul/projecten/cltl/emoeco/myscrapexamp/bin
	cd /home/paul/projecten/cltl/emoeco/myscrapexamp/bin && chmod 775 w2html
	cd m4_htmldocdir && /home/paul/projecten/cltl/emoeco/myscrapexamp/bin/w2html myscrapexamp.w


pdf : myscrapexamp.pdf

print : myscrapexamp.pdf
	lpr myscrapexamp.pdf

view : myscrapexamp.pdf
	evince myscrapexamp.pdf

html : m4_htmltarget

DIRS = ../nuweb/bin 

$(DIRS) : 
	$(MKDIR) $@

sources : myscrapexamp.w $(DIRS)
	$(NUWEB) myscrapexamp.w

test : sources
	cd .. && python scrape.py 1051970


