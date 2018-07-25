pragma solidity ^0.4.24;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract CoomiToken {
  function transferFrom(address from, address to, uint256 value) public returns (bool);
}

contract Owned {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _owner) public onlyOwner {
    require(_owner != address(0));
    owner = _owner;
  }
}

contract Crowdsale is Owned {
  using SafeMath for uint256;

  CoomiToken public coomiToken;
  uint256 public exchangeRate;
  uint256 public withdrowRate0; // Molecular
  uint256 public withdrowRate1; // Denominator
  uint256 public etherSum;
  uint256 public coomiSum;
  mapping(address => uint256) public etherSenders;
  mapping(address => uint256) public coomiWinners;
  mapping(address => uint256) public coomiWithdraws;

  constructor(CoomiToken _coomiToken) public {
    coomiToken = _coomiToken;
    exchangeRate = 0;
    withdrowRate0 = 0;
    withdrowRate1 = 0;
  }

  function() payable public {
    require(exchangeRate > 0);
    address from = msg.sender;
    uint256 etherValue = msg.value;
    uint256 coomiValue = etherValue.mul(exchangeRate);
    owner.transfer(etherValue);
    etherSenders[from] = etherSenders[from].add(etherValue);
    coomiWinners[from] = coomiWinners[from].add(coomiValue);
    etherSum = etherSum.add(etherValue);
    coomiSum = coomiSum.add(coomiValue);
  }

  function withdrow() public {
    withdrow(msg.sender);
  }
  
  function withdrowTo(address _to) public onlyOwner {
    withdrow(_to);
  }

  function setExchangeRate(uint256 _exchangeRate) public onlyOwner {
    exchangeRate = _exchangeRate;
  }

  function setWithdrowRate(uint256 _withdrowRate0, uint256 _withdrowRate1) public onlyOwner {
    require(_withdrowRate1 >= _withdrowRate0);
    withdrowRate0 = _withdrowRate0;
    withdrowRate1 = _withdrowRate1;
  }
  
  function withdrow(address to) internal {
    require(withdrowRate0 > 0);
    require(withdrowRate1 >= withdrowRate0);
    uint256 withdrowValue = coomiWinners[to].mul(withdrowRate0)
                                            .div(withdrowRate1)
                                            .sub(coomiWithdraws[to]);
    require(withdrowValue > 0);
    coomiToken.transferFrom(owner, to, withdrowValue);
    coomiWithdraws[to] = coomiWithdraws[to].add(withdrowValue);
    require(coomiWinners[to] >= coomiWithdraws[to]);
  }
}