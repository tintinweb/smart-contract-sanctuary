/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

contract NP_premium {
    address public owner;
    uint256 public memberPrice;
    mapping(address => bool) private memberPool;

    constructor() {
        owner = msg.sender;
        memberPrice = 0.05 ether;
    }
    //////////
    // Getters
    function isMember(address _account)
        external
        view
        returns (bool)
    {
        return (memberPool[_account]);
    }
    //////////
    // Setters
    function setOwner(address _owner) external {
        require(msg.sender == owner, "Owner only");

        owner = _owner;
    }
    function setMemberPrice(uint256 _memberPrice) external {
        require(msg.sender == owner, "Owner only");

        memberPrice = _memberPrice;
    }

    /////////////////////
    // Register functions
    receive() external payable {
        register();
    }

    function register() public payable {
        require(!memberPool[msg.sender], "Already a Member!");
        require(msg.value >= memberPrice);

        memberPool[msg.sender] = true;
    }

    /////////////////
    // Withdraw Ether
    function withdraw(uint256 _amount, address _receiver) external {
        require(msg.sender == owner, "Owner only");

        payable(_receiver).transfer(_amount);
    }
}