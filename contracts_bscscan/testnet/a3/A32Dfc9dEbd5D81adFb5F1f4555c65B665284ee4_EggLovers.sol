/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: Ownable.sol


// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: EggsConfigs.sol


pragma solidity >= 0.8.7;


contract EggsConfigs is Ownable {

    uint internal startingCoins = 1000000000; // 1bi
    uint internal startingNests = 1;

    struct BaseConfig {
        uint incubationTime; // In Seconds
        uint cardOppeningTime; // In Seconds
        uint nestExpirationTime;
        uint indicationReward;
        uint maxSellPerWeek;
        uint minPerSell;
        uint coinsPrice; // In Gwei
        uint systemChicken;
        uint8 maxCardNumber;
    }

    BaseConfig public configs;

    constructor() {
        configs.incubationTime = 72 * 3600;
        configs.cardOppeningTime = 24 * 3600;
        configs.nestExpirationTime = 240 * 3600;
        configs.indicationReward = 4;
        configs.maxSellPerWeek = 2160;
        configs.minPerSell = 10;
        configs.coinsPrice = 1 ether;
        configs.systemChicken = 5;
        configs.maxCardNumber = 6;
    }

    function setIncubationTime(uint newValue) onlyOwner external {
        configs.incubationTime = newValue;
    }

    function setCardOppeningTime(uint newValue) onlyOwner external {
        configs.cardOppeningTime = newValue;
    }

    function setIndicationReward(uint newValue) onlyOwner external {
        configs.indicationReward = newValue;
    }

    function setMaxSellPerWeek(uint newValue) onlyOwner external {
        configs.maxSellPerWeek = newValue;
    }

    function setMinPerSell(uint newValue) onlyOwner external {
        configs.minPerSell = newValue;
    }

    function setCoinsPrice(uint newValue) onlyOwner external {
        configs.coinsPrice = newValue;
    }
    
    function setSystemChicken(uint newValue) onlyOwner external {
        configs.systemChicken = newValue;
    }

    function setMaxCardNumber(uint8 newValue) onlyOwner external {
        configs.maxCardNumber = newValue;
    }

}
// File: Pausable.sol


// OpenZeppelin Contracts v4.3.2 (security/Pausable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context, Ownable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
// File: @openzeppelin/contracts/utils/math/Math.sol



pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// File: EggLovers.sol


pragma solidity >= 0.8.7;







