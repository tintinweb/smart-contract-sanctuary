/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

/**
 * @dev Implementation of the Owned Contract.
 *
 */
contract Owned is Context {

    address public _owner;
    address public _newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(_msgSender() == _owner, "AdaMarkets: Only Owner can perform this task");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _newOwner = newOwner;
    }

    function acceptOwnership() public {
        require(_msgSender() == _newOwner, "AdaMarkets: Token Contract Ownership has not been set for the address");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
        _newOwner = address(0);
    }
}

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

/**
 * @dev Implementation of the {IERC20} interface.
 *
 */
contract AdaMarkets is IERC20, Owned {

    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances; // Total balance per address (locked + unlocked)

    mapping (address => uint256) private _unlockedTokens; // Unlocked Tokens, available for transfer

    mapping (address => mapping (address => uint256)) private _allowances;

    struct LockRecord {
        uint256 lockingPeriod;
        uint256 tokens;
        bool isUnlocked;
    }

    mapping(address => LockRecord[]) private records; // Record of Locking periods and tokens per address

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor( address owner )  {
        _name = "AdaMarkets";
        _symbol = "ADAM";
        _decimals = 18;
        _totalSupply = 1000000 * (10 ** 18);
        _owner = owner;
        _balances[_owner] = _totalSupply;
        _unlockedTokens[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply );
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
     * @dev See {IERC20-balanceOf}.
     */
    function unLockedBalanceOf(address account) public view returns (uint256) {
        return _unlockedTokens[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {

        _transfer(_msgSender(),recipient,amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        
        require(spender != address(0), "AdaMarkets: approve to the zero address");

        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);

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
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {

        _transfer(sender,recipient,amount);

        require(amount <= _allowances[sender][_msgSender()],"AdaMarkets: Check for approved token count failed");
        
        _allowances[sender][_msgSender()] = _allowances[sender][_msgSender()].sub(amount);

        emit Approval(sender, _msgSender(), _allowances[sender][_msgSender()]);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        
        require(recipient != address(0),"AdaMarkets: Cannot have recipient as zero address");
        require(sender != address(0),"AdaMarkets: Cannot have sender as zero address");
        require(_balances[sender] >= amount,"AdaMarkets: Insufficient Balance" );
        require(_balances[recipient] + amount >= _balances[recipient],"AdaMarkets: Balance check failed");
        
        // update the unlocked tokens based on time if required
        _updateUnLockedTokens(sender, amount);
        _unlockedTokens[sender] = _unlockedTokens[sender].sub(amount);
        _unlockedTokens[recipient] = _unlockedTokens[recipient].add(amount);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        
        emit Transfer(sender,recipient,amount);
    }

    function _transferLock(address sender, address recipient, uint256 amount) private {
        
        require(recipient != address(0),"AdaMarkets: Cannot have recipient as zero address");
        require(sender != address(0),"AdaMarkets: Cannot have sender as zero address");
        require(_balances[sender] >= amount,"AdaMarkets: Insufficient Balance" );
        require(_balances[recipient] + amount >= _balances[recipient],"AdaMarkets: Balance check failed");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        _unlockedTokens[sender] = _unlockedTokens[sender].sub(amount);

        emit Transfer(sender,recipient,amount);
    }
    
     /**
     * @dev Destroys `amount` tokens from the `account`.
     *
     * See {ERC20-_burn}.
     */
     
    function burn(address account, uint256 amount) public onlyOwner {

        require(account != address(0), "AdaMarkets: burn from the zero address");

        if( _balances[account] == _unlockedTokens[account]){
            _unlockedTokens[account] = _unlockedTokens[account].sub(amount, "AdaMarkets: burn amount exceeds balance");
        }

        _balances[account] = _balances[account].sub(amount, "AdaMarkets: burn amount exceeds balance");

        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);

        if(account != _msgSender()){
            
            require(amount <= _allowances[account][_msgSender()],"AdaMarkets: Check for approved token count failed");

            _allowances[account][_msgSender()] = _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance");
            emit Approval(account, _msgSender(), _allowances[account][_msgSender()]);
        }
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's _msgSender() to `to` _msgSender()
    // - Owner's _msgSender() must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // - takes in locking Period to lock the tokens to be used
    // - if want to transfer without locking enter 0 in lockingPeriod argument 
    // ------------------------------------------------------------------------
    function distributeTokens(address to, uint tokens, uint256 lockingPeriod) onlyOwner public returns (bool success) {
        // if there is no lockingPeriod, add tokens to _unlockedTokens per address
        if(lockingPeriod == 0)
            _transfer(_msgSender(),to, tokens);
        // if there is a lockingPeriod, add tokens to record mapping
        else
            _transferLock(_msgSender(),to, tokens);
            _addRecord(to, tokens, lockingPeriod);
        return true;
    }
        
    // ------------------------------------------------------------------------
    // Adds record of addresses with locking period and tokens to lock
    // ------------------------------------------------------------------------
    function _addRecord(address to, uint tokens, uint256 lockingPeriod) private {
        records[to].push(LockRecord(lockingPeriod,tokens, false));
    }
        
    // ------------------------------------------------------------------------
    // Checks if there is required amount of unLockedTokens available
    // ------------------------------------------------------------------------
    function _updateUnLockedTokens(address _from, uint tokens) private returns (bool success) {
        // if _unlockedTokens are greater than "tokens" of "to", initiate transfer
        if(_unlockedTokens[_from] >= tokens){
            return true;
        }
        // if _unlockedTokens are less than "tokens" of "to", update _unlockedTokens by checking record with "now" time
        else{
            _updateRecord(_from);
            // check if _unlockedTokens are greater than "token" of "to", initiate transfer
            if(_unlockedTokens[_from] >= tokens){
                return true;
            }
            // otherwise revert
            else{
                revert("AdaMarkets: Insufficient unlocked tokens");
            }
        }
    }
        
    // ------------------------------------------------------------------------
    // Unlocks the coins if lockingPeriod is expired
    // ------------------------------------------------------------------------
     function _updateRecord(address account) private returns (bool success){
        LockRecord[] memory tempRecords = records[account];
        uint256 unlockedTokenCount = 0;
        for(uint256 i=0; i < tempRecords.length; i++){
            if(tempRecords[i].lockingPeriod < block.timestamp && tempRecords[i].isUnlocked == false){
                unlockedTokenCount = unlockedTokenCount.add(tempRecords[i].tokens);
                tempRecords[i].isUnlocked = true;
                records[account][i] = LockRecord(tempRecords[i].lockingPeriod, tempRecords[i].tokens, tempRecords[i].isUnlocked);
            }
        }
        _unlockedTokens[account] = _unlockedTokens[account].add(unlockedTokenCount);
        return true;
    }        
}