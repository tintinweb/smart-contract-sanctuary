/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

pragma solidity ^0.5.0;

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }
}

// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.5.0;


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
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/introspection/IERC165.sol

pragma solidity ^0.5.0;

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

// File: @openzeppelin/contracts-ethereum-package/contracts/introspection/ERC165.sol

pragma solidity ^0.5.0;



/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is Initializable, IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function initialize() public initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.5.0;



/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is Initializable, IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721Receiver.sol

pragma solidity ^0.5.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

// File: contracts/GunToken.sol

pragma solidity ^0.5.0;








/**
 * ERC-721 implementation that allows
 * tokens (of the same category) to be minted in batches. Each batch
 * contains enough data to generate all
 * token ids inside the batch, and to
 * generate the tokenURI in the batch
 */
contract GunToken is Initializable, Context, ERC165, IERC721 {
    using strings for *;
    using Address for address;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

     /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => uint256) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Token name
    string private constant _name = "War Riders Gun";

    // Token symbol
    string private constant _symbol = "WRG";

    address internal factory;
    address internal oldToken;
    uint256 internal migrateCursor;

    uint16 public constant maxAllocation = 4000;
    uint256 public lastAllocation;

    event BatchTransfer(address indexed from, address indexed to, uint256 indexed batchIndex);

    struct Batch {
        address owner;
        uint16 size;
        uint8 category;
        uint256 startId;
        uint256 startTokenId;
    }

    Batch[] public allBatches;
    mapping(uint256 => bool) public outOfBatch;

    //Used for enumeration
    mapping(address => Batch[]) public batchesOwned;
    //Batch index to owner batch index
    mapping(uint256 => uint256) public ownedBatchIndex;

    mapping(uint8 => uint256) internal totalGunsMintedByCategory;
    uint256 internal _totalSupply;

    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    modifier onlyFactory {
        require(msg.sender == factory, "Not authorized");
        _;
    }

    function initialize(address factoryAddress, address oldGunToken) public initializer {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);

        factory = factoryAddress;
        oldToken = oldGunToken;

        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
       require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function categoryTypeToId(uint8 category, uint256 categoryId) public view returns (uint256) {
        for (uint i = 0; i < allBatches.length; i++) {
            Batch memory a = allBatches[i];
            if (a.category != category)
                continue;

            uint256 endId = a.startId + a.size;
            if (categoryId >= a.startId && categoryId < endId) {
                uint256 dif = categoryId - a.startId;

                return a.startTokenId + dif;
            }
        }

        revert("Category not found");
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @param __owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address __owner, uint256 index) public view returns (uint256) {
        return tokenOfOwner(__owner)[index];
    }

    function getBatchCount(address __owner) public view returns(uint256) {
        return batchesOwned[__owner].length;
    }

    function getTokensInBatch(address __owner, uint256 index) public view returns (uint256[] memory) {
        Batch memory a = batchesOwned[__owner][index];
        uint256[] memory result = new uint256[](a.size);

        uint256 pos = 0;
        uint end = a.startTokenId + a.size;
        for (uint i = a.startTokenId; i < end; i++) {
            if (outOfBatch[i]) {
                continue;
            }

            result[pos] = i;
            pos++;
        }

        if (pos == 0) {
          return new uint256[](0);
        }

        uint256 subAmount = a.size - pos;

        assembly { mstore(result, sub(mload(result), subAmount)) }

        return result;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        return allTokens()[index];
    }

    function allTokens() public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](totalSupply());

        uint pos = 0;
        for (uint i = 0; i < allBatches.length; i++) {
            Batch memory a = allBatches[i];
            uint end = a.startTokenId + a.size;
            for (uint j = a.startTokenId; j < end; j++) {
                result[pos] = j;
                pos++;
            }
        }

        return result;
    }

    function tokenOfOwner(address __owner) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](balanceOf(__owner));

        uint pos = 0;
        for (uint i = 0; i < batchesOwned[__owner].length; i++) {
            Batch memory a = batchesOwned[__owner][i];
            uint end = a.startTokenId + a.size;
            for (uint j = a.startTokenId; j < end; j++) {
                if (outOfBatch[j]) {
                    continue;
                }

                result[pos] = j;
                pos++;
            }
        }

        uint256[] memory fallbackOwned = _tokensOfOwner(__owner);
        for (uint i = 0; i < fallbackOwned.length; i++) {
            result[pos] = fallbackOwned[i];
            pos++;
        }

        return result;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        if (outOfBatch[_tokenId]) {
            address __owner = _tokenOwner[_tokenId];
            return __owner != address(0);
        } else {
            uint256 index = getBatchIndex(_tokenId);
            if (index < allBatches.length) {
                Batch memory a = allBatches[index];
                uint end = a.startTokenId + a.size;

                return _tokenId < end;
            }
            return false;
        }
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function claimAllocation(address to, uint16 size, uint8 category) public onlyFactory returns (uint) {
        require(size < maxAllocation, "Size must be smaller than maxAllocation");

        allBatches.push(Batch({
            owner: to,
            size: size,
            category: category,
            startId: totalGunsMintedByCategory[category],
            startTokenId: lastAllocation
        }));

        uint end = lastAllocation + size;
        for (uint i = lastAllocation; i < end; i++) {
            emit Transfer(address(0), to, i);
        }

        lastAllocation += maxAllocation;

        _ownedTokensCount[to] += size;
        totalGunsMintedByCategory[category] += size;

        _addBatchToOwner(to, allBatches[allBatches.length - 1]);

        _totalSupply += size;
        return lastAllocation;
    }

    function migrate(uint256 count) public onlyOwner returns (uint256) {
        GunToken oldGuns = GunToken(oldToken);

        for (uint256 i = 0; i < count; i++) {
            uint256 index = migrateCursor + i;

            (address to, uint16 size, uint8 category, uint256 startId, uint256 startTokenId) = oldGuns.allBatches(index);
            allBatches.push(Batch({
                owner: to,
                size: size,
                category: category,
                startId: startId,
                startTokenId: startTokenId
            }));

            uint end = lastAllocation + size;
            uint256 ubalance = size;
            for (uint z = lastAllocation; z < end; z++) {
                address __owner = oldGuns.ownerOf(z);
                if (__owner != to) {
                    outOfBatch[z] = true;
                    _addTokenTo(__owner, z);
                    ubalance--;
                    emit Transfer(address(0), __owner, z);
                } else {
                    emit Transfer(address(0), to, z);
                }
            }

            lastAllocation += maxAllocation;
            _ownedTokensCount[to] += ubalance;
            totalGunsMintedByCategory[category] += size;

            _addBatchToOwner(to, allBatches[allBatches.length - 1]);

            _totalSupply += size;
        }

        migrateCursor += count;

        return lastAllocation;
    }

    function getBatchIndex(uint256 tokenId) public pure returns (uint256) {
        uint256 index = (tokenId / maxAllocation);

        return index;
    }

    function categoryForToken(uint256 tokenId) public view returns (uint8) {
        uint256 index = getBatchIndex(tokenId);
        require(index < allBatches.length, "Token batch doesn't exist");

        Batch memory a = allBatches[index];

        return a.category;
    }

    function categoryIdForToken(uint256 tokenId) public view returns (uint256) {
        uint256 index = getBatchIndex(tokenId);
        require(index < allBatches.length, "Token batch doesn't exist");

        Batch memory a = allBatches[index];

        uint256 categoryId = (tokenId % maxAllocation) + a.startId;

        return categoryId;
    }

    function uintToString(uint v) internal pure returns (string memory) {
        if (v == 0) {
            return "0";
        }
        uint j = v;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (v != 0) {
            bstr[k--] = byte(uint8(48 + v % 10));
            v /= 10;
        }

        return string(bstr);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(exists(tokenId), "Token doesn't exist!");
        //Predict the token URI
        uint8 category = categoryForToken(tokenId);
        uint256 _categoryId = categoryIdForToken(tokenId);

        string memory id = uintToString(category).toSlice().concat("/".toSlice()).toSlice().concat(uintToString(_categoryId).toSlice().concat(".json".toSlice()).toSlice());
        string memory _base = "https://vault.warriders.com/guns/";

        //Final URL: https://vault.warriders.com/guns/<category>/<category_id>.json
        string memory _metadata = _base.toSlice().concat(id.toSlice());

        return _metadata;
    }

    function _removeBatchFromOwner(address from, Batch memory batch) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 globalIndex = getBatchIndex(batch.startTokenId);

        uint256 lastBatchIndex = batchesOwned[from].length - 1;
        uint256 batchIndex = ownedBatchIndex[globalIndex];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (batchIndex != lastBatchIndex) {
            Batch memory lastBatch = batchesOwned[from][lastBatchIndex];
            uint256 lastGlobalIndex = getBatchIndex(lastBatch.startTokenId);

            batchesOwned[from][batchIndex] = lastBatch; // Move the last batch to the slot of the to-delete batch
            ownedBatchIndex[lastGlobalIndex] = batchIndex; // Update the moved batch's index
        }

        // This also deletes the contents at the last position of the array
        batchesOwned[from].length--;

        // Note that ownedBatchIndex[batch] hasn't been cleared: it still points to the old slot (now occupied by
        // lastBatch, or just over the end of the array if the batch was the last one).
    }

    function _addBatchToOwner(address to, Batch memory batch) private {
        uint256 globalIndex = getBatchIndex(batch.startTokenId);

        ownedBatchIndex[globalIndex] = batchesOwned[to].length;
        batchesOwned[to].push(batch);
    }

    function batchTransfer(uint256 batchIndex, address to) public {
        Batch storage a = allBatches[batchIndex];

        address previousOwner = a.owner;

        require(a.owner == msg.sender, "You don't own this batch");

        _removeBatchFromOwner(previousOwner, a);

        a.owner = to;

        _addBatchToOwner(to, a);

        emit BatchTransfer(previousOwner, to, batchIndex);

        //Now to need to emit a bunch of transfer events
        uint end = a.startTokenId + a.size;
        //uint256 unActivated = 0;
        uint256 tokensMoved = 0;
        for (uint i = a.startTokenId; i < end; i++) {
            if (outOfBatch[i]) {
                continue;
            }
            tokensMoved++;
            emit Transfer(previousOwner, to, i);
        }

        _ownedTokensCount[to] += tokensMoved;
        _ownedTokensCount[previousOwner] -= tokensMoved;
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external pure returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param __owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function _tokensOfOwner(address __owner) internal view returns (uint256[] storage) {
        return _ownedTokens[__owner];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) internal {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        _ownedTokens[from].length--;

        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the token was the last one).
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param __owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address __owner) public view returns (uint256) {
        require(__owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[__owner];
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        if (outOfBatch[tokenId]) {
            address __owner = _tokenOwner[tokenId];
            require(__owner != address(0), "ERC721: owner query for nonexistent token");

            return __owner;
        }

        uint256 index = getBatchIndex(tokenId);
        require(index < allBatches.length, "Token batch doesn't exist");
        Batch memory a = allBatches[index];
        require(tokenId < a.startTokenId + a.size, "Token outside bounds of batch");
        return a.owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address __owner = ownerOf(tokenId);
        require(to != __owner, "ERC721: approval to current owner");

        require(_msgSender() == __owner || isApprovedForAll(__owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(__owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param __owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address __owner, address operator) public view returns (bool) {
        return _operatorApprovals[__owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(exists(tokenId), "ERC721: operator query for nonexistent token");
        address __owner = ownerOf(tokenId);
        return (spender == __owner || getApproved(tokenId) == spender || isApprovedForAll(__owner, spender));
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _addTokenTo(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to]++;
        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        uint256 index = getBatchIndex(tokenId);
        require(index < allBatches.length, "Token batch doesn't exist");
        Batch memory a = allBatches[index];
        require(tokenId < a.startTokenId + a.size, "Token out of bounds in batch");

        bool shouldRemove = false;
        bool shouldAdd = false;

        if (!outOfBatch[tokenId]) {
            //If this tokenID hasn't left it's origin batch
            //mark it as so
            outOfBatch[tokenId] = true;

            //Add token to 'to' address
            //(This will also increase their balance)
            //_addTokenTo(to, tokenId);
            shouldAdd = true;
        } else {
            if (to == a.owner) {
                //If this token is going back to the batch owner
                //Then mark it as inside the batch
                outOfBatch[tokenId] = false;

                //And remove the token from 'from' address
                //_removeTokenFromOwnerEnumeration(from, tokenId);
                shouldRemove = true;
            } else {
                shouldRemove = true;
                shouldAdd = true;
            }
        }

        _clearApproval(tokenId);

        _ownedTokensCount[from]--;
        _ownedTokensCount[to]++;

        _tokenOwner[tokenId] = to;

        if (shouldRemove) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }

        if (shouldAdd) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This function is deprecated.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }

    /**
    * Returns the number of tokens that are owned outside of a batch for a given owner
    */
    function fallbackCount(address __owner) public view returns (uint256) {
        return _ownedTokens[__owner].length;
    }

    /**
    * Returns a token at a given index that are owned outside of a batch for a given owner
    */
    function fallbackIndex(address __owner, uint256 index) public view returns (uint256) {
        return _ownedTokens[__owner][index];
    }
    
    function gunCountForCategory(uint8 category) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < allBatches.length; i++) {
            Batch memory b = allBatches[i];
            if (b.category == category) {
                count += b.size;
            }
        }

        return count;
    }

    function updateGunFactory(address new_factory) external onlyOwner {
        factory = new_factory;
    }
}