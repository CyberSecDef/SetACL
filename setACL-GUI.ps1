[CmdletBinding()]
param(
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][string] $computerName = $null
)
Begin{
	clear;
	Add-Type -AssemblyName System.Windows.Forms | out-null
	Add-Type -AssemblyName System.Drawing | out-null
   
    $code = @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;

namespace System
{
	public class IconExtractor
	{

	 public static Icon Extract(string file, int number, bool largeIcon)
	 {
	  IntPtr large;
	  IntPtr small;
	  ExtractIconEx(file, number, out large, out small, 1);
	  try
	  {
	   return Icon.FromHandle(largeIcon ? large : small);
	  }
	  catch
	  {
	   return null;
	  }

	 }
	 [DllImport("Shell32.dll", EntryPoint = "ExtractIconExW", CharSet = CharSet.Unicode, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
	 private static extern int ExtractIconEx(string sFile, int iIndex, out IntPtr piLargeVersion, out IntPtr piSmallVersion, int amountIcons);

	}
}
"@

Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing
    $global:imageList = $null;
    $global:imageList = new-Object System.Windows.Forms.ImageList 
    $System_Drawing_Size = New-Object System.Drawing.Size 
    $System_Drawing_Size.Width = 16
    $System_Drawing_Size.Height = 16 
    $global:imageList.ImageSize = $System_Drawing_Size 


    $script:icons = @();
    for($i = 0; $i -lt 100; $i++){
        $icon = [System.IconExtractor]::Extract("shell32.dll", $i, $true);
        if($icon -ne $null -and $icon -is [System.Drawing.Icon]){
            $script:icons += ( [System.IconExtractor]::Extract("shell32.dll", $i, $true) )
            
            $global:imageList.Images.Add( [System.Drawing.Icon]( [System.IconExtractor]::Extract("shell32.dll", $i, $true) ) ) 
        }
    }
	[Windows.Forms.Application]::EnableVisualStyles()
    
    
	class FormHelper{
		static [object] getFormControl(
			$Control = "Form",
			[HashTable]$Member = @{}
		){
			If($Control -isnot "Windows.Forms.Control"){
				Try {
					$Control = New-Object Windows.Forms.$Control
				} Catch {
					$PSCmdlet.WriteError($_)
				}
			}
			$Styles = @{RowStyles = "RowStyle"; ColumnStyles = "ColumnStyle"}
			ForEach ($Key in $Member.Keys) {
				If ($Style = $Styles.$Key) {
					[Void]$Control.$Key.Clear()
					For ($i = 0; $i -lt $Member.$Key.Length; $i++) {
						[Void]$Control.$Key.Add((New-Object Windows.Forms.$Style($Member.$Key[$i])))
					}
				} Else {
					Switch (($Control | Get-Member $Key).MemberType) {
						"Property"	{$Control.$Key = $Member.$Key}
						"Method"  	{Invoke-Expression "[Void](`$Control.$Key($($Member.$Key)))"}
						"Event"   	{Invoke-Expression "`$Control.Add_$Key(`$Member.`$Key)"}
						Default   	{Write-Error("The $($Control.GetType().Name) control doesn't have a '$Key' member.")}
					}
				}
			}
			return $Control	
		}
        
        
	}

	Class SetACL{
		$form = $null;
        
        
		[void] mnuFileOpen(){
			write-host 'test'
		}
	
        [void] expandFileSystem( $node ){
            $path = "$($node.tag.split('|')[1])\";
            write-host $path
            gci -path $path | ft |out-string | write-host
            
            if($node.isExpanded -eq $false -or $node.nodes.count -eq 0){
                if($node.level -eq 2){
                    
                    $node.imageIndex=7;
                    $node.selectedimageIndex=$node.imageIndex;
                    gci -path $path | ? {$_.PSIsContainer -eq $true } | sort Name | % {
                        $node.Nodes.Add($_,$_)
                        $node.Nodes[$_].tag = "FileSystem|$($_.fullname)"
                        $node.Nodes[$_].ImageIndex = 3
                        $node.Nodes[$_].SelectedImageIndex = $node.Nodes[$_].ImageIndex
                        
                    }
                }else{
                    $node.imageIndex=3;
                    $node.selectedimageIndex=$node.imageIndex;
                    $node | fl | out-string | write-host
                }
            
            }
            
        }
        
        [void] nodeClicked( $tree ){
            clear
            # $tree | fl | out-string | write-host
            if($tree.selectedNode.tag -ne $null){
                switch( $tree.selectedNode.tag.split('|')[0] ){
                    "FileSystem" {
                        $this.expandFileSystem( $tree.selectedNode );
                        break;
                    }
                } 
            }
            
        }
        
		[void] generateForm(){
			$script:self = $this
			$this.form = [FormHelper]::getFormControl('Form', @{ Width = "800"; Height = "400"; Text = "SetACL PowerShell Studio"; StartPosition = "CenterScreen"; FormBorderStyle = "Sizable"; Topmost = $false; MinimizeBox = $true; MaximizeBox = $true;} )

			$this.form.Controls.Add(( [FormHelper]::getFormControl('ToolStrip', @{ Name = 'mainToolStrip'; Dock = 'Top';} )) ) | out-null
			$this.form.Controls.Add(( [FormHelper]::getFormControl('MenuStrip', @{ Name = 'menuMain'; Dock = 'Top';} )) )| out-null
			$this.form.controls['menuMain'].Items.Add( ( [FormHelper]::getFormControl('ToolStripMenuItem', @{ Name = 'menuFile'; Text = "File";} ) ) ) | out-null
			$this.form.controls['menuMain'].Items['menuFile'].DropDownItems.Add( ( [FormHelper]::getFormControl('ToolStripMenuItem', @{ Name = 'menuOpen'; ShortcutKeys = "Control, O"; Text = "Open"} ) ) ) | out-null
			$this.form.controls['menuMain'].Items['menuFile'].DropDownItems['menuOpen'].Add_Click({$script:self.mnuFileOpen()})

            $this.form.controls.add( ( [FormHelper]::getFormControl( 'statusbar', @{ Name = 'status';}) ) );
            
			$this.form.Controls.Add( ( [FormHelper]::getFormControl( 'SplitContainer', @{ Name = 'mainContent'; Dock = 'Fill'; SplitterWidth = 2; Orientation = 'Horizontal'; SplitterDistance = '200'; Panel1MinSize = '200'; backcolor = '#cccccc';} ) ) ) | out-null

			$this.form.controls['mainContent'].panel1.backcolor = 'white';
			$this.form.controls['mainContent'].panel2.backcolor = 'white';

			$this.form.Controls['mainContent'].panel1.controls.add( ( 
				[FormHelper]::getFormControl( 'SplitContainer', @{Name = 'mainBody'; Dock = 'Fill'; SplitterWidth = 2; Panel1MinSize = 100; Panel2MinSize = 100;  backcolor = '#cccccc'} ) 
			) ) | out-null

			$this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.backcolor = 'white';
			$this.form.Controls['mainContent'].panel1.controls['mainBody'].panel2.backcolor = 'white';

            
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls.add( (
                [FormHelper]::getFormControl('treeview', @{ Name = "treeNodes"; Dock = "Fill"; 'ImageList' = $global:imageList;} )
            ) ) | out-null

            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].add_click( {$script:self.nodeClicked( $this ) } )
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].add_AfterSelect( {$script:self.nodeClicked( $this ) } )
            
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes.Add("root",(hostname), 15);
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].imageIndex = 15;
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].selectedimageIndex = 15;
            

            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes.Add('FileSystem','FileSystem', 7)
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['FileSystem'].imageIndex = 7
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['FileSystem'].selectedimageIndex = 7
            
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes.Add('Printers','Printers', 16)
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['Printers'].imageIndex = 16
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['Printers'].selectedimageIndex = 16
            
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes.Add('Registry', 'Registry', 48)
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['Registry'].imageIndex = 48
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['Registry'].selectedimageIndex = 48
            
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes.Add('Services', 'Services', 28)
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['Services'].imageIndex = 28
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['Services'].selectedimageIndex = 28
            
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes.Add('Shares','Shares', 9)
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['Shares'].imageIndex = 9
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['Shares'].selectedimageIndex = 9
            
            get-psdrive | ? {$_.Provider.Name -eq 'FileSystem' } | Sort Name | % {
                $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['FileSystem'].Nodes.add( "$($_.name):", "$($_.name):", 28 )
                $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['FileSystem'].Nodes[ "$($_.name):" ].Tag = "FileSystem|$($_.name):"                
                $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['FileSystem'].Nodes[ "$($_.name):" ].imageIndex=7;
                $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['FileSystem'].Nodes[ "$($_.name):" ].selectedimageIndex=$node.imageIndex;
            }
            
            get-printer | Sort Name | % { 
                $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['Printers'].Nodes.add( "$($_.name)" )            
            }
           
            get-psdrive | ? {$_.Provider.Name -eq 'Registry' } | Sort Name | % { 
                $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['Registry'].Nodes.add( "$($_.name):" )            
            }
            
            get-service | Sort Name | % { 
                $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['Services'].Nodes.add( "$($_.name)" )            
            }
            
            get-SmbShare | Sort Name | % { 
                $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['Shares'].Nodes.add( "$($_.name)" )            
            }
            
            $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].expand();
			$this.form.Controls['mainContent'].BringToFront()
            
		}
		
		SetACL(){
			$this.generateForm();
			
			$this.form.ShowDialog() | out-null
		}
	}
}
Process{
	$setAcl = [SetACL]::new();

}
End{

}