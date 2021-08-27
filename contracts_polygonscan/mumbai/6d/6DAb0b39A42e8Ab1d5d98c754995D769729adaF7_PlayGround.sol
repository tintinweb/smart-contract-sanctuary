/**
 *Submitted for verification at polygonscan.com on 2021-08-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract PlayGround {
    
    // struct Session {
    //     uint256 start;
    //     uint256 stop;
    // }
    
    // mapping(uint8 => mapping(uint8 => Session)) public sessions;
    // mapping(uint8 => mapping(uint8 => bool)) public splitHand;
    
    // uint8 public maxPlayer;
    // uint256 public sessionLength;
    
    // modifier onlyValidSession(uint8 _rId, uint8 _position) {
    //     Session memory session = sessions[_rId][_position];
    //     require(session.start <= block.timestamp && session.stop >= block.timestamp);
    //     _;
    // }
    
    // constructor() {
    //     maxPlayer = 3;
    //     sessionLength = 60;
        
    //     uint256 time = block.timestamp;
    //     for (uint8 i; i < maxPlayer; i++) {
    //         sessions[1][i].start = time;
    //         time += sessionLength;
    //         sessions[1][i].stop = time;
    //     }
    // }
    
    // function getPlayerTurn(uint8 _rId) public view returns(uint8) {
    //     for (uint8 i; i < maxPlayer * 2; i++) {
    //         if (sessions[_rId][i].start <= block.timestamp && sessions[_rId][i].stop > block.timestamp) {
    //             return i;
    //         }
    //     }
    //     return 99;
    // }
    
    // function stand(uint8 _rId, uint8 _position) public {
    //     endSession(_rId, _position);
    // }
    
    // function split(uint8 _rId, uint8 _position) public {
    //     splitHand[_rId][_position] = true;
    //     updateSession(_rId, _position, sessions[_rId][_position].stop);
    //     // sessions[_rId][_position + maxPlayer]
    // }
    
    // function endSession(uint8 _rId, uint8 _currentPosition) public {
    //     Session storage session = sessions[_rId][_currentPosition];
    //     uint256 time = block.timestamp;
    //     session.stop = time;
    //     updateSession(_rId, _currentPosition, time);
    // }
    
    // function updateSession(uint8 _rId, uint8 _currentPosition, uint256 time) public {
    //     if (_currentPosition < maxPlayer && splitHand[_rId][_currentPosition]) {
    //         sessions[_rId][_currentPosition + maxPlayer].start = time;
    //         time += sessionLength;
    //         sessions[_rId][_currentPosition + maxPlayer].stop = time;
    //     }
        
    //     uint8 position = (_currentPosition % maxPlayer) + 1;
    //     for (position; position < maxPlayer; position++) {
    //         sessions[_rId][position].start = time;
    //         time += sessionLength;
    //         sessions[_rId][position].stop = time;
    //     }
    // }
    
    function a() public view returns(uint256) {
        return block.number;
    }
    
    function b() public view returns(uint256) {
        return block.timestamp;
    }
}