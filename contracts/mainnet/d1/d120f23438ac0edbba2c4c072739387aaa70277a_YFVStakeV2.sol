/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: YFIRewards.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

// File: @openzeppelin/contracts/math/Math.sol

pragma solidity 0.5.17;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity 0.5.17;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity 0.5.17;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity 0.5.17;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity 0.5.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

    function mint(address account, uint amount) external;

    function burn(uint amount) external;

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

    /** YFV, vUSD, vETH has minters **/
    function minters(address account) external view returns (bool);

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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity 0.5.17;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity 0.5.17;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/IRewardDistributionRecipient.sol

pragma solidity 0.5.17;


contract IRewardDistributionRecipient is Ownable {
    address public rewardReferral;

    function notifyRewardAmount(uint256 reward) external;

    function setRewardReferral(address _rewardReferral) external onlyOwner {
        rewardReferral = _rewardReferral;
    }
}

// File: contracts/CurveRewards.sol

pragma solidity 0.5.17;


contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    IERC20 public yfv = IERC20(0x45f24BaEef268BB6d63AEe5129015d69702BCDfa);

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function tokenStake(uint256 amount, uint256 actualStakeAmount) internal {
        _totalSupply = _totalSupply.add(actualStakeAmount);
        _balances[msg.sender] = _balances[msg.sender].add(actualStakeAmount);
        yfv.safeTransferFrom(msg.sender, address(this), amount);
    }

    function tokenStakeOnBehalf(address stakeFor, uint256 amount, uint256 actualStakeAmount) internal {
        _totalSupply = _totalSupply.add(actualStakeAmount);
        _balances[stakeFor] = _balances[stakeFor].add(actualStakeAmount);
        yfv.safeTransferFrom(msg.sender, address(this), amount);
    }

    function tokenWithdraw(uint256 amount, uint256 actualWithdrawAmount) internal {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        yfv.safeTransfer(msg.sender, actualWithdrawAmount);
    }
}

interface IYFVReferral {
    function setReferrer(address farmer, address referrer) external;
    function getReferrer(address farmer) external view returns (address);
}

