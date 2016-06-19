<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" exclude-result-prefixes="xs tan fn"
   version="3.0">

   <xsl:output indent="yes"/>
   <xsl:include href="../../../library/TAN-1-dev/functions/TAN-core-functions.xsl"/>
   <!-- , 'roots.csv', 'lexemes.csv' -->
   <!--<xsl:param name="filenames" select="('words.csv')" as="xs:string*"/>-->
   <xsl:variable name="raw-syr-nt" as="xs:string*"
      select="unparsed-text-lines('../../../pre-TAN/syr/sedra3/peshitta_bfbs-sedra.txt')"/>
   <xsl:variable name="raw-sedra3-toks" as="xs:string*"
      select="unparsed-text-lines('../../../pre-TAN/syr/sedra3/WORDS.TXT')"/>
   <xsl:variable name="raw-sedra3-lexemes" as="xs:string*"
      select="unparsed-text-lines('../../../pre-TAN/syr/sedra3/LEXEMES.TXT')"/>
   <xsl:variable name="transliteration-key-raw" as="xs:string*"
      select="unparsed-text-lines('../../../pre-TAN/syr/sedra4/words.csv')"/>
   <xsl:variable name="exemplar-TAN-LM-file" select="doc('../TAN-LM/nt.syr.bfbs.TAN-LM.xml')"/>

   <!-- Step 1a, prepare exemplar -->
   <xsl:variable name="revised-exemplar" as="document-node()">
      <xsl:document>
         <xsl:apply-templates select="$exemplar-TAN-LM-file" mode="prep"/>
      </xsl:document>
   </xsl:variable>
   <xsl:mode name="prep" on-no-match="shallow-copy"/>
   <xsl:template match="tan:head" mode="prep">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="prep"/>
         <change when="{current-dateTime()}" who="{tan:agent[1]/@xml:id}">Data replaced by source
            files.</change>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:body" mode="prep">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <!--<xsl:copy-of select="$syriac-words"/>-->
         <!--<xsl:copy-of select="$lexeme-key"/>-->
         <xsl:for-each-group select="$peshitta-analyzed/*/tan:ana" group-by="tan:lm/tan:l || '#' || tan:lm/tan:m">
            <xsl:variable name="key-split" select="tokenize(current-grouping-key(),'#')"/>
            <ana>
               <xsl:copy-of select="current-group()/tan:tok"/>
               <lm>
                  <l><xsl:value-of select="$key-split[1]"/></l>
                  <m><xsl:value-of select="$key-split[2]"/></m>
               </lm>
            </ana>
         </xsl:for-each-group>
      </xsl:copy>
   </xsl:template>

   <!-- Step 1b, prepare transliteration key -->
   <xsl:variable name="transliteration-head"
      select="analyze-string(head($transliteration-key-raw), '&quot;([^&quot;]*)&quot;')/fn:match/fn:group"
      as="element()*"/>
   <xsl:variable name="transliteration-key" as="document-node()">
      <xsl:document>
         <transliteration-key>
            <xsl:for-each select="tail($transliteration-key-raw)">
               <xsl:variable name="data-parsed"
                  select="analyze-string(., '&quot;([^&quot;]*)&quot;')/fn:match/fn:group"/>
               <tok>
                  <xsl:for-each select="1 to count($transliteration-head)">
                     <xsl:variable name="pos" select="."/>
                     <xsl:attribute name="{$transliteration-head[$pos]}" select="$data-parsed[$pos]"
                     />
                  </xsl:for-each>
               </tok>
            </xsl:for-each>
         </transliteration-key>
      </xsl:document>
   </xsl:variable>
   <xsl:key name="tlit" match="tan:tok" use="@sedra3"/>

   <!-- Step 1c, prepare master lexeme file -->
   <xsl:variable name="lexeme-head"
      select="('id', 'root_idref', 'lexeme', 'lexeme_vocalized', 'morphology', 'attributes')"
      as="xs:string*"/>
   <xsl:variable name="lexeme-key" as="document-node()">
      <xsl:document>
         <lexemes>
            <xsl:for-each select="$raw-sedra3-lexemes">
               <xsl:variable name="data-parsed"
                  select="analyze-string(., '&quot;([^&quot;]*)&quot;|(-?[\d:]+)')/fn:match/fn:group"/>
               <xsl:variable name="attribute-prep"
                  select="($lexeme-errata[@old = $data-parsed[5]]/@new, $data-parsed[5])[1]"/>
               <xsl:variable name="attributes"
                  select="tan:bin-head-zeros(tan:dec-to-bin(xs:integer(($attribute-prep, 0)[1])), 6)"
               />
               <xsl:variable name="pos" select="substring($attributes, 1, 4)"/>
               <l id="{$data-parsed[1]}">
                  <xsl:attribute name="pos"
                     select="$sedra-code-key[@feature = 'pos']/tan:feature[@bin = $pos]/@code"/>
                  <xsl:value-of
                     select="key('tlit', $data-parsed[3], $transliteration-key)[1]/@syriac"/>
               </l>
            </xsl:for-each>
         </lexemes>
      </xsl:document>
   </xsl:variable>
   <xsl:variable name="lexeme-errata" as="element()*">
      <erratum old="-232" new="24"/>
   </xsl:variable>
   <xsl:key name="l" match="tan:l" use="@id"/>

   <!-- Step 1d, prepare master file of tokens (attested word forms) -->
   <xsl:variable name="tok-head"
      select="('id', 'lexeme_idref', 'word', 'word_vocalized', 'morphology', 'attributes')"
      as="xs:string*"/>
   <xsl:variable name="tok-key" as="document-node()">
      <xsl:document>
         <toks>
            <xsl:for-each select="$raw-sedra3-toks[position() gt 0]">
               <xsl:variable name="data-parsed"
                  select="analyze-string(., '&quot;([^&quot;]*)&quot;|([\d:]+)')/fn:match/fn:group"/>
               <ana key="{$data-parsed[1]}">
                  <tok val="{key('tlit', $data-parsed[3], $transliteration-key)[1]/@syriac}"/>
                  <xsl:variable name="this-lexeme" select="key('l', $data-parsed[2], $lexeme-key)"/>
                  <lm>
                     <l>
                        <xsl:value-of select="$this-lexeme"/>
                     </l>
                     <m>
                        <xsl:variable name="m1-bin"
                           select="tan:bin-head-zeros(tan:dec-to-bin(xs:integer($data-parsed[5])), 32)"/>
                        <xsl:variable name="m2-bin"
                           select="tan:bin-head-zeros(tan:dec-to-bin(xs:integer(($data-parsed[6], 0)[1])), 7)"/>
                        <xsl:variable name="kaylo" select="substring($m1-bin, 1, 6)"/>
                        <xsl:variable name="enclitic" select="substring($m2-bin, 2, 1)"/>
                        <xsl:variable name="seyame" select="substring($m2-bin, 7, 1)"/>
                        <xsl:variable name="state" select="substring($m1-bin, 10, 2)"/>
                        <xsl:variable name="tense" select="substring($m1-bin, 7, 3)"/>
                        <xsl:variable name="number" select="substring($m1-bin, 12, 2)"/>
                        <xsl:variable name="person" select="substring($m1-bin, 14, 2)"/>
                        <xsl:variable name="gender" select="substring($m1-bin, 16, 2)"/>
                        <xsl:variable name="prefix" select="substring($m1-bin, 18, 6)"/>
                        <xsl:variable name="contraction" select="substring($m1-bin, 24, 2)"/>
                        <xsl:variable name="suff-number" select="substring($m1-bin, 26, 1)"/>
                        <xsl:variable name="suff-person" select="substring($m1-bin, 27, 2)"/>
                        <xsl:variable name="suff-gender" select="substring($m1-bin, 29, 2)"/>

                        <xsl:variable name="codes" as="xs:string*"
                           select="
                              $this-lexeme/@pos,
                              $sedra-code-key[@feature = 'kaylo']/tan:feature[@bin = $kaylo]/@code,
                              $sedra-code-key[@feature = 'enclitic']/tan:feature[@bin = $enclitic]/@code,
                              $sedra-code-key[@feature = 'seyame']/tan:feature[@bin = $seyame]/@code,
                              $sedra-code-key[@feature = 'state']/tan:feature[@bin = $state]/@code,
                              $sedra-code-key[@feature = 'tense']/tan:feature[@bin = $tense]/@code,
                              $sedra-code-key[@feature = 'number']/tan:feature[@bin = $number]/@code,
                              $sedra-code-key[@feature = 'person']/tan:feature[@bin = $person]/@code,
                              $sedra-code-key[@feature = 'gender']/tan:feature[@bin = $gender]/@code,
                              $sedra-code-key[@feature = 'prefix']/tan:feature[@bin = $prefix]/@code,
                              if ($contraction = '01') then
                                 (
                                 $sedra-code-key[@feature = 'suff-number']/tan:feature[@bin = $suff-number]/@code,
                                 $sedra-code-key[@feature = 'suff-person']/tan:feature[@bin = $suff-person]/@code,
                                 $sedra-code-key[@feature = 'suff-gender']/tan:feature[@bin = $suff-gender]/@code
                                 )
                              else
                                 ()
                              "/>
                        <xsl:value-of select="string-join($codes, ' ')"/>
                     </m>
                  </lm>
               </ana>
            </xsl:for-each>
         </toks>
      </xsl:document>
   </xsl:variable>
   <xsl:key name="ana" match="tan:ana" use="@key"/>

   <!-- Step 1e, prepare Peshitta text -->
   <xsl:variable name="peshitta-analyzed" as="document-node()">
      <xsl:document>
         <peshitta-analyzed>
            <xsl:for-each select="$raw-syr-nt">
               <xsl:variable name="cut" select="analyze-string(., '(^\w+ \d+:\d+) ')"/>
               <xsl:variable name="ref" select="$cut/fn:match/fn:group"/>
               <xsl:variable name="ref-split" select="tokenize($ref, '\s+')"/>
               <xsl:variable name="book-name-new" select="$book-names[@old = $ref-split[1]]/@new"/>
               <xsl:variable name="toks" select="tokenize($cut/fn:non-match, '\s+')"/>
               <xsl:for-each select="$toks[matches(., '\w')]">
                  <xsl:variable name="pos" select="position()"/>
                  <xsl:variable name="this-ana" select="key('ana', ., $tok-key)"/>
                  <ana>
                     <tok>
                        <xsl:attribute name="ref" select="$book-name-new || ' ' || $ref-split[2]"/>
                        <xsl:attribute name="pos" select="$pos"/>
                        <!--<xsl:copy-of select="$this-ana/tan:tok/@*"/>-->
                     </tok>
                     <xsl:copy-of select="$this-ana/tan:lm"/>
                  </ana>
               </xsl:for-each>
            </xsl:for-each>
         </peshitta-analyzed>
      </xsl:document>
   </xsl:variable>

   <xsl:variable name="sedra-code-key" as="element()*">
      <key feature="pos">
         <feature bin="0000" code="verb"/>
         <feature bin="0001" code="participle adjective"/>
         <feature bin="0010" code="denominative"/>
         <feature bin="0011" code="substantive"/>
         <feature bin="0100" code="noun"/>
         <feature bin="0101" code="pronoun"/>
         <feature bin="0110" code="proper"/>
         <feature bin="0111" code="numeral"/>
         <feature bin="1000" code="adjective"/>
         <feature bin="1001" code="particle"/>
         <feature bin="1010" code="idiom"/>
         <feature bin="1011" code="adverb"/>
         <feature bin="1100" code="adj-place"/>
         <feature bin="1101" code="adverb"/>
      </key>
      <key feature="kaylo">
         <feature bin="000001" code="p'al"/>
         <feature bin="000010" code="ethp'el"/>
         <feature bin="000011" code="pa''el"/>
         <feature bin="000100" code="ethpa''al"/>
         <feature bin="000101" code="aph'el"/>
         <feature bin="000110" code="ettaph'al"/>
         <feature bin="000111" code="shaph'el"/>
         <feature bin="001000" code="eshtaph'al"/>
         <feature bin="001001" code="saph'el"/>
         <feature bin="001010" code="estaph'al"/>
         <feature bin="001011" code="paw'el"/>
         <feature bin="001100" code="ethpaw'al"/>
         <feature bin="001101" code="pay'el"/>
         <feature bin="001110" code="ethpay'al"/>
         <feature bin="001111" code="palpal"/>
         <feature bin="010000" code="ethpalpal" bis=""/>
         <feature bin="010001" code="palpel"/>
         <feature bin="010010" code="ethpalpal"/>
         <feature bin="010011" code="pam'el"/>
         <feature bin="010100" code="ethpam'al" err=""/>
         <feature bin="010101" code="par'el"/>
         <feature bin="010110" code="ethpar'al"/>
         <feature bin="010111" code="pa'li"/>
         <feature bin="011000" code="ethpa'li"/>
         <feature bin="011001" code="pahli" err=""/>
         <feature bin="011010" code="ethpahli" err=""/>
         <feature bin="011011" code="taph'el"/>
         <feature bin="011100" code="ethaphal"/>
      </key>
      <key feature="enclitic">
         <feature bin="1" code="enclitic"/>
      </key>
      <key feature="seyame">
         <feature bin="1" code="seyame"/>
      </key>
      <key feature="state">
         <feature bin="01" code="absolute"/>
         <feature bin="10" code="construct"/>
         <feature bin="11" code="emphatic"/>
      </key>
      <key feature="tense">
         <feature bin="001" code="perfect"/>
         <feature bin="010" code="imperfect"/>
         <feature bin="011" code="imperative"/>
         <feature bin="100" code="infinitive"/>
         <feature bin="101" code="active participle"/>
         <feature bin="110" code="passive participle"/>
         <feature bin="111" code="participle"/>
      </key>
      <key feature="number">
         <feature bin="01" code="singular"/>
         <feature bin="10" code="plural"/>
      </key>
      <key feature="person">
         <feature bin="01" code="3"/>
         <feature bin="10" code="2"/>
         <feature bin="11" code="1"/>
      </key>
      <key feature="gender">
         <feature bin="01" code="c"/>
         <feature bin="10" code="m"/>
         <feature bin="11" code="f"/>
      </key>
      <key feature="contraction">
         <feature bin="10" code="contraction"/>
      </key>
      <key feature="prefix">
         <feature bin="000001" code="pre-b"/>
         <feature bin="000010" code="pre-d"/>
         <feature bin="001000" code="pre-d pre-l"/>
         <feature bin="000011" code="pre-w"/>
         <feature bin="001011" code="pre-w pre-l"/>
         <feature bin="000100" code="pre-l"/>
         <feature bin="001010" code="pre-w pre-d"/>
         <feature bin="001001" code="pre-w pre-b"/>
         <feature bin="000110" code="pre-d pre-b"/>
         <feature bin="110011" code="pre-d pre-l"/>
         <feature bin="001100" code="pre-l pre-d"/>
         <feature bin="000111" code="pre-dd"/>
         <feature bin="000101" code="pre-b pre-d"/>
         <feature bin="010111" code="pre-w pre-d pre-l"/>
         <feature bin="011011" code="pre-ll pre-d"/>
         <feature bin="010011" code="pre-dd pre-l"/>
         <feature bin="011000" code="pre-w pre-l pre-d"/>
         <feature bin="010101" code="pre-w pre-d pre-b"/>
         <feature bin="010100" code="pre-w pre-b pre-d"/>
      </key>
      <key feature="suff-number">
         <feature bin="0" code="suff-sg"/>
         <feature bin="1" code="suff-pl"/>
      </key>
      <key feature="suff-person">
         <feature bin="01" code="suff-3"/>
         <feature bin="10" code="suff-2"/>
         <feature bin="11" code="suff-1"/>
      </key>
      <key feature="suff-gender">
         <feature bin="00" code="suff-c"/>
         <feature bin="01" code="suff-m"/>
         <feature bin="10" code="suff-f"/>
      </key>
   </xsl:variable>

   <xsl:variable name="book-names" as="element()+">
      <book new="Mt" old="Matthew"/>
      <book new="Mk" old="Mark"/>
      <book new="Lu" old="Luke"/>
      <book new="Jn" old="John"/>
      <book new="Ac" old="Acts"/>
      <book new="Ro" old="Romans"/>
      <book new="1Co" old="1Corinthians"/>
      <book new="2Co" old="2Corinthians"/>
      <book new="Gal" old="Galatians"/>
      <book new="Eph" old="Ephesians"/>
      <book new="Php" old="Philippians"/>
      <book new="Col" old="Colossians"/>
      <book new="1Th" old="1Thessalonians"/>
      <book new="2Th" old="2Thessalonians"/>
      <book new="1Tim" old="1Timothy"/>
      <book new="2Tim" old="2Timothy"/>
      <book new="Tit" old="Titus"/>
      <book new="Phm" old="Philemon"/>
      <book new="Heb" old="Hebrews"/>
      <book new="Jam" old="James"/>
      <book new="1Pe" old="1Peter"/>
      <book new="2Pe" old="2Peter"/>
      <book new="1Jn" old="1John"/>
      <book new="2Jn" old="2John"/>
      <book new="3Jn" old="3John"/>
      <book new="Jud" old="Jude"/>
      <book new="Re" old="Revelation"/>
   </xsl:variable>

   <xsl:function name="tan:dec-to-bin" as="xs:string">
      <xsl:param name="int" as="xs:integer"/>
      <xsl:variable name="new-digit" select="$int mod 2" as="xs:integer"/>
      <xsl:variable name="bin-digit" select="('0', '1')[$new-digit + 1]"/>
      <xsl:variable name="next-int" select="($int - $new-digit) idiv 2"/>
      <xsl:choose>
         <xsl:when test="$next-int lt 1">
            <xsl:value-of select="$bin-digit"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="tan:dec-to-bin($next-int) || $bin-digit"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <xsl:function name="tan:bin-head-zeros" as="xs:string">
      <xsl:param name="bin" as="xs:string"/>
      <xsl:param name="places" as="xs:integer"/>
      <xsl:variable name="no-of-zeros-to-add" select="$places - string-length($bin)"/>
      <xsl:value-of
         select="
            string-join((for $i in (1 to $no-of-zeros-to-add)
            return
               '0')) || $bin"
      />
   </xsl:function>


   <!-- OUTPUT -->

   <xsl:template match="/">
      <!--<result>
         <xsl:value-of select="tan:bin-head-zeros('1',3)"/>
      </result>-->
      <xsl:copy-of select="$revised-exemplar"/>
   </xsl:template>


</xsl:stylesheet>
