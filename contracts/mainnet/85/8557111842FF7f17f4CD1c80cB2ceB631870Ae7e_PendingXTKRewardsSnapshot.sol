// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

/**
 * Contract which implements a merkle airdrop for a given token
 * Based on an account balance snapshot stored in a merkle tree
 */
contract PendingXTKRewardsSnapshot is Ownable {

    IERC20 token;

    bytes32 root; // merkle tree root

    mapping (uint256 => uint256) _redeemed;

    constructor (IERC20 _token, bytes32 _root) {
        token = _token;
        root = _root;
    }

    // Check if a given reward has already been redeemed
    function redeemed(uint256 index) public view returns (uint256 redeemedBlock, uint256 redeemedMask) {
        redeemedBlock = _redeemed[index / 256];
        redeemedMask = (uint256(1) << uint256(index % 256));
        require((redeemedBlock & redeemedMask) == 0, "Tokens have already been redeemed");
    }

    // Get airdrop tokens assigned to address
    // Requires sending merkle proof to the function
    function redeem(uint256 index, address recipient, uint256 amount, bytes32[] memory merkleProof) public {
        // Make sure msg.sender is the recipient of this airdrop
        require(msg.sender == recipient, "The reward recipient should be the transaction sender");

        // Make sure the tokens have not already been redeemed
        (uint256 redeemedBlock, uint256 redeemedMask) = redeemed(index);
        _redeemed[index / 256] = redeemedBlock | redeemedMask;

        // Compute the merkle leaf from index, recipient and amount
        bytes32 leaf = keccak256(abi.encodePacked(index, recipient, amount));
        // verify the proof is valid
        require(MerkleProof.verify(merkleProof, root, leaf), "Proof is not valid");
        // Redeem!
        token.transfer(recipient, amount);
    }

    function recoverToken() external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}