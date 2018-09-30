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




contract MainBase is Base 
{
    modifier ValidLevel(uint8 level)
    {
        require(level<=HEROLEVEL_MAX && level>=HEROLEVEL_MIN);
        _;
    }

    modifier ValidParts(uint8 level, uint32[] parts)
    {
        require(GetPartNum(level) == parts.length);
        _;
    }

    modifier ValidPart(uint8 level, uint part)
    {
        require(part > 0);
        require(GetPartNum(level) >= part);
        _;
    }

}




contract MainCard is BasicAuth,MainBase
{
    struct Card {
        uint32 m_Index;
        uint32 m_Duration;
        uint8 m_Level;
        uint16 m_DP;  //DynamicProfit
        uint16 m_DPK; //K is coefficient
        uint16 m_SP;  //StaticProfit
        uint16 m_IP;  //ImmediateProfit
        uint32[] m_Parts;
    }

    struct CardLib {
        uint32[] m_List;
        mapping(uint32 => Card) m_Lib;
    }

    CardLib g_CardLib;

    function AddNewCard(uint32 iCard, uint32 duration, uint8 level, uint16 dp, uint16 dpk, uint16 sp, uint16 ip, uint32[] parts) external MasterAble ValidLevel(level) ValidParts(level,parts)
    {
        require(!CardExists(iCard));
        g_CardLib.m_List.push(iCard);
        g_CardLib.m_Lib[iCard] = Card({
            m_Index   : iCard,
            m_Duration: duration,
            m_Level   : level,
            m_DP      : dp,
            m_DPK     : dpk,
            m_SP      : sp,
            m_IP      : ip,
            m_Parts   : parts
        });
    }

    function CardExists(uint32 iCard) public view returns(bool)
    {
        Card storage obj = g_CardLib.m_Lib[iCard];
        return obj.m_Index == iCard;
    }

    function GetCard(uint32 iCard) internal view returns(Card storage)
    {
        return g_CardLib.m_Lib[iCard];
    }

    function GetCardInfo(uint32 iCard) external view returns(uint32, uint32, uint8, uint16, uint16, uint16, uint16, uint32[])
    {
        Card storage obj = GetCard(iCard);
        return (obj.m_Index, obj.m_Duration, obj.m_Level, obj.m_DP, obj.m_DPK, obj.m_SP, obj.m_IP, obj.m_Parts);
    }

    function GetExistsCardList() external view returns(uint32[])
    {
        return g_CardLib.m_List;
    }

}




