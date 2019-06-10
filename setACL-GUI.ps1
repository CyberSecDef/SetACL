[CmdletBinding()]
param(
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][string] $computerName = $null
)
Begin{
	clear;
	$error.clear();
	Add-Type -AssemblyName System.Windows.Forms | out-null
	Add-Type -AssemblyName System.Drawing | out-null	
    Add-Type -AssemblyName System.security | out-null

    Add-Type -assemblyName PresentationFramework | out-null
    Add-Type -assemblyName PresentationCore | out-null
    Add-Type -assemblyName WindowsBase | out-null
    add-type -assemblyName System.Data | out-null
    
	Class SetACL{
		$form = $null;
        $computerName = $null;

		[void] mnuFileOpen(){
			write-host 'test'
		}
        [string] getPermissions( $acl ){
            $accessMask = [ordered]@{
                [uint32]'0x80000000' = 'GenericRead'
                [uint32]'0x40000000' = 'GenericWrite'
                [uint32]'0x20000000' = 'GenericExecute'
                [uint32]'0x10000000' = 'GenericAll'
                [uint32]'0x02000000' = 'MaximumAllowed'
                [uint32]'0x01000000' = 'AccessSystemSecurity'
                [uint32]'0x00100000' = 'Synchronize'
                [uint32]'0x00080000' = 'WriteOwner'
                [uint32]'0x00040000' = 'WriteDAC'
                [uint32]'0x00020000' = 'ReadControl'
                [uint32]'0x00010000' = 'Delete'
                [uint32]'0x00000100' = 'WriteAttributes'
                [uint32]'0x00000080' = 'ReadAttributes'
                [uint32]'0x00000040' = 'DeleteChild'
                [uint32]'0x00000020' = 'Execute/Traverse'
                [uint32]'0x00000010' = 'WriteExtendedAttributes'
                [uint32]'0x00000008' = 'ReadExtendedAttributes'
                [uint32]'0x00000004' = 'AppendData/AddSubdirectory'
                [uint32]'0x00000002' = 'WriteData/AddFile'
                [uint32]'0x00000001' = 'ReadData/ListDirectory'
            }
            
            $simplePermissions = [ordered]@{
                [uint32]'0x1f01ff' = 'FullControl'
                [uint32]'0x0301bf' = 'Modify'
                [uint32]'0x0200a9' = 'ReadAndExecute'
                [uint32]'0x02019f' = 'ReadAndWrite'
                [uint32]'0x020089' = 'Read'
                [uint32]'0x000116' = 'Write'
            }
            
            $permissions = @()
            
            if( ($acl | select -first 1).fileSystemRights -ne $null){
                $fileSystemRights = $acl | Select-Object -Expand FileSystemRights -First 1
                $fsr = $fileSystemRights.value__
                
                $permissions += $simplePermissions.Keys | ForEach-Object {
                      if (($fsr -band $_) -eq $_) {
                        $simplePermissions[$_]
                        $fsr = $fsr -band (-bnot $_)
                      }
                    }
                $permissions += $accessMask.Keys |
                    Where-Object { $fsr -band $_ } |
                    ForEach-Object { $accessMask[$_] }
            }
            
            if( ($acl | select -first 1).RegistryRights -ne $null){
                $registryRights = $acl | Select-Object -Expand RegistryRights -First 1
                $rr = $RegistryRights.value__
                
                $permissions += $simplePermissions.Keys | ForEach-Object {
                      if (($rr -band $_) -eq $_) {
                        $simplePermissions[$_]
                        $rr = $rr -band (-bnot $_)
                      }
                    }
                $permissions += $accessMask.Keys |
                    Where-Object { $rr -band $_ } |
                    ForEach-Object { $accessMask[$_] }
            }
            
            
            return ($permissions -join ", ")
        }
        [string] getInheritanceFlags( $str ){
            $results = switch($str){
                "This Folder, Subfolders and Files" { ( [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit) }
                "This Folder and Subfolders"{[System.Security.AccessControl.InheritanceFlags]::ContainerInherit}
                "This Folder and Files"{[System.Security.AccessControl.InheritanceFlags]::ObjectInherit}
                "This Folder only" { [System.Security.AccessControl.InheritanceFlags]::None }
                "Subfolders and Files"{ ( [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit) }
                "Subfolders only"{[System.Security.AccessControl.InheritanceFlags]::ContainerInherit}
                "Files only"{[System.Security.AccessControl.InheritanceFlags]::ObjectInherit}
            }
            
            return $results
        }
        [string] getPropogationFlags( $str ){
            $results = switch($str){
                "This Folder, Subfolders and Files" { [System.Security.AccessControl.PropagationFlags]::None }
                "This Folder and Subfolders"{ [System.Security.AccessControl.PropagationFlags]::NoPropagateInherit }
                "This Folder and Files"{[System.Security.AccessControl.PropagationFlags]::None }
                "This Folder only" { [System.Security.AccessControl.PropagationFlags]::None }
                "Subfolders and Files"{ [System.Security.AccessControl.PropagationFlags]::InheritOnly }
                "Subfolders only"{[System.Security.AccessControl.PropagationFlags]::InheritOnly}
                "Files only"{[System.Security.AccessControl.PropagationFlags]::InheritOnly}
            }
            
            return $results
        }
        
        [string] getAppliesTo( $acl ){
            $appliesTo = '';
            switch( $acl.PropagationFlags ){
                ([System.Security.AccessControl.PropagationFlags]::None){
                    if($acl.InheritanceFlags -eq ( [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit)){
                        $appliesTo = 'This Folder, Subfolders and Files';
                    }
                    if($acl.InheritanceFlags -eq ( [System.Security.AccessControl.InheritanceFlags]::ObjectInherit)){
                        $appliesTo = 'This Folder and Files';
                    }
                    if($acl.InheritanceFlags -eq ( [System.Security.AccessControl.InheritanceFlags]::None)){
                        $appliesTo = 'This Folder only';
                    }
                    break;
                }
                ([System.Security.AccessControl.PropagationFlags]::InheritOnly){
                    if($acl.InheritanceFlags -eq ( [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit)){
                        $appliesTo = 'Subfolders and Files';
                    }
                    if($acl.InheritanceFlags -eq ( [System.Security.AccessControl.InheritanceFlags]::ContainerInherit)){
                        $appliesTo = 'Subfolders only';
                    }
                    if($acl.InheritanceFlags -eq ( [System.Security.AccessControl.InheritanceFlags]::ObjectInherit)){
                        $appliesTo = 'Files only';
                    }
                    break;
                }
                ([System.Security.AccessControl.PropagationFlags]::NoPropagateInherit){
                    if($acl.InheritanceFlags -eq ( [System.Security.AccessControl.InheritanceFlags]::ContainerInherit)){
                        $appliesTo = 'This folder and Subfolders';
                    }

                    break;
                }
            }
            return $appliesTo;
        }
        [void] logEvent($module, $msg){
            $this.form.Content.FindName('logfile').Text += "`r`n[$( get-date -Format 'MM/dd/yyyy hh:mm:ss' )] - $($module) - $($msg)";
            $this.form.Content.FindName('logfile').ScrollToEnd();

        }
        
        [void] updatePermissionsGrid( $node ){
            $class = "$($node.tag.split('|')[0])";
            $path = "$($node.tag.split('|')[1])";
            
            $this.form.Content.FindName('selectedObjectPermTable').ItemsSource = $null;
            $this.form.Content.FindName('selectedObjectPermTable').Items.clear()
            $this.form.Content.FindName('selectedObjectPermTable').Items.Refresh()
            
            switch($class){
                "FileSystem" {
                    if( (Get-Item $path) -is [System.IO.DirectoryInfo]){
                        get-acl -path "$($path)\" -errorAction SilentlyContinue| select -expand access | % {
                            $row= New-Object PSObject
                            Add-Member -inputObject $row -memberType NoteProperty -name "Type" -value $_.AccessControlType;
                            Add-Member -inputObject $row -memberType NoteProperty -name "Principal" -value $_.IdentityReference.ToString()
                            Add-Member -inputObject $row -memberType NoteProperty -name "Access" -value $this.getPermissions($_);
                            Add-Member -inputObject $row -memberType NoteProperty -name "Inherited" -value $_.IsInherited
                            Add-Member -inputObject $row -memberType NoteProperty -name "Applies To" -value $this.getAppliesTo($_);
                    
                            $this.form.Content.FindName('selectedObjectPermTable').AddChild($row)
                        }
                    }else{
                        get-acl -path "$($path)" -errorAction SilentlyContinue| select -expand access | % {
                            $row= New-Object PSObject
                            Add-Member -inputObject $row -memberType NoteProperty -name "Type" -value $_.AccessControlType;
                            Add-Member -inputObject $row -memberType NoteProperty -name "Principal" -value $_.IdentityReference.ToString()
                            Add-Member -inputObject $row -memberType NoteProperty -name "Access" -value $this.getPermissions($_);
                            Add-Member -inputObject $row -memberType NoteProperty -name "Inherited" -value $_.IsInherited
                            Add-Member -inputObject $row -memberType NoteProperty -name "Applies To" -value '';
                    
                            $this.form.Content.FindName('selectedObjectPermTable').AddChild($row)
                        }
                    }
                }
                "Share" {
                    Get-SmbShareAccess "$($path)" -errorAction SilentlyContinue | % {
                            $row= New-Object PSObject
                            Add-Member -inputObject $row -memberType NoteProperty -name "Type" -value $_.AccessControlType;
                            Add-Member -inputObject $row -memberType NoteProperty -name "Principal" -value $_.AccountName.ToString()
                            Add-Member -inputObject $row -memberType NoteProperty -name "Access" -value $_.AccessRight;
                            Add-Member -inputObject $row -memberType NoteProperty -name "Inherited" -value ''
                            Add-Member -inputObject $row -memberType NoteProperty -name "Applies To" -value ''
                    
                            $this.form.Content.FindName('selectedObjectPermTable').AddChild($row)
                        }
                }
                "Service" {
                    $srv = gwmi win32_service -computerName $this.computerName | ? { $_.name -eq $path } | select -first 1
                    $pathName = ($srv.pathname -replace "(.+exe).*", '$1' -replace '"'  )
                    # write-host $pathName
                    # get-acl -path $pathName | ft | out-string | write-host
                    get-acl -path $pathName -errorAction SilentlyContinue| select -expand access | % {
                        $row= New-Object PSObject
                        Add-Member -inputObject $row -memberType NoteProperty -name "Type" -value $_.AccessControlType;
                        Add-Member -inputObject $row -memberType NoteProperty -name "Principal" -value $_.IdentityReference.ToString()
                        Add-Member -inputObject $row -memberType NoteProperty -name "Access" -value $this.getPermissions($_);
                        Add-Member -inputObject $row -memberType NoteProperty -name "Inherited" -value $_.IsInherited
                        Add-Member -inputObject $row -memberType NoteProperty -name "Applies To" -value '';
                
                        $this.form.Content.FindName('selectedObjectPermTable').AddChild($row)
                    }
                }
                "Registry" {
                    get-acl -path "$($path)\" -errorAction SilentlyContinue| select -expand access | % {
                        $row= New-Object PSObject
                        Add-Member -inputObject $row -memberType NoteProperty -name "Type" -value $_.AccessControlType;
                        Add-Member -inputObject $row -memberType NoteProperty -name "Principal" -value $_.IdentityReference.ToString()
                        Add-Member -inputObject $row -memberType NoteProperty -name "Access" -value $this.getPermissions($_);
                        Add-Member -inputObject $row -memberType NoteProperty -name "Inherited" -value $_.IsInherited
                        Add-Member -inputObject $row -memberType NoteProperty -name "Applies To" -value $this.getAppliesTo($_);
                
                        $this.form.Content.FindName('selectedObjectPermTable').AddChild($row)
                    }
                }
            }
            
        }
        
        [void] updateTreeNodeRegistryChildren( $node ){
            $path = "$($node.tag.split('|')[1])";
            gci -path "$($path)\"  -errorAction SilentlyContinue | ? {$_.PSIsContainer -eq $true } | sort Name | % {
                try{
                    if( (gci ($_.fullname) -errorAction SilentlyContinue  ) -ne $null){
                        $treeViewItem = iex "[Windows.Controls.TreeViewItem]::new()"
                        $treeViewItem.Header = "$($_.psChildName)";
                        $treeViewItem.Tag = "Registry|$($_.name -replace 'HKEY_LOCAL_MACHINE','HKLM:' -replace 'HKEY_CURRENT_USER','HKCU')";
                        $treeViewItem.Add_Expanded({
                            $script:self.expandFileSystem($_.OriginalSource)
                        })
                        
                        if( (gci "$($_.fullname)\" -errorAction SilentlyContinue  | Measure-Object | select -expand count) -gt 0){
                            $treeViewItem.Items.Add($null)
                        }
                        
                        $node.Items.Add($treeViewItem)
                        
                        
                    }
                }catch{

                }
            }
        }
        
        [void] updateTreeNodeFileSystemChildren( $node ){
            $path = "$($node.tag.split('|')[1])";
            if( (Get-Item $path) -is [System.IO.DirectoryInfo]){
                gci -path "$($path)\"  -errorAction SilentlyContinue | ? {$_.PSIsContainer -eq $true } | sort Name | % {
                    try{
                        if( (gci ($_.fullname) -errorAction SilentlyContinue  ) -ne $null){
                            
                            $treeViewItem = iex "[Windows.Controls.TreeViewItem]::new()"
                            $treeViewItem.Header = "$($_.name)";
                            $treeViewItem.Tag = "FileSystem|$($_.fullname)";
                            $treeViewItem.Add_Expanded({
                                $script:self.expandFileSystem($_.OriginalSource)
                            })
                            
                            if( (gci "$($_.fullname)\" -errorAction SilentlyContinue  | Measure-Object | select -expand count) -gt 0){
                                $treeViewItem.Items.Add($null)
                            }
                            $node.Items.Add($treeViewItem)
                            
                        }
                    }catch{

                    }
                }
            
                gci -path "$($path)\"  -errorAction SilentlyContinue | ? {$_.PSIsContainer -eq $false } | sort Name | % {
                    try{

                        $treeViewItem = iex "[Windows.Controls.TreeViewItem]::new()"
                        $treeViewItem.Header = "$($_.name)";
                        $treeViewItem.Tag = "FileSystem|$($_.fullname)";
                        $node.Items.Add($treeViewItem)                        
                    }catch{

                    }
                }
            }
            
        }
        
        [void] selectService( $node ){
            $path = "$($node.tag.split('|')[1])";
            $srv = gwmi win32_service -computerName $this.computerName | ? { $_.name -eq $path } | select -first 1
            
            $this.logEvent("Service", "Analyzing $($path)")
            $this.form.Content.FindName('selectedObject').Content = ($srv.pathname -replace "(.+exe).*", '$1' -replace '"' | %{ """$($_)""" } )
            $this.form.Content.FindName('selectedObjectType').Content = "Service"
            $this.form.Content.FindName('selectedObjectOwnerTable').Content = ''
            $this.updatePermissionsGrid( $node )
        }
        
        [void] selectShare( $node ){
            $path = "$($node.tag.split('|')[1])";
            $this.logEvent("Share", "Analyzing $($path)")
            $this.form.Content.FindName('selectedObject').Content = $path
            $this.form.Content.FindName('selectedObjectType').Content = "SMB Share"
            $this.form.Content.FindName('selectedObjectOwnerTable').Content = ''
            $this.updatePermissionsGrid( $node )
        }
        
        [void] selectFileSystem( $node ){
            $path = "$($node.tag.split('|')[1])";
            $this.logEvent("FileSystem", "Analyzing $($path)")
            $this.form.Content.FindName('selectedObject').Content = $path
            $this.form.Content.FindName('selectedObjectType').Content = "File / Directory"
            $this.form.Content.FindName('selectedObjectOwnerTable').Content = ( get-acl -path $path -errorAction SilentlyContinue | select -expand Owner )
            $this.updatePermissionsGrid( $node )
        }
        
        [void] expandFileSystem( $node ){
			$node.Items.clear()

            $path = "$($node.tag.split('|')[1])";
            
            $this.logEvent("FileSystem", "Analyzing $($path)")
        
            $this.form.Content.FindName('selectedObject').Content = $path
            $this.form.Content.FindName('selectedObjectType').Content = "File / Directory"
            $this.form.Content.FindName('selectedObjectOwnerTable').Content = ( get-acl -path $path -errorAction SilentlyContinue | select -expand Owner )
       
            $this.updateTreeNodeFileSystemChildren( $node )
            $this.updatePermissionsGrid( $node )
            
        }

		[void] expandRegistry( $node ){
            $node.Items.clear()
			# $node | fl | out-string | write-host
            $path = "$($node.tag.split('|')[1])\";
			
            $this.form.Content.FindName('selectedObject').Content = $path
            $this.form.Content.FindName('selectedObjectType').Content = "Registry"
            $this.form.Content.FindName('selectedObjectOwnerTable').Content = ( get-acl -path $path -errorAction SilentlyContinue | select -expand Owner )
            
            $this.updateTreeNodeRegistryChildren( $node )
            $this.updatePermissionsGrid( $node )

        }

        [void] nodeClicked( $tree ){
			if($tree.selectedNode.level -le 1){
				$this.form.Controls['mainContent'].panel1.controls['mainBody'].panel2.controls['contentPanel'].controls['selObject'].text = $tree.selectedNode.text
			}elseif($tree.selectedNode.tag -ne $null){
                switch( $tree.selectedNode.tag.split('|')[0] ){
                    "FileSystem" {
                        $this.expandFileSystem( $tree.selectedNode );
                        break;
                    }
					"Registry" {
                        $this.expandRegistry( $tree.selectedNode );
                        break;
                    }
                }
            }

        }
       
        [object] getPrinters(){
            return get-printer -computerName $this.computerName | Sort Name;
        }
        
        [object] getServices(){
            return gwmi win32_service -computerName $this.computerName | Sort Name;
        }

        [object] getShares(){
            return get-smbShare | Sort Name;
        }
        
        [void] removeAcl(){
            $selRow = $this.form.Content.FindName('selectedObjectPermTable').selectedItem  
            # $selRow | ft | out-string | write-host
            
            # write-host $this.form.Content.FindName('selectedObject').Content
            # write-host $selRow.Principal
            # write-host $selRow.Access
            # write-host $selRow.Inherited
            # write-host $selRow.'Applies To'
            # write-host $this.getInheritanceFlags( $selRow.'Applies To')
            # write-host $this.getPropogationFlags( $selRow.'Applies To')
            
            # get-acl $this.form.Content.FindName('selectedObject').Content | select -expand access | fl |out-string | write-host
            if( (Get-Item $this.form.Content.FindName('selectedObject').Content ) -is [System.IO.DirectoryInfo]){
                $toRemove = get-acl $this.form.Content.FindName('selectedObject').Content | select -expand access | ? { 
                    $_.IdentityReference -eq $selRow.Principal -and 
                    $_.IsInherited -eq ([boolean]($selRow.Inherited)) -and 
                    $_.FileSystemRights -eq $selRow.Access -and 
                    $_.InheritanceFlags -eq $this.getInheritanceFlags( $selRow.'Applies To' ) -and 
                    $_.PropagationFlags -eq $this.getPropogationFlags( $selRow.'Applies To' )
                } 
            }else{
                $toRemove = get-acl $this.form.Content.FindName('selectedObject').Content | select -expand access | ? { 
                    $_.IdentityReference -eq $selRow.Principal -and 
                    $_.IsInherited -eq ([boolean]($selRow.Inherited)) -and 
                    $_.FileSystemRights -eq $selRow.Access 
                } 
            }
            
            # $toRemove | fl | out-string | write-host
            
            try{
                $acl = get-acl -path $this.form.Content.FindName('selectedObject').Content
                $acl.RemoveAccessRule($toRemove) | out-null;
                
                # $acl | select -expand access | fl | out-string | write-host
                set-acl -path $this.form.Content.FindName('selectedObject').Content -aclObject $acl
            }catch{
                $mbox = iex "[System.Windows.MessageBox]"
                $mbox.Show($error)            
            }
            $this.updatePermissionsGrid( $this.form.Content.FindName('treeObjects').selectedItem )
        }   
        
        [void] addAcl(){
            
            $path = "$($this.form.Content.FindName('treeObjects').selectedItem.tag.split('|')[1])";
            if( (Get-Item $path) -is [System.IO.DirectoryInfo]){
                $CurUsr = $this.form.Content.FindName('permsPrincipal').Text
                $acl = Get-Acl $path
                $permissions = switch($true){
                    $this.form.Content.FindName('permsFC').isChecked {"FullControl"; break;}
                    $this.form.Content.FindName('permsM').isChecked {"Modify"; break;}
                    $this.form.Content.FindName('permsRE').isChecked {"ReadAndExecute"; break;}
                    $this.form.Content.FindName('permsR').isChecked {"Read"; break;}
                    $this.form.Content.FindName('permsW').isChecked {"Write"; break;}
                }
                
                $inheritenceFlags = switch($this.form.Content.FindName('permsAppliesTo').SelectedItem.Content){
                    "This Folder, Subfolders and Files" {"ContainerInherit, ObjectInherit"}
                    "This Folder and Subfolders" {"ContainerInherit"}
                    "This Folder and Files" {"ObjectInherit"}
                    "This Folder Only" {"None"}
                    "Subfolders and Files" {"ContainerInherit,ObjectInherit"}
                    "Subfolders Only" {"ContainerInherit"}
                    "Files Only" {"ObjectInherit"}
                }
                
                $propogationFlags = switch($this.form.Content.FindName('permsAppliesTo').SelectedItem.Content){
                    "This Folder, Subfolders and Files" {"None"}
                    "This Folder and Subfolders" {"NoPropagateInherit"}
                    "This Folder and Files" {"None"}
                    "This Folder Only" {"None"}
                    "Subfolders and Files" {"InheritOnly"}
                    "Subfolders Only" {"InheritOnly"}
                    "Files Only" {"InheritOnly"}
                }
                
                $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($CurUsr,$permissions,$inheritenceFlags, $propogationFlags, "Allow")
                $AccessRule | ft | out-string | write-host   
                try{
                    $acl.SetAccessRule($AccessRule)
                    $acl | Set-Acl $path
                    $this.form.Content.FindName('Overlay').Visibility = "Collapsed"
                }catch{
                    $mbox = iex "[System.Windows.MessageBox]"
                    $mbox.Show($error)
                }
                
            }else{
                $CurUsr = $this.form.Content.FindName('permsPrincipal').Text
                $acl = Get-Acl $path
                $permissions = switch($true){
                    $this.form.Content.FindName('permsFC').isChecked {"FullControl"; break;}
                    $this.form.Content.FindName('permsM').isChecked {"Modify"; break;}
                    $this.form.Content.FindName('permsRE').isChecked {"ReadAndExecute"; break;}
                    $this.form.Content.FindName('permsR').isChecked {"Read"; break;}
                    $this.form.Content.FindName('permsW').isChecked {"Write"; break;}
                }
                
                $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($CurUsr,$permissions,"Allow")
                try{
                    $acl.SetAccessRule($AccessRule)
                    $acl | Set-Acl $path
                    $this.form.Content.FindName('Overlay').Visibility = "Collapsed"
                }catch{
                    $mbox = iex "[System.Windows.MessageBox]"
                    $mbox.Show($error)
                }
                
                
                $this.form.Content.FindName('Overlay').Visibility = "Collapsed"
            }
            $this.updatePermissionsGrid( $this.form.Content.FindName('treeObjects').selectedItem )
        }
        
        
        [void] showEditAcl(){
            $path = "$($this.form.Content.FindName('treeObjects').selectedItem.tag.split('|')[1])";
            $selRow = $this.form.Content.FindName('selectedObjectPermTable').selectedItem  
            if( (Get-Item $path) -is [System.IO.DirectoryInfo]){
                $this.form.Content.FindName('permsAppliesTo').isEnabled = $true;
            }else{
                $this.form.Content.FindName('permsAppliesTo').isEnabled = $false;
            }
            $this.form.Content.FindName('permsPrincipal').Text = $selRow.Principal;
            
            switch($selRow.access){
                "FullControl" {$this.form.Content.FindName('permsFC').isChecked = $true}
                "Modify" {$this.form.Content.FindName('permsM').isChecked = $true}
                "ReadAndExecute" {$this.form.Content.FindName('permsRE').isChecked = $true}
                "Read" {$this.form.Content.FindName('permsR').isChecked = $true}
                "Write" {$this.form.Content.FindName('permsW').isChecked = $true}
            }
            
            # $this.form.Content.FindName('permsAppliesTo').items[0]  | ft | out-string | write-host
            
            for($i = 0; $i -lt $this.form.Content.FindName('permsAppliesTo').items.count; $i++){
                if( $this.form.Content.FindName('permsAppliesTo').items[$i].content -eq $selRow.'Applies To'){
                    $this.form.Content.FindName('permsAppliesTo').selectedIndex = $i
                }
            }
            
            $this.form.Content.FindName('Overlay').Visibility = "Visible"
        }
        
        [void] showAddAcl(){
            $path = "$($this.form.Content.FindName('treeObjects').selectedItem.tag.split('|')[1])";
            if( (Get-Item $path) -is [System.IO.DirectoryInfo]){
                $this.form.Content.FindName('permsAppliesTo').isEnabled = $true;
            }else{
                $this.form.Content.FindName('permsAppliesTo').isEnabled = $false;
            }
            $this.form.Content.FindName('permsPrincipal').Text = '';
            $this.form.Content.FindName('permsAppliesTo').selectedIndex=0
            
            $this.form.Content.FindName('Overlay').Visibility = "Visible"
        }
        
        
        
        [void] permsCancelClick(){
            $this.form.Content.FindName('Overlay').Visibility = "Collapsed"
        }
        
		SetACL(){
            $script:self = $this
            $this.computerName = ( hostname )
			
            $reader = New-Object System.Xml.XmlNodeReader ([xml](gc "$( $PSScriptRoot)\SetACL-gui.xaml"))
            $xamlReader = iex "[Windows.Markup.XamlReader]"
            $this.form = $xamlReader::Load( $reader ) 
                
            $this.form.Content.FindName('selectedObject').Content = $this.computerName 
            $this.form.Content.FindName('treeObjects').Items.GetItemAt(0).Header = $this.computerName 
 
 
            # $this.form.Content.FindName('btnAddACL').add_Click({$script:self.showAddAcl()})
            # $this.form.Content.FindName('btnEditACL').add_Click({$script:self.showEditAcl()})
            # $this.form.Content.FindName('btnRemoveACL').add_Click({$script:self.removeAcl()})
 
            $this.form.Content.FindName('permsAdd').add_Click({$script:self.showAddAcl()})
            $this.form.Content.FindName('permsEdit').add_Click({$script:self.showEditAcl()})
            $this.form.Content.FindName('permsRemove').add_Click({$script:self.removeAcl()})
            
 
            $this.form.Content.FindName('permsCancel').add_Click({$script:self.permsCancelClick()})
            $this.form.Content.FindName('permsExec').add_Click({$script:self.addAcl()})
 
 
            get-psdrive | ? {$_.Provider.Name -eq 'FileSystem' } | Sort Name | % {
                $treeViewItem = iex "[Windows.Controls.TreeViewItem]::new()"
                $treeViewItem.Header = "$($_.name):";
                $treeViewItem.Tag = "FileSystem|$($_.name):";
                $treeViewItem.Add_Expanded({
                    $script:self.expandFileSystem($_.OriginalSource)
                })
                $treeViewItem.Add_Selected({
                    $script:self.selectFileSystem($_.OriginalSource)
                })
                $subItemIndex = $this.form.Content.FindName('treeObjects').Items.GetItemAt(0).Items.GetItemAt(0).Items.Add( $treeViewItem )
				if( (gci "$($_.fullname)\" -errorAction SilentlyContinue  | ? { $_.PSIsContainer -eq $true } | Measure-Object | select -expand count) -gt 0){
					$this.form.Content.FindName('treeObjects').Items.GetItemAt(0).Items.GetItemAt(0).Items.GetItemAt($subItemIndex).Items.Add($null)
				}
            }
            
            get-psdrive | ? {$_.Provider.Name -eq 'Registry' } | Sort Name | % {
                $treeViewItem = iex "[Windows.Controls.TreeViewItem]::new()"
                $treeViewItem.Header = "$($_.name):";
                $treeViewItem.Tag = "Registry|$($_.name):";
                $treeViewItem.Add_Expanded({
                    $script:self.expandRegistry($_.OriginalSource)
                })
                $treeViewItem.Add_Selected({
                    $script:self.expandRegistry($_.OriginalSource)
                })
                $subItemIndex = $this.form.Content.FindName('treeObjects').Items.GetItemAt(0).Items.GetItemAt(2).Items.Add( $treeViewItem )
				if( (gci "$($_.fullname)\" -errorAction SilentlyContinue  | ? { $_.PSIsContainer -eq $true } | Measure-Object | select -expand count) -gt 0){
					$this.form.Content.FindName('treeObjects').Items.GetItemAt(0).Items.GetItemAt(2).Items.GetItemAt($subItemIndex).Items.Add($null)
				}
            }
            

            $this.getPrinters() | Sort Name | % {
                $treeViewItem = iex "[Windows.Controls.TreeViewItem]::new()"
                $treeViewItem.Header = "$($_.name)";
                $treeViewItem.Tag = "Printer|$($_.name)";
                $this.form.Content.FindName('treeObjects').Items.GetItemAt(0).Items.GetItemAt(1).Items.Add( $treeViewItem )
            }
            
            
            $this.getServices() | Sort Name | % {
                $treeViewItem = iex "[Windows.Controls.TreeViewItem]::new()"
                $treeViewItem.Header = "$($_.name)";
                $treeViewItem.Tag = "Service|$($_.name)";
                $treeViewItem.Add_Selected({
                    $script:self.selectService($_.OriginalSource)
                })
                $this.form.Content.FindName('treeObjects').Items.GetItemAt(0).Items.GetItemAt(3).Items.Add( $treeViewItem )
            }
            
            $this.getShares() | Sort Name | % {
                $treeViewItem = iex "[Windows.Controls.TreeViewItem]::new()"
                $treeViewItem.Header = "$($_.name)";
                $treeViewItem.Tag = "Share|$($_.name)";
                $treeViewItem.Add_Selected({
                    $script:self.selectShare($_.OriginalSource)
                })
                $this.form.Content.FindName('treeObjects').Items.GetItemAt(0).Items.GetItemAt(4).Items.Add( $treeViewItem )
            }
            
            $this.form.ShowDialog() | out-null
		}
	}
}
Process{
	$setAcl = [SetACL]::new();
}
End{
	$error | select *
}
