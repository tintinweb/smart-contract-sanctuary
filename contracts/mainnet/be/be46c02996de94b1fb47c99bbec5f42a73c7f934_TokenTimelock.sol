pragma solidity ^0.4.23;

contract ERC20Basic {
  // events
  event Transfer(address indexed from, address indexed to, uint256 value);

  // public functions
  function totalSupply() public view returns (uint256);
  function balanceOf(address addr) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
}

contract Ownable {

  // public variables
  address public owner;

  // internal variables

  // events
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  // public functions
  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  // internal functions
}

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock is Ownable {
  // ERC20 basic token contract being held
  ERC20Basic public token;

  uint8 public decimals = 8;

  address public beneficiary;
  
  uint256 public releaseTime1 = 1543593600; // 2018.12.1
  uint256 public releaseTime2 = 1559318400; // 2019.6.1
  uint256 public releaseTime3 = 1575129600; // 2019.12.1
  uint256 public releaseTime4 = 1590940800; // 2020.6.1
  
  uint256 public releaseValue1 = 1500000000 * (10 ** uint256(decimals)); 
  uint256 public releaseValue2 = 1500000000 * (10 ** uint256(decimals)); 
  uint256 public releaseValue3 = 1500000000 * (10 ** uint256(decimals)); 
  uint256 public releaseValue4 = 1500000000 * (10 ** uint256(decimals)); 

  bool public releaseState1 = false;
  bool public releaseState2 = false;
  bool public releaseState3 = false;
  bool public releaseState4 = false;

  constructor(
    ERC20Basic _token,
    address _beneficiary

  )
    public
  {
    require(block.timestamp < releaseTime1);
    require(block.timestamp < releaseTime2);
    require(block.timestamp < releaseTime3);
    require(block.timestamp < releaseTime4);
    
    require(_beneficiary != address(0));
    require(_token != address(0));

    token = _token;
    beneficiary = _beneficiary;


  }
    // fallback function
    function() public payable {
        revert();
    }
  function checkCanRelease(bool rState, uint256 rTime, uint256 rAmount) private 
  {
    require(block.timestamp >= rTime);
    require(false == rState);
    uint256 amount = token.balanceOf(this);
    require(amount > 0);
    require(amount >= rAmount);
  }
  function releaseImpl(uint256 rAmount) private 
  {
    require( token.transfer(beneficiary, rAmount) );
  }

  function release_1() onlyOwner public 
  {
    checkCanRelease(releaseState1, releaseTime1, releaseValue1);
    
    releaseState1 = true;
    releaseImpl(releaseValue1);
  }

  function release_2() onlyOwner public 
  {
    checkCanRelease(releaseState2, releaseTime2, releaseValue2);

    releaseState2 = true;
    releaseImpl(releaseValue2);
  }

  function release_3() onlyOwner public 
  {
    checkCanRelease(releaseState3, releaseTime3, releaseValue3);
    releaseState3 = true;
    releaseImpl(releaseValue3);   
  }

  function release_4() onlyOwner public 
  {
    checkCanRelease(releaseState4, releaseTime4, releaseValue4);
    releaseState4 = true;
    releaseImpl(releaseValue4);
  }
  
  function release_remain() onlyOwner public 
  {
    require(true == releaseState1);
    require(true == releaseState2);
    require(true == releaseState3);
    require(true == releaseState4);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    releaseImpl(amount);
  }
}