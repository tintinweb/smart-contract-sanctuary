// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

pragma solidity 0.8.8;

error SpecialtyNotEARNING();

error OnlyOwnerClaim();

error LengthMismatch();

interface IMvlNFT is IERC721Metadata {
  event SetTokenSpecialty(uint256 tokenId, uint256 option);

  enum Specialty {
    COMMON,
    EARNING
  }

  function safeMint(address to, Specialty option) external;

  function safeMintBatch(address[] memory to, Specialty[] memory option) external;

  function setTokenURI(uint256 tokenId, string memory _tokenURI) external;

  function getTokenSpecialty(uint256 tokenId) external view returns (Specialty option);

  function claimNFTReward(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

error AuctionNotInProgress();
error AuctionNotEnded();
error NotAuthorized();
error NotBidBefore();
error NotSameAmount();
error SurpassTotalBidder();
error NotBidOwner();
error AlreadyExist();

struct Bid {
  address owner;
  uint256 amount;
}

/// @title AuctionFactory
/// @notice AuctionFactory creates and manages Auction contracts
interface IAuction {
  event PlaceBid(address indexed account, bytes12 bid, uint256 amount, uint256 totalBid);

  event UpdateBid(address indexed account, bytes12 bid, uint256 newBid, uint256 totalBid);

  event CancelBid(address indexed account, uint256 totalBid);

  enum State {
    PENDING,
    ACTIVE,
    END
  }

  function initialize(
    uint256 startTimestamp,
    uint256 endTimestamp,
    uint256 mintAmount,
    uint256 floorPrice,
    uint256 auctionId
  ) external;

  /// View Functions ///

  function getAuctionState() external view returns (State state);

  function getAuctionInformation()
    external
    view
    returns (
      uint256 startTimestamp,
      uint256 endTimestamp,
      uint256 mintAmount,
      uint256 floorPrice,
      uint256 auctionId,
      uint256 criteria
    );

  function getBiddingPrice(bytes12 bid) external view returns (uint256 bidAmount);

  function getBidOwner(bytes12 bid) external view returns (address owner_);

  function getMultiBids(uint256 k) external view returns (Bid[] memory);

  function getMultiBidAmount(uint256 k) external view returns (uint256[] memory);

  function getWinBids() external view returns (Bid[] memory);

  function getWinBidAmounts() external view returns (uint256[] memory);

  /// User Functions ///

  /// @notice User can bid by executing this function
  function placeBid(uint256 amount) external;

  function updateBid(bytes12 bid, uint256 amount) external;

  function cancelBid(bytes12 bid) external;

  function refundBid(bytes12 bid) external;

  /// Admin Functions ///
  function emergencyStop() external;

  function transferAsset(address account, uint256 amount) external;

  /// @notice Set criteria for the auction
  function setCriteria(uint256 currentMvlPrice) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

error InvalidTimestamps();
error FinishedAuction();

interface IAuctionFactory {
  event AuctionCreated(
    address indexed auctionAddress,
    uint256 auctionId,
    uint256 startTimestamp,
    uint256 endTimestamp,
    uint256 mintAmount,
    uint256 floorPrice
  );

  /// @notice Returns mvl token contract address
  function getMvlAddress() external view returns (address mvlAddress);

  /// @notice Return the address of the auction corresponded to the given id
  function getAuctionAddress(uint256 id) external view returns (address auction);

  /// @notice Deploy new auction contract with `Create2`.
  function createAuction(
    uint256 startTimestamp,
    uint256 endTimestamp,
    uint256 mintAmount,
    uint256 floorPrice
  ) external;

  function emergencyStop(uint256 auctionId) external;
}

// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Create2.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '../interfaces/IAuctionFactory.sol';
import '../interfaces/IAuction.sol';

import '../dependencies/interfaces/IMvlNFT.sol';

pragma solidity 0.8.8;

error NotInSale();

error SoldOut();

interface IPublicSale {
  struct Sale {
    uint256 startTimestamp;
    uint256 endTimestamp;
    uint256 amount;
    uint256 price;
    IMvlNFT.Specialty option;
  }

  event SaleBegin(
    uint256 saleId,
    uint256 startTimestamp,
    uint256 endTimestamp,
    uint256 amount,
    uint256 price,
    uint256 option
  );

  event Purchase(address indexed account, uint256 saleId, uint256 price);

  function getMvlAddress() external view returns (address mvlAddress);

  function getMvlNftAddress() external view returns (address mvlNftAddress);

  function createSale(
    uint256 startTimestamp,
    uint256 endTimestamp,
    uint256 amount,
    uint256 price,
    IMvlNFT.Specialty option
  ) external;

  function purchase(uint256 saleId) external;

  function withdrawMvl() external;

  function emergencyStop(uint256 saleId) external;
}

// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Create2.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '../interfaces/IAuctionFactory.sol';
import '../interfaces/IAuction.sol';
import '../interfaces/IPublicSale.sol';

import '../dependencies/interfaces/IMvlNFT.sol';

pragma solidity 0.8.8;

/// @title PublicSale
/// @notice PublicSale
contract PublicSale is IPublicSale, Ownable {
  using Counters for Counters.Counter;

  Counters.Counter internal _saleIds;

  mapping(uint256 => Sale) internal _sales;

  IERC20 internal _mvl;
  IMvlNFT internal _mvlNft;

  constructor(address mvl_, address mvlNft_) {
    _mvl = IERC20(mvl_);
    _mvlNft = IMvlNFT(mvlNft_);
  }

  modifier underway(uint256 saleId) {
    if (!getSaleUnderway(saleId)) revert NotInSale();
    _;
  }

  /// View Functions ///

  /// @notice return mvl address
  function getMvlAddress() public view returns (address mvlAddress) {
    mvlAddress = address(_mvl);
  }

  /// @notice return mvl nft address
  function getMvlNftAddress() public view returns (address mvlNftAddress) {
    mvlNftAddress = address(_mvlNft);
  }

  /// @notice return whether sale with given saleId is underway
  function getSaleUnderway(uint256 saleId) public view returns (bool) {
    Sale memory sale = _sales[saleId];
    return (block.timestamp >= sale.startTimestamp && block.timestamp < sale.endTimestamp);
  }

  /// @notice return sale data with given saleId
  function getSaleData(uint256 saleId)
    external
    view
    returns (
      uint256 startTimestamp,
      uint256 endTimestamp,
      uint256 amount,
      uint256 price,
      IMvlNFT.Specialty option
    )
  {
    Sale memory sale = _sales[saleId];
    startTimestamp = sale.startTimestamp;
    endTimestamp = sale.endTimestamp;
    amount = sale.amount;
    price = sale.price;
    option = sale.option;
  }

  /// User Function ///

  /// @notice User can purchase normal mvl nft
  /// @param saleId User should designate the saleId
  function purchase(uint256 saleId) external underway(saleId) {
    Sale storage sale = _sales[saleId];

    if (sale.amount < 1) revert SoldOut();

    sale.amount--;

    _mvlNft.safeMint(msg.sender, sale.option);

    _mvl.transferFrom(msg.sender, address(this), sale.price);

    emit Purchase(msg.sender, saleId, sale.price);
  }

  /// Admin Functions ///

  /// @notice Admin can create sale
  function createSale(
    uint256 startTimestamp,
    uint256 endTimestamp,
    uint256 amount,
    uint256 price,
    IMvlNFT.Specialty option
  ) external onlyOwner {
    uint256 saleId = _saleIds.current();

    _saleIds.increment();

    Sale storage sale = _sales[saleId];

    sale.startTimestamp = startTimestamp;
    sale.endTimestamp = endTimestamp;
    sale.amount = amount;
    sale.price = price;
    sale.option = option;

    emit SaleBegin(saleId, startTimestamp, endTimestamp, amount, price, uint256(option));
  }

  /// @notice Transfer mvl in this contract to the owner
  function withdrawMvl() external onlyOwner {
    _mvl.transfer(owner(), _mvl.balanceOf(address(this)));
  }

  function emergencyStop(uint256 saleId) external onlyOwner {
    Sale storage sale = _sales[saleId];
    sale.endTimestamp = 0;
  }
}