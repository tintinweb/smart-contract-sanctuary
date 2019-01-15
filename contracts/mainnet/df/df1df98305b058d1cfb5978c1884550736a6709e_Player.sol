pragma solidity ^0.5.0;

interface TeamInterface {

    function isOwner() external view returns (bool);

    function isAdmin(address _sender) external view returns (bool);

    function isDev(address _sender) external view returns (bool);

}

interface WorksInterface {

    function addWorks(
        bytes32 _worksID,
        bytes32 _artistID, 
        uint8 _debrisNum, 
        uint256 _price, 
        uint256 _beginTime
    ) 
        external;

    function configRule(
        bytes32 _worksID,
        uint8 _firstBuyLimit, 
        uint256 _freezeGap, 
        uint256 _protectGap, 
        uint256 _increaseRatio,
        uint256 _discountGap, 
        uint256 _discountRatio, 

        uint8[3] calldata _firstAllot, 
        uint8[3] calldata _againAllot, 
        uint8[3] calldata _lastAllot 
    ) 
        external;

    function publish(bytes32 _worksID, uint256 _beginTime) external;

    function close(bytes32 _worksID) external;

    function getWorks(bytes32 _worksID) external view returns (uint8, uint256, uint256, uint256, bool);

    function getDebris(bytes32 _worksID, uint8 _debrisID) external view 
        returns (uint256, address, address, bytes32, bytes32, uint256);

    function getRule(bytes32 _worksID) external view 
        returns (uint8, uint256, uint256, uint256, uint256, uint256, uint8[3] memory, uint8[3] memory, uint8[3] memory);

    function hasWorks(bytes32 _worksID) external view returns (bool);

    function hasDebris(bytes32 _worksID, uint8 _debrisID) external view returns (bool);

    function isPublish(bytes32 _worksID) external view returns (bool);

    function isStart(bytes32 _worksID) external view returns (bool);

    function isProtect(bytes32 _worksID, uint8 _debrisID) external view returns (bool);

    function isSecond(bytes32 _worksID, uint8 _debrisID) external view returns (bool);

    function isGameOver(bytes32 _worksID) external view returns (bool);
    
    function isFinish(bytes32 _worksID, bytes32 _unionID) external view returns (bool);

    function hasFirstUnionIds(bytes32 _worksID, bytes32 _unionID) external view returns (bool);

    function hasSecondUnionIds(bytes32 _worksID, bytes32 _unionID) external view returns (bool);

    function getFirstUnionIds(bytes32 _worksID) external view returns (bytes32[] memory);

    function getSecondUnionIds(bytes32 _worksID) external view returns (bytes32[] memory);

    function getPrice(bytes32 _worksID) external view returns (uint256);

    function getDebrisPrice(bytes32 _worksID, uint8 _debrisID) external view returns (uint256);

    function getDebrisStatus(bytes32 _worksID, uint8 _debrisID) external view returns (uint256[4] memory, uint256, bytes32);

    function getInitPrice(bytes32 _worksID, uint8 _debrisID) external view returns (uint256);

    function getLastPrice(bytes32 _worksID, uint8 _debrisID) external view returns (uint256);

    function getLastBuyer(bytes32 _worksID, uint8 _debrisID) external view returns (address payable);

    function getLastUnionId(bytes32 _worksID, uint8 _debrisID) external view returns (bytes32);

    function getFreezeGap(bytes32 _worksID) external view returns (uint256);

    function getFirstBuyLimit(bytes32 _worksID) external view returns (uint256);

    function getArtistId(bytes32 _worksID) external view returns (bytes32);

    function getDebrisNum(bytes32 _worksID) external view returns (uint8);

    function getAllot(bytes32 _worksID, uint8 _flag) external view returns (uint8[3] memory);

    function getAllot(bytes32 _worksID, uint8 _flag, uint8 _element) external view returns (uint8);

    function getPools(bytes32 _worksID) external view returns (uint256);

    function getPoolsAllot(bytes32 _worksID) external view returns (uint256, uint256[3] memory, uint8[3] memory);

    function getStartHourglass(bytes32 _worksID) external view returns (uint256);