contract MainChip is BasicAuth,MainBase
{
    using IndexList for uint32[];

    struct Chip
    {
        uint8 m_Level;
        uint8 m_LimitNum;
        uint8 m_Part;
        uint32 m_Index;
        uint256 m_UsedNum;
    }

    struct PartManager
    {
        uint32[] m_IndexList;   //index list, player can obtain
        uint32[] m_UnableList;  //player can&#39;t obtain
    }

    struct ChipLib
    {
        uint32[] m_List;
        mapping(uint32 => Chip) m_Lib;
        mapping(uint32 => uint[]) m_TempList;
        mapping(uint8 => mapping(uint => PartManager)) m_PartMap;//level -> level list
    }

    ChipLib g_ChipLib;

    function AddNewChip(uint32 iChip, uint8 lv, uint8 limit, uint8 part) external MasterAble ValidLevel(lv) ValidPart(lv,part)
    {
        require(!ChipExists(iChip));
        g_ChipLib.m_List.push(iChip);
        g_ChipLib.m_Lib[iChip] = Chip({
            m_Index       : iChip,
            m_Level       : lv,
            m_LimitNum    : limit,
            m_Part        : part,
            m_UsedNum     : 0
        });
        PartManager storage pm = GetPartManager(lv,part);
        pm.m_IndexList.push(iChip);
    }

    function GetChip(uint32 iChip) internal view returns(Chip storage)
    {
        return g_ChipLib.m_Lib[iChip];
    }

    function GetPartManager(uint8 level, uint iPart) internal view returns(PartManager storage)
    {
        return g_ChipLib.m_PartMap[level][iPart];
    }

    function ChipExists(uint32 iChip) public view returns(bool)
    {
        Chip storage obj = GetChip(iChip);
        return obj.m_Index == iChip;
    }

    function GetChipUsedNum(uint32 iChip) internal view returns(uint)
    {
        Chip storage obj = GetChip(iChip);
        uint[] memory tempList = g_ChipLib.m_TempList[iChip];
        uint num = tempList.length;
        for (uint i=num; i>0; i--)
        {
            if(tempList[i-1]<=now) {
                num -= i;
                break;
            }
        }
        return obj.m_UsedNum + num;
    }

    function CanObtainChip(uint32 iChip) internal view returns(bool)
    {
        Chip storage obj = GetChip(iChip);
        if (obj.m_LimitNum == 0) return true;
        if (GetChipUsedNum(iChip) < obj.m_LimitNum) return true;
        return false;
    }

    function CostChip(uint32 iChip) internal
    {
        BeforeChipCost(iChip);
        Chip storage obj = GetChip(iChip);
        obj.m_UsedNum--;
    }

    function ObtainChip(uint32 iChip) internal
    {
        BeforeChipObtain(iChip);
        Chip storage obj = GetChip(iChip);
        obj.m_UsedNum++;
    }

    function BeforeChipObtain(uint32 iChip) internal
    {
        Chip storage obj = GetChip(iChip);
        if (obj.m_LimitNum == 0) return;
        uint usedNum = GetChipUsedNum(iChip);
        require(obj.m_LimitNum >= usedNum+1);
        if (obj.m_LimitNum == usedNum+1) {
            PartManager storage pm = GetPartManager(obj.m_Level,obj.m_Part);
            if (pm.m_IndexList.remove(iChip)){
                pm.m_UnableList.push(iChip);
            }
        }
    }

    function BeforeChipCost(uint32 iChip) internal
    {
        Chip storage obj = GetChip(iChip);
        if (obj.m_LimitNum == 0) return;
        uint usedNum = GetChipUsedNum(iChip);
        require(obj.m_LimitNum >= usedNum);
        if (obj.m_LimitNum == usedNum) {
            PartManager storage pm = GetPartManager(obj.m_Level,obj.m_Part);
            if (pm.m_UnableList.remove(iChip)) {
                pm.m_IndexList.push(iChip);
            }
        }
    }

    function AddChipTempTime(uint32 iChip, uint expireTime) internal
    {
        uint[] storage list = g_ChipLib.m_TempList[iChip];
        require(list.length==0 || expireTime>=list[list.length-1]);
        BeforeChipObtain(iChip);
        list.push(expireTime);
    }

    function RefreshChipUnableList(uint8 level) internal
    {
        uint partNum = GetPartNum(level);
        for (uint iPart=1; iPart<=partNum; iPart++)
        {
            PartManager storage pm = GetPartManager(level,iPart);
            for (uint i=pm.m_UnableList.length; i>0; i--)
            {
                uint32 iChip = pm.m_UnableList[i-1];
                if (CanObtainChip(iChip)) {
                    pm.m_IndexList.push(iChip);
                    pm.m_UnableList.remove(iChip,i-1);
                }
            }
        }
    }

    function GenChipByWeight(uint random, uint8 level, uint[] extWeight) internal view returns(uint32)
    {
        uint partNum = GetPartNum(level);
        uint allWeight;
        uint[] memory newWeight = new uint[](partNum+1);
        uint[] memory realWeight = new uint[](partNum+1);
        for (uint iPart=1; iPart<=partNum; iPart++)
        {
            PartManager storage pm = GetPartManager(level,iPart);
            uint curWeight = extWeight[iPart-1]+GetPartWeight(level,iPart);
            allWeight += pm.m_IndexList.length*curWeight;
            newWeight[iPart] = allWeight;
            realWeight[iPart] = curWeight;
        }

        uint weight = random % allWeight;
        for (iPart=1; iPart<=partNum; iPart++)
        {
            if (weight >= newWeight[iPart]) continue;
            pm = GetPartManager(level,iPart);
            uint idx = (weight-newWeight[iPart-1])/realWeight[iPart];
            return pm.m_IndexList[idx];
        }
    }

    function GetChipInfo(uint32 iChip) external view returns(uint32, uint8, uint8, uint, uint8, uint)
    {
        Chip storage obj = GetChip(iChip);
        return (obj.m_Index, obj.m_Level, obj.m_LimitNum, GetPartWeight(obj.m_Level,obj.m_Part), obj.m_Part, GetChipUsedNum(iChip));
    }

    function GetExistsChipList() external view returns(uint32[])
    {
        return g_ChipLib.m_List;
    }

}




