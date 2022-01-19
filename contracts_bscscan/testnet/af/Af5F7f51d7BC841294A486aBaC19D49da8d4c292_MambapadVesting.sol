/**
 *Submitted for verification at BscScan.com on 2022-01-18
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }
}

library SafeMathInt {
  int256 private constant MIN_INT256 = int256(1) << 255;
  int256 private constant MAX_INT256 = ~(int256(1) << 255);

  function mul(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a * b;

    require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
    require((b == 0) || (c / b == a));
    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
    require(b != -1 || a != MIN_INT256);

    return a / b;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require((b >= 0 && c <= a) || (b < 0 && c > a));
    return c;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  function abs(int256 a) internal pure returns (int256) {
    require(a != MIN_INT256);
    return a < 0 ? -a : a;
  }
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
  address internal owner;
  mapping(address => bool) internal authorizations;

  constructor(address _owner) {
    owner = _owner;
    authorizations[_owner] = true;
  }

  modifier onlyOwner() {
    require(isOwner(msg.sender), '!OWNER');
    _;
  }

  modifier authorized() {
    require(isAuthorized(msg.sender), '!AUTHORIZED');
    _;
  }

  function authorize(address adr) public onlyOwner {
    authorizations[adr] = true;
  }

  function unauthorize(address adr) public onlyOwner {
    authorizations[adr] = false;
  }

  function isOwner(address account) public view returns (bool) {
    return account == owner;
  }

  function isAuthorized(address adr) public view returns (bool) {
    return authorizations[adr];
  }

  function transferOwnership(address payable adr) public onlyOwner {
    owner = adr;
    authorizations[adr] = true;
    emit OwnershipTransferred(adr);
  }

  event OwnershipTransferred(address owner);
}

contract MambapadVesting is Auth {
  
  using SafeMath for uint256;
  using SafeMathInt for int256;

  IBEP20 public MambaContract;

  uint256 public Denominator = 100;
  uint256 public maxPerc = 100;

  uint256 public Team_VESTING_PER_MONTH = 10;

  uint256 public Private_VESTING_PER_MONTH = 10;

  uint256 public Prisale_VESTING_PER_MONTH = 10;
  
  uint256 public Stake_VESTING_PER_MONTH = 20;

  uint256 private months = 0;

  uint256 private vest_start_day;

  bool public isInitialDeposit;
  uint256 private constant MAX_UINT256 = ~uint256(0);

  event initialVestingAmountDeposit(address indexed _from, address indexed _to, uint256 amount);
  event MonthWithdraw(address indexed _to, uint256 amount);
  event EmergencyWithdraw(address indexed _from, uint256 amount);

  constructor(address _mambapad) Auth(msg.sender) {
    MambaContract =  IBEP20(_mambapad);
    vest_start_day = block.timestamp;
  }

  function initialDepositVestingAmounts() external onlyOwner {
    require(!isInitialDeposit, "Already deposited");
    uint256 tokenTotalSupply = MambaContract.totalSupply();

    
    uint256 teamTotalVestingAmount = tokenTotalSupply.mul(5).mul(50).div(Denominator).div(Denominator);
    uint256 privateSaleTotalVestingAmount = tokenTotalSupply.mul(10).mul(40).div(Denominator).div(Denominator);
    uint256 preSaleTotalVestingAmount = tokenTotalSupply.mul(30).mul(40).div(Denominator).div(Denominator);
    uint256 stakeTotalVestingAmount = tokenTotalSupply.mul(25).mul(80).div(Denominator).div(Denominator);

    uint256 totalAmount = (teamTotalVestingAmount.mul(4)).add(privateSaleTotalVestingAmount).add(preSaleTotalVestingAmount).add(stakeTotalVestingAmount);

    MambaContract.transferFrom(owner, address(this), totalAmount);
    isInitialDeposit = true;

    emit initialVestingAmountDeposit(owner, address(this), totalAmount);
  }

  function monthWithdraw(address _to) external onlyOwner returns(bool) {
    require(isInitialDeposit, "Not deposited yet");
    uint256 period = block.timestamp - vest_start_day;
    uint256 period_months = period.div(10 minutes);
    require(period_months > months, "Can't widthraw yet");

    if(months>=10) return true;

    uint256 _rMonths = period_months.sub(months);
    uint256 tokenTotalSupply = MambaContract.totalSupply();

    uint256 teamPerc = Team_VESTING_PER_MONTH.mul(_rMonths);
    if(teamPerc > maxPerc) teamPerc = maxPerc;

    uint256 privateSalePerc = Private_VESTING_PER_MONTH.mul(_rMonths);
    if(privateSalePerc > maxPerc) privateSalePerc = maxPerc;

    uint256 preSalePerc = Prisale_VESTING_PER_MONTH.mul(_rMonths);
    if(preSalePerc > maxPerc) preSalePerc = maxPerc;

    uint256 stakePerc = Stake_VESTING_PER_MONTH.mul(_rMonths);
    if(stakePerc > maxPerc) stakePerc = maxPerc;
    if(months>=5) stakePerc = 0;

    uint256 teamAmount = tokenTotalSupply.mul(5).mul(50).mul(teamPerc);
    teamAmount = teamAmount.div(Denominator).div(Denominator).div(Denominator);

    uint256 privateSaleAmount = tokenTotalSupply.mul(10).mul(40);
    privateSaleAmount = privateSaleAmount.mul(privateSalePerc).div(Denominator**3);

    uint256 preSaleAmount = tokenTotalSupply.mul(30).mul(40);
    preSaleAmount = preSaleAmount.mul(preSalePerc).div(Denominator**3);

    uint256 stakeAmount = tokenTotalSupply.mul(25).mul(80);
    stakeAmount = stakeAmount.mul(stakePerc).div(Denominator**3);

    uint256 monthTotalAmount = teamAmount.mul(4);
    monthTotalAmount = monthTotalAmount.add(privateSaleAmount).add(preSaleAmount).add(stakeAmount);

    address recipient = _to;
    require(MambaContract.balanceOf(address(this)) > monthTotalAmount, " The balance amount have to be great the sening amount");

    MambaContract.transfer(recipient, monthTotalAmount);


    months = period_months;

    emit MonthWithdraw(_to, monthTotalAmount);
    return true;
  }

  function emergencyWithdraw(uint256 amount) external onlyOwner {
    MambaContract.transfer(owner, amount);
    emit EmergencyWithdraw(owner, amount);
  }

}