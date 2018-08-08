pragma solidity ^0.4.11;

contract ForklogBlockstarter {
    
    string public constant contract_md5 = "847df4b1ba31f28b9399b52d784e4a8e";
    string public constant contract_sha256 = "cd195ff7ac4743a1c878f0100e138e36471bb79c0254d58806b8244080979116";
    
    mapping (address => bool) private signs;

    address private alex = 0x8D5bd2aBa04A07Bfa0cc976C73eD45B23cC6D6a2;
    address private andrey = 0x688d12D97D0E480559B6bEB6EE9907B625c14Adb;
    address private toly = 0x34972356Af9B8912c1DC2737fd43352A8146D23D;
    address private eugene = 0x259BBd479Bd174129a3ccb007f608D52cd2630e9;

    // This function will be executed by default.
    function() {
        sing();
    }
    
    function sing() {
        singBy(msg.sender);
    }
    
    function singBy(address signer) {
        if (isSignedBy(signer)) return;
        signs[signer] = true;
    }
    
    function isSignedBy(address signer) constant returns (bool) {
        return signs[signer] == true;
    }
    
    function isSignedByAlex() constant returns (bool) {
        return isSignedBy(alex);
    }
    
    function isSignedByAndrey() constant returns (bool) {
        return isSignedBy(andrey);
    }
    
    function isSignedByToly() constant returns (bool) {
        return isSignedBy(toly);
    }
    
    function isSignedByEugene() constant returns (bool) {
        return isSignedBy(eugene);
    }
    
    function isSignedByAll() constant returns (bool) {
        return (
            isSignedByAlex() && 
            isSignedByAndrey() && 
            isSignedByToly() && 
            isSignedByEugene()
        );
    }
}

