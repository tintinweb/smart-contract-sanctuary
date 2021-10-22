/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

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

// File: @openzeppelin/contracts/security/Pausable.sol



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
abstract contract Pausable is Context {
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
    function _pause() internal virtual whenNotPaused {
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
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: GameManager.sol

//  SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract GameManager is Ownable, Pausable{
    
    address private devWallet;
    string[] private listContractName;
    mapping (string => address) addressOf; // contract name => its address
    constructor(){
        listContractName = ["GLAHeroNFT", "GLAToken", "GLAMarket", "GLASpawner", "GLABattle", "GLAUpgrade", "GLAItem", "GLAEquipment","GLAFarming","GLAP2P"];
    }

    function getListContract() public view returns (string[] memory){
        return listContractName;
    }

    function  getDevWallet() external view returns (address){
        return devWallet;
    }

    function setDevWallet(address devWallet_) public onlyOwner{
        devWallet = devWallet_;
    }

    function getContract(string memory contract_) external whenNotPaused view returns(address){
        return addressOf[contract_];
    }
    
    function setContract(string memory contract_, address address_) external onlyOwner {
        addressOf[contract_] = address_;
    }
    
    function pause() public whenNotPaused onlyOwner{
        _pause();
    }
    
    function unpause() public whenPaused onlyOwner{
        _unpause();
    }
    //GLAMarket
    
    function marketSetMarketFee(uint8 newFee) public onlyOwner{
        IGLAMarket(addressOf["GLAMarket"]).setFee(newFee);
    }
    
    //GLABattle
    function battleSetBaseRate(uint256 _heroLvBaseRate, uint256 _evilLvBaseRate, uint256 _rareBaseRate) public onlyOwner{
        IGLABattle(addressOf["GLABattle"]).setBaseRate(_heroLvBaseRate, _evilLvBaseRate, _rareBaseRate);
    }
    
    function battleSetBaseTokenReward(uint8 _baseTokenReward) public onlyOwner{
        IGLABattle(addressOf["GLABattle"]).setBaseTokenReward(_baseTokenReward);
    }
    
    function battleSetBaseExpReward(uint256 _baseExpReward) public onlyOwner{
        IGLABattle(addressOf["GLABattle"]).setBaseExpReward(_baseExpReward);
    }
    
    function battleSetWinRate(uint8 evilLevel, uint8 value) public onlyOwner{
        IGLABattle(addressOf["GLABattle"]).setWinRate(evilLevel, value);
    }
    
    function battleSetCoolDown(uint8 rarity, uint256 minute) public onlyOwner{
        IGLABattle(addressOf["GLABattle"]).setCoolDown(rarity, minute);
    }
    
    function battleSetWeightOfEvilLv(uint8 _evilLevel, uint256 _weightOfEvilLv) public onlyOwner{
        IGLABattle(addressOf["GLABattle"]).setWeightOfEvilLv(_evilLevel, _weightOfEvilLv);
    }
    
    function battleSetBoostInfo(uint256 _boostTimestamp, uint256 _boostLast, uint256 _boostRateExp, uint256 _boostRateToken) public onlyOwner{
        IGLABattle(addressOf["GLABattle"]).setBoostInfo(_boostTimestamp, _boostLast, _boostRateExp, _boostRateToken);
    }
    
    //GLAItem
    function itemCreateNewItemType(string memory newTypeItem, uint256 price) public onlyOwner {
        IGLAItem(addressOf["GLAItem"]).createNewItemType(newTypeItem, price);
    }
    
    function itemChangeItemPrice(string memory itemType, uint256 price) public onlyOwner{
        IGLAItem(addressOf["GLAItem"]).changeItemPrice(itemType, price);
    }
    
    //GLASpawner
    
    function spawnerSetPriceNewHero(uint256 newHeroPrice) public onlyOwner{
        IGLASpawner(addressOf["GLASpawner"]).setPrice(newHeroPrice);
    }
    
    //GLAHeroNFT
    function heroNFSetRenameFee(uint256 newRenameFee) public onlyOwner{
        IGLAHeroNFT(addressOf["GLAHeroNFT"]).setRenamFee(newRenameFee);
    }
}

interface IGLAMarket{
    function setFee(uint8 fee) external;
}

interface IGLABattle{
    function setBaseRate(uint256 _heroLvBaseRate, uint256 _evilLvBaseRate, uint256 _rareBaseRate) external;
    function setBaseTokenReward(uint8 _baseTokenReward) external;
    function setBaseExpReward(uint256 _baseExpReward) external;
    function setWinRate(uint8 evilLevel, uint8 value) external;
    function setCoolDown(uint8 rarity, uint256 minute) external;
    function setWeightOfEvilLv(uint8 _evilLevel, uint256 _weightOfEvilLv) external;
    function setBoostInfo(uint256 _boostTimestamp, uint256 _boostLast, uint256 _boostRateExp, uint256 _boostRateToken) external;
}

interface IGLAItem{
    function createNewItemType(string memory newTypeItem, uint256 price) external;
    function changeItemPrice(string memory itemType, uint256 price) external;
}

interface IGLASpawner{
        function setPrice(uint256 newHeroPrice) external;
}
interface IGLAHeroNFT{
    function setRenamFee(uint256 newRenameFee) external;
}