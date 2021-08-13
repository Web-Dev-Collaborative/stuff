<#macro toolbar>
</#macro>
<#macro breadcrumbs>
<div><span id="ca-breadcrumbs"></span></div>
</#macro>
<#macro body>
Missing body macro for ${nestedpage}
</#macro>
<#include "${nestedpage}">
<html>
  <head>
    <link rel="shortcut icon" href="${RequestContext.pathToRoot}res/css/images/favicon.ico" type="image/x-icon">
    <link rel="icon" href="${RequestContext.pathToRoot}res/css/images/favicon.ico" type="image/x-icon">
    <meta charset="UTF-8"/>
     <#include "js_css_include.ftl"/>
    <script type="text/javascript">
    <#include "main.js"/>
    <#include "header.js"/>
    </script>
  </head>
  <body>
    <div class="outer-north">
        <#include "header.ftl"/>
    </div> 
   
    <div class="outer-center">
<@body/>
    </div>
    
    <div class="outer-south env-${Global.environmentName}">
        Copyright Netflix.com
    </div>
    
  </body>
</html>

