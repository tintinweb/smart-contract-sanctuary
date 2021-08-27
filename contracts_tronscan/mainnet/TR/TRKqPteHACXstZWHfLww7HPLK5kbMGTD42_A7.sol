//SourceUnit: a7.sol


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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


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


pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.5.0;


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply;
    
    struct Burn {
		address user;
		uint256 a7amount;
        uint256 timestamp;
	}
    

    Burn[] burns;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function burn(uint256 value) public returns (bool) {
        _burn(msg.sender, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }
     function burnFrom(address account, uint256 amount) public returns (bool) {
        require( _balances[account] > amount,"It's not enough A7 Token");
        _burnFrom(account,amount);
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
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
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        burns.push(Burn(account,value,block.timestamp));
        
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
    
}



/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */

//*******************************************************************//
//------------------         Token interface        -------------------//
//*******************************************************************//

    contract TetherToken {
       function transfer(address to, uint value) public;
       function transferFrom(address from, address to, uint value) public  returns (bool);
       function balanceOf(address who) public view returns (uint256);
    }

contract A7 is ERC20, ERC20Detailed {
    
    address public  USDTToken = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;
    
    uint256 public _locked;
    uint256 private _lastTime;
    address private _suanli;
    address private _productor;
    uint256 private _days;
    uint256 private _turn;
    uint256 private _price;
    uint256 public _sourceTotalSupply;
    address private _owner;
    uint256 private _release;
    bool private _sellflag;
    bool private _buyflag;
    
	TetherToken tether;

    constructor () public ERC20Detailed("A7Token", "A7", 6) {
         _owner = msg.sender;
         _productor= msg.sender;
         _suanli= msg.sender;
         _price= 10000;
         _lastTime = 1629907199;
        _totalSupply = 200000000 * (10 ** uint256(decimals()));
        _locked = 200000000 * (10 ** uint256(decimals()));
        _release=16666 * (10 ** uint256(decimals()));
        _sourceTotalSupply = 200000000 * (10 ** uint256(decimals()));
        _turn = 0;
        _days =0;
        _balances[msg.sender]=_totalSupply*15/100;
        _locked =_totalSupply.sub(_balances[msg.sender]);
        _sellflag=false;
        _buyflag=false;
        tether = TetherToken(USDTToken);
            

    }

    function () external payable {
    }


    function issue() public returns (bool){
        if(block.timestamp.sub(_lastTime) < 86400){
            return true;
        }

        if(_locked<_release){
            return true;
        }
        _locked = _locked.sub(_release);
        uint256 amount1 = _release.div(10);
        uint256 amount2 = _release.sub(amount1)  ;
        _balances[_productor] = _balances[_productor].add(amount1);
        _balances[_suanli] = _balances[_suanli].add(amount2);
        uint256 nowturn = _days/360;
        if(nowturn > _turn){
            _turn = nowturn;
            _release = _release*9/10;
        }

        _lastTime = _lastTime.add(86400);
        _days = _days.add(1);
        emit Transfer(address(0), _suanli, _release);
        return true;
    }


    //usdt->A7
    function buytoken(uint256 usdtAmount) public returns (bool){
        uint256 a7Amount=usdtAmount.mul(10000).div(_price);
        uint256 nodeAmount=usdtAmount.div(10);
        require(_buyflag==true);
        require(_locked>a7Amount, "It's not enough A7 Token");
        uint usdt = tether.balanceOf(msg.sender);
        require(usdt>usdtAmount, "It's not enough USDT Token");
        require( tether.transferFrom(msg.sender, address(this), usdtAmount),"token transfer failed");
        _balances[msg.sender]=_balances[msg.sender].add(a7Amount);
        _locked = _locked.sub(a7Amount);
        emit Transfer(address(this), msg.sender, a7Amount);
        tether.transfer(_productor, nodeAmount);
        issue();
        return true;
    }
     //A7->usdt
    function selltoken(uint256 a7Amount) public returns (bool){
        uint256 usdtAmount=a7Amount.mul(_price).div(10000).mul(9).div(10);
        uint256 burnAmount=a7Amount.div(10);
        uint256 addAmount=a7Amount.sub(burnAmount);

        require(_sellflag==true);
        require( _balances[msg.sender] >= a7Amount,"It's not enough A7 Token");
        require( a7Amount >= 10*(10**6),"10 A7 start");
       
        require(tether.balanceOf(address(this)) >= usdtAmount,"It's not enough usdt Token");
        tether.transfer(msg.sender, usdtAmount);
        _balances[msg.sender]=_balances[msg.sender].sub(addAmount);
        emit Transfer( msg.sender, address(this),addAmount);
        _locked = _locked.add(addAmount);
        _burn(msg.sender,burnAmount);
        issue();
        return true;
    }

    
    function getSuanli() public view returns (address){
        return _suanli;
    }
    
    function getProductor() public view returns (address){
        return _productor;
    }

    function getA7price() public view returns (uint256){
        return _price;
    }


    function setprice(uint a7price) public returns (bool){
        if(msg.sender == _owner){
            _price=a7price;
        }
        return true;
    }
    function getBurnInfo( uint256 index) public view returns(address, uint256, uint256) {
	    
		return (burns[index].user, burns[index].a7amount, burns[index].timestamp);
	}
    function getBurnLength() public view returns(uint256) {
		return burns.length;
	}

    function setbuyflag(bool flag) public returns (bool){
        if(msg.sender == _owner){
            _buyflag=flag;
        }
        return true;
    }

    function setsellflag(bool flag) public returns (bool){
        if(msg.sender == _owner){
            _sellflag=flag;
        }
        return true;
    }

      function getsellflag() public view returns(bool) {
		return _sellflag;
	}

     function getbuyflag() public view returns(bool) {
		return _buyflag;
	}

    function bindSuanli(address addressSuanli) public returns (bool){
        if(msg.sender == _owner){
            _suanli = addressSuanli;
        }
        return true;
    }
    
    function bindProductor(address addressProductor) public returns (bool){
        if(msg.sender == _owner){
            _productor = addressProductor;
        }
        return true;
    }
    
    function bindUsdt(address addressUsdt) public returns (bool){
        if(msg.sender == _owner){
            USDTToken = addressUsdt;
            tether = TetherToken(USDTToken);
        
        }
        return true;
    }
    
    function bindOwner(address addressOwner) public returns (bool){
        if(msg.sender == _owner){
            _owner = addressOwner;
        }
        return true;
    }



}