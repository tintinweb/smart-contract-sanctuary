pragma solidity ^0.4.19;


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

contract OwnedInterface {
    function getOwner() public view returns(address);
    function changeOwner(address) public returns (bool);
}

contract Owned is OwnedInterface {
    
    address private contractOwner;
  
    event LogOwnerChanged(
        address oldOwner, 
        address newOwner);

    modifier onlyOwner {
        require(msg.sender == contractOwner);
        _;
    } 
   
    function Owned() public {
        contractOwner = msg.sender;
    }
    
    function getOwner() public view returns(address owner) {
        return contractOwner;
    }
  
    function changeOwner(address newOwner) 
        public 
        onlyOwner 
        returns(bool success) 
    {
        require(newOwner != 0);
        LogOwnerChanged(contractOwner, newOwner);
        contractOwner = newOwner;
        return true;
    }
}

contract TimeLimitedStoppableInterface is OwnedInterface 
{
  function isRunning() public view returns(bool contractRunning);
  function setRunSwitch(bool) public returns(bool onOff);
}

contract TimeLimitedStoppable is TimeLimitedStoppableInterface, Owned 
{
  bool private running;
  uint private finalBlock;

  modifier onlyIfRunning
  {
    require(running);
    _;
  }
  
  event LogSetRunSwitch(address sender, bool isRunning);
  event LogSetFinalBlock(address sender, uint lastBlock);

  function TimeLimitedStoppable() public {
    running = true;
    finalBlock = now + 390 days;
    LogSetRunSwitch(msg.sender, true);
    LogSetFinalBlock(msg.sender, finalBlock);
  }

  function isRunning() 
    public
    view 
    returns(bool contractRunning) 
  {
    return running && now <= finalBlock;
  }

  function getLastBlock() public view returns(uint lastBlock) {
    return finalBlock;
  }

  function setRunSwitch(bool onOff) 
    public
    onlyOwner
    returns(bool success)
  {
    LogSetRunSwitch(msg.sender, onOff);
    running = onOff;
    return true;
  }

  function SetFinalBlock(uint lastBlock) 
    public 
    onlyOwner 
    returns(bool success) 
  {
    finalBlock = lastBlock;
    LogSetFinalBlock(msg.sender, finalBlock);
    return true;
  }

}

