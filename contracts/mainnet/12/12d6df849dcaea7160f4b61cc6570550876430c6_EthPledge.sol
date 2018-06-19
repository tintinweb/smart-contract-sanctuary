pragma solidity ^0.4.2;

/*

EthPledge allows people to pledge to donate a certain amount to a charity, which gets sent only if others match it. A user may pledge to donate 10 Ether to a charity, for example, which will get listed here and will be sent to the charity later only if other people also collectively contribute 10 Ether under that pledge. You can also pledge to donate several times what other people donate, up to a certain amount -- for example, you may choose to put up 10 Ether, which gets sent to the charity if others only contribute 2 Ether.

Matching pledges of this kind are quite common (companies may pledge to match all charitable donations their employees make up to a certain amount, for example, or it may just be a casual arrangement between 2 people) and by running on the Ethereum blockchain, EthPledge guarantees 100% transparency. 

Note that as Ethereum is still relatively new at this stage, not many charities have an Ethereum address to take donations yet, though it&#39;s our hope that more will come. The main charity with an Ethereum donation address at this time is Heifer International, whose Ethereum address is 0xb30cb3b3E03A508Db2A0a3e07BA1297b47bb0fb1 (see https://www.heifer.org/what-you-can-do/give/digital-currency.html)

Visit EthPledge.com to play with this smart contract. Reach out: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e1828e8f95808295a1a49589b18d84858684cf828e8c">[email&#160;protected]</a>

*/

