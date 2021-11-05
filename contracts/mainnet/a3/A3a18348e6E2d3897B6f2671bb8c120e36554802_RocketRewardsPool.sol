// SPDX-License-Identifier: MIT

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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./ERC20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |    DECENTRALISED STAKING PROTOCOL FOR ETHEREUM    |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind Ethereum staking pool protocol, designed to
  *  be community-owned, decentralised, and trustless.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../interface/RocketStorageInterface.sol";

/// @title Base settings / modifiers for each contract in Rocket Pool
/// @author David Rugendyke

abstract contract RocketBase {

    // Calculate using this as the base
    uint256 constant calcBase = 1 ether;

    // Version of the contract
    uint8 public version;

    // The main storage contract where primary persistant storage is maintained
    RocketStorageInterface rocketStorage = RocketStorageInterface(0);


    /*** Modifiers **********************************************************/

    /**
    * @dev Throws if called by any sender that doesn't match a Rocket Pool network contract
    */
    modifier onlyLatestNetworkContract() {
        require(getBool(keccak256(abi.encodePacked("contract.exists", msg.sender))), "Invalid or outdated network contract");
        _;
    }

    /**
    * @dev Throws if called by any sender that doesn't match one of the supplied contract or is the latest version of that contract
    */
    modifier onlyLatestContract(string memory _contractName, address _contractAddress) {
        require(_contractAddress == getAddress(keccak256(abi.encodePacked("contract.address", _contractName))), "Invalid or outdated contract");
        _;
    }

    /**
    * @dev Throws if called by any sender that isn't a registered node
    */
    modifier onlyRegisteredNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("node.exists", _nodeAddress))), "Invalid node");
        _;
    }

    /**
    * @dev Throws if called by any sender that isn't a trusted node DAO member
    */
    modifier onlyTrustedNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("dao.trustednodes.", "member", _nodeAddress))), "Invalid trusted node");
        _;
    }

    /**
    * @dev Throws if called by any sender that isn't a registered minipool
    */
    modifier onlyRegisteredMinipool(address _minipoolAddress) {
        require(getBool(keccak256(abi.encodePacked("minipool.exists", _minipoolAddress))), "Invalid minipool");
        _;
    }
    

    /**
    * @dev Throws if called by any account other than a guardian account (temporary account allowed access to settings before DAO is fully enabled)
    */
    modifier onlyGuardian() {
        require(msg.sender == rocketStorage.getGuardian(), "Account is not a temporary guardian");
        _;
    }




    /*** Methods **********************************************************/

    /// @dev Set the main Rocket Storage address
    constructor(RocketStorageInterface _rocketStorageAddress) {
        // Update the contract address
        rocketStorage = RocketStorageInterface(_rocketStorageAddress);
    }


    /// @dev Get the address of a network contract by name
    function getContractAddress(string memory _contractName) internal view returns (address) {
        // Get the current contract address
        address contractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        // Check it
        require(contractAddress != address(0x0), "Contract not found");
        // Return
        return contractAddress;
    }


    /// @dev Get the address of a network contract by name (returns address(0x0) instead of reverting if contract does not exist)
    function getContractAddressUnsafe(string memory _contractName) internal view returns (address) {
        // Get the current contract address
        address contractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        // Return
        return contractAddress;
    }


    /// @dev Get the name of a network contract by address
    function getContractName(address _contractAddress) internal view returns (string memory) {
        // Get the contract name
        string memory contractName = getString(keccak256(abi.encodePacked("contract.name", _contractAddress)));
        // Check it
        require(bytes(contractName).length > 0, "Contract not found");
        // Return
        return contractName;
    }

    /// @dev Get revert error message from a .call method
    function getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }



    /*** Rocket Storage Methods ****************************************/

    // Note: Unused helpers have been removed to keep contract sizes down

    /// @dev Storage get methods
    function getAddress(bytes32 _key) internal view returns (address) { return rocketStorage.getAddress(_key); }
    function getUint(bytes32 _key) internal view returns (uint) { return rocketStorage.getUint(_key); }
    function getString(bytes32 _key) internal view returns (string memory) { return rocketStorage.getString(_key); }
    function getBytes(bytes32 _key) internal view returns (bytes memory) { return rocketStorage.getBytes(_key); }
    function getBool(bytes32 _key) internal view returns (bool) { return rocketStorage.getBool(_key); }
    function getInt(bytes32 _key) internal view returns (int) { return rocketStorage.getInt(_key); }
    function getBytes32(bytes32 _key) internal view returns (bytes32) { return rocketStorage.getBytes32(_key); }

    /// @dev Storage set methods
    function setAddress(bytes32 _key, address _value) internal { rocketStorage.setAddress(_key, _value); }
    function setUint(bytes32 _key, uint _value) internal { rocketStorage.setUint(_key, _value); }
    function setString(bytes32 _key, string memory _value) internal { rocketStorage.setString(_key, _value); }
    function setBytes(bytes32 _key, bytes memory _value) internal { rocketStorage.setBytes(_key, _value); }
    function setBool(bytes32 _key, bool _value) internal { rocketStorage.setBool(_key, _value); }
    function setInt(bytes32 _key, int _value) internal { rocketStorage.setInt(_key, _value); }
    function setBytes32(bytes32 _key, bytes32 _value) internal { rocketStorage.setBytes32(_key, _value); }

    /// @dev Storage delete methods
    function deleteAddress(bytes32 _key) internal { rocketStorage.deleteAddress(_key); }
    function deleteUint(bytes32 _key) internal { rocketStorage.deleteUint(_key); }
    function deleteString(bytes32 _key) internal { rocketStorage.deleteString(_key); }
    function deleteBytes(bytes32 _key) internal { rocketStorage.deleteBytes(_key); }
    function deleteBool(bytes32 _key) internal { rocketStorage.deleteBool(_key); }
    function deleteInt(bytes32 _key) internal { rocketStorage.deleteInt(_key); }
    function deleteBytes32(bytes32 _key) internal { rocketStorage.deleteBytes32(_key); }

    /// @dev Storage arithmetic methods
    function addUint(bytes32 _key, uint256 _amount) internal { rocketStorage.addUint(_key, _amount); }
    function subUint(bytes32 _key, uint256 _amount) internal { rocketStorage.subUint(_key, _amount); }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |    DECENTRALISED STAKING PROTOCOL FOR ETHEREUM    |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind Ethereum staking pool protocol, designed to
  *  be community-owned, decentralised, and trustless.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../RocketBase.sol";
