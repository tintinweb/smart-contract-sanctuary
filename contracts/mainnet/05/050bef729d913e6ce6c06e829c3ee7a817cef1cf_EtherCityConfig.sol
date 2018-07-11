pragma solidity ^0.4.0;

library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0 || b == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  function muldiv(uint256 a, uint256 b, uint256 c) internal pure returns (uint256 d) {
    if (a == 0 || b == 0) {
      return 0;
    }
    d = a * b;
    assert(d / a == b);
    return d / c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract EtherCityConfig
{
    struct BuildingData
    {
        uint256 population;
        uint256 creditsPerSec;   // *100
        uint256 maxUpgrade;
        uint256 constructCredit;
        uint256 constructEther;
        uint256 upgradeCredit;
        uint256 demolishCredit;

        uint256 constructSale;
        uint256 upgradeSale;
        uint256 demolishSale;
    }

    uint256 private initCredits;
    uint256 private initLandCount;
    uint256 private initcreditsPerSec;

    uint256 private maxLandCount;
    uint256 private ethLandCost;

    uint256 private creditsPerEth;

    address private owner;
    address private admin;

    mapping(uint256 => BuildingData) private buildingData;
    
    constructor() public payable
    {
        owner = msg.sender;
        creditsPerEth = 1;
    }

    function SetAdmin(address addr) external
    {
        assert(msg.sender == owner);

        admin = addr;
    }
    
    function GetVersion() external pure returns(uint256)
    {
        return 1000;
    }

    function GetInitData() external view returns(uint256 ethland, uint256 maxland, uint256 credits, uint256 crdtsec, uint256 landCount)
    {
        ethland = ethLandCost;
        maxland = maxLandCount;
        credits = initCredits;
        crdtsec = initcreditsPerSec;
        landCount = initLandCount;
    }

    function SetInitData(uint256 ethland, uint256 maxland, uint256 credits, uint256 crdtsec, uint256 landCount) external
    {
        require(msg.sender == owner || msg.sender == admin);

        ethLandCost = ethland;
        maxLandCount = maxland;
        initCredits = credits;
        initcreditsPerSec = crdtsec;
        initLandCount = landCount;
    }

    function GetCreditsPerEth() external view returns(uint256)
    {
        return creditsPerEth;
    }

    function SetCreditsPerEth(uint256 crdteth) external
    {
        require(crdteth > 0);
        require(msg.sender == owner || msg.sender == admin);

        creditsPerEth = crdteth;
    }

    function GetLandData() external view returns(uint256 ethland, uint256 maxland)
    {
        ethland = ethLandCost;
        maxland = maxLandCount;
    }

    function GetBuildingData(uint256 id) external view returns(uint256 bid, uint256 population, uint256 crdtsec, 
                            uint256 maxupd, uint256 cnstcrdt, uint256 cnsteth, uint256 updcrdt, uint256 dmlcrdt,
                            uint256 cnstcrdtsale, uint256 cnstethsale, uint256 updcrdtsale, uint256 dmlcrdtsale)
    {
        BuildingData storage bdata = buildingData[id];

        bid = id;
        population = bdata.population;   // *100
        crdtsec = bdata.creditsPerSec;   // *100
        maxupd = bdata.maxUpgrade;
        cnstcrdt = bdata.constructCredit;
        cnsteth = bdata.constructEther;
        updcrdt = bdata.upgradeCredit;
        dmlcrdt = bdata.demolishCredit;
        cnstcrdtsale = bdata.constructCredit * bdata.constructSale / 100;
        cnstethsale = bdata.constructEther * bdata.constructSale /100;
        updcrdtsale = bdata.upgradeCredit * bdata.upgradeSale / 100;
        dmlcrdtsale = bdata.demolishCredit * bdata.demolishSale / 100;
    }

    function SetBuildingData(uint256 bid, uint256 pop, uint256 crdtsec, uint256 maxupd,
                            uint256 cnstcrdt, uint256 cnsteth, uint256 updcrdt, uint256 dmlcrdt) external
    {
        require(msg.sender == owner || msg.sender == admin);

        buildingData[bid] = BuildingData({population:pop, creditsPerSec:crdtsec, maxUpgrade:maxupd,
                            constructCredit:cnstcrdt, constructEther:cnsteth, upgradeCredit:updcrdt, demolishCredit:dmlcrdt,
                            constructSale:100, upgradeSale:100, demolishSale:100
                            });
    }

    function SetBuildingSale(uint256 bid, uint256 cnstsale, uint256 updsale, uint256 dmlsale) external
    {
        BuildingData storage bdata = buildingData[bid];

        require(0 < cnstsale && cnstsale <= 100);
        require(0 < updsale && updsale <= 100);
        require(msg.sender == owner || msg.sender == admin);

        bdata.constructSale = cnstsale;
        bdata.upgradeSale = updsale;
        bdata.demolishSale = dmlsale;
    }

    function SetBuildingDataArray(uint256[] data) external
    {
        require(data.length % 8 == 0);
        require(msg.sender == owner || msg.sender == admin);

        for(uint256 index = 0; index < data.length; index += 8)
        {
            BuildingData storage bdata = buildingData[data[index]];

            bdata.population = data[index + 1];
            bdata.creditsPerSec = data[index + 2];
            bdata.maxUpgrade = data[index + 3];
            bdata.constructCredit = data[index + 4];
            bdata.constructEther = data[index + 5];
            bdata.upgradeCredit = data[index + 6];
            bdata.demolishCredit = data[index + 7];
            bdata.constructSale = 100;
            bdata.upgradeSale = 100;
            bdata.demolishSale = 100;
        }
    }

    function GetBuildingParam(uint256 id) external view
                returns(uint256 population, uint256 crdtsec, uint256 maxupd)
    {
        BuildingData storage bdata = buildingData[id];

        population = bdata.population;   // *100
        crdtsec = bdata.creditsPerSec;   // *100
        maxupd = bdata.maxUpgrade;
    }

    function GetConstructCost(uint256 id, uint256 count) external view
                returns(uint256 cnstcrdt, uint256 cnsteth)
    {
        BuildingData storage bdata = buildingData[id];

        cnstcrdt = bdata.constructCredit * bdata.constructSale / 100  * count;
        cnsteth = bdata.constructEther * bdata.constructSale / 100  * count;
    }

    function GetUpgradeCost(uint256 id, uint256 count) external view
                returns(uint256 updcrdt)
    {
        BuildingData storage bdata = buildingData[id];

        updcrdt = bdata.upgradeCredit * bdata.upgradeSale / 100 * count;
    }

    function GetDemolishCost(uint256 id, uint256 count) external view
                returns(uint256)
    {
        BuildingData storage bdata = buildingData[id];

        return bdata.demolishCredit * bdata.demolishSale / 100 * count;
   }
}

contract EtherCityRank
{
    struct LINKNODE
    {
        uint256 count;
        uint256 leafLast;
    }

    struct LEAFNODE
    {
        address player;
        uint256 population;
        uint256 time;

        uint256 prev;
        uint256 next;
    }

    uint256 private constant LINK_NULL = uint256(-1);
    uint256 private constant LEAF_PER_LINK = 30;
    uint256 private constant LINK_COUNT = 10;
    uint256 private constant LINK_ENDIDX = LINK_COUNT - 1;

    mapping(uint256 => LINKNODE) private linkNodes; // 30 * 10 = 300rank
    mapping(uint256 => LEAFNODE) private leafNodes;
    uint256 private leafCount;

    address private owner;
    address private admin;
    address private city;
    
    constructor() public payable
    {
        owner = msg.sender;

        for(uint256 index = 1; index < LINK_COUNT; index++)
            linkNodes[index] = LINKNODE({count:0, leafLast:LINK_NULL});

        // very first rank
        linkNodes[0] = LINKNODE({count:1, leafLast:0});
        leafNodes[0] = LEAFNODE({player:address(0), population:uint256(-1), time:0, prev:LINK_NULL, next:LINK_NULL});
        leafCount = 1;
    }

    function GetVersion() external pure returns(uint256)
    {
        return 1000;
    }

    function GetRank(uint16 rankidx) external view returns(address player, uint256 pop, uint256 time, uint256 nextidx)
    {
        uint256 leafidx;

        if (rankidx == 0)
            leafidx = leafNodes[0].next;
        else
            leafidx = rankidx;

        if (leafidx != LINK_NULL)
        {
            player = leafNodes[leafidx].player;
            pop = leafNodes[leafidx].population;
            time = leafNodes[leafidx].time;
            nextidx = leafNodes[leafidx].next;
        }
        else
        {
            player = address(0);
            pop = 0;
            time = 0;
            nextidx = 0;
        }
    }

    function UpdateRank(address player, uint256 pop_new, uint256 time_new) external
    {
        bool found;
        uint256 linkidx;
        uint256 leafidx;
        uint256 emptyidx;

        require(owner == msg.sender || admin == msg.sender || city == msg.sender);

        emptyidx = RemovePlayer(player);

        (found, linkidx, leafidx) = findIndex(pop_new, time_new);
        if (linkidx == LINK_NULL)
            return;

        if (linkNodes[LINK_ENDIDX].count == LEAF_PER_LINK)
        {   // remove overflow
            emptyidx = linkNodes[LINK_ENDIDX].leafLast;
            RemoveRank(LINK_ENDIDX, emptyidx);
        }
        else if (emptyidx == LINK_NULL)
        {
            emptyidx = leafCount;
            leafCount++;
        }

        leafNodes[emptyidx] = LEAFNODE({player:player, population:pop_new, time:time_new, prev:LINK_NULL, next:LINK_NULL});

        // insert emptyidx before leafidx
        InsertRank(linkidx, leafidx, emptyidx);
    }

    /////////////////////////////////////////////////////////////////
    //
    function adminSetAdmin(address addr) external
    {
        require(owner == msg.sender);

        admin = addr;
    }

    function adminSetCity(address addr) external
    {
        require(owner == msg.sender || admin == msg.sender);

        city = addr;
    }

    function adminResetRank() external
    {
        require(owner == msg.sender || admin == msg.sender);

        for(uint256 index = 1; index < LINK_COUNT; index++)
            linkNodes[index] = LINKNODE({count:0, leafLast:LINK_NULL});

        // very first rank
        linkNodes[0] = LINKNODE({count:1, leafLast:0});
        leafNodes[0] = LEAFNODE({player:address(0), population:uint256(-1), time:0, prev:LINK_NULL, next:LINK_NULL});
        leafCount = 1;
    }

    /////////////////////////////////////////////////////////////////
    //
    function findIndex(uint256 pop, uint256 time) private view returns(bool found, uint256 linkidx, uint256 leafidx)
    {
        uint256 comp;

        found = false;

        for(linkidx = 0; linkidx < LINK_COUNT; linkidx++)
        {
            LINKNODE storage lknode = linkNodes[linkidx];
            if (lknode.count < LEAF_PER_LINK)
                break;

            LEAFNODE storage lfnode = leafNodes[lknode.leafLast];
            if ((compareLeaf(pop, time, lfnode.population, lfnode.time) >= 1))
                break;
        }

        if (linkidx == LINK_COUNT)
        {
            linkidx = (linkNodes[LINK_ENDIDX].count < LEAF_PER_LINK) ? LINK_ENDIDX : LINK_NULL;
            leafidx = LINK_NULL;
            return;
        }
            
        leafidx = lknode.leafLast;
        for(uint256 index = 0; index < lknode.count; index++)
        {
            lfnode = leafNodes[leafidx];
            comp = compareLeaf(pop, time, lfnode.population, lfnode.time);
            if (comp == 0)  // <
            {
                leafidx = lfnode.next;
                break;
            }
            else if (comp == 1) // ==
            {
                found = true;
                break;
            }

            if (index + 1 < lknode.count)
                leafidx = lfnode.prev;
        }
    }
    
    function InsertRank(uint256 linkidx, uint256 leafidx_before, uint256 leafidx_new) private
    {
        uint256 leafOnLink;
        uint256 leafLast;

        if (leafidx_before == LINK_NULL)
        {   // append
            leafLast = linkNodes[linkidx].leafLast;
            if (leafLast != LINK_NULL)
                ConnectLeaf(leafidx_new, leafNodes[leafLast].next);
            else
                leafNodes[leafidx_new].next = LINK_NULL;

            ConnectLeaf(leafLast, leafidx_new);
            linkNodes[linkidx].leafLast = leafidx_new;
            linkNodes[linkidx].count++;
            return;
        }

        ConnectLeaf(leafNodes[leafidx_before].prev, leafidx_new);
        ConnectLeaf(leafidx_new, leafidx_before);

        leafLast = LINK_NULL;
        for(uint256 index = linkidx; index < LINK_COUNT; index++)
        {
            leafOnLink = linkNodes[index].count;
            if (leafOnLink < LEAF_PER_LINK)
            {
                if (leafOnLink == 0) // add new
                    linkNodes[index].leafLast = leafLast;

                linkNodes[index].count++;
                break;
            }

            leafLast = linkNodes[index].leafLast;
            linkNodes[index].leafLast = leafNodes[leafLast].prev;
        }
    }

    function RemoveRank(uint256 linkidx, uint256 leafidx) private
    {
        uint256 next;

        for(uint256 index = linkidx; index < LINK_COUNT; index++)
        {
            LINKNODE storage link = linkNodes[index];
            
            next = leafNodes[link.leafLast].next;
            if (next == LINK_NULL)
            {
                link.count--;
                if (link.count == 0)
                    link.leafLast = LINK_NULL;
                break;
            }
            else
                link.leafLast = next;
        }

        LEAFNODE storage leaf_cur = leafNodes[leafidx];
        if (linkNodes[linkidx].leafLast == leafidx)
            linkNodes[linkidx].leafLast = leaf_cur.prev;

        ConnectLeaf(leaf_cur.prev, leaf_cur.next);
    }

    function RemovePlayer(address player) private returns(uint256 leafidx)
    {
        for(uint256 linkidx = 0; linkidx < LINK_COUNT; linkidx++)
        {
            LINKNODE storage lknode = linkNodes[linkidx];

            leafidx = lknode.leafLast;
            for(uint256 index = 0; index < lknode.count; index++)
            {
                LEAFNODE storage lfnode = leafNodes[leafidx];

                if (lfnode.player == player)
                {
                    RemoveRank(linkidx, leafidx);
                    return;
                }

                leafidx = lfnode.prev;
            }
        }

        return LINK_NULL;
    }

    function ConnectLeaf(uint256 leafprev, uint256 leafnext) private
    {
        if (leafprev != LINK_NULL)
            leafNodes[leafprev].next = leafnext;

        if (leafnext != LINK_NULL)
            leafNodes[leafnext].prev = leafprev;
    }

    function compareLeaf(uint256 pop1, uint256 time1, uint256 pop2, uint256 time2) private pure returns(uint256)
    {
        if (pop1 > pop2)
            return 2;
        else if (pop1 < pop2)
            return 0;

        if (time1 > time2)
            return 2;
        else if (time1 < time2)
            return 0;

        return 1;
    }
}

contract EtherCityData
{
    struct WORLDDATA
    {
        uint256 ethBalance;
        uint256 ethDev;

        uint256 population;
        uint256 credits;

        uint256 starttime;
    }

    struct WORLDSNAPSHOT
    {
        bool valid;
        uint256 ethDay;
        uint256 ethBalance;
        uint256 ethRankFund;
        uint256 ethShopFund;

        uint256 ethRankFundRemain;
        uint256 ethShopFundRemain;

        uint256 population;
        uint256 credits;

        uint256 lasttime;
    }

    struct CITYDATA
    {
        bytes32 name;

        uint256 credits;

        uint256 population;
        uint256 creditsPerSec;   // *100

        uint256 landOccupied;
        uint256 landUnoccupied;

        uint256 starttime;
        uint256 lasttime;
        uint256 withdrawSS;
    }

    struct CITYSNAPSHOT
    {
        bool valid;

        uint256 population;
        uint256 credits;

        uint256 shopCredits;

        uint256 lasttime;
    }

    struct BUILDINGDATA
    {
        uint256 constructCount;
        uint256 upgradeCount;

        uint256 population;
        uint256 creditsPerSec;   // *100
    }

    uint256 private constant INTFLOATDIV = 100;

    address private owner;
    address private admin;
    address private city;
    bool private enabled;

    WORLDDATA private worldData;
    mapping(uint256 => WORLDSNAPSHOT) private worldSnapshot;

    address[] private playerlist;
    mapping(address => CITYDATA) private cityData;
    mapping(address => mapping(uint256 => CITYSNAPSHOT)) private citySnapshot;
    mapping(address => mapping(uint256 => BUILDINGDATA)) private buildings;
    mapping(address => uint256) private ethBalance;


    constructor() public payable
    {
        owner = msg.sender;

        enabled = true;
        worldData = WORLDDATA({ethBalance:0, ethDev:0, population:0, credits:0, starttime:block.timestamp});
        worldSnapshot[nowday()] = WORLDSNAPSHOT({valid:true, ethDay:0, ethBalance:0, ethRankFund:0, ethShopFund:0, ethRankFundRemain:0, ethShopFundRemain:0, population:0, credits:0, lasttime:block.timestamp});
    }

    function GetVersion() external pure returns(uint256)
    {
        return 1001;
    }

    function IsPlayer(address player) external view returns(bool)
    {
        for(uint256 index = 0; index < playerlist.length; index++)
         {
             if (playerlist[index] == player)
                return true;
         }

        return false;
    }

    function IsCityNameExist(bytes32 cityname) external view returns(bool)
    {
        for(uint256 index = 0; index < playerlist.length; index++)
        {
            if (cityData[playerlist[index]].name == cityname)
               return false;
        }

        return true;
    }

    function CreateCityData(address player, uint256 crdtsec, uint256 landcount) external
    {
        uint256 day;

        require(cityData[player].starttime == 0);
        require(owner == msg.sender || admin == msg.sender || (enabled && city == msg.sender));

        playerlist.push(player);    // new player

        day = nowday();
        cityData[player] = CITYDATA({name:0, credits:0, population:0, creditsPerSec:crdtsec, landOccupied:0, landUnoccupied:landcount, starttime:block.timestamp, lasttime:block.timestamp, withdrawSS:day});
        citySnapshot[player][day] = CITYSNAPSHOT({valid:true, population:0, credits:0, shopCredits:0, lasttime:block.timestamp});
    }

    function GetWorldData() external view returns(uint256 ethBal, uint256 ethDev, uint256 population, uint256 credits, uint256 starttime)
    {
        require(owner == msg.sender || admin == msg.sender || city == msg.sender);

        ethBal = worldData.ethBalance;
        ethDev = worldData.ethDev;
        population = worldData.population;
        credits = worldData.credits;
        starttime = worldData.starttime;
    }

    function SetWorldData(uint256 ethBal, uint256 ethDev, uint256 population, uint256 credits, uint256 starttime) external
    {
        require(owner == msg.sender || admin == msg.sender || (enabled && city == msg.sender));

        worldData.ethBalance = ethBal;
        worldData.ethDev = ethDev;
        worldData.population = population;
        worldData.credits = credits;
        worldData.starttime = starttime;
    }

    function SetWorldSnapshot(uint256 day, bool valid, uint256 population, uint256 credits, uint256 lasttime) external
    {
        WORLDSNAPSHOT storage wss = worldSnapshot[day];

        require(owner == msg.sender || admin == msg.sender || (enabled && city == msg.sender));

        wss.valid = valid;
        wss.population = population;
        wss.credits = credits;
        wss.lasttime = lasttime;
    }

    function GetCityData(address player) external view returns(uint256 credits, uint256 population, uint256 creditsPerSec,
                                    uint256 landOccupied, uint256 landUnoccupied, uint256 lasttime)
    {
        CITYDATA storage cdata = cityData[player];

        require(owner == msg.sender || admin == msg.sender || city == msg.sender);

        credits = cdata.credits;
        population = cdata.population;
        creditsPerSec = cdata.creditsPerSec;
        landOccupied = cdata.landOccupied;
        landUnoccupied = cdata.landUnoccupied;
        lasttime = cdata.lasttime;
    }

    function SetCityData(address player, uint256 credits, uint256 population, uint256 creditsPerSec,
                        uint256 landOccupied, uint256 landUnoccupied, uint256 lasttime) external
    {
        CITYDATA storage cdata = cityData[player];

        require(owner == msg.sender || admin == msg.sender || (enabled && city == msg.sender));

        cdata.credits = credits;
        cdata.population = population;
        cdata.creditsPerSec = creditsPerSec;
        cdata.landOccupied = landOccupied;
        cdata.landUnoccupied = landUnoccupied;
        cdata.lasttime = lasttime;
    }

    function GetCityName(address player) external view returns(bytes32)
    {
        return cityData[player].name;
    }

    function SetCityName(address player, bytes32 name) external
    {
        require(owner == msg.sender || admin == msg.sender || (enabled && city == msg.sender));

        cityData[player].name = name;
    }

    function GetCitySnapshot(address player, uint256 day) external view returns(bool valid, uint256 population, uint256 credits, uint256 shopCredits, uint256 lasttime)
    {
        CITYSNAPSHOT storage css = citySnapshot[player][day];

        require(owner == msg.sender || admin == msg.sender || city == msg.sender);

        valid = css.valid;
        population = css.population;
        credits = css.credits;
        shopCredits = css.shopCredits;
        lasttime = css.lasttime;
    }

    function SetCitySnapshot(address player, uint256 day, bool valid, uint256 population, uint256 credits, uint256 shopCredits, uint256 lasttime) external
    {
        CITYSNAPSHOT storage css = citySnapshot[player][day];

        require(owner == msg.sender || admin == msg.sender || (enabled && city == msg.sender));

        css.valid = valid;
        css.population = population;
        css.credits = credits;
        css.shopCredits = shopCredits;
        css.lasttime = lasttime;
    }

    function GetBuildingData(address player, uint256 id) external view returns(uint256 constructCount, uint256 upgradeCount, uint256 population, uint256 creditsPerSec)
    {
        BUILDINGDATA storage bdata = buildings[player][id];

        require(owner == msg.sender || admin == msg.sender || city == msg.sender);

        constructCount = bdata.constructCount;
        upgradeCount = bdata.upgradeCount;
        population = bdata.population;
        creditsPerSec = bdata.creditsPerSec;
    }

    function SetBuildingData(address player, uint256 id, uint256 constructCount, uint256 upgradeCount, uint256 population, uint256 creditsPerSec) external
    {
        BUILDINGDATA storage bdata = buildings[player][id];

        require(owner == msg.sender || admin == msg.sender || (enabled && city == msg.sender));

        bdata.constructCount = constructCount;
        bdata.upgradeCount = upgradeCount;
        bdata.population = population;
        bdata.creditsPerSec = creditsPerSec;
    }

    function GetEthBalance(address player) external view returns(uint256)
    {
        require(owner == msg.sender || admin == msg.sender || city == msg.sender);

        return ethBalance[player];
    }

    function SetEthBalance(address player, uint256 eth) external
    {
        require(owner == msg.sender || admin == msg.sender || (enabled && city == msg.sender));

        ethBalance[player] = eth;
    }

    function AddEthBalance(address player, uint256 eth) external
    {
        require(owner == msg.sender || admin == msg.sender || (enabled && city == msg.sender));

        ethBalance[player] += eth;
    }

    function GetWithdrawBalance(address player) external view returns(uint256 ethBal)
    {
        uint256 startday;

        require(owner == msg.sender || admin == msg.sender || city == msg.sender);

        ethBal = ethBalance[player];

        startday = cityData[player].withdrawSS;
        for(uint256 day = nowday() - 1; day >= startday; day--)
        {
            WORLDSNAPSHOT memory wss = TestWorldSnapshotInternal(day);
            CITYSNAPSHOT memory css = TestCitySnapshotInternal(player, day);
            ethBal += Math.min256(SafeMath.muldiv(wss.ethRankFund, css.population, wss.population), wss.ethRankFundRemain);
        }
    }

    function WithdrawEther(address player) external
    {
        uint256 startday;
        uint256 ethBal;
        uint256 eth;
        CITYDATA storage cdata = cityData[player];

        require(owner == msg.sender || admin == msg.sender || (enabled && city == msg.sender));

        ethBal = ethBalance[player];

        startday = cdata.withdrawSS;
        for(uint256 day = nowday() - 1; day >= startday; day--)
        {
            WORLDSNAPSHOT storage wss = ValidateWorldSnapshotInternal(day);
            CITYSNAPSHOT storage css = ValidateCitySnapshotInternal(player, day);

            if (wss.ethRankFundRemain > 0)
            {
                eth = Math.min256(SafeMath.muldiv(wss.ethRankFund, css.population, wss.population), wss.ethRankFundRemain);
                wss.ethRankFundRemain -= eth;
                ethBal += eth;
            }
        }

        require(0 < ethBal);

        ethBalance[player] = 0;
        cdata.withdrawSS = nowday() - 1;

        player.transfer(ethBal);
    }

    function GetEthShop(address player) external view returns(uint256 shopEth, uint256 shopCredits)
    {
        uint256 day;
        CITYSNAPSHOT memory css;
        WORLDSNAPSHOT memory wss;

        require(owner == msg.sender || admin == msg.sender || city == msg.sender);

        day = nowday() - 1;
        if (day < cityData[player].starttime / 24 hours)
        {
            shopEth = 0;
            shopCredits = 0;
            return;
        }

        wss = TestWorldSnapshotInternal(day);
        css = TestCitySnapshotInternal(player, day);

        shopEth = Math.min256(SafeMath.muldiv(wss.ethShopFund, css.shopCredits, wss.credits), wss.ethShopFundRemain);
        shopCredits = css.shopCredits;
    }

    function TradeEthShop(address player, uint256 credits) external
    {
        uint256 day;
        uint256 shopEth;

        require(owner == msg.sender || admin == msg.sender || (enabled && city == msg.sender));

        day = nowday() - 1;
        require(day >= cityData[player].starttime / 24 hours);

        WORLDSNAPSHOT storage wss = ValidateWorldSnapshotInternal(day);
        CITYSNAPSHOT storage css = ValidateCitySnapshotInternal(player, day);

        require(wss.ethShopFundRemain > 0);
        require((0 < credits) && (credits <= css.shopCredits));

        shopEth = Math.min256(SafeMath.muldiv(wss.ethShopFund, css.shopCredits, wss.credits), wss.ethShopFundRemain);

        wss.ethShopFundRemain -= shopEth;
        css.shopCredits -= credits;

        ethBalance[player] += shopEth;
    }

    function UpdateEthBalance(uint256 bal, uint256 devf, uint256 rnkf, uint256 shpf) external payable
    {
        require(owner == msg.sender || admin == msg.sender || (enabled && city == msg.sender));

        worldData.ethBalance += bal + devf + rnkf + shpf;
        worldData.ethDev += devf;

        WORLDSNAPSHOT storage wss = ValidateWorldSnapshotInternal(nowday());
        wss.ethDay += bal + devf + rnkf + shpf;
        wss.ethBalance += bal;
        wss.ethRankFund += rnkf;
        wss.ethShopFund += shpf;
        wss.ethRankFundRemain += rnkf;
        wss.ethShopFundRemain += shpf;
        wss.lasttime = block.timestamp;

        ethBalance[owner] += devf;
    }

    function ValidateWorldSnapshot(uint256 day) external returns(uint256 ethRankFund, uint256 population, uint256 credits, uint256 lasttime)
    {
        WORLDSNAPSHOT storage wss = ValidateWorldSnapshotInternal(day);

        require(owner == msg.sender || admin == msg.sender || (enabled && city == msg.sender));

        ethRankFund = wss.ethRankFund;
        population = wss.population;
        credits = wss.credits;
        lasttime = wss.lasttime;
    }

    function TestWorldSnapshot(uint256 day) external view returns(uint256 ethRankFund, uint256 population, uint256 credits, uint256 lasttime)
    {
        WORLDSNAPSHOT memory wss = TestWorldSnapshotInternal(day);

        require(owner == msg.sender || admin == msg.sender || city == msg.sender);

        ethRankFund = wss.ethRankFund;
        population = wss.population;
        credits = wss.credits;
        lasttime = wss.lasttime;
    }

    function ValidateCitySnapshot(address player, uint256 day) external returns(uint256 population, uint256 credits, uint256 shopCredits, uint256 lasttime)
    {
        CITYSNAPSHOT storage css = ValidateCitySnapshotInternal(player, day);
    
        require(owner == msg.sender || admin == msg.sender || (enabled && city == msg.sender));

        population = css.population;
        credits = css.credits;
        shopCredits = css.shopCredits;
        lasttime = css.lasttime;
    }

    function TestCitySnapshot(address player, uint256 day) external view returns(uint256 population, uint256 credits, uint256 shopCredits, uint256 lasttime)
    {
        CITYSNAPSHOT memory css = TestCitySnapshotInternal(player, day);

        require(owner == msg.sender || admin == msg.sender || city == msg.sender);

        population = css.population;
        credits = css.credits;
        shopCredits = css.shopCredits;
        lasttime = css.lasttime;
    }

    /////////////////////////////////////////////////////////////////
    //
    function nowday() private view returns(uint256)
    {
        return block.timestamp / 24 hours;
    }

    function adminSetAdmin(address addr) external
    {
        require(owner == msg.sender);

        admin = addr;
    }

    function adminSetCity(address addr) external
    {
        require(owner == msg.sender || admin == msg.sender);

        city = addr;
    }

    function adminGetEnabled() external view returns(bool)
    {
        require(owner == msg.sender || admin == msg.sender);

        return enabled;
    }

    function adminSetEnabled(bool bval) external
    {
        require(owner == msg.sender || admin == msg.sender);

        enabled = bval;
    }

    function adminGetWorldData() external view returns(uint256 eth, uint256 ethDev,
                                                 uint256 population, uint256 credits, uint256 starttime)
    {
        require(msg.sender == owner || msg.sender == admin);

        eth = worldData.ethBalance;
        ethDev = worldData.ethDev;
        population = worldData.population;
        credits = worldData.credits;
        starttime = worldData.starttime;
    }

    function adminGetWorldSnapshot(uint256 day) external view returns(bool valid, uint256 ethDay, uint256 ethBal, uint256 ethRankFund, uint256 ethShopFund, uint256 ethRankFundRemain,
                                uint256 ethShopFundRemain, uint256 population, uint256 credits, uint256 lasttime)
    {
        WORLDSNAPSHOT storage wss = worldSnapshot[day];

        require(owner == msg.sender || admin == msg.sender);

        valid = wss.valid;
        ethDay = wss.ethDay;
        ethBal = wss.ethBalance;
        ethRankFund = wss.ethRankFund;
        ethShopFund = wss.ethShopFund;
        ethRankFundRemain = wss.ethRankFundRemain;
        ethShopFundRemain = wss.ethShopFundRemain;
        population = wss.population;
        credits = wss.credits;
        lasttime = wss.lasttime;
    }

    function adminSetWorldSnapshot(uint256 day, bool valid, uint256 ethDay, uint256 ethBal, uint256 ethRankFund, uint256 ethShopFund, uint256 ethRankFundRemain,
                                uint256 ethShopFundRemain, uint256 population, uint256 credits, uint256 lasttime) external
    {
        WORLDSNAPSHOT storage wss = worldSnapshot[day];

        require(owner == msg.sender || admin == msg.sender);

        wss.valid = valid;
        wss.ethDay = ethDay;
        wss.ethBalance = ethBal;
        wss.ethRankFund = ethRankFund;
        wss.ethShopFund = ethShopFund;
        wss.ethRankFundRemain = ethRankFundRemain;
        wss.ethShopFundRemain = ethShopFundRemain;
        wss.population = population;
        wss.credits = credits;
        wss.lasttime = lasttime;
    }

    function adminGetCityData(address player) external view returns(bytes32 name, uint256 credits, uint256 population, uint256 creditsPerSec,
                                    uint256 landOccupied, uint256 landUnoccupied, uint256 starttime, uint256 lasttime, uint256 withdrawSS)
    {
        CITYDATA storage cdata = cityData[player];

        require(owner == msg.sender || admin == msg.sender);

        name = cdata.name;
        credits = cdata.credits;
        population = cdata.population;
        creditsPerSec = cdata.creditsPerSec;
        landOccupied = cdata.landOccupied;
        landUnoccupied = cdata.landUnoccupied;
        starttime = cdata.starttime;
        lasttime = cdata.lasttime;
        withdrawSS = cdata.withdrawSS;
    }

    function adminSetCityData(address player, bytes32 name, uint256 credits, uint256 population, uint256 creditsPerSec,
                        uint256 landOccupied, uint256 landUnoccupied, uint256 starttime, uint256 lasttime, uint256 withdrawSS) external
    {
        CITYDATA storage cdata = cityData[player];

        require(owner == msg.sender || admin == msg.sender);

        cdata.name = name;
        cdata.credits = credits;
        cdata.population = population;
        cdata.creditsPerSec = creditsPerSec;
        cdata.landOccupied = landOccupied;
        cdata.landUnoccupied = landUnoccupied;
        cdata.starttime = starttime;
        cdata.lasttime = lasttime;
        cdata.withdrawSS = withdrawSS;
    }

    function adminUpdateWorldSnapshot() external
    {
        require(msg.sender == owner || msg.sender == admin);

        ValidateWorldSnapshotInternal(nowday());
    }

    function adminGetPastShopFund() external view returns(uint256 ethBal)
    {
        uint256 startday;
        WORLDSNAPSHOT memory wss;

        require(msg.sender == owner || msg.sender == admin);

        ethBal = 0;

        startday = worldData.starttime / 24 hours;
        for(uint256 day = nowday() - 2; day >= startday; day--)
        {
            wss = TestWorldSnapshotInternal(day);
            ethBal += wss.ethShopFundRemain;
        }
    }

    function adminCollectPastShopFund() external
    {
        uint256 startday;
        uint256 ethBal;

        require(msg.sender == owner || msg.sender == admin);

        ethBal = ethBalance[owner];

        startday = worldData.starttime / 24 hours;
        for(uint256 day = nowday() - 2; day >= startday; day--)
        {
            WORLDSNAPSHOT storage wss = ValidateWorldSnapshotInternal(day);

            ethBal += wss.ethShopFundRemain;
            wss.ethShopFundRemain = 0;
        }

        ethBalance[owner] = ethBal;
    }

    function adminSendWorldBalance() external payable
    {
        require(msg.sender == owner || msg.sender == admin);

        WORLDSNAPSHOT storage wss = ValidateWorldSnapshotInternal(nowday());
        wss.ethBalance += msg.value;
    }

    function adminTransferWorldBalance(uint256 eth) external
    {
        require(msg.sender == owner || msg.sender == admin);

        WORLDSNAPSHOT storage wss = ValidateWorldSnapshotInternal(nowday());
        require(eth <= wss.ethBalance);

        ethBalance[owner] += eth;
        wss.ethBalance -= eth;
    }

    function adminGetContractBalance() external view returns(uint256)
    {
        require(msg.sender == owner || msg.sender == admin);

        return address(this).balance;
    }

    function adminTransferContractBalance(uint256 eth) external
    {
        require(msg.sender == owner || msg.sender == admin);
        owner.transfer(eth);
    }

    function adminGetPlayerCount() external view returns(uint256)
    {
        require(msg.sender == owner || msg.sender == admin);

        return playerlist.length;
    }

    function adminGetPlayer(uint256 index) external view returns(address player, uint256 eth)
    {
        require(msg.sender == owner || msg.sender == admin);

        player = playerlist[index];
        eth = ethBalance[player];
    }


    /////////////////////////////////////////////////////////////////
    //
    function ValidateWorldSnapshotInternal(uint256 day) private returns(WORLDSNAPSHOT storage)
    {
        uint256 fndf;
        uint256 sday;

        sday = day;
        while (!worldSnapshot[sday].valid)
            sday--;

        WORLDSNAPSHOT storage prev = worldSnapshot[sday];
        sday++;

        while (sday <= day)
        {
            worldSnapshot[sday] = WORLDSNAPSHOT({valid:true, ethDay:0, ethBalance:0, ethRankFund:0, ethShopFund:0, ethRankFundRemain:0, ethShopFundRemain:0, population:prev.population, credits:prev.credits, lasttime:prev.lasttime / 24 hours + 1});
            WORLDSNAPSHOT storage wss = worldSnapshot[sday];
            wss.ethBalance = prev.ethBalance * 90 /100;
            fndf = prev.ethBalance - wss.ethBalance;
            wss.ethRankFund = fndf * 70 / 100;
            wss.ethShopFund = fndf - wss.ethRankFund;
            wss.ethRankFund = wss.ethRankFund;
            wss.ethShopFund = wss.ethShopFund;
            wss.ethRankFundRemain = wss.ethRankFund;
            wss.ethShopFundRemain = wss.ethShopFund;

            prev = wss;
            sday++;
        }

        return prev;
    }

    function TestWorldSnapshotInternal(uint256 day) private view returns(WORLDSNAPSHOT memory)
    {
        uint256 fndf;
        uint256 sday;

        sday = day;
        while (!worldSnapshot[sday].valid)
            sday--;

        WORLDSNAPSHOT memory prev = worldSnapshot[sday];
        sday++;

        while (sday <= day)
        {
            WORLDSNAPSHOT memory wss = WORLDSNAPSHOT({valid:true, ethDay:0, ethBalance:0, ethRankFund:0, ethShopFund:0, ethRankFundRemain:0, ethShopFundRemain:0, population:prev.population, credits:prev.credits, lasttime:prev.lasttime / 24 hours + 1});
            wss.ethBalance = prev.ethBalance * 90 /100;
            fndf = prev.ethBalance - wss.ethBalance;
            wss.ethRankFund = fndf * 70 / 100;
            wss.ethShopFund = fndf - wss.ethRankFund;
            wss.ethRankFund = wss.ethRankFund;
            wss.ethShopFund = wss.ethShopFund;
            wss.ethRankFundRemain = wss.ethRankFund;
            wss.ethShopFundRemain = wss.ethShopFund;

            prev = wss;
            sday++;
        }

        return prev;
    }

    function ValidateCitySnapshotInternal(address player, uint256 day) private returns(CITYSNAPSHOT storage)
    {
        uint256 sday;

        sday = day;
        while (!citySnapshot[player][sday].valid)
            sday--;

        CITYSNAPSHOT storage css = citySnapshot[player][sday];
        sday++;

        while (sday <= day)
        {
            citySnapshot[player][sday] = CITYSNAPSHOT({valid:true, population:css.population, credits:css.credits, shopCredits:css.credits, lasttime:sday * 24 hours});
            css = citySnapshot[player][sday];
            sday++;
        }
    
        return css;
    }

    function TestCitySnapshotInternal(address player, uint256 day) private view returns(CITYSNAPSHOT memory)
    {
        uint256 sday;

        sday = day;
        while (!citySnapshot[player][sday].valid)
            sday--;

        CITYSNAPSHOT memory css = citySnapshot[player][sday];
        sday++;

        while (sday <= day)
        {
            css = CITYSNAPSHOT({valid:true, population:css.population, credits:css.credits, shopCredits:css.credits, lasttime:sday * 24 hours});
            sday++;
        }

        return css;
    }
}


contract EtherCity
{
    struct WORLDDATA
    {
        uint256 ethBalance;
        uint256 ethDev;

        uint256 population;
        uint256 credits;

        uint256 starttime;
    }

    struct WORLDSNAPSHOT
    {
        uint256 population;
        uint256 credits;
        uint256 lasttime;
    }

    struct CITYDATA
    {
        uint256 credits;

        uint256 population;
        uint256 creditsPerSec;   // *100

        uint256 landOccupied;
        uint256 landUnoccupied;

        uint256 lasttime;
    }

    struct CITYSNAPSHOT
    {
        uint256 population;
        uint256 credits;

        uint256 shopCredits;

        uint256 lasttime;
    }

    struct BUILDINGDATA
    {
        uint256 constructCount;
        uint256 upgradeCount;

        uint256 population;
        uint256 creditsPerSec;   // *100
    }

    uint256 private constant INTFLOATDIV = 100;

    address private owner;
    address private admin;

    EtherCityConfig private config;
    EtherCityData private data;
    EtherCityRank private rank;

    // events
    event OnConstructed(address player, uint256 id, uint256 count);
    event OnUpdated(address player, uint256 id, uint256 count);
    event OnDemolished(address player, uint256 id, uint256 count);
    event OnBuyLands(address player, uint256 count);
    event OnBuyCredits(address player, uint256 eth);


    constructor() public payable
    {
        owner = msg.sender;
    }

    function GetVersion() external pure returns(uint256)
    {
        return 1001;
    }

    function IsPlayer() external view returns(bool)
    {
        return data.IsPlayer(msg.sender);
    }

    function StartCity() external
    {
        uint256 ethland;
        uint256 maxland;
        uint256 initcrdt;
        uint256 crdtsec;
        uint256 landcount;

        (ethland, maxland, initcrdt, crdtsec, landcount) = config.GetInitData();
        CITYDATA memory cdata = dtCreateCityData(msg.sender, crdtsec, landcount);

        UpdateCityData(cdata, 0, initcrdt, 0, 0);

        dtSetCityData(msg.sender, cdata);
    }

    function GetCityName(address player) external view returns(bytes32)
    {
        return data.GetCityName(player);
    }

    function SetCityName(bytes32 name) external
    {
        data.SetCityName(msg.sender, name);
    }

    function GetWorldSnapshot() external view returns(uint256 ethFund, uint256 population, uint256 credits, 
                                                    uint256 lasttime, uint256 nexttime, uint256 timestamp)
    {
        WORLDSNAPSHOT memory wss;
        
        (ethFund, wss) = dtTestWorldSnapshot(nowday());

        population = wss.population;
        credits = wss.credits;
        lasttime = wss.lasttime;
        nexttime = daytime(nowday() + 1);

        timestamp = block.timestamp;
    }

    function GetCityData() external view returns(bytes32 cityname, uint256 population, uint256 credits, uint256 creditsPerSec,
                                                                    uint256 occupied, uint256 unoccupied, uint256 timestamp)
    {
        CITYDATA memory cdata = dtGetCityData(msg.sender);

        cityname = data.GetCityName(msg.sender);
        credits = CalcIncCredits(cdata) + cdata.credits;
        population = cdata.population;
        creditsPerSec = cdata.creditsPerSec;   // *100
        occupied = cdata.landOccupied;
        unoccupied = cdata.landUnoccupied;
        timestamp = block.timestamp;
    }

    function GetCitySnapshot() external view returns(uint256 population, uint256 credits, uint256 timestamp)
    {
        CITYSNAPSHOT memory css = dtTestCitySnapshot(msg.sender, nowday());

        population = css.population;
        credits = css.credits;
        timestamp = block.timestamp;
    }

    function GetBuildingData(uint256 id) external view returns(uint256 constructCount, uint256 upgradeCount, uint256 population, uint256 creditsPerSec)
    {
        BUILDINGDATA memory bdata = dtGetBuildingData(msg.sender, id);

        constructCount = bdata.constructCount;
        upgradeCount = bdata.upgradeCount;
        (population, creditsPerSec) = CalcBuildingParam(bdata);
    }

    function GetConstructCost(uint256 id, uint256 count) external view returns(uint256 cnstcrdt, uint256 cnsteth)
    {
        (cnstcrdt, cnsteth) = config.GetConstructCost(id, count);
    }

    function ConstructByCredits(uint256 id, uint256 count) external
    {
        CITYDATA memory cdata = dtGetCityData(msg.sender);

        require(count > 0);
        if (!ConstructBuilding(cdata, id, count, true))
            require(false);

        dtSetCityData(msg.sender, cdata);

        emit OnConstructed(msg.sender, id, count);
    }

    function ConstructByEth(uint256 id, uint256 count) external payable
    {
        CITYDATA memory cdata = dtGetCityData(msg.sender);

        require(count > 0);
        if (!ConstructBuilding(cdata, id, count, false))
            require(false);

        dtSetCityData(msg.sender, cdata);

        emit OnConstructed(msg.sender, id, count);
    }

    function BuyLandsByEth(uint256 count) external payable
    {
        uint256 ethland;
        uint256 maxland;

        require(count > 0);

        (ethland, maxland) = config.GetLandData();

        CITYDATA memory cdata = dtGetCityData(msg.sender);
        require(cdata.landOccupied + cdata.landUnoccupied + count <= maxland);

        UpdateEthBalance(ethland * count, msg.value);
        UpdateCityData(cdata, 0, 0, 0, 0);

        cdata.landUnoccupied += count;

        dtSetCityData(msg.sender, cdata);

        emit OnBuyLands(msg.sender, count);
    }

    function BuyCreditsByEth(uint256 eth) external payable
    {
        CITYDATA memory cdata = dtGetCityData(msg.sender);

        require(eth > 0);

        UpdateEthBalance(eth, msg.value);
        UpdateCityData(cdata, 0, 0, 0, 0);

        cdata.credits += eth * config.GetCreditsPerEth();

        dtSetCityData(msg.sender, cdata);

        emit OnBuyCredits(msg.sender, eth);
    }

    function GetUpgradeCost(uint256 id, uint256 count) external view returns(uint256)
    {
        return config.GetUpgradeCost(id, count);
    }

    function UpgradeByCredits(uint256 id, uint256 count) external
    {
        uint256 a_population;
        uint256 a_crdtsec;
        uint256 updcrdt;
        CITYDATA memory cdata = dtGetCityData(msg.sender);
        
        require(count > 0);

        (a_population, a_crdtsec) = UpdateBuildingParam(cdata, id, 0, count);
        require((a_population > 0) || (a_crdtsec > 0));

        updcrdt = config.GetUpgradeCost(id, count);

        UpdateCityData(cdata, a_population, 0, updcrdt, a_crdtsec);
        if (a_population != 0)
            rank.UpdateRank(msg.sender, cdata.population, cdata.lasttime);

        dtSetCityData(msg.sender, cdata);

        emit OnUpdated(msg.sender, id, count);
    }

    function GetDemolishCost(uint256 id, uint256 count) external view returns (uint256)
    {
        require(count > 0);

        return config.GetDemolishCost(id, count);
    }

    function DemolishByCredits(uint256 id, uint256 count) external
    {
        uint256 a_population;
        uint256 a_crdtsec;
        uint256 dmlcrdt;
        CITYDATA memory cdata = dtGetCityData(msg.sender);
        
        require(count > 0);

        (a_population, a_crdtsec) = UpdateBuildingParam(cdata, id, -count, 0);
        require((a_population > 0) || (a_crdtsec > 0));

        dmlcrdt = config.GetDemolishCost(id, count);

        UpdateCityData(cdata, a_population, 0, dmlcrdt, a_crdtsec);
        if (a_population != 0)
            rank.UpdateRank(msg.sender, cdata.population, cdata.lasttime);

        dtSetCityData(msg.sender, cdata);

        emit OnDemolished(msg.sender, id, count);
    }

    function GetEthBalance() external view returns(uint256 ethBal)
    {
        return data.GetWithdrawBalance(msg.sender);
    }

    function WithdrawEther() external
    {
        data.WithdrawEther(msg.sender);

        CITYDATA memory cdata = dtGetCityData(msg.sender);
        UpdateCityData(cdata, 0, 0, 0, 0);
        dtSetCityData(msg.sender, cdata);
    }

    function GetEthShop() external view returns(uint256 shopEth, uint256 shopCredits)
    {
        (shopEth, shopCredits) = data.GetEthShop(msg.sender);
    }

    function TradeEthShop(uint256 credits) external
    {
        data.TradeEthShop(msg.sender, credits);

        CITYDATA memory cdata = dtGetCityData(msg.sender);
        UpdateCityData(cdata, 0, 0, credits, 0);
        dtSetCityData(msg.sender, cdata);
    }

    /////////////////////////////////////////////////////////////////
    // admin
    function adminIsAdmin() external view returns(bool)
    {
        return msg.sender == owner || msg.sender == admin;
    }

    function adminSetAdmin(address addr) external
    {
        require(msg.sender == owner);

        admin = addr;
    }

    function adminSetConfig(address dta, address cfg, address rnk) external
    {
        require(msg.sender == owner || msg.sender == admin);

        data = EtherCityData(dta);
        config = EtherCityConfig(cfg);
        rank = EtherCityRank(rnk);
    }

    function adminAddWorldBalance() external payable
    {
        require(msg.value > 0);
        require(msg.sender == owner || msg.sender == admin);

        UpdateEthBalance(msg.value, msg.value);
    }

    function adminGetBalance() external view returns(uint256 dta_bal, uint256 cfg_bal, uint256 rnk_bal, uint256 cty_bal)
    {
        require(msg.sender == owner || msg.sender == admin);

        dta_bal = address(data).balance;
        cfg_bal = address(config).balance;
        rnk_bal = address(rank).balance;
        cty_bal = address(this).balance;
    }

    /////////////////////////////////////////////////////////////////
    // internal
    function nowday() private view returns(uint256)
    {
        return block.timestamp / 24 hours;
    }

    function daytime(uint256 day) private pure returns(uint256)
    {
        return day * 24 hours;
    }

    function ConstructBuilding(CITYDATA memory cdata, uint256 id, uint256 count, bool byCredit) private returns(bool)
    {
        uint256 a_population;
        uint256 a_crdtsec;
        uint256 cnstcrdt;
        uint256 cnsteth;

        if (count > cdata.landUnoccupied)
            return false;

        (a_population, a_crdtsec) = UpdateBuildingParam(cdata, id, count, 0);

        if ((a_population == 0) && (a_crdtsec == 0))
            return false;

        (cnstcrdt, cnsteth) = config.GetConstructCost(id, count);

        if (!byCredit)
            UpdateEthBalance(cnsteth, msg.value);

        UpdateCityData(cdata, a_population, 0, cnstcrdt, a_crdtsec);
        if (a_population != 0)
            rank.UpdateRank(msg.sender, cdata.population, cdata.lasttime);

        return true;            
    }

    function UpdateBuildingParam(CITYDATA memory cdata, uint256 id, uint256 cnstcount, uint256 updcount) private returns(uint256 a_population, uint256 a_crdtsec)
    {
        uint256 population;
        uint256 crdtsec;
        uint256 maxupd;
        BUILDINGDATA memory bdata = dtGetBuildingData(msg.sender, id);

        if (bdata.upgradeCount == 0)
            bdata.upgradeCount = 1;

        a_population = 0;
        a_crdtsec = 0;

        (population, crdtsec, maxupd) = config.GetBuildingParam(id);
        if (cnstcount > cdata.landUnoccupied)
            return;

        cdata.landOccupied += cnstcount;
        cdata.landUnoccupied -= cnstcount;

        if (bdata.upgradeCount + updcount > maxupd)
            return;

        (a_population, a_crdtsec) = CalcBuildingParam(bdata);
        bdata.population = population;
        bdata.creditsPerSec = crdtsec;
        bdata.constructCount += cnstcount;
        bdata.upgradeCount += updcount;
        (population, crdtsec) = CalcBuildingParam(bdata);

        dtSetBuildingData(msg.sender, id, bdata);

        a_population = population - a_population;
        a_crdtsec = crdtsec - a_crdtsec;
    }

    function CalcBuildingParam(BUILDINGDATA memory bdata) private pure returns(uint256 population, uint256 crdtsec)
    {
        uint256 count;

        count = bdata.constructCount * bdata.upgradeCount;
        population = bdata.population * count;
        crdtsec = bdata.creditsPerSec * count;
    }

    function CalcIncCredits(CITYDATA memory cdata) private view returns(uint256)
    {
        return SafeMath.muldiv(cdata.creditsPerSec, block.timestamp - cdata.lasttime, INTFLOATDIV);
    }

    function UpdateCityData(CITYDATA memory cdata, uint256 pop, uint256 inccrdt, uint256 deccrdt, uint256 crdtsec) private
    {
        uint256 day;

        day = nowday();

        inccrdt += CalcIncCredits(cdata);
        require((cdata.credits + inccrdt) >= deccrdt);

        inccrdt -= deccrdt;

        cdata.population += pop;
        cdata.credits += inccrdt;
        cdata.creditsPerSec += crdtsec;
        cdata.lasttime = block.timestamp;

        WORLDDATA memory wdata = dtGetWorldData();
        wdata.population += pop;
        wdata.credits += inccrdt;
        dtSetWorldData(wdata);

        WORLDSNAPSHOT memory wss = dtValidateWorldSnapshot(day);
        wss.population += pop;
        wss.credits += inccrdt;
        wss.lasttime = block.timestamp;
        dtSetWorldSnapshot(day, wss);

        CITYSNAPSHOT memory css = dtValidateCitySnapshot(msg.sender, day);
        css.population += pop;
        css.credits += inccrdt;
        css.shopCredits += inccrdt;
        css.lasttime = block.timestamp;
        dtSetCitySnapshot(msg.sender, day, css);
    }

    function UpdateEthBalance(uint256 eth, uint256 val) private returns(bool)
    {
        uint256 devf;
        uint256 fndf;
        uint256 rnkf;

        if (eth > val)
        {
            fndf = dtGetEthBalance(msg.sender);
            require(eth - val <= fndf);
            dtSetEthBalance(msg.sender, fndf - eth + val);
        }

        devf = eth * 17 / 100;
        fndf = eth * 33 / 100;
        rnkf = fndf * 70 / 100;

        data.UpdateEthBalance.value(val)(eth - devf - fndf, devf, rnkf, fndf - rnkf);
    }

    /////////////////////////////////////////////////////////////////
    //
    function dtGetWorldData() private view returns(WORLDDATA memory wdata)
    {
         (wdata.ethBalance, wdata.ethDev, wdata.population, wdata.credits, wdata.starttime) = data.GetWorldData();
    }

    function dtSetWorldData(WORLDDATA memory wdata) private
    {
        data.SetWorldData(wdata.ethBalance, wdata.ethDev, wdata.population, wdata.credits, wdata.starttime);
    }

    function dtSetWorldSnapshot(uint256 day, WORLDSNAPSHOT memory wss) private
    {
        data.SetWorldSnapshot(day, true, wss.population, wss.credits, wss.lasttime);
    }

    function dtCreateCityData(address player, uint256 crdtsec, uint256 landcount) private returns(CITYDATA memory)
    {
        data.CreateCityData(player, crdtsec, landcount);
        return dtGetCityData(player);
    }

    function dtGetCityData(address player) private view returns(CITYDATA memory cdata)
    {
        (cdata.credits, cdata.population, cdata.creditsPerSec, cdata.landOccupied, cdata.landUnoccupied, cdata.lasttime) = data.GetCityData(player);
    }

    function dtSetCityData(address player, CITYDATA memory cdata) private
    {
        data.SetCityData(player, cdata.credits, cdata.population, cdata.creditsPerSec, cdata.landOccupied, cdata.landUnoccupied, cdata.lasttime);
    }

    function dtSetCitySnapshot(address player, uint256 day, CITYSNAPSHOT memory css) private
    {
        data.SetCitySnapshot(player, day, true, css.population, css.credits, css.shopCredits, css.lasttime);
    }

    function dtGetBuildingData(address player, uint256 id) private view returns(BUILDINGDATA memory bdata)
    {
        (bdata.constructCount, bdata.upgradeCount, bdata.population, bdata.creditsPerSec) = data.GetBuildingData(player, id);
    }

    function dtSetBuildingData(address player, uint256 id, BUILDINGDATA memory bdata) private
    {
        data.SetBuildingData(player, id, bdata.constructCount, bdata.upgradeCount, bdata.population, bdata.creditsPerSec);
    }

    function dtGetEthBalance(address player) private view returns(uint256)
    {
        return data.GetEthBalance(player);
    }

    function dtSetEthBalance(address player, uint256 eth) private
    {
        data.SetEthBalance(player, eth);
    }

    function dtAddEthBalance(address player, uint256 eth) private
    {
        data.AddEthBalance(player, eth);
    }

    function dtValidateWorldSnapshot(uint256 day) private returns(WORLDSNAPSHOT memory wss)
    {
        uint256 ethRankFund;

        (ethRankFund, wss.population, wss.credits, wss.lasttime) = data.ValidateWorldSnapshot(day);
    }

    function dtTestWorldSnapshot(uint256 day) private view returns(uint256 ethRankFund, WORLDSNAPSHOT memory wss)
    {
        (ethRankFund, wss.population, wss.credits, wss.lasttime) = data.TestWorldSnapshot(day);
    }

    function dtValidateCitySnapshot(address player, uint256 day) private returns(CITYSNAPSHOT memory css)
    {
        (css.population, css.credits, css.shopCredits, css.lasttime) = data.ValidateCitySnapshot(player, day);
    }

    function dtTestCitySnapshot(address player, uint256 day) private view returns(CITYSNAPSHOT memory css)
    {
        (css.population, css.credits, css.shopCredits, css.lasttime) = data.TestCitySnapshot(player, day);
    }
}