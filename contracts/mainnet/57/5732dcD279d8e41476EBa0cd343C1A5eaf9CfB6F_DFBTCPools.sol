pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

import './SafeMath.sol';
import './TransferHelper.sol';
import './IERC20.sol';
import './UQ112x112.sol';

contract DFBTCPools {
   
    using SafeMath for uint; 
    using UQ112x112 for uint224;
   
    struct UserAssetsRecord {
        address _user;
        uint _startTime;
        uint _pledgeCycle;
        uint _amount;
        uint _hasTakeOut;
        bool _bFinished;
    }
    
    UserAssetsRecord[] public userAssetsRecordList;
    mapping(address=>UserAssetsRecord[]) public userAmounts;
    
    uint  public decreaseVal = 10;
    uint  public totalDays = 365;
    uint  public dayTakeout = 40;
    address public dfbtc = 0x67C8d54F38369571AAe70183b8568494032b5D7C;
    address public aom = 0x060924FB947e37EEE230d0B1A71D9618aEc269fC;
    address public owner;
    mapping(uint=>bool) public pledgeCyclemap;
    mapping(uint=>uint) public baseCalPower;
    mapping(uint=>uint) public annualizedRate;
    mapping(address=>uint) public userToCounts;
    mapping(address=>uint) public userToTakeOut;
    
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'dfbtc: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
    modifier onlyOnwer {
        require(owner == msg.sender, "dfbtc: The caller must be onwer!!!");
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        
        pledgeCyclemap[7] = true;
        pledgeCyclemap[30] = true;
        pledgeCyclemap[90] = true;
        pledgeCyclemap[180] = true;
        
        baseCalPower[7] = 55;
        baseCalPower[30] = 65;
        baseCalPower[90] = 75;
        baseCalPower[180] = 81;
        
        annualizedRate[7] = 6;
        annualizedRate[30] = 8;
        annualizedRate[90] = 11;
        annualizedRate[180] = 15;
        
        //addAssets(msg.sender, 7, 10000);
        //addAssets(msg.sender, 30, 10000);
        //addAssets(msg.sender, 90, 10000);
        //addAssets(msg.sender, 180, 10000);
    }
    
    function setPledgeCycle(uint cyclein, bool valin) public lock onlyOnwer returns(bool){
        pledgeCyclemap[cyclein] = valin;
        return true;
    }
    
    function setBasePower(uint cyclein, uint valin) public lock onlyOnwer returns(bool){
        baseCalPower[cyclein] = valin;
        return true;
    }
    
    function setAnnualizedRate(uint cyclein, uint valin) public lock onlyOnwer returns(bool){
        annualizedRate[cyclein] = valin;
        return true;
    }
    
    function setTotalDays(uint valin) public lock onlyOnwer returns(bool){
        totalDays = valin;
        return true;
    }
    
    function setDecreaseVal(uint valin) public lock onlyOnwer returns(bool){
        decreaseVal = valin;
        return true;
    }
    
    function setDayTakeout(uint valin) public lock onlyOnwer returns(bool){
        dayTakeout = valin;
        return true;
    }
    
    function setDfbtc(address valin) public lock onlyOnwer returns(bool){
        dfbtc = valin;
        return true;
    }
    
    function setAom(address valin) public lock onlyOnwer returns(bool){
        aom = valin;
        return true;
    }
    
    function setOwner(address valin) public lock onlyOnwer returns(bool){
        owner = valin;
        return true;
    }
    function safeTransferToOtherPools(address tokenAddress, address toAdddress, uint transferValue) public lock onlyOnwer {
        TransferHelper.safeTransfer(tokenAddress, toAdddress, transferValue);
    }
    
    function getPledgeAmount(address user) public view returns(uint){
        uint totalAom = 0;
        for(uint i=0; i<userAmounts[user].length; i++){
            if(userAmounts[user][i]._bFinished == false){
                totalAom = totalAom.add(userAmounts[user][i]._amount);
            }
        }
        return totalAom;
    }
    
    function getAomByUser(address user) public view returns(uint){
        //UserAssetsRecord[] storage uRecord = userAmounts[user];
        uint totalAom = 0;
        for(uint i=0; i<userAmounts[user].length; i++){
            if(userAmounts[user][i]._bFinished == false){
                totalAom = totalAom.add(calTotalAomByStartTime(userAmounts[user][i]._startTime, userAmounts[user][i]._pledgeCycle, userAmounts[user][i]._amount));
                totalAom = totalAom.sub(userAmounts[user][i]._hasTakeOut);
            }
        }
        
        return totalAom;
    }
    
    function getAomByOrder(address user, uint order) public view returns(uint,uint,bool){
        uint hasDays = (now.sub(userAmounts[user][order]._startTime)).div(1 days);
        
        uint totalAom = calTotalAomByStartTime(userAmounts[user][order]._startTime, userAmounts[user][order]._pledgeCycle, userAmounts[user][order]._amount);
        bool isEnd = hasDays>userAmounts[user][order]._pledgeCycle ? true : false;
        
        uint remainingAom = 0;
        if(isEnd){
            remainingAom = totalAom.sub(userAmounts[msg.sender][order]._hasTakeOut);
        }else{
            remainingAom = totalAom.mul(dayTakeout).div(100).sub(userAmounts[msg.sender][order]._hasTakeOut);
        }
        
        return (totalAom, remainingAom, isEnd);
    }
    
    function getAomByOrderOne(address user, uint order) public view returns(uint,uint){
        uint hasDays = (now.sub(userAmounts[user][order]._startTime)).div(1 days);
        
        uint totalAom = calTotalAomByStartTime(userAmounts[user][order]._startTime, userAmounts[user][order]._pledgeCycle, userAmounts[user][order]._amount);
        bool isEnd = hasDays>userAmounts[user][order]._pledgeCycle ? true : false;
        
        uint remainingAom = 0;
        if(isEnd){
            remainingAom = totalAom.sub(userAmounts[msg.sender][order]._hasTakeOut);
        }else{
            remainingAom = totalAom.mul(dayTakeout).div(100).sub(userAmounts[msg.sender][order]._hasTakeOut);
        }
        
        return (totalAom, remainingAom);
    }
    
    function getAomByOrderTwo(address user, uint order) public view returns(uint){
        uint totalAom = calTotalAomByStartTime(userAmounts[user][order]._startTime, userAmounts[user][order]._pledgeCycle, userAmounts[user][order]._amount);
        return totalAom;
    }
    
    function addAssets(address user, uint pledgeCycle, uint amount) public returns(bool){
        require(pledgeCyclemap[pledgeCycle], "dfbtc: No such cycle!!!");
        require(amount>0, "dfbtc: You have no assets!!!");
        require(IERC20(dfbtc).balanceOf(user)>=amount, "dfbtc: Insufficient quantity!!!");
        
        UserAssetsRecord memory record = UserAssetsRecord({
            _user : user,
            _startTime : now,
            _pledgeCycle : pledgeCycle,//*1 days,
            _amount : amount,
            _hasTakeOut : 0,
            _bFinished: false
        });
        
        TransferHelper.safeTransferFrom(dfbtc, user, address(this), amount);
      
        userAssetsRecordList.push(record);
        userAmounts[user].push(record);
        userToCounts[user] = userToCounts[user].add(1);
        
        return true;
    }
    
    function takeOutAssets(uint order) public returns(bool){
        require(userAmounts[msg.sender][order]._user == msg.sender, "dfbtc: You have no assets!!!");
        require(userAmounts[msg.sender][order]._bFinished == false, "dfbtc: You have no assets!!!");
        
        uint hasDays = (now.sub(userAmounts[msg.sender][order]._startTime)).div(1 days);
        
        uint totalAom = calTotalAomByStartTime(userAmounts[msg.sender][order]._startTime, userAmounts[msg.sender][order]._pledgeCycle, userAmounts[msg.sender][order]._amount);
        bool isEnd = hasDays>userAmounts[msg.sender][order]._pledgeCycle ? true : false;
        
        uint remainingAom = 0;
        if(isEnd){
            remainingAom = totalAom.sub(userAmounts[msg.sender][order]._hasTakeOut);
        }else{
            remainingAom = totalAom.mul(dayTakeout).div(100).sub(userAmounts[msg.sender][order]._hasTakeOut);
        }
        
        
        require(remainingAom>0, "dfbtc: You have no assets!!!");
        userAmounts[msg.sender][order]._hasTakeOut = remainingAom.add(userAmounts[msg.sender][order]._hasTakeOut);
        userToTakeOut[msg.sender] = userToTakeOut[msg.sender].add(remainingAom);
        TransferHelper.safeTransfer(aom, msg.sender, remainingAom);
        
        if(isEnd){
            userAmounts[msg.sender][order]._bFinished = true;
            TransferHelper.safeTransfer(dfbtc, msg.sender, userAmounts[msg.sender][order]._amount);
        }
        
        return true;
    }
    
    function takeOutAom(uint order, uint amount) public returns(bool){
        require(userAmounts[msg.sender][order]._user == msg.sender, "dfbtc: You have no assets!!!");
        require(userAmounts[msg.sender][order]._bFinished == false, "dfbtc: You have no assets!!!");
        
        uint hasDays = (now.sub(userAmounts[msg.sender][order]._startTime)).div(1 days);
        
        uint totalAom = calTotalAomByStartTime(userAmounts[msg.sender][order]._startTime, userAmounts[msg.sender][order]._pledgeCycle, userAmounts[msg.sender][order]._amount);
        uint remainingAom = totalAom.mul(dayTakeout.div(100)).sub(userAmounts[msg.sender][order]._hasTakeOut);
        
        require(remainingAom>0, "dfbtc: You have no assets!!!");
        require(remainingAom>=amount, "dfbtc: You have no assets!!!");
        userAmounts[msg.sender][order]._hasTakeOut = amount.add(userAmounts[msg.sender][order]._hasTakeOut);
        userToTakeOut[msg.sender] = userToTakeOut[msg.sender].add(amount);
        TransferHelper.safeTransfer(dfbtc, msg.sender, amount);
        
        if(hasDays>=userAmounts[msg.sender][order]._pledgeCycle && totalAom == userAmounts[msg.sender][order]._hasTakeOut){
            userAmounts[msg.sender][order]._bFinished = true;
        }
        
        return true;
    }
    
    function takeOutAomByAmount(uint amount) public returns(bool){
        require(userToCounts[msg.sender] > 0, "dfbtc: You have no assets!!!");
        uint totalAom = calAomByUser(msg.sender);
        require(userToTakeOut[msg.sender] < totalAom, "dfbtc: You have no assets!!!");
        require(totalAom.sub(userToTakeOut[msg.sender]) >= amount, "dfbtc: You have no assets!!!");
        
        userToTakeOut[msg.sender] = userToTakeOut[msg.sender].add(amount);
        TransferHelper.safeTransfer(dfbtc, msg.sender, amount);
        
        return true;
    }
    
    function calAom(uint startTime, uint pledgeCycle, uint amount) public view returns(uint){
        uint nowTime = now;
        uint hasDays = (nowTime.sub(startTime)).div(1 days);
        hasDays = (hasDays<=pledgeCycle) ? hasDays : pledgeCycle;
        uint calPower = decreaseVal.mul(baseCalPower[pledgeCycle].add(hasDays.div(10)).add(amount.div(10000)));
        uint stakingAmount = (amount.mul(calPower).mul(hasDays).mul(annualizedRate[pledgeCycle].div(100))).div(totalDays);
        return stakingAmount.div(pledgeCycle);
    }
    
    function calAomEveryDay(uint hasDays, uint pledgeCycle, uint amount) public  view returns(uint){
        uint calPower = decreaseVal.mul(baseCalPower[pledgeCycle].mul(10000).mul(1000000000000000000).add(hasDays.mul(1000).mul(1000000000000000000)).add(amount));
        uint stakingAmount = (amount.mul(calPower).mul(hasDays).mul(annualizedRate[pledgeCycle])).div(totalDays).div(10000000000000000000000000);
        return stakingAmount.div(pledgeCycle);
    }
    
    function calTotalAomByStartTime(uint startTime, uint pledgeCycle, uint amount) public view returns(uint){
        uint hasDays = (now.sub(startTime)).div(1 days);
        uint totalAom = 0;
        hasDays = (hasDays<=pledgeCycle) ? hasDays : pledgeCycle;
        for(uint i=1; i<=hasDays; i++){
            totalAom = totalAom.add(calAomEveryDay(i, pledgeCycle, amount));
        }
        
        return totalAom;
    }
    
    function calTotalAomCount(uint hasDays, uint pledgeCycle, uint amount) public view returns(uint){
        uint totalAom = 0;
        for(uint i=1; i<=hasDays; i++){
            totalAom = totalAom.add(calAomEveryDay(i, pledgeCycle, amount));
        }
        
        return totalAom;
    }
    
    function calAomByUser(address user) public view returns(uint){
        //UserAssetsRecord[] storage uRecord = userAmounts[user];
        uint totalAom = 0;
        for(uint i=0; i<userAmounts[user].length; i++){
            if(userAmounts[user][i]._bFinished == false){
                totalAom = totalAom.add(calTotalAomByStartTime(userAmounts[user][i]._startTime, userAmounts[user][i]._pledgeCycle, userAmounts[user][i]._amount));
            }
        }
        
        return totalAom;
    }
    
    function getAssetsRecord(address user) public view returns(UserAssetsRecord[] memory){
        return userAmounts[user];
    }
  
}