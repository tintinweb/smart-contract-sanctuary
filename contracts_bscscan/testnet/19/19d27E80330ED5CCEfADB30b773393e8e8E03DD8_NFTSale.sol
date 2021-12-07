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

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTSale is Ownable { 
    mapping(IERC721Metadata => mapping(uint256 => SaleInfo)) public allTokenSale;

    uint32 public feeListing;
    uint32 public feeSale;
    uint32 public feeBuy;
    uint32 public feeDecimal = 8;

    struct SaleInfo {
        address owner;
        uint256 price;
        IERC20 contractERC20;
        bool exist;
    }

    event ListingPrice(address seller, uint256 tokenId, SaleInfo saleInfo);
    event Sold(address buyer, uint256 tokenId, IERC721Metadata contractSale);
    event Canceled(address seller, uint256 tokenId, IERC721Metadata contractSale);
    event Updated(address seller, uint256 tokenId, SaleInfo saleInfo);
    
    function SaleToken(uint256 _tokenId, IERC721Metadata _contractNFT, uint256 _price, IERC20 _contractERC20) public payable {
        require(_contractNFT.getApproved(_tokenId) == address(this));
        require(allTokenSale[_contractNFT][_tokenId].exist == false);

        if (feeListing > 0) {
            if (address(_contractERC20) != address(0)) {
                _contractERC20.transferFrom(msg.sender, owner(), (_price*feeListing)/feeDecimal);
            } else {
                (bool sent, ) = msg.sender.call{value: (_price*feeListing)/feeDecimal}("");
                require(sent, "Failed to send Ether");
            }
        }

        _contractNFT.transferFrom(msg.sender, address(this), _tokenId);
        
        SaleInfo memory saleInfo;

        saleInfo.exist = true;
        saleInfo.owner = msg.sender;
        saleInfo.price = _price;
        saleInfo.contractERC20 = _contractERC20;

        allTokenSale[_contractNFT][_tokenId] = saleInfo;
        
        emit ListingPrice(msg.sender, _tokenId, saleInfo);
    }

    function BuyToken(uint256 _tokenId, IERC721Metadata _contractNFT) public payable{
        require(allTokenSale[_contractNFT][_tokenId].exist == true);

        uint256 price = allTokenSale[_contractNFT][_tokenId].price;
        uint256 amountFeeBuy = (price * feeBuy)/ feeDecimal;
        uint256 amountFeeSale = (price * feeSale)/ feeDecimal;

        price = price - amountFeeSale;
        
        if (address(allTokenSale[_contractNFT][_tokenId].contractERC20) != address(0)) {
            allTokenSale[_contractNFT][_tokenId].contractERC20.transferFrom(msg.sender, allTokenSale[_contractNFT][_tokenId].owner, price);

            if (amountFeeBuy > 0) {
                allTokenSale[_contractNFT][_tokenId].contractERC20.transferFrom(msg.sender, owner(), amountFeeBuy);
            }
            if (amountFeeSale > 0) {
                allTokenSale[_contractNFT][_tokenId].contractERC20.transferFrom(msg.sender, owner(), amountFeeSale);
            }
        } else {
            (bool sent, ) = allTokenSale[_contractNFT][_tokenId].owner.call{value: price}("");
            require(sent, "Failed to send Ether");

            if (amountFeeBuy > 0) {
                (sent, ) = allTokenSale[_contractNFT][_tokenId].owner.call{value: amountFeeBuy}("");
                require(sent, "Failed to send Ether");
            }
            if (amountFeeSale > 0) {
                (sent, ) = allTokenSale[_contractNFT][_tokenId].owner.call{value: amountFeeSale}("");
                require(sent, "Failed to send Ether");
            }
        }
        
        _contractNFT.transferFrom(address(this), msg.sender, _tokenId);

        delete allTokenSale[_contractNFT][_tokenId];

        emit Sold(msg.sender, _tokenId, _contractNFT);
    }

    function CancelSaleToken(uint256 _tokenId, IERC721Metadata _contractNFT) public {
        require(allTokenSale[_contractNFT][_tokenId].exist == true);
        require(msg.sender == allTokenSale[_contractNFT][_tokenId].owner);
        
        _contractNFT.transferFrom(address(this), msg.sender, _tokenId);

        delete allTokenSale[_contractNFT][_tokenId];

        emit Canceled(msg.sender, _tokenId, _contractNFT);
    }

    function UpdatePrice(uint256 _tokenId, IERC721Metadata _contractNFT, uint256 _price, IERC20 _contractERC20) public {
        require(allTokenSale[_contractNFT][_tokenId].exist == true);
        require(msg.sender == allTokenSale[_contractNFT][_tokenId].owner);

        SaleInfo memory saleInfo = allTokenSale[_contractNFT][_tokenId];

        saleInfo.price = _price;
        saleInfo.contractERC20 = _contractERC20;
        
        allTokenSale[_contractNFT][_tokenId] = saleInfo;

        emit Updated(msg.sender, _tokenId, saleInfo);
    }

    function GetPrice(uint256 _tokenId, IERC721Metadata _contractNFT) public view returns (uint256) {
        return allTokenSale[_contractNFT][_tokenId].price;
    }

    function UpdateFeeListing(uint32 _feeListing) public onlyOwner() {
        require(_feeListing < 100*feeDecimal, "fee must lower than 100");
        feeListing = _feeListing;
    }

    function UpdateFeeSale(uint32 _feeSale) public onlyOwner() {
        require(_feeSale < 100*feeDecimal, "fee must lower than 100");
        feeSale = _feeSale;
    }

    function UpdateFeeBuy(uint32 _feeBuy) public onlyOwner() {
        require(_feeBuy < 100*feeDecimal, "fee must lower than 100");
        feeBuy = _feeBuy;
    }
}