<!-----------------------------------------------------------------------
********************************************************************************
Copyright 2005-2008 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldboxframework.com | www.luismajano.com | www.ortussolutions.com
********************************************************************************

Author 	    :	Luis Majano
Date        :	January 18, 2007
Description :
	This cfc takes care of request context operations such as
	creating new contexts, retrieving, clearing, etc.

Modification History:
01/18/2007 - Created
----------------------------------------------------------------------->
<cfcomponent name="requestService" output="false" hint="This service takes care of preparing and creating request contexts. Facades to FORM and URL" extends="baseService">

<!------------------------------------------- CONSTRUCTOR ------------------------------------------->

	<cffunction name="init" access="public" output="false" returntype="requestService" hint="Constructor">
		<cfargument name="controller" type="any" required="true">
		<cfscript>
			setController(arguments.controller);			
			/* Setup context properties */
			setContextProperties(structnew());
			return this;
		</cfscript>
	</cffunction>

<!------------------------------------------- PUBLIC ------------------------------------------->

	<!--- Request Capture --->
	<cffunction name="requestCapture" access="public" returntype="any" output="false" hint="I capture a request.">
		<cfscript>
			var Context = getContext();
			var DebugPassword = controller.getSetting("debugPassword");
			var EventName = controller.getSetting("EventName");
			var oFlashStorage = "";
			
			/* Collection Appends */
			initFORMURL();
			Context.collectionAppend(FORM,true);
			Context.collectionAppend(URL);			
					
			/* Get Flash Persistance Storage */
			if( controller.getSetting("FlashURLPersistScope",1) eq "session" ){
				oFlashStorage = controller.getPlugin("sessionstorage");
			}
			else{
				/* Get Client Storage */
				oFlashStorage = controller.getPlugin("clientstorage");				
			}
			/* Flash Persistance Contruction */	
			if ( oFlashStorage.exists('_coldbox_persistStruct') ){
				//Append flash persistance structure and overwrite if needed.
				Context.collectionAppend(oFlashStorage.getVar('_coldbox_persistStruct'),true);
				//Remove Flash persistance
				oFlashStorage.deleteVar('_coldbox_persistStruct');
			}	
			
			//Object Caching Garbage Collector
			controller.getColdboxOCM().reap();
			
			//Debug Mode Checks
			if ( Context.valueExists("debugMode") and isBoolean(Context.getValue("debugMode")) ){
				if ( DebugPassword eq "")
					controller.getDebuggerService().setDebugMode(Context.getValue("debugMode"));
				else if ( Context.valueExists("debugpass") and CompareNoCase(DebugPassword,Context.getValue("debugpass")) eq 0 )
					controller.getDebuggerService().setDebugMode(Context.getValue("debugMode"));
			}

			//Default Event Definition
			if ( not Context.valueExists(EventName))
				Context.setValue(EventName, controller.getSetting("DefaultEvent"));
			//Event More Than 1 Check, grab the first event instance, other's are discarded
			if ( listLen(Context.getValue(EventName)) gte 2 )
				Context.setValue(EventName, getToken(Context.getValue(EventName),2,","));
			
			/* Are we using event caching? */
			EventCachingTest(Context);
			
			//Return Context
			return Context;
		</cfscript>
	</cffunction>

	<!--- Event caching test --->
	<cffunction name="EventCachingTest" access="public" output="false" returntype="void" hint="Tests if the incoming context is an event cache">
		<cfargument name="context" required="true" type="any" hint="">
		<cfscript>
			var eventCacheKey = "";
			/* Are we using event caching? */
			if ( controller.getSetting("EventCaching") ){	
				
				/* Check for Event Cache Purge */
				if ( Context.valueExists("fwCache") ){
					/* Clear the cache key. */
					eventCacheKey = controller.getHandlerService().EVENT_CACHEKEY_PREFIX & Context.getCurrentEvent() & "-" & controller.getColdboxOCM().getEventURLFacade().getUniqueHash(Context.getCurrentEvent());
					controller.getColdboxOCM().clearKey( eventCacheKey );
				}
				else{
					/* Setup the cache key */
					eventCacheKey = controller.getHandlerService().EVENT_CACHEKEY_PREFIX & Context.getCurrentEvent() & "-" & controller.getColdboxOCM().getEventURLFacade().getUniqueHash(Context.getCurrentEvent());
					/* Cleanup the cache key, just in case. */
					Context.removeValue('cbox_eventCacheableEntry');
					/* Determine if this event has been cached */
					if ( controller.getColdboxOCM().lookup(eventCacheKey) ){
						/* Event has been found, flag it so we can render it */
						Context.setEventCacheableEntry(eventCacheKey);
					}
				}//end else no purging
			}//If using event caching.
		</cfscript>
	</cffunction>
	
	<!--- Get the Context --->
	<cffunction name="getContext" access="public" output="false" returntype="any" hint="Get the Request Context">
		<cfscript>
			if ( contextExists() )
				return request.cb_requestContext;
			else
				return createContext();
		</cfscript>
	</cffunction>

	<!--- Set the context --->
	<cffunction name="setContext" access="public" output="false" returntype="void" hint="Set the Request Context">
		<cfargument name="Context" type="any" required="true">
		<cfscript>
			request.cb_requestContext = arguments.Context;
		</cfscript>
	</cffunction>

	<!--- Check if context exists --->
	<cffunction name="contextExists" access="public" output="false" returntype="boolean" hint="Does the request context exist">
		<cfscript>
			return structKeyExists(request,"cb_requestContext");
		</cfscript>
	</cffunction>
	
	<!--- Get / Set context properties --->
	<cffunction name="getContextProperties" access="public" output="false" returntype="struct" hint="Get ContextProperties">
		<cfreturn instance.ContextProperties/>
	</cffunction>	
	<cffunction name="setContextProperties" access="public" output="false" returntype="void" hint="Set ContextProperties">
		<cfargument name="ContextProperties" type="struct" required="true"/>
		<cfset instance.ContextProperties = arguments.ContextProperties/>
	</cffunction>
	
