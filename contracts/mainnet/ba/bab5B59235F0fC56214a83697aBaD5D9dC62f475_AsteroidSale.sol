// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAsteroidToken.sol";
import "./interfaces/IAsteroidFeatures.sol";
import "./interfaces/IAsteroidScans.sol";


/**
 * @dev Contract that controls the initial sale of Asteroid tokens
 */
contract AsteroidSale is Ownable {
  IAsteroidToken token;
  IAsteroidFeatures features;
  IAsteroidScans scans;
  uint64 public saleStartTime; // in seconds since epoch
  uint64 public saleEndTime; // in seconds since epoch
  uint public baseAsteroidPrice;
  uint public baseLotPrice;

  event SaleCreated(uint64 indexed start, uint64 end, uint asteroidPrice, uint lotPrice);
  event SaleCancelled(uint64 indexed start);

  /**
   * @param _token Reference to the AsteroidToken contract address
   * @param _features Reference to the AsteroidFeatures contract address
   */
  constructor(IAsteroidToken _token, IAsteroidFeatures _features, IAsteroidScans _scans) {
    token = _token;
    features = _features;
    scans = _scans;
  }

  /**
   * @dev Sets the initial parameters for the sale
   * @param _startTime Seconds since epoch to start the sale
   * @param _duration Seconds for the sale to run starting at _startTime
   * @param _perAsteroid Price in wei per asteroid
   * @param _perLot Additional price per asteroid multiplied by the surface area of the asteroid
   */
  function setSaleParams(uint64 _startTime, uint64 _duration, uint _perAsteroid, uint _perLot) external onlyOwner {
    require(_startTime > saleEndTime + 86400, "Next sale must start at least 1 day after the previous");
    require(_startTime >= block.timestamp, "Sale must start in the future");
    require(_duration >= 86400, "Sale must last for at least 1 day");
    saleStartTime = _startTime;
    saleEndTime = _startTime + _duration;
    baseAsteroidPrice = _perAsteroid;
    baseLotPrice = _perLot;
    emit SaleCreated(saleStartTime, saleEndTime, baseAsteroidPrice, baseLotPrice);
  }

  /**
   * @dev Cancels a future or ongoing sale
   **/
  function cancelSale() external onlyOwner {
    emit SaleCancelled(saleStartTime);
    saleStartTime = 0;
    saleEndTime = 0;
  }

  /**
   * @dev Retrieve the price for the given asteroid which includes a base price and a price scaled by surface area
   * @param _tokenId ERC721 token ID of the asteroid
   */
  function getAsteroidPrice(uint _tokenId) public view returns (uint) {
    require(baseAsteroidPrice > 0 && baseLotPrice > 0, "Base prices must be set");
    uint radius = features.getRadius(_tokenId);
    uint lots = (radius * radius) / 250000;
    return baseAsteroidPrice + (baseLotPrice * lots);
  }

  /**
   * @dev Purchase an asteroid
   * @param _tokenId ERC721 token ID of the asteroid
   **/
  function buyAsteroid(uint _tokenId) external payable {
    require(msg.value == getAsteroidPrice(_tokenId), "Incorrect amount of Ether sent");
    token.mint(_msgSender(), _tokenId);
    scans.recordScanOrder(_tokenId);
  }

  /**
   * @dev Withdraw Ether from the contract to owner address
   */
  function withdraw() external onlyOwner {
      uint balance = address(this).balance;
      _msgSender().transfer(balance);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IAsteroidFeatures {

  function getAsteroidSeed(uint _asteroidId) external pure returns (bytes32);

  function getRadius(uint _asteroidId) external pure returns (uint);

  function getSpectralType(uint _asteroidId) external pure returns (uint);

  function getSpectralTypeBySeed(bytes32 _seed) external pure returns (uint);

  function getOrbitalElements(uint _asteroidId) external pure returns (uint[6] memory orbitalElements);

  function getOrbitalElementsBySeed(bytes32 _seed) external pure returns (uint[6] memory orbitalElements);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IAsteroidScans {

  function addManager(address _manager) external;

  function removeManager(address _manager) external;

  function isManager(address _manager) external view returns (bool);

  function recordScanOrder(uint _asteroidId) external;

  function getScanOrder(uint _asteroidId) external view returns(uint);

  function setInitialBonuses(uint[] calldata _asteroidIds, uint[] calldata _bonuses) external;

  function finalizeScan(uint _asteroidId) external;

  function retrieveScan(uint _asteroidId) external view returns (uint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface IAsteroidToken is IERC721 {
  function addManager(address _manager) external;

  function removeManager(address _manager) external;

  function isManager(address _manager) external view returns (bool);

  function mint(address _to, uint256 _tokenId) external;

  function burn(address _owner, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

