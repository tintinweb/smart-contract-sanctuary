pragma solidity ^0.4.0;

interface ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// GOO - Crypto Idle Game
// https://ethergoo.io

contract Goo is ERC20 {
    
    string public constant name  = "IdleEth";
    string public constant symbol = "Goo";
    uint8 public constant decimals = 0;
    uint256 private roughSupply;
    uint256 public totalGooProduction;
    address public owner; // Minor management of game
    bool public gameStarted;
    
    uint256 public researchDivPercent = 8;
    uint256 public gooDepositDivPercent = 2;
    
    uint256 public totalEtherGooResearchPool; // Eth dividends to be split between players&#39; goo production
    uint256[] private totalGooProductionSnapshots; // The total goo production for each prior day past
    uint256[] private totalGooDepositSnapshots;  // The total goo deposited for each prior day past
    uint256[] private allocatedGooResearchSnapshots; // Div pot #1 (research eth allocated to each prior day past)
    uint256[] private allocatedGooDepositSnapshots;  // Div pot #2 (deposit eth allocated to each prior day past)
    uint256 public nextSnapshotTime;
    
    // Balances for each player
    mapping(address => uint256) private ethBalance;
    mapping(address => uint256) private gooBalance;
    mapping(address => mapping(uint256 => uint256)) private gooProductionSnapshots; // Store player&#39;s goo production for given day (snapshot)
    mapping(address => mapping(uint256 => uint256)) private gooDepositSnapshots;    // Store player&#39;s goo deposited for given day (snapshot)
    mapping(address => mapping(uint256 => bool)) private gooProductionZeroedSnapshots; // This isn&#39;t great but we need know difference between 0 production and an unused/inactive day.
    
    mapping(address => uint256) private lastGooSaveTime; // Seconds (last time player claimed their produced goo)
    mapping(address => uint256) public lastGooProductionUpdate; // Days (last snapshot player updated their production)
    mapping(address => uint256) private lastGooResearchFundClaim; // Days (snapshot number)
    mapping(address => uint256) private lastGooDepositFundClaim; // Days (snapshot number)
    mapping(address => uint256) private battleCooldown; // If user attacks they cannot attack again for short time
    
    // Stuff owned by each player
    mapping(address => mapping(uint256 => uint256)) private unitsOwned;
    mapping(address => mapping(uint256 => bool)) private upgradesOwned;
    mapping(uint256 => address) private rareItemOwner;
    mapping(uint256 => uint256) private rareItemPrice;
    
    // Rares & Upgrades (Increase unit&#39;s production / attack etc.)
    mapping(address => mapping(uint256 => uint256)) private unitGooProductionIncreases; // Adds to the goo per second
    mapping(address => mapping(uint256 => uint256)) private unitGooProductionMultiplier; // Multiplies the goo per second
    mapping(address => mapping(uint256 => uint256)) private unitAttackIncreases;
    mapping(address => mapping(uint256 => uint256)) private unitAttackMultiplier;
    mapping(address => mapping(uint256 => uint256)) private unitDefenseIncreases;
    mapping(address => mapping(uint256 => uint256)) private unitDefenseMultiplier;
    mapping(address => mapping(uint256 => uint256)) private unitGooStealingIncreases;
    mapping(address => mapping(uint256 => uint256)) private unitGooStealingMultiplier;
    mapping(address => mapping(uint256 => uint256)) private unitMaxCap;
    
    // Mapping of approved ERC20 transfers (by player)
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => bool) private protectedAddresses; // For npc exchanges (requires 0 goo production)
    
    // Raffle structures
    struct TicketPurchases {
        TicketPurchase[] ticketsBought;
        uint256 numPurchases; // Allows us to reset without clearing TicketPurchase[] (avoids potential for gas limit)
        uint256 raffleId;
    }
    
    // Allows us to query winner without looping (avoiding potential for gas limit)
    struct TicketPurchase {
        uint256 startId;
        uint256 endId;
    }
    
    // Raffle tickets
    mapping(address => TicketPurchases) private rareItemTicketsBoughtByPlayer;
    mapping(uint256 => address[]) private itemRafflePlayers;
    
    // Duplicating for the two raffles is not ideal
    mapping(address => TicketPurchases) private rareUnitTicketsBoughtByPlayer;
    mapping(uint256 => address[]) private unitRafflePlayers;

    // Item raffle info
    uint256 private constant RAFFLE_TICKET_BASE_GOO_PRICE = 1000;
    uint256 private itemRaffleEndTime;
    uint256 private itemRaffleRareId;
    uint256 private itemRaffleTicketsBought;
    address private itemRaffleWinner; // Address of winner
    bool private itemRaffleWinningTicketSelected;
    uint256 private itemRaffleTicketThatWon;
    
     // Unit raffle info
    uint256 private unitRaffleEndTime;
    uint256 private unitRaffleId;     // Raffle Id
    uint256 private unitRaffleRareId; // Unit Id
    uint256 private unitRaffleTicketsBought;
    address private unitRaffleWinner; // Address of winner
    bool private unitRaffleWinningTicketSelected;
    uint256 private unitRaffleTicketThatWon;
    
    // Minor game events
    event UnitBought(address player, uint256 unitId, uint256 amount);
    event UnitSold(address player, uint256 unitId, uint256 amount);
    event PlayerAttacked(address attacker, address target, bool success, uint256 gooStolen);
    
    event ReferalGain(address player, address referal, uint256 amount);
    event UpgradeMigration(address player, uint256 upgradeId, uint256 txProof);
    
    GooGameConfig schema = GooGameConfig(0xf925a82b8c26520170c8d51b65a7def6364877b3);
    
    // Constructor
    function Goo() public payable {
        owner = msg.sender;
    }
    
    function() payable {
        // Fallback will donate to pot
        totalEtherGooResearchPool += msg.value;
    }
    
    function beginGame(uint256 firstDivsTime) external payable {
        require(msg.sender == owner);
        require(!gameStarted);
        
        gameStarted = true; // GO-OOOO!
        nextSnapshotTime = firstDivsTime;
        totalGooDepositSnapshots.push(0); // Add initial-zero snapshot
        totalEtherGooResearchPool = msg.value; // Seed pot
    }
    
    // Incase community prefers goo deposit payments over production %, can be tweaked for balance
    function tweakDailyDividends(uint256 newResearchPercent, uint256 newGooDepositPercent) external {
        require(msg.sender == owner);
        require(newResearchPercent > 0 && newResearchPercent <= 10);
        require(newGooDepositPercent > 0 && newGooDepositPercent <= 10);
        
        researchDivPercent = newResearchPercent;
        gooDepositDivPercent = newGooDepositPercent;
    }
    
    function totalSupply() public constant returns(uint256) {
        return roughSupply; // Stored goo (rough supply as it ignores earned/unclaimed goo)
    }
    
    function balanceOf(address player) public constant returns(uint256) {
        return gooBalance[player] + balanceOfUnclaimedGoo(player);
    }
    
    function balanceOfUnclaimedGoo(address player) internal constant returns (uint256) {
        uint256 lastSave = lastGooSaveTime[player];
        if (lastSave > 0 && lastSave < block.timestamp) {
            return (getGooProduction(player) * (block.timestamp - lastSave)) / 100;
        }
        return 0;
    }
    
    function etherBalanceOf(address player) public constant returns(uint256) {
        return ethBalance[player];
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        updatePlayersGoo(msg.sender);
        require(amount <= gooBalance[msg.sender]);
        
        gooBalance[msg.sender] -= amount;
        gooBalance[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address player, address recipient, uint256 amount) public returns (bool) {
        updatePlayersGoo(player);
        require(amount <= allowed[player][msg.sender] && amount <= gooBalance[player]);
        
        gooBalance[player] -= amount;
        gooBalance[recipient] += amount;
        allowed[player][msg.sender] -= amount;
        
        emit Transfer(player, recipient, amount);
        return true;
    }
    
    function approve(address approvee, uint256 amount) public returns (bool){
        allowed[msg.sender][approvee] = amount;
        emit Approval(msg.sender, approvee, amount);
        return true;
    }
    
    function allowance(address player, address approvee) public constant returns(uint256){
        return allowed[player][approvee];
    }
    
    function getGooProduction(address player) public constant returns (uint256){
        return gooProductionSnapshots[player][lastGooProductionUpdate[player]];
    }
    
    function updatePlayersGoo(address player) internal {
        uint256 gooGain = balanceOfUnclaimedGoo(player);
        lastGooSaveTime[player] = block.timestamp;
        roughSupply += gooGain;
        gooBalance[player] += gooGain;
    }
    
    function updatePlayersGooFromPurchase(address player, uint256 purchaseCost) internal {
        uint256 unclaimedGoo = balanceOfUnclaimedGoo(player);
        
        if (purchaseCost > unclaimedGoo) {
            uint256 gooDecrease = purchaseCost - unclaimedGoo;
            require(gooBalance[player] >= gooDecrease);
            roughSupply -= gooDecrease;
            gooBalance[player] -= gooDecrease;
        } else {
            uint256 gooGain = unclaimedGoo - purchaseCost;
            roughSupply += gooGain;
            gooBalance[player] += gooGain;
        }
        
        lastGooSaveTime[player] = block.timestamp;
    }
    
    function increasePlayersGooProduction(address player, uint256 increase) internal {
        gooProductionSnapshots[player][allocatedGooResearchSnapshots.length] = getGooProduction(player) + increase;
        lastGooProductionUpdate[player] = allocatedGooResearchSnapshots.length;
        totalGooProduction += increase;
    }
    
    function reducePlayersGooProduction(address player, uint256 decrease) internal {
        uint256 previousProduction = getGooProduction(player);
        uint256 newProduction = SafeMath.sub(previousProduction, decrease);
        
        if (newProduction == 0) { // Special case which tangles with "inactive day" snapshots (claiming divs)
            gooProductionZeroedSnapshots[player][allocatedGooResearchSnapshots.length] = true;
            delete gooProductionSnapshots[player][allocatedGooResearchSnapshots.length]; // 0
        } else {
            gooProductionSnapshots[player][allocatedGooResearchSnapshots.length] = newProduction;
        }
        
        lastGooProductionUpdate[player] = allocatedGooResearchSnapshots.length;
        totalGooProduction -= decrease;
    }
    
    
    function buyBasicUnit(uint256 unitId, uint256 amount) external {
        uint256 schemaUnitId;
        uint256 gooProduction;
        uint256 gooCost;
        uint256 ethCost;
        uint256 existing = unitsOwned[msg.sender][unitId];
        (schemaUnitId, gooProduction, gooCost, ethCost) = schema.getUnitInfo(unitId, existing, amount);
        
        require(gameStarted);
        require(schemaUnitId > 0); // Valid unit
        require(ethCost == 0); // Free unit
        
        uint256 newTotal = SafeMath.add(existing, amount);
        if (newTotal > 99) { // Default unit limit
            require(newTotal <= unitMaxCap[msg.sender][unitId]); // Housing upgrades (allow more units)
        }
        
        // Update players goo
        updatePlayersGooFromPurchase(msg.sender, gooCost);
        
        if (gooProduction > 0) {
            increasePlayersGooProduction(msg.sender, getUnitsProduction(msg.sender, unitId, amount));
        }
        
        unitsOwned[msg.sender][unitId] = newTotal;
        emit UnitBought(msg.sender, unitId, amount);
    }
    
    
    function buyEthUnit(uint256 unitId, uint256 amount) external payable {
        uint256 schemaUnitId;
        uint256 gooProduction;
        uint256 gooCost;
        uint256 ethCost;
        uint256 existing = unitsOwned[msg.sender][unitId];
        (schemaUnitId, gooProduction, gooCost, ethCost) = schema.getUnitInfo(unitId, existing, amount);
        
        require(gameStarted);
        require(schemaUnitId > 0);
        require(ethBalance[msg.sender] + msg.value >= ethCost);

        if (ethCost > msg.value) {
            ethBalance[msg.sender] -= (ethCost - msg.value);
        }
        
        uint256 devFund = ethCost / 50; // 2% fee on purchases (marketing, gameplay & maintenance)
        uint256 dividends = (ethCost - devFund) / 4; // 25% goes to pool (75% retained for sale value)
        totalEtherGooResearchPool += dividends;
        ethBalance[owner] += devFund;
        
        
        uint256 newTotal = SafeMath.add(existing, amount);
        if (newTotal > 99) { // Default unit limit
            require(newTotal <= unitMaxCap[msg.sender][unitId]); // Housing upgrades (allow more units)
        }
        
        // Update players goo
        updatePlayersGooFromPurchase(msg.sender, gooCost);
        
        if (gooProduction > 0) {
            increasePlayersGooProduction(msg.sender, getUnitsProduction(msg.sender, unitId, amount));
        }
        
        unitsOwned[msg.sender][unitId] += amount;
        emit UnitBought(msg.sender, unitId, amount);
    }
    
    
    function sellUnit(uint256 unitId, uint256 amount) external {
        uint256 existing = unitsOwned[msg.sender][unitId];
        require(existing >= amount && amount > 0);
        existing -= amount;
        unitsOwned[msg.sender][unitId] = existing;
        
        uint256 schemaUnitId;
        uint256 gooProduction;
        uint256 gooCost;
        uint256 ethCost;
        (schemaUnitId, gooProduction, gooCost, ethCost) = schema.getUnitInfo(unitId, existing, amount);
        require(schema.unitSellable(unitId));
        
        uint256 gooChange = balanceOfUnclaimedGoo(msg.sender) + ((gooCost * 3) / 4); // Claim unsaved goo whilst here
        lastGooSaveTime[msg.sender] = block.timestamp;
        roughSupply += gooChange;
        gooBalance[msg.sender] += gooChange;
        
        if (gooProduction > 0) {
            reducePlayersGooProduction(msg.sender, getUnitsProduction(msg.sender, unitId, amount));
        }
        
        if (ethCost > 0) { // Premium units sell for 75% of buy cost
            ethBalance[msg.sender] += (ethCost * 3) / 4;
        }
        
        emit UnitSold(msg.sender, unitId, amount);
    }
    
    
    function buyUpgrade(uint256 upgradeId) external payable {
        uint256 gooCost;
        uint256 ethCost;
        uint256 upgradeClass;
        uint256 unitId;
        uint256 upgradeValue;
        uint256 prerequisiteUpgrade;
        (gooCost, ethCost, upgradeClass, unitId, upgradeValue, prerequisiteUpgrade) = schema.getUpgradeInfo(upgradeId);
        
        require(gameStarted);
        require(unitId > 0); // Valid upgrade
        require(!upgradesOwned[msg.sender][upgradeId]); // Haven&#39;t already purchased
        
        if (prerequisiteUpgrade > 0) {
            require(upgradesOwned[msg.sender][prerequisiteUpgrade]);
        }
        
        if (ethCost > 0) {
            require(ethBalance[msg.sender] + msg.value >= ethCost);
             if (ethCost > msg.value) { // They can use their balance instead
                ethBalance[msg.sender] -= (ethCost - msg.value);
            }
        
            uint256 devFund = ethCost / 50; // 2% fee on purchases (marketing, gameplay & maintenance)
            totalEtherGooResearchPool += (ethCost - devFund); // Rest goes to div pool (Can&#39;t sell upgrades)
            ethBalance[owner] += devFund;
        }
        
        // Update players goo
        updatePlayersGooFromPurchase(msg.sender, gooCost);

        upgradeUnitMultipliers(msg.sender, upgradeClass, unitId, upgradeValue);
        upgradesOwned[msg.sender][upgradeId] = true;
    }
    
    function upgradeUnitMultipliers(address player, uint256 upgradeClass, uint256 unitId, uint256 upgradeValue) internal {
        uint256 productionGain;
        if (upgradeClass == 0) {
            unitGooProductionIncreases[player][unitId] += upgradeValue;
            productionGain = unitsOwned[player][unitId] * upgradeValue * (10 + unitGooProductionMultiplier[player][unitId]);
            increasePlayersGooProduction(player, productionGain);
        } else if (upgradeClass == 1) {
            unitGooProductionMultiplier[player][unitId] += upgradeValue;
            productionGain = unitsOwned[player][unitId] * upgradeValue * (schema.unitGooProduction(unitId) + unitGooProductionIncreases[player][unitId]);
            increasePlayersGooProduction(player, productionGain);
        } else if (upgradeClass == 2) {
            unitAttackIncreases[player][unitId] += upgradeValue;
        } else if (upgradeClass == 3) {
            unitAttackMultiplier[player][unitId] += upgradeValue;
        } else if (upgradeClass == 4) {
            unitDefenseIncreases[player][unitId] += upgradeValue;
        } else if (upgradeClass == 5) {
            unitDefenseMultiplier[player][unitId] += upgradeValue;
        } else if (upgradeClass == 6) {
            unitGooStealingIncreases[player][unitId] += upgradeValue;
        } else if (upgradeClass == 7) {
            unitGooStealingMultiplier[player][unitId] += upgradeValue;
        } else if (upgradeClass == 8) {
            unitMaxCap[player][unitId] = upgradeValue; // Housing upgrade (new capacity)
        }
    }
    
    function removeUnitMultipliers(address player, uint256 upgradeClass, uint256 unitId, uint256 upgradeValue) internal {
        uint256 productionLoss;
        if (upgradeClass == 0) {
            unitGooProductionIncreases[player][unitId] -= upgradeValue;
            productionLoss = unitsOwned[player][unitId] * upgradeValue * (10 + unitGooProductionMultiplier[player][unitId]);
            reducePlayersGooProduction(player, productionLoss);
        } else if (upgradeClass == 1) {
            unitGooProductionMultiplier[player][unitId] -= upgradeValue;
            productionLoss = unitsOwned[player][unitId] * upgradeValue * (schema.unitGooProduction(unitId) + unitGooProductionIncreases[player][unitId]);
            reducePlayersGooProduction(player, productionLoss);
        } else if (upgradeClass == 2) {
            unitAttackIncreases[player][unitId] -= upgradeValue;
        } else if (upgradeClass == 3) {
            unitAttackMultiplier[player][unitId] -= upgradeValue;
        } else if (upgradeClass == 4) {
            unitDefenseIncreases[player][unitId] -= upgradeValue;
        } else if (upgradeClass == 5) {
            unitDefenseMultiplier[player][unitId] -= upgradeValue;
        } else if (upgradeClass == 6) {
            unitGooStealingIncreases[player][unitId] -= upgradeValue;
        } else if (upgradeClass == 7) {
            unitGooStealingMultiplier[player][unitId] -= upgradeValue;
        }
    }
    
    function buyRareItem(uint256 rareId) external payable {
        uint256 upgradeClass;
        uint256 unitId;
        uint256 upgradeValue;
        (upgradeClass, unitId, upgradeValue) = schema.getRareInfo(rareId);

        address previousOwner = rareItemOwner[rareId];
        require(previousOwner != 0);
        require(unitId > 0);
        
        // We have to claim buyer&#39;s goo before updating their production values
        updatePlayersGoo(msg.sender);
        upgradeUnitMultipliers(msg.sender, upgradeClass, unitId, upgradeValue);
        
        // We have to claim seller&#39;s goo before reducing their production values
        updatePlayersGoo(previousOwner);
        removeUnitMultipliers(previousOwner, upgradeClass, unitId, upgradeValue);
        
        uint256 ethCost = rareItemPrice[rareId];
        require(ethBalance[msg.sender] + msg.value >= ethCost);
        
        // Splitbid/Overbid
        if (ethCost > msg.value) {
            // Earlier require() said they can still afford it (so use their ingame balance)
            ethBalance[msg.sender] -= (ethCost - msg.value);
        } else if (msg.value > ethCost) {
            // Store overbid in their balance
            ethBalance[msg.sender] += msg.value - ethCost;
        }
        
        // Distribute ethCost
        uint256 devFund = ethCost / 50; // 2% fee on purchases (marketing, gameplay & maintenance)
        uint256 dividends = ethCost / 20; // 5% goes to pool (~93% goes to player)
        totalEtherGooResearchPool += dividends;
        ethBalance[owner] += devFund;
        
        // Transfer / update rare item
        rareItemOwner[rareId] = msg.sender;
        rareItemPrice[rareId] = (ethCost * 5) / 4; // 25% price flip increase
        ethBalance[previousOwner] += ethCost - (dividends + devFund);
    }
    
    function withdrawEther(uint256 amount) external {
        require(amount <= ethBalance[msg.sender]);
        ethBalance[msg.sender] -= amount;
        msg.sender.transfer(amount);
    }
    
    function fundGooResearch(uint256 amount) external {
        updatePlayersGooFromPurchase(msg.sender, amount);
        gooDepositSnapshots[msg.sender][totalGooDepositSnapshots.length - 1] += amount;
        totalGooDepositSnapshots[totalGooDepositSnapshots.length - 1] += amount;
    }
    
    function claimResearchDividends(address referer, uint256 startSnapshot, uint256 endSnapShot) external {
        require(startSnapshot <= endSnapShot);
        require(startSnapshot >= lastGooResearchFundClaim[msg.sender]);
        require(endSnapShot < allocatedGooResearchSnapshots.length);
        
        uint256 researchShare;
        uint256 previousProduction = gooProductionSnapshots[msg.sender][lastGooResearchFundClaim[msg.sender] - 1]; // Underflow won&#39;t be a problem as gooProductionSnapshots[][0xffffffffff] = 0;
        for (uint256 i = startSnapshot; i <= endSnapShot; i++) {
            
            // Slightly complex things by accounting for days/snapshots when user made no tx&#39;s
            uint256 productionDuringSnapshot = gooProductionSnapshots[msg.sender][i];
            bool soldAllProduction = gooProductionZeroedSnapshots[msg.sender][i];
            if (productionDuringSnapshot == 0 && !soldAllProduction) {
                productionDuringSnapshot = previousProduction;
            } else {
               previousProduction = productionDuringSnapshot;
            }
            
            researchShare += (allocatedGooResearchSnapshots[i] * productionDuringSnapshot) / totalGooProductionSnapshots[i];
        }
        
        
        if (gooProductionSnapshots[msg.sender][endSnapShot] == 0 && !gooProductionZeroedSnapshots[msg.sender][endSnapShot] && previousProduction > 0) {
            gooProductionSnapshots[msg.sender][endSnapShot] = previousProduction; // Checkpoint for next claim
        }
        
        lastGooResearchFundClaim[msg.sender] = endSnapShot + 1;
        
        uint256 referalDivs;
        if (referer != address(0) && referer != msg.sender) {
            referalDivs = researchShare / 100; // 1%
            ethBalance[referer] += referalDivs;
            emit ReferalGain(referer, msg.sender, referalDivs);
        }
        
        ethBalance[msg.sender] += researchShare - referalDivs;
    }
    
    
    function claimGooDepositDividends(address referer, uint256 startSnapshot, uint256 endSnapShot) external {
        require(startSnapshot <= endSnapShot);
        require(startSnapshot >= lastGooDepositFundClaim[msg.sender]);
        require(endSnapShot < allocatedGooDepositSnapshots.length);
        
        uint256 depositShare;
        for (uint256 i = startSnapshot; i <= endSnapShot; i++) {
            depositShare += (allocatedGooDepositSnapshots[i] * gooDepositSnapshots[msg.sender][i]) / totalGooDepositSnapshots[i];
        }
        
        lastGooDepositFundClaim[msg.sender] = endSnapShot + 1;
        
        uint256 referalDivs;
        if (referer != address(0) && referer != msg.sender) {
            referalDivs = depositShare / 100; // 1%
            ethBalance[referer] += referalDivs;
            emit ReferalGain(referer, msg.sender, referalDivs);
        }
        
        ethBalance[msg.sender] += depositShare - referalDivs;
    }
    
    
    // Allocate pot #1 divs for the day (00:00 cron job)
    function snapshotDailyGooResearchFunding() external {
        require(msg.sender == owner);
        
        uint256 todaysGooResearchFund = (totalEtherGooResearchPool * researchDivPercent) / 100; // 8% of pool daily
        totalEtherGooResearchPool -= todaysGooResearchFund;
        
        totalGooProductionSnapshots.push(totalGooProduction);
        allocatedGooResearchSnapshots.push(todaysGooResearchFund);
        nextSnapshotTime = block.timestamp + 24 hours;
    }
    
    // Allocate pot #2 divs for the day (12:00 cron job)
    function snapshotDailyGooDepositFunding() external {
        require(msg.sender == owner);
        
        uint256 todaysGooDepositFund = (totalEtherGooResearchPool * gooDepositDivPercent) / 100; // 2% of pool daily
        totalEtherGooResearchPool -= todaysGooDepositFund;
        totalGooDepositSnapshots.push(0); // Reset for to store next day&#39;s deposits
        allocatedGooDepositSnapshots.push(todaysGooDepositFund); // Store to payout divs for previous day deposits
    }
    
    
    // Raffle for rare items
    function buyItemRaffleTicket(uint256 amount) external {
        require(itemRaffleEndTime >= block.timestamp);
        require(amount > 0);
        
        uint256 ticketsCost = SafeMath.mul(RAFFLE_TICKET_BASE_GOO_PRICE, amount);
        require(balanceOf(msg.sender) >= ticketsCost);
        
        // Update players goo
        updatePlayersGooFromPurchase(msg.sender, ticketsCost);
        
        // Handle new tickets
        TicketPurchases storage purchases = rareItemTicketsBoughtByPlayer[msg.sender];
        
        // If we need to reset tickets from a previous raffle
        if (purchases.raffleId != itemRaffleRareId) {
            purchases.numPurchases = 0;
            purchases.raffleId = itemRaffleRareId;
            itemRafflePlayers[itemRaffleRareId].push(msg.sender); // Add user to raffle
        }
        
        // Store new ticket purchase
        if (purchases.numPurchases == purchases.ticketsBought.length) {
            purchases.ticketsBought.length += 1;
        }
        purchases.ticketsBought[purchases.numPurchases++] = TicketPurchase(itemRaffleTicketsBought, itemRaffleTicketsBought + (amount - 1)); // (eg: buy 10, get id&#39;s 0-9)
        
        // Finally update ticket total
        itemRaffleTicketsBought += amount;
    }
    
    // Raffle for rare units
    function buyUnitRaffleTicket(uint256 amount) external {
        require(unitRaffleEndTime >= block.timestamp);
        require(amount > 0);
        
        uint256 ticketsCost = SafeMath.mul(RAFFLE_TICKET_BASE_GOO_PRICE, amount);
        require(balanceOf(msg.sender) >= ticketsCost);
        
        // Update players goo
        updatePlayersGooFromPurchase(msg.sender, ticketsCost);
        
        // Handle new tickets
        TicketPurchases storage purchases = rareUnitTicketsBoughtByPlayer[msg.sender];
        
        // If we need to reset tickets from a previous raffle
        if (purchases.raffleId != unitRaffleId) {
            purchases.numPurchases = 0;
            purchases.raffleId = unitRaffleId;
            unitRafflePlayers[unitRaffleId].push(msg.sender); // Add user to raffle
        }
        
        // Store new ticket purchase
        if (purchases.numPurchases == purchases.ticketsBought.length) {
            purchases.ticketsBought.length += 1;
        }
        purchases.ticketsBought[purchases.numPurchases++] = TicketPurchase(unitRaffleTicketsBought, unitRaffleTicketsBought + (amount - 1)); // (eg: buy 10, get id&#39;s 0-9)
        
        // Finally update ticket total
        unitRaffleTicketsBought += amount;
    }
    
    function startItemRaffle(uint256 endTime, uint256 rareId) external {
        require(msg.sender == owner);
        require(schema.validRareId(rareId));
        require(rareItemOwner[rareId] == 0);
        require(block.timestamp < endTime);
        
        if (itemRaffleRareId != 0) { // Sanity to assure raffle has ended before next one starts
            require(itemRaffleWinner != 0);
        }
        
        // Reset previous raffle info
        itemRaffleWinningTicketSelected = false;
        itemRaffleTicketThatWon = 0;
        itemRaffleWinner = 0;
        itemRaffleTicketsBought = 0;
        
        // Set current raffle info
        itemRaffleEndTime = endTime;
        itemRaffleRareId = rareId;
    }
    
    function startUnitRaffle(uint256 endTime, uint256 unitId) external {
        require(msg.sender == owner);
        require(block.timestamp < endTime);
        
        if (unitRaffleRareId != 0) { // Sanity to assure raffle has ended before next one starts
            require(unitRaffleWinner != 0);
        }
        
        // Reset previous raffle info
        unitRaffleWinningTicketSelected = false;
        unitRaffleTicketThatWon = 0;
        unitRaffleWinner = 0;
        unitRaffleTicketsBought = 0;
        
        // Set current raffle info
        unitRaffleEndTime = endTime;
        unitRaffleRareId = unitId;
        unitRaffleId++; // Can&#39;t use unitRaffleRareId (as rare units are not unique)
    }
    
    function awardItemRafflePrize(address checkWinner, uint256 checkIndex) external {
        require(itemRaffleEndTime < block.timestamp);
        require(itemRaffleWinner == 0);
        require(rareItemOwner[itemRaffleRareId] == 0);
        
        if (!itemRaffleWinningTicketSelected) {
            drawRandomItemWinner(); // Ideally do it in one call (gas limit cautious)
        }
        
        // Reduce gas by (optionally) offering an address to _check_ for winner
        if (checkWinner != 0) {
            TicketPurchases storage tickets = rareItemTicketsBoughtByPlayer[checkWinner];
            if (tickets.numPurchases > 0 && checkIndex < tickets.numPurchases && tickets.raffleId == itemRaffleRareId) {
                TicketPurchase storage checkTicket = tickets.ticketsBought[checkIndex];
                if (itemRaffleTicketThatWon >= checkTicket.startId && itemRaffleTicketThatWon <= checkTicket.endId) {
                    assignItemRafflePrize(checkWinner); // WINNER!
                    return;
                }
            }
        }
        
        // Otherwise just naively try to find the winner (will work until mass amounts of players)
        for (uint256 i = 0; i < itemRafflePlayers[itemRaffleRareId].length; i++) {
            address player = itemRafflePlayers[itemRaffleRareId][i];
            TicketPurchases storage playersTickets = rareItemTicketsBoughtByPlayer[player];
            
            uint256 endIndex = playersTickets.numPurchases - 1;
            // Minor optimization to avoid checking every single player
            if (itemRaffleTicketThatWon >= playersTickets.ticketsBought[0].startId && itemRaffleTicketThatWon <= playersTickets.ticketsBought[endIndex].endId) {
                for (uint256 j = 0; j < playersTickets.numPurchases; j++) {
                    TicketPurchase storage playerTicket = playersTickets.ticketsBought[j];
                    if (itemRaffleTicketThatWon >= playerTicket.startId && itemRaffleTicketThatWon <= playerTicket.endId) {
                        assignItemRafflePrize(player); // WINNER!
                        return;
                    }
                }
            }
        }
    }
    
    function awardUnitRafflePrize(address checkWinner, uint256 checkIndex) external {
        require(unitRaffleEndTime < block.timestamp);
        require(unitRaffleWinner == 0);
        
        if (!unitRaffleWinningTicketSelected) {
            drawRandomUnitWinner(); // Ideally do it in one call (gas limit cautious)
        }
        
        // Reduce gas by (optionally) offering an address to _check_ for winner
        if (checkWinner != 0) {
            TicketPurchases storage tickets = rareUnitTicketsBoughtByPlayer[checkWinner];
            if (tickets.numPurchases > 0 && checkIndex < tickets.numPurchases && tickets.raffleId == unitRaffleId) {
                TicketPurchase storage checkTicket = tickets.ticketsBought[checkIndex];
                if (unitRaffleTicketThatWon >= checkTicket.startId && unitRaffleTicketThatWon <= checkTicket.endId) {
                    assignUnitRafflePrize(checkWinner); // WINNER!
                    return;
                }
            }
        }
        
        // Otherwise just naively try to find the winner (will work until mass amounts of players)
        for (uint256 i = 0; i < unitRafflePlayers[unitRaffleId].length; i++) {
            address player = unitRafflePlayers[unitRaffleId][i];
            TicketPurchases storage playersTickets = rareUnitTicketsBoughtByPlayer[player];
            
            uint256 endIndex = playersTickets.numPurchases - 1;
            // Minor optimization to avoid checking every single player
            if (unitRaffleTicketThatWon >= playersTickets.ticketsBought[0].startId && unitRaffleTicketThatWon <= playersTickets.ticketsBought[endIndex].endId) {
                for (uint256 j = 0; j < playersTickets.numPurchases; j++) {
                    TicketPurchase storage playerTicket = playersTickets.ticketsBought[j];
                    if (unitRaffleTicketThatWon >= playerTicket.startId && unitRaffleTicketThatWon <= playerTicket.endId) {
                        assignUnitRafflePrize(player); // WINNER!
                        return;
                    }
                }
            }
        }
    }
    
    function assignItemRafflePrize(address winner) internal {
        itemRaffleWinner = winner;
        rareItemOwner[itemRaffleRareId] = winner;
        rareItemPrice[itemRaffleRareId] = (schema.rareStartPrice(itemRaffleRareId) * 21) / 20; // Buy price slightly higher (Div pool cut)
        
        updatePlayersGoo(winner);
        uint256 upgradeClass;
        uint256 unitId;
        uint256 upgradeValue;
        (upgradeClass, unitId, upgradeValue) = schema.getRareInfo(itemRaffleRareId);
        upgradeUnitMultipliers(winner, upgradeClass, unitId, upgradeValue);
    }
    
    function assignUnitRafflePrize(address winner) internal {
        unitRaffleWinner = winner;
        updatePlayersGoo(winner);
        increasePlayersGooProduction(winner, getUnitsProduction(winner, unitRaffleRareId, 1));
        unitsOwned[winner][unitRaffleRareId] += 1;
    }
    
    // Random enough for small contests (Owner only to prevent trial & error execution)
    function drawRandomItemWinner() public {
        require(msg.sender == owner);
        require(itemRaffleEndTime < block.timestamp);
        require(!itemRaffleWinningTicketSelected);
        
        uint256 seed = itemRaffleTicketsBought + block.timestamp;
        itemRaffleTicketThatWon = addmod(uint256(block.blockhash(block.number-1)), seed, itemRaffleTicketsBought);
        itemRaffleWinningTicketSelected = true;
    }
    
    function drawRandomUnitWinner() public {
        require(msg.sender == owner);
        require(unitRaffleEndTime < block.timestamp);
        require(!unitRaffleWinningTicketSelected);
        
        uint256 seed = unitRaffleTicketsBought + block.timestamp;
        unitRaffleTicketThatWon = addmod(uint256(block.blockhash(block.number-1)), seed, unitRaffleTicketsBought);
        unitRaffleWinningTicketSelected = true;
    }
    
    // Gives players the upgrades they &#39;previously paid for&#39; (i.e. will be one of same unit/type/value of their v1 purchase)
    // Tx of their (prior) purchase is provided so can be validated by anyone for 0 abuse
    function migrateV1Upgrades(address[] playerToCredit, uint256[] upgradeIds, uint256[] txProof) external {
        require(msg.sender == owner);
        require(!gameStarted); // Pre-game migration
        
        for (uint256 i = 0; i < txProof.length; i++) {
            address player = playerToCredit[i];
            uint256 upgradeId = upgradeIds[i];
            
            uint256 unitId = schema.upgradeUnitId(upgradeId);
            if (unitId > 0 && !upgradesOwned[player][upgradeId]) { // Upgrade valid (and haven&#39;t already migrated)
                uint256 upgradeClass = schema.upgradeClass(upgradeId);
                uint256 upgradeValue = schema.upgradeValue(upgradeId);
        
                upgradeUnitMultipliers(player, upgradeClass, unitId, upgradeValue);
                upgradesOwned[player][upgradeId] = true;
                emit UpgradeMigration(player, upgradeId, txProof[i]);
            }
        }
    }
    
    function protectAddress(address exchange, bool shouldProtect) external {
        require(msg.sender == owner);
        if (shouldProtect) {
            require(getGooProduction(exchange) == 0); // Can&#39;t protect actual players
        }
        protectedAddresses[exchange] = shouldProtect;
    }
    
    function attackPlayer(address target) external {
        require(battleCooldown[msg.sender] < block.timestamp);
        require(target != msg.sender);
        require(!protectedAddresses[target]); // Target not whitelisted (i.e. exchange wallets)
        
        uint256 attackingPower;
        uint256 defendingPower;
        uint256 stealingPower;
        (attackingPower, defendingPower, stealingPower) = getPlayersBattlePower(msg.sender, target);
        
        if (battleCooldown[target] > block.timestamp) { // When on battle cooldown you&#39;re vulnerable (starting value is 50% normal power)
            defendingPower = schema.getWeakenedDefensePower(defendingPower);
        }
        
        if (attackingPower > defendingPower) {
            battleCooldown[msg.sender] = block.timestamp + 30 minutes;
            if (balanceOf(target) > stealingPower) {
                // Save all their unclaimed goo, then steal attacker&#39;s max capacity (at same time)
                uint256 unclaimedGoo = balanceOfUnclaimedGoo(target);
                if (stealingPower > unclaimedGoo) {
                    uint256 gooDecrease = stealingPower - unclaimedGoo;
                    gooBalance[target] -= gooDecrease;
                    roughSupply -= gooDecrease;
                } else {
                    uint256 gooGain = unclaimedGoo - stealingPower;
                    gooBalance[target] += gooGain;
                    roughSupply += gooGain;
                }
                gooBalance[msg.sender] += stealingPower;
                emit PlayerAttacked(msg.sender, target, true, stealingPower);
            } else {
                emit PlayerAttacked(msg.sender, target, true, balanceOf(target));
                gooBalance[msg.sender] += balanceOf(target);
                gooBalance[target] = 0;
            }
            
            lastGooSaveTime[target] = block.timestamp;
            // We don&#39;t need to claim/save msg.sender&#39;s goo (as production delta is unchanged)
        } else {
            battleCooldown[msg.sender] = block.timestamp + 10 minutes;
            emit PlayerAttacked(msg.sender, target, false, 0);
        }
    }
    
    function getPlayersBattlePower(address attacker, address defender) internal constant returns (uint256, uint256, uint256) {
        uint256 startId;
        uint256 endId;
        (startId, endId) = schema.battleUnitIdRange();
        
        uint256 attackingPower;
        uint256 defendingPower;
        uint256 stealingPower;

        // Not ideal but will only be a small number of units (and saves gas when buying units)
        while (startId <= endId) {
            attackingPower += getUnitsAttack(attacker, startId, unitsOwned[attacker][startId]);
            stealingPower += getUnitsStealingCapacity(attacker, startId, unitsOwned[attacker][startId]);
            
            defendingPower += getUnitsDefense(defender, startId, unitsOwned[defender][startId]);
            startId++;
        }
        
        return (attackingPower, defendingPower, stealingPower);
    }
    
    function getPlayersBattleStats(address player) external constant returns (uint256, uint256, uint256, uint256) {
        uint256 startId;
        uint256 endId;
        (startId, endId) = schema.battleUnitIdRange();
        
        uint256 attackingPower;
        uint256 defendingPower;
        uint256 stealingPower;

        // Not ideal but will only be a small number of units (and saves gas when buying units)
        while (startId <= endId) {
            attackingPower += getUnitsAttack(player, startId, unitsOwned[player][startId]);
            stealingPower += getUnitsStealingCapacity(player, startId, unitsOwned[player][startId]);
            defendingPower += getUnitsDefense(player, startId, unitsOwned[player][startId]);
            startId++;
        }
        
        if (battleCooldown[player] > block.timestamp) { // When on battle cooldown you&#39;re vulnerable (starting value is 50% normal power)
            defendingPower = schema.getWeakenedDefensePower(defendingPower);
        }
        
        return (attackingPower, defendingPower, stealingPower, battleCooldown[player]);
    }
    
    function getUnitsProduction(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
        return (amount * (schema.unitGooProduction(unitId) + unitGooProductionIncreases[player][unitId]) * (10 + unitGooProductionMultiplier[player][unitId]));
    }
    
    function getUnitsAttack(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
        return (amount * (schema.unitAttack(unitId) + unitAttackIncreases[player][unitId]) * (10 + unitAttackMultiplier[player][unitId])) / 10;
    }
    
    function getUnitsDefense(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
        return (amount * (schema.unitDefense(unitId) + unitDefenseIncreases[player][unitId]) * (10 + unitDefenseMultiplier[player][unitId])) / 10;
    }
    
    function getUnitsStealingCapacity(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
        return (amount * (schema.unitStealingCapacity(unitId) + unitGooStealingIncreases[player][unitId]) * (10 + unitGooStealingMultiplier[player][unitId])) / 10;
    }
    
    
    // To display on website
    function getGameInfo() external constant returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256[], bool[]){
        uint256[] memory units = new uint256[](schema.currentNumberOfUnits());
        bool[] memory upgrades = new bool[](schema.currentNumberOfUpgrades());
        
        uint256 startId;
        uint256 endId;
        (startId, endId) = schema.productionUnitIdRange();
        
        uint256 i;
        while (startId <= endId) {
            units[i] = unitsOwned[msg.sender][startId];
            i++;
            startId++;
        }
        
        (startId, endId) = schema.battleUnitIdRange();
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
        
        return (block.timestamp, totalEtherGooResearchPool, totalGooProduction, totalGooDepositSnapshots[totalGooDepositSnapshots.length - 1],  gooDepositSnapshots[msg.sender][totalGooDepositSnapshots.length - 1],
        nextSnapshotTime, balanceOf(msg.sender), ethBalance[msg.sender], getGooProduction(msg.sender), units, upgrades);
    }
    
    // To display on website
    function getRareItemInfo() external constant returns (address[], uint256[]) {
        address[] memory itemOwners = new address[](schema.currentNumberOfRares());
        uint256[] memory itemPrices = new uint256[](schema.currentNumberOfRares());
        
        uint256 startId;
        uint256 endId;
        (startId, endId) = schema.rareIdRange();
        
        uint256 i;
        while (startId <= endId) {
            itemOwners[i] = rareItemOwner[startId];
            itemPrices[i] = rareItemPrice[startId];
            
            i++;
            startId++;
        }
        
        return (itemOwners, itemPrices);
    }
    
    // To display on website
    function viewUnclaimedResearchDividends() external constant returns (uint256, uint256, uint256) {
        uint256 startSnapshot = lastGooResearchFundClaim[msg.sender];
        uint256 latestSnapshot = allocatedGooResearchSnapshots.length - 1; // No snapshots to begin with
        
        uint256 researchShare;
        uint256 previousProduction = gooProductionSnapshots[msg.sender][lastGooResearchFundClaim[msg.sender] - 1]; // Underflow won&#39;t be a problem as gooProductionSnapshots[][0xfffffffffffff] = 0;
        for (uint256 i = startSnapshot; i <= latestSnapshot; i++) {
            
            // Slightly complex things by accounting for days/snapshots when user made no tx&#39;s
            uint256 productionDuringSnapshot = gooProductionSnapshots[msg.sender][i];
            bool soldAllProduction = gooProductionZeroedSnapshots[msg.sender][i];
            if (productionDuringSnapshot == 0 && !soldAllProduction) {
                productionDuringSnapshot = previousProduction;
            } else {
               previousProduction = productionDuringSnapshot;
            }
            
            researchShare += (allocatedGooResearchSnapshots[i] * productionDuringSnapshot) / totalGooProductionSnapshots[i];
        }
        return (researchShare, startSnapshot, latestSnapshot);
    }
    
    // To display on website
    function viewUnclaimedDepositDividends() external constant returns (uint256, uint256, uint256) {
        uint256 startSnapshot = lastGooDepositFundClaim[msg.sender];
        uint256 latestSnapshot = allocatedGooDepositSnapshots.length - 1; // No snapshots to begin with
        
        uint256 depositShare;
        for (uint256 i = startSnapshot; i <= latestSnapshot; i++) {
            depositShare += (allocatedGooDepositSnapshots[i] * gooDepositSnapshots[msg.sender][i]) / totalGooDepositSnapshots[i];
        }
        return (depositShare, startSnapshot, latestSnapshot);
    }
    
    
    // To allow clients to verify contestants
    function getItemRafflePlayers(uint256 raffleId) external constant returns (address[]) {
        return (itemRafflePlayers[raffleId]);
    }
    
    // To allow clients to verify contestants
    function getUnitRafflePlayers(uint256 raffleId) external constant returns (address[]) {
        return (unitRafflePlayers[raffleId]);
    }
    
    // To allow clients to verify contestants
    function getPlayersItemTickets(address player) external constant returns (uint256[], uint256[]) {
        TicketPurchases storage playersTickets = rareItemTicketsBoughtByPlayer[player];
        
        if (playersTickets.raffleId == itemRaffleRareId) {
            uint256[] memory startIds = new uint256[](playersTickets.numPurchases);
            uint256[] memory endIds = new uint256[](playersTickets.numPurchases);
            
            for (uint256 i = 0; i < playersTickets.numPurchases; i++) {
                startIds[i] = playersTickets.ticketsBought[i].startId;
                endIds[i] = playersTickets.ticketsBought[i].endId;
            }
        }
        
        return (startIds, endIds);
    }
    
    // To allow clients to verify contestants
    function getPlayersUnitTickets(address player) external constant returns (uint256[], uint256[]) {
        TicketPurchases storage playersTickets = rareUnitTicketsBoughtByPlayer[player];
        
        if (playersTickets.raffleId == unitRaffleId) {
            uint256[] memory startIds = new uint256[](playersTickets.numPurchases);
            uint256[] memory endIds = new uint256[](playersTickets.numPurchases);
            
            for (uint256 i = 0; i < playersTickets.numPurchases; i++) {
                startIds[i] = playersTickets.ticketsBought[i].startId;
                endIds[i] = playersTickets.ticketsBought[i].endId;
            }
        }
        
        return (startIds, endIds);
    }
    
    // To display on website
    function getLatestItemRaffleInfo() external constant returns (uint256, uint256, uint256, address, uint256) {
        return (itemRaffleEndTime, itemRaffleRareId, itemRaffleTicketsBought, itemRaffleWinner, itemRaffleTicketThatWon);
    }
    
    // To display on website
    function getLatestUnitRaffleInfo() external constant returns (uint256, uint256, uint256, address, uint256) {
        return (unitRaffleEndTime, unitRaffleRareId, unitRaffleTicketsBought, unitRaffleWinner, unitRaffleTicketThatWon);
    }
    
    
    // New units may be added in future, but check it matches existing schema so no-one can abuse selling.
    function updateGooConfig(address newSchemaAddress) external {
        require(msg.sender == owner);
        
        GooGameConfig newSchema = GooGameConfig(newSchemaAddress);
        
        requireExistingUnitsSame(newSchema);
        requireExistingUpgradesSame(newSchema);
        
        // Finally update config
        schema = GooGameConfig(newSchema);
    }
    
    function requireExistingUnitsSame(GooGameConfig newSchema) internal constant {
        // Requires units eth costs match up or fail execution
        
        uint256 startId;
        uint256 endId;
        (startId, endId) = schema.productionUnitIdRange();
        while (startId <= endId) {
            require(schema.unitEthCost(startId) == newSchema.unitEthCost(startId));
            require(schema.unitGooProduction(startId) == newSchema.unitGooProduction(startId));
            startId++;
        }
        
        (startId, endId) = schema.battleUnitIdRange();
        while (startId <= endId) {
            require(schema.unitEthCost(startId) == newSchema.unitEthCost(startId));
            require(schema.unitAttack(startId) == newSchema.unitAttack(startId));
            require(schema.unitDefense(startId) == newSchema.unitDefense(startId));
            require(schema.unitStealingCapacity(startId) == newSchema.unitStealingCapacity(startId));
            startId++;
        }
    }
    
    function requireExistingUpgradesSame(GooGameConfig newSchema) internal constant {
        uint256 startId;
        uint256 endId;
        
        // Requires ALL upgrade stats match up or fail execution
        (startId, endId) = schema.upgradeIdRange();
        while (startId <= endId) {
            require(schema.upgradeGooCost(startId) == newSchema.upgradeGooCost(startId));
            require(schema.upgradeEthCost(startId) == newSchema.upgradeEthCost(startId));
            require(schema.upgradeClass(startId) == newSchema.upgradeClass(startId));
            require(schema.upgradeUnitId(startId) == newSchema.upgradeUnitId(startId));
            require(schema.upgradeValue(startId) == newSchema.upgradeValue(startId));
            startId++;
        }
        
        // Requires ALL rare stats match up or fail execution
        (startId, endId) = schema.rareIdRange();
        while (startId <= endId) {
            uint256 oldClass;
            uint256 oldUnitId;
            uint256 oldValue;
            
            uint256 newClass;
            uint256 newUnitId;
            uint256 newValue;
            (oldClass, oldUnitId, oldValue) = schema.getRareInfo(startId);
            (newClass, newUnitId, newValue) = newSchema.getRareInfo(startId);
            
            require(oldClass == newClass);
            require(oldUnitId == newUnitId);
            require(oldValue == newValue);
            startId++;
        }
    }
}


