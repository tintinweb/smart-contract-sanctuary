// SPDX-License-Identifier: Augury Finance
// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/GovernorAlpha.sol
// Copyright Augury Finance, 2021. Do not re-use without permission.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

pragma solidity ^0.6.12;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/access/Ownable.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/math/SafeMath.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/token/ERC20/SafeERC20.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/utils/ReentrancyGuard.sol';

import './libs/IDividendCalculator.sol';
import './Operators.sol';
import './AuguryStateRepositoryV1.sol';

contract AuguryStateBasedDividendsV1 is Ownable, ReentrancyGuard, Operators, IDividendCalculator {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserState {
      uint256 lastCollectedPeriod;
    }

    struct PeriodState {
      uint256 distributable;
    }

    uint256 public epochsPerPeriod;
    uint256 public epochOffset;
    address public communityWallet;
    uint256 public poolId;

    IERC20 public dividendToken;
    AuguryStateRepositoryV1 public state;

    // [_userAddress] => UserState
    mapping(address => UserState) public users;

    // [_period] => PeriodState
    mapping(uint256 => PeriodState) public periods;
    uint256 public lastReadyPeriod;

    event DividendsCollected(address indexed user, uint256 amount);

    constructor(IERC20 _dividendToken, AuguryStateRepositoryV1 _state, address _communityWallet, uint256 _poolId) public {
        dividendToken = _dividendToken;
        state = _state;
        communityWallet = _communityWallet;
        poolId = _poolId;

        epochsPerPeriod = 7;
        epochOffset = 0;
        lastReadyPeriod = currentPeriod() - 1;
    }

    function epochToPeriod(uint256 _epoch) public view returns (uint256) {
      require(_epoch >= epochOffset, 'expected epoch to be after the epoch offset.');

      return _epoch.sub(epochOffset).div(epochsPerPeriod);
    }
    function periodToFirstEpoch(uint256 _period) public view returns(uint256) {

      return _period.mul(epochsPerPeriod).add(epochOffset);
    }

    function currentPeriod() public view returns (uint256) {
      return epochToPeriod(state.currentEpoch());
    }

    function calculateUserDistribution(uint256 _periodDistributableAmount, uint256 _poolPeriodTvl, uint256 _userPeriodTvl) public pure returns (uint256) {
        if(_poolPeriodTvl == 0 || _userPeriodTvl == 0) {
            return 0;
        }

        uint256 _numerator = _periodDistributableAmount.mul(_userPeriodTvl).mul(1e18);
        uint256 _denominator = _poolPeriodTvl;

        return _numerator.div(_denominator).div(1e18);
    }

    function calculateTvlsForPeriod(address _userAddress, uint256 _period) public view returns (uint256, uint256) {
      uint256 _poolTvl = 0;
      uint256 _userTvl = 0;

      uint256 _epoch = periodToFirstEpoch(_period);
      uint256 _nextPeriodFirstEpoch = periodToFirstEpoch(_period + 1);
      while(_epoch < _nextPeriodFirstEpoch) {

        _poolTvl = _poolTvl + state.getPoolTvlAtEpoch(poolId, _epoch);
        _userTvl = _userTvl + state.getUserTvlAtEpoch(poolId, _userAddress, _epoch);

        _epoch = _epoch + 1;
      }

      return (_poolTvl, _userTvl);
    }

    function preparePeriod(uint256 _period, uint256 _amount) public onlyOperator {
      require(_period == lastReadyPeriod + 1, 'expected period to be lastReadyPeriod + 1');
      require(_period < currentPeriod(), 'expected period to not be active.');

      periods[_period].distributable = _amount;
      lastReadyPeriod = _period;
    }

    function emergencyReturnCommunityFunds() public onlyOperator {
      uint256 _amount = dividendToken.balanceOf(address(this));
      if(_amount == 0) {
        return;
      }

      dividendToken.safeTransfer(communityWallet, _amount);
    }

    function calculateUnclaimedDividends(address _userAddress) public override view returns (uint256) {
      
      uint256 _period = users[_userAddress].lastCollectedPeriod + 1;
      uint256 _total = 0;

      while(_period <= lastReadyPeriod) {

        uint256 _periodDividends = periods[_period].distributable;

        (uint256 _poolTvl, uint256 _userTvl) = calculateTvlsForPeriod(_userAddress, _period);
        _total = _total + calculateUserDistribution(_periodDividends, _poolTvl, _userTvl);

        _period = _period + 1;
      }

      return _total;
    }
  
    function collectDividends() public override {
      uint256 _amount = calculateUnclaimedDividends(msg.sender);

      users[msg.sender].lastCollectedPeriod = lastReadyPeriod;
      if(_amount > 0) {
        dividendToken.safeTransfer(msg.sender, _amount);
        emit DividendsCollected(msg.sender, _amount);
      }
    }

    function calculateUnclaimedDividendsToPeriod(address _userAddress, uint256 _maxPeriod) public view returns (uint256) {
      
      uint256 _period = users[_userAddress].lastCollectedPeriod + 1;
      uint256 _total = 0;

      while(_period <= _maxPeriod) {

        uint256 _periodDividends = periods[_period].distributable;

        (uint256 _poolTvl, uint256 _userTvl) = calculateTvlsForPeriod(_userAddress, _period);
        _total = _total + calculateUserDistribution(_periodDividends, _poolTvl, _userTvl);

        _period = _period + 1;
      }

      return _total;
    }

    function collectDividendsToPeriod(uint256 _period) public {

      if(_period > lastReadyPeriod) {
        _period = lastReadyPeriod;
      }

      uint256 _amount = calculateUnclaimedDividendsToPeriod(msg.sender, _period);

      users[msg.sender].lastCollectedPeriod = _period;
      if(_amount > 0) {
        dividendToken.safeTransfer(msg.sender, _amount);
        emit DividendsCollected(msg.sender, _amount);
      }
    }
}

