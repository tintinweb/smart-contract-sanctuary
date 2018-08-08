/*
  8888888 .d8888b.   .d88888b.   .d8888b.  888                     888                 888      
    888  d88P  Y88b d88P" "Y88b d88P  Y88b 888                     888                 888      
    888  888    888 888     888 Y88b.      888                     888                 888      
    888  888        888     888  "Y888b.   888888  8888b.  888d888 888888      .d8888b 88888b.  
    888  888        888     888     "Y88b. 888        "88b 888P"   888        d88P"    888 "88b 
    888  888    888 888     888       "888 888    .d888888 888     888        888      888  888 
    888  Y88b  d88P Y88b. .d88P Y88b  d88P Y88b.  888  888 888     Y88b.  d8b Y88b.    888  888 
  8888888 "Y8888P"   "Y88888P"   "Y8888P"   "Y888 "Y888888 888      "Y888 Y8P  "Y8888P 888  888 

  Rocket startup for your ICO

  The innovative platform to create your initial coin offering (ICO) simply, safely and professionally.
  All the services your project needs: KYC, AI Audit, Smart contract wizard, Legal template,
  Master Nodes management, on a single SaaS platform!
*/
pragma solidity ^0.4.21;

// File: contracts\ICOStartPromo.sol

contract ICOStartPromo {

  string public url = "https://icostart.ch/token-sale";
  string public name = "icostart.ch/promo";
  string public symbol = "ICHP";
  uint8 public decimals = 18;
  uint256 public totalSupply = 1000000 ether;

  address private owner;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function ICOStartPromo() public {
    owner = msg.sender;
  }

  function setName(string _name) onlyOwner public {
    name = _name;
  }

  function setSymbol(string _symbol) onlyOwner public {
    symbol = _symbol;
  }

  function setUrl(string _url) onlyOwner public {
    url = _url;
  }

  function balanceOf(address /*_owner*/) public view returns (uint256) {
    return 1000 ether;
  }

  function transfer(address /*_to*/, uint256 /*_value*/) public returns (bool) {
    return true;
  }

  function transferFrom(address /*_from*/, address /*_to*/, uint256 /*_value*/) public returns (bool) {
    return true;
  }

  function approve(address /*_spender*/, uint256 /*_value*/) public returns (bool) {
    return true;
  }

  function allowance(address /*_owner*/, address /*_spender*/) public view returns (uint256) {
    return 0;
  }

  function airdrop(address[] _recipients) public onlyOwner {
    require(_recipients.length > 0);
    require(_recipients.length <= 200);
    for (uint256 i = 0; i < _recipients.length; i++) {
      emit Transfer(address(this), _recipients[i], 1000 ether);
    }
  }

  function() public payable {
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

}