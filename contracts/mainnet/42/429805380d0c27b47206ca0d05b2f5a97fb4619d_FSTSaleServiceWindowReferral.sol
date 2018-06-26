pragma solidity ^0.4.24;

contract ERC20 {
  function balanceOf (address owner) public view returns (uint256);
  function transfer (address to, uint256 value) public returns (bool);
}

contract FSTSaleServiceWindowReferral {
  using Math for uint256;

  address public owner;
  address private rf = address(0);

  bytes32 private secretHash;
  ERC20 public funderSmartToken;
  Math.Fraction public fstPrice;

  uint256 public totalEtherReceived = 0;

  bool public isEnabled = true;
  bool public finalized = false;

  event TokenPurchase(
    ERC20 indexed token,
    address indexed buyer,
    address indexed receiver,
    uint256 value,
    uint256 amount
  );
  
  event RFDeclare(address rf);
  event Finalize(address receiver, address rf, uint256 fstkRevenue);

  constructor (
    address _fstAddress,
    bytes32 _secretHash
  ) public {
    owner = msg.sender;
    secretHash = _secretHash;
    funderSmartToken = ERC20(_fstAddress);
    fstPrice.numerator = 1;
    fstPrice.denominator = 3600;
  }

  function () public payable {
    uint256 available = funderSmartToken.balanceOf(address(this));
    uint256 revenue;
    uint256 purchaseAmount = msg.value.div(fstPrice);

    require(
      isEnabled &&
      finalized == false &&
      available > 0 &&
      purchaseAmount > 0
    );

    if (available >= purchaseAmount) {
      revenue = msg.value;
    } else {
      purchaseAmount = available;
      revenue = available.mulCeil(fstPrice);
      isEnabled = false;

      msg.sender.transfer(msg.value - revenue);
    }

    funderSmartToken.transfer(msg.sender, purchaseAmount);

    emit TokenPurchase(funderSmartToken, msg.sender, msg.sender, revenue, purchaseAmount);
    
    totalEtherReceived += revenue;
  }
  
  function declareRF(string _secret) public {
    require(
      secretHash == keccak256(abi.encodePacked(_secret)) &&
      rf == address(0)
    );

    rf = msg.sender;
    
    emit RFDeclare(rf);
  }

  function finalize (address _receiver) public {
    require(
      msg.sender == owner &&
      isEnabled == false &&
      finalized == false &&
      rf != address(0)
    );

    finalized = true;

    // 15% referral
    rf.transfer(address(this).balance * 15 / 100);
    _receiver.transfer(address(this).balance);

    uint256 available = funderSmartToken.balanceOf(address(this));
    if (available > 0) {
      funderSmartToken.transfer(_receiver, available);
    }

    emit Finalize(_receiver, rf, totalEtherReceived * 85 / 100);
  }

  function setOwner (address _ownder) public {
    require(msg.sender == owner);
    owner = _ownder;
  }

  function setFunderSmartToken(address _fstAddress) public {
    require(msg.sender == owner);
    funderSmartToken = ERC20(_fstAddress);
  }

  function setFSTPrice(uint256 numerator, uint256 denominator) public {
    require(msg.sender == owner);
    require(
      numerator > 0 &&
      denominator > 0
    );

    fstPrice.numerator = numerator;
    fstPrice.denominator = denominator;
  }

  function setEnabled (bool _isEnabled) public {
    require(msg.sender == owner);
    isEnabled = _isEnabled;
  }

}

library Math {

  struct Fraction {
    uint256 numerator;
    uint256 denominator;
  }

  function isPositive(Fraction memory fraction) internal pure returns (bool) {
    return fraction.numerator > 0 && fraction.denominator > 0;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256 r) {
    r = a * b;
    require((a == 0) || (r / a == b));
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256 r) {
    r = a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 r) {
    require((r = a - b) <= a);
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 r) {
    require((r = a + b) >= a);
  }

  function min(uint256 x, uint256 y) internal pure returns (uint256 r) {
    return x <= y ? x : y;
  }

  function max(uint256 x, uint256 y) internal pure returns (uint256 r) {
    return x >= y ? x : y;
  }

  function mulDiv(uint256 value, uint256 m, uint256 d) internal pure returns (uint256 r) {
    // try mul
    r = value * m;
    if (r / value == m) {
      // if mul not overflow
      r /= d;
    } else {
      // else div first
      r = mul(value / d, m);
    }
  }

  function mulDivCeil(uint256 value, uint256 m, uint256 d) internal pure returns (uint256 r) {
    // try mul
    r = value * m;
    if (r / value == m) {
      // mul not overflow
      if (r % d == 0) {
        r /= d;
      } else {
        r = (r / d) + 1;
      }
    } else {
      // mul overflow then div first
      r = mul(value / d, m);
      if (value % d != 0) {
        r += 1;
      }
    }
  }

  function mul(uint256 x, Fraction memory f) internal pure returns (uint256) {
    return mulDiv(x, f.numerator, f.denominator);
  }

  function mulCeil(uint256 x, Fraction memory f) internal pure returns (uint256) {
    return mulDivCeil(x, f.numerator, f.denominator);
  }

  function div(uint256 x, Fraction memory f) internal pure returns (uint256) {
    return mulDiv(x, f.denominator, f.numerator);
  }

  function divCeil(uint256 x, Fraction memory f) internal pure returns (uint256) {
    return mulDivCeil(x, f.denominator, f.numerator);
  }

  function mul(Fraction memory x, Fraction memory y) internal pure returns (Math.Fraction) {
    return Math.Fraction({
      numerator: mul(x.numerator, y.numerator),
      denominator: mul(x.denominator, y.denominator)
    });
  }
}