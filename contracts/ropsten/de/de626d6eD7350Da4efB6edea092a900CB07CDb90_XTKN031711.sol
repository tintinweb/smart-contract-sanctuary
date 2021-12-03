/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// #############################################################################################################################
// ####################################### I M P O R T - E X T E R N A L - L I B R A R Y #######################################
// #############################################################################################################################
 
// We are using an external library to secure/optimize the contract, please check the github release for further information
// this code is not provided by us, but deemed secure by the community
 
// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// #############################################################################################################################
// #################################################### I M P O R T - E N D ####################################################
// #############################################################################################################################
 
// #############################################################################################################################
// ####################################### I M P O R T - E X T E R N A L - L I B R A R Y #######################################
// #############################################################################################################################
 
// We are using an external library to secure/optimize the contract, please check the github release for further information
// this code is not provided by us, but deemed secure by the community
 
// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
// #############################################################################################################################
// #################################################### I M P O R T - E N D ####################################################
// #############################################################################################################################
 
// #############################################################################################################################
// ####################################### I M P O R T - E X T E R N A L - L I B R A R Y #######################################
// #############################################################################################################################
 
// We are using an external library to secure/optimize the contract, please check the github release for further information
// this code is not provided by us, but deemed secure by the community
 
// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// #############################################################################################################################
// #################################################### I M P O R T - E N D ####################################################
// #############################################################################################################################
 
// #############################################################################################################################
// ####################################### I M P O R T - E X T E R N A L - L I B R A R Y #######################################
// #############################################################################################################################
 
// We are using an external library to secure/optimize the contract, please check the github release for further information
// this code is not provided by us, but deemed secure by the community
 
// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Proxy.sol

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// #############################################################################################################################
// #################################################### I M P O R T - E N D ####################################################
// #############################################################################################################################
 
// #############################################################################################################################
// ####################################### I M P O R T - E X T E R N A L - L I B R A R Y #######################################
// #############################################################################################################################
 
// We are using an external library to secure/optimize the contract, please check the github release for further information
// this code is not provided by us, but deemed secure by the community
 
// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
// #############################################################################################################################
// #################################################### I M P O R T - E N D ####################################################
// #############################################################################################################################
 


abstract contract ProxyAccess is Context, Ownable{
    mapping(address => bool) internal _proxies;
    address internal _proxyProject;

    modifier onlyProxy(){
        require(_isProxy(_msgSender()), "[ERROR] Only proxies can call this function directly!");
        _;
    }

    modifier onlyProxyProject(){
        require(_msgSender() == _proxyProject, "[ERROR] Only project proxy can call this function directly!");
        _;
    }

    function addProxy(address pContract) public virtual onlyOwner{
        _proxies[pContract] = true;
    }

    function removeProxy(address pContract) public virtual onlyOwner{
        _proxies[pContract] = false;
    }

    function _isProxy(address pContract) internal view returns(bool){
        if(_proxies[pContract]){
            return(true);
        }
        return(false);
    }

    // proxies
    function setProxyProject(address pContract) public virtual onlyOwner{
        _proxyProject = pContract;
    }
}


contract IXTKN031711Liquidity{
    function init() public{}
    function getPair() public returns(address){}
}


contract IXTKN031711Project{
    function init() public{}
    function tax(uint256) public{}
}


