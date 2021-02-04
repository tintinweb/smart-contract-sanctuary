// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import './SafeMath.sol';
import './RoyaleLPVariables.sol';


contract RoyaleLP is RoyaleLPstorage {
     
  using SafeMath for uint256;
  
  modifier onlyWallet(){
      require(true || wallet ==msg.sender, "Not Authorized");
      _;
  }
  
  modifier validAmount(uint amount){
      require(amount>0, "Not a valid amount");
      _;
  }

   modifier onlyAuthorized(address _caller) {
        require( _caller == loanContract, "not authorized");
        _;
    }
    
    
    
    // EVENTS 
    event userSupplied(address user,uint amount);

    event userRecieved(address user,uint amount);

    event userAddedToQ(address user,uint amount);
    
    
    constructor(address[N_COINS] memory _tokens,address _rpToken,address _wallet) public {
        for(uint8 i=0; i<N_COINS; i++) {
            tokens[i] = IERC20(_tokens[i]);
        }
        rpToken = IERC20(_rpToken);
        wallet=_wallet;
    }
    
     function transferOwnership(address _wallet) external onlyWallet(){
        wallet =_wallet;
    }

    /* INTERNAL FUNCTIONS */

    function getBalances() public view returns(uint256[N_COINS] memory) {
        uint256[N_COINS] memory balances;
        for(uint8 i=0; i<N_COINS; i++) {
            balances[i] = tokens[i].balanceOf(address(this));
        }
        return balances;
    }

    // functions related to deposit and supply
    
    // This function deposits the fund to Yield Optimizer
    function _deposit(uint256[N_COINS] memory amounts) internal {
        curveStrategy.deposit(amounts);
        for(uint8 i=0; i<N_COINS; i++) {
            YieldPoolBalance[i] =YieldPoolBalance[i].add(amounts[i]);
        }
    }
   
    //Internal Calculation For User Supply 

    function _supply(uint256 amount,uint256 _index) internal {
        bool result;
        uint256 mintAmount=calcRptAmount(amount,_index);
        result = tokens[_index].transferFrom(msg.sender, address(this), amount);
        require(result, "coin transfer failed");
        selfBalance[_index] =selfBalance[_index].add(amount);
        rpToken.mint(msg.sender, mintAmount);
        lockedDetails memory details=lockedDetails(mintAmount,now,mintAmount);
        lockedRPT[msg.sender][_index].push(details);
        depositDetails memory d = depositDetails(amount ,_index);
        amountSupplied[msg.sender].push(d);
    }



    // functions related to withdraw, withdraw queue and withdraw from Yield Optimizer
    function _takeBack(address recipient) internal {
        bool result;
        for(uint8 i=0; i<N_COINS; i++) {
            if(amountWithdraw[recipient][i] > 0) {
                uint temp = amountWithdraw[recipient][i].sub((amountWithdraw[recipient][i].mul(fees)).div(DENOMINATOR));
                result = tokens[i].transfer(recipient,  temp);
                require(result,"Transfer Not Succesful");
                totalWithdraw[i] =totalWithdraw[i].sub(amountWithdraw[recipient][i]);
                selfBalance[i] = selfBalance[i].sub(temp);
                updateLockedRPT(amountBurnt[recipient][i],i);
                amountWithdraw[recipient][i] = 0;
                amountBurnt[recipient][i]=0;
            }
        }
        for(uint8 i=0;i<N_COINS;i++){
            if(amountBurnt[recipient][i]!=0 && amountWithdraw[recipient][i]!=0){
                rpToken.mint(recipient,amountBurnt[recipient][i]);
            }
            amountBurnt[recipient][i]=0;
            amountWithdraw[recipient][i]=0;
        }
        isInQ[recipient] = false;
        recipientCount -= 1;
    }


    // this will fulfill withdraw requests from the queue
    function _giveBack() internal {
        uint32 counter = recipientCount;
        for(uint8 i=0; i<counter; i++) {
            address recipient = getFromQ();
            _takeBack(recipient);
        }

    }
    
     function updateLockedRPT(uint256 amount,uint _index) internal{
        uint x=amount;
        for(uint8 j=0; j<lockedRPT[msg.sender][_index].length; j++) {
             if(lockedRPT[msg.sender][_index][j].remAmt > 0 && x > 0) {
                  if(x >= lockedRPT[msg.sender][_index][j].remAmt) {
                        x = x.sub( lockedRPT[msg.sender][_index][j].remAmt);
                        lockedRPT[msg.sender][_index][j].remAmt = 0;
                    }
                    else {
                        lockedRPT[msg.sender][_index][j].remAmt =(lockedRPT[msg.sender][_index][j].remAmt).sub(x);
                        x = 0;
                    }
                }
            }
    }

      function checkWithdraw(uint256 amount,uint256 burnAmt,uint _index) internal{
        uint256[N_COINS] memory poolBalance;
        poolBalance = getBalances();
         bool instant;
          if(amount < poolBalance[_index]) {
                instant = true;
         }
        rpToken.burn(msg.sender, burnAmt);
        if(instant) {
            bool result;
            uint temp = amount.sub(amount.mul(fees).div(DENOMINATOR));
            selfBalance[_index] =selfBalance[_index].sub(temp);
            result = tokens[_index].transfer(msg.sender, temp);
            require(result,"Transfer not Succesful");
            updateLockedRPT(burnAmt,_index);
            emit userRecieved(msg.sender, temp);
        } else {
            _takeBackQ(amount,burnAmt,_index);

            emit userAddedToQ(msg.sender, amount);
        }
    }



    // this will add unfulfilled withdraw requests to the queue
    function _takeBackQ(uint256 amount,uint256 _burnAmount,uint256 _index) internal {
        amountWithdraw[msg.sender][_index] =amountWithdraw[msg.sender][_index].add( amount);
        amountBurnt[msg.sender][_index]=amountBurnt[msg.sender][_index].add(_burnAmount);
        totalWithdraw[_index] =totalWithdraw[_index].add(amount);
        if(isInQ[msg.sender] != true) {
            recipientCount += 1;
            isInQ[msg.sender] = true;
            addToQ(msg.sender);
        }

    }

  


    // this will withdraw from Yield Optimizer into this contract
    function _withdraw(uint256[N_COINS] memory amounts) internal {
        curveStrategy.withdraw(amounts);
        for(uint8 i=0; i<N_COINS; i++) {
            YieldPoolBalance[i] =YieldPoolBalance[i].sub(amounts[i]);
        }
    }

    //This function calculate RPT to be mint or burn
    function calcRptAmount(uint256 amount,uint _index) public view returns(uint256) {
        uint256 total = 0;
        uint256 decimal = 0;
        uint256 totalSuppliedTokens;
        for(uint8 i=0; i<N_COINS; i++) {
            decimal = tokens[i].decimals();
            total =total.add((selfBalance[i].sub(totalWithdraw[i]).add(loanGiven[i])).mul(1e18).div(10**decimal));
            if(i==_index){
                totalSuppliedTokens=totalSuppliedTokens.add(amount.mul(1e18).div(10**decimal));
            }
        }
        return (totalSuppliedTokens.mul(rpToken.totalSupply()).div(total));        
    }



    //function to check available amount to withdraw for user
    function availableWithdraw(address addr, uint coin) public view returns(uint256 token,uint256 RPT) {
        uint256 amount=0;
        for(uint8 j=0; j<lockedRPT[addr][coin].length; j++) {
            if( ((now - lockedRPT[addr][coin][j].time)  > (/*24 * 60 * 60 **/ lock_period))&& lockedRPT[addr][coin][j].remAmt >0) {
                amount =amount.add(lockedRPT[addr][coin][j].remAmt);
            }
        }
        amount =amount.sub(amountBurnt[addr][coin]);
        uint256 total = 0;
        uint256 decimal = 0;
        for(uint8 i=0; i<N_COINS; i++) {
            decimal = tokens[i].decimals();
            total =total.add((selfBalance[i].sub(totalWithdraw[i]).add(loanGiven[i])).mul(1e18).div(10**decimal));
        } 
        decimal=tokens[coin].decimals();
        return ((amount.mul(total).mul(10**decimal).div(rpToken.totalSupply())).div(10**18),amount);
    }




    /* USER FUNCTIONS (exposed to frontend) */
   

    function supply(uint256 amount,uint256 _index) external validAmount(amount){
        _supply(amount,_index);
        emit userSupplied(msg.sender, amount);
    }

    function requestWithdraw(uint256 amount,uint256 _index) external validAmount(amount){
        require(amount <selfBalance[_index],"Not Enough Balance in pool");
        uint256 burnAmt;
        burnAmt = calcRptAmount(amount,_index);
        require(rpToken.balanceOf(msg.sender) >= burnAmt, "low RPT");

        bool checkTime = true;
       
        (uint256 availableAmount,)=availableWithdraw(msg.sender,_index );
        
        if(availableAmount < amount) {
                    checkTime = false;
        }
        require(checkTime, "lock period | not supplied");
        checkWithdraw(amount,burnAmt,_index);
        
    }
    
  
    
    function requestWithdrawWithRPT(uint256 amount,uint256 _index) external validAmount(amount){
         require(rpToken.balanceOf(msg.sender) >= amount, "low RPT");
         (,uint availableRPT)=availableWithdraw(msg.sender,_index );
         bool checkTime = true;
         if(availableRPT < amount) {
                    checkTime = false;
        }
        require(checkTime, "lock period | not supplied");
         uint256 total = 0;
         uint256 decimal = 0;
        for(uint8 i=0; i<N_COINS; i++) {
            decimal = tokens[i].decimals();
            total =total.add((selfBalance[i].sub(totalWithdraw[i]).add(loanGiven[i])).mul(1e18).div(10**decimal));
        }
        uint256 tokenAmount;
        decimal=tokens[_index].decimals();
        tokenAmount=amount.mul(total).mul(10**decimal).div(rpToken.totalSupply()).div(10**18);
        require(tokenAmount <= selfBalance[_index],"Not Enough balance in pool");
        checkWithdraw(tokenAmount,amount,_index);
        
    }
   
    
 
    // Following two functions are called by rLoan Only
    function _loanWithdraw(
        uint256[N_COINS] memory amounts, 
        address _loanSeeker
    ) public onlyAuthorized(msg.sender) returns(bool) {
        
        for(uint8 i=0;i<3;i++){
            require(amounts[i]<=selfBalance[i],"Not Enough Balance in the pool");
        }
        uint256[N_COINS] memory poolBalance;
        poolBalance = getBalances();
        
         uint check=0;
         for(uint8 i=0;i<3;i++){
             if(amounts[i]<=poolBalance[i]){
                 check++;
             }
         }
        if(check!=3){
            _withdraw(amounts);
        }
        for(uint8 i=0; i<N_COINS; i++) {
            if(amounts[i] > 0) {
                loanGiven[i] =loanGiven[i].add(amounts[i]);
                selfBalance[i] =selfBalance[i].sub( amounts[i]);
                tokens[i].transfer(_loanSeeker, amounts[i]);
            }
        }
        return true;
    }

    //Function only called by multisig contract for transfering tokens
    function _loanRepayment(
        uint256[N_COINS] memory amounts, 
        address _loanSeeker
    ) public onlyAuthorized(msg.sender) returns(bool) {
        for(uint8 i=0; i<N_COINS; i++) {
            if(amounts[i] > 0) {
                loanGiven[i] =loanGiven[i].sub(amounts[i]);
                selfBalance[i] =selfBalance[i].add(amounts[i]);
                tokens[i].transferFrom(_loanSeeker, address(this), amounts[i]);
            }
        }
        return true;
    }

    // this function deposits without minting RPT
    function depsoitInRoyale(uint256[N_COINS] calldata amounts) external {
        for(uint8 i=0;i<N_COINS;i++){
            if(amounts[i]!=0){
             tokens[i].transferFrom(msg.sender,address(this),amounts[i]);
             selfBalance[i]=selfBalance[i].add(amounts[i]);
            }
        }
    }


    /* CORE FUNCTIONS (called by owner only) */

    //Deposit in the smart backed pool
    function deposit() onlyWallet() external {
        uint256[N_COINS] memory amounts = getBalances();
        uint256 decimal;

        //rStrategyI[3] memory strat = controller.getStrategies();
        for(uint8 i=0; i<N_COINS; i++) {
            decimal = tokens[i].decimals();
            if(amounts[i] > thresholdTokenAmount.mul(10**decimal)) {
                amounts[i] =amounts[i].add(YieldPoolBalance[i]);
                amounts[i] = amounts[i].mul(DENOMINATOR.sub(poolPart)).div(DENOMINATOR);
                amounts[i] = amounts[i].sub(YieldPoolBalance[i]);
                tokens[i].transfer(address(curveStrategy), amounts[i]);
            }
            else {
                amounts[i] = 0;
            }
        }
        uint8 counter = 0;
        for(uint8 i=0; i<N_COINS; i++) {
           if(amounts[i] != 0) {
               counter++;
               break;
           }
        }

        if(counter > 0){
            _deposit(amounts);
        }
    }

    //Withdraw from Pool
    function withdraw() onlyWallet() external {
        uint8 counter = 0;
        for(uint8 i=0; i<N_COINS; i++) {
           if(totalWithdraw[i] != 0) {
               counter++;
               break;
           }
        }

        require(counter > 0, "withdraw queue empty");
        _withdraw(totalWithdraw);
        _giveBack();
        resetQueue();
    }


    function withdrawAll() public onlyWallet() {
        uint[3] memory amounts;
        amounts=curveStrategy.withdrawAll();
        for(uint8 i=0;i<3;i++){
            if(amounts[i]>YieldPoolBalance[i]){
                 uint256 profit=amounts[i]-YieldPoolBalance[i];
                 selfBalance[i] +=profit;
                 YieldPoolBalance[i]=0;
            }
            else{
               uint256 loss=YieldPoolBalance[i].sub(amounts[i]);
               selfBalance[i] = selfBalance[i].sub(loss);
               YieldPoolBalance[i]=0;
            }

        }

    }

    //function for rebalancing pool(ratio)      
    function rebalance() onlyWallet() external {
        uint256[N_COINS] memory currentAmount = getBalances();
        uint256[N_COINS] memory amountToWithdraw;
        uint256[N_COINS] memory amountToDeposit;

        for(uint8 i=0;i<N_COINS;i++) {
           uint256 decimal=tokens[i].decimals();
           
           uint256 a=selfBalance[i].mul(poolPart.mul(1e18).div(DENOMINATOR));
           if(a > currentAmount[i]) {
              amountToWithdraw[i] = a.sub(currentAmount[i]);
              if(amountToWithdraw[i]<(50*(10**decimal))){
                  amountToWithdraw[i]=0;
              }
           }
           else if(a < currentAmount[i]) {
               amountToDeposit[i] = currentAmount[i] - a;
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

        bool check=false;
        for(uint8 i=0; i<N_COINS; i++) {
            if(amountToDeposit[i] > 0) {
                  check = true;
                  break;
            }
        }

        if(check){
             _deposit(amountToDeposit);
             check = false;
        }

        for(uint8 i=0; i<N_COINS; i++) {
            if(amountToWithdraw[i] > 0) {
                  check = true;
                  break;
            }
        }
        
        if(check) {
            _withdraw(amountToWithdraw);
             check = false;
        }

    }


    /* ADMIN FUNCTIONS */

    
    function getTotalPoolBalance() external view returns(uint256[3] memory) {
        return selfBalance;
    }

    function getTotalLoanGiven() external view returns(uint256[3] memory) {
        return loanGiven;
    }

    function setLoanContract(address _loanContract)external onlyWallet() returns(bool){
        loanContract=_loanContract;
        return true;
    }

    function changePoolPart(uint128 _newPoolPart) external onlyWallet() returns(bool) {
        poolPart = _newPoolPart;
        return true;
    }


    function setThresholdTokenAmount(uint256 _newThreshold) external onlyWallet() returns(bool) {
        thresholdTokenAmount = _newThreshold;
        return true;
    }

    function setInitialDeposit() onlyWallet() external returns(bool) {
        selfBalance = getBalances();
        return true;
    }

    function changeCurveStrategy(address _strategy) onlyWallet() external returns(bool) {
        for(uint8 i=0;i<3;i++){
            require(YieldPoolBalance[i]==0, "Call withdrawAll function first");
        } 
        curveStrategy=rCurveStrategy(_strategy);
        return true;
    }

    function setLockPeriod(uint256 lockperiod) onlyWallet() external returns(bool) {
        lock_period = lockperiod;
        return true;
    }

    function setWithdrawFees(uint128 _fees) onlyWallet() external returns(bool) {
        fees = _fees;
        return true;
    }

}