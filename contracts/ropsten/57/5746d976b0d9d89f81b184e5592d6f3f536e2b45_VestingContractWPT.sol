pragma solidity ^0.4.24;

contract Ownable {}
contract AddressesFilterFeature is Ownable {}
contract ERC20Basic {}
contract BasicToken is ERC20Basic {}
contract ERC20 {}
contract StandardToken is ERC20, BasicToken {}
contract MintableToken is AddressesFilterFeature, StandardToken {}

contract Token is MintableToken {
  mapping(address => uint256) balances;
  function transfer(address _to, uint256 _value) public returns (bool);
  function balanceOf(address owner) public view returns (uint256);
}

contract VestingContractWPT {
  //storage
  address public owner;
  Token public company_token;

  address public PartnerAccount;
  uint public originalBalance;
  uint public currentBalance;
  uint public alreadyTransfered;
  uint public startDateOfPayments;
  uint public endDateOfPayments;
  uint public periodOfOnePayments;
  uint public limitPerPeriod;
  uint public daysOfPayments;

  //modifiers
  modifier onlyOwner
  {
    require(owner == msg.sender);
    _;
  }
  
  
  //Events
  event Transfer(address indexed to, uint indexed value);
  event OwnerChanged(address indexed owner);


  //constructor
  constructor (Token _company_token) public {
    owner = msg.sender;
    PartnerAccount = 0xd7f2e333d208a820801fe6a5ab169cc1886cb90b;
    company_token = _company_token;
    originalBalance = 1785714 * 10**18; // 11 700 WPT
    currentBalance = originalBalance;
    alreadyTransfered = 0;
    startDateOfPayments = 1538251520; //From Sat Sep 29 2018 20:05:20
    endDateOfPayments = 1538265600; //From Sun Sep 30 2018 00:00:00
    periodOfOnePayments = 2 * 60; // 2 min in seconds
    daysOfPayments = (endDateOfPayments - startDateOfPayments) / periodOfOnePayments; // 117 days
    limitPerPeriod = originalBalance / daysOfPayments;
  }


  /// @dev Fallback function: don&#39;t accept ETH
  function()
    public
    payable
  {
    revert();
  }


  /// @dev Get current balance of the contract
  function getBalance()
    constant
    public
    returns(uint)
  {
    return company_token.balanceOf(this);
  }


  function setOwner(address _owner) 
    public 
    onlyOwner 
  {
    require(_owner != 0);
    
    owner = _owner;
    emit OwnerChanged(owner);
  }
  
  function sendCurrentPayment() public {
    uint currentPeriod = (now - startDateOfPayments) / periodOfOnePayments;
    uint currentLimit = currentPeriod * limitPerPeriod;
    uint unsealedAmount = currentLimit - alreadyTransfered;
    if (unsealedAmount > 0) {
      if (currentBalance >= unsealedAmount) {
        company_token.transfer(PartnerAccount, unsealedAmount);
        alreadyTransfered += unsealedAmount;
        currentBalance -= unsealedAmount;
        emit Transfer(PartnerAccount, unsealedAmount);
      } else {
        company_token.transfer(PartnerAccount, currentBalance);
        alreadyTransfered += currentBalance;
        currentBalance -= currentBalance;
        emit Transfer(PartnerAccount, currentBalance);
      }
    }
  }
}