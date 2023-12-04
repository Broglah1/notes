Add-Type -Path "C:\Devops\PatchMyPC\HtmlAgilityPack.dll"

function Scrape-Page($Url) {
    $webResponse = Invoke-WebRequest -Uri $Url
    $content = $webResponse.Content

    # Regex patterns
    $titlePattern = '<h2 class="entry-title"><a href="(.*?)">(.*?)<\/a><\/h2>'
    $metaPattern = '<p class="post-meta"> by <span class="author vcard"><a href=".*?" title=".*?" rel="author">(.*?)<\/a><\/span> \| <span class="published">(.*?)<\/span>'

    # Find matches
    $titleMatches = [regex]::Matches($content, $titlePattern)
    $metaMatches = [regex]::Matches($content, $metaPattern)

    $global:results = @()
    for ($i = 0; $i -lt $titleMatches.Count; $i++) {
        $link = $titleMatches[$i].Groups[1].Value
        $title = $titleMatches[$i].Groups[2].Value
        $author = $metaMatches[$i].Groups[1].Value
        $publishedDate = $metaMatches[$i].Groups[2].Value

        if ($title -match "November \d{1,2}, 2023") {
            $descriptionPattern = "<p>(.*?)<\/p>"
            $descriptionMatches = [regex]::Match($content, $descriptionPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
            $description = $descriptionMatches.Groups[1].Value

            # Call function to scrape article details
            $articleDetails = Scrape-ArticleDetails -ArticleUrl $link

            $global:results += [PSCustomObject]@{
                Title = $title
                Link = $link
                Author = $author
                PublishedDate = $publishedDate
                Description = $description
                ArticleDetails = $articleDetails
            }
        }
    }

    return $global:results
}
function Scrape-ArticleDetails($ArticleUrl) {
    $response = Invoke-WebRequest -Uri $ArticleUrl
    $htmlDoc = New-Object HtmlAgilityPack.HtmlDocument
    $htmlDoc.LoadHtml($response.Content)

    $updateTypeColors = @{
        "#00ff00" = "Feature Release"
        "#fad400" = "Bug Fix Release"
        "#ff0000" = "Security Release"
    }

    $global:details = @()
    $appNodes = $htmlDoc.DocumentNode.SelectNodes('//ul/li')

    foreach ($appNode in $appNodes) {
        $appNameNode = $appNode.SelectSingleNode('.//strong')
        if ($appNameNode -ne $null) {
            $appName = $appNameNode.InnerText
            $releaseNotesUrlNode = $appNode.SelectSingleNode('.//a[contains(text(), "Release Notes")]')

            if ($releaseNotesUrlNode -ne $null) {
                $releaseNotesUrl = $releaseNotesUrlNode.GetAttributeValue("href", "Not Available")

                $updateTypes = @()
                foreach ($color in $updateTypeColors.Keys) {
                    if ($appNode.InnerHtml -match "color:\s?$color") {
                        $updateTypes += $updateTypeColors[$color]
                    }
                }

                if ($updateTypes.Count -eq 0) {
                    $updateTypes += "Unknown"
                }

                $global:details += [PSCustomObject]@{
                    ApplicationName = $appName
                    ReleaseNotesUrl = $releaseNotesUrl
                    UpdateTypes = ($updateTypes -join ', ')
                }
            }
        }
    }

    return $global:details
}
# Scrape pages
$startPage = 1
$endPage = 10 # Adjust this as necessary
$allResults = @()

for ($i = $startPage; $i -le $endPage; $i++) {
    $url = "https://patchmypc.com/category/catalog-updates/page/$i"
    $pageResults = Scrape-Page -Url $url
    $allResults += $pageResults
}

# Output the results
$allResults | Format-Table -AutoSize

$securityReleases = foreach ($item in $allResults) {
    $item.ArticleDetails | Where-Object { $_.UpdateTypes -match 'Security Release' } | ForEach-Object {
        [PSCustomObject]@{
            Title = $item.Title
            Link = $item.Link
            ApplicationName = $_.ApplicationName
            ReleaseNotesUrl = $_.ReleaseNotesUrl
            UpdateType = $_.UpdateTypes
        }
    }
}

$bugReleases = foreach ($item in $allResults) {
    $item.ArticleDetails | Where-Object { $_.UpdateTypes -match 'Bug Fix Release' } | ForEach-Object {
        [PSCustomObject]@{
            Title = $item.Title
            Link = $item.Link
            ApplicationName = $_.ApplicationName
            ReleaseNotesUrl = $_.ReleaseNotesUrl
            UpdateType = $_.UpdateTypes
        }
    }
}

$featureReleases = foreach ($item in $allResults) {
    $item.ArticleDetails | Where-Object { $_.UpdateTypes -match 'Feature Release' } | ForEach-Object {
        [PSCustomObject]@{
            Title = $item.Title
            Link = $item.Link
            ApplicationName = $_.ApplicationName
            ReleaseNotesUrl = $_.ReleaseNotesUrl
            UpdateType = $_.UpdateTypes
        }
    }
}

$unknownReleases = foreach ($item in $allResults) {
    $item.ArticleDetails | Where-Object { $_.UpdateTypes -match 'Unknown' } | ForEach-Object {
        [PSCustomObject]@{
            Title = $item.Title
            Link = $item.Link
            ApplicationName = $_.ApplicationName
            ReleaseNotesUrl = $_.ReleaseNotesUrl
            UpdateTypes = $_.UpdateTypes
        }
    }
}

$allUpdates = foreach ($item in $allResults) {
    $item.ArticleDetails | ForEach-Object {
        [PSCustomObject]@{
            Title = $item.Title
            Link = $item.Link
            ApplicationName = $_.ApplicationName
            ReleaseNotesUrl = $_.ReleaseNotesUrl
            UpdateTypes = $_.UpdateTypes  # Assuming UpdateTypes is a string or a list of update types
        }
    }
}

write-host "All updates this month" $allUpdates.count
write-host "Security Releases this month" $securityReleases.Count 
write-host "Bug Releases this month" $bugReleases.count 
write-host "Feature Releases this month" $featureReleases.Count 
write-host "Unknown Releases this month" $unknownReleases.Count 


function CleanAppName($appName) {
    # Regular expression to match version and architecture patterns
    $pattern = '\s+\d+(\.\d+)*(\s+\(.*\))?'
    return $appName -replace $pattern, ''
}

$allApps = @()
foreach ($item in $allResults) {
    foreach ($detail in $item.ArticleDetails) {
        $cleanAppName = CleanAppName($detail.ApplicationName)
        $allApps += [PSCustomObject]@{
            Title = $item.Title
            Link = $item.Link
            ApplicationName = $cleanAppName
            ReleaseNotesUrl = $detail.ReleaseNotesUrl
            UpdateTypes = $detail.UpdateTypes
        }
    }
}

# Grouping and selecting the first unique application name
$uniqueApps = $allApps | Group-Object ApplicationName | ForEach-Object { $_.Group | Select-Object -First 1 }

# Sorting the unique apps by ApplicationName in ascending order (A-Z)
$sortedUniqueApps = $uniqueApps | Sort-Object ApplicationName