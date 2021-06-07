/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/proxy/[email protected]



// solhint-disable-next-line compiler-version


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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]





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


// File @openzeppelin/contracts-upgradeable/access/[email protected]






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


// File @openzeppelin/contracts/math/[email protected]





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


// File contracts/external/Decimal.sol



pragma experimental ABIEncoderV2;

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============


    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: 0 });
    }

    function one()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function from(
        uint256 a
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: a.mul(BASE) });
    }

    function ratio(
        uint256 a,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(a, BASE, b) });
    }

    // ============ Self Functions ============

    function add(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE), reason) });
    }

    function mul(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.mul(b) });
    }

    function div(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.div(b) });
    }

    function pow(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        if (b == 0) {
            return from(1);
        }

        D256 memory temp = D256({ value: self.value });
        for (uint256 i = 1; i < b; i++) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value, reason) });
    }

    function mul(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, b.value, BASE) });
    }

    function div(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, BASE, b.value) });
    }

    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    private
    pure
    returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(
        D256 memory a,
        D256 memory b
    )
    private
    pure
    returns (uint256)
    {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}


// File contracts/interfaces/ICWProtocol.sol





interface ICWProtocol {
    event ProjectCreation(bytes32 projectHash, address project, bool isCollective);

    function feeTo() external view returns (address payable);
    function protocolFee() external view returns (uint);
    function getAllProjects() external view returns (address[] memory);
    // function yieldFee() external view returns (uint);
    // function epochLength() external view returns (uint);

    // function strategyFor(address) external returns (address);

    function setFeeTo(address payable) external;
    function setProtocolFee(uint) external;
    // function setYieldFee(uint) external;

    function protocolVersion() external pure returns (string memory);
    // function updateTokenOracle(address _token, address _pool) external;
    // function updateTokenStrategy(address _token, bytes32 _name, address _depositTo, address _receive) external;
    // function oracleCaptureFor(address _token) external returns (uint256);
    // function oracleCaptureFor(address _token) external returns (Decimal.D256 memory);
	// function getTokenOracle(address _token) external view returns(address _oracle);

    // function getTokenPool(address _token) external view returns(address _pool);
    // function getTokenStrategy(address _address, bytes32 _name) external view returns(address _depositTo, address _received);
    // function getDefaultTokenStrategy(address _address) external view returns(address _depositTo, address _received);

    function allProjectsLength() external view returns (uint);
    function createProject(
        // bytes32 project, // TODO: need? 
        bytes32 name,
        bytes32 ipfsHash,
        bytes32 cwUrl,
        address recipient,
        address[] memory acceptedTokens,
        address[] memory nominations,
        uint256 threshold,
        uint256 deadline,
        uint curatorFee,
        uint projectId // TODO: store and increase all projectIds
    )
    external returns (address project);
}


// File contracts/oracle/IOracle.sol




interface IOracle {
    function setup() external;
    function capture() external returns (uint256, bool);
    function pair() external view returns (address);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]





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


// File contracts/CWStorage.sol




// Will Need to make upgradable


contract Storage {
    struct Strategy {
        address depositTo;
        address received;
        bool isDefault;
    }

    struct Provider {
        IOracle oracle;
        address tokenB;
        address pool;
    }

    struct Token {
        Provider provider;
        mapping(bytes32 => Strategy) strategies; 
        Strategy defaultStrat;
    }

    mapping(address => Token) tokens;
}


// File contracts/interfaces/ICWProject.sol





interface ICWProject {
    enum Status {
        Proposed,
        Succeeded,
        Failed
    }

    event Deposit(address sender, uint amount);
    event Curate(address sender, uint amount);
    event Withdraw(address sender, uint amount);
    event Proposed(address creator, uint threshold, uint deadline);
    event Succeeded();
    event Failed();
    event Nominated(uint _projectId, address _address);

    function lockedWithdraw() external view returns(bool);
    function funded() external view returns (bool);
    function name() external view returns (bytes32);
    function ipfsHash() external view returns (bytes32);
    function cwUrl() external view returns (bytes32);
    function beneficiary() external view returns (address);
    function creator() external view returns (address);
    function projectId() external view returns (uint);

    function totalFunding() external view returns (uint);
    function threshold() external view returns (uint256); // backing threshold in native token
    function deadline() external view returns (uint256); // deadline in blocktime
    function curatorFee() external view returns (uint);

    function factory() external view returns (address);
    function bToken() external view returns (address);
    function cToken() external view returns (address);

    function isAcceptedToken(address token) external view returns (bool);