/*

TEXT OF THE CONTRACT.

To verify a hash of the contract use SHA256 or MD5.
You can find lots of SHA256 / MD5 generators online, for example:

SHA256 online generators:
https://emn178.github.io/online-tools/sha256.html
http://www.xorbin.com/tools/sha256-hash-calculator

MD5 online generators:
https://emn178.github.io/online-tools/md5.html
http://www.xorbin.com/tools/md5-hash-calculator
http://onlinemd5.com/

The content of the contract goes below between long lines of stars (*).
Don&#39;t copy star lines when generating SHA256/MD5. Copy only text in between.

********************************************************************************
# Contract between Forklog and Blockstarter

## Signed on

June 24, 2017

## Participants

### Blockstarter.co

* Aleksandr Siman (https://facebook.com/alek.siman)
* Andrey Stegno (https://facebook.com/andrii.stegno)

### Forklog.com

* Toly Kaplan (https://facebook.com/totkaplan)
* Eugene Muratov (https://facebook.com/eugene.muratov)

## Shares for Forklog

5% of all Blockstarter tokens.

5% from Blockstarter profit.

10% of raised funds during presale (private ICO).

Public ICO reward:

* 10% up to 1 million USD.
* 9% from 1 to 2 million USD.
* 8% from 2 to 3 million USD.
* 7% from 3 to 4 million USD.
* 6% from 4 to 5 million USD.
* 5% from 5 million USD.

## Shares for Blockstarter

15,000 USD from Forklog for development of Blockstarter.

25% of all Blockstarter tokens.

## Shares for Presale contributors

20% of all Blockstarter tokens.

## Shares for ICO contributors

50% of all Blockstarter tokens.

## Blockstarter functionality

In the next sections this document describes the functionlity to be implemented by Blockstarter.

---

# <<< START AFTER FORKLOG CONTRIBUTION >>>

Forklog contributes 15,000 USD for development of Blockstarter.

# **Campaign**

## Startuper

### Create draft

* Draft of campaign can be incomplete. All values can be empty.

* Each draft has a unique URL. 

### Share draft

At any moment it is possible to share draft with team / editors.

### Publish draft for review

Once startupper thinks that campaign is well described, they post draft for validation to BlockStarter team.

Other contributors can pre-validate a draft. This can be rewarded with Blockstarter tokens.

### Edit campaign

At any given moment it’s possible to edit draft or even published campaign.

When edited a published campaign there could be 2 options to go:

1. Update on main site immediately, but additionally send updates to Blockstarter / other contributors, and if there are some strange changes - these changes can be discarded / rolled back.

2. Don’t update on main site right away. Send for approval to Blockstarter / or other contributors.

## Contributor

### Follow campaign

* Receive updates about changes in campaign

* Receive email / chat-bot notification about upcoming campaigns he follows

### Submit edits if found any typos 

It should be possible to submit campaign edits and get rewarded with tokens.

### Help with whitepaper

* Review of existent WP.

* Fix typos in WP.

# List of campaigns

## General functionality for listing

### Filtering / sections

* Upcoming

* Ongoing

* Past

* Launching on Blockstarter

* Launching on other platform

* My Campaigns

### Sorting

* By start date of campaign

* By raised amount in USD

# Bounty task tracker (bounty dashboard)

## Startupper

### Create bounty tasks

Next values can be specified by startupper, when creating a bounty task:

* Name task  (examples: Edit whitepaper, Write blog post, Find typos, etc.)

* Describe task in details

* Amount of reward in tokens

* Deadline

* Choose (*or create on the fly*) the bounty type (in order to easy match company needs with contributors offers in future)

### Manage bounty tasks

All values specified during task creation can be hanged.

New addition values can be provided while managing bounty tasks:

### Provide feedback to participants

## Contributor

### Find and participate in bounty task

### View feedback and status of provided work

# Contribution wallet

## Startupper

### Enable support of different cryptocurrencies

Possible supported coins: Bitcoin, Ethereum, Ethereum Classic, Litecoin, Waves, etc.

### Generate smart contract on Ethereum

Smart contract uses default template created by Blockstarter using values specific to ICO campaign:

* Start date

* End date

* Min cap

* Max cap

* Token symbol

* Add a string "Created on BlockStarter.co" to generated smart contract.

### Generate tokens on Waves platform

Use Waves API to issue tokens seamlessly without a headache. 

### Generate smart contract or issues tokens on other platforms

Bitshares, NXT, Wings, other?

### Publish all generated contracts to GitHub

It should be possible to see all contracts generated for campaigns that launched on Blockstarter.

Contracts could be published to a specific directory of Blockstarter repo called "contracts".

Provide Github Gist link to the draft contract.

### View totals in real time

At any given moment startupper can see a progress of their campaign:

* Total amount in USD

* Total amount in every cryptocurrency, that campaign supports.

* Total number of contributors.

## Contributor

### Select campaign for contribution

### Accept terms of campaign and enter crowdsale

### Choose currency for contribution (Ether, Waves, etc.)

List of contributions and ability to sell and buy tokens between users or buy token when crowdsale is started

---

# <<< START AFTER SUCCESSFUL PRESALE >>>

Presale is considered successful if Blockstarter raises more than 250,000 USD.

# Autoinvest in 3rd party campaigns

It should be possible to join auto investment into big ICOs even if they take place not on Blockstarter.

## Contributor

### Top up deposit on Blockstarter

Contributor puts some amount of money to his Blockstarter account.

Then it will be possible to use any amount of that money when participating in autoinvestment into campaigns that take place on other platforms.

### How to autoinvest for contributor

* List of campaigns where you can autoinvest

* Choose campaign to autoinvest.

* Decide how much you want to autoinvest.

* Submit your decision.

## BlockStarter

### How to manage autoinvesments

* Blockstarter accepts autoinvestment applications up until 3 days before 3rd party campaign starts.

* Blockstarter converts all funds to the currencies, that are accepted by 3rd party campaign. For example if campaign accepts Ethers only, but BS collected Bitcoins and Waves, it could be possible to convert all these to Ether and invest into campaign using Ethers.

* On the day when campaign starts, Blockstarter makes one big investment into 3rd party ICO.

# XBS token and economy of BlockStarter

XBS tokens could be used in different cases:

* Fee for usage of Blockstarter services: publish campaign, publish bounty, publish smart contract.

* Payment for mass feedback to fix conceptual bugs. 

* Payment for promotions of campaign, bounties, jobs and it’s position in the list.

* Payment for work made by contributor or employee.

* Reward for bounty in contrast to unissued tokens of a project.

* Payment for event posting on the Blockstarter related to the ICO to attract contributors.

## Fee for usage of Blockstarter services

Let’s assume that 1 XBS token = 1 USD.

* When creating a new campaign it is required to topup your Blockstarter balance to 500 tokens. 

* 50-100 tokens (10-20% of them) go to Blockstarter.

* 400 tokens left on startupper deposit. Startupper can use these tokens later to pay for work of other contributors: improve whitepaper, legal consultancy, artwork, etc.

* After all startupper will have 400 XBS tokens that could be used in different cases as we see below.

## Payment for promotions

Having big listing it’s always hard to be noticed naturally. Especially if you are unknown project.

XBS tokens can be used to pay for promotions of crowdsale campaigns and bounties.

Having hundreds to thousands of campaigns on site it will be hard to outstand.

By paying for, let’s say 1000 tokens will give a campaign 1000 extra views by showing the campaign on the top of Blockstarter site.

The similar situation could be with bounties or job entries: there could be thousands of different bounties and to get on top of other bounties, a project will pay some XBS tokens.

## Reward for bounty

It should be possible to pay for bounty with non existent tokens of any particular project that is going to launch crowdsale. This is a good way for project to save money and to get some work done for free. But from the other side this way of payment is not safe for workers/contributors, because there is a big chance that project will not success in crowdsale because of big competition between other projects.

XBS tokens as a payment reward for bounty could be a good alternative. Every project could have XBS tokens on its deposit (for example after a required topup during publishing of ICO campaign), and these tokens could be used as a reward for bounty tasks instead of unissued tokens of project. XBS tokens will be more respected and safe way to pay for the job, such as they will be tradeable at that moment in contrast to unissued tokens of a project. 

## Payment for work

XBS tokens could be used as a currency that projects will use to pay salary for their employees or as a one time payment to freelancers. What kind of work can be payed with XBS tokens?

* Improve/review whitepaper.

* Legal support / consultancy.

* Copywriting and PR.

* Programming related tasks.

* Design and artwork.

* Regular salary for employee.

* One time payment for freelancer.

## Fee from money raised during ICO

Blockstarter will take next % from money each campaign raise during ICO:

* 10% up to 1m USD.

* 5% from 1m to 10m USD.

* 2.5% from 10m USD.

---

# <<< START AFTER SUCCESSFUL ICO >>>

Public ICO is considered successful if Blockstarter raises more than 2,000,000 USD.

# Marketplace for contributors

## Contributor

Contributor can help a campaign in different ways, for example:

### Edit Whitepaper or give a feedback

### Help with coding or design work

### Help with legal aspects

### Help with PR

### Write an article / blog post about campaign

---

# APPENDIX A: Media plan for BlockStarter

## Create simple blog on Blockstarter

* It should be server generated (SEO friendly)

* It should lightweight. Just simple Markdown?

## Write ICO digests every week on Blockstarter blog

* A digest should describe most notable past and upcoming ICOs including ICOs that took/will take place either on Blockstarter or 3rd party platform

* ForkLog should help with copywriting for ICO digests.

## Write news about Blostarter: features, updates, news

* Write news and announcements on ForkLog.

* Write some stuff on Blockstarter blog.

## Create video reviews of ICOs using screencast of Blockstarter

* For first time these videos could be published to YouTube channel of Forklog.

* If they are interesting for audience, later they can be published to dedicated channel of Blockstarter.
********************************************************************************

*/