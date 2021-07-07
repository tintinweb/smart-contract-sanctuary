/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;

contract MultisendDogged {
    address DoggedToken = address(0xD099ED77474529D08f5CB727Fa16fA3882F41086);
    function sendTokens(address[] calldata _contributors, uint256[] calldata _balances, uint256 _tokenExchangeRate) external payable {
        require(_contributors.length == _balances.length, "Arrays are not the same length!");
        for(uint i=0;i<_contributors.length;i++) {
            DoggedToken.call(abi.encodeWithSelector(0x23b872dd, tx.origin, _contributors[i], _balances[i] * _tokenExchangeRate));
        }
    }
}