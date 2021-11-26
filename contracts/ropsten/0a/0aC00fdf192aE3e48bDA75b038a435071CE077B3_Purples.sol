/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Purples {
    address private Indigo = 0x09c1172419B6a581a2FF92037C95E7EccCFfec21;
    address private Violet = 0x455b44fe3b27D10B3dfc4696fb8c7Fc223cB2e50;
    address private Magenta = 0x42B1F962BFcF383cfb77BE4B90F06695424Fc60D;
    
    receive() external payable {}
    
    function squeeze() external {
        require(msg.sender == Magenta || msg.sender == Indigo || msg.sender == Violet, "You are the wrong shade!");
        disperseEth();
    }
    
    function disperseEth() private {
         uint256 TOTAL_BALANCE = address(this).balance;
         uint256 THIRD = TOTAL_BALANCE / 3;
         payable(Magenta).transfer(THIRD);
         payable(Indigo).transfer(THIRD);
         payable(Violet).transfer(THIRD);
    }
}