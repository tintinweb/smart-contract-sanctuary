/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

pragma solidity ^0.8.0;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "msg.sender is not the owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "new owner is the zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract AltChainCheckpoint is Ownable {
    function checkpoint(uint256 _checkpointNumber, bytes32 _checkpointHash, bytes32 _parentHash, bytes32 _blocksRoot, bytes32 _previousTxHash) external onlyOwner {
        // Checkpoint is written as Calldata
    }
}