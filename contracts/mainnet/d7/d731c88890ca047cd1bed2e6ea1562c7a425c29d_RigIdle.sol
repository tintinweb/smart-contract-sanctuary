pragma solidity ^0.4.18;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
}

library NumericSequence
{
    using SafeMath for uint256;
    function sumOfN(uint256 basePrice, uint256 pricePerLevel, uint256 owned, uint256 count) internal pure returns (uint256 price)
    {
        require(count > 0);
        
        price = 0;
        price += SafeMath.mul((basePrice + pricePerLevel * owned), count);
        price += pricePerLevel * (count.mul((count-1))) / 2;
    }
}

//-----------------------------------------------------------------------
contract RigIdle  {
    using NumericSequence for uint;
    using SafeMath for uint;

    struct MinerData 
    {
        uint256[9]   rigs; // rig types and their upgrades
        uint8[3]     hasUpgrade;
        uint256      money;
        uint256      lastUpdateTime;
        uint256      premamentMineBonusPct;
        uint256      unclaimedPot;
        uint256      lastPotClaimIndex;
    }
    
    struct RigData
    {
        uint256 basePrice;
        uint256 baseOutput;
        uint256 pricePerLevel;
        uint256 priceInETH;
        uint256 limit;
    }
    
    struct BoostData
    {
        uint256 percentBonus;
        uint256 priceInWEI;
    }
    
    struct PVPData
    {
        uint256[6] troops;
        uint256    immunityTime;
        uint256    exhaustTime;
    }
    
    struct TroopData
    {
        uint256 attackPower;
        uint256 defensePower;
        uint256 priceGold;
        uint256 priceETH;
    }
    
    uint8 private constant NUMBER_OF_RIG_TYPES = 9;
    RigData[9]  private rigData;
    
    uint8 private constant NUMBER_OF_UPGRADES = 3;
    BoostData[3] private boostData;
    
    uint8 private constant NUMBER_OF_TROOPS = 6;
    uint8 private constant ATTACKER_START_IDX = 0;
    uint8 private constant ATTACKER_END_IDX = 3;
    uint8 private constant DEFENDER_START_IDX = 3;
    uint8 private constant DEFENDER_END_IDX = 6;
    TroopData[6] private troopData;

    // honey pot variables
    uint256 private honeyPotAmount;
    uint256 private honeyPotSharePct; // 90%
    uint256 private jackPot;
    uint256 private devFund;
    uint256 private nextPotDistributionTime;
    mapping(address => mapping(uint256 => uint256)) private minerICOPerCycle;
    uint256[] private honeyPotPerCycle;
    uint256[] private globalICOPerCycle;
    uint256 private cycleCount;
    
    //booster info
    uint256 private constant NUMBER_OF_BOOSTERS = 5;
    uint256 private boosterIndex;
    uint256 private nextBoosterPrice;
    address[5] private boosterHolders;
    
    mapping(address => MinerData) private miners;
    mapping(address => PVPData)   private pvpMap;
    mapping(uint256 => address)   private indexes;
    uint256 private topindex;
    
    address private owner;
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function RigIdle() public {
        owner = msg.sender;
        
        //                   price,           prod.     upgrade,        priceETH, limit
        rigData[0] = RigData(128,             1,        64,              0,          64);
        rigData[1] = RigData(1024,            64,       512,             0,          64);
        rigData[2] = RigData(204800,          1024,     102400,          0,          128);
        rigData[3] = RigData(25600000,        8192,     12800000,        0,          128);
        rigData[4] = RigData(30000000000,     65536,    30000000000,     0.01 ether, 256);
        rigData[5] = RigData(30000000000,     100000,   10000000000,     0,          256);
        rigData[6] = RigData(300000000000,    500000,   100000000000,    0,          256);
        rigData[7] = RigData(50000000000000,  3000000,  12500000000000,  0.1 ether,  256);
        rigData[8] = RigData(100000000000000, 30000000, 50000000000000,  0,          256);
        
        boostData[0] = BoostData(30,  0.01 ether);
        boostData[1] = BoostData(50,  0.1 ether);
        boostData[2] = BoostData(100, 1 ether);
        
        topindex = 0;
        honeyPotAmount = 0;
        devFund = 0;
        jackPot = 0;
        nextPotDistributionTime = block.timestamp;
        honeyPotSharePct = 90;
        
        // has to be set to a value
        boosterHolders[0] = owner;
        boosterHolders[1] = owner;
        boosterHolders[2] = owner;
        boosterHolders[3] = owner;
        boosterHolders[4] = owner;
        
        boosterIndex = 0;
        nextBoosterPrice = 0.1 ether;
        
        //pvp
        troopData[0] = TroopData(10,     0,      100000,   0);
        troopData[1] = TroopData(1000,   0,      80000000, 0);
        troopData[2] = TroopData(100000, 0,      0,        0.01 ether);
        troopData[3] = TroopData(0,      15,     100000,   0);
        troopData[4] = TroopData(0,      1500,   80000000, 0);
        troopData[5] = TroopData(0,      150000, 0,        0.01 ether);
        
        honeyPotPerCycle.push(0);
        globalICOPerCycle.push(1);
        cycleCount = 0;
    }
    
    //--------------------------------------------------------------------------
    // Data access functions
    //--------------------------------------------------------------------------
    function GetMinerData(address minerAddr) public constant returns 
        (uint256 money, uint256 lastupdate, uint256 prodPerSec, 
         uint256[9] rigs, uint[3] upgrades, uint256 unclaimedPot, bool hasBooster, uint256 unconfirmedMoney)
    {
        uint8 i = 0;
        
        money = miners[minerAddr].money;
        lastupdate = miners[minerAddr].lastUpdateTime;
        prodPerSec = GetProductionPerSecond(minerAddr);
        
        for(i = 0; i < NUMBER_OF_RIG_TYPES; ++i)
        {
            rigs[i] = miners[minerAddr].rigs[i];
        }
        
        for(i = 0; i < NUMBER_OF_UPGRADES; ++i)
        {
            upgrades[i] = miners[minerAddr].hasUpgrade[i];
        }
        
        unclaimedPot = miners[minerAddr].unclaimedPot;
        hasBooster = HasBooster(minerAddr);
        
        unconfirmedMoney = money + (prodPerSec * (now - lastupdate));
    }
    
    function GetTotalMinerCount() public constant returns (uint256 count)
    {
        count = topindex;
    }
    
    function GetMinerAt(uint256 idx) public constant returns (address minerAddr)
    {
        require(idx < topindex);
        minerAddr = indexes[idx];
    }
    
    function GetPotInfo() public constant returns (uint256 _honeyPotAmount, uint256 _devFunds, uint256 _jackPot, uint256 _nextDistributionTime)
    {
        _honeyPotAmount = honeyPotAmount;
        _devFunds = devFund;
        _jackPot = jackPot;
        _nextDistributionTime = nextPotDistributionTime;
    }
    
    function GetProductionPerSecond(address minerAddr) public constant returns (uint256 personalProduction)
    {
        MinerData storage m = miners[minerAddr];
        
        personalProduction = 0;
        uint256 productionSpeed = 100 + m.premamentMineBonusPct;
        
        if(HasBooster(minerAddr)) // 500% bonus
            productionSpeed += 500;
        
        for(uint8 j = 0; j < NUMBER_OF_RIG_TYPES; ++j)
        {
            personalProduction += m.rigs[j] * rigData[j].baseOutput;
        }
        
        personalProduction = personalProduction * productionSpeed / 100;
    }
    
    function GetGlobalProduction() public constant returns (uint256 globalMoney, uint256 globalHashRate)
    {
        globalMoney = 0;
        globalHashRate = 0;
        uint i = 0;
        for(i = 0; i < topindex; ++i)
        {
            MinerData storage m = miners[indexes[i]];
            globalMoney += m.money;
            globalHashRate += GetProductionPerSecond(indexes[i]);
        }
    }
    
    function GetBoosterData() public constant returns (address[5] _boosterHolders, uint256 currentPrice, uint256 currentIndex)
    {
        for(uint i = 0; i < NUMBER_OF_BOOSTERS; ++i)
        {
            _boosterHolders[i] = boosterHolders[i];
        }
        currentPrice = nextBoosterPrice;
        currentIndex = boosterIndex;
    }
    
    function HasBooster(address addr) public constant returns (bool hasBoost)
    { 
        for(uint i = 0; i < NUMBER_OF_BOOSTERS; ++i)
        {
           if(boosterHolders[i] == addr)
            return true;
        }
        return false;
    }
    
    function GetPVPData(address addr) public constant returns (uint256 attackpower, uint256 defensepower, uint256 immunityTime, uint256 exhaustTime,
    uint256[6] troops)
    {
        PVPData storage a = pvpMap[addr];
            
        immunityTime = a.immunityTime;
        exhaustTime = a.exhaustTime;
        
        attackpower = 0;
        defensepower = 0;
        for(uint i = 0; i < NUMBER_OF_TROOPS; ++i)
        {
            attackpower  += a.troops[i] * troopData[i].attackPower;
            defensepower += a.troops[i] * troopData[i].defensePower;
            
            troops[i] = a.troops[i];
        }
    }
    
    function GetCurrentICOCycle() public constant returns (uint256)
    {
        return cycleCount;
    }
    
    function GetICOData(uint256 idx) public constant returns (uint256 ICOFund, uint256 ICOPot)
    {
        require(idx <= cycleCount);
        ICOFund = globalICOPerCycle[idx];
        if(idx < cycleCount)
        {
            ICOPot = honeyPotPerCycle[idx];
        } else
        {
            ICOPot =  honeyPotAmount / 5; // actual day estimate
        }
    }
    
    function GetMinerICOData(address miner, uint256 idx) public constant returns (uint256 ICOFund, uint256 ICOShare, uint256 lastClaimIndex)
    {
        require(idx <= cycleCount);
        ICOFund = minerICOPerCycle[miner][idx];
        if(idx < cycleCount)
        {
            ICOShare = (honeyPotPerCycle[idx] * minerICOPerCycle[miner][idx]) / globalICOPerCycle[idx];
        } else 
        {
            ICOShare = (honeyPotAmount / 5) * minerICOPerCycle[miner][idx] / globalICOPerCycle[idx];
        }
        lastClaimIndex = miners[miner].lastPotClaimIndex;
    }
    
    function GetMinerUnclaimedICOShare(address miner) public constant returns (uint256 unclaimedPot)
    {
        MinerData storage m = miners[miner];
        
        require(m.lastUpdateTime != 0);
        require(m.lastPotClaimIndex < cycleCount);
        
        uint256 i = m.lastPotClaimIndex;
        uint256 limit = cycleCount;
        
        if((limit - i) > 30) // more than 30 iterations(days) afk
            limit = i + 30;
        
        unclaimedPot = 0;
        for(; i < cycleCount; ++i)
        {
            if(minerICOPerCycle[msg.sender][i] > 0)
                unclaimedPot += (honeyPotPerCycle[i] * minerICOPerCycle[miner][i]) / globalICOPerCycle[i];
        }
    }
    
    // -------------------------------------------------------------------------
    // RigWars game handler functions
    // -------------------------------------------------------------------------
    function StartNewMiner() external
    {
        require(miners[msg.sender].lastUpdateTime == 0);
        
        miners[msg.sender].lastUpdateTime = block.timestamp;
        miners[msg.sender].money = 0;
        miners[msg.sender].rigs[0] = 1;
        miners[msg.sender].unclaimedPot = 0;
        miners[msg.sender].lastPotClaimIndex = cycleCount;
        
        pvpMap[msg.sender].immunityTime = block.timestamp + 28800;
        pvpMap[msg.sender].exhaustTime  = block.timestamp;
        
        indexes[topindex] = msg.sender;
        ++topindex;
    }
    
    function UpgradeRig(uint8 rigIdx, uint16 count) external
    {
        require(rigIdx < NUMBER_OF_RIG_TYPES);
        require(count > 0);
        require(count <= 256);
        
        MinerData storage m = miners[msg.sender];
        
        require(rigData[rigIdx].limit >= (m.rigs[rigIdx] + count));
        
        UpdateMoney();
     
        // the base of geometrical sequence
        uint256 price = NumericSequence.sumOfN(rigData[rigIdx].basePrice, rigData[rigIdx].pricePerLevel, m.rigs[rigIdx], count); 
       
        require(m.money >= price);
        
        m.rigs[rigIdx] = m.rigs[rigIdx] + count;
        
        if(m.rigs[rigIdx] > rigData[rigIdx].limit)
            m.rigs[rigIdx] = rigData[rigIdx].limit;
        
        m.money -= price;
    }
    
    function UpgradeRigETH(uint8 rigIdx, uint256 count) external payable
    {
        require(rigIdx < NUMBER_OF_RIG_TYPES);
        require(count > 0);
        require(count <= 256);
        require(rigData[rigIdx].priceInETH > 0);
        
        MinerData storage m = miners[msg.sender];
        
        require(rigData[rigIdx].limit >= (m.rigs[rigIdx] + count));
      
        uint256 price = (rigData[rigIdx].priceInETH).mul(count); 
       
        require(msg.value >= price);
        
        BuyHandler(msg.value);
        
        UpdateMoney();
        
        m.rigs[rigIdx] = m.rigs[rigIdx] + count;
        
        if(m.rigs[rigIdx] > rigData[rigIdx].limit)
            m.rigs[rigIdx] = rigData[rigIdx].limit;
    }
    
    function UpdateMoney() private
    {
        require(miners[msg.sender].lastUpdateTime != 0);
        require(block.timestamp >= miners[msg.sender].lastUpdateTime);
        
        MinerData storage m = miners[msg.sender];
        uint256 diff = block.timestamp - m.lastUpdateTime;
        uint256 revenue = GetProductionPerSecond(msg.sender);
   
        m.lastUpdateTime = block.timestamp;
        if(revenue > 0)
        {
            revenue *= diff;
            
            m.money += revenue;
        }
    }
    
    function UpdateMoneyAt(address addr) private
    {
        require(miners[addr].lastUpdateTime != 0);
        require(block.timestamp >= miners[addr].lastUpdateTime);
        
        MinerData storage m = miners[addr];
        uint256 diff = block.timestamp - m.lastUpdateTime;
        uint256 revenue = GetProductionPerSecond(addr);
   
        m.lastUpdateTime = block.timestamp;
        if(revenue > 0)
        {
            revenue *= diff;
            
            m.money += revenue;
        }
    }
    
    function BuyUpgrade(uint256 idx) external payable
    {
        require(idx < NUMBER_OF_UPGRADES);
        require(msg.value >= boostData[idx].priceInWEI);
        require(miners[msg.sender].hasUpgrade[idx] == 0);
        require(miners[msg.sender].lastUpdateTime != 0);
        
        BuyHandler(msg.value);
        
        UpdateMoney();
        
        miners[msg.sender].hasUpgrade[idx] = 1;
        miners[msg.sender].premamentMineBonusPct +=  boostData[idx].percentBonus;
    }
    
    //--------------------------------------------------------------------------
    // BOOSTER handlers
    //--------------------------------------------------------------------------
    function BuyBooster() external payable 
    {
        require(msg.value >= nextBoosterPrice);
        require(miners[msg.sender].lastUpdateTime != 0);
        
        for(uint i = 0; i < NUMBER_OF_BOOSTERS; ++i)
            if(boosterHolders[i] == msg.sender)
                revert();
                
        address beneficiary = boosterHolders[boosterIndex];
        
        MinerData storage m = miners[beneficiary];
        
        // 20% interest after 5 buys
        m.unclaimedPot += (msg.value * 9403) / 10000;
        
        // distribute the rest
        honeyPotAmount += (msg.value * 597) / 20000;
        devFund += (msg.value * 597) / 20000;
        
        // increase price by 5%
        nextBoosterPrice += nextBoosterPrice / 20;
        
        UpdateMoney();
        UpdateMoneyAt(beneficiary);
        
        // transfer ownership    
        boosterHolders[boosterIndex] = msg.sender;
        
        // increase booster index
        boosterIndex += 1;
        if(boosterIndex >= 5)
            boosterIndex = 0;
    }
    
    //--------------------------------------------------------------------------
    // PVP handler
    //--------------------------------------------------------------------------
    // 0 for attacker 1 for defender
    function BuyTroop(uint256 idx, uint256 count) external payable
    {
        require(idx < NUMBER_OF_TROOPS);
        require(count > 0);
        require(count <= 1000);
        
        PVPData storage pvp = pvpMap[msg.sender];
        MinerData storage m = miners[msg.sender];
        
        uint256 owned = pvp.troops[idx];
        
        uint256 priceGold = NumericSequence.sumOfN(troopData[idx].priceGold, troopData[idx].priceGold, owned, count); 
        uint256 priceETH = (troopData[idx].priceETH).mul(count);
        
        UpdateMoney();
        
        require(m.money >= priceGold);
        require(msg.value >= priceETH);
        
        if(priceGold > 0)
            m.money -= priceGold;
         
        if(msg.value > 0)
            BuyHandler(msg.value);
        
        pvp.troops[idx] += count;
    }
    
    function Attack(address defenderAddr) external
    {
        require(msg.sender != defenderAddr);
        require(miners[msg.sender].lastUpdateTime != 0);
        require(miners[defenderAddr].lastUpdateTime != 0);
        
        PVPData storage attacker = pvpMap[msg.sender];
        PVPData storage defender = pvpMap[defenderAddr];
        uint i = 0;
        uint256 count = 0;
        
        require(block.timestamp > attacker.exhaustTime);
        require(block.timestamp > defender.immunityTime);
        
        // the aggressor loses immunity
        if(attacker.immunityTime > block.timestamp)
            attacker.immunityTime = block.timestamp - 1;
            
        attacker.exhaustTime = block.timestamp + 7200;
        
        uint256 attackpower = 0;
        uint256 defensepower = 0;
        for(i = 0; i < ATTACKER_END_IDX; ++i)
        {
            attackpower  += attacker.troops[i] * troopData[i].attackPower;
            defensepower += defender.troops[i + DEFENDER_START_IDX] * troopData[i + DEFENDER_START_IDX].defensePower;
        }
        
        if(attackpower > defensepower)
        {
            if(defender.immunityTime < block.timestamp + 14400)
                defender.immunityTime = block.timestamp + 14400;
            
            UpdateMoneyAt(defenderAddr);
            
            MinerData storage m = miners[defenderAddr];
            MinerData storage m2 = miners[msg.sender];
            uint256 moneyStolen = m.money / 2;
         
            for(i = DEFENDER_START_IDX; i < DEFENDER_END_IDX; ++i)
            {
                defender.troops[i] = 0;
            }
            
            for(i = ATTACKER_START_IDX; i < ATTACKER_END_IDX; ++i)
            {
                if(troopData[i].attackPower > 0)
                {
                    count = attacker.troops[i];
                    
                    // if the troops overpower the total defense power only a fraction is lost
                    if((count * troopData[i].attackPower) > defensepower)
                        count = defensepower / troopData[i].attackPower;
                        
                    attacker.troops[i] -= count;
                    defensepower -= count * troopData[i].attackPower;
                }
            }
            
            m.money -= moneyStolen;
            m2.money += moneyStolen;
        } else
        {
            for(i = ATTACKER_START_IDX; i < ATTACKER_END_IDX; ++i)
            {
                attacker.troops[i] = 0;
            }
            
            for(i = DEFENDER_START_IDX; i < DEFENDER_END_IDX; ++i)
            {
                if(troopData[i].defensePower > 0)
                {
                    count = defender.troops[i];
                    
                    // if the troops overpower the total defense power only a fraction is lost
                    if((count * troopData[i].defensePower) > attackpower)
                        count = attackpower / troopData[i].defensePower;
                        
                    defender.troops[i] -= count;
                    attackpower -= count * troopData[i].defensePower;
                }
            }
        }
    }
    
    //--------------------------------------------------------------------------
    // ICO/Pot share functions
    //--------------------------------------------------------------------------
    function ReleaseICO() external
    {
        require(miners[msg.sender].lastUpdateTime != 0);
        require(nextPotDistributionTime <= block.timestamp);
        require(honeyPotAmount > 0);
        require(globalICOPerCycle[cycleCount] > 0);

        nextPotDistributionTime = block.timestamp + 86400;

        honeyPotPerCycle[cycleCount] = honeyPotAmount / 5; // 20% of the pot
        
        honeyPotAmount -= honeyPotAmount / 5;

        honeyPotPerCycle.push(0);
        globalICOPerCycle.push(0);
        cycleCount = cycleCount + 1;

        MinerData storage jakpotWinner = miners[msg.sender];
        jakpotWinner.unclaimedPot += jackPot;
        jackPot = 0;
    }
    
    function FundICO(uint amount) external
    {
        require(miners[msg.sender].lastUpdateTime != 0);
        require(amount > 0);
        
        MinerData storage m = miners[msg.sender];
        
        UpdateMoney();
        
        require(m.money >= amount);
        
        m.money = (m.money).sub(amount);
        
        globalICOPerCycle[cycleCount] = globalICOPerCycle[cycleCount].add(uint(amount));
        minerICOPerCycle[msg.sender][cycleCount] = minerICOPerCycle[msg.sender][cycleCount].add(uint(amount));
    }
    
    function WithdrawICOEarnings() external
    {
        MinerData storage m = miners[msg.sender];
        
        require(miners[msg.sender].lastUpdateTime != 0);
        require(miners[msg.sender].lastPotClaimIndex < cycleCount);
        
        uint256 i = m.lastPotClaimIndex;
        uint256 limit = cycleCount;
        
        if((limit - i) > 30) // more than 30 iterations(days) afk
            limit = i + 30;
        
        m.lastPotClaimIndex = limit;
        for(; i < cycleCount; ++i)
        {
            if(minerICOPerCycle[msg.sender][i] > 0)
                m.unclaimedPot += (honeyPotPerCycle[i] * minerICOPerCycle[msg.sender][i]) / globalICOPerCycle[i];
        }
    }
    
    //--------------------------------------------------------------------------
    // ETH handler functions
    //--------------------------------------------------------------------------
    function BuyHandler(uint amount) private
    {
        // add 90% to honeyPot
        honeyPotAmount += (amount * honeyPotSharePct) / 100;
        jackPot += amount / 100;
        devFund += (amount * (100-(honeyPotSharePct+1))) / 100;
    }
    
    function WithdrawPotShare() public
    {
        MinerData storage m = miners[msg.sender];
        
        require(m.unclaimedPot > 0);
        require(m.lastUpdateTime != 0);
        
        uint256 amntToSend = m.unclaimedPot;
        m.unclaimedPot = 0;
        
        if(msg.sender.send(amntToSend))
        {
            m.unclaimedPot = 0;
        }
    }
    
    function WithdrawDevFunds() public
    {
        require(msg.sender == owner);

        if(owner.send(devFund))
        {
            devFund = 0;
        }
    }
    
    // fallback payment to pot
    function() public payable {
         devFund += msg.value;
    }
}