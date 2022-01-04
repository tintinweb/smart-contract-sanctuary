/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//............................................................................................
//.BBBBBBBBBB..BIIII....GGGGGGG......... BBBBBBBBB......AAAAA.....NNNN...NNNN.....GGGGGGG.....
//.BBBBBBBBBBB.BIIII..GGGGGGGGGG........ BBBBBBBBBB.....AAAAA.....NNNNN..NNNN...GGGGGGGGGG....
//.BBBBBBBBBBB.BIIII.GGGGGGGGGGGG....... BBBBBBBBBB....AAAAAA.....NNNNN..NNNN..GGGGGGGGGGGG...
//.BBBB...BBBB.BIIII.GGGGG..GGGGG....... BBB...BBBB....AAAAAAA....NNNNNN.NNNN..GGGGG..GGGGG...
//.BBBB...BBBB.BIIIIIGGGG....GGG........ BBB...BBBB...AAAAAAAA....NNNNNN.NNNN.NGGGG....GGG....
//.BBBBBBBBBBB.BIIIIIGGG................ BBBBBBBBBB...AAAAAAAA....NNNNNNNNNNN.NGGG............
//.BBBBBBBBBB..BIIIIIGGG..GGGGGGGG...... BBBBBBBBB....AAAA.AAAA...NNNNNNNNNNN.NGGG..GGGGGGGG..
//.BBBBBBBBBBB.BIIIIIGGG..GGGGGGGG...... BBBBBBBBBB..BAAAAAAAAA...NNNNNNNNNNN.NGGG..GGGGGGGG..
//.BBBB....BBBBBIIIIIGGGG.GGGGGGGG...... BBB....BBBB.BAAAAAAAAAA..NNNNNNNNNNN.NGGGG.GGGGGGGG..
//.BBBB....BBBBBIIII.GGGGG....GGGG...... BBB....BBBB.BAAAAAAAAAA..NNNN.NNNNNN..GGGGG....GGGG..
//.BBBBBBBBBBBBBIIII.GGGGGGGGGGGG....... BBBBBBBBBBBBBAA....AAAA..NNNN..NNNNN..GGGGGGGGGGGG...
//.BBBBBBBBBBB.BIIII..GGGGGGGGGG........ BBBBBBBBBB.BBAA.....AAAA.NNNN..NNNNN...GGGGGGGGGG....
//.BBBBBBBBBB..BIIII....GGGGGGG......... BBBBBBBBB.BBBAA.....AAAA.NNNN...NNNN.....GGGGGGG.....
//............................................................................................

/*
* MARSX Token - www.marsxtoken.com - First Multiplanetary Crypto
* Main Staking Contract Of KOSMOS
* www.kosmos.marsxtoken.com
* Developed with love by MarXians
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



pragma solidity ^0.8.0;


interface IBigBang{
    
      /** @dev adding a new stiaking pool
     * @param _stakingToken: token to be used for staking
     * @param _rewardsToken token to be used for rewards
     * @param _tier1Fee Fee tier 1
     * @param _tier2Fee Fee tier 2
     * @param _tier3Fee Fee tier 3
     * @param _tier4Fee Fee tier 4
     * @param _tier5Fee Fee tier 5
     * @param _uom: 
         // 0: month
         // 1: week
         // 2: day
         // 3: hour
         // 4: minute
     * @param _multiplier: multiplier
     */
    
    function addPool  (
        address _stakingToken,
        address _rewardsToken,
        uint256 _tier1Fee,
        uint256 _tier2Fee,
        uint256 _tier3Fee,
        uint256 _tier4Fee,
        uint256 _tier5Fee,
        uint256 _uom,
        uint256 _multiplier
        ) external;
        
     /**
     * @dev check how many pools have been created.
     * Can only be called by the current owner.
     */
     function poolLength() external view returns (uint256);
    
    /* @dev check total rewards in the pool
     * @param _pid of the pool
     */

    function totalRewardsInThePool(uint256 _pid, address _poolAddress) external view returns (uint256);

    
    /* @dev add rewards to the pool
     * @param _pid of the pool
     */
    function addRewardsToThePool(uint256 _pid, address _poolAddress, uint256 _amount) external;

    /** @dev stake funds into the contract
     *@param _pid id of the pool
     *@param _address address of the user
     *@param _dValue value of tokens that the msg.sender wants to deposit
     *@param _tier days msg.sender wants to deposit the token for
     
     */
    function stake(uint256 _pid, address _address, address _poolAddress, uint256 _dValue, uint256 _tier) external;
    
    /** @dev withdrawal funds out of pool
     * @param _pid id of the pool
     * @param _address address of the user
     * @param wdValue amount to withdraw
     */
    function unstake(uint256 _pid, address _address, uint256 wdValue) external;
    
     /** @dev claim rewards out of pool
     * @param _address of the user
     * @param _pid of the pool
     */
    
    function claimRewards(uint256 _pid, address _address) external;
    
    /** @dev retreive current state of users funds
     * @param _address of the user
     * @param _pid of the pool
     * @return array of values describing the current state of user
     * index 0: total staked amount 
     * index 1: remaining days for getting rewards
     * index 2: pending Rewards
     * index 3: tierFee (apy)
     */
   function getState(uint256 _pid, address _address) external view returns (uint256[] memory);
    
}





