//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IKabyHero.sol";
import "./interfaces/IAirdropHero.sol";

contract AirdropHero is Ownable {
    
    address public kabyHeroContract;
    
    mapping(address => uint) public airdroped;
    mapping(address => uint) public amountToClaim;
    bool public acceptClaim;
    
    constructor(address kabyHeroAddr) {
        kabyHeroContract = kabyHeroAddr;
    }
    
    /**
     * @dev Set flag value for allow user claim or not
     */
    function setFlagAcceptClaim(bool isAcceptClaim) public onlyOwner {
        acceptClaim = isAcceptClaim;
    }
    
    /**
     * @dev Set receivers with amounts
     */
    function setReceiversWithAmount(address[] memory listAddress, uint[] memory listAmountHero) public onlyOwner {
        require(listAddress.length == listAmountHero.length, "AirdropHero: invalid value");
        for (uint i = 0; i < listAddress.length; i++) {
            require(listAddress[i] != address(0) && listAmountHero[i] != 0, "AirdropHero: not accept address(0) and amount 0");
            if (amountToClaim[listAddress[i]] == 0) {
                amountToClaim[listAddress[i]] = listAmountHero[i];
            }
        }
    }
    
    /**
     * @dev Set receiver with amount
     */
    function setReceiverWithAmount(address account, uint amountHero) public onlyOwner {
        require(account != address(0) && amountHero != 0, "AirdropHero: not accept address(0) and amount 0");
        amountToClaim[account] = amountHero;
    }
    
    /**
     * @dev Get max hero user can claim
     */
    function getMaxAmountClaim(address account) public view returns(uint) {
        require(account != address(0), "AirdropHero: invalid address");
        uint amountClaimed = IAirdropHero(kabyHeroContract).amountClaimed(account);
        
        return amountClaimed + amountToClaim[account];
    }
    
    /**
     * @dev Mint Heros from Minter to user has genesis
     */
    function claimHero(uint amount) public {
        require(acceptClaim, "AirdropHero: not allow claim in currently");
        address account = msg.sender;
        uint versionId = IAirdropHero(kabyHeroContract).getLatestVersion();
        
        uint maxAmountClaim = getMaxAmountClaim(account) - airdroped[account];
        require(amount <= maxAmountClaim, "AirdropHero: invalid amount");
        
        airdroped[account] += amount;
        IKabyHero(kabyHeroContract).mintHero(versionId, amount, account);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAirdropHero {
    /**
     * @notice Get amount of genesis user claimed
     */
    function amountClaimed(address account) external view returns(uint);
    
    /**
     * @notice Get latest version of system
     */
    function getLatestVersion() external view returns(uint);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IKabyHero {
    struct Hero {
        uint star;
        uint gem1;
        uint gem2;
        uint gem3;
        uint gem4;
        uint gem5;
    }

    struct Version {
        uint currentSell;
        uint currentReserve;
        uint maxSupply;
        uint maxForSell;
        uint salePrice;
        uint startTime;
        uint endTime;
        string provenance; // This is the provenance record of all Hero artworks in existence.
        bool useSummonStaking;
    }
    
    struct VersionConstructorParams {
        uint maxSupply;
        uint maxForSell;
        uint salePrice;
        uint startTime;
        uint endTime;
        string provenance;
    }

    event HeroCreated(uint indexed heroId, uint star, address ownerOfHero);
    event HeroListed(uint indexed heroId, uint price, address ownerOfHero);
    event HeroDelisted(uint indexed heroId, address ownerOfHero);
    event HeroStarUpgraded(uint indexed heroId, uint newStar, uint amount);
    event HeroBought(uint indexed heroId, address buyer, address seller, uint price);
    event HeroOffered(uint indexed heroId, address buyer, uint price);
    event HeroOfferCanceled(uint indexed heroId, address buyer);
    event HeroPriceIncreased(uint indexed heroId, uint floorPrice, uint increasedAmount);
    event ItemsEquipped(uint indexed heroId, uint[] itemIds);
    event ItemsUnequipped(uint indexed heroId, uint[] itemIds);
    event NewVersionAdded(uint versionId);
    event UpdateRandomGenerator(address newRandomGenerator);
    event SetStar(uint indexed heroId, uint star, address ownerOfHero);
    event UpdateStakingPool(address newStakingPool);
    event UpdateSummonStakingPool(address newSummonStakingPool);
    event UpdateGem(address newGem);
    event UpdateMaxStar(uint newMaxStar);
    event UpdateMarketFee(uint newMarketFee);
    event UpdateEndTime(uint endTime);
    event UpdateMaxSupply(uint newMaxSupply);
    
    /**
     * @notice Claims Heros when it's on presale phase.
     */
    function claimHero(uint versionId, uint amount) external;

    /**
     * @notice Upgrade star for hero
     */
    function upgradeStar(uint heroId, uint amount) external;

    /**
     * @notice Mint Heros from Minter to user.
     */
    function mintHero(uint versionId, uint amount, address account) external;

    /**
     * @notice Owner equips items to their Hero by burning ERC1155 Gem NFTs.
     *
     * Requirements:
     * - caller must be owner of the Hero.
     */
    function equipItems(uint heroId, uint[] memory itemIds) external;

    /**
     * @notice Owner removes items from their Hero. ERC1155 Gem NFTs are minted back to the owner.
     *
     * Requirements:
     * - caller must be owner of the Hero.
     */
    function removeItems(uint heroId, uint[] memory itemIds) external;

    /**
     * @notice Burns a Hero `.
     *
     * - Not financial advice: DONT DO THAT.
     * - Remember to remove all items before calling this function.
     */
    function sacrificeHero(uint heroId) external;

    /**
     * @notice Lists a Hero on sale.
     *
     * Requirements:
     * - `price` cannot be under Hero's `floorPrice`.
     * - Caller must be the owner of the Hero.
     */
    function list(uint heroId, uint price) external;

    /**
     * @notice Delist a Hero on sale.
     */
    function delist(uint heroId) external;

    /**
     * @notice Instant buy a specific Hero on sale.
     *
     * Requirements:
     * - Target Hero must be currently on sale.
     * - Sent value must be exact the same as current listing price.
     */
    function buy(uint heroId) external;

    /**
     * @notice Gives offer for a Hero.
     *
     * Requirements:
     * - Owner cannot offer.
     */
    function offer(uint heroId, uint offerValue) external;

    /**
     * @notice Owner take an offer to sell their Hero.
     *
     * Requirements:
     * - Cannot take offer under Hero's `floorPrice`.
     * - Offer value must be at least equal to `minPrice`.
     */
    function takeOffer(uint heroId, address offerAddr, uint minPrice) external;

    /**
     * @notice Cancels an offer for a specific Hero.
     */
    function cancelOffer(uint heroId) external;

    /**
     * @notice Finalizes the battle aftermath of 2 Heros.
     */
    // function finalizeDuelResult(uint winningheroId, uint losingheroId, uint penaltyInBps) external;

    /**
     * @notice Gets Hero information.
     */
    function getHero(uint heroId) external view returns (
        uint star,
        uint[5] memory gem
    );
    
     /**
     * @notice Gets current star of given hero.
     */
    function getHeroStar(uint heroId) external view returns (uint);

     /**
     * @notice Gets current total hero was created.
     */
    function totalSupply() external view returns (uint);

    /**
     * @notice Set random star
     */
    function setRandomStar(uint heroId, uint randomness) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

