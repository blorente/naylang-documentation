PDF := naylang.pdf  # PDF Main Target
MARKDOWN := introduction.md the_grace_programming_language.md \
						state_of_the_art.md \
						implementation.md \
						project_structure.md \
						execution_flow.md \
						parsing.md \
						ast.md \
						evaluator.md \
						methods_and_dispatch.md \
						object_model.md \
						heap.md \
						debug.md \
						frontend.md \
						modular_visitor_pattern.md \
						testing_methodology.md \
						conclusions.md \
						bibliography.md # Markdown files
APPENDICES := grace_grammar.md appendixB.md # Appendix after bibliography
METADATA := metadata.yaml  # Metadata files (Author, Date, Title, etc..)
BIBLIOGRAPHY := naylang.bib  # BibLaTeX bibliography
CSL := emerald-harvard.csl  # CSL file used for citations
TEMPLATE := template.tex  # LaTeX template for producing PDF

# Add src prefix to markdown files
MARKDOWN := $(addprefix src/, $(MARKDOWN))
APPENDICES := $(addprefix src/, $(APPENDICES))

#GRAPHS := $(wildcard graphs/*.tex)  # Latex diagrams
#IMAGES := $(wildcard images/*.png)  # .png images
# Generated PDF Images
#IMAGES += $(addprefix images/, $(notdir $(GRAPHS:.tex=.pdf)))

# Intermediate tex files required for appending after bibliography
APPENDIX := appendix.tex

all: $(PDF)

$(PDF): $(MARKDOWN) $(APPENDIX) $(TEMPLATE) $(BIBLIOGRAPHY) $(CSL) $(METADATA)
	pandoc --smart --standalone --latex-engine xelatex --template $(TEMPLATE) \
		--csl $(CSL) --table-of-contents \
		--top-level-division chapter --highlight-style haddock \
		--metadata geometry:top=2.5cm,left=4cm,right=2.5cm,bottom=2.5cm \
		--metadata date:"$(shell date +%Y/%m/%d)" \
		--metadata sansfont:"TeX Gyre Heros" \
		--metadata title:"Naylang" \
		--metadata subtitle:"A REPL interpreter and debugger for the Grace programming language." \
		--metadata date:"Director: José Luis Sierra Rodríguez" \
		--metadata keywords:"Intepreters","Programming Languages","Debuggers","Grace" \
		$(METADATA) $(MARKDOWN) --bibliography $(BIBLIOGRAPHY) --include-after-body $(APPENDIX) -o $@


# 		--top-level-division chapter --highlight-style breezedark \


# For standalone images
images/%.pdf: graphs/%.tex
	xelatex $< > /dev/null
	@mv $*.pdf images/
	@rm -f $*.log $*.aux

$(APPENDIX): $(APPENDICES)
	pandoc --smart --no-tex-ligatures --top-level-division chapter $(APPENDICES) -o $@

# Travis generation, only necessary because travis version of pandoc is old.
APPENDIX_TRAVIS := appendix_travis.tex

travis: $(MARKDOWN) $(APPENDIX_TRAVIS) $(TEMPLATE) $(IMAGES) $(BIBLIOGRAPHY) $(CSL) $(METADATA)
	pandoc --smart --standalone --latex-engine xelatex --template $(TEMPLATE) \
		--bibliography $(BIBLIOGRAPHY) --csl $(CSL) --table-of-contents \
		--chapters --highlight-style breezedark \
		--metadata date:"$(shell date +%Y/%m/%d)" \
		$(METADATA) $(MARKDOWN) --include-after-body $(APPENDIX_TRAVIS) \
		-o $(PDF)

$(APPENDIX_TRAVIS): $(APPENDICES)
	pandoc --no-tex-ligatures --chapters $(APPENDICES) -o $@

clean:
	rm -f images/*.pdf $(PDF) *.log *.aux appendix*
