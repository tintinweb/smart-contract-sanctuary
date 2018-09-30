pragma solidity ^0.4.24;



contract Base
{
    uint8 constant HEROLEVEL_MIN = 1;
    uint8 constant HEROLEVEL_MAX = 5;

    uint8 constant LIMITCHIP_MINLEVEL = 3;
    uint constant PARTWEIGHT_NORMAL = 100;
    uint constant PARTWEIGHT_LIMIT = 40;

    address creator;

    constructor() public
    {
        creator = msg.sender;
    }

    modifier MasterAble()
    {
        require(msg.sender == creator);
        _;
    }

    function IsLimitPart(uint8 level, uint part) internal pure returns(bool)
    {
        if (level < LIMITCHIP_MINLEVEL) return false;
        if (part < GetPartNum(level)) return false;
        return true;
    }

    function GetPartWeight(uint8 level, uint part) internal pure returns(uint)
    {
        if (IsLimitPart(level, part)) return PARTWEIGHT_LIMIT;
        return PARTWEIGHT_NORMAL;
    }
    
    function GetPartNum(uint8 level) internal pure returns(uint)
    {
        if (level <= 2) return 3;
        else if (level <= 4) return 4;
        return 5;
    }

}

contract BasicTime
{
    uint constant DAY_SECONDS = 60 * 60 * 24;

    function GetDayCount(uint timestamp) pure internal returns(uint)
    {
        return timestamp/DAY_SECONDS;
    }

    function GetExpireTime(uint timestamp, uint dayCnt) pure internal returns(uint)
    {
        uint dayEnd = GetDayCount(timestamp) + dayCnt;
        return dayEnd * DAY_SECONDS;
    }

}

contract BasicAuth is Base
{

    address master;
    mapping(address => bool) auth_list;

    function InitMaster(address acc) internal
    {
        require(address(0) != acc);
        master = acc;
    }

    modifier MasterAble()
    {
        require(msg.sender == creator || msg.sender == master);
        _;
    }

    modifier OwnerAble(address acc)
    {
        require(acc == tx.origin);
        _;
    }

    modifier AuthAble()
    {
        require(auth_list[msg.sender]);
        _;
    }

    function CanHandleAuth(address from) internal view returns(bool)
    {
        return from == creator || from == master;
    }
    
    function SetAuth(address target) external
    {
        require(CanHandleAuth(tx.origin) || CanHandleAuth(msg.sender));
        auth_list[target] = true;
    }

    function ClearAuth(address target) external
    {
        require(CanHandleAuth(tx.origin) || CanHandleAuth(msg.sender));
        delete auth_list[target];
    }

}




contract StoreGifts is BasicAuth
{
    struct Gift
    {
        string m_Key;
        uint m_Expire;
        uint32[] m_ItemIdxList;
        uint[] m_ItemNumlist;
    }

    mapping(address => mapping(string => bool)) g_Exchange;
    mapping(string => Gift) g_Gifts;

    constructor(address Master) public
    {
        InitMaster(Master);
    }

    function HasGift(string key) public view returns(bool)
    {
        Gift storage obj = g_Gifts[key];
        if (bytes(obj.m_Key).length == 0) return false;
        if (obj.m_Expire!=0 && obj.m_Expire<now) return false;
        return true;
    }

    function AddGift(string key, uint expire, uint32[] idxList, uint[] numList) external MasterAble
    {
        require(!HasGift(key));
        require(now<expire || expire==0);
        g_Gifts[key] = Gift({
            m_Key           : key,
            m_Expire        : expire,
            m_ItemIdxList   : idxList,
            m_ItemNumlist   : numList
        });
    }

    function DelGift(string key) external MasterAble
    {
        delete g_Gifts[key];
    }

    function GetGiftInfo(string key) external view returns(uint, uint32[], uint[])
    {
        Gift storage obj = g_Gifts[key];
        return (obj.m_Expire, obj.m_ItemIdxList, obj.m_ItemNumlist);
    }

    function Exchange(address acc, string key) external OwnerAble(acc) AuthAble
    {
        g_Exchange[acc][key] = true;
    }

    function IsExchanged(address acc, string key) external view returns(bool)
    {
        return g_Exchange[acc][key];
    }

}