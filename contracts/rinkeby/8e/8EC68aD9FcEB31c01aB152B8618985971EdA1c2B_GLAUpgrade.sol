/**
 *Submitted for verification at Etherscan.io on 2021-09-08
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

// File: contracts/GLAUpgrade.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


struct Hero {
        uint types;
        uint8 rarity;
        uint8 level;
        uint256 experience;    
        uint256 lastBattleTime;
    }


contract GLAUpgrade is Ownable{
    
    uint256 constant BASE_GEM_AMOUNT = 100;
    uint256 constant RANDOM_RANGE = 10000;
    mapping (uint256 => uint256) ratioOfRare;
    address manageContract;
    
    constructor() {
        ratioOfRare[1] = 4194;
        ratioOfRare[2] = 2581;
        ratioOfRare[3] = 1613;
        ratioOfRare[4] = 968;
        ratioOfRare[5] = 645;
    }
    
    function upgradeHero(uint256 tokenId, bool isUseCore) public {
        address itemContract = IManageContract(manageContract).getContract("GLAItem");
        address heroContract = IManageContract(manageContract).getContract("GLAHeroNFT");
        Hero memory hero = IHeroNFT(heroContract).getHero(tokenId);
        if(isUseCore)
            IItemERC721(itemContract).burn(msg.sender, 2, 1);
        IItemERC721(itemContract).burn(msg.sender, 1, BASE_GEM_AMOUNT*hero.rarity);
        uint256 rnd = _random(tokenId, RANDOM_RANGE);
        if (rnd < ratioOfRare[hero.rarity])
            IHeroNFT(heroContract).upgradeRarity(tokenId);
        else if (!isUseCore)
            IHeroNFT(heroContract).downgradeRarity(tokenId);
        }
        
    function _random(uint256 nonce, uint256 range) internal view returns (uint256)  {
        return uint256(keccak256(abi.encodePacked(msg.sender, blockhash(1), nonce, block.gaslimit, block.coinbase, block.timestamp , gasleft())))%range;      
    }
        
    //set dia chia game manage contract
    function setManageContract(address manageContract_) public onlyOwner{
        manageContract = manageContract_;
    }

}


interface IManageContract{
        function  getContract(string memory contract_) external view returns (address);
    }
    
    
interface IHeroNFT{
    function getHero(uint256 tokenId_) external view returns (Hero memory);
    
    function downgradeRarity(uint256 tokenId_) external;
    
    function upgradeRarity(uint256 tokenId_) external;
}

interface IItemERC721{
    function burn(address account, uint256 id, uint256 amount) external;
}