// main contract []
contract XTKN031711 is Context, IERC20, Ownable, ProxyAccess{
    // public properties
        // lib
            using SafeMath for uint256;
            using Address for address;

        // interfaces
            IXTKN031711Liquidity private _liquidity;
            IXTKN031711Project private _project;

        // addresses
            address public ADDRESS_BURN = 0x000000000000000000000000000000000000dEaD; // burn baby burn!
            address public ADDRESS_LIQUIDITY;// liquidity contract, locked no owner
            address public ADDRESS_PAIR;// swap pair contract, locked no owner
            address public ADDRESS_LOTTERY;// lottery contract, locked no owner
            address public ADDRESS_STAKING;// default stacking (add/withdraw any time), locked no owner
            address public ADDRESS_PROJECT;// project funds, unlocked (team)
            address public ADDRESS_STAKING_DAYS30;// staking for 30 days contract, locked no owner
            address public ADDRESS_STAKING_DAYS90;// staking for three months contract, locked no owner
            address public ADDRESS_STAKING_DAYS180;// staking for half a year, locked no owner
            address public ADDRESS_STAKING_DAYS365;// staking for a year, locked no owner

        // taxes
            uint16 public TAX_BUY_LOTTERY = 45;
            uint16 public TAX_BUY_STAKING = 45;
            uint16 public TAX_BUY_PROJECT = 10;
            uint16 public TAX_BUY_BURN = 0;

            uint16 public TAX_SELL_LOTTERY = 10;
            uint16 public TAX_SELL_STAKING = 10;
            uint16 public TAX_SELL_PROJECT = 0;
            uint16 public TAX_SELL_BURN = 80;

        // token distribution
            uint256 public TOKENS_FOR_PROJECT;
            uint256 public TOKENS_FOR_STAKING;
            uint256 public TOKENS_FOR_LIQUIDITY;

    // private properties
        // tokenomics
            string private _name = "XTKN031711";
            string private _symbol = "XTKN031711";
            uint8 private _decimals = 9;
            uint256 private _totalSupply = 1000000000 * (10 ** 9); // one billion

        // mappings (data storage)
            mapping(address => uint256) private _balances;
            mapping(address => mapping (address => uint256)) private _allowances;
            mapping(address => bool) private _accountNoTaxes;
            mapping(address => uint256) private _teamMemberWallets;

        // struct
            struct Tax{
                uint16 Lottery;
                uint16 Staking;
                uint16 Project;
                uint16 Burn;
                uint256 totalLottery;
                uint256 totalStaking;
                uint256 totalProject;
                uint256 totalBurn;
                uint256 total;
            }

        // activation of contracts
            bool private _contractLiquidityActive = false;
            bool private _contractLotteryActive = false;
            bool private _contractStakingActive = false;
            bool private _contractProjectActive = false;

    // events
        event ContractCreation();
        event ContractLocked(address indexed locker, uint256 time);

        event TransactionStart(address indexed pFrom, address indexed to, uint256 value);
            event TransactionWithNoTaxes();
            event TransactionWithTaxes(uint256 taxes);
            event TransactionBurn(uint256 burn, uint256 total);
            event TransactionLottery(uint256 lotteryTax);
            event TransactionStaking(uint256 stakingTax);
            event TransactionProject(uint256 projectTax);
        event TransactionEnd();

    // contract can be paid
    receive() external payable {}

    constructor(){
        // token creation
            _balances[address(this)] = _totalSupply;
            emit Transfer(address(0), address(this), _totalSupply);

        // except some accounts pFrom paying taxes
            _accountNoTaxes[address(this)] = true;
            _accountNoTaxes[ADDRESS_BURN] = true;

        // set token distribution
            TOKENS_FOR_STAKING = _totalSupply.mul(150).div(10**3); // 15% of all tokens go to staking rewards
            TOKENS_FOR_PROJECT = _totalSupply.mul(10).div(10**3); // 1% of all tokens go to the founding team
            TOKENS_FOR_LIQUIDITY = _totalSupply.sub(TOKENS_FOR_STAKING).sub(TOKENS_FOR_PROJECT); // rest goes to liquidity

        emit ContractCreation();
    }

    // getter

    // setter
    function init() public onlyOwner{
        if(_contractLiquidityActive && _contractLotteryActive){
            if(_contractStakingActive && _contractProjectActive){
                renounceOwnership(); // contract locked, bye!
                emit ContractLocked(_msgSender(), block.timestamp);
            }
        }
    }

    // proxy contracts
    
    event LiquiditySuccess();
    event LiquidityBalance(uint256 balance);
    event LiquidityFail();    
    function initLiquidity(address contractAddress) public onlyOwner{
        // set contract address
        ADDRESS_LIQUIDITY = contractAddress;

        // no taxes for contract
        _accountNoTaxes[ADDRESS_LIQUIDITY] = true;

        // check if liquidity contract has any native tokens, if not abort
        emit LiquidityBalance(ADDRESS_LIQUIDITY.balance);

        if(ADDRESS_LIQUIDITY.balance > 0){
            // send tokens
            _transactionTokens(address(this), ADDRESS_LIQUIDITY, TOKENS_FOR_LIQUIDITY);

            // init contract
            _liquidity = IXTKN031711Liquidity(ADDRESS_LIQUIDITY);
            _liquidity.init();
            ADDRESS_PAIR = _liquidity.getPair();

            // contract active
            _contractLiquidityActive = true;

            emit LiquiditySuccess();
        }else{
            emit LiquidityFail();
        }
    }

    event ProjectSuccess();
    event ProjectAddedTeamMemberWallet(address indexed wallet);
    function initProject(address contractAddress) public onlyOwner{
        // set contract address
        ADDRESS_PROJECT = contractAddress;

        // set proxy callback for special functions
        setProxyProject(ADDRESS_PROJECT);

        // no taxes for contract
        _accountNoTaxes[ADDRESS_PROJECT] = true;

        // transfer initial tokens
        _transactionTokens(address(this), ADDRESS_PROJECT, TOKENS_FOR_PROJECT);

        // init contract
        _project = IXTKN031711Project(ADDRESS_PROJECT);
        _project.init();
        _project.tax(TOKENS_FOR_PROJECT);

        emit ProjectSuccess();
    }


    // private methods
    function _transfer(address pFrom, address pTo, uint256 pAmount) private{
        emit TransactionStart(pFrom, pTo, pAmount);

        Tax memory Taxes;
        bool isBuy = false;
        bool isSell = false;

        // get trade direction
        if(pFrom == ADDRESS_PAIR){
            // buy from LP
            isBuy = true;
            Taxes.Lottery = TAX_BUY_LOTTERY;
            Taxes.Staking = TAX_BUY_STAKING;
            Taxes.Project = TAX_BUY_PROJECT;
            Taxes.Burn = TAX_BUY_BURN;
        }

        if(pTo == ADDRESS_PAIR){
            // sell pTo LP
            isSell = true;
            Taxes.Lottery = TAX_SELL_LOTTERY;
            Taxes.Staking = TAX_SELL_STAKING;
            Taxes.Project = TAX_SELL_PROJECT;
            Taxes.Burn = TAX_SELL_BURN;
        }

        if(!isBuy && !isSell){
            // transfer
            Taxes.Lottery = 0;
            Taxes.Staking = 0;
            Taxes.Project = 0;
            Taxes.Burn = 0;
        }

        if(_accountNoTaxes[pFrom] || _accountNoTaxes[pTo]){
            emit TransactionWithNoTaxes();  
            _transactionTokens(pFrom, pTo, pAmount);
        }else{
            Taxes.totalLottery = _tax(pAmount, Taxes.Lottery);
            Taxes.totalStaking = _tax(pAmount, Taxes.Staking);
            Taxes.totalProject = _tax(pAmount, Taxes.Project);
            Taxes.totalBurn = _tax(pAmount, Taxes.Burn);
            Taxes.total = Taxes.totalLottery.add(Taxes.totalStaking).add(Taxes.totalProject).add(Taxes.totalBurn);
            emit TransactionWithTaxes(Taxes.total);

            // taxation
            if(Taxes.totalBurn > 0){
                _transactionTokens(pFrom, ADDRESS_BURN, Taxes.totalBurn);
                emit TransactionBurn(Taxes.totalBurn, _balances[ADDRESS_BURN]);
            }
            if(Taxes.totalLottery > 0){
                _transactionTokens(pFrom, ADDRESS_LOTTERY, Taxes.totalLottery);
                emit TransactionLottery(Taxes.totalLottery);
            }
            if(Taxes.totalStaking > 0){
                _transactionTokens(pFrom, ADDRESS_STAKING, Taxes.totalStaking);
                emit TransactionStaking(Taxes.totalStaking);
            }
            if(Taxes.totalProject > 0){
                _transactionTokens(pFrom, ADDRESS_PROJECT, Taxes.totalProject);
                _project.tax(Taxes.totalProject);
                emit TransactionProject(Taxes.totalProject);
            }

            _transactionTokens(pFrom, pTo, pAmount.sub(Taxes.total));
        }

        emit TransactionEnd();
    }

    function _transactionTokens(address pFrom, address pTo, uint256 pAmount) private{
        _balances[pFrom] = _balances[pFrom].sub(pAmount);
        _balances[pTo] = _balances[pTo].add(pAmount);

        emit Transfer(pFrom, pTo, pAmount);
    }

    function _tax(uint256 pAmount, uint16 tax) private pure returns(uint256){
        return(pAmount.mul(tax).div(10**3));
    }


    // ERC20 methods
    
    function name() public view returns(string memory) {
        return(_name);
    }

    function symbol() public view returns(string memory) {
        return(_symbol);
    }

    function decimals() public view returns(uint8){
        return(_decimals);
    }

    function totalSupply() public view override returns(uint256){
        return(_totalSupply);
    }

    function balanceOf(address account) public view override returns(uint256){
        return(_balances[account]);
    }

    function allowance(address owner, address spender) public view override returns(uint256){
        return(_allowances[owner][spender]);
    }

    function approve(address spender, uint256 amount) public override returns(bool){
        _approve(_msgSender(), spender, amount);
        return(true);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "XTKN031711: approve from the zero address");
        require(spender != address(0), "XTKN031711: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns(bool){
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return(true);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool){
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "XTKN031711: decreased allowance below zero"));
        return(true);
    }

    function transfer(address recipient, uint256 amount) public override returns(bool){
        _transfer(_msgSender(), recipient, amount);
        return(true);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns(bool){
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "XTKN031711: transfer amount exceeds allowance"));
        return(true);
    }

}