contract GooGameConfig {
    
    mapping(uint256 => Unit) private unitInfo;
    mapping(uint256 => Upgrade) private upgradeInfo;
    mapping(uint256 => Rare) private rareInfo;
    
    uint256 public constant currentNumberOfUnits = 15;
    uint256 public constant currentNumberOfUpgrades = 210;
    uint256 public constant currentNumberOfRares = 2;
    
    address public owner;
    
    struct Unit {
        uint256 unitId;
        uint256 baseGooCost;
        uint256 gooCostIncreaseHalf; // Halfed to make maths slightly less (cancels a 2 out)
        uint256 ethCost;
        uint256 baseGooProduction;
        
        uint256 attackValue;
        uint256 defenseValue;
        uint256 gooStealingCapacity;
        bool unitSellable; // Rare units (from raffle) not sellable
    }
    
    struct Upgrade {
        uint256 upgradeId;
        uint256 gooCost;
        uint256 ethCost;
        uint256 upgradeClass;
        uint256 unitId;
        uint256 upgradeValue;
        uint256 prerequisiteUpgrade;
    }
    
    struct Rare {
        uint256 rareId;
        uint256 ethCost;
        uint256 rareClass;
        uint256 unitId;
        uint256 rareValue;
    }
    
    function GooGameConfig() public {
        owner = msg.sender;
        
        rareInfo[1] = Rare(1, 0.5 ether, 1, 1, 40); // 40 = +400%
        rareInfo[2] = Rare(2, 0.5 ether, 0, 2, 35); // +35
        
        unitInfo[1] = Unit(1, 0, 10, 0, 2, 0, 0, 0, true);
        unitInfo[2] = Unit(2, 100, 50, 0, 5, 0, 0, 0, true);
        unitInfo[3] = Unit(3, 0, 0, 0.01 ether, 100, 0, 0, 0, true);
        unitInfo[4] = Unit(4, 200, 100, 0, 10, 0, 0, 0, true);
        unitInfo[5] = Unit(5, 500, 250, 0, 20, 0, 0, 0, true);
        unitInfo[6] = Unit(6, 1000, 500, 0, 40, 0, 0, 0, true);
        unitInfo[7] = Unit(7, 0, 1000, 0.05 ether, 500, 0, 0, 0, true);
        unitInfo[8] = Unit(8, 1500, 750, 0, 60, 0, 0, 0, true);
        unitInfo[9] = Unit(9, 0, 0, 10 ether, 6000, 0, 0, 0, false); // First secret rare unit from raffle (unsellable)
        
        unitInfo[40] = Unit(40, 50, 25, 0, 0, 10, 10, 10000, true);
        unitInfo[41] = Unit(41, 100, 50, 0, 0, 1, 25, 500, true);
        unitInfo[42] = Unit(42, 0, 0, 0.01 ether, 0, 200, 10, 50000, true);
        unitInfo[43] = Unit(43, 250, 125, 0, 0, 25, 1, 15000, true);
        unitInfo[44] = Unit(44, 500, 250, 0, 0, 20, 40, 5000, true);
        unitInfo[45] = Unit(45, 0, 2500, 0.02 ether, 0, 0, 0, 100000, true);
    }
    
    address allowedConfig;
    function setConfigSetupContract(address schema) external {
        require(msg.sender == owner);
        allowedConfig = schema;
    }
    
    function addUpgrade(uint256 id, uint256 goo, uint256 eth, uint256 class, uint256 unit, uint256 value, uint256 prereq) external {
        require(msg.sender == allowedConfig);
        upgradeInfo[id] = Upgrade(id, goo, eth, class, unit, value, prereq);
    }
    
    function getGooCostForUnit(uint256 unitId, uint256 existing, uint256 amount) public constant returns (uint256) {
        Unit storage unit = unitInfo[unitId];
        if (amount == 1) { // 1
            if (existing == 0) {
                return unit.baseGooCost;
            } else {
                return unit.baseGooCost + (existing * unit.gooCostIncreaseHalf * 2);
            }
        } else if (amount > 1) {
            uint256 existingCost;
            if (existing > 0) { // Gated by unit limit
                existingCost = (unit.baseGooCost * existing) + (existing * (existing - 1) * unit.gooCostIncreaseHalf);
            }
            
            existing = SafeMath.add(existing, amount);
            return SafeMath.add(SafeMath.mul(unit.baseGooCost, existing), SafeMath.mul(SafeMath.mul(existing, (existing - 1)), unit.gooCostIncreaseHalf)) - existingCost;
        }
    }
    
    function getWeakenedDefensePower(uint256 defendingPower) external constant returns (uint256) {
        return defendingPower / 2;
    }
    
    function validRareId(uint256 rareId) external constant returns (bool) {
        return (rareId > 0 && rareId < 3);
    }
    
    function unitSellable(uint256 unitId) external constant returns (bool) {
        return unitInfo[unitId].unitSellable;
    }
    
    function unitEthCost(uint256 unitId) external constant returns (uint256) {
        return unitInfo[unitId].ethCost;
    }
    
    function unitGooProduction(uint256 unitId) external constant returns (uint256) {
        return unitInfo[unitId].baseGooProduction;
    }
    
    function unitAttack(uint256 unitId) external constant returns (uint256) {
        return unitInfo[unitId].attackValue;
    }
    
    function unitDefense(uint256 unitId) external constant returns (uint256) {
        return unitInfo[unitId].defenseValue;
    }
    
    function unitStealingCapacity(uint256 unitId) external constant returns (uint256) {
        return unitInfo[unitId].gooStealingCapacity;
    }
    
    function rareStartPrice(uint256 rareId) external constant returns (uint256) {
        return rareInfo[rareId].ethCost;
    }
    
    function upgradeGooCost(uint256 upgradeId) external constant returns (uint256) {
        return upgradeInfo[upgradeId].gooCost;
    }
    
    function upgradeEthCost(uint256 upgradeId) external constant returns (uint256) {
        return upgradeInfo[upgradeId].ethCost;
    }
    
    function upgradeClass(uint256 upgradeId) external constant returns (uint256) {
        return upgradeInfo[upgradeId].upgradeClass;
    }
    
    function upgradeUnitId(uint256 upgradeId) external constant returns (uint256) {
        return upgradeInfo[upgradeId].unitId;
    }
    
    function upgradeValue(uint256 upgradeId) external constant returns (uint256) {
        return upgradeInfo[upgradeId].upgradeValue;
    }
    
    function productionUnitIdRange() external constant returns (uint256, uint256) {
        return (1, 9);
    }
    
    function battleUnitIdRange() external constant returns (uint256, uint256) {
        return (40, 45);
    }
    
    function upgradeIdRange() external constant returns (uint256, uint256) {
        return (1, 210);
    }
    
    function rareIdRange() external constant returns (uint256, uint256) {
        return (1, 2);
    }
    
    function getUpgradeInfo(uint256 upgradeId) external constant returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return (upgradeInfo[upgradeId].gooCost, upgradeInfo[upgradeId].ethCost, upgradeInfo[upgradeId].upgradeClass,
        upgradeInfo[upgradeId].unitId, upgradeInfo[upgradeId].upgradeValue, upgradeInfo[upgradeId].prerequisiteUpgrade);
    }
    
    function getRareInfo(uint256 rareId) external constant returns (uint256, uint256, uint256) {
        return (rareInfo[rareId].rareClass, rareInfo[rareId].unitId, rareInfo[rareId].rareValue);
    }
    
    function getUnitInfo(uint256 unitId, uint256 existing, uint256 amount) external constant returns (uint256, uint256, uint256, uint256) {
        return (unitInfo[unitId].unitId, unitInfo[unitId].baseGooProduction, getGooCostForUnit(unitId, existing, amount), SafeMath.mul(unitInfo[unitId].ethCost, amount));
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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