
webscale-yum-and-rpm.html:
	pandoc -t html -o $@ *.md

webscale-yum-and-rpm.pdf:
	@ls *.md
	markdown2pdf --xetex --template=bookformat.template -o $@ *.md

%.pdf:
	markdown2pdf --xetex --template=bookformat.template -o $@ $*.md

.PHONY: clean

clean:
	@rm -f *.pdf *.html