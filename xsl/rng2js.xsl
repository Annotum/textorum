<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:exslt="http://exslt.org/common"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="exslt msxsl" version="1.0">
    <msxsl:script language="JScript" implements-prefix="exslt"> this['node-set'] = function (x) {
        return x; } </msxsl:script>

    <xsl:output method="text" encoding="utf-8" indent="yes" omit-xml-declaration="yes"/>

    <xsl:strip-space elements="*"/>

    <xsl:variable name="nsset" select="//namespace::*[not(. = ../../namespace::*)]"/>

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
        <xsl:apply-templates select="rng:start" mode="ingrammar"/>
        <xsl:text>
  "defs":
    {</xsl:text>
        <xsl:apply-templates select="rng:define" mode="ingrammar"/>
        <xsl:text>
    }
} </xsl:text>
    </xsl:template>

    <xsl:template match="rng:start" mode="ingrammar">
        <xsl:text>
  "$root":
    [</xsl:text>
        <xsl:apply-templates select="descendant::rng:ref" mode="rootelements"/>
        <xsl:text>
    ],
        </xsl:text>
    </xsl:template>

    <xsl:template match="rng:ref" mode="rootelements">
        <xsl:variable name="refname">
            <xsl:value-of select="@name"/>
        </xsl:variable>
        <xsl:text>
      "</xsl:text>
        <xsl:value-of select="//rng:define[@name=$refname]/rng:element/rng:name/text()"/>
        <xsl:text>"</xsl:text>
        <xsl:if test="position() != last()">
            <xsl:text>,</xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="rng:define" mode="ingrammar">
        <xsl:apply-templates select="rng:element" mode="indefine"/>
        <xsl:if test="position() != last()">
            <xsl:text>,</xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="rng:element" mode="indefine">
        <!-- Element name -->
        <xsl:text>
        "</xsl:text>
        <xsl:value-of select="rng:name/text()"/>
        <xsl:text>": {</xsl:text>

        <!-- If element accepts text node content -->
        <xsl:if test=".//rng:text[not(parent::rng:attribute)]">
            <xsl:text>
            "$": 1, </xsl:text>
        </xsl:if>

        <!-- Elements this element can contain (always present) -->
        <xsl:text>
            "contains": { </xsl:text>
        <xsl:apply-templates select="descendant::rng:ref" mode="inelement"/>
        <xsl:if test="descendant::rng:ref">
            <xsl:text>
            </xsl:text>
        </xsl:if>
        <xsl:text>},</xsl:text>

        <!-- Attributes this element can contain (always present) -->
        <xsl:text>
            "attr": {</xsl:text>
        <xsl:apply-templates select="descendant::rng:attribute" mode="attr-list"/>
        <xsl:if test="descendant::rng:attribute">
            <xsl:text>
            </xsl:text>
        </xsl:if>
        <xsl:text>}</xsl:text>

        <!-- Strict ordering of descendants -->
        <xsl:if test="descendant::rng:group/rng:ref">
            <xsl:text>,
            "order": [</xsl:text>
            <xsl:for-each select="descendant::rng:group">
                <xsl:sort select="position()" data-type="number" order="descending"/>
                <xsl:if test="child::rng:ref">
                    <xsl:for-each select="child::rng:ref">
                        <xsl:variable name="refname">
                            <xsl:value-of select="@name"/>
                        </xsl:variable>
                        <xsl:text>"</xsl:text>
                        <xsl:value-of
                            select="//rng:define[@name=$refname]/rng:element/rng:name/text()"/>
                        <xsl:text>"</xsl:text>
                        <xsl:if test="position() != last()">
                            <xsl:text>,</xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:if>
                <xsl:if test="child::rng:choice/descendant::rng:ref">
                    <xsl:if test="child::rng:ref">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                    <xsl:for-each select="child::rng:choice[descendant::rng:ref]">
                        <xsl:text>[</xsl:text>
                        <xsl:for-each select="descendant::rng:ref">
                            <xsl:variable name="refname">
                                <xsl:value-of select="@name"/>
                            </xsl:variable>
                            <xsl:text>"</xsl:text>
                            <xsl:value-of
                                select="//rng:define[@name=$refname]/rng:element/rng:name/text()"/>
                            <xsl:text>"</xsl:text>
                            <xsl:if test="position() != last()">
                                <xsl:text>, </xsl:text>
                            </xsl:if>
                        </xsl:for-each>
                        <xsl:text>]</xsl:text>
                        <xsl:if test="position() != last()">
                            <xsl:text>, </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:if>
                <xsl:if
                    test="position() != last() and (child::rng:choice/descendant::rng:ref or child::rng:ref)">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:text>]</xsl:text>
        </xsl:if>

        <!-- Close element object -->
        <xsl:text>
        }</xsl:text>

        <!-- Trailing comma -->
        <xsl:if test="position() != last()">
            <xsl:text>,</xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="rng:ref" mode="inelement">
        <xsl:variable name="groupcounter">
            <xsl:value-of select="generate-id()"/>
        </xsl:variable>
        <xsl:variable name="refname">
            <xsl:value-of select="@name"/>
        </xsl:variable>
        <xsl:text>
                "</xsl:text>
        <xsl:value-of select="/rng:grammar/rng:define[@name=$refname]/rng:element/rng:name/text()"/>
        <xsl:text>": </xsl:text>
        <xsl:choose>
            <xsl:when test="ancestor::rng:oneOrMore">
                <xsl:text>{ "group": "</xsl:text>
                <xsl:value-of select="generate-id(ancestor::rng:oneOrMore)"/>
                <xsl:text>", "required": </xsl:text>
                <xsl:choose>
                    <xsl:when test="ancestor::rng:choice/rng:empty">
                        <xsl:text>0</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>1</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text> }</xsl:text>
            </xsl:when>
            <xsl:when test="ancestor::rng:choice/rng:empty">
                <xsl:text>0</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>{ "required": 1 }</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="position() != last()">
            <xsl:text>,</xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="rng:value" mode="attr-list">
        <xsl:text>"</xsl:text>
        <xsl:value-of select="text()"/>
        <xsl:text>"</xsl:text>
        <xsl:if test="position() != last()">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="rng:attribute" mode="attr-list">
        <xsl:text>
              "</xsl:text>
        <xsl:variable name="nsuri">
            <xsl:value-of select="rng:name/@ns"/>
        </xsl:variable>
        <xsl:choose>

            <xsl:when test="local-name($nsset[. = $nsuri]) != ''">
                <xsl:value-of select="local-name($nsset[. = $nsuri])"/>
                <xsl:text>:</xsl:text>
            </xsl:when>
        </xsl:choose>
        <xsl:value-of select="rng:name/text()"/>
        <xsl:text>": { </xsl:text>
        <xsl:if test="rng:name/@ns != ''">
            <xsl:text>"ns": "</xsl:text>
            <xsl:value-of select="rng:name/@ns"/>
            <xsl:text>", </xsl:text>
        </xsl:if>
        <xsl:if test="descendant::rng:value">
            <xsl:text>"value": [</xsl:text>
            <xsl:apply-templates select="descendant::rng:value" mode="attr-list"/>
            <xsl:text>], </xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="rng:data">
                <xsl:text>"data": </xsl:text>
                <xsl:apply-templates select="rng:data" mode="attr-list"/>
                <xsl:text>, </xsl:text>
            </xsl:when>
            <xsl:when test="rng:text">
                <xsl:text>"$": 1,</xsl:text>
            </xsl:when>
        </xsl:choose>
        <xsl:text>"required": </xsl:text>
        <xsl:choose>
            <xsl:when test="ancestor::rng:choice/rng:empty">
                <xsl:text>0</xsl:text>
            </xsl:when>
            <xsl:otherwise>1</xsl:otherwise>
        </xsl:choose>

        <xsl:text> }</xsl:text>
        <xsl:if test="position() != last()">
            <xsl:text>,</xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="rng:data" mode="attr-list">
        <xsl:text>"Type: </xsl:text>
        <xsl:value-of select="@type"/>
        <xsl:text>"</xsl:text>
    </xsl:template>

</xsl:stylesheet>
