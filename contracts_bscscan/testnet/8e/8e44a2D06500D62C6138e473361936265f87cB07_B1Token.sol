//SPDX-License-Identifier: Unlicense
//https://eips.ethereum.org/EIPS/eip-20
pragma solidity ^0.8.0;

contract B1Token {
  //uint256 can over/underflow, so SafeMath prevents fuckups
  //Usings at top
  using SafeMath for uint256;

  //Public can be access from outside the contract
  //View is constant
  //Events can trigger external applications
  string public constant name = "B1 Token";
  string public constant symbol = "B1";
  address public deployerAddress;
  uint8 public constant decimals = 18;
  uint256 private burnPercentage = 5;
  uint256 private taxPercentage = 5;
  bool public open = false;

  //Define Approval event with owner address, delegate address and amount of tokens the delegate can spend
  event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

  //Define transfer event with from address, to address and amount of tokens
  event Transfer(address indexed from, address indexed to, uint256 tokens);

  //Define balances dict/hashmap/thing with address as the key and uint256 as a value
  mapping(address => uint256) balances;

  //Define allowed dict/hashmap/thing with address as the key and address:uint256 hashmap as a value
  mapping(address => mapping(address => uint256)) allowed;

  //Define array to contain list of addresses with >0 balances
  address[] PositiveBalances;
  mapping(address => uint256) PositiveBalancesHashmap;

  uint256 totalSupply_;

  constructor(uint256 total) {
    //Total being total number of tokens - is passed as parameter on deployment
    totalSupply_ = total;
    deployerAddress = payable(msg.sender);
    //msg.sender being the address of the wallet interacting with it
    //Gives all tokens to wallet that deploys contract
    balances[deployerAddress] = totalSupply_;
  }

  function totalSupply() public view returns (uint256) {
    //Public function to return totalSupply_
    return totalSupply_;
  }

  function balanceOf(address tokenOwner) public view returns (uint256) {
    //Public function to return the amount of tokens a wallet has in balances dict
    return balances[tokenOwner];
  }

  function getOpen() public view returns (bool) {
    return open;
  }

  function setOpen(bool newValue) public returns (bool) {
    require(msg.sender == deployerAddress, "Bad address");
    open = newValue;
    return true;
  }

  function getBurn() public view returns (uint256) {
    return burnPercentage;
  }

  function setBurn(uint256 newValue) public returns (bool) {
    require(msg.sender == deployerAddress, "Bad address");
    burnPercentage = newValue;
    return true;
  }

  function getTax() public view returns (uint256) {
    return taxPercentage;
  }

  function setTax(uint256 newValue) public returns (bool) {
    require(msg.sender == deployerAddress, "Bad address");
    taxPercentage = newValue;
    return true;
  }

  function allowance(address owner, address delegate) public view returns (uint256) {
    //Returns value for how much a delegate can spend on behalf of an address
    return allowed[owner][delegate];
  }

  function approve(address delegate, uint256 numTokens) public returns (bool) {
    require(open == true || deployerAddress == msg.sender);
    //Delegate is a 3rd party allowed to spend tokens for a wallet

    //mapping(address => mapping(address => uint256))
    //[owner[delegate:spendable tokens]]
    allowed[msg.sender][delegate] = numTokens;

    //Emits an event for Approval with three params
    emit Approval(msg.sender, delegate, numTokens);
    return true;
  }

  /* function mint(uint256 numTokens) public returns (bool) {
     require(msg.sender == deployerAddress, "Bad address");
     //SafeMath uses .sub instead of subtraction operator because safer. Same for add.
     balances[msg.sender] = balances[msg.sender].add(numTokens);

     totalSupply_ = totalSupply_.add(numTokens);

     //Emits an event for Transfer with three params
     emit Transfer(address(0), msg.sender, numTokens);

     return true;
  } */

  function doTransaction(address sender, address receiver, uint256 numTokens) private returns (bool) {
    //Acts as a break if wallet balance is less than numTokens - reverts previous logic if fails as well
    require(numTokens <= balances[sender], "Not enough tokens");
    require(open == true || deployerAddress == sender, "Token has not yet been opened");
    uint256 burned = 0;
    uint256 taxed = 0;

    if (burnPercentage > 0 && sender != deployerAddress) { burned = numTokens / (100 / burnPercentage); }
    if (taxPercentage > 0 && sender != deployerAddress) { taxed = numTokens / (100 / taxPercentage); }

    //SafeMath uses .sub instead of subtraction operator because safer. Same for add.
    balances[sender] = balances[sender].sub(numTokens);
    numTokens = numTokens.sub(burned.add(taxed));
    balances[receiver] = balances[receiver].add(numTokens);
    emit Transfer(sender, receiver, numTokens);
    
    if(burnPercentage > 0)
    {
      balances[address(0)] = balances[address(0)].add(burned);
      emit Transfer(sender, address(0), burned);
    }
    if(taxPercentage > 0)
    {
      balances[deployerAddress] = balances[deployerAddress].add(taxed);
      emit Transfer(sender, deployerAddress, taxed);
    }

    return true;
  }

  function transfer(address receiver, uint256 numTokens) public returns (bool) {
    doTransaction(msg.sender, receiver, numTokens);
    return true;
  }

  function transferFrom(
    address owner,
    address buyer,
    uint256 numTokens
  ) public returns (bool) {
    //Require token owner to have the amount of tokens needed
    //Require delegate for owner to be allowed to use the amount of tokens needed
    require(numTokens <= balances[owner], "Owner does not hold enough");
    require(numTokens <= allowed[owner][msg.sender], "Delegate does not have permission to spend more than allowance");

    allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
    doTransaction(owner,buyer,numTokens);
    return true;
  }

  //function rand(uint256 range) public view returns (uint256) {
  //  return uint256 (keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % range;
  //}
}

library SafeMath {
  //SafeMath library to prevent math fuckups
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}