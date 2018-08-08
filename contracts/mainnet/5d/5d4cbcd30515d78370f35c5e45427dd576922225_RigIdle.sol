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

library GeometricSequence
{
    using SafeMath for uint256;
    function sumOfNGeom(uint256 basePrice, uint256 owned, uint256 count) internal pure returns (uint256 price)
    {
        require(count > 0);
        
        uint256 multiplier = 5;
        
        uint256 basePower = owned / multiplier;
        uint256 endPower = (owned + count) / multiplier;
        
        price = (basePrice * (2**basePower) * multiplier).mul((2**((endPower-basePower)+1))-1);
        
        price = price.sub((basePrice * 2**basePower) * (owned % multiplier));
        price = price.sub((basePrice * 2**endPower) * (multiplier - ((owned + count) % multiplier)));
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
contract RigIdle is ERC20 {
    using GeometricSequence for uint;
    using SafeMath for uint;

    struct MinerData 
    {
        // rigs and their upgrades
        mapping(uint256=>uint256)  rigCount;
        mapping(int256=>uint256)   rigPctBonus;
        mapping(int256=>uint256)   rigFlatBonus;
        
        uint256 money;
        uint256 lastUpdateTime;
        uint256 unclaimedPot;
        uint256 lastPotClaimIndex;
        uint256 prestigeLevel; 
        uint256 prestigeBonusPct;
    }
  
    struct BoostData
    {
        int256  rigIndex;
        uint256 flatBonus;
        uint256 percentBonus;
        
        uint256 priceInWEI;
        uint256 priceIncreasePct;
        uint256 totalCount;
        uint256 currentIndex;
        address[] boostHolders;
    }
    
    struct RigData
    {
        uint256 basePrice;
        uint256 baseOutput;
        uint256 unlockMultiplier;
    }
    
    struct PrestigeData
    {
        uint256 price;
        uint256 productionBonusPct;
    }
    
    mapping(uint256=>RigData) private rigData;
    uint256 private numberOfRigs;

    // honey pot variables
    uint256 private honeyPotAmount;
    uint256 private devFund;
    uint256 private nextPotDistributionTime;
    mapping(address => mapping(uint256 => uint256)) private minerICOPerCycle;
    uint256[] private honeyPotPerCycle;
    uint256[] private globalICOPerCycle;
    uint256 private cycleCount;
    
    //booster info
    uint256 private numberOfBoosts;
    mapping(uint256=>BoostData) private boostData;

    //prestige info
    uint256 private maxPrestige;
    mapping(uint256=>PrestigeData) prestigeData;
    
    // miner info
    mapping(address => MinerData) private miners;
    mapping(uint256 => address)   private indexes;
    uint256 private topindex;
    
    address private owner;
    
    // ERC20 functionality
    mapping(address => mapping(address => uint256)) private allowed;
    string public constant name  = "RigWarsIdle";
    string public constant symbol = "RIG";
    uint8 public constant decimals = 8;
    uint256 private estimatedSupply;
    
    // referral
    mapping(address=>address) referrals;
    
    // Data Store Management
    mapping(uint256=>uint256) private prestigeFinalizeTime;
    mapping(uint256=>uint256) private rigFinalizeTime;
    mapping(uint256=>uint256) private boostFinalizeTime;
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function RigIdle() public {
        owner = msg.sender;
        
        //                   price,           prod.     unlockMultiplier
        rigData[0] = RigData(32,              1,        1);
        rigData[1] = RigData(256,             4,        1); 
        rigData[2] = RigData(25600,           64,       2); 
        rigData[3] = RigData(512000,          512,      1); 
        rigData[4] = RigData(10240000,        8192,     4); 
        rigData[5] = RigData(3000000000,      50000,    8); 
        rigData[6] = RigData(75000000000,     250000,   10); 
        rigData[7] = RigData(2500000000000,   1500000,  1);

        numberOfRigs = 8;
        
        topindex = 0;
        honeyPotAmount = 0;
        devFund = 0;
        nextPotDistributionTime = block.timestamp;
        
        miners[msg.sender].lastUpdateTime = block.timestamp;
        miners[msg.sender].rigCount[0] = 1;
      
        indexes[topindex] = msg.sender;
        ++topindex;
        
        boostData[0] = BoostData(-1, 0, 100, 0.1 ether, 5, 5, 0, new address[](5));
        boostData[0].boostHolders[0] = 0xe57A18783640c9fA3c5e8E4d4b4443E2024A7ff9;
        boostData[0].boostHolders[1] = 0xf0333B94F895eb5aAb3822Da376F9CbcfcE8A19C;
        boostData[0].boostHolders[2] = 0x85abE8E3bed0d4891ba201Af1e212FE50bb65a26;
        boostData[0].boostHolders[3] = 0x11e52c75998fe2E7928B191bfc5B25937Ca16741;
        boostData[0].boostHolders[4] = 0x522273122b20212FE255875a4737b6F50cc72006;
        
        numberOfBoosts = 1;
        
        prestigeData[0] = PrestigeData(25000, 100);       // before lvl 3
        prestigeData[1] = PrestigeData(25000000, 200);    // befroe lvl 5 ~30min with 30k prod
        prestigeData[2] = PrestigeData(20000000000, 400); // befroe lvl 7 ~6h with 25-30 lvl6 rig
        
        maxPrestige = 3;
        
        honeyPotPerCycle.push(0);
        globalICOPerCycle.push(1);
        cycleCount = 0;
        
        estimatedSupply = 1000000000000000000000000000;
    }
    
    //--------------------------------------------------------------------------
    // Data access functions
    //--------------------------------------------------------------------------
    function GetTotalMinerCount() public constant returns (uint256 count)
    {
        count = topindex;
    }
    
    function GetMinerAt(uint256 idx) public constant returns (address minerAddr)
    {
        require(idx < topindex);
        minerAddr = indexes[idx];
    }
    
    function GetProductionPerSecond(address minerAddr) public constant returns (uint256 personalProduction)
    {
        MinerData storage m = miners[minerAddr];
        
        personalProduction = 0;
        uint256 productionSpeedFlat = m.rigFlatBonus[-1];
        
        for(uint8 j = 0; j < numberOfRigs; ++j)
        {
            if(m.rigCount[j] > 0)
                personalProduction += (rigData[j].baseOutput + productionSpeedFlat + m.rigFlatBonus[j]) * m.rigCount[j] * (100 + m.rigPctBonus[j]);
            else
                break;
        }
        
        personalProduction = (personalProduction * ((100 + m.prestigeBonusPct) * (100 + m.rigPctBonus[-1]))) / 1000000;
    }
    
    function GetMinerData(address minerAddr) public constant returns 
        (uint256 money, uint256 lastupdate, uint256 prodPerSec, 
         uint256 unclaimedPot, uint256 globalFlat, uint256 globalPct, uint256 prestigeLevel)
    {
        money = miners[minerAddr].money;
        lastupdate = miners[minerAddr].lastUpdateTime;
        prodPerSec = GetProductionPerSecond(minerAddr);
     
        unclaimedPot = miners[minerAddr].unclaimedPot;
        
        globalFlat = miners[minerAddr].rigFlatBonus[-1];
        globalPct  = miners[minerAddr].rigPctBonus[-1];
        
        prestigeLevel = miners[minerAddr].prestigeLevel;
    }
    
    function GetMinerRigsCount(address minerAddr, uint256 startIdx) public constant returns (uint256[10] rigs, uint256[10] totalProduction)
    {
        uint256 i = startIdx;
        MinerData storage m = miners[minerAddr];
        
        for(i = startIdx; i < (startIdx+10) && i < numberOfRigs; ++i)
        {
            rigs[i]      = miners[minerAddr].rigCount[i];
            totalProduction[i] = (rigData[i].baseOutput + m.rigFlatBonus[-1] + m.rigFlatBonus[int256(i)]) * ((100 + m.rigPctBonus[int256(i)]) *
              (100 + m.prestigeBonusPct) * (100 + m.rigPctBonus[-1])) / 1000000;
        }
    }
    
    function GetTotalRigCount() public constant returns (uint256)
    {
        return numberOfRigs;
    }
    
    function GetRigData(uint256 idx) public constant returns (uint256 _basePrice, uint256 _baseOutput, uint256 _unlockMultiplier, uint256 _lockTime)
    {
        require(idx < numberOfRigs);
        
        _basePrice  = rigData[idx].basePrice;
        _baseOutput = rigData[idx].baseOutput;
        _unlockMultiplier  = rigData[idx].unlockMultiplier;
        _lockTime = rigFinalizeTime[idx];
    }
    
    function CalculatePriceofRigs(uint256 idx, uint256 owned, uint256 count) public constant returns (uint256)
    {
        if(idx >= numberOfRigs)
            return 0;
            
        if(owned == 0)
            return (rigData[idx].basePrice * rigData[idx].unlockMultiplier);
            
        return GeometricSequence.sumOfNGeom(rigData[idx].basePrice, owned, count); 
    }
    
    function GetMaxPrestigeLevel() public constant returns (uint256)
    {
        return maxPrestige;
    }
    
    function GetPrestigeInfo(uint256 idx) public constant returns (uint256 price, uint256 bonusPct, uint256 _lockTime)
    {
        require(idx < maxPrestige);
        
        price = prestigeData[idx].price;
        bonusPct = prestigeData[idx].productionBonusPct;
        _lockTime = prestigeFinalizeTime[idx];
    }
  
    function GetPotInfo() public constant returns (uint256 _honeyPotAmount, uint256 _devFunds, uint256 _nextDistributionTime)
    {
        _honeyPotAmount = honeyPotAmount;
        _devFunds = devFund;
        _nextDistributionTime = nextPotDistributionTime;
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
    
    function GetBoosterCount() public constant returns (uint256)
    {
        return numberOfBoosts;
    }
  
    function GetBoosterData(uint256 idx) public constant returns (int256 rigIdx, uint256 flatBonus, uint256 ptcBonus, 
        uint256 currentPrice, uint256 increasePct, uint256 maxNumber, uint256 _lockTime)
    {
        require(idx < numberOfBoosts);
        
        rigIdx       = boostData[idx].rigIndex;
        flatBonus    = boostData[idx].flatBonus;
        ptcBonus     = boostData[idx].percentBonus;
        currentPrice = boostData[idx].priceInWEI;
        increasePct  = boostData[idx].priceIncreasePct;
        maxNumber    = boostData[idx].totalCount;
        _lockTime    = boostFinalizeTime[idx];
    }
    
    function HasBooster(address addr, uint256 startIdx) public constant returns (uint8[10] hasBoost)
    { 
        require(startIdx < numberOfBoosts);
        
        uint j = 0;
        
        for( ;j < 10 && (j + startIdx) < numberOfBoosts; ++j)
        {
            BoostData storage b = boostData[j + startIdx];
            hasBoost[j] = 0;
            for(uint i = 0; i < b.totalCount; ++i)
            {
               if(b.boostHolders[i] == addr)
                    hasBoost[j] = 1;
            }
        }
        for( ;j < 10; ++j)
        {
            hasBoost[j] = 0;
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
        require(m.lastPotClaimIndex <= cycleCount);
        
        uint256 i = m.lastPotClaimIndex;
        uint256 limit = cycleCount;
        
        if((limit - i) > 30) // more than 30 iterations(days) afk
            limit = i + 30;
        
        unclaimedPot = 0;
        for(; i < cycleCount; ++i)
        {
            if(minerICOPerCycle[msg.sender][i] > 0)
                unclaimedPot += (honeyPotPerCycle[i] * minerICOPerCycle[msg.sender][i]) / globalICOPerCycle[i];
        }
    }
    
    // -------------------------------------------------------------------------
    // RigWars game handler functions
    // -------------------------------------------------------------------------
    function StartNewMiner(address referral) external
    {
        require(miners[msg.sender].lastUpdateTime == 0);
        require(referral != msg.sender);
        
        miners[msg.sender].lastUpdateTime = block.timestamp;
        miners[msg.sender].lastPotClaimIndex = cycleCount;
        
        miners[msg.sender].rigCount[0] = 1;
        
        indexes[topindex] = msg.sender;
        ++topindex;
        
        if(referral != owner && referral != 0 && miners[referral].lastUpdateTime != 0)
        {
            referrals[msg.sender] = referral;
            miners[msg.sender].rigCount[0] += 9;
        }
    }
    
    function UpgradeRig(uint8 rigIdx, uint256 count) external
    {
        require(rigIdx < numberOfRigs);
        require(count > 0);
        require(count <= 512);
        require(rigFinalizeTime[rigIdx] < block.timestamp);
        require(miners[msg.sender].lastUpdateTime != 0);
        
        MinerData storage m = miners[msg.sender];
        
        require(m.rigCount[rigIdx] > 0);
        require(512 >= (m.rigCount[rigIdx] + count));
        
        UpdateMoney(msg.sender);
     
        // the base of geometrical sequence
        uint256 price = GeometricSequence.sumOfNGeom(rigData[rigIdx].basePrice, m.rigCount[rigIdx], count); 
       
        require(m.money >= price);
        
        m.rigCount[rigIdx] = m.rigCount[rigIdx] + count;
        
        m.money -= price;
    }
    
    function UnlockRig(uint8 rigIdx) external
    {
        require(rigIdx < numberOfRigs);
        require(rigIdx > 0);
        require(rigFinalizeTime[rigIdx] < block.timestamp);
        require(miners[msg.sender].lastUpdateTime != 0);
        
        MinerData storage m = miners[msg.sender];
        
        require(m.rigCount[rigIdx] == 0);
        require(m.rigCount[rigIdx-1] > 0);
        
        UpdateMoney(msg.sender);
        
        uint256 price = rigData[rigIdx].basePrice * rigData[rigIdx].unlockMultiplier;
        
        require(m.money >= price);
        
        m.rigCount[rigIdx] = 1;
        m.money -= price;
    }
    
    function PrestigeUp() external
    {
        require(miners[msg.sender].lastUpdateTime != 0);
        require(prestigeFinalizeTime[m.prestigeLevel] < block.timestamp);
        
        MinerData storage m = miners[msg.sender];
        
        require(m.prestigeLevel < maxPrestige);
        
        UpdateMoney(msg.sender);
        
        require(m.money >= prestigeData[m.prestigeLevel].price);
        
        if(referrals[msg.sender] != 0)
        {
            miners[referrals[msg.sender]].money += prestigeData[m.prestigeLevel].price / 2;
        }
        
        for(uint256 i = 0; i < numberOfRigs; ++i)
        {
            if(m.rigCount[i] > 1)
                m.rigCount[i] = m.rigCount[i] / 2; 
        }
        
        m.money = 0;
        m.prestigeBonusPct += prestigeData[m.prestigeLevel].productionBonusPct;
        m.prestigeLevel += 1;
    }
 
    function UpdateMoney(address addr) private
    {
        require(block.timestamp > miners[addr].lastUpdateTime);
        
        if(miners[addr].lastUpdateTime != 0)
        {
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
    }
    
    //--------------------------------------------------------------------------
    // BOOSTER handlers
    //--------------------------------------------------------------------------
    function BuyBooster(uint256 idx) external payable 
    {
        require(miners[msg.sender].lastUpdateTime != 0);
        require(idx < numberOfBoosts);
        require(boostFinalizeTime[idx] < block.timestamp);
        
        BoostData storage b = boostData[idx];
        
        require(msg.value >= b.priceInWEI);
        
        for(uint i = 0; i < b.totalCount; ++i)
            if(b.boostHolders[i] == msg.sender)
                revert();
                
        address beneficiary = b.boostHolders[b.currentIndex];
        
        MinerData storage m = miners[beneficiary];
        MinerData storage m2 = miners[msg.sender];
        
        // distribute the ETH
        m.unclaimedPot += (msg.value * 9) / 10;
        honeyPotAmount += msg.value / 20;
        devFund += msg.value / 20;
        
        // increase price by X%
        b.priceInWEI += (b.priceInWEI * b.priceIncreasePct) / 100;
        
        UpdateMoney(msg.sender);
        UpdateMoney(beneficiary);
        
        // transfer ownership    
        b.boostHolders[b.currentIndex] = msg.sender;
        
        // handle booster bonuses
        if(m.rigFlatBonus[b.rigIndex] >= b.flatBonus){
            m.rigFlatBonus[b.rigIndex] -= b.flatBonus;
        } else {
            m.rigFlatBonus[b.rigIndex] = 0;
        }
        
        if(m.rigPctBonus[b.rigIndex] >= b.percentBonus) {
            m.rigPctBonus[b.rigIndex] -= b.percentBonus;
        } else {
            m.rigPctBonus[b.rigIndex] = 0;
        }
        
        m2.rigFlatBonus[b.rigIndex] += b.flatBonus;
        m2.rigPctBonus[b.rigIndex] += b.percentBonus;
        
        // increase booster index
        b.currentIndex += 1;
        if(b.currentIndex >= b.totalCount)
            b.currentIndex = 0;
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

        honeyPotPerCycle[cycleCount] = honeyPotAmount / 4; // 25% of the pot
        
        honeyPotAmount -= honeyPotAmount / 4;

        honeyPotPerCycle.push(0);
        globalICOPerCycle.push(0);
        cycleCount = cycleCount + 1;
    }
    
    function FundICO(uint amount) external
    {
        require(miners[msg.sender].lastUpdateTime != 0);
        require(amount > 0);
        
        MinerData storage m = miners[msg.sender];
        
        UpdateMoney(msg.sender);
        
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
    // Data Storage Management
    //--------------------------------------------------------------------------
     function AddNewBooster(uint256 idx, int256 _rigType, uint256 _flatBonus, uint256 _pctBonus, 
      uint256 _ETHPrice, uint256 _priceIncreasePct, uint256 _totalCount) external
    {
        require(msg.sender == owner);
        require(idx <= numberOfBoosts);
        
        if(idx < numberOfBoosts)
            require(boostFinalizeTime[idx] > block.timestamp); 
            
        boostFinalizeTime[idx] = block.timestamp + 7200;
        
        boostData[idx].rigIndex = _rigType;
        boostData[idx].flatBonus = _flatBonus;
        boostData[idx].percentBonus = _pctBonus;
        
        boostData[idx].priceInWEI = _ETHPrice;
        boostData[idx].priceIncreasePct = _priceIncreasePct;
        boostData[idx].totalCount = _totalCount;
        boostData[idx].currentIndex = 0;
        
        boostData[idx].boostHolders = new address[](_totalCount);
        
        for(uint256 i = 0; i < _totalCount; ++i)
            boostData[idx].boostHolders[i] = owner;
        
        if(idx == numberOfBoosts)    
            numberOfBoosts += 1;
    }
    
    function AddorModifyRig(uint256 idx, uint256 _basePrice, uint256 _baseOutput, uint256 _unlockMultiplier) external
    {
        require(msg.sender == owner);
        require(idx <= numberOfRigs);
        
        if(idx < numberOfRigs)
            require(rigFinalizeTime[idx] > block.timestamp); 
            
        rigFinalizeTime[idx] = block.timestamp + 7200;
        
        rigData[idx].basePrice     = _basePrice;
        rigData[idx].baseOutput    = _baseOutput;
        rigData[idx].unlockMultiplier = _unlockMultiplier;
        
        if(idx == numberOfRigs)
            numberOfRigs += 1;
    }
    
    function AddNewPrestige(uint256 idx, uint256 _price, uint256 _bonusPct) public
    {
        require(msg.sender == owner);
        require(idx <= maxPrestige);
        
        if(idx < maxPrestige)
            require(prestigeFinalizeTime[idx] > block.timestamp); 
            
        prestigeFinalizeTime[idx] = block.timestamp + 7200;
        
        prestigeData[idx].price = _price;
        prestigeData[idx].productionBonusPct = _bonusPct;
        
        if(idx == maxPrestige)
            maxPrestige += 1;
    }
    
    //--------------------------------------------------------------------------
    // ETH handler functions
    //--------------------------------------------------------------------------
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
        
        miners[msg.sender].money = (miners[msg.sender].money).sub(amount);
        miners[recipient].money  = (miners[recipient].money).add(amount);
        
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address miner, address recipient, uint256 amount) public returns (bool) {
        require(amount <= allowed[miner][msg.sender] && amount <= balanceOf(miner));
        
        miners[miner].money        = (miners[miner].money).sub(amount);
        miners[recipient].money    = (miners[recipient].money).add(amount);
        allowed[miner][msg.sender] = (allowed[miner][msg.sender]).sub(amount);
        
        emit Transfer(miner, recipient, amount);
        return true;
    }
    
    function approve(address approvee, uint256 amount) public returns (bool){
        require(amount <= miners[msg.sender].money);
        
        allowed[msg.sender][approvee] = amount;
        emit Approval(msg.sender, approvee, amount);
        return true;
    }
    
    function allowance(address miner, address approvee) public constant returns(uint256){
        return allowed[miner][approvee];
    }
}