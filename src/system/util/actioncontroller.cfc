<!-----------------------------------------------------------------------********************************************************************************Copyright 2005-2007 ColdBox Framework by Luis Majano and Ortus Solutions, Corpwww.coldboxframework.com | www.luismajano.com | www.ortussolutions.com********************************************************************************Author 	    :	Luis MajanoDate        :	August 21, 2006Description :	This is a cfc that contains method implementations for the base	cfc's eventhandler and plugin. This is an action base controller,	is where all action methods will be placed.	The front controller remains lean and mean.Modification History:08/21/2006 - Created10/10/2006 - Mail settings updated.12/08/2006 - Refactored.01/28/2006 - Datasource Alias resolved.-----------------------------------------------------------------------><cfcomponent name="actioncontroller" 			 hint="This is the action controller cfc. Method implementations are done here for sharing between plugin and event handler controllers. Plugins/Eh share an 'IS A' actioncontroller relation" 			 output="false"><!------------------------------------------- CONSTRUCTOR ------------------------------------------->	<cfscript>	//Controller Reference	variables.controller = structNew();	//Unique Instance ID	variables.__hash = createUUID();	</cfscript>	<cffunction name="getHash" access="public" hint="Get the instance's unique UUID" returntype="string" output="false">		<cfreturn variables.__hash>	</cffunction>	<!------------------------------------------- RESOURCE METHODS ------------------------------------------->	<!--- ************************************************************* --->	<cffunction name="getDatasource" access="public" output="false" returnType="any" hint="I will return to you a datasourceBean according to the alias of the datasource you wish to get from the configstruct (config.xml)">		<!--- ************************************************************* --->		<cfargument name="alias" type="string" hint="The alias of the datasource to get from the configstruct (alias property in the config.xml)">		<!--- ************************************************************* --->		<cfscript>		var datasources = controller.getSetting("Datasources");		//Check for datasources structure		if ( structIsEmpty(datasources) ){			throw("There are no datasources defined for this application.","","Framework.actioncontroller.DatasourceStructureEmptyException");		}		//Try to get the correct datasource.		if ( structKeyExists(datasources, arguments.alias) ){			return controller.getPlugin("beanFactory").create("coldbox.system.beans.datasourceBean").init(datasources[arguments.alias]);		}		else{			throw("The datasource: #arguments.alias# is not defined.","","Framework.actioncontroller.DatasourceNotFoundException");		}		</cfscript>	</cffunction>	<!--- ************************************************************* --->	<cffunction name="getfwLocale" access="public" output="false" returnType="string" hint="Get the default locale string used in the framework.">		<cfscript>			var localeStorage = controller.getSetting("LocaleStorage");			var storage = evaluate(localeStorage);			if ( localeStorage eq "" )				throw("The default settings in your config are blank. Please make sure you create the i18n elements.","","Framework.actioncontroller.i18N.DefaultSettingsInvalidException");			if ( not structKeyExists(storage,"DefaultLocale") ){				controller.getPlugin("i18n").setfwLocale(controller.getSetting("DefaultLocale"));			}			return storage["DefaultLocale"];		</cfscript>	</cffunction>	<!--- ************************************************************* --->	<cffunction name="getMailSettings" access="public" output="false" returnType="any" hint="I will return to you a mailsettingsBean modeled after your mail settings in your config.xml">		<cfscript>		return controller.getPlugin("beanFactory").create("coldbox.system.beans.mailsettingsBean").init(controller.getSetting("MailServer"),controller.getSetting("MailUsername"),controller.getSetting("MailPassword"), controller.getSetting("MailPort"));		</cfscript>	</cffunction>	<!--- ************************************************************* --->	<cffunction name="getResource" access="public" output="false" returnType="string" hint="Facade to i18n.getResource">		<!--- ************************************************************* --->		<cfargument name="resource" type="string" hint="The resource to retrieve from the bundle.">		<!--- ************************************************************* --->		<cfreturn controller.getPlugin("resourceBundle").getResource("#arguments.resource#")>	</cffunction>	<!--- ************************************************************* --->	<cffunction name="getSettingsBean"  hint="Returns a configBean with all the configuration structure." access="public"  returntype="coldbox.system.beans.configBean"   output="false">		<cfset var ConfigBean = controller.getPlugin("beanFactory").create("coldbox.system.beans.configBean").init(controller.getSettingStructure(false,true))>		<cfreturn ConfigBean>	</cffunction><!------------------------------------------- FRAMEWORK FACADES ------------------------------------------->	<!--- View Rendering Facades --->	<cffunction name="renderView"         access="public" hint="Facade to renderView" output="false" returntype="Any">		<!--- ************************************************************* --->		<cfargument name="view" required="true" type="string">		<!--- ************************************************************* --->		<cfreturn controller.getPlugin("renderer").renderView(arguments.view)>	</cffunction>	<cffunction name="renderExternalView" access="public" hint="Facade to renderView" output="false" returntype="Any">		<!--- ************************************************************* --->		<cfargument name="view" required="true" type="string">		<!--- ************************************************************* --->		<cfreturn controller.getPlugin("renderer").renderExternalView(arguments.view)>	</cffunction>	<!--- Plugin Facades --->	<cffunction name="getMyPlugin" access="public" hint="Facade" returntype="any" output="false">		<!--- ************************************************************* --->		<cfargument name="plugin" type="string" required="true" >		<!--- ************************************************************* --->		<cfreturn controller.getPlugin(arguments.plugin, true)>	</cffunction>	<cffunction name="getPlugin"   access="public" hint="Facade" returntype="any" output="false">		<!--- ************************************************************* --->		<cfargument name="plugin"       type="string" hint="The Plugin object's name to instantiate" >		<cfargument name="customPlugin" type="boolean" required="false" default="false">		<cfargument name="newInstance"  type="boolean" required="false" default="false">		<!--- ************************************************************* --->		<cfreturn controller.getPlugin(arguments.plugin,arguments.customPlugin,arguments.newInstance)>	</cffunction>		<!---Cache Facades --->	<cffunction name="getColdboxOCM" access="public" output="false" returntype="any" hint="Get ColdboxOCM">		<cfreturn controller.getColdboxOCM()/>	</cffunction>	<!--- Setting Facades --->	<cffunction name="getSettingStructure"  hint="Facade" access="public"  returntype="struct"   output="false">		<!--- ************************************************************* --->		<cfargument name="FWSetting"  	type="boolean" 	 required="false"  default="false">		<cfargument name="DeepCopyFlag" type="boolean"   required="false"  default="false">		<!--- ************************************************************* --->		<cfreturn controller.getSettingStructure(arguments.FWSetting,arguments.DeepCopyFlag)>	</cffunction>	<cffunction name="getSetting" 			hint="Facade" access="public" returntype="any"      output="false">		<!--- ************************************************************* --->		<cfargument name="name" 	    type="string"   	required="true">		<cfargument name="FWSetting"  	type="boolean" 	 	required="false"  default="false">		<!--- ************************************************************* --->		<cfreturn controller.getSetting(arguments.name,arguments.FWSetting)>	</cffunction>	<cffunction name="settingExists" 		hint="Facade" access="public" returntype="boolean"  output="false">		<!--- ************************************************************* --->		<cfargument name="name" 		type="string"  	required="true">		<cfargument name="FWSetting"  	type="boolean"  required="false"  default="false">		<!--- ************************************************************* --->		<cfreturn controller.settingExists(arguments.name,arguments.FWSetting)>	</cffunction>	<cffunction name="setSetting" 		    hint="Facade" access="public"  returntype="void"     output="false">		<!--- ************************************************************* --->		<cfargument name="name"  type="string" required="true" >		<cfargument name="value" type="any"    required="true" >		<!--- ************************************************************* --->		<cfset controller.setSetting(arguments.name,arguments.value)>	</cffunction>	<!--- Event Facades --->	<cffunction name="setNextEvent" access="public" returntype="void" hint="Facade"  output="false">		<!--- ************************************************************* --->		<cfargument name="event"  			type="string"   required="false"	default="#controller.getSetting("DefaultEvent")#" >		<cfargument name="queryString"  	type="any" 		required="No" 		default="" >		<cfargument name="addToken"			type="boolean" 	required="false" 	default="false"	>		<!--- ************************************************************* --->		<cfset controller.setNextEvent(arguments.event,arguments.queryString,arguments.addToken)>	</cffunction>	<cffunction name="runEvent" 	access="public" returntype="void" hint="Facade" output="false">		<!--- ************************************************************* --->		<cfargument name="event" type="string" required="no" default="">		<!--- ************************************************************* --->		<cfset controller.runEvent(arguments.event)>	</cffunction>	<!--- Controller Accessor/Mutators --->	<cffunction name="getcontroller" access="public" output="false" returntype="any" hint="Get controller">
		<cfreturn variables.controller/>
	</cffunction>
	<cffunction name="setcontroller" access="public" output="false" returntype="void" hint="Set controller">
		<cfargument name="controller" type="any" required="true"/>
		<cfset variables.controller = arguments.controller/>
	</cffunction>	<!------------------------------------------- UTILITY METHODS ------------------------------------------->	<cffunction name="throw" access="private" hint="Facade for cfthrow" output="false">		<!--- ************************************************************* --->		<cfargument name="message" 	type="string" 	required="yes">		<cfargument name="detail" 	type="string" 	required="no" default="">		<cfargument name="type"  	type="string" 	required="no" default="Framework">		<!--- ************************************************************* --->		<cfthrow type="#arguments.type#" message="#arguments.message#"  detail="#arguments.detail#">	</cffunction>	<cffunction name="dump" access="private" hint="Facade for cfmx dump" returntype="void">		<cfargument name="var" required="yes" type="any">		<cfdump var="#var#">	</cffunction>	<cffunction name="abort" access="private" hint="Facade for cfabort" returntype="void" output="false">		<cfabort>	</cffunction>	<cffunction name="include" access="private" hint="Facade for cfinclude" returntype="void" output="false">		<cfargument name="template" type="string">		<cfinclude template="#template#">	</cffunction></cfcomponent>