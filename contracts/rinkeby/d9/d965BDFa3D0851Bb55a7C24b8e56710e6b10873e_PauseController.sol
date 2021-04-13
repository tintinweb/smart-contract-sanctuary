/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

//SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.6;

contract PauseController {
    address public manager;
    bool internal paused;
    bytes32 private immutable ID;
    
    constructor (string memory _id, address _manager) {
        require(bytes(_id).length <= 32);
        bytes32 id;
        assembly {
            id := mload(add(_id, 32))
        }
        ID = id;
        
        manager = _manager;
    }
    
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
    
    function changeManager(address _newmanager) external onlyManager {
        require(_newmanager != address(0));
        manager = _newmanager;
    }
    
    function pause() external onlyManager {
        paused = true;
    }

    function play() external onlyManager {
        paused = false;
    }
    
    function isPaused() external view returns(bool) {
        return paused;
    }
    
    function id() external view returns(string memory) {
        return string(abi.encodePacked(ID));
    }
    
}