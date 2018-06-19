pragma solidity ^0.4.19;

/* CONTRACT */
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
// END_OF_contract_SafeMath
//_______________________________________________
//
/* INTERFACE */
interface token {

    function buyCoinsCrowdSale(address buyer, uint payment, address crowdSaleContr) public returns(bool success, uint retPayment);
}
//_______________________________________________
//
interface ICO {
    
    function getPrices() public returns(uint buyPrice_,  uint redeemPrice_, uint sellPrice_);
}
//________________________________________________
//
/* CONTRACT */
contract CrowdSaleMacroansyA is SafeMath {

    address internal beneficiaryFunds;
    address internal owner; 
    address internal tkn_addr;    
    address internal ico_addr;
    //
    uint internal fundingGoal;
    uint internal amountRaised;
    uint internal deadline;
    uint internal amountWithdrawn;
    //
    mapping(address => uint256) public balanceOf;
    //
    bool internal fundingGoalReached;
    bool internal crowdsaleClosed; 
    bool internal crowdsaleStart;
    bool internal unlockFundersBalance; 
    bool internal saleParamSet;
    //
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event FundOrPaymentTransfer(address beneficiary, uint amount);
//________________________________________________________
//
    /**
     * Constrctor function
     */
    function CrowdSaleMacroansyA() public {

        owner = msg.sender;
        beneficiaryFunds = owner;
        saleParamSet = false;
        fundingGoalReached = false;
        crowdsaleStart = false;
        crowdsaleClosed = false; 
        unlockFundersBalance = false; 

    }
//_________________________________________________________
//
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    } 
//_________________________________________________________
//
    function transferOr(address _Or) public onlyOwner {
        owner = _Or;
    }     
//_________________________________________________________
//
    function setContrAddr(address tkn_ma_addr, address ico_ma_addr) public onlyOwner returns(bool success){
       tkn_addr = tkn_ma_addr; ico_addr = ico_ma_addr;
       return true;
    } 
//_________________________________________________________
//
    function _getTknAddr() internal returns(address tkn_ma_addr){ return tkn_addr; }
    function _getIcoAddr() internal returns(address ico_ma_addr){  return ico_addr; }
//_________________________________________________________
//    
    function setFundingGoal(uint fundingGoalInEthers, bool resetForUnexpected) public onlyOwner returns(bool success){
            
            if(saleParamSet == false || resetForUnexpected == true ){

                fundingGoal = fundingGoalInEthers * 1 ether;
                saleParamSet = true;
            }
            return true;
    } 
//_________________________________________________________
//
    function startOrHoldCrowdSale(bool setStartCrowdSale, bool crowdsaleStart_, bool setDuration, uint durationInMinutes, bool resetAmountRaisedAndWithdrawnToZero) public onlyOwner returns(bool success) {
        
        if( setDuration == true) deadline = now + durationInMinutes * 1 minutes;

        if( setStartCrowdSale == true ) {
            crowdsaleStart = crowdsaleStart_;
            crowdsaleClosed = false;                 
            unlockFundersBalance = false; 
        }

        if(resetAmountRaisedAndWithdrawnToZero == true) { 
        	amountRaised = 0;
        	amountWithdrawn = 0;
        }
        return true;
    }
//_________________________________________________________
//
    function viewAllControls(bool show) view onlyOwner public returns(bool saleParamSet_, bool crowdsaleStart_, bool crowdsaleClosed_, bool fundingGoalReached_, bool unlockFundersBalance_){
        if(show == true) {
            return ( saleParamSet, crowdsaleStart, crowdsaleClosed, fundingGoalReached, unlockFundersBalance);
        }
    }
//_________________________________________________________
//
    function unlockFundrBal( bool unlockFundersBalance_) public onlyOwner afterDeadline returns(bool success){

        unlockFundersBalance = unlockFundersBalance_ ;
        return true;
    }
//_________________________________________________________
//           
    /**
     * Fallback function
     */
    function() payable public {

      if(msg.sender != owner){

        require(crowdsaleClosed == false && crowdsaleStart == true);

        token t = token( _getTknAddr() );

        bool sucsBuyCoinAtToken; uint retPayment;
        ( sucsBuyCoinAtToken, retPayment) = t.buyCoinsCrowdSale(msg.sender, msg.value, this);
        require(sucsBuyCoinAtToken == true);

        // return payment to buyer 
            if( retPayment > 0 ) {
                    
              bool sucsTrPaymnt;
              sucsTrPaymnt = _safeTransferPaymnt( msg.sender, retPayment );
              require(sucsTrPaymnt == true );
            }

        uint amount = safeSub( msg.value , retPayment);
        balanceOf[msg.sender] = safeAdd( balanceOf[msg.sender] , amount);
        amountRaised = safeAdd( amountRaised, amount);        

        FundTransfer(msg.sender, amount, true);
      }
    }
