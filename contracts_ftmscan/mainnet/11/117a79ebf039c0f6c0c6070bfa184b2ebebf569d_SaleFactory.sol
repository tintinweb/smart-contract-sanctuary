/**
 *Submitted for verification at FtmScan.com on 2021-12-31
*/

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: contracts/interfaces/IOwnable.sol

pragma solidity ^0.8.9;
interface IOwnable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external; 
}

// File: contracts/interfaces/INftCollectionSale.sol

pragma solidity 0.8.9;

// --------------------------------------------------------------------------------------
//
// (c) NftLaunchpad 16/12/2021 
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// --------------------------------------------------------------------------------------

interface INftCollectionSale is IOwnable {
    function mint(address to, uint256 tokenId) external;
}

// File: contracts/interfaces/ISaleModel.sol

pragma solidity ^0.8.9;


// --------------------------------------------------------------------------------------
//
// (c) ISaleModel 29/12/2021 
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// --------------------------------------------------------------------------------------

interface ISaleModel {

    function initData(bytes calldata payload) external;
    
}

// File: contracts/interfaces/ISaleFactory.sol

pragma solidity ^0.8.9;

// --------------------------------------------------------------------------------------
//
// (c) ISaleFactory 28/12/2021
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// --------------------------------------------------------------------------------------

interface ISaleFactory {

    event Initiated();
    event SaleDeployed();
    event NewSaleModel();
    event NewCommissioner();
    event NewCommissionPerc();

    function WETH() external returns(IERC20);
    function COMMISSIONER() external returns(address);
    function COMMISSION_PERC() external returns(uint256);

    /**
        @notice Deploy a new model to be used.
        @param model    Address of the new sale model contract.
     */
    function deployModel(ISaleModel model) external;

    /**
        @notice Deploy a sale model.
        @param collection    NFT collection being sold.
        @param model        Sale model being used to conduct sale.
        @param payload      Init params data of the sale model.
     */
    function createSale(
        INftCollectionSale collection, 
        uint16 model, 
        bytes calldata payload
    ) external returns (address result, bool initialised);
}

// File: contracts/SaleFactory.sol

pragma solidity ^0.8.9;

// --------------------------------------------------------------------------------------
//
// (c) SaleFactory 29/12/2021 | SPDX-License-Identifier: MIT
// Designed by, DeGatchi (https://github.com/DeGatchi).
//
// --------------------------------------------------------------------------------------

contract SaleFactory is ISaleFactory, Ownable {

    IERC20 public immutable override WETH;
    address public override COMMISSIONER;
    uint256 public override COMMISSION_PERC;

    bool public initialised;

    ISaleModel[] public models;

    constructor(IERC20 _weth, address _commissioner, uint256 _commissionPerc) {
        WETH = _weth;
        COMMISSIONER = _commissioner;
        COMMISSION_PERC = _commissionPerc;
    }

    /// @notice Must be initialised to use function.
    modifier init() {
        require(initialised, "not initialised");
        _;
    }


    //  Views
    // ----------------------------------------------------------------------

    /**
        @notice Returns the total models available for use.
     */
    function modelsLength() external view returns(uint256) {
        return models.length;
    }


    //  Admin
    // ----------------------------------------------------------------------

    /**
        @notice Deploys all initial models to be used.
        @param _models    Addresses of the initial sale model contracts.
     */
    function initFactory(ISaleModel[] memory _models) external {
        require(!initialised, "already initialised");
        for (uint256 i; i < models.length; i++) models.push(_models[i]);
        initialised = true;
        emit Initiated();
    }

    /**
        @notice Deploy a new model to be used.
        @param model    Address of the new sale model contract.
     */
    function deployModel(ISaleModel model) external override init {
        models.push(model);
        emit NewSaleModel();
    }

    /**
        @notice Removes sale model from being available to use. 
        @param index    Element to remove
     */
    function removeModel(uint256 index) external init {
        require(index < models.length);
        models[index] = models[models.length-1];
        models.pop();
    }

    /**
        @notice Assigns new commissioner to receive commissioned funds.
     */
    function newCommissioner(address _commissioner) external onlyOwner {
        COMMISSIONER = _commissioner;
        emit NewCommissioner();
    }

    /**
        @notice Assigns new commission percentage to all new deployed sale contracts.
     */
    function newCommissionPerc(uint256 _commissionPerc) external onlyOwner {
        COMMISSION_PERC = _commissionPerc;
        emit NewCommissionPerc();
    }


    //  Sale
    // ----------------------------------------------------------------------

    /**
        @notice Deploy a sale model.
        @param collection   NFT collection being sold.
        @param model        Sale model being used to conduct sale.
        @param payload      Init params data of the sale model.
     */
    function createSale(
        INftCollectionSale collection, 
        uint16 model, 
        bytes calldata payload
    ) external override init returns (address result, bool successfulInit) {
        require(models.length > model, "model not found");
        require(collection.owner() == address(this), "no mint access");

        address cloning = address(models[model]);
        bytes20 targetBytes = bytes20(cloning);

        address cloneContract;
        
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            cloneContract := create(0, clone, 0x37)
        }

        // Transfer collection ownership to allow minting
        collection.transferOwnership(cloneContract);
        
        // Call `initData` of clonedContract w/ `data`
        (bool success, ) = cloneContract.call(abi.encodeWithSignature("initData(bytes calldata payload)", payload));

        emit SaleDeployed();

        return (cloneContract, success);
    }
}