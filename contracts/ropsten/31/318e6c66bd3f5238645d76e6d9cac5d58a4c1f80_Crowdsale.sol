pragma solidity ^0.4.24;

interface ERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Crowdsale {

  ERC20 public token;
  address public owner;
  uint256 public rate;
  uint256 public weiRaised;
  mapping(address => bool) public verified;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  constructor(uint256 _rate, address _owner, ERC20 _token) public {
    require(_rate > 0);
    require(_owner != address(0));
    require(_token != address(0));

    rate = _rate;
    owner = _owner;
    token = _token;
  }

  function () external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) public payable {
    require(_beneficiary != address(0));
    require(verified[_beneficiary]);
    require(msg.value > 0);

    uint256 tokens = mul(msg.value, rate);
    weiRaised = add(msg.value, weiRaised);

    require(token.transfer(_beneficiary, tokens));
    emit TokenPurchase(msg.sender, _beneficiary, msg.value, tokens);
    owner.transfer(msg.value);
  }

  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
      if (_a == 0) { return 0; }
      c = _a * _b;
      assert(c / _a == _b);
      return c;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
      assert(_b <= _a);
      return _a - _b;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
      c = _a + _b;
      assert(c >= _a);
      return c;
  }
}