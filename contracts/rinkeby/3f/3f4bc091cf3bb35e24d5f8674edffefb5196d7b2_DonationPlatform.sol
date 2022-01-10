/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/** 
 * @title DonationPlatform
 * @dev Implements creation of and contribution to Donation Campaigns 
 */
contract DonationPlatform {

    struct Campaign {
        uint id;                // campaign id
        string name;            // campaigns name
        string description;     // campaigns description
        uint goalAmount;        // desired amount of WEI that should be collected
        uint receivedAmount;    // amount of funds that were donated to the campaign
        uint expirationTime;    // timestamp after which campaign is no longer active
        bool fundsWithdrawn;    // flag that says whether the funds for a campaign have been withdrawn by administrator
    }

    address public administrator;

    mapping (uint => Campaign) public campaigns;

    uint campaignsCreated;      // number of campaigns that have been created

    event CampaignCreated(uint id, string name, string description, uint goalAmount, uint expirationTime); // Emmited when the campaign has been created
    event CampaignReceivedDonation(uint id, string name, string description, uint goalAmount, uint expirationTime, uint donation, uint remainingAmount); // Emmited when the campaign has received a donation
    event CampaignGoalReached(uint id, string name, string description, uint goalAmount, uint expirationTime); // Emmited when the campaign's money goal has been reached
    event CampaignFundsWithdrawn(uint id, string name, string description, uint goalAmount, uint expirationTime); // Emmited when the campaign's money goal has been reached


    /** 
     * @dev Create a Donation Platform .
     */
    constructor() {
        administrator = msg.sender;
    }

    modifier OnlyAdministrator {
        require(
            msg.sender == administrator,
             "Only administrator can call this function."
        );
        _;
    }
    
    /** 
     * @dev Creates a new campaign. May only be called by 'administrator'.
     * @param _name name of the campaign
     * @param _description description of the campaign
     * @param _goal amount in WEI
     * @param _expiresIn number of seconds in which the campaign will finish  
     */
    function createCampaign(string memory _name, string memory _description,  uint _goal, uint _expiresIn) public OnlyAdministrator {

        require(
            _goal > 0,
            "Campaign goal amount cannot be 0."
        );
        require(
            _expiresIn > 0,
            "Campaign cannot last 0 seconds."
        );

        uint expirationTime = block.timestamp + _expiresIn;
        campaigns[campaignsCreated] = Campaign({id : campaignsCreated,
                                                name : _name,
                                                description : _description,
                                                goalAmount : _goal,
                                                receivedAmount : 0,
                                                expirationTime : expirationTime,
                                                fundsWithdrawn : false});
        campaignsCreated += 1;

        emit CampaignCreated(campaignsCreated-1, 
                            _name, 
                            _description, 
                            _goal, 
                            expirationTime);
    }

    /**
     * @dev Donate to the campaign if the time for campaign has not elapsed and goal amount has not been reached
     * @param _campaignId id of the campaign to which donation should be made
     */
    function donate(uint _campaignId) public payable {

        Campaign storage campaign = campaigns[_campaignId];

        require(
            _campaignId < campaignsCreated,
            "Bad campaign ID - cannot donate to the campaigns in the future."
        );
        require(
            msg.value > 0,
            "Cannot donate 0 WEI."
        );
        require(
            campaign.receivedAmount < campaign.goalAmount,
            "Cannot donate - Funds for the campaign have already been gathered."
        );
        require(
            campaign.expirationTime > block.timestamp,
            "Cannot donate - Time for the campaign has expired."
        );

        uint donation; 
        uint refund; 
        uint remainder;

        if(msg.value + campaign.receivedAmount >= campaign.goalAmount) { // cap the donation and setup for the excess funds to be returned

            donation = campaign.goalAmount - campaign.receivedAmount;      
            refund = msg.value - donation;
            remainder = 0;

        } else { // goal will not be reached with this donation

            donation = msg.value;
            refund = 0;
            remainder = campaign.goalAmount - campaign.receivedAmount - donation;

        }

        campaign.receivedAmount += donation;

        if(refund > 0) {
            (bool sent, ) = payable(msg.sender).call{value: refund}("");
            require(sent, "Failed to send the excess amount to the donator.");
        }

        emit CampaignReceivedDonation(campaign.id, 
                                    campaign.name, 
                                    campaign.description, 
                                    campaign.goalAmount,
                                    campaign.expirationTime,
                                    donation,
                                    remainder);

        if(remainder == 0) {
            emit CampaignGoalReached(campaign.id,
                                campaign.name, 
                                campaign.description, 
                                campaign.goalAmount,
                                campaign.expirationTime);
        }
    }

    /**
     * @dev Withdraw from a specific campaign if it that is possible (time or money goal has been reached)
     * @param _campaignId id of the campaign from which to withdraw the funds
     */
    function withdraw(uint _campaignId) public OnlyAdministrator {
        // There can be multiple campaigns at one time. Each campaign has effectively it's own balance
        // It is important to avoid the "Re-Entrance" problem (even though administrator will get all of the money regardless)
        Campaign storage campaign = campaigns[_campaignId];

        require(
            (campaign.expirationTime <= block.timestamp) || (campaign.receivedAmount == campaign.goalAmount),
            "Cannot withdraw - Campaign is not yet finished or the goal has not been reached."
        );

        require(
            campaign.fundsWithdrawn == false,
            "Cannot withdraw - Funds for this campaign have already been withdrawn."
        );

        campaign.fundsWithdrawn = true;
        (bool sent, ) = administrator.call{value: campaign.receivedAmount}("");
        require(sent, "Failed to withdraw.");

        emit CampaignFundsWithdrawn(campaign.id,
                    campaign.name, 
                    campaign.description, 
                    campaign.receivedAmount,
                    campaign.expirationTime);

    }

}