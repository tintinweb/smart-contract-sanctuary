pragma solidity ^0.4.16;

interface TrimpoToken {

  function presaleAddr() constant returns (address);
  function transferPresale(address _to, uint _value) public;

}

contract Admins {
  address public admin1;

  address public admin2;

  address public admin3;

  function Admins(address a1, address a2, address a3) public {
    admin1 = a1;
    admin2 = a2;
    admin3 = a3;
  }

  modifier onlyAdmins {
    require(msg.sender == admin1 || msg.sender == admin2 || msg.sender == admin3);
    _;
  }

  function setAdmin(address _adminAddress) onlyAdmins public {

    require(_adminAddress != admin1);
    require(_adminAddress != admin2);
    require(_adminAddress != admin3);

    if (admin1 == msg.sender) {
      admin1 = _adminAddress;
    }
    else
    if (admin2 == msg.sender) {
      admin2 = _adminAddress;
    }
    else
    if (admin3 == msg.sender) {
      admin3 = _adminAddress;
    }
  }

}


contract Presale is Admins {


  uint public duration;

  uint public period;

  uint public periodAmount;

  uint public hardCap;

  uint public raised;

  address public benefit;

  uint public start;

  TrimpoToken token;

  address public tokenAddress;

  uint public tokensPerEther;

  mapping (address => uint) public balanceOf;

  mapping (uint => uint) public periodBonuses;

  struct amountBonusStruct {
  uint value;
  uint bonus;
  }

  mapping (uint => amountBonusStruct)  public amountBonuses;


  modifier goodDate {
    require(start > 0);
    require(start <= now);
    require((start+duration) > now);
    _;
  }

  modifier belowHardCap {
    require(raised < hardCap);
    _;
  }

  event Investing(address investor, uint investedFunds, uint tokensWithoutBonus, uint periodBounus, uint amountBonus, uint tokens);
  event Raise(address to, uint funds);


  function Presale(
  address _tokenAddress,
  address a1,
  address a2,
  address a3
  ) Admins(a1, a2, a3) public {

    hardCap = 5000 ether;

    period = 7 days;

    periodAmount = 4;

    periodBonuses[0] = 20;
    periodBonuses[1] = 15;
    periodBonuses[2] = 10;
    periodBonuses[3] = 5;

    duration = periodAmount * (period);

    amountBonuses[0].value = 125 ether;
    amountBonuses[0].bonus = 5;

    amountBonuses[1].value = 250 ether;
    amountBonuses[1].bonus = 10;

    amountBonuses[2].value = 375 ether;
    amountBonuses[2].bonus = 15;

    amountBonuses[3].value = 500 ether;
    amountBonuses[3].bonus = 20;

    tokensPerEther = 400;

    tokenAddress = _tokenAddress;

    token = TrimpoToken(_tokenAddress);

    start = 1526342400; //15 May UTC 00:00

  }


  function getPeriodBounus() public returns (uint bonus) {
    if (start == 0) {return 0;}
    else if (start + period > now) {
      return periodBonuses[0];
    } else if (start + period * 2 > now) {
      return periodBonuses[1];
    } else if (start + period * 3 > now) {
      return periodBonuses[2];
    } else if (start + period * 4 > now) {
      return periodBonuses[3];
    }
    return 0;


  }

  function getAmountBounus(uint value) public returns (uint bonus) {
    if (value >= amountBonuses[3].value) {
      return amountBonuses[3].bonus;
    } else if (value >= amountBonuses[2].value) {
      return amountBonuses[2].bonus;
    } else if (value >= amountBonuses[1].value) {
      return amountBonuses[1].bonus;
    } else if (value >= amountBonuses[0].value) {
      return amountBonuses[0].bonus;
    }
    return 0;
  }

  function() payable public goodDate belowHardCap {

    uint tokenAmountWithoutBonus = msg.value * tokensPerEther;

    uint periodBonus = getPeriodBounus();

    uint amountBonus = getAmountBounus(msg.value);

    uint tokenAmount = tokenAmountWithoutBonus + (tokenAmountWithoutBonus * (periodBonus + amountBonus)/100);

    token.transferPresale(msg.sender, tokenAmount);

    raised+=msg.value;

    balanceOf[msg.sender]+= msg.value;

    Investing(msg.sender, msg.value, tokenAmountWithoutBonus, periodBonus, amountBonus, tokenAmount);

  }

  function setBenefit(address _benefit) public onlyAdmins {
    benefit = _benefit;
  }

  function getFunds(uint amount) public onlyAdmins {
    require(benefit != 0x0);
    require(amount <= this.balance);
    Raise(benefit, amount);
    benefit.send(amount);
  }




}