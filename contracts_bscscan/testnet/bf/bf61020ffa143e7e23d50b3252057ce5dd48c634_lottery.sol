/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
/**
SPDX-License-Identifier: UNLICENSED
**/

contract  lottery { 
    struct History {
        address add;
        string name;
        uint32 prize;
        uint64 timestamp;
    }
    struct RoundHistory {
        mapping(string=>bool) surpriseHistory;
    }
    
    uint32 sInitPool;
    string[] sAuthers;
    uint64 sStartTime = 1618383755;
    uint64 sTimeInterval = 300;
    address sBossAddr;
    address sCreater;
    string sEmptyStr = "";
    uint32 sRoundPool = 2000;
    uint32 sLastRoundCountRate = 5;
    
    uint32 mLastRoundCount = 10;
    uint32 mPrizePool;
    uint32 mPeopleCount;
    uint mRound;
    RoundHistory[] mRoundHistory;
    mapping(address=>string) mCorrespondenceAddr;
    History[][] mSurpriseHistory;
    bool mIsStart = false;
    
    constructor () {
        sCreater = msg.sender;
    }
    
    function Login(string memory name) public returns(bool hasAuth) {
        hasAuth = false;
        uint autherLength = sAuthers.length;
        for(uint i = 0;i<autherLength;i++){
            if(keccak256(abi.encode(name)) == keccak256(abi.encode(sAuthers[i]))){
                hasAuth = true;
                break;
            }
        }
        if (hasAuth){
            mCorrespondenceAddr[msg.sender] = name;
        }
    }
    
    function GetAuth()public view returns(bool boss,bool start){
        boss = sBossAddr == msg.sender;
        start = mIsStart;
    }
    
    function Start(uint32 amount)public {
        require(!mIsStart,"Already started!");
        require(msg.sender == sBossAddr,"must be boss addr");
        require(sInitPool == 0 ,"Already initialized!");
        require(amount > sRoundPool * 4 ,"amount is too small!");
        sInitPool =  amount;
        mIsStart = true;
    }
    
    function AuthVerification()public view returns(bool auth,bool end){
        string memory name = mCorrespondenceAddr[msg.sender];
        if (keccak256(abi.encode(name)) == keccak256(abi.encode(sEmptyStr))){
            return (false,false);
        }
        if (uint64(block.timestamp) <= sStartTime) {
            return (false,false);
        }
        if (!mIsStart) {
            return (false,false);
        }
        uint roundNow = mRound;
        while (sStartTime + uint64(sTimeInterval * mRound)  < uint64(block.timestamp) && roundNow < 5){
            roundNow = roundNow + 1;
        }
        if (mRound != 0 && mRoundHistory.length >= roundNow) {
            bool isDrawn = mRoundHistory[roundNow-1].surpriseHistory[name];
            if (isDrawn && roundNow == 5) {
                return (false,true);
            }else{
                return (!isDrawn,false);
            }
        }
        return (true,false);
    }
    
    function GetCountDownTime()public view returns(uint64 timeLeft,uint rounds){
        uint64 timestamp = uint64(block.timestamp);
        if(timestamp < sStartTime){
            rounds = 1;
            timeLeft = sStartTime - timestamp;
            return (timeLeft,rounds);
        }
        rounds = (timestamp - sStartTime) / sTimeInterval + 2;
        if (rounds > 5){
             rounds = 5;
             timeLeft = 0;
        }else{
            timeLeft = sTimeInterval - (timestamp - sStartTime) % sTimeInterval;
        }
    }
    
    function GetPrizePool() public view returns(uint32 pool,uint rounds){
        uint64 timestamp = uint64(block.timestamp);
        if(timestamp <= sStartTime){
            pool = sRoundPool;
            rounds =1 ;
            return (pool,rounds);
            
        }
        if (sStartTime + uint64(sTimeInterval * mRound)  < timestamp && mRound < 5){
            rounds = mRound + 1;
            if (rounds == 5) {
                pool = mPrizePool + sInitPool - sRoundPool * 4;
            }else{
                pool = mPrizePool + sRoundPool;
            }
        }else{
            pool = mPrizePool;
            rounds = mRound;  
        }
    }
    
    function GetSurpriseHistory()public view returns(History[][] memory){
        return mSurpriseHistory;
    }
    
    function Surprise() public returns(uint32 get,string memory rname,address ruser,uint round){
        require(mIsStart,"lottery not start!");
        while (mRound < 5 && sStartTime + uint64(sTimeInterval * mRound) < uint64(block.timestamp)){
            startNewRound();
        }
        require(mPeopleCount > 0,"new round not start!");
        require(uint64(block.timestamp) > sStartTime,"first round not start!");
        address user = msg.sender;
        string memory name = mCorrespondenceAddr[user];
        bool isNotEmpty = keccak256(abi.encode(name)) != keccak256(abi.encode(sEmptyStr));
        require(isNotEmpty,"Unauthorized address");
        require(mPrizePool > 0,"prizePool is empty");
        
        if (mRoundHistory.length >= mRound) {
            require(!mRoundHistory[mRound-1].surpriseHistory[name],"User has already drawn a lottery!");
        }
        
        uint32 random = uint32(uint256(msg.sender) * uint256(block.number) * uint256(block.timestamp));
        
        if (mRound == 5) {
            uint32 isLucky = random % sLastRoundCountRate;
            if ((isLucky == 0 || mPeopleCount == mLastRoundCount) && mPrizePool > 0) {
                uint32 tempPool = mPrizePool * 2 / mLastRoundCount;
                if (tempPool > mPrizePool) {
                    tempPool = mPrizePool;
                }
                get =  random % tempPool;
                if (get == 0) {
                    get = 1;
                }
                mPrizePool = mPrizePool - get;
                mLastRoundCount = mLastRoundCount - 1;
                if (mPrizePool < mLastRoundCount){
                    uint32 temp = mLastRoundCount - mPrizePool;
                    mPrizePool = mLastRoundCount;
                    if (get > temp) {
                        get = get - temp;
                    }else{
                        get = 0;
                    }
                }
            }else{
                get = 0;
            }
            mPeopleCount = mPeopleCount -1;
            if (mPeopleCount == 0 || mLastRoundCount == 0){
                get = get + mPrizePool;
                mPrizePool = 0;
            }
        }else{
            uint32 tempPool = mPrizePool * 3 / 2 / mPeopleCount;
            uint32 distribute = random % 10;
            if (distribute == 0 || distribute == 1) {
                tempPool = tempPool / 10;
                if (tempPool == 0){
                    tempPool = 1;
                }
            }
            if (distribute == 9){
                tempPool = tempPool * 4;
            }
        
            if (tempPool > mPrizePool) {
                tempPool = mPrizePool;
            }
        
            get = random % tempPool;
            if (get == 0) {
                get = 1;
            }
            mPrizePool = mPrizePool - get;
            mPeopleCount = mPeopleCount -1;
            if (mPrizePool < mPeopleCount){
                uint32 temp = mPeopleCount - mPrizePool;
                mPrizePool = mPeopleCount;
                if (get > temp) {
                    get = get - temp;
                }else{
                    get = 0;
                }
            }
            if (mPeopleCount == 0){
                get = get + mPrizePool;
                mPrizePool = 0;
            }
        }
        
        while (mRoundHistory.length < mRound) {
            mRoundHistory.push();
            mSurpriseHistory.push();
        }
        mRoundHistory[mRound-1].surpriseHistory[name] = true;
        History storage history = mSurpriseHistory[mRound-1].push();
        history.add = user;
        history.prize = get;
        history.name = name;
        history.timestamp = uint64(block.timestamp);
        round = mRound;
        rname = name;
        ruser = user;
    }
    
    function startNewRound()private{
        mRound = mRound + 1;
        if (mRound == 5) {
            mPrizePool = mPrizePool + sInitPool - sRoundPool * 4;
        }else{
            mPrizePool = mPrizePool + sRoundPool;
        }
        mPeopleCount = uint32(sAuthers.length);
    }
    
    function InitAuth (string[] memory auth,address boss,uint64 start,uint64 interval,uint32 roundPool,uint32 lastRoundCount)public {
        require(sCreater == msg.sender,"invaild init!");
        require (sAuthers.length == 0,"authers initialized!");
        require (start > sStartTime,"start too old!");
        require (interval < 864000,"interval too big!");
        require (interval > 10,"interval too small!");
        require (auth.length > 0,"authers is empty!");
        require (roundPool > 0,"roundPool is empty!");
        require (lastRoundCount > 0,"roundPool is empty!");
        sAuthers = auth;
        mPeopleCount = uint32(auth.length);
        mLastRoundCount = lastRoundCount;
        sBossAddr = boss;
        sStartTime = start;
        sTimeInterval = interval;
        sRoundPool = roundPool;
        sLastRoundCountRate = mPeopleCount / mLastRoundCount;
    }
}