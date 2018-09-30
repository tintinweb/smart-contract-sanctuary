pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
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

contract BruceCoinIco {

  event TokensSold(address indexed buyer, uint256 amount);

  struct PriceThreshold {
    uint256 tokenCount;
    uint256 price;
    uint256 tokensSold;
  }

  uint256 public maxDuration;

  address public owner;

  address public wallet;

  ERC20 public bouncyCoinToken;

  uint256 public startBlock;

  uint256 public endBlock;

  PriceThreshold[3] public priceThresholds;

  /* Current stage */
  Stages public stage;

  enum Stages {
    Deployed,
    SetUp,
    StartScheduled,
    Started,
    Ended
  }

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
      stage = Stages.Started;
    }
    if (stage == Stages.Started && block.number >= endBlock) {
      finalize();
    }
    _;
  }

  constructor(address _wallet)
    public {
    require(_wallet != 0x0);

    owner = msg.sender;
    wallet = _wallet;
    stage = Stages.Deployed;
  }

  /* Fallback function */
  function()
    public
    payable
    timedTransitions {
    if (stage == Stages.Started) {
      buyTokens();
    } else {
      revert();
    }
  }

  function setup(address _bouncyCoinToken, uint256 _maxDuration)
    public
    isOwner
    atStage(Stages.Deployed)
  {
    require(_bouncyCoinToken != 0x0);
    require(_maxDuration > 0);

    priceThresholds[0] = PriceThreshold(1000000 * 10**18, 0.00010 * 10**18, 0);
    priceThresholds[1] = PriceThreshold(2000000 * 10**18, 0.00020 * 10**18, 0);

    bouncyCoinToken = ERC20(_bouncyCoinToken);
    maxDuration = _maxDuration;

    // Validate token balance
    assert(bouncyCoinToken.balanceOf(this) == maxTokensSold());

    stage = Stages.SetUp;
  }

  function maxTokensSold()
    public
    constant
    returns (uint256) {
    uint256 total = 0;
    for (uint8 i = 0; i < priceThresholds.length; i++) {
      total += priceThresholds[i].tokenCount;
    }
    return total;
  }

  function totalTokensSold()
    public
    constant
    returns (uint256) {
    uint256 total = 0;
    for (uint8 i = 0; i < priceThresholds.length; i++) {
      total += priceThresholds[i].tokensSold;
    }
    return total;
  }

  /* Schedules start of the ICO */
  function scheduleStart(uint256 _startBlock)
    public
    isOwner
    atStage(Stages.SetUp)
  {
    startBlock = _startBlock;
    endBlock = startBlock + maxDuration;
    stage = Stages.StartScheduled;
  }

  function updateStage()
    public
    timedTransitions
    returns (Stages)
  {
    return stage;
  }

  function buyTokens()
    public
    payable
    isValidPayload
    timedTransitions
    atStage(Stages.Started)
  {
    require(msg.value > 0);

    uint256 amountRemaining = msg.value;
    uint256 tokensToReceive = 0;

    for (uint8 i = 0; i < priceThresholds.length; i++) {
      uint256 tokensAvailable = priceThresholds[i].tokenCount - priceThresholds[i].tokensSold;
      uint256 maxTokensByAmount = amountRemaining * 10**18 / priceThresholds[i].price;

      uint256 tokens;
      if (maxTokensByAmount > tokensAvailable) {
        tokens = tokensAvailable;
        amountRemaining -= (priceThresholds[i].price * tokens) / 10**18;
      } else {
        tokens = maxTokensByAmount;
        amountRemaining = 0;
      }
      priceThresholds[i].tokensSold += tokens;
      tokensToReceive += tokens;
    }

    assert(tokensToReceive > 0);

    if (amountRemaining != 0) {
      msg.sender.transfer(amountRemaining);
    }

    wallet.transfer(msg.value - amountRemaining);
    assert(bouncyCoinToken.transfer(msg.sender, tokensToReceive));

    if (totalTokensSold() == maxTokensSold()) {
      finalize();
    }

    emit TokensSold(msg.sender, tokensToReceive);
  }

  function finalize()
    private
  {
    stage = Stages.Ended;
  }

  // In case of accidental ether lock on contract
  function withdraw()
    public
    isOwner
  {
    owner.transfer(address(this).balance);
  }

  // In case of accidental token transfer to this address, owner can transfer it elsewhere
  function transferERC20Token(address _tokenAddress, address _to, uint256 _value)
    public
    isOwner
  {
    ERC20 token = ERC20(_tokenAddress);
    assert(token.transfer(_to, _value));
  }

}