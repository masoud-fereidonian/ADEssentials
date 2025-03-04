﻿function New-HTMLGroupDiagramSummary {
    [cmdletBinding()]
    param(
        [Array] $ADGroup,
        [ValidateSet('Default', 'Hierarchical', 'Both')][string] $HideAppliesTo = 'Both',
        [switch] $HideComputers,
        [switch] $HideUsers,
        [switch] $HideOther,
        [string] $DataTableID,
        [int] $ColumnID,
        [switch] $Online
    )
    $ConnectionsTracker = @{}
    New-HTMLDiagram -Height 'calc(100vh - 200px)' {
        #if ($DataTableID) {
        #    New-DiagramEvent -ID $DataTableID -ColumnID $ColumnID
        #}
        #New-DiagramOptionsLayout -HierarchicalEnabled $true -HierarchicalDirection FromLeftToRight #-HierarchicalSortMethod directed
        #New-DiagramOptionsPhysics -Enabled $true -HierarchicalRepulsionAvoidOverlap 1 -HierarchicalRepulsionNodeDistance 50
        New-DiagramOptionsPhysics -RepulsionNodeDistance 150 -Solver repulsion
        if ($ADGroup) {
            # Add it's members to diagram
            foreach ($ADObject in $ADGroup) {
                # Lets build our diagram
                # This diagram of Summary doesn't use level checking because it's a summary of a groups, and the level will be different per group
                # This means that it will look a bit different than what is there when comparing 1 to 1 with the other diagrams
                #[int] $Level = $($ADObject.Nesting) + 1
                $ID = "$($ADObject.DomainName)$($ADObject.DistinguishedName)"
                #[int] $LevelParent = $($ADObject.Nesting)
                $IDParent = "$($ADObject.ParentGroupDomain)$($ADObject.ParentGroupDN)"
                # We track connection for ID to make sure that only once the conenction is added
                if (-not $ConnectionsTracker[$ID]) {
                    $ConnectionsTracker[$ID] = @{}
                }
                if (-not $ConnectionsTracker[$ID][$IDParent]) {
                    if ($ADObject.Type -eq 'User') {
                        if (-not $HideUsers -or $HideAppliesTo -notin 'Both', 'Default') {
                            $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName
                            if ($Online) {
                                New-DiagramNode -Id $ID -Label $Label -Image 'https://image.flaticon.com/icons/svg/3135/3135715.svg'
                            } else {
                                New-DiagramNode -Id $ID -Label $Label -IconSolid user -IconColor LightSteelBlue
                            }
                            New-DiagramLink -ColorOpacity 0.2 -From $ID -To $IDParent -Color Blue -ArrowsToEnabled -Dashes
                        }
                    } elseif ($ADObject.Type -eq 'Group') {
                        if ($ADObject.Nesting -eq -1) {
                            $BorderColor = 'Red'
                            $Image = 'https://image.flaticon.com/icons/svg/921/921347.svg'
                        } else {
                            $BorderColor = 'Blue'
                            $Image = 'https://image.flaticon.com/icons/svg/166/166258.svg'
                        }
                        $SummaryMembers = -join ('Total: ', $ADObject.TotalMembers, ' Direct: ', $ADObject.DirectMembers, ' Groups: ', $ADObject.DirectGroups, ' Indirect: ', $ADObject.IndirectMembers)
                        $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName + [System.Environment]::NewLine + $SummaryMembers
                        if ($Online) {
                            New-DiagramNode -Id $ID -Label $Label -Image $Image -ArrowsToEnabled -ColorBorder $BorderColor
                        } else {
                            New-DiagramNode -Id $ID -Label $Label -ArrowsToEnabled -IconSolid user-friends -IconColor VeryLightGrey
                        }
                        New-DiagramLink -ColorOpacity 0.5 -From $ID -To $IDParent -Color Orange -ArrowsToEnabled
                    } elseif ($ADObject.Type -eq 'Computer') {
                        if (-not $HideComputers -or $HideAppliesTo -notin 'Both', 'Default') {
                            $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName
                            if ($Online) {
                                New-DiagramNode -Id $ID -Label $Label -Image 'https://image.flaticon.com/icons/svg/3003/3003040.svg'
                            } else {
                                New-DiagramNode -Id $ID -Label $Label -IconSolid desktop -IconColor LightGray
                            }
                            New-DiagramLink -ColorOpacity 0.2 -From $ID -To $IDParent -Color Arsenic -ArrowsToEnabled -Dashes
                        }
                    } else {
                        if (-not $HideOther -or $HideAppliesTo -notin 'Both', 'Default') {
                            $Label = $ADObject.Name + [System.Environment]::NewLine + $ADObject.DomainName
                            if ($Online) {
                                New-DiagramNode -Id $ID -Label $Label -Image 'https://image.flaticon.com/icons/svg/3347/3347551.svg'
                            } else {
                                New-DiagramNode -Id $ID -Label $Label -IconSolid robot -IconColor LightSalmon
                            }
                            New-DiagramLink -ColorOpacity 0.2 -From $ID -To $IDParent -Color Boulder -ArrowsToEnabled -Dashes
                        }
                    }
                    $ConnectionsTracker[$ID][$IDParent] = $true
                }
            }
        }
    }
}