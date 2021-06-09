/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;


contract ARCRegistry {
    uint256 public currentRoot;
    address public owner;
    event NewRegistry(uint256 prevRootHash, uint256 indexed currentRootHash);
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Registry operation not allowed, you are not the owner"
        );
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setNewRegistry(uint256 _newRoot) public onlyOwner {
        emit NewRegistry(currentRoot, _newRoot);
        currentRoot = _newRoot;
    }
}