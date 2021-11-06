/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract test {
    
    Position[] Positions;
    mapping (uint256 => bool) isOpen;
    struct Position {
        address _user;
        uint256 _amountInWithoutFee;
        uint256 _amountIn; // amount of in token that user deposited minus fee
        uint256 _price;
    }
    
    function fill() external {
        for (uint256 i=0; i<2000; i++) {
            Position memory _Position = Position(msg.sender, 10000, 20000, 123123123);
            Positions.push(_Position);
        }
    }
    
    function liquidatePositionsMemory() external {
        Position[] memory _Positions = Positions;
        
        for (uint256 i=210; i<220; i++) {
            _Positions[i]._price += 1;
            isOpen[i] = true;
        }
    }
    
    function liquidatePositionsStorage() external {
        for (uint256 i=230; i<240; i++) {
            Positions[i]._price += 1;
            isOpen[i] = true;
        }
    }
}