//SourceUnit: 16079122562752_4048440491258161528.sol

pragma solidity >=0.5.4 <0.6.0;

contract TronExBank{
    using SafeMath for uint;
    
    uint constant public DEPOSIT_MIN_AMOUNT = 1000 trx;                     
    uint constant public DAY_DEPOSIT_MIN_LIMIT = 500000 trx;                    
    uint constant public CONTRACT_BALANCE_STEP = 1000000 trx;            
                  
    uint constant public __INTEREST_RATE_STEP = 10;                      
    uint constant public __MAX_BASE_INTEREST_RATE = 500;                 
    uint constant public __MAX_INTEREST_RATE = 1000;                     
                  
    uint constant public __MARKETING_FEE_RATE = 800;                     
    uint constant public __DEVOPS_FEE_RATE = 200;                        
    uint constant public __WITHDRAW_SERVICE_FEE_RATE = 200;              
                  
    uint[] public __UPLINE_BONUS = [
                                     500,200,100,
                                     50,50,
                                     30,30,30,30,30,30,30,30,30,30,
                                     100,100,100,100,100,100,100,100,100,100
                                   ];                                     
                  
    uint constant public __PER10000 = 10000;                              
    uint constant public DAY = 1 days;                                    
    uint constant public INTEREST_BEARING_PERIOD = DAY;                   
             
    DepositLimit internal depositLimit;
    
    uint public deposited;                                                
    uint public withdrawn;                                                
    uint public bonus;                                                    
    uint public depositorNumber;                                          
                                               
    address payable public marketingAddress;                              
    address payable public devopsAddress;                                 
    address payable public withdrawServiceAddress;                        
    
    mapping (address => Depositor) internal depositors;                   
    
    enum DepositType {
        MAJOR,  
        MINOR   
    }
    
    struct DepositLimit{
        uint today;                                                       
        uint todayLimit;                                                  
        uint currentLimit;                                                
        uint tomorrowLimit;                                               
    } 
     
    struct Deposit { 
        uint amount;                                                      
        uint maxInterest;                                                 
        uint withdrawn;                                                   
        uint lastWithdrawTime;                                            
        uint startTime;                                                   
        bool isClosed;                                                    
        DepositType depositType;                                          
    }   
    
    struct Depositor {
        Deposit[] deposits;                                           
        address upline;                                               
        uint downlineCount;                                           
        uint deposited;                                               
        uint withdrawn;                                               
        uint bonus;                                                   
        bool isUsed;                                                  
    }
    
    event Withdrawn(address indexed depositorAddress, uint amount);
    event NewDeposit(address indexed depositorAddress, uint amount);
    event MarketingAndDevOpsFeePayed(address indexed depositorAddress, uint marketingFee,uint devopsFee);
    event WithdrawServiceFeePayed(address indexed depositorAddress, uint amount);
    event BonusReceived(address indexed depositorAddress, address indexed uplineDepositorAddress, uint indexed level, uint amount);
    
    
    //------------------------------------------public functions--------------------------------------------------------------
    
    constructor(address payable marketingAddr, address payable devopsAddr, address payable withdrawServiceAddr) public{
        require(!isContract(marketingAddr) && !isContract(devopsAddr));
        marketingAddress = marketingAddr;
        devopsAddress = devopsAddr;
        withdrawServiceAddress = withdrawServiceAddr;
        depositLimit = DepositLimit(block.timestamp.div(DAY),DAY_DEPOSIT_MIN_LIMIT,DAY_DEPOSIT_MIN_LIMIT,DAY_DEPOSIT_MIN_LIMIT);
    }
    
    function deposit(address upline) public payable {
        
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        
        uint val = msg.value;
        require(val >= DEPOSIT_MIN_AMOUNT, "Minimum deposit amount 1000 TRX");
        
        updateDepositLimit();
        uint currentLimit = depositLimit.currentLimit;
        if(val > currentLimit){
            msg.sender.transfer(val.sub(currentLimit));
            val = currentLimit;
        }
        
        Depositor storage depositor = depositors[msg.sender];
        
        uint marketingFee = val.mul(__MARKETING_FEE_RATE).div(__PER10000);
        uint devopsFee = val.mul(__DEVOPS_FEE_RATE).div(__PER10000);
        marketingAddress.transfer(marketingFee);
        devopsAddress.transfer(devopsFee);
        
        emit MarketingAndDevOpsFeePayed(msg.sender,marketingFee,devopsFee);
        
        Depositor storage upl = depositors[upline];
        if (upline != msg.sender && depositor.upline == address(0) && upl.isUsed) {
            depositor.upline = upline;
            upl.downlineCount = upl.downlineCount.add(1);
        }
        
        address u = depositor.upline;
        uint uplineTotal;
        for(uint i = 0 ; i < 25 ; i++){
            if(u==address(0))break;
            Depositor storage uplineDepositor = depositors[u];
            uint bonusLevel = i+1;
            if(shouldTransferBonus(u,bonusLevel)){
                uint amount = val.mul(__UPLINE_BONUS[i]).div(__PER10000);
                address(uint160(u)).transfer(amount);
                uplineDepositor.bonus = uint(uint(uplineDepositor.bonus).add(amount));
                uplineTotal = uplineTotal.add(amount);
                emit BonusReceived(msg.sender,u,bonusLevel,amount);
            }
            u = uplineDepositor.upline;
        }
        
        if(!depositor.isUsed){
            depositor.isUsed = true;
            depositorNumber++;
        }
        
        depositor.deposits.push(Deposit(val,val.mul(210).div(100),0,0,now,false,DepositType.MAJOR));
        depositor.deposited += val;
        
        deposited = deposited.add(val);
        bonus = bonus.add(uplineTotal);
        depositLimit.currentLimit = depositLimit.currentLimit.sub(val);
        
        emit NewDeposit(msg.sender,val);
    }
    
    function withdraw() public{
        
        Depositor storage depositor = depositors[msg.sender];
        require(depositor.isUsed,"Depositor identity requires");
        
        uint deadline = now;
        uint __contract_balance_interest_rate = getContractBalanceInterestRate();
        uint interest = calculateInterest(msg.sender,deadline);
        
        require(interest > 0, "No interest to withdraw");
        uint ctrBal = address(this).balance;
        if(ctrBal < 2000000 trx)require(depositor.withdrawn.mul(2) < depositor.deposited , "Withdraw limit happens when your accumulative total withdraw has been more than 50% of your deposit and the contract balance is less than 2000000 trx.");
        require(interest < ctrBal ,"Contract balance is not enough to pay the withdraw value.");
        
        Deposit[] storage deposits = depositor.deposits;
        for(uint i = 0 ; i < deposits.length ; i++){
            if(!deposits[i].isClosed){
                Deposit storage dp = deposits[i];
                
                uint __base_interest_rate = calculateBaseInterestRate(dp,deadline);
                uint currentInterest = calculateDepositInterest(dp,__base_interest_rate,__contract_balance_interest_rate);
                
                uint interestWithdrawn = currentInterest.add(dp.withdrawn);
                if(interestWithdrawn >= dp.maxInterest) {
                        dp.withdrawn = dp.maxInterest;
                        dp.isClosed = true;
                }else{
                        dp.withdrawn = interestWithdrawn;
                }
                dp.lastWithdrawTime = deadline;
            }
        }
        uint minorDepositAmount = interest.mul(30).div(100);
        if(minorDepositAmount > DEPOSIT_MIN_AMOUNT){
            depositor.deposits.push(Deposit(minorDepositAmount,minorDepositAmount.mul(210).div(100),0,0,deadline,false,DepositType.MINOR));
            interest = interest.sub(minorDepositAmount);
        }
        if(interest >= 10 trx){
            uint withdrawServiceFee = interest.mul(__WITHDRAW_SERVICE_FEE_RATE).div(__PER10000);
            if(withdrawServiceFee < 3 trx) withdrawServiceFee = 3 trx;
        
            withdrawServiceAddress.transfer(withdrawServiceFee);
            msg.sender.transfer(interest.sub(withdrawServiceFee));
            
            emit WithdrawServiceFeePayed(msg.sender,withdrawServiceFee);
        }else{
            msg.sender.transfer(interest);
        }
        withdrawn = withdrawn.add(interest);
        depositor.withdrawn = depositor.withdrawn.add(interest);
        
        emit Withdrawn(msg.sender, interest);
    }
     
    function getContractBalanceInterestRate() public view returns (uint){
        return address(this).balance.div(CONTRACT_BALANCE_STEP).mul(__INTEREST_RATE_STEP); //由每百万合约余额计算出来的利率万分点
    }
    
    function getInterest() public view returns (uint){
       require(depositors[msg.sender].isUsed,"Depositor identity requires");    
       return calculateInterest(msg.sender,now);
    }
    
    function getDepositInterestByIndex(uint index) public view returns (uint,uint,uint,uint){
       require(depositors[msg.sender].isUsed,"Depositor identity requires");
       Deposit[] memory deposits = depositors[msg.sender].deposits;
       require(index < deposits.length,"deposit with this index is no found.");
       Deposit memory dp = depositors[msg.sender].deposits[index];
       
       uint __base_interest_rate = calculateBaseInterestRate(dp,now);
       if(dp.isClosed)return (0,0,__base_interest_rate,0);
       uint __contract_balance_interest_rate = getContractBalanceInterestRate();
       uint __interest_rate = calculateDepositInterestRate(dp.depositType,__base_interest_rate,__contract_balance_interest_rate);
       uint interest = calculateDepositInterest(dp,__interest_rate);
       return (interest , __base_interest_rate , __contract_balance_interest_rate , __interest_rate);
    }
        
    function depositorStatistics() public view returns (uint,uint,address,uint,uint,uint,uint){
        return depositorStatisticsByDepositorAddress(msg.sender);
    }
       
    function depositorStatisticsByDepositorAddress(address depositorAddress ) public view returns (uint,uint,address,uint,uint,uint,uint){
        Depositor storage depositor = depositors[depositorAddress];
        return (calculateInterest(depositorAddress,now) , depositor.deposits.length , depositor.upline , depositor.downlineCount , depositor.deposited , depositor.withdrawn , depositor.bonus);
    }
   
    function getDepositByIndex(uint index) public view returns (uint,uint,uint,uint,uint,uint,bool,DepositType){
        return getDepositByDepositorAddressAndIndex(msg.sender,index);
    }
    
    function getDepositByDepositorAddressAndIndex(address depositorAddress ,uint index) public view returns (uint,uint,uint,uint,uint,uint,bool,DepositType){
        Depositor storage depositor = depositors[depositorAddress];
        require(depositor.deposits.length>0,"No deposit found.");
        Deposit[] storage deposits = depositor.deposits;
        uint last = deposits.length-1;
        if(index>last)index=last;
        Deposit storage dp = deposits[index];
        return (index , dp.amount , dp.maxInterest , dp.withdrawn , dp.lastWithdrawTime , dp.startTime , dp.isClosed , dp.depositType);
    }
    
    function shouldTransferBonus(address upline,uint bonusLevel) public view returns (bool){
        Depositor storage upl = depositors[upline];
        Deposit[] storage deposits = upl.deposits;
        return !deposits[deposits.length-1].isClosed && upl.bonus < upl.deposited.mul(3) && upl.downlineCount >= bonusLevel;
    }
    
    function isActive(address depositorAddress) public view returns (bool) {
        Deposit[] storage deposits = depositors[depositorAddress].deposits;
        Deposit storage dp = deposits[deposits.length-1];
        return !dp.isClosed;
    }
    
    function getCurrentDepositLimit() public view returns (uint){
        uint day =now.div(DAY);
        if(day>depositLimit.today){
            return depositLimit.tomorrowLimit;
        }
        return depositLimit.currentLimit;
    }
    
    function getDepositLimit() public view returns (uint,uint){
        uint currentLimit = getCurrentDepositLimit();
        uint tomorrowLimitExpected ;
        if(currentLimit > depositLimit.todayLimit){
            tomorrowLimitExpected = currentLimit;
        }else{
            tomorrowLimitExpected = depositLimit.todayLimit;
        }
        tomorrowLimitExpected = tomorrowLimitExpected.mul(110).div(100);
        if(tomorrowLimitExpected < DAY_DEPOSIT_MIN_LIMIT)tomorrowLimitExpected = DAY_DEPOSIT_MIN_LIMIT;
        return (currentLimit,tomorrowLimitExpected);
    }
    
    function getContractBalance() public view returns (uint){
        return address(this).balance;
    }
    
    function getGeneralStatistics()public view returns (uint,uint,uint,uint,uint,uint,uint){
        return (getCurrentDepositLimit() , getContractBalanceInterestRate() , getContractBalance() , deposited , withdrawn , bonus, depositorNumber);
    }
    
    //------------------------------------------internel functions--------------------------------------------------------------
    
    function updateDepositLimit() internal{
        uint day =now.div(DAY);
        if(day>depositLimit.today){
            
            depositLimit.today = day;
            //新一天的可储蓄限额为前一天实际储蓄数额的110%且在DAY_DEPOSIT_MAX_LIMIT和DAY_DEPOSIT_MAX_LIMIT之间
            uint tomorrowLimit = depositLimit.todayLimit.sub(depositLimit.currentLimit).mul(110).div(100);
            if(tomorrowLimit<DAY_DEPOSIT_MIN_LIMIT) tomorrowLimit = DAY_DEPOSIT_MIN_LIMIT;
            // if(tomorrowLimit>DAY_DEPOSIT_MAX_LIMIT) tomorrowLimit = DAY_DEPOSIT_MAX_LIMIT;
            
            depositLimit.todayLimit = depositLimit.tomorrowLimit;
            depositLimit.currentLimit = depositLimit.todayLimit;
            depositLimit.tomorrowLimit = tomorrowLimit;
        } 
    }
    
    function calculateInterest(address depositorAddress,uint deadline) internal view returns (uint){
        
        Depositor storage depositor = depositors[depositorAddress];
        uint interest;
        
        uint __contract_balance_interest_rate = getContractBalanceInterestRate();
        
        Deposit[] storage deposits = depositor.deposits;
        for(uint i = 0 ; i < deposits.length ; i++){
            if(!deposits[i].isClosed){
                Deposit storage dp = deposits[i];
                //
                uint __base_interest_rate = calculateBaseInterestRate(dp,deadline);
                if(__base_interest_rate!=0){
                   uint currentInterest = calculateDepositInterest(dp,__base_interest_rate,__contract_balance_interest_rate);
                   interest = interest.add(currentInterest); //累加利息
                }
            }
        } 
        return interest;
    }
    
    function calculateDepositInterest(Deposit memory dp, uint __interest_rate)  internal pure returns (uint){
        uint currentInterest;
        if(dp.withdrawn>=dp.amount){
            currentInterest = dp.amount.mul(__interest_rate.div(2)).div(__PER10000);
        }else{
            currentInterest = dp.amount.mul(__interest_rate).div(__PER10000);
            uint sum = currentInterest.add(dp.withdrawn);
            if(sum >  dp.amount){
                uint part1 = dp.amount.sub(dp.withdrawn);
                uint part2 = sum.sub(dp.amount).div(2);
                currentInterest = part1.add(part2).div(__PER10000);
            }
        }
        uint maxIncrement = dp.maxInterest.sub(dp.withdrawn);
        if(currentInterest > maxIncrement) currentInterest = maxIncrement;
        return currentInterest;
    }
    
    function calculateDepositInterest(Deposit memory dp,uint __base_interest_rate, uint __contract_balance_interest_rate) internal pure returns (uint){
        return calculateDepositInterest(dp,calculateDepositInterestRate(dp.depositType,__base_interest_rate,__contract_balance_interest_rate));
    }
    
    function calculateDepositInterestRate(DepositType t,uint __base_interest_rate, uint __contract_balance_interest_rate) internal pure returns (uint){
        if(__base_interest_rate==0)return 0;
        
        uint __interest_rate = __base_interest_rate.add(__contract_balance_interest_rate);
        if(__interest_rate > __MAX_INTEREST_RATE) __interest_rate = __MAX_INTEREST_RATE;
        if(t==DepositType.MINOR) return __interest_rate.div(2);
        return __interest_rate;
        
    }
    
    function calculateBaseInterestRate(Deposit memory dp,uint deadline) internal pure returns (uint){
        uint __base_interest_rate; //基础利率万分点
        uint start = dp.lastWithdrawTime;
        if(start==0){
            start = dp.startTime;
        }
        uint peroids = deadline.sub(start).div(INTEREST_BEARING_PERIOD);
        __base_interest_rate = peroids > 0 ? peroids.sub(1).mul(__INTEREST_RATE_STEP).add(100) : 0;
        
        if(__base_interest_rate > __MAX_BASE_INTEREST_RATE) __base_interest_rate = __MAX_BASE_INTEREST_RATE;
        return __base_interest_rate;
    }
    
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}