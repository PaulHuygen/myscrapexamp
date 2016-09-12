m4_include(inst.m4)m4_dnl
\documentclass[twoside]{artikel3}
\pagestyle{headings}
\usepackage{pdfswitch}
\usepackage{figlatex}
\usepackage{makeidx}
\renewcommand{\indexname}{General index}
\makeindex
\newcommand{\thedoctitle}{m4_doctitle}
\newcommand{\theauthor}{m4_author}
\newcommand{\thesubject}{m4_subject}
\newcommand{\NAF}{\textsc{naf}}
\title{\thedoctitle}
\author{\theauthor}
\date{m4_docdate}
m4_include(texinclusions.m4)m4_dnl
\begin{document}
\maketitle
\begin{abstract}
  In this document a web-scraper is constructed that scrapes the forum
  \url{m4_tarurl}, using Python and Beautifulsoup.
\end{abstract}
\tableofcontents

\section{Introduction}
\label{sec:Introduction}

\begin{itemize}
\item Scrape a forum on a website.
\item In this case \url{m4_tarurl}.
\item Use Python and Beautifulsoup.
\end{itemize}

\subsection{Structure of the forum}
\label{sec:forumstructure}

The forum consists of a set of \emph{boards} with different
subjects. Each board has an identifying number and a name, e.g. board
m4_CEVTboardnum is about \emph{Current Events}, abbreviated as
\textsc{cevt}. The main page of that board has as \textsc{url}:
\url{m4_tarurl/board/m4_CEVTboardnum}. It contains a table with a list
of topics and, when there are too many topics for a single page, references to other \textsc{url}'s that contain lists of
older topics. These \textsc{url}'s look like
\url{m4_tarurl/board/m4_CEVTboardnum/page/2}.

A topic has as url e.g. \url{m4_tarurl/topic/1061702} and a title. The
page of the topic contains a list of posts. 

\subsection{What are we going to do?}
\label{sec:what}

\begin{enumerate}
\item Read the pages of the board and collect the url's of the topics
\item Read the pages of the topics and extract the posts.
\item Wrap each post (text and metadata) in a \textsc{naf} file.
\end{enumerate}

\subsection{Metadata}
\label{sec:metadata}

We need to collect for each post the following metadata:
\begin{enumerate}
\item board name and ID.
\item Topic name and ID.
\item Sequence number of the post in the topic.
\item Author ID.
\item Date of the post.
\end{enumerate}

To test whether we have gathered a post with the correct metadata, we
can print it as follows:

@d methods of the main program @{@%
def print_post(board_id, board_name, topic, seq, author, post_date, text):
    print( "Board:   {} ({})".format(board_id, board_name))
    print( "Topic:   {}".format(topic))
    print( "Post nr: {}".format(seq))
    print( "Date:    {}".format(post_date))
    print( "Text: {}".format(text))

@| print_post @}


\section{The program}
\label{sec:program}


\subsection{Read the command-line}
\label{sec:read-commandline}

I this demo-phase we can either parse url \url{m4_topicURL}, or parse
a file of which the name is mentioned in the first argument.


@d get program options @{@%
boardnum = m4_CEVTboardnum
topicURL = "m4_topicURL"

infile = 'none'
if len(sys.argv) > 1:
    infile = sys.argv[1]

@| boardnum topicURL @}

\subsection{BeautifulSoup}
\label{sec:beautifulsoup}

We will use Python's \href{https://pypi.python.org/pypi/beautifulsoup4}{BeautifulSoup} module to extract the posts
from the forum. 

@d import modules in main program @{@%
from bs4 import BeautifulSoup
import requests
@| bs4 BeautifulSoup requests @}

\subsection{Extract the posts from a topic page}
\label{sec:extractpost}

A topic page contains a number of posts, wrapped in
\verb|<article>|/\verb|</article>| tags. Between these two tags we can
find:
\begin{description}
\item[Post-id:] as argument ``id'' in the \verb|article| tag.
\item[Author name:] In a tag ``header'', in a \verb|div|
  ``author-and-time'', in an anchor of class ``author-name''.
\end{description}


@d methods of the main program @{@%

def next_article(soup, postnum=0):
     for article in soup.find_all("article"):
         postnum += 1
         header = article.header
         for sp in header.find_all("span"):
             if sp['class'][0] == "postId":
                 postid = sp.string
             elif sp['class'][0] == "time":
                 posttime = sp.string
         for div in header.find_all("div"):
             if div['class'][0] =="author-and-time":
                 for anchor in div.find_all("a"):
                     if anchor['class'][0] == "author-name":
                         author=anchor.string
                         author_url = anchor.href
         text = article.textarea.string         
         yield [ postid, posttime, postnum, author, author_url, text ] 

@| nextarticle @}


