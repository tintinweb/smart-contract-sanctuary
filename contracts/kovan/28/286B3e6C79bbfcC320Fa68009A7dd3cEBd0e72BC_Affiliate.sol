// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Affiliate {

    uint256 public affiliateReward = 5;

    mapping(string => uint256) public nameToBalance;
    mapping(string => bool) public userExists;

    function addPersonWithAffiliate(string memory _name, uint256 _balance, string memory affiliateName) public{
        require(userExists[affiliateName], "Inviter not found.");
        require(!userExists[_name], "Invitee already in contract.");
        nameToBalance[affiliateName] = nameToBalance[affiliateName] + affiliateReward;
        nameToBalance[_name] = _balance;
        userExists[_name] = true;
    }

    function addPerson(string memory _name, uint256 _balance) public{
        require(!userExists[_name], "Invitee already in contract.");
        nameToBalance[_name] = _balance;
        userExists[_name] = true;
    }

    function setAffiliateReward(uint256 newAffiliateReward) public{
        require(newAffiliateReward > 0, "Need a number greater than zero.");
        affiliateReward = newAffiliateReward;
    }

}