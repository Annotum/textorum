<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    exclude-result-prefixes="#default xml">
    <xsl:output method="html" standalone="no"/>
    <xsl:param name="inlineelements"><xsl:text>span</xsl:text></xsl:param>
    <xsl:param name="fixedelements"><xsl:text></xsl:text></xsl:param>
    <xsl:template match="*">
        <xsl:variable name="oldElement">
            <xsl:value-of select="local-name(.)"/>
        </xsl:variable>
        <xsl:variable name="oldElementFull">
            <xsl:value-of select="name(.)"/>
        </xsl:variable>
        <xsl:variable name="newElement">
            <xsl:choose>
                <xsl:when test="contains(concat(',', $inlineelements, ','), concat(',',local-name(.),','))">
                    <xsl:text>span</xsl:text>
                </xsl:when>
                <xsl:when test="contains(concat(',', $fixedelements, ','), concat(',',local-name(.),','))">
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
                    <xsl:value-of select="$oldElementFull"></xsl:value-of>
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
            <xsl:apply-templates/>
        </xsl:element>                
    </xsl:template>
</xsl:stylesheet>