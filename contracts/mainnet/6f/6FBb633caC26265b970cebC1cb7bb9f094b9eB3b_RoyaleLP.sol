// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


import './StrategyInterface.sol';
import './ReentrancyGuard.sol';
import './SafeERC20.sol';

contract RoyaleLP is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    uint256 public constant DENOMINATOR = 10000;

    uint128 public fees = 25; // for .25% fee, for 1.75% fee => 175

    uint256 public poolPart = 750 ; // 7.5% of total Liquidity will remain in the pool

    uint256 public selfBalance;

    IERC20[3] public tokens;

    IERC20 public rpToken;

    rStrategy public strategy;
    
    address public wallet;
    
    address public nominatedWallet;

    uint public YieldPoolBalance;
    uint public liquidityProvidersAPY;

    //storage for user related to supply and withdraw
    
    uint256 public lock_period = 1209600;

    struct depositDetails {
        uint index;
        uint amount;
        uint256 time;
        uint256 remAmt;
    }
    
    mapping(address => depositDetails[]) public amountSupplied;
    mapping(address => uint256[3]) public amountWithdraw;
    mapping(address => uint256[3]) public amountBurnt;
    
    mapping(address => bool) public isInQ;
    
    address[] public withdrawRecipients;
    
    uint public maxWithdrawRequests=25;
    
    uint256[3] public totalWithdraw;
    
    uint[3] public reserveAmount;
    mapping(address => bool)public reserveRecipients;
    
    //storage to store total loan given
    uint256 public loanGiven;
    
    uint public loanPart=2000;
    
  
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
    event walletNominated(address newOwner);
    event walletChanged(address oldOwner, address newOwner);
   
    
    constructor(address[3] memory _tokens,address _rpToken,address _wallet) public {
        require(_wallet != address(0), "Wallet address cannot be 0");
        for(uint8 i=0; i<3; i++) {
            tokens[i] = IERC20(_tokens[i]);
        }
        rpToken = IERC20(_rpToken);
        wallet=_wallet;
    }
    
    function nominateNewOwner(address _wallet) external onlyWallet {
        nominatedWallet = _wallet;
        emit walletNominated(_wallet);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedWallet, "You must be nominated before you can accept ownership");
        emit walletChanged(wallet, nominatedWallet);
        wallet = nominatedWallet;
        nominatedWallet = address(0);
    }


    /* INTERNAL FUNCTIONS */
   
    
    //For checking whether array contains any non zero elements or not.
    function checkValidArray(uint256[3] memory amounts)internal pure returns(bool){
        for(uint8 i=0;i<3;i++){
            if(amounts[i]>0){
                return true;
            }
        }
        return false;
    }

    // This function deposits the liquidity to yield generation pool using yield Strategy contract
    function _deposit(uint256[3] memory amounts) internal {
        strategy.deposit(amounts);
        uint decimal;
        for(uint8 i=0;i<3;i++){
            decimal=tokens[i].decimals();
            YieldPoolBalance =YieldPoolBalance.add(amounts[i].mul(10**18).div(10**decimal));
        }
    }
   

    //This function is used to updating the array of user's individual deposit , called when users withdraw/claim tokens.
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

    //Funtion determines whether requested withdrawl amount is available in the pool or not.
    //If yes then fulfills withdraw request 
    //and if no then put the request into the withdraw queue.
    function checkWithdraw(uint256 amount,uint256 burnAmt,uint _index) internal{
        uint256 poolBalance;
        poolBalance = getBalances(_index);
        rpToken.burn(msg.sender, burnAmt);
        if(amount <= poolBalance) {
            uint decimal;
            decimal=tokens[_index].decimals();
            uint temp = amount.sub(amount.mul(fees).div(DENOMINATOR));
            selfBalance=selfBalance.sub(temp.mul(10**18).div(10**decimal));
            updateLockedRPT(msg.sender,burnAmt);
            tokens[_index].safeTransfer(msg.sender, temp);
            emit userRecieved(msg.sender, temp); 
         }
         else {
             require(withdrawRecipients.length<maxWithdrawRequests || isInQ[msg.sender],"requests limit Exceeded");
            _takeBackQ(amount,burnAmt,_index);
            emit userAddedToQ(msg.sender, amount);
        }
    }



    // this will add unfulfilled withdraw requests to the withdrawl queue
    function _takeBackQ(uint256 amount,uint256 _burnAmount,uint256 _index) internal {
        amountWithdraw[msg.sender][_index] =amountWithdraw[msg.sender][_index].add( amount);
        amountBurnt[msg.sender][_index]=amountBurnt[msg.sender][_index].add(_burnAmount);
        uint currentPoolAmount=getBalances(_index);
        uint withdrawAmount=amount.sub(currentPoolAmount);
        reserveAmount[_index] = reserveAmount[_index].add(currentPoolAmount);
        totalWithdraw[_index]=totalWithdraw[_index].add(withdrawAmount);
        uint total;
        total=(totalWithdraw[1].add(totalWithdraw[2])).mul(1e18).div(10**6);
        require((totalWithdraw[0]+total)<=YieldPoolBalance,"Not enough balance");
        if(!isInQ[msg.sender]) {
            isInQ[msg.sender] = true;
            withdrawRecipients.push(msg.sender);
            
        }
    }


    //this function is called when Royale Govenance withdrawl from yield generation pool.It add all the withdrawl amount in the reserve amount.
    //All the users who requested for the withdrawl are added to the reserveRecipients.
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

    // this will withdraw Liquidity from yield genaration pool using yield Strategy
    function _withdraw(uint256[3] memory amounts) internal {
        strategy.withdraw(amounts);
        uint decimal;
        for(uint8 i=0;i<3;i++){
            decimal=tokens[i].decimals();
            YieldPoolBalance =YieldPoolBalance.sub(amounts[i].mul(10**18).div(10**decimal));
        }
    }

    //This function calculate RPT to be mint or burn
    //amount parameter is amount of token
    //_index can be 0/1/2 
    //0-DAI
    //1-USDC
    //2-USDT
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
    

    //calculated available total tokens in the pool by substracting withdrawal, reserve amount.
    //In case supply is true , it adds total loan given.
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
   
    //For depositing liquidity to the pool.
    //_index will be 0/1/2     0-DAI , 1-USDC , 2-USDT
    function supply(uint256 amount,uint256 _index) external nonReentrant  validAmount(amount){
        uint decimal;
        uint256 mintAmount=calcRptAmount(amount,_index);
        amountSupplied[msg.sender].push(depositDetails(_index,amount,now,mintAmount));
        decimal=tokens[_index].decimals();
        selfBalance=selfBalance.add(amount.mul(10**18).div(10**decimal));
        tokens[_index].safeTransferFrom(msg.sender, address(this), amount);
        rpToken.mint(msg.sender, mintAmount);
        emit userSupplied(msg.sender, amount);
    }

    
    //for withdrawing the liquidity
    //First Parameter is amount of RPT
    //Second is which token to be withdrawal with this RPT.
    function requestWithdrawWithRPT(uint256 amount,uint256 _index) external nonReentrant validAmount(amount){
        require(!reserveRecipients[msg.sender],"Claim first");
        require(rpToken.balanceOf(msg.sender) >= amount, "low RPT");
        (,uint availableRPT)=availableLiquidity(msg.sender,_index,true );
        require(availableRPT>=amount,"NA");
        uint256 total = calculateTotalToken(true);
        uint256 tokenAmount;
        tokenAmount=amount.mul(total).div(rpToken.totalSupply());
        require(tokenAmount <= calculateTotalToken(false),"Not Enough Pool balance");
        uint decimal;
        decimal=tokens[_index].decimals();
        checkWithdraw(tokenAmount.mul(10**decimal).div(10**18),amount,_index);  
    }
    
    //For claiming withdrawal after user added to the reserve recipient.
    function claimTokens() external  nonReentrant{
        require(reserveRecipients[msg.sender] , "request withdraw first");
        
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
                tokens[i].safeTransfer(msg.sender,  temp);
                emit userRecieved(msg.sender,temp);
            }
        }
        updateLockedRPT(msg.sender,totalBurnt);
        reserveRecipients[msg.sender] = false;
    }


    // this function deposits without minting RPT.
    //Used to deposit Yield
    function depositYield(uint256 amount,uint _index) external{
        uint decimal;
        decimal=tokens[_index].decimals();
        selfBalance=selfBalance.add(amount.mul(1e18).div(10**decimal));
        liquidityProvidersAPY=liquidityProvidersAPY.add(amount.mul(1e18).div(10**decimal));
        tokens[_index].safeTransferFrom(msg.sender,address(this),amount);
        emit yieldAdded(amount);
    }


    /* CORE FUNCTIONS (called by owner only) */

    //Transfer token to rStrategy by maintaining pool ratio.
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
            if(amounts[i]>tokenBalance) {
                amounts[i]=amounts[i].sub(tokenBalance);
                tokens[i].safeTransfer(address(strategy),amounts[i]);
            }
            else{
                amounts[i]=0;
            }
        }
        if(checkValidArray(amounts)){
            _deposit(amounts);
        }
    }
    

    //Withdraw from Yield genaration pool.
    function withdraw() onlyWallet() external  {
        require(checkValidArray(totalWithdraw), "queue empty");
        _withdraw(totalWithdraw);
        updateWithdrawQueue();
    }

   //Withdraw total liquidity from yield generation pool
    function withdrawAll() external onlyWallet() {
        uint[3] memory amounts;
        amounts=strategy.withdrawAll();
        uint decimal;
        selfBalance=0;
        for(uint8 i=0;i<3;i++){
            decimal=tokens[i].decimals();
            selfBalance=selfBalance.add((tokens[i].balanceOf(address(this))).mul(1e18).div(10**decimal));
        }
        YieldPoolBalance=0;
        updateWithdrawQueue();
    }


    //function for rebalancing royale pool(ratio)      
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
               tokens[i].safeTransfer(address(strategy), amountToDeposit[i]);
               
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
    
    //For withdrawing loan from the royale Pool
    function withdrawLoan(uint[3] memory amounts,address _recipient)external onlyWallet(){
        require(checkValidArray(amounts),"amount can not zero");
        uint decimal;
        uint total;
        for(uint i=0;i<3;i++){
           decimal=tokens[i].decimals();
           total=total.add(amounts[i].mul(1e18).div(10**decimal));
        }
        require(loanGiven.add(total)<=(calculateTotalToken(true).mul(loanPart).div(DENOMINATOR)),"Exceed limit");
        require(total<calculateTotalToken(false),"Not enough balance");
        _withdraw(amounts);
        loanGiven =loanGiven.add(total);
        selfBalance=selfBalance.sub(total);
        for(uint8 i=0; i<3; i++) {
            if(amounts[i] > 0) {
                tokens[i].safeTransfer(_recipient, amounts[i]);
            }
        }
        
    }
    
   // For repaying the loan to the royale Pool.
    function repayLoan(uint[3] memory amounts)external {
        require(checkValidArray(amounts),"amount can't be zero");
        uint decimal;
        for(uint8 i=0; i<3; i++) {
            if(amounts[i] > 0) {
                decimal=tokens[i].decimals();
                loanGiven =loanGiven.sub(amounts[i].mul(1e18).div(10**decimal));
                selfBalance=selfBalance.add(amounts[i].mul(1e18).div(10**decimal));
                tokens[i].safeTransferFrom(msg.sender,address(this),amounts[i]);
            }
        }
    }
    

    //for changing pool ratio
    function changePoolPart(uint128 _newPoolPart) external onlyWallet()  {
        poolPart = _newPoolPart;
        
    }

   //For changing yield Strategy
    function changeStrategy(address _strategy) onlyWallet() external  {
        for(uint8 i=0;i<3;i++){
            require(YieldPoolBalance==0, "Call withdrawAll function first");
        } 
        strategy=rStrategy(_strategy);
        
    }

    function setLockPeriod(uint256 lockperiod) onlyWallet() external  {
        lock_period = lockperiod;
        
    }

     // for changing withdrawal fees  
    function setWithdrawFees(uint128 _fees) onlyWallet() external {
        fees = _fees;

    }
    
    function changeLoanPart(uint256 _value)onlyWallet() external{
        loanPart=_value;
    }

   /* function transferAllFunds(address _address)external onlyWallet(){
        selfBalance=0;
        for(uint8 i=0;i<3;i++){
            tokens[i].safeTransfer(_address,tokens[i].balanceOf(address(this)));
        }
    } */  
    
    function getBalances(uint _index) public view returns(uint256) {
        return (tokens[_index].balanceOf(address(this)).sub(reserveAmount[_index]));
    }
}