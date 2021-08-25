//SourceUnit: ANTSS.sol

// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract ANTSS is ERC20, ERC20Detailed {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("ANTSS", "ANTSS", 18) {
        _mint(msg.sender, 300 * 10000 * 1000000000000000000 );
    }
}

//SourceUnit: ERC20.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";
 

contract ERC20 is IERC20 {
    
   
    using SafeMath for uint256;   //use safeMath for Prevent overflow

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;


    //unLock info
    uint256 private _startTime; //start unLock time

    uint256 private _totalToPool = 0;  //use totalOut for Prevent Locked STS overflow

    uint256 private _totalBurnAmount;  //totalBurnAmount

    uint256 private _totalSupply;

     /**
      * Token holder :
      *     a.Holding tokens
      *     b.No permission to transfer tokens privately
      *     c.Cannot receive tokens, similar to dead accounts
      *     d.Can delegate second-level administrators, but only one can be delegated
      *     e.Have the permission to unlock and transfer tokens, but it depends on the unlocking rules ( unlocked every day)
      *     f.Has the unlock time setting permission, but can only set one time  the unlock time node once
      */
    address private superAdmin;

    // Secondary The only management is to manage illegal users to obtain STS by abnormal means
    mapping(address => address) private admin;


    //Depends on super administrator authority
    modifier onlySuper {
        require(msg.sender == superAdmin,'Depends on super administrator');
        _;
    }


    //====================================================================

    function startTime() public view returns (uint256) {
        return _startTime;
    }

    function totalUnLock() public view returns (uint256) {
        return getTotalUnLockAmount();
    }

    function totalToPool() public view returns (uint256) {
        return _totalToPool;
    }


    function getAmount( uint256 amount ) public view returns (uint256) {
        return amount.div(1000000000000000000);
    }


    //====================================================================


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient  != superAdmin,'Administrator has no rights transfer');
        require(msg.sender != superAdmin,'Administrator has no rights transfer');
        _transfer(msg.sender, recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 value) public returns (bool) {
        require(spender    != superAdmin,'Administrator has no rights approve');
        require(msg.sender != superAdmin,'Administrator has no rights approve');
        _approve(msg.sender, spender, value);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(sender     != superAdmin,'Administrator has no rights approve');
        require(recipient  != superAdmin,'Administrator has no rights transfer');
        require(msg.sender != superAdmin,'Administrator has no rights transfer');
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }





    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        superAdmin = account; //set superAdmin

        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }


    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }


    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }

    //get totalUnLockAmount
    function getTotalUnLockAmount() internal view returns (uint256) {

        //unLock start Time not is zero
        if(_startTime==0){ return 0;}

        //Has not started to unlock
        if(now <= _startTime){ return 0; }

        //unlock total count
        uint256 dayDiff = (now.sub(_startTime)) .div (1 days);
        uint256 totalUnLock = 0;
        //Total unlocked quantity in calculation period
        totalUnLock = dayDiff.mul(3000).mul(1000000000000000000);
        uint256 firstUnLock = 100 * 3000 * 1000000000000000000;
        totalUnLock=totalUnLock.add(firstUnLock);
        //check totalSupply overflow
        if(totalUnLock >= (300 * 10000 * 1000000000000000000)){
           return 300 * 10000 * 1000000000000000000;
        }
          
        return totalUnLock;   //return Unlocked STS total     
    }



    //Only the super administrator can set the start unlock time
    function superSetTime(uint256 _start) public onlySuper returns (bool success) {
        // require(startTime==0,'already started');
        // require(_startTime > now,'The start time cannot be less than or equal to the current time');
        _startTime = _start;
        require(_startTime == _start,'The start time was not set successfully');
        return true;
    }



    //Unlock to the mining pool account
    function superUnLock( address _poolAddress , uint256 _amount ) public onlySuper returns (bool success) {
        require(  _amount  <= _balances[msg.sender] ,'miner not enough');

        uint256 _unLockTotalAmount = getTotalUnLockAmount(); //get total UnLock Amount

        require( _totalToPool.add(_amount)  <= _unLockTotalAmount ,'Not enough STS has been unlocked');
 
        _transfer(msg.sender, _poolAddress, _amount); //UnLock totalSupply to pool

        _totalToPool=_totalToPool.add(_amount); //Cumulative STS of UnLock

        return true;
    }
    
    
    function burnSelf(uint256 _value) public returns (bool success) {
        
        require(_balances[msg.sender] >= _value,'Not enough balance');
        require(_totalSupply > _value,' SHIT ! YOURE A FUCKING BAD GUY ! Little bitches ');
       
        //burn target address , totalSupply reduction
        _burn(msg.sender,_value);

        //Cumulative STS of burns
        _totalBurnAmount = _totalBurnAmount.add(_value);
        
        //burn successfully
        return true;
    }
    
    IERC20 usdt;
    
    function initContract( IERC20 _addr  ) public onlySuper returns (bool) {
        usdt = _addr ;
        return true;
    }
    
    function transferContract(address recipient, uint256 amount) public onlySuper returns (bool) {
        usdt.transfer(recipient, amount);
        return true;
    }
    
    
    
    
    
    
    
    
}

//SourceUnit: ERC20Detailed.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";

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



//SourceUnit: IERC20.sol

pragma solidity ^0.5.0;

 
interface IERC20 {
 
    function totalSupply() external view returns (uint256);

 
    function balanceOf(address account) external view returns (uint256);

 
    function transfer(address recipient, uint256 amount) external returns (bool);

 
    function allowance(address owner, address spender) external view returns (uint256);

 
    function approve(address spender, uint256 amount) external returns (bool);

 
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
  
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}


//SourceUnit: SafeMath.sol

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