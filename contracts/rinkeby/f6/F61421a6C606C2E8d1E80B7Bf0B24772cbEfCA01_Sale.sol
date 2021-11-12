// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./RoyaltyDistribution.sol";


interface IRoyaltyDistributor {
    function distributeRoyalty(address mainReceiver, uint256 authorPoints) external payable;
    function distributeRoyaltyWrapped(address mainReceiver, uint256 authorPoints, uint256 amount) external;
}

interface IOpenSpace is IERC721 {
    function getAuthorAddressAndPointsByToken(uint256 tokenId) external view returns (address,uint256);
}


abstract contract OpenSpaceImplementation is Ownable  {
    IOpenSpace public OpenSpace;

    modifier onlyTokenOwner(uint256 tokenId) {
        address tokenOwner = OpenSpace.ownerOf(tokenId);
        if (tokenOwner == address(this)) {
            require(owner() == _msgSender(),"Access denied");
        } else {
            require(tokenOwner == _msgSender(), "Access denied");
        }
        _;
    }

    function updateOpenSpace(address openSpace) external onlyOwner {
        emit UpdateOpenSpace(address(OpenSpace), openSpace);
        OpenSpace = IOpenSpace(openSpace);
    }

    // EVENTS
    event UpdateOpenSpace(address oldAddress, address newAddress);

}

abstract contract Operators is OpenSpaceImplementation {

    address auctionOperator;

    modifier onlyAuctionOperator() {
        require(auctionOperator == _msgSender(), "Ownable: caller is not the auction operator");
        _;
    }

    constructor() {
        auctionOperator = _msgSender();
    }

    function transferAuctionOperator(address newAuctionOperator) public onlyOwner {
        require(newAuctionOperator != address(0), "Ownable: new auction operator is the zero address");
        emit UpdateAuctionOperator(auctionOperator, newAuctionOperator);
        auctionOperator = newAuctionOperator;
    }

    event UpdateAuctionOperator(address oldAuctionOperator, address newAuctionOperator);
}

