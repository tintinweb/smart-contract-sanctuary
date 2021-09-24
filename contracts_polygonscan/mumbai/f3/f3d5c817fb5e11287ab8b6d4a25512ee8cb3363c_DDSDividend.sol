/**
 *Submitted for verification at polygonscan.com on 2021-09-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract DDSDividend is Context {
    mapping(address => uint256) private _funds;

    function fundsOf(address payee) public view returns (uint256) {
        return _funds[payee];
    }

    function depositFunds(address[] memory payees, uint256[] memory shares) public payable {
        require(payees.length == shares.length, "DDSDividend: payees and shares length mismatch");
        require(payees.length > 0, "DDSDividend: no payees");

        uint256 _depositedFunds = msg.value;
        uint256 _totalShares = 0;

        for (uint256 i = 0; i < shares.length; i++) {
            _totalShares = _totalShares + shares[i];
        }

        for (uint256 i = 0; i < payees.length; i++) {
            _funds[payees[i]] = _depositedFunds * (shares[i] / _totalShares);
        } 
    } 
}