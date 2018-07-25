pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// HODL Ethereum
//
// Pulled from URL: hodlethereum.com
// GitHub: https://github.com/apguerrera/hodl_ethereum
//
// Enjoy.
//
// (c) Adrian Guerrera / Deepyr Pty Ltd and
// HODL Ethereum Project - 2018. The MIT Licence.
// ----------------------------------------------------------------------------

contract hodlEthereum {
    event Hodl(address indexed hodler, uint indexed amount);
    event Party(address indexed hodler, uint indexed amount);
    mapping (address => uint) public hodlers;

    // Set party date -  1st Sept 2018
    uint constant partyTime = 1535760000;

    // Deposit Funds
    function hodl() payable public {
        hodlers[msg.sender] += msg.value;
        emit Hodl(msg.sender, msg.value);
    }

    // Withdrawl Funds
    function party() public {
        require (block.timestamp > partyTime && hodlers[msg.sender] > 0);
        uint value = hodlers[msg.sender];
        hodlers[msg.sender] = 0;
        msg.sender.transfer(value);
        emit Party(msg.sender, value);
    }
}