﻿#
# ==============================================================
# @ID       $Id: DocTreeGenerator.psm1 1558 2015-11-08 21:55:14Z ms $
# @created  2011-08-01
# @project  http://cleancode.sourceforge.net/
# ==============================================================
#
# The official license for this file is shown next.
# Unofficially, consider this e-postcardware as well:
# if you find this module useful, let us know via e-mail, along with
# where in the world you are and (if applicable) your website address.
#
#
# ***** BEGIN LICENSE BLOCK *****
# Version: MPL 1.1
#
# The contents of this file are subject to the Mozilla Public License Version
# 1.1 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
# http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS IS" basis,
# WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
# for the specific language governing rights and limitations under the
# License.
#
# The Original Code is part of the CleanCode toolbox.
#
# The Initial Developer of the Original Code is Michael Sorens.
# Portions created by the Initial Developer are Copyright (C) 2011
# the Initial Developer. All Rights Reserved.
#
# Contributor(s):
#
# ***** END LICENSE BLOCK *****
#

Set-StrictMode -Version Latest
#requires -version 3.0

[System.Reflection.Assembly]::LoadWithPartialName("System.web") | Out-Null


<#

.SYNOPSIS
Generates API documentation in HTML format for one or more PowerShell namespaces.

.DESCRIPTION
Convert-HelpToHtmlTree generates a complete API in HTML format (similar to Sandcastle for .NET or javadoc for Java) for your PowerShell libraries.  You specify (via the Namespaces parameter) which PowerShell modules to document. The modules must be installed as user modules (i.e. in C:\Users\username\Documents\WindowsPowerShell\Modules) rather than system modules (i.e. C:\Windows\System32\WindowsPowerShell\v1.0\Modules).  See "Storing Modules on Disk" at http://msdn.microsoft.com/en-us/library/dd878324%28v=vs.85%29.aspx as well as "Installing Modules" in my Simple-Talk.com article at http://www.simple-talk.com/dotnet/.net-tools/further-down-the-rabbit-hole-powershell-modules-and-encapsulation/#seventh.

As with an API documentation generator for any language, the output you get is only as good as the input you provide.
But Convert-HelpToHtmlTree needs little additional information than good coding practice already dictates. If you have designed your modules to display proper help when you invoke the standard Get-Help cmdlet you have already done most everything you need to use Convert-HelpToHtmlTree.
If you run Convert-HelpToHtmlTree with totally undecorated source files it will generate the full API tree, but instead of detailed descriptions of each function in your library you will get only a concise syntax diagram--just as Get-Help would do. With Convert-HelpToHtmlTree, you will also get a slew of warning messages telling you what key pieces of documentation you are missing.

To learn how to decorate your source modules properly for Get-Help and Convert-HelpToHtmlTree, start with the PowerShell help topic "about_Comment_Based_Help".  Scroll down to the "Syntax for Comment-Based Help in Functions" section.  Note that the page also talks about adding help for the script itself; that applies only to main scripts (ps1 files) not to modules (psm1 files). Convert-HelpToHtmlTree works only with modules, not with scripts. Best practices dictate that for any substantive code, you will want to use modules in any case. And be sure to use Export-ModuleMember to explicitly specify which functions are public functions within your module; omitting it makes *all* your functions public by default.

=== File Organization ===

Convert-HelpToHtmlTree needs some additional doc-comments to generate a cohesive API for you.
(1) Each module (x.psm1) must have an associated manifest (x.psd1) in the same directory and the manifest must include a Description property.
(2) Each module must have an associated overview (module_overview.html) in the same directory. This is a standard HTML file.  The contents of the <body> element are extracted verbatim as the introductory text of the index.html page for each module.
(3) Each namespace must also include an associated overview (namespace_overview.html).  This is a standard HTML file.  The contents of the <body> element are extracted verbatim as the introductory text of each namespace in the master index.html page.

Note that I use the term "namespace" here informally because (as of v3) PowerShell does not yet have the notion of namespaces.  Convert-HelpToHtmlTree, however, requires you to structure your modules grouped in namespaces as shown in the sample input tree below.  Thus, if you have a module MyStuff.psm1, normal PowerShell conventions require you to store this in a path like this:

	...\WindowsPowerShell\Modules\MyStuff\MyStuff.psm1

...but Convert-HelpToHtmlTree requires you to include one more level for namespace, so the module must be stored in a path like this:

	...\WindowsPowerShell\Modules\MyNamespace\MyStuff\MyStuff.psm1

This allows you to organize your modules into more than one logical group if desired. In my own PowerShell library, for example, I have FileTools, SqlTools, and SvnTools modules (among others) all under the CleanCode namespace. But you may, however, include multiple namespaces.

Here's a sample input tree illustrating this:
    ==========================================
    WindowsPowerShell\Modules
    +---namespace1
    	+---namespace_overview.html
    	+---moduleA
    		+---module_overview.html
    		+---moduleA.psm1
    		+---moduleA.psd1
    	+---moduleB
    		+---module_overview.html
    		+---moduleB.psm1
    		+---moduleB.psd1
    	etc...
    +---namespace2
    	+---namespace_overview.html
    	+---moduleX
    		+---module_overview.html
    		+---moduleX.psm1
    		+---moduleX.psd1
    	+---moduleY
    		+---module_overview.html
    		+---moduleY.psm1
    		+---moduleY.psd1
    	etc...
    ==========================================

