/**
 *Submitted for verification at Etherscan.io on 2021-03-07
*/

pragma solidity >=0.4.24 <0.7.0;
pragma experimental ABIEncoderV2;

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


// File @openzeppelin/contracts-ethereum-package/contracts/GSN/[email protected]

pragma solidity ^0.6.0;

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}


// File @openzeppelin/contracts-ethereum-package/contracts/access/[email protected]

pragma solidity ^0.6.0;


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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

    uint256[49] private __gap;
}


// File @openzeppelin/contracts-ethereum-package/contracts/utils/[email protected]

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


// File @openzeppelin/contracts-ethereum-package/contracts/math/[email protected]

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/[email protected]

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File @openzeppelin/contracts-ethereum-package/contracts/token/ERC721/[email protected]

pragma solidity ^0.6.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}


// File @openzeppelin/contracts-ethereum-package/contracts/introspection/[email protected]

pragma solidity ^0.6.0;

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




pragma solidity 0.6.10;


/**
 * @notice Interface for Charged Particles ERC1155 - Token Manager
 */
interface IChargedParticlesTokenManager {
    function isNonFungible(uint256 _id) external pure returns(bool);
    function isFungible(uint256 _id) external pure returns(bool);
    function getNonFungibleIndex(uint256 _id) external pure returns(uint256);
    function getNonFungibleBaseType(uint256 _id) external pure returns(uint256);
    function isNonFungibleBaseType(uint256 _id) external pure returns(bool);
    function isNonFungibleItem(uint256 _id) external pure returns(bool);

    function createType(string calldata _uri, bool isNF) external returns (uint256);

    function mint(
        address _to, 
        uint256 _typeId, 
        uint256 _amount, 
        string calldata _uri, 
        bytes calldata _data
    ) external returns (uint256);
    
    // function mintBatch(
    //     address _to, 
    //     uint256[] calldata _types, 
    //     uint256[] calldata _amounts, 
    //     string[] calldata _uris, 
    //     bytes calldata _data
    // ) external returns (uint256[] memory);
    
    function burn(
        address _from, 
        uint256 _tokenId, 
        uint256 _amount
    ) external;
    
    // function burnBatch(
    //     address _from, 
    //     uint256[] calldata _tokenIds, 
    //     uint256[] calldata _amounts
    // ) external;
    
    function createErc20Bridge(uint256 _typeId, string calldata _name, string calldata _symbol, uint8 _decimals) external returns (address);
    function createErc721Bridge(uint256 _typeId, string calldata _name, string calldata _symbol) external returns (address);

    function uri(uint256 _id) external view returns (string memory);
    function totalSupply(uint256 _typeId) external view returns (uint256);
    function totalMinted(uint256 _typeId) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function balanceOf(address _tokenOwner, uint256 _typeId) external view returns (uint256);
    // function balanceOfBatch(address[] calldata _owners, uint256[] calldata _typeIds) external view returns (uint256[] memory);
    function isApprovedForAll(address _tokenOwner, address _operator) external view returns (bool);
}