contract EthPledge {
    
    address public owner;
    
    function EthPledge() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    struct Campaign {
        address benefactor; // Person starting the campaign, who puts in some ETH to donate to an Ethereum address. 
        address charity;
        uint amountPledged;
        uint amountRaised;
        uint donationsReceived;
        uint multiplier; // If this was 5, for example, other donators would only need to put up 1/5th of the amount the benefactor does for the pledge to be successful and all funds to be donated. Eg. Benefactor pledges 10 ETH, then after only 2 ETH is contributed to the campaign, all funds are send to the charity and the campaign ends
        bool active;
        bool successful;
        uint timeStarted;
        bytes32 descriptionPart1; // Allow a description of up to 132 characters. Each bytes32 part can only hold 32 characters.
        bytes32 descriptionPart2;
        bytes32 descriptionPart3;
        bytes32 descriptionPart4;
    }
    
    mapping (uint => Campaign) public campaign;
    
    mapping (address => uint[]) public campaignsStartedByUser;
    
    mapping (address => mapping(uint => uint)) public addressToCampaignIDToFundsDonated;
    
    mapping (address => uint[]) public campaignIDsDonatedToByUser; // Will contain duplicates if a user donates to a campaign twice
    
    struct Donation {
        address donator;
        uint amount;
        uint timeSent;
    }
    
    mapping (uint => mapping(uint => Donation)) public campaignIDtoDonationNumberToDonation;
    
    uint public totalCampaigns;
    
    uint public totalDonations;
    
    uint public totalETHraised;
    
    uint public minimumPledgeAmount = 10**14; // Basically nothing, can be adjusted later
    
    function createCampaign (address charity, uint multiplier, bytes32 descriptionPart1, bytes32 descriptionPart2, bytes32 descriptionPart3, bytes32 descriptionPart4) payable {
        require (msg.value >= minimumPledgeAmount);
        require (multiplier > 0);
        campaign[totalCampaigns].benefactor = msg.sender;
        campaign[totalCampaigns].charity = charity;
        campaign[totalCampaigns].multiplier = multiplier;
        campaign[totalCampaigns].timeStarted = now;
        campaign[totalCampaigns].amountPledged = msg.value;
        campaign[totalCampaigns].active = true;
        campaign[totalCampaigns].descriptionPart1 = descriptionPart1;
        campaign[totalCampaigns].descriptionPart2 = descriptionPart2;
        campaign[totalCampaigns].descriptionPart3 = descriptionPart3;
        campaign[totalCampaigns].descriptionPart4 = descriptionPart4;
        campaignsStartedByUser[msg.sender].push(totalCampaigns);
        totalETHraised += msg.value;
        totalCampaigns++;
    }
    
    function cancelCampaign (uint campaignID) {
        
        // If the benefactor cancels their campaign, they get a refund of their pledge amount in line with how much others have donated - if you cancel the pledge when 10% of the donation target has been reached, for example, 10% of their pledge amount (along with the donations) will be sent to the charity address, and 90% of the pledge amount you put up will be returned to you
        
        require (msg.sender == campaign[campaignID].benefactor);
        campaign[campaignID].active = false;
        campaign[campaignID].successful = false;
        uint amountShort = campaign[campaignID].amountPledged - (campaign[campaignID].amountRaised * campaign[campaignID].multiplier);
        uint amountToSendToCharity = campaign[campaignID].amountPledged + campaign[campaignID].amountRaised - amountShort;
        campaign[campaignID].charity.transfer(amountToSendToCharity);
        campaign[campaignID].benefactor.transfer(amountShort);
    }
    
    function contributeToCampaign (uint campaignID) payable {
        require (msg.value > 0);
        require (campaign[campaignID].active = true);
        campaignIDsDonatedToByUser[msg.sender].push(campaignID);
        addressToCampaignIDToFundsDonated[msg.sender][campaignID] += msg.value;
        
        campaignIDtoDonationNumberToDonation[campaignID][campaign[campaignID].donationsReceived].donator = msg.sender;
        campaignIDtoDonationNumberToDonation[campaignID][campaign[campaignID].donationsReceived].amount = msg.value;
        campaignIDtoDonationNumberToDonation[campaignID][campaign[campaignID].donationsReceived].timeSent = now;
        
        campaign[campaignID].donationsReceived++;
        totalDonations++;
        totalETHraised += msg.value;
        campaign[campaignID].amountRaised += msg.value;
        if (campaign[campaignID].amountRaised >= (campaign[campaignID].amountPledged / campaign[campaignID].multiplier)) {
            // Target reached
            campaign[campaignID].charity.transfer(campaign[campaignID].amountRaised + campaign[campaignID].amountPledged);
            campaign[campaignID].active = false;
            campaign[campaignID].successful = true;
        }
    }
    
    function adjustMinimumPledgeAmount (uint newMinimum) onlyOwner {
        require (newMinimum > 0);
        minimumPledgeAmount = newMinimum;
    }
    
    // Below are view functions that an external contract can call to get information on a campaign ID or user
    
    function returnHowMuchMoreETHNeeded (uint campaignID) view returns (uint) {
        return (campaign[campaignID].amountPledged / campaign[campaignID].multiplier - campaign[campaignID].amountRaised);
    }
    
    function generalInfo() view returns (uint, uint, uint) {
        return (totalCampaigns, totalDonations, totalETHraised);
    }
    
    function lookupDonation (uint campaignID, uint donationNumber) view returns (address, uint, uint) {
        return (campaignIDtoDonationNumberToDonation[campaignID][donationNumber].donator, campaignIDtoDonationNumberToDonation[campaignID][donationNumber].amount, campaignIDtoDonationNumberToDonation[campaignID][donationNumber].timeSent);
    }
    
    // Below two functions have to be split into two parts, otherwise there are call-stack too deep errors
    
    function lookupCampaignPart1 (uint campaignID) view returns (address, address, uint, uint, uint, bytes32, bytes32) {
        return (campaign[campaignID].benefactor, campaign[campaignID].charity, campaign[campaignID].amountPledged, campaign[campaignID].amountRaised,campaign[campaignID].donationsReceived, campaign[campaignID].descriptionPart1, campaign[campaignID].descriptionPart2);
    }
    
    function lookupCampaignPart2 (uint campaignID) view returns (uint, bool, bool, uint, bytes32, bytes32) {
        return (campaign[campaignID].multiplier, campaign[campaignID].active, campaign[campaignID].successful, campaign[campaignID].timeStarted, campaign[campaignID].descriptionPart3, campaign[campaignID].descriptionPart4);
    }
    
    // Below functions are probably not necessary, but included just in case another contract needs this information in future
    
    function lookupUserDonationHistoryByCampaignID (address user) view returns (uint[]) {
        return (campaignIDsDonatedToByUser[user]);
    }
    
    function lookupAmountUserDonatedToCampaign (address user, uint campaignID) view returns (uint) {
        return (addressToCampaignIDToFundsDonated[user][campaignID]);
    }
    
}