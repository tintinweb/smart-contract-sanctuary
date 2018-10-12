pragma solidity ^0.4.24;

contract ERC20Basic {}
contract ERC20 is ERC20Basic {}
contract Ownable {}
contract BasicToken is ERC20Basic {}
contract StandardToken is ERC20, BasicToken {}
contract Pausable is Ownable {}
contract PausableToken is StandardToken, Pausable {}
contract MintableToken is StandardToken, Ownable {}

contract OpiriaToken is MintableToken, PausableToken {
  mapping(address => uint256) balances;
  function transfer(address _to, uint256 _value) public returns (bool);
  function balanceOf(address who) public view returns (uint256);
}

contract VestingContractCTPData {
  //storage
  address public owner;
  OpiriaToken public company_token;

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
  constructor (OpiriaToken _company_token) public {
    owner = msg.sender;
    PartnerAccount = 0x30e8d315f2b51b2b620c5f368aa474ed3b7f99cc;  //WPT Partner
    company_token = _company_token;
    originalBalance = 7900 * 10**18; // 7 900 PDATA
    currentBalance = originalBalance;
    alreadyTransfered = 0;
    startDateOfPayments = 1538245215; //From Sep 29 2018 18:20:15
    endDateOfPayments = 1538254800; //From Sep 29 2018 23:00:00
    periodOfOnePayments = 2 * 60; // 2 min
    daysOfPayments = (endDateOfPayments - startDateOfPayments) / periodOfOnePayments; // 79 days
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