pragma solidity ^0.6.10;

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {

    /**
     * @notice Handle the receipt of a single ERC1155 token type
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, 
     * at the end of a `safeTransferFrom` after the balance has been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value MUST result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _id        The id of the token being transferred
     * @param _amount    The amount of tokens being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address _operator, 
        address _from, 
        uint256 _id, 
        uint256 _amount, 
        bytes calldata _data
    ) external returns(bytes4);

    /**
     * @notice Handle the receipt of multiple ERC1155 token types
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, 
     * at the end of a `safeBatchTransferFrom` after the balances have been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value WILL result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeBatchTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _ids       An array containing ids of each token being transferred
     * @param _amounts   An array containing amounts of each token being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address _operator, 
        address _from, 
        uint256[] calldata _ids, 
        uint256[] calldata _amounts, 
        bytes calldata _data
    ) external returns(bytes4);

    /**
     * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
     * @param  interfaceID The ERC-165 interface ID that is queried for support.s
     * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
     *      This function MUST NOT consume more than 5,000 gas.
     * @return Whether ERC-165 or ERC1155TokenReceiver interfaces are supported.
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}


// File contracts/lib/Common.sol



pragma solidity 0.6.10;


/**
 * @notice Common Vars for Charged Particles
 */
contract Common {
    
    uint256 constant internal DEPOSIT_FEE_MODIFIER = 1e4;   // 10000  (100%)
    uint256 constant internal MAX_CUSTOM_DEPOSIT_FEE = 5e3; // 5000   (50%)
    uint256 constant internal MIN_DEPOSIT_FEE = 1e6;        // 1000000 (0.000000000001 ETH  or  1000000 WEI)

    bytes32 constant public ROLE_DAO_GOV = keccak256("ROLE_DAO_GOV");
    bytes32 constant public ROLE_MAINTAINER = keccak256("ROLE_MAINTAINER");

    // Fungibility-Type Flags
    uint256 constant internal TYPE_MASK = uint256(uint128(~0)) << 128;  
    uint256 constant internal NF_INDEX_MASK = uint128(~0);
    uint256 constant internal TYPE_NF_BIT = 1 << 255;

    // Interface Signatures
    bytes4 constant internal INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
    bytes4 constant internal INTERFACE_SIGNATURE_ERC721 = 0x80ac58cd;
    bytes4 constant internal INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;
    bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

}


// File contracts/lib/ERC1155.sol



pragma solidity 0.6.10;





/**
 * @notice Implementation of ERC1155 Multi-Token Standard contract
 */
abstract contract ERC1155 is Initializable, Common, IChargedParticlesTokenManager, IERC165 {
    using Address for address;
    using SafeMath for uint256;

    // Type Nonce for each Unique Type
    uint256 internal nonce;

    //
    // Generic (ERC20 & ERC721)
    //
    //       Account =>         Operator => Allowed?
    mapping (address => mapping (address => bool)) internal operators;   // Operator Approval for All Tokens by Type
    //        TypeID => Total Minted Supply
    mapping (uint256 => uint256) internal mintedByType;

    //
    // ERC20 Specific
    //
    //       Account =>           TypeID => ERC20 Balance
    mapping (address => mapping (uint256 => uint256)) internal balances;
    //        TypeID => Total Circulating Supply (reduced on burn)
    mapping (uint256 => uint256) internal supplyByType;

    //
    // ERC721 Specific
    //
    //       TokenID => Operator
    mapping (uint256 => address) internal tokenApprovals;   // Operator Approval per Token
    //       TokenID => Owner
    mapping (uint256 => address) internal nfOwners;
    //       TokenID => URI for the Token Metadata
    mapping (uint256 => string) internal tokenUri;
    //
    // Enumerable NFTs
    mapping (uint256 => mapping (uint256 => uint256)) internal ownedTokensByTypeIndex;
    mapping (uint256 => mapping (uint256 => uint256)) internal allTokensByTypeIndex;
    mapping (uint256 => mapping (address => uint256[])) internal ownedTokensByType;
    mapping (uint256 => uint256[]) internal allTokensByType; // Circulating Supply

    //
    // Events
    //

    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _amount
    );

    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _amounts
    );

    event Approval(
        address indexed _owner,
        address indexed _operator,
        uint256 indexed _tokenId
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    event URI(
        uint256 indexed _id, // ID = Type or Token ID
        string _uri
    );

    /***********************************|
    |          Initialization           |
    |__________________________________*/

    function initialize() public virtual initializer {
    }

    /***********************************|
    |            Public Read            |
    |__________________________________*/

    /**
     * @notice Gets the URI of the Token Metadata
     * @param _id  The Type ID of the Token to get the URI for
     * @return  The URI of the Token Metadata
     */
    function uri(uint256 _id) external override view returns (string memory) {
        return tokenUri[_id];
    }

    /**
     * @notice Checks if a specific token interface is supported
     * @param _interfaceID  The ID of the Interface to check
     * @return  True if the interface ID is supported
     */
    function supportsInterface(bytes4 _interfaceID) external override view returns (bool) {
        if (_interfaceID == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceID == INTERFACE_SIGNATURE_ERC1155) {
            return true;
        }
        return false;
    }

    /**
     * @notice Gets the Total Circulating Supply of a Token-Type
     * @param _typeId  The Type ID of the Token
     * @return  The Total Circulating Supply of the Token-Type
     */
    function totalSupply(uint256 _typeId) external override view returns (uint256) {
        return _totalSupply(_typeId);
    }

    /**
     * @notice Gets the Total Minted Supply of a Token-Type
     * @param _typeId  The Type ID of the Token
     * @return  The Total Minted Supply of the Token-Type
     */
    function totalMinted(uint256 _typeId) external override view returns (uint256) {
        return _totalMinted(_typeId);
    }

    /**
     * @notice Gets the Owner of a Non-fungible Token (ERC-721 only)
     * @param _tokenId  The ID of the Token
     * @return  The Address of the Owner of the Token
     */
    function ownerOf(uint256 _tokenId) external override view returns (address) {
        return _ownerOf(_tokenId);
    }

    /**
     * @notice Get the balance of an account's Tokens
     * @param _tokenOwner  The address of the token holder
     * @param _typeId      The Type ID of the Token
     * @return The Owner's Balance of the Token-Type
     */
    function balanceOf(address _tokenOwner, uint256 _typeId) external override view returns (uint256) {
        return _balanceOf(_tokenOwner, _typeId);
    }

    /**
     * @notice Get the balance of multiple account/token pairs
     * @param _owners   The addresses of the token holders
     * @param _typeIds  The Type IDs of the Tokens
     * @return The Owner's Balance of the Token-Types
     */
    // function balanceOfBatch(address[] calldata _owners, uint256[] calldata _typeIds) external override view returns (uint256[] memory) {
    //     return _balanceOfBatch(_owners, _typeIds);
    // }

    /**
     * @notice Gets a specific Token by Index of a Users Enumerable Non-fungible Tokens (ERC-721 only)
     * @param _typeId  The Type ID of the Token
     * @param _owner   The address of the Token Holder
     * @param _index   The Index of the Token
     * @return  The ID of the Token by Owner, Type & Index
     */
    function tokenOfOwnerByIndex(uint256 _typeId, address _owner, uint256 _index) public view returns (uint256) {
        require(_index < _balanceOf(_owner, _typeId), "E1155: INVALID_INDEX");
        return ownedTokensByType[_typeId][_owner][_index];
    }

    /**
     * @notice Gets a specific Token by Index in All Enumerable Non-fungible Tokens (ERC-721 only)
     * @param _typeId  The Type ID of the Token
     * @param _index   The Index of the Token
     * @return  The ID of the Token by Type & Index
     */
    function tokenByIndex(uint256 _typeId, uint256 _index) public view returns (uint256) {
        require(_index < _totalSupply(_typeId), "E1155: INVALID_INDEX");
        return allTokensByType[_typeId][_index];
    }

    /**
     * @notice Sets an Operator as Approved to Manage a specific Token
     * @param _operator  Address to add to the set of authorized operators
     * @param _tokenId  The ID of the Token
     */
    function approve(address _operator, uint256 _tokenId) public {
        address _owner = _ownerOf(_tokenId);
        require(_operator != _owner, "E1155: INVALID_OPERATOR");
        require(msg.sender == _owner || isApprovedForAll(_owner, msg.sender), "E1155: NOT_OPERATOR");

        tokenApprovals[_tokenId] = _operator;
        emit Approval(_owner, _operator, _tokenId);
    }

    /**
     * @notice Gets the Approved Operator of a specific Token
     * @param _tokenId  The ID of the Token
     * @return  The address of the approved operator
     */
    function getApproved(uint256 _tokenId) public view returns (address) {
        address owner = _ownerOf(_tokenId);
        require(owner != address(0x0), "E1155: INVALID_TOKEN");
        return tokenApprovals[_tokenId];
    }

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
     * @param _operator  Address to add to the set of authorized operators
     * @param _approved  True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) public {
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @notice Queries the approval status of an operator for a given owner
     * @param _tokenOwner   The owner of the Tokens
     * @param _operator     Address of authorized operator
     * @return True if the operator is approved, false if not
     */
    function isApprovedForAll(address _tokenOwner, address _operator) public override view returns (bool) {
        return operators[_tokenOwner][_operator];
    }

    /**
     * @notice Transfers amount of an _id from the _from address to the _to address specified
     * @param _from     The Address of the Token Holder
     * @param _to       The Address of the Token Receiver
     * @param _id       ID of the Token
     * @param _amount   The Amount to transfer
     */
    function transferFrom(address _from, address _to, uint256 _id, uint256 _amount) public {
        require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "E1155: NOT_OPERATOR");
        require(_to != address(0x0), "E1155: INVALID_ADDRESS");

        _safeTransferFrom(_from, _to, _id, _amount);
    }

    /**
     * @notice Safe-transfers amount of an _id from the _from address to the _to address specified
     * @param _from     The Address of the Token Holder
     * @param _to       The Address of the Token Receiver
     * @param _id       ID of the Token
     * @param _amount   The Amount to transfer
     * @param _data     Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) public {
        require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "E1155: NOT_OPERATOR");
        require(_to != address(0x0), "E1155: INVALID_ADDRESS");

        _safeTransferFrom(_from, _to, _id, _amount);
        _callonERC1155Received(_from, _to, _id, _amount, _data);
    }

    /**
     * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
     * @param _from     The Address of the Token Holder
     * @param _to       The Address of the Token Receiver
     * @param _ids      IDs of each Token
     * @param _amounts  The Amount to transfer per Token
     * @param _data     Additional data with no specified format, sent in call to `_to`
     */
    // function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) public {
    //     require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "E1155: NOT_OPERATOR");
    //     require(_to != address(0x0),"E1155: INVALID_ADDRESS");

    //     _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    //     _callonERC1155BatchReceived(_from, _to, _ids, _amounts, _data);
    // }

    /***********************************|
    |         Private Functions         |
    |__________________________________*/

    /**
     * @dev Gets the Total Circulating Supply of a Token-Type
     * @param _typeId  The Type ID of the Token
     * @return  The Total Circulating Supply of the Token-Type
     */
    function _totalSupply(uint256 _typeId) internal view returns (uint256) {
        if (_typeId & TYPE_NF_BIT == TYPE_NF_BIT) {
            return allTokensByType[_typeId].length;
        }
        return supplyByType[_typeId];
    }

    /**
     * @dev Gets the Total Minted Supply of a Token-Type
     * @param _typeId  The Type ID of the Token
     * @return  The Total Minted Supply of the Token-Type
     */
    function _totalMinted(uint256 _typeId) internal view returns (uint256) {
        return mintedByType[_typeId];
    }

    /**
     * @dev Gets the Owner of a Non-fungible Token (ERC-721 only)
     * @param _tokenId  The ID of the Token
     * @return  The Address of the Owner of the Token
     */
    function _ownerOf(uint256 _tokenId) internal view returns (address) {
        require(_tokenId & TYPE_NF_BIT == TYPE_NF_BIT, "E1155: INVALID_TYPE");
        return nfOwners[_tokenId];
    }

    /**
     * @dev Get the balance of an account's Tokens
     * @param _tokenOwner  The address of the token holder
     * @param _typeId      The Type ID of the Token
     * @return The Owner's Balance of the Token-Type
     */
    function _balanceOf(address _tokenOwner, uint256 _typeId) internal view returns (uint256) {
        // Non-fungible
        if (_typeId & TYPE_NF_BIT == TYPE_NF_BIT) {
            _typeId = _typeId & TYPE_MASK;
            return ownedTokensByType[_typeId][_tokenOwner].length;
        }
        // Fungible
        return balances[_tokenOwner][_typeId];
    }

    /**
     * @dev Get the balance of multiple account/token pairs
     * @param _owners   The addresses of the token holders
     * @param _typeIds  The Type IDs of the Tokens
     * @return The Owner's Balance of the Token-Types
     */
    function _balanceOfBatch(address[] memory _owners, uint256[] memory _typeIds) internal view returns (uint256[] memory) {
        require(_owners.length == _typeIds.length, "E1155: ARRAY_LEN_MISMATCH");

        uint256[] memory _balances = new uint256[](_owners.length);
        for (uint256 i = 0; i < _owners.length; ++i) {
            uint256 id = _typeIds[i];
            address owner = _owners[i];

            // Non-fungible
            if (id & TYPE_NF_BIT == TYPE_NF_BIT) {
                id = id & TYPE_MASK;
                _balances[i] = ownedTokensByType[id][owner].length;
            }
            // Fungible
            else {
                _balances[i] = balances[owner][id];
            }
        }

        return _balances;
    }

    /**
     * @dev Transfers amount amount of an _id from the _from address to the _to address specified
     * @param _from     The Address of the Token Holder
     * @param _to       The Address of the Token Receiver
     * @param _id       ID of the Token
     * @param _amount   The Amount to transfer
     */
    function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount) internal {
        // Non-Fungible
        if (_id & TYPE_NF_BIT == TYPE_NF_BIT) {
            uint256 _typeId = _id & TYPE_MASK;

            require(nfOwners[_id] == _from, "E1155: INVALID_OWNER");
            nfOwners[_id] = _to;
            _amount = 1;

            _removeTokenFromOwnerEnumeration(_typeId, _from, _id);
            _addTokenToOwnerEnumeration(_typeId, _to, _id);
        }
        // Fungible
        else {
//            require(_amount <= balances[_from][_id]); // SafeMath will throw if balance is negative
            balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
            balances[_to][_id] = balances[_to][_id].add(_amount);     // Add amount
        }

        // Emit event
        emit TransferSingle(msg.sender, _from, _to, _id, _amount);
    }

    /**
     * @dev Send multiple types of Tokens from the _from address to the _to address (with safety call)
     * @param _from     The Address of the Token Holder
     * @param _to       The Address of the Token Receiver
     * @param _ids      IDs of each Token
     * @param _amounts  The Amount to transfer per Token
     */
    function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts) internal {
        require(_ids.length == _amounts.length, "E1155: ARRAY_LEN_MISMATCH");

        uint256 id;
        uint256 amount;
        uint256 typeId;
        uint256 nTransfer = _ids.length;
        for (uint256 i = 0; i < nTransfer; ++i) {
            id = _ids[i];
            amount = _amounts[i];

            if (id & TYPE_NF_BIT == TYPE_NF_BIT) { // Non-Fungible
                typeId = id & TYPE_MASK;
                require(nfOwners[id] == _from, "E1155: INVALID_OWNER");
                nfOwners[id] = _to;

                _removeTokenFromOwnerEnumeration(typeId, _from, id);
                _addTokenToOwnerEnumeration(typeId, _to, id);
            } else {
//                require(amount <= balances[_from][id]); // SafeMath will throw if balance is negative
                balances[_from][id] = balances[_from][id].sub(amount);
                balances[_to][id] = balances[_to][id].add(amount);
            }
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
    }

    /**
     * @dev Creates a new Type, either FT or NFT
     * @param _uri   The Metadata URI of the Token (ERC721 only)
     * @param _isNF  True for NFT Types; False otherwise
     */
    function _createType(string memory _uri, bool _isNF) internal returns (uint256 _type) {
        require(bytes(_uri).length > 0, "E1155: INVALID_URI");

        _type = (++nonce << 128);
        if (_isNF) {
            _type = _type | TYPE_NF_BIT;
        }
        tokenUri[_type] = _uri;

        // emit a Transfer event with Create semantic to help with discovery.
        emit TransferSingle(msg.sender, address(0x0), address(0x0), _type, 0);
        emit URI(_type, _uri);
    }

    /**
     * @dev Mints a new Token, either FT or NFT
     * @param _to      The Address of the Token Receiver
     * @param _type    The Type ID of the Token
     * @param _amount  The amount of the Token to Mint
     * @param _uri     The Metadata URI of the Token (ERC721 only)
     * @param _data    Additional data with no specified format, sent in call to `_to`
     * @return The Token ID of the newly minted Token
     */
    function _mint(address _to, uint256 _type, uint256 _amount, string memory _uri, bytes memory _data) internal returns (uint256) {
        uint256 _tokenId;

        // Non-fungible
        if (_type & TYPE_NF_BIT == TYPE_NF_BIT) {
            uint256 index = mintedByType[_type].add(1);
            mintedByType[_type] = index;

            _tokenId  = _type | index;
            nfOwners[_tokenId] = _to;
            tokenUri[_tokenId] = _uri;
            _amount = 1;

            _addTokenToOwnerEnumeration(_type, _to, _tokenId);
            _addTokenToAllTokensEnumeration(_type, _tokenId);
        }

        // Fungible
        else {
            _tokenId = _type;
            supplyByType[_type] = supplyByType[_type].add(_amount);
            mintedByType[_type] = mintedByType[_type].add(_amount);
            balances[_to][_type] = balances[_to][_type].add(_amount);
        }

        emit TransferSingle(msg.sender, address(0x0), _to, _tokenId, _amount);
        _callonERC1155Received(address(0x0), _to, _tokenId, _amount, _data);

        return _tokenId;
    }

    /**
     * @dev Mints a Batch of new Tokens, either FT or NFT
     * @param _to       The Address of the Token Receiver
     * @param _types    The Type IDs of the Tokens
     * @param _amounts  The amounts of the Tokens to Mint
     * @param _uris     The Metadata URI of the Tokens (ERC721 only)
     * @param _data     Additional data with no specified format, sent in call to `_to`
     * @return The Token IDs of the newly minted Tokens
     */
    // function _mintBatch(
    //     address _to,
    //     uint256[] memory _types,
    //     uint256[] memory _amounts,
    //     string[] memory _uris,
    //     bytes memory _data
    // )
    //     internal
    //     returns (uint256[] memory)
    // {
    //     require(_types.length == _amounts.length, "E1155: ARRAY_LEN_MISMATCH");
    //     uint256 _type;
    //     uint256 _index;
    //     uint256 _tokenId;
    //     uint256 _count = _types.length;

    //     uint256[] memory _tokenIds = new uint256[](_count);

    //     for (uint256 i = 0; i < _count; i++) {
    //         _type = _types[i];

    //         // Non-fungible
    //         if (_type & TYPE_NF_BIT == TYPE_NF_BIT) {
    //             _index = mintedByType[_type].add(1);
    //             mintedByType[_type] = _index;

    //             _tokenId  = _type | _index;
    //             nfOwners[_tokenId] = _to;
    //             _tokenIds[i] = _tokenId;
    //             tokenUri[_tokenId] = _uris[i];
    //             _amounts[i] = 1;

    //             _addTokenToOwnerEnumeration(_type, _to, _tokenId);
    //             _addTokenToAllTokensEnumeration(_type, _tokenId);
    //         }

    //         // Fungible
    //         else {
    //             _tokenIds[i] = _type;
    //             supplyByType[_type] = supplyByType[_type].add(_amounts[i]);
    //             mintedByType[_type] = mintedByType[_type].add(_amounts[i]);
    //             balances[_to][_type] = balances[_to][_type].add(_amounts[i]);
    //         }
    //     }

    //     emit TransferBatch(msg.sender, address(0x0), _to, _tokenIds, _amounts);
    //     _callonERC1155BatchReceived(address(0x0), _to, _tokenIds, _amounts, _data);

    //     return _tokenIds;
    // }

    /**
     * @dev Burns an existing Token, either FT or NFT
     * @param _from     The Address of the Token Holder
     * @param _tokenId  The ID of the Token
     * @param _amount   The Amount to burn
     */
    function _burn(address _from, uint256 _tokenId, uint256 _amount) internal {
        uint256 _typeId = _tokenId;

        // Non-fungible
        if (_tokenId & TYPE_NF_BIT == TYPE_NF_BIT) {
            address _tokenOwner = _ownerOf(_tokenId);
            require(_tokenOwner == _from || isApprovedForAll(_tokenOwner, _from), "E1155: NOT_OPERATOR");
            nfOwners[_tokenId] = address(0x0);
            tokenUri[_tokenId] = "";
            _typeId = _tokenId & TYPE_MASK;
            _amount = 1;

            _removeTokenFromOwnerEnumeration(_typeId, _tokenOwner, _tokenId);
            _removeTokenFromAllTokensEnumeration(_typeId, _tokenId);
        }

        // Fungible
        else {
            require(_balanceOf(_from, _tokenId) >= _amount, "E1155: INSUFF_BALANCE");
            supplyByType[_typeId] = supplyByType[_typeId].sub(_amount);
            balances[_from][_typeId] = balances[_from][_typeId].sub(_amount);
        }

        emit TransferSingle(msg.sender, _from, address(0x0), _tokenId, _amount);
    }

    /**
     * @dev Burns a Batch of existing Tokens, either FT or NFT
     * @param _from      The Address of the Token Holder
     * @param _tokenIds  The IDs of the Tokens
     * @param _amounts   The Amounts to Burn of each Token
     */
    // function _burnBatch(address _from, uint256[] memory _tokenIds, uint256[] memory _amounts) internal {
    //     require(_tokenIds.length == _amounts.length, "E1155: ARRAY_LEN_MISMATCH");

    //     uint256 _tokenId;
    //     uint256 _typeId;
    //     address _tokenOwner;
    //     uint256 _count = _tokenIds.length;
    //     for (uint256 i = 0; i < _count; i++) {
    //         _tokenId = _tokenIds[i];
    //         _typeId = _tokenId;

    //         // Non-fungible
    //         if (_tokenId & TYPE_NF_BIT == TYPE_NF_BIT) {
    //             _tokenOwner = _ownerOf(_tokenId);
    //             require(_tokenOwner == _from || isApprovedForAll(_tokenOwner, _from), "E1155: NOT_OPERATOR");
    //             nfOwners[_tokenId] = address(0x0);
    //             tokenUri[_tokenId] = "";
    //             _typeId = _tokenId & TYPE_MASK;
    //             _amounts[i] = 1;

    //             _removeTokenFromOwnerEnumeration(_typeId, _tokenOwner, _tokenId);
    //             _removeTokenFromAllTokensEnumeration(_typeId, _tokenId);
    //         }

    //         // Fungible
    //         else {
    //             require(_balanceOf(_from, _tokenId) >= _amounts[i], "E1155: INSUFF_BALANCE");
    //             supplyByType[_typeId] = supplyByType[_typeId].sub(_amounts[i]);
    //             balances[_from][_tokenId] = balances[_from][_tokenId].sub(_amounts[i]);
    //         }
    //     }

    //     emit TransferBatch(msg.sender, _from, address(0x0), _tokenIds, _amounts);
    // }

    /**
     * @dev Adds NFT Tokens to a Users Enumerable List
     * @param _typeId   The Type ID of the Token
     * @param _to       The Address of the Token Receiver
     * @param _tokenId  The ID of the Token
     */
    function _addTokenToOwnerEnumeration(uint256 _typeId, address _to, uint256 _tokenId) internal {
        ownedTokensByTypeIndex[_typeId][_tokenId] = ownedTokensByType[_typeId][_to].length;
        ownedTokensByType[_typeId][_to].push(_tokenId);
    }

    /**
     * @dev Adds NFT Tokens to the All-Tokens Enumerable List
     * @param _typeId   The Type ID of the Token
     * @param _tokenId  The ID of the Token
     */
    function _addTokenToAllTokensEnumeration(uint256 _typeId, uint256 _tokenId) internal {
        allTokensByTypeIndex[_typeId][_tokenId] = allTokensByType[_typeId].length;
        allTokensByType[_typeId].push(_tokenId);
    }

    /**
     * @dev Removes NFT Tokens from a Users Enumerable List
     * @param _typeId   The Type ID of the Token
     * @param _from     The Address of the Token Holder
     * @param _tokenId  The ID of the T oken
     */
    function _removeTokenFromOwnerEnumeration(uint256 _typeId, address _from, uint256 _tokenId) internal {
        uint256 _lastTokenIndex = ownedTokensByType[_typeId][_from].length.sub(1);
        uint256 _tokenIndex = ownedTokensByTypeIndex[_typeId][_tokenId];

        if (_tokenIndex != _lastTokenIndex) {
            uint256 _lastTokenId = ownedTokensByType[_typeId][_from][_lastTokenIndex];

            ownedTokensByType[_typeId][_from][_tokenIndex] = _lastTokenId;
            ownedTokensByTypeIndex[_typeId][_lastTokenId] = _tokenIndex;
        }
        ownedTokensByType[_typeId][_from].pop();
        ownedTokensByTypeIndex[_typeId][_tokenId] = 0;
    }

    /**
     * @dev Removes NFT Tokens from the All-Tokens Enumerable List
     * @param _typeId   The Type ID of the Token
     * @param _tokenId  The ID of the Token
     */
    function _removeTokenFromAllTokensEnumeration(uint256 _typeId, uint256 _tokenId) internal {
        uint256 _lastTokenIndex = allTokensByType[_typeId].length.sub(1);
        uint256 _tokenIndex = allTokensByTypeIndex[_typeId][_tokenId];
        uint256 _lastTokenId = allTokensByType[_typeId][_lastTokenIndex];

        allTokensByType[_typeId][_tokenIndex] = _lastTokenId;
        allTokensByTypeIndex[_typeId][_lastTokenId] = _tokenIndex;

        allTokensByType[_typeId].pop();
        allTokensByTypeIndex[_typeId][_tokenId] = 0;
    }

    /**
     * @dev Check if the Receiver is a Contract and ensure compatibility to the ERC1155 spec
     */
    function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) internal {
        // Check if recipient is a contract
        if (_to.isContract()) {
            bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _amount, _data);
            require(retval == ERC1155_RECEIVED_VALUE, "E1155: INVALID_RECEIVER");
        }
    }

    /**
     * @dev  Check if the Receiver is a Contract and ensure compatibility to the ERC1155 spec
     */
    // function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) internal {
    //     // Pass data if recipient is a contract
    //     if (_to.isContract()) {
    //         bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _amounts, _data);
    //         require(retval == ERC1155_BATCH_RECEIVED_VALUE, "E1155: INVALID_RECEIVER");
    //     }
    // }
}


