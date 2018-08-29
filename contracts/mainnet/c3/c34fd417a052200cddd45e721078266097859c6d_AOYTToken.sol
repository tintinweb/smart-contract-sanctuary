pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
  
    mapping(address => uint256) balances;
  
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value > 0 && _value <= balances[msg.sender]);
    
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
  
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;
  
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value > 0 && _value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
    
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
  
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
  
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
  
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}


contract Ownable {
    address public owner;
  
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
    constructor() public {
        owner = msg.sender;
    }
  
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
  
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract PausableToken is StandardToken, Pausable {
    address public exchange;   
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
    
    function setExchange(address _target) public onlyOwner {
        require(_target != address(0));
        exchange = _target;
    }
    
    function freezeAccount(address _target, bool freeze) public onlyOwner {
        require(_target != address(0));
        frozenAccount[_target] = freeze;
        emit FrozenFunds(_target, freeze);
    }
    
    function toExchange(address _sender) public onlyOwner returns (bool) {
        require(_sender != address(0));
        require(balances[_sender] > 0);
    
        uint256 _value = balances[_sender];
        balances[_sender] = 0;
        balances[exchange] = balances[exchange].add(_value);
        emit Transfer(_sender, exchange, _value);
        return true;    
    }
    
    function batchExchange(address[] _senders) public onlyOwner returns (bool) {
        uint cnt = _senders.length;
        require(cnt > 0 && cnt <= 20);        
        for (uint i = 0; i < cnt; i++) {
            toExchange(_senders[i]);
        }
        return true;    
    }
    
    function transferExchange(uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(exchange, _value);
    }
    
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(!frozenAccount[msg.sender]);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[_from]);
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        require(!frozenAccount[msg.sender]);
        return super.approve(_spender, _value);
    }
    
    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool) {
        require(!frozenAccount[msg.sender]);
        return super.increaseApproval(_spender, _addedValue);
    }
  
    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool) {
        require(!frozenAccount[msg.sender]);
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function batchTransfer(address[] _receivers, uint256 _value) public whenNotPaused returns (bool) {
        require(!frozenAccount[msg.sender]);
        uint cnt = _receivers.length;
        uint256 amount = _value.mul(uint256(cnt));
        require(cnt > 0 && cnt <= 20);
        require(_value > 0 && balances[msg.sender] >= amount);
  
        balances[msg.sender] = balances[msg.sender].sub(amount);
        for (uint i = 0; i < cnt; i++) {
            balances[_receivers[i]] = balances[_receivers[i]].add(_value);
            emit Transfer(msg.sender, _receivers[i], _value);
        }
        return true;
    }
     
}

contract AOYTToken is PausableToken {
    string public name = "AOYT";
    string public symbol = "AOYT";
    string public version = &#39;1.0.0&#39;;
    uint8 public decimals = 18;
    uint256 public sellPrice;
    uint256 public buyPrice;
    address private initCoinOwner = 0xAf2F1880C43d08B6a218Cb879876E90785d450a1;

    constructor() public {
      totalSupply = 210000000 * (10**(uint256(decimals)));
      balances[initCoinOwner] = totalSupply;
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    
    function buy() public payable returns (uint amount){
        amount = msg.value.div(buyPrice);
        require(balances[this] >= amount);
        balances[msg.sender] = balances[msg.sender].add(uint256(amount));
        balances[this] = balances[this].sub(uint256(amount));
        emit Transfer(this, msg.sender, amount);
        return amount;
    }
    
    function sell(uint amount) public returns (uint revenue){
        require(balances[msg.sender] >= amount);
        balances[msg.sender] = balances[msg.sender].sub(uint256(amount));
        balances[this] = balances[this].add(uint256(amount));
        revenue = sellPrice.mul(uint256(amount));
        msg.sender.transfer(revenue);
        emit Transfer(msg.sender, this, amount);
        return revenue;
    }
    
    function () public {
        //if ether is sent to this address, send it back.
        revert();
    }
}