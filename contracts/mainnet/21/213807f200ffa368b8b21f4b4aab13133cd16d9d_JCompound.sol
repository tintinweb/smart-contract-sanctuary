/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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




/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

////import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}




/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity >=0.6.0 <0.8.0;
////import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}




/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.6.12;

interface IETHGateway {
  function withdrawETH(uint256 amount, address onBehalfOf, bool redeemType, uint256 _cEthBal) external;
}




/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.6.12;

interface ICEth {
    function mint() external payable;
    function exchangeRateCurrent() external returns (uint256);
    function supplyRatePerBlock() external view returns (uint256);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function setExchangeRateStored(uint256 rate) external;
}



/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity >=0.6.0 <0.8.0;

////import "../utils/ContextUpgradeable.sol";
////import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}




/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
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




/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.6.12;

interface IJCompoundHelper {
    // function sendErc20ToCompoundHelper(address _underToken, address _cToken, uint256 _numTokensToSupply) external returns(uint256);
    // function redeemCErc20TokensHelper(address _cToken, uint256 _amount, bool _redeemType) external returns (uint256 redeemResult);

    function getMantissaHelper(uint256 _underDecs, uint256 _cTokenDecs) external pure returns (uint256 mantissa);
    function getCompoundPurePriceHelper(address _cTokenAddress) external view returns (uint256 compoundPrice);
    function getCompoundPriceHelper(address _cTokenAddress, uint256 _underDecs, uint256 _cTokenDecs) external view returns (uint256 compNormPrice);
}



/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
/**
 * Created on 2021-06-18
 * @summary: Markets Interface
 * @author: Jibrel Team
 */
pragma solidity 0.6.12;

interface IIncentivesController {
    function trancheANewEnter(address account, address trancheA) external; 
    function trancheBNewEnter(address account, address trancheB) external; 

    function claimRewardsAllMarkets(address _account) external returns (bool);
    function claimRewardSingleMarketTrA(uint256 _idxMarket, address _account) external;
    function claimRewardSingleMarketTrB(uint256 _idxMarket, address _account) external;
}




/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.6.12;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferETHHelper {
    function safeTransferETH(address _to, uint256 _value) internal {
        (bool success,) = _to.call{value:_value}(new bytes(0));
        require(success, 'TH ETH_TRANSFER_FAILED');
    }
}




/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
/**
 * Created on 2021-01-16
 * @summary: Jibrel Protocol Storage
 * @author: Jibrel Team
 */
pragma solidity 0.6.12;

////import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
////import "./interfaces/ICEth.sol";
////import "./interfaces/IETHGateway.sol";

contract JCompoundStorage is OwnableUpgradeable {
/* WARNING: NEVER RE-ORDER VARIABLES! Always double-check that new variables are added APPEND-ONLY. Re-ordering variables can permanently BREAK the deployed proxy contract.*/

    uint256 public constant PERCENT_DIVIDER = 10000;  // percentage divider for redemption

    struct TrancheAddresses {
        address buyerCoinAddress;       // ETH (ZERO_ADDRESS) or DAI
        address cTokenAddress;          // cETH or cDAI
        address ATrancheAddress;
        address BTrancheAddress;
    }

    struct TrancheParameters {
        uint256 trancheAFixedPercentage;    // fixed percentage (i.e. 4% = 0.04 * 10^18 = 40000000000000000)
        uint256 trancheALastActionBlock;
        uint256 storedTrancheAPrice;
        uint256 trancheACurrentRPB;
        uint16 redemptionPercentage;        // percentage with 2 decimals (divided by 10000, i.e. 95% is 9500)
        uint8 cTokenDecimals;
        uint8 underlyingDecimals;
    }

    address public adminToolsAddress;
    address public feesCollectorAddress;
    address public tranchesDeployerAddress;
    address public compTokenAddress;
    address public comptrollerAddress;
    address public rewardsToken;

    uint256 public tranchePairsCounter;
    uint256 public totalBlocksPerYear; 
    uint32 public redeemTimeout;

    mapping(address => address) public cTokenContracts;
    mapping(uint256 => TrancheAddresses) public trancheAddresses;
    mapping(uint256 => TrancheParameters) public trancheParameters;
    // last block number when the user buy/reddem tranche tokens
    mapping(address => uint256) public lastActivity;

    ICEth public cEthToken;
    IETHGateway public ethGateway;

    // enabling / disabling tranches for fund deposit
    mapping(uint256 => bool) public trancheDepositEnabled;
}


contract JCompoundStorageV2 is JCompoundStorage {
    struct StakingDetails {
        uint256 startTime;
        uint256 amount;
    }

    address public incentivesControllerAddress;

    // user => trancheNum => counter
    mapping (address => mapping(uint256 => uint256)) public stakeCounterTrA;
    mapping (address => mapping(uint256 => uint256)) public stakeCounterTrB;
    // user => trancheNum => stakeCounter => struct
    mapping (address => mapping (uint256 => mapping (uint256 => StakingDetails))) public stakingDetailsTrancheA;
    mapping (address => mapping (uint256 => mapping (uint256 => StakingDetails))) public stakingDetailsTrancheB;

    address public jCompoundHelperAddress;
}




/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.6.12;

interface IComptrollerLensInterface {
    function claimComp(address) external;
    function compAccrued(address) external view returns (uint);
}




/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.6.12;

interface ICErc20 {
    function mint(uint256) external returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function supplyRatePerBlock() external view returns (uint256);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function setExchangeRateStored(uint256 rate) external;
}



/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.6.12;

interface IJCompound {
    event TrancheAddedToProtocol(uint256 trancheNum, address trancheA, address trancheB);
    event TrancheATokenMinted(uint256 trancheNum, address buyer, uint256 amount, uint256 taAmount);
    event TrancheBTokenMinted(uint256 trancheNum, address buyer, uint256 amount, uint256 tbAmount);
    event TrancheATokenRedemption(uint256 trancheNum, address burner, uint256 amount, uint256 userAmount, uint256 feesAmount);
    event TrancheBTokenRedemption(uint256 trancheNum, address burner, uint256 amount, uint256 userAmount, uint256 feesAmount);

