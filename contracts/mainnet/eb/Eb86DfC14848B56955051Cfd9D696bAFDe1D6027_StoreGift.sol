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

    modifier CreatorAble()
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

    function GetPartLimit(uint8 level, uint part) internal pure returns(uint8)
    {
        if (!IsLimitPart(level, part)) return 0;
        if (level == 5) return 1;
        if (level == 4) return 8;
        return 15;
    }

}




contract BasicAuth is Base
{

    mapping(address => bool) auth_list;

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

    modifier ValidHandleAuth()
    {
        require(tx.origin==creator || msg.sender==creator);
        _;
    }
   
    function SetAuth(address target) external ValidHandleAuth
    {
        auth_list[target] = true;
    }

    function ClearAuth(address target) external ValidHandleAuth
    {
        delete auth_list[target];
    }

}




contract StoreGift is BasicAuth
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

    function HasGift(string key) public view returns(bool)
    {
        Gift storage obj = g_Gifts[key];
        if (bytes(obj.m_Key).length == 0) return false;
        if (obj.m_Expire!=0 && obj.m_Expire<now) return false;
        return true;
    }

    function AddGift(string key, uint expire, uint32[] idxList, uint[] numList) external CreatorAble
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

    function DelGift(string key) external CreatorAble
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