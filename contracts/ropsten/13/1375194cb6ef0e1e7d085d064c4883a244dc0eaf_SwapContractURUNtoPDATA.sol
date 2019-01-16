pragma solidity ^0.4.23;

contract Ownable {}
contract ERC20Basic {}
contract ERC20 is ERC20Basic {}
contract BasicToken is ERC20Basic {}
contract StandardToken is ERC20, BasicToken {}
contract BurnableToken is StandardToken, Ownable {}
contract URUNToken is BurnableToken {
  mapping(address => uint256) balances;
  function transfer(address _to, uint256 _amount) public returns (bool);
  function balanceOf(address _owner) public view returns (uint256);
}


contract SwapContractURUNtoPDATA {
  //storage
  address public owner;
  URUNToken public company_token;

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
  constructor (URUNToken _company_token) public {
    owner = msg.sender;
    PartnerAccount = 0x925116FF606dBe56b29899f58b5B432306429789;
    company_token = _company_token;
    originalBalance = 3333333 * 10**18; // 3 333 333 URUN
    currentBalance = originalBalance;
    alreadyTransfered = 0;
    startDateOfPayments = 1556661600; //From 01 May 2019, 00:00:00
    endDateOfPayments = 1572562800; //From 01 Nov 2019, 00:00:00
    periodOfOnePayments = 24 * 60 * 60; // 1 day in seconds
    daysOfPayments = (endDateOfPayments - startDateOfPayments) / periodOfOnePayments; // 184 days
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