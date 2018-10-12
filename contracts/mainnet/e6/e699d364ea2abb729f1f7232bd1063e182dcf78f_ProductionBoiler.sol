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




contract OldProductionBoiler
{
    function GetBoilerInfo(address acc, uint idx) external view returns(uint, uint32[]);
}

contract ProductionBoiler is BasicAuth
{

    struct Boiler
    {
        uint m_Expire;
        uint32[] m_Chips;
    }

    mapping(address => mapping(uint => Boiler)) g_Boilers;

    bool g_Synced = false;
    function SyncOldData(OldProductionBoiler oldBoiler, address[] accounts) external CreatorAble
    {
        require(!g_Synced);
        g_Synced = true;
        for (uint i=0; i<accounts.length; i++)
        {
            address acc = accounts[i];
            for (uint idx=0; idx<3; idx++)
            {
                (uint expire, uint32[] memory chips) = oldBoiler.GetBoilerInfo(acc,idx);
                if (expire == 0) continue;
                g_Boilers[acc][idx].m_Expire = expire;
                g_Boilers[acc][idx].m_Chips = chips;
            }
        }
    }

    //=========================================================================
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
        chips = obj.m_Chips;
        delete g_Boilers[acc][idx];
    }

    function GetBoilerInfo(address acc, uint idx) external view returns(uint, uint32[])
    {
        Boiler storage obj = g_Boilers[acc][idx];
        return (obj.m_Expire,obj.m_Chips);
    }

}