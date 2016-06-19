<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions"
   exclude-result-prefixes="xs tan fn tei" version="3.0">

   <xsl:output indent="yes"/>
   <xsl:include href="../../../library/TAN-1-dev/functions/TAN-core-functions.xsl"/>
   <xsl:variable name="current-base-uri" select="static-base-uri()"/>
   <xsl:variable name="source-abs-uri"
      select="resolve-uri('../../../pre-TAN/got/gotica.xml.zip', $current-base-uri)"/>
   <xsl:variable name="raw-got-nt" as="document-node()"
      select="doc('jar:' || $source-abs-uri || '!/gotica.xml')"/>
   <xsl:variable name="exemplar-TAN-TEI-file" select="doc('../nt.got.2004.xml')"/>
   <xsl:variable name="this-stylesheet-as-agent" as="element()">
      <agent xml:id="style" roles="converter">
         <IRI>tag:kalvesmaki.com,2015:stylesheet:got-nt-to-tan-tei</IRI>
         <name>Stylesheet to transform the TEI version of the Gothic New Testament to the TAN-TEI
            format</name>
      </agent>
   </xsl:variable>
   <xsl:variable name="this-stylesheet-role" as="element()">
      <role xml:id="converter">
         <IRI>tag:kalvesmaki.com,2015:role:tan-converter</IRI>
         <name>The role of converting data from a non-TAN format to TAN.</name>
      </role>
   </xsl:variable>

   <!-- Step 1, prepare exemplar -->
   <xsl:variable name="revised-exemplar" as="document-node()">
      <xsl:document>
         <xsl:apply-templates select="$exemplar-TAN-TEI-file" mode="prep"/>
      </xsl:document>
   </xsl:variable>
   <xsl:mode name="prep" on-no-match="shallow-copy"/>
   <xsl:template match="processing-instruction() | comment() | tei:head" mode="prep">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="tan:head" mode="prep">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="prep"/>
         <change when="{current-dateTime()}" who="{tan:agent[1]/@xml:id}">Data replaced by source
            files.</change>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:agent[last()]" mode="prep">
      <xsl:copy-of select="."/>
      <xsl:if test="not($head/tan:agent/tan:IRI = $this-stylesheet-as-agent/tan:IRI)">
         <xsl:copy-of select="$this-stylesheet-as-agent"/>
      </xsl:if>
   </xsl:template>
   <xsl:template match="tan:role[last()]" mode="prep">
      <xsl:copy-of select="."/>
      <xsl:if test="not($head/tan:role/tan:IRI = $this-stylesheet-role/tan:IRI)">
         <xsl:copy-of select="$this-stylesheet-role"/>
      </xsl:if>
   </xsl:template>
   <xsl:template match="tei:body" mode="prep">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:value-of select="namespace-uri($raw-got-nt/*)"/>
         <xsl:apply-templates select="$raw-got-nt//body" mode="prep-body"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="div | ab" mode="prep-body">
      <xsl:variable name="div-type-name" select="@type"/>
      <xsl:variable name="book-name" select="head"/>
      <tei:div>
         <xsl:attribute name="type" select="$div-type-rename/tan:name[@old = $div-type-name]/@new"/>
         <xsl:attribute name="n">
            <xsl:choose>
               <xsl:when test="@type = 'book'">
                  <xsl:value-of select="$book-rename/tan:name[@old = $book-name]/@new"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="@n"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:attribute>
         <xsl:choose>
            <xsl:when test="self::ab">
               <tei:p>
                  <xsl:value-of select="normalize-space(string-join(.//text()))"/>
               </tei:p>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates mode="prep-body"/>
            </xsl:otherwise>
         </xsl:choose>
      </tei:div>
   </xsl:template>
   <!-- For our purposes, we choose to ignore the scribal openers and closers -->
   <xsl:template match="head | opener | closer" mode="prep-body"/>
   <xsl:variable name="div-type-rename" as="element()">
      <div-types>
         <name old="book" new="bk"/>
         <name old="chapter" new="ch"/>
         <name old="verse" new="v"/>
      </div-types>
   </xsl:variable>
   <xsl:variable name="book-rename" as="element()">
      <books>
         <name old="Matthaeus" new="Mt"/>
         <name old="Johannes" new="Jn"/>
         <name old="Lukas" new="Lu"/>
         <name old="Markus" new="Mk"/>
         <name old="An die Römer" new="Ro"/>
         <name old="An die Korinther I" new="1Co"/>
         <name old="[An die Korinther II]" new="2Co"/>
         <name old="[An die Epheser]" new="Eph"/>
         <name old="[An die Galater]" new="Gal"/>
         <name old="An die Philipper" new="Php"/>
         <name old="An die Kolosser" new="Col"/>
         <name old="An die Thessalonicher I" new="1Th"/>
         <name old="[An die Thessalonicher II]" new="2Th"/>
         <name old="[An Timotheus I]" new="1Tim"/>
         <name old="[An Timotheus II]" new="2Tim"/>
         <name old="[An Titus]" new="Tit"/>
         <name old="An Philemon" new="Phm"/>
         <name old="Nehemias" new="ignore"/>
         <name old="Die Skeireins" new="ignore"/>
         <name old="Die gotischen Unterschriften der Urkunden" new="ignore"/>
         <name old="Der gotische Kalender" new="ignore"/>
      </books>
   </xsl:variable>
   
   <!-- Step 2. Drop superfluous divs -->
   <xsl:variable name="clean-exemplar" as="document-node()">
      <xsl:apply-templates select="$revised-exemplar" mode="clean-exemplar"></xsl:apply-templates>
   </xsl:variable>
   <xsl:mode name="clean-exemplar" on-no-match="shallow-copy"/>
   <!-- Delete divs that are slated to be ignored, or have no content -->
   <xsl:template match="*[@n = 'ignore']|tei:div[tei:p[not(text())]]" mode="clean-exemplar"/>
   

   <!-- OUTPUT -->

   <xsl:template match="/">
      <!--<xsl:copy-of select="$revised-exemplar"/>-->
      <xsl:copy-of select="$clean-exemplar"/>
   </xsl:template>

</xsl:stylesheet>
