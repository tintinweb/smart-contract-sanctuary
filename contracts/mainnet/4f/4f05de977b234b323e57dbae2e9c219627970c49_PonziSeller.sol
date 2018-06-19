pragma solidity ^0.4.18;

// see: https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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



// Ponzi Token Minimal Interface
contract PonziTokenMinInterface {
  function balanceOf(address owner) public view returns(uint256);
  function transfer(address to, uint256 value) public returns (bool);
}


contract PonziSeller {
  using SafeMath for uint256;
  enum AccessRank {
    None,
    SetPrice,
    Withdraw,
    Full
  }

  address private constant PONZI_ADDRESS = 0xc2807533832807Bf15898778D8A108405e9edfb1;
  PonziTokenMinInterface private m_ponzi;
  uint256 private m_ponziPriceInWei;
  uint256 private m_rewardNum;
  uint256 private m_rewardDen;
  mapping(address => AccessRank) private m_admins;

  event PriceChanged(address indexed who, uint256 newPrice);
  event RewardRef(address indexed refAddr, uint256 ponziAmount);
  event Withdrawal(address indexed to, uint256 amountInWei);
  event ProvidingAccess(address indexed addr, AccessRank rank);
  event PonziSold(
    address indexed purchasedBy, 
    uint256 indexed priceInWei, 
    uint256 ponziAmount, 
    uint256 weiAmount, 
    address indexed refAddr 
  );
  event NotEnoughPonzi(
    address indexed addr, 
    uint256 weiAmount, 
    uint256 ponziPriceInWei, 
    uint256 ponziBalance
  );

  modifier onlyAdmin(AccessRank  r) {
    require(m_admins[msg.sender] == r || m_admins[msg.sender] == AccessRank.Full);
    _;
  }

  function PonziSeller() public {
    m_ponzi = PonziTokenMinInterface(PONZI_ADDRESS);
    m_admins[msg.sender] = AccessRank.Full;
    m_rewardNum = 1;
    m_rewardDen = 1;
  }

  function() public payable {
    byPonzi(address(0));
  }

  function setPonziAddress(address ponziAddr) public onlyAdmin(AccessRank.Full) {
    m_ponzi = PonziTokenMinInterface(ponziAddr);
  }

  function ponziAddress() public view returns (address ponziAddr) {
    return address(m_ponzi);
  }

  function ponziPriceInWei() public view returns (uint256) { 
    return m_ponziPriceInWei;
  }

  function setPonziPriceInWei(uint256 newPonziPriceInWei) public onlyAdmin(AccessRank.SetPrice) { 
    m_ponziPriceInWei = newPonziPriceInWei;
    emit PriceChanged(msg.sender, m_ponziPriceInWei);
  }

  function rewardPercent() public view returns (uint256 numerator, uint256 denominator) {
    numerator = m_rewardNum;
    denominator = m_rewardDen;
  }

  function provideAccess(address adminAddr, uint8 rank) public onlyAdmin(AccessRank.Full) {
    require(rank <= uint8(AccessRank.Full));
    require(m_admins[adminAddr] != AccessRank.Full);
    m_admins[adminAddr] = AccessRank(rank);
  }

  function setRewardPercent(uint256 newNumerator, uint256 newDenominator) public onlyAdmin(AccessRank.Full) {
    require(newDenominator != 0);
    m_rewardNum = newNumerator;
    m_rewardDen = newDenominator;
  }

  function byPonzi(address refAddr) public payable {
    require(m_ponziPriceInWei > 0 && msg.value > m_ponziPriceInWei);

    uint256 refAmount = 0;
    uint256 senderAmount = weiToPonzi(msg.value, m_ponziPriceInWei);

    // check if ref addres is valid and calc reward
    if (refAddr != msg.sender && refAddr != address(0) && refAddr != address(this)) {
      refAmount = senderAmount.mul(m_rewardNum).div(m_rewardDen);
    }
    // check if we have enough ponzi on balance
    if (availablePonzi() < senderAmount.add(refAmount)) {
      emit NotEnoughPonzi(msg.sender, msg.value, m_ponziPriceInWei, availablePonzi());
      revert();
    }
  
    // transfer ponzi to sender
    require(m_ponzi.transfer(msg.sender, senderAmount));
    // transfer ponzi to ref if needed
    if (refAmount > 0) {
      require(m_ponzi.transfer(refAddr, refAmount));
      emit RewardRef(refAddr, refAmount);
    }
    emit PonziSold(msg.sender, m_ponziPriceInWei, senderAmount, msg.value, refAddr);
  }

  function availablePonzi() public view returns (uint256) {
    return m_ponzi.balanceOf(address(this));
  }

  function withdraw() public onlyAdmin(AccessRank.Withdraw) {
    require(address(this).balance > 0);
    uint256 b = address(this).balance;
    msg.sender.transfer(b);
    assert(address(this).balance < b);
    emit Withdrawal(msg.sender, b);
  }

  function weiToPonzi(uint256 weiAmount, uint256 tokenPrice) 
    internal 
    pure 
    returns(uint256 tokensAmount) 
  {
    tokensAmount = weiAmount.div(tokenPrice);
  }
}