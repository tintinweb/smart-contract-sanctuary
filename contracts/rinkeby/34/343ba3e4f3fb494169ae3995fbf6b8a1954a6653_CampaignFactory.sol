// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

import "./Campaign.sol";

contract CampaignFactory {
    address[] public deployedCampaigns;


    function  createCampaign(uint minium) public {
        Campaign newCampaign = new Campaign(minium, msg.sender);
        deployedCampaigns.push(address(newCampaign));
    }

    function getDeployedCampaigns() public view returns(address[] memory) {
        return deployedCampaigns;
    }
}