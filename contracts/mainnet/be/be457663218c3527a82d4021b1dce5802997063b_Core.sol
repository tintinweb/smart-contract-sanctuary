/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

/**

  Source code of Opium Protocol
  Web https://opium.network
  Telegram https://t.me/opium_network
  Twitter https://twitter.com/opium_network

 */

// File: LICENSE

/**

The software and documentation available in this repository (the "Software") is protected by copyright law and accessible pursuant to the license set forth below. Copyright © 2020 Blockeys BV. All rights reserved.

Permission is hereby granted, free of charge, to any person or organization obtaining the Software (the “Licensee”) to privately study, review, and analyze the Software. Licensee shall not use the Software for any other purpose. Licensee shall not modify, transfer, assign, share, or sub-license the Software or any derivative works of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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

// File: openzeppelin-solidity/contracts/utils/Address.sol

pragma solidity ^0.5.5;

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
        assembly { codehash := extcodehash(account) }
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
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




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

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.0;

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
 */
contract ReentrancyGuard {
    // counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

// File: erc721o/contracts/Libs/LibPosition.sol

pragma solidity ^0.5.4;

library LibPosition {
  function getLongTokenId(bytes32 _hash) public pure returns (uint256 tokenId) {
    tokenId = uint256(keccak256(abi.encodePacked(_hash, "LONG")));
  }

  function getShortTokenId(bytes32 _hash) public pure returns (uint256 tokenId) {
    tokenId = uint256(keccak256(abi.encodePacked(_hash, "SHORT")));
  }
}

// File: contracts/Lib/LibDerivative.sol

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

/// @title Opium.Lib.LibDerivative contract should be inherited by contracts that use Derivative structure and calculate derivativeHash
contract LibDerivative {
    // Opium derivative structure (ticker) definition
    struct Derivative {
        // Margin parameter for syntheticId
        uint256 margin;
        // Maturity of derivative
        uint256 endTime;
        // Additional parameters for syntheticId
        uint256[] params;
        // oracleId of derivative
        address oracleId;
        // Margin token address of derivative
        address token;
        // syntheticId of derivative
        address syntheticId;
    }

    /// @notice Calculates hash of provided Derivative
    /// @param _derivative Derivative Instance of derivative to hash
    /// @return derivativeHash bytes32 Derivative hash
    function getDerivativeHash(Derivative memory _derivative) public pure returns (bytes32 derivativeHash) {
        derivativeHash = keccak256(abi.encodePacked(
            _derivative.margin,
            _derivative.endTime,
            _derivative.params,
            _derivative.oracleId,
            _derivative.token,
            _derivative.syntheticId
        ));
    }
}

// File: contracts/Interface/IDerivativeLogic.sol

pragma solidity 0.5.16;


/// @title Opium.Interface.IDerivativeLogic contract is an interface that every syntheticId should implement
contract IDerivativeLogic is LibDerivative {
    /// @notice Validates ticker
    /// @param _derivative Derivative Instance of derivative to validate
    /// @return Returns boolean whether ticker is valid
    function validateInput(Derivative memory _derivative) public view returns (bool);

    /// @notice Calculates margin required for derivative creation
    /// @param _derivative Derivative Instance of derivative
    /// @return buyerMargin uint256 Margin needed from buyer (LONG position)
    /// @return sellerMargin uint256 Margin needed from seller (SHORT position)
    function getMargin(Derivative memory _derivative) public view returns (uint256 buyerMargin, uint256 sellerMargin);

    /// @notice Calculates payout for derivative execution
    /// @param _derivative Derivative Instance of derivative
    /// @param _result uint256 Data retrieved from oracleId on the maturity
    /// @return buyerPayout uint256 Payout in ratio for buyer (LONG position holder)
    /// @return sellerPayout uint256 Payout in ratio for seller (SHORT position holder)
    function getExecutionPayout(Derivative memory _derivative, uint256 _result)	public view returns (uint256 buyerPayout, uint256 sellerPayout);

    /// @notice Returns syntheticId author address for Opium commissions
    /// @return authorAddress address The address of syntheticId address
    function getAuthorAddress() public view returns (address authorAddress);

    /// @notice Returns syntheticId author commission in base of COMMISSION_BASE
    /// @return commission uint256 Author commission
    function getAuthorCommission() public view returns (uint256 commission);

    /// @notice Returns whether thirdparty could execute on derivative's owner's behalf
    /// @param _derivativeOwner address Derivative owner address
    /// @return Returns boolean whether _derivativeOwner allowed third party execution
    function thirdpartyExecutionAllowed(address _derivativeOwner) public view returns (bool);

    /// @notice Returns whether syntheticId implements pool logic
    /// @return Returns whether syntheticId implements pool logic
    function isPool() public view returns (bool);

    /// @notice Sets whether thirds parties are allowed or not to execute derivative's on msg.sender's behalf
    /// @param _allow bool Flag for execution allowance
    function allowThirdpartyExecution(bool _allow) public;

    // Event with syntheticId metadata JSON string (for DIB.ONE derivative explorer)
    event MetadataSet(string metadata);
}

// File: contracts/Errors/CoreErrors.sol

pragma solidity 0.5.16;

contract CoreErrors {
    string constant internal ERROR_CORE_NOT_POOL = "CORE:NOT_POOL";
    string constant internal ERROR_CORE_CANT_BE_POOL = "CORE:CANT_BE_POOL";

    string constant internal ERROR_CORE_TICKER_WAS_CANCELLED = "CORE:TICKER_WAS_CANCELLED";
    string constant internal ERROR_CORE_SYNTHETIC_VALIDATION_ERROR = "CORE:SYNTHETIC_VALIDATION_ERROR";
    string constant internal ERROR_CORE_NOT_ENOUGH_TOKEN_ALLOWANCE = "CORE:NOT_ENOUGH_TOKEN_ALLOWANCE";

    string constant internal ERROR_CORE_TOKEN_IDS_AND_QUANTITIES_LENGTH_DOES_NOT_MATCH = "CORE:TOKEN_IDS_AND_QUANTITIES_LENGTH_DOES_NOT_MATCH";
    string constant internal ERROR_CORE_TOKEN_IDS_AND_DERIVATIVES_LENGTH_DOES_NOT_MATCH = "CORE:TOKEN_IDS_AND_DERIVATIVES_LENGTH_DOES_NOT_MATCH";

    string constant internal ERROR_CORE_EXECUTION_BEFORE_MATURITY_NOT_ALLOWED = "CORE:EXECUTION_BEFORE_MATURITY_NOT_ALLOWED";
    string constant internal ERROR_CORE_SYNTHETIC_EXECUTION_WAS_NOT_ALLOWED = "CORE:SYNTHETIC_EXECUTION_WAS_NOT_ALLOWED";
    string constant internal ERROR_CORE_INSUFFICIENT_POOL_BALANCE = "CORE:INSUFFICIENT_POOL_BALANCE";

    string constant internal ERROR_CORE_CANT_CANCEL_DUMMY_ORACLE_ID = "CORE:CANT_CANCEL_DUMMY_ORACLE_ID";
    string constant internal ERROR_CORE_CANCELLATION_IS_NOT_ALLOWED = "CORE:CANCELLATION_IS_NOT_ALLOWED";

    string constant internal ERROR_CORE_UNKNOWN_POSITION_TYPE = "CORE:UNKNOWN_POSITION_TYPE";
}

// File: contracts/Errors/RegistryErrors.sol

pragma solidity 0.5.16;

contract RegistryErrors {
    string constant internal ERROR_REGISTRY_ONLY_INITIALIZER = "REGISTRY:ONLY_INITIALIZER";
    string constant internal ERROR_REGISTRY_ONLY_OPIUM_ADDRESS_ALLOWED = "REGISTRY:ONLY_OPIUM_ADDRESS_ALLOWED";
    
    string constant internal ERROR_REGISTRY_CANT_BE_ZERO_ADDRESS = "REGISTRY:CANT_BE_ZERO_ADDRESS";

    string constant internal ERROR_REGISTRY_ALREADY_SET = "REGISTRY:ALREADY_SET";
}

// File: contracts/Registry.sol

pragma solidity 0.5.16;


/// @title Opium.Registry contract keeps addresses of deployed Opium contracts set to allow them route and communicate to each other
contract Registry is RegistryErrors {

    // Address of Opium.TokenMinter contract
    address private minter;

    // Address of Opium.Core contract
    address private core;

    // Address of Opium.OracleAggregator contract
    address private oracleAggregator;

    // Address of Opium.SyntheticAggregator contract
    address private syntheticAggregator;

    // Address of Opium.TokenSpender contract
    address private tokenSpender;

    // Address of Opium commission receiver
    address private opiumAddress;

    // Address of Opium contract set deployer
    address public initializer;

    /// @notice This modifier restricts access to functions, which could be called only by initializer
    modifier onlyInitializer() {
        require(msg.sender == initializer, ERROR_REGISTRY_ONLY_INITIALIZER);
        _;
    }

    /// @notice Sets initializer
    constructor() public {
        initializer = msg.sender;
    }

    // SETTERS

    /// @notice Sets Opium.TokenMinter, Opium.Core, Opium.OracleAggregator, Opium.SyntheticAggregator, Opium.TokenSpender, Opium commission receiver addresses and allows to do it only once
    /// @param _minter address Address of Opium.TokenMinter
    /// @param _core address Address of Opium.Core
    /// @param _oracleAggregator address Address of Opium.OracleAggregator
    /// @param _syntheticAggregator address Address of Opium.SyntheticAggregator
    /// @param _tokenSpender address Address of Opium.TokenSpender
    /// @param _opiumAddress address Address of Opium commission receiver
    function init(
        address _minter,
        address _core,
        address _oracleAggregator,
        address _syntheticAggregator,
        address _tokenSpender,
        address _opiumAddress
    ) external onlyInitializer {
        require(
            minter == address(0) &&
            core == address(0) &&
            oracleAggregator == address(0) &&
            syntheticAggregator == address(0) &&
            tokenSpender == address(0) &&
            opiumAddress == address(0),
            ERROR_REGISTRY_ALREADY_SET
        );

        require(
            _minter != address(0) &&
            _core != address(0) &&
            _oracleAggregator != address(0) &&
            _syntheticAggregator != address(0) &&
            _tokenSpender != address(0) &&
            _opiumAddress != address(0),
            ERROR_REGISTRY_CANT_BE_ZERO_ADDRESS
        );

        minter = _minter;
        core = _core;
        oracleAggregator = _oracleAggregator;
        syntheticAggregator = _syntheticAggregator;
        tokenSpender = _tokenSpender;
        opiumAddress = _opiumAddress;
    }

    /// @notice Allows opium commission receiver address to change itself
    /// @param _opiumAddress address New opium commission receiver address
    function changeOpiumAddress(address _opiumAddress) external {
        require(opiumAddress == msg.sender, ERROR_REGISTRY_ONLY_OPIUM_ADDRESS_ALLOWED);
        require(_opiumAddress != address(0), ERROR_REGISTRY_CANT_BE_ZERO_ADDRESS);
        opiumAddress = _opiumAddress;
    }

    // GETTERS

    /// @notice Returns address of Opium.TokenMinter
    /// @param result address Address of Opium.TokenMinter
    function getMinter() external view returns (address result) {
        return minter;
    }

    /// @notice Returns address of Opium.Core
    /// @param result address Address of Opium.Core
    function getCore() external view returns (address result) {
        return core;
    }

    /// @notice Returns address of Opium.OracleAggregator
    /// @param result address Address of Opium.OracleAggregator
    function getOracleAggregator() external view returns (address result) {
        return oracleAggregator;
    }

    /// @notice Returns address of Opium.SyntheticAggregator
    /// @param result address Address of Opium.SyntheticAggregator
    function getSyntheticAggregator() external view returns (address result) {
        return syntheticAggregator;
    }

    /// @notice Returns address of Opium.TokenSpender
    /// @param result address Address of Opium.TokenSpender
    function getTokenSpender() external view returns (address result) {
        return tokenSpender;
    }

    /// @notice Returns address of Opium commission receiver
    /// @param result address Address of Opium commission receiver
    function getOpiumAddress() external view returns (address result) {
        return opiumAddress;
    }
}

// File: contracts/Errors/UsingRegistryErrors.sol

pragma solidity 0.5.16;

contract UsingRegistryErrors {
    string constant internal ERROR_USING_REGISTRY_ONLY_CORE_ALLOWED = "USING_REGISTRY:ONLY_CORE_ALLOWED";
}

// File: contracts/Lib/UsingRegistry.sol

pragma solidity 0.5.16;



/// @title Opium.Lib.UsingRegistry contract should be inherited by contracts, that are going to use Opium.Registry
contract UsingRegistry is UsingRegistryErrors {
    // Emitted when registry instance is set
    event RegistrySet(address registry);

    // Instance of Opium.Registry contract
    Registry internal registry;

    /// @notice This modifier restricts access to functions, which could be called only by Opium.Core
    modifier onlyCore() {
        require(msg.sender == registry.getCore(), ERROR_USING_REGISTRY_ONLY_CORE_ALLOWED);
        _;
    }

    /// @notice Defines registry instance and emits appropriate event
    constructor(address _registry) public {
        registry = Registry(_registry);
        emit RegistrySet(_registry);
    }

    /// @notice Getter for registry variable
    /// @return address Address of registry set in current contract
    function getRegistry() external view returns (address) {
        return address(registry);
    }
}

// File: contracts/Lib/LibCommission.sol

pragma solidity 0.5.16;

/// @title Opium.Lib.LibCommission contract defines constants for Opium commissions
contract LibCommission {
    // Represents 100% base for commissions calculation
    uint256 constant public COMMISSION_BASE = 10000;

    // Represents 100% base for Opium commission
    uint256 constant public OPIUM_COMMISSION_BASE = 10;

    // Represents which part of `syntheticId` author commissions goes to opium
    uint256 constant public OPIUM_COMMISSION_PART = 1;
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol

pragma solidity ^0.5.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

// File: erc721o/contracts/Libs/UintArray.sol

pragma solidity ^0.5.4;

library UintArray {
  function indexOf(uint256[] memory A, uint256 a) internal pure returns (uint256, bool) {
    uint256 length = A.length;
    for (uint256 i = 0; i < length; i++) {
      if (A[i] == a) {
        return (i, true);
      }
    }
    return (0, false);
  }

  function contains(uint256[] memory A, uint256 a) internal pure returns (bool) {
    (, bool isIn) = indexOf(A, a);
    return isIn;
  }

  function difference(uint256[] memory A, uint256[] memory B) internal pure returns (uint256[] memory, uint256[] memory) {
    uint256 length = A.length;
    bool[] memory includeMap = new bool[](length);
    uint256 count = 0;
    // First count the new length because can't push for in-memory arrays
    for (uint256 i = 0; i < length; i++) {
      uint256 e = A[i];
      if (!contains(B, e)) {
        includeMap[i] = true;
        count++;
      }
    }
    uint256[] memory newUints = new uint256[](count);
    uint256[] memory newUintsIdxs = new uint256[](count);
    uint256 j = 0;
    for (uint256 i = 0; i < length; i++) {
      if (includeMap[i]) {
        newUints[j] = A[i];
        newUintsIdxs[j] = i;
        j++;
      }
    }
    return (newUints, newUintsIdxs);
  }

  function intersect(uint256[] memory A, uint256[] memory B) internal pure returns (uint256[] memory, uint256[] memory, uint256[] memory) {
    uint256 length = A.length;
    bool[] memory includeMap = new bool[](length);
    uint256 newLength = 0;
    for (uint256 i = 0; i < length; i++) {
      if (contains(B, A[i])) {
        includeMap[i] = true;
        newLength++;
      }
    }
    uint256[] memory newUints = new uint256[](newLength);
    uint256[] memory newUintsAIdxs = new uint256[](newLength);
    uint256[] memory newUintsBIdxs = new uint256[](newLength);
    uint256 j = 0;
    for (uint256 i = 0; i < length; i++) {
      if (includeMap[i]) {
        newUints[j] = A[i];
        newUintsAIdxs[j] = i;
        (newUintsBIdxs[j], ) = indexOf(B, A[i]);
        j++;
      }
    }
    return (newUints, newUintsAIdxs, newUintsBIdxs);
  }

  function isUnique(uint256[] memory A) internal pure returns (bool) {
    uint256 length = A.length;

    for (uint256 i = 0; i < length; i++) {
      (uint256 idx, bool isIn) = indexOf(A, A[i]);

      if (isIn && idx < i) {
        return false;
      }
    }

    return true;
  }
}

// File: openzeppelin-solidity/contracts/introspection/IERC165.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: openzeppelin-solidity/contracts/introspection/ERC165.sol

pragma solidity ^0.5.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.5.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

// File: erc721o/contracts/Interfaces/IERC721O.sol

pragma solidity ^0.5.4;

contract IERC721O {
  // Token description
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function totalSupply() public view returns (uint256);
  function exists(uint256 _tokenId) public view returns (bool);

  function implementsERC721() public pure returns (bool);
  function tokenByIndex(uint256 _index) public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenURI(uint256 _tokenId) public view returns (string memory tokenUri);
  function getApproved(uint256 _tokenId) public view returns (address);
  
  function implementsERC721O() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function balanceOf(address owner) public view returns (uint256);
  function balanceOf(address _owner, uint256 _tokenId) public view returns (uint256);
  function tokensOwned(address _owner) public view returns (uint256[] memory, uint256[] memory);

  // Non-Fungible Safe Transfer From
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public;

  // Non-Fungible Unsafe Transfer From
  function transferFrom(address _from, address _to, uint256 _tokenId) public;

  // Fungible Unsafe Transfer
  function transfer(address _to, uint256 _tokenId, uint256 _quantity) public;

  // Fungible Unsafe Transfer From
  function transferFrom(address _from, address _to, uint256 _tokenId, uint256 _quantity) public;

  // Fungible Safe Transfer From
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _amount) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _amount, bytes memory _data) public;

  // Fungible Safe Batch Transfer From
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _tokenIds, uint256[] memory _amounts) public;
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _tokenIds, uint256[] memory _amounts, bytes memory _data) public;

  // Fungible Unsafe Batch Transfer From
  function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds, uint256[] memory _amounts) public;

  // Approvals
  function setApprovalForAll(address _operator, bool _approved) public;
  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId, address _tokenOwner) public view returns (address);
  function isApprovedForAll(address _owner, address _operator) public view returns (bool isOperator);
  function isApprovedOrOwner(address _spender, address _owner, uint256 _tokenId) public view returns (bool);
  function permit(address _holder, address _spender, uint256 _nonce, uint256 _expiry, bool _allowed, bytes calldata _signature) external;

  // Composable
  function compose(uint256[] memory _tokenIds, uint256[] memory _tokenRatio, uint256 _quantity) public;
  function decompose(uint256 _portfolioId, uint256[] memory _tokenIds, uint256[] memory _tokenRatio, uint256 _quantity) public;
  function recompose(uint256 _portfolioId, uint256[] memory _initialTokenIds, uint256[] memory _initialTokenRatio, uint256[] memory _finalTokenIds, uint256[] memory _finalTokenRatio, uint256 _quantity) public;

  // Required Events
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event TransferWithQuantity(address indexed from, address indexed to, uint256 indexed tokenId, uint256 quantity);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  event BatchTransfer(address indexed from, address indexed to, uint256[] tokenTypes, uint256[] amounts);
  event Composition(uint256 portfolioId, uint256[] tokenIds, uint256[] tokenRatio);
}

