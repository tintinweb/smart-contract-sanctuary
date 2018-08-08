pragma solidity ^0.4.24;
pragma experimental "v0.5.0";
pragma experimental ABIEncoderV2;

contract ERC20 {
  function balanceOf (address owner) public view returns (uint256);
  function allowance (address owner, address spender) public view returns (uint256);
  function transfer (address to, uint256 value) public returns (bool);
  function transferFrom (address from, address to, uint256 value) public returns (bool);
  function approve (address spender, uint256 value) public returns (bool);
}

contract SalesPool {
  using Math for uint256;

  address public owner;

  ERC20         public smartToken;
  Math.Fraction public tokenPrice;

  uint256 public pipeIndex = 1;
  mapping (uint256 => SalesPipe) public indexToPipe;
  mapping (address => uint256)   public pipeToIndex;

  struct Commission {
    uint256 gt;
    uint256 lte;
    uint256 pa;
  }

  struct Commissions {
    Commission[] array;
    uint256      length;
  }

  uint256 termsIndex = 1;
  mapping (uint256 => Commissions) public terms;

  event CreateSalesPipe(address salesPipe);

  constructor (
    address _smartTokenAddress,
    uint256 _priceNumerator,
    uint256 _priceDenominator
  ) public {
    owner      = msg.sender;
    smartToken = ERC20(_smartTokenAddress);

    tokenPrice.numerator   = _priceNumerator;
    tokenPrice.denominator = _priceDenominator;

    uint256 maxUint256 =
      115792089237316195423570985008687907853269984665640564039457584007913129639935;

    terms[1].array.push(Commission(0 ether, 2000 ether, 5));
    terms[1].array.push(Commission(2000 ether, 10000 ether, 8));
    terms[1].array.push(Commission(10000 ether, maxUint256, 10));
    terms[1].length = terms[1].array.length;

    terms[2].array.push(Commission(0 ether, maxUint256, 5));
    terms[2].length = terms[2].array.length;

    terms[3].array.push(Commission(0 ether, maxUint256, 15));
    terms[3].length = terms[3].array.length;

    termsIndex = 4;
  }

  function pushTerms (Commission[] _array) public {
    require(msg.sender == owner);

    for (uint256 i = 0; i < _array.length; i++) {
      terms[termsIndex].array.push(Commission(_array[i].gt, _array[i].lte, _array[i].pa));
    }

    terms[termsIndex].length = terms[termsIndex].array.length;

    termsIndex++;
  }

  function createPipe (
    uint256 _termsNumber,
    uint256 _allowance,
    bytes32 _secretHash
  ) public {
    require(msg.sender == owner);

    SalesPipe pipe = new SalesPipe(owner, _termsNumber, smartToken, _secretHash);

    address pipeAddress = address(pipe);

    smartToken.approve(pipeAddress, _allowance);

    indexToPipe[pipeIndex]   = pipe;
    pipeToIndex[pipeAddress] = pipeIndex;
    pipeIndex++;

    emit CreateSalesPipe(pipeAddress);
  }

  function setSalesPipeAllowance (address _pipeAddress, uint256 _value) public {
    require(msg.sender == owner);
    smartToken.approve(_pipeAddress, _value);
  }

  function poolTokenAmount () public view returns (uint256) {
    return smartToken.balanceOf(address(this));
  }

  function transferEther(address _to, uint256 _value) public {
    require(msg.sender == owner);
    _to.transfer(_value);
  }

  function transferToken(ERC20 erc20, address _to, uint256 _value) public {
    require(msg.sender == owner);
    erc20.transfer(_to, _value);
  }

  function setOwner (address _owner) public {
    require(msg.sender == owner);
    owner = _owner;
  }

  function setSmartToken(address _smartTokenAddress) public {
    require(msg.sender == owner);
    smartToken = ERC20(_smartTokenAddress);
  }

  function setTokenPrice(uint256 numerator, uint256 denominator) public {
    require(msg.sender == owner);
    require(
      numerator   > 0 &&
      denominator > 0
    );

    tokenPrice.numerator   = numerator;
    tokenPrice.denominator = denominator;
  }

  function getTokenPrice () public view returns (uint256, uint256) {
    return (tokenPrice.numerator, tokenPrice.denominator);
  }

  function getCommissions (uint256 _termsNumber) public view returns (Commissions) {
    return terms[_termsNumber];
  }
  
  function () payable external {}

}

