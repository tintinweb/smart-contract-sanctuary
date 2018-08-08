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

contract UpgradeAgent {
  function upgradeFrom(address _from, uint256 _value) external;
}

contract ERC223Interface {
    uint public totalSupply;
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);
    function totalSupply() public view returns (uint256 _supply);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint value) public returns (bool ok);
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

contract ERC20Interface {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value, bytes data) public returns (bool);
    
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ReceivingContract { 

    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(address _from, uint _value, bytes _data) public pure {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        
        tkn.sig = bytes4(u);
    }
}

contract Owned {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function Owned() public {
        owner = msg.sender;
    }
    
    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract TORUE is ERC223Interface,ERC20Interface,Owned {
    using SafeMath for uint;
    
    string public name = "torue";
    string public symbol = "TRE";
    uint8 public decimals = 6;
    uint256 public totalSupply = 100e8 * 1e6;

    mapping (address => uint256) balances;
    mapping (address => uint256) public lockedAccounts;
    mapping (address => bool) public frozenAccounts;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => bool) public salvageableAddresses;
    
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event Burn(address indexed burner, uint256 value);
    event DistributeTokens(uint count,uint256 totalAmount);
    event Upgrade(address indexed from, address indexed to, uint256 value);
    event AccountLocked(address indexed addr, uint256 releaseTime);
    event AccountFrozen(address indexed addr, bool frozen);

    address ownerAddress = 0xA0Bf23D5Ef64B6DdEbF5343a3C897c53005ee665;
    address lockupAddress1 = 0xB3c289934692ECE018d137fFcaB54631e6e2b405;
    address lockupAddress2 = 0x533c43AF0DDb5ee5215c0139d917F1A871ff9CB5;

    bool public compatible20 = true;
    bool public compatible223 = true;
    bool public compatible223ex = true;
    
    bool public mintingFinished = false;
    bool public salvageFinished = false;
    bool public paused = false;
    bool public upgradable = false;
    bool public upgradeAgentLocked = false;
    
    address public upgradeMaster;
    address public upgradeAgent;
    uint256 public totalUpgraded;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }
    
    modifier isRunning(){
        require(!paused);
        _;
    }
    
    function TORUE() public {
        require(msg.sender==ownerAddress);
        owner = ownerAddress;
        upgradeMaster = ownerAddress;
        balances[owner] = totalSupply.mul(70).div(100);
        balances[lockupAddress1] = totalSupply.mul(15).div(100);
        balances[lockupAddress2] = totalSupply.mul(15).div(100);
        paused = false;
    }
    
    function switchCompatible20(bool _value) onlyOwner public {
        compatible20 = _value;
    }
    function switchCompatible223(bool _value) onlyOwner public {
        compatible223 = _value;
    }
    function switchCompatible223ex(bool _value) onlyOwner public {
        compatible223ex = _value;
    }

    function switchPaused(bool _paused) onlyOwner public {
        paused = _paused;
    }
    
    function switchUpgradable(bool _value) onlyOwner public {
        upgradable = _value;
    }
    
    function switchUpgradeAgentLocked(bool _value) onlyOwner public {
        upgradeAgentLocked = _value;
    }

    function isUnlocked(address _addr) private view returns (bool){
        return(now > lockedAccounts[_addr] && frozenAccounts[_addr] == false);
    }
    
    function isUnlockedBoth(address _addr) private view returns (bool){
        return(now > lockedAccounts[msg.sender] && now > lockedAccounts[_addr] && frozenAccounts[msg.sender] == false && frozenAccounts[_addr] == false);
    }
    
    function lockAccounts(address[] _addresses, uint256 _releaseTime) onlyOwner public {
        require(_addresses.length > 0);
                
        for(uint j = 0; j < _addresses.length; j++){
            require(lockedAccounts[_addresses[j]] < _releaseTime);
            lockedAccounts[_addresses[j]] = _releaseTime;
            AccountLocked(_addresses[j], _releaseTime);
        }
    }

    function freezeAccounts(address[] _addresses, bool _value) onlyOwner public {
        require(_addresses.length > 0);

        for (uint j = 0; j < _addresses.length; j++) {
            require(_addresses[j] != 0x0);
            frozenAccounts[_addresses[j]] = _value;
            AccountFrozen(_addresses[j], _value);
        }
    }

    function setSalvageable(address _addr, bool _value) onlyOwner public {
        salvageableAddresses[_addr] = _value;
    }
    
    function finishSalvage(address _addr) onlyOwner public returns (bool) {
        require(_addr==owner);
        salvageFinished = true;
        return true;
    }
    
    function salvageTokens(address _addr,uint256 _amount) onlyOwner public isRunning returns(bool) {
        require(_amount > 0 && balances[_addr] >= _amount);
        require(now > lockedAccounts[msg.sender] && now > lockedAccounts[_addr]);
        require(salvageableAddresses[_addr] == true && salvageFinished == false);
        balances[_addr] = balances[_addr].sub(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        Transfer(_addr, msg.sender, _amount);
        return true;
    }

    function approve(address _spender, uint256 _value) public isRunning returns (bool) {
        require(compatible20);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public isRunning returns (bool) {
        require(compatible20);
        require(isUnlocked(_from));
        require(isUnlocked(_to));
        
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        
        if(isContract(_to)) {
            bytes memory empty;
            ReceivingContract rc = ReceivingContract(_to);
            rc.tokenFallback(msg.sender, _value, empty);
        }
        Transfer(_from, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value, bytes _data) public isRunning returns (bool) {
        require(compatible223);
        require(isUnlocked(_from));
        require(isUnlocked(_to));
        
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        
        if(isContract(_to)) {
            ReceivingContract rc = ReceivingContract(_to);
            rc.tokenFallback(msg.sender, _value, _data);
        }
        Transfer(msg.sender, _to, _value, _data);
        Transfer(_from, _to, _value);
        return true;
    }

    function increaseApproval(address _spender, uint _addedValue) public isRunning returns (bool) {
        require(compatible20);
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public isRunning returns (bool) {
        require(compatible20);
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function mint(address _to, uint256 _amount) onlyOwner canMint public isRunning returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }
    
    function finishMinting(address _addr) onlyOwner public returns (bool) {
        require(_addr==owner);
        mintingFinished = true;
        MintFinished();
        return true;
    }
    
    function burn(uint256 _value) public isRunning {
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
    }

    function isContract(address _addr) private view returns (bool is_contract) {
        uint ln;
        assembly {
            ln := extcodesize(_addr)
        }
        return (ln > 0);
    }

    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public isRunning returns (bool ok) {
        require(compatible223ex);
        require(isUnlockedBoth(_to));
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if (isContract(_to)) {
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
        }
        Transfer(msg.sender, _to, _value, _data);
        Transfer(msg.sender, _to, _value);

        return true;
    }

    function transfer(address _to, uint _value, bytes _data) public isRunning returns (bool ok) {
        require(compatible223);
        require(isUnlockedBoth(_to));
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(isContract(_to)) {
            ReceivingContract rc = ReceivingContract(_to);
            rc.tokenFallback(msg.sender, _value, _data);
        }
        Transfer(msg.sender, _to, _value, _data);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transfer(address _to, uint _value) public isRunning returns (bool ok) {
        require(isUnlockedBoth(_to));
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(isContract(_to)) {
            bytes memory empty;
            ReceivingContract rc = ReceivingContract(_to);
            rc.tokenFallback(msg.sender, _value, empty);
        }
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function name() public view returns (string _name) {
        return name;
    }
    
    function symbol() public view returns (string _symbol) {
        return symbol;
    }
    
    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }
    
    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function distributeTokens(address[] _addresses, uint256 _amount) onlyOwner public isRunning returns(bool) {
        require(_addresses.length > 0 && isUnlocked(msg.sender));

        uint256 totalAmount = _amount.mul(_addresses.length);
        require(balances[msg.sender] >= totalAmount);

        for (uint j = 0; j < _addresses.length; j++) {
            require(isUnlocked(_addresses[j]));
            balances[_addresses[j]] = balances[_addresses[j]].add(_amount);
            Transfer(msg.sender, _addresses[j], _amount);
        }
        balances[msg.sender] = balances[msg.sender].sub(totalAmount);
        DistributeTokens(_addresses.length, totalAmount);
        
        return true;
    }
    
    function distributeTokens(address[] _addresses, uint256[] _amounts) onlyOwner public isRunning returns (bool) {
        require(_addresses.length > 0 && _addresses.length == _amounts.length && isUnlocked(msg.sender));
        uint256 totalAmount = 0;
        for(uint j = 0; j < _addresses.length; j++){
            require(_amounts[j] > 0 && _addresses[j] != 0x0 && isUnlocked(_addresses[j]));
            totalAmount = totalAmount.add(_amounts[j]);
        }
        require(balances[msg.sender] >= totalAmount);
        
        for (j = 0; j < _addresses.length; j++) {
            balances[_addresses[j]] = balances[_addresses[j]].add(_amounts[j]);
            Transfer(msg.sender, _addresses[j], _amounts[j]);
        }
        balances[msg.sender] = balances[msg.sender].sub(totalAmount);
        DistributeTokens(_addresses.length, totalAmount);

        return true;
    }

    function upgrade(uint256 _value) external isRunning {
        require(upgradable);
        require(upgradeAgent != 0);
        require(_value != 0);
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalUpgraded = totalUpgraded.add(_value);
        UpgradeAgent(upgradeAgent).upgradeFrom(msg.sender, _value);
        Upgrade(msg.sender, upgradeAgent, _value);
    }
    
    function setUpgradeAgent(address _agent) external {
        require(_agent != 0);
        require(!upgradeAgentLocked);
        require(msg.sender == upgradeMaster);
        
        upgradeAgent = _agent;
        upgradeAgentLocked = true;
    }
    
    function setUpgradeMaster(address _master) external {
        require(_master != 0);
        require(msg.sender == upgradeMaster);
        
        upgradeMaster = _master;
    }

}