contract MainBonus is BasicTime,BasicAuth,MainBase,MainCard
{
    uint constant BASERATIO = 10000;

    struct PlayerBonus
    {
        uint m_DrawedDay;
        uint16 m_DDPermanent;// drawed day permanent
        mapping(uint => uint16) m_DayStatic;
        mapping(uint => uint16) m_DayPermanent;
        mapping(uint => uint32[]) m_DayDynamic;
    }

    struct DayRatio
    {
        uint16 m_Static;
        uint16 m_Permanent;
        uint32[] m_DynamicCard;
        mapping(uint32 => uint) m_CardNum;
    }

    struct BonusData
    {
        uint m_RewardBonus;//bonus pool,waiting for withdraw
        uint m_RecordDay;// recordday
        uint m_RecordBonus;//recordday bonus , to show
        uint m_RecordPR;// recordday permanent ratio
        mapping(uint => DayRatio) m_DayRatio;
        mapping(uint => uint) m_DayBonus;// day final bonus
        mapping(address => PlayerBonus) m_PlayerBonus;
    }

    BonusData g_Bonus;

    constructor() public
    {
        g_Bonus.m_RecordDay = GetDayCount(now);
    }

    function() external payable {}

    function NeedRefresh(uint dayNo) internal view returns(bool)
    {
        if (g_Bonus.m_RecordBonus == 0) return false;
        if (g_Bonus.m_RecordDay == dayNo) return false;
        return true;
    }

    function PlayerNeedRefresh(address acc, uint dayNo) internal view returns(bool)
    {
        if (g_Bonus.m_RecordBonus == 0) return false;
        PlayerBonus storage pb = g_Bonus.m_PlayerBonus[acc];
        if (pb.m_DrawedDay == dayNo) return false;
        return true;
    }

    function GetDynamicRatio(uint dayNo) internal view returns(uint tempRatio)
    {
        DayRatio storage dr = g_Bonus.m_DayRatio[dayNo];
        for (uint i=0; i<dr.m_DynamicCard.length; i++)
        {
            uint32 iCard = dr.m_DynamicCard[i];
            uint num = dr.m_CardNum[iCard];
            Card storage oCard = GetCard(iCard);
            tempRatio += num*oCard.m_DP*oCard.m_DPK/(oCard.m_DPK+num);
        }
    }

    function GenDayRatio(uint dayNo) internal view returns(uint iDR)
    {
        DayRatio storage dr = g_Bonus.m_DayRatio[dayNo];
        iDR += dr.m_Permanent;
        iDR += dr.m_Static;
        iDR += GetDynamicRatio(dayNo);
    }

    function GetDynamicCardNum(uint32 iCard, uint dayNo) internal view returns(uint num)
    {
        DayRatio storage dr = g_Bonus.m_DayRatio[dayNo];
        num = dr.m_CardNum[iCard];
    }

    function GetPlayerDynamicRatio(address acc, uint dayNo) internal view returns(uint tempRatio)
    {
        PlayerBonus storage pb = g_Bonus.m_PlayerBonus[acc];
        DayRatio storage dr = g_Bonus.m_DayRatio[dayNo];
        uint32[] storage cards = pb.m_DayDynamic[dayNo];
        for (uint idx=0; idx<cards.length; idx++)
        {
            uint32 iCard = cards[idx];
            uint num = dr.m_CardNum[iCard];
            Card storage oCard = GetCard(iCard);
            tempRatio += oCard.m_DP*oCard.m_DPK/(oCard.m_DPK+num);
        }
    }

    function GenPlayerRatio(address acc, uint dayNo) internal view returns(uint tempRatio)
    {
        PlayerBonus storage pb = g_Bonus.m_PlayerBonus[acc];
        tempRatio += pb.m_DayPermanent[dayNo];
        tempRatio += pb.m_DayStatic[dayNo];
        tempRatio += GetPlayerDynamicRatio(acc,dayNo);
    }

    function RefreshDayBonus() internal
    {
        uint todayNo = GetDayCount(now);
        if (!NeedRefresh(todayNo)) return;

        uint tempBonus = g_Bonus.m_RecordBonus;
        uint tempPR = g_Bonus.m_RecordPR;
        uint tempRatio;
        for (uint dayNo=g_Bonus.m_RecordDay; dayNo<todayNo; dayNo++)
        {
            tempRatio = tempPR+GenDayRatio(dayNo);
            if (tempRatio == 0) continue;
            DayRatio storage dr = g_Bonus.m_DayRatio[dayNo];
            tempPR += dr.m_Permanent;
            g_Bonus.m_DayBonus[dayNo] = tempBonus;
            tempBonus -= tempBonus*tempRatio/BASERATIO;
        }

        g_Bonus.m_RecordPR = tempPR;
        g_Bonus.m_RecordDay = todayNo;
        g_Bonus.m_RecordBonus = tempBonus;
    }

    function QueryPlayerBonus(address acc, uint todayNo) view internal returns(uint accBonus,uint16 accPR)
    {
        PlayerBonus storage pb = g_Bonus.m_PlayerBonus[acc];
        accPR = pb.m_DDPermanent;

        if (!PlayerNeedRefresh(acc, todayNo)) return;

        uint tempBonus = g_Bonus.m_RecordBonus;
        uint tempPR = g_Bonus.m_RecordPR;
        uint dayNo = pb.m_DrawedDay;
        if (dayNo == 0) return;
        for (; dayNo<todayNo; dayNo++)
        {
            uint tempRatio = tempPR+GenDayRatio(dayNo);
            if (tempRatio == 0) continue;

            uint accRatio = accPR+GenPlayerRatio(acc,dayNo);
            accPR += pb.m_DayPermanent[dayNo];

            DayRatio storage dr = g_Bonus.m_DayRatio[dayNo];
            if (dayNo >= g_Bonus.m_RecordDay) {
                tempPR += dr.m_Permanent;
                accBonus += tempBonus*accRatio/BASERATIO;
                tempBonus -= tempBonus*tempRatio/BASERATIO;
            }
            else {
                if (accRatio == 0) continue;
                accBonus += g_Bonus.m_DayBonus[dayNo]*accRatio/BASERATIO;
            }
        }
    }

    function GetDynamicCardAmount(uint32 iCard, uint timestamp) external view returns(uint num)
    {
        num = GetDynamicCardNum(iCard, GetDayCount(timestamp));
    }

    function AddDynamicProfit(address acc, uint32 iCard, uint duration) internal
    {
        RefreshDayBonus();
        uint todayNo = GetDayCount(now);
        PlayerBonus storage pb = g_Bonus.m_PlayerBonus[acc];
        if (pb.m_DrawedDay == 0) pb.m_DrawedDay = todayNo;
        for (uint dayNo=todayNo; dayNo<todayNo+duration; dayNo++)
        {
            pb.m_DayDynamic[dayNo].push(iCard);
            DayRatio storage dr= g_Bonus.m_DayRatio[dayNo];
            if (dr.m_CardNum[iCard] == 0) {
                dr.m_DynamicCard.push(iCard);
            }
            dr.m_CardNum[iCard]++;
        }
    }

    function AddStaticProfit(address acc,uint16 ratio,uint duration) internal
    {
        RefreshDayBonus();
        uint todayNo = GetDayCount(now);
        PlayerBonus storage pb = g_Bonus.m_PlayerBonus[acc];
        if (pb.m_DrawedDay == 0) pb.m_DrawedDay = todayNo;
        if (duration == 0) {
            pb.m_DayPermanent[todayNo] += ratio;
            g_Bonus.m_DayRatio[todayNo].m_Permanent += ratio;
        }
        else {
            for (uint dayNo=todayNo; dayNo<todayNo+duration; dayNo++)
            {
                pb.m_DayStatic[dayNo] += ratio;
                g_Bonus.m_DayRatio[dayNo].m_Static += ratio;
            }
        }
    }

    function ImmediateProfit(address acc, uint ratio) internal
    {
        RefreshDayBonus();
        uint bonus = ratio*g_Bonus.m_RecordBonus/BASERATIO;
        g_Bonus.m_RecordBonus -= bonus;
        g_Bonus.m_RewardBonus -= bonus;
        if (bonus == 0) return
        acc.transfer(bonus);
    }


    function ProfitByCard(address acc, uint32 iCard) internal
    {
        Card storage oCard = GetCard(iCard);
        if (oCard.m_IP > 0) {
            ImmediateProfit(acc,oCard.m_IP);
        }
        else if (oCard.m_SP > 0) {
            AddStaticProfit(acc,oCard.m_SP,oCard.m_Duration);
        }
        else {
            AddDynamicProfit(acc,iCard,oCard.m_Duration);
        }
    }

    function QueryBonus() external view returns(uint)
    {
        uint todayNo = GetDayCount(now);
        if (!NeedRefresh(todayNo)) return g_Bonus.m_RecordBonus;

        uint tempBonus = g_Bonus.m_RecordBonus;
        uint tempPR = g_Bonus.m_RecordPR;
        uint tempRatio;
        for (uint dayNo=g_Bonus.m_RecordDay; dayNo<todayNo; dayNo++)
        {
            tempRatio = tempPR+GenDayRatio(dayNo);
            if (tempRatio == 0) continue;
            DayRatio storage dr = g_Bonus.m_DayRatio[dayNo];
            tempPR += dr.m_Permanent;
            tempBonus -= tempBonus*tempRatio/BASERATIO;
        }
        return tempBonus;
    }

    function QueryMyBonus(address acc) external view returns(uint bonus)
    {
        (bonus,) = QueryPlayerBonus(acc, GetDayCount(now));
    }

    function AddBonus(uint bonus) external AuthAble
    {
        RefreshDayBonus();
        g_Bonus.m_RewardBonus += bonus;
        g_Bonus.m_RecordBonus += bonus;
    }

    function Withdraw(address acc) external
    {
        RefreshDayBonus();
        PlayerBonus storage pb = g_Bonus.m_PlayerBonus[acc];
        uint bonus;
        uint todayNo = GetDayCount(now);
        (bonus, pb.m_DDPermanent) = QueryPlayerBonus(acc, todayNo);
        require(bonus > 0);
        pb.m_DrawedDay = todayNo;
        acc.transfer(bonus);
        g_Bonus.m_RewardBonus -= bonus;
    }

    function MasterWithdraw() external
    {
        uint bonus = address(this).balance-g_Bonus.m_RewardBonus;
        require(bonus > 0);
        master.transfer(bonus);
    }


}




