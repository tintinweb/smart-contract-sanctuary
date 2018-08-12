pragma solidity ^0.4.24;

contract Crowdsale {

  ERC20 public token;
  address public owner;
  uint256 public rate;
  uint256 public weiRaised;
  address public kycAdmin;
  bool public isRunning;
  uint256 public startTimestamp;
  uint256 public endTimestamp;
  uint256 public duration;

  mapping(address => bool) public approvals;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event KycApproved(address indexed beneficiary, address indexed admin, bool status);
  event KycRefused(address indexed beneficiary, address indexed admin, bool status);

  modifier onlyOwner() { require(msg.sender == owner); _; }
  modifier onlyKycAdmin() { require(msg.sender == kycAdmin); _; }
  modifier onlyApproved(address _beneficiary) { require(approvals[_beneficiary] == true); _; }
  modifier onlyAfter(uint256 _timestamp) { require(now > _timestamp); _; }
  modifier onlyBefore(uint256 _timestamp) { require(now < _timestamp); _; }

  constructor(uint256 _rate, address _owner, uint256 _duration, ERC20 _token) public {
    require(_rate > 0);
    require(_owner != address(0));
    require(_token != address(0));

    rate = _rate;
    owner = _owner;
    token = _token;
    duration = _duration * 1 hours;
  }

  function () external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) public onlyApproved(_beneficiary) onlyBefore(endTimestamp) payable {
    require(msg.value > 0);
    uint256 tokensAmount = mul(msg.value, rate);
    weiRaised = add(msg.value, weiRaised);
    require(token.transferFrom(address(this), _beneficiary, tokensAmount));
    emit TokenPurchase(msg.sender, _beneficiary, msg.value, tokensAmount);
    owner.transfer(msg.value);
  }

  function approveAddress(address _beneficiary) external onlyKycAdmin() {
    approvals[_beneficiary] = true;
    emit KycApproved(_beneficiary, kycAdmin, true);
  }

  function refuseAddress(address _beneficiary) external onlyKycAdmin() {
    approvals[_beneficiary] = false;
    emit KycRefused(_beneficiary, kycAdmin, false);
  }

  function setKycAdmin(address _newAdmin) external onlyOwner() {
    kycAdmin = _newAdmin;
  }

  function assignReward(address _beneficiary, uint256 _amount) external onlyOwner() {
    require(token.transferFrom(address(this), _beneficiary, _amount));
  }

  function startDistribution() external onlyOwner() {
    startTimestamp = now;
    endTimestamp = now + duration;
    isRunning = true;
  }

  function stopDistribution() external onlyAfter(endTimestamp) {
    isRunning = false;
  }

  function setRate(uint256 _newRate) external onlyOwner() {
    rate = _newRate;
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

interface ERC20 {
  function transferFrom(address from, address to, uint256 value) external returns (bool);
}