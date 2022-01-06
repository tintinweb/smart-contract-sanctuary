/**
 *Submitted for verification at polygonscan.com on 2022-01-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ReceivePayment {

    // This variable stores the contracts own address and is set upon creation.
    address immutable private _ownaddress;
    uint256 _previousBalance;

    constructor() {
        _ownaddress = address(this);
        _previousBalance = address(this).balance;
    }

    function getaddress() public view returns (address) {
        return _ownaddress;
    }

    function receivepayment() public payable returns (uint256[2] memory){
        uint256[2] memory returnvalue;
        returnvalue = [_previousBalance, _ownaddress.balance];
        _previousBalance = _ownaddress.balance;
        return returnvalue;
    }
}