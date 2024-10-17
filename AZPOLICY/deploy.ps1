$policyName = "jezusicku"
$policyDisplayName = "damns"
$policyDescription = "."
$policyFilePath = "C:\Users\mjabl\OneDrive\Desktop\Azure Labs\AzureLabs\AZPOLICY\policy.json"
$resourceGroupName = "mentoring_labs"
$subscriptionId = (Get-AzContext).Subscription.Id

$policyDefinition = New-AzPolicyDefinition -Name $policyName `
                                            -DisplayName $policyDisplayName `
                                            -Description $policyDescription `
                                            -Policy $policyFilePath `
                                        

$scope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"
$policyAssignment = New-AzPolicyAssignment -Name $policyName `
                                           -DisplayName $policyDisplayName `
                                           -Scope $scope `
                                           -PolicyDefinition $policyDefinition
