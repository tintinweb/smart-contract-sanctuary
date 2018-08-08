pragma solidity ^0.4.18;

// File: contracts\Auction.sol

/**
 * @title 竞拍接口
 */
contract Auction {
    function bid() public payable returns (bool);
    function end() public returns (bool);

    event AuctionBid(address indexed from, uint256 value);
}

// File: contracts\Base.sol

library Base {
    struct NTVUConfig {
        uint bidStartValue;
        int bidStartTime;
        int bidEndTime;

        uint tvUseStartTime;
        uint tvUseEndTime;

        bool isPrivate;
        bool special;
    }
}

// File: contracts\ownership\Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

// File: contracts\util\SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts\token\ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts\token\BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

// File: contracts\util\StringUtils.sol

library StringUtils {
    function uintToString(uint v) internal pure returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }

        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }

        str = string(s);
    }

    function concat(string _base, string _value) internal pure returns (string) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i=0; i<_baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for(i=0; i<_valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    function bytesToBytes32(bytes memory source) internal pure returns (bytes32 result) {
        require(source.length <= 32);

        if (source.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function toBytes96(string memory text) internal pure returns (bytes32, bytes32, bytes32, uint8) {
        bytes memory temp = bytes(text);
        len = uint8(temp.length);
        require(len <= 96);

        uint8 i=0;
        uint8 j=0;
        uint8 k=0;

        string memory _b1 = new string(32);
        bytes memory b1 = bytes(_b1);

        string memory _b2 = new string(32);
        bytes memory b2 = bytes(_b2);

        string memory _b3 = new string(32);
        bytes memory b3 = bytes(_b3);

        uint8 len;

        for(i=0; i<len; i++) {
            k = i / 32;
            j = i % 32;

            if (k == 0) {
                b1[j] = temp[i];
            } else if(k == 1) {
                b2[j] = temp[i];
            } else if(k == 2) {
                b3[j] = temp[i];
            } 
        }

        return (bytesToBytes32(b1), bytesToBytes32(b2), bytesToBytes32(b3), len);
    }

    function fromBytes96(bytes32 b1, bytes32 b2, bytes32 b3, uint8 len) internal pure returns (string) {
        require(len <= 96);
        string memory _tmpValue = new string(len);
        bytes memory temp = bytes(_tmpValue);

        uint8 i;
        uint8 j = 0;

        for(i=0; i<32; i++) {
            if (j >= len) break;
            temp[j++] = b1[i];
        }

        for(i=0; i<32; i++) {
            if (j >= len) break;
            temp[j++] = b2[i];
        }

        for(i=0; i<32; i++) {
            if (j >= len) break;
            temp[j++] = b3[i];
        }

        return string(temp);
    }
}

// File: contracts\NTVUToken.sol

/**
 * 链上真心话时段币
 */
contract NTVUToken is BasicToken, Ownable, Auction {
    string public name;
    string public symbol = "FOT";

    uint8 public number = 0;
    uint8 public decimals = 0;
    uint public INITIAL_SUPPLY = 1;

    uint public bidStartValue;
    uint public bidStartTime;
    uint public bidEndTime;

    uint public tvUseStartTime;
    uint public tvUseEndTime;

    bool public isPrivate = false;

    uint public maxBidValue;
    address public maxBidAccount;

    bool internal auctionEnded = false;

    string public text; // 用户配置文本
    string public auditedText; // 审核通过的文本
    string public defaultText; // 默认文本
    uint8 public auditStatus = 0; // 0:未审核；1:审核通过；2:审核不通过

    uint32 public bidCount;
    uint32 public auctorCount;

    mapping(address => bool) acutors;

    address public ethSaver; // 竞拍所得ETH保管者

    /**
     * 时段币合约构造函数
     *
     * 拍卖期间如有更高出价，前一手出价者的以太坊自动退回其钱包
     *
     * @param _number 时段币的序号，从0开始
     * @param _bidStartValue 起拍价，单位 wei
     * @param _bidStartTime 起拍/私募开始时间，单位s
     * @param _bidEndTime 起拍/私募结束时间，单位s
     * @param _tvUseStartTime 时段币文本开始播放时间
     * @param _tvUseEndTime 时段币文本结束播放时间
     * @param _isPrivate 是否为私募
     * @param _defaultText 默认文本
     * @param _ethSaver 竞拍所得保管着
     */
    function NTVUToken(uint8 _number, uint _bidStartValue, uint _bidStartTime, uint _bidEndTime, uint _tvUseStartTime, uint _tvUseEndTime, bool _isPrivate, string _defaultText, address _ethSaver) public {
        number = _number;

        if (_number + 1 < 10) {
            symbol = StringUtils.concat(symbol, StringUtils.concat("0", StringUtils.uintToString(_number + 1)));
        } else {
            symbol = StringUtils.concat(symbol, StringUtils.uintToString(_number + 1));
        }

        name = symbol;
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;

        bidStartValue = _bidStartValue;
        bidStartTime = _bidStartTime;
        bidEndTime = _bidEndTime;

        tvUseStartTime = _tvUseStartTime;
        tvUseEndTime = _tvUseEndTime;

        isPrivate = _isPrivate;

        defaultText = _defaultText;

        ethSaver = _ethSaver;
    }

    /**
     * 竞拍出价
     *
     * 拍卖期间如有更高出价，前一手出价者的以太坊自动退回其钱包
     */
    function bid() public payable returns (bool) {
        require(now >= bidStartTime); // 竞拍开始时间到后才能竞拍
        require(now < bidEndTime); // 竞拍截止时间到后不能再竞拍
        require(msg.value >= bidStartValue); // 拍卖金额需要大于起拍价
        require(msg.value >= maxBidValue + 0.05 ether); // 最低0.05ETH加价
        require(!isPrivate || (isPrivate && maxBidAccount == address(0))); // 竞拍或者私募第一次出价

        // 如果上次有人出价，将上次出价的ETH退还给他
        if (maxBidAccount != address(0)) {
            maxBidAccount.transfer(maxBidValue);
        } 
        
        maxBidAccount = msg.sender;
        maxBidValue = msg.value;
        AuctionBid(maxBidAccount, maxBidValue); // 发出有人出价事件

        // 统计出价次数
        bidCount++;

        // 统计出价人数
        bool bided = acutors[msg.sender];
        if (!bided) {
            auctorCount++;
            acutors[msg.sender] = true;
        }
    }

    /**
     * 竞拍结束
     *
     * 拍卖结束后，系统确认交易，出价最高者获得该时段Token。
     */
    function end() public returns (bool) {
        require(!auctionEnded); // 已经结束竞拍了不能再结束
        require((now >= bidEndTime) || (isPrivate && maxBidAccount != address(0))); // 普通竞拍拍卖结束后才可以结束竞拍，私募只要出过价就可以结束竞拍
   
        // 如果有人出价，将时段代币转给出价最高的人
        if (maxBidAccount != address(0)) {
            address _from = owner;
            address _to = maxBidAccount;
            uint _value = INITIAL_SUPPLY;

            // 将时段币转给出价最高的人
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(_from, _to, _value); // 通知出价最高的人收到时段币了

            //将时段币中ETH转给ethSaver
            ethSaver.transfer(this.balance);
        }

        auctionEnded = true;
    }

    /**
     * 配置上链文本
     *
     * 购得时段后（包含拍卖和私募），可以设置时段文本
     * 每时段文字接受中文30字以内（含标点和空格），多出字符不显示。
     * 审核截止时间是，每个时段播出前30分钟
     */
    function setText(string _text) public {
        require(INITIAL_SUPPLY == balances[msg.sender]); // 拥有时段币的人可以设置文本
        require(bytes(_text).length > 0 && bytes(_text).length <= 90); // 汉字使用UTF8编码，1个汉字最多占用3个字节，所以最多写90个字节的字
        require(now < tvUseStartTime - 30 minutes); // 开播前30分钟不能再设置文本

        text = _text;
    }

    function getTextBytes96() public view returns(bytes32, bytes32, bytes32, uint8) {
        return StringUtils.toBytes96(text);
    }

    /**
     * 审核文本
     */
    function auditText(uint8 _status, string _text) external onlyOwner {
        require((now >= tvUseStartTime - 30 minutes) && (now < tvUseEndTime)); // 时段播出前30分钟为审核时间，截止到时段播出结束时间
        auditStatus = _status;

        if (_status == 2) { // 审核失败，更新审核文本
            auditedText = _text;
        } else if (_status == 1) { // 审核通过使用用户设置的文本
            auditedText = text; 
        }
    }

    /**
     * 获取显示文本
     */
    function getShowText() public view returns(string) {
        if (auditStatus == 1 || auditStatus == 2) { // 审核过了
            return auditedText;
        } else { // 没有审核，显示默认文本
            return defaultText;
        }
    }

    function getShowTextBytes96() public view returns(bytes32, bytes32, bytes32, uint8) {
        return StringUtils.toBytes96(getShowText());
    }

    /**
     * 转账代币
     *
     * 获得时段后，时段播出前，不可以转卖。时段播出后，可以作为纪念币转卖
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(now >= tvUseEndTime); // 时段播出后，可以转卖。

        super.transfer(_to, _value);
    }

    /**
     * 获取时段币状态信息
     *
     */
    function getInfo() public view returns(
        string _symbol,
        string _name,
        uint _bidStartValue, 
        uint _bidStartTime, 
        uint _bidEndTime, 
        uint _tvUseStartTime,
        uint _tvUseEndTime,
        bool _isPrivate
        ) {
        _symbol = symbol;
        _name = name;

        _bidStartValue = bidStartValue;
        _bidStartTime = bidStartTime;
        _bidEndTime = bidEndTime;

        _tvUseStartTime = tvUseStartTime;
        _tvUseEndTime = tvUseEndTime;

        _isPrivate = isPrivate;
    }

    /**
     * 获取时段币可变状态信息
     *
     */
    function getMutalbeInfo() public view returns(
        uint _maxBidValue,
        address _maxBidAccount,
        bool _auctionEnded,
        string _text,
        uint8 _auditStatus,
        uint8 _number,
        string _auditedText,
        uint32 _bidCount,
        uint32 _auctorCount
        ) {
        _maxBidValue = maxBidValue;
        _maxBidAccount = maxBidAccount;

        _auctionEnded = auctionEnded;

        _text = text;
        _auditStatus = auditStatus;

        _number = number;
        _auditedText = auditedText;

        _bidCount = bidCount;
        _auctorCount = auctorCount;
    }

    /**
     * 提取以太坊到ethSaver
     */
    function reclaimEther() external onlyOwner {
        require((now > bidEndTime) || (isPrivate && maxBidAccount != address(0))); // 普通竞拍拍卖结束后或者私募完成后，可以提币到ethSaver。
        ethSaver.transfer(this.balance);
    }

    /**
     * 默认给合约转以太坊就是出价
     */
    function() payable public {
        bid(); // 出价
    }
}

// File: contracts\NTVToken.sol

/**
 * 链上真心话合约
 */
contract NTVToken is Ownable {
    using SafeMath for uint256;

    uint8 public MAX_TIME_RANGE_COUNT = 66; // 最多发行66个时段代币

    bool public isRunning; // 是否启动运行

    uint public onlineTime; // 上线时间，第一时段上电视的时间
    uint8 public totalTimeRange; // 当前已经释放的总的时段数
    mapping(uint => address) internal timeRanges; // 每个时段的合约地址，编号从0开始

    string public defaultText = "浪花有意千里雪，桃花无言一队春。"; // 忘记审核使用的默认文本

    mapping(uint8 => Base.NTVUConfig) internal dayConfigs; // 每天时段配置
    mapping(uint8 => Base.NTVUConfig) internal specialConfigs; // 特殊时段配置

    address public ethSaver; // 竞拍所得ETH保管者

    event OnTV(address indexed ntvu, address indexed winer, string text); // 文本上电视

    /**
     * 佛系电视合约构造函数
     */
    function NTVToken() public {}

    /**
     * 启动区块链电视
     *
     * @param _onlineTime 区块链电视上线时间，必须为整点，例如 2018-03-26 00:00:00
     * @param _ethSaver 竞拍所得ETH保管者
     */
    function startup(uint256 _onlineTime, address _ethSaver) public onlyOwner {
        require(!isRunning); // 只能上线一次，上线后不能停止
        require((_onlineTime - 57600) % 1 days == 0); // 上线时间只能是整天时间，57600为北京时间的&#39;1970/1/2 0:0:0&#39;
        require(_onlineTime >= now); // 上线时间需要大于当前时间
        require(_ethSaver != address(0));

        onlineTime = _onlineTime;
        ethSaver = _ethSaver;

        isRunning = true;

        // ---------------------------
        // 每天的时段配置，共6个时段
        //
        // 通用规则：
        // 1、首拍后，每天18:30-22:00为竞拍时间
        // ---------------------------
        uint8[6] memory tvUseStartTimes = [0, 10, 12, 18, 20, 22]; // 电视使用开始时段
        uint8[6] memory tvUseEndTimes = [2, 12, 14, 20, 22, 24]; // 电视使用结束时段

        for (uint8 i=0; i<6; i++) {
            dayConfigs[i].bidStartValue = 0.1 ether; // 正常起拍价0.1ETH
            dayConfigs[i].bidStartTime = 18 hours + 30 minutes - 1 days; // 一天前晚上 18:30起拍
            dayConfigs[i].bidEndTime = 22 hours - 1 days; // 一天前晚上 22:00 结束拍卖

            dayConfigs[i].tvUseStartTime = uint(tvUseStartTimes[i]) * 1 hours;
            dayConfigs[i].tvUseEndTime = uint(tvUseEndTimes[i]) * 1 hours;

            dayConfigs[i].isPrivate = false; // 正常都是竞拍，非私募
        }

        // ---------------------------
        // 特殊时段配置
        // ---------------------------

        // 首拍，第1天的6个时段都是首拍，拍卖时间从两天前的18:30到一天前的22:00
        for(uint8 p=0; p<6; p++) {
            specialConfigs[p].special = true;
            
            specialConfigs[p].bidStartValue = 0.1 ether; // 起拍价0.1ETH
            specialConfigs[p].bidStartTime = 18 hours + 30 minutes - 2 days; // 两天前的18:30
            specialConfigs[p].bidEndTime = 22 hours - 1 days; // 一天前的22:00
            specialConfigs[p].isPrivate = false; // 非私募
        }
    }

    /**
     * 获取区块的时间戳，单位s
     */
    function time() constant internal returns (uint) {
        return block.timestamp;
    }

    /**
     * 获取某个时间是上线第几天，第1天返回1，上线之前返回0
     * 
     * @param timestamp 时间戳
     */
    function dayFor(uint timestamp) constant public returns (uint) {
        return timestamp < onlineTime
            ? 0
            : (timestamp.sub(onlineTime) / 1 days) + 1;
    }

    /**
     * 获取当前时间是今天的第几个时段，第一个时段返回1，没有匹配的返回0
     *
     * @param timestamp 时间戳
     */
    function numberFor(uint timestamp) constant public returns (uint8) {
        if (timestamp >= onlineTime) {
            uint current = timestamp.sub(onlineTime) % 1 days;

            for(uint8 i=0; i<6; i++) {
                if (dayConfigs[i].tvUseStartTime<=current && current<dayConfigs[i].tvUseEndTime) {
                    return (i + 1);
                }
            }
        }

        return 0;
    }

    /**
     * 创建时段币
     */
    function createNTVU() public onlyOwner {
        require(isRunning);
        require(totalTimeRange < MAX_TIME_RANGE_COUNT);

        uint8 number = totalTimeRange++;
        uint8 day = number / 6;
        uint8 num = number % 6;

        Base.NTVUConfig memory cfg = dayConfigs[num]; // 读取每天时段的默认配置

        // 如果有特殊配置则覆盖
        Base.NTVUConfig memory expCfg = specialConfigs[number];
        if (expCfg.special) {
            cfg.bidStartValue = expCfg.bidStartValue;
            cfg.bidStartTime = expCfg.bidStartTime;
            cfg.bidEndTime = expCfg.bidEndTime;
            cfg.isPrivate = expCfg.isPrivate;
        }

        // 根据上线时间计算具体的时段时间
        uint bidStartTime = uint(int(onlineTime) + day * 24 hours + cfg.bidStartTime);
        uint bidEndTime = uint(int(onlineTime) + day * 24 hours + cfg.bidEndTime);
        uint tvUseStartTime = onlineTime + day * 24 hours + cfg.tvUseStartTime;
        uint tvUseEndTime = onlineTime + day * 24 hours + cfg.tvUseEndTime;

        timeRanges[number] = new NTVUToken(number, cfg.bidStartValue, bidStartTime, bidEndTime, tvUseStartTime, tvUseEndTime, cfg.isPrivate, defaultText, ethSaver);
    }

    /**
     * 查询所有时段
     */
    function queryNTVUs(uint startIndex, uint count) public view returns(address[]){
        startIndex = (startIndex < totalTimeRange)? startIndex : totalTimeRange;
        count = (startIndex + count < totalTimeRange) ? count : (totalTimeRange - startIndex);

        address[] memory result = new address[](count);
        for(uint i=0; i<count; i++) {
            result[i] = timeRanges[startIndex + i];
        }

        return result;
    }

    /**
     * 查询当前正在播放的时段
     */
    function playingNTVU() public view returns(address){
        uint day = dayFor(time());
        uint8 num = numberFor(time());

        if (day>0 && (num>0 && num<=6)) {
            day = day - 1;
            num = num - 1;

            return timeRanges[day * 6 + uint(num)];
        } else {
            return address(0);
        }
    }

    /**
     * 审核文本
     */
    function auditNTVUText(uint8 index, uint8 status, string _text) public onlyOwner {
        require(isRunning); // 合约启动后才能审核
        require(index >= 0 && index < totalTimeRange); //只能审核已经上线的时段
        require(status==1 || (status==2 && bytes(_text).length>0 && bytes(_text).length <= 90)); // 审核不通，需要配置文本

        address ntvu = timeRanges[index];
        assert(ntvu != address(0));

        NTVUToken ntvuToken = NTVUToken(ntvu);
        ntvuToken.auditText(status, _text);

        var (b1, b2, b3, len) = ntvuToken.getShowTextBytes96();
        var auditedText = StringUtils.fromBytes96(b1, b2, b3, len);
        OnTV(ntvuToken, ntvuToken.maxBidAccount(), auditedText); // 审核后的文本记录到日志中
    }

    /**
     * 获取电视播放文本
     */
    function getText() public view returns(string){
        address playing = playingNTVU();

        if (playing != address(0)) {
            NTVUToken ntvuToken = NTVUToken(playing);

            var (b1, b2, b3, len) = ntvuToken.getShowTextBytes96();
            return StringUtils.fromBytes96(b1, b2, b3, len);
        } else {
            return ""; // 当前不是播放时段，返回空文本
        }
    }

    /**
     * 获取竞拍状态
     */
    function status() public view returns(uint8) {
        if (!isRunning) {
            return 0; // 未启动拍卖
        } else if (time() < onlineTime) {
            return 1; // 未到首播时间
        } else {
            if (totalTimeRange == 0) {
                return 2; // 没有创建播放时段
            } else {
                if (time() < NTVUToken(timeRanges[totalTimeRange - 1]).tvUseEndTime()) {
                    return 3; // 整个竞拍活动进行中
                } else {
                    return 4; // 整个竞拍活动已结束
                }
            }
        }
    }
    
    /**
     * 获取总的竞拍人数
     */
    function totalAuctorCount() public view returns(uint32) {
        uint32 total = 0;

        for(uint8 i=0; i<totalTimeRange; i++) {
            total += NTVUToken(timeRanges[i]).auctorCount();
        }

        return total;
    }

    /**
     * 获取总的竞拍次数
     */
    function totalBidCount() public view returns(uint32) {
        uint32 total = 0;

        for(uint8 i=0; i<totalTimeRange; i++) {
            total += NTVUToken(timeRanges[i]).bidCount();
        }

        return total;
    }

    /**
     * 获取总的出价ETH
     */
    function totalBidEth() public view returns(uint) {
        uint total = 0;

        for(uint8 i=0; i<totalTimeRange; i++) {
            total += NTVUToken(timeRanges[i]).balance;
        }

        total += this.balance;
        total += ethSaver.balance;

        return total;
    }

    /**
     * 获取历史出价最高的ETH
     */
    function maxBidEth() public view returns(uint) {
        uint maxETH = 0;

        for(uint8 i=0; i<totalTimeRange; i++) {
            uint val = NTVUToken(timeRanges[i]).maxBidValue();
            maxETH =  (val > maxETH) ? val : maxETH;
        }

        return maxETH;
    }

    /**
     * 提取当前合约的ETH到ethSaver
     */
    function reclaimEther() public onlyOwner {
        require(isRunning);

        ethSaver.transfer(this.balance);
    }

    /**
     * 提取时段币的ETH到ethSaver
     */
    function reclaimNtvuEther(uint8 index) public onlyOwner {
        require(isRunning);
        require(index >= 0 && index < totalTimeRange); //只能审核已经上线的时段

        NTVUToken(timeRanges[index]).reclaimEther();
    }

    /**
     * 接收ETH
     */
    function() payable external {}
}