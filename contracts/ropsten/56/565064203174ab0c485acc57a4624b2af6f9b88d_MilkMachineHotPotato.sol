pragma solidity 0.4.24;

/*
* ====================================*
*
* Team AppX presents - Moon, Inc. II: Milk Machines | Idle Game + Hot Potato
* Website: https://milk.mooninc.io/
* Discord: https://discord.gg/9Ab8Az3
*
* ====================================*
*
* -> Hot Potato Rules:
* - You can purchase machines (hot potatoes) with ETH to increase your milk production.
* - Each machine can only be owned by one person at a time, and can be purchased by anyone (except the current owner) at anytime.
* - When someone purchases a machines, its value is increased by a certain percentage.
* - Rates: 2% to contract owner; 2% to sponsor sponsor (or contract owner if no sponsor); 6% to Milk Fund; 90% to previous owner
* - overbid will be refunded
*
* -> Idle Game Rules:
* - Each machine you own have a pre-defined milk production rate, which will produce milk over time as long as you&#39;re still owning it.
* - You can sell your milk and claim a proportion of the milk fund.
* - You cannot sell milk within the first hour of a new potato starts.
* - The selling price of a milk depends on the Milk Fund and the total milk supply, the formula is:
*   MilkPrice = MilkFund / TotalMilkSupply * Multiplier
*   * Where Multiplier is a number from 0.5 to 1, which starts with 0.5 after a new production unit started, and reaches maximum value (1) after 6 hours.
*
*/


/**
 * @dev Implements &quot;hot potato mechanism&quot;, milk production, 
 *  milk price calulation and milk selling.
 */