contract SalesPipe {
  using Math for uint256;

  SalesPool public pool;
  address   public owner;

  uint256 public termsNumber;

  ERC20 public smartToken;

  address public rf = address(0);
  bytes32 public secretHash;

  bool public available = true;
  bool public finalized = false;

  uint256 public totalEtherReceived = 0;

  event TokenPurchase(
    ERC20 indexed smartToken,
    address indexed buyer,
    address indexed receiver,
    uint256 value,
    uint256 amount
  );

  event RFDeclare (address rf);
  event Finalize  (uint256 fstkRevenue, uint256 rfReceived);

  constructor (
    address _owner,
    uint256 _termsNumber,
    ERC20   _smartToken,
    bytes32 _secretHash
  ) public {
    pool  = SalesPool(msg.sender);
    owner = _owner;

    termsNumber = _termsNumber;
    smartToken  = _smartToken;

    secretHash = _secretHash;
  }

  function () external payable {
    Math.Fraction memory tokenPrice;
    (tokenPrice.numerator, tokenPrice.denominator) = pool.getTokenPrice();

    address poolAddress = address(pool);

    uint256 availableAmount =
      Math.min(
        smartToken.allowance(poolAddress, address(this)),
        smartToken.balanceOf(poolAddress)
      );
    uint256 revenue;
    uint256 purchaseAmount = msg.value.div(tokenPrice);

    require(
      available &&
      finalized == false &&
      availableAmount > 0 &&
      purchaseAmount  > 0
    );

    if (availableAmount >= purchaseAmount) {
      revenue = msg.value;

      if (availableAmount == purchaseAmount) {
        available = false;
      }
    } else {
      purchaseAmount = availableAmount;
      revenue = availableAmount.mulCeil(tokenPrice);
      available = false;

      msg.sender.transfer(msg.value - revenue);
    }

    smartToken.transferFrom(poolAddress, msg.sender, purchaseAmount);

    emit TokenPurchase(smartToken, msg.sender, msg.sender, revenue, purchaseAmount);

    totalEtherReceived += revenue;
  }

  function declareRF(string _secret) public {
    require(
      secretHash == keccak256(abi.encodePacked(_secret)) &&
      rf         == address(0)
    );

    rf = msg.sender;

    emit RFDeclare(rf);
  }

  function finalize () public {
    require(
      msg.sender == owner &&
      available  == false &&
      finalized  == false &&
      rf         != address(0)
    );

    finalized = true;

    address poolAddress = address(pool);

    uint256 rfEther   = calculateCommission(address(this).balance, termsNumber);
    uint256 fstkEther = address(this).balance - rfEther;

    rf.transfer(rfEther);
    poolAddress.transfer(fstkEther);

    emit Finalize(fstkEther, rfEther);
  }

  function calculateCommission (
    uint256 _totalReceivedEther,
    uint256 _termsNumber
  ) public view returns (uint256) {
    SalesPool.Commissions memory commissions = pool.getCommissions(_termsNumber);

    for (uint256 i = 0; i < commissions.length; i++) {
      SalesPool.Commission memory commission = commissions.array[i];
      if (_totalReceivedEther > commission.gt && _totalReceivedEther <= commission.lte) {
        return _totalReceivedEther * commission.pa / 100;
      }
    }

    return 0;
  }

  function setOwner (address _owner) public {
    require(msg.sender == owner);
    owner = _owner;
  }

  function setTermsNumber (uint256 _termsNumber) public {
    require(msg.sender == owner);
    termsNumber = _termsNumber;
  }

  function setAvailability (bool _available) public {
    require(msg.sender == owner);
    available = _available;
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