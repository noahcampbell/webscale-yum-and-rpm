
webscale-yum-and-rpm.html:
	pandoc -t html -o $@ *.md

webscale-yum-and-rpm.pdf:
	markdown2pdf -o $@ *.md

%.pdf:
	markdown2pdf -o $@ -V fontsize:18pt $*.md
