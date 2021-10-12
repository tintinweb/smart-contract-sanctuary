/**
 *Submitted for verification at polygonscan.com on 2021-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract BulkTransfer {
    address public owner;
    uint256 public airdropAmount;
    
    event ReceivedMatic(address _sender, uint _amount);

    constructor() {
        owner = msg.sender;
        airdropAmount = 50000000000000000;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    function changeOwner(address newOwner)
        external
        onlyOwner
    {
        owner = newOwner;
    }
    
    function changeAirdropAmount(uint256 newAirdropAmount)
        external
        onlyOwner
    {
        airdropAmount = newAirdropAmount;
    }
    
    function getAirdropAmount() external view returns (uint256)
    {
        return airdropAmount;
    }


    function transferMaticBulk(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            payable(addresses[i]).transfer(airdropAmount);
        }
    }

    // Transfer ETH held by this contract to the sender/owner.
    function withdrawMatic(uint256 amount)
        external
        onlyOwner
    {
        payable(msg.sender).transfer(amount);
    }
    
    function receiveMatic()
        public
        payable
    {
        //All validation for Matic specific transaction
        emit ReceivedMatic(msg.sender, msg.value);
    }

}