The output structure mirrors the input structure; the above input might generate the output tree shown below. There is a single master index page documenting all namespaces.
    ==========================================
    $TargetDir
    +---contents.html
    +---index.html
    +---namespace1
    	+---moduleA
    		+---index.html
    		+---Function1.html
    		+---Function2.html
    		+---Function3.html
    		+---Function4.html
    		etc...
    	+---moduleB
    		+---index.html
    		+---Function1.html
    		+---Function2.html
    		etc...
    +---namespace2
    	+---moduleX
    		+---index.html
    		+---Function1.html
    		etc...
    	+---moduleY
    		+---index.html
    		+---Function1.html
    		+---Function2.html
    		etc...
    etc...
    ==========================================

Convert-HelpToHtmlTree reports its progress as it runs, indicating each module and each function it is documenting. Any detected problems are comingled in this output report. Here is a portion of a run on my CleanCode library (with selected parts removed to force problems to be reported): 
    ==========================================
    Module: Assertion
    	Command: Assert-Expression
    	Command: Get-AssertCounts
    	Command: Set-AbortOnError
    	Command: Set-MaxExpressionDisplayLength
    Module: DocTreeGenerator
    	Command: Convert-HelpToHtmlTree
    ** Missing summary (from module_overview.html)
    ** Missing description (from manifest)
    Module: EnhancedChildItem
    	Command: Get-EnhancedChildItem
    ** Missing summary (from module_overview.html)
    Module: Miscellaneous
    ** No objects found
    Module: FileTools
    	Command: Get-IniFile
    etc...
    ==========================================

At the end of the run it also reports the number of namespaces, modules, functions, and total files processed.

=== Documentation Template ===

Take a look at the default template (see TemplateName parameter) and you will find it sprinkled with place holders that are automatically filled in at runtime (surrounded by braces): title, subtitle, breadcrumbs, preamble, body, postscript, copyright, and revdate.  Also, there are module-specific place holders of the form {module.propertyname} where "propertyname" may be any of the standard properties of a module -- use this to see the list of properties:
	Get-Module | Get-Member

You will also see conditional section definitions of the form 
	{ifdef pagetype}
	. . .
	{endif pagetype}
...where "pagetype" may be any of the four types of pages created: 
+ the single master page (pagetype="master"),
+ the single contents page ("contents"),
+ the module index pages, one per module ("module"), and
+ the function pages, one per exported function ("function").
The content of these conditional sections (which may be any HTML) is included only on the pages of the corresponding type, while the other conditional sections are suppressed.  Note that the module-specific place holders discussed earlier (e.g. {module.xyz}) may be used in module pages or function pages only.

=== Output Enhancements: Live links ===

