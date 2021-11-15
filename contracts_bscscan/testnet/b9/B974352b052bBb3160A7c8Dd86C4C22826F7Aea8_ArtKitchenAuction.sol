// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
//import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
//import '@openzeppelin/contracts/access/Ownable.sol';
//import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
//import './interfaces/IArtKitchen.sol';
//import './interfaces/IKitchenArts.sol';
//import './libs/SignatureVerifier.sol';
import './ArtKitchen.sol';

contract ArtKitchenAuction is ArtKitchen {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    /// Auction ids
    Counters.Counter private _auctionIds;

    // auctionId => Auction
    mapping (uint256 => Auction) private auctions;
    // auctionId => currentPrice
    mapping (uint256 => uint256) public currentPrices;
    // auctionId => bidder
    mapping (uint256 => address) public bidders;
    // auctionId => endBlock
    mapping (uint256 => uint256) public endBlocks;
    mapping (uint256 => bool) public hasClaimedNFTs;
    mapping (uint256 => bool) public hasClaimedSoldPrices;

    // tokenId => Status
    mapping (uint256 => Status) public statuses;

    uint256 public extendBlock;

    struct Auction {
        uint256 tokenId;
        uint256 startPrice;
        address seller;
    }

    enum Status {
        Listed,
        Auction,
        None
    }

    constructor(
        uint256 _creatorFeeMin,
        uint256 _creatorFeeRate,
        uint256 _commissionFeeMin,
        uint256 _commissionFeeRate,
        address _commissionAddress
    ) ArtKitchen(_creatorFeeMin, _creatorFeeRate, _commissionFeeMin, _commissionFeeRate, _commissionAddress) {
        uint256 minute = 20;
        extendBlock = minute.sub(5);
    }

    event NewAuction(address indexed seller, uint256 startPrice, uint256 endBlock);
    event Bidding(address indexed bidder, uint256 price, uint256 newEndBlock, uint256 auctionId);

    function getTokenIdFrom(uint256 _auctionId) internal view returns (uint256) {
        return auctions[_auctionId].tokenId;
    }

    function sellToAuction(uint256 _tokenId, uint256 _startPrice, uint256 _endBlock) external {
        IERC721 nft = IERC721(nftAddress);
        require(_msgSender() == nft.ownerOf(_tokenId), "Art Kitchen: Sender does not have token");
        require(_startPrice > minPrice, "Art Kitchen: Price is too low");
        require(statuses[_tokenId] == Status.None, "Art Kitchen: The item is already listed");
        uint256 _newId = _auctionIds.current();
        _auctionIds.increment();
        auctions[_newId] = Auction({
            tokenId: _tokenId,
            startPrice: _startPrice,
            seller: _msgSender()
        });
        statuses[_tokenId] = Status.Auction;
        currentPrices[_newId] = _startPrice;
        bidders[_newId] = address(0);
        endBlocks[_newId] = _endBlock;
        hasClaimedNFTs[_newId] = false;
        hasClaimedSoldPrices[_newId] = false;
        nft.safeTransferFrom(_msgSender(), address(this), _tokenId);
    }

    function bid(uint256 _auctionId) external payable {
        uint256 _tokenId = getTokenIdFrom(_auctionId);
        require(statuses[_tokenId] == Status.Auction, "Art Kitchen: The item is not listed");
        require(block.number < endBlocks[_auctionId], "Art Kitchen: This auction has been closed");
        require(msg.value > currentPrices[_auctionId], "Art Kitchen: The amount is insufficient");

        uint256 _beforePrice = currentPrices[_auctionId];
        address payable _beforeBidder = payable(bidders[_auctionId]);
        currentPrices[_auctionId] = msg.value;
        bidders[_auctionId] = _msgSender();

        if (_beforeBidder != address(0)) {
            _beforeBidder.transfer(_beforePrice);
        }
        if (extendBlock.add(block.number) > endBlocks[_auctionId]) {
            endBlocks[_auctionId] = extendBlock.add(block.number);
        }

        emit Bidding(_msgSender(), msg.value, endBlocks[_auctionId], _auctionId);
    }

    function claimNFTFromAuction(uint256 _auctionId) external {
        uint256 _tokenId = getTokenIdFrom(_auctionId);
        require(statuses[_tokenId] == Status.Auction, "Art Kitchen: The item is not listed");
        require(block.number > endBlocks[_auctionId], "Art Kitchen: This auction is still open");
        require(bidders[_auctionId] == _msgSender(), "Art Kitchen: Sender is not bidder");
        require(hasClaimedNFTs[_auctionId] == false, "Art Kitchen: Already claimed");

        IERC721 nft = IERC721(nftAddress);
        nft.safeTransferFrom(address(this), _msgSender(), _tokenId);
        hasClaimedNFTs[_auctionId] = true;
        // TODO: event
    }

    function claimSoldPrice(uint256 _auctionId) external {
        uint256 _tokenId = getTokenIdFrom(_auctionId);
        require(statuses[_tokenId] == Status.Auction, "Art Kitchen: The item is not listed");
        require(block.number > endBlocks[_auctionId], "Art Kitchen: This auction is still open");
        require(bidders[_auctionId] != address(0), "Art Kitchen: This auction was not bid on");
        require(auctions[_auctionId].seller == _msgSender(), "Art Kitchen: Sender is not the seller");
        require(hasClaimedSoldPrices[_auctionId] == false, "Art Kitchen: Already claimed");

        // calc fee
        (uint256 _commissionValue, uint256 _creatorFeeValue, uint256 _sellerValue) = _calcFeeValues(currentPrices[_auctionId]);

        address payable _seller = payable(auctions[_auctionId].seller);
        address payable _creator = payable(arts[_tokenId].creator);
        address payable _commission = payable(commissionAddress);
        _seller.transfer(_sellerValue);
        _creator.transfer(_creatorFeeValue);
        _commission.transfer(_commissionValue);

        hasClaimedSoldPrices[_auctionId] = true;
        // TODO: event
    }

    function withdrawFromAuction(uint256 _auctionId) external {
        uint256 _tokenId = getTokenIdFrom(_auctionId);
        require(statuses[_tokenId] == Status.Auction, "Art Kitchen: The item is not listed");
        require(block.number > endBlocks[_auctionId], "Art Kitchen: This auction is still open");
        require(bidders[_auctionId] == address(0), "Art Kitchen: This auction has been bid on");
        require(auctions[_auctionId].seller == _msgSender(), "Art Kitchen: Sender is not the seller");

        statuses[_tokenId] = Status.None;
        IERC721 nft = IERC721(nftAddress);
        nft.safeTransferFrom(address(this), _msgSender(), _tokenId);

        emit Withdrawal(_msgSender(), _tokenId);
    }
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

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './interfaces/IArtKitchen.sol';
import './interfaces/IKitchenArts.sol';
import './libs/SignatureVerifier.sol';

contract ArtKitchen is ERC721Holder, Ownable, AccessControl, SignatureVerifier, IArtKitchen {
    using SafeMath for uint256;

    address public nftAddress;

    address public commissionAddress;

    /// Minimum value of price
    uint256 public minPrice;

    /// Minimum value of creator fee
    uint256 public creatorFeeMin;

    /// Minimum value of commission fee
    uint256 public commissionFeeMin;

    /// Rate of creator fee
    /// 100 -> 1%
    uint256 public creatorFeeRate;

    /// Rate of commission fee
    /// 100 -> 1%
    uint256 public commissionFeeRate;

    /// NFT info mapping
//    mapping (uint256 => Item) private items;
    mapping (uint256 => Item) internal items;

    /// Listing info mapping
//    mapping (uint256 => Art) private arts;
    mapping (uint256 => Art) internal arts;

    /// Struct of NFT info
    struct Item {
        bool listed;
        address seller;
        uint256 price;
    }
    /// Struct of listing info
    struct Art {
        string itemName;
        address creator;
        string tokenURI;
    }

    constructor(
        uint256 _creatorFeeMin,
        uint256 _creatorFeeRate,
        uint256 _commissionFeeMin,
        uint256 _commissionFeeRate,
        address _commissionAddress
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        creatorFeeMin = _creatorFeeMin;
        creatorFeeRate = _creatorFeeRate;
        commissionFeeMin = _commissionFeeMin;
        commissionFeeRate = _commissionFeeRate;
        commissionAddress = _commissionAddress;
        minPrice = commissionFeeMin.add(creatorFeeMin).sub(2);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Art Kitchen: Not admin");
        _;
    }

    /**
     * @dev Set the nft contract address. Admin only.
     */
    function setNftAddress(address _address) external virtual onlyAdmin {
        require(
            IERC721(_address).supportsInterface(0x80ac58cd),
            "Not ERC721"
        );
        nftAddress = _address;
    }

    /**
     * @dev Set the minimum price. Admin only.
     */
    function setMinPrice(uint256 _minPrice) external virtual onlyAdmin {
        require(_minPrice > commissionFeeMin.add(creatorFeeMin), "Art Kitchen: Minimum price is lower than the minimum fee");
        minPrice = _minPrice;
    }

    /**
     * @dev Set the minimum value of creator fee. Admin only.
     */
    function setCreatorFeeMin(uint256 _minValue) external virtual onlyAdmin {
        creatorFeeMin = _minValue;
    }

    /**
     * @dev Set the rate of creator fee. Admin only.
     */
    function setCreatorFeeRate(uint256 _rate) external virtual onlyAdmin {
        creatorFeeRate = _rate;
    }

    /**
     * @dev Set the minimum value of commission fee. Admin only.
     */
    function setCommissionFeeMin(uint256 _minValue) external virtual onlyAdmin {
        commissionFeeMin = _minValue;
    }

    /**
     * @dev Set the rate of commission fee. Admin only.
     */
    function setCommissionFeeRate(uint256 _rate) external virtual onlyAdmin {
        commissionFeeRate = _rate;
    }

    /**
     * @dev Set the commission address. Admin only.
     */
    function setCommissionAddress(address _address) external virtual onlyAdmin {
        commissionAddress = _address;
    }

    /**
     * @dev Get listed for a specific tokenId.
     */
    function listed(uint256 _tokenId) external view virtual override returns (bool) {
        return items[_tokenId].listed;
    }

    function ownerOf(uint256 _tokenId) external view virtual returns (address) {
        IERC721 nft = IERC721(nftAddress);
        return nft.ownerOf(_tokenId);
    }

    /**
     * @dev Get creator address for a specific tokenId.
     */
    function creatorOf(uint256 _tokenId) external view virtual override returns (address) {
        address creator = arts[_tokenId].creator;
        require(creator != address(0), "Art Kitchen: creator is not set");
        return creator;
    }

    /**
     * @dev Get seller address for a specific tokenId.
     */
    function sellerOf(uint256 _tokenId) external view virtual override returns (address) {
        address seller = items[_tokenId].seller;
        require(seller != address(0), "Art Kitchen: seller is not set");
        return seller;
    }

    /**
     * @dev Get price for a specific tokenId.
     */
    function priceOf(uint256 _tokenId) external view virtual override returns (uint256) {
        return items[_tokenId].price;
    }

    /**
     * @dev Get ItemName for a specific tokenId.
     */
    function getItemName(uint256 _tokenId) external view virtual override returns (string memory) {
        return arts[_tokenId].itemName;
    }

    /**
     * @dev Mint NFTs and automatically list your item.
     */
    function create(
        string calldata _itemName,
        string calldata _tokenURI,
        uint256 _price
    ) external override returns (uint256) {
        require(bytes(_itemName).length > 0, "Art Kitchen: Item name cannot be empty");
        require(bytes(_tokenURI).length > 0, "Art Kitchen: Token URI cannot be empty");
        require(_price > minPrice, "Art Kitchen: Price is too low");

        IKitchenArts nft = IKitchenArts(nftAddress);
        uint256 newId = nft.mint(address(this), _itemName, _tokenURI);
        arts[newId] = Art({ itemName: _itemName, creator: _msgSender(), tokenURI: _tokenURI });
        items[newId] = Item({ listed: true, seller: _msgSender(), price: _price });

        emit Create(_msgSender(), _price, newId, _itemName, _tokenURI);

        return newId;
    }

    /**
     * @dev List your item. transfers token from sender to this.
     */
    function _sell(uint256 _tokenId, uint256 _price) internal virtual {
        Item memory item = items[_tokenId];
        IERC721 nft = IERC721(nftAddress);
        require(_msgSender() == nft.ownerOf(_tokenId), "Art Kitchen: Sender does not have token");
        require(_price > minPrice, "Art Kitchen: Price is too low");
        require(item.listed == false, "Art Kitchen: The item is already listed");
        items[_tokenId] = Item({ listed: true, seller: _msgSender(), price: _price });
        nft.safeTransferFrom(_msgSender(), address(this), _tokenId);
    }

    /**
     * @dev List your item.
     */
    function sell(uint256 _tokenId, uint256 _price) external override {
        _sell(_tokenId, _price);

        emit Listing(_msgSender(), _price, _tokenId);
    }

    /**
     * @dev Buy tokens on the market.
     */
    function buy(uint256 _tokenId, string calldata _msg, bytes memory signature) external override payable {
        bytes32 _message = _prefixed(keccak256(abi.encodePacked(_msg)));
        require(_recoverSigner(_message, signature) == _msgSender(), 'Art Kitchen: Invalid signature');

        Item memory _item = items[_tokenId];
//        require(_exists(_tokenId), "Art Kitchen: wrong tokenId");
        IERC721 nft = IERC721(nftAddress);
        require(_item.listed, "Art Kitchen: Item is not listed");
        require(msg.value >= _item.price, "Art Kitchen: The amount is lower");
        require(nft.ownerOf(_tokenId) == address(this), "Art Kitchen: Item is not deposited");

        _buy(_tokenId);

        emit Purchase(_item.seller, _msgSender(), _item.price, _tokenId);
    }

    function _calcFeeValues(uint256 _price) internal view returns (uint256, uint256, uint256) {
        uint256 _percentValue = 10000;
        uint256 _commissionValue = _price.div(_percentValue.div(commissionFeeRate));
        if (_commissionValue < commissionFeeMin) {
            _commissionValue = commissionFeeMin;
        }
        uint256 _creatorFeeValue = _price.div(_percentValue.div(creatorFeeRate));
        if (_creatorFeeValue < creatorFeeMin) {
            _creatorFeeValue = creatorFeeMin;
        }
        require(_commissionValue + _creatorFeeValue < _price, "Art Kitchen: Item price is lower");

        uint256 _sellerValue = _price.sub(_commissionValue.add(_creatorFeeValue));
        return (_commissionValue, _creatorFeeValue, _sellerValue);
    }

    /**
     * @dev Sender pays BNB to get token.
     *      Creators and the commission address earn commission based on price and rate of fee.
     */
    function _buy(uint256 _tokenId) internal {
        IERC721 nft = IERC721(nftAddress);

//        uint256 _percentValue = 10000;
//        uint256 _commissionValue = items[_tokenId].price.div(_percentValue.div(commissionFeeRate));
//        if (_commissionValue < commissionFeeMin) {
//            _commissionValue = commissionFeeMin;
//        }
//        uint256 _creatorFeeValue = items[_tokenId].price.div(_percentValue.div(creatorFeeRate));
//        if (_creatorFeeValue < creatorFeeMin) {
//            _creatorFeeValue = creatorFeeMin;
//        }
//        require(_commissionValue + _creatorFeeValue < items[_tokenId].price, "Art Kitchen: Item price is lower");
//
//        uint256 _sellerValue = items[_tokenId].price.sub(_commissionValue.add(_creatorFeeValue));
        (uint256 _commissionValue, uint256 _creatorFeeValue, uint256 _sellerValue) = _calcFeeValues(items[_tokenId].price);

        // transfer
        address payable _seller = payable(items[_tokenId].seller);
        address payable _buyer = payable(_msgSender());
        address payable _creator = payable(arts[_tokenId].creator);
        address payable _commission = payable(commissionAddress);

        nft.safeTransferFrom(address(this), _buyer, _tokenId);
        _seller.transfer(_sellerValue);
        _commission.transfer(_commissionValue);
        _creator.transfer(_creatorFeeValue);

        // If buyer sent more than price, we send them back their rest of funds
        if (msg.value > items[_tokenId].price) {
            _buyer.transfer(msg.value.sub(items[_tokenId].price));
        }

        items[_tokenId].listed = false;
        items[_tokenId].price = 0;
    }

    /**
     * @dev Withdraw the token.
     */
    function withdrawNFT(uint256 _tokenId) external override {
        Item memory item = items[_tokenId];
        require(item.listed == true, "Art Kitchen: The item is not listed");
        require(_msgSender() == item.seller, "Art Kitchen: Sender is not the seller");

        IERC721 nft = IERC721(nftAddress);
        nft.safeTransferFrom(address(this), _msgSender(), _tokenId);

        items[_tokenId].listed = false;
        items[_tokenId].price = 0;

        emit Withdrawal(_msgSender(), _tokenId);
    }

    /**
     * @dev Update the price of the token.
     */
    function updatePrice(uint256 _tokenId, uint256 _price) external override {
        Item memory _oldItem = items[_tokenId];
        require(_oldItem.listed == true, "Art Kitchen: The item is not listed");
        require(_msgSender() == _oldItem.seller, "Art Kitchen: Sender is not the seller");
        require(_price > minPrice, "Art Kitchen: Price is too low");

        items[_tokenId].price = _price;

        emit UpdatePrice(_msgSender(), _oldItem.price, _price, _tokenId);
    }

    /**
     * @dev Change owner of NFT Contract. Only the admin can call it.
     */
    function transferContractOwner(address _newOwner) external onlyOwner {
        transferOwnership(_newOwner);
    }

    /**
     * @dev Burn NFTs. Delete from this contract and NFT contract.
     */
    function burn(uint256 _tokenId) external override {
        IERC721 nft = IERC721(nftAddress);
        require(_msgSender() == nft.ownerOf(_tokenId), "Art Kitchen: Burn caller is not owner");
        require(_msgSender() == arts[_tokenId].creator, "Art Kitchen: Burn caller is not creator");
        require(items[_tokenId].listed == false, "Art Kitchen: NFT on sale");

        IKitchenArts kitchenArts = IKitchenArts(nftAddress);
        kitchenArts.burn(_tokenId, _msgSender());

        delete items[_tokenId];
        delete arts[_tokenId];

        emit Burn(_msgSender(), _tokenId);
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

import "../IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers.
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArtKitchen {

    event Purchase(address indexed seller, address indexed buyer, uint256 price, uint256 tokenId);

    event Create(address indexed creator, uint256 price, uint256 tokenId, string itemName, string tokenURI);

    event UpdatePrice(address indexed seller, uint256 oldPrice, uint256 newPrice, uint256 tokenId);

    event Withdrawal(address indexed seller, uint256 tokenId);

    event Listing(address indexed seller, uint256 price, uint256 tokenId);

    event Burn(address indexed creator, uint256 tokenId);

    /**
     * @dev Get ItemName for a specific tokenId.
     *
     * Requirements:
     *
     * - `_tokenId` must exist.
     */
    function getItemName(uint256 _tokenId) external view returns (string memory);

    /**
     * @dev Get listed for a specific tokenId.
     *
     * Requirements:
     *
     * - `_tokenId` must exist.
     */
    function listed(uint256 _tokenId) external view returns (bool);

    /**
     * @dev Get price for a specific tokenId.
     *
     * Requirements:
     *
     * - `_tokenId` must exist.
     */
    function priceOf(uint256 _tokenId) external view returns (uint256);

    /**
     * @dev Returns the creator for a specific `tokenId`.
     *
     * Requirements:
     *
     * - `_tokenId` must exist.
     */
    function creatorOf(uint256 _tokenId) external view returns (address);

    /**
     * @dev Returns the seller for a specific `tokenId`.
     *
     * Requirements:
     *
     * - `_tokenId` must exist.
     */
    function sellerOf(uint256 _tokenId) external view returns (address);

    /**
     * @dev Mint NFTs.
     *
     * Requirements:
     *
     * - `_itemName` cannot be empty.
     * - `_tokenURI` cannot be empty.
     * - `_price` cannot be less than minimum price.
     */
    function create(string calldata _itemName, string calldata _tokenURI, uint256 _price) external returns (uint256);

    /**
     * @dev List your NFT. Transfers NFT from sender to this contract.
     *
     * Requirements:
     *
     * - `_tokenId` must not exist.
     * - `_price` cannot be less than minimum price.
     */
    function sell(uint256 _tokenId, uint256 _price) external;

    /**
     * @dev Buy NFTs on the market.
     *
     * Requirements:
     *
     * - `_tokenId` must not exist.
     * - `_msg` cannot be empty.
     * - `_signature` cannot be empty.
     */
    function buy(uint256 _tokenId, string calldata _msg, bytes memory signature) external payable;

    /**
     * @dev Withdraw NFTs.
     *
     * Requirements:
     *
     * - `_tokenId` must not exist.
     */
    function withdrawNFT(uint256 _tokenId) external;

    /**
     * @dev Update the price of the NFT.
     *
     * Requirements:
     *
     * - `_tokenId` must not exist.
     * - `_price` cannot be less than minimum price.
     */
    function updatePrice(uint256 _tokenId, uint256 _price) external;

    /**
     * @dev Burn NFTs.
     *
     * Requirements:
     *
     * - `_tokenId` must not exist.
     */
    function burn(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IKitchenArts {

    event Mint(address indexed to, string artName, string tokenURI);

    /**
     * @dev Get art name for a specific tokenId.
     *
     * Requirements:
     *
     * - `_tokenId` must exist.
     */
    function getArtName(uint256 _tokenId) external view returns (string memory);

    /**
     * @dev Mint NFTs.
     *
     * Requirements:
     *
     * - `_to` cannot be the zero address.
     * - `_itemName` cannot be empty.
     * - `_tokenURI` cannot be empty.
     */
    function mint(address _to, string calldata _itemName, string calldata _tokenURI) external returns (uint256);

    /**
     * @dev Burn NFTs.
     *
     * Requirements:
     *
     * - `_tokenId` must exist.
     * - `_caller` must owner of token.
     */
    function burn(uint256 _tokenId, address _caller) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract SignatureVerifier {
    /// signature methods.
    function _splitSignature(bytes memory sig)
    internal
    pure
    returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
        // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
        // second 32 bytes.
            s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function _recoverSigner(bytes32 message, bytes memory sig)
    internal
    pure
    returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function _prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

