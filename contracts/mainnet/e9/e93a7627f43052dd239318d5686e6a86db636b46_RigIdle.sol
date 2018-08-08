pragma solidity ^0.4.18;

library NumericSequence
{
    function sumOfN(uint basePrice, uint pricePerLevel, uint owned, uint count) internal pure returns (uint price)
    {
        require(count > 0);
        
        price = 0;
        price += (basePrice + pricePerLevel * owned) * count;
        price += pricePerLevel * ((count-1) * count) / 2;
    }
}

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

//-----------------------------------------------------------------------
contract RigIdle is ERC20  {
    using NumericSequence for uint;

    struct MinerData 
    {
        uint[9]   rigs; // rig types and their upgrades
        uint8[3]  hasUpgrade;
        uint      money;
        uint      lastUpdateTime;
        uint      premamentMineBonusPct;
        uint      unclaimedPot;
        uint      lastPotShare;
    }
    
    struct RigData
    {
        uint basePrice;
        uint baseOutput;
        uint pricePerLevel;
        uint priceInETH;
        uint limit;
    }
    
    struct BoostData
    {
        uint percentBonus;
        uint priceInWEI;
    }
    
    struct PVPData
    {
        uint[6] troops;
        uint immunityTime;
        uint exhaustTime;
    }
    
    struct TroopData
    {
        uint attackPower;
        uint defensePower;
        uint priceGold;
        uint priceETH;
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
    uint private honeyPotAmount;
    uint private honeyPotSharePct;
    uint private jackPot;
    uint private devFund;
    uint private nextPotDistributionTime;
    
    //booster info
    uint public constant NUMBER_OF_BOOSTERS = 5;
    uint       boosterIndex;
    uint       nextBoosterPrice;
    address[5] boosterHolders;
    
    mapping(address => MinerData) private miners;
    mapping(address => PVPData)   private pvpMap;
    mapping(uint => address)  private indexes;
    uint private topindex;
    
    address public owner;
    
    // ERC20 functionality
    mapping(address => mapping(address => uint256)) private allowed;
    string public constant name  = "RigWarsIdle";
    string public constant symbol = "RIG";
    uint8 public constant decimals = 8;
    uint256 private estimatedSupply;
    
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
        // default 90% honeypot, 8% for DevFund + transaction fees, 2% safe deposit
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
        
        estimatedSupply = 80000000;
    }
    
    //--------------------------------------------------------------------------
    // Data access functions
    //--------------------------------------------------------------------------
    function GetNumberOfRigs() public pure returns (uint8 rigNum)
    {
        rigNum = NUMBER_OF_RIG_TYPES;
    }
    
    function GetRigData(uint8 rigIdx) public constant returns (uint price, uint production, uint upgrade, uint limit, uint priceETH)
    {
        require(rigIdx < NUMBER_OF_RIG_TYPES);
        price =      rigData[rigIdx].basePrice;
        production = rigData[rigIdx].baseOutput;
        upgrade =    rigData[rigIdx].pricePerLevel;
        limit =      rigData[rigIdx].limit;
        priceETH =   rigData[rigIdx].priceInETH;
    }
    
    function GetMinerData(address minerAddr) public constant returns 
        (uint money, uint lastupdate, uint prodPerSec, 
         uint[9] rigs, uint[3] upgrades, uint unclaimedPot, uint lastPot, bool hasBooster, uint unconfirmedMoney)
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
        lastPot = miners[minerAddr].lastPotShare;
        hasBooster = HasBooster(minerAddr);
        
        unconfirmedMoney = money + (prodPerSec * (now - lastupdate));
    }
    
    function GetTotalMinerCount() public constant returns (uint count)
    {
        count = topindex;
    }
    
    function GetMinerAt(uint idx) public constant returns (address minerAddr)
    {
        require(idx < topindex);
        minerAddr = indexes[idx];
    }
    
    function GetPriceOfRigs(uint rigIdx, uint count, uint owned) public constant returns (uint price)
    {
        require(rigIdx < NUMBER_OF_RIG_TYPES);
        require(count > 0);
        price = NumericSequence.sumOfN(rigData[rigIdx].basePrice, rigData[rigIdx].pricePerLevel, owned, count); 
    }
    
    function GetPotInfo() public constant returns (uint _honeyPotAmount, uint _devFunds, uint _jackPot, uint _nextDistributionTime)
    {
        _honeyPotAmount = honeyPotAmount;
        _devFunds = devFund;
        _jackPot = jackPot;
        _nextDistributionTime = nextPotDistributionTime;
    }
    
    function GetProductionPerSecond(address minerAddr) public constant returns (uint personalProduction)
    {
        MinerData storage m = miners[minerAddr];
        
        personalProduction = 0;
        uint productionSpeed = 100 + m.premamentMineBonusPct;
        
        if(HasBooster(minerAddr)) // 500% bonus
            productionSpeed += 500;
        
        for(uint8 j = 0; j < NUMBER_OF_RIG_TYPES; ++j)
        {
            personalProduction += m.rigs[j] * rigData[j].baseOutput;
        }
        
        personalProduction = personalProduction * productionSpeed / 100;
    }
    
    function GetGlobalProduction() public constant returns (uint globalMoney, uint globalHashRate)
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
    
    function GetBoosterData() public constant returns (address[5] _boosterHolders, uint currentPrice, uint currentIndex)
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
    
    function GetPVPData(address addr) public constant returns (uint attackpower, uint defensepower, uint immunityTime, uint exhaustTime,
    uint[6] troops)
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
    
    function GetPriceOfTroops(uint idx, uint count, uint owned) public constant returns (uint price, uint priceETH)
    {
        require(idx < NUMBER_OF_TROOPS);
        require(count > 0);
        price = NumericSequence.sumOfN(troopData[idx].priceGold, troopData[idx].priceGold, owned, count);
        priceETH = troopData[idx].priceETH * count;
    }
    
    // -------------------------------------------------------------------------
    // RigWars game handler functions
    // -------------------------------------------------------------------------
    function StartNewMiner() public
    {
        require(miners[msg.sender].lastUpdateTime == 0);
        
        miners[msg.sender].lastUpdateTime = block.timestamp;
        miners[msg.sender].money = 0;
        miners[msg.sender].rigs[0] = 1;
        miners[msg.sender].unclaimedPot = 0;
        miners[msg.sender].lastPotShare = 0;
        
        pvpMap[msg.sender].troops[0] = 0;
        pvpMap[msg.sender].troops[1] = 0;
        pvpMap[msg.sender].troops[2] = 0;
        pvpMap[msg.sender].troops[3] = 0;
        pvpMap[msg.sender].troops[4] = 0;
        pvpMap[msg.sender].troops[5] = 0;
        pvpMap[msg.sender].immunityTime = block.timestamp + 28800;
        pvpMap[msg.sender].exhaustTime  = block.timestamp;
        
        indexes[topindex] = msg.sender;
        ++topindex;
    }
    
    function UpgradeRig(uint8 rigIdx, uint count) public
    {
        require(rigIdx < NUMBER_OF_RIG_TYPES);
        require(count > 0);
        
        MinerData storage m = miners[msg.sender];
        
        require(rigData[rigIdx].limit >= (m.rigs[rigIdx] + count));
        
        UpdateMoney();
     
        // the base of geometrical sequence
        uint price = NumericSequence.sumOfN(rigData[rigIdx].basePrice, rigData[rigIdx].pricePerLevel, m.rigs[rigIdx], count); 
       
        require(m.money >= price);
        
        m.rigs[rigIdx] = m.rigs[rigIdx] + count;
        m.money -= price;
    }
    
    function UpgradeRigETH(uint8 rigIdx, uint count) public payable
    {
        require(rigIdx < NUMBER_OF_RIG_TYPES);
        require(count > 0);
        require(rigData[rigIdx].priceInETH > 0);
        
        MinerData storage m = miners[msg.sender];
        
        require(rigData[rigIdx].limit >= (m.rigs[rigIdx] + count));
      
        uint price = rigData[rigIdx].priceInETH * count; 
       
        require(msg.value >= price);
        
        BuyHandler(msg.value);
        
        UpdateMoney();
        
        m.rigs[rigIdx] = m.rigs[rigIdx] + count;
    }
    
    function UpdateMoney() public
    {
        require(miners[msg.sender].lastUpdateTime != 0);
        
        MinerData storage m = miners[msg.sender];
        uint diff = block.timestamp - m.lastUpdateTime;
        uint revenue = GetProductionPerSecond(msg.sender);
   
        m.lastUpdateTime = block.timestamp;
        if(revenue > 0)
        {
            revenue *= diff;
            
            m.money += revenue;
        }
    }
    
    function UpdateMoneyAt(address addr) internal
    {
        require(miners[addr].lastUpdateTime != 0);
        
        MinerData storage m = miners[addr];
        uint diff = block.timestamp - m.lastUpdateTime;
        uint revenue = GetProductionPerSecond(addr);
   
        m.lastUpdateTime = block.timestamp;
        if(revenue > 0)
        {
            revenue *= diff;
            
            m.money += revenue;
        }
    }
    
    function BuyUpgrade(uint idx) public payable
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
    function BuyBooster() public payable 
    {
        require(msg.value >= nextBoosterPrice);
        require(miners[msg.sender].lastUpdateTime != 0);
        
        for(uint i = 0; i < NUMBER_OF_BOOSTERS; ++i)
            if(boosterHolders[i] == msg.sender)
                revert();
                
        address beneficiary = boosterHolders[boosterIndex];
        
        MinerData storage m = miners[beneficiary];
        
        // 95% goes to the owner (21% interest after 5 buys)
        m.unclaimedPot += nextBoosterPrice * 95 / 100;
        
        // 5% to the pot
        BuyHandler((nextBoosterPrice / 20));
        
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
    function BuyTroop(uint idx, uint count) public payable
    {
        require(idx < NUMBER_OF_TROOPS);
        require(count > 0);
        require(count <= 1000);
        
        PVPData storage pvp = pvpMap[msg.sender];
        MinerData storage m = miners[msg.sender];
        
        uint owned = pvp.troops[idx];
        
        uint priceGold = NumericSequence.sumOfN(troopData[idx].priceGold, troopData[idx].priceGold, owned, count); 
        uint priceETH = troopData[idx].priceETH * count;
        
        UpdateMoney();
        
        require(m.money >= priceGold);
        require(msg.value >= priceETH);
        
        if(priceGold > 0)
            m.money -= priceGold;
         
        if(msg.value > 0)
            BuyHandler(msg.value);
        
        pvp.troops[idx] += count;
    }
    
    function Attack(address defenderAddr) public
    {
        require(msg.sender != defenderAddr);
        require(miners[msg.sender].lastUpdateTime != 0);
        require(miners[defenderAddr].lastUpdateTime != 0);
        
        PVPData storage attacker = pvpMap[msg.sender];
        PVPData storage defender = pvpMap[defenderAddr];
        uint i = 0;
        uint count = 0;
        
        require(block.timestamp > attacker.exhaustTime);
        require(block.timestamp > defender.immunityTime);
        
        // the aggressor loses immunity
        if(attacker.immunityTime > block.timestamp)
            attacker.immunityTime = block.timestamp - 1;
            
        attacker.exhaustTime = block.timestamp + 7200;
        
        uint attackpower = 0;
        uint defensepower = 0;
        for(i = 0; i < NUMBER_OF_TROOPS; ++i)
        {
            attackpower  += attacker.troops[i] * troopData[i].attackPower;
            defensepower += defender.troops[i] * troopData[i].defensePower;
        }
        
        if(attackpower > defensepower)
        {
            if(defender.immunityTime < block.timestamp + 14400)
                defender.immunityTime = block.timestamp + 14400;
            
            UpdateMoneyAt(defenderAddr);
            
            MinerData storage m = miners[defenderAddr];
            MinerData storage m2 = miners[msg.sender];
            uint moneyStolen = m.money / 2;
         
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
    // ETH handler functions
    //--------------------------------------------------------------------------
    function BuyHandler(uint amount) public payable
    {
        // add 2% to jakcpot
        // add 90% (default) to honeyPot
        honeyPotAmount += (amount * honeyPotSharePct) / 100;
        jackPot += amount / 50;
        // default 100 - (90+2) = 8%
        devFund += (amount * (100-(honeyPotSharePct+2))) / 100;
    }
    
    function WithdrawPotShare() public
    {
        MinerData storage m = miners[msg.sender];
        
        require(m.unclaimedPot > 0);
        
        uint amntToSend = m.unclaimedPot;
        m.unclaimedPot = 0;
        
        if(msg.sender.send(amntToSend))
        {
            m.unclaimedPot = 0;
        }
    }
    
    function WithdrawDevFunds(uint amount) public
    {
        require(msg.sender == owner);
        
        if(amount == 0)
        {
            if(owner.send(devFund))
            {
                devFund = 0;
            }
        } else
        {
            // should never be used! this is only in case of emergency
            // if some error happens with distribution someone has to access
            // and distribute the funds manually
            owner.transfer(amount);
        }
    }
    
    function SnapshotAndDistributePot() public
    {
        require(honeyPotAmount > 0);
        require(gasleft() >= 1000000);
        require(nextPotDistributionTime <= block.timestamp);
        
        uint globalMoney = 1;
        uint i = 0;
        for(i = 0; i < topindex; ++i)
        {
            globalMoney += miners[indexes[i]].money;
        }
        
        estimatedSupply = globalMoney;
        
        uint remainingPot = honeyPotAmount;
        
        // 20% of the total pot
        uint potFraction = honeyPotAmount / 5;
                
        honeyPotAmount -= potFraction;
        
        potFraction /= 10000;
        
        for(i = 0; i < topindex; ++i)
        {
            // lowest limit of pot share is 0.01%
            MinerData storage m = miners[indexes[i]];
            uint share = (m.money * 10000) / globalMoney;
            if(share > 0)
            {
                uint newPot = potFraction * share;
                
                if(newPot <= remainingPot)
                {
                    m.unclaimedPot += newPot;
                    m.lastPotShare = newPot;
                    remainingPot   -= newPot;
                }
            }
        }
        
        nextPotDistributionTime = block.timestamp + 86400;
        
        MinerData storage jakpotWinner = miners[msg.sender];
        jakpotWinner.unclaimedPot += jackPot;
        jackPot = 0;
    }
    
    // fallback payment to pot
    function() public payable {
    }
    
    //--------------------------------------------------------------------------
    // ERC20 support
    //--------------------------------------------------------------------------
    function totalSupply() public constant returns(uint256) {
        return estimatedSupply;
    }
    
    function balanceOf(address miner) public constant returns(uint256) {
        return miners[miner].money;
    }
    
     function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= miners[msg.sender].money);
        require(miners[recipient].lastUpdateTime != 0);
        
        miners[msg.sender].money -= amount * (10**uint(decimals));
        miners[recipient].money += amount * (10**uint(decimals));
        
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address miner, address recipient, uint256 amount) public returns (bool) {
        require(amount <= allowed[miner][msg.sender] && amount <= balanceOf(miner));
        require(miners[recipient].lastUpdateTime != 0);
        
        miners[miner].money -= amount * (10**uint(decimals));
        miners[recipient].money += amount * (10**uint(decimals));
        allowed[miner][msg.sender] -= amount * (10**uint(decimals));
        
        emit Transfer(miner, recipient, amount);
        return true;
    }
    
    function approve(address approvee, uint256 amount) public returns (bool){
        allowed[msg.sender][approvee] = amount * (10**uint(decimals));
        emit Approval(msg.sender, approvee, amount);
        return true;
    }
    
    function allowance(address miner, address approvee) public constant returns(uint256){
        return allowed[miner][approvee];
    }
}