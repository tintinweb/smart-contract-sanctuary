// SPDX-License-Identifier: MIT
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
    
    function decimals() external view returns (uint8);

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

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
    address private _governance;

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _governance = msgSender;
        emit GovernanceTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function governance() public view returns (address) {
        return _governance;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGovernance() {
        require(_governance == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferGovernance(address newOwner) internal virtual onlyGovernance {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit GovernanceTransferred(_governance, newOwner);
        _governance = newOwner;
    }
}

// File: contracts/strategies/StabilizeStrategyPickle.sol

pragma solidity ^0.6.6;

// This is a strategy that utilizes UNI ETH/USDT token in the Pickle.Finance protocol
// It deposits the LP token for pJar tokens
// It then deposits the pJar tokens into the pickle farm to earn pickle tokens
// It then uses the earned pickle tokens and stakes it into pickle staking to earn WETH
// It then collects the earn WETH and splits it among the depositors, the STBZ staking pool and the STBZ treasury
// The strategy doesn't sell any tokens via Uniswap so it shouldn't affect Pickle adversely
// The pickle earned via the farm are constantly being staked to earn more WETH for the users
// When a user withdraws, he/she receives a proportion of the total shares in LP token, Pickle and WETH

// Used to convert weth to eth upon withdraw
interface WrappedEther {
    function withdraw(uint) external; 
}

interface PickleJar {
    function getRatio() external view returns (uint256);
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function withdrawAll() external;
}

interface PickleFarm {
    function deposit(uint256, uint256) external;
    function withdraw(uint256, uint256) external;
    function userInfo(uint256, address) external view returns (uint256, uint256);
}

interface PickleStake {
    function stake(uint256) external;
    function withdraw(uint256) external;
    function exit() external;
    function earned(address) external view returns (uint256);
    function getReward() external;
}

interface StabilizeStakingPool {
    function notifyRewardAmount(uint256) external;
}

contract StabilizeStrategyPickleV1 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
    address public treasuryAddress; // Address of the treasury
    address public stakingAddress; // Address to the STBZ staking pool
    address public zsTokenAddress; // The address of the controlling zs-Token
    
    uint256 constant divisionFactor = 100000;
    uint256 public percentLPDepositor = 50000; // 1000 = 1%, LP depositors earn 50% of all WETH produced, 100% of everything else
    uint256 public percentStakers = 50000; // 50% of non LP WETH goes to stakers, can be changed
    
    // Reward tokens tokens list
    address[] rewardTokenList;
    
    // Info of each user.
    struct UserInfo {
        uint256 depositTime; // The time the user made the last deposit, token share is calculated from this
        uint256 balanceEstimate;
    }
    
    mapping(address => UserInfo) private userInfo;
    uint256 public weightedAverageDepositTime = 0; // Average time to enter
    
    // Strategy specific variables
    uint256 private _totalBalancePTokens = 0; // The total amount of pTokens currently staked/stored in contract
    uint256 private _stakedPickle = 0; // The amount of pickles being staked
    address constant wethAddress = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant pickleAddress = address(0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5);
    address constant pJarAddress = address(0x09FC573c502037B149ba87782ACC81cF093EC6ef); // Pickle jar address / pToken address
    address constant pFarmAddress = address(0xbD17B1ce622d73bD438b9E658acA5996dc394b0d); // Pickle farming contract aka MasterChef
    uint256 constant pTokenID = 12; // The location of the pToken in the pickle staking farm
    address constant pickleStakeAddress = address(0xa17a8883dA1aBd57c690DF9Ebf58fC194eDAb66F); // Pickle staking address
    uint256 constant minETH = 1000000000; // 0.000000001 ETH / 1 Gwei

    constructor(
        address _treasury,
        address _staking,
        address _zsToken
    ) public {
        treasuryAddress = _treasury;
        stakingAddress = _staking;
        zsTokenAddress = _zsToken;
        setupRewardTokens();
    }

    // Initialization functions
    
    function setupRewardTokens() internal {
        // Reward tokens
        rewardTokenList.push(address(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852)); // Uniswap LP token for ETH/USDT
        rewardTokenList.push(pickleAddress); // Picke token
        rewardTokenList.push(wethAddress); // Wrapped Ether token
    }
    
    // Modifier
    modifier onlyZSToken() {
        require(zsTokenAddress == _msgSender(), "Call not sent from the zs-Token");
        _;
    }
    
    // Read functions
    
    function rewardTokensCount() external view returns (uint256) {
        return rewardTokenList.length;
    }
    
    function rewardTokenAddress(uint256 _pos) external view returns (address) {
        require(_pos < rewardTokenList.length,"No token at that position");
        return rewardTokenList[_pos];
    }
    
    function balance() external view returns (uint256) {
        return _totalBalancePTokens;
    }
    
    function pricePerToken() external view returns (uint256) {
        return PickleJar(pJarAddress).getRatio();
    }
    
    // Write functions
    
    function enter() external onlyZSToken {
        deposit(_msgSender());
    }
    
    function exit() external onlyZSToken {
        // The ZS token vault is removing all tokens from this strategy
        withdraw(_msgSender(),1,1);
    }
    
    function withdraw(address payable _depositor, uint256 _share, uint256 _total) public onlyZSToken returns (uint256) {
        require(_totalBalancePTokens > 0, "There are no LP tokens in this strategy");
        // When a user withdraws, we need to pull the user's share out from all the contracts and split its tokens
        checkWETHAndPay(); // First check if we have unclaimed WETH and claim it
        
        // Next we need to calculate our percent of pTokens
        bool _takeAll = false;
        if(_share == _total){
            _takeAll = true; // Remove everything to this user
        }
        
        uint256 pTokenAmount = _totalBalancePTokens;
        if(_takeAll == false){
            pTokenAmount = _totalBalancePTokens.mul(_share).div(_total);
        }else{
            (pTokenAmount, ) = PickleFarm(pFarmAddress).userInfo(pTokenID, address(this)); // Get the total amount at the farm
            _totalBalancePTokens = pTokenAmount;
        }
        
        // Lower the amount of pTokens
         _totalBalancePTokens = _totalBalancePTokens.sub(pTokenAmount);

         // Now withdraw the pLP from Pickle Farm
        PickleFarm(pFarmAddress).withdraw(pTokenID, pTokenAmount); // This function also returns Pickle earned
        
        // Update user balance
        if(_depositor != zsTokenAddress){
            if(pTokenAmount >= userInfo[_depositor].balanceEstimate){
                userInfo[_depositor].balanceEstimate = 0;
            }else{
                userInfo[_depositor].balanceEstimate = userInfo[_depositor].balanceEstimate.sub(pTokenAmount);
            }
            if(_takeAll == true){
                userInfo[_depositor].balanceEstimate = 0;
            }
        }
        
        // Now exchange the pJar token for the LP token
        IERC20 _lpToken = IERC20(rewardTokenList[0]);
        uint256 lpWithdrawAmount = 0;
        if(_takeAll == false){
            uint256 _before = _lpToken.balanceOf(address(this));
            PickleJar(pJarAddress).withdraw(pTokenAmount);
            lpWithdrawAmount = _lpToken.balanceOf(address(this)).sub(_before);
        }else{
            PickleJar(pJarAddress).withdrawAll();
            lpWithdrawAmount = _lpToken.balanceOf(address(this)); // Get all LP tokens here
        }
        require(lpWithdrawAmount > 0,"Failed to withdraw from the Pickle Jar");

        // Transfer the accessory tokens
        transferAccessoryTokens(_depositor, _share, _total);
        
        // Now we withdraw the LP to the user
        _lpToken.safeTransfer(_depositor, lpWithdrawAmount);
        return lpWithdrawAmount;
    }
    
    function transferAccessoryTokens(address payable _depositor, uint256 _share, uint256 _total) internal {
        bool _takeAll = false;
        if(_share == _total){
            _takeAll = true;
        }
        if(_takeAll == false){
            // We need to now calculate the percent of accessory tokens going to this depositor
            // It is based on how long the depositor is in the contract and their share
            
            uint256 exitTime = now;
            uint256 enterTime = userInfo[_depositor].depositTime;
            if(userInfo[_depositor].depositTime == 0){ // User has never deposited into the contract at this address
                enterTime = now; // No access to pickle or weth reward
            }else{
                if(_share > userInfo[_depositor].balanceEstimate){
                    // This shouldn't happen under normal circumstances
                    _share = userInfo[_depositor].balanceEstimate; // The user has withdrawn more tokens than attributed to this address, put share to estimate
                }
            }
            uint256 numerator = exitTime.sub(enterTime);
            uint256 denominator = exitTime.sub(weightedAverageDepositTime);
            uint256 timeShare = 0;
            if(numerator > denominator){
                // This user has been in the contract longer than the average, allow up to 100% of tokens based on share
                timeShare = divisionFactor; // 100%
            }else{
                // User has been in less than or equal to average, limit token amount based on that
                if(denominator > 0){
                    timeShare = numerator.mul(divisionFactor).div(denominator);
                }else{
                    timeShare = 0;
                }
            }
            
            // Now withdraw the tokens based on the timeshare and share
            IERC20 _token = IERC20(pickleAddress);
            uint256 _tokenBalance = _token.balanceOf(address(this)); // Get balance of pickle in contract not staked
            uint256 tokenWithdrawAmount = _tokenBalance.add(_stakedPickle).mul(_share).div(_total); // First based on our share %
            tokenWithdrawAmount = tokenWithdrawAmount.mul(timeShare).div(divisionFactor); // Then on time in contract
            if(tokenWithdrawAmount > _tokenBalance){
                // Must remove some from the staking pool to fill this amount
                uint256 _removeAmount = tokenWithdrawAmount.sub(_tokenBalance);
                _stakedPickle = _stakedPickle.sub(_removeAmount);
                PickleStake(pickleStakeAddress).withdraw(_removeAmount);
            }
            // Send the Pickle to the user
            if(tokenWithdrawAmount > 0){
                _token.safeTransfer(_depositor, tokenWithdrawAmount);
            }
            
            // Now do the same for WETH
            _token = IERC20(wethAddress);
            _tokenBalance = _token.balanceOf(address(this)); // Weth is just stored in this contract until removed
            tokenWithdrawAmount = _tokenBalance.mul(_share).div(_total); // First based on our share %
            tokenWithdrawAmount = tokenWithdrawAmount.mul(timeShare).div(divisionFactor); // Then on time in contract
            // Convert and send ETH to user
            if(tokenWithdrawAmount > 0){
                WrappedEther(wethAddress).withdraw(tokenWithdrawAmount); // This will send ETH to this contract and burn WETH
                // Now send the Ether to user
                _depositor.transfer(tokenWithdrawAmount); // Transfer has low gas allocation, preventing re-entrancy
            }
        }else{
            // Just pull all pickle and all WETH
            if(_stakedPickle > 0){
                PickleStake(pickleStakeAddress).exit(); // Will pull all pickle and all WETH (should be near empty)
                _stakedPickle = 0;
            }
            IERC20 _token = IERC20(pickleAddress);
            if( _token.balanceOf(address(this)) > 0){
                _token.safeTransfer(_depositor, _token.balanceOf(address(this)));
            }
            _token = IERC20(wethAddress);
            uint256 wethBalance = _token.balanceOf(address(this));
            if(wethBalance > 0){
                if(_depositor != zsTokenAddress){
                    WrappedEther(wethAddress).withdraw(wethBalance); // This will send ETH to this contract and burn WETH
                    _depositor.transfer(wethBalance);
                }else{
                    // Keep it as ERC20
                    _token.safeTransfer(_depositor, wethBalance);
                }                
            }
        }        
    }

    receive() external payable {
        // We need an anonymous fallback function to accept ether into this contract
    }
    
    function deposit(address _depositor) public onlyZSToken {
        // Only the ZS token can call the function
        
        // Get the balance of the reward token sent here
        IERC20 _token = IERC20(rewardTokenList[0]);
        uint256 _lpBalance = _token.balanceOf(address(this));
        
        // Now deposit it into the pickle jar
        _token.safeApprove(pJarAddress ,_lpBalance); // Approve for transfer
        PickleJar(pJarAddress).deposit(_lpBalance); // Send the LP, get the pLP
        IERC20 _pToken = IERC20(pJarAddress);
        uint256 _pBalance = _pToken.balanceOf(address(this));
        require(_pBalance > 0,"Failed to get pTokens from the Pickle Jar");
        
        // Calculate the new weighted average
        if(_depositor != zsTokenAddress){
            // Calculate the deposit time
            userInfo[_depositor].depositTime = now;
            userInfo[_depositor].balanceEstimate += _pBalance;
            
            weightedAverageDepositTime = weightedAverageDepositTime.mul(_totalBalancePTokens)
                                        .div(_pBalance.add(_totalBalancePTokens));
            
            weightedAverageDepositTime = userInfo[_depositor].depositTime.mul(_pBalance)
                                        .div(_pBalance.add(_totalBalancePTokens))
                                        .add(weightedAverageDepositTime);
        }
        
        // Now deposit these tokens into the farm contract
        _pToken.safeApprove(pFarmAddress, _pBalance); // Approve for transfer
        PickleFarm(pFarmAddress).deposit(pTokenID, _pBalance); // This function also returns Pickle earned
        _totalBalancePTokens += _pBalance; // Add to our pTokens accounted for
        
        // Now check to see if we should claim and stake pickle
        checkPickleAndStake();
        
        // Now check to see if we should claim and payout WETH
        checkWETHAndPay();
    }
    
    function checkPickleAndStake() internal {
        // Check if we have pickle in this contract then stake if we do
        IERC20 _pickle = IERC20(pickleAddress);
        uint256 _balance = _pickle.balanceOf(address(this));
        if(_balance > 0){
            // We have pickle, let's stake it
            _pickle.safeApprove(pickleStakeAddress, _balance);
            PickleStake(pickleStakeAddress).stake(_balance);
            _stakedPickle += _balance;
        }
    }
    
    function checkWETHAndPay() internal {
        // Check if we have earned WETH from the staked pickle
        uint256 _balance = PickleStake(pickleStakeAddress).earned(address(this)); // This will return the WETH earned balance
        if(_balance > minETH){
            // Claim the reward and split it between the depositors, treasury and stakers
            IERC20 _token = IERC20(wethAddress);
            uint256 _before = _token.balanceOf(address(this));
            PickleStake(pickleStakeAddress).getReward(); // Pull the WETH from the staking address
            uint256 amount = _token.balanceOf(address(this)).sub(_before);
            require(amount > 0,"Pickle staking should have returned some WETH");
            uint256 depositorsAmount = amount.mul(percentLPDepositor).div(divisionFactor); // This amount remains in contract
            uint256 holdersAmount = amount.sub(depositorsAmount);
            uint256 stakersAmount = holdersAmount.mul(percentStakers).div(divisionFactor);
            uint256 treasuryAmount = holdersAmount.sub(stakersAmount);
            if(treasuryAmount > 0){
                _token.safeTransfer(treasuryAddress, treasuryAmount);
            }
            if(stakersAmount > 0){
                _token.safeTransfer(stakingAddress, stakersAmount);
                StabilizeStakingPool(stakingAddress).notifyRewardAmount(stakersAmount);
            }
        }
    }
    
    
    // Governance functions
    // Timelock variables
    
    uint256 private _timelockStart; // The start of the timelock to change governance variables
    uint256 private _timelockType; // The function that needs to be changed
    uint256 constant _timelockDuration = 86400; // Timelock is 24 hours
    
    // Reusable timelock variables
    address private _timelock_address;
    uint256 private _timelock_data_1;
    
    modifier timelockConditionsMet(uint256 _type) {
        require(_timelockType == _type, "Timelock not acquired for this function");
        _timelockType = 0; // Reset the type once the timelock is used
        if(_totalBalancePTokens > 0){ // Timelock only applies when balance exists
            require(now >= _timelockStart + _timelockDuration, "Timelock time not met");
        }
        _;
    }
    
    // Change the owner of the token contract
    // --------------------
    function startGovernanceChange(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 1;
        _timelock_address = _address;       
    }
    
    function finishGovernanceChange() external onlyGovernance timelockConditionsMet(1) {
        transferGovernance(_timelock_address);
    }
    // --------------------
    
    // Change the treasury address
    // --------------------
    function startChangeTreasury(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 2;
        _timelock_address = _address;
    }
    
    function finishChangeTreasury() external onlyGovernance timelockConditionsMet(2) {
        treasuryAddress = _timelock_address;
    }
    // --------------------
    
    // Change the percent going to depositors for WETH
    // --------------------
    function startChangeDepositorPercent(uint256 _percent) external onlyGovernance {
        require(_percent <= 100000,"Percent cannot be greater than 100%");
        _timelockStart = now;
        _timelockType = 3;
        _timelock_data_1 = _percent;
    }
    
    function finishChangeDepositorPercent() external onlyGovernance timelockConditionsMet(3) {
        percentLPDepositor = _timelock_data_1;
    }
    // --------------------
    
    // Change the staking address
    // --------------------
    function startChangeStakingPool(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 4;
        _timelock_address = _address;
    }
    
    function finishChangeStakingPool() external onlyGovernance timelockConditionsMet(4) {
        stakingAddress = _timelock_address;
    }
    // --------------------
    
    // Change the zsToken address
    // --------------------
    function startChangeZSToken(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 5;
        _timelock_address = _address;
    }
    
    function finishChangeZSToken() external onlyGovernance timelockConditionsMet(5) {
        zsTokenAddress = _timelock_address;
    }
    // --------------------
    
    // Change the percent going to stakers for WETH
    // --------------------
    function startChangeStakersPercent(uint256 _percent) external onlyGovernance {
        require(_percent <= 100000,"Percent cannot be greater than 100%");
        _timelockStart = now;
        _timelockType = 6;
        _timelock_data_1 = _percent;
    }
    
    function finishChangeStakersPercent() external onlyGovernance timelockConditionsMet(6) {
        percentStakers = _timelock_data_1;
    }
    // --------------------
}