// File: erc721o/contracts/Interfaces/IERC721OReceiver.sol

pragma solidity ^0.5.4;

/**
 * @title ERC721O token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721O contracts.
 */
contract IERC721OReceiver {
  /**
    * @dev Magic value to be returned upon successful reception of an amount of ERC721O tokens
    *  ERC721O_RECEIVED = `bytes4(keccak256("onERC721OReceived(address,address,uint256,uint256,bytes)"))` = 0xf891ffe0
    *  ERC721O_BATCH_RECEIVED = `bytes4(keccak256("onERC721OBatchReceived(address,address,uint256[],uint256[],bytes)"))` = 0xd0e17c0b
    */
  bytes4 constant internal ERC721O_RECEIVED = 0xf891ffe0;
  bytes4 constant internal ERC721O_BATCH_RECEIVED = 0xd0e17c0b;

  function onERC721OReceived(
    address _operator,
    address _from,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) public returns(bytes4);

  function onERC721OBatchReceived(
    address _operator,
    address _from,
    uint256[] memory _types,
    uint256[] memory _amounts,
    bytes memory _data
  ) public returns (bytes4);
}

// File: erc721o/contracts/Libs/ObjectsLib.sol

pragma solidity ^0.5.4;


library ObjectLib {
  // Libraries
  using SafeMath for uint256;

  enum Operations { ADD, SUB, REPLACE }

  // Constants regarding bin or chunk sizes for balance packing
  uint256 constant TYPES_BITS_SIZE   = 32;                     // Max size of each object
  uint256 constant TYPES_PER_UINT256 = 256 / TYPES_BITS_SIZE; // Number of types per uint256

  //
  // Objects and Tokens Functions
  //

  /**
  * @dev Return the bin number and index within that bin where ID is
  * @param _tokenId Object type
  * @return (Bin number, ID's index within that bin)
  */
  function getTokenBinIndex(uint256 _tokenId) internal pure returns (uint256 bin, uint256 index) {
    bin = _tokenId * TYPES_BITS_SIZE / 256;
    index = _tokenId % TYPES_PER_UINT256;
    return (bin, index);
  }


  /**
  * @dev update the balance of a type provided in _binBalances
  * @param _binBalances Uint256 containing the balances of objects
  * @param _index Index of the object in the provided bin
  * @param _amount Value to update the type balance
  * @param _operation Which operation to conduct :
  *     Operations.REPLACE : Replace type balance with _amount
  *     Operations.ADD     : ADD _amount to type balance
  *     Operations.SUB     : Substract _amount from type balance
  */
  function updateTokenBalance(
    uint256 _binBalances,
    uint256 _index,
    uint256 _amount,
    Operations _operation) internal pure returns (uint256 newBinBalance)
  {
    uint256 objectBalance;
    if (_operation == Operations.ADD) {
      objectBalance = getValueInBin(_binBalances, _index);
      newBinBalance = writeValueInBin(_binBalances, _index, objectBalance.add(_amount));
    } else if (_operation == Operations.SUB) {
      objectBalance = getValueInBin(_binBalances, _index);
      newBinBalance = writeValueInBin(_binBalances, _index, objectBalance.sub(_amount));
    } else if (_operation == Operations.REPLACE) {
      newBinBalance = writeValueInBin(_binBalances, _index, _amount);
    } else {
      revert("Invalid operation"); // Bad operation
    }

    return newBinBalance;
  }
  
  /*
  * @dev return value in _binValue at position _index
  * @param _binValue uint256 containing the balances of TYPES_PER_UINT256 types
  * @param _index index at which to retrieve value
  * @return Value at given _index in _bin
  */
  function getValueInBin(uint256 _binValue, uint256 _index) internal pure returns (uint256) {

    // Mask to retrieve data for a given binData
    uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

    // Shift amount
    uint256 rightShift = 256 - TYPES_BITS_SIZE * (_index + 1);
    return (_binValue >> rightShift) & mask;
  }

  /**
  * @dev return the updated _binValue after writing _amount at _index
  * @param _binValue uint256 containing the balances of TYPES_PER_UINT256 types
  * @param _index Index at which to retrieve value
  * @param _amount Value to store at _index in _bin
  * @return Value at given _index in _bin
  */
  function writeValueInBin(uint256 _binValue, uint256 _index, uint256 _amount) internal pure returns (uint256) {
    require(_amount < 2**TYPES_BITS_SIZE, "Amount to write in bin is too large");

    // Mask to retrieve data for a given binData
    uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

    // Shift amount
    uint256 leftShift = 256 - TYPES_BITS_SIZE * (_index + 1);
    return (_binValue & ~(mask << leftShift) ) | (_amount << leftShift);
  }

}

// File: erc721o/contracts/ERC721OBase.sol

pragma solidity ^0.5.4;






