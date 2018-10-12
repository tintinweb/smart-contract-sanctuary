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




library ItemList {

    struct Data {
        uint32[] m_List;
        mapping(uint32 => uint) m_Maps;
    }

    function set(Data storage self, uint32 key, uint num) public
    {
        if (!has(self,key)) {
            if (num == 0) return;
            self.m_List.push(key);
            self.m_Maps[key] = num;
        }
        else if (num == 0) {
            delete self.m_Maps[key];
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

    function AddGoods(uint32 iGoods, uint32 costItem, uint price, uint32 itemRef, uint32 amount, uint32 duration, uint32 expire, uint8 limit, uint8 disCount, uint8 disRate) external CreatorAble
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

    function DelGoods(uint32 iGoods) external CreatorAble
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