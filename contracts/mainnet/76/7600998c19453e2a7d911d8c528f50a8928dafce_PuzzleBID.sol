//
pragma solidity ^0.5.0;

interface TeamInterface {

    function isOwner() external view returns (bool);

    function isAdmin(address _sender) external view returns (bool);

    function isDev(address _sender) external view returns (bool);

}

interface PlatformInterface {

    function getAllTurnover() external view returns (uint256);

    function getTurnover(bytes32 _worksID) external view returns (uint256);

    function updateAllTurnover(uint256 _amount) external;

    function updateTurnover(bytes32 _worksID, uint256 _amount) external;

    function updateFoundAddress(address _foundation) external;

    function deposit(bytes32 _worksID) external payable;

    function transferTo(address _receiver, uint256 _amount) external;

    function getFoundAddress() external view returns (address payable);

    function balances() external view returns (uint256);

}

interface ArtistInterface {

    function getAddress(bytes32 _artistID) external view returns (address payable);

    function add(bytes32 _artistID, address _address) external;

    function hasArtist(bytes32 _artistID) external view returns (bool);

    function updateAddress(bytes32 _artistID, address _address) external;

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

interface PlayerInterface {

    function hasAddress(address _address) external view returns (bool);

    function hasUnionId(bytes32 _unionID) external view returns (bool);

    function getInfoByUnionId(bytes32 _unionID) external view returns (address payable, bytes32, uint256);

    function getUnionIdByAddress(address _address) external view returns (bytes32);

    function isFreeze(bytes32 _unionID, bytes32 _worksID) external view returns (bool);

