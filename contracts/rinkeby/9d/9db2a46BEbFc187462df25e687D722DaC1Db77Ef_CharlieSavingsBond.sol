/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract CharlieSavingsBond {
    address public charlie;
    uint256 public blockNumberEligibleToWithdraw;

    constructor(address _charlie, uint256 _blockNumberEligibleToWithdraw){
        charlie = _charlie;
        blockNumberEligibleToWithdraw = _blockNumberEligibleToWithdraw;
    }

    receive() external payable { }

    function withdraw() external payable {
        require(msg.sender == charlie, 'Only Charlie can withdraw');
        require(block.number >= blockNumberEligibleToWithdraw, 'Charlie is still a baby and cannot withdraw yet');
        payable(msg.sender).transfer(address(this).balance);
    }
}