contract EggLovers is Ownable, EggsConfigs, Pausable {

    event ChickenInsertedOnFarm();
    event NestExpired(uint quantity);
    event WhoIndicate (address indexed whoIndicates);
    event SelledCoins(address indexed who, uint256 amount);
    event ChickenBuyed();
    event SystemChicken();

    event Transfer(address indexed from, address indexed to, uint256 value);

    struct Nest {
        uint id;
        address owner;
        address chicken1Owner;
        address chicken2Owner;
        uint creationTs;
    }
    
    struct Egg {
        uint id;
        uint8 rarity;
        uint incubationStartTs;
    }

    struct Inventory {
        uint firstBuyTs;
        uint coins;
        uint mySelledThisWeek;
        uint currentWeek;

        uint32 availableChickens;
        uint32 availableNests;

        uint32 usedCards;

        uint nestsInFarmStart;
        uint[] nestsInFarm;
    }

    uint internal nonce = 0;
    uint internal nextEggId = 0;
    uint internal weekTime = 7 * 24 * 60 * 60;

    IERC20 internal busdContract = IERC20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);

    mapping (address => Inventory) public inventories;
    mapping (address => Egg[]) public eggs;

    uint public farmFirstNest;
    Nest[] public farm;

    mapping (uint8 => uint) internal _rarityPrices;

    constructor() {
        _rarityPrices[0] = 75;
        _rarityPrices[1] = 85;
        _rarityPrices[2] = 120;

        Inventory storage ownerInv = inventories[msg.sender];
        ownerInv.coins = EggsConfigs.startingCoins;

        while (farm.length < EggsConfigs.startingNests) {
            ownerInv.nestsInFarm.push(farm.length);
            farm.push(Nest(farm.length, msg.sender, address(0), address(0), block.timestamp));
        }
    }

    function getUserInventory() public view returns(Inventory memory) {
        return inventories[msg.sender];
    }

    function getUserEggs() public view returns(Egg[] memory) {
        return eggs[msg.sender];
    }

    function isNestExpired(uint id) internal view returns(bool) {
        return block.timestamp > farm[id].creationTs + EggsConfigs.configs.nestExpirationTime;
    }

    function getFarmFirstNest() internal view returns(uint) {
        uint id = farmFirstNest;
        while(id < farm.length && isNestExpired(id)) id++;
        return id;
    }

    function getActiveNest() public view returns(Nest memory) {
        uint realFarmFirstNest = getFarmFirstNest();
        require(realFarmFirstNest < farm.length, "No active nest");
        return farm[realFarmFirstNest];
    }
    
    function sellCoins(uint256 _amount) external whenNotPaused {
        Inventory storage i = inventories[msg.sender];
        uint thisWeek = block.timestamp / weekTime;
        if(i.currentWeek != thisWeek){
           i.currentWeek = thisWeek;
           i.mySelledThisWeek = 0; 
        }
        require(_amount + i.mySelledThisWeek <= EggsConfigs.configs.maxSellPerWeek, "Week limit");
        require(userCoinsBalance() >= _amount, "You do not have that amount of coins");
        require(_amount >= EggsConfigs.configs.minPerSell);

        i.coins -= _amount;
        i.mySelledThisWeek += _amount;
        
        emit Transfer(address(this), msg.sender, _amount * EggsConfigs.configs.coinsPrice);
        emit SelledCoins(msg.sender, _amount);

        busdContract.transfer(msg.sender, _amount * EggsConfigs.configs.coinsPrice);
    }
    
    function userCoinsBalance() public view returns (uint256) {
        return inventories[msg.sender].coins;
    }

    function getNestsInFarm() public view returns(uint[] memory) {
        return inventories[msg.sender].nestsInFarm;
    }

    function _getAvailableCards(Inventory memory i) internal view returns(uint8) {
        if (i.firstBuyTs == 0) return 1;
        return uint8(Math.min(EggsConfigs.configs.maxCardNumber, 1 + (block.timestamp - i.firstBuyTs) / EggsConfigs.configs.cardOppeningTime));
    }

    function buyFrango() whenNotPaused public {
        Inventory storage i = inventories[msg.sender];
        require(i.usedCards < _getAvailableCards(i), "No inventory slots available");
        if (i.firstBuyTs == 0) {
            i.firstBuyTs = block.timestamp;
            i.currentWeek = block.timestamp / 604800;
        }
        busdContract.transferFrom(msg.sender, address(this), 50 ether);
        i.availableChickens++;
        i.usedCards++;

        emit ChickenBuyed();
    }

    function buyFrangoWithIndication(address indication) external whenNotPaused {
        require(inventories[msg.sender].firstBuyTs == 0, "You already bought a chicken before");
        require(msg.sender != indication, "You cannot indicate yourself");
        inventories[indication].coins += EggsConfigs.configs.indicationReward;
        buyFrango();

        emit WhoIndicate(indication);
    }

    function removeExpiredNests() internal {
        uint realFirstNest = getFarmFirstNest();
        if (realFirstNest > farmFirstNest) {
            emit NestExpired(realFirstNest - farmFirstNest);
            for (uint id = farmFirstNest; id < realFirstNest; id++) {
                Nest memory nest = farm[id];
                inventories[nest.owner].usedCards--;
                inventories[nest.owner].nestsInFarmStart++;
                if (nest.chicken1Owner != address(0)) {
                    inventories[nest.chicken1Owner].usedCards--;
                }
            }
            farmFirstNest = realFirstNest;
        }
    }

    function addNestOnFarm() external whenNotPaused {
        Inventory storage i = inventories[msg.sender];
        require(i.availableNests > 0, "User does not have available nests");
        i.availableNests--;
        i.nestsInFarm.push(farm.length);
        farm.push(Nest(farm.length, msg.sender, address(0), address(0), block.timestamp));
        removeExpiredNests();
    }

    function _generateRarity() internal returns (uint8) {
        uint index = uint(keccak256(abi.encodePacked(block.number, block.timestamp, nonce))) % 100;
        nonce++;
        if (index >= 99) return 2;
        if (index >= 89) return 1;
        return 0;        
    }

    function _createEggForUser(address _ninhoOwner) internal {
        uint8 s_raridade = _generateRarity();
        eggs[_ninhoOwner].push( Egg(nextEggId, s_raridade, block.timestamp) );
        nextEggId++;
    }

    function addChickenOnFarm() external whenNotPaused {
        Inventory storage i = inventories[msg.sender];
        require(i.availableChickens > 0, "No chickens available");

        removeExpiredNests();
        require(farmFirstNest < farm.length, "No nests available in the farm");
        Nest storage nest = farm[farmFirstNest];

        i.availableChickens--;
        if(nest.chicken1Owner != address(0) || (nextEggId + 1) % EggsConfigs.configs.systemChicken == 0) {
            _createEggForUser(nest.owner);
            farmFirstNest++;
            inventories[nest.owner].nestsInFarmStart++;

            inventories[msg.sender].availableNests++;
            if(nest.chicken1Owner != address(0)){
                inventories[nest.chicken1Owner].availableNests++;
            }
            emit SystemChicken();
        } else {
            nest.chicken1Owner = msg.sender;
        }
        emit ChickenInsertedOnFarm();
    }

    function _getEggIndex(uint eggId) internal view returns(uint) {
        Egg[] memory userEggs = eggs[msg.sender];
        uint eggIndex = 0;
        while(eggIndex < userEggs.length && userEggs[eggIndex].id != eggId) eggIndex++;
        require(eggIndex < userEggs.length, "User does not possess this egg");
        return eggIndex;
    }

    function _isEggHatched(Egg memory egg) internal view returns(bool) {
        if (egg.incubationStartTs == 0) return false;
        return block.timestamp - egg.incubationStartTs >= EggsConfigs.configs.incubationTime;
    }

    function openEgg(uint id) external whenNotPaused {
        Egg[] storage userEggs = eggs[msg.sender];
        uint index = _getEggIndex(id);
        Egg memory egg = userEggs[index];
        require(_isEggHatched(egg), "Egg has not hatched yet");
        
        uint coinsReward = _rarityPrices[egg.rarity];
        inventories[owner()].coins -= coinsReward;
        inventories[msg.sender].coins += coinsReward;
        inventories[msg.sender].usedCards--;

        if (userEggs.length > 1) {
            userEggs[index] = userEggs[userEggs.length - 1];
        }
        userEggs.pop();
    }


    // Owner methods

    function _getContractBalance() onlyOwner public view returns (uint256) {
        return address(this).balance;
    }

    function _withdrawFromContract(uint256 _amount) onlyOwner public {
        require(_amount <= _getContractBalance());
        busdContract.transferFrom(address(this), owner() ,_amount * EggsConfigs.configs.coinsPrice);
        emit Transfer(address(this), msg.sender, _amount); 
    }

}