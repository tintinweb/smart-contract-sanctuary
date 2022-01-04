/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Test {

    mapping(address => mapping(uint256 => uint256[])) public _phrases;
    mapping(address => uint256) public _phrasesIds;

    function addPhrase(address account, uint256[] memory tokenIds) public {
        uint256 nextPId = _phrasesIds[account] + 1;
        _phrases[account][nextPId] = tokenIds;
        _phrasesIds[account] = nextPId;
    }

    function getPhrase(address account, uint256 phraseId) public view returns (uint256[] memory) {
        return _phrases[account][phraseId];
    }
}