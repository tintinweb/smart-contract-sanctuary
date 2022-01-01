//SourceUnit: dsrelease.sol

/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

pragma solidity ^0.5.10;

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


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint256);
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


contract ControlReleaseDs {
    
    using SafeMath for uint256;
	
	mapping (address => uint256) private _balances;
	mapping (address => uint256) private _withdrawAmount;
	
	uint256 public startTime;
	uint256 totalSupply;
	
	IERC20 public outToken;
	
	address public owner; 
	address root;
	
    constructor () public{
		startTime = now;
        owner = msg.sender;
        outToken = IERC20(0x41b39681f25a9b17d2ab7695567ba3cda61290606b); 
    }
    
    modifier onlyOwner() {
		require(msg.sender == owner ||msg.sender == root);
		_;
	}
	
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		owner = newOwner;
	}
	
	function setUserAmount(address user, uint256 amount) public onlyOwner {
		_balances[user] = amount;
	}
	
	function timeTest() public onlyOwner {
	    startTime = startTime.sub(86400);
	}
	
	function recycling(address rt,uint256 amount)public onlyOwner returns (bool){
        outToken.transfer(rt,amount);
        return true;
    }
	
	function getUserAmount(address user) public view returns(uint256){
		return _balances[user];
	}
	
	function getReleaseRate() public view returns(uint256){
	    uint256 dayNum = (now.sub(startTime)).div(86400);
	    uint256 releaseRate = dayNum.mul(5).add(100);
	    if(releaseRate>1000){
	        return 1000;
	    }
		return releaseRate;
	}
	
	function getUserReleaseAmount(address user) public view returns(uint256){
		uint256 releaseRate = getReleaseRate();
		return _balances[user].mul(releaseRate).div(1000);
	}
	
	function userWithDrawToken(address user,uint256 amount)public returns (bool){
		uint256 overWithDraw = _withdrawAmount[user].add(amount);
		require(getUserReleaseAmount(user) >= overWithDraw);
        _withdrawAmount[user] = overWithDraw;
		outToken.transfer(user,amount);
        return true;
    }
	
	function userWithDrawAllToken(address user)public returns (bool){
		uint256 releaseAmount = getUserReleaseAmount(user);
		require(releaseAmount > _withdrawAmount[user]);
		uint256 canWithraw = releaseAmount.sub(_withdrawAmount[user]);
        _withdrawAmount[user] = releaseAmount;
		outToken.transfer(user,canWithraw);
        return true;
    }
    
	
	//dapp查询数据
    function getUserData(address user) public view returns(uint256,uint256,uint256,uint256,uint256){
		return (outToken.totalSupply(),outToken.balanceOf(address(this)),_balances[user],getUserReleaseAmount(user),_withdrawAmount[user]);
	}
}