contract YFVStakeV2 is LPTokenWrapper, IRewardDistributionRecipient {
    IERC20 public vUSD = IERC20(0x1B8E12F839BD4e73A47adDF76cF7F0097d74c14C);
    IERC20 public vETH = IERC20(0x76A034e76Aa835363056dd418611E4f81870f16e);

    uint256 public vETH_REWARD_FRACTION_RATE = 1000;

    uint256 public constant DURATION = 7 days;
    uint8 public constant NUMBER_EPOCHS = 38;

    uint256 public constant REFERRAL_COMMISSION_PERCENT = 1;

    uint256 public currentEpochReward = 0;
    uint256 public totalAccumulatedReward = 0;
    uint8 public currentEpoch = 0;
    uint256 public starttime = 1598968800; // Tuesday, September 1, 2020 2:00:00 PM (GMT+0)
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    uint256 public constant DEFAULT_EPOCH_REWARD = 230000 * (10 ** 9); // 230,000 vUSD (and 230 vETH)
    uint256 public constant TOTAL_REWARD = DEFAULT_EPOCH_REWARD * NUMBER_EPOCHS; // 8,740,000 vUSD (and 8,740 vETH)

    uint256 public epochReward = DEFAULT_EPOCH_REWARD;
    uint256 public minStakingAmount = 90 ether;
    uint256 public unstakingFrozenTime = 40 hours;

    // ** DISABLED AT BEGINNING - WILL SET IT BY GOVERNANCE AFTER VIP-1.1
    // ** unlockWithdrawFee = 0.1%: stakers will need to pay 0.1% (sent to insurance fund)of amount they want to withdraw if the coin still frozen
    // ** lowStakeDepositFee = 0.1%: stakers still can stake with low amount but need to pay 0.1% (sent to insurance fund)
    //    specially, if lowStakeDepositFee = 10000 -> low amount stakers will not pay anything (richmen pay tax, not poormen)
    // ** highStakeDepositFee = 0.1%: stakers need to pay 0.1% of extra amount more than 90 YFV (sent to insurance fund)
    uint256 public lowStakeDepositFee = 0; // per ten thousand (eg. 15 -> 0.15%)
    uint256 public highStakeDepositFee = 0; // per ten thousand (eg. 15 -> 0.15%)
    uint256 public unlockWithdrawFee = 0; // per ten thousand (eg. 15 -> 0.15%)

    address public yfvInsuranceFund = 0xb7b2Ea8A1198368f950834875047aA7294A2bDAa; // set to Governance Multisig at start

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastStakeTimes;

    mapping(address => uint256) public accumulatedStakingPower; // will accumulate every time staker does getReward()

    mapping(address => bool) public whitelistedPools; // for stake on behalf

    event RewardAdded(uint256 reward);
    event YfvRewardAdded(uint256 reward);
    event Burned(uint256 reward);
    event Staked(address indexed user, uint256 amount, uint256 actualStakeAmount);
    event Withdrawn(address indexed user, uint256 amount, uint256 actualWithdrawAmount);
    event RewardPaid(address indexed user, uint256 reward);
    event CommissionPaid(address indexed user, uint256 reward);

    constructor() public {
        whitelistedPools[0x62a9fE913eb596C8faC0936fd2F51064022ba22e] = true; // BAL Pool
        whitelistedPools[0x70b83A7f5E83B3698d136887253E0bf426C9A117] = true; // YFI Pool
        whitelistedPools[0x1c990fC37F399C935625b815975D0c9fAD5C31A1] = true; // BAT Pool
        whitelistedPools[0x752037bfEf024Bd2669227BF9068cb22840174B0] = true; // REN Pool
        whitelistedPools[0x9b74774f55C0351fD064CfdfFd35dB002C433092] = true; // KNC Pool
        whitelistedPools[0xFBDE07329FFc9Ec1b70f639ad388B94532b5E063] = true; // BTC Pool
        whitelistedPools[0x67FfB615EAEb8aA88fF37cCa6A32e322286a42bb] = true; // ETH Pool
        whitelistedPools[0x196CF719251579cBc850dED0e47e972b3d7810Cd] = true; // LINK Pool
        whitelistedPools[msg.sender] = true; // to be able to stakeOnBehalf farmer who have stucked fund in Pool Stake v1.
    }

    function addWhitelistedPool(address _addressPool) public onlyOwner {
        whitelistedPools[_addressPool] = true;
    }

    function removeWhitelistedPool(address _addressPool) public onlyOwner {
        whitelistedPools[_addressPool] = false;
    }

    function setYfvInsuranceFund(address _yfvInsuranceFund) public onlyOwner {
        yfvInsuranceFund = _yfvInsuranceFund;
    }

    function setEpochReward(uint256 _epochReward) public onlyOwner {
        require(_epochReward <= DEFAULT_EPOCH_REWARD * 10, "Insane big _epochReward!"); // At most 10x only
        epochReward = _epochReward;
    }

    function setMinStakingAmount(uint256 _minStakingAmount) public onlyOwner {
        minStakingAmount = _minStakingAmount;
    }

    function setUnstakingFrozenTime(uint256 _unstakingFrozenTime) public onlyOwner {
        unstakingFrozenTime = _unstakingFrozenTime;
    }

    function setStakeDepositFee(uint256 _lowStakeDepositFee, uint256 _highStakeDepositFee) public onlyOwner {
        require(_lowStakeDepositFee <= 100 || _lowStakeDepositFee == 10000, "Dont be too greedy"); // <= 1% OR set to 10000 to disable low stake fee
        require(_highStakeDepositFee <= 100, "Dont be too greedy"); // <= 1%
        lowStakeDepositFee = _lowStakeDepositFee;
        highStakeDepositFee = _highStakeDepositFee;
    }

    function setUnlockWithdrawFee(uint256 _unlockWithdrawFee) public onlyOwner {
        require(_unlockWithdrawFee <= 1000, "Dont be too greedy"); // <= 10%
        unlockWithdrawFee = _unlockWithdrawFee;
    }

    // To upgrade vUSD contract (v1 is still experimental, we may need vUSDv2 with rebase() function working soon - then governance will call this upgrade)
    function upgradeVUSDContract(address _vUSDContract) public onlyOwner {
        vUSD = IERC20(_vUSDContract);
    }

    // To upgrade vETH contract (v1 is still experimental, we may need vETHv2 with rebase() function working soon - then governance will call this upgrade)
    function upgradeVETHContract(address _vETHContract) public onlyOwner {
        vETH = IERC20(_vETHContract);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(1e18)
            .div(totalSupply())
        );
    }

    // vUSD balance
    function earned(address account) public view returns (uint256) {
        uint256 calculatedEarned = balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
        uint256 poolBalance = vUSD.balanceOf(address(this));
        // some rare case the reward can be slightly bigger than real number, we need to check against how much we have left in pool
        if (calculatedEarned > poolBalance) return poolBalance;
        return calculatedEarned;
    }

    function stakingPower(address account) public view returns (uint256) {
        return accumulatedStakingPower[account].add(earned(account));
    }

    function vETHBalance(address account) public view returns (uint256) {
        return earned(account).div(vETH_REWARD_FRACTION_RATE);
    }

    function stake(uint256 amount, address referrer) public updateReward(msg.sender) checkNextEpoch {
        require(amount >= 1 szabo, "Do not stake dust");
        require(referrer != msg.sender, "You cannot refer yourself.");
        uint256 actualStakeAmount = amount;
        uint256 depositFee = 0;
        if (minStakingAmount > 0) {
            if (amount < minStakingAmount && lowStakeDepositFee < 10000) {
                // if amount is less than minStakingAmount and lowStakeDepositFee is not disabled

                // if governance does not allow low stake
                if (lowStakeDepositFee == 0) require(amount >= minStakingAmount, "Cannot stake below minStakingAmount");
                // otherwise depositFee will be calculated based on the rate
                else depositFee = amount.mul(lowStakeDepositFee).div(10000);
            } else if (amount > minStakingAmount && highStakeDepositFee > 0) {
                // if amount is greater than minStakingAmount and governance decides richman to pay tax (of the extra amount)
                depositFee = amount.sub(minStakingAmount).mul(highStakeDepositFee).div(10000);
            }
            if (depositFee > 0) {
                actualStakeAmount = amount.sub(depositFee);
            }
        }
        super.tokenStake(amount, actualStakeAmount);
        lastStakeTimes[msg.sender] = block.timestamp;
        emit Staked(msg.sender, amount, actualStakeAmount);
        if (depositFee > 0) {
            if (yfvInsuranceFund != address(0)) { // send fee to insurance
                yfv.safeTransfer(yfvInsuranceFund, depositFee);
                emit RewardPaid(yfvInsuranceFund, depositFee);
            } else { // or burn
                yfv.burn(depositFee);
                emit Burned(depositFee);
            }
        }
        if (rewardReferral != address(0) && referrer != address(0)) {
            IYFVReferral(rewardReferral).setReferrer(msg.sender, referrer);
        }
    }

    function stakeOnBehalf(address stakeFor, uint256 amount) public updateReward(stakeFor) checkNextEpoch {
        require(amount >= 1 szabo, "Do not stake dust");
        require(whitelistedPools[msg.sender], "Sorry hackers, you should stay away from us (YFV community signed)");
        uint256 actualStakeAmount = amount;
        uint256 depositFee = 0;
        if (minStakingAmount > 0) {
            if (amount < minStakingAmount && lowStakeDepositFee < 10000) {
                // if amount is less than minStakingAmount and lowStakeDepositFee is not disabled

                // if governance does not allow low stake
                if (lowStakeDepositFee == 0) require(amount >= minStakingAmount, "Cannot stake below minStakingAmount");

                // otherwise depositFee will be calculated based on the rate
                else depositFee = amount.mul(lowStakeDepositFee).div(10000);
            } else if (amount > minStakingAmount && highStakeDepositFee > 0) {
                // if amount is greater than minStakingAmount and governance decides richman to pay tax (of the extra amount)
                depositFee = amount.sub(minStakingAmount).mul(highStakeDepositFee).div(10000);
            }
            if (depositFee > 0) {
                actualStakeAmount = amount.sub(depositFee);
            }
        }
        super.tokenStakeOnBehalf(stakeFor, amount, actualStakeAmount);
        lastStakeTimes[stakeFor] = block.timestamp;
        emit Staked(stakeFor, amount, actualStakeAmount);
        if (depositFee > 0) {
            actualStakeAmount = amount.sub(depositFee);
            if (yfvInsuranceFund != address(0)) { // send fee to insurance
                yfv.safeTransfer(yfvInsuranceFund, depositFee);
                emit RewardPaid(yfvInsuranceFund, depositFee);
            } else { // or burn
                yfv.burn(depositFee);
                emit Burned(depositFee);
            }
        }
    }

    function unfrozenStakeTime(address account) public view returns (uint256) {
        return lastStakeTimes[account] + unstakingFrozenTime;
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) checkNextEpoch {
        require(amount > 0, "Cannot withdraw 0");
        uint256 actualWithdrawAmount = amount;
        if (block.timestamp < unfrozenStakeTime(msg.sender)) {
            // if coin is still frozen and governance does not allow stakers to unstake before timer ends
            if (unlockWithdrawFee == 0) revert("Coin is still frozen");

            // otherwise withdrawFee will be calculated based on the rate
            uint256 withdrawFee = amount.mul(unlockWithdrawFee).div(10000);
            actualWithdrawAmount = amount.sub(withdrawFee);
            if (yfvInsuranceFund != address(0)) { // send fee to insurance
                yfv.safeTransfer(yfvInsuranceFund, withdrawFee);
                emit RewardPaid(yfvInsuranceFund, withdrawFee);
            } else { // or burn
                yfv.burn(withdrawFee);
                emit Burned(withdrawFee);
            }
        }
        super.tokenWithdraw(amount, actualWithdrawAmount);
        emit Withdrawn(msg.sender, amount, actualWithdrawAmount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkNextEpoch {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            accumulatedStakingPower[msg.sender] = accumulatedStakingPower[msg.sender].add(rewards[msg.sender]);
            rewards[msg.sender] = 0;

            vUSD.safeTransfer(msg.sender, reward);
            vETH.safeTransfer(msg.sender, reward.div(vETH_REWARD_FRACTION_RATE));

            emit RewardPaid(msg.sender, reward);
        }
    }

    modifier checkNextEpoch() {
        require(periodFinish > 0, "Pool has not started");
        if (block.timestamp >= periodFinish) {
            currentEpochReward = epochReward;

            if (totalAccumulatedReward.add(currentEpochReward) > TOTAL_REWARD) {
                currentEpochReward = TOTAL_REWARD.sub(totalAccumulatedReward); // limit total reward
            }

            if (currentEpochReward > 0) {
                if (!vUSD.minters(address(this)) || !vETH.minters(address(this))) {
                    currentEpochReward = 0;
                } else {
                    vUSD.mint(address(this), currentEpochReward);
                    vETH.mint(address(this), currentEpochReward.div(vETH_REWARD_FRACTION_RATE));
                    totalAccumulatedReward = totalAccumulatedReward.add(currentEpochReward);
                }
                currentEpoch++;
            }

            rewardRate = currentEpochReward.div(DURATION);
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(currentEpochReward);
        }
        _;
    }

    // Start the pool with reward amount for this epoch
    function notifyRewardAmount(uint256 reward) external onlyOwner updateReward(address(0)) {
        require(periodFinish == 0, "Only can call once to start staking");
        currentEpochReward = reward;
        if (totalAccumulatedReward.add(currentEpochReward) > TOTAL_REWARD) {
            currentEpochReward = TOTAL_REWARD.sub(totalAccumulatedReward); // limit total reward
        }
        lastUpdateTime = block.timestamp;
        if (block.timestamp < starttime) { // epoch zero
            periodFinish = starttime;
            rewardRate = reward.div(periodFinish.sub(block.timestamp));
        } else { // 1st epoch
            periodFinish = lastUpdateTime.add(DURATION);
            rewardRate = reward.div(DURATION);
            currentEpoch++;
        }
        vUSD.mint(address(this), reward);
        vETH.mint(address(this), reward.div(vETH_REWARD_FRACTION_RATE));
        totalAccumulatedReward = totalAccumulatedReward.add(reward);
        emit RewardAdded(reward);
    }

    // This function allows governance to take unsupported tokens out of the contract, since this pool exists longer than the other pools.
    // This is in an effort to make someone whole, should they seriously mess up.
    // There is no guarantee governance will vote to return these.
    // It also allows for removal of airdropped tokens.
    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external {
        // only gov
        require(msg.sender == owner(), "!governance");
        // cant take staked asset
        require(_token != yfv, "yfv");
        // cant take reward asset
        require(_token != vUSD, "vUSD");
        require(_token != vETH, "vETH");

        // transfer to
        _token.safeTransfer(to, amount);
    }
}