// File contracts/lib/BridgedERC1155.sol


// BridgedERC1155.sol - Charged Particles
// Copyright (c) 2019, 2020 Rob Secord <robsecord.eth>
//
// Original Idea: https://github.com/pelith/erc-1155-adapter
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.10;





/**
 * @notice ERC-1155 Token Standard with support for Bridges to individual ERC-20 & ERC-721 Token Contracts
 */
abstract contract BridgedERC1155 is Initializable, ERC1155 {

    //        TypeID => Token Bridge Address
    mapping (uint256 => address) internal bridge;

    // Template Contracts for creating Token Bridges
    address internal templateErc20;
    address internal templateErc721;

    //
    // Events
    //
    event NewBridge(uint256 indexed _typeId, address indexed _bridge);

    //
    // Modifiers
    //
    /**
     * @dev Throws if called by any account other than a Bridge contract.
     */
    modifier onlyBridge(uint256 _typeId) {
        require(bridge[_typeId] == msg.sender, "B1155: ONLY_BRIDGE");
        _;
    }


    /***********************************|
    |          Initialization           |
    |__________________________________*/

    function initialize() public virtual override initializer {
        ERC1155.initialize();

        // Create Bridge Contract Templates
        templateErc20 = address(new ERC20Bridge());
        templateErc721 = address(new ERC721Bridge());
    }


    /***********************************|
    |            Only Bridge            |
    |__________________________________*/

    /**
     * @notice Sets an Operator Approval to manage a specific token by type in the ERC1155 Contract from a Bridge Contract
     */
    function approveBridged(
        uint256 _typeId,
        address _from,
        address _operator,
        uint256 _tokenId
    )
        public
        onlyBridge(_typeId)
    {
        uint256 _tokenTypeId = _tokenId;
        if (_tokenId & TYPE_NF_BIT == TYPE_NF_BIT) {
            _tokenTypeId = _tokenId & TYPE_MASK;
        }
        require(_tokenTypeId == _typeId, "B1155: INVALID_TYPE");

        address _owner = _ownerOf(_tokenId);
        require(_operator != _owner, "B1155: INVALID_OPERATOR");
        require(_from == _owner || isApprovedForAll(_owner, _from), "B1155: NOT_OPERATOR");

        tokenApprovals[_tokenId] = _operator;
        emit Approval(_owner, _operator, _tokenId);
    }

    /**
     * @notice Sets an Operator Approval to manage all tokens by type in the ERC1155 Contract from a Bridge Contract
     */
    function setApprovalForAllBridged(
        uint256 _typeId,
        address _from,
        address _operator,
        bool _approved
    )
        public
        onlyBridge(_typeId)
    {
        operators[_from][_operator] = _approved;
        emit ApprovalForAll(_from, _operator, _approved);
    }

    /**
     * @notice Safe-transfers a specific token by type in the ERC1155 Contract from a Bridge Contract
     */
    function transferFromBridged(
        uint256 _typeId,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _value
    )
        public
        onlyBridge(_typeId)
        returns (bool)
    {
        require(_to != address(0x0), "B1155: INVALID_ADDRESS");

        uint256 _tokenTypeId = _tokenId;
        if (_tokenId & TYPE_NF_BIT == TYPE_NF_BIT) {
            _tokenTypeId = _tokenId & TYPE_MASK;
        }
        require(_tokenTypeId == _typeId, "B1155: INVALID_TYPE");

        _safeTransferFrom(_from, _to, _tokenId, _value);
        return true;
    }


    /***********************************|
    |         Private Functions         |
    |__________________________________*/

    /**
     * @dev Creates an ERC20 Token Bridge Contract to interface with the ERC1155 Contract
     */
    function _createErc20Bridge(
        uint256 _typeId,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    )
        internal
        returns (address)
    {
        require(bridge[_typeId] == address(0), "B1155: INVALID_BRIDGE");

        address newBridge = _createClone(templateErc20);
        ERC20Bridge(newBridge).setup(_typeId, _name, _symbol, _decimals);
        bridge[_typeId] = newBridge;

        emit NewBridge(_typeId, newBridge);
        return newBridge;
    }

    /**
     * @dev Creates an ERC721 Token Bridge Contract to interface with the ERC1155 Contract
     */
    function _createErc721Bridge(
        uint256 _typeId,
        string memory _name,
        string memory _symbol
    )
        internal
        returns (address)
    {
        require(bridge[_typeId] == address(0), "B1155: INVALID_BRIDGE");

        address newBridge = _createClone(templateErc721);
        ERC721Bridge(newBridge).setup(_typeId, _name, _symbol);
        bridge[_typeId] = newBridge;

        emit NewBridge(_typeId, newBridge);
        return newBridge;
    }

    /**
     * @dev Creates Contracts from a Template via Cloning
     * see: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md
     */
    function _createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        // solhint-disable-next-line
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}