import "../../interface/token/RocketTokenRPLInterface.sol";
import "../../interface/rewards/RocketRewardsPoolInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsRewardsInterface.sol";
import "../../interface/RocketVaultInterface.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";


// Holds RPL generated by the network for claiming from stakers (node operators etc)

contract RocketRewardsPool is RocketBase, RocketRewardsPoolInterface {

    // Libs
    using SafeMath for uint;


    // Events
    event RPLTokensClaimed(address indexed claimingContract, address indexed claimingAddress, uint256 amount, uint256 time);  
    
    // Modifiers

    /**
    * @dev Throws if called by any sender that doesn't match a Rocket Pool claim contract
    */
    modifier onlyClaimContract() {
        require(getClaimingContractExists(getContractName(msg.sender)), "Not a valid rewards claiming contact");
        _;
    }

    /**
    * @dev Throws if called by any sender that doesn't match an enabled Rocket Pool claim contract
    */
    modifier onlyEnabledClaimContract() {
        require(getClaimingContractEnabled(getContractName(msg.sender)), "Not a valid rewards claiming contact or it has been disabled");
        _;
    }


    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        // Version
        version = 1;
        // Set the claim interval start time as the current time
        setUint(keccak256("rewards.pool.claim.interval.time.start"), block.timestamp);
    }


    /**
    * Get how much RPL the Rewards Pool contract currently has assigned to it as a whole
    * @return uint256 Returns rpl balance of rocket rewards contract
    */
    function getRPLBalance() override external view returns(uint256) {
        // Get the vault contract instance
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));
        // Check per contract
        return rocketVault.balanceOfToken("rocketRewardsPool", IERC20(getContractAddress("rocketTokenRPL")));
    }


    /**
    * Get the last set interval start time
    * @return uint256 Last set start timestamp for a claim interval
    */
    function getClaimIntervalTimeStart() override public view returns(uint256) {
        return getUint(keccak256("rewards.pool.claim.interval.time.start"));
    }


    /**
    * Compute the current start time before a claim is made, takes into account intervals that may have passed
    * @return uint256 Computed starting timestamp for next possible claim
    */
    function getClaimIntervalTimeStartComputed() override public view returns(uint256) {
        // If intervals have passed, a new start timestamp will be used for the next claim, if it's the same interval then return that
        uint256 claimIntervalTimeStart = getClaimIntervalTimeStart();
        uint256 claimIntervalTime = getClaimIntervalTime();
        return _getClaimIntervalTimeStartComputed(claimIntervalTimeStart, claimIntervalTime);
    }

    function _getClaimIntervalTimeStartComputed(uint256 _claimIntervalTimeStart, uint256 _claimIntervalTime) private view returns (uint256) {
        uint256 claimIntervalsPassed = _getClaimIntervalsPassed(_claimIntervalTimeStart, _claimIntervalTime);
        return claimIntervalsPassed == 0 ? _claimIntervalTimeStart : _claimIntervalTimeStart.add(_claimIntervalTime.mul(claimIntervalsPassed));
    }


    /**
    * Compute intervals since last claim period
    * @return uint256 Time intervals since last update
    */
    function getClaimIntervalsPassed() override public view returns(uint256) {
        // Calculate now if inflation has begun
        return _getClaimIntervalsPassed(getClaimIntervalTimeStart(), getClaimIntervalTime());
    }

    function _getClaimIntervalsPassed(uint256 _claimIntervalTimeStart, uint256 _claimIntervalTime) private view returns (uint256) {
        return block.timestamp.sub(_claimIntervalTimeStart).div(_claimIntervalTime);
    }


    /**
    * Get how many seconds in a claim interval
    * @return uint256 Number of seconds in a claim interval
    */
    function getClaimIntervalTime() override public view returns(uint256) {
        // Get from the DAO settings
        RocketDAOProtocolSettingsRewardsInterface daoSettingsRewards = RocketDAOProtocolSettingsRewardsInterface(getContractAddress("rocketDAOProtocolSettingsRewards"));
        return daoSettingsRewards.getRewardsClaimIntervalTime();
    }


    /**
    * Get the last time a claim was made
    * @return uint256 Last time a claim was made
    */
    function getClaimTimeLastMade() override external view returns(uint256) {
        return getUint(keccak256("rewards.pool.claim.interval.time.last"));
    }


    // Check whether a claiming contract exists
    function getClaimingContractExists(string memory _contractName) override public view returns (bool) {
        RocketDAOProtocolSettingsRewardsInterface daoSettingsRewards = RocketDAOProtocolSettingsRewardsInterface(getContractAddress("rocketDAOProtocolSettingsRewards"));
        return (daoSettingsRewards.getRewardsClaimerPercTimeUpdated(_contractName) > 0);
    }


    // If the claiming contact has a % allocated to it higher than 0, it can claim
    function getClaimingContractEnabled(string memory _contractName) override public view returns (bool) {
        // Load contract
        RocketDAOProtocolSettingsRewardsInterface daoSettingsRewards = RocketDAOProtocolSettingsRewardsInterface(getContractAddress("rocketDAOProtocolSettingsRewards"));
        // Now verify this contract can claim by having a claim perc > 0 
        return daoSettingsRewards.getRewardsClaimerPerc(_contractName) > 0 ? true : false;
    }
    

    /**
    * The current claim amount total for this interval per claiming contract
    * @return uint256 The current claim amount for this interval for the claiming contract
    */
    function getClaimingContractTotalClaimed(string memory _claimingContract) override external view returns(uint256) {
        return _getClaimingContractTotalClaimed(_claimingContract, getClaimIntervalTimeStartComputed());
    }

    function _getClaimingContractTotalClaimed(string memory _claimingContract, uint256 _claimIntervalTimeStartComputed) private view returns(uint256) {
        return getUint(keccak256(abi.encodePacked("rewards.pool.claim.interval.contract.total", _claimIntervalTimeStartComputed, _claimingContract)));
    }

    
    /**
    * Have they claimed already during this interval? 
    * @return bool Returns true if they can claim during this interval
    */
    function getClaimingContractUserHasClaimed(uint256 _claimIntervalStartTime, string memory _claimingContract, address _claimerAddress) override public view returns(bool) {
        // Check per contract
        return getBool(keccak256(abi.encodePacked("rewards.pool.claim.interval.claimer.address", _claimIntervalStartTime, _claimingContract, _claimerAddress)));
    }


    /**
    * Get the time this account registered as a claimer at
    * @return uint256 Returns the time the account was registered at
    */
    function getClaimingContractUserRegisteredTime(string memory _claimingContract, address _claimerAddress) override public view returns(uint256) {
        return getUint(keccak256(abi.encodePacked("rewards.pool.claim.contract.registered.time", _claimingContract, _claimerAddress)));
    }

    
    /**
    * Get whether this address can currently make a claim
    * @return bool Returns true if the _claimerAddress can make a claim
    */
    function getClaimingContractUserCanClaim(string memory _claimingContract, address _claimerAddress) override public view returns(bool) {
        return _getClaimingContractUserCanClaim(_claimingContract, _claimerAddress, getClaimIntervalTime());
    }

    function _getClaimingContractUserCanClaim(string memory _claimingContract, address _claimerAddress, uint256 _claimIntervalTime) private view returns(bool) {
        // Get the time they registered at
        uint256 registeredTime = getClaimingContractUserRegisteredTime(_claimingContract, _claimerAddress);
        // If it's 0 or hasn't passed one interval yet, they can't claim
        return registeredTime > 0 && registeredTime.add(_claimIntervalTime) <= block.timestamp && getClaimingContractPerc(_claimingContract) > 0 ? true : false;
    }


    /**
    * Get the number of claimers for the current interval per claiming contract
    * @return uint256 Returns number of claimers for the current interval per claiming contract
    */
    function getClaimingContractUserTotalCurrent(string memory _claimingContract) override external view returns(uint256) {
        // Return the current interval amount if in that interval, if we are moving to the next one upon next claim, use that
        return getClaimIntervalsPassed() == 0 ? getUint(keccak256(abi.encodePacked("rewards.pool.claim.interval.claimers.total.current", _claimingContract))) : getClaimingContractUserTotalNext(_claimingContract);
    }


    /**
    * Get the number of claimers that will be added/removed on the next interval
    * @return uint256 Returns the number of claimers that will be added/removed on the next interval
    */
    function getClaimingContractUserTotalNext(string memory _claimingContract) override public view returns(uint256) {
        return getUint(keccak256(abi.encodePacked("rewards.pool.claim.interval.claimers.total.next", _claimingContract)));
    }


    /**
    * Get contract claiming percentage last recorded
    * @return uint256 Returns the contract claiming percentage last recorded
    */
    function getClaimingContractPercLast(string memory _claimingContract) override public view returns(uint256) {
        return getUint(keccak256(abi.encodePacked("rewards.pool.claim.interval.contract.perc.current", _claimingContract)));
    }

   
    /**
    * Get the approx amount of rewards available for this claim interval
    * @return uint256 Rewards amount for current claim interval
    */
    function getClaimIntervalRewardsTotal() override public view returns(uint256) {
        // Get the RPL contract instance
        RocketTokenRPLInterface rplContract = RocketTokenRPLInterface(getContractAddress("rocketTokenRPL"));
        // Get the vault contract instance
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));
        // Rewards amount
        uint256 rewardsTotal = 0;
        // Is this the first claim of this interval? If so, calculate expected inflation RPL + any RPL already in the pool
        if(getClaimIntervalsPassed() > 0) {
            // Get the balance of tokens that will be transferred to the vault for this contract when the first claim is made
            // Also account for any RPL tokens already in the vault for the rewards pool
            rewardsTotal = rplContract.inflationCalculate().add(rocketVault.balanceOfToken("rocketRewardsPool", IERC20(getContractAddress("rocketTokenRPL"))));
        }else{
            // Claims have already been made, lets retrieve rewards total stored on first claim of this interval
            rewardsTotal = getUint(keccak256("rewards.pool.claim.interval.total"));
        }
        // Done
        return rewardsTotal;
    }


    /**
    * Get the percentage this contract can claim in this interval
    * @return uint256 Rewards percentage this contract can claim in this interval
    */
    function getClaimingContractPerc(string memory _claimingContract) override public view returns(uint256) {
        // Load contract
        RocketDAOProtocolSettingsRewardsInterface daoSettingsRewards = RocketDAOProtocolSettingsRewardsInterface(getContractAddress("rocketDAOProtocolSettingsRewards"));
        // Get the % amount allocated to this claim contract
        uint256 claimContractPerc = daoSettingsRewards.getRewardsClaimerPerc(_claimingContract);
        // Get the time the % was changed at, it will only use this % on the next interval
        if(daoSettingsRewards.getRewardsClaimerPercTimeUpdated(_claimingContract) > getClaimIntervalTimeStartComputed()) {
            // Ok so this percentage was set during this interval, we must use the current % assigned to the last claim and the new one will kick in the next interval
            // If this is 0, the contract hasn't made a claim yet and can only do so on the next interval
            claimContractPerc = getClaimingContractPercLast(_claimingContract);
        }
        // Done
        return claimContractPerc;
    }


    /**
    * Get the approx amount of rewards available for this claim interval per claiming contract
    * @return uint256 Rewards amount for current claim interval per claiming contract
    */
    function getClaimingContractAllowance(string memory _claimingContract) override public view returns(uint256) {
        // Get the % amount this claim contract will get
        uint256 claimContractPerc = getClaimingContractPerc(_claimingContract);
        // How much rewards are available for this claim interval?
        uint256 claimIntervalRewardsTotal = getClaimIntervalRewardsTotal();
        // How much this claiming contract is entitled to in perc
        uint256 contractClaimTotal = 0;
        // Check now
        if(claimContractPerc > 0 && claimIntervalRewardsTotal > 0)  {
            // Calculate how much rewards this claimer will receive based on their claiming perc
            contractClaimTotal = claimContractPerc.mul(claimIntervalRewardsTotal).div(calcBase);
        }
        // Done
        return contractClaimTotal;
    }

    
    // How much this claimer is entitled to claim, checks parameters that claim() will check
    function getClaimAmount(string memory _claimingContract, address _claimerAddress, uint256 _claimerAmountPerc) override external view returns (uint256) {
        if (!getClaimingContractUserCanClaim(_claimingContract, _claimerAddress)) {
            return 0;
        }
        uint256 claimIntervalTimeStartComptued = getClaimIntervalTimeStartComputed();
        uint256 claimingContractTotalClaimed = _getClaimingContractTotalClaimed(_claimingContract, claimIntervalTimeStartComptued);
        return _getClaimAmount(_claimingContract, _claimerAddress, _claimerAmountPerc, claimIntervalTimeStartComptued, claimingContractTotalClaimed);
    }

    function _getClaimAmount(string memory _claimingContract, address _claimerAddress, uint256 _claimerAmountPerc, uint256 _claimIntervalTimeStartComputed, uint256 _claimingContractTotalClaimed) private view returns (uint256) {
        // Get the total rewards available for this claiming contract
        uint256 contractClaimTotal = getClaimingContractAllowance(_claimingContract);
        // How much of the above that this claimer will receive
        uint256 claimerTotal = 0;
        // Are we good to proceed?
        if( contractClaimTotal > 0 &&
            _claimerAmountPerc > 0 &&
            _claimerAmountPerc <= 1 ether &&
            _claimerAddress != address(0x0) &&
            getClaimingContractEnabled(_claimingContract) &&
            !getClaimingContractUserHasClaimed(_claimIntervalTimeStartComputed, _claimingContract, _claimerAddress)) {

            // Now calculate how much this claimer would receive
            claimerTotal = _claimerAmountPerc.mul(contractClaimTotal).div(calcBase);
            // Is it more than currently available + the amount claimed already for this claim interval?
            claimerTotal = claimerTotal.add(_claimingContractTotalClaimed) <= contractClaimTotal ? claimerTotal : 0;
        }
        // Done
        return claimerTotal;
    }


    // An account must be registered to claim from the rewards pool. They must wait one claim interval before they can collect.
    // Also keeps track of total 
    function registerClaimer(address _claimerAddress, bool _enabled) override external onlyClaimContract { 
        // The name of the claiming contract
        string memory contractName = getContractName(msg.sender);
        // Record the time they are registering at
        uint256 registeredTime = 0;
        // How many users are to be included in next interval
        uint256 claimersIntervalTotalUpdate = getClaimingContractUserTotalNext(contractName);
        // Ok register
        if(_enabled) { 
            // Make sure they are not already registered
            require(getClaimingContractUserRegisteredTime(contractName, _claimerAddress) == 0, "Claimer is already registered");
            // Update time
            registeredTime = block.timestamp;
            // Update the total registered claimers for next interval
            setUint(keccak256(abi.encodePacked("rewards.pool.claim.interval.claimers.total.next", contractName)), claimersIntervalTotalUpdate.add(1));
        }else{
            // Make sure they are already registered
            require(getClaimingContractUserRegisteredTime(contractName, _claimerAddress) != 0, "Claimer is not registered");
            // Update the total registered claimers for next interval
            setUint(keccak256(abi.encodePacked("rewards.pool.claim.interval.claimers.total.next", contractName)), claimersIntervalTotalUpdate.sub(1));
        }
        // Save the registered time
        setUint(keccak256(abi.encodePacked("rewards.pool.claim.contract.registered.time", contractName, _claimerAddress)), registeredTime);
    }


    // A claiming contract claiming for a user and the percentage of the rewards they are allowed to receive
    function claim(address _claimerAddress, address _toAddress, uint256 _claimerAmountPerc) override external onlyEnabledClaimContract {
        // The name of the claiming contract
        string memory contractName = getContractName(msg.sender);
        // Check to see if this registered claimer has waited one interval before collecting
        uint256 claimIntervalTime = getClaimIntervalTime();
        require(_getClaimingContractUserCanClaim(contractName, _claimerAddress, claimIntervalTime), "Registered claimer is not registered to claim or has not waited one claim interval");
        // RPL contract address
        address rplContractAddress = getContractAddress("rocketTokenRPL");
        // RPL contract instance
        RocketTokenRPLInterface rplContract = RocketTokenRPLInterface(rplContractAddress);
        // Get the vault contract instance
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));
        // Get the start of the last claim interval as this may have just changed for a new interval beginning
        uint256 claimIntervalTimeStart = getClaimIntervalTimeStart();
        uint256 claimIntervalTimeStartComputed = _getClaimIntervalTimeStartComputed(claimIntervalTimeStart, claimIntervalTime);
        uint256 claimIntervalsPassed = _getClaimIntervalsPassed(claimIntervalTimeStart, claimIntervalTime);
        // Is this the first claim of this interval? If so, set the rewards total for this interval
        if (claimIntervalsPassed > 0) {
            // Mint any new tokens from the RPL inflation
            rplContract.inflationMintTokens();
            // Get how many tokens are in the reward pool to be available for this claim period
            setUint(keccak256("rewards.pool.claim.interval.total"), rocketVault.balanceOfToken("rocketRewardsPool", rplContract));
            // Set this as the start of the new claim interval
            setUint(keccak256("rewards.pool.claim.interval.time.start"), claimIntervalTimeStartComputed);
            // Soon as we mint new tokens, send the DAO's share to it's claiming contract, then attempt to transfer them to the dao if possible
            uint256 daoClaimContractAllowance = getClaimingContractAllowance("rocketClaimDAO");
            // Are we sending any?
            if (daoClaimContractAllowance > 0) {
                // Get the DAO claim contract address
                address daoClaimContractAddress = getContractAddress("rocketClaimDAO");
                // Transfers the DAO's tokens to it's claiming contract from the rewards pool
                rocketVault.transferToken("rocketClaimDAO", rplContract, daoClaimContractAllowance);
                // Set the current claim percentage this contract is entitled to for this interval
                setUint(keccak256(abi.encodePacked("rewards.pool.claim.interval.contract.perc.current", "rocketClaimDAO")), getClaimingContractPerc("rocketClaimDAO"));
                // Store the total RPL rewards claim for this claiming contract in this interval
                setUint(keccak256(abi.encodePacked("rewards.pool.claim.interval.contract.total", claimIntervalTimeStartComputed, "rocketClaimDAO")), _getClaimingContractTotalClaimed("rocketClaimDAO", claimIntervalTimeStartComputed).add(daoClaimContractAllowance));
                // Log it
                emit RPLTokensClaimed(daoClaimContractAddress, daoClaimContractAddress, daoClaimContractAllowance, block.timestamp);
            }
        }
        // Has anyone claimed from this contract so far in this interval? If not then set the interval settings for the contract
        if (_getClaimingContractTotalClaimed(contractName, claimIntervalTimeStartComputed) == 0) {
            // Get the amount allocated to this claim contract
            uint256 claimContractAllowance = getClaimingContractAllowance(contractName);
            // Make sure this is ok
            require(claimContractAllowance > 0, "Claiming contract must have an allowance of more than 0");
            // Set the current claim percentage this contract is entitled too for this interval
            setUint(keccak256(abi.encodePacked("rewards.pool.claim.interval.contract.perc.current", contractName)), getClaimingContractPerc(contractName));
            // Set the current claim allowance amount for this contract for this claim interval (if the claim amount is changed, it will kick in on the next interval)
            setUint(keccak256(abi.encodePacked("rewards.pool.claim.interval.contract.allowance", contractName)), claimContractAllowance);
            // Set the current amount of claimers for this interval
            setUint(keccak256(abi.encodePacked("rewards.pool.claim.interval.claimers.total.current", contractName)), getClaimingContractUserTotalNext(contractName));
        }
        // Check if they have a valid claim amount
        uint256 claimingContractTotalClaimed = _getClaimingContractTotalClaimed(contractName, claimIntervalTimeStartComputed);
        uint256 claimAmount = _getClaimAmount(contractName, _claimerAddress, _claimerAmountPerc, claimIntervalTimeStartComputed, claimingContractTotalClaimed);
        // First initial checks
        require(claimAmount > 0, "Claimer is not entitled to tokens, they have already claimed in this interval or they are claiming more rewards than available to this claiming contract.");
        // Send tokens now
        rocketVault.withdrawToken(_toAddress, rplContract, claimAmount);
        // Store the claiming record for this interval and claiming contract
        setBool(keccak256(abi.encodePacked("rewards.pool.claim.interval.claimer.address", claimIntervalTimeStartComputed, contractName, _claimerAddress)), true);
        // Store the total RPL rewards claim for this claiming contract in this interval
        setUint(keccak256(abi.encodePacked("rewards.pool.claim.interval.contract.total", claimIntervalTimeStartComputed, contractName)), claimingContractTotalClaimed.add(claimAmount));
        // Store the last time a claim was made
        setUint(keccak256("rewards.pool.claim.interval.time.last"), block.timestamp);
        // Log it
        emit RPLTokensClaimed(getContractAddress(contractName), _claimerAddress, claimAmount, block.timestamp);
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |    DECENTRALISED STAKING PROTOCOL FOR ETHEREUM    |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind Ethereum staking pool protocol, designed to
  *  be community-owned, decentralised, and trustless.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketStorageInterface {

    // Deploy status
    function getDeployedStatus() external view returns (bool);

    // Guardian
    function getGuardian() external view returns(address);
    function setGuardian(address _newAddress) external;
    function confirmGuardian() external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string memory);
    function getBytes(bytes32 _key) external view returns (bytes memory);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
    function getBytes32(bytes32 _key) external view returns (bytes32);

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string calldata _value) external;
    function setBytes(bytes32 _key, bytes calldata _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;

    // Arithmetic
    function addUint(bytes32 _key, uint256 _amount) external;
    function subUint(bytes32 _key, uint256 _amount) external;

    // Protected storage
    function getNodeWithdrawalAddress(address _nodeAddress) external view returns (address);
    function getNodePendingWithdrawalAddress(address _nodeAddress) external view returns (address);
    function setWithdrawalAddress(address _nodeAddress, address _newWithdrawalAddress, bool _confirm) external;
    function confirmWithdrawalAddress(address _nodeAddress) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |    DECENTRALISED STAKING PROTOCOL FOR ETHEREUM    |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind Ethereum staking pool protocol, designed to
  *  be community-owned, decentralised, and trustless.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

interface RocketVaultInterface {
    function balanceOf(string memory _networkContractName) external view returns (uint256);
    function depositEther() external payable;
    function withdrawEther(uint256 _amount) external;
    function depositToken(string memory _networkContractName, IERC20 _tokenAddress, uint256 _amount) external;
    function withdrawToken(address _withdrawalAddress, IERC20 _tokenAddress, uint256 _amount) external;
    function balanceOfToken(string memory _networkContractName, IERC20 _tokenAddress) external view returns (uint256);
    function transferToken(string memory _networkContractName, IERC20 _tokenAddress, uint256 _amount) external;
    function burnToken(ERC20Burnable _tokenAddress, uint256 _amount) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |    DECENTRALISED STAKING PROTOCOL FOR ETHEREUM    |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind Ethereum staking pool protocol, designed to
  *  be community-owned, decentralised, and trustless.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAOProtocolSettingsRewardsInterface {
    function setSettingRewardsClaimer(string memory _contractName, uint256 _perc) external;
    function getRewardsClaimerPerc(string memory _contractName) external view returns (uint256);
    function getRewardsClaimerPercTimeUpdated(string memory _contractName) external view returns (uint256);
    function getRewardsClaimersPercTotal() external view returns (uint256);
    function getRewardsClaimIntervalTime() external view returns (uint256);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |    DECENTRALISED STAKING PROTOCOL FOR ETHEREUM    |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind Ethereum staking pool protocol, designed to
  *  be community-owned, decentralised, and trustless.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketRewardsPoolInterface {
    function getRPLBalance() external view returns(uint256);
    function getClaimIntervalTimeStart() external view returns(uint256);
    function getClaimIntervalTimeStartComputed() external view returns(uint256);
    function getClaimIntervalsPassed() external view returns(uint256);
    function getClaimIntervalTime() external view returns(uint256);
    function getClaimTimeLastMade() external view returns(uint256);
    function getClaimIntervalRewardsTotal() external view returns(uint256);
    function getClaimingContractTotalClaimed(string memory _claimingContract) external view returns(uint256);
    function getClaimingContractUserTotalNext(string memory _claimingContract) external view returns(uint256);
    function getClaimingContractUserTotalCurrent(string memory _claimingContract) external view returns(uint256);  
    function getClaimingContractUserHasClaimed(uint256 _claimIntervalStartTime, string memory _claimingContract, address _claimerAddress) external view returns(bool);
    function getClaimingContractUserCanClaim(string memory _claimingContract, address _claimerAddress) external view returns(bool);
    function getClaimingContractUserRegisteredTime(string memory _claimingContract, address _claimerAddress) external view returns(uint256);
    function getClaimingContractAllowance(string memory _claimingContract) external view returns(uint256);
    function getClaimingContractPerc(string memory _claimingContract) external view returns(uint256);
    function getClaimingContractPercLast(string memory _claimingContract) external view returns(uint256);
    function getClaimingContractExists(string memory _contractName) external view returns (bool);
    function getClaimingContractEnabled(string memory _contractName) external view returns (bool);
    function getClaimAmount(string memory _claimingContract, address _claimerAddress, uint256 _claimerAmountPerc) external view returns (uint256);
    function registerClaimer(address _claimerAddress, bool _enabled) external;
    function claim(address _claimerAddress, address _toAddress, uint256 _claimerAmount) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |    DECENTRALISED STAKING PROTOCOL FOR ETHEREUM    |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind Ethereum staking pool protocol, designed to
  *  be community-owned, decentralised, and trustless.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface RocketTokenRPLInterface is IERC20 {
    function getInflationCalcTime() external view returns(uint256);
    function getInflationIntervalTime() external view returns(uint256);
    function getInflationIntervalRate() external view returns(uint256);
    function getInflationIntervalsPassed() external view returns(uint256);
    function getInflationIntervalStartTime() external view returns(uint256);
    function getInflationRewardsContractAddress() external view returns(address);
    function inflationCalculate() external view returns (uint256);
    function inflationMintTokens() external returns (uint256);
    function swapTokens(uint256 _amount) external;
}