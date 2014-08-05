<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    exclude-result-prefixes="xml">
    <xsl:output method="xml" encoding="UTF-8" indent="yes"
        doctype-system="//TEXTORUM//DOCTYPE-SYSTEM//" omit-xml-declaration="no" standalone="yes"/>
    <xsl:template match="*">
        <xsl:choose>
            <xsl:when test="boolean(@data-nsbk)">
                <xsl:variable name="oldElement">
                    <xsl:value-of select="@data-xmlel"/>
                </xsl:variable>
                <xsl:variable name="oldNS">
                    <xsl:if test="@data-nsuribk != 'http://www.w3.org/XML/1998/namespace'">
                        <xsl:value-of select="@data-nsuribk"/>
                    </xsl:if>
                </xsl:variable>
                <xsl:variable name="prefix">
                    <xsl:value-of select="name(//namespace::*[string() = $oldNS])"/>
                </xsl:variable>
                <xsl:variable name="maybeColon">
                    <xsl:if test="string($prefix)">
                        <xsl:text>:</xsl:text>
                    </xsl:if>
                </xsl:variable>
                <xsl:element name="{$prefix}{$maybeColon}{$oldElement}" namespace="{$oldNS}">
                    <xsl:copy-of
                        select="@*[not(contains('class data-clsbk style data-xmlel data-nsbk data-nsuribk', name(.)))]"/>
                    <xsl:if test="boolean(@data-clsbk)">
                        <xsl:attribute name="class">
                            <xsl:value-of select="@data-clsbk"/>
                        </xsl:attribute>
                    </xsl:if>
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="boolean(@data-xmlel)">
                <xsl:variable name="oldElement">
                    <xsl:value-of select="@data-xmlel"/>
                </xsl:variable>
                <xsl:element name="{$oldElement}">
                    <xsl:copy-of select="namespace::*[local-name(.) != 'xml']"/>
                    <xsl:copy-of
                        select="@*[not(contains('class data-clsbk style data-xmlel data-nsuribk', name(.)))]"/>
                    <xsl:if test="boolean(@data-clsbk)">
                        <xsl:attribute name="class">
                            <xsl:value-of select="@data-clsbk"/>
                        </xsl:attribute>
                    </xsl:if>
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
