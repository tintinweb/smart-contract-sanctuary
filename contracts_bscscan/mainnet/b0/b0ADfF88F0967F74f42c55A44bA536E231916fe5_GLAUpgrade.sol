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

// File: GLAUpgrade.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract GLAUpgrade is Ownable{
    uint256 constant BASE_GEM_AMOUNT = 100;
    uint256 constant RANDOM_RANGE = 10000;
    mapping (uint256 => uint256) ratioOfRare; // Current rarity => Upgrade success rate

    address gameManager;
    
    event Upgrade(uint256 indexed heroId, bool status);

    constructor(address gameManager_) Ownable() {
        ratioOfRare[1] = 4194;
        ratioOfRare[2] = 2581;
        ratioOfRare[3] = 1613;
        ratioOfRare[4] = 968;
        ratioOfRare[5] = 645;
        gameManager = gameManager_;
    }

    function upgradeHero(uint256 heroId, bool isUseCore) public returns(bool) {
        require(msg.sender == tx.origin, "don't try to cheat");
        address heroContract = IGameManager(gameManager).getContract("GLAHeroNFT");

        require(msg.sender == IGLAHeroNFT(heroContract).ownerOf(heroId),"You not own this hero");
        
        address itemContract = IGameManager(gameManager).getContract("GLAItem");
        uint8 rare = IGLAHeroNFT(heroContract).getHeroRarity(heroId);

        if (rare == 1){
            require(isUseCore, "You have to use core to update hero 1 star!");
        }

        if(isUseCore) // burn 1 core (tokenid = 2)
        {
            IGLAItem(itemContract).burn(msg.sender, 2, 1);
        }

        // Gems (tokenid = 1) needed to upgrade = BASE_GEM_AMOUNT * rarity
        IGLAItem(itemContract).burn(msg.sender, 1, BASE_GEM_AMOUNT*rare);
        uint256 rnd = _random(heroId, RANDOM_RANGE);
        
        if (rnd < ratioOfRare[rare]){
            IGLAHeroNFT(heroContract).upgradeRarity(heroId);
            emit Upgrade(heroId, true);
            return true;
            }

        else{
            if (!isUseCore)
            {
                IGLAHeroNFT(heroContract).downgradeRarity(heroId);
            }
            emit Upgrade(heroId, false);
            return false;
            }
        }

        
    function _random(uint256 nonce, uint256 range) internal view returns (uint256)  {
        return uint256(keccak256(abi.encodePacked(msg.sender, blockhash(block.number -1), nonce, block.gaslimit, block.coinbase, block.timestamp , gasleft())))%range;      
    }
        
    function setGameManager(address gameManager_) public onlyOwner{
        gameManager = gameManager_;
    }
}

interface IGameManager{
    function  getContract(string memory contract_) external view returns (address);
}

interface IGLAHeroNFT{
    function getHeroRarity(uint256 tokenId_) external view returns (uint8);
    function downgradeRarity(uint256 tokenId_) external;
    function upgradeRarity(uint256 tokenId_) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IGLAItem{
    function burn(address account, uint256 id, uint256 amount) external;
}