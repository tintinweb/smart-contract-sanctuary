pragma solidity ^0.8.0;

/** This is a slightly modified version of: https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol
 *
 */

import "MerkleProof.sol";
import "IERC20.sol";

contract KacoAirDrop {
    address immutable public token;
    bytes32 immutable public merkleRoot;
   
    // This is a packed array of booleans
    mapping(uint256 => uint256) private claimedBitMap;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);

    constructor(address token_, bytes32 merkleRoot_) public {
        token = token_;
        merkleRoot = merkleRoot_;
    }

    /**
     * No caller permissioning needed since token is transfered to the account argument,
     * if the account is not in the merkleTree then the proof is invalid.
     * User can only submit claim for full claimable amount, otherwise proof verification will fail.
     */

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external {
        // Must not have been claimed before
        require(!isClaimed(index), 'KacoAirDrop: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 leaf = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), 'KacoAirDrop: Invalid proof.');

        // Mark it claimed and send the token to user.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'KacoAirDrop: Transfer failed.');

        emit Claimed(index, account, amount);
    }

    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    // Mark claimedBitMap[claimedWordIndex] as claimed. 
    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

}