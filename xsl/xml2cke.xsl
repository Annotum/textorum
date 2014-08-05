<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    exclude-result-prefixes="xml">
    <xsl:output method="html" standalone="no"/>
    <xsl:param name="inlineelements">
        <xsl:text>span</xsl:text>
    </xsl:param>
    <xsl:param name="bold">
        <xsl:text>strong</xsl:text>
    </xsl:param>
    <xsl:param name="italic">
        <xsl:text>em</xsl:text>
    </xsl:param>
    <xsl:param name="underline">
        <xsl:text>u</xsl:text>
    </xsl:param>
    <xsl:param name="monospace">
        <xsl:text>tt</xsl:text>
    </xsl:param>
    <xsl:param name="fixedelements">
        <xsl:text/>
    </xsl:param>
    <xsl:key name="kElemByNSURI" match="*[namespace::*[not(. = ../../namespace::*)]]"
        use="namespace::*[not(. = ../../namespace::*)]"/>
    <xsl:template match="/">
        <xsl:for-each
            select="//namespace::*[not(. = ../../namespace::*)]
            [count(..|key('kElemByNSURI',.)[1])=1]">
            <xsl:element name="div">
                <xsl:attribute name="data-textorum-nsurl">
                    <xsl:value-of select="."/>
                </xsl:attribute>
                <xsl:attribute name="data-textorum-nsprefix">
                    <xsl:value-of select="local-name(.)"/>
                </xsl:attribute>
            </xsl:element>
        </xsl:for-each>
        <xsl:apply-templates select="node()|*" mode="go"/>
    </xsl:template>
    <xsl:template match="@*">
        <xsl:variable name="attrname" select="local-name(.)"/>
        <xsl:variable name="attrns" select="namespace-uri(.)"/>
        <xsl:attribute name="{$attrname}" namespace="{$attrns}">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
    <xsl:template match="*" mode="go">
        <xsl:variable name="oldElement">
            <xsl:value-of select="local-name(.)"/>
        </xsl:variable>
        <xsl:variable name="oldElementFull">
            <xsl:value-of select="name(.)"/>
        </xsl:variable>
        <xsl:variable name="newElement">
            <xsl:choose>
                <xsl:when
                    test="contains(concat(',', $inlineelements, ','), concat(',',local-name(.),','))">
                    <xsl:text>span</xsl:text>
                </xsl:when>
                <xsl:when
                    test="contains(concat(',', $bold, ','), concat(',',local-name(.),','))">
                    <xsl:text>strong</xsl:text>
                </xsl:when>
                <xsl:when
                    test="contains(concat(',', $italic, ','), concat(',',local-name(.),','))">
                    <xsl:text>em</xsl:text>
                </xsl:when>
                <xsl:when
                    test="contains(concat(',', $monospace, ','), concat(',',local-name(.),','))">
                    <xsl:text>tt</xsl:text>
                </xsl:when>
                <xsl:when
                    test="contains(concat(',', $underline, ','), concat(',',local-name(.),','))">
                    <xsl:text>u</xsl:text>
                </xsl:when>
                <xsl:when
                    test="contains(concat(',', $fixedelements, ','), concat(',',local-name(.),','))">
                    <xsl:value-of select="local-name(.)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>div</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="{$newElement}">
            <xsl:copy-of select="namespace::*[local-name(.) != 'xml']"/>
            <xsl:copy-of select="@*"/>
            <xsl:if test="$oldElementFull != $oldElement">
                <xsl:attribute name="data-nsbk">
                    <xsl:value-of select="$oldElementFull"/>
                </xsl:attribute>
                <xsl:attribute name="data-nsuribk">
                    <xsl:value-of select="namespace-uri(.)"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="boolean(@class)">
                <xsl:attribute name="data-clsbk">
                    <xsl:value-of select="@class"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:attribute name="class">
                <xsl:value-of select="$oldElement"/>
            </xsl:attribute>
            <xsl:attribute name="data-xmlel">
                <xsl:value-of select="$oldElement"/>
            </xsl:attribute>
            <xsl:apply-templates mode="go"/>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
