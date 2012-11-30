<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:output 
        method="xml" 
        encoding="UTF-8"
        doctype-public="article" 
        doctype-system="http://dtd.nlm.nih.gov/ncbi/kipling/kipling-jp3.dtd" 
        indent="yes"
    />
    <xsl:template match="*">
        <xsl:variable name="oldElement">
            <xsl:value-of select="@data-xmlel"/>
        </xsl:variable>
        <xsl:element name="{$oldElement}">
            <xsl:copy-of select="@*[not(contains('class data-clsbk style data-xmlel', name(.)))]"/>
            <xsl:if test="boolean(@data-clsbk)">
                <xsl:attribute name="class">
                    <xsl:value-of select="@data-clsbk"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>