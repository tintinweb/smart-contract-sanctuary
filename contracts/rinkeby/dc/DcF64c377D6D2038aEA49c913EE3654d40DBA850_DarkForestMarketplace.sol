// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./mocks/IDarkForestToken.sol";

contract DarkForestMarketplace is Context, Ownable, IERC721Receiver {

    struct MarketplaceItem {
        address nft;
        uint256 tokenId;
        address payable seller;
        uint256 price;
    }

    /// @dev Magic value to be returned upon successful reception of an NFT
    ///  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
    ///  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;
    uint256 constant HUNDRED_PERCENTS = 100 * 100;

    uint256 public feePercentage;
    mapping(address => bool) public isSupportedNft;
    mapping(address => mapping(uint256 => MarketplaceItem)) private items;
    mapping(DarkForestTypes.ArtifactRarity => uint256) public instantSellPrices;

    event SupportedTokenSet(address nft, bool isSupported);
    event FeePercentageSet(uint256 fee);
    event InstantSellPriceSet(DarkForestTypes.ArtifactRarity rarity, uint256 price);

    event AdminWithdrawn(address receiver, uint256 amount);
    event AdminTokenWithdrawn(address receiver, address nft, uint256 tokenId);

    event TokenListed(address nft, uint256 indexed tokenId, address indexed seller, uint256 price);
    event TokenWithdrawn(address nft, uint256 indexed tokenId, address indexed seller);
    event TokenBought(address nft, uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event TokenInstantSold(address nft, uint256 indexed tokenId, address indexed seller);

    event Received(address, uint);

    modifier onlySupportedNft(address _nft) {
        require(isSupportedNft[_nft], "DarkForestMarketplace: token is not supported");
        _;
    }

    function setSupportedToken(address _nft, bool _isSupported) external onlyOwner {
        isSupportedNft[_nft] = _isSupported;

        emit SupportedTokenSet(_nft, _isSupported);
    }

    function setFeePercentage(uint256 _fee) external onlyOwner {
        require(_fee < HUNDRED_PERCENTS, "DarkForestMarketplace: fee should be less than 100 percent");
        feePercentage = _fee;

        emit FeePercentageSet(_fee);
    }

    function setInstantSellPrice(DarkForestTypes.ArtifactRarity _rarity, uint256 _price) external onlyOwner {
        instantSellPrices[_rarity] = _price;

        emit InstantSellPriceSet(_rarity, _price);
    }

    function adminWithdraw(address payable _receiver, uint256 _amount) external onlyOwner {
        (bool sent,) = _receiver.call{value : _amount}("");
        require(sent, "DarkForestMarketplace: failed to send funds");

        emit AdminWithdrawn(_receiver, _amount);
    }

    function adminTokenWithdraw(address payable _receiver, address _nft, uint256 _tokenId) external onlyOwner {
        require(getItem(_nft, _tokenId).tokenId == 0, "DarkForestMarketplace: cannot withdraw token on marketplace");
        IERC721(_nft).safeTransferFrom(address(this), _receiver, _tokenId);

        emit AdminTokenWithdrawn(_receiver, _nft, _tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function listToken(address _nft, uint256 _tokenId, uint256 _price) external onlySupportedNft(_nft) {
        IERC721(_nft).transferFrom(_msgSender(), address(this), _tokenId);
        items[_nft][_tokenId] = MarketplaceItem({
            nft: _nft,
            tokenId: _tokenId,
            seller: payable(_msgSender()),
            price: _price
        });

        emit TokenListed(_nft, _tokenId, _msgSender(), _price);
    }

    function getItem(address _nft, uint256 _tokenId) public view returns (MarketplaceItem memory)  {
        return items[_nft][_tokenId];
    }

    function withdraw(address _nft, uint256 _tokenId) external onlySupportedNft(_nft) {
        MarketplaceItem memory item = getItem(_nft, _tokenId);
        require(item.tokenId != 0, "DarkForestMarketplace: token is not on marketplace");
        require(item.seller == _msgSender(), "DarkForestMarketplace: only seller may withdraw");

        delete items[_nft][_tokenId];

        IERC721(_nft).safeTransferFrom(address(this), _msgSender(), _tokenId);

        emit TokenWithdrawn(_nft, _tokenId, _msgSender());
    }

    function buy(address _nft, uint256 _tokenId) external payable onlySupportedNft(_nft) {
        MarketplaceItem memory item = getItem(_nft, _tokenId);
        require(item.tokenId != 0, "DarkForestMarketplace: token is not on marketplace");
        require(item.price <= msg.value, "DarkForestMarketplace: not anought funds to buy");

        delete items[_nft][_tokenId];

        IERC721(_nft).safeTransferFrom(address(this), _msgSender(), _tokenId);

        uint256 payOff = ((HUNDRED_PERCENTS - feePercentage) * item.price) / HUNDRED_PERCENTS;
        (bool sent,) = item.seller.call{value : payOff}("");
        require(sent, "DarkForestMarketplace: failed to send funds");

        emit TokenBought(_nft, _tokenId, item.seller, _msgSender(), item.price);
    }

    function instantSell(address _nft, uint256 _tokenId) external onlySupportedNft(_nft) {
        _instantSell(payable(_msgSender()), _nft, _tokenId);
    }

    function _instantSell(address payable _seller, address _nft, uint256 _tokenId) internal {
        DarkForestTypes.Artifact memory artifact = IDarkForestToken(_nft).getArtifact(_tokenId);
        uint256 price = instantSellPrices[artifact.rarity];

        require(price > 0, "DarkForestMarketplace: instant sell price cannot be zero");

        IERC721(_nft).transferFrom(_seller, address(this), _tokenId);

        (bool sent,) = _seller.call{value : price}("");
        require(sent, "DarkForestMarketplace: failed to send funds");

        emit TokenInstantSold(_nft, _tokenId, _seller);
    }

    receive() external payable {
        emit Received(_msgSender(), msg.value);
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
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./DarkForestTypes.sol";

interface IDarkForestToken {
    function getArtifact(uint256 tokenId) external view returns (DarkForestTypes.Artifact memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

library DarkForestTypes {

    struct Artifact {
        bool isInitialized;
        uint256 id;
        uint256 planetDiscoveredOn;
        ArtifactRarity rarity;
        Biome planetBiome;
        uint256 mintedAtTimestamp;
        address discoverer;
        ArtifactType artifactType;
        // an artifact is 'activated' iff lastActivated > lastDeactivated
        uint256 lastActivated;
        uint256 lastDeactivated;
        uint256 wormholeTo; // location id
    }

    enum ArtifactType {
        Unknown,
        Monolith,
        Colossus,
        Spaceship,
        Pyramid,
        Wormhole,
        PlanetaryShield,
        PhotoidCannon,
        BloomFilter,
        BlackDomain
    }

    enum ArtifactRarity {
        Unknown,
        Common,
        Rare,
        Epic,
        Legendary,
        Mythic
    }

    enum Biome {
        Unknown,
        Ocean,
        Forest,
        Grassland,
        Tundra,
        Swamp,
        Desert,
        Ice,
        Wasteland,
        Lava,
        Corrupted
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 9999
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}