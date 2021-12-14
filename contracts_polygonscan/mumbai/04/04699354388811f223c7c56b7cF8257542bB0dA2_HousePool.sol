/**
 *Submitted for verification at polygonscan.com on 2021-12-14
*/

pragma solidity ^0.8.6;
contract HousePool
{
    //structs
    struct UserBoxStruct{
        uint Balance;
        uint ActualBalance;
        uint DepositTime;
        uint rewardDept;
        uint LossDept;
    }
    //mapping()
    mapping (address => UserBoxStruct[]) public Users;
    mapping(address => uint)public UserItemlength;
    mapping(address => bool)public AccessGrant;

    //State variables
    bool internal locked;
    uint256 public constant maxProfitDivisor = 1000000; //supports upto four decimals
    uint256 public maxProfit; //ma x profit user can make
    uint256 public maxProfitAsPercentOfHouse; //mac profit as percent
    uint public releaseTime=1 minutes;
    uint public TotalDepositedAmount;
    uint public TotalValueLocked;//without rewards 
    uint public AccRewardPershare;
    //Extra
    uint public AccLossPerShare;

    address public Owner;
    uint public TotalRewardAmountgained;//Balance will be coming in and update this variable
 
    //modifiers
    modifier OnlyOwner(){
        require(msg.sender == Owner,"Caller is NOt an Owner" );
        _;
    }
    modifier CheckZero(){
        require(msg.value > 0,"Value needs to be greater than zero");
        _;
    }
    modifier ValidIndex(address _user,uint _index){
        require(_index <= (Users[_user].length -1));
        _;
    }
    modifier ValidBalance(address _user){
        require(Users[_user].length > 0);
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
    event Deposit(address indexed _sender,uint _amount,uint _depositedTime,uint _IndexNum,uint _releaseTime);
    event Withdraw(address indexed _sender,uint _amount,uint _IndexNum);
    event transfer(address indexed _to,uint _amount);
    //constructor
    constructor(){
        Owner = msg.sender;
        ownerSetMaxProfitAsPercentOfHouse(1000); 
    }
    //address
    
    //functions
    
    function deposit() public payable CheckZero returns(bool success) {

        UserBoxStruct memory user=UserBoxStruct({
            Balance : msg.value,
            DepositTime:block.timestamp,
            ActualBalance:0,
            rewardDept:(msg.value*(AccRewardPershare))/(1e18),
            LossDept:(msg.value *(AccLossPerShare)/(1e18))
        });
        Users[msg.sender].push(user);
        TotalDepositedAmount +=msg.value;
        TotalValueLocked +=msg.value;
        UserItemlength[msg.sender] += 1;
        setMaxProfit();
        emit Deposit(msg.sender,msg.value,user.DepositTime,Users[msg.sender].length-1,(user.DepositTime+releaseTime));
        return true;

    }
    
    
    function PendingRewards(address _user,uint _index) public ValidBalance(msg.sender)  view returns(uint)
    {
        //ValidBalance(msg.sender) ValidIndex(_user,_index)
        // uint RewardAmount;
        uint accrewardpershare =AccRewardPershare;
        
        uint pending;
        UserBoxStruct storage user = Users[_user][_index];
       
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
    
    function withdraw(uint amount,uint _index) public ValidBalance(msg.sender) ValidIndex(msg.sender,_index) noReentrancy returns(bool success) 
    {
        //CalculateAccumulatePerShare();
        //UpdateRewardAmount();//Not-neccesary
        setMyPresentBalance(msg.sender,_index);
        UserBoxStruct storage user = Users[msg.sender][_index];
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
                user.ActualBalance -=amount;  
                // user.ActualBalance = user.ActualBalance - (amount);
                
                user.LossDept =(user.Balance*(AccLossPerShare))/(1e18);//doudth
                if(Users[msg.sender].length > 1)
                {   
                    Users[msg.sender][_index]=Users[msg.sender][Users[msg.sender].length-1];
                    // delete UserLockBoxNums[msg.sender][UserItemlength[msg.sender]-1];
                    // for (uint i = index; i < Users[msg.sender].length-1; i++) {
                    //     myArray[i] = myArray[i + 1];
                    // }
                    Users[msg.sender].pop();
                    UserItemlength[msg.sender] -=1;
                       
                }
                else if(Users[msg.sender].length == 1)
                {
                    Users[msg.sender].pop();
                    UserItemlength[msg.sender] -=1;
                }  
                // //st false for the box exist    
            }
            else
            {
                uint UserLostAmount =user.Balance-user.ActualBalance;
                TotalDepositedAmount -=(amount+UserLostAmount);
                user.Balance -=(amount + UserLostAmount);
                user.ActualBalance -=amount; 
                user.LossDept =(user.Balance*(AccLossPerShare))/(1e18);//doudth
           
            }
            
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
            setMaxProfit();  
            //Transfer( amount);
            //TotalDepositedAmount=TotalDepositedAmount-amount;
        }
        user.rewardDept = (user.Balance*(AccRewardPershare))/(1e18);//doudth
        emit Withdraw(msg.sender,amount,_index);
        return true;
         //user.LossDept =(user.Balance*(AccLossPerShare))/(1e18);//doudth
    } 

    
    function GetMypresentBalance(address _user,uint _index)public ValidBalance(_user) ValidIndex(_user,_index) view returns(uint actualamount)
    {
       UserBoxStruct storage user = Users[_user][_index];
       //require(user.Balance > 0,"The Balance is Low");
       actualamount = (user.Balance-((user.Balance*AccLossPerShare)/(1e18)))+(user.LossDept);
    }
    function setMyPresentBalance(address _user,uint _index)internal returns(uint){//Keep it internal
       UserBoxStruct storage user = Users[_user][_index];
       //require(user.Balance > 0,"The Balance is Low");
        user.ActualBalance = GetMypresentBalance(_user,_index);
        return user.ActualBalance;

    }
    
    function Getmybalance(address _user,uint _index)public ValidBalance(_user) ValidIndex(_user,_index) view returns(uint )
    {
        UserBoxStruct storage user = Users[_user][_index];
        return user.Balance;
    }
    fallback() external payable{
        
    }
    //Owner functions
    function Transfer(uint _amount)public noReentrancy IsGranted(msg.sender)  {
        require(_amount > 0,"The input amount is very less");
        require(_amount <= TotalValueLocked,"The amount is too high");
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
        setMaxProfit();
        emit transfer(msg.sender,_amount);
        
    }

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
            
        }
    } 
    //Extra
    function CalculateLossPerShare(uint _amount)internal
    {
        uint LossAmount = _amount;
        if(LossAmount > 0)
        {
            AccLossPerShare = AccLossPerShare+((LossAmount*1e18)/TotalDepositedAmount);
        }
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
    

    function setMaxProfit() internal {
        require(maxProfitAsPercentOfHouse > 0);
        maxProfit =
            (TotalValueLocked * maxProfitAsPercentOfHouse) / maxProfitDivisor;
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

    function getUserAmount()public view returns(uint)
    {
        return Users[msg.sender].length;
    }
    
}