    function getSingleTrancheUserStakeCounterTrA(address _user, uint256 _trancheNum) external view returns (uint256);
    function getSingleTrancheUserStakeCounterTrB(address _user, uint256 _trancheNum) external view returns (uint256);
    function getSingleTrancheUserSingleStakeDetailsTrA(address _user, uint256 _trancheNum, uint256 _num) external view returns (uint256, uint256);
    function getSingleTrancheUserSingleStakeDetailsTrB(address _user, uint256 _trancheNum, uint256 _num) external view returns (uint256, uint256);
    function getTrAValue(uint256 _trancheNum) external view returns (uint256 trANormValue);
    function getTrBValue(uint256 _trancheNum) external view returns (uint256);
    function getTotalValue(uint256 _trancheNum) external view returns (uint256);
    function getTrancheACurrentRPB(uint256 _trancheNum) external view returns (uint256);
    function getTrancheAExchangeRate(uint256 _trancheNum) external view returns (uint256);
    function getTrancheBExchangeRate(uint256 _trancheNum, uint256 _newAmount) external view returns (uint256 tbPrice);
}



/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
/**
 * Created on 2021-01-15
 * @summary: JProtocol Interface
 * @author: Jibrel Team
 */
pragma solidity 0.6.12;

interface IJTranchesDeployer {
    function deployNewTrancheATokens(string calldata _nameA, string calldata _symbolA, address _sender, address _rewardToken) external returns (address);
    function deployNewTrancheBTokens(string calldata _nameB, string calldata _symbolB, address _sender, address _rewardToken) external returns (address);
}



/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
/**
 * Created on 2021-01-16
 * @summary: JTranches Interface
 * @author: Jibrel Team
 */
pragma solidity 0.6.12;

interface IJTrancheTokens {
    function mint(address account, uint256 value) external;
    function burn(uint256 value) external;
    function updateFundsReceived() external;
    function emergencyTokenTransfer(address _token, address _to, uint256 _amount) external;
    function setRewardTokenAddress(address _token) external;
}



/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
/**
 * Created on 2021-05-16
 * @summary: Admin Tools Interface
 * @author: Jibrel Team
 */
pragma solidity 0.6.12;

interface IJAdminTools {
    function isAdmin(address account) external view returns (bool);
    function addAdmin(address account) external;
    function removeAdmin(address account) external;
    function renounceAdmin() external;

    event AdminAdded(address account);
    event AdminRemoved(address account);
}



/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity >=0.6.0 <0.8.0;
////import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}




/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity >=0.6.0 <0.8.0;

////import "./IERC20Upgradeable.sol";
////import "../../math/SafeMathUpgradeable.sol";
////import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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


/** 
 *  SourceUnit: /home/fabio/Jibrel/tranche-compound-protocol/contracts/JCompound.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
/**
 * Created on 2021-02-11
 * @summary: Jibrel Compound Tranche Protocol
 * @author: Jibrel Team
 */
pragma solidity 0.6.12;

////import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
////import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
////import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
////import "./interfaces/IJAdminTools.sol";
////import "./interfaces/IJTrancheTokens.sol";
////import "./interfaces/IJTranchesDeployer.sol";
////import "./interfaces/IJCompound.sol";
////import "./interfaces/ICErc20.sol";
////import "./interfaces/IComptrollerLensInterface.sol";
////import "./JCompoundStorage.sol";
////import "./TransferETHHelper.sol";
////import "./interfaces/IIncentivesController.sol";
////import "./interfaces/IJCompoundHelper.sol";


