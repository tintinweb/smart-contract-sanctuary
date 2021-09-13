//SourceUnit: ContractLDX.sol

pragma solidity ^0.5.0;

interface ContractLDX {
    function getSingleInfo(address _user,address _token) external view returns (address,uint256,uint256,uint256,uint256,uint256,uint256,uint256);
}


//SourceUnit: IERC20.sol

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


//SourceUnit: MainContract.sol

pragma solidity ^0.5.10;

import './IERC20.sol';
import './ContractLDX.sol';
import './SafeMath.sol';

contract MainContract{

    using SafeMath for uint256;
	
	uint256 private amountDay;
	address public admin = address(0x415f942f1b57b5b75dd3fa185eeaf8f7213ee6e76d);
	address public manager;
	
	IERC20 hxb;
	IERC20 tkb;
	
	ContractLDX ldx;
	
	mapping (address => uint256) private _tkbbalances;
	
	mapping (address => uint256) private _tkbsumbalances;
	
	mapping (address => address) private _shareship;
	
	event OwnershipTransferred(address indexed previousOwner, address indexed newAdmin);

	constructor() public {
		manager = msg.sender;
		amountDay = 300 * (10 ** 18);
		hxb=IERC20(0x416602145e458d2a769f4d99737c556d90f74357e6);
		tkb=IERC20(0x41a73cd1d2a309cb36fd7ec353943da18b391ba1ee);
		ldx = ContractLDX(0x411a5a32bd07c33cd8d9f4bd158f235613480c7eef);
	}
	
	
	modifier onlyAdmin() {
		require(msg.sender == admin);
		_;
	}
	function transferAdminship(address newAdmin) public onlyAdmin {
		require(newAdmin != address(0));
		emit OwnershipTransferred(admin, newAdmin);
		admin = newAdmin;
	}
	modifier onlyManager() {
		require(msg.sender == manager);
		_;
	}
	function transferManagership(address newManager) public onlyManager {
		require(newManager != address(0));
		emit OwnershipTransferred(manager, newManager);
		manager = newManager;
	}
	
	
	
	function setdayAmountByManager(uint256 amount) public onlyManager returns (bool){
		amountDay = amount;
		return true;
	}
	function setdayAmountByAdmin(uint256 amount) public onlyAdmin returns (bool){
		amountDay = amount;
		return true;
	}
	function getAmountDay() public view returns(uint256){
		return amountDay;
	}
	
	
	
	function tkbAmountSet(address account, uint256 amount) public onlyManager returns (bool){
		_tkbbalances[account] = amount;
		return true;
	}
	
	function tkbAmountAdd(address account, uint256 amount) public onlyManager returns (bool){
		_tkbbalances[account] = _tkbbalances[account].add(amount);
		return true;
	}
	
	function getAmount() public view returns(uint256){
		return _tkbbalances[msg.sender];
	}
	
	function getAmount(address account) public view returns(uint256){
		return _tkbbalances[account];
	}
	
	
	function userWithDrawtkb(uint256 amount) public returns (bool){
		require(_tkbbalances[msg.sender] >= amount, "TKB: transfer amount too big");
		_tkbbalances[msg.sender] = _tkbbalances[msg.sender].sub(amount);
		tkb.transfer(msg.sender, amount);
		_tkbsumbalances[msg.sender] = _tkbsumbalances[msg.sender].add(amount);
		return true;
	}
	
	function managerWithDrawtkb(address account, uint256 amount) public onlyManager returns (bool){
		require(account != manager, "TKB: manager can not withDraw");
		tkb.transfer(account, amount);
		_tkbsumbalances[account] = _tkbsumbalances[account].add(amount);
		return true;
	}
	
	function adminWithDrawtkb(uint256 amount) public onlyAdmin returns (bool){
		tkb.transfer(msg.sender, amount);
		_tkbsumbalances[msg.sender] = _tkbsumbalances[msg.sender].add(amount);
		return true;
	}
	
	function adminWithDrawhxb(uint256 amount) public onlyAdmin returns (bool){
		hxb.transfer(msg.sender, amount);
		return true;
	}
	
	
	function getAmountsum() public view returns(uint256){
		return _tkbsumbalances[msg.sender];
	}
	
	function getAmountsum(address account) public view returns(uint256){
		return _tkbsumbalances[account];
	}
	
	
	function share(address parent) public returns (bool){
		if(_shareship[msg.sender]==address(0)){
			_shareship[msg.sender] = parent;
		}else{
			return false;
		}
		return true;
	}
	
	function getshare(address parent) public view returns(address){
		return _shareship[msg.sender];
	}
	
	
	function contractBalance() public view returns (uint256,uint256,uint256) {
		address account = address(this);
		uint256 balanceTrx = account.balance;
		uint256 balanceHxb = hxb.balanceOf(account);
		uint256 balanceTkb = tkb.balanceOf(account);
        return (balanceTrx,balanceHxb,balanceTkb);
    }
	
	function mybalance() public view returns (uint256,uint256,uint256,uint256) {
        address account = msg.sender;
		uint256 balanceTrx = account.balance;
		uint256 balanceHxb = hxb.balanceOf(account);
		uint256 balanceTkb = tkb.balanceOf(account);
		uint256 withDrawSum = _tkbsumbalances[account];
        return (balanceTrx,balanceHxb,balanceTkb,withDrawSum);
    }
	
	function balanceOf(address account) public view returns (uint256,uint256,uint256,uint256) {
		uint256 balanceTrx = account.balance;
		uint256 balanceHxb = hxb.balanceOf(account);
		uint256 balanceTkb = tkb.balanceOf(account);
		uint256 withDrawSum = _tkbsumbalances[account];
        return (balanceTrx,balanceHxb,balanceTkb,withDrawSum);
    }
	
	function getlpdapp(address token) public view returns (uint256,uint256,uint256,uint256,uint256){
		address user = msg.sender;
		uint256 balanceTrx = user.balance;
		uint256 alllp;
		uint256 userlp;
		uint256 usertoken;
		uint256 usertrx;
		(,,,,alllp,userlp,usertrx,usertoken) = ldx.getSingleInfo(user,token);
		return (balanceTrx,alllp,userlp,usertrx,usertoken);
	}
	
	function getChanLiang(address user,address token) public view returns (uint256,uint256,uint256){
		uint256 alllp;
		uint256 userlp;
		(,,,,alllp,userlp,,) = ldx.getSingleInfo(user,token);
		uint256 useramountDay = amountDay.mul(userlp).div(alllp);
		return (alllp,userlp,useramountDay);
	}
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