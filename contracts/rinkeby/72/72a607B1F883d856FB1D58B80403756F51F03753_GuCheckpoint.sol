/**
 *Submitted for verification at Etherscan.io on 2021-08-05
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

contract GuCheckpoint is Ownable {
    uint256 lastCheckpointNumber;
    mapping(uint256 => Checkpoint) checkpoints;
    
    struct Checkpoint {
        bool exist;
        uint256 checkpointNumber;
        bytes32 checkpointHash;
        bytes32 parentHash;
        bytes32 blocksRoot;
    }

    function checkpoint(uint256 _checkpointNumber, bytes32 _checkpointHash, bytes32 _parentHash, bytes32 _blocksRoot) external onlyOwner {
        if(_checkpointNumber == 0) {
            require(checkpoints[_checkpointNumber - 1].exist, 'previous checkpoint does not exist');
            require(checkpoints[_checkpointNumber - 1].checkpointHash == _parentHash, 'parentHash does not match');
            checkpoints[_checkpointNumber] = Checkpoint(
                true,
                _checkpointNumber,
                _checkpointHash,
                _parentHash,
                _blocksRoot
            );
        } else {
            checkpoints[_checkpointNumber] = Checkpoint(
                true,
                _checkpointNumber,
                _checkpointHash,
                0x0,
                _blocksRoot
            );
        }
    }
}