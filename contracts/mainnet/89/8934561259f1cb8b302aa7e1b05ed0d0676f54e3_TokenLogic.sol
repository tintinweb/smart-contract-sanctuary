pragma solidity ^0.4.24;

library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		if (a == 0) {
      		return 0;
    	}

    	c = a * b;
    	assert(c / a == b);
    	return c;
  	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
    	return a / b;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    	assert(b <= a);
    	return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    	c = a + b;
    	assert(c >= a);
    	return c;
	}
	
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address internal _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "you are not the owner!");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "cannot transfer ownership to ZERO address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ITokenStore {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    function transfer(address src, address dest, uint256 amount) external;
    function approve(address owner, address spender, uint256 amount) external;
    function mint(address dest, uint256 amount) external;
    function burn(address dest, uint256 amount) external;
}

/*
    TokenLogic
*/
interface ITokenLogic {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value, address owner) external returns (bool);
    function transferFrom(address from, address to, uint256 value, address spender) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue, address owner) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue, address owner) external returns (bool);
}

contract TokenLogic is Ownable, ITokenLogic {
    using SafeMath for uint256;
    
    ITokenStore private _tokenStore;
    address private _tokenFront;
    
    constructor(ITokenStore tokenStore, address tokenFront) public {
        _tokenStore = tokenStore;
        _tokenFront = tokenFront;
        _whiteList[msg.sender] = true;
    }
    
    // getters and setters for tokenStore and tokenFront
    function tokenStore() public view returns (address) {
        return _tokenStore;
    }
    
    function setTokenStore(ITokenStore newTokenStore) public onlyOwner {
        _tokenStore = newTokenStore;
    }
    
    function tokenFront() public view returns (address) {
        return _tokenFront;
    }
    
    function setTokenFront(address newTokenFront) public onlyOwner {
        _tokenFront = newTokenFront;
    }
    
    modifier onlyFront() {
        require(msg.sender == _tokenFront, "this method MUST be called by tokenFront");
        _;
    }
    
    modifier onlyFrontOrOwner() {
        require((msg.sender == _tokenFront) || isOwner(), "this method MUST be called by tokenFront or owner");
        _;
    }
    
    mapping(address => bool) private _whiteList;
    mapping(address => bool) private _quitLock;
    mapping(bytes32 => bool) private _batchRecord;
    uint256[] private _tradingOpenTime;

    // transfer ownership and balance
    function transferOwnership(address newOwner) public onlyOwner {
        _whiteList[newOwner] = true;
        _tokenStore.transfer(msg.sender, newOwner, _tokenStore.balanceOf(msg.sender));
        _whiteList[msg.sender] = false;
        super.transferOwnership(newOwner);
    }
    
    // whitelist
    function inWhiteList(address account) public view returns (bool) {
        return _whiteList[account];
    }
    
    function setWhiteList(address[] addressArr, bool[] statusArr) public onlyOwner {
        require(addressArr.length == statusArr.length, "The length of address array is not equal to the length of status array!");
        
        for(uint256 idx = 0; idx < addressArr.length; idx++) {
            _whiteList[addressArr[idx]] = statusArr[idx];
        }
    }
    
    // trading time
    function inTradingTime() public view returns (bool) {
        for(uint256 idx = 0; idx < _tradingOpenTime.length; idx = idx+2) {
            if(now > _tradingOpenTime[idx] && now < _tradingOpenTime[idx+1]) {
                return true;
            }
        }
        return false;
    }
    
    function getTradingTime() public view returns (uint256[]) {
        return _tradingOpenTime;
    }
    
    function setTradingTime(uint256[] timeArr) public onlyOwner {
        require(timeArr.length.mod(2) == 0, "the length of time arr must be even number");
        
        for(uint256 idx = 0; idx < timeArr.length; idx = idx+2) {
            require(timeArr[idx] < timeArr[idx+1], "end time must be greater than start time");
        }
        _tradingOpenTime = timeArr;
    }
    
    // quit
    function inQuitLock(address account) public view returns (bool) {
        return _quitLock[account];
    }
    
    function setQuitLock(address account) public onlyOwner {
        require(inWhiteList(account), "account is not in whiteList");
        _quitLock[account] = true;
    }
    
    function removeQuitAccount(address account) public onlyOwner {
        require(inQuitLock(account), "the account is not in quit lock status");
        
        _tokenStore.transfer(account, msg.sender, _tokenStore.balanceOf(account));
        _whiteList[account] = false;
        _quitLock[account] = false;
    }
    
    // implement for ITokenLogic
    function totalSupply() external view returns (uint256) {
        return _tokenStore.totalSupply();
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return _tokenStore.balanceOf(account);
    }
    
    function allowance(address owner, address spender) external view returns (uint256) {
        return _tokenStore.allowance(owner, spender);
    }
    
    function transfer(address from, address to, uint256 value) external onlyFront returns (bool) {
        require(inWhiteList(from), "sender is not in whiteList");
        require(inWhiteList(to), "receiver is not in whiteList");
        
        if(!inQuitLock(from) && from != owner()) {
            require(inTradingTime(), "now is not trading time");
        }
        
        _tokenStore.transfer(from, to, value);
        return true;
    }
    
    function forceTransferBalance(address from, address to, uint256 value) external onlyOwner returns (bool) {
        require(inWhiteList(to), "receiver is not in whiteList");
        _tokenStore.transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value, address owner) external onlyFront returns (bool) {
        _tokenStore.approve(owner, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value, address spender) external onlyFront returns (bool) {
        require(inWhiteList(from), "sender is not in whiteList");
        require(inWhiteList(to), "receiver is not in whiteList");
        
        if(!inQuitLock(from)) {
            require(inTradingTime(), "now is not trading time");
        }
        
        uint256 newAllowance = _tokenStore.allowance(from, spender).sub(value);
        _tokenStore.approve(from, spender, newAllowance);
        _tokenStore.transfer(from, to, value);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue, address owner) external onlyFront returns (bool) {
        uint256 newAllowance = _tokenStore.allowance(owner, spender).add(addedValue);
        _tokenStore.approve(owner, spender, newAllowance);
        
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue, address owner) external onlyFront returns (bool) {
        uint256 newAllowance = _tokenStore.allowance(owner, spender).sub(subtractedValue);
        _tokenStore.approve(owner, spender, newAllowance);
        
        return true;
    }
    
    // batch transfer
    function batchTransfer(bytes32 batch, address[] addressArr, uint256[] valueArr) public onlyOwner {
        require(addressArr.length == valueArr.length, "The length of address array is not equal to the length of value array!");
        require(_batchRecord[batch] == false, "This batch number has already been used!");
        
        for(uint256 idx = 0; idx < addressArr.length; idx++) {
            require(inWhiteList(addressArr[idx]), "receiver is not in whiteList");
            
            _tokenStore.transfer(msg.sender, addressArr[idx], valueArr[idx]);
        }
        
        _batchRecord[batch] = true;
    }
    
    // replace account
    function replaceAccount(address oldAccount, address newAccount) public onlyOwner {
        require(inWhiteList(oldAccount), "old account is not in whiteList");
        _whiteList[newAccount] = true;
        _tokenStore.transfer(oldAccount, newAccount, _tokenStore.balanceOf(oldAccount));
        _whiteList[oldAccount] = false;
    }
}

/*
    TokenFront
*/
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}