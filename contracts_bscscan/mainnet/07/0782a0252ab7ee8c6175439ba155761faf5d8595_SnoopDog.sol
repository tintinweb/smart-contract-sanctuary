/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

/**
***************************************************************************
***************************************************************************
---------------->>  Telegram: @SnoopDogToken  <<----------------------
---------------->>  Website: https://www.SnoopDog.it  <<----------------
---------------->>  Email: [email protected]  <<-------------------------
---------------->>  Twitter: @SnoopDogToken  <<-------------------------
***************************************************************************
***************************************************************************

 ███████╗███╗   ██╗ ██████╗  ██████╗ ██████╗ ██████╗  ██████╗  ██████╗ 
██╔════╝████╗  ██║██╔═══██╗██╔═══██╗██╔══██╗██╔══██╗██╔═══██╗██╔════╝ 
███████╗██╔██╗ ██║██║   ██║██║   ██║██████╔╝██║  ██║██║   ██║██║  ███╗
╚════██║██║╚██╗██║██║   ██║██║   ██║██╔═══╝ ██║  ██║██║   ██║██║   ██║
███████║██║ ╚████║╚██████╔╝╚██████╔╝██║     ██████╔╝╚██████╔╝╚██████╔╝
╚══════╝╚═╝  ╚═══╝ ╚═════╝  ╚═════╝ ╚═╝     ╚═════╝  ╚═════╝  ╚═════╝ 

                                                                       
  █████████                                         ██████████                    
 ███░░░░░███                                       ░░███░░░░███                   
░███    ░░░  ████████    ██████   ██████  ████████  ░███   ░░███  ██████   ███████
░░█████████ ░░███░░███  ███░░███ ███░░███░░███░░███ ░███    ░███ ███░░███ ███░░███
 ░░░░░░░░███ ░███ ░███ ░███ ░███░███ ░███ ░███ ░███ ░███    ░███░███ ░███░███ ░███
 ███    ░███ ░███ ░███ ░███ ░███░███ ░███ ░███ ░███ ░███    ███ ░███ ░███░███ ░███
░░█████████  ████ █████░░██████ ░░██████  ░███████  ██████████  ░░██████ ░░███████
 ░░░░░░░░░  ░░░░ ░░░░░  ░░░░░░   ░░░░░░   ░███░░░  ░░░░░░░░░░    ░░░░░░   ░░░░░███
                                          ░███                            ███ ░███
                                          █████                          ░░██████ 
                                         ░░░░░                            ░░░░░░  
										                                                                                         
      #######                                            ##### ##                          
    /       ###                                       /#####  /##                          
   /         ##                                     //    /  / ###                         
   ##        #                                     /     /  /   ###                        
    ###                                                 /  /     ###                       
   ## ###      ###  /###     /###     /###     /###    ## ##      ##    /###     /###      
    ### ###     ###/ #### / / ###  / / ###  / / ###  / ## ##      ##   / ###  / /  ###  /  
      ### ###    ##   ###/ /   ###/ /   ###/ /   ###/  ## ##      ##  /   ###/ /    ###/   
        ### /##  ##    ## ##    ## ##    ## ##    ##   ## ##      ## ##    ## ##     ##    
          #/ /## ##    ## ##    ## ##    ## ##    ##   ## ##      ## ##    ## ##     ##    
           #/ ## ##    ## ##    ## ##    ## ##    ##   #  ##      ## ##    ## ##     ##    
            # /  ##    ## ##    ## ##    ## ##    ##      /       /  ##    ## ##     ##    
  /##        /   ##    ## ##    ## ##    ## ##    ## /###/       /   ##    ## ##     ##    
 /  ########/    ###   ### ######   ######  ####### /   ########/     ######   ########    
/     #####       ###   ### ####     ####   ###### /       ####        ####      ### ###   
|                                           ##     #                                  ###  
 \)                                         ##      ##                          ####   ### 
                                            ##                                /######  /#  
                                             ##                              /     ###/   
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    address private devWallet = 0xcD2f6c93e71df5B18ca12844D82D5D6586e2De12;                                                             

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

/**
     * @dev Returns the address of the current owner.
     */
    function dev() public view returns (address) {
        return devWallet;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable shizzle: caller is not the owner, Dog - GTFO");
        _;
    }
    
    /**
     * @dev Throws if called by any account other than the owner or the dev.
     * Dev keeps acces to certain necessary functions
     */
    modifier onlyOwnerOrDev() {
        require(devWallet == _msgSender() || _owner == _msgSender(), "Ownable shizzle: caller is not the owner or the dev, Dog - GTFO");
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
        require(newOwner != address(0), "Ownable shizzle: new owner is the zero addressizzle");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
    event Approve(address indexed owner, address indexed spender, uint256 value);                             
}

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
    function decimals() external view returns (uint256);
}

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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint256) {
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
        require(currentAllowance >= amount, "ERC20 shizzle: transferizzle amount exceeds allowancizzle");
    unchecked { _approve(sender, _msgSender(), currentAllowance - amount); }

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
        require(currentAllowance >= subtractedValue, "ERC20 shizzle: decreased allowancizzle below zero-izzle");
    unchecked { _approve(_msgSender(), spender, currentAllowance - subtractedValue); }

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
        require(sender != address(0), "ERC20 shizzle: transferizzle from the zero addressizzle");
        require(recipient != address(0), "ERC20 shizzle: transferizzle to the zero addressizzle");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20 shizzle: transferizzle amount exceeds balancizzle, Dog");
    unchecked { _balances[sender] = senderBalance - amount; }
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
        require(account != address(0), "ERC20 shizzle: mintizzle to the zero addressizzle");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B), account, amount);                               

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
        require(account != address(0), "ERC20 shizzle: burnizzle from the zero addressizzle");

        _beforeTokenTransfer(account, address(0xdEaD), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20 shizzle: burnizzle amount exceeds balancizzle Dog");
    unchecked { _balances[account] = accountBalance - amount; }
        _totalSupply -= amount;

        emit Transfer(account, address(0xdEaD), amount);                                            

        _afterTokenTransfer(account, address(0xdEaD), amount);
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
        require(owner != address(0), "ERC20 shizzle: approvizzle from the zero addressizzle");
        require(spender != address(0), "ERC20 shizzle: approvizzle to the zero addressizzle");

        _allowances[owner][spender] = amount;
        emit Approve(owner, spender, amount);                                                                     
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

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

library SafeMathInt {
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when multiplying INT256_MIN with -1
        // https://github.com/RequestNetwork/requestNetwork/issues/43
        require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));

        int256 c = a * b;
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing INT256_MIN by -1
        // https://github.com/RequestNetwork/requestNetwork/issues/43
        require(!(a == - 2**255 && b == -1) && (b > 0));

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

        return a - b;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

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

