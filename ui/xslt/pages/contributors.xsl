<?xml version="1.0" encoding="UTF-8"?>
	<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:numishare="https://github.com/ewg118/numishare" xmlns:foaf="http://xmlns.com/foaf/0.1/"
	xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:res="http://www.w3.org/2005/sparql-results#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" exclude-result-prefixes="#all"
	version="2.0">
	<xsl:include href="../templates.xsl"/>
	<xsl:include href="../functions.xsl"/>

	<xsl:param name="lang" select="doc('input:request')/request/parameters/parameter[name='lang']/value"/>

	<xsl:variable name="display_path"/>
	<xsl:variable name="include_path" select="if (string(//config/theme/themes_url)) then concat(//config/theme/themes_url, //config/theme/orbeon_theme) else concat('http://', doc('input:request')/request/server-name, ':8080/orbeon/themes/', //config/theme/orbeon_theme)"/>

	<xsl:template match="/">
		<html>
			<head>
				<title>
					<xsl:value-of select="/content/config/title"/>
					<xsl:text>: </xsl:text>
					<xsl:value-of select="numishare:normalizeLabel('header_contributors', $lang)"/>
				</title>
				<link rel="shortcut icon" type="image/x-icon" href="{$include_path}/images/favicon.png"/>
				<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"/>
				<meta name="viewport" content="width=device-width, initial-scale=1"/>
				<!-- bootstrap -->
				<link rel="stylesheet" href="https://netdna.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css"/>
				<script src="https://netdna.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"/>

				<link type="text/css" href="{$include_path}/css/style.css" rel="stylesheet"/>
				<xsl:if test="string(/content/config/google_analytics)">
					<script type="text/javascript">
						<xsl:value-of select="/content/config/google_analytics"/>
					</script>
				</xsl:if>
			</head>
			<body>
				<xsl:call-template name="header"/>
				<xsl:call-template name="content"/>
				<xsl:call-template name="footer"/>
			</body>
		</html>
	</xsl:template>

	<xsl:template name="content">
		<div class="container-fluid">
			<div class="row">
				<div class="col-md-12">
					<h1>
						<xsl:value-of select="numishare:normalizeLabel('header_contributors', $lang)"/>
					</h1>
					<table class="table table-striped">
						<thead>
							<tr>
								<xsl:if test="descendant::res:binding[@name='thumbnail']">
									<th/>
								</xsl:if>								
								<th>Count</th>
								<th>Collection</th>
							</tr>
						</thead>
						<tbody>
							<xsl:apply-templates select="descendant::res:result" mode="contributors"/>
						</tbody>						
					</table>
				</div>
			</div>
		</div>
	</xsl:template>

	<xsl:template match="res:result" mode="contributors">
		<tr>
			<td>
				
				<xsl:if test="string(res:binding[@name='thumbnail']/res:uri)">
					<a href="{if (string(res:binding[@name='homepage']/res:uri)) then res:binding[@name='homepage']/res:uri else res:binding[@name='dataset']/res:uri}">
						<img src="{res:binding[@name='thumbnail']/res:uri}" alt="logo" style="max-width:100%"/>
					</a>
				</xsl:if>
			</td>
			<td>
				<h2>
					<xsl:value-of select="format-number(res:binding[@name='count']/res:literal, '###,###')"/>
				</h2>
			</td>
			<td>
				<h2>
					<xsl:choose>
						<xsl:when test="res:binding[@name='collection']">
							<a href="{if (string(res:binding[@name='homepage']/res:uri)) then res:binding[@name='homepage']/res:uri else res:binding[@name='dataset']/res:uri}">
								<xsl:value-of select="res:binding[@name='collectionLabel']/res:literal"/>
							</a>
						</xsl:when>
						<xsl:otherwise>
							<a href="{res:binding[@name='dataset']/res:uri}">
								<xsl:value-of select="res:binding[@name='title']/res:literal"/>
							</a>
						</xsl:otherwise>
					</xsl:choose>
					
				</h2>
				<dl class=" {if($lang='ar') then 'dl-horizontal ar' else 'dl-horizontal'}">
					<xsl:if test="res:binding[@name='collection']">
						<dt>Nomisma URI</dt>
						<dd>
							<a href="{res:binding[@name='collection']/res:uri}">
								<xsl:value-of select="res:binding[@name='collection']/res:uri"/>
							</a>
						</dd>
					</xsl:if>	
					<xsl:if test="res:binding[@name='publisher']">
						<dt>Publisher</dt>
						<dd>
							<xsl:value-of select="res:binding[@name='publisher']/res:literal"/>
						</dd>
					</xsl:if>
					<dt>Description</dt>
					<dd>
						<xsl:value-of select="res:binding[@name='description']/res:literal"/>
					</dd>
				</dl>
			</td>

		</tr>
	</xsl:template>
</xsl:stylesheet>
