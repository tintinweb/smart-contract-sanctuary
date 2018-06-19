pragma solidity ^0.4.11;

contract SafeMathLib {

  function safeMul(uint a, uint b) returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) returns (uint) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }

  function assert(bool assertion) private {
    if (!assertion) throw;
  }
}

contract Ownable {
  address public owner;


  function Ownable() {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address _to, uint _value) returns (bool success);
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address _from, address _to, uint _value) returns (bool success);
  function approve(address _spender, uint _value) returns (bool success);
  event Approval(address indexed owner, address indexed spender, uint value);
}



contract StandardToken is ERC20, SafeMathLib{
  
  event Minted(address receiver, uint amount);

  
  mapping(address => uint) balances;

  
  mapping (address => mapping (address => uint)) allowed;

  modifier onlyPayloadSize(uint size) {
     if(msg.data.length != size + 4) {
       throw;
     }
     _;
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
   
   
    balances[msg.sender] = safeSub(balances[msg.sender],_value);
    balances[_to] = safeAdd(balances[_to],_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to],_value);
    balances[_from] = safeSub(balances[_from],_value);
    allowed[_from][msg.sender] = safeSub(_allowance,_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {

    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

 function addApproval(address _spender, uint _addedValue)
  onlyPayloadSize(2 * 32)
  returns (bool success) {
      uint oldValue = allowed[msg.sender][_spender];
      allowed[msg.sender][_spender] = safeAdd(oldValue,_addedValue);
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
  }

  function subApproval(address _spender, uint _subtractedValue)
  onlyPayloadSize(2 * 32)
  returns (bool success) {

      uint oldVal = allowed[msg.sender][_spender];

      if (_subtractedValue > oldVal) {
          allowed[msg.sender][_spender] = 0;
      } else {
          allowed[msg.sender][_spender] = safeSub(oldVal,_subtractedValue);
      }
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
  }

}



contract UpgradeAgent {

  uint public originalSupply;

  
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;

}



 contract UpgradeableToken is StandardToken {

  
  address public upgradeMaster;

  
  UpgradeAgent public upgradeAgent;

  
  uint256 public totalUpgraded;

  
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

  
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

  
  event UpgradeAgentSet(address agent);

  
  function UpgradeableToken(address _upgradeMaster) {
    upgradeMaster = _upgradeMaster;
  }

  
  function upgrade(uint256 value) public {

      UpgradeState state = getUpgradeState();
      if(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
        
        throw;
      }

      
      if (value == 0) throw;

      balances[msg.sender] = safeSub(balances[msg.sender],value);

      
      totalSupply = safeSub(totalSupply,value);
      totalUpgraded = safeAdd(totalUpgraded,value);

      
      upgradeAgent.upgradeFrom(msg.sender, value);
      Upgrade(msg.sender, upgradeAgent, value);
  }

 
  function setUpgradeAgent(address agent) external {

      if(!canUpgrade()) {
        
        throw;
      }

      if (agent == 0x0) throw;
      
      if (msg.sender != upgradeMaster) throw;
      
      if (getUpgradeState() == UpgradeState.Upgrading) throw;

      upgradeAgent = UpgradeAgent(agent);

      
      if(!upgradeAgent.isUpgradeAgent()) throw;
      
      if (upgradeAgent.originalSupply() != totalSupply) throw;

      UpgradeAgentSet(upgradeAgent);
  }

  function getUpgradeState() public constant returns(UpgradeState) {
    if(!canUpgrade()) return UpgradeState.NotAllowed;
    else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

  
  function setUpgradeMaster(address master) public {
      if (master == 0x0) throw;
      if (msg.sender != upgradeMaster) throw;
      upgradeMaster = master;
  }

  
  function canUpgrade() public constant returns(bool) {
     return true;
  }

}


contract ReleasableToken is ERC20, Ownable {

  
  address public releaseAgent;

  
  bool public released = false;

  
  mapping (address => bool) public transferAgents;


  modifier canTransfer(address _sender) {

    if(!released) {
        if(!transferAgents[_sender]) {
            throw;
        }
    }

    _;
  }


  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
    releaseAgent = addr;
  }


  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }


  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

  
  modifier inReleaseState(bool releaseState) {
    if(releaseState != released) {
        throw;
    }
    _;
  }

  
  modifier onlyReleaseAgent() {
    if(msg.sender != releaseAgent) {
        throw;
    }
    _;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
    
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
    
    return super.transferFrom(_from, _to, _value);
  }

}

contract MintableToken is StandardToken, Ownable {

  bool public mintingFinished = false;

  
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state  );


  function mint(address receiver, uint amount) onlyMintAgent canMint public {
    totalSupply = safeAdd(totalSupply,amount);
    balances[receiver] = safeAdd(balances[receiver],amount);


    Transfer(0, receiver, amount);
  }


  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    MintingAgentChanged(addr, state);
  }

  modifier onlyMintAgent() {
    
    if(!mintAgents[msg.sender]) {
        throw;
    }
    _;
  }

  
  modifier canMint() {
    if(mintingFinished) throw;
    _;
  }
}


contract CrowdsaleToken is ReleasableToken, MintableToken, UpgradeableToken {

  event UpdatedTokenInformation(string newName, string newSymbol);

  string public name;

  string public symbol;

  uint public decimals;

  function CrowdsaleToken(string _name, string _symbol, uint _initialSupply, uint _decimals, bool _mintable)
    UpgradeableToken(msg.sender) {

    owner = msg.sender;

    name = _name;
    symbol = _symbol;

    totalSupply = _initialSupply;

    decimals = _decimals;

    
    balances[owner] = totalSupply;

    if(totalSupply > 0) {
      Minted(owner, totalSupply);
    }

    
    if(!_mintable) {
      mintingFinished = true;
      if(totalSupply == 0) {
        throw; 
      }
    }
  }


  function releaseTokenTransfer() public onlyReleaseAgent {
    mintingFinished = true;
    super.releaseTokenTransfer();
  }


  function canUpgrade() public constant returns(bool) {
    return released && super.canUpgrade();
  }


  function setTokenInformation(string _name, string _symbol) onlyOwner {
    name = _name;
    symbol = _symbol;

    UpdatedTokenInformation(name, symbol);
  }

}