    function getFirstBuyNum(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    function getSecondAmount(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    function getFirstAmount(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    function getLastAddress(bytes32 _unionID) external view returns (address payable);

    function getRewardAmount(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    function getFreezeHourglass(bytes32 _unionID, bytes32 _worksID) external view returns (uint256);

    function getMyReport(bytes32 _unionID, bytes32 _worksID) external view returns (uint256, uint256, uint256);

    function getMyStatus(bytes32 _unionID, bytes32 _worksID) external view returns (uint256, uint256, uint256, uint256, uint256);

    function getMyWorks(bytes32 _unionID, bytes32 _worksID) external view returns (address, bytes32, uint256, uint256, uint256);

    function isLegalPlayer(bytes32 _unionID, address _address) external view returns (bool);

    function register(bytes32 _unionID, address _address, bytes32 _worksID, bytes32 _referrer) external returns (bool);

    function updateLastAddress(bytes32 _unionID, address payable _sender) external;

    function updateLastTime(bytes32 _unionID, bytes32 _worksID) external;

    function updateFirstBuyNum(bytes32 _unionID, bytes32 _worksID) external;

    function updateSecondAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external;

    function updateFirstAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external;

    function updateRewardAmount(bytes32 _unionID, bytes32 _worksID, uint256 _amount) external;

    function updateMyWorks(
        bytes32 _unionID, 
        address _address, 
        bytes32 _worksID, 
        uint256 _totalInput, 
        uint256 _totalOutput
    ) external;

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
 * @title PuzzleBID Game Main Contract
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c4b2b7adb6bdbca984f5f2f7eaa7aba9">[email&#160;protected]</a>>
 */
contract PuzzleBID {

    using SafeMath for *;

    string constant public name = "PuzzleBID Game";
    string constant public symbol = "PZB";

    TeamInterface private team; 
    PlatformInterface private platform; 
    ArtistInterface private artist; 
    WorksInterface private works; 
    PlayerInterface private player; 
    
    constructor(
        address _teamAddress,
        address _platformAddress,
        address _artistAddress,
        address _worksAddress,
        address _playerAddress
    ) public {
        require(
            _teamAddress != address(0) &&
            _platformAddress != address(0) &&
            _artistAddress != address(0) &&
            _worksAddress != address(0) &&
            _playerAddress != address(0)
        );
        team = TeamInterface(_teamAddress);
        platform = PlatformInterface(_platformAddress);
        artist = ArtistInterface(_artistAddress);
        works = WorksInterface(_worksAddress);
        player = PlayerInterface(_playerAddress);
    }  

    function() external payable {
        revert();
    }

    event OnUpgrade(
        address indexed _teamAddress,
        address indexed _platformAddress,
        address indexed _artistAddress,
        address _worksAddress,
        address _playerAddress
    );

    modifier isHuman() {
        address _address = msg.sender;
        uint256 _size;

        assembly {_size := extcodesize(_address)}
        require(_size == 0, "sorry humans only");
        _;
    }

    modifier checkPlay(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID) {
        require(msg.value > 0);

        require(works.hasWorks(_worksID)); 
        require(works.hasDebris(_worksID, _debrisID)); 
        require(works.isGameOver(_worksID) == false);
        require(works.isPublish(_worksID) && works.isStart(_worksID));
        require(works.isProtect(_worksID, _debrisID) == false);
         
        require(player.isFreeze(_unionID, _worksID) == false); 
        if(player.getFirstBuyNum(_unionID, _worksID).add(1) > works.getFirstBuyLimit(_worksID)) {
            require(works.isSecond(_worksID, _debrisID));
        }      
        require(msg.value >= works.getDebrisPrice(_worksID, _debrisID));
        _;
    } 
       
    modifier onlyAdmin() {
        require(team.isAdmin(msg.sender));
        _;
    }
    
    function upgrade(
        address _teamAddress,
        address _platformAddress,
        address _artistAddress,
        address _worksAddress,
        address _playerAddress
    ) external onlyAdmin() {
        require(
            _teamAddress != address(0) &&
            _platformAddress != address(0) &&
            _artistAddress != address(0) &&
            _worksAddress != address(0) &&
            _playerAddress != address(0)
        );
        team = TeamInterface(_teamAddress);
        platform = PlatformInterface(_platformAddress);
        artist = ArtistInterface(_artistAddress);
        works = WorksInterface(_worksAddress);
        player = PlayerInterface(_playerAddress);
        emit OnUpgrade(_teamAddress, _platformAddress, _artistAddress, _worksAddress, _playerAddress);
    }   

    function startPlay(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, bytes32 _referrer) 
        isHuman()
        checkPlay(_worksID, _debrisID, _unionID)
        external
        payable
    {
        player.register(_unionID, msg.sender, _worksID, _referrer); 

        uint256 lastPrice = works.getLastPrice(_worksID, _debrisID);

        bytes32 lastUnionID = works.getLastUnionId(_worksID, _debrisID);

        works.updateDebris(_worksID, _debrisID, _unionID, msg.sender); 

        player.updateLastTime(_unionID, _worksID); 
        
        platform.updateTurnover(_worksID, msg.value); 

        platform.updateAllTurnover(msg.value); 
        
        if(works.isSecond(_worksID, _debrisID)) {
            secondPlay(_worksID, _debrisID, _unionID, lastUnionID, lastPrice);            
        } else {
            works.updateBuyNum(_worksID, _debrisID);
            firstPlay(_worksID, _debrisID, _unionID);       
        }

        if(works.isFinish(_worksID, _unionID)) {
            works.finish(_worksID, _unionID); 
            finishGame(_worksID);
            collectWorks(_worksID, _unionID); 
        }

    }

    function firstPlay(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID) private {    
        works.updateFirstBuyer(_worksID, _debrisID, _unionID, msg.sender);    
        player.updateFirstBuyNum(_unionID, _worksID); 
        player.updateFirstAmount(_unionID, _worksID, msg.value); 

        uint8[3] memory firstAllot = works.getAllot(_worksID, 0); 
        artist.getAddress(works.getArtistId(_worksID)).transfer(msg.value.mul(firstAllot[0]) / 100); 
        platform.getFoundAddress().transfer(msg.value.mul(firstAllot[1]) / 100); 

        works.updatePools(_worksID, msg.value.mul(firstAllot[2]) / 100); 
        platform.deposit.value(msg.value.mul(firstAllot[2]) / 100)(_worksID); 

    }

    function secondPlay(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, bytes32 _oldUnionID, uint256 _oldPrice) private {

        if(0 == player.getSecondAmount(_unionID, _worksID)) {
            works.updateSecondUnionIds(_worksID, _unionID);
        }

        player.updateSecondAmount(_unionID, _worksID, msg.value);

        uint8[3] memory againAllot = works.getAllot(_worksID, 1);
        uint256 lastPrice = works.getLastPrice(_worksID, _debrisID); 
        uint256 commission = lastPrice.mul(againAllot[1]) / 100;
        platform.getFoundAddress().transfer(commission); 

        lastPrice = lastPrice.sub(commission); 

        if(lastPrice > _oldPrice) {
            uint256 overflow = lastPrice.sub(_oldPrice); 
            artist.getAddress(works.getArtistId(_worksID)).transfer(overflow.mul(againAllot[0]) / 100); 
            works.updatePools(_worksID, overflow.mul(againAllot[2]) / 100); 
            platform.deposit.value(overflow.mul(againAllot[2]) / 100)(_worksID); 
            player.getLastAddress(_oldUnionID).transfer(
                lastPrice.sub(overflow.mul(againAllot[0]) / 100)                
                .sub(overflow.mul(againAllot[2]) / 100)
            ); 
        } else { 
            player.getLastAddress(_oldUnionID).transfer(lastPrice);
        }

    }

    function finishGame(bytes32 _worksID) private {              
        uint8 lastAllot = works.getAllot(_worksID, 2, 0);
        platform.transferTo(msg.sender, works.getPools(_worksID).mul(lastAllot) / 100);
        firstSend(_worksID); 
        secondSend(_worksID); 
    }

    function collectWorks(bytes32 _worksID, bytes32 _unionID) private {
        player.updateMyWorks(_unionID, msg.sender, _worksID, 0, 0);
    }
    
    function firstSend(bytes32 _worksID) private {
        uint8 i;
        bytes32[] memory tmpFirstUnionId = works.getFirstUnionIds(_worksID); 
        address tmpAddress; 
        uint256 tmpAmount;
        uint8 lastAllot = works.getAllot(_worksID, 2, 1);
        for(i=0; i<tmpFirstUnionId.length; i++) {
            tmpAddress = player.getLastAddress(tmpFirstUnionId[i]);
            tmpAmount = player.getFirstAmount(tmpFirstUnionId[i], _worksID);
            tmpAmount = works.getPools(_worksID).mul(lastAllot).mul(tmpAmount) / 100 / works.getPrice(_worksID);
            platform.transferTo(tmpAddress, tmpAmount); 
        }
    }

    function secondSend(bytes32 _worksID) private {
        uint8 i;
        bytes32[] memory tmpSecondUnionId = works.getSecondUnionIds(_worksID); 
        address tmpAddress; 
        uint256 tmpAmount;
        uint8 lastAllot = works.getAllot(_worksID, 2, 2);
        for(i=0; i<tmpSecondUnionId.length; i++) {
            tmpAddress = player.getLastAddress(tmpSecondUnionId[i]);
            tmpAmount = player.getSecondAmount(tmpSecondUnionId[i], _worksID);
            tmpAmount = works.getPools(_worksID).mul(lastAllot).mul(tmpAmount) / 100 / (platform.getTurnover(_worksID).sub(works.getPrice(_worksID)));
            platform.transferTo(tmpAddress, tmpAmount); 
        }
    }

    function getNowTime() external view returns (uint256) {
        return now;
    }

 }