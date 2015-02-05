<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:nuds="http://nomisma.org/nuds" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:nm="http://nomisma.org/id/"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mets="http://www.loc.gov/METS/" xmlns:xlink="http://www.w3.org/1999/xlink"
	xmlns:res="http://www.w3.org/2005/sparql-results#" xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" xmlns:skos="http://www.w3.org/2004/02/skos/core#"
	exclude-result-prefixes="#all">

	<xsl:template name="nuds">
		<!-- create default document -->
		<xsl:apply-templates select="//nuds:nuds">
			<xsl:with-param name="lang"/>
		</xsl:apply-templates>

		<!-- create documents for each additional activated language -->
		<xsl:for-each select="//config/descendant::language[@enabled='true']">
			<xsl:apply-templates select="//nuds:nuds">
				<xsl:with-param name="lang" select="@code"/>
			</xsl:apply-templates>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="nuds:nuds">
		<xsl:param name="lang"/>
		<xsl:variable name="id" select="nuds:control/nuds:recordId"/>
		<doc>
			<field name="id">
				<xsl:choose>
					<xsl:when test="string($lang)">
						<xsl:value-of select="concat($id, '-', $lang)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$id"/>
					</xsl:otherwise>
				</xsl:choose>
			</field>
			<field name="recordId">
				<xsl:value-of select="$id"/>
			</field>
			<xsl:if test="string($lang)">
				<field name="lang">
					<xsl:value-of select="$lang"/>
				</field>
			</xsl:if>
			<xsl:call-template name="sortid">
				<xsl:with-param name="collection-name" select="$collection-name"/>
			</xsl:call-template>
			<field name="collection-name">
				<xsl:value-of select="$collection-name"/>
			</field>
			<field name="recordType">
				<xsl:value-of select="@recordType"/>
			</field>
			<field name="publisher_display">
				<xsl:value-of select="$publisher"/>
			</field>
			<field name="timestamp">
				<xsl:choose>
					<xsl:when test="string(descendant::*:maintenanceEvent[last()]/*:eventDateTime/@standardDateTime)">
						<xsl:choose>
							<xsl:when test="contains(descendant::*:maintenanceEvent[last()]/*:eventDateTime/@standardDateTime, 'Z')">
								<xsl:value-of select="descendant::*:maintenanceEvent[last()]/*:eventDateTime/@standardDateTime"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="concat(descendant::*:maintenanceEvent[last()]/*:eventDateTime/@standardDateTime, 'Z')"/>
							</xsl:otherwise>
						</xsl:choose>						
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="if(contains(datetime:dateTime(), 'Z')) then datetime:dateTime() else concat(datetime:dateTime(), 'Z')"/>
					</xsl:otherwise>
				</xsl:choose>
			</field>

			<!-- insert coin type facets and URIs -->
			<xsl:for-each select="descendant::nuds:typeDesc[string(@xlink:href)]">
				<xsl:variable name="href" select="@xlink:href"/>
				<field name="coinType_uri">
					<xsl:value-of select="$href"/>
				</field>
				<field name="coinType_facet">
					<xsl:value-of select="$nudsGroup//object[@xlink:href=$href]/descendant::nuds:title"/>
				</field>
			</xsl:for-each>

			<xsl:apply-templates select="nuds:descMeta">
				<xsl:with-param name="lang" select="$lang"/>
			</xsl:apply-templates>

			<xsl:choose>
				<xsl:when test="string($sparql_endpoint)">
					<!-- get findspots -->
					<xsl:apply-templates select="$sparqlResult/descendant::res:group[@id=$id]/res:result"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="nuds:digRep"/>
				</xsl:otherwise>
			</xsl:choose>

			<!-- fulltext -->
			<field name="fulltext">
				<xsl:value-of select="nuds:control/nuds:recordId"/>
				<xsl:text> </xsl:text>
				<xsl:for-each select="nuds:descMeta/descendant-or-self::text()">
					<xsl:value-of select="normalize-space(.)"/>
					<xsl:text> </xsl:text>
				</xsl:for-each>
				<xsl:if test="string($lang)">
					<xsl:for-each select="$rdf/descendant-or-self::node()[@xml:lang=$lang]/text()">
						<xsl:value-of select="normalize-space(.)"/>
						<xsl:text> </xsl:text>
					</xsl:for-each>
				</xsl:if>
			</field>
		</doc>
	</xsl:template>

	<xsl:template match="res:result">
		<xsl:variable name="title" select="if (string(res:binding[@name='findspotLabel']/res:literal)) then res:binding[@name='findspotLabel']/res:literal else res:binding[@name='title']/res:literal"/>
		<xsl:variable name="uri" select="res:binding[@name='findspot']/res:uri"/>

		<field name="findspot_facet">
			<xsl:value-of select="$title"/>
		</field>
		<xsl:if test="res:binding[@name='long']/res:literal and res:binding[@name='lat']/res:literal">
			<field name="findspot_uri">
				<xsl:value-of select="$uri"/>
			</field>
			<field name="findspot_geo">
				<xsl:value-of select="$title"/>
				<xsl:text>|</xsl:text>
				<xsl:value-of select="$uri"/>
				<xsl:text>|</xsl:text>
				<xsl:value-of select="concat(res:binding[@name='long']/res:literal, ',', res:binding[@name='lat']/res:literal)"/>
			</field>
		</xsl:if>
	</xsl:template>

	<xsl:template match="nuds:descMeta">
		<xsl:param name="lang"/>
		<xsl:variable name="recordType">
			<xsl:value-of select="parent::nuds:nuds/@recordType"/>
		</xsl:variable>
		<xsl:variable name="nuds:typeDesc_resource">
			<xsl:if test="string(nuds:typeDesc/@xlink:href)">
				<xsl:value-of select="nuds:typeDesc/@xlink:href"/>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="typeDesc" as="element()*">
			<xsl:choose>
				<xsl:when test="string(nuds:typeDesc/@xlink:href)">
					<xsl:choose>
						<xsl:when test="string($nuds:typeDesc_resource)">
							<xsl:copy-of select="$nudsGroup//object[@xlink:href = $nuds:typeDesc_resource]/nuds:nuds/nuds:descMeta/nuds:typeDesc"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:copy-of select="/content/nuds:nuds/nuds:descMeta/nuds:typeDesc"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="nuds:typeDesc"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:call-template name="get_coin_sort_fields">
			<xsl:with-param name="typeDesc" select="$typeDesc"/>
			<xsl:with-param name="lang" select="$lang"/>
		</xsl:call-template>

		<field name="title_display">
			<xsl:value-of select="normalize-space(nuds:title)"/>
		</field>
		<xsl:apply-templates select="nuds:subjectSet"/>
		<xsl:apply-templates select="nuds:physDesc"/>
		<xsl:apply-templates select="$typeDesc">
			<xsl:with-param name="recordType" select="$recordType"/>
			<xsl:with-param name="lang" select="$lang"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="nuds:adminDesc"/>
		<xsl:apply-templates select="nuds:refDesc"/>
		<xsl:apply-templates select="nuds:findspotDesc"/>
	</xsl:template>

	<xsl:template match="nuds:findspotDesc">
		<xsl:choose>
			<xsl:when test="string(@xlink:href)">
				<xsl:variable name="href" select="@xlink:href"/>
				<xsl:choose>
					<xsl:when test="contains($href, 'nomisma.org')">
						<xsl:variable name="label">
							<xsl:choose>
								<xsl:when test="string($rdf/*[@rdf:about=$href]/skos:prefLabel)">
									<xsl:value-of select="$rdf/*[@rdf:about=$href]/skos:prefLabel"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$href"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:if test="$rdf/*[@rdf:about=$href]/descendant::geo:lat and $rdf/*[@rdf:about=$href]/descendant::geo:long">
							<field name="findspot_geo">
								<xsl:value-of select="$label"/>
								<xsl:text>|</xsl:text>
								<xsl:value-of select="@xlink:href"/>
								<xsl:text>|</xsl:text>
								<xsl:value-of select="concat($rdf/*[@rdf:about=$href]/descendant::geo:long, ',', $rdf/*[@rdf:about=$href]/descendant::geo:lat)"/>
							</field>
						</xsl:if>
						<xsl:if test="$rdf/*[@rdf:about=$href]/descendant::nm:findspot[contains(@rdf:resource, 'geonames.org')]">
							<xsl:variable name="geonamesUri" select="$rdf/*[@rdf:about=$href]/descendant::nm:findspot[contains(@rdf:resource, 'geonames.org')][1]/@rdf:resource"/>
							<field name="findspot_geo">
								<xsl:value-of select="$label"/>
								<xsl:text>|</xsl:text>
								<xsl:value-of select="$href"/>
								<xsl:text>|</xsl:text>
								<xsl:value-of select="$geonames//place[@id=$geonamesUri]"/>
							</field>

							<!-- insert hierarchical facets -->
							<xsl:for-each select="tokenize($geonames//place[@id=$geonamesUri]/@hierarchy, '\|')">
								<field name="findspot_hier">
									<xsl:value-of select="concat('L', position(), '|', .)"/>
								</field>
								<field name="findspot_text">
									<xsl:value-of select="."/>
								</field>
							</xsl:for-each>
						</xsl:if>
						<field name="findspot_facet">
							<xsl:value-of select="$label"/>
						</field>
					</xsl:when>
				</xsl:choose>
				<field name="findspot_uri">
					<xsl:value-of select="$href"/>
				</field>
			</xsl:when>
			<xsl:otherwise>
				<field name="findspot_facet">
					<xsl:value-of select="nuds:findspot/nuds:geoname[@xlink:role='findspot']"/>
				</field>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="nuds:subjectSet">
		<xsl:for-each select="nuds:subject">
			<xsl:choose>
				<xsl:when test="string(@localType)">
					<xsl:choose>
						<xsl:when test="@localType='category'">
							<field name="category_display">
								<xsl:value-of select="."/>
							</field>
							<xsl:variable name="subsets" select="tokenize(., '--')"/>
							<xsl:for-each select="$subsets">
								<field name="category_facet">
									<xsl:value-of select="concat('L', position(), '|', .)"/>
								</field>
							</xsl:for-each>
						</xsl:when>
						<xsl:otherwise>
							<field name="{@localType}_facet">
								<xsl:value-of select="normalize-space(.)"/>
							</field>
							<field name="{@localType}_text">
								<xsl:value-of select="normalize-space(.)"/>
							</field>	
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<field name="subject_facet">
						<xsl:value-of select="normalize-space(.)"/>
					</field>	
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="string(@xlink:href)">
				<field name="subject_uri">
					<xsl:value-of select="@xlink:href"/>
				</field>
			</xsl:if>
			<field name="subject_text">
				<xsl:value-of select="normalize-space(.)"/>
			</field>
			<xsl:if test="contains(@xlink:href, 'geonames.org')">
				<xsl:call-template name="subject-geographic"/>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="subject-geographic">
		<xsl:variable name="href" select="@xlink:href"/>
		<xsl:variable name="role">subject</xsl:variable>
		<xsl:variable name="value" select="."/>
		<!-- *_geo format is 'mint name|URI of resource|KML-compliant geographic coordinates' -->
		<field name="{$role}_geo">
			<xsl:value-of select="$geonames//place[@id=$href]/@label"/>
			<xsl:text>|</xsl:text>
			<xsl:value-of select="$href"/>
			<xsl:text>|</xsl:text>
			<xsl:value-of select="$geonames//place[@id=$href]"/>
		</field>
		<!-- insert hierarchical facets -->
		<xsl:for-each select="tokenize($geonames//place[@id=$href]/@hierarchy, '\|')">
			<xsl:if test="not(. = $value)">
				<field name="{$role}_hier">
					<xsl:value-of select="concat('L', position(), '|', .)"/>
				</field>
				<field name="{$role}_text">
					<xsl:value-of select="."/>
				</field>
			</xsl:if>
			<xsl:if test="position()=last()">
				<xsl:variable name="level" select="if (.=$value) then position() else position() + 1"/>
				<field name="{$role}_hier">
					<xsl:value-of select="concat('L', $level, '|', $value)"/>
				</field>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="nuds:digRep">
		<xsl:apply-templates select="mets:fileSec"/>
	</xsl:template>

	<xsl:template match="mets:fileSec">
		<xsl:for-each select="mets:fileGrp[@USE='obverse' or @USE='reverse']">
			<xsl:variable name="side" select="substring(@USE, 1, 3)"/>
			<xsl:for-each select="mets:file">
				<field name="{@USE}_{$side}">
					<xsl:value-of select="mets:FLocat/@xlink:href"/>
				</field>
			</xsl:for-each>
		</xsl:for-each>
		<field name="imagesavailable">true</field>
	</xsl:template>

	<xsl:template match="nuds:physDesc">
		<xsl:apply-templates select="nuds:axis"/>
		<xsl:apply-templates select="nuds:measurementsSet"/>
		<xsl:for-each select="descendant::nuds:grade">
			<field name="grade_facet">
				<xsl:value-of select="."/>
			</field>
		</xsl:for-each>

		<!-- dateOnObject -->
		<xsl:for-each select="nuds:dateOnObject/*[string(@standardDate)]/@standardDate">
			<xsl:sort order="ascending"/>
			<field name="dob_num">
				<xsl:value-of select="."/>
			</field>
			<!-- add min and max -->
			<xsl:if test="position() = 1">
				<field name="dob_min">
					<xsl:value-of select="."/>
				</field>
			</xsl:if>
			<xsl:if test="position() = last()">
				<field name="dob_max">
					<xsl:value-of select="."/>
				</field>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="nuds:adminDesc">
		<xsl:for-each select="nuds:collection | nuds:repository | nuds:owner | nuds:department">
			<field name="{local-name()}_facet">
				<xsl:value-of select="normalize-space(.)"/>
			</field>
			<xsl:if test="string(@xlink:href)">
				<field name="{local-name()}_uri">
					<xsl:value-of select="@xlink:href"/>
				</field>
			</xsl:if>
		</xsl:for-each>

		<xsl:if test="nuds:identifier">
			<field name="identifier_display">
				<xsl:value-of select="normalize-space(nuds:identifier)"/>
			</field>
			<field name="identifier_text">
				<xsl:value-of select="normalize-space(nuds:identifier)"/>
			</field>
		</xsl:if>

		<xsl:for-each select="nuds:provenance/nuds:chronList/nuds:chronItem/nuds:previousColl|nuds:provenance/nuds:chronList/nuds:chronItem/nuds:auction/nuds:saleCatalog">
			<field name="provenance_text">
				<xsl:value-of select="."/>
			</field>
			<field name="provenance_facet">
				<xsl:value-of select="."/>
			</field>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="nuds:measurementsSet">
		<xsl:for-each select="*">
			<xsl:if test="number(.)">
				<field name="{local-name()}_num">
					<xsl:value-of select="normalize-space(.)"/>
				</field>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="nuds:axis">
		<xsl:if test="number(.)">
			<field name="axis_num">
				<xsl:value-of select="."/>
			</field>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>