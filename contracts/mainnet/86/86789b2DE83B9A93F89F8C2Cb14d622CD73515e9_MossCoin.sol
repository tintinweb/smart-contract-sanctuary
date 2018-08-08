pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
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

contract Ownable {
    address owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
 
    mapping(address => uint256) balances;

    function transfer(address _to, uint256 _value) public returns (bool) {
      require(_to != address(0));
      require(_value <= balances[msg.sender]);

      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      Transfer(msg.sender, _to, _value);
      return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
      return balances[_owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        
        return true;
    }
}

contract FreezableToken is StandardToken, Ownable {
    event Freeze(address indexed who, uint256 end);

    mapping(address=>uint256) freezeEnd;

    function freeze(address _who, uint256 _end) onlyOwner public {
        require(_who != address(0));
        require(_end >= freezeEnd[_who]);

        freezeEnd[_who] = _end;

        Freeze(_who, _end);
    }

    modifier notFrozen(address _who) {
        require(freezeEnd[_who] < now);
        _;
    }

    function transferFrom(address _from, address _to, uint256 _value) public notFrozen(_from) returns (bool) {
        super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public notFrozen(msg.sender) returns (bool) {
        super.transfer(_to, _value);
    }
}

contract UpgradeAgent {
    function upgradeFrom(address _from, uint256 _value) public;
}

contract UpgradableToken is StandardToken, Ownable {
    using SafeMath for uint256;

    address public upgradeAgent;
    uint256 public totalUpgraded;

    event Upgrade(address indexed _from, address indexed _to, uint256 _value);

    function upgrade(uint256 _value) external {
        assert(upgradeAgent != address(0));
        require(_value != 0);
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalUpgraded = totalUpgraded.add(_value);
        UpgradeAgent(upgradeAgent).upgradeFrom(msg.sender, _value);
        Upgrade(msg.sender, upgradeAgent, _value);
    }

    function setUpgradeAgent(address _agent) external onlyOwner {
        require(_agent != address(0));
        assert(upgradeAgent == address(0));
        
        upgradeAgent = _agent;
    }
}

contract CrowdsaleToken is StandardToken, Ownable {
    using SafeMath for uint256;
    address public crowdsale;
    mapping (address => uint256) public waiting;
    uint256 public saled;

    event Sale(address indexed to, uint256 value);
    event Release(address indexed to);
    event Reject(address indexed to);
    event SetCrowdsale(address indexed addr);

    function setCrowdsale(address _addr) onlyOwner public {
        crowdsale = _addr;
        SetCrowdsale(_addr);
    }

    modifier onlyCrowdsale() {
        require(crowdsale != address(0));
        require(crowdsale == msg.sender);
        _;
    }

    function sale(address _to, uint256 _value) public onlyCrowdsale returns (bool) {
        require(_to != address(0));
        assert(saled.add(_value) <= balances[owner]);

        saled = saled.add(_value);
        waiting[_to] = waiting[_to].add(_value);
        Sale(_to, _value);
        return true;
    }

    // send waiting tokens to customer&#39;s balance
    function release(address _to) external onlyOwner {
        require(_to != address(0));

        uint256 val = waiting[_to];
        waiting[_to] = 0;
        balances[owner] = balances[owner].sub(val);
        balances[_to] = balances[_to].add(val);
        Release(_to);
    }

    // reject waiting token
    function reject(address _to) external onlyOwner {
        require(_to != address(0));

        saled = saled.sub(waiting[_to]);
        waiting[_to] = 0;

        Reject(_to);
    }
}

contract BurnableToken is BasicToken, Ownable {
    event Burn(uint256 value);

    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[owner]);

        balances[owner] = balances[owner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(_value);
    }
}

contract MossCoin is FreezableToken, UpgradableToken, CrowdsaleToken, BurnableToken {
    string public constant name = "Moss Coin";
    string public constant symbol = "MOC";
    uint8 public constant decimals = 18;

    function MossCoin(uint256 _amount) public
        Ownable()
    {
        totalSupply = _amount * 1 ether;
        balances[owner] = totalSupply;
    }
}