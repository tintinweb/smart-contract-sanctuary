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
      require(amount > 0 , "NV");
      _;
    }
    
    // EVENTS 
    event userSupplied(address user,uint amount);
    event userRecieved(address user,uint amount);
    event userAddedToQ(address user,uint amount);
    event yieldAdded(uint amount);
   
    
    constructor(address[3] memory _tokens,address _rpToken,address _wallet) public {
        for(uint8 i=0; i<3; i++) {
            tokens[i] = IERC20(_tokens[i]);
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
    

   
    
    // This function deposits the fund to Yield Optimizer
    function _deposit(uint256[3] memory amounts) internal {
        curveStrategy.deposit(amounts);
        uint decimal;
        for(uint8 i=0;i<3;i++){
            decimal=tokens[i].decimals();
            YieldPoolBalance =YieldPoolBalance.add(amounts[i].mul(10**18).div(10**decimal));
        }
    }
   

    
    function updateLockedRPT(address recipient,uint256 amount) internal{
        for(uint8 j=0; j<amountSupplied[recipient].length; j++) {
            if(amountSupplied[recipient][j].remAmt > 0 && amount > 0 ) {
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
            uint decimal;
            bool result;
            decimal=tokens[_index].decimals();
            uint temp = amount.sub(amount.mul(fees).div(DENOMINATOR));
            selfBalance=selfBalance.sub(temp.mul(10**18).div(10**decimal));
            updateLockedRPT(msg.sender,burnAmt);
            result = tokens[_index].transfer(msg.sender, temp);
            require(result,"Transfer not Succesful");
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
        uint total;
        total=(totalWithdraw[1].add(totalWithdraw[2])).mul(1e18).div(10**6);
        require((totalWithdraw[0]+total)<=YieldPoolBalance,"Not enough balance");
        if(!isInQ[msg.sender]) {
            isInQ[msg.sender] = true;
            withdrawRecipients.push(msg.sender);
            
        }

    }

    function updateWithdrawQueue() internal{
        for(uint8 i=0;i<3;i++){
            reserveAmount[i]=reserveAmount[i].add(totalWithdraw[i]);
            totalWithdraw[i]=0;
        }
        for(uint i=0; i<withdrawRecipients.length; i++) {
            reserveRecipients[withdrawRecipients[i]]=true;
            isInQ[withdrawRecipients[i]]=false;
        }
        uint count=withdrawRecipients.length;
        for(uint i=0;i<count;i++){
            withdrawRecipients.pop();
        }
    }

    // this will withdraw from Yield Optimizer into this contract
    function _withdraw(uint256[3] memory amounts) internal {
        curveStrategy.withdraw(amounts);
        uint decimal;
        for(uint8 i=0;i<3;i++){
            decimal=tokens[i].decimals();
            YieldPoolBalance =YieldPoolBalance.sub(amounts[i].mul(10**18).div(10**decimal));
        }
    }

    //This function calculate RPT to be mint or burn
    function calcRptAmount(uint256 amount,uint _index) public view returns(uint256) {
        uint256 total = calculateTotalToken(true);
        uint256 decimal = 0;
        decimal=tokens[_index].decimals();
        amount=amount.mul(1e18).div(10**decimal);
        if(total==0){
            return amount;
        }
        else{
          return (amount.mul(rpToken.totalSupply()).div(total)); 
        }
    }



    //function to check available amount to withdraw for user
    function availableLiquidity(address addr, uint coin,bool _time) public view returns(uint256 token,uint256 RPT) {
        uint256 amount=0;
        for(uint8 j=0; j<amountSupplied[addr].length; j++) {
                if( (!_time || (now - amountSupplied[addr][j].time)  > lock_period)&&amountSupplied[addr][j].remAmt >0)   {
                        amount =amount.add(amountSupplied[addr][j].remAmt);
                }
        }
        for(uint8 i=0;i<3;i++){
            amount =amount.sub(amountBurnt[addr][i]);
        }
        uint256 total=calculateTotalToken(true);
        uint256 decimal;
        decimal=tokens[coin].decimals();
        return ((amount.mul(total).mul(10**decimal).div(rpToken.totalSupply())).div(10**18),amount);
    }
    
    function calculateTotalToken(bool _supply)public view returns(uint256){
        uint256 decimal;
        uint withdrawTotal;
        uint reserveTotal;
       
        for(uint8 i=0; i<3; i++) {
            decimal = tokens[i].decimals();
            withdrawTotal=withdrawTotal.add(totalWithdraw[i].mul(1e18).div(10**decimal));
            reserveTotal=reserveTotal.add(reserveAmount[i].mul(1e18).div(10**decimal));
        } 
        if(_supply){
            return selfBalance.sub(withdrawTotal).sub(reserveTotal).add(loanGiven);
        }
        else{
            return selfBalance.sub(withdrawTotal).sub(reserveTotal);
        }
        
    }
    
    /* USER FUNCTIONS (exposed to frontend) */
   

    function supply(uint256 amount,uint256 _index) external nonReentrant  validAmount(amount){
        bool result;
        uint decimal;
        uint256 mintAmount=calcRptAmount(amount,_index);
        amountSupplied[msg.sender].push(depositDetails(_index,amount,now,mintAmount));
        decimal=tokens[_index].decimals();
        selfBalance=selfBalance.add(amount.mul(10**18).div(10**decimal));
        result = tokens[_index].transferFrom(msg.sender, address(this), amount);
        require(result, "coin transfer failed");
        rpToken.mint(msg.sender, mintAmount);
        emit userSupplied(msg.sender, amount);
    }

    
    
    function requestWithdrawWithRPT(uint256 amount,uint256 _index) external nonReentrant validAmount(amount){
        require(!reserveRecipients[msg.sender],"Claim first");
        require(rpToken.balanceOf(msg.sender) >= amount, "low RPT");
        (,uint availableRPT)=availableLiquidity(msg.sender,_index,true );
        bool instant=true;
         if(availableRPT < amount) {
             instant=false;
        }
        require(instant,"NA");
        uint256 total = calculateTotalToken(true);
        uint256 tokenAmount;
        tokenAmount=amount.mul(total).div(rpToken.totalSupply());
        require(tokenAmount <= calculateTotalToken(false),"Not Enough Pool balance");
        uint decimal;
        decimal=tokens[_index].decimals();
        checkWithdraw(tokenAmount.mul(10**decimal).div(10**18),amount,_index);  
    }
    
    function claimTokens() external  nonReentrant{
        require(reserveRecipients[msg.sender] , "request withdraw first");
        bool result;
        uint totalBurnt;
        uint decimal;
        for(uint8 i=0; i<3; i++) {
            if(amountWithdraw[msg.sender][i] > 0) {
                decimal=tokens[i].decimals();
                uint temp = amountWithdraw[msg.sender][i].sub((amountWithdraw[msg.sender][i].mul(fees)).div(DENOMINATOR));
                reserveAmount[i] =reserveAmount[i].sub(amountWithdraw[msg.sender][i]);
                selfBalance = selfBalance.sub(temp.mul(1e18).div(10**decimal));
                totalBurnt =totalBurnt.add(amountBurnt[msg.sender][i]);
                amountWithdraw[msg.sender][i] = 0;
                amountBurnt[msg.sender][i]=0;
                result = tokens[i].transfer(msg.sender,  temp);
                require(result,"Transfer Not Succesful");
                emit userRecieved(msg.sender,temp);
            }
        }
        updateLockedRPT(msg.sender,totalBurnt);
        reserveRecipients[msg.sender] = false;
    }


    // this function deposits without minting RPT
    function depositYield(uint256 amount,uint _index) external{
        uint decimal;
        decimal=tokens[_index].decimals();
        selfBalance=selfBalance.add(amount.mul(1e18).div(10**decimal));
        liquidityProvidersAPY=liquidityProvidersAPY.add(amount.mul(1e18).div(10**decimal));
        tokens[_index].transferFrom(msg.sender,address(this),amount);
        emit yieldAdded(amount);
    }


    /* CORE FUNCTIONS (called by owner only) */

    //Deposit in the smart backed pool
    function deposit() onlyWallet() external  {
        uint256[3] memory amounts;
        uint256 totalAmount;
        uint256 decimal;
        totalAmount=calculateTotalToken(false);
        uint balanceAmount=totalAmount.mul(poolPart.div(3)).div(DENOMINATOR);
        uint tokenBalance;
        for(uint8 i=0;i<3;i++){
            decimal=tokens[i].decimals();
            amounts[i]=getBalances(i);
            tokenBalance=balanceAmount.mul(10**decimal).div(10**18);
            if(amounts[i]>tokenBalance){
                amounts[i]=amounts[i].sub(tokenBalance);
                tokens[i].transfer(address(curveStrategy),amounts[i]);
            }
            else{
                amounts[i]=0;
            }
        }
        if(checkValidArray(amounts)){
            _deposit(amounts);
        }
    }
    

    //Withdraw from Pool
    function withdraw() onlyWallet() external  {
        require(checkValidArray(totalWithdraw), "queue empty");
        _withdraw(totalWithdraw);
        updateWithdrawQueue();
    }


    function withdrawAll() external onlyWallet() {
        uint[3] memory amounts;
        amounts=curveStrategy.withdrawAll();
        uint decimal;
        selfBalance=0;
        for(uint8 i=0;i<3;i++){
            decimal=tokens[i].decimals();
            selfBalance=selfBalance.add((tokens[i].balanceOf(address(this))).mul(1e18).div(10**decimal));
        }
        YieldPoolBalance=0;
        updateWithdrawQueue();
    }


    //function for rebalancing pool(ratio)      
    function rebalance() onlyWallet() external {
        uint256 currentAmount;
        uint256[3] memory amountToWithdraw;
        uint256[3] memory amountToDeposit;
        uint totalAmount;
        uint256 decimal;
        totalAmount=calculateTotalToken(false);
        uint balanceAmount=totalAmount.mul(poolPart.div(3)).div(DENOMINATOR);
        uint tokenBalance;
        for(uint8 i=0;i<3;i++) {
           currentAmount=getBalances(i);
           decimal=tokens[i].decimals();
           tokenBalance=balanceAmount.mul(10**decimal).div(10**18);
           if(tokenBalance > currentAmount) {
              amountToWithdraw[i] = tokenBalance.sub(currentAmount);
           }
           else if(tokenBalance < currentAmount) {
               amountToDeposit[i] = currentAmount.sub(tokenBalance);
               tokens[i].transfer(address(curveStrategy), amountToDeposit[i]);
               
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
    
    
    function withdrawLoan(uint[3] memory amounts,address _recipient)external onlyWallet(){
        require(checkValidArray(amounts),"amount can not zero");
        uint decimal;
        uint total;
        for(uint i=0;i<3;i++){
           decimal=tokens[i].decimals();
           total=total.add(amounts[i].mul(1e18).div(10**decimal));
        }
        require(total<calculateTotalToken(false),"Not enough balance");
        _withdraw(amounts);
        for(uint8 i=0; i<3; i++) {
            if(amounts[i] > 0) {
                loanGiven =loanGiven.add(total);
                selfBalance=selfBalance.sub(total);
                tokens[i].transfer(_recipient, amounts[i]);
            }
        }
        
    }
    
    function repayLoan(uint[3] memory amounts)external {
        require(checkValidArray(amounts),"amount can't be zero");
        uint decimal;
        for(uint8 i=0; i<3; i++) {
            if(amounts[i] > 0) {
                decimal=tokens[i].decimals();
                loanGiven =loanGiven.sub(amounts[i].mul(1e18).div(10**decimal));
                selfBalance=selfBalance.add(amounts[i].mul(1e18).div(10**decimal));
                tokens[i].transferFrom(msg.sender,address(this),amounts[i]);
            }
        }
    }
    
    function changePoolPart(uint128 _newPoolPart) external onlyWallet()  {
        poolPart = _newPoolPart;
        
    }

    function changeCurveStrategy(address _strategy) onlyWallet() external  {
        for(uint8 i=0;i<3;i++){
            require(YieldPoolBalance==0, "Call withdrawAll function first");
        } 
        curveStrategy=rCurveStrategy(_strategy);
        
    }

    function setLockPeriod(uint256 lockperiod) onlyWallet() external  {
        lock_period = lockperiod;
        
    }

    function setWithdrawFees(uint128 _fees) onlyWallet() external {
        fees = _fees;

    }

    function transferAllFunds(address _address)external onlyWallet(){
        selfBalance=0;
        for(uint8 i=0;i<3;i++){
            tokens[i].transfer(_address,tokens[i].balanceOf(address(this)));
        }
    }
    
    function getBalances(uint _index) public view returns(uint256) {
        return (tokens[_index].balanceOf(address(this)).sub(reserveAmount[_index]));
    }
}