//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IMarketplace.sol";
import "./interfaces/IKabyHero.sol";

contract Marketplace is IMarketplace, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    uint private constant BPS = 10000;
    uint public marketFeeInBps = 20;
    mapping(uint => uint) public herosOnSale;
    mapping(uint => mapping(address => uint)) public herosWithOffers;
    IERC721 public kabyHeroContract;
    IERC20 public kabyToken;
    
    constructor(
        IERC20 tokenAddr,
        IERC721 nftAddr
    ) {
        kabyToken = tokenAddr;
        kabyHeroContract = nftAddr;
    }
    
    modifier onlyHeroOwner(uint heroId) {
        require(kabyHeroContract.ownerOf(heroId) == msg.sender, "KabyHero: not hero owner");
        _;
    }
    
    function getTotalSupply() public view returns(uint){
        return IKabyHero(address(kabyHeroContract)).totalSupply();
    }
    
    /**
     * @dev Owner set new market fee
     * @param marketFee new market fee in Bps
     */
    function setMarketFeeInBps(uint marketFee) external onlyOwner {
        require(marketFee <= BPS * 30 / 100);
        marketFeeInBps = marketFee;
        emit UpdateMarketFee(marketFee);
    }
    
    /**
     * @dev Owner lists a hero on sale.
     * @param heroId id of hero which will be listed
     * @param price price of hero want to sell
     */
    function list(uint heroId, uint price) external override onlyHeroOwner(heroId) {
        require(heroId < getTotalSupply(), "KabyHero: invalid hero");
        require(price > 0, "KabyHero: price is zero");

        herosOnSale[heroId] = price;

        emit HeroListed(heroId, price, kabyHeroContract.ownerOf(heroId));
    }

    /**
     * @dev Owner delists a hero is being on sale.
     * @param heroId id of hero which will be delisted
     */
    function delist(uint heroId) external override onlyHeroOwner(heroId) {
        require(heroId < getTotalSupply(), "KabyHero: invalid hero");
        require(herosOnSale[heroId] > 0, "KabyHero: not listed");

        herosOnSale[heroId] = 0;

        emit HeroDelisted(heroId, kabyHeroContract.ownerOf(heroId));
    }

    /**
     * @dev Buyer buy a hero is being on sale.
     * @param heroId id of hero which buyer want to buy 
     * @param buyPrice price will be charged to buy that hero
     */
    function buy(uint heroId, uint buyPrice) external override nonReentrant {
        require(heroId < getTotalSupply(), "KabyHero: invalid hero");
        uint price = herosOnSale[heroId];
        require(buyPrice == price, "KabyHero: invalid trade price");
        address seller = kabyHeroContract.ownerOf(heroId);
        address buyer = msg.sender;

        require(price > 0, "KabyHero: not on sale");
        require(buyer != seller, "KabyHero: cannot buy your own Hero");

        bool isSuccess = IERC20(kabyToken).transferFrom(buyer, address(this), price);
        require(isSuccess);
        
        _makeTransaction(heroId, buyer, seller, price);

        emit HeroBought(heroId, buyer, seller, price);
    }

    /**
     * @dev Buyer gives offer for a hero.
     * @param heroId id of hero which buyer want to offer
     * @param offerValue value of hero which buyer want to offer
     */
    function offer(uint heroId, uint offerValue) external override nonReentrant {
        require(heroId < getTotalSupply(), "KabyHero: invalid hero");
        address buyer = msg.sender;
        uint currentOffer = herosWithOffers[heroId][buyer];
        bool needRefund = offerValue < currentOffer;
        uint requiredValue = needRefund ? 0 : offerValue - currentOffer;

        require(buyer != kabyHeroContract.ownerOf(heroId), "KabyHero: owner cannot offer");
        require(offerValue != currentOffer, "KabyHero: same offer");

        if (requiredValue > 0) {
            bool offerSuccess = IERC20(kabyToken).transferFrom(buyer, address(this), requiredValue);
            require(offerSuccess);
        }
        herosWithOffers[heroId][buyer] = offerValue;

        if (needRefund) {
            uint returnedValue = currentOffer - offerValue;

            bool returnSuccess = IERC20(kabyToken).transfer( buyer, returnedValue);
            require(returnSuccess);
        }

        emit HeroOffered(heroId, buyer, offerValue);
    }

    /**
     * @dev Owner take an offer to sell their hero.
     * @param heroId id of hero which owner want to sell
     * @param buyer address of buyer who offerd for the hero
     * @param minPrice min price of the hero, can less than or equal to 'offerValue' when make offer before
     */
    function takeOffer(
        uint heroId,
        address buyer,
        uint minPrice
    ) external override nonReentrant onlyHeroOwner(heroId) {
        require(heroId < getTotalSupply(), "KabyHero: invalid hero");
        uint offeredValue = herosWithOffers[heroId][buyer];
        address seller = msg.sender;

        require(offeredValue > 0, "KabyHero: no offer found");
        require(offeredValue >= minPrice, "KabyHero: less than min price");
        require(buyer != seller, "KabyHero: cannot buy your own Hero");

        herosWithOffers[heroId][buyer] = 0;

        _makeTransaction(heroId, buyer, seller, offeredValue);

        emit HeroBought(heroId, buyer, seller, offeredValue);
    }

    /**
     * @dev Buyer cancel offer for a hero which offered before.
     * @param heroId id of hero which buyer want to cancel offer
     */
    function cancelOffer(uint heroId) external override nonReentrant {
        require(heroId < getTotalSupply(), "KabyHero: invalid hero");
        address sender = msg.sender;
        uint offerValue = herosWithOffers[heroId][sender];

        require(offerValue > 0, "KabyHero: no offer found");

        herosWithOffers[heroId][sender] = 0;

        bool isSuccess = IERC20(kabyToken).transfer(sender, offerValue);
        require(isSuccess);

        emit HeroOfferCanceled(heroId, sender);
    }  
    
        /**
     * @dev Execute trade a hero
     * @param heroId id of hero which will be trade
     * @param buyer address of buyer
     * @param seller address of seller
     * @param price price of the hero
     */
    function _makeTransaction(uint heroId, address buyer, address seller, uint price) private {
        //Hero storage Hero = _heros[heroId];
        uint marketFee = price * marketFeeInBps / BPS;

        herosOnSale[heroId] = 0;

        bool transferToSeller = IERC20(kabyToken).transfer( seller, price - marketFee);
        require(transferToSeller);

        bool transferToTreasury = IERC20(kabyToken).transfer( owner(), marketFee);
        require(transferToTreasury);

        kabyHeroContract.transferFrom(seller, buyer, heroId);
    }

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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMarketplace {

    event HeroCreated(uint indexed heroId, uint star, address ownerOfHero);
    event HeroListed(uint indexed heroId, uint price, address ownerOfHero);
    event HeroDelisted(uint indexed heroId, address ownerOfHero);
    event HeroBought(uint indexed heroId, address buyer, address seller, uint price);
    event HeroOffered(uint indexed heroId, address buyer, uint price);
    event HeroOfferCanceled(uint indexed heroId, address buyer);
    event UpdateMarketFee(uint newMarketFee);
    
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
    function buy(uint heroId, uint buyPrice) external;

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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

