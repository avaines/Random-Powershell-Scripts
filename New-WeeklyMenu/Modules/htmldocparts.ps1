$htmlPartStart = "<html>
<head>
<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'> </meta>
<style>
body p {font-family:Tahoma;font-size:10pt; color: #0C0B07;}
h1 {font-family:Tahoma;font-size:14pt; color: #313131;}
div {font-family:Tahoma; font-size:10pt; color: #0C0B07;}
#parent {height:90%;text-align: center; display: table;width: 100%;}
#menu-table {display: table-cell;text-align: center; vertical-align: middle;} 
#menu-table table {width: 100%; table-layout: fixed;  border-collapse: collapse; padding-left: 2}
#menu-table table tr:not(:first-child) th {display: inline-block;  -webkit-writing-mode: vertical-rl;  -ms-writing-mode: tb-rl;  writing-mode: vertical-rl;}
#menu-table th {padding: 4px; font-size: 12px}
#menu-table img {width: 20px;}
#menu-table td {width: auto; border: 1px dotted black; padding: 5px;}
#menu-table .rotate {white-space:nowrap; -webkit-transform: rotate(-80deg); -moz-transform: rotate(-80deg); -o-transform: rotate(-80deg);}
#menu-table table {table-layout: auto;  border-collapse: collapse;}
.nested-table {width: 100%; margin: auto; height:30px}
.book {float: left; font-style: italic;}
.lunch {float: right;}
.recipe {text-align:center; font-weight: bold;}
#footer p{font-family:Tahoma;font-size:8pt; font-style: italic;color: #0C0B07;}
#footer {width:100%;float:left;}
#browser-support {  background: ivory;  border-left: 6px skyblue solid;  font-family: courier new;  font-size: 14px;  margin: 12px 0;  padding: 6px;}	
</style>
</head>
<body>
<div id='parent'>	
<div id='menu-table'>
  <table>"


$htmlPartStop = "</div></div><div id='footer'>
			<hr></hr><p>Created "+ $(get-Date) +" on " + $env:ComputerName + " by "+ $env:UserName +"</p>
			</div></Body></html>"