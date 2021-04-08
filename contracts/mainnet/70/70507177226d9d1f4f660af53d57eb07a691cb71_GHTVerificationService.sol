/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

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
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
}

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal virtual {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Moderator is Ownable {
    mapping(address => bool) private _mod;

    event ModSet(address indexed newMod);
    event ModDeleted(address indexed oldMod);

    /**
     * @dev Initializes the contract setting the new Mod.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _mod[msgSender] = true;
        emit ModSet(msgSender);
    }

    /**
     * @dev Throws if called by any account other than the mod.
     */
    modifier onlyMod() {
        require(isMod(), "Moderator: caller is not the mod");
        _;
    }

    /**
     * @dev Returns true if the caller is the current mod.
     */
    function isMod() public view returns (bool) {
        address msgSender = _msgSender();
        return _mod[msgSender];
    }

    /**
     * @dev Set new moderator of the contract to a new account (`newMod`).
     * Can only be called by the current owner.
     */
    function setNewMod(address newMod) public virtual onlyOwner {
        _setNewMod(newMod);
    }
    
    /**
     * @dev Delete moderator of the contract (`oldMod`).
     * Can only be called by the current owner.
     */
    function deleteMod(address oldMod) public virtual onlyOwner {
        _deleteMod(oldMod);
    }

    /**
     * @dev Set new moderator of the contract to a new account (`newMod`).
     */
    function _setNewMod(address newMod) internal virtual {
        require(newMod != address(0), "Moderator: new mod is the zero address");
        emit ModSet(newMod);
        _mod[newMod] = true;
    }
    
    /**
     * @dev Delete moderator of the contract t (`oldMod`).
     */
    function _deleteMod(address oldMod) internal virtual {
        require(oldMod != address(0), "Moderator: old Mod is the zero address");
        emit ModDeleted(oldMod);
        _mod[oldMod] = false;
    }
}


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Moderator {
    bool private _paused;

    address private _pauser;
    
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    /**
     * @dev Emitted when the pauser is transferred by a owner.
     */
    event PauserTransferred(address indexed previousPauser, address indexed newPauser);

    /**
     * @dev Initializes the contract setting the deployer as the initial pauser.
     * 
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor (address pauser) internal {
        _pauser = pauser;
        _paused = false;
        emit PauserTransferred(address(0), pauser);
    }

    /**
     * @dev Returns the address of the current pauser.
     */
    function pauser() public view returns (address) {
        return _pauser;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyPauser() {
        require(isPauser(), "Pausable: caller is not the pauser");
        _;
    }

    /**
     * @dev Returns true if the caller is the current pauser.
     */
    function isPauser() public view returns (bool) {
        return _msgSender() == _pauser;
    }

    /**
     * @dev Transfers pauser of the contract to a new account (`newPauser`).
     * Can only be called by the current owner.
     */
    function setNewPauser(address newPauser) public virtual onlyOwner {
        _transferPauser(newPauser);
    }

    /**
     * @dev Transfers pauser of the contract to a new account (`newPauser`).
     */
    function _transferPauser(address newPauser) internal virtual {
        require(newPauser != address(0), "Pausable: new pauser is the zero address");
        emit PauserTransferred(_pauser, newPauser);
        _pauser = newPauser;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

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

contract GHTVerificationService is Pausable {
    using SafeMath for uint256;
    mapping (address => bool) private _whiteListAddress;
    mapping (address => uint256) private _GHTAmount;
    
    IERC20 GHT;
    /**
     * @dev Emitted when the user's address is locked or unlocked by a owner (`account`).
     */
    event SetWhiteListAddress(address indexed account, bool flag);
    event DepositGHT(address indexed account, uint256 amount);
    event GHTWithdrawalConfirmation(address indexed account, address indexed to, uint256 amount);
    event DecreaseGHTAmount(address indexed account, uint256 amount);
    
    constructor(address pauser, address _ght) public Pausable(pauser){
        address msgSender = _msgSender();
        setWhiteListAddress(msgSender,true);
        GHT = IERC20(_ght);
    }
    
     /**
     * @dev Returns GHT amount of `account` sent to contract.
     */
    function getGHTAmount(address account) public view returns (uint256) {
        return _GHTAmount[account];
    }
    
    /**
     * @dev User deposit to Wallet.
     */
    function depositGHT(uint256 amount, address user) public whenNotPaused {
        GHT.transferFrom(user,address(this),amount);
        _GHTAmount[user] = _GHTAmount[user].add(amount);
        
        emit DepositGHT(user, amount);
    }
    
    /**
     * @dev User withdraw GHT from Wallet.
     */
    function confirmedGHTWithdrawal(uint256 amount, address whitelistAddress, address to, uint256 update) public onlyMod whenNotPaused {
        //require(_whiteListAddress[user]);
        //require(_GHTAmount[whitelistAddress] >= amount);
        
        if(update!=0)
            _GHTAmount[whitelistAddress] = update;
        
        GHT.transfer(to,amount);
        _GHTAmount[whitelistAddress] = _GHTAmount[whitelistAddress].sub(amount);
        
        assert(_GHTAmount[whitelistAddress]>=0);
        
        emit GHTWithdrawalConfirmation(whitelistAddress, to, amount);
    }
    
    /**
     * @dev Decrease GHT in wallet cz used.
     */
    function decreaseGHTAmount(uint256 amount, address user) public onlyMod whenNotPaused {
        _GHTAmount[user] = _GHTAmount[user].sub(amount);
        assert(_GHTAmount[user]>=0);
        emit DecreaseGHTAmount(user, amount);
    }
    
    /**
     * @dev Set the user's address to lock or unlock.
     */
    function setWhiteListAddress(address account, bool flag) public onlyMod {
        _setWhiteListAddress(account, flag);
        emit SetWhiteListAddress(account, flag);
    }
    
    /**
     * @dev Returns the state `account`.
     */
    function getWhiteListAddress(address account) public view returns (bool) {
        return _whiteListAddress[account];
    }
    
    /**
     * @dev Set the user's address to lock or unlock.
     */
    function _setWhiteListAddress(address account, bool flag) internal {
        _whiteListAddress[account] = flag;
    }
    
    /**
     * @dev Pausese contract.
     *
     * See {Pausable-_pause}.
     */
    function pauseContract() public virtual onlyPauser {
        _pause();
    }
    
    /**
     * @dev Unpauses contract.
     *
     * See {Pausable-_unpause}.
     */
    function unpauseContract() public virtual onlyPauser {
        _unpause();
    }
}