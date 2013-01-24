<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:output method="html" standalone="no"/>
    <xsl:template match="*">
        <xsl:variable name="oldElement">
            <xsl:value-of select="local-name(.)"/>
        </xsl:variable>
        <xsl:variable name="oldElementFull">
            <xsl:value-of select="name(.)"/>
        </xsl:variable>
        <xsl:variable name="newElement">
            <xsl:choose>
                <xsl:when test="local-name(.) = 'journal-meta'">
                    <xsl:text>div</xsl:text>
                </xsl:when>
                <xsl:when test="contains(',table,thead,tbody,td,tr,th,', concat(',',local-name(.),','))">
                    <xsl:value-of select="local-name(.)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>div</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="{$newElement}">
            <xsl:copy-of select="namespace::*"/>
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