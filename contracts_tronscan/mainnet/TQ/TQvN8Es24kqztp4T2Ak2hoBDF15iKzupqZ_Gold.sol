//SourceUnit: gold-1.2.sol

pragma solidity ^0.4.0;

interface TRC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

interface GoldGameConfig {
    function addUpgrade(uint256 id, uint256 gold, uint256 tron, uint256 class, uint256 unit, uint256 value, uint256 prereq) external;
    function addUnit(uint256 id, uint256 gold, uint256 goldIncreaseHalf, uint256 tron, uint256 production, uint256 attack, uint256 defense, uint256 stealing, bool sellable) external;
    
    function setConstants(uint256 numUnits, uint256 numUpgrades, uint256 numRares, uint256 lastProductionId, uint256 lastSoldierId) external;
    function getGoldCostForUnit(uint256 unitId, uint256 existing, uint256 amount) public constant returns (uint256);
    
    function validRareId(uint256 rareId) external constant returns (bool);
    function unitSellable(uint256 unitId) external constant returns (bool);
    function unitTronCost(uint256 unitId) external constant returns (uint256);
    function unitGoldProduction(uint256 unitId) external constant returns (uint256);
    
    function upgradeGoldCost(uint256 upgradeId) external constant returns (uint256);
    function upgradeTronCost(uint256 upgradeId) external constant returns (uint256);
    function upgradeClass(uint256 upgradeId) external constant returns (uint256);
    function upgradeUnitId(uint256 upgradeId) external constant returns (uint256);
    function upgradeValue(uint256 upgradeId) external constant returns (uint256);
    function productionUnitIdRange() external constant returns (uint256, uint256);
    
    function upgradeIdRange() external constant returns (uint256, uint256);
    
    function getUpgradeInfo(uint256 upgradeId) external constant returns (uint256, uint256, uint256, uint256, uint256, uint256);
    
    function getUnitInfo(uint256 unitId, uint256 existing, uint256 amount) external constant returns (uint256, uint256, uint256, uint256);
    function getCurrentNumberOfUnits() external constant returns (uint256);
    function getCurrentNumberOfUpgrades() external constant returns (uint256);
    
}

// Welcome to the TronGold Contract
// https://trongold.io