\subsection{Generate the NAF file}
\label{sec:Generate-naf}


Generate the \NAF{} file with the \href{https://github.com/cltl/KafNafParserPy}{KafNafParserPy} package. 

@d import modules in main program @{@%
import KafNafParserPy
@| @}

If you construct a \naf{} from scratch, it doesn't have a header section. To work around this, we read in a template of a \NAF{} file
that contains an empty header. Fill in the header, add a \verb|raw| tag with the textof the post and write out to a file that is named after the \textsc{id} of the post:

@d methods of the main program @{@%
def printnaf(post_id, topic, author, post_date, text):
    naf = KafNafParserPy.KafNafParser(filename = 'template.naf')
    naf.set_language("en")
    outtext = Contents_block(text)
    naf.set_raw(outtext.without_bbcode())
    @< create the naf header @>
    naf.dump(filename = str(post_id) + ".naf")

@| printnaf @}

@o ../template.naf @{@%
<?xml version="1.0" encoding="UTF-8"?>
<NAF>
  <nafHeader></nafHeader>
</NAF>

@| @}

The following metadata goes in the \NAF{} header:
\begin{itemize}
\item Topic
\item Author
\item Date of the post.
\end{itemize}

@d create the naf header @{@%
header = naf.get_header()
fileDesc = KafNafParserPy.CfileDesc()
header.set_fileDesc(fileDesc)
fileDesc.set_title(topic)
fileDesc.set_author(author)
fileDesc.set_creationtime(convert_timestring(post_date))
@| @}

Find the time of the post. The time is expressed as a string like \verb|Mar 22 22:48|. This must be converted to an \textsc{iso} 8601 format. Therefore,
create a datetime object from the time-string. The year does not seem to be included in the timestring. we have to solve this later.

@d methods of the main program @{@%
def convert_timestring(post_string):
    [ monthname, daynum, time_of_day ] = post_string.split()
    [ hour, minute ] = time_of_day.split(':')
    year = 2016
    pubdate = datetime.datetime(year, monthnums[monthname], int(daynum), int(hour), int(minute))
    return pubdate.isoformat()

    
@| convert_timestring @}

To convert month-names (e.g. ``Jan'') to month-numbers (e.g. 1), use the following dictionary. 

@d variables of the main program @{@%
monthnums = {v: k for k,v in enumerate(calendar.month_abbr)}
@| monthnums @}


@d import modules in main program @{@%
import datetime
import calendar
@| datetime calendar@}

\subsection{Remove mark-up from the text}
\label{sec:nomarkup}

The \textsc{html} pages of Ragingbull contain the text od the posts as \textsc{html} code or as ``bb-code''. A concise guide for bb-code can be found \href{https://msparp.com/bbcodeguide}{here}. 

\begin{tabular}{lll}
\textbf{tag}                      & \textbf{description} & \textbf{action} \\
  \verb|[b], [/b]:                & boldface           & remove mark-up\\
  \verb|[i], [/i]:                & italic             & remove mark-up \\
  \verb|[u], [/u]:                & underline          & remove mark-up \\
  \verb|[s], [/s]:                & strike-through     & remove tag \\
  \verb|[color], [/color]:        & back-ground color  & remove mark-up \\
  \verb|[center], [/center]:      & centered text      & remove mark-up \\
  \verb|[quote], [/quote]:        & quotation          & Add quotation marks \\
  \verb|[quote={name}], [/quote]: & quotation          & \verb|name said: `` ... ''\\
  \verb|[url], [/url]:            & Link               & remove mark-up \\
  \verb|[url={url}], [/url]:      & Link               & Leave the text. \\
  \verb|[img ...], [/img]:        & image              & replace by ``image'' \\
  \verb|[ul], [/ul]:              & Unordened list     & remove mark-up \\
  \verb|[ol], [/ol]:              & ordened list       & remove mark-up \\
  \verb|[list], [/list]:          & list               & remove mark-up \\
  \verb|[li], [/li]:              & list item          &  \\
  \verb|[code], [/code]:          & Verbatim           &  \\
  \verb|[table], [/table]:        & table              &  \\
  \verb|[tr], [/tr]:              & teble row          &  \\
  \verb|[th], [/th]:              & table heading      &  \\
  \verb|[td], [/td]:              & table cell         &  \\
  \verb|[youtube], [/youtube]:    & URL to Youtube     &  remove mark-up \\
  \verb|[gvideo], [/gvideo]:      & URL to video       &  remove mark-up \\
\end{tabular}

@d methods of the main program @{@%

class Contents_block:
        def __init__(self,intext):
             self.intext = intext

        def _strip_bbtag(self, intext, tagname):
             s1 = intext.replace('[' + tagname + ']', '')
             return s1.replace('[/' + tagname + ']', '')

        def _strip_bbtagged_substring(self, intext, tagname):
             pattern = re.compile('\[' + tagname + '\].*\[/' + tagname + '\]')
             return re.sub(pattern, '', intext)

        def _replace_bbtagged_substring(self, intext, tagname, repl):
             pattern = re.compile('\[' + tagname + '\].*\[/' + tagname + '\]')
             return re.sub(pattern, repl, intext)

        def _unquote(self, intext):
             out = self._strip_bbtag(intext, 'quote')
             pattern = re.compile('\[quote=(.*)\](.*)\[/quote\]')
             out = re.sub(pattern, '\1 said: "\2"', out)
             return out

        def _un_url(self, intext):
             out = self._strip_bbtag(intext, 'url')
             pattern = re.compile('\[url=(.*)\](.*)\[/url\]')
             out = re.sub(pattern, '\2' + ' (' + '\1' + ')', out)
             return out


        def without_bbcode(self):
             out = self._strip_bbtag(self.intext, 'b')
             out = self._strip_bbtag(out, 'i')
             out = self._strip_bbtag(out, 'u')
             out = self._strip_bbtag(out, 'color')
             out = self._strip_bbtag(out, 'youtube')
             out = self._strip_bbtag(out, 'gvideo')
             out = self._strip_bbtagged_substring(out, 's')
             out = self._strip_bbtagged_substring(out, 'img')
             out = self._unquote(out)
             return out   

@| @}

@d import modules in main program @{@%
import re
@|re  @}



\subsection{Test with a single "topic" page}
\label{sec:testsetup}

@d methods of the main program @{@%
def get_testsoup():
    if infile == 'none':
        r = requests.get('m4_topicURL')
        if r.status_code != 200:
             print("Http request result: {}".format(r.status_code))
             print("Error exit")
             sys.exit()
        soup = BeautifulSoup(r.content, 'lxml')
    else:
        with open(infile, 'r') as content_file:
            content = content_file.read()
        soup = BeautifulSoup(content, 'lxml')
    return soup
@| @}


\subsection{The program file}
\label{sec:program-file}

@o ../scrape.py @{@%

@< import modules in main program @>
import sys
@< variables of the main program @>
@< methods of the main program @>

if __name__ == "__main__" :
    @< get program options @>
@%    @< collect the URL's of the topics @>
@%    @< print the testpost @>
    soup = get_testsoup()
    seq = 0
    for [postid, posttime, postnum, author, author_url, text] in  next_article(soup):
        seq += 1
@%        print( "Author: {}".format(author))
        printnaf(postid, "topic", author, posttime, text)
@| @}


For now, the program just prints a mock-up of a post:

@d print the testpost @{@%
print_post(boardnum, "CEVT", "Gallup: life got better", 1, "juddism", datetime.datetime.now(), "Come on now")
@| @}





\appendix

\section{How to read and translate this document}
\label{sec:translatedoc}

This document is an example of \emph{literate
  programming}~\cite{Knuth:1983:LP}. It contains the code of all sorts
of scripts and programs, combined with explaining texts. In this
document the literate programming tool \texttt{nuweb} is used, that is
currently available from Sourceforge
(URL:\url{m4_nuwebURL}). The advantages of Nuweb are, that
it can be used for every programming language and scripting language, that
it can contain multiple program sources and that it is very simple.


\subsection{Read this document}
\label{sec:read}

The document contains \emph{code scraps} that are collected into
output files. An output file (e.g. \texttt{output.fil}) shows up in the text as follows:

\begin{alltt}
"output.fil" \textrm{4a \(\equiv\)}
      # output.fil
      \textrm{\(<\) a macro 4b \(>\)}
      \textrm{\(<\) another macro 4c \(>\)}
      \(\diamond\)

\end{alltt}

The above construction contains text for the file. It is labelled with
a code (in this case 4a)  The constructions between the \(<\) and
\(>\) brackets are macro's, placeholders for texts that can be found
in other places of the document. The test for a macro is found in
constructions that look like:

\begin{alltt}
\textrm{\(<\) a macro 4b \(>\) \(\equiv\)}
     This is a scrap of code inside the macro.
     It is concatenated with other scraps inside the
     macro. The concatenated scraps replace
     the invocation of the macro.

{\footnotesize\textrm Macro defined by 4b, 87e}
{\footnotesize\textrm Macro referenced in 4a}
\end{alltt}

Macro's can be defined on different places. They can contain other macro´s.

\begin{alltt}
\textrm{\(<\) a scrap 87e \(>\) \(\equiv\)}
     This is another scrap in the macro. It is
     concatenated to the text of scrap 4b.
     This scrap contains another macro:
     \textrm{\(<\) another macro 45b \(>\)}

{\footnotesize\textrm Macro defined by 4b, 87e}
{\footnotesize\textrm Macro referenced in 4a}
\end{alltt}


\subsection{Process the document}
\label{sec:processing}

The raw document is named
\verb|a_<!!>m4_progname<!!>.w|. Figure~\ref{fig:fileschema}
\begin{figure}[hbtp]
  \centering
  \includegraphics{fileschema.fig}
  \caption{Translation of the raw code of this document into
    printable/viewable documents and into program sources. The figure
    shows the pathways and the main files involved.}
  \label{fig:fileschema}
\end{figure}
 shows pathways to
translate it into printable/viewable documents and to extract the
program sources. Table~\ref{tab:transtools}
\begin{table}[hbtp]
  \centering
  \begin{tabular}{lll}
    \textbf{Tool} & \textbf{Source} & \textbf{Description} \\
    gawk  & \url{www.gnu.org/software/gawk/}& text-processing scripting language \\
    M4    & \url{www.gnu.org/software/m4/}& Gnu macro processor \\
    nuweb & \url{nuweb.sourceforge.net} & Literate programming tool \\
    tex   & \url{www.ctan.org} & Typesetting system \\
    tex4ht & \url{www.ctan.org} & Convert \TeX{} documents into \texttt{xml}/\texttt{html}
  \end{tabular}
  \caption{Tools to translate this document into readable code and to
    extract the program sources}
  \label{tab:transtools}
\end{table}
lists the tools that are
needed for a translation. Most of the tools (except Nuweb) are available on a
well-equipped Linux system.

@%\textbf{NOTE:} Currently, not the most recent version  of Nuweb is used, but an older version that has been modified by me, Paul Huygen.

@d parameters in Makefile @{@%
NUWEB=m4_nuwebbinary
@| @}


\subsection{Translate and run}
\label{sec:transrun}

This chapter assembles the Makefile for this project.

@o Makefile -t @{@%
@< default target @>

@< parameters in Makefile @> 

@< impliciete make regels @>
@< expliciete make regels @>
@< make targets @>
@| @}

The default target of make is \verb|all|.

@d  default target @{@%
all : @< all targets @>
.PHONY : all

@|PHONY all @}


One of the targets is certainly the \textsc{pdf} version of this
document.

@d all targets @{m4_progname.pdf@}

We use many suffixes that were not known by the C-programmers who
constructed the \texttt{make} utility. Add these suffixes to the list.

@d parameters in Makefile @{@%
.SUFFIXES: .pdf .w .tex .html .aux .log .php

@| SUFFIXES @}



\subsection{Pre-processing}
\label{sec:pre-processing}

To make usable things from the raw input \verb|a_<!!>m4_progname<!!>.w|, do the following:

\begin{enumerate}
\item Process \verb|\$| characters.
\item Run the m4 pre-processor.
\item Run nuweb.
\end{enumerate}

This results in a \LaTeX{} file, that can be converted into a \pdf{}
or a \HTML{} document, and in the program sources and scripts.

\subsubsection{Process `dollar' characters }
\label{sec:procdollars}

Many ``intelligent'' \TeX{} editors (e.g.\ the auctex utility of
Emacs) handle \verb|\$| characters as special, to switch into
mathematics mode. This is irritating in program texts, that often
contain \verb|\$| characters as well. Therefore, we make a stub, that
translates the two-character sequence \verb|\\$| into the single
\verb|\$| character.


@d expliciete make regels @{@%
m4_<!!>m4_progname<!!>.w : a_<!!>m4_progname<!!>.w
@%	gawk '/^@@%/ {next}; {gsub(/[\\][\\$\$]/, "$$");print}' a_<!!>m4_progname<!!>.w > m4_<!!>m4_progname<!!>.w
	gawk '{if(match($$0, "@@<!!>%")) {printf("%s", substr($$0,1,RSTART-1))} else print}' a_<!!>m4_progname.w \
          | gawk '{gsub(/[\\][\\$\$]/, "$$");print}'  > m4_<!!>m4_progname<!!>.w
@% $

@| @}

@%@d expliciete make regels @{@%
@%m4_<!!>m4_progname<!!>.w : a_<!!>m4_progname<!!>.w
@%	gawk '/^@@%/ {next}; {gsub(/[\\][\\$\$]/, "$$");print}' a_<!!>m4_progname<!!>.w > m4_<!!>m4_progname<!!>.w
@%
@%@% $
@%@| @}

\subsubsection{Run the M4 pre-processor}
\label{sec:run_M4}

@d  expliciete make regels @{@%
m4_progname<!!>.w : m4_<!!>m4_progname<!!>.w
	m4 -P m4_<!!>m4_progname<!!>.w > m4_progname<!!>.w

@| @}


\subsection{Typeset this document}
\label{sec:typeset}

Enable the following:
\begin{enumerate}
\item Create a \pdf{} document.
\item Print the typeset document.
\item View the typeset document with a viewer.
\item Create a \HTML document.
\end{enumerate}

In the three items, a typeset \pdf{} document is required or it is the
requirement itself.




\subsubsection{Figures}
\label{sec:figures}

This document contains figures that have been made by
\texttt{xfig}. Post-process the figures to enable inclusion in this
document.

The list of figures to be included:

@d parameters in Makefile @{@%
FIGFILES=fileschema

@| FIGFILES @}

We use the package \texttt{figlatex} to include the pictures. This
package expects two files with extensions \verb|.pdftex| and
\verb|.pdftex_t| for \texttt{pdflatex} and two files with extensions \verb|.pstex| and
\verb|.pstex_t| for the \texttt{latex}/\texttt{dvips}
combination. Probably tex4ht uses the latter two formats too.

Make lists of the graphical files that have to be present for
latex/pdflatex:

@d parameters in Makefile @{@%
FIGFILENAMES=\$(foreach fil,\$(FIGFILES), \$(fil).fig)
PDFT_NAMES=\$(foreach fil,\$(FIGFILES), \$(fil).pdftex_t)
PDF_FIG_NAMES=\$(foreach fil,\$(FIGFILES), \$(fil).pdftex)
PST_NAMES=\$(foreach fil,\$(FIGFILES), \$(fil).pstex_t)
PS_FIG_NAMES=\$(foreach fil,\$(FIGFILES), \$(fil).pstex)

@|FIGFILENAMES PDFT_NAMES PDF_FIG_NAMES PST_NAMES PS_FIG_NAMES@}


Create
the graph files with program \verb|fig2dev|:

@d impliciete make regels @{@%
%.eps: %.fig
	fig2dev -L eps \$< > \$@@

%.pstex: %.fig
	fig2dev -L pstex \$< > \$@@

.PRECIOUS : %.pstex
%.pstex_t: %.fig %.pstex
	fig2dev -L pstex_t -p \$*.pstex \$< > \$@@

%.pdftex: %.fig
	fig2dev -L pdftex \$< > \$@@

.PRECIOUS : %.pdftex
%.pdftex_t: %.fig %.pstex
	fig2dev -L pdftex_t -p \$*.pdftex \$< > \$@@

@| fig2dev @}


\subsubsection{Bibliography}
\label{sec:bbliography}

To keep this document portable, create a portable bibliography
file. It works as follows: This document refers in the
\texttt|bibliography| statement to the local \verb|bib|-file
\verb|m4_progname.bib|. To create this file, copy the auxiliary file
to another file \verb|auxfil.aux|, but replace the argument of the
command \verb|\bibdata{m4_progname}| to the names of the bibliography
files that contain the actual references (they should exist on the
computer on which you try this). This procedure should only be
performed on the computer of the author. Therefore, it is dependent of
a binary file on his computer.


@d expliciete make regels @{@%
bibfile : m4_progname.aux m4_mkportbib
	m4_mkportbib m4_progname m4_bibliographies

.PHONY : bibfile
@| @}

\subsubsection{Create a printable/viewable document}
\label{sec:createpdf}

Make a \pdf{} document for printing and viewing.

@d make targets @{@%
pdf : m4_progname.pdf

print : m4_progname.pdf
	m4_printpdf(m4_progname)

view : m4_progname.pdf
	m4_viewpdf(m4_progname)

@| pdf view print @}

Create the \pdf{} document. This may involve multiple runs of nuweb,
the \LaTeX{} processor and the bib\TeX{} processor, and depends on the
state of the \verb|aux| file that the \LaTeX{} processor creates as a
by-product. Therefore, this is performed in a separate script,
\verb|w2pdf|.

\paragraph{The w2pdf script}
\label{sec:w2pdf}

The three processors nuweb, \LaTeX{} and bib\TeX{} are
intertwined. \LaTeX{} and bib\TeX{} create parameters or change the
value of parameters, and write them in an auxiliary file. The other
processors may need those values to produce the correct output. The
\LaTeX{} processor may even need the parameters in a second
run. Therefore, consider the creation of the (\pdf) document finished
when none of the processors causes the auxiliary file to change. This
is performed by a shell script \verb|w2pdf|.

@%@d make targets @{@%
@%m4_progname.pdf : m4_progname.w \$(FIGFILES)
@%	chmod 775 bin/w2pdf
@%	bin/w2pdf m4_progname
@%
@%@| @}



Note, that in the following \texttt{make} construct, the implicit rule
\verb|.w.pdf| is not used. It turned out, that make did not calculate
the dependencies correctly when I did use this rule.

@d  impliciete make regels@{@%
@%.w.pdf :
%.pdf : %.w \$(W2PDF)  \$(PDF_FIG_NAMES) \$(PDFT_NAMES)
	chmod 775 \$(W2PDF)
	\$(W2PDF) \$*

@| @}

The following is an ugly fix of an unsolved problem. Currently I
develop this thing, while it resides on a remote computer that is
connected via the \verb|sshfs| filesystem. On my home computer I
cannot run executables on this system, but on my work-computer I
can. Therefore, place the following script on a local directory.

@d parameters in Makefile @{@%
W2PDF=m4_nuwebbindir/w2pdf
@| @}

@d directories to create @{m4_nuwebbindir @| @}

@d expliciete make regels  @{@%
\$(W2PDF) : m4_progname.w
	\$(NUWEB) m4_progname.w
@| @}

m4_dnl
m4_dnl Open compile file.
m4_dnl args: 1) directory; 2) file; 3) Latex compiler
m4_dnl
m4_define(m4_opencompilfil,
<!@o !>\$1<!!>\$2<! @{@%
#!/bin/bash
# !>\$2<! -- compile a nuweb file
# usage: !>\$2<! [filename]
# !>m4_header<!
NUWEB=m4_nuwebbinary
LATEXCOMPILER=!>\$3<!
@< filenames in nuweb compile script @>
@< compile nuweb @>

@| @}
!>)m4_dnl

m4_opencompilfil(<!m4_nuwebbindir/!>,<!w2pdf!>,<!pdflatex!>)m4_dnl

@%@o w2pdf @{@%
@%#!/bin/bash
@%# w2pdf -- make a pdf file from a nuweb file
@%# usage: w2pdf [filename]
@%#  [filename]: Name of the nuweb source file.
@%`#' m4_header
@%echo "translate " \$1 >w2pdf.log
@%@< filenames in w2pdf @>
@%
@%@< perform the task of w2pdf @>
@%
@%@| @}

The script retains a copy of the latest version of the auxiliary file.
Then it runs the four processors nuweb, \LaTeX{}, MakeIndex and bib\TeX{}, until
they do not change the auxiliary file or the index. 

@d compile nuweb @{@%
NUWEB=m4_nuweb
@< run the processors until the aux file remains unchanged @>
@< remove the copy of the aux file @>
@| @}

The user provides the name of the nuweb file as argument. Strip the
extension (e.g.\ \verb|.w|) from the filename and create the names of
the \LaTeX{} file (ends with \verb|.tex|), the auxiliary file (ends
with \verb|.aux|) and the copy of the auxiliary file (add \verb|old.|
as a prefix to the auxiliary filename).

@d filenames in nuweb compile script @{@%
nufil=\$1
trunk=\${1%%.*}
texfil=\${trunk}.tex
auxfil=\${trunk}.aux
oldaux=old.\${trunk}.aux
indexfil=\${trunk}.idx
oldindexfil=old.\${trunk}.idx
@| nufil trunk texfil auxfil oldaux indexfil oldindexfil @}

Remove the old copy if it is no longer needed.
@d remove the copy of the aux file @{@%
rm \$oldaux
@| @}

Run the three processors. Do not use the option \verb|-o| (to suppres
generation of program sources) for nuweb,  because \verb|w2pdf| must
be kept up to date as well.

@d run the three processors @{@%
\$NUWEB \$nufil
\$LATEXCOMPILER \$texfil
makeindex \$trunk
bibtex \$trunk
@| nuweb makeindex bibtex @}


Repeat to copy the auxiliary file and the index file  and run the processors until the
auxiliary file and the index file are equal to their copies.
 However, since I have not yet been able to test the \verb|aux|
file and the \verb|idx| in the same test statement, currently only the
\verb|aux| file is tested.

It turns out, that sometimes a strange loop occurs in which the
\verb|aux| file will keep to change. Therefore, with a counter we
prevent the loop to occur more than m4_maxtexloops times.

@d run the processors until the aux file remains unchanged @{@%
LOOPCOUNTER=0
while
  ! cmp -s \$auxfil \$oldaux 
do
  if [ -e \$auxfil ]
  then
   cp \$auxfil \$oldaux
  fi
  if [ -e \$indexfil ]
  then
   cp \$indexfil \$oldindexfil
  fi
  @< run the three processors @>
  if [ \$LOOPCOUNTER -ge 10 ]
  then
    cp \$auxfil \$oldaux
  fi;
done
@| @}


\subsubsection{Create HTML files}
\label{sec:createhtml}

\textsc{Html} is easier to read on-line than a \pdf{} document that
was made for printing. We use \verb|tex4ht| to generate \HTML{}
code. An advantage of this system is, that we can include figures
in the same way as we do for \verb|pdflatex|.

Nuweb creates a \LaTeX{} file that is suitable
for \verb|latex2html| if the source file has \verb|.hw| as suffix instead of
\verb|.w|. However, this feature is not compatible with tex4ht.

Make html file:

@d make targets @{@%
html : m4_htmltarget

@| @}

The \HTML{} file depends on its source file and the graphics files.

Make lists of the graphics files and copy them.

@d parameters in Makefile @{@%
HTML_PS_FIG_NAMES=\$(foreach fil,\$(FIGFILES), m4_htmldocdir/\$(fil).pstex)
HTML_PST_NAMES=\$(foreach fil,\$(FIGFILES), m4_htmldocdir/\$(fil).pstex_t)
@| @}


@d impliciete make regels @{@%
m4_htmldocdir/%.pstex : %.pstex
	cp  \$< \$@@

m4_htmldocdir/%.pstex_t : %.pstex_t
	cp  \$< \$@@

@| @}

Copy the nuweb file into the html directory.

@d expliciete make regels @{@%
m4_htmlsource : m4_progname.w
	cp  m4_progname.w m4_htmlsource

@| @}

We also need a file with the same name as the documentstyle and suffix
\verb|.4ht|. Just copy the file \verb|report.4ht| from the tex4ht
distribution. Currently this seems to work.

@d expliciete make regels @{@%
m4_4htfildest : m4_4htfilsource
	cp m4_4htfilsource m4_4htfildest

@| @}

Copy the bibliography.

@d expliciete make regels  @{@%
m4_htmlbibfil : m4_anuwebdir/m4_progname.bib
	cp m4_anuwebdir/m4_progname.bib m4_htmlbibfil

@| @}



Make a dvi file with \texttt{w2html} and then run
\texttt{htlatex}. 

@d expliciete make regels @{@%
m4_htmltarget : m4_htmlsource m4_4htfildest \$(HTML_PS_FIG_NAMES) \$(HTML_PST_NAMES) m4_htmlbibfil
	cp w2html m4_abindir
	cd m4_abindir && chmod 775 w2html
	cd m4_htmldocdir && m4_abindir/w2html m4_progname.w

@| @}

Create a script that performs the translation.

@%m4_<!!>opencompilfil(m4_htmldocdir/,`w2dvi',`latex')m4_dnl


@o w2html @{@%
#!/bin/bash
# w2html -- make a html file from a nuweb file
# usage: w2html [filename]
#  [filename]: Name of the nuweb source file.
`#' m4_header
echo "translate " \$1 >w2html.log
NUWEB=m4_nuwebbinary
@< filenames in w2html @>

@< perform the task of w2html @>

@| @}

The script is very much like the \verb|w2pdf| script, but at this
moment I have still difficulties to compile the source smoothly into
\textsc{html} and that is why I make a separate file and do not
recycle parts from the other file. However, the file works similar.


@d perform the task of w2html @{@%
@< run the html processors until the aux file remains unchanged @>
@< remove the copy of the aux file @>
@| @}


The user provides the name of the nuweb file as argument. Strip the
extension (e.g.\ \verb|.w|) from the filename and create the names of
the \LaTeX{} file (ends with \verb|.tex|), the auxiliary file (ends
with \verb|.aux|) and the copy of the auxiliary file (add \verb|old.|
as a prefix to the auxiliary filename).

@d filenames in w2html @{@%
nufil=\$1
trunk=\${1%%.*}
texfil=\${trunk}.tex
auxfil=\${trunk}.aux
oldaux=old.\${trunk}.aux
indexfil=\${trunk}.idx
oldindexfil=old.\${trunk}.idx
@| nufil trunk texfil auxfil oldaux @}

@d run the html processors until the aux file remains unchanged @{@%
while
  ! cmp -s \$auxfil \$oldaux 
do
  if [ -e \$auxfil ]
  then
   cp \$auxfil \$oldaux
  fi
@%  if [ -e \$indexfil ]
@%  then
@%   cp \$indexfil \$oldindexfil
@%  fi
  @< run the html processors @>
done
@< run tex4ht @>

@| @}


To work for \textsc{html}, nuweb \emph{must} be run with the \verb|-n|
option, because there are no page numbers.

@d run the html processors @{@%
\$NUWEB -o -n \$nufil
latex \$texfil
makeindex \$trunk
bibtex \$trunk
htlatex \$trunk
@| @}


When the compilation has been satisfied, run makeindex in a special
way, run bibtex again (I don't know why this is necessary) and then run htlatex another time.
@d run tex4ht @{@%
m4_index4ht
makeindex -o \$trunk.ind \$trunk.4dx
bibtex \$trunk
htlatex \$trunk
@| @}


\paragraph{create the program sources}
\label{sec:createsources}

Run nuweb, but suppress the creation of the \LaTeX{} documentation.
Nuweb creates only sources that do not yet exist or that have been
modified. Therefore make does not have to check this. However,
``make'' has to create the directories for the sources if they
do not yet exist.
@%This is especially important for the directories
@%with the \HTML{} files. It seems to be easiest to do this with a shell
@%script.
So, let's create the directories first.

@d parameters in Makefile @{@%
MKDIR = mkdir -p

@| MKDIR @}



@d make targets @{@%
DIRS = @< directories to create @>

\$(DIRS) : 
	\$(MKDIR) \$@@

@| DIRS @}


@d make targets @{@%
sources : m4_progname.w \$(DIRS)
@%	cp ./createdirs m4_bindir/createdirs
@%	cd m4_bindir && chmod 775 createdirs
@%	m4_bindir/createdirs
	\$(NUWEB) m4_progname.w

test : sources
	cd .. && python scrape.py m4_testfile

@| @}

@%@o createdirs @{@%
@%#/bin/bash
@%# createdirs -- create directories
@%`#' m4_header
@%@< create directories @>
@%@| @}


\section{References}
\label{sec:references}

\subsection{Literature}
\label{sec:literature}

\bibliographystyle{plain}
\bibliography{m4_progname}

\subsection{URL's}
\label{sec:urls}

\begin{description}
\item[Nuweb:] \url{m4_nuwebURL}
\item[Apache Velocity:] \url{m4_velocityURL}
\item[Velocitytools:] \url{m4_velocitytoolsURL}
\item[Parameterparser tool:] \url{m4_parameterparserdocURL}
\item[Cookietool:] \url{m4_cookietooldocURL}
\item[VelocityView:] \url{m4_velocityviewURL}
\item[VelocityLayoutServlet:] \url{m4_velocitylayoutservletURL}
\item[Jetty:] \url{m4_jettycodehausURL}
\item[UserBase javadoc:] \url{m4_userbasejavadocURL}
\item[VU corpus Management development site:] \url{http://code.google.com/p/vucom} 
\end{description}

\section{Indexes}
\label{sec:indexes}


\subsection{Filenames}
\label{sec:filenames}

@f

\subsection{Macro's}
\label{sec:macros}

@m

\subsection{Variables}
\label{sec:veriables}

@u

\end{document}

% Local IspellDict: british 

% LocalWords:  Webcom
