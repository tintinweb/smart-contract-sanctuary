/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
  function balanceOf(address _account) external view returns (uint256);
  function transfer(address _to, uint256 _amount) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
  function transferAndFreeze(address _to, uint256 _amount) external returns (bool);
}

interface IPancakePair {
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// This contract should have owner role of BADGE token
contract Sales {
  mapping(address => bool) public owners;
  IERC20 public badge;
  IERC20 public edge;
  IERC20 public busd;
  IERC20 public wbnb;
  IPancakePair public bnbBusdPair;
  IPancakePair public badgeBnbPair;
  IPancakePair public edgeBnbPair;

  uint256 public staticPrice;
  bool public dynamicPricing = true;

  // Constant
  uint256 public TARGET_SALES = 100000000 * 1e18; // 1 million BADGE
  uint256 public INITIAL_PRICE = 16745000000000; // 1 JPY
  uint256 public FINAL_PRICE = 167450000000000; // 10 JPY
  uint256 public EDGE_PRICE = 16745000000000; // 1 JPY

  modifier onlyOwner {
      require(owners[msg.sender], 'Sales: onlyOwner');
      _;
  }

  constructor() {
    owners[msg.sender] = true;
  }

  // Admin
  function setOwner(address _owner) external onlyOwner returns (bool) {
    owners[_owner] = true;
    return true;
  }

  function removeOwner(address _owner) external onlyOwner returns (bool) {
    require(_owner != msg.sender, "Sales: Cannot remove yourself");
    owners[_owner] = false;
    return true;
  }

  // BEP20 Token Addresses
  function setTokens(address _wbnb, address _busd, address _badge, address _edge) external onlyOwner returns (bool) {
    wbnb = IERC20(_wbnb);
    busd = IERC20(_busd);
    badge = IERC20(_badge);
    edge = IERC20(_edge);
    return true;
  }

  // PancakePair Contracts
  function setPairs(address _bnbBusdPair, address _badgeBnbPair, address _edgeBnbPair) external onlyOwner returns (bool) {
    bnbBusdPair = IPancakePair(_bnbBusdPair);
    badgeBnbPair = IPancakePair(_badgeBnbPair);
    edgeBnbPair = IPancakePair(_edgeBnbPair);
    return true;
  }

  // Price Config
  function setStaticPrice(uint256 _staticPrice) external onlyOwner returns (bool) {
    staticPrice = _staticPrice;
    return true;
  }

  function setDynamicParameters(uint256 _targetSales, uint256 _initialPrice, uint256 _finalPrice) external onlyOwner returns (bool) {
    TARGET_SALES = _targetSales;
    INITIAL_PRICE = _initialPrice;
    FINAL_PRICE = _finalPrice;
    return true;
  }

  function setDynamicPricing(bool _dynamicPricing) external onlyOwner returns (bool) {
    dynamicPricing = _dynamicPricing;
    return true;
  }

  function setEdgePrice(uint256 _edgePrice) external onlyOwner returns (bool) {
    EDGE_PRICE = _edgePrice;
    return true;
  }

  // Withdrawal
  function withdrawBNB(uint256 _amount) external onlyOwner returns (bool) {
    if (_amount > 0) {
      payable(msg.sender).transfer(_amount);
    } else {
      payable(msg.sender).transfer(address(this).balance);
    }
    return true;
  }

  function withdrawToken(address _tokenAddress, uint256 _amount) external onlyOwner returns (bool) {
    IERC20 token = IERC20(_tokenAddress);
    if (_amount > 0) {
      token.transfer(msg.sender, _amount);
    } else {
      token.transfer(msg.sender, token.balanceOf(address(this)));
    }
    return true;
  }

  // View
  function getMarketPrice() external view returns (uint256 badgePriceInBnb, uint256 badgePriceInUsd, uint256 edgePriceInBnb, uint256 edgePriceInUsd) {
    (uint112 badgeReserveInBadgeBnbPool, uint112 bnbReserveInBadgeBnbPool, ) = badgeBnbPair.getReserves();
    badgePriceInBnb =  bnbReserveInBadgeBnbPool * 1e18 / badgeReserveInBadgeBnbPool;
    badgePriceInUsd = convertBnbToUsd(badgePriceInBnb);

    (uint112 edgeReserveInEdgeBnbPool, uint112 bnbReserveInEdgeBnbPool, ) = badgeBnbPair.getReserves();
    edgePriceInBnb =  bnbReserveInEdgeBnbPool * 1e18 / edgeReserveInEdgeBnbPool;
    edgePriceInUsd = convertBnbToUsd(badgePriceInBnb);
  }

  function getBadgePrice() public view returns (uint256 priceBnb, uint256 priceUsd) {
    if (dynamicPricing) {
      priceBnb = FINAL_PRICE - (FINAL_PRICE - INITIAL_PRICE) * getStock() / TARGET_SALES;
    } else {
      priceBnb = staticPrice;
    }
    priceUsd = convertBnbToUsd(priceBnb);
  }

  function getEdgeBalanceOf(address _account) public view returns (uint256 balance, uint256 balanceUsd) {
    balance = edge.balanceOf(_account);
    balanceUsd = convertBnbToUsd(convertEdgeToBnb(balance));
  }

  function convertBadgeToBnb(uint256 _badgeAmount) public view returns (uint256) {
    (uint256 priceBnb, ) = getBadgePrice();
    return _badgeAmount * priceBnb / 1e18;
  }

  // Conversion Utilities
  function convertBnbToUsd(uint256 _bnbAmount) public view returns (uint256) {
    (uint112 reserve0, uint112 reserve1, ) = bnbBusdPair.getReserves();
    uint112 busdReserve = address(busd) < address(wbnb) ? reserve0 : reserve1;
    uint112 wbnbReserve = address(busd) < address(wbnb) ? reserve1 : reserve0;
    uint256 usdAmount = _bnbAmount * busdReserve / wbnbReserve;
    return usdAmount;
  }

  function convertUsdToBnb(uint256 _usdAmount) public view returns (uint256) {
    (uint112 reserve0, uint112 reserve1, ) = bnbBusdPair.getReserves();
    uint112 busdReserve = address(busd) < address(wbnb) ? reserve0 : reserve1;
    uint112 wbnbReserve = address(busd) < address(wbnb) ? reserve1 : reserve0;
    uint256 bnbAmount = _usdAmount * wbnbReserve / busdReserve;
    return bnbAmount;
  }

  function convertEdgeToBnb(uint256 _edgeAmount) public view returns (uint256) {
    uint256 bnbAmount = _edgeAmount * EDGE_PRICE / 1e18;
    return bnbAmount;
  }

  function convertBnbToEdge(uint256 _bnbAmount) public view returns (uint256) {
    uint256 edgeAmount = _bnbAmount * 1e18 / EDGE_PRICE;
    return edgeAmount;
  }

  function getQuote(uint256 _badgeAmount, uint256 _edgeBalance) public view returns (
      uint256 subtotalBnb,
      uint256 subtotalUsd,
      uint256 discountEdge,
      uint256 discountUsd,
      uint256 totalBnb,
      uint256 totalUsd) {
    subtotalBnb = convertBadgeToBnb(_badgeAmount);
    subtotalUsd = convertBnbToUsd(subtotalBnb);

    uint256 discountBnb = subtotalBnb / 2;
    discountEdge = convertBnbToEdge(discountBnb);
    discountEdge = discountEdge > _edgeBalance ? _edgeBalance : discountEdge;
    discountBnb = convertEdgeToBnb(discountEdge);
    discountUsd = convertBnbToUsd(discountBnb);

    totalBnb = subtotalBnb - discountBnb;
    totalUsd = subtotalUsd - discountUsd;
  }

  function getStock() public view returns (uint256) {
    return badge.balanceOf(address(this));
  }

  // External
  function buy(uint256 _badgeAmount, uint256 _edgeAmount) external payable returns (bool) {
    // Check
    uint256 edgeBalance  = _edgeAmount > 0 ? edge.balanceOf(msg.sender) : 0;
    (, , uint256 discountEdge, , uint256 totalBnb, ) = getQuote(_badgeAmount, edgeBalance);
    require(msg.value >= totalBnb, 'Sales: insufficient BNB balance');
    require(edge.balanceOf(msg.sender) >= discountEdge, 'Sales: insufficient EDGE balance');

    // Interaction
    if(discountEdge > 0 ) edge.transferFrom(msg.sender, address(this), discountEdge);
    badge.transferAndFreeze(msg.sender, _badgeAmount);

    return true;
  }
}