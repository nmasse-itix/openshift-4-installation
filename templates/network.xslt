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
          <!-- fix for the 5s timeout on DNS -->
          <!-- see https://www.math.tamu.edu/~comech/tools/linux-slow-dns-lookup/ -->
          <dnsmasq:option value="auth-server=${network_domain},"/>
          <dnsmasq:option value="auth-zone=${network_domain}"/>

          <!-- Wildcard route -->
          <dnsmasq:option value="address=/${alias}/${ip}"/>
        </dnsmasq:options>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