pragma solidity ^0.8.0;

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




pragma solidity ^0.8.0;


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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}






pragma solidity ^0.8.0;


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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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




pragma solidity ^0.8.0;

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



pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


pragma solidity ^0.8.0;

/* @title Big Bang Contract
 * Open Zeppelin Pausable is Ownable.  contains address owner */
contract BigBang is Pausable, Ownable {
    using SafeMath for uint256;
  
    // Info of each pool.
    struct PoolInfo {
        address stakingToken;                   // Address of staking token contract.
        address rewardsToken;                   // Address of rewards token contract.
        uint256 tier1Fee;                       // TIER1Fee: uint representing the rewards rate (e.g. 5 stands for 0.005 -> 0.5%)
        uint256 tier2Fee;                       // TIER2Fee: uint representing the rewards rate (e.g. 5  stands for 0.005 -> 0.5%)
        uint256 tier3Fee;                       // TIER3Fee: uint representing the rewards rate (e.g. 5  stands for 0.005 -> 0.5%)
        uint256 tier4Fee;                       // TIER4Fee: uint representing the rewards rate (e.g. 5  stands for 0.005 -> 0.5%)
        uint256 tier5Fee;                       // TIER5Fee: uint representing the rewards rate (e.g. 5  stands for 0.005 -> 0.5%)
        uint256 multiplier;                     // 1 or 10 (1 month)
        uint256  uom;                           // unit of measure: 
                                                   // 0: month
                                                   // 1: week
                                                   // 2: day
                                                   // 3: hour
                                                   // 4: minute
        uint256 totalDeposited;                 // Total deposits of the stake contract
        uint256 totalRewards;                   // Total deposits of the rewards contract
        uint256 totalRewardsDebt;               // Total debt towards the stakers
    }
    
  

   /** @dev Info of each user. */
    struct UserInfo {
        uint256 amount;     // How many Staking tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 endOfStake; // Date when the rewards can be claimed
        uint256 apy;        // APY
        /*
        We do some fancy math here. Basically, any point in time, the amount of rewards
        entitled to a user but is pending to be distributed is:
        
        user.rewardDebt = (user.amount * pool.accCakePerShare)  
        
        */
    }


    /** @dev Info of each user that stakes LP tokens.*/
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    /** @dev Info of each pool. */
    PoolInfo[] public poolInfo;


    /** @dev notify that StakeContract address has been changed
     * @param oldSC old address of the staking contract
     * @param newSC new address of the staking contract
     */
    event NotifyNewStakingContract(address oldSC, address newSC);

      /** @dev notify that StakeContract address has been changed
     * @param oldRC old address of the rewards contract
     * @param newRC new address of the rewards contract
     */
    event NotifyNewRewardsContract(address oldRC, address newRC);

    /** @dev trigger notification of deposits
     * @param pid           pid of the pool
     * @param sender        sender of transaction
     * @param amount        amount of staked tokens
     */
    event NotifyStake(uint256 pid, address sender, uint256 amount);

    /** @dev trigger notification of staked amount
     * @param pid           pid of the pool
     * @param sender        sender of transaction
     * @param amount        amount of withdrawal tokens
     */
    
    event NotifyUnstake(
        uint256 pid,
        address sender,
        uint256 amount
    );

    /** @dev trigger notification of withdrawal
     * @param pid               pid of the pool
     * @param sender            address of msg.sender
     * @param rewardAmount      users final rewards withdrawn
     */
    event NotifyRewardClaimed(
        uint256 pid, 
        address sender, 
        uint256 rewardAmount);

    /** @dev trigger notification of withdrawal
     * @param pid               pid of the pool
     * @param rewardAmount      users final rewards withdrawn
     */
    event NotifyRewardAdded(
        uint256 pid, 
        uint256 rewardAmount);


    /** @dev contract constructor
     */
    constructor () {}
        
    /************************ PUBLIC Queries **********************************/
    
    /** @dev check total rewards in the pool
     * @param _pid of the pool
     * @param _poolAddress address of the pool
     */

    function totalRewardsInThePool(uint256 _pid, address _poolAddress) public view returns (uint256){
        // Retrieve Pool information
        PoolInfo storage pool = poolInfo[_pid];
        return ERC20(pool.rewardsToken).balanceOf(_poolAddress);
        }

    /** @dev check if user has already staked something
     * @param _pid of the pool
     * @param _address of the user
     */
    function isAlreadyUser(uint256 _pid, address _address ) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_address];
        uint256 isUser = 0;
        if (user.amount > 0)
        {
            isUser = 1;
        }
        return isUser;
        
    }

    /** @dev check if the pool is open for staking: the total rewardsDebt of the users does not exceed the total rewards of the pool.
     * @param _pid of the pool
     */
    function isPoolOpen(uint256 _pid) public view returns (bool) {
        // Retrieve Pool information
        PoolInfo storage pool = poolInfo[_pid];
        // Check if the total rewards in the pool are minor than the debt that the pool has towards the stakers
        if (pool.totalRewards < pool.totalRewardsDebt)
        {
            // The pool is closed for staking
            return false;
        }
        // The pool is open for staking
        return true;
    }
    
    /**
     * @dev check how many pools have been created.
     */
     function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    
    /**@dev retrieve amount deposited by the msg.sender
     * @param _address of the user
     * @param _pid of the pool
     * @return uint
     */
    function getBalanceOfDeposit(uint256 _pid, address _address)
        external
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_pid][_address];
        return user.amount;
    }
    

    /** @dev retreive current state of users funds
     * @param _address of the user
     * @param _pid of the pool
     * @return array of values describing the current state of user
     */
    function getState(uint256 _pid,  address _address) external view returns (uint256[] memory) {
        UserInfo storage user = userInfo[_pid][_address];
        uint256[] memory state = new uint256[](5);
        state[0] = user.amount;                                     // total staked amount for getting rewards
        state[1] = user.endOfStake;                                 // remaining days for getting rewards
        state[2] = claimableRewards(_pid, _address);                // claimable Rewards
        state[3] = user.apy;                                        // apy
        state[4] = user.rewardDebt;                                 // total reward debt

        return state;
    }


    /************************ USER MANAGEMENT **********************************/

    /************************ POOL MANAGEMENT **********************************/
    
     /** @dev adding a new stiaking pool
     * @param _stakingToken: token to be used for staking
     * @param _rewardsToken token to be used for rewards
     * @param _tier1Fee Fee tier 1
     * @param _tier2Fee Fee tier 2
     * @param _tier3Fee Fee tier 3
     * @param _tier4Fee Fee tier 4
     * @param _tier5Fee Fee tier 5
     */
    
    
    function addPool  (
        address _stakingToken,
        address _rewardsToken,
        uint256 _tier1Fee,
        uint256 _tier2Fee,
        uint256 _tier3Fee,
        uint256 _tier4Fee,
        uint256 _tier5Fee, 
        uint256 _uom,
        uint256 _multiplier
        ) external 
    {
            poolInfo.push(PoolInfo({
            stakingToken:       _stakingToken,
            rewardsToken:       _rewardsToken,
            tier1Fee:           _tier1Fee,
            tier2Fee:           _tier2Fee,
            tier3Fee:           _tier3Fee,
            tier4Fee:           _tier4Fee,
            tier5Fee:           _tier5Fee,
            uom:                _uom,
            multiplier:         _multiplier,
            totalDeposited:0,
            totalRewards:0,
            totalRewardsDebt:0
        })
        );
    }
    

    /** @dev set staking contract address
     * @param _pid: pid of the pool
     * @param _stakeContract new address to change staking contract / mechanism
     */
    function setStakeContract(uint256 _pid, address _stakeContract) external onlyOwner {
        require(_stakeContract != address(0));
        PoolInfo storage pool = poolInfo[_pid];
        address oldSC = pool.stakingToken;
        pool.stakingToken = _stakeContract;
        emit NotifyNewStakingContract(oldSC, _stakeContract);
    }

    /** @dev set rewards contract address
     ** @pid pid of the pool
     * @param _rewardContract new address to change  contract / mechanism
     */
    function setRewardsContract(uint256 _pid, address _rewardContract) external onlyOwner {
        require(_rewardContract != address(0));
        PoolInfo storage pool = poolInfo[_pid];
        address oldRC = pool.rewardsToken;
        pool.rewardsToken = _rewardContract;
        emit NotifyNewRewardsContract(oldRC, _rewardContract);
    }

    /** @dev add rewards amount to the pool
     ** @pid pid of the pool
     * @param _pid pid of the pool 
     * @param _amount of rewards token
     */
    function addRewardsToThePool(uint256 _pid, address _poolAddress, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        require(totalRewardsInThePool(_pid, _poolAddress) >= _amount, 
                "Insufficient Rewards token for the pool"
        );
        pool.totalRewards += _amount;
        emit NotifyRewardAdded(_pid, _amount);
    }

  
    /************************ POOL MANAGEMENT **********************************/

    /************************ POOL MANAGEMENT INTERNAL **********************************/

    /** @dev adding a new user to the staking pool
    * @param _pid: pid of the pool
    * @param _user: address of the user
    * @param _amount: deposited amount
    * @param _endOfStake: date of the end of stake
    * @param _rewardDebt: rewardDebt
    */
    
    function addUserToPool(
        uint256 _pid,
        address _user,
        uint256 _amount,
        uint256 _endOfStake,
        uint256 _apy,
        uint256 _rewardDebt
    ) internal {
        UserInfo memory user = UserInfo({
            amount: _amount,
            rewardDebt: _rewardDebt,
            endOfStake: _endOfStake,
            apy: _apy
        });
        userInfo[_pid][_user] = user;
    }
    
     /** @dev remove user from the staking pool*/

    function removeUserFromPool(
        uint256 _pid,
        address _user
    ) internal {
        delete userInfo[_pid][_user];
    }

    /** @dev calculate rewards for the user
     * @param _pid pid of the pool
     * @param _apy of the user
     * @param _amount staked by the user
     * @return uint that is the value of the rewards 
    */

    function calculateRewards(uint256 _pid, uint256 _apy, uint256 _amount) public view returns(uint256){
        // retrieve pool information
        PoolInfo memory pool = poolInfo[_pid];
        uint256 rewards= _amount.div(pool.totalRewards).mul(_apy).div(1000);
        return rewards;
    }

    /************************ POOL MANAGEMENT INTERNAL **********************************/


    /************************ PUBLIC POOL ACTIONS **********************************/

    /** @dev deposit funds to the contract
     *@param _dValue value of tokens that the msg.sender wants to deposit
     *@param _tier days msg.sender wants to deposit the token for
     *@param _pid pool
     
     */

    function stake(uint256 _pid, address _address, address _poolAddress, uint256 _dValue, uint256 _tier) external whenNotPaused {
        // require the user to be a new user
        PoolInfo storage pool = poolInfo[_pid];
        uint256 endOfStake;
        uint256 apy;
        uint256 totalSupplyRewardsToken = ERC20(pool.rewardsToken).totalSupply();
        uint256 totalSupplyStakingToken = ERC20(pool.stakingToken).totalSupply();

        // user can't have more than 1 position in the pool
        require(
            isAlreadyUser(_pid, _address) == 0,
            "User has already a position in the pool"
        );

        // pool has to be opened
        require (
            isPoolOpen(_pid) == true,
            "The pool is closed: no enough rewards"
        );

        // require the user to have enough tokens to be deposited
        require(
            ERC20(pool.stakingToken).balanceOf(_address) >= _dValue,
            "The user does not have enough tokens to deposit"
        );

        // increase the total deposited variable of the value of tokens transferred as parameter
        pool.totalDeposited = pool.totalDeposited.add(_dValue);

        //calculate tier % for the user
        if (_tier == 1) {
            apy = pool.tier1Fee;
        }
        if (_tier == 2) {
            apy = pool.tier2Fee;
        }
        if (_tier == 3) {
            apy = pool.tier3Fee;
        }
        if (_tier == 4) {
            apy = pool.tier4Fee;
        }
        if (_tier == 5) {
            apy = pool.tier5Fee;
        }

        //calculate end of stake
        
        if(pool.uom == 0) {
           endOfStake = block.timestamp + (_tier * pool.multiplier *  30 days);    
        }
        if(pool.uom == 1) {
            endOfStake = block.timestamp + (_tier * pool.multiplier * 1 weeks);    
        }
        if(pool.uom == 2) {
            endOfStake = block.timestamp + (_tier * pool.multiplier * 1 days);        
        }
        if(pool.uom == 3) {
            endOfStake = block.timestamp + (_tier * pool.multiplier * 1 hours);    
        }
        if(pool.uom == 4) {
            endOfStake = block.timestamp + (_tier * pool.multiplier * 1 minutes);    
        }
        
        
        // calculate rewards
        uint256 weigthedRatio = totalSupplyRewardsToken / totalSupplyStakingToken;
        uint256 rewards= _dValue.mul(apy).div(1000).mul(weigthedRatio);

        // update the total reward debt of the pool
        pool.totalRewardsDebt = pool.totalRewardsDebt.add(rewards);

        // add  user in the mapping array
        addUserToPool(
            _pid
            ,_address
            ,_dValue
            ,endOfStake
            ,apy
            ,rewards
        );

        // transfer the tokens from the ERC20 smart contract to this pool address
        ERC20(pool.stakingToken).transferFrom(_address , _poolAddress, _dValue);
        // emit notify stake event
        emit NotifyStake(_pid, _address, _dValue);
    }

    /** @dev withdrawal funds out of pool
     * @param _pid pid of the pool
     * @param _address of the user
     * @param wdValue amount to unstake
     */
    function unstake(uint256 _pid, address _address, uint256 wdValue) external whenNotPaused {
        
        // get pool information
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_address];
        // require the amount to withdraw to be > 0
        require(wdValue > 0);
        // require the sender to have a deposited balance >= at the withdraw requested amount
        require(user.amount >= wdValue);
        
        // transfer the withdraw requested amount to the spender
        ERC20(pool.stakingToken).transferFrom(msg.sender, _address, wdValue);

        // emit new event
        emit NotifyUnstake(
            _pid,
            _address,
            wdValue
        );
        
        // calculate new deposited amount
        user.amount.sub(wdValue);

        // remove user from the mapping array
        removeUserFromPool(_pid, _address);
        
        // redute the deposited balance by the withdraw requested amount
        pool.totalDeposited = pool.totalDeposited.sub(wdValue);
        
    }

    /** @dev calculate rewards for the user
     * @param _address of the user
     * @return uint that is the value of the rewards
     */

    function claimableRewards(uint256 _pid, address _address)
        public
        view
        returns (uint256)
    {
        
        UserInfo storage user = userInfo[_pid][_address];
        
        uint256 rewards = 0;
        
        
        // check if the staking period is over
        if (block.timestamp > user.endOfStake) {
           rewards = user.rewardDebt;
            
        }
        // return the rewards balance
        return rewards;
    }

    /** @dev claim rewards out of pool
     * @param _address of the user
     * @param _pid of the pool
     */
    
    function claimRewards(uint256 _pid, address _address) external whenNotPaused {
        // add a require
        // get user information
        UserInfo storage user = userInfo[_pid][_address];
        uint256 prevRewardDebt = user.rewardDebt;
        uint256 newRewardDebt;
        
        // get pool information
        PoolInfo storage pool = poolInfo[_pid]; 
        
        // transfer the rewards
        ERC20(pool.rewardsToken).transferFrom(msg.sender, _address,claimableRewards(_pid, _address));
        emit NotifyRewardClaimed(_pid, _address, claimableRewards(_pid, _address));
        
        // update the user information about the rewardDebt
        newRewardDebt = prevRewardDebt - claimableRewards(_pid, _address);
        user.rewardDebt = newRewardDebt;
        
        // update pool information
        pool.totalRewardsDebt -= prevRewardDebt;
    }
    
    /************************ PUBLIC POOL ACTIONS **********************************/
    
}