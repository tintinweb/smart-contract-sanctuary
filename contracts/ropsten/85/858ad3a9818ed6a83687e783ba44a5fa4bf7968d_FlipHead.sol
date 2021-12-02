/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract FlipHead {

    address public player;
    uint256 betSize = 0.001 ether;
    uint256 public STATE = 0;

    function isHeads() public view returns(uint256){
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number))) % 2;
        return random;
    }

    function makeBet(uint256 _choice) external payable {
        require((msg.value >= 1000000000000000), "use this function with more ether");
        player = msg.sender;
        if(_choice == isHeads())
        {
            payable(player).transfer(address(this).balance);
            STATE++;
        }
    }
}