/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

pragma solidity ^0.8.0;


// 
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

// 
/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// 
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

// 
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

// 
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// 
/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// 
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// 
/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// 
/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// 
/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// 
/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// 
interface IMysteryBoxNFT is IERC1155 {
    function createMysteryBox(
        uint256 _boxType,
        bytes memory _boxName,
        uint256 _amount,
        string memory _tokenURI
    ) external returns (uint256 tokenId);

    function burnMysteryBox(address account, uint256 id, uint256 amount) external;
    function getBoxInfo(uint256 _tokenId) external view returns (uint256, bytes memory, string memory);
    function getBoxType(uint256 _tokenId) external view returns (uint256);
}

// 
contract Campaign is Ownable, Initializable, Pausable, ERC1155Holder {
    using SafeMath for uint256;
    struct MysteryBox {
        uint256 price;
        uint256 quantity;
    }

    struct CampaignInfo {
        mapping(uint256 => MysteryBox) mysteryBoxInfo;
        mapping(uint256 => bool) exist;
        uint256[] mysteryBoxIds;
        uint256[] mysteryBoxPrices;
        uint256[] mysteryBoxTotals;
        uint256 start;
        uint256 end;
    }

    struct CampaignReturnInfo {
        uint256 campaignId;
        uint256[] mysteryBoxIds;
        uint256[] mysteryBoxPrices;
        uint256[] mysteryBoxTotals;
        uint256[] mysteryBoxQuantities;
        uint256 start;
        uint256 end;
    }

    IMysteryBoxNFT private mysteryBoxNFT;


    address payable private feeAddress;
    uint256 private constant ZOOM_FEE = 10 ** 2;

    mapping(uint256 => CampaignInfo) private campaigns;
    mapping(address => bool) public whiteListUsers;
    uint256 private currentCampaignId = 0;

    event OpenCampaign(address indexed creator, uint256 indexed campaignId, uint256[] mysteryBoxIds);
    event BuyMysteryBox(address indexed buyer, uint256 indexed mysteryBoxId, uint256 quantity, uint256 campaignId);
    event WithdrawRedundantMysteryBox(address indexed sender, uint256 campaignId, uint256[] withdrawIds, uint256[] withdrawQuantities);

    modifier onlyWhiteListUser() {
        require(whiteListUsers[msg.sender], "Only-white-list-can-execute");
        _;
    }

    constructor() {
        whiteListUsers[msg.sender] = true;
    }

    function adminWhiteListUsers(address _user, bool _whiteList) public onlyOwner {
        whiteListUsers[_user] = _whiteList;
    }

    function initialize(
        address _mysteryBoxNFT,
        address payable _opeBoxFeeTo
    ) external initializer {
        mysteryBoxNFT = IMysteryBoxNFT(_mysteryBoxNFT);
        feeAddress = _opeBoxFeeTo;
    }


    function setFeeTo(address payable _openBoxFeeTo) public onlyOwner {
        require(address(_openBoxFeeTo) != address(0) || address(_openBoxFeeTo) != address(this), "invalid address");
        feeAddress = _openBoxFeeTo;
    }


    function setMysteryBoxNFT(address _mysteryBoxNFT) external onlyOwner {
        require(address(_mysteryBoxNFT) != address(0), "Invalid Address");
        mysteryBoxNFT = IMysteryBoxNFT(_mysteryBoxNFT);
    }


    function openCampaign(
        uint256[] memory _mysteryBoxIds,
        uint256[] memory _mysteryBoxPrices,
        uint256[] memory _mysteryBoxQuantities,
        uint256 start,
        uint256 end) public onlyWhiteListUser {
        require(_mysteryBoxIds.length == _mysteryBoxPrices.length, 'Invalid Input');
        require(_mysteryBoxPrices.length == _mysteryBoxQuantities.length, 'Invalid Input');
        require(start < end && start > block.timestamp, 'Invalid Time');

        uint256 nextCampaignId = _getNextCampaignID();
        _incrementCampaignId();
        CampaignInfo storage info = campaigns[nextCampaignId];
        info.start = start;
        info.end = end;

        for (uint256 i = 0; i < _mysteryBoxIds.length; i++) {
            require(mysteryBoxNFT.balanceOf(msg.sender, _mysteryBoxIds[i]) >= _mysteryBoxQuantities[i], 'Not Enough Box To List');
            require(_mysteryBoxPrices[i] > 0, 'Invalid Price');
            require(!info.exist[_mysteryBoxIds[i]], 'Invalid mysteryBoxIds');
            info.exist[_mysteryBoxIds[i]] = true;
            info.mysteryBoxIds.push(_mysteryBoxIds[i]);
            info.mysteryBoxPrices.push(_mysteryBoxPrices[i]);
            info.mysteryBoxTotals.push(_mysteryBoxQuantities[i]);

            info.mysteryBoxInfo[_mysteryBoxIds[i]].price = _mysteryBoxPrices[i];
            info.mysteryBoxInfo[_mysteryBoxIds[i]].quantity = _mysteryBoxQuantities[i];
        }
        mysteryBoxNFT.safeBatchTransferFrom(msg.sender, address(this), _mysteryBoxIds, _mysteryBoxQuantities, abi.encodePacked(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")));
        emit OpenCampaign(msg.sender, nextCampaignId, _mysteryBoxIds);
    }

    function withdrawRedundantMysteryBox(
        uint256 campaignId) public onlyWhiteListUser {
        CampaignInfo storage campaign = campaigns[campaignId];
        require(campaign.end < block.timestamp, 'Campaign is opening');
        uint256[] memory withdrawIds;
        uint256[] memory withdrawQuantities;
        uint256 id = 0;
        for (uint256 i = 0; i < campaign.mysteryBoxIds.length; i++) {
            uint256 quantity = campaign.mysteryBoxInfo[campaign.mysteryBoxIds[i]].quantity;
            if (quantity > 0) {
                withdrawIds[id] = campaign.mysteryBoxIds[i];
                withdrawQuantities[id] = quantity;
                campaign.mysteryBoxInfo[campaign.mysteryBoxIds[i]].quantity = 0;
                id++;
            }
        }
        if (withdrawIds.length == 0) {
            return;
        }
        mysteryBoxNFT.safeBatchTransferFrom(address(this), msg.sender, withdrawIds, withdrawQuantities, abi.encodePacked(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")));
        emit WithdrawRedundantMysteryBox(msg.sender, campaignId, withdrawIds, withdrawQuantities);
    }


    function buyMysteryBoxWithBNB(
        uint256 _campaignId,
        uint256 _mysteryBoxId,
        uint256 _quantity
    ) public payable whenNotPaused {
        CampaignInfo storage campaign = campaigns[_campaignId];
        require(campaign.start <= block.timestamp && campaign.end >= block.timestamp, 'Campaign Inactive');
        require(campaign.mysteryBoxInfo[_mysteryBoxId].quantity >= _quantity, 'Out Of Stock!');
        require(mysteryBoxNFT.balanceOf(address(this), _mysteryBoxId) >= _quantity, 'Out Of Stock!');

        require(msg.value >= campaign.mysteryBoxInfo[_mysteryBoxId].price.mul(_quantity), 'Not Enough Money To Buy!');
        payable(feeAddress).transfer(msg.value);
        mysteryBoxNFT.safeTransferFrom(address(this), msg.sender, _mysteryBoxId, _quantity,
            abi.encodePacked(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")));
        campaign.mysteryBoxInfo[_mysteryBoxId].quantity = campaign.mysteryBoxInfo[_mysteryBoxId].quantity.sub(_quantity);
        emit BuyMysteryBox(msg.sender, _mysteryBoxId, _quantity, _campaignId);
    }


    function getActiveCampaigns() public view returns (CampaignReturnInfo[] memory) {
        uint256 cCampaignId = currentCampaignId;

        uint256 size = 0;
        for (uint256 i = 1; i <= cCampaignId; i++) {
            if (campaigns[i].end > block.timestamp) {
                size++;
            }
        }

        uint256 id = 0;
        CampaignReturnInfo[] memory result = new CampaignReturnInfo[](size);
        for (uint256 i = 1; i <= cCampaignId; i++) {
            if (campaigns[i].end > block.timestamp) {
                result[id] = getCampaignInfo(i);
                id++;
            }
        }
        return result;
    }

    function getCampaignInfo(uint256 _campaignId) public view returns (CampaignReturnInfo memory) {
        CampaignInfo  storage campaign = campaigns[_campaignId];
        CampaignReturnInfo memory result;
        result.campaignId = _campaignId;
        result.start = campaign.start;
        result.end = campaign.end;
        result.mysteryBoxIds = campaign.mysteryBoxIds;
        result.mysteryBoxPrices = campaign.mysteryBoxPrices;
        result.mysteryBoxTotals = campaign.mysteryBoxTotals;

        uint256[] memory mysteryBoxQuantities = new uint256[](campaign.mysteryBoxIds.length);
         uint256 id = 0;
        for (uint256 i = 0; i < campaign.mysteryBoxIds.length; i++) {

                mysteryBoxQuantities[id] = campaign.mysteryBoxInfo[campaign.mysteryBoxIds[i]].quantity;
                id++;
        }
        result.mysteryBoxQuantities = mysteryBoxQuantities;
        return result;
    }


    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    function _getNextCampaignID() private view returns (uint256) {
        return currentCampaignId.add(1);
    }


    function _incrementCampaignId() private {
        currentCampaignId++;
    }
}