contract Ownable {
  address public owner;


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
  function totalSupply() public view returns (uint256);
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

  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
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

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

contract CMCTInterface is ERC20 {
  function isCMCT() public pure returns(bool isIndeed);
}

contract CMCT is CMCTInterface, StandardToken, CanReclaimToken {
  string public name = "Crowd Machine Compute Token";
  string public symbol = "CMCT";
  uint8  public decimals = 8;
  uint256 public INITIAL_SUPPLY = uint(2000000000) * (10 ** uint256(decimals));

  function CMCT() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
   
  function isCMCT() public pure returns(bool isIndeed) {
      return true;
  }
}

contract CmctSaleInterface is TimeLimitedStoppableInterface, CanReclaimToken {
  
  struct FunderStruct {
    bool registered;
    bool approved;
  }
  
  mapping(address => FunderStruct) public funderStructs;
  
  function isUser(address user) public view returns(bool isIndeed);
  function isApproved(address user) public view returns(bool isIndeed);
  function registerSelf(bytes32 uid) public returns(bool success);
  function registerUser(address user, bytes32 uid) public returns(bool success);
  function approveUser(address user, bytes32 uid) public returns(bool success);
  function disapproveUser(address user, bytes32 uid) public returns(bool success);
  function withdrawEth(uint amount, address to, bytes32 uid) public returns(bool success);
  function relayCMCT(address receiver, uint amount, bytes32 uid) public returns(bool success);
  function bulkRelayCMCT(address[] receivers, uint[] amounts, bytes32 uid) public returns(bool success);
  function () public payable;
}

contract CmctSale is CmctSaleInterface, TimeLimitedStoppable {
  
  CMCTInterface cmctToken;
  
  event LogSetTokenAddress(address sender, address cmctContract);
  event LogUserRegistered(address indexed sender, address indexed user, bytes32 indexed uid);
  event LogUserApproved(address indexed sender, address user, bytes32 indexed uid);
  event LogUserDisapproved(address indexed sender, address user, bytes32 indexed uid);
  event LogEthWithdrawn(address indexed sender, address indexed to, uint amount, bytes32 indexed uid);
  event LogCMCTRelayFailed(address indexed sender, address indexed receiver, uint amount, bytes32 indexed uid);
  event LogCMCTRelayed(address indexed sender, address indexed receiver, uint amount, bytes32 indexed uid);
  event LogEthReceived(address indexed sender, uint amount);
  
  modifier onlyifInitialized {
      require(cmctToken.isCMCT());
      _;
  }

  function 
    CmctSale(address cmctContract) 
    public 
  {
    require(cmctContract != 0);
    cmctToken = CMCTInterface(cmctContract);
    LogSetTokenAddress(msg.sender, cmctContract);
   }

  function setTokenAddress(address cmctContract) public onlyOwner returns(bool success) {
      require(cmctContract != 0);
      cmctToken = CMCTInterface(cmctContract);
      LogSetTokenAddress(msg.sender, cmctContract);
      return true;
  }

  function getTokenAddress() public view returns(address cmctContract) {
    return cmctToken;
  }

  function isUser(address user) public view returns(bool isIndeed) {
      return funderStructs[user].registered;
  }

  function isApproved(address user) public view returns(bool isIndeed) {
      if(!isUser(user)) return false;
      return(funderStructs[user].approved);
  }

  function registerSelf(bytes32 uid) public onlyIfRunning returns(bool success) {
      require(!isUser(msg.sender));
      funderStructs[msg.sender].registered = true;
      LogUserRegistered(msg.sender, msg.sender, uid);
      return true;
  }

  function registerUser(address user, bytes32 uid) public onlyOwner onlyIfRunning returns(bool success) {
      require(!isUser(user));
      funderStructs[user].registered = true;
      LogUserRegistered(msg.sender, user, uid);
      return true;      
  }

  function approveUser(address user, bytes32 uid) public onlyOwner onlyIfRunning returns(bool success) {
      require(isUser(user));
      require(!isApproved(user));
      funderStructs[user].approved = true;
      LogUserApproved(msg.sender, user, uid);
      return true;
  }

  function disapproveUser(address user, bytes32 uid) public onlyOwner onlyIfRunning returns(bool success) {
      require(isUser(user));
      require(isApproved(user));
      funderStructs[user].approved = false;
      LogUserDisapproved(msg.sender, user, uid);
      return true;      
  }

  function withdrawEth(uint amount, address to, bytes32 uid) public onlyOwner returns(bool success) {
      LogEthWithdrawn(msg.sender, to, amount, uid);
      to.transfer(amount);
      return true;
  }

  function relayCMCT(address receiver, uint amount, bytes32 uid) public onlyOwner onlyIfRunning onlyifInitialized returns(bool success) {
    if(!isApproved(receiver)) {
      LogCMCTRelayFailed(msg.sender, receiver, amount, uid);
      return false;
    } else {
      LogCMCTRelayed(msg.sender, receiver, amount, uid);
      require(cmctToken.transfer(receiver, amount));
      return true;
    }
  }
 
  function bulkRelayCMCT(address[] receivers, uint[] amounts, bytes32 uid) public onlyOwner onlyIfRunning onlyifInitialized returns(bool success) {
    for(uint i=0; i<receivers.length; i++) {
      if(!isApproved(receivers[i])) {
        LogCMCTRelayFailed(msg.sender, receivers[i], amounts[i], uid);
      } else {
        LogCMCTRelayed(msg.sender, receivers[i], amounts[i], uid);
        require(cmctToken.transfer(receivers[i], amounts[i]));
      } 
    }
    return true;
  }

  function () public onlyIfRunning payable {
    require(isApproved(msg.sender));
    LogEthReceived(msg.sender, msg.value);
  }
}