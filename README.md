# StaleTeamsProfileRemidiation
Project Proposal
Project Title
Stale User Profile Detection and Legacy Microsoft Teams Remediation via Intune Proactive Remediations
Employer
University of Huddersfield
Project Summary
Microsoft Defender for Endpoint has identified a high number of Microsoft Teams-related software detections across the managed Windows estate. Some devices are reporting multiple Teams versions at the same time, which has created uncertainty about whether these entries represent active software, legacy application remnants, stale registry data, old installer references, per-user installations, or delayed Defender inventory.
Initial investigation showed that the issue was more complex than a simple Teams version cleanup. Defender is reporting a mixture of current Teams packages, Teams Classic remnants, Teams Machine-Wide Installer entries, per-user Teams data, registry artefacts and stale local profile content.
A confirmed test case showed that an old local user profile, unused since 2023, still contained a full Microsoft Teams Classic per-user installation of approximately 488 MB. Teams Classic could still be launched from that profile. This confirmed that at least some Defender detections were genuine legacy application binaries rather than harmless reporting artefacts.
The work has therefore moved from a Teams-specific cleanup activity into a wider endpoint hygiene and stale user profile remediation project. The proposed solution is an Intune Proactive Remediation that detects stale local Windows profiles on appropriate single-user managed laptops and removes eligible profiles safely using supported Windows profile management methods.
The solution will use a PowerShell detection script and a PowerShell remediation script. The detection script will identify stale profiles based on last-use evidence and report devices requiring remediation. The remediation script will remove only eligible profiles using Win32_UserProfile and Remove-CimInstance. Active, loaded, system, administrator, provisioning, enrolment, local support and agreed protected profiles will be excluded.
Microsoft Intune will be used for deployment and reporting. Microsoft Defender for Endpoint will be used to compare before-and-after software inventory, including whether Teams Classic and older Teams-related detections reduce following stale profile removal.
The project will produce evidence of investigation, hypothesis testing, PowerShell development, source control, code quality checks, testing, staged deployment, monitoring, exception handling, security controls and iterative improvement.
Current Position
The original issue was identified through Defender software inventory, where a large number of Teams-related versions appeared across managed devices. The early assumption was that many of these detections may have been caused by stale registry keys, old Teams installer references, Teams Machine-Wide Installer remnants or Defender inventory delay.
Local investigation changed that understanding. Some detections appear to be inventory or artefact related, but at least one confirmed device contained an old, launchable Teams Classic installation inside a stale local user profile. This showed that the underlying issue is not limited to Teams itself. Assigned-user laptops can retain old local profiles from previous, occasional or support logons, and those profiles can retain outdated per-user software and cached data.
The current remediation approach is to target the underlying stale profile condition rather than only deleting Teams-specific folders. This provides a safer and more complete operational improvement because it addresses the profile state that can retain legacy per-user applications, not just one application name.
Problem Statement
Stale local profiles on managed laptops can retain old application binaries, cached data and historic per-user software. Microsoft Defender for Endpoint may continue to report these components even where the current user is using the approved modern Teams client.
This creates several operational and security issues:
Defender software inventory becomes harder to interpret.
Old Teams versions may appear to remain present on devices.
Security and support teams may need to spend time investigating detections that are linked to unused profiles.
Legacy per-user applications may remain on devices longer than necessary.
Unused local profiles consume disk space.
Manual device-by-device investigation is not scalable across the laptop estate.
The evidence indicates that stale profile remediation is a more appropriate corrective action than a narrow Teams-only cleanup. The project will therefore focus on identifying and safely removing stale local profiles from appropriate managed laptops.
Project Aim
The project will deliver a safe, repeatable and reportable Intune Proactive Remediation solution that detects and removes stale local Windows user profiles from managed University laptops.
The expected outcome is cleaner endpoint state, reduced legacy per-user application remnants, improved Defender software inventory quality and better visibility of remaining exceptions.
Project Objectives
The project will deliver the following objectives:
Investigate Defender Teams version detections and identify whether they relate to active software, legacy components, stale local profiles or reporting artefacts.
Develop a PowerShell detection script that identifies stale local Windows profiles on Intune-managed laptops.
Develop a PowerShell remediation script that removes eligible stale profiles using supported Windows profile management methods.
Protect active, loaded, system, administrator, provisioning, enrolment, local support and agreed protected profiles through explicit exclusion logic.
Deploy the solution through Microsoft Intune Proactive Remediations, which is the appropriate management route for the target laptop estate.
Use a controlled rollout model, beginning with local testing and a pilot group before wider deployment.
Monitor detection and remediation outcomes through Intune reporting.
Compare Defender software inventory before and after remediation to assess whether legacy Teams-related detections reduce.
Maintain evidence of source control, script versions, test results, deployment outputs, monitoring data, exception handling and lessons learned.
Demonstrate DevOps engineering practice through automation, source control, testing, staged release, monitoring, feedback and iterative refinement.
Scope
The project will cover Intune-managed University Windows laptops where the device is intended for single-user assignment and where stale local profiles can be safely remediated.
The remediation will apply to local Windows profiles stored under C:\Users where the profile has not been accessed for an agreed stale period. The initial proposed threshold is 90 days, with 60 days available as a later refinement if testing, risk review and service agreement support that change.
The project will use:
Microsoft Defender for Endpoint software inventory.
Microsoft Intune Proactive Remediations.
PowerShell.
Win32_UserProfile.
Remove-CimInstance.
Intune remediation reporting.
Before-and-after Defender comparison.
Source control and testing evidence.
Shared lab devices, student classroom devices and specialist multi-user devices will be excluded from the initial deployment. These device types have different usage patterns and profile-retention requirements, so they should only be considered through separate review and approval.
The remediation will not remove active or loaded profiles. It will not remove the current approved Microsoft Teams client. It will not remove the Teams Meeting Add-in unless a separate decision is made. It will not use direct deletion of C:\Users folders as the primary remediation method.
Technical Approach
The solution will use Microsoft Intune Proactive Remediations with two PowerShell scripts.
Detection Script
The detection script will run as SYSTEM in 64-bit PowerShell. It will query local profiles using Win32_UserProfile and assess each profile against agreed eligibility rules.
The detection logic will check:
profile path;
SID;
loaded status;
special profile status;
last-use evidence;
profile age;
protected profile names;
agreed exclusion rules.
Profiles that meet the stale threshold and do not match any exclusion rule will be reported as eligible for remediation.
The script will exit with code 1 when remediation is required and code 0 when no stale profiles are found. This allows Intune Proactive Remediations to trigger the remediation script only where required.
Remediation Script
The remediation script will use the same eligibility rules as the detection script. This keeps detection and remediation aligned and reduces the chance of inconsistent behaviour.
Eligible stale profiles will be removed using Remove-CimInstance against Win32_UserProfile. This uses the Windows profile management layer rather than simply deleting folders from disk.
The remediation will skip:
loaded profiles;
active profiles;
special Windows profiles;
administrator profiles;
provisioning or enrolment profiles;
local support profiles;
agreed protected profiles;
any profile where the script cannot determine eligibility safely.
The remediation output will record which profiles were removed, skipped or failed. Failed or uncertain removals will remain visible for follow-up rather than being hidden.
Development and Delivery Approach
The project will follow an iterative delivery approach.
The first stage will evidence the Defender software inventory position and the local investigation that confirmed stale profiles as a genuine contributing factor. This will include the Teams Classic example found inside an unused 2023 profile.
The second stage will develop the PowerShell detection and remediation scripts. The scripts will be version-controlled and updated through small, traceable changes. Code quality will be supported through clear structure, comments, predictable exit codes, error handling, logging and validation checks.
Testing will include defined profile scenarios before deployment to a wider device group. The test matrix will include:
a device with no stale profiles;
a device with one stale profile;
a device with multiple stale profiles;
a device with a loaded profile;
a device with protected administrator or support profiles;
a device with Teams Classic remnants inside a stale profile;
a device where remediation should be skipped;
a device where failure should be reported safely.
Where practical, PSScriptAnalyzer and Pester tests will be used to strengthen code quality and testing evidence.
The third stage will deploy the remediation to a small pilot group using Intune Proactive Remediations. Pilot results will be reviewed before any wider deployment. The wider rollout will remain controlled and limited to appropriate managed laptop device groups.
The final stage will review Intune remediation output, Defender software inventory and exception data. The scripts and deployment approach will be refined where testing or monitoring shows that changes are needed.
Success Criteria
The project will be successful when the following outcomes are demonstrated:
Stale local profiles can be detected reliably on managed laptops.
Active, loaded and protected profiles are excluded from remediation.
Eligible stale profiles can be removed safely using supported Windows methods.
The remediation can be deployed through Intune without requiring users to bring laptops to campus.
Intune reporting shows detection, remediation, success, failure and exception outcomes.
Defender software inventory can be compared before and after remediation.
Legacy Teams Classic or older Teams-related detections reduce where stale profile removal was the cause.
Failed, skipped or uncertain devices remain visible for review.
Source control, testing, deployment, monitoring, data security and operational ownership are evidenced.
The final documentation is clear enough for future support, review and maintenance.
Business and Service Value
The project improves endpoint hygiene, security posture and operational efficiency.
The security value comes from reducing old per-user application remnants and cached profile data on managed laptops. Removing stale profiles also helps reduce the chance that unsupported or outdated application binaries remain present on devices unnecessarily.
The support value comes from improving the quality of Defender software inventory. Fewer stale detections should reduce confusion around whether old Teams versions are actively installed and should make remaining exceptions easier to investigate.
The operational value comes from replacing manual device-by-device investigation with a repeatable Intune-delivered remediation. This allows remote laptops to be remediated without requiring users to attend campus or support teams to handle each device individually.
The user value comes from a silent and controlled remediation model. The active user profile is protected, and the work is designed to avoid disruption to normal laptop use.
The wider Digital Workspace value comes from using monitoring, automation, controlled deployment and evidence-led improvement to reduce hidden endpoint drift.
Risks and Controls
Risk	Control
Active user profile is removed accidentally	Loaded and active profiles will be excluded. Eligibility logic will be tested before wider deployment.
Administrator, support or provisioning profile is removed	Protected profile names and known support profiles will be explicitly excluded.
Shared, lab or specialist device is remediated incorrectly	Initial deployment will target appropriate laptop groups only. Shared and specialist device groups will be excluded.
Defender inventory does not update immediately	Before-and-after reporting will be interpreted over time rather than expecting instant inventory change.
Profile folder is deleted incorrectly	Remediation will use Win32_UserProfile and Remove-CimInstance rather than direct C:\Users folder deletion.
Stale profile detection is too aggressive	The initial stale threshold will be conservative, with 90 days proposed for production use. Any move to 60 days will require review.
Script output exposes unnecessary user data	Output will be limited to operationally useful remediation evidence and will avoid unnecessary personal data.
CI/CD evidence is too light	The project will use source control, version history, validation checks, testing evidence and staged Intune deployment as a lightweight release workflow.
Remaining detections are misinterpreted	Remaining Defender entries will be reviewed as exceptions and may represent current Teams, inventory delay or other Teams components.
Evidence Plan
The project will produce evidence across investigation, development, deployment and monitoring.
The evidence set will include:
project brief and scope;
Defender baseline software inventory;
affected-device investigation notes;
evidence of Teams Classic inside a stale local profile;
PowerShell detection script;
PowerShell remediation script;
Git repository and commit history;
script version history;
change log;
PSScriptAnalyzer output;
Pester tests or structured test evidence;
test matrix and results;
Intune Proactive Remediation configuration;
pilot deployment results;
detection and remediation output;
before-and-after Defender comparison;
exception list;
lessons learned;
final KSB mapping.
This evidence will show how the work moved from investigation through to tested code, controlled deployment, monitoring and refinement.
Assessment Coverage
The project provides evidence across the main BCS DevOps Engineer project areas.
Code quality will be evidenced through PowerShell development, source control, versioning, code checks, testing, comments, error handling and safe remediation logic.
Meeting user needs will be evidenced through user stories, acceptance criteria, silent deployment, active profile protection, reduced manual support and improved security visibility.
CI/CD will be evidenced through a lightweight release workflow: source-controlled scripts, validation, testing, pilot deployment and staged Intune rollout.
Refreshing and patching will be evidenced through endpoint state improvement, removal of stale profile data, reduction of legacy application remnants and alignment to a cleaner managed endpoint baseline.
Operability will be evidenced through Intune remediation reporting, Defender inventory comparison, logging, exception handling and monitoring of outcomes.
Data persistence will be evidenced through the use of local Windows profile state, Defender inventory records, Intune remediation records and retained logs or evidence outputs.
Automation will be evidenced through PowerShell and Intune Proactive Remediations replacing manual investigation and cleanup.
Data security will be evidenced through stale profile risk reduction, protected-profile exclusions, controlled deployment, limited logging and safe removal methods.
Next Steps
The next stage is to finalise the project sign-off position with the tutor and confirm that the proposed scope is suitable for the work-based project.
The practical delivery steps are:
Confirm the final stale profile threshold for pilot and production use.
Confirm the pilot device group and excluded device groups.
Finalise the detection and remediation scripts.
Store the scripts in source control with clear version history.
Complete the test matrix and capture results.
Deploy to a controlled Intune pilot group.
Review Intune detection and remediation output.
Compare Defender Teams-related detections before and after remediation.
Refine exclusions or script logic where evidence shows this is needed.
Complete the final project report and KSB mapping.
Conclusion
The project provides a suitable Level 4 DevOps Engineer work-based project because it includes real investigation, coding, testing, automation, controlled deployment, monitoring and improvement.
The strongest evidence is the way the work changed direction after testing challenged the original assumption. Defender initially appeared to show a Teams version problem. Local investigation showed that stale user profiles could retain full legacy Teams Classic installations. The remediation approach was therefore adjusted to address the wider endpoint hygiene issue rather than only removing Teams-specific artefacts.
The project demonstrates a practical DevOps engineering cycle: identify the issue through monitoring, investigate the evidence, test the hypothesis, develop code, deploy safely, monitor the result and improve the solution based on what the evidence shows.
