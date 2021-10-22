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

// File: GLASpawner.sol


pragma solidity ^0.8.0;



contract GLASpawner is Ownable{
    uint private rarity1 = 7500; // threshold for 1-star hero  
    uint private rarity2 = 9375; // threshold for 2-star hero
    
    uint256 newHeroPrice = 7e21;
    
    address private gameManager;
    
    event OpenChest(address indexed user, uint heroType, uint8 rarity);
    event BuyNewHero(address indexed user, uint256 heroType);
    event SetPrice(uint256 newHeroPrice);

    modifier onlyGameManager {
        require(gameManager == msg.sender, "not authorized");
        _;
    }

    constructor(address gameManager_) Ownable() {
        setGameManager(gameManager_);
    }
    
    // user buys 1-star hero
    function buyNewHero(uint heroType) public {
        require(heroType < 3, "Unavailable type hero");
        require(tx.origin == msg.sender, "don't try to cheat");

        address devWallet = IGameManager(gameManager).getDevWallet();
        address GLATokenContract = IGameManager(gameManager).getContract("GLAToken");
    
        IGLAToken(GLATokenContract).transferFrom(msg.sender, devWallet, newHeroPrice);
        _mint(msg.sender, heroType, 1);
        emit BuyNewHero(msg.sender, heroType);
    }
    
    function openERC1155Chest() public {
        require(tx.origin == msg.sender, "don't try to cheat");
        address glaItem = IGameManager(gameManager).getContract("GLAItem");
        IGLAItem(glaItem).burn(msg.sender, 3, 1);
        uint256 rnd = _random(10000);
        uint8 rarity;
        if (rnd < rarity1) 
            rarity = 1;
        else if (rnd < rarity2)
            rarity = 2;
        else
            rarity = 3;

        uint heroType = _random(3);

         _mint(msg.sender, heroType, rarity);
        emit OpenChest(msg.sender, heroType, rarity);
    }

    function setPrice(uint256 newHeroPrice_) external onlyGameManager  {
        newHeroPrice = newHeroPrice_;
        emit SetPrice(newHeroPrice_);
    }
    
    function getHeroPrice() public view returns(uint256) {
        return newHeroPrice;
    }
    
    function _random(uint256 range) internal view returns (uint256)  {
        return uint256(keccak256(abi.encodePacked(
                                                    msg.sender, 
                                                    blockhash(block.number-1), 
                                                    block.gaslimit, 
                                                    block.timestamp, 
                                                    gasleft())))%range;      
    }

    function _mint(address owner, uint heroType, uint8 rarity) internal{
        address heroContract = IGameManager(gameManager).getContract("GLAHeroNFT");
        IGLAHeroNFT(heroContract).mint(owner, heroType, rarity);
    }

    function setGameManager(address managerContract_) public onlyOwner {
        gameManager = managerContract_;
    }
}

interface IGameManager{
    function getContract(string memory contract_) external view returns (address);
    function getDevWallet() external view returns (address);
}

interface IGLAHeroNFT{
    function mint (address owner, uint heroType, uint8 rarity) external;
}

interface IGLAToken{
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IGLAItem{
    function getIdOf(string memory itemType) external view returns(uint256);
    function burn(address account, uint256 id, uint256 amount) external;
}