pragma solidity ^0.4.24;

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

contract Manage {
    address owner = 0x0;
    address admin = 0x0;
    
    /**
     *  0 : init, 1 : limited, 2 : running, 3 : finishing
     */
    uint8 public status = 0;

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

    modifier isAdmin {
        assert(owner == msg.sender || admin == msg.sender);
        _;
    }

    modifier isRunning {
        assert(status == 1 || status == 2 || owner == msg.sender);
        _;
    }

    modifier validAddress {
        assert(0x0 != msg.sender);
        _;
    }

    function setStatus(uint8 _status) isAdmin public {
        status = _status;
    }
    
    function setOwner(address _owner) isOwner public {
        owner = _owner;
    }
    
    function setAdmin(address _admin) isOwner public {
        admin = _admin;
    }
    
    function getManagers() isAdmin constant public returns (address _owner, address _admin) {
        return (owner, admin);
    }
}

contract EIP20Interface {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TokenBase is EIP20Interface, Manage, Math {
    string public name;
    string public symbol;
    uint8 public decimals;
    
    event Burn(address indexed from, uint256 value);

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    function init(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 tokenDecimals) internal {
        require(status == 0);
        owner = msg.sender;
        admin = msg.sender;
        totalSupply = initialSupply * 10 ** uint256(tokenDecimals);
        balances[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        status = 1;
    }
    
    function _transfer(address _from, address _to, uint _value) isRunning validAddress internal {
        require(balances[_from] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        uint previousBalances = Math.add(balances[_from], balances[_to]);
        balances[_from] = Math.subtract(balances[_from], _value);
        balances[_to] = Math.add(balances[_to], _value);
        emit Transfer(_from, _to, _value);
        assert(balances[_from] + balances[_to] == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) isRunning validAddress public returns (bool success) {
        require(_value == 0 || allowed[msg.sender][_spender] == 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function close() isOwner public {
        selfdestruct(owner);
    }
}

contract BT01Token is TokenBase {
    uint256 public sellPrice;
    uint256 public buyPrice;
    uint8 frozenPercent;
    mapping (address => uint256) public frozenBalanceOf;
    
    event Frozen(address target, uint256 balance);
    event Price(uint256 newSellPrice, uint256 newBuyPrice);
    
    constructor() public {
        init(10000000000, "BT01Token", "BT01", 18);
        frozenPercent = 10;
        
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    function _transfer(address _from, address _to, uint _value) validAddress internal {
        require(frozenBalanceOf[_from] <= _value);
        
        super._transfer(_from, _to, _value);
        
        if(status == 1) 
            _freeze(_to, frozenPercent);
    }
    
    function _freeze(address target, uint8 percent) public  returns (uint256 balance) {
        uint256 frozenBalance = balances[target] * percent / 100;
        frozenBalanceOf[target] = frozenBalance;
        return frozenBalance;
    }
    
    function freeze(address target, uint8 percent) isAdmin validAddress public {
        require(percent > 0);
        uint256 frozenBalance = _freeze(target, percent);
        emit Frozen(target, frozenBalance);
    }
    
    function unfreeze(address target) isAdmin validAddress public {
        delete frozenBalanceOf[target];
    }
    
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) isAdmin public {
        require(newSellPrice > 0 && newBuyPrice > 0);
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
        emit Price(sellPrice, buyPrice);
    }
    
    function buy() payable public {
        require(buyPrice > 0);
        uint amount = msg.value / buyPrice;
        _transfer(this, msg.sender, amount);
    }
    
    function sell(uint256 amount) public {
        require(sellPrice > 0);
        address myAddress = this;
        require(myAddress.balance >= amount * sellPrice);
        _transfer(msg.sender, this, amount);
        msg.sender.transfer(amount * sellPrice);
    }
}