# Proposed additions to sgel-mongodb/vendor-icons

Generic icons sourced from the web on 2026-10-29 for the MongoDB x Microsoft co-sell deck (slides 4, 9 and 10), where the repository had no suitable artwork.

## What's inside
* `svg/microsoft/fluent/` – 26 original, unmodified SVGs from Microsoft Fluent UI System Icons (24 px, regular style, MIT licence).
* `svg/mcp/` – Model Context Protocol mark from Simple Icons (CC0 SVG; trademark rights not granted).
* `png/...` – PNG counterparts with the same basenames, rendered at 512 px from the SVG (aspect ratio and transparency preserved, original colour).
* `catalog/icons-additions.json` – one record per file: name, Windows-style repo path, format, vendor, family, kind, aliases, suggested use, dimensions, SHA-256 and source URL/licence. Merge into `catalog/icons.json`.
* `docs/vendors/microsoft-fluent/LICENSE` and `docs/vendors/mcp/USAGE.md` – licence and usage notes.

## Update 29 Oct 2026 (second batch)
* 4 colour Fluent icons (Building Multiple, Database, People, Bot), MIT.
* Microsoft 365 Copilot (SVG + M365-badge PNG) and Copilot Studio (SVG), Microsoft icons under Microsoft's icon terms; see docs/vendors/microsoft-copilot/USAGE.md.
* New family folders to approve: microsoft/copilot, microsoft/power-platform.

## Naming
Follows the repo pattern `<vendor>-[<family>-]<kind>[-<component>][--style-<style>][--size-<size>]`.
New identifiers to approve: family `fluent` under vendor `microsoft`, and vendor `mcp`.

## Icons
| Basename | Used for | Original |
|---|---|---|
| `microsoft-fluent-ui-building-multiple--style-regular--size-24` | ERP / enterprise apps | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Building%20Multiple/SVG/ic_fluent_building_multiple_24_regular.svg) |
| `microsoft-fluent-ui-people-team--style-regular--size-24` | CRM | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/People%20Team/SVG/ic_fluent_people_team_24_regular.svg) |
| `microsoft-fluent-ui-server--style-regular--size-24` | Mainframe / legacy systems | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Server/SVG/ic_fluent_server_24_regular.svg) |
| `microsoft-fluent-ui-database--style-regular--size-24` | Legacy or self-managed database | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Database/SVG/ic_fluent_database_24_regular.svg) |
| `microsoft-fluent-ui-folder--style-regular--size-24` | File shares | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Folder/SVG/ic_fluent_folder_24_regular.svg) |
| `microsoft-fluent-ui-building-factory--style-regular--size-24` | OT systems | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Building%20Factory/SVG/ic_fluent_building_factory_24_regular.svg) |
| `microsoft-fluent-ui-apps--style-regular--size-24` | Line-of-business apps | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Apps/SVG/ic_fluent_apps_24_regular.svg) |
| `microsoft-fluent-ui-arrow-import--style-regular--size-24` | Ingest | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Arrow%20Import/SVG/ic_fluent_arrow_import_24_regular.svg) |
| `microsoft-fluent-ui-data-treemap--style-regular--size-24` | Normalize | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Data%20Treemap/SVG/ic_fluent_data_treemap_24_regular.svg) |
| `microsoft-fluent-ui-shield-checkmark--style-regular--size-24` | Govern | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Shield%20Checkmark/SVG/ic_fluent_shield_checkmark_24_regular.svg) |
| `microsoft-fluent-ui-lock-closed--style-regular--size-24` | Keep data local / security & encryption | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Lock%20Closed/SVG/ic_fluent_lock_closed_24_regular.svg) |
| `microsoft-fluent-ui-building-government--style-regular--size-24` | Data residency & sovereignty | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Building%20Government/SVG/ic_fluent_building_government_24_regular.svg) |
| `microsoft-fluent-ui-organization--style-regular--size-24` | Operational context | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Organization/SVG/ic_fluent_organization_24_regular.svg) |
| `microsoft-fluent-ui-brain-circuit--style-regular--size-24` | Vector + memory | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Brain%20Circuit/SVG/ic_fluent_brain_circuit_24_regular.svg) |
| `microsoft-fluent-ui-code--style-regular--size-24` | API-ready data | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Code/SVG/ic_fluent_code_24_regular.svg) |
| `microsoft-fluent-ui-certificate--style-regular--size-24` | Trusted upstream model | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Certificate/SVG/ic_fluent_certificate_24_regular.svg) |
| `microsoft-fluent-ui-branch--style-regular--size-24` | Governance & lineage | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Branch/SVG/ic_fluent_branch_24_regular.svg) |
| `microsoft-fluent-ui-arrow-download--style-regular--size-24` | Data ingestion | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Arrow%20Download/SVG/ic_fluent_arrow_download_24_regular.svg) |
| `microsoft-fluent-ui-table--style-regular--size-24` | Lakehouse & warehousing | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Table/SVG/ic_fluent_table_24_regular.svg) |
| `microsoft-fluent-ui-flowchart--style-regular--size-24` | Semantic modeling | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Flowchart/SVG/ic_fluent_flowchart_24_regular.svg) |
| `microsoft-fluent-ui-data-bar-vertical--style-regular--size-24` | Analytics & insights | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Data%20Bar%20Vertical/SVG/ic_fluent_data_bar_vertical_24_regular.svg) |
| `microsoft-fluent-ui-rocket--style-regular--size-24` | Faster grounding | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Rocket/SVG/ic_fluent_rocket_24_regular.svg) |
| `microsoft-fluent-ui-plug-connected--style-regular--size-24` | Lower integration effort | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Plug%20Connected/SVG/ic_fluent_plug_connected_24_regular.svg) |
| `microsoft-fluent-ui-target-arrow--style-regular--size-24` | Higher enterprise relevance | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Target%20Arrow/SVG/ic_fluent_target_arrow_24_regular.svg) |
| `microsoft-fluent-ui-shield-lock--style-regular--size-24` | Security & compliance | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Shield%20Lock/SVG/ic_fluent_shield_lock_24_regular.svg) |
| `microsoft-fluent-ui-pulse--style-regular--size-24` | Observability | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Pulse/SVG/ic_fluent_pulse_24_regular.svg) |
| `mcp-logo--style-simple-icons` | Model Context Protocol (MongoDB MCP Server path) | [source](https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/modelcontextprotocol.svg) |

