pragma solidity ^0.4.11;
contract crowdFund {
    // Defines a new struct type that has two fields.
    struct Backer {
        address addr;
        uint fundAmount;
    }
    struct crowdFundingCampaign {
        address beneficiaryAddress;
        uint fundGoal;
        uint numBacker;
        uint fundAmount;
        mapping (uint => Backer) backers;
    }
    uint numCrowdFundingCampaigns;
    mapping (uint => crowdFundingCampaign) crowdFundingCampaigns;
    function newCrowdFundingCampaign(address beneficiaryAddress, uint goal) returns (uint crowdFundingCampaignID) {
        crowdFundingCampaignID = numCrowdFundingCampaigns++; // crowdFundingCampaignID is a return variable
        // Create new struct and save in storage, leaving out the mapping type.
        crowdFundingCampaigns[crowdFundingCampaignID] = crowdFundingCampaign(beneficiaryAddress, goal, 0, 0);
    }
    function contribute(uint crowdFundingCampaignID) payable {
        crowdFundingCampaign storage c = crowdFundingCampaigns[crowdFundingCampaignID];
        // Create a new temporary memory struct, initialise with values that are given
        // and copy it over to storage.
        // Note that you can also use Backer(msg.sender, msg.value) for initializing.
        c.backers[c.numBacker++] = Backer({addr: msg.sender, fundAmount: msg.value});
        c.fundAmount += msg.value;
    }
    function checkGoalReach(uint crowdFundingCampaignID) returns (bool reached) {
        crowdFundingCampaign storage c = crowdFundingCampaigns[crowdFundingCampaignID];
        if (c.fundAmount < c.fundGoal)
            return false;
        uint fundAmount = c.fundAmount;
        c.fundAmount = 0;
        c.beneficiaryAddress.transfer(fundAmount);
        return true;
    }
}