abstract contract NFTSale is Operators {
    enum Status {
        None,
        OnSale,
        OnAuction
    }
    struct SaleInfo {
        Status status;
        uint256 price;
    }

    // Mapping from token ID to sale info
    mapping(uint256 => SaleInfo) internal _saleInfo;
    uint256 public royaltyPercent = 80;
    uint256 DENOMINATOR = 1000;
    uint256 defaultAuthorPoints = 20;
    IRoyaltyDistributor royaltyDistributor;
    address public immutable WETH;
    uint256 public auctionProcessingFee = 0.01 ether;

    constructor(address _weth) {
        WETH = _weth;
    }

    function saleInfo(uint256 tokenId) public view returns(SaleInfo memory) {
        return _saleInfo[tokenId];
    }

    // onlyTokenOwner ---- start

    function addToAuction(uint256 tokenId, uint256 price) public payable onlyTokenOwner(tokenId) {
        require(msg.value >= auctionProcessingFee, "Insufficient amount");
        (bool success,) = payable(auctionOperator).call{value: msg.value}("");
        require(success, "Can't send funds to auction operator wallet");
        _addToAuction(tokenId, price);
    }

    function removeFromAuction(uint256 tokenId) public onlyAuctionOperator {
        _removeFromAuction(tokenId);
    }

    function addToSale(uint256 tokenId, uint256 price) public onlyTokenOwner(tokenId) {
        _addToSale(tokenId, price);
    }

    function removeFromSale(uint256 tokenId) public onlyTokenOwner(tokenId) {
        _removeFromSale(tokenId);
    }

    function updatePrice(uint256 tokenId, uint256 price) public onlyTokenOwner(tokenId) {
        emit UpdatePrice(_saleInfo[tokenId].price, price, tokenId);
        _saleInfo[tokenId].price = price;
    }

    // onlyTokenOwner ---- end

    // onlyOwner   ----- start
    function updateRoyaltyPercent(uint256 _newPercent) public onlyOwner {
        require(_newPercent < 100, "Should be less than 100!");
        emit RoyaltyUpdated(royaltyPercent, _newPercent);
        royaltyPercent = _newPercent;
    }

    function updateAuctionProcessingFee(uint256 _newFee) public onlyOwner {
        emit UpdateAuctionProcessingFee(auctionProcessingFee, _newFee);
        auctionProcessingFee = _newFee;
    }

    function updateRoyaltyDistributor(address _newAddress) public onlyOwner {
        emit RoyaltyDistributorUpdated(address(royaltyDistributor), _newAddress);
        royaltyDistributor = IRoyaltyDistributor(_newAddress);
    }
    // onlyOwner   ----- end

    function sendRoyalty(address authorAddress, uint256 authorPoints, uint256 amount) private {
        royaltyDistributor.distributeRoyalty{value: amount}(authorAddress, authorPoints);
    }

    function sendRoyaltyWrapped(address buyer, address authorAddress, uint256 authorPoints, uint256 amount) private {
        bool success = IERC20(WETH).transferFrom(buyer, address(royaltyDistributor), amount);
        require(success, 'Issue with transferring funds from buyer to royalty');
        royaltyDistributor.distributeRoyaltyWrapped(authorAddress, authorPoints, amount);
    }

    function _addToAuction(uint256 tokenId, uint256 price) internal {
        require(_saleInfo[tokenId].status != Status.OnAuction, "Already on auction");
        require(price > 0, "Sell price should be greater than zero");
        _saleInfo[tokenId] = SaleInfo(Status.OnAuction, price);
        emit AddToAuction(tokenId, price);
    }
    function _removeFromAuction(uint256 tokenId) internal {
        require(_saleInfo[tokenId].status == Status.OnAuction , "Token is not on auction");
        _saleInfo[tokenId].status = Status.None;
        emit RemoveFromAuction(tokenId);
    }

    function _addToSale(uint256 tokenId, uint256 price) internal {
        require(_saleInfo[tokenId].status == Status.None, "Already in sale or auction list");
        require(price > 0, "Sell price should be greater than zero");
        _saleInfo[tokenId] = SaleInfo(Status.OnSale, price);
        emit AddToSale(tokenId, price);
    }

    function _removeFromSale(uint256 tokenId) internal {
        require(_saleInfo[tokenId].status == Status.OnSale , "Token is not in sale list");
        _saleInfo[tokenId].status = Status.None;
        emit RemoveFromSale(tokenId);
    }


    function buyToken(uint256 tokenId) external payable {
        require(_saleInfo[tokenId].status != Status.None, "Token is not in sale and is not on auction");
        address seller = OpenSpace.ownerOf(tokenId);
        require(seller != _msgSender(), "Self buying");
        uint256 price = _saleInfo[tokenId].price;
        require(msg.value >= price, "Insufficient amount");

        (address authorAddress, uint256 authorPoints) = OpenSpace.getAuthorAddressAndPointsByToken(tokenId);
        if (seller == address(this)) {
            sendRoyalty(authorAddress, authorPoints, price); //change address to creator
            emit RoyaltySent(authorAddress, price);
        } else {
            uint256 royaltyFee = price * royaltyPercent / DENOMINATOR;
            uint256 clearedPrice = price - royaltyFee;
            sendRoyalty(authorAddress, authorPoints, royaltyFee); //change address to creator
            emit RoyaltySent(authorAddress, royaltyFee);

            (bool sent, ) = payable(seller).call{value: clearedPrice}("");
            require(sent, "Error: Cannot send payment");
        }
        OpenSpace.transferFrom(seller, _msgSender(), tokenId);
        _removeFromSale(tokenId);
        emit Sold(tokenId, price);
    }

    function processAuction(uint256 tokenId, address buyer, uint256 price) external onlyAuctionOperator {
        require(_saleInfo[tokenId].status == Status.OnAuction, "Token is not on auction");
        address seller = OpenSpace.ownerOf(tokenId);

        (address authorAddress, uint256 authorPoints) = OpenSpace.getAuthorAddressAndPointsByToken(tokenId);
        if (seller == address(this)) {
            sendRoyaltyWrapped(buyer, authorAddress, authorPoints, price);
            emit RoyaltySent(authorAddress, price);
        } else {
            uint256 royaltyFee = price * royaltyPercent / DENOMINATOR;
            uint256 clearedPrice = price - royaltyFee;
            sendRoyaltyWrapped(buyer, authorAddress, authorPoints, royaltyFee); //change address to creator
            emit RoyaltySent(authorAddress, royaltyFee);
            bool success = IERC20(WETH).transferFrom(buyer, seller, clearedPrice);
            require(success, 'Issue with transferring funds from buyer to seller');
        }
        OpenSpace.transferFrom(seller, buyer, tokenId);
        _removeFromSale(tokenId);
        emit Sold(tokenId, price);
    }

    //for tests
    function tokenOwner(uint256 tokenId) public view returns(address) {
        return OpenSpace.ownerOf(tokenId);
    }

    receive() external payable {}

    event AddToSale(uint256 tokenId, uint256 price);
    event RemoveFromSale(uint256 tokenId);
    event AddToAuction(uint256 tokenId, uint256 price);
    event RemoveFromAuction(uint256 tokenId);
    event UpdatePrice(uint256 oldValue, uint256 newValue, uint256 tokenId);
    event Sold(uint256 tokenId, uint256 price);
    event RoyaltyUpdated(uint256 oldValue,uint256 newValue);
    event RoyaltyDistributorUpdated(address oldAddress, address newAddress);
    event RoyaltySent(address royaltyAddress, uint256 amount);
    event UpdateAuctionProcessingFee(uint256 oldFee, uint256 newFee);

}

