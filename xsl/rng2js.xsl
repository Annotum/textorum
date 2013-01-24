<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:rng="http://relaxng.org/ns/structure/1.0" version="1.0">
    <xsl:output method="text" encoding="utf-8" indent="yes" omit-xml-declaration="yes"/>

    <xsl:strip-space elements="*"/>

    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="*">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="rng:grammar">
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="rng:start"/>
        <xsl:text>
  "defs": 
    {</xsl:text>
        <xsl:apply-templates select="rng:define"/>
        <xsl:text>
    } 
} </xsl:text>
    </xsl:template>
    <xsl:template match="rng:start">
        <xsl:text>
  "$root":
    [</xsl:text>
        <xsl:for-each select="descendant::rng:ref">
            <xsl:variable name="refname">
                <xsl:value-of select="@name"/>
            </xsl:variable>
            <xsl:text>
      "</xsl:text>
            <xsl:value-of select="/*//rng:define[@name=$refname]/rng:element/rng:name/text()"/>
            <xsl:text>"</xsl:text>
            <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>
    ],
        </xsl:text>
    </xsl:template>
    
    <xsl:template match="rng:define">
        <xsl:for-each select="rng:element">
            <xsl:text>
        "</xsl:text>
            <xsl:value-of select="rng:name/text()"/>
            <xsl:text>": {</xsl:text>
            <xsl:if test=".//rng:text[not(parent::rng:attribute)]"><xsl:text>
            "$": 1, </xsl:text></xsl:if>
            <xsl:text>
            "contains": { </xsl:text>
            <xsl:for-each select="descendant::rng:ref">
                <xsl:variable name="refname">
                    <xsl:value-of select="@name"/>
                </xsl:variable>
                <xsl:text>
                "</xsl:text>
                <xsl:value-of select="/*//rng:define[@name=$refname]/rng:element/rng:name/text()"/>
                <xsl:text>": </xsl:text>
                <xsl:choose>
                    <xsl:when test="parent::rng:choice/rng:empty"><xsl:text>0</xsl:text></xsl:when>
                    <xsl:otherwise><xsl:text>1</xsl:text></xsl:otherwise>
                </xsl:choose>
                <xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each><xsl:if test="descendant::rng:ref"><xsl:text>
            </xsl:text></xsl:if><xsl:text>},
            "attr": {</xsl:text>
            <xsl:for-each select="descendant::rng:attribute">
                <xsl:text>
                "</xsl:text>
                <xsl:value-of select="rng:name/text()"/>
                <xsl:text>": </xsl:text>
                <xsl:choose>
                    <xsl:when test="parent::rng:choice/rng:empty"><xsl:text>0</xsl:text></xsl:when>
                    <xsl:otherwise>1</xsl:otherwise>
                </xsl:choose>
                <xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each><xsl:if test="descendant::rng:attribute"><xsl:text>
            </xsl:text></xsl:if> 
            <xsl:text>}
        }</xsl:text>
            <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each><xsl:if test="position() != last()">
            <xsl:text>,</xsl:text>
        </xsl:if>
    </xsl:template>


</xsl:stylesheet>
