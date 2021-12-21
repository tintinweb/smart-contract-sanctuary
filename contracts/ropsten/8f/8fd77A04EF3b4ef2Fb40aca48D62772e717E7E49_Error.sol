/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract Error {
    function testRequire(uint _i) public pure {
        require(_i > 10 , "Input must be greater than 10");
    }

    function testRevert(uint _i) public pure {
        //  this code does the same as the testRequire
        if (_i < 10) {
            revert("Input must be greater than 10");
        }
    }

    uint public num;
    function testAssert() public view {
        //  assert that num is always equal to 0
        //  since it is impossible to update the value of num
        assert(num == 0);
    }

    //  custom error
    error InsufficientBalance(uint balance, uint withdrawAmount);   //  Insufficient 不充分的
    event Log(uint message);

    function testCustomError(uint _withdrawAmount) public  {
        uint bal = address(this).balance;
        emit Log(bal);
        //  if balance is not enough to withdraw
        if (bal < _withdrawAmount) {
            //  revert error
            revert InsufficientBalance(bal,  _withdrawAmount);
        }
    }
}