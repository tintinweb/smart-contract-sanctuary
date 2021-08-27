// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

//  _ __   ___  __ _ _ __ ______ _ _ __  
// | '_ \ / _ \/ _` | '__|_  / _` | '_ \ 
// | |_) |  __/ (_| | |   / / (_| | |_) |
// | .__/ \___|\__,_|_|  /___\__,_| .__/ 
// | |                            | |    
// |_|                            |_|    

// https://pearzap.com/

// Get average block duration

import "./SafeMath.sol";

contract GetAverageBlockDuration {
    using SafeMath for uint256;
    
    uint256 public lastBlockUpdate;
    uint256 public lastTimeUpdate;
    
    constructor(
    ) public {
        lastBlockUpdate = block.number;
        lastTimeUpdate = block.timestamp;
    }
    
    
    function updateLastBlock() public {
        // at least 4000 block between 2 updates
        require(block.number > lastBlockUpdate+4, 'can t update now'); // TODO Set to 4000
        lastBlockUpdate = block.number;
        lastTimeUpdate = block.timestamp;
    }    
    
    function getAverageBlockDuration() public view returns (uint256 _numberOfblock, uint256 _averageDuration, uint256 _actualTime, uint256 _actualBlock) {
        _actualBlock = block.number;
        _actualTime = block.timestamp;
        
        _numberOfblock = _actualBlock-lastBlockUpdate;
        _averageDuration = ((_actualTime.sub(lastTimeUpdate)).mul(1e18)).div(_numberOfblock);

        return (_numberOfblock, _averageDuration, _actualTime, _actualBlock);
    }

}