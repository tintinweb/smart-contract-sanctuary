/**
 *Submitted for verification at Etherscan.io on 2021-02-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

 contract Math {
    function add(uint256 x, uint256 y) pure internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function subtract(uint256 x, uint256 y) pure internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }
}

contract Auth {
    address observer = address(0);
    address owner = address(0);
    address admin = address(0);

    modifier isOwner {
        require(owner == msg.sender);
        _;
    }

    modifier isAdmin {
        require(owner == msg.sender || admin == msg.sender);
        _;
    }
    
    function setObserver(address _observer) public {
        require(observer == msg.sender);
        observer = _observer;
    }
    
    function setAdmin(address _admin) isOwner public {
        admin = _admin;
    }
    
    function setOwner(address _owner) public {
        require(observer == msg.sender);
        owner = _owner;
    }
    
    function managers() public view returns (address _owner, address _admin) {
        return (owner, admin);
    }
}

contract Manage is Auth {
    
    /**
     *  0 : init, 1 : limited, 2 : running, 3 : finishing
     */
    uint8 public status = 0;

    modifier isRunning {
        require(status == 2 || owner == msg.sender || admin == msg.sender || (status == 1 && (owner == msg.sender || admin == msg.sender)));
        _;
    }

    function limit() isAdmin public {
    	require(status != 1);
        status = 1;
    }
    
    function start() isAdmin public {
    	require(status != 2);
        status = 2;
    }
    
    function close() isAdmin public {
    	require(status != 3);
        status = 3;
    }
}

interface EIP20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TokenBase is EIP20Interface, Manage, Math {
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    event Burn(address indexed from, uint256 value);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    constructor() {
        owner = msg.sender;
        admin = msg.sender;
        observer = msg.sender;
    }
    
    function init(uint256 initialSupply, string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) internal virtual {
        require(status == 0);
        _totalSupply = initialSupply * 10 ** uint256(tokenDecimals);
        _balances[msg.sender] = _totalSupply;
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
        status = 2;
    }
    
    function name() public view virtual returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public view virtual override returns (uint256) {
        return _balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public virtual override returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 _value) isRunning internal virtual {
    	require(address(0) != _from, "ERC20: transfer from the zero address");
    	require(address(0) != _to, "ERC20: transfer to the zero address");
        require(_balances[_from] >= _value, "ERC20: transfer amount exceeds balance");
        require(_balances[_to] + _value >= _balances[_to]);
        uint previousBalances = _balances[_from] + _balances[_to];
        _balances[_from] = Math.subtract(_balances[_from], _value);
        _balances[_to] = Math.add(_balances[_to], _value);
        emit Transfer(_from, _to, _value);
        assert(_balances[_from] + _balances[_to] == previousBalances);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) isRunning public virtual override returns (bool) {
    	require(address(0) != _from, "ERC20: transfer from the zero address");
    	require(address(0) != _to, "ERC20: transfer to the zero address");
        require(_value <= _allowances[_from][msg.sender], "ERC20: transfer amount exceeds allowance");
        _allowances[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) isRunning public virtual override returns (bool) {
    	require(address(0) != _spender, "ERC20: approve spender the zero address");
        require(_value == 0 || _allowances[msg.sender][_spender] == 0);
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function increaseAllowance(address _spender, uint256 _value) isRunning public virtual returns (bool) {
    	require(address(0) != _spender, "ERC20: approve spender the zero address");
   		_allowances[msg.sender][_spender] = Math.add(_allowances[msg.sender][_spender], _value);
   		emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);
   		return true;
	}

	function decreaseAllowance(address _spender, uint _value) isRunning public virtual returns (bool) {
    	require(address(0) != _spender, "ERC20: approve spender the zero address");
	   	uint256 oldValue = _allowances[msg.sender][_spender];
	   	if (_value >= oldValue) {
	       _allowances[msg.sender][_spender] = 0;
	   	} else {
	       _allowances[msg.sender][_spender] = Math.subtract(oldValue, _value);
	   	}
	   	emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);
	   	return true;
	}
    