contract MilkMachineHotPotato {

    /* ======== STRUCT ======== */

    /// @dev The Potato struct. Every potato in the game is represented by this structure.
    struct Potato {
        uint price;
        uint64 startTime;
        uint64 lastPurchaseTime;
        uint32 purchaseCount;
        uint32 priceIncreasePercent;
        uint32 milkProductionMultiplier;
    }


    /* ======== CONSTANTS ======== */

    /// @dev The cut of all potatoes for the contract owner, measured in basis points (1/100 of a percent).
    uint public constant OWNER_CUT = 200;

    /// @dev The cut of all potatoes for the individual sponsors, measured in basis points (1/100 of a percent).
    uint public constant SPONSOR_CUT = 200;

    /// @dev The portion to be stored as Milk Fund (contract balance), measured in basis points (1/100 of a percent).
    uint public constant MILK_FUND_CUT = 600;

    /// @dev Maximum allowed price increase percentage (100 = potato price doubled each flip).
    uint public constant MAX_PRICE_INCREASE_PERCENT = 100;

    /// @dev Maximum allowed milk production multiplier.
    uint public constant MAX_MILK_PRODUCTION_MULTIPLIER = 8;


    /* ======== STATE VARIABLES ======== */

    /// @dev Contract owner
    address public owner;

    /// @dev An array containing the all the potatoes, the index of this array is the ID of each potato.
    Potato[] public potatoes;

    /// @dev Keeps a record of the IDs of each potato that each user owns.
    mapping(address => uint[]) public ownerPotatoes;

    /// @dev A mapping from potato IDs to the address that owns them.
    mapping(uint => address) potatoIdToOwner;

    /// @dev A mapping from potato IDs to the address the sponsor who will receive the dev cut.
    mapping(uint => address) potatoIdToSponsor;

    /// @dev A mapping from potato ID to index of the ownerPotatoes&#39; potatoes list.
    mapping(uint => uint) potatoIdToOwnerPotatoesIndex;

    // Store the production unit start time to calculate sell price.
    uint[] public potatoStartTime;

    // Global milk balances
    uint public totalMilkProduction;
    uint private totalMilkBalance;
    uint private lastTotalMilkSaveTime; // Last time any player claimed their produced milk

    // Milk balances for each player
    mapping(address => uint) public milkProduction;
    mapping(address => uint) public milkBalance;
    mapping(address => uint) private lastMilkSaveTime; // Last time player claimed their produced milk


    /* ======== EVENTS ======== */

    /// @dev The PotatoSold event is fired whenever a potato is purchased.
    event PotatoSold(uint timestamp, address indexed oldOwner, uint indexed potatoId, uint sellingPrice, uint paymentToOldOwner, address indexed newOwner);


    /* ======== PUBLIC/EXTERNAL FUNCTIONS ======== */

    /// @dev Constructor / optionally can seed the milk fund.
    constructor() public payable {
        owner = msg.sender;

        // Create initial potatoes
        _createPotato(0.01 ether, 1529175600 - 3 days, 50, 1, owner);
        _createPotato(0.01 ether, 1529175600 + 2 hours - 3 days, 50, 2, owner);
        _createPotato(0.01 ether, 1529175600 + 4 hours - 3 days, 50, 3, owner);
    }

    /// @dev Allows user to send ether and purchase the potato.
    function purchasePotato(uint _potatoId) public payable {
        // Store the initial contract balance to assert balance chance at the end of this function.
        uint initialContractBalance = address(this).balance;

        address oldOwner = potatoIdToOwner[_potatoId];
        address newOwner = msg.sender;

        Potato storage potato = potatoes[_potatoId];
        uint currentPrice = potato.price;

        // Making sure the potato purchase has started.
        require(now >= potato.startTime);

        // Making sure potato owner is not sending to self.
        require(oldOwner != newOwner);

        // Safety check to prevent against an unexpected 0x0 default.
        require(newOwner != address(0));

        // Disallow transfers to this contract to prevent accidental misuse.
        require(newOwner != address(this));

        // Making sure sent amount is greater than or equal to the currentPrice, excess fund will be returned later in this function.
        require(msg.value >= currentPrice);

        // Calculate the amount to be paid to the original potato owner.
        uint ownerEarnings = currentPrice * OWNER_CUT / 10000;
        uint sponsorEarnings = currentPrice * SPONSOR_CUT / 10000;
        uint addToMilkFund = currentPrice * MILK_FUND_CUT / 10000;
        uint paymentToOldOwner = currentPrice - ownerEarnings - sponsorEarnings - addToMilkFund;

        // Update the potato price based on its current priceIncrease
        potato.price += uint128(currentPrice * potato.priceIncreasePercent / 100);

        // Set lastPurchaseTime
        potato.lastPurchaseTime = uint64(now);

        // Increment purchaseCount
        potato.purchaseCount++;

        // Update milk production rate for both players.
        _handleProductionDecrease(oldOwner, potato.milkProductionMultiplier);
        _handleProductionIncrease(newOwner, potato.milkProductionMultiplier);

        // Reassign ownership, emit Transfer event. All neccessary preconditions has been checked.
        _transfer(oldOwner, newOwner, _potatoId);

        // Calculate any excess funds sent from the user.
        uint bidExcess = msg.value - currentPrice;

        // Return the excess funds.
        if (bidExcess > 0) {
            msg.sender.transfer(bidExcess);
        }

        // Send the owner cut.
        owner.transfer(ownerEarnings);

        // Send the sponsor cut.
        potatoIdToSponsor[_potatoId].transfer(sponsorEarnings);

        // Pay previous potatoOwner.
        oldOwner.transfer(paymentToOldOwner);

        // Tell the world.
        emit PotatoSold(now, oldOwner, _potatoId, currentPrice, paymentToOldOwner, newOwner);

        // Assert the balance change to be equal to the additional milk fund.
        uint newContractBalance = address(this).balance;
        assert(newContractBalance - initialContractBalance + 1 >= addToMilkFund);
    }

    /**
     * @dev Sell all milk, the eth earned is calculated by the proportion of milk owned.
     *  Selling of milk is forbidden within one hour of new production unit launch.
     */
    function sellAllMilk() public {
        _updatePlayersMilk(msg.sender);

        uint sellPrice = computeMilkSellPrice();

        require(sellPrice > 0);

        uint myMilk = milkBalance[msg.sender];
        uint value = myMilk * sellPrice;

        milkBalance[msg.sender] = 0;

        msg.sender.transfer(value);
    }

    /// @dev The external function for owner to create a new HotPotato potato.
    function createPotato(uint _initialPrice, uint _startTime, uint _priceIncreasePercent, uint _milkProductionMultiplier, address _sponsor) external returns (uint) {
        require(msg.sender == owner);

        // First potato is created in constructor by directly calling the _createPotato internal function so there is always a previous potato.
        uint previousPotatoStartTime = potatoStartTime[potatoStartTime.length - 1];
        require(_startTime >= previousPotatoStartTime && _startTime >= now + 6 hours);
        require(_milkProductionMultiplier <= MAX_MILK_PRODUCTION_MULTIPLIER);
        require(_priceIncreasePercent <= MAX_PRICE_INCREASE_PERCENT);

        return _createPotato(_initialPrice, _startTime, _priceIncreasePercent, _milkProductionMultiplier, _sponsor);
    }


    /* ======== PUBLIC/EXTERNAL VIEW FUNCTIONS ======== */

    /// @dev Returns the total number of potatoes currently in existence.
    function potatoTotalSupply() public view returns (uint) {
        return potatoes.length;
    }

    /// @dev Returns the number of potatoes owned by a specific address.
    function potatoBalanceOf(address _owner) public view returns (uint) {
        return ownerPotatoes[_owner].length;
    }

    /// @dev Get an array of IDs of each potato that an user owns.
    function getOwnerPotatoes(address _owner) external view returns(uint[]) {
        return ownerPotatoes[_owner];
    }

    /// @dev Returns all the relevant information about a specific potato.
    function getPotato(uint _potatoId) external view returns (
        address _owner,
        address _sponsor,
        uint _price,
        uint _startTime,
        uint _lastPurchaseTime,
        uint _purchaseCount,
        uint _priceIncreasePercent,
        uint _milkProductionMultiplier
    ) {
        Potato storage potato = potatoes[_potatoId];

        return (potatoIdToOwner[_potatoId], potatoIdToSponsor[_potatoId], potato.price, potato.startTime, potato.lastPurchaseTime,
            potato.purchaseCount, potato.priceIncreasePercent, potato.milkProductionMultiplier);
    }

    /// @dev Returns all the relevant information about milk production.
    function getState() public view returns (uint, uint, uint, uint, uint, uint, uint) {
        return (totalMilkProduction, milkProduction[msg.sender], milkTotalSupply(), milkBalanceOf(msg.sender), 
            address(this).balance, lastTotalMilkSaveTime, computeMilkSellPrice());
    }

    function milkTotalSupply() public constant returns(uint) {
        return totalMilkBalance + balanceOfTotalUnclaimedMilk();
    }

    function milkBalanceOf(address player) public constant returns(uint) {
        return milkBalance[player] + _balanceOfUnclaimedMilk(player);
    }

    function balanceOfTotalUnclaimedMilk() public constant returns(uint) {
        if (lastTotalMilkSaveTime > 0 && lastTotalMilkSaveTime < block.timestamp) {
            return (totalMilkProduction * (block.timestamp - lastTotalMilkSaveTime));
        }

        return 0;
    }

    /**
     * @dev Compute sell price for 1 milk, with a multiplier of 0.5 when a new potato is started,
     *  and then goes up until it reaches the maximum multiplier after 2 days.
     */
    function computeMilkSellPrice() public view returns (uint) {
        uint supply = milkTotalSupply();

        if (supply == 0) {
            return 0;
        }

        uint index;
        uint lastPotatoStartTime = now;

        while (index < potatoStartTime.length && potatoStartTime[index] < now) {
            lastPotatoStartTime = potatoStartTime[index];
            index++;
        }

        if (now < lastPotatoStartTime + 1 hours) {
            return 0;
        }

        uint timeToMaxValue = 6 hours;

        uint secondsPassed = now - lastPotatoStartTime;
        secondsPassed = secondsPassed <= timeToMaxValue ? secondsPassed : timeToMaxValue;
        uint multiplier = 5000 + 5000 * secondsPassed / timeToMaxValue;

        return address(this).balance / supply * multiplier / 10000;
    }


    /* ======== PRIVATE/INTERNAL FUNCTIONS ======== */

    /// @dev The internal function that creates a new potato and stores it, assume all parameters to be validated.
    function _createPotato(uint _initialPrice, uint _startTime, uint _priceIncreasePercent, uint _milkProductionMultiplier, address _sponsor) internal returns (uint) {
        // Create a new potato.
        potatoes.push(Potato(uint128(_initialPrice), uint64(_startTime), 0, 0, uint32(_priceIncreasePercent), uint32(_milkProductionMultiplier)));

        // Potato id is the index in the storage array.
        uint newPotatoId = potatoes.length - 1;

        potatoIdToSponsor[newPotatoId] = _sponsor;

        // Append potato startTime.
        potatoStartTime.push(_startTime);

        // This will assign the initial ownership of potato to the _sponsor, and also emit the Transfer event.
        _transfer(address(0), _sponsor, newPotatoId);

        // Update milk production rate for initial potato owner.
        _handleProductionIncrease(_sponsor, _milkProductionMultiplier);

        return newPotatoId;
    }

    /// @dev Assigns ownership of a specific potato to an address.
    function _transfer(address _from, address _to, uint _potatoId) internal {
        // Remove potato from _form address.
        // When creating new potato, _from is 0x0.
        if (_from != address(0)) {
            uint[] storage fromPotatoes = ownerPotatoes[_from];
            uint potatoIndex = potatoIdToOwnerPotatoesIndex[_potatoId];

            // Put the last potato to the transferred potato index and update its index in ownerPotatoesIndexes.
            uint lastPotatoId = fromPotatoes[fromPotatoes.length - 1];

            // Do nothing if the transferring potato is the last item.
            if (_potatoId != lastPotatoId) {
                fromPotatoes[potatoIndex] = lastPotatoId;
                potatoIdToOwnerPotatoesIndex[lastPotatoId] = potatoIndex;
            }

            fromPotatoes.length--;
        }

        // Add potato to _to address.
        // Transfer ownership.
        potatoIdToOwner[_potatoId] = _to;

        // Add the _potatoId to ownerPotatoes[_to] and remember the index in ownerPotatoesIndexes.
        potatoIdToOwnerPotatoesIndex[_potatoId] = ownerPotatoes[_to].length;
        ownerPotatoes[_to].push(_potatoId);
    }

    function _handleProductionIncrease(address _player, uint _amount) internal {
        _updatePlayersMilk(_player);

        totalMilkProduction = SafeMath.add(totalMilkProduction, _amount);
        milkProduction[_player] = SafeMath.add(milkProduction[_player], _amount);
    }

    function _handleProductionDecrease(address _player, uint _amount) internal {
        _updatePlayersMilk(_player);

        totalMilkProduction = SafeMath.sub(totalMilkProduction, _amount);
        milkProduction[_player] = SafeMath.sub(milkProduction[_player], _amount);
    }

    function _balanceOfUnclaimedMilk(address _player) internal view returns (uint) {
        uint lastSave = lastMilkSaveTime[_player];

        if (lastSave > 0 && lastSave < block.timestamp) {
            return (milkProduction[_player] * (block.timestamp - lastSave));
        }

        return 0;
    }

    function _updatePlayersMilk(address _player) internal {
        totalMilkBalance += balanceOfTotalUnclaimedMilk();
        milkBalance[_player] += _balanceOfUnclaimedMilk(_player);
        lastTotalMilkSaveTime = block.timestamp;
        lastMilkSaveTime[_player] = block.timestamp;
    }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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