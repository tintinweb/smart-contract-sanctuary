/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

pragma solidity ^0.8.0;

struct Fish {
    uint color;
    uint baseIncome;
    uint blockStaked;
    uint reefHealthBonus;
}

// controller 0x01231 points to items, items stored at different addrs (0x123, 0x1234)
// item w/ index 0 thats stored on a controller at 0x01231
// point to opensea/ipfs

contract ReefController {
    mapping(address => Reef) playerReefs; // right now players can only have reef, change to Reef[] for multiple
    mapping(address => bool) playerHasReef; // true/false based on msg.sender

    function startGame() public returns (address _mintedReef) {
        require(!playerHasReef[msg.sender], "You already have a reef!");
        playerHasReef[msg.sender] = true;
        playerReefs[msg.sender] = new Reef();
        return address(playerReefs[msg.sender]);
    }

    function restartGame() public returns (address _newReef) {
        require(playerHasReef[msg.sender], "You must already have a reef to use this function.");
        playerReefs[msg.sender] = new Reef();
        return address(playerReefs[msg.sender]);
    }
}

contract Reef {
    // Item[] activeItems;
    // ItemStruct[] activeItemsStruct;
    // ItemController2 itemStructController;

    // probably the approach we will take.
    // function addItem(address _item) public returns (bool _itemAdded) {
    //     Item _localItem = Item(_item);
    //     reefHealth += _localItem.getHealthModifier();
    //     return true;
    // }

    // function setItemStructControllerAddr(address _addr) public {
    //     itemStructController = ItemController2(_addr);
    // }

    // function addItemStruct(uint _id) public returns (bool _itemAdded) {
    //     activeItemsStruct.push(itemStructController.getItemById(_id));
    // }


    uint constant maxFish = 10;
    uint constant blocksPerDay = 6500;
    uint constant blocksPerDayExpedited = 270; // 1 day per hour
    uint constant blocksPerDaySuperExpedited = 4; // 1 day per minute

    uint constant coralDecimals = 9;

    uint lastBlockClaimed;
    uint genesisBlock;

    Fish[] stakedFish;
    Fish[] inventoryFish;

    uint public coralBalance;
    

    uint reefHealth; // can be 0 - 100, starts at 0 
    uint baseIncome = 100; // 100 shells for basic income (modify w/ external contract?)
    uint currentActiveModifier = 1; // used for "schooling" fish, can be 1.1, 1.2, etc.

    uint percentageDecimalPrecision = 9;

    constructor () {
        lastBlockClaimed = block.number;
        genesisBlock = lastBlockClaimed;
    }

    function mintCommonFish() public {
        // require 2500 coral to mint this fish
        require(coralBalance >= 2500, "You don't have enough Coral to mint this fish.");
        coralBalance -= 2500;
        Fish memory _localFish;
        _localFish.baseIncome = 100;
        _localFish.reefHealthBonus = 5;
        inventoryFish.push(_localFish);
    }

    function mintUncommonFish() public {
        // require 10000 coral to mint this fish
        require(coralBalance >= 10000, "You don't have enough Coral to mint this fish.");
        coralBalance -= 10000;
        Fish memory _localFish;
        _localFish.baseIncome = 250;
        _localFish.reefHealthBonus = 10;
        inventoryFish.push(_localFish);
    }

    function mintRareFish() public {
        // require 25000 coral to mint this fish
        require(coralBalance >= 25000, "You don't have enough Coral to mint this fish.");
        coralBalance -= 25000;
        Fish memory _localFish;
        _localFish.baseIncome = 500;
        _localFish.reefHealthBonus = 25;
        inventoryFish.push(_localFish);
    }

    function mintUltraRareFish() public {
        // require 25000 coral to mint this fish
        require(coralBalance >= 100000, "You don't have enough Coral to mint this fish.");
        coralBalance -= 100000;
        Fish memory _localFish;
        _localFish.baseIncome = 1000;
        _localFish.reefHealthBonus = 50;
        inventoryFish.push(_localFish);
    }

    function stakeFish(uint _index) public returns (bool _success){
        Fish memory _fishToStake = inventoryFish[_index];
        delete inventoryFish[_index]; // TODO: readjust the array (not important for the testnet versions)
        stake(_fishToStake);
        return true;
    }


    // for adding fish to your reef
    function stake(Fish memory _fish) internal returns (bool stakeSuccess){
        // only a certain number of fish can be staked
        require(stakedFish.length < maxFish);
        // fish is staked on this current block
        _fish.blockStaked = block.number;
        
        // update the reef health with the fish's health modifier
        reefHealth += _fish.reefHealthBonus;

        // push to the list of fish currently staked
        stakedFish.push(_fish);
        
        return true;
    }

    function claimRewards() public returns (uint _amountClaimed) {
        coralBalance += checkUnclaimedRewards();

        lastBlockClaimed = block.number;
        // reset the block staked for each fish
        for (uint i = 0; i < stakedFish.length; i++) {
            stakedFish[i].blockStaked = block.number;
        }

        return coralBalance;
    }

    function TEST_setCoralBalance(uint _balance) public {
        coralBalance = _balance;
    }

    function getNumberOfDaysSinceGenesis() public view returns (uint _daysSinceStart) {
        return uint((block.number - genesisBlock) / blocksPerDaySuperExpedited);
    }

    function getFishInventory() public view returns (Fish[] memory _unstakedFish) {
        return inventoryFish;
    }

    function getStakedFish() public view returns (Fish[] memory _stakedFish) {
        return stakedFish;
    }

    // TODO: test this function
    function checkUnclaimedRewards() public view returns (uint _totalRewards) {
        //TODO add currentActiveModifier
        //TODO align decimal precisions correctly (done?)
        uint baseIncomeRewards = baseIncome * getDaysSinceLastWithdraw();
        return uint( ( (baseIncomeRewards + getIncomeFromFish()) * getReefHealthMultiplier() ) / 10**percentageDecimalPrecision) ;  
    }

    // Calculates the reward the staked fish have generated
    // TODO: test this function
    function getIncomeFromFish() public view returns (uint _incomeFromFish) {
        Fish memory currFish;
        for (uint i = 0; i < stakedFish.length; i++) {
            currFish = stakedFish[i];
            _incomeFromFish += (currFish.baseIncome * getDaysStakedForFish(currFish)); 
        }
        return _incomeFromFish;
    }


    // TODO: test this function
    // Internal view
    function getDaysStakedForFish(Fish memory _fish) internal view returns (uint _daysStaked) {
        return uint((block.number - _fish.blockStaked) / blocksPerDaySuperExpedited);
    }

    // Public view for readability
    function getDaysStakedForFish(uint _index) public view returns (uint _daysStaked) {
        return uint((block.number - stakedFish[_index].blockStaked) / blocksPerDaySuperExpedited);
    }

    // TODO: test this function
    function getDaysSinceLastWithdraw() public view returns (uint _daysSinceLastWithdrawal) {
        return uint((block.number - lastBlockClaimed) / blocksPerDaySuperExpedited);
    }

    // add a 'swap' function to swap a staked fish with one you own

    // NOTE uses 9 decimal point precision, so 10^9 == 1, 2 * 10^8 == 0.20, etc.
    function getReefHealthMultiplier() public view returns (uint _multiplier) {
        if (reefHealth < 5) return 2 * 10**(percentageDecimalPrecision-1);
        else if (reefHealth >= 5 && reefHealth < 10) return 3 * 10**(percentageDecimalPrecision-1);
        else if (reefHealth >= 10 && reefHealth < 20) return 4 * 10**(percentageDecimalPrecision-1);
        else if (reefHealth >= 20 && reefHealth < 30) return 5 * 10**(percentageDecimalPrecision-1);
        else if (reefHealth >= 30 && reefHealth < 40) return 6 * 10**(percentageDecimalPrecision-1);
        else if (reefHealth >= 40 && reefHealth < 50) return 7 * 10**(percentageDecimalPrecision-1);
        else if (reefHealth >= 50 && reefHealth < 60) return 8 * 10**(percentageDecimalPrecision-1);
        else if (reefHealth >= 60 && reefHealth < 70) return 9 * 10**(percentageDecimalPrecision-1);
        else if (reefHealth >= 70 && reefHealth < 80) return 10**(percentageDecimalPrecision);
        else if (reefHealth >= 80 && reefHealth < 90) return 11 * 10**(percentageDecimalPrecision-1);
        else if (reefHealth >= 90) return 12 * 10**(percentageDecimalPrecision-1);
    }

    
    function getReefHealth() public view returns (uint _health) {
        return reefHealth;
    }

}