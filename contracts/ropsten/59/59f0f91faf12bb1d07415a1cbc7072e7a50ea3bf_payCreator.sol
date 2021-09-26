/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract payCreator
{
    address public contractCreator; 
    uint256 tokenCounter;
    uint mintingPrice;

    constructor() {
        contractCreator = msg.sender;
        mintingPrice = 0.01 ether;
    }

    function payMe() payable public {
        require(msg.value == mintingPrice, "Pay for minting");
    }

    function setMintingPrice(uint price) public{
        require(msg.sender == contractCreator, "only creator can set price");
        mintingPrice = price;
    }

    function withDrawEth(uint amount) public {
        require(msg.sender==contractCreator);
        payable(contractCreator).transfer(amount);
    }
}