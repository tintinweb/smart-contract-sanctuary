/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

interface IFlashToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address to, uint256 value) external returns (bool);

    function burn(uint256 value) external returns (bool);
}


// A library for performing overflow-safe math, courtesy of DappHub: https://github.com/dapphub/ds-math/blob/d0ef6d6a5f/src/math.sol
// Modified to include only the essentials
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "MATH:: ADD_OVERFLOW");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "MATH:: SUB_UNDERFLOW");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MATH:: MUL_OVERFLOW");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "MATH:: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}



contract ClaimContract {
    using MerkleProof for bytes;
    using SafeMath for uint256;

    enum MigrationType { V1_UNCLAIMED, HOLDER, STAKER }

    address public constant FLASH_TOKEN_V1 = 0xB4467E8D621105312a914F1D42f10770C0Ffe3c8;
    address public constant FLASH_TOKEN_V2 = 0x20398aD62bb2D930646d45a6D4292baa0b860C1f;
    bytes32 public constant MERKLE_ROOT = 0x56dc616cf485d230be34e774839fc4b1b11b0ab99b92d594f7f16f4065f7e814;
    uint256 public constant V1_UNCLAIMED_DEADLINE = 1617235140;

    mapping(uint256 => uint256) private claimedBitMap;

    event Claimed(uint256 index, address sender, uint256 amount);

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function _getMigratableAmountAndTransferV1(address _user, uint256 _balance) private returns (uint256 flashV2Mint) {
        uint256 flashV1Balance = IFlashToken(FLASH_TOKEN_V1).balanceOf(_user);
        flashV2Mint = flashV1Balance >= _balance ? _balance : flashV1Balance;
        IFlashToken(FLASH_TOKEN_V1).transferFrom(_user, address(this), flashV2Mint);
    }

    function claim(
        uint256 index,
        uint256 balance,
        uint256 bonusAmount,
        uint256 expiry,
        uint256 expireAfter,
        MigrationType migrationType,
        bytes32[] calldata merkleProof
    ) external {
        require(!isClaimed(index), "FlashV2Migration: Already claimed.");

        address user = msg.sender;

        require(
            MerkleProof.verify(
                merkleProof,
                MERKLE_ROOT,
                keccak256(
                    abi.encodePacked(index, user, balance, bonusAmount, expiry, expireAfter, uint256(migrationType))
                )
            ),
            "FlashV2Migration: Invalid proof."
        );

        uint256 flashV2Mint = balance;

        if (migrationType == MigrationType.V1_UNCLAIMED) {
            require(block.timestamp <= V1_UNCLAIMED_DEADLINE, "FlashV2Migration: V1 claim time expired.");
        } else if (migrationType == MigrationType.HOLDER) {
            flashV2Mint = _getMigratableAmountAndTransferV1(user, balance);
        } else if (migrationType == MigrationType.STAKER) {
            if (expireAfter > block.timestamp) {
                uint256 burnAmount = balance.mul(expireAfter.sub(block.timestamp)).mul(75e16).div(expiry.mul(1e18));
                flashV2Mint = balance.sub(burnAmount);
            }
        } else {
            revert("FlashV2Migration: Invalid migration type");
        }

        _setClaimed(index);

        IFlashToken(FLASH_TOKEN_V2).mint(user, flashV2Mint.add(bonusAmount));

        emit Claimed(index, user, flashV2Mint);
    }
}