Unlike the MSDN pages for the standard PowerShell library, output generated by this function makes live links in your references (.LINK) documentation section.  There are seven classes of input you can specify, shown below.  In order, they are MSDN-defined (built-in) cmdlet, MSDN-defined (built-in) topic, custom function in the same module, custom function in a different local module (not yet implemented), plain text, explicit link with a label, and explicit link without a label.

    Get-ChildItem
    about_Aliases
    New-CustomFunctionInSameModule
    New-CustomFunctionInOtherModule
    some plain text here
    [other important stuff] (http://foobar.com)
    http://alpha/beta/

This output is generated from the above input:

    <ul>
    <li><a href='http://technet.microsoft.com/en-us/library/dd347686.aspx'>Get-ChildItem</a></li>
    <li><a href='http://technet.microsoft.com/en-us/library/dd347645.aspx'>about_Aliases</a></li>
    <li><a href='New-CustomFunctionInSameModule.html'>New-CustomFunctionInSameModule</a></li>
    <li><a href='../../namespace/module/New-CustomFunctionInOtherModule.html'>New-CustomFunctionInOtherModule</a></li>
    <li>some plain text here</li>
    <li><a href='http://foobar.com'>other important stuff</a></li>
    <li><a href='http://alpha/beta/'>http://alpha/beta/</a></li>
    </ul>

The MSDN references are retrieved automatically from two fixed MSDN reference pages (one for cmdlets and one for "about" topics).  If those fixed references ever change URLs, that will break the generator; update those URLs in the Get-CmdletDocLinks function to mend it.

=== Output Enhancements: Formatting ===

Convert-HelpToHtmlTree also adds some simple CSS styling to the generated web pages, making the generated web pages much more user-friendly than the plain mono-spaced text output of Get-Help viewed in a PowerShell window. Viewing help from within Show-Command is only minimally better than Get-Help, adding some bold markup. Convert-HelpToHtmlTree, on the other hand:
+ Adds section headings to each of the main sections within help.
+ Outputs most text in proportional font.
+ Outputs portions of text you designate (via leading white space on a line) in a fixed-width font.
+ Preserves your line breaks. (So if you want text to flow and wrap automatically at the window edge you must put it all in a single paragraph in your source file.)
+ Highlights initial code sample in each example. (Note that, just like Get-Help, ONLY the first line immediately following the .EXAMPLE directive is treated as the code sample, so resist the urge to put line breaks in your sample!)

.PARAMETER TargetDir
Directory name to store the generated HTML documentation set.
If not supplied, the current directory is used.

.PARAMETER Namespaces
One or more names of top-level directories under your user-level
module repository (...Documents\WindowsPowerShell\Modules) to document.
Wilcards are permitted.

.PARAMETER TemplateName
Name of your custom template file to use to generate each HTML file.
If not supplied, the default template (psdoc_template.html) is used;
it is stored in the same directory as this module file.

.PARAMETER DocTitle
The value of DocTitle fills in the TITLE place holder on the overview page
and the SUBTITLE place holder on all subordinate pages.
The current namespace is affixed to the beginning, e.g.
with a namespace of "Abc" and a DocTitle of "Libraries v1.0", the 
value that is substituted in the template is "Abc Libraries v1.0".
If not supplied, the value would be the more generic "Abc Namespace".
Using the default template, DocTitle appears in the web page title 
and in the main heading for the home (overview) page.
It is also used on top of the heading of each subordinate page 
in a smaller font to provide context.

.PARAMETER Copyright
The value of Copyright fills in the COPYRIGHT place holder on each page.
Using the default template, Copyright appears at the bottom of each page.
If you do not intend to supply this value edit the default template
to remove the rest of the copyright phrase.

.PARAMETER RevisionDate
The value of RevisionDate fills in the REVDATE place holder on each page.
Using the default template, RevisionDate appears at the bottom of each page.
If you do not intend to supply this value edit the default template
to remove the rest of the revision date phrase.

.PARAMETER OutputWidth
[DEPRECATED--This was needed for PowerShell V2]
You can separate the width of the output from the width of the invoking window
by setting this parameter to an integer of 80 or larger. The value determines where
lines wrap. Use a value of 80 to emulate a standard console width.
But for a web page, 100 or 120 is not unreasonable.
Default is the current window width.

.INPUTS
None. You cannot pipe objects to Convert-HelpToHtmlTree.

.OUTPUTS
None. Convert-HelpToHtmlTree does not generate any output.

.EXAMPLE
PS> Convert-HelpToHtmlTree -Namespaces "MyPsEnhancements" -TargetDir "API"
Generates documentation for the modules under ...\My Documents\WindowsPowerShell\Modules\MyPsEnhancements to the relative path "API" using the default template, omitting replacement values for DocTitle, Copyright, or RevisionDate.

.EXAMPLE
PS> Convert-HelpToHtmlTree -Namespaces "Html","Files" -TemplateName "C:\myfiles\psdoc_template.html" -TargetDir "c:\temp\psdoc_tmp" -DocTitle 'PowerShell Libraries v1.5.1 API' -Copyright '2011' -RevisionDate '2011.12.13'
This uses ...\My Documents\WindowsPowerShell\Modules\Html and ...\My Documents\WindowsPowerShell\Modules\Files as source namespaces and generates output into c:\temp\psdoc_tmp.  The pages use the specified template rather than the default template.  Values are given for the document title/home page header, the copyright date and the revision date.

.EXAMPLE
PS> Convert-HelpToHtmlTree * API
Scans all namespace-aware directories under ...\WindowsPowerShell\Modules and generates documentation for them in a local subdirectory called API.

.LINK
about_Comment_Based_Help
.LINK
[About Help Topics] (http://technet.microsoft.com/en-us/library/dd347616.aspx)
.LINK
[Cmdlet Help Topics] (http://technet.microsoft.com/en-us/library/dd347701.aspx)

.NOTES
This function is part of the CleanCode toolbox
from http://cleancode.sourceforge.net/.

Since CleanCode 1.1.01.

#>

function Convert-HelpToHtmlTree
{
	[CmdletBinding(SupportsShouldProcess=$true)]

	Param(
		[parameter(Mandatory=$true)][String[]]$Namespaces,
		[string]$TargetDir    = ".",
		[string]$TemplateName = "",
		[string]$DocTitle     = "",
		[string]$Copyright    = "",
		[string]$RevisionDate = "",
		[int]$OutputWidth     = $host.UI.RawUI.BufferSize.Width
	)

	Init-Variables

	Write-Host "Target dir: $TargetDir"
	$namespaceSummary = @{}
	$Namespaces |
	# Convert wildcards (if any) in Namespaces parameter to instances
	% {
		Get-ChildItem (Get-UserPsModulePath) $_	} |
	% {
		$namespace = $_.Name # Grab name out of DirectoryInfo object
		Write-Host "Namespace: $namespace"
		$script:namespaceCount++;
		$script:moduleSummary = @{}
		if ($DocTitle) { $title = "{0} {1}" -f $namespace, $DocTitle }
		else { $title = "$namespace Namespace"}
		$namespaceDir = Join-Path (Get-UserPsModulePath) $namespace
		$saveModuleCount = $moduleCount
		Get-ChildItem $namespaceDir |
			? { $_.PsIsContainer } |
			% { Process-Module $namespace $_.Name $title}
		if ($saveModuleCount -eq $moduleCount) { 
			[void](Handle-MissingValue "No modules found");
			$noModulesFlagged = $true
		}
		$namespaceSummary[$namespace] = $moduleSummary
		Add-ItemToContentsList $namespace "namespace" -itemUrl "index.html"
	}

	# Do this last; uses data collected from above.
	$title = ""
	if ($DocTitle) { $title = $DocTitle }
	else { $title = "PowerShell API" }
	if ($Namespaces.Count -eq 1) { $title = "{0} {1}" -f $Namespaces[0],$title }
	Generate-HomePage $title
	Generate-ContentsPage $title
	if ($noModulesFlagged) {
		write-warning "Note that 'No modules found' typically indicates your"
		write-warning "module directories are not within a namespace directory." }
	"Done: {0} namespace(s), {1} module(s), {2} function(s), {3} file(s) processed." `
		-f $namespaceCount,$moduleCount, $functionCount, $fileCount
}

########################### Support #############################

function Init-Variables()
{
	# This allows output generation to be independent of the width
	# of the invoking window. Height is irrelevant in this call.
	# Hmmm... this call fails if wrapped in an if-statement !!
	$host.UI.RawUI.BufferSize = `
		new-object System.Management.Automation.Host.Size($OutputWidth,50);

	$script:fileCount        = 0
	$script:functionCount    = 0
	$script:moduleCount      = 0
	$script:namespaceCount   = 0
	$script:noModulesFlagged = $false
	$script:itemList         = @()

	$script:PAGE_HOME        = "home"
	$script:PAGE_CONTENTS    = "contents"
	$script:PAGE_MODULE      = "module"
	$script:PAGE_FUNCTION    = "function"
	$script:PAGE_LIST = $PAGE_HOME, $PAGE_CONTENTS, $PAGE_MODULE, $PAGE_FUNCTION

    $script:CSS_ERR_MSG        = "errMsg"
    $script:CSS_PS_CMD         = "pscmd"
    $script:CSS_PS_DOC_SECTION = "PowerShellDoc"

	$script:CMDLET_TYPES       ='Function','Filter','Cmdlet'

	$script:namespace_overview_filename = "namespace_overview.html"
	$script:module_overview_filename    = "module_overview.html"

	# Get the name of *this* module because it requires special handling.
	if ($script:MyInvocation.MyCommand.Path -match "Modules\\(.*)\\\w*.psm1")
	{ $script:thisModule = $Matches[1] }
	else { $script:thisModule = "" }

	$script:msdnIndex = Get-CmdletDocLinks
	
	if (! ($script:template = Get-Template $TemplateName)) { exit }
	Init-ModuleProperties
}

function Init-ModuleProperties()
{
	$allModuleProperties =
		Get-Module |
		Get-Member |
		? { $_.MemberType -eq "Property" } |
		% { $_.Name }
	# Hmmm... should work without Out-String but causes $matches to be empty!
	$tstring = $template | Out-String
	$script:modulePropertiesInTemplate = @()
	$allModuleProperties | % {
		$property = $_
		if ($tstring -match "\{module.($property)\}") {
			$script:modulePropertiesInTemplate += $matches[1] } 
	}
	if ($script:modulePropertiesInTemplate.count -eq 0) {
		$script:modulePropertiesInTemplate = $null
	}
#	This essentially serves as a boolean indicating presence of any.
#	$script:modulePropertiesInTemplate = 
#		$template | Select-String ( $moduleProperties | % { "{module.$_}"} )
}

function Add-ItemToContentsList(
	$itemName = "",
	$itemType = "",
	$itemUrl = "",
	$parentName = "",
	$parentUrl = "")
{
	# NB: URLs should be relative to the home page.

	$item = new-object object
	# Enumerate list so all properties are defined whether or not passed in.
	"itemName","itemType","itemUrl","parentName","parentUrl" |
	% { 
		Add-Member -inputobject $item NoteProperty $_ $PSBoundParameters[$_]
	}
	$script:itemList += $item
}

function Process-Module($namespace, $moduleName, $parentTitle)
{
	Write-Host "    Module: $moduleName"
	$script:moduleCount++;
	$qualifiedModName = (join-Path $namespace $moduleName)
	if (! (Get-Module $moduleName -ListAvailable))
	{ [void](Handle-MissingValue "No objects found") }
	elseif (! (Import-MostModules $qualifiedModName))
	{ [void](Handle-MissingValue "Cannot load $qualifiedModName module") }
	else {
		if (!$parentTitle) { $parentTitle = "{0} Namespace" -f $namespace }
		$moduleDocPath = Join-Path $TargetDir (Join-Path $namespace $moduleName)
		if (! (Test-Path $moduleDocPath)) { 
			if ($PSCmdlet.ShouldProcess($moduleDocPath, "mkdir")) {
				mkdir $moduleDocPath | Out-Null } 
		}

		$moduleDetails = @{}
		if ($modulePropertiesInTemplate) {
			$modulePropertiesInTemplate | % {
				$newval = invoke-expression "(Get-Module $moduleName).$_"
				$moduleDetails[$_] = $newval
			}
		}

		$help = @{}
		Generate-FunctionPages $qualifiedModName $moduleName $moduleDocPath $parentTitle $help
		Generate-ModulePage $qualifiedModName $moduleName $moduleDocPath $parentTitle $help
		Remove-MostModules $qualifiedModName $moduleName
	}
}

function Generate-FunctionPages($qualifiedModName, $moduleName, $moduleDocPath, $parentTitle, $helpHash)
{
	Get-Command -Module $moduleName |
	? { $_.CommandType -in $CMDLET_TYPES } |
	Filter-ThisModule $qualifiedModName $moduleName |
	% { 
		$function = $_.Name
		Write-Host ("        {0}: {1}" -f $_.CommandType, $function)
		$script:functionCount++;
		$helpHash[$function] = Microsoft.PowerShell.Core\Get-Help $_ -Full -ErrorAction SilentlyContinue
		# convert to string array;
        # must specify a wide width otherwise lines break at 80 characters!
		$helpText = @($helpHash[$function] | Out-String -Stream -Width 16384)
		# If no doc-comments are attached to function, Get-Help returns a single line
		# enumerating syntax.
		if ($helpText.Count -eq 1) {
			Handle-MissingValue "Cannot find Help for $function" | Out-Null
			# Shows a blank entry for this function on the module summary page.
			$helpHash[$function].Synopsis = ""
		}
		($helpSections, $helpSectionOrder) = Get-Sections($helpText)
		$body = ConvertTo-Body $helpSections $helpSectionOrder $helpHash[$function] $moduleName
		
		$targetFile = join-path $moduleDocPath ($function+".html")
		$breadcrumbs = Get-HtmlBreadCrumbs `
			(Get-HtmlLink (Join-HtmlPath "..", "..", "index.html") $namespace),
			(Get-HtmlLink "index.html" $moduleName),
			$function
		Fill-Template $template $targetFile $PAGE_FUNCTION `
			-title $function `
			-subtitle ($parentTitle + ":") `
			-breadcrumbs $breadcrumbs `
			-body $body `
			-copyright $copyright `
			-revDate $RevisionDate `
			-moduleDetails $moduleDetails
		Add-ItemToContentsList $function $_.CommandType `
			-itemUrl (Join-HtmlPath $namespace, $moduleName, ($function+".html")) `
			-parentUrl (Join-HtmlPath $namespace, $moduleName, "index.html") `
			-parentName $moduleName
	}
}

function Generate-ModulePage($qualifiedModName, $moduleName, $moduleDocPath, $parentTitle, $helpHash)
{
	$indexTableRows = 
	Get-Command -Module $moduleName | 
	Filter-ThisModule $qualifiedModName $moduleName |
	sort -Property Name |
	% {
		if ($_.CommandType -in $CMDLET_TYPES) {
			Get-HtmlRow (Get-HtmlLink ($_.Name+".html") $_.Name), ($helpHash[$_.Name].Synopsis)
		}
		elseif ($_.CommandType -eq "Alias") {
			Get-HtmlRow $_.Name, ("Alias to " + $_.Definition)
		}
		else {
			Get-HtmlRow $_.Name, $_.CommandType
		}
	}

	$targetFile = join-path $moduleDocPath "index.html"
	$breadcrumbs = Get-HtmlBreadCrumbs `
		(Get-HtmlLink (Join-HtmlPath "..", "..", "index.html") $namespace),
		$moduleName
	Fill-Template $template $targetFile $PAGE_MODULE `
		-title $moduleName  `
		-subtitle ($parentTitle + ":") `
		-breadcrumbs $breadcrumbs `
		-body (Get-HtmlTable $indexTableRows) `
		-preamble (Get-ModulePreamble $namespaceDir $moduleName) `
		-copyright $copyright `
		-revDate $RevisionDate `
		-moduleDetails $moduleDetails
	Add-ItemToContentsList $moduleName "module" `
		-itemUrl (Join-HtmlPath $namespace, $moduleName, "index.html") `
		-parentName $namespace `
		-parentUrl "index.html"
}

function Generate-HomePage($title)
{
	Write-Host "Generating home page..."
	$body = $namespaceSummary.Keys | Sort  | % {
		$namespace = $_
		$headLevel = 2
		Get-HtmlHead "$namespace Namespace" $headLevel
		Get-NamespacePreamble (join-path (Get-UserPsModulePath) $namespace)
		$moduleItems = $namespaceSummary[$namespace]
		Get-HtmlTable (
			$moduleItems.Keys | Sort |
			%{
				Get-HtmlRow (Get-HtmlLink (Join-HtmlPath $namespace, $_, "index.html") $_),
					$moduleItems[$_] 
			}
		)
	}
	$targetFile = join-path $TargetDir "index.html"
	Fill-Template $template $targetFile $PAGE_HOME `
		-title $title `
		-body $body `
		-copyright $Copyright `
		-revDate $RevisionDate
}

function Generate-ContentsPage($title)
{
	Write-Host "Generating contents page..."
	$body = $itemList |
		Group -Property { $_.itemName.Substring(0,1).ToUpper() } |
		Sort -Property Name |
		% { 
			$headLevel = 2
			Get-HtmlHead $_.Name $headLevel
			$_.Group | Sort -Property itemName  | % {
				if ($_.itemUrl) { $item = Get-HtmlLink $_.itemUrl $_.itemName }
				else { $item = $_.itemName }
				if ($_.parentUrl) { $parent = Get-HtmlLink $_.parentUrl $_.parentName }
				else { $parent = $_.parentName }
				if ($_.itemType -eq "namespace") {
					"{0} - {1}`n{2}`n" -f $item, $_.itemType, (Get-HtmlLineBreak) }
				else {
					"{0} - {1} in {2}`n{3}`n" -f $item, $_.itemType, $parent, (Get-HtmlLineBreak)
				}
			}
		}
	$targetFile = join-path $TargetDir "contents.html"
	Fill-Template $template $targetFile $PAGE_CONTENTS `
		-title $title `
		-body $body `
		-copyright $Copyright `
		-revDate $RevisionDate
}

function Fill-Template(
	[string[]]$template, [string]$targetFile, [string]$fileType, [hashtable]$moduleDetails, 
	$title, $subtitle, $breadcrumbs, $body, $preamble, $postscript, $copyright, $revDate)
{
	if ($PSCmdlet.ShouldProcess($targetFile, "create")) {

		# convert array to string--necessary for (?s) flag in step 1 below.
		$newContent = $template | Out-String
		# First, filter based on page type.
		$PAGE_LIST |
		% { 
			# regex courtesy of Perl Cookbook, section 6.16, allows for
			# multiple occurrences of {ifdef}...{endif} pairs for the
			# same filetype (but does not handle nested occurrences!).
			if ($_ -eq $fileType) { $replacement = '$1' }
			else { $replacement = "" }
			$newContent = $newContent `
				-replace "(?s){ifdef $_}((?:(?!{ifdef $_}).)*){endif $_}", $replacement
		}

		# Second, replace general content
		# Hmmm... The PowerShell native -replace operator fails if the second arg
		# contains "$_" -- some env info substitutes for that
		# as a second-level replace operation; hence, using .Net Replace here.
		$newContent = $newContent.Replace("{title}", $title)
		$newContent = $newContent.Replace("{subtitle}", $subtitle)
		$newContent = $newContent.Replace("{breadcrumbs}", $breadcrumbs)
		$newContent = $newContent.Replace("{body}", $body)
		$newContent = $newContent.Replace("{preamble}", $preamble)
		$newContent = $newContent.Replace("{postscript}", $postscript)
		$newContent = $newContent.Replace("{copyright}", $copyright)
		$newContent = $newContent.Replace("{revdate}", $revDate)

		# Third, replace module details
		if ($moduleDetails) {
			$moduleDetails.GetEnumerator() |
			% { $newContent = $newContent -replace "{module.$($_.Name)}", $_.Value }
		}

		$newContent | Set-Content $targetFile
	}
	$script:fileCount += 1
}

function Get-NamespacePreamble($path)
{
	"`n" + (Get-Overview $path $namespace_overview_filename) + "`n"
}

function Get-ModulePreamble($path, $moduleName)
{
	$details = Get-Overview (Join-Path $path $moduleName) $module_overview_filename

	$summary = (Get-Module $moduleName).description
	if (!$summary) {
		$displayName = Get-RelevantPath `
			(Join-Path (Join-Path $path $moduleName) "$moduleName.psd1")
		$summary = Handle-MissingValue "Missing description (from $displayName)" }
	$script:moduleSummary[$moduleName] = $summary
	$summary = Get-HtmlPara $summary
	"`n" + $summary + "`n`n" + $details + "`n"
}

function Get-Overview($path, $filename)
{
	$overviewPath = Join-Path $path $filename
	$details = $null
	if (Test-Path $overviewPath) {
		try {
			$data = [xml](get-content $overviewPath)
			$details = $data.html.body.InnerXml
		}
		catch [Exception] {
			[void](Handle-MissingValue $_.Exception.Message)
		}
	}
	if (!$details) {
		$displayName = Get-RelevantPath $overviewPath
		$details = Get-HtmlPara `
			(Handle-MissingValue "Missing summary (from $displayName)") }
	$details
}

# Trim off the module directory prefix.
function Get-RelevantPath($path)
{
	$path.substring((Get-UserPsModulePath).Length+1)
}

function Handle-MissingValue($message)
{
	Write-Host -ForegroundColor Red ("** " + $message)
	Get-HtmlSpan $message -Class $CSS_ERR_MSG
}

# Get just the user path out of the env var containing both the user path
# and the system path, by searching for the user name component of a path,
# optionally followed by a dollar sign (indicating home folder share).
function Get-UserPsModulePath()
{
	$env:PSModulePath.split(";") | ? { $_ -match "\\$($env:USERNAME)\`$?\\" }
}

function Get-Template([string]$templateName)
{
	if (!$templateName -or ! (Test-Path $templateName)) {
		# None supplied; get template in the same location as this script
		$scriptDir = Split-Path $script:MyInvocation.MyCommand.Path
		$templateName = Join-Path $scriptDir "psdoc_template.html"
	}
	get-content $templateName
}

# Convert Import-Module into a functional object
function Import-MostModules($qModuleName)
{
	# Skip reloading this module--causes all functions to be lost!
	if ($qModuleName -eq $thisModule) { return $true }

	Import-Module $qModuleName -force
	return ! (!$?)
}

function Remove-MostModules($qModuleName, $moduleName)
{
	if ($qModuleName -ne $thisModule) {
		# Hmmm... With -WhatIf, Remove-Module complains about no modules removed
		# when in fact it does properly remove the module!
		# This suppresses the false-error from displaying.
		if ($WhatIfPreference) { 
			Remove-Module $moduleName -ErrorAction SilentlyContinue }
		else { Remove-Module $moduleName }
	}
}

filter Filter-ThisModule($qModuleName, $moduleName)
{
    # Since we are executing in THIS module, its private functions are visible
    # by (Get-Command -Module...) so must be filtered down to the list of
    # actually exported functions.
    # (Calling code needs to use Get-Command because it needs to examine
    # types as well.)
	if ($qModuleName -eq $thisModule)
	{
		$realList = (Get-Module $moduleName).ExportedCommands.Keys
		if ( $realList -contains $_.Name ) { $_  }
	}
	else { $_ }
}

function Get-Sections($text)
{
	$sectionHash = @{} # collection sections keyed by section name
	$sectionOrder = @() # remember insertion order
	$rowNum = 0
	$lowBound = 0
	$sectionName = ""
	# Handle corner case of no help defined for a given function,
	# where help returned just 1 row containing the syntax without an indent.
	if ($helpText.Count -eq 1) { $sectionName = "Syntax"; $rowNum = 1 }
	else {
	$text | % {
		# The normal help text has section headers (NAME, SYNOPSIS, SYNTAX, DESCRIPTION, etc.)
		# at the start of a line and everything else indented.
		# Thus, this signals a new section:
		if ($_ -match "^[A-Z]") {
			Add-HelpSection $sectionName $text ([ref]$sectionHash) ([ref]$sectionOrder)# output prior section
			$sectionName = $_
			$lowBound = $rowNum + 1
		}
		# My deviation from "standard"--add separate section for examples
		elseif ($_ -match "----\s+EXAMPLE 1\s+----") {
			Add-HelpSection $sectionName $text ([ref]$sectionHash) ([ref]$sectionOrder)# output prior section
			$sectionName = "EXAMPLES"
			$lowBound = $rowNum
		}
		$rowNum++
	}
	}
	Add-HelpSection $sectionName $text ([ref]$sectionHash) ([ref]$sectionOrder)# output final section
	$sectionHash, $sectionOrder
}

function Add-HelpSection($sectionName, $text, [ref]$hash, [ref]$order)
{
	if ($sectionName) { # output previously collected section
		$hash.value[$sectionName] = $text[$lowBound..($rowNum-1)]
		$order.value += $sectionName
	}
}

function ConvertTo-Body($sectionHash, $sectionOrder, $helpItem, $moduleName)
{
	$sectionOrder | % {
		$sectionName = $_
		
		# emit header
		$section = Get-HtmlHead $sectionName 2
		
		# emit body
		if ($sectionName -eq "RELATED LINKS")
		{
            if ((-join $sectionHash[$sectionName]).Length -gt 0) {
			    $section += Get-HtmlList (Add-Links $moduleName $sectionHash[$sectionName]) }
            else {
                $section += Get-HtmlPara "-none-" }
		}
		elseif ($sectionName -eq "EXAMPLES")
        {
            $section += Get-HtmlPara (HtmlEncode $sectionHash[$sectionName])
            $break = Get-HtmlLineBreak
            # add CSS class name
            $section = $section -replace "(EXAMPLE\s+\d+\s+------*$break)\s*$break\s*(.*?)($break)", "`$1$(Get-HtmlSpan `$2 -Class $CSS_PS_CMD)`$3"
        }
		else { $section += Get-HtmlPara (HtmlEncode $sectionHash[$sectionName]) }
		Get-HtmlDiv $section -Class $CSS_PS_DOC_SECTION
	}
}

function HtmlEncode($text)
{
	# The full [System.Web.HttpUtility]::HtmlEncode() method would do too much,
	# eradicating newlines in particular. This is sufficient here.
	$text -replace "<", "&lt;" -replace ">", "&gt;" 
}

function Add-Links($currentModuleName, $text)
{
	$text -split "`n" | % {
		$item = $_ # default to "as is" entry
		if ($_ -match "^\s*([\w\-]+)\s*$") { # cmdlet format: "verb-noun"
            $thisCmdName = $Matches[1]
			if ($msdnIndex[$thisCmdName]) {
				$item = Get-HtmlLink $msdnIndex[$thisCmdName] $thisCmdName # generate link to MSDN
			}
			else {
                $cmd = Get-Command $thisCmdName -ErrorAction SilentlyContinue
                $thisModName = ""
                $thisNamespace = ""
                if ($cmd) {
                    $thisModName = $cmd.ModuleName
                    $thisNamespace = ($cmd.Module.Path -split '\\')[-3]
                }
                if ($thisModName -eq $currentModuleName) { $path = $thisCmdName }
                elseif ($thisModName) { $path = "..","..",$thisNamespace,$thisModName,$thisCmdName -join "/" }
                if ($thisModName) { # generate link to local directory
				    $item = Get-HtmlLink ("{0}.html" -f $path) $thisCmdName }
			}
		}
		elseif ($_ -match "^\s*(about_[\w_]+)\s*$") { # topic format: "about_topic"
			if ($msdnIndex[$Matches[1]]) {
				$item = Get-HtmlLink $msdnIndex[$Matches[1]] $Matches[1] # generate link to MSDN
			}
		}
		elseif ($_ -match "^\s*\[([^]]+)\]\s*\(([^)]+)\)\s*$") { # text link format: "[label] (URL)"
			$item = Get-HtmlLink $Matches[2] $Matches[1] # generate link from URL and label provided
		}
		elseif ($_ -match "^\s*(https?:\S+)\s*$") { # URL format: "http:..." or "https:..."
			$item = Get-HtmlLink $Matches[1] $Matches[1] # generate link from URL provided
		}
		if ($item) { Get-HtmlListItem $item } # emit only if non-empty
	}
}

function Get-CmdletDocLinks($referenceWebPage, $topicRegex)
{
	# Adapted from http://powershell.com/cs/blogs/tips/archive/2010/10/06/scraping-information-from-web-pages.aspx
	$cmdletReferenceWebPage = "http://technet.microsoft.com/en-us/library/dd347701.aspx"
	$aboutReferenceWebPage  = "http://technet.microsoft.com/en-us/library/dd347616.aspx"
	$cmdletRegex            = [RegEx]'<p>\s*<a\s+href="(http.*?)">(\w+-\w+)</a>'
	$aboutRegex             = [RegEx]'<p>\s*<a\s+href="(http.*?)">(about_\w+)</a>'

	$topicIndex = @{}
	$progressPreference = 'silentlyContinue'
	$content = (Invoke-WebRequest $cmdletReferenceWebPage).Content
	$cmdletRegex.Matches($content) | % { $topicIndex[$_.Groups[2].Value] = $_.Groups[1].Value }
	$content = (Invoke-WebRequest $aboutReferenceWebPage).Content
	$aboutRegex.Matches($content) | % { $topicIndex[$_.Groups[2].Value] = $_.Groups[1].Value }
	$progressPreference = 'Continue'
	return $topicIndex
}


########################### HTML Support #############################

function Join-HtmlPath([String[]]$path)
{
	$path -join "/"
}

function Get-HtmlLink($href, $value)
{
	"<a href='{0}'>{1}</a>" -f $href, $value
}

function Get-HtmlCell([String]$text, [int]$columnCount)
{
	if ($columnCount) {"     <td colspan='{0}' bgcolor='#CCCCCC'>{1}</td>" -f $columnCount, $text }
	else { "    <td>{0}</td>" -f $text} }

function Get-HtmlRow([String[]]$items, [int]$columnCount)
{
	$cells = $items | % { Get-HtmlCell $_ $columnCount } | Out-String
	"  <tr>`n{0}  </tr>`n" -f $cells
}

function Get-HtmlTable([String[]]$items)
{
	"`n<table border='1'>`n{0}</table>`n" -f ($items | Out-String)
}

function Get-HtmlDiv($text, $class)
{
	if ($class) { $class = (" class='{0}'" -f $class) }
	"<div{1}>`n{0}</div>`n" -f [string]::join("`n", $text), $class
}

function Get-HtmlSpan($text, $class)
{
	if ($class) { $class = (" class='{0}'" -f $class) }
	"<span{1}>{0}</span>" -f [string]::join("`n", $text), $class
}

function Get-HtmlPara($text, $class)
{
	if ($class) { $class = (" class='{0}'" -f $class) }
	"<p{1}>{0}</p>`n" -f [string]::join("`n", (CheckForIndent $text)), $class
}

function CheckForIndent ($text)
{
    $blanks = 0;
    $text | % {
        if ($_ -match '^\s*$') { if ($blanks++ -eq 0) { "$_<br/>" } else { $_ } }
        else {
            $blanks = 0
            if ($_ -match '^\s{4}\s+') { Get-HtmlPre $_ } else { "$_<br/>" }
        }
    }
}

function Get-HtmlPre($text)
{
	# allow for possible array with join
	"<pre>{0}</pre>" -f [string]::join("`n", $text)
}

function Get-HtmlHead($text, $level)
{
	"<h{0}>{1}</h{0}>`n" -f $level, $text
}

function Get-HtmlLineBreak()
{
	"<br/>"
}

function Get-HtmlBreadCrumbs([String[]] $items)
{
	$items -join " &raquo; "
}

function Get-HtmlListItem($text)
{
	"<li>{0}</li>" -f $text
}

function Get-HtmlList($list)
{
	if ($list) {
	"<ul>`n{0}`n</ul>" -f [string]::join("`n", $list) }
}

Export-ModuleMember Convert-HelpToHtmlTree
