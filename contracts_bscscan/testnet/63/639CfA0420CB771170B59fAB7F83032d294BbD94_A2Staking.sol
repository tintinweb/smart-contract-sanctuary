// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract A2Staking is Context, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event PoolAdded(uint256 indexed poolId, address indexed token, uint256 cliff, uint256 duration, uint256 penalty, uint256 unstakeCliff);
    event PoolClosed(uint256 indexed poolId);

    event Staked(address indexed token, uint256 indexed pool, address indexed beneficiary, uint256 stake, uint256 stakeAmount, uint256 duration);
    event UnstakeIntention(address indexed token, uint256 indexed pool, address indexed beneficiary, uint256 stake, uint256 amount);
    event Unstaked(address indexed token, uint256 indexed pool, address indexed beneficiary, uint256 stake, uint256 unstakeAmount, uint256 penalty);

    uint256 private constant EXP = 1e18;

    struct Pool {
        IERC20 token;               // Token of the pool
        uint256 cliff;              // Period when unstake is prohibited
        uint256 duration;           // Stake duration (including cliff)
        uint256 penalty;            // Penalty of early unstake calculated as amount * penalty / EXP
        uint256 unstakeCliff;       // Period between unstake intention and unstake
        bool closed;                // Closed pool is no longer available for new stakes, only unstake allowed
        uint256 tvl;                // Total amount of tokens locked in this pool
    }

    struct Stake {
        uint256 start;
        uint256 amount;
        uint256 unstakeIntentionTimestamp;
    }

    Pool[] public pools;
    mapping(address => mapping(uint256 => Stake[])) public stakes;
    address public penaltyBeneficiary;
    uint256 public adminUnstakePenalty;

    constructor() {
        penaltyBeneficiary = owner();
    }

    function addPool(IERC20 token, uint256 cliff, uint256 duration, uint256 penalty, uint256 unstakeCliff) external onlyOwner returns(uint256) {
        require(penalty < EXP, "penalty >= 100%");
        require(duration >= cliff, "wrong duration"); //Infinite pool can be created with zero cliff && zero duration
        uint256 poolId = pools.length;
        pools.push(Pool({
            token: token,
            cliff: cliff,
            duration: duration,
            penalty:penalty,
            unstakeCliff:unstakeCliff,
            closed:false,
            tvl: 0
        }));
        emit PoolAdded(poolId, address(token), cliff, duration, penalty, unstakeCliff);
        return poolId;
    }

    function closePool(uint256 poolId) external onlyOwner {
        Pool storage pool = pools[poolId];
        require(address(pool.token) != address(0), "pool not found");
        require(!pool.closed, "already closed");
        pool.closed = true;
        emit PoolClosed(poolId);
    }

    function setPenaltyBeneficiary(address _penaltyBeneficiary) external onlyOwner {
        penaltyBeneficiary = _penaltyBeneficiary;
    }

    function setAdminUnstakePenalty(uint256 _adminUnstakePenalty) external onlyOwner {
        require(_adminUnstakePenalty < EXP, "penalty >= 100%");
        adminUnstakePenalty = _adminUnstakePenalty;
    }

    function stake(uint256 poolId, uint256 amount) external {
        stakeInternal(_msgSender(), poolId, amount);
    }

    function stakeFor(address beneficiary, uint256 poolId, uint256 amount) external {
        stakeInternal(beneficiary, poolId, amount);
    }

     /**
     * @notice Intention to unstake from specific stake
     * @param poolId Pool to unstake from
     * @param stakeId Stake to unstake from
     */
    function unstakeIntention(uint256 poolId, uint256 stakeId) external {
        unstakeIntentionInternal(_msgSender(), poolId, stakeId);
    }

     /**
     * @notice Unstake from specific stake
     * @param poolId Pool to unstake from
     * @param stakeId Stake to unstake from
     * @param amount Amount to unstake
     */
    function unstakeExactStake(uint256 poolId, uint256 stakeId, uint256 amount) external {
        unstakeExactStakeInternal(_msgSender(), poolId, stakeId, amount);
    }

    /**
     * @notice Unstake from specific stakes
     * @param poolId Pool to unstake from
     * @param stakeIds Array of stake ids to use for unstake, must be sorted in ascending order
     * @param amounts Array of amounts corresponding to stake ids
     */
    function unstakeExactStakes(uint256 poolId, uint256[] calldata stakeIds, uint256[] calldata amounts) external {
        require(stakeIds.length == amounts.length, "arrays length mismatch");
        unstakeExactStakesInternal(_msgSender(), poolId, stakeIds, amounts);
    }

     /**
     * @notice Unstake + stake to another pool
     * @param fromPoolId Pool to unstake from
     * @param stakeId Stake to unstake from
     * @param amount Amount to unstake
     * @param toPoolId Pool to stake to
     */
    function restake(uint256 fromPoolId, uint256 stakeId, uint256 amount, uint256 toPoolId) external {
        restakeExactStakeInternal(_msgSender(), fromPoolId, stakeId, amount, toPoolId);
    }


    function userStakesAndPenalties(address beneficiary, uint256 poolId) external view
    returns(uint256[] memory stakeStarts, uint256[] memory stakeAmounts, uint256[] memory penalties) {
        Pool storage pool = pools[poolId];
        require(address(pool.token) != address(0), "pool not found");
        Stake[] storage userStakes = stakes[beneficiary][poolId];

        stakeStarts = new uint256[](userStakes.length);
        stakeAmounts = new uint256[](userStakes.length);
        penalties = new uint256[](userStakes.length);

        for(uint256 i=0; i<userStakes.length; i++) {
            Stake storage stakee = userStakes[i];
            stakeStarts[i] = stakee.start;
            stakeAmounts[i] = stakee.amount;
            uint256 unstakeTimestamp = (stakee.unstakeIntentionTimestamp == 0)?block.timestamp:stakee.unstakeIntentionTimestamp;
            uint256 penaltieForFullUnstake = calculateUnstakePenalty(pool, stakee, stakee.amount, unstakeTimestamp);
            if (penaltieForFullUnstake == 0) {
                penalties[i] = 0;    
            } else if(penaltieForFullUnstake == stakee.amount) {
                penalties[i] = EXP;
            } else {
                penalties[i] = penaltieForFullUnstake.mul(EXP).div(stakee.amount);
            }
        }
    }

    function allUserStakesAndPenalties(address beneficiary) external view
    returns(uint256[] memory stakePools, uint256[] memory stakeIds, uint256[] memory stakeStarts, uint256[] memory stakeAmounts, uint256[] memory penalties, uint256[] memory unstakeIntentionTimestamps) {
        uint256 totalStakes;
        for(uint256 p=0; p<pools.length; p++){
            totalStakes += stakes[beneficiary][p].length;
        }
        
        stakePools = new uint256[](totalStakes);
        stakeIds = new uint256[](totalStakes);
        stakeStarts = new uint256[](totalStakes);
        stakeAmounts = new uint256[](totalStakes);
        penalties = new uint256[](totalStakes);
        unstakeIntentionTimestamps = new uint256[](totalStakes);

        uint256 idx;
        for(uint256 p=0; p<pools.length; p++){
            Stake[] storage userStakes = stakes[beneficiary][p];
            if(userStakes.length == 0) continue;

            Pool storage pool = pools[p];
            for(uint256 i=0; i<userStakes.length; i++) {
                Stake storage stakee = userStakes[i];
                stakePools[idx] = p;
                stakeIds[idx] = i;
                stakeStarts[idx] = stakee.start;
                stakeAmounts[idx] = stakee.amount;
                unstakeIntentionTimestamps[idx] = stakee.unstakeIntentionTimestamp;
                uint256 unstakeTimestamp = (stakee.unstakeIntentionTimestamp == 0)?block.timestamp:stakee.unstakeIntentionTimestamp;
                uint256 penaltieForFullUnstake = calculateUnstakePenalty(pool, stakee, stakee.amount, unstakeTimestamp);
                if (penaltieForFullUnstake == 0) {
                    penalties[idx] = 0;    
                } else if(penaltieForFullUnstake == stakee.amount) {
                    penalties[idx] = EXP;
                } else {
                    penalties[idx] = penaltieForFullUnstake.mul(EXP).div(stakee.amount);
                }
                idx++;
            }
        }
    }


    function stakeInternal(address beneficiary, uint256 poolId, uint256 amount) internal {
        Pool storage pool = pools[poolId];
        require(address(pool.token) != address(0), "pool not found");
        require(!pool.closed, "pool closed");

        pool.token.safeTransferFrom(_msgSender(), address(this), amount);

        Stake[] storage userStakes = stakes[beneficiary][poolId];
        uint256 stakeId = userStakes.length;
        userStakes.push(Stake({
            start: block.timestamp,
            amount: amount,
            unstakeIntentionTimestamp: 0
        }));
        pool.tvl = pool.tvl.add(amount);
        emit Staked(address(pool.token), poolId, beneficiary, stakeId, amount, pool.duration);
    }

    function unstakeIntentionInternal(address beneficiary, uint256 poolId, uint256 stakeId) internal {
        Pool storage pool = pools[poolId];
        require(address(pool.token) != address(0), "pool not found");
        Stake[] storage userStakes = stakes[beneficiary][poolId];
        require(userStakes.length > 0, "no stakes");
        require(stakeId < userStakes.length, "wrong stake id");

        Stake storage stakee = userStakes[stakeId];
        stakee.unstakeIntentionTimestamp = block.timestamp;
        emit UnstakeIntention(address(pool.token), poolId, beneficiary, stakeId, stakee.amount);
    }


    function adminUnstakeExactStake(address beneficiary, uint256 poolId, uint256 stakeId, uint256 unstakeAmount) external onlyOwner {
        Pool storage pool = pools[poolId];
        require(address(pool.token) != address(0), "pool not found");
        Stake[] storage userStakes = stakes[beneficiary][poolId];
        require(userStakes.length > 0, "no stakes");
        require(stakeId < userStakes.length, "wrong stake id");

        Stake storage stakee = userStakes[stakeId];
        require(unstakeAmount <= stakee.amount, "unstakeAmount too high");

        uint256 penaltyAmount = unstakeAmount.mul(adminUnstakePenalty).div(EXP);
        uint256 userAmount = unstakeAmount.sub(penaltyAmount);
        stakee.amount = stakee.amount.sub(unstakeAmount);
        stakee.unstakeIntentionTimestamp = 0;

        if(stakee.unstakeIntentionTimestamp == 0){
            emit UnstakeIntention(address(pool.token), poolId, beneficiary, stakeId, unstakeAmount);
        }
        emit Unstaked(address(pool.token), poolId, beneficiary, stakeId, unstakeAmount, penaltyAmount);
        pool.tvl = pool.tvl.sub(unstakeAmount);

        pool.token.safeTransfer(beneficiary, userAmount);
        if(penaltyAmount > 0) {
            pool.token.safeTransfer(penaltyBeneficiary, penaltyAmount);
        }
    }

    function unstakeExactStakeInternal(address beneficiary, uint256 poolId, uint256 stakeId, uint256 unstakeAmount) internal {
        Pool storage pool = pools[poolId];
        require(address(pool.token) != address(0), "pool not found");
        Stake[] storage userStakes = stakes[beneficiary][poolId];
        require(userStakes.length > 0, "no stakes");
        require(stakeId < userStakes.length, "wrong stake id");

        Stake storage stakee = userStakes[stakeId];
        (uint256 userAmount, uint256 penaltyAmount) = prepareUnstakeExactStake(pool, stakee, unstakeAmount, false);
        stakee.amount = stakee.amount.sub(unstakeAmount);
        emit Unstaked(address(pool.token), poolId, beneficiary, stakeId, unstakeAmount, penaltyAmount);
        pool.tvl = pool.tvl.sub(unstakeAmount);

        pool.token.safeTransfer(beneficiary, userAmount);
        if(penaltyAmount > 0) {
            pool.token.safeTransfer(penaltyBeneficiary, penaltyAmount);
        }
    }

    function unstakeExactStakesInternal(address beneficiary, uint256 poolId, uint256[] memory stakeIds, uint256[] memory amounts) internal {
        Pool storage pool = pools[poolId];
        require(address(pool.token) != address(0), "pool not found");
        Stake[] storage userStakes = stakes[beneficiary][poolId];
        require(userStakes.length > 0, "no stakes");

        //require(stakeIds.length == amounts.length, "arrays length mismatch"); //Here we assume its already checked
        uint256 prevStakeId;
        uint256 totalUserAmount;
        uint256 totalPenaltyAmount;

        for (uint256 i=0; i<stakeIds.length; i++) {
            uint256 stakeId = stakeIds[i];
            require(i==0 || prevStakeId < stakeId, "unsorted stake ids"); // Prevent unstaking from same stake twice
            require(stakeId < userStakes.length, "wrong stake id");
            prevStakeId = stakeId;

            Stake storage stakee = userStakes[stakeId];
            (uint256 userAmount, uint256 penaltyAmount) = prepareUnstakeExactStake(pool, stakee, amounts[i], false);
            stakee.amount = stakee.amount.sub(amounts[i]);
            emit Unstaked(address(pool.token), poolId, beneficiary, stakeIds[i], amounts[i], penaltyAmount);

            totalUserAmount = totalUserAmount.add(userAmount);
            totalPenaltyAmount = totalPenaltyAmount.add(penaltyAmount);
        }

        pool.tvl = pool.tvl.sub(totalUserAmount).sub(totalPenaltyAmount);

        pool.token.safeTransfer(beneficiary, totalUserAmount);
        if(totalPenaltyAmount > 0) {
            pool.token.safeTransfer(penaltyBeneficiary, totalPenaltyAmount);
        }
    }

    function restakeExactStakeInternal(address beneficiary, uint256 fromPoolId, uint256 stakeId, uint256 amount, uint256 toPoolId) internal {
        Pool storage pool = pools[fromPoolId];
        require(address(pool.token) != address(0), "pool not found");

        Pool storage toPool = pools[toPoolId];
        require(address(pool.token) == address(toPool.token), "different pool tokens");

        bool ignoreUnstake = (toPool.duration >= pool.duration); // Allow restake without intention to a pool with longer duration

        Stake[] storage userStakes = stakes[beneficiary][fromPoolId];
        require(userStakes.length > 0, "no stakes");
        require(stakeId < userStakes.length, "wrong stake id");

        Stake storage stakee = userStakes[stakeId];
        (uint256 userAmount, uint256 penaltyAmount) = prepareUnstakeExactStake(pool, stakee, amount, ignoreUnstake);
        stakee.amount = stakee.amount.sub(amount);

        if(stakee.unstakeIntentionTimestamp == 0){
            emit UnstakeIntention(address(pool.token), fromPoolId, beneficiary, stakeId, amount);
        }

        emit Unstaked(address(pool.token), fromPoolId, beneficiary, stakeId, amount, penaltyAmount);
        pool.tvl = pool.tvl.sub(amount);

        //pool.token.safeTransfer(beneficiary, userAmount); // Do not transfer to user because we restake it

        userStakes = stakes[beneficiary][toPoolId];
        uint256 toStakeId = userStakes.length;
        userStakes.push(Stake({
            start: block.timestamp,
            amount: userAmount,
            unstakeIntentionTimestamp: 0
        }));
        toPool.tvl = toPool.tvl.add(userAmount);
        emit Staked(address(toPool.token), toPoolId, beneficiary, toStakeId, userAmount, pool.duration);

        if(penaltyAmount > 0) {
            pool.token.safeTransfer(penaltyBeneficiary, penaltyAmount);
        }

    }
    
    function prepareUnstakeExactStake(Pool storage pool, Stake storage stakee, uint256 amount, bool ignoreUnstake) internal
    returns(uint256 userAmount, uint256 penaltyAmount) {
        require(stakee.start > 0, "incorrect stake"); // should never happen, but just to be sure...

        require(amount > 0, "wrong amount");
        require(amount <= stakee.amount, "high amount"); 

        uint256 unstakeTimestamp = block.timestamp;
        if(pool.unstakeCliff > 0) {
            if(!ignoreUnstake) {
                require(stakee.unstakeIntentionTimestamp > 0, "no unstake intention");
                require(stakee.unstakeIntentionTimestamp.add(pool.unstakeCliff) <= block.timestamp, "unstake cliff not passed");
                unstakeTimestamp = stakee.unstakeIntentionTimestamp;
            }
            stakee.unstakeIntentionTimestamp = 0;
        }

        if(pool.duration > 0) {
            penaltyAmount = calculateUnstakePenalty(pool, stakee, amount, unstakeTimestamp);
            require(penaltyAmount < amount, "unstake not available yet");
            userAmount = amount - penaltyAmount;
            return (userAmount, penaltyAmount);
        } else {
            return (amount, 0);
        }
    }

    /**
     * @notice Calculates penalty amount
     * @dev if penalty == unstakeAmount, that indicates that unstake is forbidden
     * @param pool Pool of the stake
     * @param stakee Stake to unstake from
     * @param unstakeAmount Amount to unstake
     * @param unstakeTimestamp Timestamp of unstake action (usually timestamp of unstake intention)
     * @return penalty amount
     */
    function calculateUnstakePenalty(Pool storage pool, Stake storage stakee, uint256 unstakeAmount, uint256 unstakeTimestamp) internal view returns(uint256) {
        uint256 timePassed = unstakeTimestamp.sub(stakee.start);
        if(timePassed >= pool.duration) return 0;
        if(timePassed < pool.cliff) return unstakeAmount; //unstake is prohibited

        uint256 penaltyTimeLeft = pool.duration.sub(timePassed);
        uint256 linearVestingDuration = pool.duration.sub(pool.cliff); 
        // penaltyTimePeriod != 0 because if pool.duration == pool.cliff, then one of conditions above will be true
        return unstakeAmount.mul(pool.penalty).mul(penaltyTimeLeft).div(linearVestingDuration).div(EXP);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity ^0.7.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

