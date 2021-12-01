/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Cards {
    address payable public _ace;
    address payable public _spade;
    address payable public _club;

    constructor (address payable Ace, address payable Spade, address payable Club) {
        _ace = Ace;
        _spade = Spade;
        _club = Club;
    }

    receive() external payable {}
    
    function deal() external {
        require(msg.sender == _ace || msg.sender == _spade || msg.sender == _club, "Loser!");
        disperseEth();
    }
    
    function disperseEth() private {
         uint256 BALANCE = address(this).balance;
         uint256 THIRD = BALANCE / 5;
         uint256 TWOOTH = BALANCE / 5 * 2;
         payable(_ace).transfer(TWOOTH);
         payable(_spade).transfer(TWOOTH);
         payable(_club).transfer(THIRD);
         
    }

    function updateAce(address payable Ace) external {
        require(msg.sender == _ace || msg.sender == _spade, "Loser!");
        _ace = Ace;
    }

    function updateSpade(address payable Spade) external {
        require(msg.sender == _ace || msg.sender == _spade, "Loser!");
        _spade = Spade;
    }

    function updateBB(address payable Club) external {
        require(msg.sender == _ace || msg.sender == _spade, "Loser!");
        _club = Club;
    }
}