/**
 * @title Sale
 * Sale - a contract for sale support.
 */
contract Sale is NFTSale {

    constructor(address _weth) NFTSale(_weth) {}

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
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RoyaltyDistribution is Ownable {
    enum CurrencyType { Both, Eth, Weth }
    struct Currency {
        uint256 eth;
        uint256 weth;
    }
    mapping (address => uint256) receiversPoints;
    mapping (address => Currency) accumulatedBalances;
    address public immutable WETH;
    address public saleContract;
    uint256 public totalPartnersPoints;
    address[] public receivers;

    modifier onlySaleContract() {
        require(saleContract == _msgSender(), "Ownable: caller is not the sale contract");
        _;
    }
    constructor (address _saleContract, address _weth) {
        saleContract = _saleContract;
        WETH = _weth;
    }

    function getAccumulated(address receiver) external view returns(Currency memory){
        return accumulatedBalances[receiver];
    }

    function distributeRoyalty(address authorAddress, uint256 authorPoints) external payable {
        uint256 totalIncome = msg.value;
        uint256 distributed;
        uint256 totalPoints = totalPartnersPoints + authorPoints;
        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 share = totalIncome * receiversPoints[receivers[i]]/totalPoints;
            accumulatedBalances[receivers[i]].eth += share;
            distributed += share;
        }
        uint256 authorShare = totalIncome - distributed;
        accumulatedBalances[authorAddress].eth += authorShare;
    }

    function distributeRoyaltyWrapped(address authorAddress, uint256 authorPoints, uint256 amount) external onlySaleContract {
        uint256 distributed;
        uint256 totalPoints = totalPartnersPoints + authorPoints;

        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 share = amount * receiversPoints[receivers[i]]/totalPoints;
            accumulatedBalances[receivers[i]].weth += share;
            distributed += share;
        }

        uint256 authorShare = amount - distributed;
        accumulatedBalances[authorAddress].weth += authorShare;
    }

    function sendRoyalty(address royaltyHolder, CurrencyType ct) public onlyOwner {
      _sendRoyalty(royaltyHolder, royaltyHolder, ct);
    }

    function claimRoyalty(address receiver, CurrencyType ct) public {
        _sendRoyalty(msg.sender, receiver, ct);
    }

    function _sendRoyalty(address sender, address receiver, CurrencyType ct) internal {
        if (ct == CurrencyType.Both || ct == CurrencyType.Eth) {
            uint256 amount = accumulatedBalances[sender].eth;
            require(amount > 0);
            accumulatedBalances[sender].eth -= amount;
            (bool success,) = receiver.call{value: amount}("");
            require(success,'Cannot send ETH');
        }
        if (ct == CurrencyType.Both || ct == CurrencyType.Weth) {
            uint256 amount = accumulatedBalances[sender].weth;
            require(amount > 0);
            accumulatedBalances[sender].weth -= amount;
            bool success = IERC20(WETH).transfer(receiver, amount);
            require(success,'Cannot send WETH');
        }
    }

    function updateReceivers(address[] memory newReceivers, uint256[] memory points) external onlyOwner {
        require(newReceivers.length == points.length, 'different lengths');
        delete receivers;
        uint256 newSum;
        for (uint256 i = 0; i < newReceivers.length; i++) {
            receivers.push(newReceivers[i]);
            receiversPoints[newReceivers[i]] = points[i];
            newSum += points[i];
        }
        totalPartnersPoints = newSum;
    }


    function updateSaleContract(address newSale) external onlyOwner {
        saleContract = newSale;
    }

    receive() external payable {}
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