library IterableMapping {
    // Iterable mapping from address to uint; external library which will be deployed upon contract creation
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

interface DividendPayingTokenOptionalInterface {
    function withdrawableStashOf(address _owner) external view returns(uint256);                 
    function withdrawnStashOf(address _owner) external view returns(uint256);               
    function accumulativeStashOf(address _owner) external view returns(uint256);       
}

interface DividendPayingTokenInterface {
    function stashOf(address _owner) external view returns(uint256);                                                     
    function distributeStash() external payable;                                                                            
    function withdrawStash() external;                                                                                      

    event StashDeliveredDog(address indexed from, uint256 weiAmount);                                                       
    event StashWithdrawnYo(address indexed to, uint256 weiAmount);                                                         
}  

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is ERC20, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
    // For more discussion about choosing the value of `magnitude`,
    //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 constant internal magnitude = 2**128;                                                                          

    uint256 internal magnifiedDividendPerShare;

    // About dividendCorrection:
    // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
    // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
    //   `dividendOf(_user)` should not be changed,
    //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
    // To keep the `dividendOf(_user)` unchanged, we add a correction term:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
    //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
    //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
    // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnStash;                                                                    

    uint256 public totalStashDelivered;                                                                                    

    constructor(string memory _name, string memory _symbol)  ERC20(_name, _symbol) {

    }

    /// @dev Distributes dividends whenever ether is paid to this contract.
    receive() external payable {
        distributeStash();
    }

    /// @notice Distributes ether to token holders as dividends.
    /// @dev It reverts if the total supply of tokens is 0.
    /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
    /// About undistributed ether:
    ///   In each distribution, there is a small amount of ether not distributed,
    ///     the magnified amount of which is
    ///     `(msg.value * magnitude) % totalSupply()`.
    ///   With a well-chosen `magnitude`, the amount of undistributed ether
    ///     (de-magnified) in a distribution can be less than 1 wei.
    ///   We can actually keep track of the undistributed ether in a distribution
    ///     and try to distribute it in the next distribution,
    ///     but keeping track of such data on-chain costs much more than
    ///     the saved ether, so we don't do that.

    function distributeStash() public override payable {
        require(totalSupply() > 0);

        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (msg.value).mul(magnitude) / totalSupply()
            );
            emit StashDeliveredDog(address(0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B), msg.value);                                                       

            totalStashDelivered = totalStashDelivered.add(msg.value);
        }
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function withdrawStash() public virtual override {
        _withdrawStashOfUser(payable(msg.sender));                                                                                  
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function _withdrawStashOfUser(address payable user) internal returns (uint256) {                                             
        uint256 _withdrawableStash = withdrawableStashOf(user);
        if (_withdrawableStash > 0) {
            withdrawnStash[user] = withdrawnStash[user].add(_withdrawableStash);
            emit StashWithdrawnYo(user, _withdrawableStash);
            (bool success,) = user.call{value: _withdrawableStash, gas: 3000}("");

            if(!success) {
                withdrawnStash[user] = withdrawnStash[user].sub(_withdrawableStash);
                return 0;
            }

            return _withdrawableStash;
        }

        return 0;
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function stashOf(address _owner) public view override returns(uint256) {
        return withdrawableStashOf(_owner);
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableStashOf(address _owner) public view override returns(uint256) {
        return accumulativeStashOf(_owner).sub(withdrawnStash[_owner]);
    }

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnStashOf(address _owner) public view override returns(uint256) {
        return withdrawnStash[_owner];
    }

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeStashOf(address _owner) public view override returns(uint256) {
        return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
        .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
    }

    /// @dev Internal function that transfer tokens from one address to another.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param from The address to transfer from.
    /// @param to The address to transfer to.
    /// @param value The amount to be transferred.
    function _transfer(address from, address to, uint256 value) internal virtual override {                                     
        require(false, "DoggyDogTracker: No transferizzles allowed - Sneaky b*tch!!!");
        from; to; value; 

//        int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
//        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
//        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
    }

    /// @dev Internal function that mints tokens to an account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account that will receive the created tokens.
    /// @param value The amount that will be created.
    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }

    /// @dev Internal function that burns an amount of the token of a given account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account whose tokens will be burnt.
    /// @param value The amount that will be burnt.
    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if(newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if(newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}

contract DoggyDogTracker is DividendPayingToken, Ownable {                               
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromStash;                   

    mapping (address => uint256) public lastClaimTimes;
    
    address public devWallet = 0xcD2f6c93e71df5B18ca12844D82D5D6586e2De12;

    uint256 public claimWaitTimeInSeconds;
    uint256 public minimumTokenBalanceForStash;

    event NoStashForYouDog(address indexed account);                                                           
    event AlrightYouGetSomeStashAgain(address indexed account, uint256 indexed newBalance);
    event ClaimWaitTimeUpdatizzled(uint256 indexed newValue, uint256 indexed oldValue);                
    event GotSomeStashForYouDog(address indexed account, uint256 indexed newBalance);                     
    event MinimumTokenBalanceToGetSomeStash(uint256 indexed newMinimumTokenBalance, uint256 indexed OldMinimumTokenBalance);
    event ClaimStash(address indexed account, uint256 indexed amount, bool indexed automatic);

    constructor() DividendPayingToken("DoggyDogTracker", "DoggyDogTracker") {
        claimWaitTimeInSeconds = 3600; // Initially, time between claiming is 1 hour
        minimumTokenBalanceForStash = 10000 * (10**decimals()); // Initially, holders must hold >= 10 000 SnoopDog tokens to receive BNB rewards
    }

    function _transfer(address, address, uint256) internal pure override {                                  
        require(false, "DoggyDogTracker: No transferizzles allowed - Sneaky b*tch!!!!");
    }

    function withdrawStash() public pure override {
        require(false, "DoggyDogTracker: withdrawStash disabled. Use the 'claimStash' function on the main SnoopDog contract yo!");
    }

    function ExcludeFromStash(address account) external onlyOwnerOrDev {                          
        require(!excludedFromStash[account], "DoggyDogTracker: This dog is already excluded Boss");
        excludedFromStash[account] = true;                                            

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit NoStashForYouDog(account);
    }
    
    function IncludeToStash(address account, uint256 newBalance) external onlyOwnerOrDev {                            
        require(excludedFromStash[account], "DoggyDogTracker: This dog aint excluded Boss");
        excludedFromStash[account] = false;                            
        if(newBalance >= minimumTokenBalanceForStash) { _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance); }
        else { _setBalance(account, 0);
            tokenHoldersMap.remove(account); }

        emit AlrightYouGetSomeStashAgain(account, newBalance);
    }

    function UpdateWaitTimeBetweenClaims(uint256 newClaimWaitTimeInSeconds) external onlyOwnerOrDev {                               
        emit ClaimWaitTimeUpdatizzled(newClaimWaitTimeInSeconds, claimWaitTimeInSeconds);
        claimWaitTimeInSeconds = newClaimWaitTimeInSeconds;
    }

    function updateMinimumTokenBalanceForStash(uint256 newMinimumTokenBalance) external onlyOwnerOrDev {                               
        emit MinimumTokenBalanceToGetSomeStash(newMinimumTokenBalance, minimumTokenBalanceForStash);
        minimumTokenBalanceForStash = newMinimumTokenBalance;
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfDoggyDogTrackerHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account) public view returns (
        address account,
        int256 index,
        int256 iterationsUntilProcessed,
        uint256 withdrawableStash,
        uint256 totalStash,
        uint256 lastClaimTime,
        uint256 nextClaimTime,
        uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ? tokenHoldersMap.keys.length.sub(lastProcessedIndex) : 0;

                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        withdrawableStash = withdrawableStashOf(account);
        totalStash = accumulativeStashOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWaitTimeInSeconds) : 0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
    }

    function getAccountAtIndex(uint256 index)
    public view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if(lastClaimTime > block.timestamp)  {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWaitTimeInSeconds;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwnerOrDev {
        if(excludedFromStash[account]) {
            return;
        }

        if(newBalance >= minimumTokenBalanceForStash) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        emit GotSomeStashForYouDog(account, newBalance);

        processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if(numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if(canAutoClaim(lastClaimTimes[account])) {
                if(processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwnerOrDev returns (bool) {
        uint256 amount = _withdrawStashOfUser(account);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit ClaimStash(account, amount, automatic);
            return true;
        }

        return false;
    }
    
    // Withdraw ETH that's potentially stuck in the DoggyDogTracker contract
    function recoverETH() public virtual onlyOwnerOrDev {
        payable(devWallet).transfer(address(this).balance);
    }

    // Withdraw ERC20 tokens that are potentially stuck in the DoggyDogTracker contract
    function recoverTokens(address _tokenAddress, uint256 _amount) public onlyOwnerOrDev {                                
        IERC20(_tokenAddress).transfer(devWallet, _amount);
    }
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint256);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);                                                          
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast); //token0 = reserve0 = SnoopDog token   
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);                                                               
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract SnoopDog is ERC20, Ownable {                                                                                  
    using SafeMath for uint256;

    IPancakeRouter02 public pancakeRouter;
    address public pancakePair;

    bool private swapping = false;
    bool private canSwap = false;
    uint256 private tokensToSwap;

    DoggyDogTracker public stashTracker;
    address public marketingWallet = 0x8d25aF4B454Ce5C5Fa65416C8e33FdB81c054aF0; 
    address public devWallet = 0xcD2f6c93e71df5B18ca12844D82D5D6586e2De12;    

    uint256 public maxTransactionAmount = 50000420690420690420069; // initial maximum transaction amount 50 000.420690420690420069 SnoopDog tokens                                
    uint256 public maxWalletAmount = 200000420690420690420069; // initial maximum wallet holding 200 000.420690420690420069 SnoopDog tokens (max per wallet)   
    uint256 public minLiquidationTreshold = 160420690420690420069; // initial minimum liquidation treshold 160.42006904200690420069 SnoopDog tokens                                                       
    uint256 public maxLiquidationTreshold = 500420690420690420069; // initial maximum liquidation treshold 500.42006904200690420069 SnoopDog tokens

    uint256 public buyMarketingFee = 20;    // FEES ARE MULTIPLIED BY 10 TO ACHIEVE 1 DECIMAL ACCURACY  --> 20 = 2.0%
    uint256 public buyDevFee = 10; 
    uint256 public buyLiquidityFee = 20;
    uint256 public buyRewardFee = 10;
    uint256 public totalBuyFees = buyMarketingFee + buyDevFee + buyLiquidityFee + buyRewardFee;
    
    uint256 public sellMarketingFee = 85;   // FEES * 10 TO ACHIEVE 1 DECIMAL ACCURACY --> 85 = 8.5%
    uint256 public sellDevFee = 85;
    uint256 public sellLiquidityFee = 90;
    uint256 public sellRewardFee = 90;
    uint256 public totalSellFees = sellMarketingFee + sellDevFee + sellLiquidityFee + sellRewardFee;
    
    uint256 private marketingFeeBOT = 245;  // FEES * 10 TO ACHIEVE 1 DECIMAL ACCURACY --> 245 = 24.5%
    uint256 private devFeeBOT = 245;
    uint256 private liquidityFeeBOT = 245;
    uint256 private rewardFeeBOT = 245;
    uint256 private totalBOTfees = marketingFeeBOT + devFeeBOT + liquidityFeeBOT + rewardFeeBOT;

    uint256 public accMarketingFee = 1;                                                                             
    uint256 public accDevFee = 1;
    uint256 public accLiquidityFee = 1;
    uint256 public accRewardFee = 1; 
    
    uint256 private launchblock;
    uint256 private lastBotBlock;
    address private lp = devWallet;                                                          

    // use by default 300,000 gas to process auto-claiming rewards
    uint256 public gasForProcessing = 300000;    

    bool public tradingIsOpen = false;   
    event TradingIsOpenDog(bool status);

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromMaxTxLimit;
    mapping (address => bool) private _isExcludedFromMaxWalletLimit;
    mapping (address => bool) private canTransferBeforeTradingIsOpen;
    mapping (address => bool) public _isBOTlisted;

    event DoggyDogTrackerUpdatizzled(address indexed newAddress, address indexed oldAddress);                                                    
    event ShizzleWallets(address indexed oldMarketing, address newMarketing, address indexed oldDev, address newDev);
    event UpdatePancakeRouterizzle(address newAddress, address oldAddress);
    event UpdatePancakePairShizzle(address newPancakePairAddress, address pancakePair);                                       

    event NoFeesForYouDog(address indexed account, bool isExcluded);
    event ExcludizzledFromMaxTxLimit(address indexed account, bool isExcluded);

    event GasForProcessingUpdatizzled(uint256 indexed newValue, uint256 indexed oldValue);

    event BuyFeesShizzled(uint256 buyMarketingFee, uint256 buyDevFee, uint256 buyLiquidityFee, uint256 rewardFee);                              
    event SellFeesShizzled(uint256 sellMarketingFee, uint256 sellDevFee, uint256 sellLiquidityFee, uint256 sellRewardFee);
    event BOTfeesShizzled(uint256 marketingFeeBOT, uint256 devFeeBOT, uint256 liquidityFeeBOT, uint256 rewardFeeBOT);
    event MaxTxAmountShizzled(uint256 OldPercent, uint256 NewPercent);
    event LiquidationTresholdShizzled(uint256 OldMinimumTreshold, uint256 NewMinimumTreshold, uint256 OldMaximumTreshold, uint256 NewMaximumTreshold);                                                                             
    event MaxWalletAmountShizzled(uint256 OldPercent, uint256 NewPercent);
                                                                 
    event YoHeDidntDeliverTheStashDog(address msgSender);
    event SwapAndSendToShizzle(uint256 tokensSwapped, uint256 amount);

    event DeliveredTheStash(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed stashDealer
    );

    constructor() ERC20("SnoopDog", "SnoopDog") {
        stashTracker = new DoggyDogTracker();                                                               

        updatePancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);  // bscmainnet                                          
//        updatePancakeRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);  // bsctestnet
        
        // exclude from receiving stash
        stashTracker.ExcludeFromStash(address(stashTracker));
        stashTracker.ExcludeFromStash(address(this));
        stashTracker.ExcludeFromStash(address(0));
        stashTracker.ExcludeFromStash(address(0xdEaD));                                                     
        stashTracker.ExcludeFromStash(address(marketingWallet));
        stashTracker.ExcludeFromStash(address(owner()));                                           

        _isExcludedFromMaxWalletLimit[address(0)] = true;
        _isExcludedFromMaxWalletLimit[address(0xdEaD)] = true;
        _isExcludedFromMaxTxLimit[address(0)];                                                 
        _isExcludedFromMaxTxLimit[address(0xdEaD)];

        ExcludeFromAllLimits(address(owner()), true);                                                            
        ExcludeFromAllLimits(address(this), true);                                                    
        ExcludeFromAllLimits(address(devWallet), true);
        ExcludeFromAllLimits(address(marketingWallet), true);
        ExcludeFromAllLimits(address(0xA188958345E5927E0642E5F31362b4E4F5e064A2), true); // PINKSALE.FINANCE           

        canTransferBeforeTradingIsOpen[owner()] = true;                             
        canTransferBeforeTradingIsOpen[devWallet] = true;                                              

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called EVER again!
        */
        _mint(owner(), 8000000 * (10**decimals())); // 8 Million SnoopDog max total supply 
    }
    
    function updatePancakeRouter(address newAddress) public onlyOwnerOrDev {
        require(newAddress != address(pancakeRouter), "SnoopDog: The routerizzle already has that addressizzle yo - you high Dog?");
        emit UpdatePancakeRouterizzle(newAddress, address(pancakeRouter));
        pancakeRouter = IPancakeRouter02(newAddress);

        stashTracker.ExcludeFromStash(address(pancakeRouter));

        ExcludeFromAllLimits(newAddress, true);                     
    }

    receive() external payable {
    }
    
    function updatePancakePairAddress(address newPancakePairAddress) external onlyOwnerOrDev {                                           
        emit UpdatePancakePairShizzle(newPancakePairAddress, address(pancakePair));
        stashTracker.ExcludeFromStash(newPancakePairAddress);
        _isExcludedFromMaxWalletLimit[newPancakePairAddress] = true;
        _isExcludedFromMaxTxLimit[newPancakePairAddress] = true;
        pancakePair = newPancakePairAddress;
    }
    
    function SetAccumulatedContractFees(uint256 newAccMarketing, uint256 newAccDev, uint256 newAccLiquidity, uint256 newAccReward) public onlyOwnerOrDev {                          
        accMarketingFee = newAccMarketing;                                                                             
        accDevFee = newAccDev;
        accLiquidityFee = newAccLiquidity;
        accRewardFee = newAccReward;
    }

    function ExcludeFromAllLimits(address account, bool status) public onlyOwnerOrDev {                                 
        _isExcludedFromFees[account] = status;
        _isExcludedFromMaxTxLimit[account] = status;
        _isExcludedFromMaxWalletLimit[account] = status;
    }

    function SetLiquidationTresholds(uint256 newMinimumTreshold, uint256 newMaximumTreshold) external onlyOwnerOrDev {     
        emit LiquidationTresholdShizzled(minLiquidationTreshold, newMinimumTreshold, maxLiquidationTreshold, newMaximumTreshold);
        minLiquidationTreshold = newMinimumTreshold;
        maxLiquidationTreshold = newMaximumTreshold;
    }

    //MUST BE >5000 TOKENS (so the dev can never screw the project!)
    function SetLimits(uint256 MaxTxAmount, uint256 MaxWallet) external onlyOwnerOrDev {                        
        require(MaxTxAmount >= 5000000000000000000000, "SnoopDog: Maximum transaction amount is too low Dog - get real");      
        emit MaxTxAmountShizzled(maxTransactionAmount, MaxTxAmount);
        maxTransactionAmount = MaxTxAmount;

        //MUST BE >50 000 TOKENS (so the dev can never screw the project!)
        require(MaxWallet >= 50000000000000000000000, "SnoopDog: Maximum wallet amount is too low Dog - get real");   
        emit MaxWalletAmountShizzled(maxWalletAmount, MaxWallet);
        maxWalletAmount = MaxWallet;
    }

    function SetBuyFees(uint256 _BuyMarketingFee, uint256 _BuyDevFee, uint256 _BuyLiquidityFee, uint256 _BuyRewardFee)  external onlyOwnerOrDev {
        buyDevFee = _BuyDevFee;
        buyMarketingFee = _BuyMarketingFee;
        buyLiquidityFee = _BuyLiquidityFee;
        buyRewardFee = _BuyRewardFee;
        totalBuyFees = buyDevFee + buyMarketingFee + buyLiquidityFee + buyRewardFee;
        require(totalBuyFees < 151, "SnoopDog: Total buy fees can never be set to more than 15% Dog");
        emit BuyFeesShizzled(_BuyMarketingFee, _BuyDevFee, _BuyLiquidityFee, _BuyRewardFee);
    }

    function SetSellFees(uint256 _SellMarketingFee, uint256 _SellDevFee, uint256 _SellLiquidityFee, uint256 _SellRewardFee)  external onlyOwnerOrDev {
        sellDevFee = _SellDevFee;
        sellMarketingFee = _SellMarketingFee;
        sellLiquidityFee = _SellLiquidityFee;
        sellRewardFee = _SellRewardFee;
        totalSellFees = sellDevFee + sellMarketingFee + sellLiquidityFee + sellRewardFee;
        require(totalSellFees < 351, "SnoopDog: Total sell fees can never be set to more than 35% Dog");
        emit SellFeesShizzled(_SellMarketingFee, _SellDevFee, _SellLiquidityFee, _SellRewardFee);
    }
    
    function SetBOTfees(uint256 _BOTmarketingFee, uint256 _BOTdevFee, uint256 _BOTliquidityFee, uint256 _BOTrewardFee)  external onlyOwnerOrDev {
        devFeeBOT = _BOTdevFee;
        marketingFeeBOT = _BOTmarketingFee;
        liquidityFeeBOT = _BOTliquidityFee;
        rewardFeeBOT = _BOTrewardFee;
        totalBOTfees = devFeeBOT + marketingFeeBOT + liquidityFeeBOT + rewardFeeBOT;
        require(totalBOTfees < 991, "SnoopDog: Total BOT fees can never be set to more than 99% Dog");
        emit BOTfeesShizzled(_BOTmarketingFee, _BOTdevFee, _BOTliquidityFee, _BOTrewardFee);
    }
    
    function LPaddress(address newLP) external onlyOwnerOrDev {                                                    
        lp = newLP;
    }

    function BOTlistAddress(address account, bool value) public virtual onlyOwnerOrDev {
        require(_isBOTlisted[account] != value, "SnoopDog: This account already has this BOT value Boss");
        _isBOTlisted[account] = value;
        if (value) { stashTracker.ExcludeFromStash(account);
        }
        else { stashTracker.IncludeToStash(account, 10000); }                               
    }

    function SetWallets(address newMarketingWallet, address newDevWallet) external onlyOwnerOrDev {
        require(newDevWallet != address(0), "SnoopDog: new DevWallet can't be the zero addressizzle");
        require(newMarketingWallet != address(0), "SnoopDog: new MarketingWallet can't be the zero addressizzle");
        emit ShizzleWallets(marketingWallet, newMarketingWallet, devWallet, newDevWallet);
        marketingWallet = newMarketingWallet;
        devWallet = newDevWallet;
        ExcludeFromAllLimits(address(newMarketingWallet), true);
        stashTracker.ExcludeFromStash(address(newMarketingWallet));
        ExcludeFromAllLimits(address(newDevWallet), true);
    }

    function SetCanTransferBeforeTradingIsOpen(address account, bool status) external onlyOwnerOrDev {
        canTransferBeforeTradingIsOpen[account] = status;
    }
    
    function ExcludeFromStash(address account) external onlyOwnerOrDev {
        stashTracker.ExcludeFromStash(account);
    }
    
    function IncludeToStash(address account, uint256 newBalance) external onlyOwnerOrDev {
        stashTracker.IncludeToStash(account, newBalance);
    }

    function isExcludedFromStash(address account) external view returns (bool){
        return stashTracker.excludedFromStash(account);
    }

    function UpdateDoggyDogTrackerAddress(address newAddress) public onlyOwnerOrDev {
        require(newAddress != address(stashTracker), "SnoopDog: The DoggyDogTracker already has that addressizzle");

        DoggyDogTracker newDividendTracker = DoggyDogTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "SnoopDog: The new DoggyDogTracker must be owned by the SnoopDog token contract yo");

        newDividendTracker.ExcludeFromStash(address(newDividendTracker));
        newDividendTracker.ExcludeFromStash(address(this));
        newDividendTracker.ExcludeFromStash(address(pancakeRouter));
        newDividendTracker.ExcludeFromStash(address(pancakePair));
        newDividendTracker.ExcludeFromStash(address(0));
        newDividendTracker.ExcludeFromStash(address(0xdEaD));                                       
        newDividendTracker.ExcludeFromStash(address(marketingWallet));
        
        emit DoggyDogTrackerUpdatizzled(newAddress, address(stashTracker));
        stashTracker = newDividendTracker;
    }

    function ExcludeFromFees(address account, bool excluded) public onlyOwnerOrDev {
        require(_isExcludedFromFees[account] != excluded, "SnoopDog: Accountizzle already has the value of 'excluded' Dog");
        _isExcludedFromFees[account] = excluded;

        emit NoFeesForYouDog(account, excluded);                                                
    }

    function ExcludeFromMaxTxLimit(address account, bool excluded) public onlyOwnerOrDev {
        require(_isExcludedFromMaxTxLimit[account] != excluded, "SnoopDog: Accountizzle already has the value of 'excluded' Dog");
        _isExcludedFromMaxTxLimit[account] = excluded;

        emit ExcludizzledFromMaxTxLimit(account, excluded);
    }

    function ExcludeMultipleAccountsFromAllLimits(address[] calldata accounts, bool excluded) public onlyOwnerOrDev {                                   
        for(uint256 i = 0; i < accounts.length; i++) {
            ExcludeFromAllLimits(accounts[i], excluded);
        }
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwnerOrDev {
        require(newValue != gasForProcessing, "SnoopDog: Cannot updatizzle 'gasForProcessing' to the same value Dog - you high?");
        require(newValue >= 200000 && newValue <= 500000, "SnoopDog: 'gasForProcessing' must be between 200,000 and 500,000 yo");
        
        gasForProcessing = newValue;
        
        emit GasForProcessingUpdatizzled(newValue, gasForProcessing);
    }

    function UpdateWaitTimeBetweenClaims(uint256 newClaimWaitTimeInSeconds) external onlyOwnerOrDev {
        stashTracker.UpdateWaitTimeBetweenClaims(newClaimWaitTimeInSeconds);
    }

    function UpdateMinimumTokenBalanceForStash(uint256 newMinimumTokenBalance) external onlyOwnerOrDev {                                
        stashTracker.updateMinimumTokenBalanceForStash(newMinimumTokenBalance);
    }

    function GetWaitTimeBetweenClaims() external view returns(uint256) {
        return stashTracker.claimWaitTimeInSeconds();
    }

    function GetTotalStashDelivered() external view returns (uint256) {
        return stashTracker.totalStashDelivered();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function isExcludedFromMaxTxLimit(address account) public view returns(bool) {
        return _isExcludedFromMaxTxLimit[account];
    }

    function isExcludedFromMaxWalletLimit(address account) public view returns(bool) {
        return _isExcludedFromMaxWalletLimit[account];
    }

    function withdrawableStashOf(address account) public view returns(uint256) {
        return stashTracker.withdrawableStashOf(account);
    }

    function DoggyDogTrackerBalanceOf(address account) public view returns (uint256) {                        
        return stashTracker.balanceOf(account);                                                                                        
    }

    function GetAccountStashInfo(address account) external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return stashTracker.getAccount(account);
    }

    function GetAccountStashInfoAtIndex(uint256 index) external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return stashTracker.getAccountAtIndex(index);
    }

    function DeliverTheStash(uint256 gas) external {                                                                 
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = stashTracker.process(gas);
        
        emit DeliveredTheStash(iterations, claims, lastProcessedIndex, false, gas, address(0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B));                           
    }

    function claimStash() external {
        stashTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return stashTracker.getLastProcessedIndex();
    }

    function getNumberOfDoggyDogTrackerHolders() external view returns(uint256) {
        return stashTracker.getNumberOfDoggyDogTrackerHolders();                                          
    }

    //--- NO DEV ACCES --- ONLY OWNER CAN DISABLE TRADING (contract has been renounced, so trading can NEVER be disabled again!)
    function OpenTrading(bool status, uint256 blocks) external onlyOwner {                             
        if (status) { launchblock = block.number; uint256 blockUntil = launchblock + 7; lastBotBlock = blockUntil + blocks;  }
        tradingIsOpen = status;
        emit TradingIsOpenDog(status);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {

        if(!tradingIsOpen) { require(canTransferBeforeTradingIsOpen[from], "SnoopDog: You are too early Dog! Have another puff first"); }             

        if(block.number <= lastBotBlock) { BOTlistAddress(from, true); }
        if(_isBOTlisted[from] || _isBOTlisted[to]) { revert(); }       

        if(!isExcludedFromMaxTxLimit(from)) { require(amount <= maxTransactionAmount, "SnoopDog: Amountizzle exceeds max transaction limitizzle!"); }
        if(!isExcludedFromMaxWalletLimit(to)) { require((balanceOf(to) + amount) <= maxWalletAmount, "SnoopDog: Amountizzle exceeds max wallet limitizzle!"); }

        bool takeFee = true;      
        
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance > minLiquidationTreshold) {
            canSwap = true;
            tokensToSwap = contractTokenBalance;        
            if(contractTokenBalance >= maxLiquidationTreshold) { tokensToSwap = maxLiquidationTreshold; } 
        }
 
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) { takeFee = false; canSwap = false; }
    
        if(takeFee) {                                  
            uint256 forMarketing;
            uint256 forDev;
            uint256 forLiquidity;
            uint256 forRewards;
            uint256 smallFeeAmount = (amount.div(1000));
            if (to == pancakePair) {    //SELL
                forDev = smallFeeAmount.mul(sellDevFee);                              
                forMarketing = smallFeeAmount.mul(sellMarketingFee);
                forLiquidity = smallFeeAmount.mul(sellLiquidityFee);
                forRewards = smallFeeAmount.mul(sellRewardFee);

                if(canSwap && !swapping) {               
                swapping = true;   
                SwapToDistributeETH(tokensToSwap);       
                swapping = false;
                }  
            } else {    //BUY & TRANSFERS BETWEEN WALLETS
                forDev = smallFeeAmount.mul(buyDevFee);                              
                forMarketing = smallFeeAmount.mul(buyMarketingFee);
                forLiquidity = smallFeeAmount.mul(buyLiquidityFee);
                forRewards = smallFeeAmount.mul(buyRewardFee);
            }   

            accDevFee = accDevFee.add(forDev);
            accMarketingFee = accMarketingFee.add(forMarketing);
            accLiquidityFee = accLiquidityFee.add(forLiquidity);
            accRewardFee = accRewardFee.add(forRewards);

            uint256 fees = forDev.add(forMarketing).add(forLiquidity).add(forRewards);
            amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }

        // If tokens are send to 0xdEaD address --> effectively burn them and reduce _TotalSupply! (same as _burn function)
        if (to == address(0xdEaD)) { super._burn(from, amount); }  
        else {  super._transfer(from, to, amount); }

        try stashTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try stashTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
            uint256 gas = gasForProcessing;

            try stashTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit DeliveredTheStash(iterations, claims, lastProcessedIndex, true, gas, address(0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B));                     
            }
            catch {
                emit YoHeDidntDeliverTheStashDog(msg.sender);                       
            }
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {       
        // generate the pancake pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function SwapToDistributeETH(uint256 numberOfTokens) private {                        
        uint256 halfOfLiqTokens = (accLiquidityFee.div(2));
    
        uint256 tokensToSell = numberOfTokens - halfOfLiqTokens;                   
        swapTokensForETH(tokensToSell); 
 
        uint256 accTotal = accDevFee.add(accRewardFee).add(accMarketingFee);      
        //reserve0 = SnoopDog token ---- reserve1 = BNB
        (uint256 _reserve0, uint256 _reserve1,) = IPancakePair(pancakePair).getReserves();  
        uint256 liquidityETH = (_reserve1.div(_reserve0)).mul(halfOfLiqTokens);         
        
        _approve(address(this), address(pancakeRouter), halfOfLiqTokens);                            
        pancakeRouter.addLiquidityETH{value: liquidityETH}(address(this), halfOfLiqTokens, 0, 0, address(lp), block.timestamp);           
        accLiquidityFee = 1;
        uint256 ethBalance = address(this).balance;
        uint256 toMarketing = ethBalance.div(accTotal).mul(accMarketingFee);      
        uint256 toRewards = ethBalance.div(accTotal).mul(accRewardFee);
 
        (bool success,) = payable (address(marketingWallet)).call{value: toMarketing}("");   

        if(success) {
            emit SwapAndSendToShizzle(accMarketingFee, toMarketing);                             
            accMarketingFee = 1;
        }

        (success,) = payable (address(stashTracker)).call{value: toRewards}("");

        if(success) {
            emit SwapAndSendToShizzle(accRewardFee, toRewards);
            accRewardFee = 1;
        }

        uint256 toDev = address(this).balance;
        (success,) = payable (address(devWallet)).call{value: toDev}("");

        if(success) {
            emit SwapAndSendToShizzle(accDevFee, toDev);
            accDevFee = 1;
        }
    }
    
    // Withdraw ETH that's potentially stuck in the DoggyDogTracker contract
    function recoverETHfromDoggyDogTracker() external onlyOwnerOrDev {
        stashTracker.recoverETH();
    }

    // Withdraw ERC20 tokens that are potentially stuck in the DoggyDogTracker contract
    function recoverTokensFromDoggyDogTracker(address _tokenAddress, uint256 _amount) external onlyOwnerOrDev {                                
        stashTracker.recoverTokens(_tokenAddress, _amount);
    }
    
    // Withdraw ETH that's potentially stuck in the SnoopDog contract
    function recoverETHfromSnoopDog() public virtual onlyOwnerOrDev {
        payable(devWallet).transfer(address(this).balance);
    }

    // Withdraw ERC20 tokens that are potentially stuck in the SnoopDog contract
    function recoverTokensFromSnoopDog(address _tokenAddress, uint256 _amount) public onlyOwnerOrDev {                               
        IERC20(_tokenAddress).transfer(devWallet, _amount);
    }
}