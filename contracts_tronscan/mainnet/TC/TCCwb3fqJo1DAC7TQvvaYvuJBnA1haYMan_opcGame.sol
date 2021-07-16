//SourceUnit: opcGame.sol

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

interface CheckPlyer{
    function checkPlyerInfo(address _ply,uint256 _amount) external view returns(uint256);
}

contract opcGame{
    using SafeMath for *;
    // emergency 
    address public owner;
    address public emergencyMan;
    address public setPriceMan;
    bool public emergencyFlag;
    // team 
    address private team1;
    address private team2;
    address private team3;
    address private team4;
    
    // airdrop 
    IERC20 public  airCoin;
    mapping(address => uint256) public plyAirAmount;
    uint256 public totalAir ;
    address private checkPly;
    
    address public constant NULLPARENT = address(0x0000000000000000000000000000000000000001);
    
    // game info
    uint256 public totalInvestedAmount; // total inversted trx
    uint256 public totalWithdrawAmount; // total inversted trx
    uint256 public PID; // plys
    uint256 public gameStartTime;
    uint256 public constant INCREMENT = 3000000*1e6;
    //uint256 public constant INCREMENT = 3*1e6;
    uint256 public constant INCREMENT_NOMORL_RATE = 200; //2% 
    //uint256 public constant INCREMENT_NOMORL_RATE = 1080000; //2%
    uint256 public constant INCREMENT_UP_RATE = 1; //0.01%
    uint256 public constant INCREMENT_DOWN_RATE = 50; //0.5%
    uint256 public constant INCREMENT_TOP_LIMIT = 500; //5%
    uint256 public constant INCREMENT_LOWER_LIMIT = 50; //0.5%
    uint256 public currentRate; // second rate; 1%  = 100/10000;
    uint256 public lastesLevelbalance; // second rate;
    
    uint256 public priceOpc;
    
    // ply info
    mapping(address => uint256) public plyID;
    mapping(uint256 => address) public plyid_addr;
    
    mapping(address => uint256) public plyRewardPerSec; // 
    mapping(address => PlyInfo_S) public plyInfo;
    mapping(address => PlyRelationship_S) public plyRel; 
    
    mapping(address => uint256) public plyRelReward; // relationship reward;
    mapping(address => uint256) public plyStaticReward; // relationship reward;
    
    struct PlyInfo_S {
        uint256 pi_id; //ply total Invested
        uint256 pi_withdrawStaticAmount; // already  withdrawd staticamount
        uint256 pi_withdrawTempAmount;
        uint256 pi_withdrawRelAmount; // already withdrawd relationship amount
        uint256 pi_plyInvestedAmount; // ply Invested this is total 
        uint256 pi_principal; // this is for static 
        uint256 pi_startTime;
        uint256 pi_updateTime;
        uint256 pi_startI;
        uint256 pi_updateI1;
        uint256 pi_updateI2;
    }
    
    struct PlyRelationship_S{
        uint256 pr_totalSonNumber;
        uint256 pr_totalReferrals;
        address pr_parent;
        uint256 pr_totalInversted;
    }
    
    uint256 public currentRateLevel;
    struct poolRateInfo_S{
        uint256 startTime;
        uint256 endTime; // after end
        uint256 rate; 
        uint256 totalTimeRate; //after end need update this is (endTime-startTime)*rate + totalTimeRate0;
    }
    mapping(uint256 => poolRateInfo_S) public poolRateInfo;
    mapping(uint256 => uint256) public poolLevelAmount;
    
    
    
    constructor(IERC20 airdropAddr,address checkAddr) public{
        owner = msg.sender;
        airCoin = airdropAddr;
        //emergencyMan = address(0x61AB7344Da71906884501a67d93e1B644E83E3C7) ; 
        team1 = address(0x5A1d7Be3a92F02AF8688e64F4fE8d3B52fe69bb3); //1.5
        team4 = address(0x1Bc04b7c9012bd52A4925112b3dE67B91a484a4B);//1.5
        team2 = address(0x9e80752B2a7c79316797731b766acE9F5e1e3dAB); //4%
        team3 = address(0x12CFf485B860BdAC19f9AF3C73413a0a577Af1fA);//5%
        setPriceMan = address(0x243a1413330B8b32F0B3b82B7970d264dc78725C);
        //setPriceMan = address(0x86122cC2e269cCf8CB3A78208027Bc9D8121c7fF);
        currentRate = INCREMENT_NOMORL_RATE;
        checkPly = checkAddr;
        
    }
    
    function invest(address parent) public payable{
        require(msg.value >= 1000*1e6,"to smail invest");
        if(plyID[msg.sender] == 0){
            require(parent == NULLPARENT || plyID[parent] >0 ,"err parent");
        }
        
        //new plyer
        teamTransfer(msg.value);
        updatePool(msg.value);
        plyInfoSet(msg.sender,msg.value);
        updateRel(msg.sender,parent,msg.value);
        airdrop(msg.sender,msg.value);
        
        
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function teamTransfer(uint256 amount) internal{
        uint256 t1Amount  =  amount.mul(15).div(1000);
        uint256 t4Amount  =  amount.mul(15).div(1000);
        uint256 t2Amount = amount.mul(40).div(1000);
        uint256 t3Amount = amount.mul(50).div(1000);
        toPayable(team1).transfer(t1Amount);
        toPayable(team4).transfer(t4Amount);
        toPayable(team2).transfer(t2Amount);
        toPayable(team3).transfer(t3Amount);
        totalWithdrawAmount = totalWithdrawAmount.add(t1Amount).add(t2Amount).add(t3Amount).add(t4Amount);
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
                if(currentRate >=500){
                    currentRate = 500;
                }
                if(totalWithdrawAmount.mul(100)>=totalInvestedAmount.mul(60)){
                    currentRate = 50;
                }
                poolLevelAmount[currentRateLevel+1] =poolLevelAmount[currentRateLevel]+ tem*INCREMENT;
                poolRateInfoUpdate();
                
            }
            }
        }else{
            if(poolLevelAmount[currentRateLevel] > curBalance){
            tem = poolLevelAmount[currentRateLevel].sub(curBalance).div(INCREMENT);
            if(tem > 0){
                if((tem*5)>currentRate){
                    currentRate = 50;
                }else{
                    currentRate -= (tem*5);
                }
                if(currentRate < 50){
                    currentRate = 50;
                }
                
                if(totalWithdrawAmount.mul(100)>=totalInvestedAmount.mul(60)){
                    currentRate = 50;
                }
                poolLevelAmount[currentRateLevel+1] = poolLevelAmount[currentRateLevel]- tem*INCREMENT;
                poolRateInfoUpdate();
                
            }else{
                if(totalWithdrawAmount.mul(100)>=totalInvestedAmount.mul(60)){
                    currentRate = 50;
                    poolLevelAmount[currentRateLevel+1] = poolLevelAmount[currentRateLevel];
                    poolRateInfoUpdate();
                }
            }
            
            }else{
                if(totalWithdrawAmount.mul(100)>=totalInvestedAmount.mul(60)){
                    currentRate = 50;
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
        //PlyRelationship_S storage prs = plyRel[msg.sender]; 
        
        if(plyID[ply] == 0){
            PID++;
            plyID[ply] = PID;
            plyid_addr[PID] = ply;
            pinfo.pi_id = PID;
            pinfo.pi_plyInvestedAmount = amount;
            pinfo.pi_principal = amount;
            pinfo.pi_startTime = now;
            pinfo.pi_startI = currentRateLevel;
            
        }else{
            pinfo.pi_plyInvestedAmount = pinfo.pi_plyInvestedAmount.add(amount);
            
            //calc static Reward
            uint256 cuReward;
            cuReward = calcStaticReward(ply);
            
            plyStaticReward[ply] = plyStaticReward[ply].add(cuReward);
            if(plyStaticReward[ply] > pinfo.pi_principal*2){
                plyStaticReward[ply] = pinfo.pi_principal*2;
            }
            
            pinfo.pi_updateI1 = currentRateLevel;
            
            pinfo.pi_updateTime = now;
            pinfo.pi_withdrawTempAmount = 0;
            pinfo.pi_principal = pinfo.pi_principal.add(amount);
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
                reward = re.div(10000).div(1 days);
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
            reward = re.div(10000).div(1 days);
            return reward;
            
         }else{
            uint256 re = pinfo.pi_principal.mul((PtE-PtS)*poolRateInfo[1].rate);
            reward = re.div(10000).div(1 days);
            return reward; 
         }
        
    }
    
    function calcCheckStatic(address ply) public view returns(uint256){
        //return calcStaticReward(ply)+plyStaticReward[ply];
        uint256 reward = calcStaticReward(ply)+plyStaticReward[ply];
        if(reward >plyInfo[ply].pi_principal*2 ){
            reward = plyInfo[ply].pi_principal*2;
        }
        //if(plyInfo[ply].pi_withdrawStaticAmount+reward > plyInfo[ply].pi_plyInvestedAmount*2){
        //    reward = plyInfo[ply].pi_plyInvestedAmount.mul(2).sub(plyInfo[ply].pi_withdrawStaticAmount);
        //}
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
                newPly = true;
            } 
        }else{
            parent_parent = prs.pr_parent;
        }
        
        
        //top 19 level
        for(uint8 i =1; i<=20;i++){
            if(parent_parent == NULLPARENT){
                return;
            }
            updateParent(parent_parent,amount,i,newPly);
            
            parent_parent = plyRel[parent_parent].pr_parent;
        }
    }
    
    function updateParent(address parent,uint256 amount,uint256 i,bool isNewPly) internal{
        PlyRelationship_S storage prs = plyRel[parent];
        
        // calc
        uint256 reward;
        uint256 burnAmout  = amount;
        if(prs.pr_totalSonNumber >= i){
            if(burnAmout > plyInfo[parent].pi_principal){
                burnAmout = plyInfo[parent].pi_principal;
            }
            if(i<=5){
                reward = burnAmout.mul(30).div(1000); // 3%
            }else if(i>=6 && i<=15){
                reward = burnAmout.mul(3).div(1000); // 0.3%
            }else if(i>=16 && i<=20){
                reward = burnAmout.mul(10).div(1000); // 1%
            }
            plyRelReward[parent] = plyRelReward[parent].add(reward);
        }
        if(isNewPly){
           prs.pr_totalReferrals++; 
        }
        prs.pr_totalInversted = prs.pr_totalInversted.add(amount);

    }
    
    function setPriceOpc(uint256 pric) public{
        require(msg.sender == setPriceMan,"only emergency man");
        priceOpc = pric;
    }
    function airdrop(address ply,uint256 amount) internal{
        if(amount < 10000*1e6){
            return;
        }
        if(priceOpc == 0){
            return;
        }
        PlyRelationship_S storage prs = plyRel[ply];
        uint256 son = prs.pr_totalSonNumber;
        uint256 prec = (10000-currentRate*10)*1e12/(100*10*priceOpc);
        uint256 airdropAmount = amount.mul(prec).div(10000);
        //uint256 airdropAmount = amount.mul((10000)/50).div(10000);
        airdropAmount = airdropAmount.mul(1e18).div(1e6);
        airdropAmount = airdropAmount.mul(40).div(100);
        
        if(son>=10){
            if(son>=20){
                airdropAmount = airdropAmount.mul(150).div(100);
            }else{
                airdropAmount = airdropAmount.mul(120).div(100);
            }   
        }
        airdropAmount = airdropAmount.div(1e6);
        if(airdropAmount>0){
            airCoin.transfer(ply,airdropAmount);
            plyAirAmount[ply] = plyAirAmount[ply].add(airdropAmount);
            totalAir = totalAir.add(airdropAmount);
        }
    }
    
    //static 
    function withdrawDeposits() public {
        //require(!emergencyFlag,"emergency");
        require(address(this).balance >0,"not trx");
        require(plyID[msg.sender] >0,"not ply");
        
        PlyInfo_S storage pinfo  = plyInfo[msg.sender];
        uint256 reward ;
        uint256 tt;
        (reward,tt) = getStaticReward(msg.sender);
        
        
        if(address(this).balance <= reward){
            reward = address(this).balance;
        }
        
        uint256 canWithdraw = reward.mul(70).div(100); 
        uint256 reInverst = reward.sub(canWithdraw);
        
        plyStaticReward[msg.sender] = 0;
        totalWithdrawAmount = totalWithdrawAmount.add(canWithdraw);
        pinfo.pi_withdrawTempAmount += canWithdraw;
        
        msg.sender.transfer(canWithdraw);
        pinfo.pi_withdrawStaticAmount += canWithdraw;
        //re invest
        if(tt == 1){
            pinfo.pi_principal = pinfo.pi_principal.add(reInverst).sub(reward.div(2));
        }
        pinfo.pi_updateI1 = currentRateLevel;
        pinfo.pi_updateTime = now;
        
        
        setPoolRateInfo(false);
    }
    
    function getStaticReward(address ply) view internal returns(uint256 reward,uint256 _tt){
        
        reward = calcStaticReward(ply);
        reward = reward.add(plyStaticReward[ply]);
        if(reward >= plyInfo[ply].pi_principal*2){
            reward = plyInfo[ply].pi_principal*2;
        }
        uint256 reward2;
        reward2  = CheckPlyer(checkPly).checkPlyerInfo(ply,reward);
        if(reward2 == reward){
            _tt =1;
        }else{
            _tt = 2;
        }
        reward = reward2;
        
    }
    
    //dics
    function withdrawdReferral() public{
        //require(!emergencyFlag,"emergency");
        require(plyRelReward[msg.sender] >0,"not eng rel reward");
        require(address(this).balance >0,"not trx");
        require(plyID[msg.sender] >0,"not ply");
        
        uint256 plyrelAmountTemp = plyRelReward[msg.sender];
        if(address(this).balance < plyrelAmountTemp){
            plyrelAmountTemp = address(this).balance;
        }
        uint256 canWithdraw = plyrelAmountTemp.mul(70).div(100); //70%
        uint256 reInverst = plyrelAmountTemp.sub(canWithdraw);
        plyRelReward[msg.sender] = 0;
        
        totalWithdrawAmount = totalWithdrawAmount.add(canWithdraw);
        msg.sender.transfer(canWithdraw);
        plyInfo[msg.sender].pi_withdrawRelAmount += canWithdraw;
        //re invest
        plyInfo[msg.sender].pi_principal = plyInfo[msg.sender].pi_principal.add(reInverst);
        setPoolRateInfo(false);
        
    }
    
    function backRate() internal{
        if(totalWithdrawAmount.mul(100)>=totalInvestedAmount.mul(60)){
            currentRate = 50;
            poolRateInfoUpdate();
        }
    }
    function notifyEmer(address _emAddr) public{
        require(msg.sender == owner,"only owner");
        emergencyMan = _emAddr;
    }
    /*function startUpEmergency() public{
        require(msg.sender == emergencyMan,"only emergency man");
        emergencyFlag = true;
    }
    
    function closeEmergency() public {
        require(msg.sender == emergencyMan,"only emergency man");
        emergencyFlag = false;
    }*/
    
}