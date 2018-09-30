pragma solidity ^0.4.24;



library IndexList
{
    function insert(uint32[] storage self, uint32 index, uint pos) external
    {
        require(self.length >= pos);
        self.length++;
        for (uint i=self.length; i>pos; i++)
        {
            self[i+1] = self[i];
        }
        self[pos] = index;
    }

    function remove(uint32[] storage self, uint32 index) external returns(bool)
    {
        return remove(self,index,0);
    }

    function remove(uint32[] storage self, uint32 index, uint startPos) public returns(bool)
    {
        for (uint i=startPos; i<self.length; i++)
        {
            if (self[i] != index) continue;
            for (uint j=i; j<self.length-1; j++)
            {
                self[j] = self[j+1];
            }
            delete self[self.length-1];
            self.length--;
            return true;
        }
        return false;
    }

}

library ItemList {

    using IndexList for uint32[];
    
    struct Data {
        uint32[] m_List;
        mapping(uint32 => uint) m_Maps;
    }

    function _insert(Data storage self, uint32 key, uint val) internal
    {
        self.m_List.push(key);
        self.m_Maps[key] = val;
    }

    function _delete(Data storage self, uint32 key) internal
    {
        self.m_List.remove(key);
        delete self.m_Maps[key];
    }

    function set(Data storage self, uint32 key, uint num) public
    {
        if (!has(self,key)) {
            if (num == 0) return;
            _insert(self,key,num);
        }
        else if (num == 0) {
            _delete(self,key);
        } 
        else {
            uint old = self.m_Maps[key];
            if (old == num) return;
            self.m_Maps[key] = num;
        }
    }

    function add(Data storage self, uint32 key, uint num) external
    {
        uint iOld = get(self,key);
        uint iNow = iOld+num;
        require(iNow >= iOld);
        set(self,key,iNow);
    }

    function sub(Data storage self, uint32 key, uint num) external
    {
        uint iOld = get(self,key);
        require(iOld >= num);
        set(self,key,iOld-num);
    }

    function has(Data storage self, uint32 key) public view returns(bool)
    {
        return self.m_Maps[key] > 0;
    }

    function get(Data storage self, uint32 key) public view returns(uint)
    {
        return self.m_Maps[key];
    }

    function list(Data storage self) view external returns(uint32[],uint[])
    {
        uint len = self.m_List.length;
        uint[] memory values = new uint[](len);
        for (uint i=0; i<len; i++)
        {
            uint32 key = self.m_List[i];
            values[i] = self.m_Maps[key];
        }
        return (self.m_List,values);
    }

    function isEmpty(Data storage self) view external returns(bool)
    {
        return self.m_List.length == 0;
    }

    function keys(Data storage self) view external returns(uint32[])
    {
        return self.m_List;
    }

}




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




contract StoreGoods is BasicAuth
{
    using ItemList for ItemList.Data;

    struct Goods
    {
        uint32 m_Index;
        uint32 m_CostItem;
        uint32 m_ItemRef;
        uint32 m_Amount;
        uint32 m_Duration;
        uint32 m_Expire;
        uint8 m_PurchaseLimit;
        uint8 m_DiscountLimit;
        uint8 m_DiscountRate;
        uint m_CostNum;
    }

    mapping(uint32 => Goods) g_Goods;
    mapping(address => ItemList.Data) g_PurchaseInfo;

    constructor(address Master) public
    {
        InitMaster(Master);
    }

    function AddGoods(
        uint32 iGoods,
        uint32 costItem,
        uint price,
        uint32 itemRef,
        uint32 amount,
        uint32 duration,
        uint32 expire,
        uint8 limit,
        uint8 disCount,
        uint8 disRate
    ) external MasterAble
    {
        require(!HasGoods(iGoods));
        g_Goods[iGoods] = Goods({
            m_Index         :iGoods,
            m_CostItem      :costItem,
            m_ItemRef       :itemRef,
            m_CostNum       :price,
            m_Amount        :amount,
            m_Duration      :duration,
            m_Expire        :expire,
            m_PurchaseLimit :limit,
            m_DiscountLimit :disCount,
            m_DiscountRate  :disRate
        });
    }

    function DelGoods(uint32 iGoods) external MasterAble
    {
        delete g_Goods[iGoods];
    }

    function HasGoods(uint32 iGoods) public view returns(bool)
    {
        Goods storage obj = g_Goods[iGoods];
        return obj.m_Index == iGoods;
    }

    function GetGoodsInfo(uint32 iGoods) external view returns(
        uint32,uint32,uint32,uint32,uint32,uint,uint8,uint8,uint8
    )
    {
        Goods storage obj = g_Goods[iGoods];
        return (
            obj.m_Index,
            obj.m_CostItem,
            obj.m_ItemRef,
            obj.m_Amount,
            obj.m_Duration,
            obj.m_CostNum,
            obj.m_PurchaseLimit,
            obj.m_DiscountLimit,
            obj.m_DiscountRate
        );
    }

    function GetRealCost(address acc, uint32 iGoods) external view returns(uint)
    {
        Goods storage obj = g_Goods[iGoods];
        if (g_PurchaseInfo[acc].get(iGoods) >= obj.m_DiscountLimit) {
            return obj.m_CostNum;
        }
        else {
            return obj.m_CostNum * obj.m_DiscountRate / 100;
        }
    }

    function BuyGoods(address acc, uint32 iGoods) external OwnerAble(acc) AuthAble
    {
        g_PurchaseInfo[acc].add(iGoods,1);
    }

    function IsOnSale(uint32 iGoods) external view returns(bool)
    {
        Goods storage obj = g_Goods[iGoods];
        if (obj.m_Expire == 0) return true;
        if (obj.m_Expire >= now) return true;
        return false;
    }

    function CheckPurchaseCount(address acc, uint32 iGoods) external view returns(bool)
    {
        Goods storage obj = g_Goods[iGoods];
        if (obj.m_PurchaseLimit == 0) return true;
        if (g_PurchaseInfo[acc].get(iGoods) < obj.m_PurchaseLimit) return true;
        return false;
    }

    function GetPurchaseInfo(address acc) external view returns(uint32[], uint[])
    {
        return g_PurchaseInfo[acc].list();
    }

}