//________________________________________________
//
    function viewCrowdSaleLive(bool show, bool showFundsInWei) public view returns(uint fundingGoal_, uint fundRaised, uint fundWithDrawn, uint timeRemainingInMin, uint tokenPriceInWei, bool fundingGoalReached_ ){
        
        if(show == true && crowdsaleStart == true){
            
            if( deadline >= now ) timeRemainingInMin = safeSub( deadline, now) / 60;
            if( now > deadline ) timeRemainingInMin == 0;
            
            ICO ico = ICO(_getIcoAddr());
            uint buyPrice_; 
            (buyPrice_,) = ico.getPrices();

            if(showFundsInWei == false){
	            return( safeDiv(fundingGoal,10**18), safeDiv(amountRaised,10**18), safeDiv(amountWithdrawn, 10**18) , timeRemainingInMin, buyPrice_, fundingGoalReached );
            }
            //
            if(showFundsInWei == true){
	            return( fundingGoal, amountRaised, amountWithdrawn , timeRemainingInMin, buyPrice_, fundingGoalReached);
            }            
        }
    }
//_______________________________________________
//
    function viewMyContribution(bool show) public view returns(uint yourContributionInWEI){
        if(show == true && crowdsaleStart == true){

            return(balanceOf[msg.sender]);
        }
    }
//________________________________________________
//
    modifier afterDeadline() { if (now >= deadline) _; }
//________________________________________________
//
    /**
     * Check Crowdsale Goal and Dead Line
     */
    function checkGoalReached() afterDeadline public {

       if(crowdsaleStart == true){

            if (amountRaised >= fundingGoal){
                fundingGoalReached = true;
                GoalReached(beneficiaryFunds, amountRaised);
                crowdsaleClosed = true;               
            } 
            //
             if (amountRaised < fundingGoal)  fundingGoalReached = false;             
       }
    }
//________________________________________________
//
    /**
     * Fund withdraw to backers if crowdsale not successful
     *
     */
    function safeWithdrawal() afterDeadline public {

        if ( (!fundingGoalReached || unlockFundersBalance == true) && msg.sender != owner) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                require(this.balance >= amount );
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount, false);
                    amountWithdrawn = safeAdd( amountWithdrawn, amount); 
                } else {
                    balanceOf[msg.sender] = amount;
                  }
            }
        }
    }
//________________________________________________
//
    /*
    * @notice Withdraw Payments to beneficiary if crowdsale successful
    * @param withdrawAmount the amount withdrawn in wei
    */
    function withdrawFund(uint withdrawAmount, bool withdrawTotalAmountBalance) onlyOwner public returns(bool success) {
      
        if (fundingGoalReached && beneficiaryFunds == msg.sender && unlockFundersBalance == false ) {
                      
            if( withdrawTotalAmountBalance == true ) withdrawAmount = safeSub( amountRaised, amountWithdrawn);
            require(this.balance >= withdrawAmount );
            amountWithdrawn = safeAdd( amountWithdrawn, withdrawAmount); 
            success = _withdraw(withdrawAmount);   
            require(success == true); 
            
        }
      
        return success;      
    }   
//_________________________________________________________
     /*internal function can be called by this contract only
     */
    function _withdraw(uint _withdrawAmount) internal returns(bool success) {

        bool sucsTrPaymnt = _safeTransferPaymnt( beneficiaryFunds, _withdrawAmount); 
        require(sucsTrPaymnt == true);         
        return true;     
    }  
//________________________________________________
//
    function _safeTransferPaymnt( address paymentBenfcry, uint payment) internal returns(bool sucsTrPaymnt){
              
          uint pA = payment; 
          uint paymentTemp = pA;
          pA = 0;
          paymentBenfcry.transfer(paymentTemp); 
          FundOrPaymentTransfer(paymentBenfcry, paymentTemp);                       
          paymentTemp = 0; 
          
          return true;
    }      
//________________________________________________
//              
            bool private isEndOk;
                function endOfRewards(bool isEndNow) public onlyOwner {

                        isEndOk == isEndNow;
                }
                //
                function endOfRewardsConfirmed(bool isEndNow) public onlyOwner{

                    if(isEndOk == true && isEndNow == true) selfdestruct(owner);
                }
//________________________________________________
}
// END_OF_CONTRACT