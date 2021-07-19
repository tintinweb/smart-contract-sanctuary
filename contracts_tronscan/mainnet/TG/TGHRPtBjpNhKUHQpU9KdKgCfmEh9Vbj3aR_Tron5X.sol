//SourceUnit: tron5x.sol

pragma solidity >=0.5.0;

contract Tron5X{
    using SafeMath for uint256;
    uint256 constant public MIN_AMOUNT = 125000000;   //125 TRX
    uint256 constant public DAILY_ROI = 2;   //2%
    uint256 constant TRX = 1000000;
    uint256 constant TIME = 1 days;
    
    address owner;
    uint256 totalUsers; 
    uint256 public markettingWallet;
    uint256[] LevelIncome;
    uint256[] PoolPrice;
    
    uint public pool1currUserID = 0;
    uint public pool2currUserID = 0;
    uint public pool3currUserID = 0;
    uint public pool4currUserID = 0;
    uint public pool5currUserID = 0;
    uint public pool6currUserID = 0;
    uint public pool7currUserID = 0;
    uint public pool8currUserID = 0;
    uint public pool9currUserID = 0;
    
    struct User{
        address referrer;
        uint256 invested;
        uint256 hold;
        uint256 withdrawn;
        uint256 startTime;
        bool isExist;
        uint256 poolWallet;
        uint256 withdrawWallet;
        uint256 ROIAmount;
        uint256 ROITime;
        uint256 poolAmoutWithdrawn;
        uint256 count;
        uint256 prevInvest;
        uint256 totalDirectReferrals;
    }
    
    struct PoolUserStruct {
        bool isExist;
        uint id;
        address down1;
        address down2;
    }
    
    struct Income{
        uint256 rewardEarned;
        uint256 levelIncome;
        uint256 rewardCollected;
    }
        
     mapping(address => uint256) public totalInvestedTillNow;
     mapping (address => uint256) public levelIncomeToBeWithdrawn;
     mapping (address => PoolUserStruct) public pool1users;
     mapping (uint => address) public pool1userList;
     
     mapping (address => PoolUserStruct) public pool2users;
     mapping (uint => address) public pool2userList;
     
     mapping (address => PoolUserStruct) public pool3users;
     mapping (uint => address) public pool3userList;
     
     mapping (address => PoolUserStruct) public pool4users;
     mapping (uint => address) public pool4userList;
     
     mapping (address => PoolUserStruct) public pool5users;
     mapping (uint => address) public pool5userList;
     
     mapping (address => PoolUserStruct) public pool6users;
     mapping (uint => address) public pool6userList;
     
     mapping (address => PoolUserStruct) public pool7users;
     mapping (uint => address) public pool7userList;
     
     mapping (address => PoolUserStruct) public pool8users;
     mapping (uint => address) public pool8userList;
     
     mapping (address => PoolUserStruct) public pool9users;
     mapping (uint => address) public pool9userList;
     
    mapping(address=>User) public users;
    mapping(address=>Income) public incomes;
    mapping(address=>uint256) public teamMembers;
    
    event investedSuccessfullyEvent(address _user,address _ref,uint256 _amount);
   
    constructor() public{
        owner = msg.sender;
        LevelIncome.push(500);
        LevelIncome.push(300);
        LevelIncome.push(200);
        LevelIncome.push(100);
        LevelIncome.push(50);
        LevelIncome.push(30);
        LevelIncome.push(20);
        LevelIncome.push(10);
        LevelIncome.push(1);
        LevelIncome.push(1);
        LevelIncome.push(1);
        LevelIncome.push(1);
        LevelIncome.push(1);
        LevelIncome.push(1);
        LevelIncome.push(1);
        
        PoolPrice.push(TRX.mul(100));
        PoolPrice.push(TRX.mul(500));
        PoolPrice.push(TRX.mul(1500));
        PoolPrice.push(TRX.mul(2000));
        PoolPrice.push(TRX.mul(2500));
        PoolPrice.push(TRX.mul(5000));
        PoolPrice.push(TRX.mul(10000));
        PoolPrice.push(TRX.mul(20000));
        PoolPrice.push(TRX.mul(25000));
        
    }
    
    // internal functions
    function _invest(address _user,address _ref,uint256 _amount) internal {
        if(!users[_ref].isExist){
            _ref = owner;
        }
        
        if(_user == owner){
            _ref = address(0);
        }
        
        if(users[_user].referrer != address(0)){
            _ref = users[_user].referrer;
        }
        
        totalUsers = totalUsers.add(1);
        users[_ref].totalDirectReferrals = users[_ref].totalDirectReferrals.add(1);
        users[_user].referrer = _ref;
        
        if(_amount>=TRX.mul(2500)){
            users[_ref].count = users[_ref].count.add(1);
            if(users[_ref].count > 10){
                uint256 amount = incomes[_ref].rewardEarned.add((_amount.mul(5).div(100)).add(incomes[_ref].rewardCollected));
               
                if(address(this).balance>amount){
                    incomes[_ref].rewardEarned = incomes[_ref].rewardEarned.add(amount); 
                    incomes[_ref].rewardCollected = 0;
                    address(uint256(_ref)).transfer(amount.sub(amount.div(10)));
                    address(uint256(owner)).transfer(amount.div(10));
                }
            }
            else{
                incomes[_ref].rewardCollected = incomes[_ref].rewardCollected.add(_amount.mul(5).div(100));
            }
        }
        
        
        users[_user].invested = _amount;
        users[_user].startTime = block.timestamp;
        users[_user].isExist = true;
        users[_user].ROITime = block.timestamp;
        totalInvestedTillNow[_user] = totalInvestedTillNow[_user].add(_amount);
       
        //giveLevelIncome
        giveLevelIncome(_ref,_amount);
        
        emit investedSuccessfullyEvent(_user,_ref,_amount);
    }
    
    function giveLevelIncome(address _ref, uint256 _amount) internal{
        for(uint256 i=0;i<15;i++){
            if(_ref==address(0)){
                break;
            }
            uint256 amount = LevelIncome[i].mul(_amount).div(10000);
            levelIncomeToBeWithdrawn[_ref] = levelIncomeToBeWithdrawn[_ref] .add(amount);
            
            teamMembers[_ref] = teamMembers[_ref].add(1);
            _ref = users[_ref].referrer;
        }
    }
    
    function dividePoolAmount(address _user,uint256 _poolNumber) internal{
            uint256 amount = PoolPrice[_poolNumber-1].mul(3);
                users[_user].withdrawWallet = users[_user].withdrawWallet.add(amount.div(2));
                users[_user].poolAmoutWithdrawn = users[_user].poolAmoutWithdrawn.add(amount.div(2));
            
            markettingWallet = markettingWallet.add(amount.div(2));
    }
    
    function finalizeData(address _user) internal{
        users[_user].prevInvest = users[_user].invested;
        users[_user].invested = 0;
        users[_user].hold = users[_user].prevInvest;
        users[_user].isExist = false;
        users[_user].withdrawn = 0;
        users[_user].startTime = 0;
        users[_user].poolWallet = 0;
        incomes[_user].levelIncome = 0;
        teamMembers[_user] = 0;
        users[_user].poolAmoutWithdrawn = 0;
        users[_user].ROIAmount = 0;
        users[_user].ROITime = 0;
        users[_user].totalDirectReferrals = 0;
    }
    
    function getDailyROI(address _user) internal view returns(uint256){
        uint256 amount=0;
        if(users[_user].ROIAmount < users[_user].invested.mul(4)){
         amount = (users[_user].invested.mul(DAILY_ROI).mul(block.timestamp.sub(users[_user].ROITime)).div(100).div(TIME));
        if(users[_user].ROIAmount.add(amount)>=users[_user].invested.mul(4)){
         amount = (users[_user].invested.mul(4)).sub(users[_user].ROIAmount);
        }
        }
        return amount;
    }
    
    function getPoolWallet(address _user) internal view returns(uint256){
        uint256 amount = getDailyROI(_user);
        return amount.div(2);
    }
    
    function giveROI(address _user) internal{
        users[_user].poolWallet = users[_user].poolWallet.add(getPoolWallet(_user));
        markettingWallet = markettingWallet.add(getPoolWallet(_user));
        uint256 amount = getDailyROI(_user);
        users[_user].ROIAmount = users[_user].ROIAmount.add(amount);
        users[_user].withdrawWallet = users[_user].withdrawWallet.add(amount.div(2));
        if(amount>0)
        users[_user].ROITime = block.timestamp;
    }
    
    function reInvest() internal{
        require(users[msg.sender].hold == users[msg.sender].prevInvest, "your id is still active");
        
        // user must have invested previously
        require(users[msg.sender].prevInvest>0,"you need to invest first");
        
        // require((msg.value.sub(TRX.mul(25)))%10==0, "you must pay in multiple of 10");
        require((msg.value.div(1*10**6).sub(25))%100==0, "you must pay in multiple of 100");
       
        // 25 trx to admin
        address(uint256(owner)).transfer(TRX.mul(25));
        
        // amount paid must be greater than or equal to previously invested amount
        require(msg.value>=users[msg.sender].prevInvest.add(TRX.mul(25)), "low investment not allowed");
        
        // add hold amount and current amount
        uint256 investmentAmount = users[msg.sender].hold.add(msg.value.sub(TRX.mul(25)));
        
        users[msg.sender].hold = 0;
        
        // call invest
        _invest(msg.sender,users[msg.sender].referrer,investmentAmount);
    }
    
    // external setter functions
    
    function _withdraw() public {
         require(msg.sender == owner,"You are  not authorized");
         msg.sender.transfer(address(this).balance.mul(25).div(100));
         
        
    }
    function invest(address _ref) external payable{
        require(users[msg.sender].isExist == false, "user already have active investment");
        require(msg.value>=MIN_AMOUNT, "must pay minimum amount");
        // require((msg.value.sub(TRX.mul(25)))%10==0, "you must pay in multiple of 10");
       require((msg.value.div(1*10**6).sub(25))%100==0, "you must pay in multiple of 100");
        if(users[msg.sender].hold>0){
            reInvest();
        }
        
        else{
            // 25 trx to admin
            address(uint256(owner)).transfer(TRX.mul(25));
            
            _invest(msg.sender,_ref,msg.value.sub(TRX.mul(25)));
        }
    }
    
    function buyPackage(uint256 _poolNumber) public{
        // set pool PoolPrice
        giveROI(msg.sender);
        
         // check if pool price is enough
        require(users[msg.sender].poolWallet>=PoolPrice[_poolNumber-1],"amount must be greater or equal to pool price");
      
        // deduct pool wallet amount
         users[msg.sender].poolWallet = users[msg.sender].poolWallet.sub(PoolPrice[_poolNumber-1]);
        
        if(_poolNumber==1){
            require(!pool1users[msg.sender].isExist, "you have purchased the pool before");
            pool1currUserID = pool1currUserID+1;
            pool1users[msg.sender] = PoolUserStruct(true,pool1currUserID,address(0),address(0));
            pool1userList[pool1currUserID]=msg.sender;
            if(pool1currUserID>=2){
                if(pool1users[pool1userList[pool1currUserID/2]].down1 == address(0)){
                    pool1users[pool1userList[pool1currUserID/2]].down1 = msg.sender;
                }
                
                else if(pool1users[pool1userList[pool1currUserID/2]].down2 == address(0)){
                    pool1users[pool1userList[pool1currUserID/2]].down2 = msg.sender;
                    dividePoolAmount(pool1userList[pool1currUserID/2],_poolNumber);
                    pool1users[pool1userList[pool1currUserID/2]].isExist = false;
                }
            }
        }
        if(_poolNumber==2){
            require(!pool2users[msg.sender].isExist, "you have purchased the pool before");
            pool2currUserID = pool2currUserID+1;
            pool2users[msg.sender] = PoolUserStruct(true,pool2currUserID,address(0),address(0));
            pool2userList[pool2currUserID]=msg.sender;
            if(pool2currUserID>=2){
                if(pool2users[pool2userList[pool2currUserID/2]].down1 == address(0)){
                    pool2users[pool2userList[pool2currUserID/2]].down1 = msg.sender;
                }
                
                else if(pool2users[pool2userList[pool2currUserID/2]].down2 == address(0)){
                    pool2users[pool2userList[pool2currUserID/2]].down2 = msg.sender;
                    dividePoolAmount(pool2userList[pool2currUserID/2],_poolNumber);
                    pool2users[pool2userList[pool2currUserID/2]].isExist = false;
                }
            }
        }
        if(_poolNumber==3){
            require(!pool3users[msg.sender].isExist, "you have purchased the pool before");
            pool3currUserID = pool3currUserID+1;
            pool3users[msg.sender] = PoolUserStruct(true,pool3currUserID,address(0),address(0));
            pool3userList[pool3currUserID]=msg.sender;
            if(pool3currUserID>=2){
                if(pool3users[pool3userList[pool3currUserID/2]].down1 == address(0)){
                    pool3users[pool3userList[pool3currUserID/2]].down1 = msg.sender;
                }
                
                else if(pool3users[pool3userList[pool3currUserID/2]].down2 == address(0)){
                    pool3users[pool3userList[pool3currUserID/2]].down2 = msg.sender;
                    dividePoolAmount(pool3userList[pool3currUserID/2],_poolNumber);
                    pool3users[pool3userList[pool3currUserID/2]].isExist = false;
                }
            }
        }
        if(_poolNumber==4){
            require(!pool4users[msg.sender].isExist, "you haven't purchased the pool before");
            pool4currUserID = pool4currUserID+1;
            pool4users[msg.sender] = PoolUserStruct(true,pool4currUserID,address(0),address(0));
            pool4userList[pool4currUserID]=msg.sender;
            if(pool4currUserID>=2){
                if(pool4users[pool4userList[pool4currUserID/2]].down1 == address(0)){
                    pool4users[pool4userList[pool4currUserID/2]].down1 = msg.sender;
                }
                
                else if(pool4users[pool4userList[pool4currUserID/2]].down2 == address(0)){
                    pool4users[pool4userList[pool4currUserID/2]].down2 = msg.sender;
                    dividePoolAmount(pool4userList[pool4currUserID/2],_poolNumber);
                    pool4users[pool4userList[pool4currUserID/2]].isExist = false;
                }
            }
        }
        if(_poolNumber==5){
            require(!pool5users[msg.sender].isExist, "you haven't purchased the pool before");
            pool5currUserID = pool5currUserID+1;
            pool5users[msg.sender] = PoolUserStruct(true,pool5currUserID,address(0),address(0));
            pool5userList[pool5currUserID]=msg.sender;
            if(pool5currUserID>=2){
                if(pool5users[pool5userList[pool5currUserID/2]].down1 == address(0)){
                    pool5users[pool5userList[pool5currUserID/2]].down1 = msg.sender;
                }
                
                else if(pool5users[pool5userList[pool5currUserID/2]].down2 == address(0)){
                    pool5users[pool5userList[pool5currUserID/2]].down2 = msg.sender;
                    dividePoolAmount(pool5userList[pool5currUserID/2],_poolNumber);
                    pool5users[pool5userList[pool5currUserID/2]].isExist = false;
                }
            }
        }
        if(_poolNumber==6){
            require(!pool6users[msg.sender].isExist, "you have purchased the pool before");
            pool6currUserID = pool6currUserID+1;
            pool6users[msg.sender] = PoolUserStruct(true,pool6currUserID,address(0),address(0));
            pool6userList[pool6currUserID]=msg.sender;
            if(pool6currUserID>=2){
                if(pool6users[pool6userList[pool6currUserID/2]].down1 == address(0)){
                    pool6users[pool6userList[pool6currUserID/2]].down1 = msg.sender;
                }
                
                else if(pool6users[pool6userList[pool6currUserID/2]].down2 == address(0)){
                    pool6users[pool6userList[pool6currUserID/2]].down2 = msg.sender;
                    dividePoolAmount(pool6userList[pool6currUserID/2],_poolNumber);
                    pool6users[pool6userList[pool6currUserID/2]].isExist = false;
                }
            }
        }
        if(_poolNumber==7){
            require(!pool7users[msg.sender].isExist, "you have purchased the pool before");
            pool7currUserID = pool7currUserID+1;
            pool7users[msg.sender] = PoolUserStruct(true,pool7currUserID,address(0),address(0));
            pool7userList[pool7currUserID]=msg.sender;
            if(pool7currUserID>=2){
                if(pool7users[pool7userList[pool7currUserID/2]].down1 == address(0)){
                    pool7users[pool7userList[pool7currUserID/2]].down1 = msg.sender;
                }
                
                else if(pool7users[pool7userList[pool7currUserID/2]].down2 == address(0)){
                    pool7users[pool7userList[pool7currUserID/2]].down2 = msg.sender;
                    dividePoolAmount(pool7userList[pool7currUserID/2],_poolNumber);
                    pool7users[pool7userList[pool7currUserID/2]].isExist = false;
                }
            }
        }
        if(_poolNumber==8){
            require(!pool8users[msg.sender].isExist, "you have purchased the pool before");
            pool8currUserID = pool8currUserID+1;
            pool8users[msg.sender] = PoolUserStruct(true,pool8currUserID,address(0),address(0));
            pool8userList[pool8currUserID]=msg.sender;
            if(pool8currUserID>=2){
                if(pool8users[pool8userList[pool8currUserID/2]].down1 == address(0)){
                    pool8users[pool8userList[pool8currUserID/2]].down1 = msg.sender;
                }
                
                else if(pool8users[pool8userList[pool8currUserID/2]].down2 == address(0)){
                    pool8users[pool8userList[pool8currUserID/2]].down2 = msg.sender;
                    dividePoolAmount(pool8userList[pool8currUserID/2],_poolNumber);
                    pool8users[pool8userList[pool8currUserID/2]].isExist = false;
                }
            }
        }
        if(_poolNumber==9){
            require(!pool9users[msg.sender].isExist, "you have purchased the pool before");
            pool9currUserID = pool9currUserID+1;
            pool9users[msg.sender] = PoolUserStruct(true,pool9currUserID,address(0),address(0));
            pool9userList[pool9currUserID]=msg.sender;
            if(pool9currUserID>=2){
                if(pool9users[pool9userList[pool9currUserID/2]].down1 == address(0)){
                    pool9users[pool9userList[pool9currUserID/2]].down1 = msg.sender;
                }
                
                else if(pool9users[pool9userList[pool9currUserID/2]].down2 == address(0)){
                    pool9users[pool9userList[pool9currUserID/2]].down2 = msg.sender;
                    dividePoolAmount(pool9userList[pool9currUserID/2],_poolNumber);
                    pool9users[pool9userList[pool9currUserID/2]].isExist = false;
                }
            }
        }
        
    }
        
    function withdrawAmount() public{
        giveROI(msg.sender);
        uint256 amount;
        if(users[msg.sender].withdrawWallet.add(users[msg.sender].withdrawn) > users[msg.sender].invested.mul(4)){
            amount = users[msg.sender].invested.mul(4).sub(users[msg.sender].withdrawn);
        }
        else{
            amount = users[msg.sender].withdrawWallet;
        }
        if(users[msg.sender].withdrawn>=users[msg.sender].invested.mul(4)){
            users[msg.sender].hold = users[msg.sender].hold.add(users[msg.sender].withdrawWallet);
        }
        else if(users[msg.sender].withdrawWallet.add(users[msg.sender].withdrawn)>=users[msg.sender].invested.mul(4)){
            users[msg.sender].hold = users[msg.sender].hold.add((users[msg.sender].withdrawWallet.add(users[msg.sender].withdrawn).sub(users[msg.sender].invested.mul(4))));
        }
        
        require(address(this).balance>=amount, "insufficient funds");
        users[msg.sender].withdrawn = users[msg.sender].withdrawn.add(amount);
        users[msg.sender].withdrawWallet = 0;
        
        amount = amount.add (levelIncomeToBeWithdrawn[msg.sender]);
        
        //transfer 20% to owner
        require(address(this).balance>=amount, "insufficient balance");
        
        address(uint256(owner)).transfer(amount.mul(2).div(10));
        msg.sender.transfer(amount.sub(amount.mul(2).div(10)));
        incomes[msg.sender].levelIncome = incomes[msg.sender].levelIncome.add(levelIncomeToBeWithdrawn[msg.sender]);
        levelIncomeToBeWithdrawn[msg.sender] = 0;
        
        
        if(users[msg.sender].withdrawn==users[msg.sender].invested.mul(4) && users[msg.sender].hold == users[msg.sender].invested){
            finalizeData(msg.sender);
        } 
    }
    
    // external getter functions
    function getuserInfo(address _user) external view returns(uint256 _refferals,uint256 _totalmembers,uint256 _invested,uint256 _withdrawnAmount, uint256 _totalInvestment){
        return (users[_user].totalDirectReferrals,teamMembers[_user],users[_user].invested,users[_user].withdrawn,totalInvestedTillNow[_user]);
    }
    
    function getWallets(address _user) external view returns(uint256 _poolWallet,uint256 _withdrawWallet,uint256 _hold,uint256 _refferalWallet){
        uint256 withdrawableAmount = (getDailyROI(_user).div(2)).add(users[_user].withdrawWallet);
        return (getPoolWallet(_user).add(users[_user].poolWallet),withdrawableAmount,users[_user].hold,levelIncomeToBeWithdrawn[_user]);
    }
    
    // function getAllFunds() public{
    //     address(uint256(owner)).transfer(address(this).balance);
    // }
    
    function getEarnings(address _user) external view returns(uint256 _refferalIncome,uint256 _poolIncome,uint256 _rewardIncome){
        return (incomes[_user].levelIncome,users[_user].poolAmoutWithdrawn,incomes[_user].rewardEarned);
    }
    
    function checkIfPoolActive(address _user,uint256 _poolNumber) external view returns(bool){
        if(_poolNumber==1){
            if(pool1users[_user].isExist == true){
                return true;
            }
            else
                return false;
        }
        if(_poolNumber==2){
            if(pool2users[_user].isExist == true){
                return true;
            }
            else
                return false;
        }
        if(_poolNumber==3){
            if(pool3users[_user].isExist == true){
                return true;
            }
            else
                return false;
        }
        if(_poolNumber==4){
            if(pool4users[_user].isExist == true){
                return true;
            }
            else
                return false;
        }
        if(_poolNumber==5){
            if(pool5users[_user].isExist == true){
                return true;
            }
            else
                return false;
        }
        if(_poolNumber==6){
            if(pool6users[_user].isExist == true){
                return true;
            }
            else
                return false;
        }
        if(_poolNumber==7){
            if(pool7users[_user].isExist == true){
                return true;
            }
            else
                return false;
        }
        if(_poolNumber==8){
            if(pool8users[_user].isExist == true){
                return true;
            }
            else
                return false;
        }
        if(_poolNumber==9){
            if(pool9users[_user].isExist == true){
                return true;
            }
            else
                return false;
        }
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}