/**
 * @notice ERC20 Token Bridge
 */
contract ERC20Bridge {
    using SafeMath for uint256;

    BridgedERC1155 public entity;

    uint256 public typeId;
    string public name;
    string public symbol;
    uint8 public decimals;

    mapping (address => mapping (address => uint256)) private allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setup(uint256 _typeId, string memory _name, string memory _symbol, uint8 _decimals) public {
        require(typeId == 0 && address(entity) == address(0), "B1155: ERC20_ALREADY_INIT");
        entity = BridgedERC1155(msg.sender);
        typeId = _typeId;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return entity.totalSupply(typeId);
    }

    function balanceOf(address _account) external view returns (uint256) {
        return entity.balanceOf(_account, typeId);
    }

    function transfer(address _recipient, uint256 _amount) external returns (bool) {
        require(entity.transferFromBridged(typeId, msg.sender, _recipient, typeId, _amount), "B1155: ERC20_TRANSFER_FAILED");
        emit Transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool) {
        allowed[_sender][msg.sender] = allowed[_sender][msg.sender].sub(_amount);
        require(entity.transferFromBridged(typeId, _sender, _recipient, typeId, _amount), "B1155: ERC20_TRANSFER_FAILED");
        emit Transfer(_sender, _recipient, _amount);
        return true;
    }
}
// ERC20 ABI
/*
[
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "internalType": "address",
                "name": "from",
                "type": "address"
            },
            {
                "indexed": true,
                "internalType": "address",
                "name": "to",
                "type": "address"
            },
            {
                "indexed": true,
                "internalType": "uint256",
                "name": "tokenId",
                "type": "uint256"
            }
        ],
        "name": "Transfer",
        "type": "event"
    },
    {
        "constant": false,
        "inputs": [
            {
                "internalType": "address",
                "name": "_to",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "_tokenId",
                "type": "uint256"
            }
        ],
        "name": "approve",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "internalType": "address",
                "name": "_account",
                "type": "address"
            }
        ],
        "name": "balanceOf",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "entity",
        "outputs": [
            {
                "internalType": "contract IBridgedERC1155",
                "name": "",
                "type": "address"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "internalType": "uint256",
                "name": "_tokenId",
                "type": "uint256"
            }
        ],
        "name": "getApproved",
        "outputs": [
            {
                "internalType": "address",
                "name": "",
                "type": "address"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "internalType": "address",
                "name": "_owner",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "_operator",
                "type": "address"
            }
        ],
        "name": "isApprovedForAll",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "name",
        "outputs": [
            {
                "internalType": "string",
                "name": "",
                "type": "string"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "internalType": "uint256",
                "name": "_tokenId",
                "type": "uint256"
            }
        ],
        "name": "ownerOf",
        "outputs": [
            {
                "internalType": "address",
                "name": "",
                "type": "address"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "internalType": "address",
                "name": "_from",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "_to",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "_tokenId",
                "type": "uint256"
            }
        ],
        "name": "safeTransferFrom",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "internalType": "address",
                "name": "_from",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "_to",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "_tokenId",
                "type": "uint256"
            },
            {
                "internalType": "bytes",
                "name": "_data",
                "type": "bytes"
            }
        ],
        "name": "safeTransferFrom",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "internalType": "address",
                "name": "_operator",
                "type": "address"
            },
            {
                "internalType": "bool",
                "name": "_approved",
                "type": "bool"
            }
        ],
        "name": "setApprovalForAll",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "internalType": "uint256",
                "name": "_typeId",
                "type": "uint256"
            },
            {
                "internalType": "string",
                "name": "_name",
                "type": "string"
            },
            {
                "internalType": "string",
                "name": "_symbol",
                "type": "string"
            }
        ],
        "name": "setup",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "internalType": "bytes4",
                "name": "interfaceId",
                "type": "bytes4"
            }
        ],
        "name": "supportsInterface",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "payable": false,
        "stateMutability": "pure",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "symbol",
        "outputs": [
            {
                "internalType": "string",
                "name": "",
                "type": "string"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "internalType": "uint256",
                "name": "_index",
                "type": "uint256"
            }
        ],
        "name": "tokenByIndex",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "internalType": "address",
                "name": "_owner",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "_index",
                "type": "uint256"
            }
        ],
        "name": "tokenOfOwnerByIndex",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "internalType": "uint256",
                "name": "_tokenId",
                "type": "uint256"
            }
        ],
        "name": "tokenURI",
        "outputs": [
            {
                "internalType": "string",
                "name": "",
                "type": "string"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "totalSupply",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "internalType": "address",
                "name": "_from",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "_to",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "_tokenId",
                "type": "uint256"
            }
        ],
        "name": "transferFrom",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "typeId",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    }
]
*/

