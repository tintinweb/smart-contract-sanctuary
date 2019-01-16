pragma solidity ^0.4.24;

contract Owned {}
contract ERC20Interface {}

contract DataeumToken is Owned, ERC20Interface {
  mapping(address => uint256) balances;
  function transfer(address to, uint tokens) public returns (bool success);
  function balanceOf(address tokenOwner) public view returns (uint balance);
}

contract SwapContractDataeumToPDATA {
  //storage
  address public owner;
  DataeumToken public company_token;

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
  constructor (DataeumToken _company_token) public {
    owner = msg.sender;
    PartnerAccount = 0xd7f2E333D208A820801fe6A5ab169cc1886cB90B;
    company_token = _company_token;
    originalBalance = 10000000 * 10**18; // 10 000 000 DataeumToken
    currentBalance = originalBalance;
    alreadyTransfered = 0;
    startDateOfPayments = 1543497300; //From 01 May 2019, 00:00:00
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
	if (now > startDateOfPayments) {
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
}