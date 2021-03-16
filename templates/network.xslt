<?xml version="1.0" ?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dnsmasq="http://libvirt.org/schemas/network/dnsmasq/1.0">
  <xsl:output omit-xml-declaration="yes" indent="yes"/>
  
  <!-- Identity transform -->
  <xsl:template match="node()|@*">
     <xsl:copy>
       <xsl:apply-templates select="node()|@*"/>
     </xsl:copy>
  </xsl:template>

  <!-- Append custom dnsmasq options to the network element -->
  <xsl:template match="/network">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:copy-of select="node()"/>
        <dnsmasq:options>
            <dnsmasq:option value="address=/${alias}/${ip}"/>
        </dnsmasq:options>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
