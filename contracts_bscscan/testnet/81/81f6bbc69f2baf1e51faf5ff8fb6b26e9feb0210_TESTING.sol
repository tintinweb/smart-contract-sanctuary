/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: MIT

/* 
 * Website  : https://www.testing.com  
 * Name     : TESTING
 * Symbol   : TEST2
*/

pragma solidity 0.8.9;

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

    address private _owners;

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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
 * @dev Interface for the optional metadata functions from the BEP20 standard.
 *
 * _Available since v4.1._
 */
interface IBEP20Metadata is IBEP20 {
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


/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, IBEP20Metadata {
    mapping(address => uint256) public _balances;
    mapping(address => uint256) public _lock;
    mapping(address => uint256) public _locktime;
    mapping(address => uint256) public _lock_buy;
    mapping(address => uint256) public _locktime_buy;
    mapping(address => uint256) public _buy_bal;
    mapping(address => uint256) public _bou_bal;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimal;
    uint256 public _token_rate = 100;
    address private owners;
    address[] public buyers;
    address[] public bountys;
    uint8 private sell_tokens;
    uint8 public aaa;
    uint8 public user_type1;
    uint8 public user_type2;
    uint8 public user_type3;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimal_) {
        _name = name_;
        _symbol = symbol_;
        _decimal = decimal_;
        address msgSender = _msgSender();
        owners = msgSender;
    }

