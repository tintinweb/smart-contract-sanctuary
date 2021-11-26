//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IWastedWarrior.sol";
import "./utils/Whitelist.sol";

contract WastedWhitelist is Whitelist {
    IWastedWarrior public wastedWarrior;
    uint public balance;
    
    constructor (IWastedWarrior wastedWarriorAddress) {
        wastedWarrior = wastedWarriorAddress;
    }
    
    function setWastedWarrior(IWastedWarrior wastedWarriorAddress) external onlyOwner {
        require(address(wastedWarriorAddress) != address(0));
        wastedWarrior = wastedWarriorAddress;
    }
    
    function buyWastedWarrior(uint amount, uint rarityPackage) onlyMember external payable {
        require(amount != 0, 'WC: invalid amount');
        
        if(rarityPackage == uint(IWastedWarrior.PackageRarity.PLASTIC)) {
            require(msg.value == wastedWarrior.getPlasticPackageFee() * amount, "WC: Not enough fee");
        } else if(rarityPackage == uint(IWastedWarrior.PackageRarity.STEEL)) {
            require(msg.value == wastedWarrior.getSteelPackageFee() * amount, "WC: Not enough fee");
        } else if (rarityPackage == uint(IWastedWarrior.PackageRarity.GOLD)) {
            require(msg.value == wastedWarrior.getGoldPackageFee() * amount, "WC: Not enough fee");
        } else if (rarityPackage == uint(IWastedWarrior.PackageRarity.PLATINUM)) {
            require(msg.value == wastedWarrior.getPlatinumPackageFee() * amount, "WC: Not enough fee");
        }
        
        balance += msg.value;
        
        wastedWarrior.mintFor(msg.sender, amount, rarityPackage);
    }
    
    function withdraw() external onlyOwner {
        require(balance != 0, "WC: not enough");
        (bool isSuccess,) = owner().call{value: balance}("");
        require(isSuccess);
    }
    
    function widthdrawAmount(uint amount) external onlyOwner {
        require(amount != 0 && amount <= balance, "WC: not valid");
        balance -= amount;
        (bool isSuccess,) = owner().call{value: balance}("");
        require(isSuccess);
        
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is Ownable {
    // List of authorized address to perform some restricted actions
    mapping(address => bool) public whitelist;

    modifier onlyMember() {
        require(whitelist[msg.sender], "Whitelist: not member of whitelist");
        _;
    }

    /**
     * @notice Add addresses to whitelist.
     * 
     * Requirements: 
     * - only Owner of contract.
     */
    function addMember(address[] memory members) external onlyOwner {
        require(members.length != 0, "Whitelist: invalid members");
        for(uint i = 0; i < members.length; i++) {
            whitelist[address(members[i])] = true;
        }
    }

    /**
    * @notice Remove addresses from whitelist.
    * 
    * Requirements: 
    * - only Owner of contract.
    */
    function removeMember(address[] memory members) external onlyOwner {
        require(members.length != 0, "Whitelist: invalid members");
        for(uint i = 0; i < members.length; i++) {
            whitelist[address(members[i])] = false;
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


interface IWastedWarrior {
    
    enum PackageRarity { NONE, PLASTIC, STEEL, GOLD, PLATINUM }
    
    event WarriorCreated(uint indexed warriorId, bool isBreed, bool isFusion, uint indexed packageType, address indexed buyer);
    event WarriorListed(uint indexed warriorId, uint price);
    event WarriorDelisted(uint indexed warriorId);
    event WarriorBought(uint indexed warriorId, address buyer, address seller, uint price);
    event WarriorOffered(uint indexed warriorId, address buyer, uint price);
    event WarriorOfferCanceled(uint indexed warriorId, address buyer);
    event NameChanged(uint indexed warriorId, string newName);
    event PetAdopted(uint indexed warriorId, uint indexed petId);
    event PetReleased(uint indexed warriorId, uint indexed petId);
    event AcquiredSkill(uint indexed warriorId, uint indexed skillId);
    event ItemsEquipped(uint indexed warriorId, uint[] itemIds);
    event ItemsRemoved(uint indexed warriorId, uint[] itemIds);
    event WarriorLeveledUp(uint indexed warriorId, uint level, uint amount);
    event BreedingWarrior(uint indexed fatherId, uint indexed motherId, uint newId);
    event FusionWarrior(uint indexed firstWarriorId, uint indexed secondWarriorId, uint newId);
    
    struct BoughtPackageTimes {
        uint plastic;
        uint steel;
        uint gold;
        uint platinum;
    }
    
    struct ParentWarrior {
        uint fatherId;
        uint motherId;
    }
    
    struct Collaborator {
        uint totalSupplyPlasticPackages;
        uint totalSupplySteelPackages;
        uint totalSupplyGoldPackages;
        uint totalSupplyPlatinumPackages;
        uint mintedPlasticPackages;
        uint mintedSteelPackages;
        uint mintedGoldPackages;
        uint mintedPlatinumPackages;
    }
    
    struct Warrior {
        string name;
        uint256 level;
        uint256 weapon;
        uint256 armor;
        uint256 accessory;
        bool isBreed;
        bool isFusion;
    }
    
    function addCollaborator(address collaborator, uint totalSupplyPlasticPackages, uint totalSupplySteelPackages, uint totalSupplyGoldPackages, uint totalSupplyPlatinumPackages) external; 
    
    /**
     * @notice Gets warrior information.
     * 
     * @dev Prep function for staking.
     */
    function getWarrior(uint warriorId) external view returns (
        string memory name,
        bool isBreed,
        bool isFusion,
        uint level,
        uint pet,
        uint[] memory skills,
        uint[3] memory equipment
    );
    
    /**
    * @notice get plastic package fee.
    */
    function getPlasticPackageFee() external view returns(uint);
    
    /**
    * @notice get steel package fee.
    */
    function getSteelPackageFee() external view returns(uint);
    
    /**
    * @notice get gold package fee.
    */
    function getGoldPackageFee() external view returns(uint);
    
    /**
    * @notice get platinum package fee.
    */
    function getPlatinumPackageFee() external view returns(uint);
    
     /**
     * @notice Function can level up a Warrior.
     * 
     * @dev Prep function for staking.
     */
    function levelUp(uint warriorId, uint amount) external;
    
    /**
     * @notice Get current level of given warrior.
     * 
     * @dev Prep function for staking.
     */
    function getWarriorLevel(uint warriorId) external view returns (uint);
    
    /**
     * @notice mint warrior for specific address.
     * 
     * @dev Function take 3 arguments are address of buyer, amount, rarityPackage.
     * 
     * Requirements: 
     * - onlyCollaborator
     */
    function mintFor(address buyer, uint amount, uint rarityPackage) external;

    /**
     * @notice Function to change Warrior's name.
     *
     * @dev Function take 2 arguments are warriorId, new name of warrior.
     * 
     * Requirements:
     * - `replaceName` must be a valid string.
     * - `replaceName` is not duplicated.
     * - You have to pay `serviceFeeToken` to change warrior's name.
     */
    function rename(uint warriorId, string memory replaceName) external;

    /**
     * @notice Owner equips items to their warrior by burning ERC1155 Equipment NFTs.
     *
     * Requirements:
     * - caller must be owner of the warrior.
     */
    function equipItems(uint warriorId, uint[] memory itemIds) external;

    /**
     * @notice Owner removes items from their warrior. ERC1155 Equipment NFTs are minted back to the owner.
     *
     * Requirements:
     * - Caller must be owner of the warrior.
     */
    function removeItems(uint warriorId, uint[] memory itemIds) external;

    /**
     * @notice Lists a warrior on sale.
     *
     * Requirements:
     * - Caller must be the owner of the warrior.
     */
    function listing(uint warriorId, uint price) external;

    /**
     * @notice Remove from a list on sale.
     */
    function delist(uint warriorId) external;

    /**
     * @notice Instant buy a specific warrior on sale.
     *
     * Requirements:
     * - Caller must be the owner of the warrior.
     * - Target warrior must be currently on sale time.
     * - Sent value must be exact the same as current listing price.
     * - Owner cannot buy.
     */
    function buy(uint warriorId) external payable;

    /**
     * @notice Gives offer for a warrior.
     *
     * Requirements:
     * - Owner cannot offer.
     */
    function offer(uint warriorId, uint offerPrice) external payable;

    /**
     * @notice Owner accept an offer to sell their warrior.
     */
    function acceptOffer(uint warriorId, address buyer) external;

    /**
     * @notice Abort an offer for a specific warrior.
     */
    function abortOffer(uint warriorId) external;

    // /**
    //  * @notice Acquire skill for warrior by skillId.
    //  * 
    //  */
    // function acquireSkill(uint warriorId, uint skillId) external;

    /**
     * @notice Adopts a Pet.
     */
    function adoptPet(uint warriorId, uint petId) external;

    /**
     * @notice Abandons a Pet attached to a warrior.
     */
    function abandonPet(uint warriorId) external;
    
    /**
     * @notice Burn two warriors to create one new warrior.
     * 
     * @dev The id of the new warrior is the length of the warriors array
     * 
     * Requirements:
     * - caller must be owner of the warriors.
     */
    function fusionWarrior(uint firstWarriorId, uint secondWarriorId) external payable;
    
    /**
     * @notice Breed based on two warriors.
     * 
     * @dev The id of the new warrior is the length of the warriors array
     * 
     * Requirements:
     * - caller must be owner of the warriors.
     * - warriors's owner can only breeding 7 times at most.
     */
    function breedingWarrior (uint fatherId, uint motherId) external payable;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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