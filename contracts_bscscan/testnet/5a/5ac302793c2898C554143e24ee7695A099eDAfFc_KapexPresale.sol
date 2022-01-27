//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./interfaces/IERC20.sol";

contract KapexPresale {
  address private owner;

  address private presaleToken; // KAPEX
  address private houseToken; // KODA

  uint256 private price; // How much KAPEX the address gets for 1 BNB (only 2 decimals included)
  uint256 private minHouseTokenHoldAmount; // How much KODA the address needs to own (in wei)

  uint256 private minBNB; // In wei
  uint256 private maxBNB; // In wei
  uint256 private startDateBuy; // Timestamp
  uint256 private startDateClaim; // Timestamp
  uint256 private maxPurchase; // In wei (Max amount of bnb he can spend)

  bool private buyPaused = false; // Buy is avaialable from the start
  bool private claimPaused = true; // Claiming is not available, would be started later
  bool private ended = false; // This ends both buying and claiming

  mapping(address => uint256) public bought; // BNB spent by account
  mapping(address => string) public allocatedBand; // If the address doesn't belong to any band, the value will be ""
  mapping(string => uint256) public bandsPercentages; // Band percentages is added to the initial price, 10^9 is considered 100%

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  constructor(
    address _presaleToken,
    address _houseToken,
    uint256 _price,
    uint256 _minHouseTokenHoldAmount,
    uint256 _startDateBuy,
    uint256 _startDateClaim,
    uint256 _minBNB,
    uint256 _maxBNB,
    uint256 _maxPurchase
  ) {
    require(_startDateBuy >= block.timestamp, "_startDateBuy has to be greater than block.timestamp");
    require(_startDateClaim >= block.timestamp, "_startDateClaim has to be greater than block.timestamp");

    owner = msg.sender;

    presaleToken = _presaleToken;
    houseToken = _houseToken;
    startDateBuy = _startDateBuy;
    startDateClaim = _startDateClaim;
    price = _price;
    minBNB = _minBNB;
    maxBNB = _maxBNB;
    maxPurchase = _maxPurchase;
    minHouseTokenHoldAmount = _minHouseTokenHoldAmount;

    bandsPercentages["0"] = 100000000; // +10%
    bandsPercentages["A"] = 75000000; // +7.5%
    bandsPercentages["B"] = 50000000; // +5%
    bandsPercentages["C"] = 25000000; // +2.5%
    bandsPercentages["D"] = 0; // Normal price
  }

  //////////
  // Getters
  function calculateBNBToPresaleToken(uint256 _amount) public view returns (uint256) {
    require(presaleToken != address(0), "Presale token not set");

    uint256 tokens = ((_amount * price) / 100) / (10**(18 - uint256(IERC20(presaleToken).decimals())));

    uint256 tokensWithBand = tokens + (tokens * bandsPercentages[allocatedBand[msg.sender]]) / 10**9;

    return (tokensWithBand);
  }

  function getOwner() external view returns (address) {
    return (owner);
  }

  function getPresaleToken() external view returns (address) {
    return (presaleToken);
  }

  function getHouseToken() external view returns (address) {
    return (houseToken);
  }

  function getPrice() external view returns (uint256) {
    return (price);
  }

  function getMinHouseTokenHoldAmount() external view returns (uint256) {
    return (minHouseTokenHoldAmount);
  }

  function getMaxPurcase() external view returns (uint256) {
    return (maxPurchase);
  }

  function getMinBNB() external view returns (uint256) {
    return (minBNB);
  }

  function getMaxBNB() external view returns (uint256) {
    return (maxBNB);
  }

  function getStartDateBuy() external view returns (uint256) {
    return (startDateBuy);
  }

  function getStartDateClaim() external view returns (uint256) {
    return (startDateClaim);
  }

  function isBuyPaused() external view returns (bool) {
    return (buyPaused);
  }

  function isClaimPaused() external view returns (bool) {
    return (claimPaused);
  }

  function isEnded() external view returns (bool) {
    return (ended);
  }

  /////////////
  // Buy tokens

  receive() external payable {
    buy();
  }

  function buy() public payable {
    require(block.timestamp > startDateBuy, "Sale hasn't started yet");
    require(!buyPaused, "Buying is paused");
    require(!ended, "Sale has ended");
    require(bytes(allocatedBand[msg.sender]).length > 0, "msg.sender does not belong to any band (not whitelisted)");
    require(IERC20(houseToken).balanceOf(msg.sender) >= minHouseTokenHoldAmount, "msg.sender doesn't hold enough Koda");
    require(bought[msg.sender] + msg.value <= maxPurchase, "Cannot buy more than max purchase amount");
    require(msg.value >= minBNB, "msg.value is less than minBNB");
    require(msg.value <= maxBNB, "msg.value is great than maxBNB");

    bought[msg.sender] = bought[msg.sender] + msg.value;
  }

  function claim() public {
    require(block.timestamp > startDateClaim, "Claim hasn't started yet");
    require(!claimPaused, "Claiming is paused");
    require(!ended, "Sale has ended");
    require(bought[msg.sender] > 0, "msg.sender has nothing to claim");
    require(presaleToken != address(0), "Presale token not set");
    require(bytes(allocatedBand[msg.sender]).length > 0, "msg.sender does not belong to any band");

    uint256 amount = calculateBNBToPresaleToken(bought[msg.sender]);

    require(
      IERC20(presaleToken).balanceOf(address(this)) >= amount,
      "Contract doesn't have enough presale tokens. Please contact owner to add more supply"
    );

    bought[msg.sender] = 0;

    IERC20(presaleToken).transfer(msg.sender, amount);
  }

  //////////////////
  // Owner functions

  function setOwner(address _owner) external onlyOwner {
    owner = _owner;
  }

  function setBandPercentage(string calldata _band, uint256 _percentage) external onlyOwner {
    bandsPercentages[_band] = _percentage;
  }

  function setBands(address[] calldata _wallets, string calldata _band) external onlyOwner {
    for (uint256 i = 0; i < _wallets.length; i++) allocatedBand[_wallets[i]] = _band;
  }

  function setBand(address _wallet, string calldata _band) external onlyOwner {
    allocatedBand[_wallet] = _band;
  }

  function withdrawBNB(uint256 _amount, address _receiver) external onlyOwner {
    payable(_receiver).transfer(_amount);
  }

  function setPresaleToken(address _presaleToken, address _receiver) external onlyOwner {
    if (presaleToken != address(0)) {
      uint256 contractBal = IERC20(presaleToken).balanceOf(address(this));
      if (contractBal > 0) IERC20(presaleToken).transfer(_receiver, contractBal);
    }

    presaleToken = _presaleToken;
  }

  function setStartDateBuy(uint256 _startDateBuy) external onlyOwner {
    startDateBuy = _startDateBuy;
  }

  function setStartDateClaim(uint256 _startDateClaim) external onlyOwner {
    startDateClaim = _startDateClaim;
  }

  function setHouseToken(address _houseToken) external onlyOwner {
    houseToken = _houseToken;
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setMinHouseTokenHoldAmount(uint256 _minHouseTokenHoldAmount) external onlyOwner {
    minHouseTokenHoldAmount = _minHouseTokenHoldAmount;
  }

  function setMaxPurchase(uint256 _maxPurchase) external onlyOwner {
    maxPurchase = _maxPurchase;
  }

  function setMinBNB(uint256 _minBNB) external onlyOwner {
    minBNB = _minBNB;
  }

  function setMaxBNB(uint256 _maxBNB) external onlyOwner {
    maxBNB = _maxBNB;
  }

  function setBuyPause() external onlyOwner {
    if (buyPaused) {
      buyPaused = false;
    } else {
      buyPaused = true;
    }
  }

  function setClaimPause() external onlyOwner {
    if (claimPaused) {
      require(presaleToken != address(0), "Presale token not set");

      claimPaused = false;
    } else {
      claimPaused = true;
    }
  }

  function endSale(address _receiver) external onlyOwner {
    require(presaleToken != address(0), "Presale token not set");

    uint256 contractBal = IERC20(presaleToken).balanceOf(address(this));
    if (contractBal > 0) IERC20(presaleToken).transfer(_receiver, contractBal);

    ended = true;
    buyPaused = true;
    claimPaused = true;
  }

  function reset(
    address _presaleToken,
    address _houseToken,
    uint256 _price,
    uint256 _minHouseTokenHoldAmount,
    uint256 _startDateBuy,
    uint256 _startDateClaim,
    uint256 _minBNB,
    uint256 _maxBNB
  ) external onlyOwner {
    require(_startDateBuy > block.timestamp, "_startDateBuy has to be greater than block.timestamp");
    require(_startDateClaim > block.timestamp, "_startDateClaim has to be greater than block.timestamp");
    require(ended, "end the sale first");

    ended = false;
    buyPaused = false;
    claimPaused = false;
    presaleToken = _presaleToken;
    houseToken = _houseToken;
    price = _price;
    minHouseTokenHoldAmount = _minHouseTokenHoldAmount;
    startDateBuy = _startDateBuy;
    startDateClaim = _startDateClaim;
    minBNB = _minBNB;
    maxBNB = _maxBNB;
  }
}

pragma solidity >=0.5.0;

interface IERC20 {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
}