// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'SM_ADD_OVERFLOW');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = sub(x, y, 'SM_SUB_UNDERFLOW');
    }

    function sub(
        uint256 x,
        uint256 y,
        string memory message
    ) internal pure returns (uint256 z) {
        require((z = x - y) <= x, message);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'SM_MUL_OVERFLOW');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SM_DIV_BY_ZERO');
        uint256 c = a / b;
        return c;
    }

    function ceil_div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = div(a, b);
        if (c == mul(a, b)) {
            return c;
        } else {
            return add(c, 1);
        }
    }

    function toUint32(uint256 n) internal pure returns (uint32) {
        require(n < 2**32, 'IS_EXCEEDS_32_BITS');
        return uint32(n);
    }

    function toUint96(uint256 n) internal pure returns (uint96) {
        require(n < 2**96, 'IT_EXCEEDS_96_BITS');
        return uint96(n);
    }

    function add96(uint96 a, uint96 b) internal pure returns (uint96 c) {
        c = a + b;
        require(c >= a, 'SM_ADD_OVERFLOW');
    }

    function sub96(uint96 a, uint96 b) internal pure returns (uint96) {
        require(b <= a, 'SM_SUB_UNDERFLOW');
        return a - b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH_APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH_TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH_TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, 'TH_ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface IIntegralMerkleTimeRelease {
    event OwnerSet(address owner);
    event Claim(address claimer, address receiver, uint256 option1Amount, uint256 option2Amount);
    event Skim(address to, uint256 amount);
    event Option1StopBlockSet(uint256 option1StopBlock);
    event Option2StopBlockSet(uint256 option2StopBlock);
}

// SPDX-License-Identifier: GPL-3.0-or-later

// CODE COPIED FROM COMPOUND PROTOCOL (https://github.com/compound-finance/compound-protocol/tree/b9b14038612d846b83f8a009a82c38974ff2dcfe)

// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// CODE WAS SLIGHTLY MODIFIED

// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'SafeMath.sol';

