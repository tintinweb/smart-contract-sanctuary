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




contract StoreChipBag is BasicAuth
{

    mapping(address => uint32[]) g_ChipBag;

    constructor(address Master) public
    {
        InitMaster(Master);
    }

    function AddChip(address acc, uint32 iChip) external OwnerAble(acc) AuthAble
    {
        g_ChipBag[acc].push(iChip);
    }

    function CollectChips(address acc) external returns(uint32[] chips)
    {
        chips = g_ChipBag[acc];
        delete g_ChipBag[acc];
    }

    function GetChipsInfo(address acc) external view returns(uint32[] chips)
    {
        chips = g_ChipBag[acc];
    }

}