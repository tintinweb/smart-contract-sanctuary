/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity ^0.4.24;

contract CryptoPunk
{
  function punkIndexToAddress(uint256 punkIndex) public view returns (address ownerAddress);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function transferPunk(address to, uint punkIndex) public;
}

contract ERC20
{
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function transfer(address to, uint tokens) public returns (bool success);
}

contract PunkLombard
{
  address public CryptoPunksContract;

  uint256 public loanAmount; //amount of loan in wei
  uint256 public punkIndex; //punk identifier
  uint256 public annualInterestRate; // 10% = 100000000000000000
  uint256 public loanTenor; //loan term; seconds after start of loan when default occurs and punk can be claimed
  uint256 public loanPeriod; //effective number of seconds until loan was repaid
  address public lender; //address providing loan proceeds
  address public borrower; //address putting the CryptoPunk up as collateral
  uint256 public loanStart; //time when lender sent ETH
  uint256 public loanEnd; //time when borrower repaid loan + interest
  uint256 public interest; //effective interest amount in ETH

  address public contractOwner;

  modifier onlyOwner
  {
    if (msg.sender != contractOwner) revert();
    _;
  }

  modifier onlyLender
  {
    if (msg.sender != lender) revert();
    _;
  }

  constructor () public
  {
    CryptoPunksContract = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB; //MainNet
    contractOwner = msg.sender;
    borrower = msg.sender;
  }

  function transferContractOwnership(address newContractOwner) public onlyOwner
  {
    contractOwner = newContractOwner;
  }

  function setTerms(uint256 _loanAmount, uint256 _annualInterestRate, uint256 _loanTenor, uint256 _punkIndex) public onlyOwner
  {
    require(CryptoPunk(CryptoPunksContract).balanceOf(address(this)) == 1);
    loanAmount = _loanAmount;
    annualInterestRate = _annualInterestRate;
    loanTenor = _loanTenor;
    punkIndex = _punkIndex;
  }


  function claimCollateral() public onlyLender //in case of default
  {
    require(now > (loanStart + loanTenor));
    CryptoPunk(CryptoPunksContract).transferPunk(lender, punkIndex); //lender now gets ownership of punk
  }

  function () payable public
  {

    if(msg.sender == borrower) //repaying loan
    {
      require(now <= (loanStart + loanTenor)); //if loan tenor lapses, loan defaults and repayment no longer possible
      uint256 loanPeriodCheck = (now - loanStart);
      interest = (((loanAmount * annualInterestRate) / 10 ** 18) * loanPeriodCheck) / 365 days;
      require(msg.value >= loanAmount + interest);
      loanPeriod = loanPeriodCheck;
      loanEnd = now;
      uint256 change = msg.value - (loanAmount + interest);
      lender.transfer(loanAmount + interest);
      if(change > 0)
      {
        borrower.transfer(change);
      }
      CryptoPunk(CryptoPunksContract).transferPunk(borrower, punkIndex); //transfer punk ownership back to borrower after successful repayment
    }

    if(msg.sender != borrower) // lender sending loan principal
    {
      require(loanStart == 0); //Loan proceeds can only be sent once
      require(CryptoPunk(CryptoPunksContract).balanceOf(address(this)) == 1); //lombard contract should only own 1 punk
      require(CryptoPunk(CryptoPunksContract).punkIndexToAddress(punkIndex) == address(this));  //ensure the lombard contract owns the punk specified
      require(msg.value >= loanAmount); //primitive interest
      lender = msg.sender;
      loanStart = now;
      if(msg.value > loanAmount) //lender sent amount in excess of loanAmount
      {
        msg.sender.transfer(msg.value-loanAmount); //return excess amount
      }
      borrower.transfer(loanAmount); //send loan proceeds through to borrower
    }

  }

  //to rescue trapped tokens
  function transfer_targetToken(address target, address to, uint256 quantity) public onlyOwner
  {
    ERC20(target).transfer(to, quantity);
  }

  //abiltiy to reclaim pumk before loan has begun
  function reclaimPunkBeforeLoan(address _to, uint256 _punkIndex) public onlyOwner
  {
    require(loanStart == 0);
    CryptoPunk(CryptoPunksContract).transferPunk(_to, _punkIndex);
  }
}