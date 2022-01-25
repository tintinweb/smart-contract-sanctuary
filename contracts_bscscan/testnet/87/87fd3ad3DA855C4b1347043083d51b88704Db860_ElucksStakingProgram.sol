/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

// owner 0x2dBEA1e49B10Bb97c15c3f8AFCb853F3151830D6
// busd  0x4851fbaed7efcc3c19c2f922adf10d71f508f9e4
// elucks   0x79833FaE930B90FC2B5CF0Eaba7b3787153e007d

//  Elucks

pragma solidity 0.5.4;

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender)
  external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)
  external returns (bool);
  
  function transferFrom(address from, address to, uint256 value)
  external returns (bool);
  function burn(uint256 value)
  external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);
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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract ElucksStakingProgram  {
     using SafeMath for uint256;
     
    struct Staking {
        uint256 programId;
        uint256 stakingDate;
        uint256 staking;
        uint256 lastWithdrawalDate;
        uint256 currentRewards;
        bool    isExpired;
        uint256 genRewards;
        uint256 stakingToken;
        bool    isAddedStaked;
    }

    struct Program {
        uint256 dailyInterest;
        uint256 term; //0 means unlimited
        uint256 maxDailyInterest;
    }
  
     
    struct User {
        uint id;
        address referrer;
        uint256 referralReward;
        uint256 selfBuy;
uint256 selfSell;
        uint256 programCount;
        uint256 totalStakingBusd;
        uint256 totalStakingToken;
        uint256 currentPercent;
        uint256 compoundReward;
        uint256 freeStakedToken;
        uint256 airdropReward;
        mapping(uint256 => Staking) programs;
        mapping(uint256 => uint256) refStake;
        mapping(uint256 => uint256) refUser;
    }
    
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(address => uint8) public position;
    mapping(address => bool) public isStop;
    Program[] private stakingPrograms_;
    
    uint256 private constant INTEREST_CYCLE = 1 days;

    uint public lastUserId = 2;
    uint256 public tokenPrice=30*1e16;
    uint256  priceIncPercent=230;
    uint256  priceDecPercent=230;
    bool public isAdminOpen;
    
    uint256 public  total_staking_token = 0;
    uint256 public  total_staking_busd = 0;
    uint256 public  total_virtual_staking = 0;
    
    uint256 public  total_withdraw_token = 0;
    uint256 public  total_withdraw_busd = 0;
    uint256 public  total_virtual_withdraw = 0;
    
    uint256 public  total_token_buy = 0;
uint256 public  total_token_sell = 0;
    
    
    uint64 public  priceIndex = 1;
    bool   public  buyOn = true;
    bool   public  sellOn = true;
    bool   public  stakingOn = true;
    bool   public  airdropOn = true;
    bool   public  withdrawOn = true;
    
    uint256 public  MINIMUM_BUY = 1e18;
    uint256 public  MINIMUM_SELL = 20*1e18;    //@ 20busd
    uint256 public MAXIMUM_SELL = 30*1e18;
   /* uint256 public MAXIMUM_SELL = 100*1e18; */
    uint256 public  priceUpdateGap = 200*1e18;
    uint256 public airDropToken= 10*1e18;
   /* uint256 public airDropToken= 1e18; */
    uint256 public airDropPerMonth= 1e18;
    uint256 public airDropTokenLeft=1e18;
    
    address public owner;
    
    mapping(uint64 => uint) public buyLevel;
    mapping(uint64 => uint) public sellLevel;
    mapping(uint64 => uint) public priceLevel;
    
    mapping(address => bool) public airdropClaimed;
    mapping(address => uint256) public userAirdropToken;
    mapping(address => uint256) public lastAirdropWithdraw;
    

  
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event CycleStartedToken(address indexed user,uint256 stakeID, uint256 walletUsedToken, uint256 rewardUsedToken,uint256 compoundUsedToken, uint256 airdropUsedToken, uint256 tokenPrice);
    event CycleStartedBusd(address indexed user,uint256 stakeID, uint256 walletUsedBusd, uint256 rewardUsedBusd,uint256 compoundUsedBusd, uint256 airdropUsedBusd,uint256 tokenPrice);
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate, uint busd_amount);
    event onWithdraw(address  _user, uint256 withdrawalAmount,uint256 withdrawalAmountToken);
    event ReferralReward(address  _user,address _from,uint256 reward);
    IBEP20 private elucksToken; 
    IBEP20 private busdToken; 

    constructor(address ownerAddress, IBEP20 _busdToken, IBEP20 _elucksToken) public 
    {
        owner = ownerAddress;
        
        elucksToken = _elucksToken;
        busdToken = _busdToken;
        
        stakingPrograms_.push(Program(99,1*24*60*60,99)); //1 day and 0.99%
/*stakingPrograms_.push(Program(33,400*24*60*60,33)); //400 days and 0.33% */
  
        User memory user = User({
            id: 1,
            referrer: address(0),
            referralReward: uint(0),
            selfBuy: uint(0),
            selfSell: uint(0),
            programCount: uint(0),
            totalStakingBusd: uint(0),
            totalStakingToken: uint(0),
            currentPercent: uint(0),
            compoundReward:uint(0),
            freeStakedToken:uint(0),
            airdropReward:uint(0)
        });
        airdropClaimed[ownerAddress]=false;
        userAirdropToken[ownerAddress]=0;
        lastAirdropWithdraw[ownerAddress]=0;
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
    } 
    
    function() external payable 
    {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function withdrawBalance(uint256 amt,uint8 _type) public 
    {
        require(msg.sender == owner, "onlyOwner");
        if(_type==1)
        msg.sender.transfer(amt);
        else if(_type==2)
        busdToken.transfer(msg.sender,amt);
        else
        elucksToken.transfer(msg.sender,amt);
    }
    
    // ***Airdrop Program***
    
    function claimAirdrop(address referrerAddress) public 
    {
        require(airdropOn,"Airdrop Stopped");
        require(!airdropClaimed[msg.sender],"Already Claimed");
        uint256 tokens=(airDropToken/tokenPrice)*1e18;
        require(airDropTokenLeft>=tokens,"Airdrop Finished");
        if(!isUserExists(msg.sender))
        {
            registration(msg.sender, referrerAddress);   
        }
        airdropClaimed[msg.sender]=true;
        lastAirdropWithdraw[msg.sender]=block.timestamp;
        users[msg.sender].airdropReward=airDropToken;
        userAirdropToken[msg.sender]=airDropToken;
        uint256 refReward=(airDropToken.mul(3)).div(100);
        users[users[msg.sender].referrer].referralReward=users[users[msg.sender].referrer].referralReward+refReward;
        airDropTokenLeft=airDropTokenLeft-tokens;
    }
    
    function registration(address userAddress, address referrerAddress) public 
    {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            referralReward: 0,
            selfBuy: 0,
            selfSell: 0,
            programCount: 0,
            totalStakingBusd: 0,
            totalStakingToken: 0,
            currentPercent: 0,
            compoundReward: 0,
            freeStakedToken:0,
            airdropReward:0
        });
        lastAirdropWithdraw[userAddress]=0;
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        lastUserId++;
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    // Staking Process
    
    function start_staking(uint256 walletUsedBusd,uint256 rewardUsedBusd,uint256 compoundUsedBusd,uint256 airdropBusd,uint256 _programId,address referrer) public 
    {
        require(stakingOn,"Staking Stopped.");
        require(!isStop[msg.sender],"Contact Support.");
        if(!isUserExists(msg.sender))
        {
            registration(msg.sender, referrer);   
        }
        else
        {
            updateRewards();
        }
        
        // ***airdrop balance***
        require(users[msg.sender].airdropReward>=airdropBusd,"Low Airdrop balance");
        uint256 airdropUsed=(airdropBusd.mul(1e18)).div(tokenPrice);
        
        // ***wallet balance*** 
        uint256 walletUsed=(walletUsedBusd.mul(1e18)).div(tokenPrice);
       require(elucksToken.balanceOf(msg.sender)>=walletUsed,"Low wallet balance");
        require(elucksToken.allowance(msg.sender,address(this))>=walletUsed,"Allow token first");
        
        // ***level balance***
        require(users[msg.sender].referralReward>=rewardUsedBusd,"Low reward balance");
        uint256 rewardUsed=(rewardUsedBusd.mul(1e18)).div(tokenPrice);
        
        
        // ***compound balance***
        
        require(users[msg.sender].compoundReward>=compoundUsedBusd,"Low Compound balance");
        uint256 compoundUsed=(compoundUsedBusd.mul(1e18)).div(tokenPrice);
        
        require(_programId>=0 && _programId<stakingPrograms_.length, "Wrong staking program id");
        
        uint256 _amount=walletUsed+rewardUsed+compoundUsed+airdropUsed;
        elucksToken.transferFrom(msg.sender,address(this),walletUsed);
       
        uint256 _busdAmount=walletUsedBusd+rewardUsedBusd+compoundUsedBusd+airdropBusd;
        require(_busdAmount>=10*1e18, "Minimum 10 BUSD");
        
        
        require(isUserExists(msg.sender), "user not exists");
        uint256 programCount = users[msg.sender].programCount;
        users[msg.sender].referralReward=users[msg.sender].referralReward-rewardUsedBusd;
        users[msg.sender].compoundReward=users[msg.sender].compoundReward-compoundUsedBusd;
        users[msg.sender].airdropReward=users[msg.sender].airdropReward-airdropBusd;
        
        users[msg.sender].programs[programCount].programId = _programId;
        users[msg.sender].programs[programCount].stakingDate = block.timestamp;
        users[msg.sender].programs[programCount].lastWithdrawalDate = block.timestamp;
        users[msg.sender].programs[programCount].staking = _busdAmount;
        users[msg.sender].programs[programCount].currentRewards = 0;
        users[msg.sender].programs[programCount].genRewards = 0;
        users[msg.sender].programs[programCount].isExpired = false;
        users[msg.sender].programs[programCount].stakingToken = _amount;
        users[msg.sender].programCount = users[msg.sender].programCount.add(1);
        
        users[msg.sender].totalStakingToken = users[msg.sender].totalStakingToken.add(_amount);
        users[msg.sender].totalStakingBusd = users[msg.sender].totalStakingBusd.add(_busdAmount);
        users[msg.sender].currentPercent=getStakingPercent(msg.sender);
        address referrerAddress=users[msg.sender].referrer;
        for(uint8 i=0;i<10;i++)
        {
          if(users[msg.sender].programCount==1)     
          users[referrerAddress].refUser[i]=users[referrerAddress].refUser[i]+1;
          users[referrerAddress].refStake[i]=users[referrerAddress].refStake[i]+_amount;
             
          if(users[referrerAddress].referrer!=address(0))
          referrerAddress=users[referrerAddress].referrer;
          else
          break;
        }
        
        
        if(msg.sender!=owner)
        _calculateReferrerReward(_busdAmount,users[msg.sender].referrer);
        
        total_staking_busd=total_staking_busd+_busdAmount;
        total_virtual_staking=total_virtual_staking+_busdAmount;
        total_staking_token=total_staking_token+_amount;
        
        if(total_virtual_staking>=priceUpdateGap && !isAdminOpen)
        updateTokenPrice(1);
        uint256 walletBusd=walletUsedBusd;
        uint256 rewardBusd=rewardUsedBusd;
        uint256 compoundBusd=compoundUsedBusd;
        uint256 airdropUsedBusd=airdropBusd;
        uint256 airdropToken=airdropUsed;
        emit CycleStartedToken(msg.sender,users[msg.sender].programCount, walletUsed, rewardUsed,compoundUsed,airdropToken,tokenPrice);
        emit CycleStartedBusd(msg.sender,users[msg.sender].programCount, walletBusd, rewardBusd,compoundBusd,airdropUsedBusd,tokenPrice);
    }

    function buyToken(uint256 tokenQty) public payable
    {
         require(buyOn,"Buy Stopped.");
         require(!isContract(msg.sender),"Can not be contract");
         require(isUserExists(msg.sender), "user not exists");
         require(tokenQty>=MINIMUM_BUY,"Invalid minimum quantity");
         uint256 buy_amt=(tokenQty/1e18)*tokenPrice;
         require(busdToken.balanceOf(msg.sender)>=(buy_amt),"Low Balance");
         require(busdToken.allowance(msg.sender,address(this))>=buy_amt,"Invalid buy amount");
         
         users[msg.sender].selfBuy=users[msg.sender].selfBuy+tokenQty;
         busdToken.transferFrom(msg.sender ,address(this), (buy_amt));
         elucksToken.transfer(msg.sender , tokenQty);
         
         total_token_buy=total_token_buy+tokenQty;
         emit TokenDistribution(address(this), msg.sender, tokenQty, tokenPrice, buy_amt);                  
     }

    function sellToken(uint256 tokenQty) public payable
    {
         require(sellOn,"sell Stopped.");
         require(!isContract(msg.sender),"Can not be contract");
         require(isUserExists(msg.sender), "user not exists");
         require(tokenQty>=MINIMUM_SELL,"Invalid minimum quantity");
         require(tokenQty>=MAXIMUM_SELL,"Invalid maxmimum quantity");
         uint256 sell_amt=(tokenQty/1e18)*tokenPrice;
         require(elucksToken.balanceOf(msg.sender)>=(sell_amt),"Low Balance");
         require(elucksToken.allowance(msg.sender,address(this))>=sell_amt,"Invalid sell amount");
         
         users[msg.sender].selfSell=users[msg.sender].selfSell+tokenQty;
         elucksToken.transferFrom(msg.sender ,address(this), (tokenQty));
         busdToken.transfer(msg.sender , sell_amt);
         
                  
     }
     
     // ***Referral Program***
     
    function _calculateReferrerReward(uint256 _staking, address _referrer) private 
    {
         uint256 oldPercent;
         uint256 totalPercent;
         for(uint8 i=0;i<10;i++)
         {
             uint256 refPercent=getPercent(_referrer);
             if(refPercent>oldPercent && totalPercent<250)
             {
                uint256 left=refPercent-oldPercent;
                totalPercent=totalPercent+left;
                if(left>0)
                {
                    if(users[_referrer].totalStakingBusd>=_staking)
                    users[_referrer].referralReward=users[_referrer].referralReward+((_staking.mul(left)).div(1000));
                    else
                    {
                        uint256 rest=_staking-users[_referrer].totalStakingBusd;
                        users[_referrer].referralReward=users[_referrer].referralReward+((users[_referrer].totalStakingBusd.mul(left)).div(1000)); 
                        users[_referrer].compoundReward=users[_referrer].compoundReward+((rest.mul(left)).div(1000)); 
                    }
                    emit ReferralReward(_referrer,msg.sender,(_staking.mul(left)).div(1000));
                }
                oldPercent=refPercent;
             }
             
             users[_referrer].refStake[i]=users[_referrer].refStake[i]+_staking;
             if(users[_referrer].referrer!=address(0))
             _referrer=users[_referrer].referrer;
             else
             break;
         }
     }
    
    function withdraw() public payable 
    {
        require(withdrawOn,"Withdraw Stopped.");
        require(!isStop[msg.sender],"Contact Support.");
        require(msg.value == 0, "withdrawal doesn't allow to transfer bnb simultaneously");
        uint256 uid = users[msg.sender].id;
        require(uid != 0, "Can not withdraw because no any stakings");
        uint256 withdrawalAmount = 0;
        for (uint256 i = 0; i < users[msg.sender].programCount; i++) 
        {
            if (users[msg.sender].programs[i].genRewards>0) {
                withdrawalAmount += users[msg.sender].programs[i].genRewards;
                users[msg.sender].programs[i].genRewards=0;
            }
            
            if (users[msg.sender].programs[i].isExpired) {
                continue;
            }

            Program storage program = stakingPrograms_[users[msg.sender].programs[i].programId];

            bool isExpired = false;
            bool isAddedStaked = false;
            uint256 withdrawalDate = block.timestamp;
            if (program.term > 0) {
                uint256 endTime = users[msg.sender].programs[i].stakingDate.add(program.term);
                if (withdrawalDate >= endTime) {
                    withdrawalDate = endTime;
                    isExpired = true;
                    users[msg.sender].freeStakedToken=users[msg.sender].freeStakedToken+users[msg.sender].programs[i].stakingToken;
                    isAddedStaked=true;
                }
            }

            uint256 amount = _calculateRewards(users[msg.sender].programs[i].staking , users[msg.sender].currentPercent , withdrawalDate , users[msg.sender].programs[i].lastWithdrawalDate , users[msg.sender].currentPercent);

            withdrawalAmount += amount;            
            
            users[msg.sender].programs[i].lastWithdrawalDate = withdrawalDate;
            users[msg.sender].programs[i].isExpired = isExpired;
            users[msg.sender].programs[i].isAddedStaked = isAddedStaked;
            users[msg.sender].programs[i].currentRewards += amount;
        }
        uint256 referralToken;
        uint256 airdropToken;
        uint256 roiToken=(withdrawalAmount.mul(1e18)).div(tokenPrice);
        if(users[msg.sender].referralReward>0)
        {
            referralToken=(users[msg.sender].referralReward.mul(1e18)).div(tokenPrice);
            users[msg.sender].referralReward=0;
        }
        if(users[msg.sender].airdropReward>0)
        {
            airdropToken=get_airdropToken(msg.sender);
            users[msg.sender].airdropReward=users[msg.sender].airdropReward-airdropToken;
            lastAirdropWithdraw[msg.sender]=block.timestamp;
        }
        
        uint256 totalToken=users[msg.sender].freeStakedToken+referralToken+roiToken+airdropToken;
        users[msg.sender].freeStakedToken=0;
        if(totalToken>0)
        {
        elucksToken.transfer(msg.sender,totalToken);
        total_withdraw_busd=total_withdraw_busd+(totalToken.mul(1e18)).div(tokenPrice);
        total_withdraw_token=total_withdraw_token+(totalToken);
        total_virtual_withdraw=total_virtual_withdraw+totalToken;
        if(total_virtual_withdraw>priceUpdateGap && !isAdminOpen)
        updateTokenPrice(2);
        _calculateReferrerReward(withdrawalAmount, users[msg.sender].referrer);
        emit onWithdraw(msg.sender, withdrawalAmount,totalToken);
        }
    }
    
    
    function updateRewards() private
    {
        require(msg.value == 0, "withdrawal doesn't allow to transfer bnb simultaneously");
        uint256 uid = users[msg.sender].id;
        require(uid != 0, "Can not withdraw because no any stakings");
        uint256 withdrawalAmount = 0;
        for (uint256 i = 0; i < users[msg.sender].programCount; i++) 
        {
            if (users[msg.sender].programs[i].isExpired) {
                continue;
            }

            Program storage program = stakingPrograms_[users[msg.sender].programs[i].programId];

            bool isExpired = false;
            bool isAddedStaked = false;
            uint256 withdrawalDate = block.timestamp;
            if (program.term > 0) {
                uint256 endTime = users[msg.sender].programs[i].stakingDate.add(program.term);
                if (withdrawalDate >= endTime) {
                    withdrawalDate = endTime;
                    isExpired = true;
                    isAddedStaked=true;
                    users[msg.sender].freeStakedToken=users[msg.sender].freeStakedToken+users[msg.sender].programs[i].stakingToken;
                }
            }

            uint256 amount = _calculateRewards(users[msg.sender].programs[i].staking , users[msg.sender].currentPercent , withdrawalDate , users[msg.sender].programs[i].lastWithdrawalDate , users[msg.sender].currentPercent);

            withdrawalAmount += amount;
            
            users[msg.sender].programs[i].lastWithdrawalDate = withdrawalDate;
            users[msg.sender].programs[i].isExpired = isExpired;
            users[msg.sender].programs[i].isAddedStaked = isAddedStaked;
            users[msg.sender].programs[i].currentRewards += amount;
            users[msg.sender].programs[i].genRewards += amount;
        }
    }
    
    function getStakingProgramByUID(address _user) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory,uint256[] memory, bool[] memory, bool[] memory) 
    {
       
        User storage staker = users[_user];
        uint256[] memory stakingDates = new  uint256[](staker.programCount);
        uint256[] memory stakings = new  uint256[](staker.programCount);
        uint256[] memory currentRewards = new  uint256[](staker.programCount);
        bool[] memory isExpireds = new  bool[](staker.programCount);
        uint256[] memory newRewards = new uint256[](staker.programCount);
        uint256[] memory genRewards = new uint256[](staker.programCount);
        bool[] memory isAddedStakeds = new bool[](staker.programCount);

        for(uint256 i=0; i<staker.programCount; i++){
            require(staker.programs[i].stakingDate!=0,"wrong staking date");
            currentRewards[i] = staker.programs[i].currentRewards;
            genRewards[i] = staker.programs[i].genRewards;
            isAddedStakeds[i] = staker.programs[i].isAddedStaked;
            stakingDates[i] = staker.programs[i].stakingDate;
            stakings[i] = staker.programs[i].staking;
            if (staker.programs[i].isExpired) {
                isExpireds[i] = true;
                newRewards[i] = 0;
                
            } else {
                isExpireds[i] = false;
                if (stakingPrograms_[staker.programs[i].programId].term > 0) {
                    if (block.timestamp >= staker.programs[i].stakingDate.add(stakingPrograms_[staker.programs[i].programId].term)) {
                        newRewards[i] = _calculateRewards(staker.programs[i].staking, staker.currentPercent, staker.programs[i].stakingDate.add(stakingPrograms_[staker.programs[i].programId].term), staker.programs[i].lastWithdrawalDate, staker.currentPercent);
                        isExpireds[i] = true;
                       
                    }
                    else{
                        newRewards[i] = _calculateRewards(staker.programs[i].staking, staker.currentPercent, block.timestamp, staker.programs[i].lastWithdrawalDate, staker.currentPercent);
                      
                    }
                } else {
                    newRewards[i] = _calculateRewards(staker.programs[i].staking, staker.currentPercent, block.timestamp, staker.programs[i].lastWithdrawalDate, staker.currentPercent);
                 
                }
            }
        }

        return
        (
        stakingDates,
        stakings,
        currentRewards,
        newRewards,
        genRewards,
        isExpireds,
        isAddedStakeds
        );
    }
    
    function getStakingToken(address _user) public view returns (uint256[] memory) 
    {
       
        User storage staker = users[_user];
        uint256[] memory stakings = new  uint256[](staker.programCount);

        for(uint256 i=0; i<staker.programCount; i++){
            require(staker.programs[i].stakingDate!=0,"wrong staking date");
            stakings[i] = staker.programs[i].stakingToken;
        }

        return
        (
            stakings
        );
    }

    function _calculateRewards(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start , uint256 _maxDailyInterest) private pure returns (uint256) {

        uint256 numberOfDays =  (_now - _start) / INTEREST_CYCLE ;
        uint256 result = 0;
        uint256 index = 0;
        if(numberOfDays > 0){
          uint256 secondsLeft = (_now - _start);
           for (index; index < numberOfDays; index++) {
               if(_dailyInterestRate + index <= _maxDailyInterest ){
                   secondsLeft -= INTEREST_CYCLE;
                     result += (_amount * (_dailyInterestRate + index) / 10000 * INTEREST_CYCLE) / (60*60*24);
               }
               else
               {
                 break;
               }
            }

            result += (_amount * (_dailyInterestRate + index) / 10000 * secondsLeft) / (60*60*24);

            return result;

        }else{
            return (_amount * _dailyInterestRate / 10000 * (_now - _start)) / (60*60*24);
        }

    }
    
    // ***Token Price Algorithm***
    
    function updateTokenPrice(uint8 _type) private
    {
       if(_type==1)
       {
         while(true)
         {
             uint256 tempPrice=(tokenPrice*priceIncPercent)/1000000;
             tokenPrice=tokenPrice+tempPrice;
             total_virtual_staking=total_virtual_staking-priceUpdateGap;
             if(total_virtual_staking<priceUpdateGap)
             return;
         }
       }
       else
       {
         while(true)
         {
             uint256 tempPrice=(tokenPrice.mul(priceDecPercent)).div(1000000);
             tokenPrice=tokenPrice-tempPrice;
             total_virtual_withdraw=total_virtual_withdraw-priceUpdateGap;
             if(total_virtual_withdraw<priceUpdateGap)
             return;
         }
       }
    }
    
    
    // ***Staking Percent***
       function getStakingPercent(address _user) public view returns(uint16)
    {
        require(isUserExists(_user),"User Not Exist");
        return 33;
    }

