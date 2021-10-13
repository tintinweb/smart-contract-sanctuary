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

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

interface IIntegralStaking {
    event StopIssuance(uint32 stopBlock);
    event Deposit(address user, uint256 stakeId, uint96 amount);
    event WithdrawAll(address user, uint96 amount, address to);
    event Withdraw(address user, uint256 stakeId, uint96 amount, address to);
    event ClaimAll(address user, uint96 amount, address to);
    event Claim(address user, uint256 stakeId, uint96 amount, address to);

    struct UserStake {
        uint32 startBlock;
        uint32 claimedBlock;
        uint96 lockedAmount;
        bool withdrawn;
    }

    function getUserStakes(address _user) external view returns (UserStake[] memory);

    function owner() external view returns (address);

    function integralToken() external view returns (address);

    function durationInBlocks() external view returns (uint32);

    function stopBlock() external view returns (uint32);

    function ratePerBlockNumerator() external view returns (uint32);

    function ratePerBlockDenominator() external view returns (uint32);

    function setOwner(address _owner) external;

    function stopIssuance(uint32 _stopBlock) external;

    function deposit(uint96 _amount) external returns (uint256 stakeId);

    function withdrawAll(address _to) external;

    function withdraw(uint256 _stakeId, address _to) external;

    function claimAll(address _to) external;

    function claim(uint256 _stakeId, address _to) external;

    function getAllClaimable(address _user) external view returns (uint96 claimableAmount);