// SPDX-License-Identifier: Augury Finance
// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/GovernorAlpha.sol
// Copyright Augury Finance, 2021. Do not re-use without permission.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

pragma solidity ^0.6.12;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/access/Ownable.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/math/SafeMath.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/utils/ReentrancyGuard.sol';

import './libs/IDividends.sol';
import './Operators.sol';

contract AuguryStateRepositoryV1 is Ownable, ReentrancyGuard, Operators, IDividends {
    using SafeMath for uint256;

    struct PoolUserState {
        uint256 tvl;
        uint256 lastPositiveStakedTime;
        uint256 lastZeroStakedTime;
    }

    struct UserState {
        uint256 lastInteractedAt;
    }

    struct PoolUserSnapshot {
        uint256 tvl;
    }

    struct PoolSnapshot {
        uint256 tvl;
    }

    struct PoolState {
        uint256 lastInteractedAt;
        uint256 tvl;
    }

    uint256 public constant MAX_UINT_256 = uint256(-1);
    uint256 public epochOffsetSeconds;
    uint256 public epochDurationSeconds;
    uint256 public lastCapturedEpoch;

    ///////////
    // Users //
    ///////////

    address[] public userAddresses;
    // [_pid][_userAddress] => PoolUserState
    mapping(uint256 => mapping(address => PoolUserState)) public poolUsers;
    // [_pid][_userAddress][_epoch] => PoolUserSnapshot
    mapping(uint256 => mapping(address => mapping(uint256 => PoolUserSnapshot))) public poolUserSnapshots;
    // [_userAddress] => UserState
    mapping(address => UserState) public users;

    ///////////
    // Pools //
    ///////////

    uint256[] public poolIds;
    // [_pid] => PoolState
    mapping(uint256 => PoolState) public pools;
    // [_pid][_epoch] => PoolSnapshot
    mapping(uint256 => mapping(uint256 => PoolSnapshot)) public poolSnapshots;

    constructor() public {
        // 1 day
        epochDurationSeconds = 1 days;
        // Fri May 28 2021 09:00:00 GMT-0500 (Central Daylight Time)
        epochOffsetSeconds = 1622210400;

        require((now - 2 * epochDurationSeconds) > epochOffsetSeconds, 'epochDurationSecondsOffset must be at least two epochs in the past.');

        lastCapturedEpoch = secondsToEpoch(getNow()) - 1;
    }

    function getNow() public virtual view returns (uint256) {
        return now;
    }

    function getUserLastStakedTime(uint _pid, address _user) public view returns (uint256) {
        uint256 positiveStakeTime = poolUsers[_pid][_user].lastPositiveStakedTime;
        uint256 zeroStakeTime = poolUsers[_pid][_user].lastZeroStakedTime;

        return positiveStakeTime > zeroStakeTime ? positiveStakeTime
            : zeroStakeTime;
    }

    function hasUserInteracted(address _user) public view returns (bool) {
        return users[_user].lastInteractedAt > 0;
    }

    function hasPoolInteracted(uint256 _pid) public view returns (bool) {
        return pools[_pid].lastInteractedAt > 0;
    }

    function secondsToEpoch(uint256 _seconds) public view returns (uint256) {
        return (_seconds - epochOffsetSeconds).div(epochDurationSeconds);
    }

    function currentEpoch() public view returns (uint256) {
        return secondsToEpoch(getNow());
    }

    // user state
    function _setUserStakedAmount(uint256 _pid, address _userAddress, uint256 _newTvl) private nonReentrant {
        uint256 _currentEpoch = currentEpoch();
        uint256 _now = getNow();

        PoolState storage _pool = pools[_pid];
        PoolSnapshot storage _poolSnapshot = poolSnapshots[_pid][_currentEpoch];

        PoolUserState storage _poolUser = poolUsers[_pid][_userAddress];
        PoolUserSnapshot storage _userSnapshot = poolUserSnapshots[_pid][_userAddress][_currentEpoch];

        if(!hasUserInteracted(_userAddress)) {
            userAddresses.push(_userAddress);
        }
        users[_userAddress].lastInteractedAt = _now;

        if(!hasPoolInteracted(_pid)) {
            poolIds.push(_pid);
        }
        _pool.lastInteractedAt = _now;

        // when the user removes stake
        if(_poolUser.tvl > _newTvl) {
            uint256 _decrementTotalBy = _poolUser.tvl.sub(_newTvl);
            _pool.tvl = _pool.tvl.sub(_decrementTotalBy);
        }

        // when the user adds stake
        if (_poolUser.tvl < _newTvl) {
            uint256 _incrementTotalBy = _newTvl.sub(_poolUser.tvl);
            _pool.tvl = _pool.tvl.add(_incrementTotalBy);
        }

        if(_pool.tvl == 0) {
            _poolSnapshot.tvl = MAX_UINT_256;
        } else {
            _poolSnapshot.tvl = _pool.tvl;
        }

        _poolUser.tvl = _newTvl;
        if(_newTvl == 0) {
            _userSnapshot.tvl = MAX_UINT_256;
            _poolUser.lastZeroStakedTime = getNow();
        } else {
            _userSnapshot.tvl = _newTvl;
            _poolUser.lastPositiveStakedTime = getNow();
        }
    }
    function setUserStakedAmount(uint256 _pid, address _userAddress, uint256 _newTvl) public override onlyOwner {
        _setUserStakedAmount(_pid, _userAddress, _newTvl);
    }

    function getUserTvlAtEpoch(uint256 _pid, address _userAddress, uint256 _epoch) public view returns (uint256) {

        require(_epoch > 0, 'expected a positive epoch.');
        require(_epoch < currentEpoch(), 'expected a previous epoch.');
        
        if(!hasUserInteracted(_userAddress)) {
            return 0;
        }

        // 0 means that the user did not interact with during the epoch
        // we should never get to the 0th epoch, since that would mean the user was not interacted with ever
        uint256 _snapshotTvl = poolUserSnapshots[_pid][_userAddress][_epoch].tvl;
        while(_snapshotTvl == 0 && _epoch > 1) {
            _epoch = _epoch - 1;
            _snapshotTvl = poolUserSnapshots[_pid][_userAddress][_epoch].tvl;
        }

        return _snapshotTvl == MAX_UINT_256 ? 0
            : _snapshotTvl;
    }

    function getPoolTvlAtEpoch(uint256 _pid, uint256 _epoch) public view returns (uint256) {
    
        require(_epoch > 0, 'expected a positive epoch.');
        require(_epoch < currentEpoch(), 'expected a previous epoch.');
        
        if(!hasPoolInteracted(_pid)) {
            return 0;
        }

        // 0 means the pool did not receive any interactions duing the epoch
        // we should never get to the 0th epoch, since that would mean that the pool was not interacted with ever
        uint256 _snapshotTvl = poolSnapshots[_pid][_epoch].tvl;
        while(_snapshotTvl == 0 && _epoch > 1) {
            _epoch = _epoch - 1;
            _snapshotTvl = poolSnapshots[_pid][_epoch].tvl;
        }

        return _snapshotTvl == MAX_UINT_256 ? 0
            : _snapshotTvl;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/token/ERC20/SafeERC20.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/access/Ownable.sol';

import './libs/IOperable.sol';

contract Operators is Ownable, IOperable {
    mapping(address => bool) public operators;

    event OperatorUpdated(address indexed operator, bool indexed status);

    constructor () internal {
        operators[msg.sender] = true;
        emit OperatorUpdated(msg.sender, true);
    }

    modifier onlyOperator() {
        require(operators[msg.sender], 'Operator: caller is not the operator');
        _;
    }

    // Update the status of the operator
    function updateOperator(address _operator, bool _status) external override onlyOwner {
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/access/Ownable.sol';

import './IOperable.sol';

interface IDividendCalculator is IOperable {

  function calculateUnclaimedDividends(address _userAddress) external view returns (uint256);
  
  function collectDividends() external;
}

// SPDX-License-Identifier: MIT

// Referral Interface

pragma solidity ^0.6.12;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/access/Ownable.sol';

import './IOperable.sol';

interface IDividends is IOperable {
  function setUserStakedAmount(uint256 _pid, address _userAddress, uint256 _omenTotalStakedAmount_d18) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IOperable {
    // Update the status of the operator
    function updateOperator(address _operator, bool _status) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import '../GSN/Context.sol';
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './IERC20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeERC20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, 'SafeERC20: decreased allowance below zero');
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}