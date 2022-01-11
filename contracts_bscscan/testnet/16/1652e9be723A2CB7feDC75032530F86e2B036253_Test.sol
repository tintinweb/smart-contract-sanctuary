/**
 *Submitted for verification at BscScan.com on 2022-01-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Test {
    mapping(uint256 => string) private path;
    string public basePath;

    event BasePathUpdated(address indexed from, string indexed basePath);
    event PathUpdated(address from, uint256 id, string path);

    constructor(string memory _basePath) {
	    basePath = _basePath;
    }

    function setBasePath(string calldata _basePath) external {
    	basePath = _basePath;
    	emit BasePathUpdated(msg.sender, basePath);
    }

    function setPath(uint256 _id, string calldata _path) external {
    	path[_id] = _path;	
        emit PathUpdated(msg.sender, _id, _path);
    }

    function getPath(uint256 id) external view returns(string memory) {
    	return string(abi.encodePacked(basePath, path[id]));
    }
}