contract JCompound is OwnableUpgradeable, ReentrancyGuardUpgradeable, JCompoundStorageV2, IJCompound {
    using SafeMathUpgradeable for uint256;

    /**
     * @dev contract initializer
     * @param _adminTools price oracle address
     * @param _feesCollector fees collector contract address
     * @param _tranchesDepl tranches deployer contract address
     * @param _compTokenAddress COMP token contract address
     * @param _comptrollAddress comptroller contract address
     * @param _rewardsToken rewards token address (slice token address)
     */
    function initialize(address _adminTools, 
            address _feesCollector, 
            address _tranchesDepl,
            address _compTokenAddress,
            address _comptrollAddress,
            address _rewardsToken) external initializer() {
        OwnableUpgradeable.__Ownable_init();
        adminToolsAddress = _adminTools;
        feesCollectorAddress = _feesCollector;
        tranchesDeployerAddress = _tranchesDepl;
        compTokenAddress = _compTokenAddress;
        comptrollerAddress = _comptrollAddress;
        rewardsToken = _rewardsToken;
        redeemTimeout = 3; //default
        totalBlocksPerYear = 2102400; // same number like in Compound protocol
    }

    /**
     * @dev set constants for JCompound
     * @param _trNum tranche number
     * @param _redemPerc redemption percentage (scaled by 1e4)
     * @param _redemTimeout redemption timeout, in blocks
     * @param _blocksPerYear blocks per year (compound set it to 2102400)
     */
    function setConstantsValues(uint256 _trNum, uint16 _redemPerc, uint32 _redemTimeout, uint256 _blocksPerYear) external onlyAdmins {
        trancheParameters[_trNum].redemptionPercentage = _redemPerc;
        redeemTimeout = _redemTimeout;
        totalBlocksPerYear = _blocksPerYear;
    }

    /**
     * @dev set eth gateway 
     * @param _ethGateway ethGateway address
     */
    function setETHGateway(address _ethGateway) external onlyAdmins {
        ethGateway = IETHGateway(_ethGateway);
    }

    /**
     * @dev set incentive rewards address
     * @param _incentivesController incentives controller contract address
     */
    function setincentivesControllerAddress(address _incentivesController) external onlyAdmins {
        incentivesControllerAddress = _incentivesController;
    }

    /**
     * @dev set incentive rewards address
     * @param _helper JCompound helper contract address
     */
    function setJCompoundHelperAddress(address _helper) external onlyAdmins {
        jCompoundHelperAddress = _helper;
    }

    /**
     * @dev admins modifiers
     */
    modifier onlyAdmins() {
        require(IJAdminTools(adminToolsAddress).isAdmin(msg.sender), "!Admin");
        _;
    }

    // This is needed to receive ETH
    fallback() external payable {}
    receive() external payable {}

    /**
     * @dev set new addresses for price oracle, fees collector and tranche deployer 
     * @param _adminTools price oracle address
     * @param _feesCollector fees collector contract address
     * @param _tranchesDepl tranches deployer contract address
     * @param _compTokenAddress COMP token contract address
     * @param _comptrollAddress comptroller contract address
     * @param _rewardsToken rewards token address (slice token address)
     */
    function setNewEnvironment(address _adminTools, 
            address _feesCollector, 
            address _tranchesDepl,
            address _compTokenAddress,
            address _comptrollAddress,
            address _rewardsToken) external onlyOwner {
        require((_adminTools != address(0)) && (_feesCollector != address(0)) && 
            (_tranchesDepl != address(0)) && (_comptrollAddress != address(0)) && (_compTokenAddress != address(0)), "ChkAddress");
        adminToolsAddress = _adminTools;
        feesCollectorAddress = _feesCollector;
        tranchesDeployerAddress = _tranchesDepl;
        compTokenAddress = _compTokenAddress;
        comptrollerAddress = _comptrollAddress;
        rewardsToken = _rewardsToken;
    }

    /**
     * @dev set relationship between ethers and the corresponding Compound cETH contract
     * @param _cEtherContract compound token contract address (cETH contract, on Kovan: 0x41b5844f4680a8c38fbb695b7f9cfd1f64474a72)
     */
    function setCEtherContract(address _cEtherContract) external onlyAdmins {
        cEthToken = ICEth(_cEtherContract);
        cTokenContracts[address(0)] = _cEtherContract;
    }

    /**
     * @dev set relationship between a token and the corresponding Compound cToken contract
     * @param _erc20Contract token contract address (i.e. DAI contract, on Kovan: 0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa)
     * @param _cErc20Contract compound token contract address (i.e. cDAI contract, on Kovan: 0xf0d0eb522cfa50b716b3b1604c4f0fa6f04376ad)
     */
    function setCTokenContract(address _erc20Contract, address _cErc20Contract) external onlyAdmins {
        cTokenContracts[_erc20Contract] = _cErc20Contract;
    }

    /**
     * @dev check if a cToken is allowed or not
     * @param _erc20Contract token contract address (i.e. DAI contract, on Kovan: 0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa)
     * @return true or false
     */
    function isCTokenAllowed(address _erc20Contract) public view returns (bool) {
        return cTokenContracts[_erc20Contract] != address(0);
    }

    /**
     * @dev get RPB from compound
     * @param _trancheNum tranche number
     * @return cToken compound supply RPB
     */
    function getCompoundSupplyRPB(uint256 _trancheNum) external view returns (uint256) {
        ICErc20 cToken = ICErc20(cTokenContracts[trancheAddresses[_trancheNum].buyerCoinAddress]);
        return cToken.supplyRatePerBlock();
    }

    /**
     * @dev check if a cToken is allowed or not
     * @param _trancheNum tranche number
     * @param _cTokenDec cToken decimals
     * @param _underlyingDec underlying token decimals
     */
    function setDecimals(uint256 _trancheNum, uint8 _cTokenDec, uint8 _underlyingDec) external onlyAdmins {
        require((_cTokenDec <= 18) && (_underlyingDec <= 18), "Decs");
        trancheParameters[_trancheNum].cTokenDecimals = _cTokenDec;
        trancheParameters[_trancheNum].underlyingDecimals = _underlyingDec;
    }

    /**
     * @dev set tranche A fixed percentage (scaled by 1e18)
     * @param _trancheNum tranche number
     * @param _newTrAPercentage new tranche A fixed percentage (scaled by 1e18)
     */
    function setTrancheAFixedPercentage(uint256 _trancheNum, uint256 _newTrAPercentage) external onlyAdmins {
        trancheParameters[_trancheNum].trancheAFixedPercentage = _newTrAPercentage;
        trancheParameters[_trancheNum].storedTrancheAPrice = setTrancheAExchangeRate(_trancheNum);
    }

    /**
     * @dev add tranche in protocol
     * @param _erc20Contract token contract address (0x0000000000000000000000000000000000000000 if eth)
     * @param _nameA tranche A token name
     * @param _symbolA tranche A token symbol
     * @param _nameB tranche B token name
     * @param _symbolB tranche B token symbol
     * @param _fixedRpb tranche A percentage fixed compounded interest per year
     * @param _cTokenDec cToken decimals
     * @param _underlyingDec underlying token decimals
     */
    function addTrancheToProtocol(address _erc20Contract, string memory _nameA, string memory _symbolA, string memory _nameB, 
                string memory _symbolB, uint256 _fixedRpb, uint8 _cTokenDec, uint8 _underlyingDec) external onlyAdmins nonReentrant {
        require(tranchesDeployerAddress != address(0), "!TrDepl");
        require(isCTokenAllowed(_erc20Contract), "!Allow");

        trancheAddresses[tranchePairsCounter].buyerCoinAddress = _erc20Contract;
        trancheAddresses[tranchePairsCounter].cTokenAddress = cTokenContracts[_erc20Contract];
        // our tokens always with 18 decimals
        trancheAddresses[tranchePairsCounter].ATrancheAddress = 
                IJTranchesDeployer(tranchesDeployerAddress).deployNewTrancheATokens(_nameA, _symbolA, msg.sender, rewardsToken);
        trancheAddresses[tranchePairsCounter].BTrancheAddress = 
                IJTranchesDeployer(tranchesDeployerAddress).deployNewTrancheBTokens(_nameB, _symbolB, msg.sender, rewardsToken);
        
        trancheParameters[tranchePairsCounter].cTokenDecimals = _cTokenDec;
        trancheParameters[tranchePairsCounter].underlyingDecimals = _underlyingDec;
        trancheParameters[tranchePairsCounter].trancheAFixedPercentage = _fixedRpb;
        trancheParameters[tranchePairsCounter].trancheALastActionBlock = block.number;
        // if we would like to have always 18 decimals
        trancheParameters[tranchePairsCounter].storedTrancheAPrice = 
            IJCompoundHelper(jCompoundHelperAddress).getCompoundPriceHelper(cTokenContracts[_erc20Contract], _underlyingDec, _cTokenDec);

        trancheParameters[tranchePairsCounter].redemptionPercentage = 9950;  //default value 99.5%

        calcRPBFromPercentage(tranchePairsCounter); // initialize tranche A RPB

        emit TrancheAddedToProtocol(tranchePairsCounter, trancheAddresses[tranchePairsCounter].ATrancheAddress, trancheAddresses[tranchePairsCounter].BTrancheAddress);

        tranchePairsCounter = tranchePairsCounter.add(1);
    } 

    /**
     * @dev enables or disables tranche deposit (default: disabled)
     * @param _trancheNum tranche number
     * @param _enable true or false
     */
    function setTrancheDeposit(uint256 _trancheNum, bool _enable) external onlyAdmins {
        trancheDepositEnabled[_trancheNum] = _enable;
    }

    /**
     * @dev send an amount of tokens to corresponding compound contract (it takes tokens from this contract). Only allowed token should be sent
     * @param _erc20Contract token contract address
     * @param _numTokensToSupply token amount to be sent
     * @return mint result
     */
    function sendErc20ToCompound(address _erc20Contract, uint256 _numTokensToSupply) internal returns(uint256) {
        address cTokenAddress = cTokenContracts[_erc20Contract];
        require(cTokenAddress != address(0), "!Accept");

        IERC20Upgradeable underlying = IERC20Upgradeable(_erc20Contract);

        ICErc20 cToken = ICErc20(cTokenAddress);

        SafeERC20Upgradeable.safeApprove(underlying, cTokenAddress, _numTokensToSupply);
        require(underlying.allowance(address(this), cTokenAddress) >= _numTokensToSupply, "!AllowCToken");

        uint256 mintResult = cToken.mint(_numTokensToSupply);
        return mintResult;
    }

    /**
     * @dev redeem an amount of cTokens to have back original tokens (tokens remains in this contract). Only allowed token should be sent
     * @param _erc20Contract original token contract address
     * @param _amount cToken amount to be sent
     * @param _redeemType true or false, normally true
     */
    function redeemCErc20Tokens(address _erc20Contract, uint256 _amount, bool _redeemType) internal returns (uint256 redeemResult) {
        address cTokenAddress = cTokenContracts[_erc20Contract];
        require(cTokenAddress != address(0),  "!Accept");

        ICErc20 cToken = ICErc20(cTokenAddress);

        if (_redeemType) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cToken.redeem(_amount);
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cToken.redeemUnderlying(_amount);
        }
        return redeemResult;
    }

    /**
     * @dev get Tranche A exchange rate
     * @param _trancheNum tranche number
     * @return tranche A token stored price
     */
    function getTrancheAExchangeRate(uint256 _trancheNum) public view override returns (uint256) {
        return trancheParameters[_trancheNum].storedTrancheAPrice;
    }

    /**
     * @dev get RPB for a given percentage (expressed in 1e18)
     * @param _trancheNum tranche number
     * @return RPB for a fixed percentage
     */
    function getTrancheACurrentRPB(uint256 _trancheNum) external view override returns (uint256) {
        return trancheParameters[_trancheNum].trancheACurrentRPB;
    }

    /**
     * @dev set Tranche A exchange rate
     * @param _trancheNum tranche number
     * @return tranche A token stored price
     */
    function setTrancheAExchangeRate(uint256 _trancheNum) internal returns (uint256) {
        calcRPBFromPercentage(_trancheNum);
        uint256 deltaBlocks = (block.number).sub(trancheParameters[_trancheNum].trancheALastActionBlock);
        if (deltaBlocks > 0) {
            uint256 deltaPrice = (trancheParameters[_trancheNum].trancheACurrentRPB).mul(deltaBlocks);
            trancheParameters[_trancheNum].storedTrancheAPrice = (trancheParameters[_trancheNum].storedTrancheAPrice).add(deltaPrice);
            trancheParameters[_trancheNum].trancheALastActionBlock = block.number;
        }
        return trancheParameters[_trancheNum].storedTrancheAPrice;
    }

    /**
     * @dev get Tranche A exchange rate (tokens with 18 decimals)
     * @param _trancheNum tranche number
     * @return tranche A token current price
     */
    function calcRPBFromPercentage(uint256 _trancheNum) public returns (uint256) {
        // if normalized price in tranche A price, everything should be scaled to 1e18 
        trancheParameters[_trancheNum].trancheACurrentRPB = trancheParameters[_trancheNum].storedTrancheAPrice
            .mul(trancheParameters[_trancheNum].trancheAFixedPercentage).div(totalBlocksPerYear).div(1e18);
        return trancheParameters[_trancheNum].trancheACurrentRPB;
    }

    /**
     * @dev get Tranche A value in underlying tokens
     * @param _trancheNum tranche number
     * @return trANormValue tranche A value in underlying tokens
     */
    function getTrAValue(uint256 _trancheNum) public view override returns (uint256 trANormValue) {
        uint256 totASupply = IERC20Upgradeable(trancheAddresses[_trancheNum].ATrancheAddress).totalSupply();
        uint256 diffDec = uint256(18).sub(uint256(trancheParameters[_trancheNum].underlyingDecimals));
        uint256 storedAPrice = trancheParameters[_trancheNum].storedTrancheAPrice;
        trANormValue = totASupply.mul(storedAPrice).div(1e18).div(10 ** diffDec);
        return trANormValue;
    }

    /**
     * @dev get Tranche B value in underlying tokens
     * @param _trancheNum tranche number
     * @return tranche B valuein underlying tokens
     */
    function getTrBValue(uint256 _trancheNum) external view override returns (uint256) {
        uint256 totProtValue = getTotalValue(_trancheNum);
        uint256 totTrAValue = getTrAValue(_trancheNum);
        if (totProtValue > totTrAValue) {
            return totProtValue.sub(totTrAValue);
        } else
            return 0;
    }

    /**
     * @dev get Tranche total value in underlying tokens
     * @param _trancheNum tranche number
     * @return tranche total value in underlying tokens
     */
    function getTotalValue(uint256 _trancheNum) public view override returns (uint256) {
        address cTokenAddress = trancheAddresses[_trancheNum].cTokenAddress;
        uint256 underDecs = uint256(trancheParameters[_trancheNum].underlyingDecimals);
        uint256 cTokenDecs = uint256(trancheParameters[_trancheNum].cTokenDecimals);
        uint256 compNormPrice = IJCompoundHelper(jCompoundHelperAddress).getCompoundPriceHelper(cTokenAddress, underDecs, cTokenDecs);
        uint256 mantissa = IJCompoundHelper(jCompoundHelperAddress).getMantissaHelper(underDecs, cTokenDecs);
        if (mantissa < 18) {
            compNormPrice = compNormPrice.div(10 ** (uint256(18).sub(mantissa)));
        } else {
            compNormPrice = IJCompoundHelper(jCompoundHelperAddress).getCompoundPurePriceHelper(cTokenAddress);
        }
        uint256 totProtSupply = getTokenBalance(trancheAddresses[_trancheNum].cTokenAddress);
        return totProtSupply.mul(compNormPrice).div(1e18);
    }

    /**
     * @dev get Tranche B exchange rate
     * @param _trancheNum tranche number
     * @param _newAmount new amount entering tranche B (in underlying tokens)
     * @return tbPrice tranche B token current price
     */
    function getTrancheBExchangeRate(uint256 _trancheNum, uint256 _newAmount) public view override returns (uint256 tbPrice) {
        // set amount of tokens to be minted via taToken price
        // Current tbDai price = (((cDai X cPrice)-(aSupply X taPrice)) / bSupply)
        // where: cDai = How much cDai we hold in the protocol
        // cPrice = cDai / Dai price
        // aSupply = Total number of taDai in protocol
        // taPrice = taDai / Dai price
        // bSupply = Total number of tbDai in protocol
        uint256 totTrBValue;

        uint256 totBSupply = IERC20Upgradeable(trancheAddresses[_trancheNum].BTrancheAddress).totalSupply(); // 18 decimals
        // if normalized price in tranche A price, everything should be scaled to 1e18 
        uint256 underlyingDec = uint256(trancheParameters[_trancheNum].underlyingDecimals);
        uint256 normAmount = _newAmount;
        if (underlyingDec < 18)
            normAmount = _newAmount.mul(10 ** uint256(18).sub(underlyingDec));
        uint256 newBSupply = totBSupply.add(normAmount); // 18 decimals

        uint256 totProtValue = getTotalValue(_trancheNum).add(_newAmount); //underlying token decimals
        uint256 totTrAValue = getTrAValue(_trancheNum); //underlying token decimals
        if (totProtValue >= totTrAValue)
            totTrBValue = totProtValue.sub(totTrAValue); //underlying token decimals
        else
            totTrBValue = 0;
        // if normalized price in tranche A price, everything should be scaled to 1e18 
        if (underlyingDec < 18 && totTrBValue > 0) {
            totTrBValue = totTrBValue.mul(10 ** (uint256(18).sub(underlyingDec)));
        }
        if (totTrBValue > 0 && newBSupply > 0) {
            // if normalized price in tranche A price, everything should be scaled to 1e18 
            tbPrice = totTrBValue.mul(1e18).div(newBSupply);
        } else
            // if normalized price in tranche A price, everything should be scaled to 1e18 
            tbPrice = uint256(1e18);

        return tbPrice;
    }

    /**
     * @dev set staking details for tranche A holders, with number, amount and time
     * @param _trancheNum tranche number
     * @param _account user's account
     * @param _stkNum staking detail counter
     * @param _amount amount of tranche A tokens
     * @param _time time to be considered the deposit
     */
    function setTrAStakingDetails(uint256 _trancheNum, address _account, uint256 _stkNum, uint256 _amount, uint256 _time) external onlyAdmins {
        stakeCounterTrA[_account][_trancheNum] = _stkNum;
        StakingDetails storage details = stakingDetailsTrancheA[_account][_trancheNum][_stkNum];
        details.startTime = _time;
        details.amount = _amount;
    }

    /**
     * @dev when redemption occurs on tranche A, removing tranche A tokens from staking information (FIFO logic)
     * @param _trancheNum tranche number
     * @param _amount amount of redeemed tokens
     */
    function decreaseTrancheATokenFromStake(uint256 _trancheNum, uint256 _amount) internal {
        uint256 senderCounter = stakeCounterTrA[msg.sender][_trancheNum];
        uint256 tmpAmount = _amount;
        for (uint i = 1; i <= senderCounter; i++) {
            StakingDetails storage details = stakingDetailsTrancheA[msg.sender][_trancheNum][i];
            if (details.amount > 0) {
                if (details.amount <= tmpAmount) {
                    tmpAmount = tmpAmount.sub(details.amount);
                    details.amount = 0;
                    //delete stakingDetailsTrancheA[msg.sender][_trancheNum][i];
                    // update details number
                    //stakeCounterTrA[msg.sender][_trancheNum] = stakeCounterTrA[msg.sender][_trancheNum].sub(1);
                } else {
                    details.amount = details.amount.sub(tmpAmount);
                    tmpAmount = 0;
                }
            }
            if (tmpAmount == 0)
                break;
        }
    }

    function getSingleTrancheUserStakeCounterTrA(address _user, uint256 _trancheNum) external view override returns (uint256) {
        return stakeCounterTrA[_user][_trancheNum];
    }

    function getSingleTrancheUserSingleStakeDetailsTrA(address _user, uint256 _trancheNum, uint256 _num) external view override returns (uint256, uint256) {
        return (stakingDetailsTrancheA[_user][_trancheNum][_num].startTime, stakingDetailsTrancheA[_user][_trancheNum][_num].amount);
    }

    /**
     * @dev set staking details for tranche B holders, with number, amount and time
     * @param _trancheNum tranche number
     * @param _account user's account
     * @param _stkNum staking detail counter
     * @param _amount amount of tranche B tokens
     * @param _time time to be considered the deposit
     */
    function setTrBStakingDetails(uint256 _trancheNum, address _account, uint256 _stkNum, uint256 _amount, uint256 _time) external onlyAdmins {
        stakeCounterTrB[_account][_trancheNum] = _stkNum;
        StakingDetails storage details = stakingDetailsTrancheB[_account][_trancheNum][_stkNum];
        details.startTime = _time;
        details.amount = _amount; 
    }

    /**
     * @dev when redemption occurs on tranche B, removing tranche B tokens from staking information (FIFO logic)
     * @param _trancheNum tranche number
     * @param _amount amount of redeemed tokens
     */
    function decreaseTrancheBTokenFromStake(uint256 _trancheNum, uint256 _amount) internal {
        uint256 senderCounter = stakeCounterTrB[msg.sender][_trancheNum];
        uint256 tmpAmount = _amount;
        for (uint i = 1; i <= senderCounter; i++) {
            StakingDetails storage details = stakingDetailsTrancheB[msg.sender][_trancheNum][i];
            if (details.amount > 0) {
                if (details.amount <= tmpAmount) {
                    tmpAmount = tmpAmount.sub(details.amount);
                    details.amount = 0;
                    //delete stakingDetailsTrancheB[msg.sender][_trancheNum][i];
                    // update details number
                    //stakeCounterTrB[msg.sender][_trancheNum] = stakeCounterTrB[msg.sender][_trancheNum].sub(1);
                } else {
                    details.amount = details.amount.sub(tmpAmount);
                    tmpAmount = 0;
                }
            }
            if (tmpAmount == 0)
                break;
        }
    }

    function getSingleTrancheUserStakeCounterTrB(address _user, uint256 _trancheNum) external view override returns (uint256) {
        return stakeCounterTrB[_user][_trancheNum];
    }

    function getSingleTrancheUserSingleStakeDetailsTrB(address _user, uint256 _trancheNum, uint256 _num) external view override returns (uint256, uint256) {
        return (stakingDetailsTrancheB[_user][_trancheNum][_num].startTime, stakingDetailsTrancheB[_user][_trancheNum][_num].amount);
    }

    /**
     * @dev buy Tranche A Tokens
     * @param _trancheNum tranche number
     * @param _amount amount of stable coins sent by buyer
     */
    function buyTrancheAToken(uint256 _trancheNum, uint256 _amount) external payable nonReentrant {
        require(trancheDepositEnabled[_trancheNum], "!Deposit");
        address cTokenAddress = trancheAddresses[_trancheNum].cTokenAddress;
        address underTokenAddress = trancheAddresses[_trancheNum].buyerCoinAddress;
        uint256 prevCompTokenBalance = getTokenBalance(cTokenAddress);
        if (underTokenAddress == address(0)){
            require(msg.value == _amount, "!Amount");
            //Transfer ETH from msg.sender to protocol;
            TransferETHHelper.safeTransferETH(address(this), _amount);
            // transfer ETH to Coompound receiving cETH
            cEthToken.mint{value: _amount}();
        } else {
            // check approve
            require(IERC20Upgradeable(underTokenAddress).allowance(msg.sender, address(this)) >= _amount, "!Allowance");
            //Transfer DAI from msg.sender to protocol;
            SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(underTokenAddress), msg.sender, address(this), _amount);
            // transfer DAI to Coompound receiving cDai
            sendErc20ToCompound(underTokenAddress, _amount);
            // IJCompoundHelper(jCompoundHelperAddress).sendErc20ToCompoundHelper(underTokenAddress, cTokenAddress, _amount);
        }
        uint256 newCompTokenBalance = getTokenBalance(cTokenAddress);
        // set amount of tokens to be minted calculate taToken amount via taToken price
        setTrancheAExchangeRate(_trancheNum);
        uint256 taAmount;
        if (newCompTokenBalance > prevCompTokenBalance) {
            // if normalized price in tranche A price, everything should be scaled to 1e18 
            uint256 diffDec = uint256(18).sub(uint256(trancheParameters[_trancheNum].underlyingDecimals));
            uint256 normAmount = _amount.mul(10 ** diffDec);
            taAmount = normAmount.mul(1e18).div(trancheParameters[_trancheNum].storedTrancheAPrice);
            //Mint trancheA tokens and send them to msg.sender and notify to incentive controller BEFORE totalSupply updates
            IIncentivesController(incentivesControllerAddress).trancheANewEnter(msg.sender, trancheAddresses[_trancheNum].ATrancheAddress);
            IJTrancheTokens(trancheAddresses[_trancheNum].ATrancheAddress).mint(msg.sender, taAmount);
        } else {
            taAmount = 0;
        }

        stakeCounterTrA[msg.sender][_trancheNum] = stakeCounterTrA[msg.sender][_trancheNum].add(1);
        StakingDetails storage details = stakingDetailsTrancheA[msg.sender][_trancheNum][stakeCounterTrA[msg.sender][_trancheNum]];
        details.startTime = block.timestamp;
        details.amount = taAmount;

        lastActivity[msg.sender] = block.number;
        emit TrancheATokenMinted(_trancheNum, msg.sender, _amount, taAmount);
    }

    /**
     * @dev redeem Tranche A Tokens
     * @param _trancheNum tranche number
     * @param _amount amount of stable coins sent by buyer
     */
    function redeemTrancheAToken(uint256 _trancheNum, uint256 _amount) external nonReentrant {
        require((block.number).sub(lastActivity[msg.sender]) >= redeemTimeout, "!Timeout");
        // check approve
        address aTrancheAddress = trancheAddresses[_trancheNum].ATrancheAddress;
        require(IERC20Upgradeable(aTrancheAddress).allowance(msg.sender, address(this)) >= _amount, "!Allowance");
        //Transfer DAI from msg.sender to protocol;
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(aTrancheAddress), msg.sender, address(this), _amount);

        uint256 oldBal;
        uint256 diffBal;
        uint256 userAmount;
        uint256 feesAmount;
        setTrancheAExchangeRate(_trancheNum);
        // if normalized price in tranche A price, everything should be scaled to 1e18 
        uint256 taAmount = _amount.mul(trancheParameters[_trancheNum].storedTrancheAPrice).div(1e18);
        uint256 diffDec = uint256(18).sub(uint256(trancheParameters[_trancheNum].underlyingDecimals));
        uint256 normAmount = taAmount.div(10 ** diffDec);

        address cTokenAddress = trancheAddresses[_trancheNum].cTokenAddress;
        uint256 cTokenBal = getTokenBalance(cTokenAddress); // needed for emergency
        address underTokenAddress = trancheAddresses[_trancheNum].buyerCoinAddress;
        uint256 redeemPerc = uint256(trancheParameters[_trancheNum].redemptionPercentage);
        if (underTokenAddress == address(0)) {
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(cTokenAddress), address(ethGateway), cTokenBal);
            // calculate taAmount via cETH price
            oldBal = getEthBalance();
            ethGateway.withdrawETH(normAmount, address(this), false, cTokenBal);
            diffBal = getEthBalance().sub(oldBal);
            userAmount = diffBal.mul(redeemPerc).div(PERCENT_DIVIDER);
            TransferETHHelper.safeTransferETH(msg.sender, userAmount);
            if (diffBal != userAmount) {
                // transfer fees to JFeesCollector
                feesAmount = diffBal.sub(userAmount);
                TransferETHHelper.safeTransferETH(feesCollectorAddress, feesAmount);
            }   
        } else {
            // calculate taAmount via cToken price
            oldBal = getTokenBalance(underTokenAddress);
            uint256 compoundRetCode = redeemCErc20Tokens(underTokenAddress, normAmount, false);
            // uint256 compoundRetCode = IJCompoundHelper(jCompoundHelperAddress).redeemCErc20TokensHelper(cTokenAddress, normAmount, false);
            if(compoundRetCode != 0) {
                // emergency: send all ctokens balance to compound 
                redeemCErc20Tokens(underTokenAddress, cTokenBal, true); 
                // SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(aTrancheAddress), jCompoundHelperAddress, cTokenBal);
                // IJCompoundHelper(jCompoundHelperAddress).redeemCErc20TokensHelper(cTokenAddress, cTokenBal, false); 
            }
            diffBal = getTokenBalance(underTokenAddress).sub(oldBal);
            userAmount = diffBal.mul(redeemPerc).div(PERCENT_DIVIDER);
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(underTokenAddress), msg.sender, userAmount);
            if (diffBal != userAmount) {
                // transfer fees to JFeesCollector
                feesAmount = diffBal.sub(userAmount);
                SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(underTokenAddress), feesCollectorAddress, feesAmount);
            }
        }

        // claim and transfer rewards to msg.sender. Be sure to wait for this function to be completed! 
        bool rewClaimCompleted = IIncentivesController(incentivesControllerAddress).claimRewardsAllMarkets(msg.sender);

        // decrease tokens after claiming rewards
        if (rewClaimCompleted && _amount > 0)
            decreaseTrancheATokenFromStake(_trancheNum, _amount);
     
        IJTrancheTokens(aTrancheAddress).burn(_amount);

        lastActivity[msg.sender] = block.number;
        emit TrancheATokenRedemption(_trancheNum, msg.sender, 0, userAmount, feesAmount);
    }

    /**
     * @dev buy Tranche B Tokens
     * @param _trancheNum tranche number
     * @param _amount amount of stable coins sent by buyer
     */
    function buyTrancheBToken(uint256 _trancheNum, uint256 _amount) external payable nonReentrant {
        require(trancheDepositEnabled[_trancheNum], "!Deposit");
        address cTokenAddress = trancheAddresses[_trancheNum].cTokenAddress;
        address underTokenAddress = trancheAddresses[_trancheNum].buyerCoinAddress;
        uint256 prevCompTokenBalance = getTokenBalance(cTokenAddress);
        // if eth, ignore _amount parameter and set it to msg.value
        if (trancheAddresses[_trancheNum].buyerCoinAddress == address(0)) {
            require(msg.value == _amount, "!Amount");
            //_amount = msg.value;
        }
        // refresh value for tranche A
        setTrancheAExchangeRate(_trancheNum);
        // get tranche B exchange rate
        // if normalized price in tranche B price, everything should be scaled to 1e18 
        uint256 diffDec = uint256(18).sub(uint256(trancheParameters[_trancheNum].underlyingDecimals));
        uint256 normAmount = _amount.mul(10 ** diffDec);
        uint256 tbAmount = normAmount.mul(1e18).div(getTrancheBExchangeRate(_trancheNum, _amount));
        if (underTokenAddress == address(0)) {
            TransferETHHelper.safeTransferETH(address(this), _amount);
            // transfer ETH to Coompound receiving cETH
            cEthToken.mint{value: _amount}();
        } else {
            // check approve
            require(IERC20Upgradeable(underTokenAddress).allowance(msg.sender, address(this)) >= _amount, "!Allowance");
            //Transfer DAI from msg.sender to protocol;
            SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(underTokenAddress), msg.sender, address(this), _amount);
            // transfer DAI to Couompound receiving cDai
            sendErc20ToCompound(underTokenAddress, _amount);
            // IJCompoundHelper(jCompoundHelperAddress).sendErc20ToCompoundHelper(underTokenAddress, cTokenAddress, _amount);
        }
        uint256 newCompTokenBalance = getTokenBalance(cTokenAddress);
        if (newCompTokenBalance > prevCompTokenBalance) {
            //Mint trancheB tokens and send them to msg.sender and notify to incentive controller BEFORE totalSupply updates
            IIncentivesController(incentivesControllerAddress).trancheBNewEnter(msg.sender, trancheAddresses[_trancheNum].BTrancheAddress);
            IJTrancheTokens(trancheAddresses[_trancheNum].BTrancheAddress).mint(msg.sender, tbAmount);
        } else 
            tbAmount = 0;

        stakeCounterTrB[msg.sender][_trancheNum] = stakeCounterTrB[msg.sender][_trancheNum].add(1);
        StakingDetails storage details = stakingDetailsTrancheB[msg.sender][_trancheNum][stakeCounterTrB[msg.sender][_trancheNum]];
        details.startTime = block.timestamp;
        details.amount = tbAmount;     

        lastActivity[msg.sender] = block.number;
        emit TrancheBTokenMinted(_trancheNum, msg.sender, _amount, tbAmount);
    }

    /**
     * @dev redeem Tranche B Tokens
     * @param _trancheNum tranche number
     * @param _amount amount of stable coins sent by buyer
     */
    function redeemTrancheBToken(uint256 _trancheNum, uint256 _amount) external nonReentrant {
        require((block.number).sub(lastActivity[msg.sender]) >= redeemTimeout, "!Timeout");
        // check approve
        address bTrancheAddress = trancheAddresses[_trancheNum].BTrancheAddress;
        require(IERC20Upgradeable(bTrancheAddress).allowance(msg.sender, address(this)) >= _amount, "!Allowance");
        //Transfer DAI from msg.sender to protocol;
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(bTrancheAddress), msg.sender, address(this), _amount);

        uint256 oldBal;
        uint256 diffBal;
        uint256 userAmount;
        uint256 feesAmount;
        // refresh value for tranche A
        setTrancheAExchangeRate(_trancheNum);
        // get tranche B exchange rate
        // if normalized price in tranche B price, everything should be scaled to 1e18 
        uint256 tbAmount = _amount.mul(getTrancheBExchangeRate(_trancheNum, 0)).div(1e18);
        uint256 diffDec = uint256(18).sub(uint256(trancheParameters[_trancheNum].underlyingDecimals));
        uint256 normAmount = tbAmount.div(10 ** diffDec);

        address cTokenAddress = trancheAddresses[_trancheNum].cTokenAddress;
        uint256 cTokenBal = getTokenBalance(cTokenAddress); // needed for emergency
        address underTokenAddress = trancheAddresses[_trancheNum].buyerCoinAddress;
        uint256 redeemPerc = uint256(trancheParameters[_trancheNum].redemptionPercentage);
        if (underTokenAddress == address(0)){
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(cTokenAddress), address(ethGateway), cTokenBal);
            // calculate tbETH amount via cETH price
            oldBal = getEthBalance();
            ethGateway.withdrawETH(normAmount, address(this), false, cTokenBal);
            diffBal = getEthBalance().sub(oldBal);
            userAmount = diffBal.mul(redeemPerc).div(PERCENT_DIVIDER);
            TransferETHHelper.safeTransferETH(msg.sender, userAmount);
            if (diffBal != userAmount) {
                // transfer fees to JFeesCollector
                feesAmount = diffBal.sub(userAmount);
                TransferETHHelper.safeTransferETH(feesCollectorAddress, feesAmount);
            }   
        } else {
            // calculate taToken amount via cToken price
            oldBal = getTokenBalance(underTokenAddress);
            require(redeemCErc20Tokens(underTokenAddress, normAmount, false) == 0, "!cTokenAnswer");
            // uint256 compRetCode = IJCompoundHelper(jCompoundHelperAddress).redeemCErc20TokensHelper(cTokenAddress, normAmount, false);
            // require(compRetCode == 0, "!cTokenAnswer");
            diffBal = getTokenBalance(underTokenAddress);
            userAmount = diffBal.mul(redeemPerc).div(PERCENT_DIVIDER);
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(underTokenAddress), msg.sender, userAmount);
            if (diffBal != userAmount) {
                // transfer fees to JFeesCollector
                feesAmount = diffBal.sub(userAmount);
                SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(underTokenAddress), feesCollectorAddress, feesAmount);
            }   
        }

        // claim and transfer rewards to msg.sender. Be sure to wait for this function to be completed! 
        bool rewClaimCompleted = IIncentivesController(incentivesControllerAddress).claimRewardsAllMarkets(msg.sender);

        // decrease tokens after claiming rewards
        if (rewClaimCompleted && _amount > 0)
            decreaseTrancheBTokenFromStake(_trancheNum, _amount);

        IJTrancheTokens(bTrancheAddress).burn(_amount);

        lastActivity[msg.sender] = block.number;
        emit TrancheBTokenRedemption(_trancheNum, msg.sender, 0, userAmount, feesAmount);
    }

    /**
     * @dev redeem every cToken amount and send values to fees collector
     * @param _trancheNum tranche number
     * @param _cTokenAmount cToken amount to send to compound protocol
     */
    function redeemCTokenAmount(uint256 _trancheNum, uint256 _cTokenAmount) external onlyAdmins nonReentrant {
        uint256 oldBal;
        uint256 diffBal;
        address underTokenAddress = trancheAddresses[_trancheNum].buyerCoinAddress;
        uint256 cTokenBal = getTokenBalance(trancheAddresses[_trancheNum].cTokenAddress); // needed for emergency
        if (underTokenAddress == address(0)) {
            oldBal = getEthBalance();
            ethGateway.withdrawETH(_cTokenAmount, address(this), true, cTokenBal);
            diffBal = getEthBalance().sub(oldBal);
            TransferETHHelper.safeTransferETH(feesCollectorAddress, diffBal);
        } else {
            // calculate taToken amount via cToken price
            oldBal = getTokenBalance(underTokenAddress);
            require(redeemCErc20Tokens(underTokenAddress, _cTokenAmount, true) == 0, "!cTokenAnswer");
            // address cToken = cTokenContracts[trancheAddresses[_trancheNum].buyerCoinAddress];
            // uint256 compRetCode = IJCompoundHelper(jCompoundHelperAddress).redeemCErc20TokensHelper(cToken, _cTokenAmount, false);
            // require(compRetCode == 0, "!cTokenAnswer");
            diffBal = getTokenBalance(underTokenAddress);
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(underTokenAddress), feesCollectorAddress, diffBal);
        }
    }

    /**
     * @dev get every token balance in this contract
     * @param _tokenContract token contract address
     */
    function getTokenBalance(address _tokenContract) public view returns (uint256) {
        return IERC20Upgradeable(_tokenContract).balanceOf(address(this));
    }

    /**
     * @dev get eth balance on this contract
     */
    function getEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev transfer tokens in this contract to fees collector contract
     * @param _tokenContract token contract address
     * @param _amount token amount to be transferred 
     */
    function transferTokenToFeesCollector(address _tokenContract, uint256 _amount) external onlyAdmins {
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_tokenContract), feesCollectorAddress, _amount);
    }

    /**
     * @dev transfer ethers in this contract to fees collector contract
     * @param _amount ethers amount to be transferred 
     */
    function withdrawEthToFeesCollector(uint256 _amount) external onlyAdmins {
        TransferETHHelper.safeTransferETH(feesCollectorAddress, _amount);
    }

    /**
     * @dev get total accrued Comp token from all market in comptroller
     * @return comp amount accrued
     */
    function getTotalCompAccrued() public view onlyAdmins returns (uint256) {
        return IComptrollerLensInterface(comptrollerAddress).compAccrued(address(this));
    }

    /**
     * @dev claim total accrued Comp token from all market in comptroller and transfer the amount to a receiver address
     * @param _receiver destination address
     */
    function claimTotalCompAccruedToReceiver(address _receiver) external onlyAdmins nonReentrant {
        uint256 totAccruedAmount = getTotalCompAccrued();
        if (totAccruedAmount > 0) {
            IComptrollerLensInterface(comptrollerAddress).claimComp(address(this));
            uint256 amount = IERC20Upgradeable(compTokenAddress).balanceOf(address(this));
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(compTokenAddress), _receiver, amount);
        }
    }
}