    function burn(uint256 _value) public virtual returns (bool) {
        require(_balances[msg.sender] >= _value, "ERC20: burn amount exceeds balances");   // Check if the sender has enough
        _balances[msg.sender] -= _value;            // Subtract from the sender
        _totalSupply -= _value;                      // Updates _totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public virtual returns (bool) {
    	require(address(0) != _from, "ERC20: burn from the zero address");
        require(_balances[_from] >= _value, "ERC20: burn amount exceeds balances");                // Check if the targeted balance is enough
        require(_value <= _allowances[_from][msg.sender], "ERC20: burn amount exceeds allowances");    // Check allowance
        _balances[_from] -= _value;                         // Subtract from the targeted balance
        _allowances[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        _totalSupply -= _value;                              // Update _totalSupply
        emit Burn(_from, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view virtual override returns (uint256) {
        return _allowances[_owner][_spender];
    }
    
    function destruct() isOwner public {
        selfdestruct(payable(msg.sender));
    }
}

contract TRIA is TokenBase {
    uint256 private sellPrice;
    uint256 private buyPrice;
    uint8 freezePercent;
    address[] private frozenAddresses;
    mapping (address => uint256) private frozenBalances;
    
    event FrozenBalance(address indexed target, uint256 balance);
    event Price(uint256 newSellPrice, uint256 newBuyPrice);
    
    constructor() TokenBase() payable {
        init(10000000000, "TRIA", "TRC", 18);
        freezePercent = 100;
        
        emit Transfer(address(0), msg.sender, 10000000000);
    }
    
    function _transfer(address _from, address _to, uint256 _value) isRunning internal virtual override {
        require(frozenBalances[_from] <= balanceOf(_from) - _value);
        
        super._transfer(_from, _to, _value);
        
        if(status == 1) 
        	freeze(_to, freezePercent);
    }
    
    function increaseFrozenBalances(address target, uint256 _value) isAdmin public virtual {
        require(_value > 0);
        if(frozenBalances[target] == 0)
        	frozenAddresses.push(target);
        	
        frozenBalances[target] += _value;
        emit FrozenBalance(target, frozenBalances[target]);
    }
    
    function decreaseFrozenBalances(address target, uint256 _value) isAdmin public virtual {
        require(_value > 0 && frozenBalances[target] >= _value);
        frozenBalances[target] -= _value;
        
        if(frozenBalances[target] == 0)
        	deleteFrozenAddresses(target);
        	
        emit FrozenBalance(target, frozenBalances[target]);
    }
    
    function freeze(address target, uint8 percent) isAdmin public virtual {
        require(percent > 0 && percent <= 100);
        if(frozenBalances[target] == 0)
        	frozenAddresses.push(target);
        
        uint256 frozenBalance = balanceOf(target) * percent / 100;
        frozenBalances[target] = frozenBalance;
        
        emit FrozenBalance(target, frozenBalance);
    }
    
    function changeFrozenBalanceAll(uint8 percent) isAdmin public virtual {
        uint arrayLength = frozenAddresses.length;
		for (uint i=0; i<arrayLength; i++) {
			uint256 frozenBalance = balanceOf(frozenAddresses[i]) * percent / 100;
        	frozenBalances[frozenAddresses[i]] = frozenBalance;
		}
    }
    
    function unfreeze(address target) isAdmin public virtual {
    	deleteFrozenAddresses(target);
    	delete frozenBalances[target];
    }
    
    function deleteFrozenAddresses(address target) internal virtual {
    	uint arrayLength = frozenAddresses.length;
    	uint indexToBeDeleted;
    	bool exists = false;
		for (uint i=0; i<arrayLength; i++) {
  			if (frozenAddresses[i] == target) {
    			indexToBeDeleted = i;
    			exists = true;
    			break;
  			}
		}
		if(exists) {
    		address lastAddress = frozenAddresses[frozenAddresses.length-1];
            frozenAddresses[indexToBeDeleted] = lastAddress;
            frozenAddresses.pop();
    	}
    }
    
    function unfreezeAll() isAdmin public virtual {
    	uint arrayLength = frozenAddresses.length;
		for (uint i=0; i<arrayLength; i++) {
    		delete frozenBalances[frozenAddresses[i]];
		}
		delete frozenAddresses;
    }
    
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) isAdmin public virtual {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
        emit Price(sellPrice, buyPrice);
    }
    
    function buy() payable public virtual {
        require(buyPrice > 0);
        uint amount = msg.value / buyPrice;
        _transfer(address(this), msg.sender, amount);
    }
    
    function sell(uint256 amount) payable public virtual {
        require(sellPrice > 0);
        address myAddress = address(this);
        require(myAddress.balance >= amount * sellPrice);
        _transfer(msg.sender, address(this), amount);
        payable(msg.sender).transfer(amount * sellPrice);
    }
    
    function setFreezePercent(uint8 percent) isAdmin public virtual {
    	freezePercent = percent;
    }
    
    function frozenBalancesOf(address target) public view virtual returns (uint256) {
        return frozenBalances[target];
    }
    
    function frozenAddressesOf(address target) public view virtual returns (address) {
        uint arrayLength = frozenAddresses.length;
		for (uint i=0; i<arrayLength; i++) {
  			if (frozenAddresses[i] == target) {
    			return frozenAddresses[i];
  			}
		}
		return address(0);
    }
    
    function frozenCount() public view virtual returns (uint) {
        return frozenAddresses.length;
    }
}