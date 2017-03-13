PDF := naylang.pdf  # PDF Main Target
MARKDOWN := introduction.md state_of_the_art.md workflow.md milestones.md \
	risk_analysis.md interface.md implementation.md type_checking.md \
	postmortem.md  # Markdown files
MARKDOWN_COMPLUTENSE := introduction.md focus.md state_of_the_art.md \
	workflow.md milestones.md risk_analysis.md interface.md implementation.md \
	type_checking.md postmortem.md
APPENDICES := appendixA.md appendixB.md  # Appendix after bibliography
METADATA := metadata.yaml  # Metadata files (Author, Date, Title, etc..)
BIBLIOGRAPHY := naylang.bib  # BibLaTeX bibliography
CSL := emerald-harvard.csl  # CSL file used for citations
TEMPLATE := template.tex  # LaTeX template for producing PDF

# Add src prefix to markdown files
MARKDOWN := $(addprefix src/, $(MARKDOWN))
MARKDOWN_COMPLUTENSE := $(addprefix src/, $(MARKDOWN_COMPLUTENSE))
APPENDICES := $(addprefix src/, $(APPENDICES))

GRAPHS := $(wildcard graphs/*.tex)  # Latex diagrams
IMAGES := $(wildcard images/*.png)  # .png images
# Generated PDF Images
IMAGES += $(addprefix images/, $(notdir $(GRAPHS:.tex=.pdf)))

# Intermediate tex files required for appending after bibliography
BODY := body.tex
APPENDIX := appendices.tex
BODY_COMPLUTENSE := body_complutense.tex

all: $(PDF)

$(PDF): $(BODY) $(APPENDIX) $(TEMPLATE) $(IMAGES)
	pandoc --smart --standalone --latex-engine xelatex --template $(TEMPLATE) \
		--table-of-contents --top-level-division chapter \
		--metadata author:"Borja Lorente Escobar" --metadata title:Naylang \
		--metadata subtitle:"A REPL interpreter and debugger for the Grace educational programming language." \
		--metadata date:"$(shell date +%Y/%m/%d)" --metadata documentclass:scrreprt \
		--metadata sansfont:"TeX Gyre Heros" --metadata colorlinks \
		--metadata lof --metadata papersize:A4 --metadata fontsize:12pt \
		--metadata mainlang:English \
		--metadata keywords: \
		--metadata abstract:"[Abstract goes here]" \
		$(BODY) $(APPENDIX) -o $@


complutense: $(BODY_COMPLUTENSE) $(APPENDIX) $(TEMPLATE) $(IMAGES)
	pandoc --smart --standalone --latex-engine xelatex --template $(TEMPLATE) \
		--table-of-contents --top-level-division chapter \
		--metadata author:"Borja Lorente Escobar" \
		--metadata title:"A REPL interpreter and debugger for the Grace educational programming language" \
		--metadata date:"Director: José Luis Sierra" \
		--metadata documentclass:scrreprt \
		--metadata sansfont:"TeX Gyre Heros" --metadata colorlinks \
		--metadata lof --metadata papersize:A4 --metadata fontsize:12pt \
		--metadata mainlang:English \
		--metadata keywords:"[Keywords]" \
		--metadata titlepic:images/fdi.png $(BODY_COMPLUTENSE) $(APPENDIX) \
		-o $(PDF)


# For standalone images
images/%.pdf: graphs/%.tex
	xelatex $< > /dev/null
	mv $*.pdf images/
	rm -f $*.log $*.aux

$(BODY): $(MARKDOWN) $(BIBLIOGRAPHY) $(CSL)
	pandoc --no-tex-ligatures --top-level-division chapter \
		--bibliography $(BIBLIOGRAPHY) --csl $(CSL) $(MARKDOWN) -o $@


$(BODY_COMPLUTENSE): $(MARKDOWN_COMPLUTENSE) $(BIBLIOGRAPHY) $(CSL)
	pandoc --no-tex-ligatures --top-level-division chapter --table -of-contents \
		--bibliography $(BIBLIOGRAPHY) --csl $(CSL) $(MARKDOWN_COMPLUTENSE) \
		-o $@

$(APPENDIX): $(APPENDICES)
	pandoc --no-tex-ligatures --top-level-division chapter $(APPENDICES) -o $@

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
		--metadata keywords:"[Keywords]" \
		$(BODY_TRAVIS) $(APPENDIX_TRAVIS) -o $(PDF)

$(BODY_TRAVIS): $(MARKDOWN) $(BIBLIOGRAPHY) $(CSL)
	pandoc --no-tex-ligatures --chapters --bibliography $(BIBLIOGRAPHY) --csl \
		$(CSL) $(MARKDOWN) -o $@

$(APPENDIX_TRAVIS): $(APPENDICES)
	pandoc --no-tex-ligatures --chapters $(APPENDICES) -o $@


clean:
	rm -f images/*.pdf $(PDF) *.log *.aux $(BODY) $(APPENDIX)