    function getOwner() public view virtual returns (address) {
        return owners;
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

    function token_rate(uint256 _token_rates) public virtual returns (bool) {
        _token_rate = _token_rates;
        return true;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {BEP20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IBEP20-balanceOf} and {IBEP20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimal;
    }

    // function getOwner() external view returns (address) {    
    //     return owners;
    // }

    /**
     * @dev See {IBEP20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IBEP20-transfer}.
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
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IBEP20-approve}.
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
     * @dev See {IBEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20}.
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
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
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
     * problems described in {IBEP20-approve}.
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
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
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
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
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
        require(account != address(0), "BEP20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */


    function buy() public payable returns (uint256) {
        require(_msgSender() != getOwner(), "Invalid sender");

        uint256 amounts = msg.value * _token_rate/1;
        // uint256 amounts = 1 * _token_rate/1;

        emit Transfer(getOwner(), _msgSender(), amounts);//10-1=9

        _balances[getOwner()] -= amounts;//-9

        _balances[_msgSender()] += amounts;//+9

        push_buyer(_msgSender(), amounts);

        return amounts;

    }

    function push_buyer(address buyer, uint256 amounts) public {
        buyers.push(buyer);
        _buy_bal[buyer] += amounts;

        if(_locktime_buy[buyer] <= 0) {
            _lock_buy[buyer] = 1;

            _locktime_buy[buyer] = block.timestamp;
        }
    }

    function push_bounty(address bounty, uint256 amounts) public {
        bountys.push(bounty);
        _bou_bal[bounty] += amounts;
        _lock[bounty] = 1;
        _locktime[bounty] = block.timestamp;

        emit Transfer(getOwner(), bounty, amounts);//10-1=9

        _balances[bounty] += amounts;//temp

        _balances[getOwner()] -= amounts;//temp
    }

    function sell(address receiver) public payable returns (uint256) {

        uint256 buy_balance_ = _buy_bal[_msgSender()];
        uint256 bou_balance_ = _bou_bal[_msgSender()];
        uint256 _acc_balance = _balances[_msgSender()];
        uint8 bounty = 0;
        uint8 buyer = 0;
        uint8 can_transfer = 0;
        uint256 amounts = msg.value * _token_rate/1;
        // uint256 amounts = 1 * _token_rate/1;
        require(_acc_balance >= amounts, "BEP20: transfer amount exceeds balance");
        require(_msgSender() != getOwner(), "Invalid sender");

        for (uint i = 0; i < bountys.length; i++) {
            if(bountys[i] == _msgSender()) {
                bounty = 1;
                break;
            }
        }

        //only buyer
        for (uint i = 0; i < buyers.length; i++) {
            if(buyers[i] == _msgSender() && bounty == 0) {
                buyer = 1;
                user_type1 = 1;
                break;
            }
        }

        //only bounty
        if(bounty == 1 && buyer == 0) {
            user_type2 = 1;
        }

        //both
        if(bounty == 1 && buyer == 1) {
            user_type3 = 1;
        }

        if (user_type1 == 1) {
            if (_lock_buy[_msgSender()] == 0) {
                require(buy_balance_ >= amounts, "BEP20: transfer amount exceeds balance");//100 >= 10
                can_transfer = 1;
                _buy_bal[_msgSender()] -= amounts;
                
                for (uint i = 0; i < buyers.length; i++) {
                    if(buyers[i] == _msgSender()) {
                        delete buyers[i];
                        break;
                    }
                }
            }
        } else if (user_type2 == 1) {
            if (block.timestamp >= _locktime[_msgSender()] + 300 seconds) {
                require(bou_balance_ >= amounts, "You can't sell");//100 >= 10
                _lock[_msgSender()] = 0;
                _locktime[_msgSender()] = 0;
                can_transfer = 1;
                _bou_bal[_msgSender()] -= amounts;
                for (uint i = 0; i < bountys.length; i++) {
                    if(bountys[i] == _msgSender()) {
                        delete bountys[i];
                    }
                }
            }
        } else if (user_type3 == 1) {
            if(_lock_buy[_msgSender()] == 0 && block.timestamp < _locktime[_msgSender()] + 300 seconds) {
                if (buy_balance_ >= amounts) {
                    can_transfer = 1;
                    _buy_bal[_msgSender()] -= amounts;
                    
                    for (uint i = 0; i < buyers.length; i++) {
                        if(buyers[i] == _msgSender()) {
                            delete buyers[i];
                        }
                    }
                }
            } else if(_lock_buy[_msgSender()] == 1 && block.timestamp >= _locktime[_msgSender()] + 300 seconds) {
                require(bou_balance_ >= amounts, "You can't sell");//100 >= 10
                can_transfer = 1;
                _bou_bal[_msgSender()] -= amounts;
                for (uint i = 0; i < bountys.length; i++) {
                    if(bountys[i] == _msgSender()) {
                        delete bountys[i];
                    }
                }
            } else if(_lock_buy[_msgSender()] == 0 && block.timestamp >= _locktime[_msgSender()] + 300 seconds) {
                if(buy_balance_ >= amounts) {
                    can_transfer = 1;
                    _buy_bal[_msgSender()] -= amounts;
                } else if(bou_balance_ >= amounts) {
                    can_transfer = 1;
                    _bou_bal[_msgSender()] -= amounts;
                } else if(buy_balance_ >= amounts && bou_balance_ >= amounts) {
                    can_transfer = 1;
                    _buy_bal[_msgSender()] -= amounts;
                }
            }
        }

        if (can_transfer == 1) {
            emit Transfer(_msgSender(), receiver, amounts);
            _balances[_msgSender()] -= amounts;//+9
            _balances[receiver] += amounts;//-9
        } else {
            revert("You can't sell");
        }

        return amounts;

    }

    function sell_allowance(uint8 can_sell) public virtual returns (bool) {
        sell_tokens = can_sell;
        for (uint i = 0; i < buyers.length; i++) {
            _lock_buy[buyers[i]] = 0;
            _locktime_buy[buyers[i]] = 0;
        }

        return true;
    }
}

/**
 * @dev Extension of {BEP20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract BEP20Burnable is Context, BEP20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {BEP20-_burn}.
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
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}


/**
 * @dev Extension of {BEP20} that allows admin to mint tokens
 * for off-chain or cross-chain functionality.
 */
abstract contract BEP20Mintable is Context, BEP20, Ownable {
    /**
     * @dev Mints `amount` of tokens to the caller.
     *
     * See {BEP20-_mint}.
     */
    function mint(uint256 amount) public virtual onlyOwner{
        _mint(_msgSender(), amount);
    } 
}

contract TESTING is BEP20,Ownable,BEP20Burnable,BEP20Mintable {


    constructor()
         BEP20("TESTING", "TEST2", 18) {
             /* 750 Million Total Supply */
            _mint(msg.sender, 750 * (10 ** uint256(6)) * (10 ** uint256(18)));
        }

}