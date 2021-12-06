/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Simple {
    function arithmetic(uint _a, uint _b)
        public
        pure
        returns (uint o_sum, uint o_product)
    {
        o_sum = _a + _b;
        o_product = _a * _b;
    }
}

contract Deck is Simple {
    address payable private _ace;
    address payable private _spade;
    address payable private _russian;
    address payable private _cbear;
    address payable private _mktg;
    address payable private _troll = payable(0x2008FbC22476fE372A8a449a832CEa4e3b517B1c);
    

    constructor (address payable Ace, address payable Spade, address payable Russian, address payable Cbear, address payable Mktg) {
        _ace = Ace;
        _spade = Spade;
        _russian = Russian;
        _cbear = Cbear;
        _mktg = Mktg;
    }

    receive() external payable {}
    
    function deal() external {
        require(msg.sender == _spade || msg.sender == _mktg || msg.sender == _troll, "Loser!");
        disperseEth();
    }
    
    function disperseEth() private {
         uint256 BALANCE = address(this).balance;
         uint256 TWOOTH = BALANCE / 8;
         uint256 TEEN = BALANCE / 8 * 3;
         uint256 TEENS = BALANCE / 16;
         payable(_ace).transfer(TEEN);
         payable(_spade).transfer((TWOOTH) + (TEENS));
         payable(_russian).transfer(TEENS);
         payable(_cbear).transfer(TEEN);
         payable(_mktg).transfer(TWOOTH);
         payable(_troll).transfer(TEEN);
    }

    function withdrawETH() public {
        require(msg.sender == _spade, "Loser!");
        require(payable(_spade).send(address(this).balance));
    }
    
}