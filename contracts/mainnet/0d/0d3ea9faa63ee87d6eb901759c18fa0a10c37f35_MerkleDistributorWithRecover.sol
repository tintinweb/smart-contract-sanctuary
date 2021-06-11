// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";

import "./MerkleDistributor.sol";

contract MerkleDistributorWithRecover is MerkleDistributor {
    using SafeERC20 for IERC20;

    address immutable public owner;
    uint256 immutable public startTime;
    uint256 constant public DELAY = 1 days * 45;

    constructor(address owner_, address token_, bytes32 merkleRoot_) MerkleDistributor(token_, merkleRoot_) {
        owner = owner_;
        startTime = block.timestamp;
    }

    function recoverERC20(address _token) public {
        require(msg.sender == owner, "only-owner");
        require(block.timestamp >= startTime + DELAY, "not-recoverable");

        IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }
}