/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

pragma solidity ^0.4.13;

library SafeMath {

  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {

    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a / _b;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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

  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
    
  }
}

contract ReleasableToken is ERC20, Ownable {

    address public releaseAgent;

    bool public released = false;

    mapping(address => bool) public transferAgents;

    modifier canTransfer(address _sender) {
        require(released || transferAgents[_sender], "For the token to be able to transfer: it's required that the crowdsale is in released state; or the sender is a transfer agent.");
        _;
    }

    function setReleaseAgent(address addr) public onlyOwner inReleaseState(false) {

        releaseAgent = addr;
    }

    
    function setTransferAgent(address addr, bool state) public onlyOwner inReleaseState(false) {
        transferAgents[addr] = state;
    }

    function releaseTokenTransfer() public onlyReleaseAgent {
        released = true;
    }

    modifier inReleaseState(bool releaseState) {
        require(releaseState == released, "It's required that the state to check aligns with the released flag.");
        _;
    }

    modifier onlyReleaseAgent() {
        require(msg.sender == releaseAgent, "Message sender is required to be a release agent.");
        _;
    }

    function transfer(address _to, uint _value) public canTransfer(msg.sender) returns (bool success) {
        // Call StandardToken.transfer()
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public canTransfer(_from) returns (bool success) {
        // Call StandardToken.transferForm()
        return super.transferFrom(_from, _to, _value);
    }

}

contract UpgradeableToken is StandardToken {

    using SafeMath for uint256;


    address public upgradeMaster;

    UpgradeAgent public upgradeAgent;

    uint256 public totalUpgraded;

    enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade}

    event Upgrade(address indexed _from, address indexed _to, uint256 _value);

    event UpgradeAgentSet(address agent);

    constructor(address _upgradeMaster) public {
        upgradeMaster = _upgradeMaster;
    }

    function upgrade(uint256 value) public {

        UpgradeState state = getUpgradeState();

        require(state == UpgradeState.ReadyToUpgrade, "It's required that the upgrade state is ready.");

        require(value > 0, "The upgrade value is required to be above 0.");

        balances[msg.sender] = balances[msg.sender].sub(value);

        totalSupply_ = totalSupply_.sub(value);
        totalUpgraded = totalUpgraded.add(value);

        upgradeAgent.upgradeFrom(msg.sender, value);
        emit Upgrade(msg.sender, upgradeAgent, value);
    }

    function setUpgradeAgent(address agent) external {

        require(canUpgrade(), "It's required to be in canUpgrade() condition when setting upgrade agent.");

        require(agent != address(0), "Agent is required to be an non-empty address when setting upgrade agent.");

        require(msg.sender == upgradeMaster, "Message sender is required to be the upgradeMaster when setting upgrade agent.");

        require(getUpgradeState() != UpgradeState.ReadyToUpgrade, "Upgrade state is required to not be upgrading when setting upgrade agent.");

        require(address(upgradeAgent) == address(0), "upgradeAgent once set, cannot be reset");

        upgradeAgent = UpgradeAgent(agent);

        require(upgradeAgent.isUpgradeAgent(), "The provided updateAgent contract is required to be compliant to the UpgradeAgent interface method when setting upgrade agent.");

        require(upgradeAgent.originalSupply() == totalSupply_, "The provided upgradeAgent contract's originalSupply is required to be equivalent to existing contract's totalSupply_ when setting upgrade agent.");

        emit UpgradeAgentSet(upgradeAgent);
    }

    function getUpgradeState() public view returns (UpgradeState) {
        if (!canUpgrade()) return UpgradeState.NotAllowed;
        else if (address(upgradeAgent) == address(0)) return UpgradeState.WaitingForAgent;
        else return UpgradeState.ReadyToUpgrade;
    }

    function setUpgradeMaster(address master) public {
        require(master != address(0), "The provided upgradeMaster is required to be a non-empty address when setting upgrade master.");

        require(msg.sender == upgradeMaster, "Message sender is required to be the original upgradeMaster when setting (new) upgrade master.");

        upgradeMaster = master;
    }

    bool canUpgrade_ = true;

    function canUpgrade() public view returns (bool) {
        return canUpgrade_;
    }

}

contract Toksi is ReleasableToken, MintableToken, UpgradeableToken {

    event UpdatedTokenInformation(string newName, string newSymbol);

    string public name;

    string public symbol;

    uint8 public decimals;

    address public Reserve;
    address public Ecosystem;
    address public Founder;
    address public PreSale;
    address public Marketing;

    
    constructor(string _name, string _symbol, uint256 _initialSupply, uint8 _decimals, bool _mintable,
        address _Reserve,
        address _Ecosystem,
        address _Founder,
        address _PreSale,
        address _Marketing)
    public UpgradeableToken(msg.sender) {

       owner = msg.sender;
        releaseAgent = owner;

        name = _name;
        symbol = _symbol;

        decimals = _decimals;

        Reserve = _Reserve;
        Ecosystem = _Ecosystem;
        Founder = _Founder;
        PreSale = _PreSale;
        Marketing = _Marketing;

        if (_initialSupply > 0) {
            require((_initialSupply % 10) == 0, "_initialSupply has to be a mulitple of 10");
            uint256 thirtyPerCent = _initialSupply.mul(3).div(10);
            uint256 twentyPerCent = _initialSupply.mul(2).div(10);
            uint256 tenPerCent = _initialSupply.div(10);

            mint(Reserve, thirtyPerCent);

            mint(Ecosystem, twentyPerCent);

            mint(Founder, twentyPerCent);

            mint(PreSale, twentyPerCent);

            mint(Marketing, tenPerCent);

        }

        if (!_mintable) {
            finishMinting();
            require(totalSupply_ > 0, "Total supply is required to be above 0 if the token is not mintable.");
        }

    }

    function releaseTokenTransfer() public onlyReleaseAgent {
        mintingFinished = true;
        super.releaseTokenTransfer();
    }

    function canUpgrade() public view returns (bool) {
        return released && super.canUpgrade();
    }

    function totalSupply() public view returns (uint) {
        return totalSupply_.sub(balances[address(0)]);
    }

}

contract UpgradeAgent {

    uint public originalSupply;

    function isUpgradeAgent() public pure returns (bool) {
        return true;
    }

    function upgradeFrom(address _from, uint256 _value) public;

}