pragma solidity 0.4.17;

// import "./FunderSmartToken.sol";

contract PreSale {

  address private deployer;

  // for performing allowed transfer
  address private FunderSmartTokenAddress = 0x0;
  address private FundersTokenCentral = 0x0;

  // 1 eth = 150 fst
  uint256 public oneEtherIsHowMuchFST = 150;

  // uint256 public startTime = 0;
  uint256 public startTime = 1506052800; // 2017/09/22
  uint256 public endTime   = 1508731200; // 2017/10/22

  uint256 public soldTokenValue = 0;
  uint256 public preSaleHardCap = 330000000 * (10 ** 18) * 2 / 100; // presale 2% hard cap amount

  event BuyEvent (address buyer, string email, uint256 etherValue, uint256 tokenValue);

  function PreSale () public {
    deployer = msg.sender;
  }

  // PreSale Contract 必須先從 Funder Smart Token approve 過
  function buyFunderSmartToken (string _email, string _code) payable public returns (bool) {
    require(FunderSmartTokenAddress != 0x0); // 需初始化過 token contract 位址
    require(FundersTokenCentral != 0x0); // 需初始化過 fstk 中央帳戶
    require(msg.value >= 1 ether); // 人們要至少用 1 ether 買 token
    require(now >= startTime && now <= endTime); // presale 舉辦期間
    require(soldTokenValue <= preSaleHardCap); // 累積 presale 量不得超過 fst 總發行量 2%

    uint256 _tokenValue = msg.value * oneEtherIsHowMuchFST;

    // 35%
    if (keccak256(_code) == 0xde7683d6497212fbd59b6a6f902a01c91a09d9a070bba7506dcc0b309b358eed) {
      _tokenValue = _tokenValue * 135 / 100;
    }

    // 30%
    if (keccak256(_code) == 0x65b236bfb931f493eb9e6f3db8d461f1f547f2f3a19e33a7aeb24c7e297c926a) {
      _tokenValue = _tokenValue * 130 / 100;
    }

    // 25%
    if (keccak256(_code) == 0x274125681e11c33f71574f123a20cfd59ed25e64d634078679014fa3a872575c) {
      _tokenValue = _tokenValue * 125 / 100;
    }

    // 將 FST 從 FundersTokenCentral 轉至 msg.sender
    if (FunderSmartTokenAddress.call(bytes4(keccak256("transferFrom(address,address,uint256)")), FundersTokenCentral, msg.sender, _tokenValue) != true) {
      revert();
    }

    BuyEvent(msg.sender, _email, msg.value, _tokenValue);

    soldTokenValue = soldTokenValue + _tokenValue;

    return true;
  }

  // 把以太幣傳出去
  function transferOut (address _to, uint256 _etherValue) public returns (bool) {
    require(msg.sender == deployer);
    _to.transfer(_etherValue);
    return true;
  }

  // 指定 FST Token Contract (FunderSmartTokenAddress)
  function setFSTAddress (address _funderSmartTokenAddress) public returns (bool) {
    require(msg.sender == deployer);
    FunderSmartTokenAddress = _funderSmartTokenAddress;
    return true;
  }

  // 指定 FSTK 主帳 (FundersTokenCentral)
  function setFSTKCentral (address _fundersTokenCentral) public returns (bool) {
    require(msg.sender == deployer);
    FundersTokenCentral = _fundersTokenCentral;
    return true;
  }

  function () public {}

}