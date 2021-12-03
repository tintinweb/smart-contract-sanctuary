/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// SPDX-License-Identifier: MIT
//Team Stardust-Isitcom

pragma solidity ^0.8.0;

contract MintNFT {

    address public owner;
    uint256 public price;
    uint256 public tokenID;
    


    constructor(uint256 _price,uint256 _tokenID) {
        owner = msg.sender;
        price=_price;
        tokenID=_tokenID;
    }

    function mintNFT() external payable {

    if(msg.value < price){
            revert("prix insuffisant");
            }

            owner=msg.sender;
            price=msg.value;   
   }   

}