contract ERC721OBase is IERC721O, ERC165, IERC721 {
  // Libraries
  using ObjectLib for ObjectLib.Operations;
  using ObjectLib for uint256;

  // Array with all tokenIds
  uint256[] internal allTokens;

  // Packed balances
  mapping(address => mapping(uint256 => uint256)) internal packedTokenBalance;

  // Operators
  mapping(address => mapping(address => bool)) internal operators;

  // Keeps aprovals for tokens from owner to approved address
  // tokenApprovals[tokenId][owner] = approved
  mapping (uint256 => mapping (address => address)) internal tokenApprovals;

  // Token Id state
  mapping(uint256 => uint256) internal tokenTypes;

  uint256 constant internal INVALID = 0;
  uint256 constant internal POSITION = 1;
  uint256 constant internal PORTFOLIO = 2;

  // Interface constants
  bytes4 internal constant INTERFACE_ID_ERC721O = 0x12345678;

  // EIP712 constants
  bytes32 public DOMAIN_SEPARATOR;
  bytes32 public PERMIT_TYPEHASH;

  // mapping holds nonces for approval permissions
  // nonces[holder] => nonce
  mapping (address => uint) public nonces;

  modifier isOperatorOrOwner(address _from) {
    require((msg.sender == _from) || operators[_from][msg.sender], "msg.sender is neither _from nor operator");
    _;
  }

  constructor() public {
    _registerInterface(INTERFACE_ID_ERC721O);
    
    // Calculate EIP712 constants
    DOMAIN_SEPARATOR = keccak256(abi.encode(
      keccak256("EIP712Domain(string name,string version,address verifyingContract)"),
      keccak256(bytes("ERC721o")),
      keccak256(bytes("1")),
      address(this)
    ));
    PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
  }

  function implementsERC721O() public pure returns (bool) {
    return true;
  }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function exists(uint256 _tokenId) public view returns (bool) {
    return tokenTypes[_tokenId] != INVALID;
  }

  /**
   * @dev return the _tokenId type' balance of _address
   * @param _address Address to query balance of
   * @param _tokenId type to query balance of
   * @return Amount of objects of a given type ID
   */
  function balanceOf(address _address, uint256 _tokenId) public view returns (uint256) {
    (uint256 bin, uint256 index) = _tokenId.getTokenBinIndex();
    return packedTokenBalance[_address][bin].getValueInBin(index);
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

  /**
   * @dev Gets Iterate through the list of existing tokens and return the indexes
   *        and balances of the tokens owner by the user
   * @param _owner The adddress we are checking
   * @return indexes The tokenIds
   * @return balances The balances of each token
   */
  function tokensOwned(address _owner) public view returns (uint256[] memory indexes, uint256[] memory balances) {
    uint256 numTokens = totalSupply();
    uint256[] memory tokenIndexes = new uint256[](numTokens);
    uint256[] memory tempTokens = new uint256[](numTokens);

    uint256 count;
    for (uint256 i = 0; i < numTokens; i++) {
      uint256 tokenId = allTokens[i];
      if (balanceOf(_owner, tokenId) > 0) {
        tempTokens[count] = balanceOf(_owner, tokenId);
        tokenIndexes[count] = tokenId;
        count++;
      }
    }

    // copy over the data to a correct size array
    uint256[] memory _ownedTokens = new uint256[](count);
    uint256[] memory _ownedTokensIndexes = new uint256[](count);

    for (uint256 i = 0; i < count; i++) {
      _ownedTokens[i] = tempTokens[i];
      _ownedTokensIndexes[i] = tokenIndexes[i];
    }

    return (_ownedTokensIndexes, _ownedTokens);
  }

  /**
   * @dev Will set _operator operator status to true or false
   * @param _operator Address to changes operator status.
   * @param _approved  _operator's new operator status (true or false)
   */
  function setApprovalForAll(address _operator, bool _approved) public {
    // Update operator status
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /// @notice Approve for all by signature
  function permit(address _holder, address _spender, uint256 _nonce, uint256 _expiry, bool _allowed, bytes calldata _signature) external {
    // Calculate hash
    bytes32 digest =
      keccak256(abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(
          PERMIT_TYPEHASH,
          _holder,
          _spender,
          _nonce,
          _expiry,
          _allowed
        ))
    ));

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    bytes32 r;
    bytes32 s;
    uint8 v;

    bytes memory signature = _signature;

    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := byte(0, mload(add(signature, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    address recoveredAddress;

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      recoveredAddress = address(0);
    } else {
      // solium-disable-next-line arg-overflow
      recoveredAddress = ecrecover(digest, v, r, s);
    }

    require(_holder != address(0), "Holder can't be zero address");
    require(_holder == recoveredAddress, "Signer address is invalid");
    require(_expiry == 0 || now <= _expiry, "Permission expired");
    require(_nonce == nonces[_holder]++, "Nonce is invalid");
    
    // Update operator status
    operators[_holder][_spender] = _allowed;
    emit ApprovalForAll(_holder, _spender, _allowed);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    require(_to != msg.sender, "Can't approve to yourself");
    tokenApprovals[_tokenId][msg.sender] = _to;
    emit Approval(msg.sender, _to, _tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 _tokenId, address _tokenOwner) public view returns (address) {
    return tokenApprovals[_tokenId][_tokenOwner];
  }

  /**
   * @dev Function that verifies whether _operator is an authorized operator of _tokenHolder.
   * @param _operator The address of the operator to query status of
   * @param _owner Address of the tokenHolder
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function isApprovedForAll(address _owner, address _operator) public view returns (bool isOperator) {
    return operators[_owner][_operator];
  }

  function isApprovedOrOwner(
    address _spender,
    address _owner,
    uint256 _tokenId
  ) public view returns (bool) {
    return (
      _spender == _owner ||
      getApproved(_tokenId, _owner) == _spender ||
      isApprovedForAll(_owner, _spender)
    );
  }

  function _updateTokenBalance(
    address _from,
    uint256 _tokenId,
    uint256 _amount,
    ObjectLib.Operations op
  ) internal {
    (uint256 bin, uint256 index) = _tokenId.getTokenBinIndex();
    packedTokenBalance[_from][bin] = packedTokenBalance[_from][bin].updateTokenBalance(
      index, _amount, op
    );
  }
}

// File: erc721o/contracts/ERC721OTransferable.sol

pragma solidity ^0.5.4;




contract ERC721OTransferable is ERC721OBase, ReentrancyGuard {
  // Libraries
  using Address for address;

  // safeTransfer constants
  bytes4 internal constant ERC721O_RECEIVED = 0xf891ffe0;
  bytes4 internal constant ERC721O_BATCH_RECEIVED = 0xd0e17c0b;

  function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds, uint256[] memory _amounts) public {
    // Batch Transfering
    _batchTransferFrom(_from, _to, _tokenIds, _amounts);
  }

  /**
    * @dev transfer objects from different tokenIds to specified address
    * @param _from The address to BatchTransfer objects from.
    * @param _to The address to batchTransfer objects to.
    * @param _tokenIds Array of tokenIds to update balance of
    * @param _amounts Array of amount of object per type to be transferred.
    * @param _data Data to pass to onERC721OReceived() function if recipient is contract
    * Note:  Arrays should be sorted so that all tokenIds in a same bin are adjacent (more efficient).
    */
  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _tokenIds,
    uint256[] memory _amounts,
    bytes memory _data
  ) public nonReentrant {
    // Batch Transfering
    _batchTransferFrom(_from, _to, _tokenIds, _amounts);

    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC721OReceiver(_to).onERC721OBatchReceived(
        msg.sender, _from, _tokenIds, _amounts, _data
      );
      require(retval == ERC721O_BATCH_RECEIVED);
    }
  }

  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _tokenIds,
    uint256[] memory _amounts
  ) public {
    safeBatchTransferFrom(_from, _to, _tokenIds, _amounts, "");
  }

  function transfer(address _to, uint256 _tokenId, uint256 _amount) public {
    _transferFrom(msg.sender, _to, _tokenId, _amount);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId, uint256 _amount) public {
    _transferFrom(_from, _to, _tokenId, _amount);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _amount) public {
    safeTransferFrom(_from, _to, _tokenId, _amount, "");
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _amount, bytes memory _data) public nonReentrant {
    _transferFrom(_from, _to, _tokenId, _amount);
    require(
      _checkAndCallSafeTransfer(_from, _to, _tokenId, _amount, _data),
      "Sent to a contract which is not an ERC721O receiver"
    );
  }

  /**
    * @dev transfer objects from different tokenIds to specified address
    * @param _from The address to BatchTransfer objects from.
    * @param _to The address to batchTransfer objects to.
    * @param _tokenIds Array of tokenIds to update balance of
    * @param _amounts Array of amount of object per type to be transferred.
    * Note:  Arrays should be sorted so that all tokenIds in a same bin are adjacent (more efficient).
    */
  function _batchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _tokenIds,
    uint256[] memory _amounts
  ) internal isOperatorOrOwner(_from) {
    // Requirements
    require(_tokenIds.length == _amounts.length, "Inconsistent array length between args");
    require(_to != address(0), "Invalid to address");

    // Number of transfers to execute
    uint256 nTransfer = _tokenIds.length;

    // Don't do useless calculations
    if (_from == _to) {
      for (uint256 i = 0; i < nTransfer; i++) {
        emit Transfer(_from, _to, _tokenIds[i]);
        emit TransferWithQuantity(_from, _to, _tokenIds[i], _amounts[i]);
      }
      return;
    }

    for (uint256 i = 0; i < nTransfer; i++) {
      require(_amounts[i] <= balanceOf(_from, _tokenIds[i]), "Quantity greater than from balance");
      _updateTokenBalance(_from, _tokenIds[i], _amounts[i], ObjectLib.Operations.SUB);
      _updateTokenBalance(_to, _tokenIds[i], _amounts[i], ObjectLib.Operations.ADD);

      emit Transfer(_from, _to, _tokenIds[i]);
      emit TransferWithQuantity(_from, _to, _tokenIds[i], _amounts[i]);
    }

    // Emit batchTransfer event
    emit BatchTransfer(_from, _to, _tokenIds, _amounts);
  }

  function _transferFrom(address _from, address _to, uint256 _tokenId, uint256 _amount) internal {
    require(isApprovedOrOwner(msg.sender, _from, _tokenId), "Not approved");
    require(_amount <= balanceOf(_from, _tokenId), "Quantity greater than from balance");
    require(_to != address(0), "Invalid to address");

    _updateTokenBalance(_from, _tokenId, _amount, ObjectLib.Operations.SUB);
    _updateTokenBalance(_to, _tokenId, _amount, ObjectLib.Operations.ADD);
    emit Transfer(_from, _to, _tokenId);
    emit TransferWithQuantity(_from, _to, _tokenId, _amount);
  }

  function _checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _amount,
    bytes memory _data
  ) internal returns (bool) {
    if (!_to.isContract()) {
      return true;
    }

    bytes4 retval = IERC721OReceiver(_to).onERC721OReceived(msg.sender, _from, _tokenId, _amount, _data);
    return(retval == ERC721O_RECEIVED);
  }
}

// File: erc721o/contracts/ERC721OMintable.sol

pragma solidity ^0.5.4;



