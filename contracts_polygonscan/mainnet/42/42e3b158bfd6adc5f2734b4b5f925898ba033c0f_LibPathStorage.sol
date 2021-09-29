/**
 *Submitted for verification at polygonscan.com on 2021-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library LibPathStorage {
    
    uint constant private MAX_PATH = 5;
    
    function _setPath(mapping(bytes32 => address[MAX_PATH]) storage _paths, address[] memory _path) public {
        assert(_path.length > 0 && _path.length <= MAX_PATH);
        
        bytes32 hashAB = keccak256(abi.encodePacked(_path[0],_path[_path.length - 1]));
        bytes32 hashBA = keccak256(abi.encodePacked(_path[_path.length - 1],_path[0]));
        for(uint i; i < _path.length; i++) {
            _paths[hashAB][i] = _path[i];
            _paths[hashBA][_path.length - 1 - i] = _path[i];
        }
    }
    function getPath(mapping(bytes32 => address[MAX_PATH]) storage _paths, address a, address b) public view returns (address[] memory path) {
        bytes32 hashAB = keccak256(abi.encodePacked(a, b));
        address[MAX_PATH] storage _path = _paths[hashAB];
        path = new address[](MAX_PATH);
        
        for (uint i; i < MAX_PATH; i++) {
            path[i] = _path[i];
            if (path[i] == address(0)) {
                assembly { path := i } //reduce length
                break;
            }
        }
        require(path.length > 0, "path not found");
    }
}