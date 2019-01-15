pragma solidity ^0.5.0;

interface TeamInterface {

    function isOwner() external view returns (bool);

    function isAdmin(address _sender) external view returns (bool);

    function isDev(address _sender) external view returns (bool);

}

interface ArtistInterface {

    function getAddress(bytes32 _artistID) external view returns (address payable);

    function add(bytes32 _artistID, address _address) external;

    function hasArtist(bytes32 _artistID) external view returns (bool);

    function updateAddress(bytes32 _artistID, address _address) external;

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
 * @title Works Contract
 * @dev http://www.puzzlebid.com/
 * @author PuzzleBID Game Team 
 * @dev Simon<<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="fc8a8f958e858491bccdcacfd29f9391">[email&#160;protected]</a>>
 */
contract Works {

    using SafeMath for *;

    TeamInterface private team; 
    ArtistInterface private artist; 

    constructor(address _teamAddress, address _artistAddress) public {
        require(_teamAddress != address(0) && _artistAddress != address(0));
        team = TeamInterface(_teamAddress);
        artist = ArtistInterface(_artistAddress);
    }

    function() external payable {
        revert();
    }

    event OnUpgrade(address indexed _teamAddress, address indexed _artistAddress);
    event OnAddWorks(
        bytes32 _worksID,
        bytes32 _artistID, 
        uint8 _debrisNum, 
        uint256 _price, 
        uint256 _beginTime,
        bool _isPublish
    );
    event OnInitDebris(
        bytes32 _worksID,
        uint8 _debrisNum,
        uint256 _initPrice
    );
    event OnUpdateDebris(
        bytes32 _worksID, 
        uint8 _debrisID, 
        bytes32 _unionID, 
        address indexed _sender
    );
    event OnUpdateFirstBuyer(
        bytes32 _worksID, 
        uint8 _debrisID, 
        bytes32 _unionID, 
        address indexed _sender
    );
    event OnUpdateBuyNum(bytes32 _worksID, uint8 _debrisID);
    event OnFinish(bytes32 _worksID, bytes32 _unionID, uint256 _time);
    event OnUpdatePools(bytes32 _worksID, uint256 _value);
    event OnUpdateFirstUnionIds(bytes32 _worksID, bytes32 _unionID);
    event OnUpdateSecondUnionIds(bytes32 _worksID, bytes32 _unionID);

    mapping(bytes32 => Datasets.Works) private works; 
    mapping(bytes32 => Datasets.Rule) private rules; 
    mapping(bytes32 => uint256) private pools; 
    mapping(bytes32 => mapping(uint8 => Datasets.Debris)) private debris; 
    mapping(bytes32 => bytes32[]) firstUnionID; 
    mapping(bytes32 => bytes32[]) secondUnionID; 

    modifier whenHasWorks(bytes32 _worksID) {
        require(works[_worksID].beginTime != 0);
        _;
    }

    modifier whenNotHasWorks(bytes32 _worksID) {
        require(works[_worksID].beginTime == 0);
        _;
    }

    modifier whenHasArtist(bytes32 _artistID) {
        require(artist.hasArtist(_artistID));
        _;
    }

    modifier onlyAdmin() {
        require(team.isAdmin(msg.sender));
        _;
    }

    modifier onlyDev() {
        require(team.isDev(msg.sender));
        _;
    }

    function upgrade(address _teamAddress, address _artistAddress) external onlyAdmin() {
        require(_teamAddress != address(0) && _artistAddress != address(0));
        team = TeamInterface(_teamAddress);
        artist = ArtistInterface(_artistAddress);
        emit OnUpgrade(_teamAddress, _artistAddress);
    }

    function addWorks(
        bytes32 _worksID,
        bytes32 _artistID, 
        uint8 _debrisNum, 
        uint256 _price, 
        uint256 _beginTime
    ) 
        external 
        onlyAdmin()
        whenNotHasWorks(_worksID)
        whenHasArtist(_artistID)
    {
        require(
            _debrisNum >= 2 && _debrisNum < 256 && 
            _price > 0 && _price % _debrisNum == 0 &&
            _beginTime > 0 && _beginTime > now 
        ); 

        works[_worksID] = Datasets.Works(
            _worksID, 
            _artistID, 
            _debrisNum, 
            _price.mul(1 wei),
            _beginTime, 
            0,
            false,
            bytes32(0)
        ); 

        emit OnAddWorks(
            _worksID,
            _artistID, 
            _debrisNum, 
            _price, 
            _beginTime,
            false
        ); 

        initDebris(_worksID, _price, _debrisNum);
    }

    function initDebris(bytes32 _worksID, uint256 _price, uint8 _debrisNum) private {      
        uint256 initPrice = (_price / _debrisNum).mul(1 wei);
        for(uint8 i=1; i<=_debrisNum; i++) {
            debris[_worksID][i].worksID = _worksID;
            debris[_worksID][i].initPrice = initPrice;
        }
        emit OnInitDebris(
            _worksID,
            _debrisNum,
            initPrice
        );
    }

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
        external
        onlyAdmin()
        whenHasWorks(_worksID)
    {

        require(
            _firstBuyLimit > 0 &&
            _freezeGap > 0 &&
            _protectGap > 0 &&
            _increaseRatio > 0 && 
            _discountGap > 0 &&
            _discountRatio > 0 &&
            _discountGap > _protectGap
        );

        require(
            _firstAllot[0] > 0 && _firstAllot[1] > 0 && _firstAllot[2] > 0 && 
            _againAllot[0] > 0 && _againAllot[1] > 0 && _againAllot[2] > 0 &&
            _lastAllot[0] > 0 && _lastAllot[1] > 0 && _lastAllot[2] > 0
        ); 

        rules[_worksID] = Datasets.Rule(
            _firstBuyLimit,
            _freezeGap.mul(1 seconds),
            _protectGap.mul(1 seconds),
            _increaseRatio,
            _discountGap.mul(1 seconds),    
            _discountRatio,
            _firstAllot,
            _againAllot,
            _lastAllot
        );
    }

    function publish(bytes32 _worksID, uint256 _beginTime) external onlyAdmin() {
        require(works[_worksID].beginTime != 0 && works[_worksID].isPublish == false);
        require(this.getAllot(_worksID, 0, 0) != 0);
        if(_beginTime > 0) {
            require(_beginTime > now);
            works[_worksID].beginTime = _beginTime;
        }
        works[_worksID].isPublish = true;
    }

    function close(bytes32 _worksID) external onlyAdmin() {
        works[_worksID].isPublish = false;
    }

    function getWorks(bytes32 _worksID) external view returns (uint8, uint256, uint256, uint256, bool) {
        return (
            works[_worksID].debrisNum,
            works[_worksID].price,
            works[_worksID].beginTime,
            works[_worksID].endTime,
            works[_worksID].isPublish
        );
    }

    function getDebris(bytes32 _worksID, uint8 _debrisID) external view 
        returns (uint256, address, address, bytes32, bytes32, uint256) {
        return (
            debris[_worksID][_debrisID].buyNum,
            debris[_worksID][_debrisID].firstBuyer,
            debris[_worksID][_debrisID].lastBuyer,
            debris[_worksID][_debrisID].firstUnionID,
            debris[_worksID][_debrisID].lastUnionID,
            debris[_worksID][_debrisID].lastTime
        );
    }

    function getRule(bytes32 _worksID) external view 
        returns (uint256, uint256, uint256, uint8[3] memory, uint8[3] memory, uint8[3] memory) {
        return (
            rules[_worksID].increaseRatio,
            rules[_worksID].discountGap,
            rules[_worksID].discountRatio,
            rules[_worksID].firstAllot,
            rules[_worksID].againAllot,
            rules[_worksID].lastAllot
        );
    }

    function hasWorks(bytes32 _worksID) external view returns (bool) {
        return works[_worksID].beginTime != 0;
    }

    function hasDebris(bytes32 _worksID, uint8 _debrisID) external view returns (bool) {
        return _debrisID > 0 && _debrisID <= works[_worksID].debrisNum;
    }

    function isPublish(bytes32 _worksID) external view returns (bool) {
        return works[_worksID].isPublish;
    }

    function isStart(bytes32 _worksID) external view returns (bool) {
        return works[_worksID].beginTime <= now;
    }

    function isProtect(bytes32 _worksID, uint8 _debrisID) external view returns (bool) {
        if(debris[_worksID][_debrisID].lastTime == 0) {
            return false;
        }
        uint256 protectGap = rules[_worksID].protectGap;
        return debris[_worksID][_debrisID].lastTime.add(protectGap) < now ? false : true;
    }

    function isSecond(bytes32 _worksID, uint8 _debrisID) external view returns (bool) {
        return debris[_worksID][_debrisID].buyNum > 0;
    }

    function isGameOver(bytes32 _worksID) external view returns (bool) {
        return works[_worksID].endTime != 0;
    }

    function isFinish(bytes32 _worksID, bytes32 _unionID) external view returns (bool) {
        bool finish = true; 
        uint8 i = 1;
        while(i <= works[_worksID].debrisNum) {
            if(debris[_worksID][i].lastUnionID != _unionID) {
                finish = false;
                break;
            }
            i++;
        }
        return finish;
    } 

    function hasFirstUnionIds(bytes32 _worksID, bytes32 _unionID) external view returns (bool) {
        if(0 == firstUnionID[_worksID].length) {
            return false;
        }
        bool has = false;
        for(uint256 i=0; i<firstUnionID[_worksID].length; i++) {
            if(firstUnionID[_worksID][i] == _unionID) {
                has = true;
                break;
            }
        }
        return has;
    }

    function hasSecondUnionIds(bytes32 _worksID, bytes32 _unionID) external view returns (bool) {
        if(0 == secondUnionID[_worksID].length) {
            return false;
        }
        bool has = false;
        for(uint256 i=0; i<secondUnionID[_worksID].length; i++) {
            if(secondUnionID[_worksID][i] == _unionID) {
                has = true;
                break;
            }
        }
        return has;
    }  

    function getFirstUnionIds(bytes32 _worksID) external view returns (bytes32[] memory) {
        return firstUnionID[_worksID];
    }

    function getSecondUnionIds(bytes32 _worksID) external view returns (bytes32[] memory) {
        return secondUnionID[_worksID];
    }

    function getPrice(bytes32 _worksID) external view returns (uint256) {
        return works[_worksID].price;
    }

    function getDebrisPrice(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {        
        uint256 discountGap = rules[_worksID].discountGap;
        uint256 discountRatio = rules[_worksID].discountRatio;
        uint256 increaseRatio = rules[_worksID].increaseRatio;
        uint256 lastPrice;

        if(debris[_worksID][_debrisID].buyNum > 0 && debris[_worksID][_debrisID].lastTime.add(discountGap) < now) { 

            uint256 n = (now.sub(debris[_worksID][_debrisID].lastTime.add(discountGap))) / discountGap; 
            if((now.sub(debris[_worksID][_debrisID].lastTime.add(discountGap))) % discountGap > 0) { 
                n = n.add(1);
            }
            for(uint256 i=0; i<n; i++) {
                if(0 == i) {
                    lastPrice = debris[_worksID][_debrisID].lastPrice.mul(increaseRatio).mul(discountRatio) / 10000; 
                } else {
                    lastPrice = lastPrice.mul(discountRatio) / 100;
                }
            }

        } else if (debris[_worksID][_debrisID].buyNum > 0) { 
            lastPrice = debris[_worksID][_debrisID].lastPrice.mul(increaseRatio) / 100;
        } else {
            lastPrice = debris[_worksID][_debrisID].initPrice; 
        }

        return lastPrice;
    }

    function getDebrisStatus(bytes32 _worksID, uint8 _debrisID) external view returns (uint256[4] memory, uint256, uint256, bytes32)  {
        uint256 gap = 0;
        uint256 status = 0;

        if(0 == debris[_worksID][_debrisID].buyNum) { 

        } else if(this.isProtect(_worksID, _debrisID)) { 
            gap = rules[_worksID].protectGap;
            status = 1;
        } else { 

            if(debris[_worksID][_debrisID].lastTime.add(rules[_worksID].discountGap) > now) {
                gap = rules[_worksID].discountGap; 
            } else {
                uint256 n = (now.sub(debris[_worksID][_debrisID].lastTime)) / rules[_worksID].discountGap; 
                if((now.sub(debris[_worksID][_debrisID].lastTime.add(rules[_worksID].discountGap))) % rules[_worksID].discountGap > 0) { 
                    n = n.add(1);
                }
                gap = rules[_worksID].discountGap.mul(n); 
            }
            status = 2;

        }
        uint256 price = this.getDebrisPrice(_worksID, _debrisID);
        bytes32 lastUnionID = debris[_worksID][_debrisID].lastUnionID;
        uint256[4] memory state = [status, debris[_worksID][_debrisID].lastTime, gap, now];
        return (state, price, debris[_worksID][_debrisID].buyNum, lastUnionID);
    }

    function getInitPrice(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {
        return debris[_worksID][_debrisID].initPrice;
    }

    function getLastPrice(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {
        return debris[_worksID][_debrisID].lastPrice;
    }

    function getLastBuyer(bytes32 _worksID, uint8 _debrisID) external view returns(address) {
        return debris[_worksID][_debrisID].lastBuyer;
    }

    function getLastUnionId(bytes32 _worksID, uint8 _debrisID) external view returns(bytes32) {
        return debris[_worksID][_debrisID].lastUnionID;
    }

    function getFreezeGap(bytes32 _worksID) external view returns(uint256) {
        return rules[_worksID].freezeGap;
    }

    function getFirstBuyLimit(bytes32 _worksID) external view returns(uint256) {
        return rules[_worksID].firstBuyLimit;
    }

    function getArtistId(bytes32 _worksID) external view returns(bytes32) {
        return works[_worksID].artistID;
    }

    function getDebrisNum(bytes32 _worksID) external view returns(uint8) {
        return works[_worksID].debrisNum;
    }

    function getAllot(bytes32 _worksID, uint8 _flag) external view returns(uint8[3] memory) {
        require(_flag < 3);
        if(0 == _flag) {
            return rules[_worksID].firstAllot;
        } else if(1 == _flag) {
            return rules[_worksID].againAllot;
        } else {
            return rules[_worksID].lastAllot;
        }        
    }

    function getAllot(bytes32 _worksID, uint8 _flag, uint8 _element) external view returns(uint8) {
        require(_flag < 3 && _element < 3);
        if(0 == _flag) {
            return rules[_worksID].firstAllot[_element];
        } else if(1 == _flag) {
            return rules[_worksID].againAllot[_element];
        } else {
            return rules[_worksID].lastAllot[_element];
        }        
    }

    function getPools(bytes32 _worksID) external view returns (uint256) {
        return pools[_worksID];
    }

    function getPoolsAllot(bytes32 _worksID) external view returns (uint256, uint256[3] memory, uint8[3] memory) {
        require(works[_worksID].endTime != 0); 

        uint8[3] memory lastAllot = this.getAllot(_worksID, 2); 
        uint256 finishAccount = pools[_worksID].mul(lastAllot[0]) / 100; 
        uint256 firstAccount = pools[_worksID].mul(lastAllot[1]) / 100;
        uint256 allAccount = pools[_worksID].mul(lastAllot[2]) / 100;
        uint256[3] memory account = [finishAccount, firstAccount, allAccount];   

        return (pools[_worksID], account, lastAllot);
    }

    function getStartHourglass(bytes32 _worksID) external view returns(uint256) {
        if(works[_worksID].beginTime > 0 && works[_worksID].beginTime > now ) {
            return works[_worksID].beginTime.sub(now);
        }
        return 0;
    }

    function getWorksStatus(bytes32 _worksID) external view returns (uint256, uint256, uint256, bytes32) {
        return (works[_worksID].beginTime, works[_worksID].endTime, now, works[_worksID].lastUnionID);
    }

    function getProtectHourglass(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {
        if(
            debris[_worksID][_debrisID].lastTime > 0 && 
            debris[_worksID][_debrisID].lastTime.add(rules[_worksID].protectGap) > now
        ) {
            return debris[_worksID][_debrisID].lastTime.add(rules[_worksID].protectGap).sub(now);
        }
        return 0;
    }

    function getDiscountHourglass(bytes32 _worksID, uint8 _debrisID) external view returns(uint256) {
        if(debris[_worksID][_debrisID].lastTime == 0) {
            return 0;
        }
        uint256 discountGap = rules[_worksID].discountGap;
        uint256 n = (now.sub(debris[_worksID][_debrisID].lastTime)) / discountGap; 
        if((now.sub(debris[_worksID][_debrisID].lastTime)) % discountGap > 0) { 
            n = n.add(1);
        }
        return debris[_worksID][_debrisID].lastTime.add(discountGap.mul(n)).sub(now);
    }

    function updateDebris(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address payable _sender) external onlyDev() {
        debris[_worksID][_debrisID].lastPrice = this.getDebrisPrice(_worksID, _debrisID);
        debris[_worksID][_debrisID].lastUnionID = _unionID; 
        debris[_worksID][_debrisID].lastBuyer = _sender; 
        debris[_worksID][_debrisID].lastTime = now; 
        emit OnUpdateDebris(_worksID, _debrisID, _unionID, _sender);
    }

    function updateFirstBuyer(bytes32 _worksID, uint8 _debrisID, bytes32 _unionID, address payable _sender) external onlyDev() {
        debris[_worksID][_debrisID].firstBuyer = _sender;
        debris[_worksID][_debrisID].firstUnionID = _unionID;
        emit OnUpdateFirstBuyer(_worksID, _debrisID, _unionID, _sender);
        this.updateFirstUnionIds(_worksID, _unionID);
    }

    function updateBuyNum(bytes32 _worksID, uint8 _debrisID) external onlyDev() {
        debris[_worksID][_debrisID].buyNum = debris[_worksID][_debrisID].buyNum.add(1);
        emit OnUpdateBuyNum(_worksID, _debrisID);
    }

    function finish(bytes32 _worksID, bytes32 _unionID) external onlyDev() {
        works[_worksID].endTime = now;
        works[_worksID].lastUnionID = _unionID;
        emit OnFinish(_worksID, _unionID, now);
    }

    function updatePools(bytes32 _worksID, uint256 _value) external onlyDev() {
        pools[_worksID] = pools[_worksID].add(_value);
        emit OnUpdatePools(_worksID, _value);
    }

    function updateFirstUnionIds(bytes32 _worksID, bytes32 _unionID) external onlyDev() {
        if(this.hasFirstUnionIds(_worksID, _unionID) == false) {
            firstUnionID[_worksID].push(_unionID);
            emit OnUpdateFirstUnionIds(_worksID, _unionID);
        }
    }

    function updateSecondUnionIds(bytes32 _worksID, bytes32 _unionID) external onlyDev() {
        if(this.hasSecondUnionIds(_worksID, _unionID) == false) {
            secondUnionID[_worksID].push(_unionID);
            emit OnUpdateSecondUnionIds(_worksID, _unionID);
        }
    }

 }