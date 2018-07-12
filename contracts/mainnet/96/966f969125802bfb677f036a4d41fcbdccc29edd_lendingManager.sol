pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract lendingManager {

uint256 public REQUESTED_STATUS; 
uint256 public ACTIVE_STATUS; 
uint256 public REQUEST_CANCELED_BY_BORROWER_STATUS;
uint256 public REQUEST_CANCELED_BY_LENDER_STATUS;
uint256 public ACTIVE_LOAN_CANCELED_BY_LENDER_STATUS;
uint256 public COMPLETION_STATUS; 
uint256 public DEFAULTED_STATUS;

uint256 public MAX_LOAN_AMOUNT;
uint256 public MAX_INTEREST_AMOUNT;

uint256 public PERCENTAGE_PRECISION;

address public ELIX_ADDRESS;

event LoanRequestedAtIndex(uint256 index);
event LoanCanceledByBorrowerAtIndex(uint256 index); 
event LoanCanceledByLenderAtIndex(uint256 index); 
event Defaulted(uint256 index,address informer); 
event LoanBegunAtIndex(uint256 index); 
event LoanUpdatedByVolAddress(uint256 index,uint256 oldAmount,uint256 oldInterest,uint256 amount,uint256 interest);
event PaidBackPortionForLoanAtIndex(uint256 index,uint256 amount); 
event LoanPaidLateAtIndex(uint256 index,uint256 amount); 
event LoanRequestCanceledByLenderAtIndex(uint256 index);
event LoanCompletedWithFinalPortion(uint256 index, uint256 amount); 
event ActiveLoanUpdatedByVolAddressToCompletion(uint256 index);
event LenderClaimedLoanAtIndex(address lender,uint256 index);

loan[] public loans; 

struct loan   {
    address borrower;
    address lender;
    address volAddress;
    uint256 startBlock;
    uint256 amount; 
    uint256 paidBackBlock; 
    uint256 status;
    uint256 amountPaidBackSoFar; 
    uint256 loanLength; 
    uint256 interest; 
    bool borrowerPaidLate;
    bool requestCancel;
    string message; 
}

function lendingManager()  {
    
    REQUESTED_STATUS=1;
    ACTIVE_STATUS=2;
    REQUEST_CANCELED_BY_BORROWER_STATUS=3; 
    REQUEST_CANCELED_BY_LENDER_STATUS=4; 
    COMPLETION_STATUS=5;
    ACTIVE_LOAN_CANCELED_BY_LENDER_STATUS=6;
    DEFAULTED_STATUS=7;

    MAX_LOAN_AMOUNT = 100000000000000000000000000000;
    MAX_INTEREST_AMOUNT = 100000000000000000000000000000;

    PERCENTAGE_PRECISION = 1000000000000000000;


    ELIX_ADDRESS = 0xc8C6A31A4A806d3710A7B38b7B296D2fABCCDBA8;
}

function loanCompleted(uint256 index, uint256 amount) private {

    loans[index].paidBackBlock=block.number;
    
    if (block.number>SafeMath.add(loans[index].startBlock,loans[index].loanLength)) {
        loans[index].borrowerPaidLate=true;
        emit LoanPaidLateAtIndex(index,amount); 
    }

    loans[index].status=COMPLETION_STATUS; 
    emit LoanCompletedWithFinalPortion(index, amount); 
    if(amount > 0){ 
        if (! elixir(ELIX_ADDRESS).transferFrom(loans[index].borrower,loans[index].lender, amount)) revert();
    }

}

function adjustLoanParams(uint256 newPrincipal, uint256 newInterest, uint256 index) public {
    require(newPrincipal > 0);
    require(msg.sender == loans[index].volAddress);
    require(loans[index].status == REQUESTED_STATUS || loans[index].status == ACTIVE_STATUS);
    require(newPrincipal <= MAX_LOAN_AMOUNT);
    require(newInterest <= MAX_INTEREST_AMOUNT);

    if (block.number==loans[index].startBlock) revert(); 

    if( SafeMath.add(newPrincipal,newInterest) > loans[index].amountPaidBackSoFar){  
        
        emit LoanUpdatedByVolAddress(index,loans[index].amount,loans[index].interest,newPrincipal,newInterest);
        loans[index].amount = newPrincipal;
        loans[index].interest = newInterest; 
    } else {
        uint256 adjustedTotalRatio = SafeMath.div( SafeMath.mul(PERCENTAGE_PRECISION,loans[index].amountPaidBackSoFar), SafeMath.add(newPrincipal,newInterest) );
        loans[index].interest = SafeMath.div( SafeMath.mul(newInterest, adjustedTotalRatio), PERCENTAGE_PRECISION);
        loans[index].amount = SafeMath.sub(loans[index].amountPaidBackSoFar, loans[index].interest);
		emit ActiveLoanUpdatedByVolAddressToCompletion(index);
		loanCompleted(index, 0);
    }  
}


function requestLoan(address lender, address volAddress, uint256 amount,uint256 length,uint256 interest,bool requestCancel, string loanMessage) public returns(uint256)   {
    if (msg.sender==lender) revert(); 
    
    
    if (amount==0 || length<4 || length>225257143) revert(); 
    
   
    require(amount <= MAX_LOAN_AMOUNT);
    require(interest <= MAX_INTEREST_AMOUNT);    

    loans.push(loan(msg.sender,lender, volAddress,0,amount,0,REQUESTED_STATUS,0,length,interest,false,false,loanMessage));
    
    emit LoanRequestedAtIndex(loans.length-1); 
    
    return (loans.length-1);
}


function cancelLoanRequestAtIndexByLender(uint256 index) public {
  if (loans[index].status==REQUESTED_STATUS && loans[index].lender==msg.sender)    {
        
        loans[index].status=REQUEST_CANCELED_BY_LENDER_STATUS; 
        emit LoanRequestCanceledByLenderAtIndex(index); 
  }
}


function cancelLoanRequestAtIndexByBorrower(uint256 index) public {
  if (loans[index].status==REQUESTED_STATUS && loans[index].borrower==msg.sender)    {
       
        loans[index].status=REQUEST_CANCELED_BY_BORROWER_STATUS; 
        emit LoanCanceledByBorrowerAtIndex(index); 
  }
}


function cancelActiveLoanAtIndex(uint256 index) public  {
  if (loans[index].status==ACTIVE_STATUS && loans[index].lender==msg.sender)   {

      loans[index].status = ACTIVE_LOAN_CANCELED_BY_LENDER_STATUS;
      emit LoanCanceledByLenderAtIndex(index); 
  }
}


function stateBorrowerDefaulted(uint256 index) public  {
  if (loans[index].status==ACTIVE_STATUS && loans[index].lender==msg.sender)   {
    if (block.number>SafeMath.add(loans[index].startBlock,loans[index].loanLength)){
      emit Defaulted(index,msg.sender); 
      loans[index].status=DEFAULTED_STATUS;
    }
  }
}


function declareDefaultAsBorrower(uint256 index) public  {
  if (loans[index].status==ACTIVE_STATUS && loans[index].borrower==msg.sender)   {
      emit Defaulted(index,msg.sender); 
      loans[index].status=DEFAULTED_STATUS;
  }
}


function attemptBeginLoanAtIndex(uint256 index) public returns(bool) {
    if (loans[index].status==REQUESTED_STATUS)    {
    	if (loans[index].lender==0x000000000000000000000000000000000000dEaD)	{
			
			if (msg.sender==loans[index].borrower) revert();
			loans[index].lender=msg.sender;
			
			emit LenderClaimedLoanAtIndex(msg.sender,index);
		} else	{
			if (!(msg.sender==loans[index].lender)) revert();
		}
		
        
        loans[index].status=ACTIVE_STATUS;
        loans[index].startBlock = block.number;
        emit LoanBegunAtIndex(index);
        
        if (! elixir(ELIX_ADDRESS).transferFrom(msg.sender, loans[index].borrower, loans[index].amount) ) revert();
        return true;
    }
    return false;
}


function payAmountForLoanAtIndex(uint256 amount,uint256 index) public {

    if (loans[index].status==ACTIVE_STATUS && msg.sender==loans[index].borrower && amount>0)    {
        require(amount <= SafeMath.add(MAX_LOAN_AMOUNT,MAX_INTEREST_AMOUNT));
        require( SafeMath.add(amount, loans[index].amountPaidBackSoFar) <= SafeMath.add(loans[index].amount, loans[index].interest) );
    
        if (block.number==loans[index].startBlock) revert();
    	        
       
        loans[index].amountPaidBackSoFar = SafeMath.add(loans[index].amountPaidBackSoFar,amount);
        
        if (loans[index].amountPaidBackSoFar == SafeMath.add(loans[index].amount,loans[index].interest))    {
            loanCompleted(index, amount);
        } else {
            emit PaidBackPortionForLoanAtIndex(index,amount); 
            
            if (! elixir(ELIX_ADDRESS).transferFrom(msg.sender,loans[index].lender, amount)) revert();
        }
    }
}



function returnBorrower(uint256 index) public returns(address)	{
	return loans[index].borrower;
}

function returnLender(uint256 index) public returns(address)	{
	return loans[index].lender;
}

function returnVolAdjuster(uint256 index) public returns(address)	{
	return loans[index].volAddress;
}

function returnStartBlock(uint256 index) returns(uint256)	{
	return loans[index].startBlock;
}

function returnAmount(uint256 index) returns(uint256)	{
	return loans[index].amount;
}

function returnPaidBackBlock(uint256 index) returns(uint256)	{
	return loans[index].paidBackBlock;
}

function returnLoanStatus(uint256 index) public returns(uint256)	{
	return loans[index].status;
}

function returnAmountPaidBackSoFar(uint256 index) public returns(uint256)	{
	return loans[index].amountPaidBackSoFar;
}

function returnLoanLength(uint256 index) public returns(uint256)	{
	return loans[index].loanLength;
}

function returnInterest(uint256 index) public returns(uint256)	{
	return loans[index].interest;
}

function returnBorrowerPaidLate(uint256 index) public returns(bool)	{
	return loans[index].borrowerPaidLate;
}

function returnRequestCancel(uint256 index) public returns(bool)	{
	return loans[index].requestCancel;
}

function returnMessage(uint256 index) public returns(string)	{
	return loans[index].message;
}

function getLoansCount() public returns(uint256) {
    return loans.length;
}

function returnAmountPlusInterest(uint256 index) returns(uint256)	{
	return SafeMath.add(loans[index].amount,loans[index].interest);
}

}

contract elixir {
    function transfer(address _to, uint256 _amount) returns (bool success);
    function transferFrom(address _from,address _to,uint256 _amount) returns (bool success);
}