contract MainBag is BasicTime,BasicAuth,MainChip,MainCard
{
    using ItemList for ItemList.Data;

    struct Bag
    {
        ItemList.Data m_Stuff;
        ItemList.Data m_TempStuff;
        ItemList.Data m_Chips;
        ItemList.Data m_TempCards; // temporary cards
        ItemList.Data m_PermCards; // permanent cards
    }

    mapping(address => Bag) g_BagList;

    function GainStuff(address acc, uint32 iStuff, uint iNum) external AuthAble OwnerAble(acc)
    {
        Bag storage obj = g_BagList[acc];
        obj.m_Stuff.add(iStuff,iNum);
    }

    function CostStuff(address acc, uint32 iStuff, uint iNum) external AuthAble OwnerAble(acc)
    {
        Bag storage obj = g_BagList[acc];
        obj.m_Stuff.sub(iStuff,iNum);
    }

    function GetStuffNum(address acc, uint32 iStuff) view external returns(uint)
    {
        Bag storage obj = g_BagList[acc];
        return obj.m_Stuff.get(iStuff);
    }

    function GetStuffList(address acc) external view returns(uint32[],uint[])
    {
        Bag storage obj = g_BagList[acc];
        return obj.m_Stuff.list();
    }

    function GainTempStuff(address acc, uint32 iStuff, uint dayCnt) external AuthAble OwnerAble(acc)
    {
        Bag storage obj = g_BagList[acc];
        require(obj.m_TempStuff.get(iStuff) <= now);
        obj.m_TempStuff.set(iStuff,now+dayCnt*DAY_SECONDS);
    }

    function GetTempStuffExpire(address acc, uint32 iStuff) external view returns(uint expire)
    {
        Bag storage obj = g_BagList[acc];
        expire = obj.m_TempStuff.get(iStuff);
    }

    function GetTempStuffList(address acc) external view returns(uint32[],uint[])
    {
        Bag storage obj = g_BagList[acc];
        return obj.m_TempStuff.list();
    }

    function GainChip(address acc, uint32 iChip,bool bGenerated) external AuthAble OwnerAble(acc)
    {
        if (!bGenerated) {
            require(CanObtainChip(iChip));
            ObtainChip(iChip);
        }
        Bag storage obj = g_BagList[acc];
        obj.m_Chips.add(iChip,1);
    }

    function CostChip(address acc, uint32 iChip) external AuthAble OwnerAble(acc)
    {
        Bag storage obj = g_BagList[acc];
        obj.m_Chips.sub(iChip,1);
        CostChip(iChip);
    }

    function GetChipNum(address acc, uint32 iChip) external view returns(uint)
    {
        Bag storage obj = g_BagList[acc];
        return obj.m_Chips.get(iChip);
    }

    function GetChipList(address acc) external view returns(uint32[],uint[])
    {
        Bag storage obj = g_BagList[acc];
        return obj.m_Chips.list();
    }

    function GainCard2(address acc, uint32 iCard) internal
    {
        Card storage oCard = GetCard(iCard);
        if (oCard.m_IP > 0) return;
        uint i;
        uint32 iChip;
        Bag storage obj = g_BagList[acc];
        if (oCard.m_Duration > 0) {
            // temporary
            uint expireTime = GetExpireTime(now,oCard.m_Duration);
            for (i=0; i<oCard.m_Parts.length; i++)
            {
                iChip = oCard.m_Parts[i];
                AddChipTempTime(iChip,expireTime);
            }
            obj.m_TempCards.set(iCard,expireTime);
        }
        else {
            // permanent
            for (i=0; i<oCard.m_Parts.length; i++)
            {
                iChip = oCard.m_Parts[i];
                ObtainChip(iChip);
            }
            obj.m_PermCards.set(iCard,1);
        }
    }

    function HasCard(address acc, uint32 iCard) public view returns(bool)
    {
        Bag storage obj = g_BagList[acc];
        if (obj.m_TempCards.get(iCard) > now) return true;
        if (obj.m_PermCards.has(iCard)) return true;
        return false;
    }

    function GetCardList(address acc) external view returns(uint32[] tempCards, uint[] cardsTime, uint32[] permCards)
    {
        Bag storage obj = g_BagList[acc];
        (tempCards,cardsTime) = obj.m_TempCards.list();
        permCards = obj.m_PermCards.keys();
    }


}




