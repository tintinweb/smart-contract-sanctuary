/**
 *Submitted for verification at polygonscan.com on 2022-01-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ReceivePaymentAndTransfer {

    // This variable stores the contracts own address and is set upon creation.
    address immutable private _ownaddress;
    uint256 _previousBalance;
    address _recipient;

    constructor() {
        _ownaddress = address(this);
        _previousBalance = address(this).balance;
        _recipient = address(0);
    }

    function getaddress() public view returns (address) {
        return _ownaddress;
    }

    function getprevbalance() public view returns (uint256) {
        return _previousBalance;
    }

    function getRecipient() public view returns (address) {
        return _recipient;
    }

    function receivepayment(address recipient) public payable {
        require(msg.value >= 0.001 ether, "Value too low");
        _recipient = recipient;
        payable(address(_recipient)).transfer( msg.value - msg.value/10 );
    } 
}