    function backWithETH() external payable returns (bool);
    function back(address token, uint value) external returns (bool);
    function curateWithETH() external payable returns (bool);
    function curate(address token, uint value) external returns (bool);
    function withdraw() external returns (bool);
    function redeemBToken(address token, uint valueToRemove) external returns (bool);
    function redeemCToken(address token, uint valueToRemove) external returns (bool);
    // function withdrawETH(uint valueToRemove) external returns (bool);

    function setName(bytes32 _name) external;
    function setIpfsHash(bytes32 _ipfsHash) external;
    function setCwUrl(bytes32 _cwUrl) external;
    function setBeneficiary(address _beneficiary) external;
    function setThreshold(uint256 _threshold) external;

    function addNominations(address[] memory _nominations) external;
    function removeNominations(address[] memory _nominations) external;

    function addAcceptedTokens(address[] memory _tokens) external;
    function isNominationed(address nomination) external view returns (bool);
}


// File contracts/interfaces/IVault.sol





interface IVault {
    function token() external view returns (address);
    function underlying() external view returns (address);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function controller() external view returns (address);
    function governance() external view returns (address);
    function getPricePerFullShare() external view returns (uint256);
    function balanceOf() external view returns (uint256);
    function deposit(uint256) external;
    function depositAll() external;
    function withdraw(uint256) external;
    function withdrawAll() external;
}


// File contracts/interfaces/IWETHVault.sol





interface IWETHVault is IVault {
    function depositETH() external payable;
    function withdrawETH() external;
}


// File contracts/interfaces/ICWToken.sol





interface ICWToken {
    function approveOtherContract(IERC20 token, address recipient, uint256 amount) external;
}


// File @openzeppelin/contracts/utils/[email protected]





/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


// File @openzeppelin/contracts/utils/[email protected]





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


// File @openzeppelin/contracts/GSN/[email protected]





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


// File @openzeppelin/contracts/access/[email protected]







/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]







/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]






/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}


// File @openzeppelin/contracts/utils/[email protected]





/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]






/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}


// File @openzeppelin/contracts/presets/[email protected]









/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC20PresetMinterPauser is Context, AccessControl, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) public ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}


// File contracts/CWToken.sol





