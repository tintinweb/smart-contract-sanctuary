/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// Dependency file: contracts/libraries/Math.sol

// pragma solidity ^0.6.12;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


// Dependency file: contracts/libraries/SafeMath.sol

// pragma solidity ^0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
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



// Dependency file: contracts/interfaces/IERC20.sol

// pragma solidity ^0.6.12;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


// Dependency file: contracts/libraries/Address.sol

// pragma solidity ^0.6.12;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [// importANT]
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
     * // importANT: because control is transferred to `recipient`, care must be
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
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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

// Dependency file: contracts/libraries/SafeERC20.sol

// pragma solidity ^0.6.12;

// import "contracts/interfaces/IERC20.sol";
// import "contracts/libraries/SafeMath.sol";
// import "contracts/libraries/Address.sol";

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

// Dependency file: contracts/interfaces/IWSERC20.sol

// pragma solidity ^0.6.12;

interface IWSERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}


// Dependency file: contracts/interfaces/IStakingRewards.sol

// pragma solidity ^0.6.12;


interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

// Dependency file: contracts/ReentrancyGuard.sol

// pragma solidity ^0.6.0;

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


// Root file: contracts/staking/StakingRewardsV2.sol

pragma solidity ^0.6.12;


// import 'contracts/libraries/Math.sol';
// import 'contracts/libraries/SafeMath.sol';
// import "contracts/libraries/SafeERC20.sol";

// import 'contracts/interfaces/IERC20.sol';
// import 'contracts/interfaces/IWSERC20.sol';
// import 'contracts/interfaces/IStakingRewards.sol';

// import 'contracts/ReentrancyGuard.sol';

