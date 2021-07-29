// GetManagementURL
let GetManagementBaseUri=(govKind as text) as text =>
    let
        managementUrl = if govKind ="us-government" then "https://management.usgovcloudapi.net"
                    else if govKind="germany-government" then""
                    else if govKind = "china" then "https://management.chinacloudapi.cn"
                    else "https://management.azure.com"

    in
        managementUrl

in GetManagementBaseUri

// AzureKind
"global" meta [IsParameterQuery=true, List={"us-government", "global", "china"}, DefaultValue="global", Type="Text", IsParameterQueryRequired=true]

// ListServerFarms
let ListServerFarms = (SubscriptionId as text) =>
let
 GetPages = (Path)=>
 let
     Source = Json.Document(Web.Contents(Path)),
     LL= @Source[value],
     result = try @LL & @GetPages(Source[#"nextLink"]) otherwise @LL
 in
 result,
    Fullset = GetPages(GetManagementURL(AzureKind)&"/subscriptions/"&SubscriptionId&"/providers/Microsoft.Web/serverfarms?api-version=2019-08-01"),
    #"Converted to Table" = Table.FromList(Fullset, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"id", "name", "type", "kind", "location", "tags", "properties", "sku"}, {"id", "name", "type", "kind", "location", "tags", "properties", "sku"}),
    #"Renamed Columns" = Table.RenameColumns(#"Expanded Column1",{{"id", "Server Farm Resource Id"}, {"name", "Server Farm Name"}}),
    #"Expanded properties" = Table.ExpandRecordColumn(#"Renamed Columns", "properties", {"serverFarmId", "name", "workerSize", "workerSizeId", "workerTierName", "numberOfWorkers", "currentWorkerSize", "currentWorkerSizeId", "currentNumberOfWorkers", "status", "webSpace", "subscription", "adminSiteName", "hostingEnvironment", "hostingEnvironmentProfile", "maximumNumberOfWorkers", "planName", "adminRuntimeSiteName", "computeMode", "siteMode", "geoRegion", "perSiteScaling", "elasticScaleEnabled", "maximumElasticWorkerCount", "numberOfSites", "hostingEnvironmentId", "isSpot", "spotExpirationTime", "freeOfferExpirationTime", "tags", "kind", "resourceGroup", "reserved", "isXenon", "hyperV", "mdmId", "targetWorkerCount", "targetWorkerSizeId", "provisioningState", "webSiteId", "existingServerFarmIds", "kubeEnvironmentProfile", "zoneRedundant"}, {"properties.serverFarmId", "properties.name", "properties.workerSize", "properties.workerSizeId", "properties.workerTierName", "properties.numberOfWorkers", "properties.currentWorkerSize", "properties.currentWorkerSizeId", "properties.currentNumberOfWorkers", "properties.status", "properties.webSpace", "properties.subscription", "properties.adminSiteName", "properties.hostingEnvironment", "properties.hostingEnvironmentProfile", "properties.maximumNumberOfWorkers", "properties.planName", "properties.adminRuntimeSiteName", "properties.computeMode", "properties.siteMode", "properties.geoRegion", "properties.perSiteScaling", "properties.elasticScaleEnabled", "properties.maximumElasticWorkerCount", "properties.numberOfSites", "properties.hostingEnvironmentId", "properties.isSpot", "properties.spotExpirationTime", "properties.freeOfferExpirationTime", "properties.tags", "properties.kind", "properties.resourceGroup", "properties.reserved", "properties.isXenon", "properties.hyperV", "properties.mdmId", "properties.targetWorkerCount", "properties.targetWorkerSizeId", "properties.provisioningState", "properties.webSiteId", "properties.existingServerFarmIds", "properties.kubeEnvironmentProfile", "properties.zoneRedundant"}),
    #"Expanded sku" = Table.ExpandRecordColumn(#"Expanded properties", "sku", {"name", "tier", "size", "family", "capacity"}, {"sku.name", "sku.tier", "sku.size", "sku.family", "sku.capacity"}),
   #"Added Conditional Column" = Table.AddColumn(#"Expanded sku", "IsTagged", each if [tags] = null  then "Untagged" else if [tags] = [] then "Untagged" else "Tagged"),
    #"Removed Columns" = Table.RemoveColumns(#"Added Conditional Column",{"tags"})
 in
    #"Removed Columns"
 in
    ListServerFarms

// All Subscriptions
//Developed by Cristian & Jordi

let
 GetPages = (Path)=>
 let
     Source = Json.Document(Web.Contents(Path)),
     LL= @Source[value],
     result = try @LL & @GetPages(Source[#"nextLink"]) otherwise @LL
 in
 result,
     Fullset = GetPages(GetManagementURL(AzureKind)&"/subscriptions?api-version=2020-01-01"),
     #"Converted to Table" = Table.FromList(Fullset, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
     #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"id", "authorizationSource", "managedByTenants", "subscriptionId", "tenantId", "displayName", "state", "subscriptionPolicies", "tags"}, {"id", "authorizationSource", "managedByTenants", "subscriptionId", "tenantId", "displayName", "state", "subscriptionPolicies", "tags"}),
     #"Removed Columns" = Table.RemoveColumns(#"Expanded Column1",{"managedByTenants"}),
     #"Expanded subscriptionPolicies" = Table.ExpandRecordColumn(#"Removed Columns", "subscriptionPolicies", {"locationPlacementId", "quotaId", "spendingLimit"}, {"locationPlacementId", "quotaId", "spendingLimit"}),
     #"Removed Columns1" = Table.RemoveColumns(#"Expanded subscriptionPolicies",{"tags"}),
     #"Renamed Columns" = Table.RenameColumns(#"Removed Columns1",{{"displayName", "Subscription Name"}}),
     #"Removed Columns2" = Table.RemoveColumns(#"Renamed Columns",{"id"})
 in
     #"Removed Columns2"

// ServerFarms
let
    Source = #"All Subscriptions",
    #"Invoked Custom Function" = Table.AddColumn(#"All Subscriptions", "ListServerFarms", each ListServerFarms([subscriptionId])),
    #"Removed Errors" = Table.RemoveRowsWithErrors(#"Invoked Custom Function", {"ListServerFarms"}),
    #"Expanded ListServerFarms" = Table.ExpandTableColumn(#"Removed Errors", "ListServerFarms", {"Server Farm Resource Id", "Server Farm Name", "type", "kind", "location", "properties.serverFarmId", "properties.name", "properties.workerSize", "properties.workerSizeId", "properties.workerTierName", "properties.numberOfWorkers", "properties.currentWorkerSize", "properties.currentWorkerSizeId", "properties.currentNumberOfWorkers", "properties.status", "properties.webSpace", "properties.subscription", "properties.adminSiteName", "properties.hostingEnvironment", "properties.hostingEnvironmentProfile", "properties.maximumNumberOfWorkers", "properties.planName", "properties.adminRuntimeSiteName", "properties.computeMode", "properties.siteMode", "properties.geoRegion", "properties.perSiteScaling", "properties.elasticScaleEnabled", "properties.maximumElasticWorkerCount", "properties.numberOfSites", "properties.hostingEnvironmentId", "properties.isSpot", "properties.spotExpirationTime", "properties.freeOfferExpirationTime", "properties.tags", "properties.kind", "properties.resourceGroup", "properties.reserved", "properties.isXenon", "properties.hyperV", "properties.mdmId", "properties.targetWorkerCount", "properties.targetWorkerSizeId", "properties.provisioningState", "properties.webSiteId", "properties.existingServerFarmIds", "properties.kubeEnvironmentProfile", "properties.zoneRedundant", "sku.name", "sku.tier", "sku.size", "sku.family", "sku.capacity", "IsTagged"}, {"Server Farm Resource Id", "Server Farm Name", "type", "kind", "location", "properties.serverFarmId", "properties.name", "properties.workerSize", "properties.workerSizeId", "properties.workerTierName", "properties.numberOfWorkers", "properties.currentWorkerSize", "properties.currentWorkerSizeId", "properties.currentNumberOfWorkers", "properties.status", "properties.webSpace", "properties.subscription", "properties.adminSiteName", "properties.hostingEnvironment", "properties.hostingEnvironmentProfile", "properties.maximumNumberOfWorkers", "properties.planName", "properties.adminRuntimeSiteName", "properties.computeMode", "properties.siteMode", "properties.geoRegion", "properties.perSiteScaling", "properties.elasticScaleEnabled", "properties.maximumElasticWorkerCount", "properties.numberOfSites", "properties.hostingEnvironmentId", "properties.isSpot", "properties.spotExpirationTime", "properties.freeOfferExpirationTime", "properties.tags", "properties.kind", "properties.resourceGroup", "properties.reserved", "properties.isXenon", "properties.hyperV", "properties.mdmId", "properties.targetWorkerCount", "properties.targetWorkerSizeId", "properties.provisioningState", "properties.webSiteId", "properties.existingServerFarmIds", "properties.kubeEnvironmentProfile", "properties.zoneRedundant", "sku.name", "sku.tier", "sku.size", "sku.family", "sku.capacity", "IsTagged"})
in
    #"Expanded ListServerFarms"