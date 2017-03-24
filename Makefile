PDF := naylang.pdf  # PDF Main Target
MARKDOWN := introduction.md the_grace_programming_language.md state_of_the_art.md implementation.md # Markdown files
APPENDICES := appendixA.md appendixB.md  # Appendix after bibliography
METADATA := metadata.yaml  # Metadata files (Author, Date, Title, etc..)
BIBLIOGRAPHY := naylang.bib  # BibLaTeX bibliography
CSL := emerald-harvard.csl  # CSL file used for citations
TEMPLATE := template.tex  # LaTeX template for producing PDF

# Add src prefix to markdown files
MARKDOWN := $(addprefix src/, $(MARKDOWN))
APPENDICES := $(addprefix src/, $(APPENDICES))

GRAPHS := $(wildcard graphs/*.tex)  # Latex diagrams
IMAGES := $(wildcard images/*.png)  # .png images
# Generated PDF Images
IMAGES += $(addprefix images/, $(notdir $(GRAPHS:.tex=.pdf)))

# Intermediate tex files required for appending after bibliography
APPENDIX := appendices.tex

all: $(PDF)

$(PDF): $(MARKDOWN) $(APPENDIX) $(TEMPLATE) $(IMAGES) $(BIBLIOGRAPHY) $(CSL) $(METADATA)
	pandoc --smart --standalone --latex-engine xelatex --template $(TEMPLATE) \
		--bibliography $(BIBLIOGRAPHY) --csl $(CSL) --table-of-contents \
		--top-level-division chapter --metadata date:"$(shell date +%Y/%m/%d)" \
		--metadata sansfont:"TeX Gyre Heros" \
		--verbose \
		$(METADATA) $(MARKDOWN) --include-after-body $(APPENDIX) -o $@

# For standalone images
images/%.pdf: graphs/%.tex
	xelatex $< > /dev/null
	mv $*.pdf images/
	rm -f $*.log $*.aux

$(APPENDIX): $(APPENDICES)
	pandoc --smart --no-tex-ligatures --top-level-division chapter $(APPENDICES) -o $@

# Travis generation, only necessary because travis version of pandoc is old.
BODY_TRAVIS := body_travis.tex

travis: $(BODY_TRAVIS) $(APPENDIX_TRAVIS) $(TEMPLATE) $(IMAGES)
	pandoc --smart --standalone --latex-engine xelatex --template $(TEMPLATE) \
		--table-of-contents --chapters \
		--metadata author:"Borja Lorente Escobar" --metadata title:Naylang \
		--metadata subtitle:"A REPL interpreter and debugger for the Grace educational programming language" \
		--metadata date:2017-02-18 --metadata documentclass:scrreprt \
		--metadata colorlinks --metadata lof --metadata papersize:A4 \
		--metadata fontsize:12pt --metadata mainlang:English \
		--verbose \
		--metadata keywords:"[Keywords]" \
		$(BODY_TRAVIS) $(APPENDIX_TRAVIS) -o $(PDF)

$(BODY_TRAVIS): $(MARKDOWN) $(BIBLIOGRAPHY) $(CSL)
	pandoc --no-tex-ligatures --chapters --bibliography $(BIBLIOGRAPHY) --csl \
		$(CSL) $(MARKDOWN) -o $@

$(APPENDIX_TRAVIS): $(APPENDICES)
	pandoc --no-tex-ligatures --chapters $(APPENDICES) -o $@


clean:
	rm -f images/*.pdf $(PDF) *.log *.aux $(BODY) $(APPENDIX) appendix*