## Added in revision 2 (29 Oct 2026)
| Basename | Used for | Original |
|---|---|---|
| `microsoft-fluent-ui-building-multiple--style-color--size-24` | ERP / enterprise apps (colour) | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Building%20Multiple/SVG/ic_fluent_building_multiple_24_color.svg) |
| `microsoft-fluent-ui-database--style-color--size-24` | Mainframe & legacy databases (colour) | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Database/SVG/ic_fluent_database_24_color.svg) |
| `microsoft-fluent-ui-people--style-color--size-24` | Users | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/People/SVG/ic_fluent_people_24_color.svg) |
| `microsoft-fluent-ui-bot-sparkle--style-color--size-24` | Foundry Agent Service (generic agent glyph) | [source](https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets/Bot%20Sparkle/SVG/ic_fluent_bot_sparkle_24_color.svg) |
| `microsoft-product-logo-microsoft-365-copilot` (PNG) | Microsoft 365 Copilot | [source](https://raw.githubusercontent.com/DamoBird365/microsoft-cloud-icons/master/icons/copilot/copilot-365.png) |
| `microsoft-product-logo-copilot-studio` (PNG) | Copilot Studio | [source](https://raw.githubusercontent.com/DamoBird365/microsoft-cloud-icons/master/icons/power-platform/copilot-studio.png) |

Still missing (not retrievable here): official **Foundry Agent Service** icon from the Azure Architecture Icons (July 2026) set: https://learn.microsoft.com/en-us/azure/architecture/icons/ (mirror: https://az-icons.com/icon/foundry-agent-service). New family identifier to approve: `product` under vendor `microsoft`.

## Checks done
* Every SVG parsed as well-formed XML and rendered to PNG; renders inspected visually.
* SHA-256 recorded for every file in the catalog.
* The deck uses tinted copies of the PNGs (colour changed to match each diagram column). Those tinted copies are deck assets only and are not part of this pack.
