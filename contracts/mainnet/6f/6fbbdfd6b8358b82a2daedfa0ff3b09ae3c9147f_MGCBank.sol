/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract MGCBank {
    address payable public _team;
    address payable public _mktg;

    constructor (address payable Team, address payable Mktg) {
        _team = Team;
        _mktg = Mktg;
    }

    receive() external payable {}
    
    function disburse() external {
        require(msg.sender == _team || msg.sender == _mktg, "Nice Try!");
        disperseEth();
    }
    
    function disperseEth() private {
         uint256 BALANCE = address(this).balance;
         uint256 THIRD = BALANCE / 3;
         uint256 TWOOTH = BALANCE / 3 * 2;
         payable(_mktg).transfer(THIRD);
         payable(_team).transfer(TWOOTH);
         
    }
}