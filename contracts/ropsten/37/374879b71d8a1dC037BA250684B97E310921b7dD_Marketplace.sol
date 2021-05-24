/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

pragma solidity ^0.8.0;

interface IRegistry {
    function addApplication(
        uint256 applicationId,
        uint256 applicationFee,
        address privateAddress,
        uint256 companyId
    ) external;

    function updateApplication(address privateAddress, uint256 fee) external;

    function setUserPrivateAddress(address privateAddress) external;

    function addRoyalty(
        uint256 tokenId,
        address beneficiary,
        uint256 fee
    ) external;

    function changeRoyaltyFee(uint256 tokenId, uint256 fee) external;

    function changeTokenPrice(uint256 tokenId, uint256 price) external;

    function changeRoyaltyBeneficiary(uint256 tokenId, address beneficiary)
        external;

    function addApplicationToken(address appAddress, uint256 tokenId) external;

    function offerForSale(uint256 tokenId, uint256 price) external;

    function removeFromSale(uint256 tokenId) external;

    function getRoyaltyBeneficiary(address sender)
        external
        returns (address beneficiary);

    function getTokenSaleData(uint256 tokenId)
        external
        returns (
            bool isForSale,
            uint256 price,
            uint256 royalty,
            address beneficiary,
            uint256 appFee,
            address appAddress
        );

    function getMarketplace() external returns (address);
	function markAsSold(uint256 tokenId) external;
}

interface IMarketplace {
    function updateToken(address token) external;

    function updateMarketFee(uint256 fee) external;

    function updateRegistry(address registry) external;

    function putUpTokenForSale(uint256 tokenId, uint256 price) external;

    function updateTokenPrice(uint256 tokenId, uint256 price) external;

    function removeTokenFromSale(uint256 tokenId) external;

    function buyToken(uint256 tokenId) external;
}

contract Marketplace is Ownable {
    IRegistry public registry;
    IERC721 public token;
    uint256 public fee;

    event TokenBought(
        address indexed from,
        address indexed to,
        uint256 indexed tokenID,
        uint256 price
    );

    constructor(
        address _token,
        uint256 _fee,
        address _registry
    ) {
        registry = IRegistry(_registry);
        token = IERC721(_token);
        fee = _fee;
    }

    function updateToken(address _token) external onlyOwner {
        token = IERC721(_token);
    }

    function updateMarketFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function updateRegistry(address _registry) external onlyOwner {
        registry = IRegistry(_registry);
    }

	// marketplace should have approve from token owner
    function putUpTokenForSale(uint256 tokenId, uint256 price)
        external
        onlyTokenOwner(tokenId)
    {
        registry.offerForSale(tokenId, price);
    }

    function updateTokenPrice(uint256 tokenId, uint256 price)
        external
        onlyTokenOwner(tokenId)
    {
        registry.changeTokenPrice(tokenId, price);
    }

    function removeTokenFromSale(uint256 tokenId)
        external
        onlyTokenOwner(tokenId)
    {
        registry.removeFromSale(tokenId);
    }

    function buyToken(uint256 tokenId) external payable {
        bool isForSale;
        uint256 price;
        uint256 royalty;
        address beneficiary;
        uint256 appFee;
        address appAddress;

        (isForSale, price, royalty, beneficiary, appFee, appAddress) = registry
            .getTokenSaleData(tokenId);

        require(isForSale == true, "Token is not for Sale!");
        require(msg.value == price, "Didn't send enough ETH");

        uint256 platformFee = price * fee / 100;
        uint256 royaltyFee = price * royalty / 100;
        uint256 applicationFee = price * appFee / 100;

        uint256 transferAmount =
            price - platformFee - royaltyFee - applicationFee;

        address tokenOwner = token.ownerOf(tokenId);

        payable(tokenOwner).transfer(transferAmount);

        if (platformFee > 0) {
            payable(owner()).transfer(platformFee);
        }
        if (royaltyFee > 0) {
            payable(beneficiary).transfer(royaltyFee);
        }
        if (applicationFee > 0) {
            payable(appAddress).transfer(applicationFee);
        }

		registry.markAsSold(tokenId);

        token.transferFrom(tokenOwner, msg.sender, tokenId);

        emit TokenBought(tokenOwner, msg.sender, tokenId, price);
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(
            token.ownerOf(tokenId) == msg.sender,
            "Only token owner can perform this action"
        );
        _;
    }
}