contract CWToken is ERC20PresetMinterPauser, ICWToken {
    address internal constant ETH_ADDRESS = address(0x0);

    string public constant TOKEN_NAME = "CWToken"; // TODO: change
    string public constant TOKEN_SYMBOL = "CW"; // TODO: change
    uint8 public constant DECIMALS = 18;
    string public constant B = "B";
    string public constant C = "C";

    constructor(address _token, bool _isBToken)
        public
        ERC20PresetMinterPauser(
            string(
                abi.encodePacked(
                    "CW ",
                    isBToken(_isBToken),
                    tokenName(_token),
                    " Token"
                )
            ),
            string(abi.encodePacked(isBToken(_isBToken), tokenSymbol(_token)))
        )
    {}

    function isBToken(bool _isBToken) internal returns (string memory) {
        if (_isBToken) {
            return B;
        }
        return C;
    }

    function tokenName(address _token) internal returns (string memory) {
        if (_token == ETH_ADDRESS) {
            return "Ethereum";
        }
        return ERC20(_token).name();
    }

    function tokenSymbol(address _token) internal returns (string memory) {
        if (_token == ETH_ADDRESS) {
            return "ETH";
        }
        return ERC20(_token).symbol();
    }

    function approveOtherContract(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external override {
        token.approve(recipient, amount);
    }
}


// File contracts/Constants.sol





library Constants {
    address public constant dydx = address(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);
    address public constant fulcrum = address(0x493C57C4763932315A328269E1ADaD09653B9081);

    // Accepted Tokens
    address public constant dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F); // DAI
    address public constant weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH

    // aaveTokens: https://docs.aave.com/developers/deployed-contracts
    address public constant aave = address(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
    address public constant aavePool = address(0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3);

    address public constant aDAI = address(0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d); // aDAI

    // cTokens: https://api.compound.finance/api/v2/ctoken
    address public constant cDAI = address(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643); // cDAI
    address public constant cETH = address(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5); // cETH

    // Yearn Vaults: https://docs.yearn.finance/developers/deployed-contracts-registry
    address public constant yWETH = address(0xe1237aA7f535b0CC33Fd973D66cBf830354D16c7);

    // Yearn Earn: https://docs.yearn.finance/developers/deployed-contracts-registry
    address public constant yDAIv3 = address(0xC2cB1040220768554cf699b0d863A3cd4324ce32); // yDAIv3
    address public constant yUSDCv3 = address(0x26EA744E5B887E5205727f55dFBE8685e3b21951); // yUSDCv3
    address public constant yUSDTv3 = address(0xE6354ed5bC4b393a5Aad09f21c46E101e692d447); // yUSDTv3
    address public constant yBUSDv3 = address(0x04bC0Ab673d88aE9dbC9DA2380cB6B79C4BCa9aE); // yBUSDv3

    /* Chain */
    uint256 private constant CHAIN_ID = 1; // Mainnet

    /* Oracle */
    address private constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    /* Deployed */
    // Address of the BaseProtocol DAO
    // TODO: Fill in with deployed address
    address private constant DAO_ADDRESS = address(0x0);

    // USDC/ETH pair address
    // TODO: Fill in with deployed address
    address private constant PAIR_ADDRESS = address(0x0);

    /**
        * Getters
        */

    function getUsdcAddress() internal pure returns (address) {
            return USDC;
    }

    function getChainId() internal pure returns (uint256) {
            return CHAIN_ID;
    }

    function getDaoAddress() internal pure returns (address) {
            return DAO_ADDRESS;
    }

    function getPairAddress() internal pure returns (address) {
            return PAIR_ADDRESS;
    }
}


// File contracts/CWProject.sol











contract CWProject is ICWProject {
    using SafeMath for uint;
    
    uint constant internal PRECISE_UINT = 10 ** 18;
    address constant internal ETH_ADDRESS = address(0x0);

    bool public override lockedWithdraw;
    bool public override funded;
    bytes32 public override name;
    bytes32 public override ipfsHash;
    bytes32 public override cwUrl;
    address public override beneficiary;
    address public override creator;
    uint public override projectId;

    uint256 public override threshold; // backing threshold in native token
    uint256 public override deadline; // backing threshold in native token
    uint public override curatorFee;

    address public override factory;
    address public override bToken;
    address public override cToken;

    address[] public acceptedTokenAddresses;    // accepted token address, will be used when withdraw all
    mapping (address => bool) public acceptedTokens;
    uint public override totalFunding;

    mapping (address => bool) public nominations;

    function isNominationed(address _nomination) external override view returns (bool) {
        return nominations[_nomination];
    }

    function isAcceptedToken(address _token) external override view returns (bool) {
        return acceptedTokens[_token];
    }

    constructor(
        bytes32 _name,
        bytes32 _ipfsHash,
        bytes32 _cwUrl,
        address _beneficiary,
        address _creator,
        address[] memory _tokens,
        address[] memory _nominations,
        uint256 _threshold,
        uint256 _deadline,
        uint _curatorFee,
        uint _projectId
    ) public {
        projectId = _projectId;
        factory = msg.sender;
        name = _name;
        ipfsHash = _ipfsHash;
        cwUrl = _cwUrl;
        beneficiary = _beneficiary;
        creator = _creator;
        addNominations(_nominations);
        threshold = _threshold;
        deadline = _deadline;
        bToken = address(new CWToken(_tokens[0], true)); // is CWToken or ERC20 constuctor?
        cToken = address(new CWToken(_tokens[0], false));
        curatorFee = _curatorFee;
        addAcceptedTokens(_tokens);
    }

    function isProtocolVersion1() internal returns (bool) {
        return keccak256(abi.encodePacked(ICWProtocol(factory).protocolVersion())) == keccak256(abi.encodePacked('1.0.0'));
    }

    function getDepositAddress(address _token, bool _isBacking) internal returns (address) {
        // todo: handle multi b/cTokens

        if (_isBacking) {
            return bToken;
        } else {
            return cToken;
        }
    }

    function backWithETH() external payable override onlyAcceptedToken(ETH_ADDRESS) onlyActiveProject returns (bool) {
        require(
            msg.value > 0,
            "Project: Backing amount must be greater than 0"
        );

        if (isProtocolVersion1()) {
            // bToken mints the same amount of the token to the msg.sender
            CWToken(bToken).mint(msg.sender, msg.value);

            // increment funding amounts from backer and for total 
            totalFunding = totalFunding.add(msg.value);

            // check if project reached funding threshold
            if (totalFunding > threshold) {
                funded = true;
                emit Succeeded();
            }
        } else {}

        emit Deposit(msg.sender, msg.value);

        return true;
    }

    function back(address token, uint value) external override onlyAcceptedToken(token) onlyActiveProject returns (bool) {
        require(value > 0, 'Requires non-zero backing amount');

        if(isProtocolVersion1()) {
            // deposit value to backing deposit address
            IERC20(token).transferFrom(msg.sender, address(this), value);

            // mints the same amount of token to the msg.sender
            CWToken(bToken).mint(msg.sender, value);

            // increment funding amounts from backer and for total 
            totalFunding = totalFunding.add(value);

            // check if project reached funding threshold
            if (totalFunding > threshold) {
                funded = true;
                emit Succeeded();
            }
        } else {
            // // if the token address is 0 then we assume backing with ETH
            // bool backingWithETH = token == address(0x0);
            // // TODO: Add better comments for variable stubs
            // address depositTo;
            // address received;
            // // bToken mint amount stub
            // uint256 v;
            // if (!backingWithETH) {
            //     // TODO: Convert token value into respective minting amount
            //     // TODO: Likely using an oracle against ETH/USD price
            //     v = value;
            //     (depositTo, received) = ICWProtocol(factory).getDefaultTokenStrategy(token);
            // } else {
            //     require(msg.value > 0 && value == 0, 'Requires non-zero curating amount');
            //     v = msg.value;
            //     (depositTo, received) = ICWProtocol(factory).getTokenStrategy(Constants.weth, 'yWETH');
            // }        

            // // mints the same amount of token to the msg.sender
            // CWToken(bToken).mint(msg.sender, v);
            // // increment funding amounts from backer and for total 
            // totalFunding += v;
            // // TODO: Track backing to protocol
            // // TODO: How to track backing in multiple currencies?
            // // ICWProtocol(factory).trackBacking(msg.sender, v);
            // // check if project reached funding threshold
            // if (totalFunding > threshold) {
            //     funded = true;
            // }

            // if (!backingWithETH) {
            //     // @TODO ??
            //     IERC20(depositTo).transfer(msg.sender, v);
            // } else {
            //     // deposit into vault
            //     IWETHVault(depositTo).depositETH{value:v};
            // }
        }

        emit Deposit(msg.sender, value);
        return true;
    }

    function curateWithETH() external payable override onlyAcceptedToken(ETH_ADDRESS) onlyActiveProject returns (bool) {
        require(
            msg.value > 0,
            "Project: Curating amount must be greater than 0"
        );

        if (isProtocolVersion1()) {
            // bToken mints the same amount of the token to the msg.sender
            CWToken(cToken).mint(msg.sender, msg.value);
        } else {}

        emit Curate(msg.sender, msg.value);

        return true;
    }

    function curate(address token, uint value) external override onlyAcceptedToken(token) onlyActiveProject returns (bool) {
        require(value > 0, 'Requires non-zero curating amount');

        if(isProtocolVersion1()){
            // deposit token to the Project
            IERC20(token).transferFrom(msg.sender, address(this), value);

            // mints the same amount of token to the msg.sender
            CWToken(cToken).mint(msg.sender, value);
        } else {
            // // if the token address is 0 then we assume curating with ETH
            // bool curatingWithETH = token == address(0x0);
            // // CToken mint amount stub
            // uint256 v;
            // address depositTo;
            // address received;
            // // if the token address is 0 then we assume curating with ETH
            // if (!curatingWithETH) {
            //     // TODO: Convert token value into respective minting amount
            //     v = value;
            //     (depositTo, received) = ICWProtocol(factory).getDefaultTokenStrategy(token);
            // } else {
            //     require(msg.value > 0, 'Requires non-zero curating amount');
            //     require(value == 0, 'Requires zero non-native value amount');
            //     v = msg.value;
            //     (depositTo, received) = ICWProtocol(factory).getTokenStrategy(Constants.weth, 'yWETH');
            // }
            
            // CWToken(cToken).mint(msg.sender, v); // mints the same amount of token to the msg.sender
            // _mintFee(v); // increment amounts from curator and for total project funding

            // // TODO: Where to deposit?
            // if (!curatingWithETH) {
            //     // @TODO ??
            //     IERC20(depositTo).transfer(msg.sender, v);
            // } else {
            //     // deposit into vault
            //     IWETHVault(depositTo).depositETH{value:v};
            // }
        }

        emit Curate(msg.sender, value);

        return true;
    }

    function withdraw() public override noRewithdraw onlyFinishedProject returns (bool) {
        require(msg.sender == beneficiary, 'Beneficiary can only call this method');

        if (!funded) {
            return false;
        }

        uint length = acceptedTokenAddresses.length;
        uint256 protocolFee = ICWProtocol(factory).protocolFee();
        address payable protocolFeeTo = ICWProtocol(factory).feeTo();
        uint withdrawPercent = 100 - curatorFee - protocolFee;

        if(isProtocolVersion1()){
            for (uint i=0; i < length; i++) {
                address token = acceptedTokenAddresses[i];  // each accepted token address
                uint256 amount = IERC20(bToken).totalSupply();

                if (amount > 0) {
                    // withdraw only available amount of the token
                    uint256 withdrawAmount =
                        amount.mul(withdrawPercent).div(100);
                    // send protocol fee to protocol
                    uint256 protocolFeeAmount =
                        amount.mul(protocolFee).div(100);

                    if (token == ETH_ADDRESS) {
                        (bool sent, ) =
                                beneficiary.call{value: withdrawAmount}("");
                        (bool sent_, ) =
                            protocolFeeTo.call{value: protocolFeeAmount}("");
                        require(
                            sent && sent_,
                            "Project: Withdraw ETH failed"
                        );
                    } else {
                        IERC20(token).transfer(beneficiary, withdrawAmount);
                        IERC20(token).transfer(
                            protocolFeeTo,
                            protocolFeeAmount
                        );
                    }
                }
            }
        } else {
            // for (uint i=0; i < length; i++) {
            //     address token = acceptedTokenAddresses[i];
            //     bool backingWithETH = token == address(0x0);
            //     address depositTo;
            //     address received;
            //     if (!backingWithETH) {
            //         (depositTo, received) = ICWProtocol(factory).getDefaultTokenStrategy(token);

            //         // uint256 totalBalance = IERC20(token).balanceOf(depositTo);  // totalFunding
            //         uint256 totalBalance = totalFunding;    // this will be fixed later considering Oracle

            //         // withdraw only available amount
            //         uint256 withdrawAmount = totalBalance * withdrawablePercent / 100;
            //         IERC20(token).transferFrom(depositTo, beneficiary, withdrawAmount);

            //         // send fundingSuccessFee(protocolFee) to protocol
            //         uint256 fundingSuccessFee = totalBalance * ICWProtocol(factory).protocolFee() / 100;
            //         IERC20(token).transferFrom(depositTo, ICWProtocol(factory).feeTo(), fundingSuccessFee);
            //     } else {
            //         (depositTo, received) = ICWProtocol(factory).getTokenStrategy(Constants.weth, 'yWETH');
            //         // uint256 totalBalance = IWETHVault(depositTo).balanceOf();   // totalFunding
            //         uint256 totalBalance = totalFunding;    // this will be fixed later considering Oracle
                    
            //         // withdraw only available amount
            //         uint256 withdrawAmount = totalBalance * withdrawablePercent / 100;
            //         IWETHVault(depositTo).withdraw(withdrawAmount);

            //         // todo:        send fundingSuccessFee(protocolFee) to protocol
            //         // question:    where send fundingSuccessFee to?
            //     }
            // }
        }
        emit Withdraw(msg.sender, totalFunding.mul(withdrawPercent).div(100));
        return true;
    }

    function redeemBToken(address _token, uint _amount) public override onlyAcceptedToken(_token) onlyFinishedProject returns (bool) {
        require(
            _amount > 0,
            "Project: RedeemBToken amount must be grater than 0"
        );
        require(!funded, "Project: Funding success");

        require(
            CWToken(bToken).balanceOf(msg.sender) >= _amount,
            "Project: Redeem amount exceeds your backed balance"
        );

        uint256 bTokenTotalSupply = IERC20(bToken).totalSupply();
        address payable protocolFeeTo = ICWProtocol(factory).feeTo();

        if (isProtocolVersion1()) {
            uint256 backedAmount =
                _amount.mul(100 - ICWProtocol(factory).protocolFee()).div(100);
            uint256 protocolFeeAmount = _amount.sub(backedAmount);

            if (_token == ETH_ADDRESS) {
                uint256 bonusAmount =
                    _amount
                        .mul(address(this).balance.sub(bTokenTotalSupply))
                        .div(bTokenTotalSupply);
                (bool sent, ) =
                    payable(msg.sender).call{
                        value: backedAmount.add(bonusAmount)
                    }("");
                (bool sent_, ) =
                    protocolFeeTo.call{value: protocolFeeAmount}("");
                require(sent && sent_, "Project: Redeem ETH failed");
            } else {
                uint256 bonusAmount =
                    _amount
                        .mul(
                        IERC20(_token).balanceOf(address(this)).sub(
                            bTokenTotalSupply
                        )
                    )
                        .div(bTokenTotalSupply);
                IERC20(_token).transfer(
                    msg.sender,
                    backedAmount.add(bonusAmount)
                );
                IERC20(_token).transfer(protocolFeeTo, protocolFeeAmount);
            }
        } else {
            // // reclaim their underlying collateral as well as the pro-rata claim on cTokens
            // bool backingWithETH = token == address(0x0);
            // address depositTo;
            // address received;
            // if (!backingWithETH) {
            //     (depositTo, received) = ICWProtocol(factory).getDefaultTokenStrategy(token);
            //     uint256 totalBalance = IERC20(token).balanceOf(depositTo);
            //     uint256 totalBalanceExceptCuratorFee = totalBalance * (100 - curatorFee) / 100;
            //     uint removePercent = valueToRemove / totalBalanceExceptCuratorFee * 100;    // get the percent of withdraw amount to calc curator fee
            //     uint256 withdrawCuratorFee = ((totalBalance * curatorFee / 100) * removePercent) / 100;
            //     require(totalFunding >= valueToRemove + withdrawCuratorFee, 'You are going to redeem greater than available amount');

            //     // reclaim underlying collateral
            //     IERC20(token).transferFrom(depositTo, msg.sender, valueToRemove);

            //     // reclaim their cut of the staked curator funds
            //     IERC20(token).transferFrom(depositTo, beneficiary, withdrawCuratorFee);

            //     // totalFunding - underlyingCollateral - curatorFee
            //     totalFunding = totalFunding - valueToRemove - withdrawCuratorFee;
            // } else {
            //     (depositTo, received) = ICWProtocol(factory).getTokenStrategy(Constants.weth, 'yWETH');
            //     uint256 totalBalance = IWETHVault(depositTo).balanceOf();
            //     uint256 totalBalanceExceptCuratorFee = totalBalance * (100 - curatorFee) / 100;
            //     uint removePercent = valueToRemove / totalBalanceExceptCuratorFee * 100;

            //     uint256 withdrawCuratorFee = ((totalBalance * curatorFee / 100) * removePercent) / 100; // get the percent of withdraw amount to calc curator fee
            //     require(totalFunding >= valueToRemove + withdrawCuratorFee, 'You are going to redeem greater than available amount');

            //     // reclaim underlying collateral
            //     IWETHVault(depositTo).withdraw(valueToRemove);

            //     // reclaim their cut of the staked curator funds
            //     IWETHVault(depositTo).withdraw(withdrawCuratorFee);

            //     // totalFunding - underlyingCollateral - curatorFee
            //     totalFunding = totalFunding - valueToRemove - withdrawCuratorFee;
            // }

            // // bToken burn valutToRemove
            // CWToken(bToken).burn(valueToRemove);
        }

        CWToken(bToken).burnFrom(msg.sender, _amount);

        return true;
    }

    function redeemCToken(address _token, uint256 _amount) public override onlyAcceptedToken(_token) onlyFinishedProject returns (bool) {
        require(
            _amount > 0,
            "Project: RedeemCToken amount must be grater than 0"
        );
        require(funded, "Project: Funding failed");

        require(
            CWToken(cToken).balanceOf(msg.sender) >= _amount,
            "Project: Redeem amount exceeds your curated balance"
        );

        uint256 cTokenTotalSupply = IERC20(cToken).totalSupply();

        if (isProtocolVersion1()) {
            if (_token == ETH_ADDRESS) {
                uint256 bonusAmount =
                    _amount
                        .mul(curatorFee)
                        .mul(address(this).balance.sub(cTokenTotalSupply))
                        .div(cTokenTotalSupply)
                        .div(100);
                (bool sent, ) =
                    payable(msg.sender).call{value: _amount.add(bonusAmount)}(
                        ""
                    );
                require(sent, "Project: Redeem ETH failed");
            } else {
                uint256 bonusAmount =
                    _amount
                        .mul(curatorFee)
                        .mul(
                        IERC20(_token).balanceOf(address(this)).sub(
                            cTokenTotalSupply
                        )
                    )
                        .div(cTokenTotalSupply)
                        .div(100);
                IERC20(_token).transfer(msg.sender, _amount.add(bonusAmount));
            }
        } else {
            // todo: logic for V2
        }

        CWToken(cToken).burnFrom(msg.sender, _amount);

        return true;
    }

    function _mintFee(uint _amount) private returns (bool feeOn) {
        // if fee is on mint fee
        address feeTo = ICWProtocol(factory).feeTo();
        feeOn = feeTo != address(0x0);
        if (feeOn) {
            // FIXME: This will be 0 unless amount is 1
            uint feeToMint = 1 / _amount;
            if (feeToMint > 0) CWToken(bToken).mint(feeTo, feeToMint);
        }
    }

    function setName(bytes32 _name) onlyCreator external override {
        name = _name;
    }

    function setIpfsHash(bytes32 _ipfsHash) onlyCreator external override {
        ipfsHash = _ipfsHash;
    }

    function setCwUrl(bytes32 _cwUrl) onlyCreator external override {
        cwUrl = _cwUrl;
    }

    function setBeneficiary(address _beneficiary) onlyCreator external override {
        beneficiary = _beneficiary;
    }

    function setThreshold(uint256 _threshold) onlyCreator external override {
        uint prevThreshold = threshold;
        require(prevThreshold <= _threshold, 'no stealing of funds');
        threshold = _threshold;
    }

    function addNominations(address[] memory _nominations) onlyCreator public override {
        uint length = _nominations.length;

        for (uint i=0; i < length; i++) {
            _addNomination(_nominations[i]);
        }
    }

    function _addNomination(address _nomination) onlyCreator public {
        // ICWProject(_nomination).propose(action); // @TODO

        if (_nomination == factory) {
            // implement logic for nominating Collective for v2
            // collective will be able to curate or back if they want
        } else {            
        }

        // push new _nomination to nominations array
        nominations[_nomination] = true;

        // emit event with projectId and string of address
        emit Nominated(projectId, _nomination);   // @TODO: determine second param
    }

    function _removeNomination(address _nomination) onlyCreator public {
        require(nominations[_nomination] == true);
        nominations[_nomination] == false;
    }

    function removeNominations(address[] memory _nominations) onlyCreator override external {
        uint length = _nominations.length;
        
        for (uint i=0; i < length; i++) {
            _removeNomination(_nominations[i]);
        }
    }

    function addAcceptedTokens(address[] memory _tokens) public override onlyCreator
    {
        uint256 length = _tokens.length;
        for (uint256 i = 0; i < length; i++) {
            _addAcceptedToken(_tokens[i]);
        }
    }

    function _addAcceptedToken(address _token) onlyCreator public {
        if (!acceptedTokens[_token]) {
            acceptedTokens[_token] = true;
            acceptedTokenAddresses.push(_token);
        }
    }

    modifier onlyCreator {
        require(tx.origin == creator);
        _;
    }

    modifier onlyAcceptedToken(address _token) {
        require(
            acceptedTokens[_token],
            "Project: Token is not an acceptedToken"
        );
        _;
    }

    modifier onlyActiveProject() {
        require(
            block.timestamp < deadline,
            'Project: Deadline is passed');
        _;
    }

    modifier onlyFinishedProject() {
        require(
            block.timestamp >= deadline,
            "Project: Prior to deadline"
        );
        _;
    }

    modifier noRewithdraw() {
        require(!lockedWithdraw, "Project: No rewithdraw");

        lockedWithdraw = true;
        _;
    }
}


// File contracts/CWProtocol.sol






// import './oracle/IDAO.sol'; // CWProtocol is inherited from IDAO
// import './oracle/IOracle.sol';;
// import './CWCollective.sol';
// import './Constants.sol';

// Protocol is the Proxy/Controller/Factory for Projects and Collectives
contract CWProtocol is ICWProtocol, OwnableUpgradeable, Storage {

    // the fee taken from total amount raised on each project in basis points
    uint public override protocolFee;
    
    // // the fee taken from yield generated on deposited assets in basis points
    // uint public override yieldFee;
    
    // // period of time to which deposited assets can be harvested
    // uint public override epochLength;

    // the address to which all fees go to
    address payable public override feeTo;

    uint256 public maxFee;

    // struct BackingClaimInfo {
    //     uint256 backingAmount;
    //     uint256 timestamp;
    //     uint256 rolledOverReward; // @TODO: how to determine
    // }

    // struct CurationClaimInfo {
    //     mapping(address => uint256) curationAmounts;
    //     address[] curationTokens;
    //     uint256 timestamp;
    //     uint256 rolledOverReward;
    // }

    mapping (bytes32 => address) public projects;
    // mapping (bytes32 => bool) public projectsBacked;
    // mapping (bytes32 => uint) public totalProjectsFunding;
    // mapping (address => mapping (bytes32 => uint256)) public projectBacking;
    // mapping (address => mapping (bytes32 => BackingClaimInfo)) public unclaimedBackingRewards;
    // mapping (address => mapping (bytes32 => uint256)) public projectCurating;
    // mapping (address => mapping (bytes32 => CurationClaimInfo)) public unclaimedCurationRewards;

    address[] public allProjects;

    // function epoch() override external view returns (uint256) {
    //     return epochLength;
    // }

    // // TODO: Set up oracle with Getters/State structure
    // function oracleFor(address _token) public returns (IOracle) {
    //     return tokens[_token].provider.oracle;
    // }

    function protocolVersion() override public pure returns (string memory) {
        return '1.0.0';
    }

    // function strategyFor(address) external override returns (address) {
    //   // TODO
    // }
    // function updateTokenOracle(address _token, address _pool) external override {
    //   // TODO
    // }
    // function updateTokenStrategy(address _token, bytes32 _name, address _depositTo, address _receive) external override {
    //   // TODO
    // }

    function initialize(address nn) public initializer {
        __Ownable_init();
        // updateTokenStrategy(Constants.weth, 'cETH', Constants.cETH, Constants.cETH, true);
        // updateTokenStrategy(Constants.weth, 'yWETH', Constants.yWETH, Constants.yWETH, false);
        // updateTokenStrategy(Constants.dai, 'aDAI', Constants.aavePool, Constants.aDAI, false);
        // updateTokenStrategy(Constants.dai, 'cDAI', Constants.cDAI, Constants.cDAI, false);
        // updateTokenStrategy(Constants.dai, 'yDAI', Constants.yDAIv3, Constants.yDAIv3, true);

        maxFee = 10000; // TODO: ??? 
    }

    function createProject(
        // bytes32 project, // TODO: need? 
        bytes32 name,
        bytes32 ipfsHash,
        bytes32 cwUrl,
        address recipient,
        address[] memory acceptedTokens,
        address[] memory nominations,
        uint256 threshold,
        uint256 deadline,
        uint curatorFee,
        uint projectId
    )
        external override
        returns (address)
    {
        bytes32 pHash = _project_to_hash(msg.sender, recipient, name, threshold);
        address creator = msg.sender;

        CWProject p = new CWProject(
            name,
            ipfsHash,
            cwUrl,
            recipient,
            creator,
            acceptedTokens,
            nominations,
            threshold,
            deadline,
            curatorFee,
            projectId
        );

        projects[pHash] = address(p);
        allProjects.push(address(p));

        bool isCollective = false;
        emit ProjectCreation(pHash, address(p), isCollective);
        return address(p);
    }

    // function createCollective(
        
    // )

    // function updateTokenStrategy(address _token, bytes32 _name, address _depositTo, address _receive, bool isDefault) public onlyOwner {
    //     Strategy memory strat = Strategy(_depositTo, _receive, isDefault);
    //     tokens[_token].strategies[_name] = strat;
    //     if (isDefault) {
    //         tokens[_token].defaultStrat = strat;
    //     }
    // }

    // function updateTokenProvider(address _token, address _tokenB, address _oracle) public onlyOwner  {
    //     tokens[_token].provider.tokenB = _tokenB;
    //     tokens[_token].provider.oracle = IOracle(_oracle);
    // }

    // function oracleCaptureFor(address _token) override external returns (uint256) {
    //     (uint256 price, bool valid) = oracleFor(_token).capture();

    //     if (!valid) {
    //         return 1;
    //     }

    //     return price;
    // }

    // function getTokenOracle(address _token) public view returns(address _oracle) {
    //   return tokens[_token].provider.oracle;
    // }

    // function getTokenPool(address _token) override public view returns(address _pool) {
    // // require(tokens[_address].provider == null, 'no pool set');
    //     return tokens[_token].provider.pool;
    // }

    // function getDefaultTokenStrategy(address _address) override public view returns(address _depositTo, address _received) {
    //     return (tokens[_address].defaultStrat.depositTo, tokens[_address].defaultStrat.received);
    // }

    // function getTokenStrategy(address _address, bytes32 _name) override public view returns(address _depositTo, address _received) {
    //     return (tokens[_address].strategies[_name].depositTo, tokens[_address].strategies[_name].received);
    // }

    function allProjectsLength() override external view returns (uint) {
        return allProjects.length;
    }

    function getAllProjects() override external view returns(address[] memory) {
        return allProjects;
    }

    function _project_to_hash(address creator, address recipient, bytes32 name, uint256 threshold) internal pure returns (bytes32) {
        bytes memory encoded = abi.encodePacked(creator, recipient, name, threshold);
        return keccak256(encoded);
    }

    function setFeeTo(address payable _feeTo) onlyOwner override external {
        feeTo = _feeTo;
    }

    function setProtocolFee(uint _protocolFee) onlyOwner override external {
        require(_protocolFee <= maxFee, 'fee too high');
        protocolFee = _protocolFee;
    }

    // function setYieldFee(uint _yieldFee) onlyOwner override external {
    //     require(_yieldFee <= maxFee, 'fee too high');
    //     yieldFee = _yieldFee;
    // }
}