    function getWorksStatus(bytes32 _worksID) external view returns (uint256, uint256, uint256, bytes32);

    function getProtectHourglass(bytes32 _worksID, uint8 _debrisID) external view returns (uint256);

    function getDiscountHourglass(bytes32 _worksID, uint8 _debrisID) external view returns (uint256);

    function updateDebris(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address _sender) external;

    function updateFirstBuyer(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address _sender) external;

    function updateBuyNum(bytes32 _worksID, uint8 _debrisID) external;

    function finish(bytes32 _worksID, bytes32 _unionID) external;

    function updatePools(bytes32 _worksID, uint256 _value) external;

    function updateFirstUnionIds(bytes32 _worksID, bytes32 _unionID) external;

    function updateSecondUnionIds(bytes32 _worksID, bytes32 _unionID) external;

 }

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr 
 * - changed asserts to requires with error log outputs
 * - removed div, its useless
 */
library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
    /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }

} 

library Datasets {

    struct Player {
        address[] ethAddress; 
        bytes32 referrer; 
        address payable lastAddress; 
        uint256 time;
    }

    struct MyWorks { 
        address ethAddress; 
        bytes32 worksID; 
        uint256 totalInput; 
        uint256 totalOutput; 
        uint256 time; 
    }


    struct Works {
        bytes32 worksID; 
        bytes32 artistID; 
        uint8 debrisNum; 
        uint256 price; 
        uint256 beginTime; 
        uint256 endTime;
        bool isPublish; 
        bytes32 lastUnionID;
    }

    struct Debris {
        uint8 debrisID; 
        bytes32 worksID; 
        uint256 initPrice; 
        uint256 lastPrice; 
        uint256 buyNum; 
        address payable firstBuyer; 
        address payable lastBuyer; 
        bytes32 firstUnionID; 
        bytes32 lastUnionID; 
        uint256 lastTime; 
    }
    
    struct Rule {       
        uint8 firstBuyLimit; 
        uint256 freezeGap; 
        uint256 protectGap; 
        uint256 increaseRatio;
        uint256 discountGap; 
        uint256 discountRatio; 

        uint8[3] firstAllot; 
        uint8[3] againAllot;
        uint8[3] lastAllot; 
    }

    struct PlayerCount {
        uint256 lastTime; 
        uint256 firstBuyNum; 
        uint256 firstAmount; 
        uint256 secondAmount; 
        uint256 rewardAmount;
    }

}

/**
 * @title Player Contract
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="ddabaeb4afa4a5b09decebeef3beb2b0">[email&#160;protected]</a>>
 */
