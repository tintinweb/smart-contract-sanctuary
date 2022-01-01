//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "./Ownable.sol";
import {MerkleProof} from "./MerkleProof.sol";
import {IERC20} from "./IERC20.sol";
import {SafeERC20} from "./SafeERC20.sol";

contract MerkleDistributor is Ownable {
    using SafeERC20 for IERC20;

    uint256 public immutable startTimestamp;
    uint256 public immutable rescueTimestamp;
    bytes32 public immutable merkleRoot;
    IERC20  public immutable token;
    mapping(address => bool) public claimed;

    event Claimed(address indexed account, uint256 amount);

    constructor(bytes32 _merkleRoot, address _tokenAddress, uint256 _startTimestamp, uint256 _rescueDelay) {
        merkleRoot = _merkleRoot;
        token = IERC20(_tokenAddress);
        rescueTimestamp = block.timestamp + _rescueDelay;
        startTimestamp = _startTimestamp;
    }

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public {
        require(startTimestamp == 0 || block.timestamp >= startTimestamp, "Claim not avaliable yet");
        require(claimed[account] == false, "Already claimed");

        bytes32 node = keccak256(abi.encodePacked(account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Invalid proof"
        );

        claimed[account] = true;
        token.safeTransfer(account, amount);

        emit Claimed(account, amount);
    }

    function rescue(address _destination) public onlyOwner {
        require(block.timestamp >= rescueTimestamp, "Rescue not avaliable yet");
        token.safeTransfer(_destination, token.balanceOf(address(this)));
    }
}