contract ERC721OMintable is ERC721OTransferable {
  // Libraries
  using LibPosition for bytes32;

  // Internal functions
  function _mint(uint256 _tokenId, address _to, uint256 _supply) internal {
    // If the token doesn't exist, add it to the tokens array
    if (!exists(_tokenId)) {
      tokenTypes[_tokenId] = POSITION;
      allTokens.push(_tokenId);
    }

    _updateTokenBalance(_to, _tokenId, _supply, ObjectLib.Operations.ADD);
    emit Transfer(address(0), _to, _tokenId);
    emit TransferWithQuantity(address(0), _to, _tokenId, _supply);
  }

  function _burn(address _tokenOwner, uint256 _tokenId, uint256 _quantity) internal {
    uint256 ownerBalance = balanceOf(_tokenOwner, _tokenId);
    require(ownerBalance >= _quantity, "TOKEN_MINTER:NOT_ENOUGH_POSITIONS");

    _updateTokenBalance(_tokenOwner, _tokenId, _quantity, ObjectLib.Operations.SUB);
    emit Transfer(_tokenOwner, address(0), _tokenId);
    emit TransferWithQuantity(_tokenOwner, address(0), _tokenId, _quantity);
  }

  function _mint(address _buyer, address _seller, bytes32 _derivativeHash, uint256 _quantity) internal {
    _mintLong(_buyer, _derivativeHash, _quantity);
    _mintShort(_seller, _derivativeHash, _quantity);
  }
  
  function _mintLong(address _buyer, bytes32 _derivativeHash, uint256 _quantity) internal {
    uint256 longTokenId = _derivativeHash.getLongTokenId();
    _mint(longTokenId, _buyer, _quantity);
  }
  
  function _mintShort(address _seller, bytes32 _derivativeHash, uint256 _quantity) internal {
    uint256 shortTokenId = _derivativeHash.getShortTokenId();
    _mint(shortTokenId, _seller, _quantity);
  }

  function _registerPortfolio(uint256 _portfolioId, uint256[] memory _tokenIds, uint256[] memory _tokenRatio) internal {
    if (!exists(_portfolioId)) {
      tokenTypes[_portfolioId] = PORTFOLIO;
      emit Composition(_portfolioId, _tokenIds, _tokenRatio);
    }
  }
}

// File: erc721o/contracts/ERC721OComposable.sol

pragma solidity ^0.5.4;




contract ERC721OComposable is ERC721OMintable {
  // Libraries
  using UintArray for uint256[];
  using SafeMath for uint256;

  function compose(uint256[] memory _tokenIds, uint256[] memory _tokenRatio, uint256 _quantity) public {
    require(_tokenIds.length == _tokenRatio.length, "TOKEN_MINTER:TOKEN_IDS_AND_RATIO_LENGTH_DOES_NOT_MATCH");
    require(_quantity > 0, "TOKEN_MINTER:WRONG_QUANTITY");
    require(_tokenIds.length > 0, "TOKEN_MINTER:WRONG_QUANTITY");
    require(_tokenIds.isUnique(), "TOKEN_MINTER:TOKEN_IDS_NOT_UNIQUE");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      _burn(msg.sender, _tokenIds[i], _tokenRatio[i].mul(_quantity));
    }

    uint256 portfolioId = uint256(keccak256(abi.encodePacked(
      _tokenIds,
      _tokenRatio
    )));

    _registerPortfolio(portfolioId, _tokenIds, _tokenRatio);
    _mint(portfolioId, msg.sender, _quantity);
  }

  function decompose(uint256 _portfolioId, uint256[] memory _tokenIds, uint256[] memory _tokenRatio, uint256 _quantity) public {
    require(_tokenIds.length == _tokenRatio.length, "TOKEN_MINTER:TOKEN_IDS_AND_RATIO_LENGTH_DOES_NOT_MATCH");
    require(_quantity > 0, "TOKEN_MINTER:WRONG_QUANTITY");
    require(_tokenIds.length > 0, "TOKEN_MINTER:WRONG_QUANTITY");
    require(_tokenIds.isUnique(), "TOKEN_MINTER:TOKEN_IDS_NOT_UNIQUE");

    uint256 portfolioId = uint256(keccak256(abi.encodePacked(
      _tokenIds,
      _tokenRatio
    )));

    require(portfolioId == _portfolioId, "TOKEN_MINTER:WRONG_PORTFOLIO_ID");
    _burn(msg.sender, _portfolioId, _quantity);

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      _mint(_tokenIds[i], msg.sender, _tokenRatio[i].mul(_quantity));
    }
  }

  function recompose(
    uint256 _portfolioId,
    uint256[] memory _initialTokenIds,
    uint256[] memory _initialTokenRatio,
    uint256[] memory _finalTokenIds,
    uint256[] memory _finalTokenRatio,
    uint256 _quantity
  ) public {
    require(_initialTokenIds.length == _initialTokenRatio.length, "TOKEN_MINTER:INITIAL_TOKEN_IDS_AND_RATIO_LENGTH_DOES_NOT_MATCH");
    require(_finalTokenIds.length == _finalTokenRatio.length, "TOKEN_MINTER:FINAL_TOKEN_IDS_AND_RATIO_LENGTH_DOES_NOT_MATCH");
    require(_quantity > 0, "TOKEN_MINTER:WRONG_QUANTITY");
    require(_initialTokenIds.length > 0, "TOKEN_MINTER:WRONG_QUANTITY");
    require(_finalTokenIds.length > 0, "TOKEN_MINTER:WRONG_QUANTITY");
    require(_initialTokenIds.isUnique(), "TOKEN_MINTER:TOKEN_IDS_NOT_UNIQUE");
    require(_finalTokenIds.isUnique(), "TOKEN_MINTER:TOKEN_IDS_NOT_UNIQUE");

    uint256 oldPortfolioId = uint256(keccak256(abi.encodePacked(
      _initialTokenIds,
      _initialTokenRatio
    )));

    require(oldPortfolioId == _portfolioId, "TOKEN_MINTER:WRONG_PORTFOLIO_ID");
    _burn(msg.sender, _portfolioId, _quantity);
    
    _removedIds(_initialTokenIds, _initialTokenRatio, _finalTokenIds, _finalTokenRatio, _quantity);
    _addedIds(_initialTokenIds, _initialTokenRatio, _finalTokenIds, _finalTokenRatio, _quantity);
    _keptIds(_initialTokenIds, _initialTokenRatio, _finalTokenIds, _finalTokenRatio, _quantity);

    uint256 newPortfolioId = uint256(keccak256(abi.encodePacked(
      _finalTokenIds,
      _finalTokenRatio
    )));

    _registerPortfolio(newPortfolioId, _finalTokenIds, _finalTokenRatio);
    _mint(newPortfolioId, msg.sender, _quantity);
  }

  function _removedIds(
    uint256[] memory _initialTokenIds,
    uint256[] memory _initialTokenRatio,
    uint256[] memory _finalTokenIds,
    uint256[] memory _finalTokenRatio,
    uint256 _quantity
  ) private {
    (uint256[] memory removedIds, uint256[] memory removedIdsIdxs) = _initialTokenIds.difference(_finalTokenIds);

    for (uint256 i = 0; i < removedIds.length; i++) {
      uint256 index = removedIdsIdxs[i];
      _mint(_initialTokenIds[index], msg.sender, _initialTokenRatio[index].mul(_quantity));
    }

    _finalTokenRatio;
  }

  function _addedIds(
      uint256[] memory _initialTokenIds,
      uint256[] memory _initialTokenRatio,
      uint256[] memory _finalTokenIds,
      uint256[] memory _finalTokenRatio,
      uint256 _quantity
  ) private {
    (uint256[] memory addedIds, uint256[] memory addedIdsIdxs) = _finalTokenIds.difference(_initialTokenIds);

    for (uint256 i = 0; i < addedIds.length; i++) {
      uint256 index = addedIdsIdxs[i];
      _burn(msg.sender, _finalTokenIds[index], _finalTokenRatio[index].mul(_quantity));
    }

    _initialTokenRatio;
  }

  function _keptIds(
      uint256[] memory _initialTokenIds,
      uint256[] memory _initialTokenRatio,
      uint256[] memory _finalTokenIds,
      uint256[] memory _finalTokenRatio,
      uint256 _quantity
  ) private {
    (uint256[] memory keptIds, uint256[] memory keptInitialIdxs, uint256[] memory keptFinalIdxs) = _initialTokenIds.intersect(_finalTokenIds);

    for (uint256 i = 0; i < keptIds.length; i++) {
      uint256 initialIndex = keptInitialIdxs[i];
      uint256 finalIndex = keptFinalIdxs[i];

      if (_initialTokenRatio[initialIndex] > _finalTokenRatio[finalIndex]) {
        uint256 diff = _initialTokenRatio[initialIndex] - _finalTokenRatio[finalIndex];
        _mint(_initialTokenIds[initialIndex], msg.sender, diff.mul(_quantity));
      } else if (_initialTokenRatio[initialIndex] < _finalTokenRatio[finalIndex]) {
        uint256 diff = _finalTokenRatio[finalIndex] - _initialTokenRatio[initialIndex];
        _burn(msg.sender, _initialTokenIds[initialIndex], diff.mul(_quantity));
      }
    }
  }
}

// File: erc721o/contracts/Libs/UintsLib.sol

pragma solidity ^0.5.4;

library UintsLib {
  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }

    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }

    bytes memory bstr = new bytes(len);
    uint k = len - 1;
    while (_i != 0) {
      bstr[k--] = byte(uint8(48 + _i % 10));
      _i /= 10;
    }

    return string(bstr);
  }
}

// File: erc721o/contracts/ERC721OBackwardCompatible.sol

pragma solidity ^0.5.4;