contract Main is MainChip,MainCard,MainBag,MainBonus
{

    constructor(address Master) public
    {
        InitMaster(Master);
    }

    function GainCard(address acc, uint32 iCard) external
    {
        require(CardExists(iCard) && !HasCard(acc,iCard));
        GainCard2(acc,iCard);
        ProfitByCard(acc,iCard);
    }

    function GetDynamicCardAmountList(address acc) external view returns(uint[] amountList)
    {
        Bag storage oBag = g_BagList[acc];
        uint len = oBag.m_TempCards.m_List.length;
        amountList = new uint[](len);
        for (uint i=0; i<len; i++)
        {
            uint32 iCard = oBag.m_TempCards.m_List[i];
            amountList[i] = GetDynamicCardNum(iCard,GetDayCount(now));
        }
    }

    function GenChipByRandomWeight(uint random, uint8 level, uint[] extWeight) external AuthAble returns(uint32 iChip)
    {
        RefreshChipUnableList(level);
        iChip = GenChipByWeight(random,level,extWeight);
        ObtainChip(iChip);
    }

    function CheckGenChip(uint32 iChip) external view returns(bool)
    {
        return CanObtainChip(iChip);
    }

    function GenChip(uint32 iChip) external AuthAble
    {
        require(CanObtainChip(iChip));
        ObtainChip(iChip);
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




contract Child is Base {

    Main g_Main;

    constructor(Main main) public
    {
        require(main != address(0));
        g_Main = main;
        g_Main.SetAuth(this);
    }

    function kill() external MasterAble
    {
        g_Main.ClearAuth(this);
        selfdestruct(creator);
    }

    function AddBonus(uint percent) internal
    {
        address(g_Main).transfer(msg.value);
        g_Main.AddBonus(msg.value * percent / 100);
    }

    function GenRandom(uint seed,uint base) internal view returns(uint,uint)
    {
        uint r = uint(keccak256(abi.encodePacked(msg.sender,seed,now)));
        if (base != 0) r %= base;
        return (r,seed+1);
    }

}




contract Store is Child
{
    uint constant BONUS_PERCENT_PURCHASE = 80;
    uint constant CHIPGIFT_NORMALCHIP_RATE = 10000;
    uint32 constant CHIPGIFT_ITEMINDEX = 24001;

    uint8 constant EXCHANGE_OK = 0;
    uint8 constant EXCHANGE_KEYERR = 1;
    uint8 constant EXCHANGE_HADGOT = 2;

    StoreGoods g_Goods;
    StoreGifts g_Gifts;

    constructor(Main main, StoreGoods goods, StoreGifts gifts) public Child(main)
    {
        g_Goods = goods;
        g_Gifts = gifts;
        g_Goods.SetAuth(this);
        g_Gifts.SetAuth(this);
    }
    
    function kill() external MasterAble
    {
        g_Goods.ClearAuth(this);
    }

    function GenExtWeightList(uint8 level) internal pure returns(uint[] extList)
    {
        uint partNum = GetPartNum(level);
        extList = new uint[](partNum);
        for (uint i=0; i<partNum; i++)
        {
            uint iPart = i+1;
            if (!IsLimitPart(level,iPart)) {
                extList[i] = GetPartWeight(level, iPart)*CHIPGIFT_NORMALCHIP_RATE;
            }
        }
    }

    function GiveChipGitf() internal
    {
        for (uint8 level=HEROLEVEL_MIN; level<=HEROLEVEL_MAX; level++)
        {
            (uint random,) = GenRandom(level, 0);
            uint32 iChip = g_Main.GenChipByRandomWeight(random, level, GenExtWeightList(level));
            g_Main.GainChip(msg.sender, iChip, true);
        }
    }

    function BuyGoods(uint32 iGoods) external payable
    {
        require(g_Goods.HasGoods(iGoods));
        require(g_Goods.IsOnSale(iGoods));
        require(g_Goods.CheckPurchaseCount(msg.sender, iGoods));
        (,uint32 iCostItem,uint32 iItemRef,uint32 iAmount,uint32 iDuration,,,,) = g_Goods.GetGoodsInfo(iGoods);
        uint iCostNum = g_Goods.GetRealCost(msg.sender, iGoods);
        if (iCostItem == 0) {
            // cost ether(wei)
            require(msg.value == iCostNum);
            AddBonus(BONUS_PERCENT_PURCHASE);
        }
        else {
            // cost other stuff
            g_Main.CostStuff(msg.sender,iCostItem,iCostNum);
        }
        g_Goods.BuyGoods(msg.sender, iGoods);
        if (iItemRef == CHIPGIFT_ITEMINDEX) {
            GiveChipGitf();
        }
        else {
            if (iDuration == 0) {
                g_Main.GainStuff(msg.sender, iItemRef, iAmount);
            }
            else {
                g_Main.GainTempStuff(msg.sender, iItemRef, iDuration);
            }
        }
    }

    function GetPurchaseInfo() external view returns(uint32[] goodsList, uint[] purchaseCountList)
    {
        (goodsList, purchaseCountList) = g_Goods.GetPurchaseInfo(msg.sender);
    }

    function CheckExchange(string key) public view returns(uint8)
    {
        if (!g_Gifts.HasGift(key)) return EXCHANGE_KEYERR;
        if (g_Gifts.IsExchanged(msg.sender, key)) return EXCHANGE_HADGOT;
        return EXCHANGE_OK;
    }

    function ExchangeGift(string key) external
    {
        require(CheckExchange(key) == EXCHANGE_OK);
        g_Gifts.Exchange(msg.sender, key);
        (, uint32[] memory idxList, uint[] memory numList) = g_Gifts.GetGiftInfo(key);
        for (uint i=0; i<idxList.length; i++)
        {
            g_Main.GainStuff(msg.sender, idxList[i], numList[i]);
        }
    }

}