/**
 * @notice ERC721 Token Bridge
 */
contract ERC721Bridge {
    BridgedERC1155 public entity;

    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;
    uint256 public typeId;
    string public name;
    string public symbol;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function setup(uint256 _typeId, string memory _name, string memory _symbol) public {
        require(typeId == 0 && address(entity) == address(0), "B1155: ERC721_ALREADY_INIT");
        entity = BridgedERC1155(msg.sender);
        typeId = _typeId;
        name = _name;
        symbol = _symbol;
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        require(interfaceId != 0xffffffff, "B1155: ERC721_INVALID_INTERFACE");
        return interfaceId == INTERFACE_ID_ERC721;
    }

    function totalSupply() external view returns (uint256) {
        return entity.totalSupply(typeId);
    }

    function balanceOf(address _account) external view returns (uint256) {
        return entity.balanceOf(_account, typeId);
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return entity.ownerOf(_tokenId);
    }

    function approve(address _to, uint256 _tokenId) external {
        entity.approveBridged(typeId, msg.sender, _to, _tokenId);
    }
    function getApproved(uint256 _tokenId) external view returns (address) {
        return entity.getApproved(_tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        entity.setApprovalForAllBridged(typeId, msg.sender, _operator, _approved);
    }
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return entity.isApprovedForAll(_owner, _operator);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        _transferFrom(msg.sender, _from, _to, _tokenId);
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        _safeTransferFrom(msg.sender, _from, _to, _tokenId, "");
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external {
        _safeTransferFrom(msg.sender, _from, _to, _tokenId, _data);
    }

    // Enumeration
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        return entity.tokenOfOwnerByIndex(typeId, _owner, _index);
    }
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        return entity.tokenByIndex(typeId, _index);
    }

    // Metadata
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return entity.uri(_tokenId);
    }

    function _transferFrom(address _operator, address _from, address _to, uint256 _tokenId) internal {
        require((_operator == _from) || entity.isApprovedForAll(_from, _operator), "B1155: ERC721_NOT_OPERATOR");
        require(entity.transferFromBridged(typeId, _from, _to, _tokenId, 1), "B1155: ERC721_TRANSFER_FAILED");
        emit Transfer(_from, _to, _tokenId);
    }

    function _safeTransferFrom(address _operator, address _from, address _to, uint256 _tokenId, bytes memory _data) internal {
        require((_operator == _from) || entity.isApprovedForAll(_from, _operator), "B1155: ERC721_NOT_OPERATOR");
        require(entity.transferFromBridged(typeId, _from, _to, _tokenId, 1), "B1155: ERC721_TRANSFER_FAILED");
        require(_checkOnERC721Received(_operator, _from, _to, _tokenId, _data), "B1155: ERC721_INVALID_RECEIVER");
        emit Transfer(_from, _to, _tokenId);
    }

    function _isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function _checkOnERC721Received(address _operator, address _from, address _to, uint256 _tokenId, bytes memory _data) internal returns (bool) {
        if (!_isContract(_to)) { return true; }
        bytes4 retval = IERC721Receiver(_to).onERC721Received(_operator, _from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }
}
// ERC721 ABI
/*
[
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "internalType": "address",
                "name": "from",
                "type": "address"
            },
            {
                "indexed": true,
                "internalType": "address",
                "name": "to",
                "type": "address"
            },
            {
                "indexed": true,
                "internalType": "uint256",
                "name": "tokenId",
                "type": "uint256"
            }
        ],
        "name": "Transfer",
        "type": "event"
    },
    {
        "constant": false,
        "inputs": [
            {
                "internalType": "address",
                "name": "_to",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "_tokenId",
                "type": "uint256"
            }
        ],
        "name": "approve",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "internalType": "address",
                "name": "_account",
                "type": "address"
            }
        ],
        "name": "balanceOf",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "entity",
        "outputs": [
            {
                "internalType": "contract IBridgedERC1155",
                "name": "",
                "type": "address"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "internalType": "uint256",
                "name": "_tokenId",
                "type": "uint256"
            }
        ],
        "name": "getApproved",
        "outputs": [
            {
                "internalType": "address",
                "name": "",
                "type": "address"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "internalType": "address",
                "name": "_owner",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "_operator",
                "type": "address"
            }
        ],
        "name": "isApprovedForAll",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "name",
        "outputs": [
            {
                "internalType": "string",
                "name": "",
                "type": "string"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "internalType": "uint256",
                "name": "_tokenId",
                "type": "uint256"
            }
        ],
        "name": "ownerOf",
        "outputs": [
            {
                "internalType": "address",
                "name": "",
                "type": "address"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "internalType": "address",
                "name": "_from",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "_to",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "_tokenId",
                "type": "uint256"
            }
        ],
        "name": "safeTransferFrom",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "internalType": "address",
                "name": "_from",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "_to",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "_tokenId",
                "type": "uint256"
            },
            {
                "internalType": "bytes",
                "name": "_data",
                "type": "bytes"
            }
        ],
        "name": "safeTransferFrom",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "internalType": "address",
                "name": "_operator",
                "type": "address"
            },
            {
                "internalType": "bool",
                "name": "_approved",
                "type": "bool"
            }
        ],
        "name": "setApprovalForAll",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "internalType": "uint256",
                "name": "_typeId",
                "type": "uint256"
            },
            {
                "internalType": "string",
                "name": "_name",
                "type": "string"
            },
            {
                "internalType": "string",
                "name": "_symbol",
                "type": "string"
            }
        ],
        "name": "setup",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "internalType": "bytes4",
                "name": "interfaceId",
                "type": "bytes4"
            }
        ],
        "name": "supportsInterface",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "payable": false,
        "stateMutability": "pure",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "symbol",
        "outputs": [
            {
                "internalType": "string",
                "name": "",
                "type": "string"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "internalType": "uint256",
                "name": "_index",
                "type": "uint256"
            }
        ],
        "name": "tokenByIndex",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "internalType": "address",
                "name": "_owner",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "_index",
                "type": "uint256"
            }
        ],
        "name": "tokenOfOwnerByIndex",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "internalType": "uint256",
                "name": "_tokenId",
                "type": "uint256"
            }
        ],
        "name": "tokenURI",
        "outputs": [
            {
                "internalType": "string",
                "name": "",
                "type": "string"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "totalSupply",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "internalType": "address",
                "name": "_from",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "_to",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "_tokenId",
                "type": "uint256"
            }
        ],
        "name": "transferFrom",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "typeId",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    }
]

*/


