// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import './SafeMath.sol';
import './RoyaleLPVariables.sol';
import './Re.sol';


contract RoyaleLP is RoyaleLPstorage,ReentrancyGuard {
     
  using SafeMath for uint256;
  
    modifier onlyWallet(){
      require(wallet ==msg.sender, "NA");
      _;
    }
  
     modifier validAmount(uint amount){
      require(amount > 0, "NV");
      _;
    }

    modifier onlyAuthorized() {
        require( msg.sender == loanContract, "NA");
        _;
    }

    // EVENTS 
    event userSupplied(address user,uint amount);
    event userRecieved(address user,uint amount);
    event userAddedToQ(address user,uint amount);
    event yieldAdded(uint[3] amounts);
    
    
    constructor(address[3] memory _tokens,address _rpToken,address _wallet) public {
        uint256 decimal;
        for(uint8 i=0; i<3; i++) {
            tokens[i] = IERC20(_tokens[i]);
            decimal=tokens[i].decimals();
            selfBalance[i]= (10**decimal).mul(1000);
        }
        rpToken = IERC20(_rpToken);
        wallet=_wallet;
    }
    
     function transferOwnership(address _wallet) external onlyWallet(){
        wallet =_wallet;
    }

    /* INTERNAL FUNCTIONS */

    function checkValidArray(uint256[3] memory amounts)internal pure returns(bool){
        for(uint8 i=0;i<3;i++){
            if(amounts[i]>0){
                return true;
            }
        }
        return false;
    }

    // functions related to deposit and supply
    
    // This function deposits the fund to Yield Optimizer
    function _deposit(uint256[3] memory amounts) internal {
        curveStrategy.deposit(amounts);
        for(uint8 i=0; i<3; i++) {
            YieldPoolBalance[i] =YieldPoolBalance[i].add(amounts[i]);
        }
    }
   
    //Internal Calculation For User Supply 



    // functions related to withdraw, withdraw queue and withdraw from Yield Optimizer
    function _takeBack(address recipient) internal {
        bool result;
        for(uint8 i=0; i<3; i++) {
            if(amountWithdraw[recipient][i] > 0) {
                uint temp = amountWithdraw[recipient][i].sub((amountWithdraw[recipient][i].mul(fees)).div(DENOMINATOR));
                result = tokens[i].transfer(recipient,  temp);
                require(result,"Transfer Not Succesful");
                totalWithdraw[i] =totalWithdraw[i].sub(amountWithdraw[recipient][i]);
                selfBalance[i] = selfBalance[i].sub(temp);
                updateLockedRPT(recipient,amountBurnt[recipient][i],i);
                amountWithdraw[recipient][i] = 0;
                amountBurnt[recipient][i]=0;
                emit userRecieved(recipient,temp);
            }
        }
        for(uint8 i=0;i<3;i++){
            if(amountBurnt[recipient][i]!=0 && amountWithdraw[recipient][i]!=0){
                rpToken.mint(recipient,amountBurnt[recipient][i]);
            }
            amountBurnt[recipient][i]=0;
            amountWithdraw[recipient][i]=0;
        }
        isInQ[recipient] = false;
        recipientCount -= 1;
    }


    
     function updateLockedRPT(address recipient,uint256 amount,uint _index) internal{
        for(uint8 j=0; j<amountSupplied[recipient].length; j++) {
             if(amountSupplied[recipient][j].index==_index && amountSupplied[recipient][j].remAmt > 0 && amount > 0 ) {
                  if(amount >= amountSupplied[recipient][j].remAmt) {
                        amount = amount.sub( amountSupplied[recipient][j].remAmt);
                        amountSupplied[recipient][j].remAmt = 0;
                    }
                    else {
                        amountSupplied[recipient][j].remAmt =(amountSupplied[recipient][j].remAmt).sub(amount);
                        amount = 0;
                    }
                }
            }
    }

    function checkWithdraw(uint256 amount,uint256 burnAmt,uint _index) internal{
        uint256 poolBalance;
        poolBalance = getBalances(_index);
        rpToken.burn(msg.sender, burnAmt);
        if(amount < poolBalance) {
            bool result;
            uint temp = amount.sub(amount.mul(fees).div(DENOMINATOR));
            selfBalance[_index] =selfBalance[_index].sub(temp);
            result = tokens[_index].transfer(msg.sender, temp);
            require(result,"Transfer not Succesful");
            updateLockedRPT(msg.sender,burnAmt,_index);
            emit userRecieved(msg.sender, temp); 
         }
         else {
            _takeBackQ(amount,burnAmt,_index);
            emit userAddedToQ(msg.sender, amount);
        }
    }



    // this will add unfulfilled withdraw requests to the queue
    function _takeBackQ(uint256 amount,uint256 _burnAmount,uint256 _index) internal {
        amountWithdraw[msg.sender][_index] =amountWithdraw[msg.sender][_index].add( amount);
        amountBurnt[msg.sender][_index]=amountBurnt[msg.sender][_index].add(_burnAmount);
        totalWithdraw[_index] =totalWithdraw[_index].add(amount);
        if(!isInQ[msg.sender]) {
            recipientCount += 1;
            isInQ[msg.sender] = true;
            addToQ(msg.sender);
        }

    }

  


    // this will withdraw from Yield Optimizer into this contract
    function _withdraw(uint256[3] memory amounts) internal {
        curveStrategy.withdraw(amounts);
        for(uint8 i=0; i<3; i++) {
            YieldPoolBalance[i] =YieldPoolBalance[i].sub(amounts[i]);
        }
    }

    //This function calculate RPT to be mint or burn
    function calcRptAmount(uint256 amount,uint _index) public view returns(uint256) {
        uint256 total = calculateTotalToken();
        uint256 decimal = 0;
        decimal=tokens[_index].decimals();
        amount=amount.mul(1e18).div(10**decimal);
        return (amount.mul(rpToken.totalSupply()).div(total));        
    }



    //function to check available amount to withdraw for user
    function availableLiquidity(address addr, uint coin,bool _time) public view returns(uint256 token,uint256 RPT) {
        uint256 amount=0;
        for(uint8 j=0; j<amountSupplied[addr].length; j++) {
            if(amountSupplied[addr][j].index==coin){
                if( (!_time || (now - amountSupplied[addr][j].time)  > lock_period)&&amountSupplied[addr][j].remAmt >0)   {
                        amount =amount.add(amountSupplied[addr][j].remAmt);
                }
            }
        }
        amount =amount.sub(amountBurnt[addr][coin]);
        uint256 total=calculateTotalToken();
        uint256 decimal;
        decimal=tokens[coin].decimals();
        return ((amount.mul(total).mul(10**decimal).div(rpToken.totalSupply())).div(10**18),amount);
    }
    
    function calculateTotalToken()public view  returns(uint256){
        uint256 total=0;
        uint256 decimal;
        for(uint8 i=0; i<3; i++) {
            decimal = tokens[i].decimals();
            total =total.add((selfBalance[i].sub(totalWithdraw[i]).add(loanGiven[i])).mul(1e18).div(10**decimal));
        } 
        return total;
    }
    
    /* USER FUNCTIONS (exposed to frontend) */
   

    function supply(uint256 amount,uint256 _index) external nonReentrant validAmount(amount){
        bool result;
        uint256 mintAmount=calcRptAmount(amount,_index);
        result = tokens[_index].transferFrom(msg.sender, address(this), amount);
        require(result, "coin transfer failed");
        selfBalance[_index] =selfBalance[_index].add(amount);
        rpToken.mint(msg.sender, mintAmount);
        amountSupplied[msg.sender].push(depositDetails(_index,amount ,now,mintAmount));
        emit userSupplied(msg.sender, amount);
    }

    
    
    function requestWithdrawWithRPT(uint256 amount,uint256 _index) external nonReentrant validAmount(amount){
         require(rpToken.balanceOf(msg.sender) >= amount, "low RPT");
         (,uint availableRPT)=availableLiquidity(msg.sender,_index,true );
        bool instant=true;
         if(availableRPT < amount) {
             instant=false;
        }
        require(instant,"NA");
        uint256 total = calculateTotalToken();
            uint256 decimal;
            uint256 tokenAmount;
            decimal=tokens[_index].decimals();
            tokenAmount=amount.mul(total).mul(10**decimal).div(rpToken.totalSupply()).div(10**18);
            require(tokenAmount <= selfBalance[_index],"Not Enough balance");
            checkWithdraw(tokenAmount,amount,_index);  
    }
   
    // Following two functions are called by rLoan Only
    function _loanWithdraw(uint256[3] memory amounts,uint256[3] memory withdrawAmount, address _loanSeeker) public onlyAuthorized() returns(bool) {
        if(checkValidArray(withdrawAmount)){
            _withdraw(withdrawAmount);
        }
        for(uint8 i=0; i<3; i++) {
            if(amounts[i] > 0) {
                loanGiven[i] =loanGiven[i].add(amounts[i]);
                selfBalance[i] =selfBalance[i].sub( amounts[i]);
                tokens[i].transfer(_loanSeeker, amounts[i]);
            }
        }
        return true;
    }
    //Function only called by multisig contract for transfering tokens
    function _loanRepayment(uint256[3] memory amounts, address _loanSeeker) public onlyAuthorized()  returns(bool) {
        for(uint8 i=0; i<3; i++) {
            if(amounts[i] > 0) {
                loanGiven[i] =loanGiven[i].sub(amounts[i]);
                selfBalance[i] =selfBalance[i].add(amounts[i]);
                tokens[i].transferFrom(_loanSeeker, address(this), amounts[i]);
            }
        }
        return true;
    }

    // this function deposits without minting RPT
    function depsoitYield(uint256[3] calldata amounts) external {
        for(uint8 i=0;i<3;i++){
            if(amounts[i]!=0){
             tokens[i].transferFrom(msg.sender,address(this),amounts[i]);
             selfBalance[i]=selfBalance[i].add(amounts[i]);
             liquidityProvidersAPY[i]=amounts[i];
            }
        }
    }


    /* CORE FUNCTIONS (called by owner only) */

    //Deposit in the smart backed pool
    function deposit() onlyWallet() external {
        uint256[3] memory amounts;
        uint256 decimal;
        for(uint8 i=0; i<3; i++) {
            amounts[i]=getBalances(i);
            decimal = tokens[i].decimals();
            if(amounts[i] > threshold.mul(10**decimal)) {
                amounts[i] =((amounts[i].add(YieldPoolBalance[i])).mul(DENOMINATOR.sub(poolPart)).div(DENOMINATOR)).sub(YieldPoolBalance[i]);
                tokens[i].transfer(address(curveStrategy), amounts[i]);
            }
            else {
                amounts[i] = 0;
            }
        }
        if(checkValidArray(amounts)){
            _deposit(amounts);
        }
    }

    //Withdraw from Pool
    function withdraw() onlyWallet() external {
        require(checkValidArray(totalWithdraw), "withdraw queue empty");
        _withdraw(totalWithdraw);
        uint32 counter = recipientCount;
        for(uint8 i=0; i<counter; i++) {
            address recipient = getFromQ();
            _takeBack(recipient);
        }
        first=1;
        last=0;
    }


    function withdrawAll() public onlyWallet() {
        uint[3] memory amounts;
        amounts=curveStrategy.withdrawAll();
        for(uint8 i=0;i<3;i++){
            if(amounts[i]>YieldPoolBalance[i]){
                 selfBalance[i] =selfBalance[i].add(amounts[i].sub(YieldPoolBalance[i]));
            }
            else{
               selfBalance[i] = selfBalance[i].sub(YieldPoolBalance[i].sub(amounts[i]));
            }
            YieldPoolBalance[i]=0;

        }
    }

    //function for rebalancing pool(ratio)      
    function rebalance() onlyWallet() external {
        uint256 currentAmount;
        uint256[3] memory amountToWithdraw;
        uint256[3] memory amountToDeposit;
        uint256 decimal;
        for(uint8 i=0;i<3;i++) {
           currentAmount=getBalances(i);
           decimal=tokens[i].decimals();
           uint256 strategyAmount=selfBalance[i].mul(poolPart).div(DENOMINATOR);
           if(strategyAmount > currentAmount) {
              amountToWithdraw[i] = strategyAmount.sub(currentAmount);
              if(amountToWithdraw[i]<(50*(10**decimal))){
                  amountToWithdraw[i]=0;
              }
           }
           else if(strategyAmount < currentAmount) {
               amountToDeposit[i] = currentAmount.sub(strategyAmount);
               if(amountToDeposit[i]<(50*(10**decimal))){
                   amountToDeposit[i]=0;
               }
               else{
                  tokens[i].transfer(address(curveStrategy), amountToDeposit[i]);
               }
           }
           else {
               amountToWithdraw[i] = 0;
               amountToDeposit[i] = 0;
           }
        }
        if(checkValidArray(amountToDeposit)){
             _deposit(amountToDeposit);
             
        }
        if(checkValidArray(amountToWithdraw)) {
            _withdraw(amountToWithdraw);
            
        }

    }


    function getBalances(uint _index) public view returns(uint256) {
        return tokens[_index].balanceOf(address(this));
    }

    /* ADMIN FUNCTIONS */
    
    function setLoanContract(address _loanContract)external onlyWallet() {
        loanContract=_loanContract;
        
    }

    function changePoolPart(uint128 _newPoolPart) external onlyWallet()  {
        poolPart = _newPoolPart;
        
    }


    function setThresholdTokenAmount(uint256 _newThreshold) external onlyWallet()  {
        threshold = _newThreshold;
        
    }

    function changeCurveStrategy(address _strategy) onlyWallet() external  {
        for(uint8 i=0;i<3;i++){
            require(YieldPoolBalance[i]==0, "Call withdrawAll function first");
        } 
        curveStrategy=rCurveStrategy(_strategy);
        
    }

    function setLockPeriod(uint256 lockperiod) onlyWallet() external  {
        lock_period = lockperiod;
        
    }

    function setWithdrawFees(uint128 _fees) onlyWallet() external {
        fees = _fees;
        
    }
    
    function getAmountSuppliedLength(address _address)public view returns(uint256){
        return amountSupplied[_address].length;
    }
    
    function getYourLiquidity(address _address , uint256 _index) public view returns(uint256){
       (uint256 amount,)= availableLiquidity(_address,_index,false);
       return amount;
    }
}