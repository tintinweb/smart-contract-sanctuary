/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract EtherRock {
    function getRockInfo (uint rockNumber) virtual public returns (address, bool, uint, uint);
    function buyRock (uint rockNumber) virtual public payable;
    function sellRock (uint rockNumber, uint price) virtual public;
    function giftRock (uint rockNumber, address receiver) virtual public;
}

contract RockHelperV1 {
    address payable owner;
    EtherRock etherRock = EtherRock(0x37504AE0282f5f334ED29b4548646f887977b7cC);

    constructor () {
        owner = payable(msg.sender);
    }
    
    event PurchaseRock(address purchaser, uint256 rockId, uint256 rockPrice);

    function buy(uint256[] memory ids) public payable {
        for (uint256 i = 0; i < ids.length; i++) {
            address rockOwner;
            bool rockCanBid;
            uint256 rockPrice;
            uint256 rockTimeSold;
            (rockOwner, rockCanBid, rockPrice, rockTimeSold) = etherRock.getRockInfo(ids[i]);

            etherRock.buyRock{value: rockPrice}(ids[i]);
            etherRock.sellRock(ids[i], type(uint256).max);
            etherRock.giftRock(ids[i], msg.sender);
            
            emit PurchaseRock(msg.sender, ids[i], rockPrice);
        }
    }

    receive() external payable {}

    function tip() external payable {}

    function withdraw() external {
        require(msg.sender == owner, "Not owner!");
        owner.transfer(address(this).balance);
    }
}