    function getClaimable(address _user, uint256 _stakeId) external view returns (uint96 claimableAmount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface IIntegralToken {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import 'Math.sol';
import 'SafeMath.sol';
import 'TransferHelper.sol';
import 'Votes.sol';
import 'IIntegralStaking.sol';
import 'IIntegralToken.sol';

contract IntegralStaking is IIntegralStaking, Votes {
    using SafeMath for uint32;
    using SafeMath for uint96;
    using SafeMath for uint256;
    using TransferHelper for address;

    address public override owner;
    address public immutable override integralToken;
    uint32 public immutable override durationInBlocks;
    uint32 public override stopBlock;
    uint32 public immutable override ratePerBlockNumerator;
    uint32 public immutable override ratePerBlockDenominator;

    mapping(address => UserStake[]) public userStakes;

    constructor(
        address _integralToken,
        uint32 _durationInBlocks,
        uint32 _ratePerBlockNumerator,
        uint32 _ratePerBlockDenominator
    ) {
        owner = msg.sender;
        integralToken = _integralToken;
        durationInBlocks = _durationInBlocks;
        ratePerBlockNumerator = _ratePerBlockNumerator;
        ratePerBlockDenominator = _ratePerBlockDenominator;
    }

    function getUserStakes(address _user) external view override returns (UserStake[] memory) {
        return userStakes[_user];
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, 'IS_FORBIDDEN');
        owner = _owner;
    }

    function stopIssuance(uint32 _stopBlock) external override {
        require(msg.sender == owner, 'IS_FORBIDDEN');
        require(_stopBlock >= block.number, 'IS_INVALID_INPUT');
        require(stopBlock == 0, 'IS_ALREADY_STOPPED');

        stopBlock = _stopBlock;
        emit StopIssuance(_stopBlock);
    }

    function deposit(uint96 _amount) external override returns (uint256 stakeId) {
        require(_amount > 0, 'IS_INVALID_AMOUNT');
        require(stopBlock == 0 || stopBlock > block.number, 'IS_ALREADY_STOPPED');

        address user = msg.sender;

        // deposit token to contract
        integralToken.safeTransferFrom(user, address(this), _amount);

        // add a new stake
        UserStake memory userStake;
        userStake.startBlock = block.number.toUint32();
        userStake.lockedAmount = _amount;
        userStakes[user].push(userStake);

        stakeId = userStakes[user].length - 1;

        _updateVotes(address(0), user, _amount);

        emit Deposit(user, stakeId, _amount);
    }

    function withdrawAll(address _to) external override {
        require(_to != address(0), 'IS_ADDRESS_ZERO');

        address user = msg.sender;
        uint96 withdrawnAmount;
        uint256 length = userStakes[user].length;
        for (uint256 i = 0; i < length; i++) {
            UserStake memory userStake = userStakes[user][i];
            uint256 endBlock = _calculateStopBlock(userStake.startBlock);
            if (endBlock < block.number && userStake.withdrawn == false) {
                withdrawnAmount = withdrawnAmount.add96(userStake.lockedAmount);
                userStakes[user][i].withdrawn = true;
            }
        }

        _finalizeWithdraw(user, _to, withdrawnAmount);

        emit WithdrawAll(user, withdrawnAmount, _to);
    }

    function withdraw(uint256 _stakeId, address _to) external override {
        require(_to != address(0), 'IS_ADDRESS_ZERO');

        address user = msg.sender;
        require(userStakes[user].length > _stakeId, 'IS_INVALID_ID');

        UserStake memory userStake = userStakes[user][_stakeId];

        uint256 endBlock = _calculateStopBlock(userStake.startBlock);
        require(endBlock <= block.number, 'IS_LOCKED');
        require(userStake.withdrawn == false, 'IS_ALREADY_WITHDRAWN');

        uint96 withdrawnAmount = userStake.lockedAmount;

        userStakes[user][_stakeId].withdrawn = true;

        _finalizeWithdraw(user, _to, withdrawnAmount);

        emit Withdraw(user, _stakeId, withdrawnAmount, _to);
    }

    function _finalizeWithdraw(
        address user,
        address to,
        uint96 withdrawnAmount
    ) internal {
        _updateVotes(user, address(0), withdrawnAmount);
        integralToken.safeTransfer(to, withdrawnAmount);
    }

    function claimAll(address _to) external override {
        require(_to != address(0), 'IS_ADDRESS_ZERO');

        address user = msg.sender;
        uint96 claimedAmount;
        uint32 currentBlock = block.number.toUint32();
        uint256 length = userStakes[user].length;
        for (uint256 i = 0; i < length; i++) {
            uint96 _getClaimableAmount = _getClaimable(user, i);
            if (_getClaimableAmount != 0) {
                claimedAmount = claimedAmount.add96(_getClaimableAmount);
                userStakes[user][i].claimedBlock = currentBlock;
            }
        }

        IIntegralToken(integralToken).mint(_to, claimedAmount);

        emit ClaimAll(user, claimedAmount, _to);
    }

    function claim(uint256 _stakeId, address _to) external override {
        require(_to != address(0), 'IS_ADDRESS_ZERO');

        address user = msg.sender;
        require(userStakes[user].length > _stakeId, 'IS_INVALID_ID');

        uint96 claimedAmount = _getClaimable(user, _stakeId);
        require(claimedAmount != 0, 'IS_ALREADY_CLAIMED');

        userStakes[user][_stakeId].claimedBlock = block.number.toUint32();

        IIntegralToken(integralToken).mint(_to, claimedAmount);

        emit Claim(user, _stakeId, claimedAmount, _to);
    }

    function getAllClaimable(address user) external view override returns (uint96 claimableAmount) {
        uint256 length = userStakes[user].length;
        for (uint256 i = 0; i < length; i++) {
            claimableAmount = claimableAmount.add96(_getClaimable(user, i));
        }
    }

    function getClaimable(address _user, uint256 _stakeId) external view override returns (uint96) {
        require(userStakes[_user].length > _stakeId, 'IS_INVALID_ID');

        return _getClaimable(_user, _stakeId);
    }

    function getUserStakesCount(address user) external view returns (uint256) {
        return userStakes[user].length;
    }

    function getTotalStaked(address user) external view returns (uint96) {
        return checkpoints[user][checkpointsLength[user] - 1].votes;
    }

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96) {
        return _getPriorVotes(account, blockNumber);
    }

    function _getClaimable(address user, uint256 stakeId) internal view returns (uint96 claimableAmount) {
        UserStake memory userStake = userStakes[user][stakeId];

        uint256 fromBlock = Math.max(userStake.startBlock, userStake.claimedBlock);
        uint256 toBlock = Math.min(block.number, _calculateStopBlock(userStake.startBlock));

        if (fromBlock < toBlock) {
            claimableAmount = userStake
                .lockedAmount
                .mul(ratePerBlockNumerator)
                .mul(toBlock.sub(fromBlock))
                .div(ratePerBlockDenominator)
                .toUint96();
        }
    }

    function _calculateStopBlock(uint32 startBlock) internal view returns (uint256) {
        uint256 endBlock = startBlock.add(durationInBlocks);
        return (stopBlock == 0 || endBlock < stopBlock) ? endBlock : stopBlock;
    }
}