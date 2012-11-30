<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:output method="html" standalone="no"/>
    <xsl:template match="*">
        <xsl:variable name="oldElement">
            <xsl:value-of select="local-name(.)"/>
        </xsl:variable>
        <xsl:variable name="newElement">
            <xsl:choose>
                <xsl:when test="local-name(.) = 'journal-meta'">
                    <xsl:text>span</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>span</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="{$newElement}">
            <xsl:copy-of select="namespace::*"/>
            <xsl:copy-of select="@*"/>
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