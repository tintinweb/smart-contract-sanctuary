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

  uint public hardCap;

  uint public raised;

  uint public bonus;

  address public benefit;

  uint public start;

  TrimpoToken token;

  address public tokenAddress;

  uint public tokensPerEther;

  mapping (address => uint) public balanceOf;

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

  event Investing(address investor, uint investedFunds, uint tokensWithoutBonus, uint tokens);
  event Raise(address to, uint funds);


  function Presale(
  address _tokenAddress,
  address a1,
  address a2,
  address a3
  ) Admins(a1, a2, a3) public {

    hardCap = 1000 ether;

    bonus = 50; //percents bonus

    duration = 61 days;

    tokensPerEther = 400; //base price without bonus

    tokenAddress = _tokenAddress;

    token = TrimpoToken(_tokenAddress);

    start = 1526342400; //15 May

  }

  function() payable public goodDate belowHardCap {

    uint tokenAmountWithoutBonus = msg.value * tokensPerEther;

    uint tokenAmount = tokenAmountWithoutBonus + (tokenAmountWithoutBonus * bonus/100);

    token.transferPresale(msg.sender, tokenAmount);

    raised+=msg.value;

    balanceOf[msg.sender]+= msg.value;

    Investing(msg.sender, msg.value, tokenAmountWithoutBonus, tokenAmount);

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