/*    function getStakingPercent(address _user) public view returns(uint16)
    {
        require(isUserExists(_user),"User Not Exist");
        
        if(users[_user].totalStakingBusd>=2000*1e18)
        return 33;
        else if(users[_user].totalStakingBusd>=1000*1e18)
        return 33;
        else if(users[_user].totalStakingBusd>=500*1e18)
        return 33;
        else
        return 33;
    }
*/

    //  ***Referral Reward Percent***
    
    function getPercent(address _user) public view returns(uint16)
    {
        if(position[_user]==0)
        {
            if(!isUserExists(_user))
            return 0;
            uint256 totalDirect=users[_user].refUser[0];
            uint256 totalTeam;
            for(uint8 i=0;i<10;i++)
            {
               totalTeam=totalTeam+users[_user].refUser[i]; 
            }
            
            if(totalDirect>=2 && totalTeam>=3)
            return 250;
            else if(totalDirect>=3 && totalTeam>=4)
            return 200;
            else if(totalDirect>=2 && totalTeam>=5)
            return 150;
            else
            return 50;
        }
        else
        {
            if(position[_user]==1)
            return 150;
            else if(position[_user]==2)
            return 200;
            else if(position[_user]==3)
            return 250;  
        }
    }

/*
function getPercent(address _user) public view returns(uint16)
    {
        if(position[_user]==0)
        {
            if(!isUserExists(_user))
            return 0;
            uint256 totalDirect=users[_user].refUser[0];
            uint256 totalTeam;
            for(uint8 i=0;i<10;i++)
            {
               totalTeam=totalTeam+users[_user].refUser[i]; 
            }
            
            if(totalDirect>=20 && totalTeam>=1000)
            return 250;
            else if(totalDirect>=15 && totalTeam>=500)
            return 200;
            else if(totalDirect>=10 && totalTeam>=50)
            return 150;
            else
            return 50;
        }
        else
        {
            if(position[_user]==1)
            return 150;
            else if(position[_user]==2)
            return 200;
            else if(position[_user]==3)
            return 250;  
        }
    }
*/
    
    function get_airdropToken(address user) public view returns(uint256)
    {
      if(block.timestamp>lastAirdropWithdraw[user] && users[user].airdropReward>0)
      {
          uint256 gapPer=((block.timestamp.sub(lastAirdropWithdraw[user])).div(60*60*24*30)).mul(100);
          uint256 totalAmount=(userAirdropToken[user].mul(gapPer)).div(1000);
          
          if(totalAmount>=users[user].airdropReward)
          return users[user].airdropReward;
          else
          return totalAmount;
      }
      else
      {
          return 0;
      }
    }
    

    function isContract(address _address) public view returns (bool _isContract)
    {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }   
   
    
    function openAdminPrice(uint8 _type) public payable
    {
              require(msg.sender==owner,"Only Owner");
              if(_type==1)
              isAdminOpen=true;
              else
              {
                isAdminOpen=false;
                total_virtual_staking=0;
                total_virtual_withdraw=0;
              }
    }
    
    function sendAirdropToken(address _user,uint256 token) public payable
    {
        require(msg.sender==owner,"Only Owner.");
        require(isUserExists(_user),"User Not Exist.");
        require(airdropClaimed[_user],"First claim airdrop.");
        require(airDropTokenLeft>0,"Airdrop Finished");
        uint256 tokens=(token/tokenPrice)*1e18;
        users[_user].airdropReward=users[_user].airdropReward+token;
        userAirdropToken[_user]=userAirdropToken[_user]+token; 
        airDropTokenLeft=airDropTokenLeft-tokens;
    }
    
    function updatePrice(uint256 _price) public payable
    {
              require(msg.sender==owner,"Only Owner");
              require(isAdminOpen,"Admin option not open.");
              tokenPrice=_price;
    }
    
    function updatePosition(address user,uint8 _position) public payable
    {
        require(msg.sender==owner,"Only Owner");
        position[user]=_position;
    }
    
    
    function switchStaking(uint8 _type) public payable
    {
        require(msg.sender==owner,"Only Owner");
            if(_type==1)
            stakingOn=true;
            else
            stakingOn=false;
    }
    
    function switchBuy(uint8 _type) public payable
    {
        require(msg.sender==owner,"Only Owner");
            if(_type==1)
            buyOn=true;
            else
            buyOn=false;
    }
    
    function switchSell(uint8 _type) public payable
    {
        require(msg.sender==owner,"Only Owner");
            if(_type==1)
            sellOn=true;
            else
            sellOn=false;
    }
    
    function switchAirdrop(uint8 _type) public payable
    {
        require(msg.sender==owner,"Only Owner");
            if(_type==1)
            airdropOn=true;
            else
            airdropOn=false;
    }
    
    function switchWithdraw(uint8 _type) public payable
    {
        require(msg.sender==owner,"Only Owner");
            if(_type==1)
            withdrawOn=true;
            else
            withdrawOn=false;
    }
    

    function stopStaking(address _user,uint8 _type) public payable
    {
        require(msg.sender==owner,"Only Owner");
            if(_type==1)
            isStop[_user]=true;
            else
            isStop[_user]=false;
    }
    
    function isUserExists(address user) public view returns (bool) 
    {
        return (users[user].id != 0);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}