/**
 *Submitted for verification at polygonscan.com on 2021-12-08
*/

pragma solidity ^0.8.6;
contract HousePool
{
    //structs
    struct UserBoxStruct{
        uint BoxNum;
        uint Balance;
        uint ActualBalance;
        uint DepositTime;
        uint rewardDept;
        //Extra
        uint LossDept;
    }
    //mapping()
    mapping (address => mapping(uint=>UserBoxStruct)) public Users;
    mapping(address => uint[])public UserLockBoxNums;
    mapping(address => uint)public UserBoxLength;
    mapping(address =>mapping(uint=>bool))public BoxExits;
    mapping(address => bool)public AccessGrant;

    //State variables
    bool internal locked;
    uint256 public constant maxProfitDivisor = 1000000; //supports upto four decimals
    uint256 public maxProfit; //ma x profit user can make
    uint256 public maxProfitAsPercentOfHouse; //mac profit as percent
    uint256 public minBet;
    uint256 public minBetAspercent;
    uint256 public minBetDivisor=10000;//supports 2 decimals
    uint256 public maxBetAsPercent;//maxmimum bet-->supports upto two decimals
    uint256 public maxBet;
    uint256 public maxBetDivisor=10000;//supports 2decimals
    uint public releaseTime=1 minutes;
    uint public TotalDepositedAmount;
    uint public TotalValueLocked;//without rewards 
    uint public AccRewardPershare;
    address public Bettingcontract;
    //Extra
    uint public AccLossPerShare;

    uint public BoxNum;
    address public Owner;
    uint public TotalRewardAmountgained;//Balance will be coming in and update this variable
    //uint public PreviousUpdatedrewards;// like when we updated pool.lastreward block
 
    //modifiers
    modifier OnlyBetting(){
        require(msg.sender == Bettingcontract,"Caller is not betting contract");
        _;
    }
    modifier OnlyOwner(){
        require(msg.sender == Owner,"Caller is NOt an Owner" );
        _;
    }
    modifier CheckZero(){
        require(msg.value > 0,"Value needs to be greater than zero");
        _;
    }
    modifier ValidBox(address _user,uint _box){
        require(BoxExits[_user][_box]==true);
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == Owner) ;
        _;
    }
    modifier IsGranted(address _account)
    {
        require(AccessGrant[_account] == true,"No Access to Call function");
        _;
    }
     modifier noReentrancy() {
        require(!locked , "No reentrancy");
        locked = true;
        _;
        locked = false;
    }
    //events
    event Deposit(address indexed _sender,uint _amount,uint _depositedTime,uint _boxNum,uint _releaseTime);
    event Withdraw(address indexed _sender,uint _amount,uint _boxNum);
    event transfer(address indexed _to,uint _amount);
    //constructor
    constructor(){
        Owner = msg.sender;
        ownerSetMinBet(1); 
        ownerSetMaxBet(10);
        ownerSetMaxProfitAsPercentOfHouse(1000); 
    }
    //address
    
    //functions
    
    function deposit() public payable CheckZero returns(bool success) {
        BoxNum=BoxNum+1;
        UserLockBoxNums[msg.sender].push(BoxNum);
        UserBoxStruct storage user=Users[msg.sender][BoxNum];
        user.Balance  += msg.value;
        user.DepositTime = block.timestamp;
        BoxExits[msg.sender][BoxNum]=true;
        TotalDepositedAmount +=msg.value;
        TotalValueLocked +=msg.value;
        UserBoxLength[msg.sender] += 1;
        SetMinimumBet();
        SetMaxBet();
        setMaxProfit();
        user.rewardDept = (user.Balance*(AccRewardPershare))/(1e18);//assigning the rewards upto now we gained 
        //Extra
        user.LossDept =(user.Balance *(AccLossPerShare)/(1e18));//assigning the loss
        emit Deposit(msg.sender,msg.value,user.DepositTime,BoxNum,(user.DepositTime+releaseTime));
        return true;

    }
    
    
    function PendingRewards(address _user,uint _box) public ValidBox(_user,_box)   view returns(uint)
    {
        // uint RewardAmount;
        uint accrewardpershare =AccRewardPershare;
         //RewardAmount=getMultiplier(TotalRewardAmountgained,PreviousUpdatedrewards);
        // if(RewardAmount > 0)
        // {
        //     accrewardpershare =accrewardpershare+((RewardAmount*1e18)/TotalDepositedAmount);
        // }
        
        uint pending;
        UserBoxStruct storage user = Users[_user][_box];
       
        if(((user.Balance *  accrewardpershare)/1e18) > user.rewardDept)
        {
            pending =((user.Balance*AccRewardPershare)/(1e18))-(user.rewardDept);
        }
        return pending;
    }
    // function getMultiplier(uint Total,uint Previous)public view returns(uint)
    // {
    //     return (Total - Previous);
    // }
    
    function withdraw(uint amount,uint _box) public ValidBox(msg.sender,_box) noReentrancy returns(bool success) 
    {
        //CalculateAccumulatePerShare();
        //UpdateRewardAmount();//Not-neccesary
        setMyPresentBalance(msg.sender,_box);
        UserBoxStruct storage user = Users[msg.sender][_box];
        require(amount <= user.ActualBalance,"Look into the Acyual Balance");
        require(block.timestamp > (user.DepositTime + releaseTime),"The Locking is not completed");
        
        uint pending=((user.Balance*AccRewardPershare)/(1e18))-(user.rewardDept);
          if(pending > 0)
          {
              payable(msg.sender).transfer(pending);
          }
        if(amount > 0)
        {
            if(user.ActualBalance - amount== 0)
            {
                TotalDepositedAmount -=user.Balance;
                user.Balance =0;
                ////delete the lock box from boxes of the user
                for(uint i=0;i<UserLockBoxNums[msg.sender].length;i++)
                {
                    if(UserLockBoxNums[msg.sender][i] == _box)
                    {
                        UserLockBoxNums[msg.sender][i]=UserLockBoxNums[msg.sender][(UserLockBoxNums[msg.sender].length)-1];
                        delete UserLockBoxNums[msg.sender][(UserLockBoxNums[msg.sender].length)-1];
                        UserBoxLength[msg.sender] -=1;
                        BoxExits[msg.sender][_box]=false;
                    }
                }
                // //st false for the box exist
                 
                
            }
            else
            {
                uint UserLostAmount =user.Balance-user.ActualBalance;
                TotalDepositedAmount -=(amount+UserLostAmount);
                //TotalDepositedAmount -=amount;
                //user.Balance -=amount;
                user.Balance -=(amount + UserLostAmount);
            }


            user.ActualBalance -=amount; 
           // user.ActualBalance = user.ActualBalance - (amount);
           if(amount <= TotalValueLocked)
           {
               TotalValueLocked -=amount;
               payable(msg.sender).transfer(amount);
           }
           else
           {
                TotalValueLocked =0;
               payable(msg.sender).transfer(TotalValueLocked);  
           }
           
           SetMinimumBet();
            SetMaxBet();
            setMaxProfit();  
            //Transfer( amount);
            //TotalDepositedAmount=TotalDepositedAmount-amount;
            user.LossDept =(user.Balance*(AccLossPerShare))/(1e18);//doudth
        }
         user.rewardDept = (user.Balance*(AccRewardPershare))/(1e18);//doudth
         emit Withdraw(msg.sender,amount,_box);
         return true;
         //user.LossDept =(user.Balance*(AccLossPerShare))/(1e18);//doudth
    } 

    
    function GetMypresentBalance(address _user,uint _box)public view returns(uint actualamount)
    {
       UserBoxStruct storage user = Users[_user][_box];
       //require(user.Balance > 0,"The Balance is Low");
       actualamount = (user.Balance-((user.Balance*AccLossPerShare)/(1e18)))+(user.LossDept);
    }
    function setMyPresentBalance(address _user,uint _box)internal returns(uint){//Keep it internal
       UserBoxStruct storage user = Users[_user][_box];
       //require(user.Balance > 0,"The Balance is Low");
        user.ActualBalance = GetMypresentBalance(_user,_box);
        return user.ActualBalance;

    }
    
    function Getmybalance(uint _box)public view returns(uint )
    {
        UserBoxStruct storage user = Users[msg.sender][_box];
        return user.Balance;
    }
    fallback() external payable{
        
    }
    //Owner functions
    function Transfer(uint _amount)public noReentrancy IsGranted(msg.sender)  {
        require(_amount > 0,"The input amount is very less");
        require(_amount <= address(this).balance,"The amount is too high");
        if(_amount <= TotalValueLocked)
        {
            TotalValueLocked =TotalValueLocked - _amount;
            payable(msg.sender).transfer(_amount);
            
        }
        else
        {
            TotalValueLocked =0;
            payable(msg.sender).transfer(TotalValueLocked);
            
        }
        
        CalculateLossPerShare(_amount);
        //payable(msg.sender).transfer(_amount);
        SetMinimumBet();
        SetMaxBet();
        setMaxProfit();
        emit transfer(msg.sender,_amount);
        
    }

    // function EmergencyTransfer(uint _amount,address _user)public noReentrancy OnlyOwner{
    //     require(_amount > 0,"The input amount is very less");
    //     require(_amount <= address(this).balance,"The amount is too high");
    //     if(_amount <= TotalValueLocked)
    //     {
    //         payable(msg.sender).transfer(_amount);
    //         TotalValueLocked =TotalValueLocked - _amount;
    //     }
    //     else
    //     {
    //         payable(msg.sender).transfer(TotalValueLocked);
    //         TotalValueLocked =0;
    //     }
        
    //     // TotalDepositedAmount =TotalDepositedAmount -_amount;
    //     CalculateLossPerShare(_amount);
    //     //payable(_user).transfer(_amount);
    //     SetMinimumBet();
    //     SetMaxBet();
    //     setMaxProfit();
    // }
    //One idea-->create only betting ,so that only betting contract can call this transfer and CalculateAccumulatePerShare
    function TransferOwnerShip(address _newOwner)public OnlyOwner {
        require(_newOwner != address(0),"The address cannot be zero");
        Owner = _newOwner;
    } 
    function CalculateAccumulatePerShare(uint _amount)public IsGranted(msg.sender){
        
       TotalRewardAmountgained += _amount;
       uint RewardAmount=_amount;
        if(RewardAmount > 0)
        {
            AccRewardPershare =AccRewardPershare+((RewardAmount*1e18)/TotalDepositedAmount);
            //PreviousUpdatedrewards +=RewardAmount;
        }
    } 
    //Extra
    function CalculateLossPerShare(uint _amount)internal{
        uint LossAmount = _amount;
        if(LossAmount > 0)
        {
            AccLossPerShare = AccLossPerShare+((LossAmount*1e18)/TotalDepositedAmount);
        }
    }
    function ownerSetMinBet(uint256 newMinimumBet) public onlyOwner {
        require(newMinimumBet > 0,"It needs to greater than zero");
        minBetAspercent = newMinimumBet;//set as the percentage which will support the 2 decimals
        SetMinimumBet();
    }
    function ownerSetMaxBet(uint256 newMaximumBet)public onlyOwner{
        require(newMaximumBet > 0,"It needs to greater than zero");
        maxBetAsPercent = newMaximumBet;
        SetMaxBet();
    }
    
    function ownerSetMaxProfitAsPercentOfHouse(uint256 newMaxProfitAsPercent)
        public
        onlyOwner
    {
        /* restrict each bet to a maximum profit of 1% contractBalance */
       // if (newMaxProfitAsPercent > 10000) throw;
       //CAW
       require(newMaxProfitAsPercent > 0);
        maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
        setMaxProfit();
    }
    
    function SetMaxBet()internal{
        require(maxBetAsPercent > 0);
        maxBet=(address(this).balance * maxBetAsPercent)/maxBetDivisor;
    }


    function SetMinimumBet()internal{
        require(minBetAspercent > 0);
        // uint contractBalance=address(this).balance;
       minBet = (address(this).balance * minBetAspercent)/minBetDivisor;
    }

    function setMaxProfit() internal {
        require(maxProfitAsPercentOfHouse > 0);
        maxProfit =
            (address(this).balance * maxProfitAsPercentOfHouse) /
            maxProfitDivisor;
    }
    function SetBettingContract(address _betting)public onlyOwner
    {
        require(_betting != address(0));
        Bettingcontract=_betting;
    }
    function SetTransferAccess(address _account)public onlyOwner
    {
        require(_account != address(0));
        AccessGrant[_account]=true;

    }
    function TransferOwnership(address _account)public onlyOwner
    {
        require(_account != address(0));
        Owner=_account;
    }
    
}