<!------------------------------------------- PRIVATE ------------------------------------------->
	
	<cffunction name="initFORMURL" access="private" returntype="void" hint="param form/url" output="false" >
		<cfparam name="FORM" default="#structNew()#">
		<cfparam name="URL"  default="#structNew()#">		
	</cffunction>
	
	<!--- Creates a new Context Object --->
	<cffunction name="createContext" access="private" output="false" returntype="any" hint="Creates a new request context object">
		<cfscript>
		var oContext = "";
		var oDecorator = "";
		
		/* Ensure Loaded Properties */
		loadProperties();
		
		/* Param FORM/URL */
		initFORMURL();
			
		//Create the original request context
		oContext = CreateObject("component","coldbox.system.beans.requestContext").init(FORM,URL,getContextProperties());
		
		//Determine if we have a decorator, if we do, then decorate it.
		if ( getContextProperties().isUsingDecorator ){
			//Create the decorator
			oDecorator = CreateObject("component",controller.getSetting("RequestContextDecorator")).init(oContext);
			//Set Request Context in storage
			setContext(oDecorator);
			//Return
			return oDecorator;
		}
		
		//Set Request Context in storage
		setContext(oContext);
		
		//Return Context
		return oContext;
		</cfscript>
	</cffunction>
	
	<!--- Lazy Load Context Properties --->
	<cffunction name="loadProperties" access="private" returntype="void" hint="Load the context properties" output="false" >
		<cfscript>
			var Properties = structnew();
			
			/* Verify we have context properties */
			if( structisEmpty(getContextProperties()) ){
				/* Setup Context Properties */
				Properties.DefaultLayout = "";
				Properties.DefaultView = "";
				Properties.ViewLayouts = structNew();
				Properties.FolderLayouts = structNew();
				Properties.EventName = "";
				Properties.isSES = false;
				Properties.sesbaseURL = "";
				
				/* Get default context properties */
				if( controller.settingExists("EventName") ){
					Properties.EventName = controller.getSetting("EventName");
				}		
				if ( controller.settingExists("DefaultLayout") ){
					Properties.DefaultLayout = controller.getSetting("DefaultLayout");
				}
				if ( controller.settingExists("DefaultView") ){
					Properties.DefaultView = controller.getSetting("DefaultView");
				}
				if ( controller.settingExists("ViewLayouts") ){
					Properties.ViewLayouts = controller.getSetting("ViewLayouts");
				}
				if ( controller.settingExists("FolderLayouts") ){
					Properties.FolderLayouts = controller.getSetting("FolderLayouts");
				}
				if( controller.settingExists("sesbaseURL") ){
					Properties.sesbaseurl = controller.getSetting('sesBaseURL');
				}
				/* Decorator */
				if ( controller.settingExists("RequestContextDecorator") and controller.getSetting("RequestContextDecorator") neq ""){
					Properties.isUsingDecorator = true;
				}
				else{
					Properties.isUsingDecorator = false;
				}
				/* Persist them */
				setContextProperties(Properties);		
			}// end if empty properties
		</cfscript>
	</cffunction>

</cfcomponent>