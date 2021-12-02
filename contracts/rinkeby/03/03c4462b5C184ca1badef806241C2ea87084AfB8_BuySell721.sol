pragma solidity ^0.8.1;

import "Ownable.sol";
import "IERC721.sol";
import "IERC20.sol";

contract BuySell721 is Ownable {
    enum PledgeStatus {
        DONE,
        PAID_OUT,
        REFUNDED
    }

    enum ItemStatus {
        FOR_SALE,
        SOLD,
        PURCHASE_APPROVED
    }

    struct Item {
        address contractAddress;
        uint256 tokenId;
        address paymentContract;
        uint256 price;
        uint256 pledgeAmount;
        uint256 pledge;
        address owner;
        ItemStatus status;
    }

    struct Pledge {
        uint256 item;
        address pledger;
        PledgeStatus status;
    }

    mapping(uint256 => Item) public itemForSaleStore;
    mapping(uint256 => Pledge) public pledgeStore;
    uint256 public itemSaleNumber;
    uint256 public pledgeNumber;

    event ItemForSale(uint256 item);
    event PledgeForItem(uint256 item, address pledger, PledgeStatus status);
    event ApprovePurchase(uint256 item, uint256 pledge, address pledger);
    event RefundPledge(uint256 pledge);
    event ApprovePurchase(uint256 item);
    event BuyItem(uint256 item);

    function itemForSale(
        address _contractAddress,
        uint256 _tokenId,
        address _paymentContract,
        uint256 _price,
        uint256 _pledgeAmount
    ) external {
        address _msgSender = msg.sender;
        IERC721 _nftContract = IERC721(_contractAddress);
        require(
            _nftContract.ownerOf(_tokenId) == _msgSender,
            "BuySell: looks like it's not your item"
        );
        require(
            _pledgeAmount < _price,
            "BuySell: price can't be less than pledge"
        );
        itemSaleNumber += 1;
        itemForSaleStore[itemSaleNumber] = Item({
            contractAddress: _contractAddress,
            tokenId: _tokenId,
            paymentContract: _paymentContract,
            price: _price,
            pledgeAmount: _pledgeAmount,
            pledge: 0,
            owner: _msgSender,
            status: ItemStatus.FOR_SALE
        });
        _nftContract.transferFrom(_msgSender, address(this), _tokenId);

        emit ItemForSale(itemSaleNumber);
    }

    function reserveItem(uint256 _itemId) external {
        address _msgSender = msg.sender;
        Item memory _itemForSale = itemForSaleStore[_itemId];
        if (_itemForSale.pledge != 0) {
            require(
                pledgeStore[_itemForSale.pledge].status ==
                    PledgeStatus.REFUNDED,
                "BuySell: this item is already reserved"
            );
        }
        IERC20 _pledgeContract = IERC20(_itemForSale.paymentContract);
        _pledgeContract.transferFrom(
            _msgSender,
            address(this),
            _itemForSale.pledgeAmount
        );
        pledgeNumber += 1;
        pledgeStore[pledgeNumber] = Pledge({
            item: _itemId,
            pledger: _msgSender,
            status: PledgeStatus.DONE
        });

        itemForSaleStore[_itemId].pledge = pledgeNumber;

        emit PledgeForItem(_itemId, _msgSender, PledgeStatus.DONE);
    }

    function refundPledge(uint256 _itemId) external {
        address _msgSender = msg.sender;
        Item memory _itemForSale = itemForSaleStore[_itemId];
        require(_itemForSale.pledge != 0, "BuySell: no pledge available");
        Pledge memory _pledge = pledgeStore[_itemForSale.pledge];

        require(
            _msgSender == _itemForSale.owner,
            "BuySell: It's not your item"
        );
        require(
            _pledge.status == PledgeStatus.DONE,
            "BuySell: you can't refund it"
        );
        IERC20 _pledgeContract = IERC20(_itemForSale.paymentContract);
        _pledgeContract.transferFrom(
            address(this),
            _msgSender,
            _itemForSale.pledgeAmount
        );
        pledgeStore[_itemForSale.pledge].status = PledgeStatus.REFUNDED;

        emit RefundPledge(_itemForSale.pledge);
    }

    function approvePurchase(uint256 _itemId) external {
        address _msgSender = msg.sender;
        Item memory _itemForSale = itemForSaleStore[_itemId];
        require(_itemForSale.pledge != 0, "BuySell: no pledge available");
        Pledge memory _pledge = pledgeStore[_itemForSale.pledge];
        require(
            _msgSender == _itemForSale.owner,
            "BuySell: It's not your item"
        );
        require(
            _pledge.status == PledgeStatus.DONE,
            "BuySell: you can't approve purchase to it"
        );

        itemForSaleStore[_itemId].status = ItemStatus.PURCHASE_APPROVED;

        emit ApprovePurchase(_itemId);
    }

    function buyItem(uint256 _itemId) external {
        address _msgSender = msg.sender;
        Item memory _itemForSale = itemForSaleStore[_itemId];
        Pledge memory _pledge = pledgeStore[_itemForSale.pledge];
        // check if sender is a pledger
        require(
            _pledge.pledger == _msgSender,
            "BuySell: this pledge isn't your"
        );
        // check if pledge is available
        require(
            _pledge.status == PledgeStatus.DONE,
            "BuySell: this pledge is inavailable"
        );

        IERC20(_itemForSale.paymentContract).transferFrom(
            _msgSender,
            address(this),
            _itemForSale.price - _itemForSale.pledgeAmount
        );
        IERC721(_itemForSale.contractAddress).safeTransferFrom(
            address(this),
            _msgSender,
            _itemForSale.tokenId
        );

        itemForSaleStore[_itemId].status = ItemStatus.SOLD;
        pledgeStore[_itemForSale.pledge].status = PledgeStatus.PAID_OUT;

        emit BuyItem(_itemId);
    }

    function cancelSale(uint256 _itemId) external {
        
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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

import "IERC165.sol";

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