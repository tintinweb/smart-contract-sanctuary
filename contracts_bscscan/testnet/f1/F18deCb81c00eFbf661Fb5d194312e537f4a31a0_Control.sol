// File: SafeMath.sol

pragma solidity ^0.8.0;

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

// File: IERC20.sol

pragma solidity ^0.8.0;

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

// File: Control.sol

// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.8.0;



/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract Control {
    
    using SafeMath for uint256;
    IERC20 public mt;
    address public owner;
    uint256 minBnbValue = 1000000000000000;
    uint256 maxBnbValue = 5000000000000000000;
    uint256 public ktnum = 0;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _rewardTokenbalances;
    mapping (address => uint256) private _rewardBnbbalances;
    mapping (address => address) private _userShip;
    
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public payable {
        owner = msg.sender;
        mt = IERC20(0xd40b8de58139136563bFDE9f3FEE9799A8bFC5Cd);
        // mt.balanceOf{value:1}(owner);
    }
    
    modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		owner = newOwner;
	}
    
    function balanceOf(address account) public view returns (uint256) {
        return mt.balanceOf(account);
    }
    
    function balanceKtOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function getMeBnb() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getRewardToken(address account) public view returns (uint256) {
        return _rewardTokenbalances[account];
    }
    
    function getUserShip(address account) public view returns (address) {
        return _userShip[account];
    }
    
    function getNowTime() public view returns (uint256) {
        return block.timestamp;
    }
    
    
    function getUserData(address account) public view returns (address,uint256,uint256,uint256,uint256,uint256) {
        uint256 bnbNum = account.balance;
        return (_userShip[account],bnbNum,_balances[account],_rewardTokenbalances[account],balanceOf(account),_rewardBnbbalances[account]);
    }
    function withDrawKt() public  returns (uint256) {
        address account = msg.sender;
        require(ktnum <= 1000, "ERC20: amount over");
        require( _balances[account] == 0, "ERC20: have withDraw");
        _balances[account] = 50000000000000000000;
        mt.transfer(account,50000000000000000000);
        ktnum = ktnum.add(1);
        return 50000000000000000000;
    }
    function userShip(address parent) public returns (bool){
		require(parent != address(0), "Control: userShip is not zero");
		require(_userShip[msg.sender]== address(0), "Control: parent is have");
		_userShip[msg.sender] = parent;
		return true;
	}
    function swap() payable public returns (bool){
        uint256 bnbAmount = msg.value;
        require(bnbAmount >= minBnbValue, "ERC20: bnbAmount too small");
        require(bnbAmount <= maxBnbValue, "ERC20: bnbAmount too big");
        mt.transfer(msg.sender,bnbAmount.mul(6000));
        //rewardParent(msg.sender,bnbAmount);
        return true;
    }
    function rewardParent(address account,uint256 bnbAmount) internal{
        address parent =  _userShip[account];
        if(parent!=address(0)){
            _rewardTokenbalances[parent] = _rewardTokenbalances[parent].add(bnbAmount.mul(6000).mul(12).div(100));
            // payable(parent).transfer(bnbAmount.mul(12).div(100));
            _rewardBnbbalances[parent] = _rewardBnbbalances[parent].add(bnbAmount.mul(12).div(100));
            address gparent =  _userShip[parent];
            if(gparent!=address(0)){
                 _rewardTokenbalances[gparent] = _rewardTokenbalances[gparent].add(bnbAmount.mul(6000).mul(6).div(100));
                //  payable(gparent).transfer(bnbAmount.mul(6).div(100));
                 _rewardBnbbalances[gparent] = _rewardBnbbalances[gparent].add(bnbAmount.mul(6).div(100));
            }
        }
    }
    
    function withDraw() payable onlyOwner public returns (bool){
        payable(msg.sender).transfer(getMeBnb());
        return true;
    }
    
    function withDraw(uint256 bnbAmount) payable onlyOwner public returns (bool){
        payable(msg.sender).transfer(bnbAmount);
        return true;
    }
    
    function withDrawToken(uint256 tokenAmount) public onlyOwner returns (bool){
        mt.transfer(msg.sender,tokenAmount);
        return true;
    }
    function userWithDrawBnb() payable public returns (bool){
        payable(msg.sender).transfer(_rewardBnbbalances[msg.sender]);
        _rewardBnbbalances[msg.sender] = 0;
        return true;
    }
    function userWithDrawRewardToken() payable public returns (bool){
        mt.transfer(msg.sender,_rewardTokenbalances[msg.sender]);
        _rewardTokenbalances[msg.sender] = 0;
        return true;
    }
    
    receive() external payable {}
}