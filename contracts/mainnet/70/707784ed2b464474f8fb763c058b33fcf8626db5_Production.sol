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




contract MainCard is BasicAuth
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

    function AddNewCard(uint32 iCard, uint32 duration, uint8 level, uint16 dp, uint16 dpk, uint16 sp, uint16 ip, uint32[] parts) internal
    {
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




contract MainChip is BasicAuth
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

    function AddNewChip(uint32 iChip, uint8 lv, uint8 limit, uint8 part) internal
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




contract MainBonus is BasicTime,BasicAuth,MainCard
{
    uint constant BASERATIO = 10000;

    struct PlayerBonus
    {
        uint m_Bonus;       // bonus by immediateprofit
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

    address receiver;
    BonusData g_Bonus;

    constructor(address Receiver) public
    {
        g_Bonus.m_RecordDay = GetDayCount(now);
        receiver = Receiver;
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
        accBonus = pb.m_Bonus;

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
        if (g_Bonus.m_RecordBonus == 0) return;
        uint bonus = ratio*g_Bonus.m_RecordBonus/BASERATIO;
        g_Bonus.m_RecordBonus -= bonus;
        g_Bonus.m_RewardBonus -= bonus;
        g_Bonus.m_PlayerBonus[acc].m_Bonus += bonus;
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

    function Withdraw(address acc) external OwnerAble(acc)
    {
        RefreshDayBonus();
        PlayerBonus storage pb = g_Bonus.m_PlayerBonus[acc];
        uint bonus;
        uint todayNo = GetDayCount(now);
        (bonus, pb.m_DDPermanent) = QueryPlayerBonus(acc, todayNo);
        require(bonus > 0);
        pb.m_Bonus = 0;
        pb.m_DrawedDay = todayNo;
        g_Bonus.m_RewardBonus -= bonus;
        acc.transfer(bonus);
    }

    function MasterWithdraw() external
    {
        uint bonus = address(this).balance-g_Bonus.m_RewardBonus;
        require(bonus > 0);
        receiver.transfer(bonus);
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




contract OldMain
{
    function GetStuffList(address) external view returns(uint32[], uint[]);
    function GetTempStuffList(address acc) external view returns(uint32[], uint[]);
    function GetChipList(address acc) external view returns(uint32[], uint[]);
    function GetCardList(address acc) external view returns(uint32[] tempCards, uint[] cardsTime, uint32[] permCards);
}

contract Main is MainChip,MainCard,MainBag,MainBonus
{
    using ItemList for ItemList.Data;

    constructor(address Receiver) public MainBonus(Receiver) {}

    ///==================================================================
    bool g_Synced = false;
    function SyncOldData(OldMain oldMain, address[] accounts) external CreatorAble
    {
        // transfer itemdata
        require(!g_Synced);
        g_Synced = true;
        for (uint i=0; i<accounts.length; i++)
        {
            address acc = accounts[i];
            SyncStuff(oldMain, acc);
            SyncTempStuff(oldMain, acc);
            SyncChip(oldMain, acc);
            SyncCard(oldMain, acc);
        }
    }

    function SyncItemData(ItemList.Data storage Data, uint32[] idxList, uint[] valList) internal
    {
        if (idxList.length == 0) return;
        for (uint i=0; i<idxList.length; i++)
        {
            uint32 index = idxList[i];
            uint val = valList[i];
            Data.set(index, val);
        }
    }

    function SyncStuff(OldMain oldMain, address acc) internal
    {
        (uint32[] memory idxList, uint[] memory valList) = oldMain.GetStuffList(acc);
        SyncItemData(g_BagList[acc].m_Stuff, idxList, valList);
    }

    function SyncTempStuff(OldMain oldMain, address acc) internal
    {
        (uint32[] memory idxList, uint[] memory valList) = oldMain.GetTempStuffList(acc);
        SyncItemData(g_BagList[acc].m_TempStuff, idxList, valList);
    }

    function SyncChip(OldMain oldMain, address acc) internal
    {
        (uint32[] memory idxList, uint[] memory valList) = oldMain.GetChipList(acc);
        SyncItemData(g_BagList[acc].m_Chips, idxList, valList);
    }

    function CompensateChips(address acc, uint32[] idxList) internal
    {
        for (uint i=0; i<idxList.length; i++)
        {
            uint32 iCard = idxList[i];
            if (iCard == 0) return;
            Card storage obj = GetCard(iCard);
            for (uint j=0; j<obj.m_Parts.length; j++)
            {
                uint32 iChip = obj.m_Parts[j];
                g_BagList[acc].m_Chips.add(iChip,1);
            }
        }
    }

    function SyncCard(OldMain oldMain, address acc) internal
    {
        (uint32[] memory idxList, uint[] memory valList ,uint32[] memory permCards) = oldMain.GetCardList(acc);
        uint32[] memory allCards = new uint32[](idxList.length+permCards.length);
        uint i=0;
        uint j=0;
        for (j=0; j<idxList.length; j++)
        {
            uint expire = valList[j];
            if (expire < now) continue;
            allCards[i] = idxList[j];
            i++;
        }
        for (j=0; j<permCards.length; j++)
        {
            allCards[i] = permCards[j];
            i++;
        }
        CompensateChips(acc, allCards);
    }

    ///==================================================================

    function InsertCard(uint32 iCard, uint32 duration, uint8 level, uint16 dp, uint16 dpk, uint16 sp, uint16 ip, uint32[] parts) external CreatorAble
    {
        require(!CardExists(iCard));
        require(level<=HEROLEVEL_MAX && level>=HEROLEVEL_MIN);
        require(GetPartNum(level) == parts.length);
        AddNewCard(iCard, duration, level, dp, dpk, sp, ip, parts);
        for (uint8 iPart=1; iPart<=parts.length; iPart++)
        {
            uint idx = iPart-1;
            uint32 iChip = parts[idx];
            uint8 limit = GetPartLimit(level, iPart);
            AddNewChip(iChip, level, limit, iPart);
        }
    }

    function GainCard(address acc, uint32 iCard) external AuthAble OwnerAble(acc)
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




contract Child is Base {

    Main g_Main;

    constructor(Main main) public
    {
        require(main != address(0));
        g_Main = main;
        g_Main.SetAuth(this);
    }

    function kill() external CreatorAble
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




contract Production is Child {

    uint32 constant STUFF_IDX_POINT = 22001;
    uint32 constant STUFF_IDX_GENRAL = 21000;
    uint32 constant STUFF_IDX_EXTRA = 21004;

    uint32 constant PERMISSION_1 = 23002;
    uint32 constant PERMISSION_2 = 23003;

    uint constant BASERATIO = 10000;
    uint constant BOILER_FREE_IDX = 0;
    uint constant BOILER_MAX_NUM = 3;

    uint constant CREATE_COST_MIN = 30;
    uint constant CREATE_COST_FEW = 60;
    uint constant CREATE_COST_MANY = 150;
    uint constant CREATE_COST_MAX = 300;

    uint constant COOLTIME_MIN = 60 * 60;
    uint constant COOLTIME_MID = 60 * 60 * 2;
    uint constant COOLTIME_MAX = 60 * 60 * 4;

    uint constant ACCELERATE_UNITTIME = 60 * 5;
    uint constant ACCELERATE_UNITFEE = 0.0013 ether;
    uint constant BONUS_PERCENT_ACCELERATE = 80;

    ProductionBoiler g_Boilers;

    constructor(Main main, ProductionBoiler pb) public Child(main)
    {
        g_Boilers = pb;
        g_Boilers.SetAuth(this);
    }

    function kill() external CreatorAble
    {
        g_Boilers.ClearAuth(this);
    }

    function GenChipIndex(
        uint seed,
        uint8 level,
        uint[] extWeight3,
        uint[] extWeight4,
        uint[] extWeight5
    ) internal returns(uint32,uint)
    {
        uint random;
        (random,seed) = GenRandom(seed,0);
        if (level==1 || level==2) {
            return (g_Main.GenChipByRandomWeight(random,level,extWeight3),seed);
        }
        else if (level==3 || level==4) {
            return (g_Main.GenChipByRandomWeight(random,level,extWeight4),seed);
        }
        else {
            return (g_Main.GenChipByRandomWeight(random,level,extWeight5),seed);
        }
    }

    function GenChipLevel_Special(uint costAll, uint x, uint seed) internal view returns(uint8,uint)
    {
        uint8 outLv;
        uint random;
        if (costAll <= CREATE_COST_FEW) {
            outLv = 3;
        }
        else {
            (random,seed) = GenRandom(seed,BASERATIO);
            uint baseR = BASERATIO*x/100;
            if (costAll <= CREATE_COST_MANY) {
                baseR /= 10;
                if (random <= BASERATIO*80/100-baseR) {
                    outLv = 3;
                }
                else if (random <= BASERATIO-baseR/4) {
                    outLv = 4;
                }
                else {
                    outLv = 5;
                }
            }
            else {
                baseR /= 10;
                if (random <= BASERATIO*70/100-baseR) {
                    outLv = 3;
                }
                else if (random <= BASERATIO*95/100-baseR/5) {
                    outLv = 4;
                }
                else {
                    outLv = 5;
                }
            }
        }
        return (outLv,seed);
    }

    function GenChipLevel_Extra(uint costAll, uint x, uint seed) internal view returns(uint8,uint)
    {
        uint8 outLv;
        uint random;
        uint baseR = BASERATIO*x/100;
        (random,seed) = GenRandom(seed,BASERATIO);
        if (costAll <= CREATE_COST_FEW) {
            baseR /= 4;
            if (random <= BASERATIO*80/100-baseR) {
                outLv = 1;
            }
            else if (random <= BASERATIO*98/100-baseR*3/4) {
                outLv = 2;
            }
            else if (random <= BASERATIO-baseR/4) {
                outLv = 3;
            }
            else {
                outLv = 4;
            }
        }
        else if (costAll <= CREATE_COST_MANY) {
            baseR /= 10;
            if (random <= BASERATIO*55/100-baseR) {
                outLv = 1;
            }
            else if (random <= BASERATIO*85/100-baseR*4/5) {
                outLv = 2;
            }
            else if (random <= BASERATIO*95/100-baseR*2/5) {
                outLv = 3;
            }
            else if (random <= BASERATIO-baseR/5) {
                outLv = 4;
            }
            else {
                outLv = 5;
            }
        }
        else {
            baseR /= 10;
            if (random <= BASERATIO*30/100-baseR/2) {
                outLv = 1;
            }
            else if (random <= BASERATIO*75/100-baseR) {
                outLv = 2;
            }
            else if (random <= BASERATIO*88/100-baseR*4/7) {
                outLv = 3;
            }
            else if (random <= BASERATIO*97/100-baseR/7) {
                outLv = 4;
            }
            else {
                outLv = 5;
            }
        }
        return (outLv,seed);
    }

    function GenChipLevel_General(uint costAll, uint x, uint seed) internal view returns(uint8,uint)
    {
        uint8 outLv;
        uint random;
        uint baseR = BASERATIO*x/100;
        (random,seed) = GenRandom(seed,BASERATIO);
        if (costAll <= CREATE_COST_FEW) {
            baseR /= 2;
            if (random <= BASERATIO - baseR) {
                outLv = 1;
            }
            else {
                outLv = 2;
            }
        }
        else if (costAll <= CREATE_COST_MANY) {
            baseR = baseR*14/100;
            if (random <= BASERATIO*70/100-baseR) {
                outLv = 1;
            }
            else if (random <= BASERATIO*95/100-baseR/4) {
                outLv = 2;
            }
            else {
                outLv = 3;
            }
        }
        else {
            baseR = baseR*11/100;
            if (random <= BASERATIO*50/100-baseR) {
                outLv = 1;
            }
            else if (random <= BASERATIO*90/100-baseR/3) {
                outLv = 2;
            }
            else {
                outLv = 3;
            }
        }
        return (outLv,seed);
    }

    function GenOutChipsNum(uint seed, uint costAll, uint x) internal view returns(uint,uint)
    {
        uint amount;
        uint random;
        uint baseR = BASERATIO*x/100;
        (random,seed) = GenRandom(seed,BASERATIO);
        if (costAll <= CREATE_COST_FEW) {
            if (random <= BASERATIO - baseR) {
                amount = 3;
            }
            else {
                amount = 4;
            }
        }
        else {
            baseR /= 10;
            if (costAll <= CREATE_COST_MANY) {
                if (random <= BASERATIO*7/10 - baseR*2) {
                    amount = 3;
                }
                else if (random <= BASERATIO*3/10 + baseR) {
                    amount = 4;
                }
                else {
                    amount = 5;
                }
            }
            else {
                if (random <= BASERATIO*7/10 - baseR) {
                    amount = 4;
                }
                else {
                    amount = 5;
                }
            }
        }
        return (amount,seed);
    }

    function GetMinCost(uint a, uint b, uint c) internal pure returns(uint)
    {
        if (a>b) {
            if (a>c) return a;
        }
        else if (b>c) return b;
        else return c;
    }

    function GenExtWeightList(uint costA, uint costB, uint costC) internal pure returns(uint[],uint[],uint[])
    {
        uint min = GetMinCost(costA,costB,costC);
        uint[] memory extWeight3 = new uint[](3);
        uint[] memory extWeight4 = new uint[](4);
        uint[] memory extWeight5 = new uint[](5);
        extWeight3[0] = costA;
        extWeight4[0] = costA;
        extWeight5[0] = costA;
        extWeight3[1] = costB;
        extWeight4[1] = costB;
        extWeight5[1] = costB;
        extWeight3[2] = costC;
        extWeight4[2] = costC;
        extWeight5[2] = costC;
        extWeight5[3] = min;
        min = min/2;
        extWeight4[3] = min;
        extWeight5[4] = min;
        return (extWeight3,extWeight4,extWeight5);
    }

    function GenChipsLevel(uint costAll,bool bUseX) internal view returns(uint8[] lvList, uint seed)
    {
        // calculate amount, chips by random
        uint x = costAll - CREATE_COST_MIN;
        uint i;
        uint amount;
        // cal chips amount
        (amount,seed) = GenOutChipsNum(0,costAll,x);
        lvList = new uint8[](amount);
        if (bUseX) {
            (lvList[0], seed) = GenChipLevel_Special(costAll,x,seed);
            for (i=1; i<amount; i++)
            {
                (lvList[i], seed) = GenChipLevel_Extra(costAll,x,seed);
            }
        }
        else {
            for (i=0; i<amount; i++)
            {
                (lvList[i], seed) = GenChipLevel_General(costAll,x,seed);
            }
        }

    }

    function CreateChips(uint costAll, uint costA, uint costB, uint costC, bool bUseX) internal returns(uint32[])
    {
        (uint[] memory ext3,
         uint[] memory ext4,
         uint[] memory ext5
        ) = GenExtWeightList(costA,costB,costC);

        (uint8[] memory lvList, uint seed) = GenChipsLevel(costAll,bUseX);
        uint32[] memory chips = new uint32[](lvList.length);
        for (uint i=0; i<lvList.length; i++)
        {
            uint8 chipLv = lvList[i];
            (chips[i], seed) = GenChipIndex(seed,chipLv,ext3,ext4,ext5);
        }
        return chips;
    }

    function GetPermissionIdx(uint idx) internal pure returns(uint32)
    {
        if (idx == 1) return PERMISSION_1;
        else if (idx == 2) return PERMISSION_2;
        return 0;
    }

    function IsBoilerValid(uint idx) internal view returns(bool)
    {
        if (idx != BOILER_FREE_IDX) {
            uint32 iStuff = GetPermissionIdx(idx);
            if (iStuff == 0) return false;
            if (g_Main.GetTempStuffExpire(msg.sender,iStuff) < now) return false;
        }
        return g_Boilers.IsBoilerValid(msg.sender,idx);
    }

    function CollectChips(uint idx) internal
    {
        uint32[] memory chips = g_Boilers.CollectChips(msg.sender,idx);
        for (uint i=0; i<chips.length; i++)
        {
            g_Main.GainChip(msg.sender,chips[i],true);
        }
    }

    function GetExchangePoint(uint8 chipLv) internal pure returns(uint)
    {
        if (chipLv == 1) return 1;
        else if (chipLv == 2) return 3;
        else if (chipLv == 3) return 10;
        else if (chipLv == 4) return 30;
        else if (chipLv == 5) return 120;
        return 0;
    }

    //=========================================================================

    function Create(uint idx,uint costA, uint costB, uint costC, bool bUseX) external
    {
        require(costA <= CREATE_COST_MAX);
        require(costB <= CREATE_COST_MAX);
        require(costC <= CREATE_COST_MAX);
        uint costAll = costA+costB+costC;
        require(costAll>=CREATE_COST_MIN && costAll<=CREATE_COST_MAX);

        require(IsBoilerValid(idx));

        g_Main.CostStuff(msg.sender,STUFF_IDX_GENRAL,costAll);
        if (bUseX) g_Main.CostStuff(msg.sender,STUFF_IDX_EXTRA,1);
        uint CD;
        if (costAll <= CREATE_COST_FEW) {
            CD = COOLTIME_MIN;
        }
        else if (costAll <= CREATE_COST_MANY) {
            CD = COOLTIME_MID;
        }
        else {
            CD = COOLTIME_MAX;
        }

        uint32[] memory chips = CreateChips(costAll,costA,costB,costC,bUseX);
        g_Boilers.GenerateChips(msg.sender,idx,CD,chips);
    }

    function GetBoilersInfo() external view returns(uint[], uint32[], uint32[], uint32[] )
    {
        uint[] memory expireList = new uint[](BOILER_MAX_NUM);
        uint32[][] memory allChips = new uint32[][](BOILER_MAX_NUM);
        for (uint i=BOILER_FREE_IDX; i<BOILER_MAX_NUM; i++)
        {
            (uint expire, uint32[] memory chips) = g_Boilers.GetBoilerInfo(msg.sender,i);
            expireList[i] = expire;
            allChips[i] = chips;
        }
        return (
            expireList,
            allChips[0],
            allChips[1],
            allChips[2]
        );
    }

    function ResolveChips(uint32[] chips) external
    {
        for (uint i=0; i<chips.length; i++)
        {
            uint32 iChip = chips[i];
            g_Main.CostChip(msg.sender,iChip);
            (,uint8 lv,,,,) = g_Main.GetChipInfo(iChip);
            uint point = GetExchangePoint(lv);
            g_Main.GainStuff(msg.sender,STUFF_IDX_POINT,point);
        }
    }

    function Collect(uint idx) external
    {
        require(g_Boilers.IsBoilerExpire(msg.sender,idx));
        require(!g_Boilers.IsBoilerValid(msg.sender,idx));
        CollectChips(idx);
    }

    function Accelerate(uint idx) external payable
    {
        (uint expire,) = g_Boilers.GetBoilerInfo(msg.sender,idx);
        require(expire > now);
        uint remain = expire-now;
        uint num = remain/ACCELERATE_UNITTIME;
        if (remain != num*ACCELERATE_UNITTIME) {
            num++;
        }
        uint fee = num*ACCELERATE_UNITFEE;
        require(fee == msg.value);
        AddBonus(BONUS_PERCENT_ACCELERATE);
        CollectChips(idx);
    }

}