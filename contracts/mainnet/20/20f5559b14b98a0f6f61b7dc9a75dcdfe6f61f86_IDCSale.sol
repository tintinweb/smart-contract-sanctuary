pragma solidity ^0.4.24;

library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b); 
    return c;
  }
}

contract Ownable {

  address public owner;
  event SetOwner(address indexed oldOwner, address indexed newOwner);
  
  constructor() internal {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function setOwner(address _newOwner) external onlyOwner {
    emit SetOwner(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Saleable is Ownable {

  address public saler;
  event SetSaler(address indexed oldSaler, address indexed newSaler);

  modifier onlySaler() {
    require(msg.sender == saler);
    _;
  }

  function setSaler(address _newSaler) external onlyOwner {
    emit SetSaler(saler, _newSaler);
    saler = _newSaler;
  }
}

contract Pausable is Ownable {

  bool public paused = false;

  event Pause();
  event Unpause();

  modifier notPaused() {
    require(!paused);
    _;
  }

  modifier isPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner notPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner isPaused public {
    paused = false;
    emit Unpause();
  }
}

contract ERC20Interface {
    
  function totalSupply() public view returns (uint256);
  function decimals() public view returns (uint8);
  function balanceOf(address _owner) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
 
  function allowance(address _owner, address _spender) public view returns (uint256);
  function approve(address _spender, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandToken is ERC20Interface {

  using SafeMath for uint256;

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  function totalSupply() public view returns (uint256) {
    return totalSupply;
  }
  
  function decimals() public view returns (uint8) {
    return decimals;
  }
  
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
}

contract BurnableToken is StandToken {

  event Burn(address indexed burner, uint256 value);

  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(burner, _value);
  }
}

contract IDCToken is BurnableToken, Pausable, Saleable {

  address public addrTeam;
  address public addrSale;
  address public addrMine;

  mapping(address => uint256) public tokenAngel;
  mapping(address => uint256) public tokenPrivate;
  mapping(address => uint256) public tokenCrowd;

  uint256 public release = 0;
  uint256 private teamLocked = 0;
  
  uint256 constant private DAY_10 = 10 days;
  uint256 constant private DAY_90 = 90 days;
  uint256 constant private DAY_120 = 120 days;
  uint256 constant private DAY_150 = 150 days;
  uint256 constant private DAY_180 = 180 days;
  uint256 constant private DAY_360 = 360 days;
  uint256 constant private DAY_720 = 720 days;
  
  event TransferToken(uint8 stage, address indexed to, uint256 value);
  event TokenRelease(address caller, uint256 time);

  constructor(address _team, address _sale, address _mine) public {
    name = "IDC Token";
    symbol = "IT";
    decimals = 18;
    totalSupply = 3*10**9*10**uint256(decimals); //3 billion        
    
    addrTeam = _team;
    addrSale = _sale;
    addrMine = _mine;
    
    balances[_team] = totalSupply.mul(2).div(5); //40% for team
    balances[_sale] = totalSupply.mul(1).div(5); //20% for sale
    balances[_mine] = totalSupply.mul(2).div(5); //40% for mining
    teamLocked = balances[_team];    
    
    emit Transfer(0,_team,balances[_team]);
    emit Transfer(0,_sale,balances[_sale]);
    emit Transfer(0,_mine,balances[_mine]);
  }

  function transfer(address _to, uint256 _value) notPaused public returns (bool) {
    if(msg.sender == addrTeam || tokenAngel[msg.sender] > 0 || tokenPrivate[msg.sender] > 0) {
      require(balanceOfUnlocked(msg.sender) >= _value);
    }
    StandToken.transfer(_to, _value);
    return true;
  }
  
  function transferFrom(address _from, address _to, uint256 _value) notPaused public returns (bool) {
    if(_from == addrTeam || tokenAngel[_from] > 0 || tokenPrivate[_from] > 0) {
      require(balanceOfUnlocked(_from) >= _value);
    }
    StandToken.transferFrom(_from, _to, _value);
    return true;
  }  
  
  function balanceOfUnlocked(address _sender) public view returns (uint256) {
    require(release > 0 && now > release);
    uint256 tmPast = now.sub(release);
    uint256 balance = balanceOf(_sender);
    
    if(_sender == addrTeam) {
      if(tmPast < DAY_180) {
        balance = balance.sub(teamLocked);
      }
      else if(tmPast >= DAY_180 && tmPast < DAY_360) {
        balance = balance.sub(teamLocked.mul(7).div(10));
      }
      else if(tmPast >= DAY_360 && tmPast < DAY_720) {
        balance = balance.sub(teamLocked.mul(4).div(10));
      }
    }
    if(tokenAngel[_sender] > 0) {
      if(tmPast < DAY_120) {
        balance = balance.sub(tokenAngel[_sender]);
      }
      else if(tmPast >= DAY_120 && tmPast < DAY_150) {
        balance = balance.sub(tokenAngel[_sender].mul(7).div(10));
      }
      else if(tmPast >= DAY_150 && tmPast < DAY_180) {
        balance = balance.sub(tokenAngel[_sender].mul(4).div(10));
      }
    }
    if(tokenPrivate[_sender] > 0) {
      if(tmPast < DAY_90) {
        balance = balance.sub(tokenPrivate[_sender].div(2));
      }
    }
    return balance;
  }
  
  function transferToken(uint8 _stage, address _to, uint256 _tokens) onlySaler external payable {
    require(_stage >= 0 && _stage <= 2);
    if(_stage == 0) { 
      tokenAngel[_to] = tokenAngel[_to].add(_tokens);
    }
    else if(_stage == 1) {
      tokenPrivate[_to] = tokenPrivate[_to].add(_tokens);
    }
    else if(_stage == 2) { 
      tokenCrowd[_to] = tokenCrowd[_to].add(_tokens);
    }
    balances[addrSale] = balances[addrSale].sub(_tokens);
    balances[_to] = balances[_to].add(_tokens);
    emit Transfer(addrSale, _to, _tokens);
    emit TransferToken(_stage, _to, _tokens);
  }

  function burnToken(uint256 _tokens) onlySaler external returns (bool) {
    require(_tokens > 0);
    balances[addrSale] = balances[addrSale].sub(_tokens);
    totalSupply = totalSupply.sub(_tokens);
    emit Burn(addrSale, _tokens);
  }
  
  function tokenRelease() onlySaler external returns (bool) {
    require(release == 0);
    release = now + DAY_10;
    emit TokenRelease(msg.sender, release);
    return true;
  }
}

contract IDCSale is Pausable {
  
  using SafeMath for uint256;

  IDCToken private token;
  address public beneficiary;

  enum Stage { Angel, Private, Crowd, Finalized, Failed }
  Stage private stage = Stage.Angel;
  uint256 public stageBegin = 0;
  uint256 public stageLength = DAY_30;
  
  uint256 public angelGoal = 0;
  uint256 public angelSaled = 0;
  uint256 public privGoal = 0; 
  uint256 public privSaled = 0;
  uint256 private angelSoftCap = 0; 

  uint256 constant private DAY_10 = 10 days;
  uint256 constant private DAY_20 = 20 days;
  uint256 constant private DAY_30 = 30 days;

  uint256 constant private MIN_ANGLE = 500 ether;
  uint256 constant private MIN_PRIV = 50 ether;
  
  mapping(address => uint256) public recvEthers;

  event RecvEther(address sender, uint256 ethers);
  event WithdrawEther(address sender, uint256 ethers);
  event RefundEther(address sender, uint256 ethers);
  
  constructor(address _token, address _beneficiary) public {
    require(_token != 0 && _beneficiary != 0);

    token = IDCToken(_token); 
    beneficiary = _beneficiary;

    uint256 stageGoal = 3*10**8*10**uint256(token.decimals());
    angelGoal = stageGoal; 
    privGoal = stageGoal;
    angelSoftCap = stageGoal.div(3);
  }
  
  function() external notPaused payable {
    require(stage < Stage.Finalized);
    updateStageByTime();
    uint256 tokens = msg.value.mul(getPrice());

    if(stage == Stage.Angel) {
      require(msg.value >= MIN_ANGLE && angelSaled.add(tokens) <= angelGoal);
      token.transferToken(0, msg.sender, tokens);
      angelSaled = angelSaled.add(tokens);
      recvEthers[msg.sender] = recvEthers[msg.sender].add(msg.value);
      emit RecvEther(msg.sender, msg.value);
    } 
    else if(stage == Stage.Private) {
      require(msg.value >= MIN_PRIV && privSaled.add(tokens) <= privGoal);
      token.transferToken(1, msg.sender, tokens);
      privSaled = privSaled.add(tokens);
      recvEthers[msg.sender] = recvEthers[msg.sender].add(msg.value);
      emit RecvEther(msg.sender, msg.value);
    }
    else if(stage == Stage.Crowd) {
      require(privSaled.add(tokens) <= privGoal);
      token.transferToken(2, msg.sender, tokens);
      privSaled = privSaled.add(tokens);
      recvEthers[msg.sender] = recvEthers[msg.sender].add(msg.value);
      emit RecvEther(msg.sender, msg.value);
    }

    updateStageBySaled();
    if(stage == Stage.Finalized) {
      token.tokenRelease();
      if(angelSaled < angelGoal) {
        token.burnToken(angelGoal.sub(angelSaled));
      }
      if(privSaled < privGoal) {
        token.burnToken(privGoal.sub(privSaled));
      }
    }
  }

  function updateStageByTime() private {
    if(stageBegin == 0)  {
        stageBegin = now;
    }
    uint256 stagePast = now.sub(stageBegin);
    if(stage == Stage.Angel) {
      if(stagePast > stageLength) {
        if(angelSaled >= angelSoftCap) {
          stage = Stage.Private;
        }
        else {
          stage = Stage.Failed;
        }
        stageBegin = now;
        stageLength = DAY_30;
      }
    }
    else if(stage == Stage.Private) {
      if(stagePast > stageLength) {
        stage = Stage.Crowd;
        stageBegin = now;
        stageLength = DAY_30;
      } 
    }
    else if(stage == Stage.Crowd) { 
      if(stagePast > stageLength) {
        stage = Stage.Finalized;
        stageBegin = now;
      } 
    }
  }
  
  function updateStageBySaled() private {
    if(stage == Stage.Angel) {
      if(angelSaled > angelGoal.sub(MIN_ANGLE.mul(getPrice()))) {
        stage = Stage.Private;
        stageBegin = now;
        stageLength = DAY_30;
      }
    }
    else if(stage == Stage.Private) {
      if(privSaled > privGoal.sub(MIN_PRIV.mul(getPrice()))) {
        stage = Stage.Finalized;
        stageBegin = now;
      }
    }
    else if(stage == Stage.Crowd) { 
      if(privSaled >= privGoal) {
        stage = Stage.Finalized;
        stageBegin = now;
      } 
    }
  }
  
  function getPrice() public view returns (uint32) {
    if(stage == Stage.Angel) {
      return 8000;  
    }
    else if(stage == Stage.Private) {
      return 5000;  
    }
    else if(stage == Stage.Crowd) {
      uint256 stagePast = now.sub(stageBegin);
      if(stagePast <= DAY_10) {
        return 4000;  
      }
      else if(stagePast > DAY_10 && stagePast <= DAY_20) {
        return 3000;  
      }
      else if(stagePast > DAY_20 && stagePast <= DAY_30) {
        return 2000;  
      }
    }
    return 2000;
  }
  
  function getStageInfo() public view returns (uint8, uint256, uint256) {
    require(stageBegin != 0);

    uint256 stageUnsold = 0;
    if(stage == Stage.Angel) {
      stageUnsold = angelGoal - angelSaled;  
    }
    else if(stage == Stage.Private || stage == Stage.Crowd) {
      stageUnsold = privGoal - privSaled;  
    }
    uint256 stageRemain = 0;
    if(stageBegin.add(stageLength) > now) {
        stageRemain = stageBegin.add(stageLength).sub(now);
    }
    return (uint8(stage), stageUnsold, stageRemain);
  }
  
  function setStageLength(uint256 _seconds) onlyOwner external {
    require(stageBegin + _seconds > now);
    stageLength = _seconds;
  }

  function withdrawEther(uint256 _ethers) onlyOwner external returns (bool) {
    require(_ethers > 0 && _ethers <= address(this).balance);
    
    beneficiary.transfer(_ethers);
    emit WithdrawEther(beneficiary, _ethers);
    return true;
  }
  
  function refundEther() external returns (bool) {
    require(stage == Stage.Failed); 
    uint256 ethers = recvEthers[msg.sender];
    assert(ethers > 0);
    recvEthers[msg.sender] = 0;
    
    msg.sender.transfer(ethers);
    emit RefundEther(msg.sender, ethers);
    return true;
  }
}