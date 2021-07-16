//SourceUnit: phoenix.sol

pragma solidity ^0.5.8;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface GPoolInfo{
    function gpoolInfo(address _ply,uint256 _amount) external view returns(uint256);
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

contract phoenix{
    using SafeMath for *;
    // emergency 
    address public owner;
    address public setPriceMan;
    bool public emergencyFlag;
    // team 
    address private team1;
    address private team2;
    address private team3;
    address private team4;
    address private team5;
    address private team6;
    
    mapping(address => uint256) public plyAirAmount;
    uint256 public totalAir ;
    address private gInfo;
    
    address public constant NULLPARENT = address(0x0000000000000000000000000000000000000001);
    
    // game info
    uint256 public totalInvestedAmount; // total inversted trx
    uint256 public totalWithdrawAmount; // total inversted trx
    uint256 public PID; // plys
    uint256 public gameStartTime;
    uint256 public constant INCREMENT = 10000000*1e6;
    //uint256 public constant INCREMENT = 3*1e6;
    uint256 public constant INCREMENT_NOMORL_RATE = 166; //2% 
    //uint256 public constant INCREMENT_NOMORL_RATE = 1080000; //2%
    uint256 public constant INCREMENT_UP_RATE = 1; //0.01%
    uint256 public constant INCREMENT_DOWN_RATE = 166; //0.5%
    uint256 public constant INCREMENT_TOP_LIMIT = 1800; //5%
    uint256 public constant INCREMENT_LOWER_LIMIT = 50; //0.5%
    uint256 public currentRate; // second rate; 1%  = 100/10000;
    uint256 public lastesLevelbalance; // second rate;
    uint256 public onDay = 1 days;
    //uint256 public onDay = 1 hours;
    
    
    
    
    // ply info
    mapping(address => uint256) public plyID;
    mapping(uint256 => address) public plyid_addr;
    
    mapping(address => uint256) public plyRewardPerSec; // 
    mapping(address => PlyInfo_S) public plyInfo;
    mapping(address => PlyRelationship_S) public plyRel; 
    
    mapping(address => uint256) public plyRelReward; // relationship reward;
    mapping(address => uint256) public plyInverReward; // relationship reward;
    mapping(address => uint256) public plyStaticReward; // relationship reward;
    
    struct PlyInfo_S {
        uint256 pi_id; //ply total Invested
        uint256 pi_withdrawAmount; // already  withdrawd staticamount
        uint256 pi_principal; // this is for static 
        uint256 pi_startTime;
        uint256 pi_updateTime;
        uint256 pi_lastWithdraw;
        uint256 pi_startI;
        uint256 pi_updateI1;
    }
    
    struct PlyRelationship_S{
        uint256 pr_totalSonNumber;
        uint256 pr_totalSonInversted;
        uint256 pr_sonWithdraw;
        address pr_parent;
        uint256 pr_totalInversted;
        uint256 pr_totalReferrals;
        //uint256 pr_totalInverstedAmount;
    }
    uint256 public Days;
    mapping(uint256 => luckyDay_S) public DayLucky; // day 
    mapping(address  => bool) public DayLuckyWithDrawflag; // day withDraw flage
    mapping(address =>uint256) public plyLucky;
    mapping(uint256 => mapping(address => uint256)) public daySonInverAmount;
    uint256 public totalLock;
    struct luckyDay_S{
        address luck1;
        uint256 referralsAmount1;
        address luck2;
        uint256 referralsAmount2;
        address luck3;
        uint256 referralsAmount3;
        address luck4;
        uint256 referralsAmount4;
        mapping(address => uint8) plyluckid;
        address[] luckList;
        uint256 poolAmount;
        bool withdraw;
    }
    
    mapping(uint256 =>uint256) public DayIn;
     mapping(uint256 =>uint256) public DayOut;
    
    
    uint256 public currentRateLevel;
    struct poolRateInfo_S{
        uint256 startTime;
        uint256 endTime; // after end
        uint256 rate; 
        uint256 totalTimeRate; //after end need update this is (endTime-startTime)*rate + totalTimeRate0;
    }
    mapping(uint256 => poolRateInfo_S) public poolRateInfo;
    mapping(uint256 => uint256) public poolLevelAmount;
    
    
    
    constructor(/*uint256 sTime*/) public{
        
        owner = msg.sender;
        Days = 1;
        gameStartTime= 1608005520;
        //gameStartTime= 1607746320;
        gInfo = address(0x8736d90B7268F1811243B9feCD09ec3Adc1DA754);
        //gInfo = address(0x692a70D2e424a56D2C6C27aA97D1a86395877b3A);
        
        currentRate = INCREMENT_NOMORL_RATE;
        init();
    
    }
    
    function init() internal{
        team1 = address(0x7cDa6eEF7c609f5EF7D9c4a34d767A5eb5761f33); //i 2
        team2 = address(0x86122cC2e269cCf8CB3A78208027Bc9D8121c7fF); //il 2
        team3 = address(0x5199a874B777942820b731d9dd78bE671b27d8b1);  //4。42
        team4 = address(0x7dc6c8B6fde6964bfad59AC03FaC9405F19fb492); // 2.526
        team5 = address(0x76Ec40D5f4b3c237669c5A6Ef205e1E992112Cb6); //1.263
        team6 = address(0xF74a0FC1444162fE8955A5102b0786c1BD0eCD55);//3.789
    }
    
    function invest(address parent) public payable{
        require(msg.value >= 100*1e6,"to smail invest");
        //require(msg.value >= 1*1e6,"to smail invest");
        require(now >= gameStartTime,"not startSmart");
        if(plyID[msg.sender] == 0){
            require(parent == NULLPARENT || plyID[parent] >0 ,"err parent");
        }
        
        updateLucky();
        DayIn[Days]+= msg.value;
        //new plyer
        teamTransfer(msg.value);
        updatePool(msg.value);
        plyInfoSet(msg.sender,msg.value);
        updateRel(msg.sender,parent,msg.value);
        //airdrop(msg.sender,msg.value);
        
    }
    
    function updateLucky() internal{
        uint256 timeDay = calcDays(now);
        luckyDay_S storage dl  = DayLucky[Days];
        uint256 lockAmount = dl.poolAmount;
        /*if(timeDay > Days && !dl.withdraw){
            plyLucky[dl.luck1] = plyLucky[dl.luck1].add(lockAmount.mul(40).div(100));
            plyLucky[dl.luck2] = plyLucky[dl.luck2].add(lockAmount.mul(30).div(100));
            plyLucky[dl.luck3] = plyLucky[dl.luck3].add(lockAmount.mul(20).div(100));
            plyLucky[dl.luck4] = plyLucky[dl.luck4].add(lockAmount.mul(10).div(100));
             Days =timeDay;
             dl.withdraw = true;
             totalLock += lockAmount;
        }*/
        uint256  totalI;
        if(timeDay > Days && !dl.withdraw){
            if(dl.luck1 != address(0x0000000000000000000000000000000000000000)){
                plyLucky[dl.luck1] = plyLucky[dl.luck1].add(lockAmount.mul(40).div(100));
                totalI+=lockAmount.mul(40).div(100);
            }
            if(dl.luck2 != address(0x0000000000000000000000000000000000000000)){
                plyLucky[dl.luck2] = plyLucky[dl.luck2].add(lockAmount.mul(30).div(100));
                totalI+=lockAmount.mul(30).div(100);
            }
            if(dl.luck3 != address(0x0000000000000000000000000000000000000000)){
                plyLucky[dl.luck3] = plyLucky[dl.luck3].add(lockAmount.mul(20).div(100));
                totalI+=lockAmount.mul(20).div(100);
            }
                
            if(dl.luck4 != address(0x0000000000000000000000000000000000000000)){
                plyLucky[dl.luck4] = plyLucky[dl.luck4].add(lockAmount.mul(10).div(100));
                totalI+=lockAmount.mul(10).div(100);
            }
             Days =timeDay;
             dl.withdraw = true;
             totalLock += totalI;
        }
    }
    function lockyCheck(address ply) internal{
        //check  the time ;
        //uint256 totalIn = plyRel[ply].pr_totalSonInversted;
        uint256 totalIn = daySonInverAmount[Days][ply];
        
        address[] memory newList = new address[](4);
        luckyDay_S storage dl  = DayLucky[Days];
        bool isInsert = false;
        uint256 len = dl.luckList.length;
        bool isIn;
        for(uint256 i=0;i<len;i++){
            if(i>=4){
                break;
            }
            if(ply == dl.luckList[i]){
                isIn = true;
            }
        }
        
        if(len == 0){
            newList[0] = ply;
            isInsert = true;
        }else{
            if(isIn){
                for(uint256 i=0;i<len;i++){
                    for(uint256 j=0;j<len-1-i;j++){
                        if(daySonInverAmount[Days][dl.luckList[j]] < daySonInverAmount[Days][dl.luckList[j+1]]){
                            address tem = dl.luckList[j+1];
                            dl.luckList[j+1] = dl.luckList[j];
                            dl.luckList[j] = tem;
                        }
                    }
                }
                isInsert = true;
                
            }else{
                for(uint256 i=0;i<len;i++){
            
                if(totalIn > daySonInverAmount[Days][dl.luckList[i]])/*plyRel[dl.luckList[i]].pr_totalSonInversted*/{
                    newList[i] = ply;
                    if(i !=3){
                        for(uint256 j=i;j<3;j++){
                            newList[j+1] = dl.luckList[j];
                        }
                    }
                    isInsert = true;
                    break;
                }else{
                    newList[i] = dl.luckList[i];
                }
            }
            }
        }
        /*for(uint256 i=0;i<len;i++){
            
            if(totalIn > daySonInverAmount[Days][dl.luckList[i]]){
                newList[i] = ply;
                if(i !=3){
                    for(uint256 j=i;j<3;j++){
                        newList[j+1] = dl.luckList[j];
                    }
                }
                isInsert = true;
                break;
            }else{
                newList[i] = dl.luckList[i];
            }
        }*/
        if(isInsert){
            if(!isIn){
                dl.luckList= newList;
            }
            
        //if(totalIn > DayLucky[Days].referralsAmount1){
            dl.luck1 = dl.luckList[0];
            dl.referralsAmount1 = daySonInverAmount[Days][dl.luck1];/*plyRel[dl.luck1].pr_totalSonInversted*/
            dl.luck2 = dl.luckList[1];
            dl.referralsAmount2 = daySonInverAmount[Days][dl.luck2];//plyRel[dl.luck2].pr_totalSonInversted;
            dl.luck3 = dl.luckList[2];
            dl.referralsAmount3 = daySonInverAmount[Days][dl.luck3];//plyRel[dl.luck3].pr_totalSonInversted;
            dl.luck4 = dl.luckList[3];
            dl.referralsAmount4 = daySonInverAmount[Days][dl.luck4];//plyRel[dl.luck4].pr_totalSonInversted;
            
        }
         
        
        
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function teamTransfer(uint256 amount) internal{
        
        //uint256 amount6315 = amount.mul(6315).div(1000000);
        toPayable(team1).transfer(amount.mul(15).div(1000));
        toPayable(team2).transfer(amount.mul(15).div(1000));
        toPayable(team3).transfer(amount.mul(4422).div(100000));
        toPayable(team4).transfer(amount.mul(2526).div(100000));
        toPayable(team5).transfer(amount.mul(1263).div(100000));
        toPayable(team6).transfer(amount.mul(3789).div(100000));
        
        
       
        totalWithdrawAmount = totalWithdrawAmount.add(amount.mul(15).div(100));
    }
    function updatePool(uint256 amount) internal{
        totalInvestedAmount = totalInvestedAmount.add(amount);
        
        if(PID == 0){
            currentRateLevel = 1;
            poolRateInfo[currentRateLevel] = poolRateInfo_S(now,0,INCREMENT_NOMORL_RATE,0);
            poolLevelAmount[currentRateLevel] = 0;
        }
        
        setPoolRateInfo(true);
        
    }
    function contractBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function setPoolRateInfo(bool isAdd) internal {
         // update currentRate
        uint256 curBalance = address(this).balance;
        uint256 tem ;
        
        if(isAdd){
            if(poolLevelAmount[currentRateLevel] < curBalance){
                tem = curBalance.sub(poolLevelAmount[currentRateLevel]).div(INCREMENT);
                if(tem > 0){
                    currentRate = currentRate.add(tem);
                    if(currentRate >=INCREMENT_TOP_LIMIT){
                        currentRate = INCREMENT_TOP_LIMIT;
                    }
                    poolLevelAmount[currentRateLevel+1] =poolLevelAmount[currentRateLevel]+ tem*INCREMENT;
                    poolRateInfoUpdate();
                }
            }
        }else{
            if(poolLevelAmount[currentRateLevel] > curBalance){
                tem = poolLevelAmount[currentRateLevel].sub(curBalance).div(INCREMENT);
                if(tem > 0){
                    if(tem<currentRate){
                        currentRate = currentRate.sub(tem);
                    }else{
                        currentRate = INCREMENT_DOWN_RATE;
                    }
                    
                    if(currentRate < INCREMENT_DOWN_RATE){
                        currentRate = INCREMENT_DOWN_RATE;
                    }
                    poolLevelAmount[currentRateLevel+1] = poolLevelAmount[currentRateLevel]- tem*INCREMENT;
                    poolRateInfoUpdate();
                }
                
            }
        }
        
        lastesLevelbalance =  address(this).balance;

    }

    function poolRateInfoUpdate() internal{
        poolRateInfo[currentRateLevel].endTime = now;
        uint256 time1 =now-poolRateInfo[currentRateLevel].startTime;
        if(currentRateLevel == 1){
            poolRateInfo[currentRateLevel].totalTimeRate = time1.mul(poolRateInfo[currentRateLevel].rate);
        }else{
            uint256 befortTRate =  poolRateInfo[currentRateLevel-1].totalTimeRate;
            poolRateInfo[currentRateLevel].totalTimeRate = befortTRate+ time1*poolRateInfo[currentRateLevel].rate;
        }
        currentRateLevel++;
        poolRateInfo[currentRateLevel] = poolRateInfo_S(now,0,currentRate,0);
    }
    
    function plyInfoSet(address ply,uint256 amount) internal {
        
        PlyInfo_S storage pinfo  = plyInfo[msg.sender];
        
        
        if(plyID[ply] == 0){
            PID++;
            plyID[ply] = PID;
            plyid_addr[PID] = ply;
            pinfo.pi_id = PID;
            pinfo.pi_principal = amount;
            pinfo.pi_startTime = now;
            pinfo.pi_startI = currentRateLevel;
            pinfo.pi_lastWithdraw = now;
            
        }else{
            
            pinfo.pi_principal = pinfo.pi_principal.add(amount);
            //calc static Reward
            uint256 cuReward;
            cuReward = calcStaticReward(ply);
            
            plyStaticReward[ply] = plyStaticReward[ply].add(cuReward);
            
            pinfo.pi_updateI1 = currentRateLevel;
            
            pinfo.pi_updateTime = now;
            
            
        }
    
    }
    
    function calcStaticReward(address ply) public view returns(uint256 reward){
         PlyInfo_S storage pinfo  = plyInfo[ply];

         uint256 PtS ;
         uint256 PtE = now;
         if(pinfo.pi_updateTime == 0){
            PtS = pinfo.pi_startTime;
             
         }else{
            PtS = pinfo.pi_updateTime; 
         }
         bool jumpLevel = true;
         if(pinfo.pi_updateI1 == 0){
            if(pinfo.pi_startI == currentRateLevel){
                  jumpLevel = false;  
            }
         }else{
            if(pinfo.pi_updateI1 == currentRateLevel){
                  jumpLevel = false;  
            } 
         }
            
         if(currentRateLevel > 1){
            if(!jumpLevel){
                uint256 re = pinfo.pi_principal.mul((PtE-PtS)*poolRateInfo[currentRateLevel].rate);
                reward = re.div(10000).div(onDay);
                return reward;
            }
            uint256 t1 = PtE.sub(poolRateInfo[currentRateLevel].startTime).mul(poolRateInfo[currentRateLevel].rate);
            uint256 t2 = poolRateInfo[currentRateLevel-1].totalTimeRate;
            uint256 sLevel ;
            if(pinfo.pi_updateI1 == 0){
                sLevel = pinfo.pi_startI;
            }else{
                sLevel = pinfo.pi_updateI1;
            }
            uint256 t3 ;
            
            if(sLevel>1){
                t3 = poolRateInfo[sLevel-1].totalTimeRate;
               // t4 = PtS.sub(poolRateInfo[sLevel].startTime).mul(poolRateInfo[sLevel].rate);
            }else{
                t3 = 0;
                
            }
            uint256 t4 = PtS.sub(poolRateInfo[sLevel].startTime).mul(poolRateInfo[sLevel].rate);
            uint256 re = pinfo.pi_principal.mul((t1+t2)-(t3+t4));
            reward = re.div(10000).div(onDay);
            return reward;
            
         }else{
            uint256 re = pinfo.pi_principal.mul((PtE-PtS)*poolRateInfo[1].rate);
            reward = re.div(10000).div(onDay);
            return reward; 
         }
        
    }
    
    function calcCheckStatic(address ply) public view returns(uint256){
        //return calcStaticReward(ply)+plyStaticReward[ply];
        uint256 reward = calcStaticReward(ply)+plyStaticReward[ply];
        //if(reward >plyInfo[ply].pi_principal*2 ){
          //  reward = plyInfo[ply].pi_principal*2;
       // }
        if(plyInfo[ply].pi_withdrawAmount+reward > plyInfo[ply].pi_principal*2){
            reward = plyInfo[ply].pi_principal.mul(2).sub(plyInfo[ply].pi_withdrawAmount);
        }
        return reward;
    }
    
    function updateRel(address ply,address parent,uint256 amount) internal{
        PlyRelationship_S storage prs = plyRel[ply]; 
        
        bool newPly = false ;
        address parent_parent = parent;
        if(plyInfo[ply].pi_startTime == now){
           if(parent == NULLPARENT){
                prs.pr_parent = NULLPARENT; 
                return ;
            }else{
                prs.pr_parent = parent; 
                plyRel[parent].pr_totalSonNumber++;
                //plyInverReward[parent] = plyInverReward[parent].add(amount.mul(10).div(100));
                
                //plyRel[parent].pr_totalSonInversted += amount;
                newPly = true;
            } 
        }else{
            parent_parent = prs.pr_parent;
        }
        if(prs.pr_parent != NULLPARENT){
            plyRel[prs.pr_parent].pr_totalSonInversted += amount;
            plyInverReward[prs.pr_parent] = plyInverReward[prs.pr_parent].add(amount.mul(10).div(100));
            daySonInverAmount[Days][prs.pr_parent] += amount;
            
        }
        DayLucky[Days].poolAmount = DayLucky[Days].poolAmount.add(amount.mul(3).div(100));
        if(parent_parent != NULLPARENT){
            //DayLucky[Days].poolAmount = DayLucky[Days].poolAmount.add(amount.mul(4).div(100));
            lockyCheck(parent_parent);
        }
        
        //top 15 level
        for(uint8 i =1; i<=15;i++){
            if(parent_parent == NULLPARENT){
                return;
            }
            updateParent(parent_parent,amount,newPly);
            
            parent_parent = plyRel[parent_parent].pr_parent;
        }
    }
    
    function updateParent(address parent,uint256 amount,bool isNewPly) internal{
        PlyRelationship_S storage prs = plyRel[parent];
        
        if(isNewPly){
           prs.pr_totalReferrals++; 
        }
        prs.pr_totalInversted = prs.pr_totalInversted.add(amount);

    }
    
    function calcDays(uint256 time) internal view returns(uint256 day){
        uint256 leng = time.sub(gameStartTime);
        day = leng.div(onDay).add(1);
    }
    
    //static 
    function withdraw() public {
        //require(!emergencyFlag,"emergency");
        require(address(this).balance >0,"not trx");
        require(plyID[msg.sender] >0,"not ply");
        updateLucky();
        uint256 tempR;
        
        PlyInfo_S storage pinfo  = plyInfo[msg.sender];
        uint256 timeLeng = now.sub(pinfo.pi_lastWithdraw);
        require(timeLeng>=onDay,"24 for once");
        uint256 canWith =  0;
        if(pinfo.pi_principal*2 > pinfo.pi_withdrawAmount){
            canWith = pinfo.pi_principal*2-pinfo.pi_withdrawAmount;
        }
        //uint256 canWith = pinfo.pi_principal*2.sub(pinfo.pi_withdrawAmount);
        uint256 reward ;
        uint256 staticR;
        uint256 info;
        (reward,info) = getStaticReward(msg.sender);
        tempR = reward;
        if(reward >= canWith){
             reward = canWith;
             staticR = reward;
        }else{
            staticR = reward;
            if(reward + plyRelReward[msg.sender] > canWith){
                plyRelReward[msg.sender] = plyRelReward[msg.sender].sub(canWith.sub(reward));
                reward = canWith;
                //plyRelReward[msg.sender] = plyRelReward[msg.sender].sub(canWith.sub(reward));
            }else{
                if(reward + plyRelReward[msg.sender] + plyLucky[msg.sender] > canWith){
                     uint256 lk = plyLucky[msg.sender];
                     plyLucky[msg.sender] = plyLucky[msg.sender].sub(canWith.sub(reward.add( plyRelReward[msg.sender])));
                     totalLock = totalLock.sub(lk.sub(plyLucky[msg.sender]));
                     reward = canWith;
                     
                }else{
                    if(reward + plyRelReward[msg.sender] + plyLucky[msg.sender]+plyInverReward[msg.sender] > canWith){
                        plyInverReward[msg.sender] = plyLucky[msg.sender].sub(canWith.sub(reward.add( plyRelReward[msg.sender].add(plyLucky[msg.sender]))));
                       reward = canWith; 
                    }else{
                       //reward = reward + plyRelReward[msg.sender] + plyLucky[msg.sender];
                        reward = reward + plyRelReward[msg.sender] + plyLucky[msg.sender]+plyInverReward[msg.sender]; 
                        plyInverReward[msg.sender] = 0;
                    }
                    totalLock -=plyLucky[msg.sender];
                    plyLucky[msg.sender] = 0; 
                    
                }
                plyRelReward[msg.sender] = 0;
            }
            
        }
        if(address(this).balance  <= reward){
            reward = address(this).balance;
        }
        
        if(reward > 0){
            calcParentReward(msg.sender,staticR);
            //msg.sender.transfer(reward);
            if(info == 1){
                msg.sender.transfer(reward);
                totalWithdrawAmount += reward;
                pinfo.pi_withdrawAmount +=reward;
            }else{
                msg.sender.transfer(tempR);
            }
            if(plyRel[msg.sender].pr_parent != NULLPARENT){
                plyRel[plyRel[msg.sender].pr_parent].pr_sonWithdraw = plyRel[plyRel[msg.sender].pr_parent].pr_sonWithdraw.add(reward);
            }
        }
        //msg.sender.transfer(reward);
        DayOut[Days]+= reward;
        pinfo.pi_updateI1 = currentRateLevel;
        pinfo.pi_updateTime = now;
        pinfo.pi_lastWithdraw = now;
        
        setPoolRateInfo(false);
    }
    
    function calcParentReward(address ply,uint256 reward) internal{
        PlyRelationship_S storage prs = plyRel[ply]; 
        if(reward ==0){
            return;
        }
        //down ply
        address parent_parent = prs.pr_parent;
        uint256 levelAmmount = 0;
        
    
        //top 15 level
        for(uint8 i =1; i<=15;i++){
            if(parent_parent == NULLPARENT){
                return;
            }
            //plyRel[parent_parent].pr_sonWithdraw = plyRel[parent_parent].pr_sonWithdraw.add(reward);
            if(plyRel[parent_parent].pr_totalSonInversted>plyRel[parent_parent].pr_sonWithdraw){
                levelAmmount = plyRel[parent_parent].pr_totalSonInversted-plyRel[parent_parent].pr_sonWithdraw;
            }
            if(levelAmmount == 0){
                continue;
            }
            if(levelAmmount >=10000*1e6 && levelAmmount <100000*1e6){
            //if(levelAmmount >=1*1e6 && levelAmmount <10*1e6){
                //level = 5;
                if(i==1){
                    plyRelReward[parent_parent]+= reward.mul(15).div(100);
                }else if(i>=2 && i<=5){
                    plyRelReward[parent_parent]+= reward.mul(10).div(100);
                }
            }else if(levelAmmount >=100000*1e6 && levelAmmount <200000*1e6){
            //}else if(levelAmmount >=10*1e6 && levelAmmount <20*1e6){
                //10
                if(i==1){
                    plyRelReward[parent_parent]+= reward.mul(15).div(100);
                }else if(i>=2 && i<=10){
                    plyRelReward[parent_parent]+= reward.mul(10).div(100);
                }
            }else if(levelAmmount >=200000*1e6 && levelAmmount <300000*1e6){
                //level = 12;
                if(i==1){
                    plyRelReward[parent_parent]+= reward.mul(15).div(100);
                }else if(i>=2 && i<=5){
                    plyRelReward[parent_parent]+= reward.mul(10).div(100);
                }else if(i>5 && i<=10){
                    plyRelReward[parent_parent]+= reward.mul(8).div(100);
                }else if(i>=11 && i<=12){
                    plyRelReward[parent_parent]+= reward.mul(6).div(100);
                }
            //}else if(levelAmmount >=300000*1e6){
            }else if(levelAmmount >=300000*1e6){
                //level = 15;
                if(i==1){
                    plyRelReward[parent_parent]+= reward.mul(12).div(100);
                }else if(i>=2 && i<=5){
                    plyRelReward[parent_parent]+= reward.mul(8).div(100);
                }else if(i>5 && i<=10){
                    plyRelReward[parent_parent]+= reward.mul(6).div(100);
                }else if(i>=11 && i<=12){
                    plyRelReward[parent_parent]+= reward.mul(4).div(100);
                }else if(i>=13 && i<= 15){
                     plyRelReward[parent_parent]+= reward.mul(2).div(100);
                }
            }
            parent_parent = plyRel[parent_parent].pr_parent;
            levelAmmount = 0;
        }
        //;
    //    plyRel[prs.pr_parent].pr_sonWithdraw = plyRel[prs.pr_parent].pr_sonWithdraw.add(reward);
    }
    
    //function calc
    
    function getStaticReward(address ply) view public returns(uint256 reward,uint256 info){
        
        reward = calcStaticReward(ply);
        reward = reward.add(plyStaticReward[ply]);
       
        if(reward+plyInfo[ply].pi_withdrawAmount > plyInfo[ply].pi_principal*2){
            reward = plyInfo[ply].pi_principal.mul(2).sub(plyInfo[ply].pi_withdrawAmount);
        }
        uint256 reward2;
        reward2  = GPoolInfo(gInfo).gpoolInfo(ply,reward);
        if(reward2 == reward){
            info =1;
        }else{
            info = 2;
        }
        reward = reward2;
        
        
    }
    
    
    
    
}