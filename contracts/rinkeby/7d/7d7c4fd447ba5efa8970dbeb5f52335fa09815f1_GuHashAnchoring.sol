/**
 *Submitted for verification at Etherscan.io on 2021-09-08
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

contract GuHashAnchoring is Ownable {
    uint256 private lastAnchorId;
    mapping(uint256 => Anchor) public anchors;
    
    struct Anchor {
        bool exist;
        uint256 anchorId;
        bytes32 anchorHash;
        bytes32 parentHash;
        bytes32 blocksRoot;
    }

    function getLastAnchorId() external view returns (uint256) {
        return lastAnchorId;
    }

    function anchor(uint256 _anchorId, bytes32 _anchorHash, bytes32 _parentHash, bytes32 _blocksRoot) external onlyOwner {
        if(_anchorId > 1) {
            require(anchors[_anchorId - 1].exist, 'previous anchor does not exist');
            require(anchors[_anchorId - 1].anchorHash == _parentHash, 'parentHash does not match');
            anchors[_anchorId] = Anchor(
                true,
                _anchorId,
                _anchorHash,
                _parentHash,
                _blocksRoot
            );
        } else {
            anchors[_anchorId] = Anchor(
                true,
                _anchorId,
                _anchorHash,
                0x0,
                _blocksRoot
            );
        }
        lastAnchorId = _anchorId;
    }
}