contract ERC721OBackwardCompatible is ERC721OComposable {
  using UintsLib for uint256;

  // Interface constants
  bytes4 internal constant INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 internal constant INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
  bytes4 internal constant INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

  // Reciever constants
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  // Metadata URI
  string internal baseTokenURI;

  constructor(string memory _baseTokenURI) public ERC721OBase() {
    baseTokenURI = _baseTokenURI;
    _registerInterface(INTERFACE_ID_ERC721);
    _registerInterface(INTERFACE_ID_ERC721_ENUMERABLE);
    _registerInterface(INTERFACE_ID_ERC721_METADATA);
  }

  // ERC721 compatibility
  function implementsERC721() public pure returns (bool) {
    return true;
  }

  /**
    * @dev Gets the owner of a given NFT
    * @param _tokenId uint256 representing the unique token identifier
    * @return address the owner of the token
    */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    if (exists(_tokenId)) {
      return address(this);
    }

    return address(0);
  }

  /**
   *  @dev Gets the number of tokens owned by the address we are checking
   *  @param _owner The adddress we are checking
   *  @return balance The unique amount of tokens owned
   */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    (, uint256[] memory tokens) = tokensOwned(_owner);
    return tokens.length;
  }

  // ERC721 - Enumerable compatibility
  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * Reverts if the index is greater or equal to the total number of tokens
   * @param _index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId) {
    (, uint256[] memory tokens) = tokensOwned(_owner);
    require(_index < tokens.length);
    return tokens[_index];
  }

  // ERC721 - Metadata compatibility
  function tokenURI(uint256 _tokenId) public view returns (string memory tokenUri) {
    require(exists(_tokenId), "Token doesn't exist");
    return string(abi.encodePacked(
      baseTokenURI, 
      _tokenId.uint2str(),
      ".json"
    ));
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    if (exists(_tokenId)) {
      return address(this);
    }

    return address(0);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public nonReentrant {
    _transferFrom(_from, _to, _tokenId, 1);
    require(
      _checkAndCallSafeTransfer(_from, _to, _tokenId, _data),
      "Sent to a contract which is not an ERC721 receiver"
    );
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public {
    _transferFrom(_from, _to, _tokenId, 1);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * The call is not executed if the target address is not a contract
   * @param _from address representing the previous owner of the given token ID
   * @param _to target address that will receive the tokens
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function _checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  ) internal returns (bool) {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = IERC721Receiver(_to).onERC721Received(
        msg.sender, _from, _tokenId, _data
    );
    return (retval == ERC721_RECEIVED);
  }
}

// File: contracts/TokenMinter.sol

pragma solidity 0.5.16;



/// @title Opium.TokenMinter contract implements ERC721O token standard for minting, burning and transferring position tokens
contract TokenMinter is ERC721OBackwardCompatible, UsingRegistry {
    /// @notice Calls constructors of super-contracts
    /// @param _baseTokenURI string URI for token explorers
    /// @param _registry address Address of Opium.registry
    constructor(string memory _baseTokenURI, address _registry) public ERC721OBackwardCompatible(_baseTokenURI) UsingRegistry(_registry) {}

    /// @notice Mints LONG and SHORT position tokens
    /// @param _buyer address Address of LONG position receiver
    /// @param _seller address Address of SHORT position receiver
    /// @param _derivativeHash bytes32 Hash of derivative (ticker) of position
    /// @param _quantity uint256 Quantity of positions to mint
    function mint(address _buyer, address _seller, bytes32 _derivativeHash, uint256 _quantity) external onlyCore {
        _mint(_buyer, _seller, _derivativeHash, _quantity);
    }

    /// @notice Mints only LONG position tokens for "pooled" derivatives
    /// @param _buyer address Address of LONG position receiver
    /// @param _derivativeHash bytes32 Hash of derivative (ticker) of position
    /// @param _quantity uint256 Quantity of positions to mint
    function mint(address _buyer, bytes32 _derivativeHash, uint256 _quantity) external onlyCore {
        _mintLong(_buyer, _derivativeHash, _quantity);
    }

    /// @notice Burns position tokens
    /// @param _tokenOwner address Address of tokens owner
    /// @param _tokenId uint256 tokenId of positions to burn
    /// @param _quantity uint256 Quantity of positions to burn
    function burn(address _tokenOwner, uint256 _tokenId, uint256 _quantity) external onlyCore {
        _burn(_tokenOwner, _tokenId, _quantity);
    }

    /// @notice ERC721 interface compatible function for position token name retrieving
    /// @return Returns name of token
    function name() external view returns (string memory) {
        return "Opium Network Position Token";
    }

    /// @notice ERC721 interface compatible function for position token symbol retrieving
    /// @return Returns symbol of token
    function symbol() external view returns (string memory) {
        return "ONP";
    }

    /// VIEW FUNCTIONS

    /// @notice Checks whether _spender is approved to spend tokens on _owners behalf or owner itself
    /// @param _spender address Address of spender
    /// @param _owner address Address of owner
    /// @param _tokenId address tokenId of interest
    /// @return Returns whether _spender is approved to spend tokens
    function isApprovedOrOwner(
        address _spender,
        address _owner,
        uint256 _tokenId
    ) public view returns (bool) {
        return (
        _spender == _owner ||
        getApproved(_tokenId, _owner) == _spender ||
        isApprovedForAll(_owner, _spender) ||
        isOpiumSpender(_spender)
        );
    }

    /// @notice Checks whether _spender is Opium.TokenSpender
    /// @return Returns whether _spender is Opium.TokenSpender
    function isOpiumSpender(address _spender) public view returns (bool) {
        return _spender == registry.getTokenSpender();
    }
}

// File: contracts/Errors/OracleAggregatorErrors.sol

pragma solidity 0.5.16;

contract OracleAggregatorErrors {
    string constant internal ERROR_ORACLE_AGGREGATOR_NOT_ENOUGH_ETHER = "ORACLE_AGGREGATOR:NOT_ENOUGH_ETHER";

    string constant internal ERROR_ORACLE_AGGREGATOR_QUERY_WAS_ALREADY_MADE = "ORACLE_AGGREGATOR:QUERY_WAS_ALREADY_MADE";

    string constant internal ERROR_ORACLE_AGGREGATOR_DATA_DOESNT_EXIST = "ORACLE_AGGREGATOR:DATA_DOESNT_EXIST";

    string constant internal ERROR_ORACLE_AGGREGATOR_DATA_ALREADY_EXIST = "ORACLE_AGGREGATOR:DATA_ALREADY_EXIST";
}

// File: contracts/Interface/IOracleId.sol

pragma solidity 0.5.16;

/// @title Opium.Interface.IOracleId contract is an interface that every oracleId should implement
interface IOracleId {
    /// @notice Requests data from `oracleId` one time
    /// @param timestamp uint256 Timestamp at which data are needed
    function fetchData(uint256 timestamp) external payable;

    /// @notice Requests data from `oracleId` multiple times
    /// @param timestamp uint256 Timestamp at which data are needed for the first time
    /// @param period uint256 Period in seconds between multiple timestamps
    /// @param times uint256 How many timestamps are requested
    function recursivelyFetchData(uint256 timestamp, uint256 period, uint256 times) external payable;

    /// @notice Requests and returns price in ETH for one request. This function could be called as `view` function. Oraclize API for price calculations restricts making this function as view.
    /// @return fetchPrice uint256 Price of one data request in ETH
    function calculateFetchPrice() external returns (uint256 fetchPrice);

    // Event with oracleId metadata JSON string (for DIB.ONE derivative explorer)
    event MetadataSet(string metadata);
}

// File: contracts/OracleAggregator.sol

pragma solidity 0.5.16;





/// @title Opium.OracleAggregator contract requests and caches the data from `oracleId`s and provides them to the Core for positions execution
contract OracleAggregator is OracleAggregatorErrors, ReentrancyGuard {
    using SafeMath for uint256;

    // Storage for the `oracleId` results
    // dataCache[oracleId][timestamp] => data
    mapping (address => mapping(uint256 => uint256)) public dataCache;

    // Flags whether data were provided
    // dataExist[oracleId][timestamp] => bool
    mapping (address => mapping(uint256 => bool)) public dataExist;

    // Flags whether data were requested
    // dataRequested[oracleId][timestamp] => bool
    mapping (address => mapping(uint256 => bool)) public dataRequested;

    // MODIFIERS

    /// @notice Checks whether enough ETH were provided withing data request to proceed
    /// @param oracleId address Address of the `oracleId` smart contract
    /// @param times uint256 How many times the `oracleId` is being requested
    modifier enoughEtherProvided(address oracleId, uint256 times) {
        // Calling Opium.IOracleId function to get the data fetch price per one request
        uint256 oneTimePrice = calculateFetchPrice(oracleId);

        // Checking if enough ether was provided for `times` amount of requests
        require(msg.value >= oneTimePrice.mul(times), ERROR_ORACLE_AGGREGATOR_NOT_ENOUGH_ETHER);
        _;
    }

    // PUBLIC FUNCTIONS

    /// @notice Requests data from `oracleId` one time
    /// @param oracleId address Address of the `oracleId` smart contract
    /// @param timestamp uint256 Timestamp at which data are needed
    function fetchData(address oracleId, uint256 timestamp) public payable nonReentrant enoughEtherProvided(oracleId, 1) {
        // Check if was not requested before and mark as requested
        _registerQuery(oracleId, timestamp);

        // Call the `oracleId` contract and transfer ETH
        IOracleId(oracleId).fetchData.value(msg.value)(timestamp);
    }

    /// @notice Requests data from `oracleId` multiple times
    /// @param oracleId address Address of the `oracleId` smart contract
    /// @param timestamp uint256 Timestamp at which data are needed for the first time
    /// @param period uint256 Period in seconds between multiple timestamps
    /// @param times uint256 How many timestamps are requested
    function recursivelyFetchData(address oracleId, uint256 timestamp, uint256 period, uint256 times) public payable nonReentrant enoughEtherProvided(oracleId, times) {
        // Check if was not requested before and mark as requested in loop for each timestamp
        for (uint256 i = 0; i < times; i++) {	
            _registerQuery(oracleId, timestamp + period * i);
        }

        // Call the `oracleId` contract and transfer ETH
        IOracleId(oracleId).recursivelyFetchData.value(msg.value)(timestamp, period, times);
    }

    /// @notice Receives and caches data from `msg.sender`
    /// @param timestamp uint256 Timestamp of data
    /// @param data uint256 Data itself
    function __callback(uint256 timestamp, uint256 data) public {
        // Don't allow to push data twice
        require(!dataExist[msg.sender][timestamp], ERROR_ORACLE_AGGREGATOR_DATA_ALREADY_EXIST);

        // Saving data
        dataCache[msg.sender][timestamp] = data;

        // Flagging that data were received
        dataExist[msg.sender][timestamp] = true;
    }

    /// @notice Requests and returns price in ETH for one request. This function could be called as `view` function. Oraclize API for price calculations restricts making this function as view.
    /// @param oracleId address Address of the `oracleId` smart contract
    /// @return fetchPrice uint256 Price of one data request in ETH
    function calculateFetchPrice(address oracleId) public returns(uint256 fetchPrice) {
        fetchPrice = IOracleId(oracleId).calculateFetchPrice();
    }

    // PRIVATE FUNCTIONS

    /// @notice Checks if data was not requested and provided before and marks as requested
    /// @param oracleId address Address of the `oracleId` smart contract
    /// @param timestamp uint256 Timestamp at which data are requested
    function _registerQuery(address oracleId, uint256 timestamp) private {
        // Check if data was not requested and provided yet
        require(!dataRequested[oracleId][timestamp] && !dataExist[oracleId][timestamp], ERROR_ORACLE_AGGREGATOR_QUERY_WAS_ALREADY_MADE);

        // Mark as requested
        dataRequested[oracleId][timestamp] = true;	
    }

    // VIEW FUNCTIONS

    /// @notice Returns cached data if they exist, or reverts with an error
    /// @param oracleId address Address of the `oracleId` smart contract
    /// @param timestamp uint256 Timestamp at which data were requested
    /// @return dataResult uint256 Cached data provided by `oracleId`
    function getData(address oracleId, uint256 timestamp) public view returns(uint256 dataResult) {
        // Check if Opium.OracleAggregator has data
        require(hasData(oracleId, timestamp), ERROR_ORACLE_AGGREGATOR_DATA_DOESNT_EXIST);

        // Return cached data
        dataResult = dataCache[oracleId][timestamp];
    }

    /// @notice Getter for dataExist mapping
    /// @param oracleId address Address of the `oracleId` smart contract
    /// @param timestamp uint256 Timestamp at which data were requested
    /// @param result bool Returns whether data were provided already
    function hasData(address oracleId, uint256 timestamp) public view returns(bool result) {
        return dataExist[oracleId][timestamp];
    }
}

// File: contracts/Errors/SyntheticAggregatorErrors.sol

pragma solidity 0.5.16;

contract SyntheticAggregatorErrors {
    string constant internal ERROR_SYNTHETIC_AGGREGATOR_DERIVATIVE_HASH_NOT_MATCH = "SYNTHETIC_AGGREGATOR:DERIVATIVE_HASH_NOT_MATCH";
    string constant internal ERROR_SYNTHETIC_AGGREGATOR_WRONG_MARGIN = "SYNTHETIC_AGGREGATOR:WRONG_MARGIN";
    string constant internal ERROR_SYNTHETIC_AGGREGATOR_COMMISSION_TOO_BIG = "SYNTHETIC_AGGREGATOR:COMMISSION_TOO_BIG";
}

// File: contracts/SyntheticAggregator.sol

pragma solidity 0.5.16;







/// @notice Opium.SyntheticAggregator contract initialized, identifies and caches syntheticId sensitive data
contract SyntheticAggregator is SyntheticAggregatorErrors, LibDerivative, LibCommission, ReentrancyGuard {
    // Emitted when new ticker is initialized
    event Create(Derivative derivative, bytes32 derivativeHash);

    // Enum for types of syntheticId
    // Invalid - syntheticId is not initialized yet
    // NotPool - syntheticId with p2p logic
    // Pool - syntheticId with pooled logic
    enum SyntheticTypes { Invalid, NotPool, Pool }

    // Cache of buyer margin by ticker
    // buyerMarginByHash[derivativeHash] = buyerMargin
    mapping (bytes32 => uint256) public buyerMarginByHash;

    // Cache of seller margin by ticker
    // sellerMarginByHash[derivativeHash] = sellerMargin
    mapping (bytes32 => uint256) public sellerMarginByHash;

    // Cache of type by ticker
    // typeByHash[derivativeHash] = type
    mapping (bytes32 => SyntheticTypes) public typeByHash;

    // Cache of commission by ticker
    // commissionByHash[derivativeHash] = commission
    mapping (bytes32 => uint256) public commissionByHash;

    // Cache of author addresses by ticker
    // authorAddressByHash[derivativeHash] = authorAddress
    mapping (bytes32 => address) public authorAddressByHash;

    // PUBLIC FUNCTIONS

    /// @notice Initializes ticker, if was not initialized and returns `syntheticId` author commission from cache
    /// @param _derivativeHash bytes32 Hash of derivative
    /// @param _derivative Derivative Derivative itself
    /// @return commission uint256 Synthetic author commission
    function getAuthorCommission(bytes32 _derivativeHash, Derivative memory _derivative) public nonReentrant returns (uint256 commission) {
        // Initialize derivative if wasn't initialized before
        _initDerivative(_derivativeHash, _derivative);
        commission = commissionByHash[_derivativeHash];
    }

    /// @notice Initializes ticker, if was not initialized and returns `syntheticId` author address from cache
    /// @param _derivativeHash bytes32 Hash of derivative
    /// @param _derivative Derivative Derivative itself
    /// @return authorAddress address Synthetic author address
    function getAuthorAddress(bytes32 _derivativeHash, Derivative memory _derivative) public nonReentrant returns (address authorAddress) {
        // Initialize derivative if wasn't initialized before
        _initDerivative(_derivativeHash, _derivative);
        authorAddress = authorAddressByHash[_derivativeHash];
    }

    /// @notice Initializes ticker, if was not initialized and returns buyer and seller margin from cache
    /// @param _derivativeHash bytes32 Hash of derivative
    /// @param _derivative Derivative Derivative itself
    /// @return buyerMargin uint256 Margin of buyer
    /// @return sellerMargin uint256 Margin of seller
    function getMargin(bytes32 _derivativeHash, Derivative memory _derivative) public nonReentrant returns (uint256 buyerMargin, uint256 sellerMargin) {
        // If it's a pool, just return margin from syntheticId contract
        if (_isPool(_derivativeHash, _derivative)) {
            return IDerivativeLogic(_derivative.syntheticId).getMargin(_derivative); 
        }

        // Initialize derivative if wasn't initialized before
        _initDerivative(_derivativeHash, _derivative);

        // Check if margins for _derivativeHash were already cached
        buyerMargin = buyerMarginByHash[_derivativeHash];
        sellerMargin = sellerMarginByHash[_derivativeHash];
    }

    /// @notice Checks whether `syntheticId` implements pooled logic
    /// @param _derivativeHash bytes32 Hash of derivative
    /// @param _derivative Derivative Derivative itself
    /// @return result bool Returns whether synthetic implements pooled logic
    function isPool(bytes32 _derivativeHash, Derivative memory _derivative) public nonReentrant returns (bool result) {
        result = _isPool(_derivativeHash, _derivative);
    }

    // PRIVATE FUNCTIONS

    /// @notice Initializes ticker, if was not initialized and returns whether `syntheticId` implements pooled logic
    /// @param _derivativeHash bytes32 Hash of derivative
    /// @param _derivative Derivative Derivative itself
    /// @return result bool Returns whether synthetic implements pooled logic
    function _isPool(bytes32 _derivativeHash, Derivative memory _derivative) private returns (bool result) {
        // Initialize derivative if wasn't initialized before
        _initDerivative(_derivativeHash, _derivative);
        result = typeByHash[_derivativeHash] == SyntheticTypes.Pool;
    }

    /// @notice Initializes ticker: caches syntheticId type, margin, author address and commission
    /// @param _derivativeHash bytes32 Hash of derivative
    /// @param _derivative Derivative Derivative itself
    function _initDerivative(bytes32 _derivativeHash, Derivative memory _derivative) private {
        // Check if type for _derivativeHash was already cached
        SyntheticTypes syntheticType = typeByHash[_derivativeHash];

        // Type could not be Invalid, thus this condition says us that type was not cached before
        if (syntheticType != SyntheticTypes.Invalid) {
            return;
        }

        // For security reasons we calculate hash of provided _derivative
        bytes32 derivativeHash = getDerivativeHash(_derivative);
        require(derivativeHash == _derivativeHash, ERROR_SYNTHETIC_AGGREGATOR_DERIVATIVE_HASH_NOT_MATCH);

        // POOL
        // Get isPool from SyntheticId
        bool result = IDerivativeLogic(_derivative.syntheticId).isPool();
        // Cache type returned from synthetic
        typeByHash[derivativeHash] = result ? SyntheticTypes.Pool : SyntheticTypes.NotPool;

        // MARGIN
        // Get margin from SyntheticId
        (uint256 buyerMargin, uint256 sellerMargin) = IDerivativeLogic(_derivative.syntheticId).getMargin(_derivative);
        // We are not allowing both margins to be equal to 0
        require(buyerMargin != 0 || sellerMargin != 0, ERROR_SYNTHETIC_AGGREGATOR_WRONG_MARGIN);
        // Cache margins returned from synthetic
        buyerMarginByHash[derivativeHash] = buyerMargin;
        sellerMarginByHash[derivativeHash] = sellerMargin;

        // AUTHOR ADDRESS
        // Cache author address returned from synthetic
        authorAddressByHash[derivativeHash] = IDerivativeLogic(_derivative.syntheticId).getAuthorAddress();

        // AUTHOR COMMISSION
        // Get commission from syntheticId
        uint256 commission = IDerivativeLogic(_derivative.syntheticId).getAuthorCommission();
        // Check if commission is not set > 100%
        require(commission <= COMMISSION_BASE, ERROR_SYNTHETIC_AGGREGATOR_COMMISSION_TOO_BIG);
        // Cache commission
        commissionByHash[derivativeHash] = commission;

        // If we are here, this basically means this ticker was not used before, so we emit an event for Dapps developers about new ticker (derivative) and it's hash
        emit Create(_derivative, derivativeHash);
    }
}

// File: contracts/Lib/Whitelisted.sol

pragma solidity 0.5.16;

/// @title Opium.Lib.Whitelisted contract implements whitelist with modifier to restrict access to only whitelisted addresses
contract Whitelisted {
    // Whitelist array
    address[] internal whitelist;

    /// @notice This modifier restricts access to functions, which could be called only by whitelisted addresses
    modifier onlyWhitelisted() {
        // Allowance flag
        bool allowed = false;

        // Going through whitelisted addresses array
        uint256 whitelistLength = whitelist.length;
        for (uint256 i = 0; i < whitelistLength; i++) {
            // If `msg.sender` is met within whitelisted addresses, raise the flag and exit the loop
            if (whitelist[i] == msg.sender) {
                allowed = true;
                break;
            }
        }

        // Check if flag was raised
        require(allowed, "Only whitelisted allowed");
        _;
    }

    /// @notice Getter for whitelisted addresses array
    /// @return Array of whitelisted addresses
    function getWhitelist() public view returns (address[] memory) {
        return whitelist;
    }
}

// File: contracts/Lib/WhitelistedWithGovernance.sol

pragma solidity 0.5.16;


/// @title Opium.Lib.WhitelistedWithGovernance contract implements Opium.Lib.Whitelisted and adds governance for whitelist controlling
contract WhitelistedWithGovernance is Whitelisted {
    // Emitted when new governor is set
    event GovernorSet(address governor);

    // Emitted when new whitelist is proposed
    event Proposed(address[] whitelist);
    // Emitted when proposed whitelist is committed (set)
    event Committed(address[] whitelist);

    // Proposal life timelock interval
    uint256 public timeLockInterval;

    // Governor address
    address public governor;

    // Timestamp of last proposal
    uint256 public proposalTime;

    // Proposed whitelist
    address[] public proposedWhitelist;

    /// @notice This modifier restricts access to functions, which could be called only by governor
    modifier onlyGovernor() {
        require(msg.sender == governor, "Only governor allowed");
        _;
    }

    /// @notice Contract constructor
    /// @param _timeLockInterval uint256 Initial value for timelock interval
    /// @param _governor address Initial value for governor
    constructor(uint256 _timeLockInterval, address _governor) public {
        timeLockInterval = _timeLockInterval;
        governor = _governor;
        emit GovernorSet(governor);
    }

    /// @notice Calling this function governor could propose new whitelist addresses array. Also it allows to initialize first whitelist if it was not initialized yet.
    function proposeWhitelist(address[] memory _whitelist) public onlyGovernor {
        // Restrict empty proposals
        require(_whitelist.length != 0, "Can't be empty");

        // Consider empty whitelist as not initialized, as proposing of empty whitelists is not allowed
        // If whitelist has never been initialized, we set whitelist right away without proposal
        if (whitelist.length == 0) {
            whitelist = _whitelist;
            emit Committed(_whitelist);

        // Otherwise save current time as timestamp of proposal, save proposed whitelist and emit event
        } else {
            proposalTime = now;
            proposedWhitelist = _whitelist;
            emit Proposed(_whitelist);
        }
    }

    /// @notice Calling this function governor commits proposed whitelist if timelock interval of proposal was passed
    function commitWhitelist() public onlyGovernor {
        // Check if proposal was made
        require(proposalTime != 0, "Didn't proposed yet");

        // Check if timelock interval was passed
        require((proposalTime + timeLockInterval) < now, "Can't commit yet");
        
        // Set new whitelist and emit event
        whitelist = proposedWhitelist;
        emit Committed(whitelist);

        // Reset proposal time lock
        proposalTime = 0;
    }

    /// @notice This function allows governor to transfer governance to a new governor and emits event
    /// @param _governor address Address of new governor
    function setGovernor(address _governor) public onlyGovernor {
        require(_governor != address(0), "Can't set zero address");
        governor = _governor;
        emit GovernorSet(governor);
    }
}

// File: contracts/Lib/WhitelistedWithGovernanceAndChangableTimelock.sol

pragma solidity 0.5.16;


/// @notice Opium.Lib.WhitelistedWithGovernanceAndChangableTimelock contract implements Opium.Lib.WhitelistedWithGovernance and adds possibility for governor to change timelock interval within timelock interval
contract WhitelistedWithGovernanceAndChangableTimelock is WhitelistedWithGovernance {
    // Emitted when new timelock is proposed
    event Proposed(uint256 timelock);
    // Emitted when new timelock is committed (set)
    event Committed(uint256 timelock);

    // Timestamp of last timelock proposal
    uint256 public timeLockProposalTime;
    // Proposed timelock
    uint256 public proposedTimeLock;

    /// @notice Calling this function governor could propose new timelock
    /// @param _timelock uint256 New timelock value
    function proposeTimelock(uint256 _timelock) public onlyGovernor {
        timeLockProposalTime = now;
        proposedTimeLock = _timelock;
        emit Proposed(_timelock);
    }

    /// @notice Calling this function governor could commit previously proposed new timelock if timelock interval of proposal was passed
    function commitTimelock() public onlyGovernor {
        // Check if proposal was made
        require(timeLockProposalTime != 0, "Didn't proposed yet");
        // Check if timelock interval was passed
        require((timeLockProposalTime + timeLockInterval) < now, "Can't commit yet");
        
        // Set new timelock and emit event
        timeLockInterval = proposedTimeLock;
        emit Committed(proposedTimeLock);

        // Reset timelock time lock
        timeLockProposalTime = 0;
    }
}

// File: contracts/TokenSpender.sol

pragma solidity 0.5.16;





/// @title Opium.TokenSpender contract holds users ERC20 approvals and allows whitelisted contracts to use tokens
contract TokenSpender is WhitelistedWithGovernanceAndChangableTimelock {
    using SafeERC20 for IERC20;

    // Initial timelock period
    uint256 public constant WHITELIST_TIMELOCK = 1 hours;

    /// @notice Calls constructors of super-contracts
    /// @param _governor address Address of governor, who is allowed to adjust whitelist
    constructor(address _governor) public WhitelistedWithGovernance(WHITELIST_TIMELOCK, _governor) {}

    /// @notice Using this function whitelisted contracts could call ERC20 transfers
    /// @param token IERC20 Instance of token
    /// @param from address Address from which tokens are transferred
    /// @param to address Address of tokens receiver
    /// @param amount uint256 Amount of tokens to be transferred
    function claimTokens(IERC20 token, address from, address to, uint256 amount) external onlyWhitelisted {
        token.safeTransferFrom(from, to, amount);
    }

    /// @notice Using this function whitelisted contracts could call ERC721O transfers
    /// @param token IERC721O Instance of token
    /// @param from address Address from which tokens are transferred
    /// @param to address Address of tokens receiver
    /// @param tokenId uint256 Token ID to be transferred
    /// @param amount uint256 Amount of tokens to be transferred
    function claimPositions(IERC721O token, address from, address to, uint256 tokenId, uint256 amount) external onlyWhitelisted {
        token.safeTransferFrom(from, to, tokenId, amount);
    }
}

// File: contracts/Core.sol

pragma solidity 0.5.16;
















/// @title Opium.Core contract creates positions, holds and distributes margin at the maturity
contract Core is LibDerivative, LibCommission, UsingRegistry, CoreErrors, ReentrancyGuard {
    using SafeMath for uint256;
    using LibPosition for bytes32;
    using SafeERC20 for IERC20;

    // Emitted when Core creates new position
    event Created(address buyer, address seller, bytes32 derivativeHash, uint256 quantity);
    // Emitted when Core executes positions
    event Executed(address tokenOwner, uint256 tokenId, uint256 quantity);
    // Emitted when Core cancels ticker for the first time
    event Canceled(bytes32 derivativeHash);

    // Period of time after which ticker could be canceled if no data was provided to the `oracleId`
    uint256 public constant NO_DATA_CANCELLATION_PERIOD = 2 weeks;

    // Vaults for pools
    // This mapping holds balances of pooled positions
    // poolVaults[syntheticAddress][tokenAddress] => availableBalance
    mapping (address => mapping(address => uint256)) public poolVaults;

    // Vaults for fees
    // This mapping holds balances of fee recipients
    // feesVaults[feeRecipientAddress][tokenAddress] => availableBalance
    mapping (address => mapping(address => uint256)) public feesVaults;

    // Hashes of cancelled tickers
    mapping (bytes32 => bool) public cancelled;

    /// @notice Calls Core.Lib.UsingRegistry constructor
    constructor(address _registry) public UsingRegistry(_registry) {}

    // PUBLIC FUNCTIONS

    /// @notice This function allows fee recipients to withdraw their fees
    /// @param _tokenAddress address Address of an ERC20 token to withdraw
    function withdrawFee(address _tokenAddress) public nonReentrant {
        uint256 balance = feesVaults[msg.sender][_tokenAddress];
        feesVaults[msg.sender][_tokenAddress] = 0;
        IERC20(_tokenAddress).safeTransfer(msg.sender, balance);
    }

    /// @notice Creates derivative contracts (positions)
    /// @param _derivative Derivative Derivative definition
    /// @param _quantity uint256 Quantity of derivatives to be created
    /// @param _addresses address[2] Addresses of buyer and seller
    /// [0] - buyer address
    /// [1] - seller address - if seller is set to `address(0)`, consider as pooled position
    function create(Derivative memory _derivative, uint256 _quantity, address[2] memory _addresses) public nonReentrant {
        if (_addresses[1] == address(0)) {
            _createPooled(_derivative, _quantity, _addresses[0]);
        } else {
            _create(_derivative, _quantity, _addresses);
        }
    }

    /// @notice Executes several positions of `msg.sender` with same `tokenId`
    /// @param _tokenId uint256 `tokenId` of positions that needs to be executed
    /// @param _quantity uint256 Quantity of positions to execute
    /// @param _derivative Derivative Derivative definition
    function execute(uint256 _tokenId, uint256 _quantity, Derivative memory _derivative) public nonReentrant {
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory quantities = new uint256[](1);
        Derivative[] memory derivatives = new Derivative[](1);

        tokenIds[0] = _tokenId;
        quantities[0] = _quantity;
        derivatives[0] = _derivative;

        _execute(msg.sender, tokenIds, quantities, derivatives);
    }

    /// @notice Executes several positions of `_tokenOwner` with same `tokenId`
    /// @param _tokenOwner address Address of the owner of positions
    /// @param _tokenId uint256 `tokenId` of positions that needs to be executed
    /// @param _quantity uint256 Quantity of positions to execute
    /// @param _derivative Derivative Derivative definition
    function execute(address _tokenOwner, uint256 _tokenId, uint256 _quantity, Derivative memory _derivative) public nonReentrant {
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory quantities = new uint256[](1);
        Derivative[] memory derivatives = new Derivative[](1);

        tokenIds[0] = _tokenId;
        quantities[0] = _quantity;
        derivatives[0] = _derivative;

        _execute(_tokenOwner, tokenIds, quantities, derivatives);
    }

    /// @notice Executes several positions of `msg.sender` with different `tokenId`s
    /// @param _tokenIds uint256[] `tokenId`s of positions that needs to be executed
    /// @param _quantities uint256[] Quantity of positions to execute for each `tokenId`
    /// @param _derivatives Derivative[] Derivative definitions for each `tokenId`
    function execute(uint256[] memory _tokenIds, uint256[] memory _quantities, Derivative[] memory _derivatives) public nonReentrant {
        _execute(msg.sender, _tokenIds, _quantities, _derivatives);
    }

    /// @notice Executes several positions of `_tokenOwner` with different `tokenId`s
    /// @param _tokenOwner address Address of the owner of positions
    /// @param _tokenIds uint256[] `tokenId`s of positions that needs to be executed
    /// @param _quantities uint256[] Quantity of positions to execute for each `tokenId`
    /// @param _derivatives Derivative[] Derivative definitions for each `tokenId`
    function execute(address _tokenOwner, uint256[] memory _tokenIds, uint256[] memory _quantities, Derivative[] memory _derivatives) public nonReentrant {
        _execute(_tokenOwner, _tokenIds, _quantities, _derivatives);
    }

    /// @notice Cancels tickers, burns positions and returns margins to positions owners in case no data were provided within `NO_DATA_CANCELLATION_PERIOD`
    /// @param _tokenId uint256 `tokenId` of positions that needs to be canceled
    /// @param _quantity uint256 Quantity of positions to cancel
    /// @param _derivative Derivative Derivative definition
    function cancel(uint256 _tokenId, uint256 _quantity, Derivative memory _derivative) public nonReentrant {
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory quantities = new uint256[](1);
        Derivative[] memory derivatives = new Derivative[](1);

        tokenIds[0] = _tokenId;
        quantities[0] = _quantity;
        derivatives[0] = _derivative;

        _cancel(tokenIds, quantities, derivatives);
    }

    /// @notice Cancels tickers, burns positions and returns margins to positions owners in case no data were provided within `NO_DATA_CANCELLATION_PERIOD`
    /// @param _tokenIds uint256[] `tokenId` of positions that needs to be canceled
    /// @param _quantities uint256[] Quantity of positions to cancel for each `tokenId`
    /// @param _derivatives Derivative[] Derivative definitions for each `tokenId`
    function cancel(uint256[] memory _tokenIds, uint256[] memory _quantities, Derivative[] memory _derivatives) public nonReentrant {
        _cancel(_tokenIds, _quantities, _derivatives);
    }

    // PRIVATE FUNCTIONS

    struct CreatePooledLocalVars {
        SyntheticAggregator syntheticAggregator;
        IDerivativeLogic derivativeLogic;
        IERC20 marginToken;
        TokenSpender tokenSpender;
        TokenMinter tokenMinter;
    }

    /// @notice This function creates pooled positions
    /// @param _derivative Derivative Derivative definition
    /// @param _quantity uint256 Quantity of positions to create
    /// @param _address address Address of position receiver
    function _createPooled(Derivative memory _derivative, uint256 _quantity, address _address) private {
        // Local variables
        CreatePooledLocalVars memory vars;

        // Create instance of Opium.SyntheticAggregator
        // Create instance of Opium.IDerivativeLogic
        // Create instance of margin token
        // Create instance of Opium.TokenSpender
        // Create instance of Opium.TokenMinter
        vars.syntheticAggregator = SyntheticAggregator(registry.getSyntheticAggregator());
        vars.derivativeLogic = IDerivativeLogic(_derivative.syntheticId);
        vars.marginToken = IERC20(_derivative.token);
        vars.tokenSpender = TokenSpender(registry.getTokenSpender());
        vars.tokenMinter = TokenMinter(registry.getMinter());

        // Generate hash for derivative
        bytes32 derivativeHash = getDerivativeHash(_derivative);

        // Check with Opium.SyntheticAggregator if syntheticId is a pool
        require(vars.syntheticAggregator.isPool(derivativeHash, _derivative), ERROR_CORE_NOT_POOL);

        // Check if ticker was canceled
        require(!cancelled[derivativeHash], ERROR_CORE_TICKER_WAS_CANCELLED);

        // Validate input data against Derivative logic (`syntheticId`)
        require(vars.derivativeLogic.validateInput(_derivative), ERROR_CORE_SYNTHETIC_VALIDATION_ERROR);

        // Get cached margin required according to logic from Opium.SyntheticAggregator
        (uint256 margin, ) = vars.syntheticAggregator.getMargin(derivativeHash, _derivative);

        // Check ERC20 tokens allowance: margin * quantity
        // `msg.sender` must provide margin for position creation
        require(vars.marginToken.allowance(msg.sender, address(vars.tokenSpender)) >= margin.mul(_quantity), ERROR_CORE_NOT_ENOUGH_TOKEN_ALLOWANCE);

    	// Take ERC20 tokens from msg.sender, should never revert in correct ERC20 implementation
        vars.tokenSpender.claimTokens(vars.marginToken, msg.sender, address(this), margin.mul(_quantity));

        // Since it's a pooled position, we add transferred margin to pool balance
        poolVaults[_derivative.syntheticId][_derivative.token] = poolVaults[_derivative.syntheticId][_derivative.token].add(margin.mul(_quantity));

        // Mint LONG position tokens
        vars.tokenMinter.mint(_address, derivativeHash, _quantity);

        emit Created(_address, address(0), derivativeHash, _quantity);
    }

    struct CreateLocalVars {
        SyntheticAggregator syntheticAggregator;
        IDerivativeLogic derivativeLogic;
        IERC20 marginToken;
        TokenSpender tokenSpender;
        TokenMinter tokenMinter;
    }

    /// @notice This function creates p2p positions
    /// @param _derivative Derivative Derivative definition
    /// @param _quantity uint256 Quantity of positions to create
    /// @param _addresses address[2] Addresses of buyer and seller
    /// [0] - buyer address
    /// [1] - seller address
    function _create(Derivative memory _derivative, uint256 _quantity, address[2] memory _addresses) private {
        // Local variables
        CreateLocalVars memory vars;

        // Create instance of Opium.SyntheticAggregator
        // Create instance of Opium.IDerivativeLogic
        // Create instance of margin token
        // Create instance of Opium.TokenSpender
        // Create instance of Opium.TokenMinter
        vars.syntheticAggregator = SyntheticAggregator(registry.getSyntheticAggregator());
        vars.derivativeLogic = IDerivativeLogic(_derivative.syntheticId);
        vars.marginToken = IERC20(_derivative.token);
        vars.tokenSpender = TokenSpender(registry.getTokenSpender());
        vars.tokenMinter = TokenMinter(registry.getMinter());

        // Generate hash for derivative
        bytes32 derivativeHash = getDerivativeHash(_derivative);

        // Check with Opium.SyntheticAggregator if syntheticId is not a pool
        require(!vars.syntheticAggregator.isPool(derivativeHash, _derivative), ERROR_CORE_CANT_BE_POOL);

        // Check if ticker was canceled
        require(!cancelled[derivativeHash], ERROR_CORE_TICKER_WAS_CANCELLED);

        // Validate input data against Derivative logic (`syntheticId`)
        require(vars.derivativeLogic.validateInput(_derivative), ERROR_CORE_SYNTHETIC_VALIDATION_ERROR);

        uint256[2] memory margins;
        // Get cached margin required according to logic from Opium.SyntheticAggregator
        // margins[0] - buyerMargin
        // margins[1] - sellerMargin
        (margins[0], margins[1]) = vars.syntheticAggregator.getMargin(derivativeHash, _derivative);

        // Check ERC20 tokens allowance: (margins[0] + margins[1]) * quantity
        // `msg.sender` must provide margin for position creation
        require(vars.marginToken.allowance(msg.sender, address(vars.tokenSpender)) >= margins[0].add(margins[1]).mul(_quantity), ERROR_CORE_NOT_ENOUGH_TOKEN_ALLOWANCE);

    	// Take ERC20 tokens from msg.sender, should never revert in correct ERC20 implementation
        vars.tokenSpender.claimTokens(vars.marginToken, msg.sender, address(this), margins[0].add(margins[1]).mul(_quantity));

        // Mint LONG and SHORT positions tokens
        vars.tokenMinter.mint(_addresses[0], _addresses[1], derivativeHash, _quantity);

        emit Created(_addresses[0], _addresses[1], derivativeHash, _quantity);
    }

    struct ExecuteAndCancelLocalVars {
        TokenMinter tokenMinter;
        OracleAggregator oracleAggregator;
        SyntheticAggregator syntheticAggregator;
    }

    /// @notice Executes several positions of `_tokenOwner` with different `tokenId`s
    /// @param _tokenOwner address Address of the owner of positions
    /// @param _tokenIds uint256[] `tokenId`s of positions that needs to be executed
    /// @param _quantities uint256[] Quantity of positions to execute for each `tokenId`
    /// @param _derivatives Derivative[] Derivative definitions for each `tokenId`
    function _execute(address _tokenOwner, uint256[] memory _tokenIds, uint256[] memory _quantities, Derivative[] memory _derivatives) private {
        require(_tokenIds.length == _quantities.length, ERROR_CORE_TOKEN_IDS_AND_QUANTITIES_LENGTH_DOES_NOT_MATCH);
        require(_tokenIds.length == _derivatives.length, ERROR_CORE_TOKEN_IDS_AND_DERIVATIVES_LENGTH_DOES_NOT_MATCH);

        // Local variables
        ExecuteAndCancelLocalVars memory vars;

        // Create instance of Opium.TokenMinter
        // Create instance of Opium.OracleAggregator
        // Create instance of Opium.SyntheticAggregator
        vars.tokenMinter = TokenMinter(registry.getMinter());
        vars.oracleAggregator = OracleAggregator(registry.getOracleAggregator());
        vars.syntheticAggregator = SyntheticAggregator(registry.getSyntheticAggregator());

        for (uint256 i; i < _tokenIds.length; i++) {
            // Check if execution is performed after endTime
            require(now > _derivatives[i].endTime, ERROR_CORE_EXECUTION_BEFORE_MATURITY_NOT_ALLOWED);

            // Checking whether execution is performed by `_tokenOwner` or `_tokenOwner` allowed third party executions on it's behalf
            require(
                _tokenOwner == msg.sender ||
                IDerivativeLogic(_derivatives[i].syntheticId).thirdpartyExecutionAllowed(_tokenOwner),
                ERROR_CORE_SYNTHETIC_EXECUTION_WAS_NOT_ALLOWED
            );

            // Returns payout for all positions
            uint256 payout = _getPayout(_derivatives[i], _tokenIds[i], _quantities[i], vars);

            // Transfer payout
            if (payout > 0) {
                IERC20(_derivatives[i].token).safeTransfer(_tokenOwner, payout);
            }

            // Burn executed position tokens
            vars.tokenMinter.burn(_tokenOwner, _tokenIds[i], _quantities[i]);

            emit Executed(_tokenOwner, _tokenIds[i], _quantities[i]);
        }
    }

    /// @notice Cancels tickers, burns positions and returns margins to positions owners in case no data were provided within `NO_DATA_CANCELLATION_PERIOD`
    /// @param _tokenIds uint256[] `tokenId` of positions that needs to be canceled
    /// @param _quantities uint256[] Quantity of positions to cancel for each `tokenId`
    /// @param _derivatives Derivative[] Derivative definitions for each `tokenId`
    function _cancel(uint256[] memory _tokenIds, uint256[] memory _quantities, Derivative[] memory _derivatives) private {
        require(_tokenIds.length == _quantities.length, ERROR_CORE_TOKEN_IDS_AND_QUANTITIES_LENGTH_DOES_NOT_MATCH);
        require(_tokenIds.length == _derivatives.length, ERROR_CORE_TOKEN_IDS_AND_DERIVATIVES_LENGTH_DOES_NOT_MATCH);

        // Local variables
        ExecuteAndCancelLocalVars memory vars;

        // Create instance of Opium.TokenMinter
        // Create instance of Opium.OracleAggregator
        // Create instance of Opium.SyntheticAggregator
        vars.tokenMinter = TokenMinter(registry.getMinter());
        vars.oracleAggregator = OracleAggregator(registry.getOracleAggregator());
        vars.syntheticAggregator = SyntheticAggregator(registry.getSyntheticAggregator());

        for (uint256 i; i < _tokenIds.length; i++) {
            // Don't allow to cancel tickers with "dummy" oracleIds
            require(_derivatives[i].oracleId != address(0), ERROR_CORE_CANT_CANCEL_DUMMY_ORACLE_ID);

            // Check if cancellation is called after `NO_DATA_CANCELLATION_PERIOD` and `oracleId` didn't provided data
            require(
                _derivatives[i].endTime + NO_DATA_CANCELLATION_PERIOD <= now &&
                !vars.oracleAggregator.hasData(_derivatives[i].oracleId, _derivatives[i].endTime),
                ERROR_CORE_CANCELLATION_IS_NOT_ALLOWED
            );

            // Generate hash for derivative
            bytes32 derivativeHash = getDerivativeHash(_derivatives[i]);

            // Emit `Canceled` event only once and mark ticker as canceled
            if (!cancelled[derivativeHash]) {
                cancelled[derivativeHash] = true;
                emit Canceled(derivativeHash);
            }

            uint256[2] memory margins;
            // Get cached margin required according to logic from Opium.SyntheticAggregator
            // margins[0] - buyerMargin
            // margins[1] - sellerMargin
            (margins[0], margins[1]) = vars.syntheticAggregator.getMargin(derivativeHash, _derivatives[i]);

            uint256 payout;
            // Check if `_tokenId` is an ID of LONG position
            if (derivativeHash.getLongTokenId() == _tokenIds[i]) {
                // Set payout to buyerPayout
                payout = margins[0];

            // Check if `_tokenId` is an ID of SHORT position
            } else if (derivativeHash.getShortTokenId() == _tokenIds[i]) {
                // Set payout to sellerPayout
                payout = margins[1];
            } else {
                // Either portfolioId, hack or bug
                revert(ERROR_CORE_UNKNOWN_POSITION_TYPE);
            }
            
            // Transfer payout * _quantities[i]
            if (payout > 0) {
                IERC20(_derivatives[i].token).safeTransfer(msg.sender, payout.mul(_quantities[i]));
            }

            // Burn canceled position tokens
            vars.tokenMinter.burn(msg.sender, _tokenIds[i], _quantities[i]);
        }
    }

    /// @notice Calculates payout for position and gets fees
    /// @param _derivative Derivative Derivative definition
    /// @param _tokenId uint256 `tokenId` of positions
    /// @param _quantity uint256 Quantity of positions
    /// @param _vars ExecuteAndCancelLocalVars Helping local variables
    /// @return payout uint256 Payout for all tokens
    function _getPayout(Derivative memory _derivative, uint256 _tokenId, uint256 _quantity, ExecuteAndCancelLocalVars memory _vars) private returns (uint256 payout) {
        // Trying to getData from Opium.OracleAggregator, could be reverted
        // Opium allows to use "dummy" oracleIds, in this case data is set to `0`
        uint256 data;
        if (_derivative.oracleId != address(0)) {
            data = _vars.oracleAggregator.getData(_derivative.oracleId, _derivative.endTime);
        } else {
            data = 0;
        }

        uint256[2] memory payoutRatio;
        // Get payout ratio from Derivative logic
        // payoutRatio[0] - buyerPayout
        // payoutRatio[1] - sellerPayout
        (payoutRatio[0], payoutRatio[1]) = IDerivativeLogic(_derivative.syntheticId).getExecutionPayout(_derivative, data);

        // Generate hash for derivative
        bytes32 derivativeHash = getDerivativeHash(_derivative);

        // Check if ticker was canceled
        require(!cancelled[derivativeHash], ERROR_CORE_TICKER_WAS_CANCELLED);

        uint256[2] memory margins;
        // Get cached total margin required from Opium.SyntheticAggregator
        // margins[0] - buyerMargin
        // margins[1] - sellerMargin
        (margins[0], margins[1]) = _vars.syntheticAggregator.getMargin(derivativeHash, _derivative);

        uint256[2] memory payouts;
        // Calculate payouts from ratio
        // payouts[0] -> buyerPayout = (buyerMargin + sellerMargin) * buyerPayoutRatio / (buyerPayoutRatio + sellerPayoutRatio)
        // payouts[1] -> sellerPayout = (buyerMargin + sellerMargin) * sellerPayoutRatio / (buyerPayoutRatio + sellerPayoutRatio)
        payouts[0] = margins[0].add(margins[1]).mul(payoutRatio[0]).div(payoutRatio[0].add(payoutRatio[1]));
        payouts[1] = margins[0].add(margins[1]).mul(payoutRatio[1]).div(payoutRatio[0].add(payoutRatio[1]));
        
        // Check if `_tokenId` is an ID of LONG position
        if (derivativeHash.getLongTokenId() == _tokenId) {
            // Check if it's a pooled position
            if (_vars.syntheticAggregator.isPool(derivativeHash, _derivative)) {
                // Pooled position payoutRatio is considered as full payout, not as payoutRatio
                payout = payoutRatio[0];

                // Multiply payout by quantity
                payout = payout.mul(_quantity);

                // Check sufficiency of syntheticId balance in poolVaults
                require(
                    poolVaults[_derivative.syntheticId][_derivative.token] >= payout
                    ,
                    ERROR_CORE_INSUFFICIENT_POOL_BALANCE
                );

                // Subtract paid out margin from poolVault
                poolVaults[_derivative.syntheticId][_derivative.token] = poolVaults[_derivative.syntheticId][_derivative.token].sub(payout);
            } else {
                // Set payout to buyerPayout
                payout = payouts[0];

                // Multiply payout by quantity
                payout = payout.mul(_quantity);
            }

            // Take fees only from profit makers
            // Check: payout > buyerMargin * quantity
            if (payout > margins[0].mul(_quantity)) {
                // Get Opium and `syntheticId` author fees and subtract it from payout
                payout = payout.sub(_getFees(_vars.syntheticAggregator, derivativeHash, _derivative, payout - margins[0].mul(_quantity)));
            }

        // Check if `_tokenId` is an ID of SHORT position
        } else if (derivativeHash.getShortTokenId() == _tokenId) {
            // Set payout to sellerPayout
            payout = payouts[1];

            // Multiply payout by quantity
            payout = payout.mul(_quantity);

            // Take fees only from profit makers
            // Check: payout > sellerMargin * quantity
            if (payout > margins[1].mul(_quantity)) {
                // Get Opium fees and subtract it from payout
                payout = payout.sub(_getFees(_vars.syntheticAggregator, derivativeHash, _derivative, payout - margins[1].mul(_quantity)));
            }
        } else {
            // Either portfolioId, hack or bug
            revert(ERROR_CORE_UNKNOWN_POSITION_TYPE);
        }
    }

    /// @notice Calculates `syntheticId` author and opium fees from profit makers
    /// @param _syntheticAggregator SyntheticAggregator Instance of Opium.SyntheticAggregator
    /// @param _derivativeHash bytes32 Derivative hash
    /// @param _derivative Derivative Derivative definition
    /// @param _profit uint256 payout of one position
    /// @return fee uint256 Opium and `syntheticId` author fee
    function _getFees(SyntheticAggregator _syntheticAggregator, bytes32 _derivativeHash, Derivative memory _derivative, uint256 _profit) private returns (uint256 fee) {
        // Get cached `syntheticId` author address from Opium.SyntheticAggregator
        address authorAddress = _syntheticAggregator.getAuthorAddress(_derivativeHash, _derivative);
        // Get cached `syntheticId` fee percentage from Opium.SyntheticAggregator
        uint256 commission = _syntheticAggregator.getAuthorCommission(_derivativeHash, _derivative);

        // Calculate fee
        // fee = profit * commission / COMMISSION_BASE
        fee = _profit.mul(commission).div(COMMISSION_BASE);

        // If commission is zero, finish
        if (fee == 0) {
            return 0;
        }

        // Calculate opium fee
        // opiumFee = fee * OPIUM_COMMISSION_PART / OPIUM_COMMISSION_BASE
        uint256 opiumFee = fee.mul(OPIUM_COMMISSION_PART).div(OPIUM_COMMISSION_BASE);

        // Calculate author fee
        // authorFee = fee - opiumFee
        uint256 authorFee = fee.sub(opiumFee);

        // Get opium address
        address opiumAddress = registry.getOpiumAddress();

        // Update feeVault for Opium team
        // feesVault[opium][token] += opiumFee
        feesVaults[opiumAddress][_derivative.token] = feesVaults[opiumAddress][_derivative.token].add(opiumFee);

        // Update feeVault for `syntheticId` author
        // feeVault[author][token] += authorFee
        feesVaults[authorAddress][_derivative.token] = feesVaults[authorAddress][_derivative.token].add(authorFee);
    }
}