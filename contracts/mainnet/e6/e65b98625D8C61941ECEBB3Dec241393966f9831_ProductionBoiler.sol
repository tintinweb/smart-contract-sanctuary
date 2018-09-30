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




contract ProductionBoiler is BasicAuth
{

    struct Boiler
    {
        uint m_Expire;
        uint32[] m_Chips;
    }

    mapping(address => mapping(uint => Boiler)) g_Boilers;

    constructor(address Master) public
    {
        InitMaster(Master);
    }

    function IsBoilerValid(address acc, uint idx) external view returns(bool)
    {
        Boiler storage obj = g_Boilers[acc][idx];
        if (obj.m_Chips.length > 0) return false;
        return true;
    }

    function IsBoilerExpire(address acc, uint idx) external view returns(bool)
    {
        Boiler storage obj = g_Boilers[acc][idx];
        return obj.m_Expire <= now;
    }

    //=========================================================================

    function GenerateChips(address acc, uint idx, uint cd, uint32[] chips) external AuthAble OwnerAble(acc)
    {
        Boiler storage obj = g_Boilers[acc][idx];
        obj.m_Expire = cd+now;
        obj.m_Chips = chips;
    }

    function CollectChips(address acc, uint idx) external AuthAble OwnerAble(acc) returns(uint32[] chips)
    {
        Boiler storage obj = g_Boilers[acc][idx];
        chips = new uint32[](obj.m_Chips.length);
        for (uint i=0; i<obj.m_Chips.length; i++)
        {
            chips[i] = obj.m_Chips[i];
            delete obj.m_Chips[i];
        }
        obj.m_Chips.length = 0;
        obj.m_Expire = 0;
    }

    function GetBoilerInfo(address acc, uint idx) external view returns(uint, uint32[])
    {
        Boiler storage obj = g_Boilers[acc][idx];
        return (obj.m_Expire,obj.m_Chips);
    }

}