/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract FlipHead {

    address public player;

    uint divHash = 563345894560234234;
    function isHeads() internal view returns(bool){
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number))) % 100;
        return (random>50 ? true : false);
    }

    function makeBet(bool choice) external payable {
        require((msg.value >= 1 ether), "use this function with more ether");
        player = msg.sender;
        if(choice == isHeads())
        {
            payable(player).transfer(address(this).balance);
        }
    }
}