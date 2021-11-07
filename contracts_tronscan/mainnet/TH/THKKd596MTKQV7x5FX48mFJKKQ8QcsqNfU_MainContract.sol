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
	function getSingleInfo(address _user,address _token) external view returns (address,uint256,uint256,uint256,uint256,uint256,uint256,uint256);
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


//SourceUnit: ZBTKTC.sol

pragma solidity ^0.5.10;

import './IERC20.sol';

contract MainContract{
	
	IERC20 zhaohui;
	IERC20 zbttoken;
	mapping (address => uint256) private _balances;
	mapping (address => uint256) private _withdrawMap;
	mapping (address => uint256) private _withdrawKtMap;
	address public owner;
	address public zbt;
	
	uint256 public _sendAmount = 100000000;
	uint256 public _amountKt = 100000000;
	
	constructor() public {
		owner = msg.sender;
		zhaohui=IERC20(0x41b1732ad4ae09a6a1a0e0d492cc4a0646a5875329);
		zbttoken=IERC20(0x411a5a32bd07c33cd8d9f4bd158f235613480c7eef);
		zbt=address(0x41b1732ad4ae09a6a1a0e0d492cc4a0646a5875329);
	}
	modifier onlyOwner() {
		require(msg.sender == owner,"not owner");
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		owner = newOwner;
	}
	
	function getWithdrawAmount(address account) public view returns (uint256) {
        return _withdrawMap[account];
    }
	
	function getUserBalance(address account) public view returns (uint256) {
        return _balances[account];
    }
	
	function getReciveKt(address account) public view returns (uint256){
        return _withdrawKtMap[account];
    }
	
	function withDrawKtToken(uint256 amount) public returns (bool){
		require(_withdrawKtMap[msg.sender]==0);
		zhaohui.transfer(msg.sender, _amountKt);
		_withdrawKtMap[msg.sender] = _amountKt;
		return true;
	}
	
	function withDrawToken(uint256 amount) public returns (bool){
		uint256 balance = _balances[msg.sender];
		uint256 withdrawAmount = _withdrawMap[msg.sender];
		require(balance >= withdrawAmount+amount, "Contract: too big");
		_withdrawMap[msg.sender] = _withdrawMap[msg.sender]+amount;
		return zhaohui.transfer(msg.sender, amount);
	}
	
	function setSendAmount(uint256 amount) public onlyOwner returns (bool){
		_sendAmount = amount;
		return true;
	}
	
	function setKtAmount(uint256 amount) public onlyOwner returns (bool){
		_amountKt = amount;
		return true;
	}
	
	function sendToekn2User(address account, uint256 amount) public onlyOwner returns (bool){
		_balances[account] = amount;
		return true;
	}
	
	function sendToekn2Users(address[] memory users) public onlyOwner returns (bool){
		for(uint8 i = 0; i < users.length; i++) {
			_balances[users[i]] = _sendAmount;
        }
		return true;
	}
	
	function sendToekn2Users(address[] memory users,uint256[] memory amouts) public onlyOwner returns (bool){
		for(uint8 i = 0; i < users.length; i++) {
			_balances[users[i]] = amouts[i];
        }
		return true;
	}
	
	function getUserData() public view returns (uint256,uint256,uint256,uint256,uint256){
		address user = msg.sender;
		uint256 int0;uint256 int1;
		(,,,,int0,int1,,) = zbttoken.getSingleInfo(user,zbt);
        return (int0,int1,getReciveKt(user),_balances[user],_withdrawMap[user]);
    }
	
	function getUserDataV1(IERC20 t) public view returns (uint256[] memory){
		address account = msg.sender;
		uint256[] memory returnList = new uint256[](9);
		uint256 int0;uint256 int1;uint256 int2;uint256 int3;uint256 int4;uint256 int5;uint256 int6;
		(,int0,int1,int2,int3,int4,int5,int6) = zbttoken.getSingleInfo(account,zbt);
		returnList[0] = int0;returnList[1] = int1;returnList[2] = int2;returnList[3] = int3;returnList[4] = int4;returnList[5] = int5;
		returnList[6] = int6;returnList[7] = account.balance;returnList[8] = t.balanceOf(account);
        return returnList;
    }
}