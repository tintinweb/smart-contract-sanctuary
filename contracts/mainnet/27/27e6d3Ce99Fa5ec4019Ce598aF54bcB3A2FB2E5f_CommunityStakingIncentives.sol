/**
 *Submitted for verification at Etherscan.io on 2020-09-07
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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
        require(c >= a, "SafeMath: addition overflow");

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
        return sub(a, b, "SafeMath: subtraction overflow");
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
        return div(a, b, "SafeMath: division by zero");
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
        return mod(a, b, "SafeMath: modulo by zero");
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

// File: @openzeppelin/contracts/utils/Address.sol

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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
      return functionCall(target, data, "Address: low-level call failed");
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;




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
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol


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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/interfaces/IPooledStaking.sol

/*
    Copyright (C) 2020 NexusMutual.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

pragma solidity ^0.6.10;

interface IPooledStaking {
  function stakerContractStake(address staker, address contractAddress) external view returns (uint);
  function stakerContractPendingUnstakeTotal(address staker, address contractAddress) external view returns (uint);
}

// File: contracts/interfaces/INXMMaster.sol

/*
    Copyright (C) 2020 NexusMutual.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

pragma solidity ^0.6.10;

interface INXMMaster {
  function getLatestAddress(bytes2 _contractName) external view returns (address payable contractAddress);
}

// File: contracts/CommunityStakingIncentives.sol

/*
    Copyright (C) 2020 NexusMutual.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

pragma solidity ^0.6.10;







contract CommunityStakingIncentives is ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint;

  INXMMaster public master;
  uint public roundDuration;
  uint public roundsStartTime;
  uint public constant rewardRateScale = 1e18;

  /**
  * @dev Add rewards as a sponsor for a particular contract.
  * @param _roundDuration Duration of a reward round in seconds.
  * @param _roundsStartTime Timestamp in seconds at which rounds start. Needs to be in the future.
  * @param masterAddress NexusMutual Master contract address.
  */
  constructor(uint _roundDuration, uint _roundsStartTime, address masterAddress) public {

    require(_roundDuration > 0, "_roundDuration needs to be greater than 0");
    require(_roundsStartTime >= now, "_roundsStartTime needs to be in the future");
    roundDuration = _roundDuration;
    roundsStartTime = _roundsStartTime;
    master = INXMMaster(masterAddress);
  }

  struct RewardPool {
    uint amount;
    // rate nextRate and nextRateStartRound  may not be up to date. use _getRates to get the up to date values.
    uint rate;
    uint nextRate;
    uint nextRateStartRound;
    mapping(address => uint) lastRoundClaimed;
  }

  // stakedContractAddress => sponsorAddress => tokenAddress => RewardPool
  mapping (address => mapping (address => mapping (address => RewardPool))) rewardPools;

  event Deposited (
    address indexed stakedContract,
    address indexed sponsor,
    address tokenAddress,
    uint amount
  );

  event Withdrawn (
    address stakedContract,
    address sponsor,
    address tokenAddress,
    uint amount
  );

  event Claimed (
    address stakedContract,
    address sponsor,
    address tokenAddress,
    uint amount,
    address receiver,
    uint roundNumber
  );

  /**
  * @dev set the reward ratio as a sponsor for a particular contract and ERC20 token.
  * @param stakedContract Contract the staker has a stake on.
  * @param tokenAddress Address of the ERC20 token of the reward funds.
  * @param rate Rate between the NXM stake and the reward amount. (Scaled by 1e18)
  */
  function setRewardRate(address stakedContract, address tokenAddress, uint rate) public {

    RewardPool storage pool = rewardPools[stakedContract][msg.sender][tokenAddress];

    uint currentRound = getCurrentRound();
    uint currentRate;
    (currentRate, , ) = _getRates(pool, currentRound);
    if (currentRate == 0) {
      // set the rate for the current round
      pool.rate = rate;
      pool.nextRate = 0;
      pool.nextRateStartRound = 0;
    } else {
      // set the rate for the next round
      if (pool.rate != currentRate) {
        pool.rate = pool.nextRate;
      }
      pool.nextRate = rate;
      pool.nextRateStartRound = currentRound + 1;
    }
  }

  /**
  * @dev Add rewards as a sponsor for a particular contract.
  * @param stakedContract Contract the staker has a stake on.
  * @param tokenAddress Address of the ERC20 token of the reward funds.
  * @param amount Amount of rewards to be deposited.
  */
  function depositRewards(address stakedContract, address tokenAddress, uint amount) public {

    IERC20 erc20 = IERC20(tokenAddress);
    erc20.safeTransferFrom(msg.sender, address(this), amount);
    RewardPool storage pool = rewardPools[stakedContract][msg.sender][tokenAddress];
    pool.amount = pool.amount.add(amount);
    emit Deposited(stakedContract, msg.sender, tokenAddress, amount);
  }

  /**
  * @dev Add rewards as a sponsor for a particular contract.
  * @param stakedContract Contract the staker has a stake on.
  * @param tokenAddress Address of the ERC20 token of the reward funds.
  * @param amount Amount of rewards to be deposited.
  * @param rate Rate between the NXM stake and the reward amount. (Scaled by 1e18)
  */
  function depositRewardsAndSetRate(address stakedContract, address tokenAddress, uint amount, uint rate) external {
    depositRewards(stakedContract, tokenAddress, amount);
    setRewardRate(stakedContract, tokenAddress, rate);
  }

  /**
  * @dev Calls claimReward for each separate (stakedContract, sponsor, token) tuple specified.
  * @param stakedContracts Contracts the staker has a stake on.
  * @param sponsors Sponsors to claim rewards from.
  * @param tokenAddresses Addresses of the ERC20 token of the reward funds.
  * @return tokensRewarded Tokens rewarded by each sponsor.
  */
  function claimRewards(
    address[] calldata stakedContracts,
    address[] calldata sponsors,
    address[] calldata tokenAddresses
  ) external nonReentrant returns (uint[] memory tokensRewarded) {

    require(stakedContracts.length == sponsors.length, "stakedContracts.length != sponsors.length");
    require(stakedContracts.length == tokenAddresses.length, "stakedContracts.length != tokenAddresses.length");

    tokensRewarded = new uint[](stakedContracts.length);
    for (uint i = 0; i < stakedContracts.length; i++) {
      tokensRewarded[i] = claimReward(stakedContracts[i], sponsors[i], tokenAddresses[i]);
    }
  }

  /**
  * @dev Claims reward as a NexusMutual staker.
  * @param stakedContract contract the staker has a stake on.
  * @param sponsor Sponsor providing the reward funds.
  * @param tokenAddress address of the ERC20 token of the reward funds.
  * @return rewardAmount amount rewarded
  */
  function claimReward(
    address stakedContract,
    address sponsor,
    address tokenAddress
  ) internal returns (uint rewardAmount) {

    uint currentRound = getCurrentRound();
    RewardPool storage pool = rewardPools[stakedContract][sponsor][tokenAddress];
    uint lastRoundClaimed = pool.lastRoundClaimed[msg.sender];
    require(currentRound > lastRoundClaimed, "Already claimed this reward for this round");

    if (pool.nextRateStartRound != 0 && pool.nextRateStartRound <= currentRound) {
      pool.rate = pool.nextRate;
      pool.nextRateStartRound = 0;
      pool.nextRate = 0;
    }

    IPooledStaking pooledStaking = IPooledStaking(master.getLatestAddress("PS"));
    uint stake = pooledStaking.stakerContractStake(msg.sender, stakedContract);
    uint pendingUnstake = pooledStaking.stakerContractPendingUnstakeTotal(msg.sender, stakedContract);
    uint netStake = stake >= pendingUnstake ? stake.sub(pendingUnstake) : 0;
    rewardAmount = netStake.mul(pool.rate).div(rewardRateScale);
    uint rewardsAvailable = pool.amount;
    if (rewardAmount > rewardsAvailable) {
      rewardAmount = rewardsAvailable;
    }
    require(rewardAmount > 0, "rewardAmount needs to be greater than 0");

    pool.lastRoundClaimed[msg.sender] = currentRound;
    pool.amount = rewardsAvailable.sub(rewardAmount);

    IERC20 erc20 = IERC20(tokenAddress);
    erc20.safeTransfer(msg.sender, rewardAmount);
    emit Claimed(stakedContract, sponsor, tokenAddress, rewardAmount, msg.sender, currentRound);
  }

  /**
  * @dev Withdraw reward funds as a Sponsor for a particular staked contract.
  * @param stakedContract Contract the staker has a stake on.
  * @param tokenAddress Address of the ERC20 token of the reward funds.
  * @param amount Amount of reward funds to be withdrawn.
  */
  function withdrawRewards(address stakedContract, address tokenAddress, uint amount) external nonReentrant {
    IERC20 erc20 = IERC20(tokenAddress);
    RewardPool storage pool = rewardPools[stakedContract][msg.sender][tokenAddress];
    require(pool.amount >= amount, "Not enough tokens to withdraw");
    require(pool.rate == 0, "Reward rate is not 0");

    pool.amount = pool.amount.sub(amount);
    erc20.safeTransfer(msg.sender, amount);
    emit Withdrawn(stakedContract, msg.sender, tokenAddress, amount);
  }

  /**
  @dev Fetch the amount of available rewards for a staker for the current round from a particular reward pool.
  * @param staker whose rewards are counted.
  * @param stakedContract contract the staker has a stake on.
  * @param sponsor Sponsor providing the reward funds.
  * @param tokenAddress address of the ERC20 token of the reward funds.
  * @return rewardAmount amount of reward tokens available for this particular staker.
  */
  function getAvailableStakerReward(
    address staker,
    address stakedContract,
    address sponsor,
    address tokenAddress
  ) public view returns (uint rewardAmount) {

    uint currentRound = getCurrentRound();
    RewardPool storage pool = rewardPools[stakedContract][sponsor][tokenAddress];
    uint lastRoundClaimed = pool.lastRoundClaimed[staker];
    if (lastRoundClaimed >= currentRound) {
      return 0;
    }
    uint rate;
    (rate, , ) = _getRates(pool, currentRound);
    IPooledStaking pooledStaking = IPooledStaking(master.getLatestAddress("PS"));
    uint stake = pooledStaking.stakerContractStake(staker, stakedContract);
    uint pendingUnstake = pooledStaking.stakerContractPendingUnstakeTotal(staker, stakedContract);
    uint netStake = stake >= pendingUnstake ? stake.sub(pendingUnstake) : 0;
    rewardAmount = netStake.mul(rate).div(rewardRateScale);
    uint rewardsAvailable = pool.amount;
    if (rewardAmount > rewardsAvailable) {
      rewardAmount = rewardsAvailable;
    }
  }

  /**
  * @dev Calls claimReward for each separate (stakedContract, sponsor, token) tuple specified.
  * @param stakedContracts Contracts the staker has a stake on.
  * @param sponsors Sponsors to claim rewards from.
  * @param tokenAddresses Addresses of the ERC20 token of the reward funds.
  * @return tokensRewarded Tokens rewarded by each sponsor.
  */
  function getAvailableStakerRewards(
    address staker,
    address[] calldata stakedContracts,
    address[] calldata sponsors,
    address[] calldata tokenAddresses
  ) external view returns (uint[] memory tokensRewarded) {
    require(stakedContracts.length == sponsors.length, "stakedContracts.length != sponsors.length");
    require(stakedContracts.length == tokenAddresses.length, "stakedContracts.length != tokenAddresses.length");

    tokensRewarded = new uint[](stakedContracts.length);
    for (uint i = 0; i < stakedContracts.length; i++) {
      tokensRewarded[i] = getAvailableStakerReward(staker, stakedContracts[i], sponsors[i], tokenAddresses[i]);
    }
  }

  /**
  @dev Fetch RewardPool information
  * @param stakedContract contract a staker has a stake on.
  * @param sponsor Sponsor providing the reward funds.
  * @param tokenAddress address of the ERC20 token of the reward funds.
  * @return amount total available token amount of the RewardPool
  * @return rate rate to NXM of the RewardPool.
  * @return nextRateStartRound round number for which the next rate applies. if 0, no nextRate is set.
  * @return nextRate rate for the next round of the RewardPool. if nextRateStartRound is 0 this value is not relevant.
  */
  function getRewardPool(
      address stakedContract,
    address sponsor,
    address tokenAddress
  ) public view returns (uint amount, uint rate, uint nextRateStartRound, uint nextRate) {
    RewardPool storage pool = rewardPools[stakedContract][sponsor][tokenAddress];
    (rate, nextRateStartRound, nextRate) = _getRates(pool, getCurrentRound());
    amount = pool.amount;
  }


  /**
  @dev Fetch information for multiple RewardPools
  * @param stakedContracts contract a staker has a stake on.
  * @param sponsors Sponsor providing the reward funds.
  * @param tokenAddresses address of the ERC20 token of the reward funds.
  * @return amount total available token amount of the RewardPool
  * @return rate rate to NXM of the RewardPool.
  * @return nextRateStartRound round number for which the next rate applies. if 0, no nextRate is set.
  * @return nextRate rate for the next round of the RewardPool. if nextRateStartRound is 0 this value is not relevant.
  */
  function getRewardPools(
    address[] calldata stakedContracts,
    address[] calldata sponsors,
    address[] calldata tokenAddresses
  ) external view returns (
    uint[] memory amount,
    uint[] memory rate,
    uint[] memory nextRateStartRound,
    uint[] memory nextRate
  ) {
    require(stakedContracts.length == sponsors.length, "stakedContracts.length != sponsors.length");
    require(stakedContracts.length == tokenAddresses.length, "stakedContracts.length != tokenAddresses.length");

    amount = new uint[](stakedContracts.length);
    rate = new uint[](stakedContracts.length);
    nextRateStartRound = new uint[](stakedContracts.length);
    nextRate = new uint[](stakedContracts.length);

    for (uint i = 0; i < stakedContracts.length; i++) {
      RewardPool storage pool = rewardPools[stakedContracts[i]][sponsors[i]][tokenAddresses[i]];
      (rate[i], nextRateStartRound[i], nextRate[i]) = _getRates(pool, getCurrentRound());
      amount[i] = pool.amount;
    }
  }

  /**
  * @dev Fetch the current round number.
  */
  function getCurrentRound() public view returns (uint) {
    require(roundsStartTime <= now, "Rounds haven't started yet");
    return (now - roundsStartTime) / roundDuration + 1;
  }

  /**
  * @dev Fetch the last round in which a staker fetched his reward from a particular RewardPool.
  * @param stakedContract contract a staker has a stake on.
  * @param sponsor Sponsor providing the reward funds.
  * @param tokenAddress address of the ERC20 token of the reward funds.
  */
  function getLastRoundClaimed(
    address stakedContract,
    address sponsor,
    address tokenAddress,
    address staker
  ) external view returns (uint) {
    return rewardPools[stakedContract][sponsor][tokenAddress].lastRoundClaimed[staker];
  }

  function _getRates(RewardPool storage pool, uint currentRound) internal view returns (uint rate, uint nextRateStartRound, uint nextRate) {
    bool needsUpdate = pool.nextRateStartRound != 0 && pool.nextRateStartRound <= currentRound;
    if (needsUpdate) {
      return (pool.nextRate, 0, 0);
    }
    return (pool.rate, pool.nextRateStartRound, pool.nextRate);
  }
}