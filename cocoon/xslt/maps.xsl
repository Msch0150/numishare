<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:numishare="http://code.google.com/p/numishare/" exclude-result-prefixes="#all" version="2.0">
	<!-- includes -->
	<xsl:include href="header.xsl"/>
	<xsl:include href="footer.xsl"/>
	<xsl:include href="search_segments.xsl"/>

	<xsl:param name="pipeline"/>
	<xsl:param name="display_path"/>
	<xsl:variable name="collection_type" select="/content//collection_type"/>
	
	<xsl:param name="q"/>
	<xsl:param name="lang"/>
	<xsl:param name="tokenized_q" select="tokenize($q, ' AND ')"/>

	<xsl:template match="/">
		<html>
			<head>
				<title>
					<xsl:value-of select="//config/title"/>
					<xsl:text>: Map the Collection</xsl:text>
				</title>
				<link rel="shortcut icon" type="image/x-icon" href="{$display_path}images/favicon.png"/>
				<!-- YUI grids -->
				<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/2.8.2r1/build/grids/grids-min.css"/>
				<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/2.8.2r1/build/reset-fonts-grids/reset-fonts-grids.css"/>
				<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/2.8.2r1/build/base/base-min.css"/>
				<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/2.8.2r1/build/fonts/fonts-min.css"/>
				
				<!-- local theme and styling -->
				<link type="text/css" href="{$display_path}themes/{//config/theme/jquery_ui_theme}.css" rel="stylesheet"/>
				<link type="text/css" href="{$display_path}style.css" rel="stylesheet"/>
				
				<!-- jquery -->
				<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.6.4/jquery.min.js"/>
				<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.23/jquery-ui.min.js"/>
				
				<!-- menu -->
				<script type="text/javascript" src="{$display_path}javascript/ui/jquery.ui.core.js"/>
				<script type="text/javascript" src="{$display_path}javascript/ui/jquery.ui.widget.js"/>
				<script type="text/javascript" src="{$display_path}javascript/ui/jquery.ui.position.js"/>
				<script type="text/javascript" src="{$display_path}javascript/ui/jquery.ui.button.js"/>
				<script type="text/javascript" src="{$display_path}javascript/ui/jquery.ui.menu.js"/>
				<script type="text/javascript" src="{$display_path}javascript/ui/jquery.ui.menubar.js"/>
				<script type="text/javascript" src="{$display_path}javascript/numishare-menu.js"/>
				
				<!-- facet related js and css -->
				<link type="text/css" href="{$display_path}jquery.multiselect.css" rel="stylesheet"/>
				<script type="text/javascript" src="{$display_path}javascript/jquery.multiselect.min.js"/>
				<script type="text/javascript" src="{$display_path}javascript/jquery.multiselectfilter.js"/>
				<script type="text/javascript" src="{$display_path}javascript/jquery.livequery.js"/>	

				<!-- display timemap for hoards, regular openlayers map for coin and coin type collections -->
				<xsl:choose>
					<xsl:when test="$collection_type='hoard'">
						<!-- timemap dependencies -->
						<script type="text/javascript" src="http://www.openlayers.org/api/OpenLayers.js"/>
						<script type="text/javascript" src="{$display_path}javascript/mxn.js"/>
						<script type="text/javascript" src="http://static.simile.mit.edu/timeline/api-2.2.0/timeline-api.js?bundle=true"/>
						<script type="text/javascript" src="{$display_path}javascript/timemap_full.pack.js"/>
						<script type="text/javascript" src="{$display_path}javascript/param.js"/>
						<script type="text/javascript" src="{$display_path}javascript/loaders/xml.js"/>
						<script type="text/javascript" src="{$display_path}javascript/loaders/kml.js"/>
						<script type="text/javascript" src="{$display_path}javascript/map_functions.js"/>
						<script type="text/javascript" src="{$display_path}javascript/facet_functions.js"/>
					</xsl:when>
					<xsl:otherwise>
						<!-- fancybox -->
						<link type="text/css" href="{$display_path}jquery.fancybox-1.3.4.css" rel="stylesheet"/>
						<script type="text/javascript" src="{$display_path}javascript/jquery.fancybox-1.3.4.min.js"/>
						<!-- maps-->
						<script type="text/javascript" src="http://www.openlayers.org/api/OpenLayers.js"/>
						<script type="text/javascript" src="http://maps.google.com/maps/api/js?v=3.2&amp;sensor=false"/>
						<script type="text/javascript" src="{$display_path}javascript/map_functions.js"/>		
						<script type="text/javascript" src="{$display_path}javascript/facet_functions.js"/>
						<script type="text/javascript">
						$(document).ready(function(){
							$('a.thumbImage').livequery(function(){
								$(this).fancybox();
							});
						});
						</script>
					</xsl:otherwise>
				</xsl:choose>
				
				<!-- Google Analytics -->
				<xsl:if test="string(/config/google_analytics/script)">
					<script type="text/javascript">
						<xsl:value-of select="//config/google_analytics/script"/>
					</script>
				</xsl:if>
			</head>
			<body class="yui-skin-sam">
				<div id="doc4" class="{//config/theme/layouts/*[name()=$pipeline]/yui_class}">
					<xsl:call-template name="header"/>
					<xsl:call-template name="maps"/>
					<xsl:call-template name="footer"/>
				</div>
			</body>
		</html>
	</xsl:template>

	<xsl:template name="maps">
		<div id="bd">
			<div id="backgroundPopup"/>
			<h1>Maps</h1>
			<!--<cinclude:include src="cocoon:/get_department_checkbox"/>-->
			<div class="remove_facets"/>

			<xsl:choose>
				<xsl:when test="//result[@name='response']/@numFound &gt; 0">
					<div style="display:table">
						<ul id="filter_list" section="maps">
							<xsl:apply-templates select="//lst[@name='facet_fields']"/>
						</ul>
					</div>
					<!-- display timemap divs for hoard records or regular map + ajax results div for non-hoard collections -->
					<xsl:choose>
						<xsl:when test="$collection_type='hoard'">
							<div id="timemap">
								<div id="mapcontainer">
									<div id="map"/>
								</div>
								<div id="timelinecontainer">
									<div id="timeline"/>
								</div>
							</div>
						</xsl:when>
						<xsl:otherwise>
							<div id="mapcontainer"/>
							<div class="legend">
								<table>
									<tbody>
										<tr>
											<th style="width:100px">Legend</th>
											<td style="background-color:#ffcc66;border:2px solid #cc6633;width:50px;"/>
											<td style="width:100px">Mint</td>
											<td style="background-color:#00a000;border:2px solid #006100;width:50px;"/>
											<td style="width:100px">Findspot</td>
										</tr>
									</tbody>
								</table>
							</div>
							<a name="results"/>
							<div id="results"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<h2> No results found.</h2>
				</xsl:otherwise>
			</xsl:choose>
			<!--<input type="hidden" name="q" id="facet_form_query" value="{if (string($imageavailable_stripped)) then $imageavailable_stripped else '*:*'}"/>-->
			<input id="facet_form_query" name="q" value="*:*" type="hidden"/>
			<span style="display:none" id="collection_type">
				<xsl:value-of select="$collection_type"/>
			</span>
		</div>
	</xsl:template>
	
	<xsl:template match="lst[@name='facet_fields']">
		<xsl:for-each select="lst[not(@name='mint_geo') and number(int[@name='numFacetTerms']) &gt; 0 and not(@name='mint_facet')]|lst[@name='mint_facet' and $collection_type='hoard']">
			<li class="fl">
				<xsl:variable name="val" select="@name"/>
				<xsl:variable name="new_query">
					<xsl:for-each select="$tokenized_q[not(contains(., $val))]">
						<xsl:value-of select="."/>
						<xsl:if test="position() != last()">
							<xsl:text> AND </xsl:text>
						</xsl:if>
					</xsl:for-each>
				</xsl:variable>
				
				<xsl:variable name="title">
					<xsl:value-of select="numishare:normalize_fields(@name)"/>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="@name = 'category_facet'">
						<!--<h2>Category</h2>-->
						<button class="ui-multiselect ui-widget ui-state-default ui-corner-all" type="button" title="Category" aria-haspopup="true" style="width: 180px;" id="{@name}_link" label="{$q}">
							<span class="ui-icon ui-icon-triangle-2-n-s"/>
							<span>Category</span>
						</button>
						<xsl:choose>
							<xsl:when test="contains($q, @name)">
								<div class="ui-multiselect-menu ui-widget ui-widget-content ui-corner-all" style="width: 180px">
									<div class="ui-widget-header ui-corner-all ui-multiselect-header ui-helper-clearfix ui-multiselect-hasfilter">
										<ul class="ui-helper-reset">
											<li class="ui-multiselect-close">
												<a class="ui-multiselect-close category-close" href="#"> close<span class="ui-icon ui-icon-circle-close"/>
												</a>
											</li>
										</ul>
									</div>
									<ul class="category-multiselect-checkboxes ui-helper-reset" id="{@name}-list" style="height: 175px;">
										<!--<xsl:if test="contains($q, @name)">
											<cinclude:include src="cocoon:/get_categories?q={$q}&amp;fq=*&amp;prefix=L1&amp;link=&amp;section=collection"/>
										</xsl:if>-->
									</ul>
								</div>
							</xsl:when>
							<xsl:otherwise>
								<div class="ui-multiselect-menu ui-widget ui-widget-content ui-corner-all" style="width: 180px;">
									<div class="ui-widget-header ui-corner-all ui-multiselect-header ui-helper-clearfix ui-multiselect-hasfilter">
										<ul class="ui-helper-reset">
											<li class="ui-multiselect-close">
												<a class="ui-multiselect-close category-close" href="#"> close<span class="ui-icon ui-icon-circle-close"/>
												</a>
											</li>
										</ul>
									</div>
									<ul class="category-multiselect-checkboxes ui-helper-reset" id="{@name}-list" style="height: 175px;"/>
								</div>
							</xsl:otherwise>
						</xsl:choose>
						<br/>
					</xsl:when>
					<xsl:when test="@name='century_num'">
						<button class="ui-multiselect ui-widget ui-state-default ui-corner-all" type="button" title="Date" aria-haspopup="true" style="width: 180px;" id="{@name}_link" label="{$q}">
							<span class="ui-icon ui-icon-triangle-2-n-s"/>
							<span>Date</span>
						</button>
						<div class="ui-multiselect-menu ui-widget ui-widget-content ui-corner-all date-div" style="width: 180px;">
							<div class="ui-widget-header ui-corner-all ui-multiselect-header ui-helper-clearfix ui-multiselect-hasfilter">
								<ul class="ui-helper-reset">
									<li class="ui-multiselect-close">
										<a class="ui-multiselect-close century-close" href="#">
											<span class="ui-icon ui-icon-circle-close"/>
										</a>
									</li>
								</ul>
							</div>
							<ul class="century-multiselect-checkboxes ui-helper-reset" id="{@name}-list" style="height: 175px;">
								<!--<cinclude:include src="cocoon:/get_centuries?q={encode-for-uri($q)}"/>-->
							</ul>
						</div>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="count" select="number(int[@name='numFacetTerms'])"/>
						<xsl:variable name="mincount" as="xs:integer">
							<xsl:choose>
								<xsl:when test="$count &gt; 500">
									<xsl:value-of select="ceiling($count div 500)"/>
								</xsl:when>
								<xsl:otherwise>1</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:variable name="select_new_query">
							<xsl:choose>
								<xsl:when test="string($new_query)">
									<xsl:value-of select="$new_query"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>*:*</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<select id="{@name}-select" multiple="multiple" class="multiselect" size="10" title="{$title}" q="{$q}" mincount="{$mincount}"
							new_query="{if (contains($q, @name)) then $select_new_query else ''}">
							<xsl:if test="$pipeline='maps'">
								<xsl:attribute name="style">width:180px</xsl:attribute>
							</xsl:if>
							<xsl:if test="contains($q, @name)">
								<!--<option selected="selected">test</option>-->
								<!--<cinclude:include src="cocoon:/maps_get_facet_options?q={$q}&amp;category={@name}&amp;sort=index&amp;offset=0&amp;limit=-1&amp;rows=0&amp;mincount={$mincount}"/>-->
							</xsl:if>
						</select>
						<br/>
					</xsl:otherwise>
				</xsl:choose>
			</li>
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>
