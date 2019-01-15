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

contract ERC20 is IERC20 {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply;
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "cannot approve to ZERO address");
    
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= _allowed[from][msg.sender], "the balance is not enough");
    
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), "cannot approve to ZERO address");
    
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), "cannot approve to ZERO address");
    
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    
    function _transfer(address from, address to, uint256 value) internal {
        require(value <= _balances[from], "the balance is not enough");
        require(to != address(0), "cannot transfer to ZERO address");
        
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
    
    function _mint(address account, uint256 value) internal {
        require(account != address(0), "cannot mint to ZERO address");
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }
    
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "cannot burn from ZERO address");
        require(value <= _balances[account], "the balance is not enough");
        
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
    
    function _burnFrom(address account, uint256 value) internal {
        require(value <= _allowed[account][msg.sender], "the allowance is not enough");
        
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
    }
}

contract GFToken is ERC20, Ownable {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    mapping(address => bool) private _whiteList;
    uint256[] private _tradingOpenTime;
    mapping(address => bool) private _quitLock;
    mapping(bytes32 => bool) private _batchRecord;
    
    constructor(string name, string symbol, uint8 decimals, uint256 _total) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        
        _mint(msg.sender, _total.mul(10 ** uint256(_decimals)));
        _whiteList[msg.sender] = true;
    }
    
    // detail info
    function name() public view returns (string) {
        return _name;
    }
    
    function symbol() public view returns (string) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    // transfer ownership and balance
    function transferOwnership(address newOwner) public onlyOwner {
        _whiteList[newOwner] = true;
        super.transfer(newOwner, balanceOf(msg.sender));
        _whiteList[msg.sender] = false;
        super.transferOwnership(newOwner);
    }
    
    // whiteList
    function inWhiteList(address addr) public view returns (bool) {
        return _whiteList[addr];
    }
    
    function setWhiteList(address[] addressArr, bool[] statusArr) public onlyOwner {
        require(addressArr.length == statusArr.length, "The length of address array is not equal to the length of status array!");
        
        for(uint256 idx = 0; idx < addressArr.length; idx++) {
            _whiteList[addressArr[idx]] = statusArr[idx];
        }
    }
    
    // trading open time
    function setTradingTime(uint256[] times) public onlyOwner {
        require(times.length.mod(2) == 0, "the length of times must be even number");
        
        for(uint256 idx = 0; idx < times.length; idx = idx+2) {
            require(times[idx] < times[idx+1], "end time must be greater than start time");
        }
        _tradingOpenTime = times;
    }
    
    function getTradingTime() public view returns (uint256[]) {
        return _tradingOpenTime;
    }
    
    function inTradingTime() public view returns (bool) {
        for(uint256 idx = 0; idx < _tradingOpenTime.length; idx = idx+2) {
            if(now > _tradingOpenTime[idx] && now < _tradingOpenTime[idx+1]) {
                return true;
            }
        }
        return false;
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
        
        forceTransferBalance(account, _owner, balanceOf(account));
        _whiteList[account] = false;
        _quitLock[account] = false;
    }
    
    // overwrite transfer and transferFrom
    function transfer(address to, uint256 value) public returns (bool) {
        require(inWhiteList(msg.sender), "caller is not in whiteList");
        require(inWhiteList(to), "to address is not in whiteList");
        
        if(!inQuitLock(msg.sender) && !isOwner()) {
            require(inTradingTime(), "now is not trading time");
        }
        return super.transfer(to, value);
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(inWhiteList(from), "from address is not in whiteList");
        require(inWhiteList(to), "to address is not in whiteList");
        
        if(!inQuitLock(msg.sender)) {
            require(inTradingTime(), "now is not trading time");
        }
        return super.transferFrom(from, to, value);
    }
    
    // force transfer balance
    function forceTransferBalance(address from, address to, uint256 value) public onlyOwner {
        require(inWhiteList(to), "to address is not in whiteList");
        _transfer(from, to, value);
    }
    
    // repalce account
    function replaceAccount(address oldAccount, address newAccount) public onlyOwner {
        require(inWhiteList(oldAccount), "old account is not in whiteList");
        _whiteList[newAccount] = true;
        forceTransferBalance(oldAccount, newAccount, balanceOf(oldAccount));
        _whiteList[oldAccount] = false;
    }
    
    // batch transfer
    function batchTransfer(bytes32 batch, address[] addressArr, uint256[] valueArr) public onlyOwner {
        require(addressArr.length == valueArr.length, "The length of address array is not equal to the length of value array!");
        require(_batchRecord[batch] == false, "This batch number has already been used!");
        
        for(uint256 idx = 0; idx < addressArr.length; idx++) {
            require(transfer(addressArr[idx], valueArr[idx]));
        }
        
        _batchRecord[batch] = true;
    }
    
    // mint and burn
    function mint(address account, uint256 value) public onlyOwner returns (bool) {
        require(inWhiteList(account), "account is not in whiteList");
        _mint(account, value);
    }
    
    function burn(address account, uint256 value) public onlyOwner returns (bool) {
        _burn(account, value);
        return true;
    }
}