contract Votes {
    using SafeMath for uint96;

    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;
    mapping(address => uint32) public checkpointsLength;

    event DelegateVotesChanged(address indexed account, uint96 oldVotes, uint96 newVotes);

    function getCurrentVotes(address account) external view returns (uint96) {
        // out of bounds access is safe and returns 0 votes
        return checkpoints[account][checkpointsLength[account] - 1].votes;
    }

    function _getPriorVotes(address account, uint256 blockNumber) internal view returns (uint96) {
        require(blockNumber < block.number, 'VO_NOT_YET_DETERMINED');

        uint32 n = checkpointsLength[account];
        if (n == 0) {
            return 0;
        }

        if (checkpoints[account][n - 1].fromBlock <= blockNumber) {
            return checkpoints[account][n - 1].votes;
        }

        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = n - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2;
            Checkpoint memory checkpoint = checkpoints[account][center];
            if (checkpoint.fromBlock == blockNumber) {
                return checkpoint.votes;
            } else if (checkpoint.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _updateVotes(
        address giver,
        address receiver,
        uint96 votes
    ) internal {
        if (giver == receiver || votes == 0) {
            return;
        }
        if (giver != address(0)) {
            uint32 n = checkpointsLength[giver];
            require(n > 0, 'VO_INSUFFICIENT_VOTES');
            // out of bounds access is safe and returns 0 votes
            uint96 oldVotes = checkpoints[giver][n - 1].votes;
            uint96 newVotes = oldVotes.sub96(votes);
            _writeCheckpoint(giver, n, newVotes);
        }

        if (receiver != address(0)) {
            uint32 n = checkpointsLength[receiver];
            // out of bounds access is safe and returns 0 votes
            uint96 oldVotes = checkpoints[receiver][n - 1].votes;
            uint96 newVotes = oldVotes.add96(votes);
            _writeCheckpoint(receiver, n, newVotes);
        }
    }

    function _writeCheckpoint(
        address account,
        uint32 n,
        uint96 votes
    ) internal {
        uint32 blockNumber = safe32(block.number);
        // out of bounds access is safe and returns 0 votes
        uint96 oldVotes = checkpoints[account][n - 1].votes;
        if (n > 0 && checkpoints[account][n - 1].fromBlock == blockNumber) {
            checkpoints[account][n - 1].votes = votes;
        } else {
            checkpoints[account][n] = Checkpoint(blockNumber, votes);
            checkpointsLength[account] = n + 1;
        }
        emit DelegateVotesChanged(account, oldVotes, votes);
    }

    function safe32(uint256 n) internal pure returns (uint32) {
        require(n < 2**32, 'VO_EXCEEDS_32_BITS');
        return uint32(n);
    }
}

// SPDX-License-Identifier: MIT
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * This library is copied from openzeppelin.
 * See `openzeppelin-contracts/test/cryptography/MerkleProof.test.js` for some examples.
 */
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

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'Math.sol';
import 'SafeMath.sol';
import 'TransferHelper.sol';
import 'IERC20.sol';
import 'IIntegralMerkleTimeRelease.sol';
import 'Votes.sol';
import 'MerkleProof.sol';

contract IntegralMerkleTimeRelease is IIntegralMerkleTimeRelease, Votes {
    using SafeMath for uint256;
    using SafeMath for uint96;

    address public immutable token;
    bytes32 public immutable merkleRoot;
    address public owner;

    uint96 public option1TotalAllocations;
    uint96 public option2TotalAllocations;
    uint96 public option1TotalClaimed;
    uint96 public option2TotalClaimed;

    struct Option {
        uint96 allocation;
        uint96 claimed;
        uint32 initBlock;
    }

    mapping(address => Option) public option1;
    mapping(address => Option) public option2;

    uint256 public option1StartBlock;
    uint256 public option1EndBlock;
    uint256 public option1StopBlock;

    uint256 public option2StartBlock;
    uint256 public option2EndBlock;
    uint256 public option2StopBlock;

    uint256 public option1StopSetBlock;
    uint256 public option2StopSetBlock;

    constructor(
        address _token,
        bytes32 _merkleRoot,
        uint256 _option1StartBlock,
        uint256 _option1EndBlock,
        uint256 _option2StartBlock,
        uint256 _option2EndBlock
    ) {
        owner = msg.sender;
        emit OwnerSet(owner);
        token = _token;
        merkleRoot = _merkleRoot;
        _setOption1Timeframe(_option1StartBlock, _option1EndBlock);
        _setOption2Timeframe(_option2StartBlock, _option2EndBlock);
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, 'MR_FORBIDDEN');
        owner = _owner;
        emit OwnerSet(owner);
    }

    function _setOption1Timeframe(uint256 _option1StartBlock, uint256 _option1EndBlock) internal {
        require(_option1EndBlock > _option1StartBlock, 'MR_INVALID_OPTION1_TIME_FRAME');
        option1StartBlock = _option1StartBlock;
        option1EndBlock = _option1EndBlock;
        option1StopBlock = _option1EndBlock;
        option1StopSetBlock = _option1EndBlock;
    }

    function _setOption2Timeframe(uint256 _option2StartBlock, uint256 _option2EndBlock) internal {
        require(_option2EndBlock > _option2StartBlock, 'MR_INVALID_OPTION2_TIME_FRAME');
        option2StartBlock = _option2StartBlock;
        option2EndBlock = _option2EndBlock;
        option2StopBlock = _option2EndBlock;
        option2StopSetBlock = _option2EndBlock;
    }

    function initializeAndClaim(
        address to,
        uint96 amount1,
        uint96 amount2,
        bytes32[] calldata merkleProof
    ) external {
        if (option1[msg.sender].allocation == 0 && option2[msg.sender].allocation == 0) {
            initializeAllocations(msg.sender, amount1, amount2, merkleProof);
        }

        claim(to);
    }

    function initializeAllocations(
        address wallet,
        uint96 amount1,
        uint96 amount2,
        bytes32[] calldata merkleProof
    ) public {
        require(
            option1StopSetBlock == option1EndBlock && option2StopSetBlock == option2EndBlock,
            'MR_STOP_ALREADY_SET'
        );
        require(
            option1[wallet].allocation == 0 && option2[wallet].allocation == 0,
            'MR_ALLOCATION_ALREADY_INITIALIZED'
        );

        bytes32 node = keccak256(abi.encodePacked(wallet, uint256(amount1), uint256(amount2)));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MR_INVALID_PROOF');

        uint32 initBlock = safe32(block.number);
        if (amount1 > 0) {
            option1[wallet].allocation = amount1;
            option1[wallet].initBlock = initBlock;
            option1TotalAllocations = option1TotalAllocations.add96(amount1);
        }
        if (amount2 > 0) {
            option2[wallet].allocation = amount2;
            option2[wallet].initBlock = initBlock;
            option2TotalAllocations = option2TotalAllocations.add96(amount2);
        }
        require(IERC20(token).balanceOf(address(this)) >= getTokensLeft(), 'MR_INSUFFICIENT_BALANCE');
    }

    function updateOption1Allocations(address[] calldata wallets, uint96[] calldata amounts) external {
        require(msg.sender == owner, 'MR_FORBIDDEN');
        require(option1StopSetBlock == option1EndBlock, 'MR_STOP_ALREADY_SET');
        require(wallets.length == amounts.length, 'MR_INVALID_LENGTHS');
        for (uint256 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            uint96 amount = amounts[i];
            uint96 oldAmount = option1[wallet].allocation;
            require(oldAmount > 0, 'MR_ALLOCATION_NOT_SET');
            require(getReleasedOption1(wallet) <= amount, 'MR_ALLOCATION_TOO_SMALL');
            option1TotalAllocations = option1TotalAllocations.sub96(oldAmount).add96(amount);
            option1[wallet].allocation = amount;
            uint96 claimed = option1[wallet].claimed;
            if (checkpointsLength[wallet] != 0) {
                _updateVotes(wallet, address(0), oldAmount.sub96(claimed));
            }
            _updateVotes(address(0), wallet, amount.sub96(claimed));
        }
        require(IERC20(token).balanceOf(address(this)) >= getTokensLeft(), 'MR_INSUFFICIENT_BALANCE');
    }

    function updateOption2Allocations(address[] calldata wallets, uint96[] calldata amounts) external {
        require(msg.sender == owner, 'MR_FORBIDDEN');
        require(option2StopSetBlock == option2EndBlock, 'MR_STOP_ALREADY_SET');
        require(wallets.length == amounts.length, 'MR_INVALID_LENGTHS');
        for (uint256 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            uint96 amount = amounts[i];
            uint96 oldAmount = option2[wallet].allocation;
            require(oldAmount > 0, 'MR_ALLOCATION_NOT_SET');
            require(getReleasedOption2(wallet) <= amount, 'MR_ALLOCATION_TOO_SMALL');
            option2TotalAllocations = option2TotalAllocations.sub96(oldAmount).add96(amount);
            option2[wallet].allocation = amount;
            uint96 claimed = option2[wallet].claimed;
            if (checkpointsLength[wallet] != 0) {
                _updateVotes(wallet, address(0), oldAmount.sub96(claimed));
            }
            _updateVotes(address(0), wallet, amount.sub96(claimed));
        }
        require(IERC20(token).balanceOf(address(this)) >= getTokensLeft(), 'MR_INSUFFICIENT_BALANCE');
    }

    function getTokensLeft() public view returns (uint96) {
        uint256 allocationTime1 = option1EndBlock.sub(option1StartBlock);
        uint256 claimableTime1 = option1StopBlock.sub(option1StartBlock);
        uint256 allocation1 = option1TotalAllocations.mul(claimableTime1).div(allocationTime1);

        uint256 allocationTime2 = option2EndBlock.sub(option2StartBlock);
        uint256 claimableTime2 = option2StopBlock.sub(option2StartBlock);
        uint256 allocation2 = option2TotalAllocations.mul(claimableTime2).div(allocationTime2);

        return allocation1.add(allocation2).sub(option1TotalClaimed).sub(option2TotalClaimed).toUint96();
    }

    function setOption1StopBlock(uint256 _option1StopBlock) external {
        require(msg.sender == owner, 'MR_FORBIDDEN');
        require(option1StopSetBlock == option1EndBlock, 'MR_STOP_ALREADY_SET');
        require(_option1StopBlock >= block.number && _option1StopBlock < option1EndBlock, 'MR_INVALID_BLOCK_NUMBER');
        option1StopBlock = _option1StopBlock;
        option1StopSetBlock = block.number;
        emit Option1StopBlockSet(_option1StopBlock);
    }

    function setOption2StopBlock(uint256 _option2StopBlock) external {
        require(msg.sender == owner, 'MR_FORBIDDEN');
        require(option2StopSetBlock == option2EndBlock, 'MR_STOP_ALREADY_SET');
        require(_option2StopBlock >= block.number && _option2StopBlock < option2EndBlock, 'MR_INVALID_BLOCK_NUMBER');
        option2StopBlock = _option2StopBlock;
        option2StopSetBlock = block.number;
        emit Option2StopBlockSet(_option2StopBlock);
    }

    function skim(address to) external {
        require(msg.sender == owner, 'MR_FORBIDDEN');
        require(to != address(0), 'MR_ADDRESS_ZERO');

        uint256 amount = getExcessTokens();
        TransferHelper.safeTransfer(token, to, amount);
        emit Skim(to, amount);
    }

    function getExcessTokens() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this)).sub(getTokensLeft());
    }

    function getReleasedOption1(address wallet) public view returns (uint96) {
        return _getReleasedOption1ForBlock(wallet, block.number);
    }

    function _getReleasedOption1ForBlock(address wallet, uint256 blockNumber) internal view returns (uint96) {
        if (blockNumber <= option1StartBlock) {
            return 0;
        }
        uint256 elapsed = Math.min(blockNumber, option1StopBlock).sub(option1StartBlock);
        uint256 allocationTime = option1EndBlock.sub(option1StartBlock);
        return option1[wallet].allocation.mul(elapsed).div(allocationTime).toUint96();
    }

    function getReleasedOption2(address wallet) public view returns (uint96) {
        return _getReleasedOption2ForBlock(wallet, block.number);
    }

    function _getReleasedOption2ForBlock(address wallet, uint256 blockNumber) internal view returns (uint96) {
        if (blockNumber <= option2StartBlock) {
            return 0;
        }
        uint256 elapsed = Math.min(blockNumber, option2StopBlock).sub(option2StartBlock);
        uint256 allocationTime = option2EndBlock.sub(option2StartBlock);
        return option2[wallet].allocation.mul(elapsed).div(allocationTime).toUint96();
    }

    function getClaimableOption1(address wallet) external view returns (uint256) {
        return getReleasedOption1(wallet).sub(option1[wallet].claimed);
    }

    function getClaimableOption2(address wallet) external view returns (uint256) {
        return getReleasedOption2(wallet).sub(option2[wallet].claimed);
    }

    function getOption1Allocation(address wallet) external view returns (uint256) {
        return option1[wallet].allocation;
    }

    function getOption1Claimed(address wallet) external view returns (uint256) {
        return option1[wallet].claimed;
    }

    function getOption2Allocation(address wallet) external view returns (uint256) {
        return option2[wallet].allocation;
    }

    function getOption2Claimed(address wallet) external view returns (uint256) {
        return option2[wallet].claimed;
    }

    function claim(address to) public {
        address sender = msg.sender;
        Option memory _option1 = option1[sender];
        Option memory _option2 = option2[sender];
        uint96 _option1Claimed = _option1.claimed;
        uint96 _option2Claimed = _option2.claimed;
        uint96 option1Amount = getReleasedOption1(sender).sub96(_option1Claimed);
        uint96 option2Amount = getReleasedOption2(sender).sub96(_option2Claimed);

        option1[sender].claimed = _option1Claimed.add96(option1Amount);
        option2[sender].claimed = _option2Claimed.add96(option2Amount);
        option1TotalClaimed = option1TotalClaimed.add96(option1Amount);
        option2TotalClaimed = option2TotalClaimed.add96(option2Amount);

        uint96 totalClaimed = option1Amount.add96(option2Amount);
        if (checkpointsLength[sender] == 0) {
            _updateVotes(address(0), sender, _option1.allocation.add96(_option2.allocation));
        }
        _updateVotes(sender, address(0), totalClaimed);

        TransferHelper.safeTransfer(token, to, totalClaimed);
        emit Claim(sender, to, option1Amount, option2Amount);
    }

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96) {
        uint96 option1TotalAllocation = option1[account].allocation;
        uint96 option2TotalAllocation = option2[account].allocation;

        uint256 votes = 0;
        if (checkpointsLength[account] == 0 || checkpoints[account][0].fromBlock > blockNumber) {
            if (option1[account].initBlock <= blockNumber) {
                votes = votes.add(option1TotalAllocation);
            }
            if (option2[account].initBlock <= blockNumber) {
                votes = votes.add(option2TotalAllocation);
            }
        } else {
            votes = _getPriorVotes(account, blockNumber);
        }

        if (option1StopBlock == option1EndBlock && option2StopBlock == option2EndBlock) {
            return votes.toUint96();
        }
        if (option1StopSetBlock > blockNumber && option2StopSetBlock > blockNumber) {
            return votes.toUint96();
        }

        uint256 lockedAllocation1;
        uint256 lockedAllocation2;
        if (blockNumber >= option1StopSetBlock) {
            uint256 allocationTime = option1EndBlock.sub(option1StartBlock);
            uint256 haltedTime = option1EndBlock.sub(option1StopBlock);
            lockedAllocation1 = option1TotalAllocation.mul(haltedTime).div(allocationTime);
        }
        if (blockNumber >= option2StopSetBlock) {
            uint256 allocationTime = option2EndBlock.sub(option2StartBlock);
            uint256 haltedTime = option2EndBlock.sub(option2StopBlock);
            lockedAllocation2 = option2TotalAllocation.mul(haltedTime).div(allocationTime);
        }
        return votes.sub(lockedAllocation1).sub(lockedAllocation2).toUint96();
    }
}