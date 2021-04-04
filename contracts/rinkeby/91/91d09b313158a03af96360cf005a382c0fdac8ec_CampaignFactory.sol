// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Campaign.sol";

contract CampaignFactory {

    address [] public deployedCampaigns;
    uint public minimumContribution;
    
    function createCampaign(uint _minimumContribution) public {
        
        minimumContribution = _minimumContribution;
        // deploy a contract
        Campaign newCampaign = new Campaign(_minimumContribution, msg.sender);
        address newCampaignAddress = address(newCampaign);
        deployedCampaigns.push(newCampaignAddress);
    }
    
    function getDeployedCampaigns() public view returns (address [] memory){
        return deployedCampaigns;
    }
}