// File contracts/ChargedParticlesTokenManager.sol

// SPDX-License-Identifier: MIT

// ChargedParticlesTokenManager.sol -- Charged Particles
// Copyright (c) 2019, 2020 Rob Secord <robsecord.eth>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.10;






/**
 * @notice Charged Particles ERC1155 - Token Manager
 */
contract ChargedParticlesTokenManager is Initializable, OwnableUpgradeSafe, BridgedERC1155 {
    using SafeMath for uint256;
    using Address for address payable;

    // Integrated Controller Contracts
    mapping (address => bool) internal fusedParticles;
    // mapping (address => mapping (uint256 => bool)) internal fusedParticleTypes;
    mapping (uint256 => address) internal fusedParticleTypes;

    // Contract Version
    bytes16 public version;

    // Throws if called by any account other than a Fused-Particle contract.
    modifier onlyFusedParticles() {
        require(fusedParticles[msg.sender], "CPTM: ONLY_FUSED");
        _;
    }

    /***********************************|
    |          Initialization           |
    |__________________________________*/

    function initialize() public override initializer {
        __Ownable_init();
        BridgedERC1155.initialize();
        version = "v0.4.2";
    }


    /***********************************|
    |            Public Read            |
    |__________________________________*/

    function isNonFungible(uint256 _id) external override pure returns(bool) {
        return _id & TYPE_NF_BIT == TYPE_NF_BIT;
    }
    function isFungible(uint256 _id) external override pure returns(bool) {
        return _id & TYPE_NF_BIT == 0;
    }
    function getNonFungibleIndex(uint256 _id) external override pure returns(uint256) {
        return _id & NF_INDEX_MASK;
    }
    function getNonFungibleBaseType(uint256 _id) external override pure returns(uint256) {
        return _id & TYPE_MASK;
    }
    function isNonFungibleBaseType(uint256 _id) external override pure returns(bool) {
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK == 0);
    }
    function isNonFungibleItem(uint256 _id) external override pure returns(bool) {
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK != 0);
    }

    /**
     * @notice Gets the Creator of a Token Type
     * @param _typeId     The Type ID of the Token
     * @return  The Creator Address
     */
    function getTypeCreator(uint256 _typeId) external view returns (address) {
        return fusedParticleTypes[_typeId];
    }


    /***********************************|
    |      Only Charged Particles       |
    |__________________________________*/

    /**
     * @dev Creates a new Particle Type, either FT or NFT
     */
    function createType(
        string calldata _uri,
        bool isNF
    )
        external
        override
        onlyFusedParticles
        returns (uint256)
    {
        uint256 _typeId = _createType(_uri, isNF);
        fusedParticleTypes[_typeId] = msg.sender;
        return _typeId;
    }

    /**
     * @dev Mints a new Particle, either FT or NFT
     */
    function mint(
        address _to,
        uint256 _typeId,
        uint256 _amount,
        string calldata _uri,
        bytes calldata _data
    )
        external
        override
        onlyFusedParticles
        returns (uint256)
    {
        require(fusedParticleTypes[_typeId] == msg.sender, "CPTM: ONLY_FUSED");
        return _mint(_to, _typeId, _amount, _uri, _data);
    }

    /**
     * @dev Mints a Batch of new Particles, either FT or NFT
     */
    // function mintBatch(
    //     address _to,
    //     uint256[] calldata _types,
    //     uint256[] calldata _amounts,
    //     string[] calldata _uris,
    //     bytes calldata _data
    // )
    //     external
    //     override
    //     onlyFusedParticles
    //     returns (uint256[] memory)
    // {
    //     for (uint256 i = 0; i < _types.length; i++) {
    //         require(fusedParticleTypes[_types[i]] == msg.sender, "CPTM: ONLY_FUSED");
    //     }
    //     return _mintBatch(_to, _types, _amounts, _uris, _data);
    // }

    /**
     * @dev Burns an existing Particle, either FT or NFT
     */
    function burn(
        address _from,
        uint256 _tokenId,
        uint256 _amount
    )
        external
        override
        onlyFusedParticles
    {
        uint256 _typeId = _tokenId;
        if (_tokenId & TYPE_NF_BIT == TYPE_NF_BIT) {
            _typeId = _tokenId & TYPE_MASK;
        }
        require(fusedParticleTypes[_typeId] == msg.sender, "CPTM: ONLY_FUSED");
        _burn(_from, _tokenId, _amount);
    }

    /**
     * @dev Burns a Batch of existing Particles, either FT or NFT
     */
    // function burnBatch(
    //     address _from,
    //     uint256[] calldata _tokenIds,
    //     uint256[] calldata _amounts
    // )
    //     external
    //     override
    //     onlyFusedParticles
    // {
    //     for (uint256 i = 0; i < _tokenIds.length; i++) {
    //         uint256 _typeId = _tokenIds[i];
    //         if (_typeId & TYPE_NF_BIT == TYPE_NF_BIT) {
    //             _typeId = _typeId & TYPE_MASK;
    //         }
    //         require(fusedParticleTypes[_typeId] == msg.sender, "CPTM: ONLY_FUSED");
    //     }
    //     _burnBatch(_from, _tokenIds, _amounts);
    // }

    /**
     * @dev Creates an ERC20 Token Bridge Contract to interface with the ERC1155 Contract
     */
    function createErc20Bridge(
        uint256 _typeId,
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals
    )
        external
        override
        onlyFusedParticles
        returns (address)
    {
        require(fusedParticleTypes[_typeId] == msg.sender, "CPTM: ONLY_FUSED");
        return _createErc20Bridge(_typeId, _name, _symbol, _decimals);
    }

    /**
     * @dev Creates an ERC721 Token Bridge Contract to interface with the ERC1155 Contract
     */
    function createErc721Bridge(
        uint256 _typeId,
        string calldata _name,
        string calldata _symbol
    )
        external
        override
        onlyFusedParticles
        returns (address)
    {
        require(fusedParticleTypes[_typeId] == msg.sender, "CPTM: ONLY_FUSED");
        return _createErc721Bridge(_typeId, _name, _symbol);
    }


    /***********************************|
    |          Only Admin/DAO           |
    |__________________________________*/

    /**
     * @dev Adds an Integration Controller Contract as a Fused Particle to allow Creating/Minting
     */
    function registerContractType(address _particleAddress, bool _fusedState) external onlyOwner {
        fusedParticles[_particleAddress] = _fusedState;
    }
}