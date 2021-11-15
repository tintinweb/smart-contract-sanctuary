/**
 *Submitted for verification at polygonscan.com on 2021-11-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Donation {
    
    // Store campaign data
    struct Campaign {
        address payable reciever;
        string reason;
        uint amount;
    }
    
    // Map using campaign name as key
    mapping(string => Campaign) public campaign;
    
    // Let user create campaign
    function createCampaign(string memory _name, address payable _reciever, string memory _reason, uint _amount) public {
        campaign[_name].reciever = _reciever;
        campaign[_name].reason = _reason;
        campaign[_name].amount = _amount;
    }
    
    // Get campaign address from campaign name
    function getCampaignAddress(string memory name) public view returns(address) {
        return campaign[name].reciever;
    }
    
    // Let user donate to campaign
    function donateToCampaign(string memory _campaignName) public payable {
        require(msg.value > 0, "Value cannot be zero");
        require(campaign[_campaignName].amount > 0, "Campaign closed");
        require(campaign[_campaignName].amount >= msg.value, "Donated more than needed");
        transfer(campaign[_campaignName].reciever, msg.value);
        campaign[_campaignName].amount -= msg.value;
    }
    
    // Transfer money to wallet
    function transfer(address payable _reciever, uint _amount) private {
        (bool success, ) = _reciever.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }
    
}