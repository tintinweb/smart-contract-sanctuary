/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.25;

contract ImplementationV1 {
    
    mapping(uint256 => uint256) private uint256Params;
    
    function getVal(uint256 key) public view returns (uint256) {
        return uint256Params[key] + 33;
    }
    
    function setVal(uint256 key, uint256 value) public payable {
        uint256Params[key] = value;
    }
 
    // function addPlayer(address _player, uint _points) public onlyOwner {
    //     require (points[_player] == 0);
    //     points[_player] = _points;
    // }
    // function setPoints(address _player, uint _points) public onlyOwner {
    //     require (points[_player] != 0);
    //     points[_player] = _points;
    // }
}