contract Gold is TRC20 {
    
    string public constant name  = "Trongold";
    string public constant symbol = "GOLD";
    uint8 public constant decimals = 6;
    uint256 private roughSupply;
    uint256 public totalGoldProduction;
    address public owner; // Minor management of game
    bool public gameStarted;
    bool public tradingActive = true;
    
    uint256 public researchDivPercent = 300;
    uint256 public goldDepositDivPercent = 500;
    
    uint256 public totalTronGoldResearchPool; // TRX dividends to be split between players' gold production
    uint256[] private totalGoldProductionSnapshots; // The total gold production for each prior day past
    uint256[] private totalGoldDepositSnapshots;  // The total gold deposited for each prior day past
    uint256[] private allocatedGoldResearchSnapshots; // Div pot #1 (research TRX allocated to each prior day past)
    uint256[] private allocatedGoldDepositSnapshots;  // Div pot #2 (deposit TRX allocated to each prior day past)
    uint256 public nextSnapshotTime;
    uint256 public nextGoldDepositSnapshotTime;
    
    // Balances for each player
    mapping(address => uint256) private goldBalance;
    mapping(address => mapping(uint256 => uint256)) private goldProductionSnapshots; // Store player's gold production for given day (snapshot)
    mapping(address => mapping(uint256 => uint256)) private goldDepositSnapshots;    // Store player's gold deposited for given day (snapshot)
    mapping(address => mapping(uint256 => bool)) private goldProductionZeroedSnapshots; // This isn't great but we need know difference between 0 production and an unused/inactive day.
    
    mapping(address => address[]) public playerRefList;
    mapping(address => uint) public playerRefBonus;
    mapping(address => mapping(address => bool)) public playerRefLogged;
    
    mapping(address => uint256) private lastGoldSaveTime; // Seconds (last time player claimed their produced gold)
    mapping(address => uint256) public lastGoldProductionUpdate; // Days (last snapshot player updated their production)
    mapping(address => uint256) private lastGoldResearchFundClaim; // Days (snapshot number)
    mapping(address => uint256) private lastGoldDepositFundClaim; // Days (snapshot number)
   
    
    // Stuff owned by each player
    mapping(address => mapping(uint256 => uint256)) private unitsOwned;
    mapping(address => mapping(uint256 => bool)) private upgradesOwned;
   
    
    // Rares & Upgrades (Increase unit's production / attack etc.)
    mapping(address => mapping(uint256 => uint256)) private unitGoldProductionIncreases; // Adds to the gold per second
    mapping(address => mapping(uint256 => uint256)) private unitGoldProductionMultiplier; // Multiplies the gold per second
    
    mapping(address => mapping(uint256 => uint256)) private unitMaxCap;
    
    // Mapping of approved ERC20 transfers (by player)
    mapping(address => mapping(address => uint256)) private allowed;
    address [] investors;
    

    
    // Minor game events
    event UnitBought(address player, uint256 unitId, uint256 amount);
    
    
    event ReferalGain(address player, address referal, uint256 amount);
   
    
    GoldGameConfig schema;
    
    modifier SnapshotCheck {
        if ( block.timestamp >= nextSnapshotTime && nextSnapshotTime != 0){
            snapshotDailyGoldResearchFunding();
        }
        if ( block.timestamp >= nextGoldDepositSnapshotTime && nextGoldDepositSnapshotTime != 0){
            snapshotDailyGoldDepositFunding();
        }
        _;
    }
    
    // Constructor
    function Gold(address schemaAddress) public payable {
        owner = msg.sender;
        schema = GoldGameConfig(schemaAddress);
    }
    
    function() payable SnapshotCheck {
        // Fallback will donate to pot
        totalTronGoldResearchPool += msg.value;
    }
    
    function beginGame(uint256 firstDivsTime) external payable {
        require(msg.sender == owner);
        require(!gameStarted);
        
        gameStarted = true;
        nextSnapshotTime = firstDivsTime;
        nextGoldDepositSnapshotTime = firstDivsTime + 1 minutes;
        totalGoldDepositSnapshots.push(0); // Add initial-zero snapshot
        totalTronGoldResearchPool = msg.value; // Seed pot
    }

     function resetGame(uint256 value) public {
        require(msg.sender == owner);
	require(gameStarted);
        if (totalTronGoldResearchPool < 20 trx) // Reset the game only if total pot is under 20 TRX
        {
            for (uint i=0; i< investors.length ; i++){
     
    //goldProductionSnapshots[investors[i]] = 0; // Store player's gold production for given day (snapshot)
    goldDepositSnapshots[investors[i]][1] = 0;    // Store player's gold deposited for given day (snapshot)
    //goldProductionZeroedSnapshots[investors[i]] = 0; // This isn't great but we need know difference between 0 production and an unused/inactive   
    lastGoldSaveTime[investors[i]] = 0; // Seconds (last time player claimed their produced gold)
    lastGoldProductionUpdate[investors[i]] = 0; // Days (last snapshot player updated their production)
    //lastGoldResearchFundClaim[investors[i]] = 0; // Days (snapshot number)
    //lastGoldDepositFundClaim[investors[i]] = 0; // Days (snapshot number)
            goldProductionSnapshots[investors[i]][allocatedGoldResearchSnapshots.length] = 0;
            goldProductionZeroedSnapshots[investors[i]][allocatedGoldResearchSnapshots.length] = true;
            delete goldProductionSnapshots[investors[i]][allocatedGoldResearchSnapshots.length]; // 0
	    goldProductionSnapshots[investors[i]][lastGoldProductionUpdate[investors[i]]] = 0;

            totalGoldProduction = 0;

	    unitGoldProductionMultiplier[investors[i]][1] = 0;
            unitGoldProductionIncreases[investors[i]][1] = 0;
            unitsOwned[investors[i]][1] = 0;
	    unitGoldProductionMultiplier[investors[i]][2] = 0;
            unitGoldProductionIncreases[investors[i]][2] = 0;
            unitsOwned[investors[i]][2] = 0;
            upgradesOwned[investors[i]][1] = false;
            upgradesOwned[investors[i]][2] = false;
            upgradesOwned[investors[i]][3] = false;
            upgradesOwned[investors[i]][4] = false;
            upgradesOwned[investors[i]][5] = false;
            upgradesOwned[investors[i]][6] = false;
            upgradesOwned[investors[i]][7] = false;
            upgradesOwned[investors[i]][8] = false;
            upgradesOwned[investors[i]][9] = false;
            upgradesOwned[investors[i]][10] = false;
            upgradesOwned[investors[i]][11] = false;
            upgradesOwned[investors[i]][12] = false;
            upgradesOwned[investors[i]][13] = false;
            upgradesOwned[investors[i]][14] = false;
            upgradesOwned[investors[i]][15] = false;
	    upgradesOwned[investors[i]][16] = false;
            upgradesOwned[investors[i]][17] = false;
            upgradesOwned[investors[i]][18] = false;
            upgradesOwned[investors[i]][19] = false;
            upgradesOwned[investors[i]][20] = false;
            upgradesOwned[investors[i]][21] = false;
	    upgradesOwned[investors[i]][22] = false;
            upgradesOwned[investors[i]][23] = false;
	    upgradesOwned[investors[i]][24] = false;
	    upgradesOwned[investors[i]][25] = false;
	    upgradesOwned[investors[i]][26] = false;
	    upgradesOwned[investors[i]][27] = false;
	    upgradesOwned[investors[i]][28] = false;
	    upgradesOwned[investors[i]][29] = false;
	    upgradesOwned[investors[i]][230] = false;
	    upgradesOwned[investors[i]][227] = false;
            upgradesOwned[investors[i]][228] = false;
            upgradesOwned[investors[i]][229] = false;
	    upgradesOwned[investors[i]][230] = false;
	    upgradesOwned[investors[i]][231] = false;
	    upgradesOwned[investors[i]][232] = false;
            upgradesOwned[investors[i]][292] = false;
            upgradesOwned[investors[i]][293] = false;
            upgradesOwned[investors[i]][464] = false;
	    upgradesOwned[investors[i]][465] = false;          
            
        }  
        } } 

    
    
    
    function totalSupply() public constant returns(uint256) {
        return roughSupply; // Stored gold (rough supply as it ignores earned/unclaimed gold)
    }
    
    function balanceOf(address player) public constant returns(uint256) {
        return goldBalance[player] + balanceOfUnclaimedGold(player);
    }
    
    function balanceOfUnclaimedGold(address player) internal constant returns (uint256) {
        uint256 lastSave = lastGoldSaveTime[player];
        if (lastSave > 0 && lastSave < block.timestamp) {
            return (getGoldProduction(player) * (block.timestamp - lastSave)) / 10000;
        }
        return 0;
    }
    
    function transfer(address recipient, uint256 amount) public SnapshotCheck returns (bool) {
        updatePlayersGold(msg.sender);
        require(amount <= goldBalance[msg.sender]);
        require(tradingActive);
        
        goldBalance[msg.sender] -= amount;
        goldBalance[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address player, address recipient, uint256 amount) public SnapshotCheck returns (bool) {
        updatePlayersGold(player);
        require(amount <= allowed[player][msg.sender] && amount <= goldBalance[player]);
        require(tradingActive);
        
        goldBalance[player] -= amount;
        goldBalance[recipient] += amount;
        allowed[player][msg.sender] -= amount;
        
        emit Transfer(player, recipient, amount);
        return true;
    }
    
    function approve(address approvee, uint256 amount) public SnapshotCheck returns (bool){
        allowed[msg.sender][approvee] = amount;
        emit Approval(msg.sender, approvee, amount);
        return true;
    }
    
    function allowance(address player, address approvee) public constant returns(uint256){
        return allowed[player][approvee];
    }
    
    function getGoldProduction(address player) public constant returns (uint256){
        return goldProductionSnapshots[player][lastGoldProductionUpdate[player]];
    }
    
    function updatePlayersGold(address player) internal {
        uint256 goldGain = balanceOfUnclaimedGold(player);
        lastGoldSaveTime[player] = block.timestamp;
        roughSupply += goldGain;
        goldBalance[player] += goldGain;
    }
    
    function updatePlayersGoldFromPurchase(address player, uint256 purchaseCost) internal {
        uint256 unclaimedGold = balanceOfUnclaimedGold(player);
        
        if (purchaseCost > unclaimedGold) {
            uint256 goldDecrease = purchaseCost - unclaimedGold;
            require(goldBalance[player] >= goldDecrease);
            roughSupply -= goldDecrease;
            goldBalance[player] -= goldDecrease;
        } else {
            uint256 goldGain = unclaimedGold - purchaseCost;
            roughSupply += goldGain;
            goldBalance[player] += goldGain;
        }
        
        lastGoldSaveTime[player] = block.timestamp;
    }
    
    function increasePlayersGoldProduction(address player, uint256 increase) internal {
        goldProductionSnapshots[player][allocatedGoldResearchSnapshots.length] = getGoldProduction(player) + increase;
        lastGoldProductionUpdate[player] = allocatedGoldResearchSnapshots.length;
        totalGoldProduction += increase;
    }
    
    function reducePlayersGoldProduction(address player, uint256 decrease) internal {
        uint256 previousProduction = getGoldProduction(player);
        uint256 newProduction = SafeMath.sub(previousProduction, decrease);
        
        if (newProduction == 0) { // Special case which tangles with "inactive day" snapshots (claiming divs)
            goldProductionZeroedSnapshots[player][allocatedGoldResearchSnapshots.length] = true;
            delete goldProductionSnapshots[player][allocatedGoldResearchSnapshots.length]; // 0
        } else {
            goldProductionSnapshots[player][allocatedGoldResearchSnapshots.length] = newProduction;
        }
        
        lastGoldProductionUpdate[player] = allocatedGoldResearchSnapshots.length;
        totalGoldProduction -= decrease;
    }
    
    
    function buyBasicUnit(uint256 unitId, uint256 amount) external SnapshotCheck {
        uint256 schemaUnitId;
        uint256 goldProduction;
        uint256 goldCost;
        uint256 tronCost;
        uint256 existing = unitsOwned[msg.sender][unitId];
        (schemaUnitId, goldProduction, goldCost, tronCost) = schema.getUnitInfo(unitId, existing, amount);
        
        require(gameStarted);
        require(schemaUnitId > 0); // Valid unit
        require(tronCost == 0); // Free unit
        
        uint256 newTotal = SafeMath.add(existing, amount);
        if (newTotal > 9) { // Default unit limit
            require(newTotal <= unitMaxCap[msg.sender][unitId]); // Housing upgrades (allow more units)
        }
        
        // Update players gold
        updatePlayersGoldFromPurchase(msg.sender, goldCost);
        
        if (goldProduction > 0) {
            increasePlayersGoldProduction(msg.sender, getUnitsProduction(msg.sender, unitId, amount));
        }
        investors.push(msg.sender);
        unitsOwned[msg.sender][unitId] = newTotal;
        emit UnitBought(msg.sender, unitId, amount);
    }
    
    
    function buyTronUnit(uint256 unitId, uint256 amount) external payable SnapshotCheck {
        uint256 schemaUnitId;
        uint256 goldProduction;
        uint256 goldCost;
        uint256 tronCost;
        uint256 existing = unitsOwned[msg.sender][unitId];
        (schemaUnitId, goldProduction, goldCost, tronCost) = schema.getUnitInfo(unitId, existing, amount);
        
        require(gameStarted);
        require(schemaUnitId > 0);
        require(msg.value >= tronCost);

        uint256 devFund = SafeMath.div(SafeMath.mul(tronCost, 10), 100); // % for developer
        uint256 dividends = tronCost - devFund;
        totalTronGoldResearchPool += dividends;
        
        
        uint256 newTotal = SafeMath.add(existing, amount);
        if (newTotal > 9) { // Default unit limit
            require(newTotal <= unitMaxCap[msg.sender][unitId]); // Housing upgrades (allow more units)
        }
        
        // Update players gold
        updatePlayersGoldFromPurchase(msg.sender, goldCost);
        
        if (goldProduction > 0) {
            increasePlayersGoldProduction(msg.sender, getUnitsProduction(msg.sender, unitId, amount));
        }
        investors.push(msg.sender);
        unitsOwned[msg.sender][unitId] += amount;
        emit UnitBought(msg.sender, unitId, amount);
        feeSplit(devFund);
    }
    
    
    function buyUpgrade(uint256 upgradeId) external payable SnapshotCheck {
        uint256 goldCost;
        uint256 tronCost;
        uint256 upgradeClass;
        uint256 unitId;
        uint256 upgradeValue;
        uint256 prerequisiteUpgrade;
        (goldCost, tronCost, upgradeClass, unitId, upgradeValue, prerequisiteUpgrade) = schema.getUpgradeInfo(upgradeId);
        
        require(gameStarted);
        require(unitId > 0); // Valid upgrade
        require(!upgradesOwned[msg.sender][upgradeId]); // Haven't already purchased
        
        if (prerequisiteUpgrade > 0) {
            require(upgradesOwned[msg.sender][prerequisiteUpgrade]);
        }
        
        if (tronCost > 0) {
            require(msg.value >= tronCost);
        
            uint256 devFund = SafeMath.div(SafeMath.mul(tronCost, 10), 100); // % for developer
            totalTronGoldResearchPool += (tronCost - devFund); // Rest goes to div pool (Can't sell upgrades)
            feeSplit(devFund);
        }
        
        // Update players gold
        updatePlayersGoldFromPurchase(msg.sender, goldCost);

        upgradeUnitMultipliers(msg.sender, upgradeClass, unitId, upgradeValue);
        upgradesOwned[msg.sender][upgradeId] = true;
    }
    
    function upgradeUnitMultipliers(address player, uint256 upgradeClass, uint256 unitId, uint256 upgradeValue) internal {
        uint256 productionGain;
        if (upgradeClass == 0) {
            unitGoldProductionIncreases[player][unitId] += upgradeValue;
            productionGain = unitsOwned[player][unitId] * upgradeValue * (10 + unitGoldProductionMultiplier[player][unitId]);
            increasePlayersGoldProduction(player, productionGain);
        } else if (upgradeClass == 1) {
            unitGoldProductionMultiplier[player][unitId] += upgradeValue;
            productionGain = unitsOwned[player][unitId] * upgradeValue * (schema.unitGoldProduction(unitId) + unitGoldProductionIncreases[player][unitId]);
            increasePlayersGoldProduction(player, productionGain);
        }  else if (upgradeClass == 8) {
            unitMaxCap[player][unitId] = upgradeValue; // Housing upgrade (new capacity)
        }
    }
    
    function removeUnitMultipliers(address player, uint256 upgradeClass, uint256 unitId, uint256 upgradeValue) internal {
        uint256 productionLoss;
        if (upgradeClass == 0) {
            unitGoldProductionIncreases[player][unitId] -= upgradeValue;
            productionLoss = unitsOwned[player][unitId] * upgradeValue * (10 + unitGoldProductionMultiplier[player][unitId]);
            reducePlayersGoldProduction(player, productionLoss);
        } else if (upgradeClass == 1) {
            unitGoldProductionMultiplier[player][unitId] -= upgradeValue;
            productionLoss = unitsOwned[player][unitId] * upgradeValue * (schema.unitGoldProduction(unitId) + unitGoldProductionIncreases[player][unitId]);
            reducePlayersGoldProduction(player, productionLoss);
        } 
    }
    
    
    
    function withdrawTron(address referer, uint256 startSnapshotResearch, uint256 endSnapshotResearch, uint256 startSnapshotDeposit, uint256 endSnapShotDeposit) external SnapshotCheck {
        claimResearchDividends(referer, startSnapshotResearch, endSnapshotResearch);
        claimGoldDepositDividends(referer, startSnapshotDeposit, endSnapShotDeposit);
    }
    
    function fundGoldResearch(uint256 amount) external SnapshotCheck {
        updatePlayersGoldFromPurchase(msg.sender, amount);
        goldDepositSnapshots[msg.sender][totalGoldDepositSnapshots.length - 1] += amount;
        totalGoldDepositSnapshots[totalGoldDepositSnapshots.length - 1] += amount;
    }
    
    function claimResearchDividends(address referer, uint256 startSnapshot, uint256 endSnapShot) public SnapshotCheck {
        require(startSnapshot <= endSnapShot);
        if (startSnapshot >= lastGoldResearchFundClaim[msg.sender] && endSnapShot < allocatedGoldResearchSnapshots.length) {
            
            uint256 researchShare;
            uint256 previousProduction = goldProductionSnapshots[msg.sender][lastGoldResearchFundClaim[msg.sender] - 1]; // Underflow won't be a problem as goldProductionSnapshots[][0xffffffffff] = 0;
            for (uint256 i = startSnapshot; i <= endSnapShot; i++) {
                
                // Slightly complex things by accounting for days/snapshots when user made no tx's
                uint256 productionDuringSnapshot = goldProductionSnapshots[msg.sender][i];
                bool soldAllProduction = goldProductionZeroedSnapshots[msg.sender][i];
                if (productionDuringSnapshot == 0 && !soldAllProduction) {
                    productionDuringSnapshot = previousProduction;
                } else {
                   previousProduction = productionDuringSnapshot;
                }
                
                researchShare += (allocatedGoldResearchSnapshots[i] * productionDuringSnapshot) / totalGoldProductionSnapshots[i];
            }
            
            
            if (goldProductionSnapshots[msg.sender][endSnapShot] == 0 && !goldProductionZeroedSnapshots[msg.sender][endSnapShot] && previousProduction > 0) {
                goldProductionSnapshots[msg.sender][endSnapShot] = previousProduction; // Checkpoint for next claim
            }
            
            lastGoldResearchFundClaim[msg.sender] = endSnapShot + 1;
            
            uint256 referalDivs;
            if (referer != address(0) && referer != msg.sender) {
                referalDivs = researchShare / 100; // 1%
                referer.send(referalDivs);
                playerRefBonus[referer] += referalDivs;
                if (!playerRefLogged[referer][msg.sender]){
                    playerRefLogged[referer][msg.sender] = true;
                    playerRefList[referer].push(msg.sender);
                }
                emit ReferalGain(referer, msg.sender, referalDivs);
            }
            
            msg.sender.send(researchShare - referalDivs);
        }
    }
    
    
    function claimGoldDepositDividends(address referer, uint256 startSnapshot, uint256 endSnapShot) public SnapshotCheck {
        require(startSnapshot <= endSnapShot);
        if (startSnapshot >= lastGoldDepositFundClaim[msg.sender] && endSnapShot < allocatedGoldDepositSnapshots.length) {
            uint256 depositShare;
            for (uint256 i = startSnapshot; i <= endSnapShot; i++) {
                uint256 totalDeposited = totalGoldDepositSnapshots[i];
                if (totalDeposited > 0) {
                    depositShare += (allocatedGoldDepositSnapshots[i] * goldDepositSnapshots[msg.sender][i]) / totalDeposited;
                }
            }
            
            lastGoldDepositFundClaim[msg.sender] = endSnapShot + 1;
            
            uint256 referalDivs;
            if (referer != address(0) && referer != msg.sender) {
                referalDivs = depositShare / 100; // 1%
                referer.send(referalDivs);
                playerRefBonus[referer] += referalDivs;
                if (!playerRefLogged[referer][msg.sender]){
                    playerRefLogged[referer][msg.sender] = true;
                    playerRefList[referer].push(msg.sender);
                }
                emit ReferalGain(referer, msg.sender, referalDivs);
            }
            
            msg.sender.send(depositShare - referalDivs);
        }
    }
    
    
    // Allocate pot #1 divs for the day (00:00 cron job)
    function snapshotDailyGoldResearchFunding() public {
        //require(msg.sender == owner);
        require(block.timestamp >= nextSnapshotTime);
        
        uint256 todaysGoldResearchFund = (totalTronGoldResearchPool * researchDivPercent) / 10000; // % of pool daily
        //uint256 todaysGoldResearchFund = 0; // % of pool daily
        totalTronGoldResearchPool -= todaysGoldResearchFund;
        
        totalGoldProductionSnapshots.push(totalGoldProduction);
        allocatedGoldResearchSnapshots.push(todaysGoldResearchFund);
        nextSnapshotTime = block.timestamp + 2 minutes;
    }
    
    // Allocate pot #2 divs for the day (12:00 cron job)
    function snapshotDailyGoldDepositFunding() public {
        //require(msg.sender == owner);
        require(block.timestamp >= nextGoldDepositSnapshotTime);
        
        uint256 todaysGoldDepositFund = (totalTronGoldResearchPool * goldDepositDivPercent) / 10000; // % of pool daily
        totalTronGoldResearchPool -= todaysGoldDepositFund;
        totalGoldDepositSnapshots.push(0); // Reset for to store next day's deposits
        allocatedGoldDepositSnapshots.push(todaysGoldDepositFund); // Store to payout divs for previous day deposits
        
        nextGoldDepositSnapshotTime = block.timestamp + 2 minutes;
    }
    
    
    
        function feeSplit(uint value) internal {
        uint a = value;
        owner.send(a); //
    }
    
    
    function getUnitsProduction(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
        return (amount * (schema.unitGoldProduction(unitId) + unitGoldProductionIncreases[player][unitId]) * (10 + unitGoldProductionMultiplier[player][unitId]));
    }
    
    
    
    function getPlayerRefs(address player) public view returns (uint) {
        return playerRefList[player].length;
    }
    
    // To display on website
    function getGameInfo() external constant returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256[], bool[], uint256){
        uint256[] memory units = new uint256[](schema.getCurrentNumberOfUnits());
        bool[] memory upgrades = new bool[](schema.getCurrentNumberOfUpgrades());
        
        uint256 startId;
        uint256 endId;
        (startId, endId) = schema.productionUnitIdRange();
        
        uint256 i;
        while (startId <= endId) {
            units[i] = unitsOwned[msg.sender][startId];
            i++;
            startId++;
        }
        
        
        
        // Reset for upgrades
        i = 0;
        (startId, endId) = schema.upgradeIdRange();
        while (startId <= endId) {
            upgrades[i] = upgradesOwned[msg.sender][startId];
            i++;
            startId++;
        }
        
        return (block.timestamp, totalTronGoldResearchPool, totalGoldProduction, totalGoldDepositSnapshots[totalGoldDepositSnapshots.length - 1],  goldDepositSnapshots[msg.sender][totalGoldDepositSnapshots.length - 1],
        nextSnapshotTime, balanceOf(msg.sender), getGoldProduction(msg.sender), units, upgrades, nextGoldDepositSnapshotTime);
    }
    
    
    
    // To display on website
    function viewUnclaimedResearchDividends() external constant returns (uint256, uint256, uint256) {
        uint256 startSnapshot = lastGoldResearchFundClaim[msg.sender];
        uint256 latestSnapshot = allocatedGoldResearchSnapshots.length - 1; // No snapshots to begin with
        
        uint256 researchShare;
        uint256 previousProduction = goldProductionSnapshots[msg.sender][lastGoldResearchFundClaim[msg.sender] - 1]; // Underflow won't be a problem as goldProductionSnapshots[][0xfffffffffffff] = 0;
        for (uint256 i = startSnapshot; i <= latestSnapshot; i++) {
            
            // Slightly complex things by accounting for days/snapshots when user made no tx's
            uint256 productionDuringSnapshot = goldProductionSnapshots[msg.sender][i];
            bool soldAllProduction = goldProductionZeroedSnapshots[msg.sender][i];
            if (productionDuringSnapshot == 0 && !soldAllProduction) {
                productionDuringSnapshot = previousProduction;
            } else {
               previousProduction = productionDuringSnapshot;
            }
            
            researchShare += (allocatedGoldResearchSnapshots[i] * productionDuringSnapshot) / totalGoldProductionSnapshots[i];
        }
        return (researchShare, startSnapshot, latestSnapshot);
    }
    
    // To display on website
    function viewUnclaimedDepositDividends() external constant returns (uint256, uint256, uint256) {
        uint256 startSnapshot = lastGoldDepositFundClaim[msg.sender];
        uint256 latestSnapshot = allocatedGoldDepositSnapshots.length - 1; // No snapshots to begin with
        
        uint256 depositShare;
        for (uint256 i = startSnapshot; i <= latestSnapshot; i++) {
            depositShare += (allocatedGoldDepositSnapshots[i] * goldDepositSnapshots[msg.sender][i]) / totalGoldDepositSnapshots[i];
        }
        return (depositShare, startSnapshot, latestSnapshot);
    }
    
    
    
    
   
    
    
    // New units may be added in future, but check it matches existing schema so no-one can abuse selling.
    function updateGoldConfig(address newSchemaAddress) external {
        require(msg.sender == owner);
        
        GoldGameConfig newSchema = GoldGameConfig(newSchemaAddress);
        
        
        
        // Finally update config
        schema = GoldGameConfig(newSchema);
    }
    
    
    
    
}


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}