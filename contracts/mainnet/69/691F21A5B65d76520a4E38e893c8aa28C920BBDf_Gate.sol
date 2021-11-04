// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IGate.sol";

/**
 * @title Gate contract between Boson router and ERC1155NonTransferable
 * Enables conditional commit
 */

contract Gate is IGate, Ownable, Pausable {
    mapping(uint256 => uint256) private voucherToToken;
    mapping(address => mapping(uint256 => bool)) private isDeactivated; // mapping user => voucherSet => bool

    IERC1155 private nonTransferableTokenContract;
    address private bosonRouterAddress;
  
    /**
     * @notice Construct and initialze the contract. Inizializes associated contract address. 
     * @param _bosonRouterAddress address of the associated BosonRouter contract instance
     */
    constructor(address _bosonRouterAddress, address _nonTransferableTokenContractAddress)
    notZeroAddress(_nonTransferableTokenContractAddress) notZeroAddress(_bosonRouterAddress) {
          bosonRouterAddress = _bosonRouterAddress;
        nonTransferableTokenContract = IERC1155(_nonTransferableTokenContractAddress
                );

        emit LogBosonRouterSet(_bosonRouterAddress, owner());
        emit LogNonTransferableContractSet(_nonTransferableTokenContractAddress, owner());
    }

    modifier onlyFromRouter() {
        require(msg.sender == bosonRouterAddress, "UNAUTHORIZED_BR"); 
        _;
    }

    modifier onlyRouterOrOwner() {
        require(msg.sender == bosonRouterAddress || msg.sender == owner(), "UNAUTHORIZED_O_BR"); 
        _;
    }

    /**
     * @notice  Checking if a non-zero address is provided, otherwise reverts.
     */
    modifier notZeroAddress(address _tokenAddress) {
        require(_tokenAddress != address(0), "0A"); //zero address
        _;
    }

    /**
     * @notice For a given _tokenIdSupply, it tells on which NFT it depends
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) [voucherSetID]
     * @return quest NFT token ID
     */
    function getNftTokenId(uint256 _tokenIdSupply) external view override returns (uint256) {
        return voucherToToken[_tokenIdSupply];
    }

    /**
     * @notice Sets the contract, where gate contract checks if quest NFT token exists
     * @param _nonTransferableTokenContractAddress address of a non-transferable token contract
     */
    function setNonTransferableTokenContract(
        address _nonTransferableTokenContractAddress
    ) external override onlyOwner notZeroAddress(_nonTransferableTokenContractAddress) whenPaused {
        nonTransferableTokenContract = IERC1155(
            _nonTransferableTokenContractAddress
        );

        emit LogNonTransferableContractSet(_nonTransferableTokenContractAddress, owner());
    }

      /**
     * @notice Gets the contract address, where gate contract checks if quest NFT token exists
     * @return Address of contract that hold non transferable NFTs (quest NFTs)
     */
    function getNonTransferableTokenContract(
    ) external view override returns (address) {
        return address(nonTransferableTokenContract);
    }

    /**
     * @notice Sets the Boson router contract address, from which deactivate is accepted
     * @param _bosonRouterAddress address of a non-transferable token contract
     */
    function setBosonRouterAddress(address _bosonRouterAddress)
        external
        override
        onlyOwner
        notZeroAddress(_bosonRouterAddress)
        whenPaused
    {
        bosonRouterAddress = _bosonRouterAddress;

        emit LogBosonRouterSet(_bosonRouterAddress, owner());
    }

    /**
     * @notice Registers connection between setID and tokenID
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) [voucherSetID]
     * @param _nftTokenId an ID of a quest token
     */
    function registerVoucherSetId(uint256 _tokenIdSupply, uint256 _nftTokenId)
        external
        override
        whenNotPaused
        onlyRouterOrOwner
    {
        require(_nftTokenId != 0, "TOKEN_ID_0_NOT_ALLOWED");
        require(_tokenIdSupply != 0, "INVALID_TOKEN_SUPPLY");

        voucherToToken[_tokenIdSupply] = _nftTokenId;

        emit LogVoucherSetRegistered(_tokenIdSupply, _nftTokenId);
    }

    /**
     * @notice Checks if user possesses the required quest NFT token for given voucher set
     * @param _user user address
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) [voucherSetID]
     * @return true if user possesses quest NFT token, and the token is not deactivated
     */
    function check(address _user, uint256 _tokenIdSupply)
        external
        view
        override
        returns (bool)
    {
        return
            !isDeactivated[_user][_tokenIdSupply] &&
            nonTransferableTokenContract.balanceOf(
                _user,
                voucherToToken[_tokenIdSupply]
            ) > 0;
    }

    /**
     * @notice Stores information that certain user already claimed
     * @param _user user address
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) [voucherSetID]
     */
    function deactivate(address _user, uint256 _tokenIdSupply)
        external
        override
        whenNotPaused
        onlyFromRouter
    {
        isDeactivated[_user][_tokenIdSupply] = true;

        emit LogUserVoucherDeactivated(_user, _tokenIdSupply);
    }

    /**
     * @notice Pause register and deactivate
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract and allows register and deactivate
     */
    function unpause() external override onlyOwner {
        _unpause();
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
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

pragma solidity ^0.7.0;

import "./Context.sol";

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
    constructor () {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.7.6;

interface IGate {
    event LogNonTransferableContractSet(
        address indexed _nonTransferableTokenContractAddress,
        address indexed _triggeredBy
    );
    event LogBosonRouterSet(
        address indexed _bosonRouter,
        address indexed _triggeredBy
    );
    event LogVoucherSetRegistered(
        uint256 indexed _tokenIdSupply,
        uint256 indexed _nftTokenId
    );
    event LogUserVoucherDeactivated(
        address indexed _user,
        uint256 indexed _tokenIdSupply
    );

    /**
     * @notice For a given _tokenIdSupply, it tells on which NFT it depends
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) [voucherSetID]
     * @return quest NFT token ID
     */
    function getNftTokenId(uint256 _tokenIdSupply)
        external
        view
        returns (uint256);

    /**
     * @notice Sets the contract, where gate contract checks if quest NFT token exists
     * @param _nonTransferableTokenContractAddress address of a non-transferable token contract
     */
    function setNonTransferableTokenContract(
        address _nonTransferableTokenContractAddress
    ) external;

    /**
     * @notice Sets the Boson router contract address, from which deactivate is accepted
     * @param _bosonRouter address of a non-transferable token contract
     */
    function setBosonRouterAddress(address _bosonRouter) external;

    /**
     * @notice Registers connection between setID and tokenID
     * @param _tokenIdSupply an ID of a supply token (ERC-1155)
     * @param _nftTokenId an ID of a quest token
     */
    function registerVoucherSetId(uint256 _tokenIdSupply, uint256 _nftTokenId)
        external;

    /**
     * @notice Gets the contract address, where gate contract checks if quest NFT token exists
     * @return Address of contract that hold non transferable NFTs (quest NFTs)
     */
    function getNonTransferableTokenContract() external view returns (address);

    /**
     * @notice Checks if user possesses the required quest NFT token for given voucher set
     * @param _user user address
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) [voucherSetID]
     * @return true if user possesses quest NFT token, and the token is not deactivated
     */
    function check(address _user, uint256 _tokenIdSupply)
        external
        view
        returns (bool);

    /**
     * @notice Stores information that certain user already claimed
     * @param _user user address
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) [voucherSetID]
     */
    function deactivate(address _user, uint256 _tokenIdSupply) external;

    /**
     * @notice Pause register and deactivate
     */
    function pause() external;

    /**
     * @notice Unpause the contract and allows register and deactivate
     */
    function unpause() external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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