contract Player {

    using SafeMath for *;

    TeamInterface private team; 
    WorksInterface private works; 
    
    constructor(address _teamAddress, address _worksAddress) public {
        require(_teamAddress != address(0) && _worksAddress != address(0));
        team = TeamInterface(_teamAddress);
        works = WorksInterface(_worksAddress);
    }

    function() external payable {
        revert();
    }

    event OnUpgrade(address indexed _teamAddress, address indexed _worksAddress);
    event OnRegister(
        address indexed _address, 
        bytes32 _unionID, 
        bytes32 _referrer, 
        uint256 time
    );
    event OnUpdateLastAddress(bytes32 _unionID, address indexed _sender);
    event OnUpdateLastTime(bytes32 _unionID, bytes32 _worksID, uint256 _time);
    event OnUpdateFirstBuyNum(bytes32 _unionID, bytes32 _worksID, uint256 _firstBuyNum);
    event OnUpdateSecondAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount);
    event OnUpdateFirstAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount);
    event OnUpdateReinvest(bytes32 _unionID, bytes32 _worksID, uint256 _amount);
    event OnUpdateRewardAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount);
    event OnUpdateMyWorks(
        bytes32 _unionID, 
        address indexed _address, 
        bytes32 _worksID, 
        uint256 _totalInput, 
        uint256 _totalOutput,
        uint256 _time
    );

    mapping(bytes32 => Datasets.Player) private playersByUnionId; 
    mapping(address => bytes32) private playersByAddress; 
    address[] private playerAddressSets; 
    bytes32[] private playersUnionIdSets; 

    mapping(bytes32 => mapping(bytes32 => Datasets.PlayerCount)) playerCount;

   mapping(bytes32 => mapping(bytes32 => Datasets.MyWorks)) myworks; 
    
    modifier onlyAdmin() {
        require(team.isAdmin(msg.sender));
        _;
    }
    
    modifier onlyDev() {
        require(team.isDev(msg.sender));
        _;
    }

    function upgrade(address _teamAddress, address _worksAddress) external onlyAdmin() {
        require(_teamAddress != address(0) && _worksAddress != address(0));
        team = TeamInterface(_teamAddress);
        works = WorksInterface(_worksAddress);
        emit OnUpgrade(_teamAddress, _worksAddress);
    }


    function hasAddress(address _address) external view returns (bool) {
        bool has = false;
        for(uint256 i=0; i<playerAddressSets.length; i++) {
            if(playerAddressSets[i] == _address) {
                has = true;
                break;
            }
        }
        return has;
    }

    function hasUnionId(bytes32 _unionID) external view returns (bool) {
        bool has = false;
        for(uint256 i=0; i<playersUnionIdSets.length; i++) {
            if(playersUnionIdSets[i] == _unionID) {
                has = true;
                break;
            }
        }
        return has;
    }

    function getInfoByUnionId(bytes32 _unionID) external view returns (address payable, bytes32, uint256) {
        return (
            playersByUnionId[_unionID].lastAddress,
            playersByUnionId[_unionID].referrer, 
            playersByUnionId[_unionID].time
        );
    }

    function getUnionIdByAddress(address _address) external view returns (bytes32) {
        return playersByAddress[_address];
    }

    function isFreeze(bytes32 _unionID, bytes32 _worksID) external view returns (bool) {
        uint256 freezeGap = works.getFreezeGap(_worksID);
        return playerCount[_unionID][_worksID].lastTime.add(freezeGap) < now ? false : true;
    }

    function getFirstBuyNum(bytes32 _unionID, bytes32 _worksID) external view returns (uint256) {
        return playerCount[_unionID][_worksID].firstBuyNum;
    }

    function getSecondAmount(bytes32 _unionID, bytes32 _worksID) external view returns (uint256) {
        return playerCount[_unionID][_worksID].secondAmount;
    }

    function getFirstAmount(bytes32 _unionID, bytes32 _worksID) external view returns (uint256) {
        return playerCount[_unionID][_worksID].firstAmount;
    }

    function getLastAddress(bytes32 _unionID) external view returns (address payable) {
        return playersByUnionId[_unionID].lastAddress;
    }

    function getRewardAmount(bytes32 _unionID, bytes32 _worksID) external view returns (uint256) {
        return playerCount[_unionID][_worksID].rewardAmount;
    }

    function getFreezeHourglass(bytes32 _unionID, bytes32 _worksID) external view returns(uint256) {
        uint256 freezeGap = works.getFreezeGap(_worksID);
        if(playerCount[_unionID][_worksID].lastTime.add(freezeGap) > now) {
            return playerCount[_unionID][_worksID].lastTime.add(freezeGap).sub(now);
        }
        return 0;
    }

    function getMyReport(bytes32 _unionID, bytes32 _worksID) external view returns (uint256, uint256, uint256) {
        uint256 currInput = 0; 
        uint256 currOutput = 0;      
        uint256 currFinishReward = 0; 
        uint8 lastAllot = works.getAllot(_worksID, 2, 0); 

        currInput = this.getFirstAmount(_unionID, _worksID).add(this.getSecondAmount(_unionID, _worksID));
        currOutput = this.getRewardAmount(_unionID, _worksID);         
        currFinishReward = this.getRewardAmount(_unionID, _worksID).add(works.getPools(_worksID).mul(lastAllot) / 100);
        return (currInput, currOutput, currFinishReward);
    }

    function getMyStatus(bytes32 _unionID, bytes32 _worksID) external view returns (uint256, uint256, uint256, uint256, uint256) {
        return (
            playerCount[_unionID][_worksID].lastTime, 
            works.getFreezeGap(_worksID), 
            now, 
            playerCount[_unionID][_worksID].firstBuyNum,
            works.getFirstBuyLimit(_worksID)
        );
    }

    function getMyWorks(bytes32 _unionID, bytes32 _worksID) external view returns (address, bytes32, uint256, uint256, uint256) {
        return (
            myworks[_unionID][_worksID].ethAddress,
            myworks[_unionID][_worksID].worksID,
            myworks[_unionID][_worksID].totalInput,
            myworks[_unionID][_worksID].totalOutput,
            myworks[_unionID][_worksID].time
        );
    }

    function isLegalPlayer(bytes32 _unionID, address _address) external view returns (bool) {
        return (this.hasUnionId(_unionID) || this.hasAddress(_address)) && playersByAddress[_address] == _unionID;
    }

    function register(bytes32 _unionID, address payable _address, bytes32 _worksID, bytes32 _referrer) external onlyDev() returns (bool) {
        require(_unionID != bytes32(0) && _address != address(0) && _worksID != bytes32(0));

        if(this.hasAddress(_address)) {
            if(playersByAddress[_address] != _unionID) {
                revert();
            } else {
                return true;
            }
        }
         
        playersByUnionId[_unionID].ethAddress.push(_address);
        if(_referrer != bytes32(0)) {
            playersByUnionId[_unionID].referrer = _referrer;
        }
        playersByUnionId[_unionID].lastAddress = _address;
        playersByUnionId[_unionID].time = now;

        playersByAddress[_address] = _unionID;

        playerAddressSets.push(_address);
        if(this.hasUnionId(_unionID) == false) {
            playersUnionIdSets.push(_unionID);
            playerCount[_unionID][_worksID] = Datasets.PlayerCount(0, 0, 0, 0, 0);
        }

        emit OnRegister(_address, _unionID, _referrer, now);

        return true;
    }

    function updateLastAddress(bytes32 _unionID, address payable _sender) external onlyDev() {
        if(playersByUnionId[_unionID].lastAddress != _sender) {
            playersByUnionId[_unionID].lastAddress = _sender;
            emit OnUpdateLastAddress(_unionID, _sender);
        }
    }

    function updateLastTime(bytes32 _unionID, bytes32 _worksID) external onlyDev() {
        playerCount[_unionID][_worksID].lastTime = now;
        emit OnUpdateLastTime(_unionID, _worksID, now);
    }

    function updateFirstBuyNum(bytes32 _unionID, bytes32 _worksID) external onlyDev() {
        playerCount[_unionID][_worksID].firstBuyNum = playerCount[_unionID][_worksID].firstBuyNum.add(1);
        emit OnUpdateFirstBuyNum(_unionID, _worksID, playerCount[_unionID][_worksID].firstBuyNum);
    }

    function updateSecondAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external onlyDev() {
        playerCount[_unionID][_worksID].secondAmount = playerCount[_unionID][_worksID].secondAmount.add(_amount);
        emit OnUpdateSecondAmount(_unionID, _worksID, _amount);
    }

    function updateFirstAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external onlyDev() {
        playerCount[_unionID][_worksID].firstAmount = playerCount[_unionID][_worksID].firstAmount.add(_amount);
        emit OnUpdateFirstAmount(_unionID, _worksID, _amount);
    }

    function updateRewardAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external onlyDev() {
        playerCount[_unionID][_worksID].rewardAmount = playerCount[_unionID][_worksID].rewardAmount.add(_amount);
        emit OnUpdateRewardAmount(_unionID, _worksID, _amount);
    }    

    function updateMyWorks(
        bytes32 _unionID, 
        address _address, 
        bytes32 _worksID, 
        uint256 _totalInput, 
        uint256 _totalOutput
    ) external onlyDev() {
        myworks[_unionID][_worksID] = Datasets.MyWorks(_address, _worksID, _totalInput, _totalOutput, now);
        emit OnUpdateMyWorks(_unionID, _address, _worksID, _totalInput, _totalOutput, now);
    }

}