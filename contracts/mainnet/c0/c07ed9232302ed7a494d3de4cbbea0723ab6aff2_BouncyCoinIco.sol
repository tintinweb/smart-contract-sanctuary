pragma solidity ^0.4.24;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract BouncyCoinIco {

  event TokensSold(address buyer, uint256 tokensAmount, uint256 ethAmount);

  struct PriceThreshold {
    uint256 tokenCount;
    uint256 price;
    uint256 tokensSold;
  }

  uint256 public constant PRE_ICO_TOKENS = 10000000 * 10**18;
  uint256 public constant PRE_ICO_PRICE = 0.00010 * 10**18;

  uint256 public constant PRE_ICO_MINIMUM_CONTRIBUTION = 5 ether;
  uint256 public constant ICO_MINIMUM_CONTRIBUTION = 0.1 ether;

  uint256 public maxPreIcoDuration;
  uint256 public maxIcoDuration;

  address public owner;

  address public wallet;

  ERC20 public bouncyCoinToken;

  uint256 public startBlock;
  uint256 public preIcoEndBlock;
  uint256 public icoEndBlock;

  uint256 public preIcoTokensSold;
  PriceThreshold[2] public icoPriceThresholds;

  /* Current stage */
  Stages public stage;

  enum Stages {
    Deployed,
    SetUp,
    StartScheduled,
    PreIcoStarted,
    IcoStarted,
    Ended
  }

  /* Modifiers */

  modifier atStage(Stages _stage) {
    require(stage == _stage);
    _;
  }

  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier isValidPayload() {
    require(msg.data.length == 0 || msg.data.length == 4);
    _;
  }

  modifier timedTransitions() {
    if (stage == Stages.StartScheduled && block.number >= startBlock) {
      startPreIco();
    }
    if (stage == Stages.PreIcoStarted && block.number >= preIcoEndBlock) {
      startIco();
    }
    if (stage == Stages.IcoStarted && block.number >= icoEndBlock) {
      finalize();
    }
    _;
  }

  /* Constructor */

  constructor(address _wallet)
    public {
    require(_wallet != 0x0);

    owner = msg.sender;
    wallet = _wallet;
    stage = Stages.Deployed;
  }

  /* Public functions */

  function()
    public
    payable
    timedTransitions {
    if (stage == Stages.PreIcoStarted) {
      buyPreIcoTokens();
    } else if (stage == Stages.IcoStarted) {
      buyIcoTokens();
    } else {
      revert();
    }
  }

  function setup(address _bouncyCoinToken, uint256 _maxPreIcoDuration, uint256 _maxIcoDuration)
    public
    isOwner
    atStage(Stages.Deployed) {
    require(_bouncyCoinToken != 0x0);
    require(_maxPreIcoDuration > 0);
    require(_maxIcoDuration > 0);

    icoPriceThresholds[0] = PriceThreshold(20000000 * 10**18, 0.00020 * 10**18, 0);
    icoPriceThresholds[1] = PriceThreshold(50000000 * 10**18, 0.00025 * 10**18, 0);

    bouncyCoinToken = ERC20(_bouncyCoinToken);
    maxPreIcoDuration = _maxPreIcoDuration;
    maxIcoDuration = _maxIcoDuration;

    // validate token balance
    uint256 tokensRequired = PRE_ICO_TOKENS + maxIcoTokensSold();
    assert(bouncyCoinToken.balanceOf(this) == tokensRequired);

    stage = Stages.SetUp;
  }

  function maxIcoTokensSold()
    public
    constant
    returns (uint256) {
    uint256 total = 0;
    for (uint8 i = 0; i < icoPriceThresholds.length; i++) {
      total += icoPriceThresholds[i].tokenCount;
    }
    return total;
  }

  function totalIcoTokensSold()
    public
    constant
    returns (uint256) {
    uint256 total = 0;
    for (uint8 i = 0; i < icoPriceThresholds.length; i++) {
      total += icoPriceThresholds[i].tokensSold;
    }
    return total;
  }

  /* Schedules the start */
  function scheduleStart(uint256 _startBlock)
    public
    isOwner
    atStage(Stages.SetUp) {
    startBlock = _startBlock;
    preIcoEndBlock = startBlock + maxPreIcoDuration;
    stage = Stages.StartScheduled;
  }

  function updateStage()
    public
    timedTransitions
    returns (Stages) {
    return stage;
  }

  function buyPreIcoTokens()
    public
    payable
    isValidPayload
    timedTransitions
    atStage(Stages.PreIcoStarted) {
    require(msg.value >= PRE_ICO_MINIMUM_CONTRIBUTION);

    uint256 amountRemaining = msg.value;

    uint256 tokensAvailable = PRE_ICO_TOKENS - preIcoTokensSold;
    uint256 maxTokensByAmount = amountRemaining * 10**18 / PRE_ICO_PRICE;

    uint256 tokensToReceive = 0;
    if (maxTokensByAmount > tokensAvailable) {
      tokensToReceive = tokensAvailable;
      amountRemaining -= (PRE_ICO_PRICE * tokensToReceive) / 10**18;
    } else {
      tokensToReceive = maxTokensByAmount;
      amountRemaining = 0;
    }
    preIcoTokensSold += tokensToReceive;

    assert(tokensToReceive > 0);

    if (amountRemaining != 0) {
      msg.sender.transfer(amountRemaining);
    }

    uint256 amountAccepted = msg.value - amountRemaining;
    wallet.transfer(amountAccepted);

    if (preIcoTokensSold == PRE_ICO_TOKENS) {
      startIco();
    }

    emit TokensSold(msg.sender, tokensToReceive, amountAccepted);
  }

  function buyIcoTokens()
    public
    payable
    isValidPayload
    timedTransitions
    atStage(Stages.IcoStarted) {
    require(msg.value >= ICO_MINIMUM_CONTRIBUTION);

    uint256 amountRemaining = msg.value;
    uint256 tokensToReceive = 0;

    for (uint8 i = 0; i < icoPriceThresholds.length; i++) {
      uint256 tokensAvailable = icoPriceThresholds[i].tokenCount - icoPriceThresholds[i].tokensSold;
      uint256 maxTokensByAmount = amountRemaining * 10**18 / icoPriceThresholds[i].price;

      uint256 tokens;
      if (maxTokensByAmount > tokensAvailable) {
        tokens = tokensAvailable;
        amountRemaining -= (icoPriceThresholds[i].price * tokens) / 10**18;
      } else {
        tokens = maxTokensByAmount;
        amountRemaining = 0;
      }
      icoPriceThresholds[i].tokensSold += tokens;
      tokensToReceive += tokens;
    }

    assert(tokensToReceive > 0);

    if (amountRemaining != 0) {
      msg.sender.transfer(amountRemaining);
    }

    uint256 amountAccepted = msg.value - amountRemaining;
    wallet.transfer(amountAccepted);

    if (totalIcoTokensSold() == maxIcoTokensSold()) {
      finalize();
    }

    emit TokensSold(msg.sender, tokensToReceive, amountAccepted);
  }

  function stop()
    public
    isOwner {
    finalize();
  }

  function finishPreIcoAndStartIco()
    public
    isOwner
    timedTransitions
    atStage(Stages.PreIcoStarted) {
    startIco();
  }

  /* Private functions */

  function startPreIco()
    private {
    stage = Stages.PreIcoStarted;
  }

  function startIco()
    private {
    stage = Stages.IcoStarted;
    icoEndBlock = block.number + maxIcoDuration;
  }

  function finalize()
    private {
    stage = Stages.Ended;
  }

  // In case of accidental ether lock on contract
  function withdraw()
    public
    isOwner {
    owner.transfer(address(this).balance);
  }

  // In case of accidental token transfer to this address, owner can transfer it elsewhere
  function transferERC20Token(address _tokenAddress, address _to, uint256 _value)
    public
    isOwner {
    ERC20 token = ERC20(_tokenAddress);
    assert(token.transfer(_to, _value));
  }

}