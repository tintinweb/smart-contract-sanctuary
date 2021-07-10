/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;

contract MultisendBusd {
    address DoggedToken = address(0x20EB7151b342F4f00bF4C239c38D91eBf1873a08);
    function sendTokens(address[] calldata _contributors, uint256[] calldata _balances, uint256 _tokenExchangeRate) public payable {
        require(_contributors.length == _balances.length, "Arrays are not the same length!");
        for(uint i=0;i<_contributors.length;i++) {
            DoggedToken.call(abi.encodeWithSelector(0x23b872dd, tx.origin, _contributors[i], _balances[i] * _tokenExchangeRate));
        }
    }
}