contract StakingRewardsV2 is ReentrancyGuard, IStakingRewards {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool public initialized;
    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    address public rewardsDistributor;
    address public externalController;

    struct RewardEpoch {
        uint id;
        uint totalSupply;
        uint startEpoch;
        uint finishEpoch;
        uint rewardRate;
        uint lastUpdateTime;
        uint rewardPerTokenStored;
    }
    // epoch
    mapping(uint => RewardEpoch) public epochData;
    mapping(uint => mapping(address => uint)) public userRewardPerTokenPaid;
    mapping(uint => mapping(address => uint)) public rewards;
    mapping(uint => mapping(address => uint)) private _balances;
    mapping(address => uint) public lastAccountEpoch;
    uint public currentEpochId;

    function initialize(
        address _externalController,
        address _rewardsDistributor,
        address _rewardsToken,
        address _stakingToken
        ) external {
            require(initialized == false, "Contract already initialized.");
            rewardsToken = IERC20(_rewardsToken);
            stakingToken = IERC20(_stakingToken);
            rewardsDistributor = _rewardsDistributor;
            externalController = _externalController;
            initialized = true;
    }

    function fixPool(bool recalcRate, address[] memory accounts) public {
        // require(msg.sender == address(0x95Db09ff2644eca19cB4b99318483254BFD52dAe), "Not allowed");
        RewardEpoch memory curepoch = epochData[currentEpochId];
        if (recalcRate) {
            uint rewardsDuration = curepoch.finishEpoch - block.timestamp;
            epochData[currentEpochId].rewardRate = rewardsToken.balanceOf(address(this)).div(rewardsDuration);
            epochData[currentEpochId].lastUpdateTime = block.timestamp;
            epochData[currentEpochId].startEpoch = block.timestamp;
            epochData[currentEpochId].rewardPerTokenStored = 0;
            _updateRewardForEpoch(address(0), currentEpochId);
        }
        if (accounts.length > 0){
            for(uint i = 0; i < accounts.length; i++) {
                delete rewards[currentEpochId][accounts[i]];
                userRewardPerTokenPaid[currentEpochId][accounts[i]] = 0;
                _updateRewardForEpoch(accounts[i], currentEpochId);
            }
        }
        initialized = true;
    }

    function _totalSupply(uint epoch) internal view returns (uint) {
        return epochData[epoch].totalSupply;
    }

    function _balanceOf(uint epoch, address account) public view returns (uint) {
        return _balances[epoch][account];
    }

    function _lastTimeRewardApplicable(uint epoch) internal view returns (uint) {
        if (block.timestamp < epochData[epoch].startEpoch) {
            return epochData[epoch].startEpoch;
        }
        return Math.min(block.timestamp, epochData[epoch].finishEpoch);
    }

    function totalSupply() external override view returns (uint) {
        return _totalSupply(currentEpochId);
    }

    function balanceOf(address account) external override view returns (uint) {
        return _balanceOf(currentEpochId, account);
    }

    function lastTimeRewardApplicable() public override view returns (uint) {
        return _lastTimeRewardApplicable(currentEpochId);
    }

    function _rewardPerToken(uint _epoch) internal view returns (uint) {
        RewardEpoch memory epoch = epochData[_epoch];
        if (epoch.totalSupply == 0) {
            return epoch.rewardPerTokenStored;
        }
        return
            epoch.rewardPerTokenStored.add(
                _lastTimeRewardApplicable(_epoch).sub(epoch.lastUpdateTime).mul(epoch.rewardRate).mul(1e18).div(epoch.totalSupply)
            );
    }

    function rewardPerToken() public override view returns (uint) {
        _rewardPerToken(currentEpochId);
    }

    function _earned(uint _epoch, address account) internal view returns (uint256) {
        return _balances[_epoch][account].mul(_rewardPerToken(_epoch).sub(userRewardPerTokenPaid[_epoch][account])).div(1e18).add(rewards[_epoch][account]);
    }

    function earned(address account) public override view returns (uint256) {
        return _earned(currentEpochId, account);
    }

    function getRewardForDuration() external override view returns (uint256) {
        RewardEpoch memory epoch = epochData[currentEpochId];
        return epoch.rewardRate.mul(epoch.finishEpoch - epoch.startEpoch);
    }

    function _stake(uint amount, bool withDepositTransfer) internal {
        require(amount > 0, "Cannot stake 0");
        require(currentEpochId > 0, "Any epoch should be started before stake");
        require(lastAccountEpoch[msg.sender] == currentEpochId || lastAccountEpoch[msg.sender] == 0, "Account should update epoch to stake.");
        epochData[currentEpochId].totalSupply = epochData[currentEpochId].totalSupply.add(amount);
        _balances[currentEpochId][msg.sender] = _balances[currentEpochId][msg.sender].add(amount);
        if(withDepositTransfer) {
            stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        }
        lastAccountEpoch[msg.sender] = currentEpochId;
        emit Staked(msg.sender, amount, currentEpochId);
    }

    function stake(uint256 amount) nonReentrant updateReward(msg.sender) override external {
        _stake(amount, true);
    }

    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external nonReentrant updateReward(msg.sender) {
        // permit
        IWSERC20(address(stakingToken)).permit(msg.sender, address(this), amount, deadline, v, r, s);
        _stake(amount, true);
    }

    function withdraw(uint256 amount) override public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        uint lastEpoch = lastAccountEpoch[msg.sender];
        epochData[lastEpoch].totalSupply = epochData[lastEpoch].totalSupply.sub(amount);
        _balances[lastEpoch][msg.sender] = _balances[lastEpoch][msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, lastEpoch);
    }

    function getReward() override public nonReentrant updateReward(msg.sender) {
        uint lastEpoch = lastAccountEpoch[msg.sender];
        uint reward = rewards[lastEpoch][msg.sender];
        if (reward > 0) {
            rewards[lastEpoch][msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() override external {
        withdraw(_balances[lastAccountEpoch[msg.sender]][msg.sender]);
        getReward();
        lastAccountEpoch[msg.sender] = 0;
    }

    function updateStakingEpoch() public {
        uint lastEpochId = lastAccountEpoch[msg.sender];
        if (lastEpochId != currentEpochId) {
            _updateRewardForEpoch(msg.sender, lastEpochId);

        // Remove record about staking on last account epoch
        uint stakedAmount = _balances[lastEpochId][msg.sender];
        _balances[lastEpochId][msg.sender] = 0;
        epochData[lastEpochId].totalSupply = epochData[lastEpochId].totalSupply.sub(stakedAmount);
        // Move collected rewards from last epoch to the current
        rewards[currentEpochId][msg.sender] = rewards[lastEpochId][msg.sender];
        rewards[lastEpochId][msg.sender] = 0;

        // Restake
        lastAccountEpoch[msg.sender] = currentEpochId;
        _stake(stakedAmount, false);
        }
    }

    function _updateRewardForEpoch(address account, uint epoch) internal {
        epochData[epoch].rewardPerTokenStored = _rewardPerToken(epoch);
        epochData[epoch].lastUpdateTime = _lastTimeRewardApplicable(epoch);
        if (account != address(0)) {
            rewards[epoch][account] = _earned(epoch, account);
            userRewardPerTokenPaid[epoch][account] = epochData[epoch].rewardPerTokenStored;
        }
    }


    modifier updateReward(address account) {
        uint lastEpoch = lastAccountEpoch[account];
        if(account == address(0) || lastEpoch == 0) {
            lastEpoch = currentEpochId;
        }
        _updateRewardForEpoch(account, lastEpoch);
        _;
    }

    function notifyRewardAmount(uint reward, uint startEpoch, uint finishEpoch) nonReentrant external {
        require(msg.sender == rewardsDistributor, "Only reward distribured allowed.");
        require(startEpoch >= block.timestamp, "Provided start date too late.");
        require(finishEpoch > startEpoch, "Wrong end date epoch.");
        require(reward > 0, "Wrong reward amount");
        uint rewardsDuration = finishEpoch - startEpoch;

        RewardEpoch memory newEpoch;
        // Initialize new epoch
        currentEpochId++;
        newEpoch.id = currentEpochId;
        newEpoch.startEpoch = startEpoch;
        newEpoch.finishEpoch = finishEpoch;
        newEpoch.rewardRate = reward.div(rewardsDuration);
        // last update time will be right when epoch starts
        newEpoch.lastUpdateTime = startEpoch;

        epochData[newEpoch.id] = newEpoch;

        emit EpochAdded(newEpoch.id, startEpoch, finishEpoch, reward);
    }

    function externalWithdraw() external {
        require(msg.sender == externalController, "Only external controller allowed.");
        rewardsToken.transfer(msg.sender, rewardsToken.balanceOf(msg.sender));
    }

    event EpochAdded(uint epochId, uint startEpoch, uint finishEpoch, uint256 reward);
    event Staked(address indexed user, uint amount, uint epoch);
    event Withdrawn(address indexed user, uint amount, uint epoch);
    event RewardPaid(address indexed user, uint reward);


}