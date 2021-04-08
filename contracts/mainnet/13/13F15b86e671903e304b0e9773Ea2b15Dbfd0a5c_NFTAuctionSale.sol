// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract NFTAuctionSale is Ownable {
    using SafeMath for uint256;

    event NewAuctionItemCreated(uint256 auctionId);
    event EmergencyStarted();
    event EmergencyStopped();
    event BidPlaced(
        uint256 auctionId,
        address paymentTokenAddress,
        uint256 bidId,
        address addr,
        uint256 bidPrice,
        uint256 timestamp,
        address transaction
    );
    event BidReplaced(
        uint256 auctionId,
        address paymentTokenAddress,
        uint256 bidId,
        address addr,
        uint256 bidPrice,
        uint256 timestamp,
        address transaction
    );

    event RewardClaimed(address addr, uint256 auctionId, uint256 tokenCount);
    event BidIncreased(
        uint256 auctionId,
        address paymentTokenAddress,
        uint256 bidId,
        address addr,
        uint256 bidPrice,
        uint256 timestamp,
        address transaction
    );

    struct AuctionProgress {
        uint256 currentPrice;
        address bidder;
    }

    struct AuctionInfo {
        uint256 startTime;
        uint256 endTime;
        uint256 totalSupply;
        uint256 startPrice;
        address paymentTokenAddress; // ERC20
        address auctionItemAddress; // ERC1155
        uint256 auctionItemTokenId;
    }

    address public salesPerson = address(0);

    bool private emergencyStop = false;

    mapping(uint256 => AuctionInfo) private auctions;
    mapping(uint256 => mapping(uint256 => AuctionProgress)) private bids;
    mapping(uint256 => mapping(address => uint256)) private currentBids;

    uint256 public totalAuctionCount = 0;

    constructor() public {}

    modifier onlySalesPerson {
        require(
            _msgSender() == salesPerson,
            "Only salesPerson can call this function"
        );
        _;
    }

    function setSalesPerson(address _salesPerson) external onlyOwner {
        salesPerson = _salesPerson;
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function getBatchAuctions(uint256 fromId)
        external
        view
        returns (AuctionInfo[] memory)
    {
        require(fromId <= totalAuctionCount, "Invalid auction id");
        AuctionInfo[] memory currentAuctions =
            new AuctionInfo[](totalAuctionCount - fromId + 1);
        for (uint256 i = fromId; i <= totalAuctionCount; i++) {
            AuctionInfo storage auction = auctions[i];
            currentAuctions[i - fromId] = auction;
        }
        return currentAuctions;
    }

    function getBids(uint256 auctionId)
        external
        view
        returns (AuctionProgress[] memory)
    {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        AuctionInfo storage auction = auctions[auctionId];
        AuctionProgress[] memory lBids =
            new AuctionProgress[](auction.totalSupply);
        mapping(uint256 => AuctionProgress) storage auctionBids =
            bids[auctionId];
        for (uint256 i = 0; i < auction.totalSupply; i++) {
            AuctionProgress storage lBid = auctionBids[i];
            lBids[i] = lBid;
        }
        return lBids;
    }

    /// @notice Get max bid price in the specified auction
    /// @param auctionId Auction Id
    /// @return the max bid price
    function getMaxPrice(uint256 auctionId) public view returns (uint256) {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        AuctionInfo storage auction = auctions[auctionId];
        mapping(uint256 => AuctionProgress) storage auctionBids =
            bids[auctionId];

        uint256 maxPrice = auctionBids[0].currentPrice;
        for (uint256 i = 1; i < auction.totalSupply; i++) {
            maxPrice = max(maxPrice, auctionBids[i].currentPrice);
        }

        return maxPrice;
    }

    /// @notice Get min bid price in the specified auction
    /// @param auctionId Auction Id
    /// @return the min bid price
    function getMinPrice(uint256 auctionId) public view returns (uint256) {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        AuctionInfo storage auction = auctions[auctionId];
        mapping(uint256 => AuctionProgress) storage auctionBids =
            bids[auctionId];

        uint256 minPrice = auctionBids[0].currentPrice;
        for (uint256 i = 1; i < auction.totalSupply; i++) {
            minPrice = min(minPrice, auctionBids[i].currentPrice);
        }

        return minPrice;
    }

    /// @notice Transfers ERC20 tokens holding in contract to the contract owner
    /// @param tokenAddr ERC20 token address
    function transferERC20(address tokenAddr) external onlySalesPerson {
        IERC20 erc20 = IERC20(tokenAddr);
        erc20.transfer(_msgSender(), erc20.balanceOf(address(this)));
    }

    /// @notice Transfers ETH holding in contract to the contract owner
    function transferETH() external onlySalesPerson {
        _msgSender().transfer(address(this).balance);
    }

    /// @notice Create auction with specific parameters
    /// @param paymentTokenAddress ERC20 token address the bidders will pay
    /// @param paymentTokenAddress ERC1155 token address for the auction
    /// @param auctionItemTokenId Token ID of NFT
    /// @param totalSupply ERC20 token address
    /// @param startPrice Bid starting price
    /// @param startTime Auction starting time
    /// @param endTime Auction ending time
    function createAuction(
        address paymentTokenAddress,
        address auctionItemAddress,
        uint256 auctionItemTokenId,
        uint256 startPrice,
        uint256 totalSupply,
        uint256 startTime,
        uint256 endTime
    ) external onlyOwner {
        require(
            salesPerson != address(0),
            "Salesperson address should be valid"
        );
        require(emergencyStop == false, "Emergency stopped");
        require(totalSupply > 0, "Total supply should be greater than 0");
        IERC1155 auctionToken = IERC1155(auctionItemAddress);

        // check if the input address is ERC1155
        require(
            auctionToken.supportsInterface(0xd9b67a26),
            "Auction token is not ERC1155"
        );

        // check NFT balance
        require(
            auctionToken.balanceOf(salesPerson, auctionItemTokenId) >=
                totalSupply,
            "NFT balance not sufficient"
        );

        // check allowance
        require(
            auctionToken.isApprovedForAll(salesPerson, address(this)),
            "Auction token from sales person has no allowance for this contract"
        );

        // Init auction struct

        // increment auction index and push
        totalAuctionCount = totalAuctionCount.add(1);
        auctions[totalAuctionCount] = AuctionInfo(
            startTime,
            endTime,
            totalSupply,
            startPrice,
            paymentTokenAddress,
            auctionItemAddress,
            auctionItemTokenId
        );

        // emit event
        emit NewAuctionItemCreated(totalAuctionCount);
    }

    /// @notice Claim auction reward tokens to the caller
    /// @param auctionId Auction Id
    function claimReward(uint256 auctionId) external {
        require(emergencyStop == false, "Emergency stopped");
        require(auctionId <= totalAuctionCount, "Auction id is invalid");

        require(
            auctions[auctionId].endTime <= block.timestamp,
            "Auction is not ended yet"
        );

        mapping(address => uint256) storage auctionCurrentBids =
            currentBids[auctionId];
        uint256 totalWon = auctionCurrentBids[_msgSender()];

        require(totalWon > 0, "Nothing to claim");

        auctionCurrentBids[_msgSender()] = 0;

        IERC1155(auctions[auctionId].auctionItemAddress).safeTransferFrom(
            salesPerson,
            _msgSender(),
            auctions[auctionId].auctionItemTokenId,
            totalWon,
            ""
        );

        emit RewardClaimed(_msgSender(), auctionId, totalWon);
    }

    /// @notice Increase the caller's bid price
    /// @param auctionId Auction Id
    function increaseMyBidETH(uint256 auctionId) external payable {
        require(emergencyStop == false, "Emergency stopped");
        require(auctionId <= totalAuctionCount, "Auction id is invalid");
        require(msg.value > 0, "Wrong amount");
        require(
            block.timestamp < auctions[auctionId].endTime,
            "Auction is ended"
        );

        AuctionInfo storage auction = auctions[auctionId];

        require(
            auction.paymentTokenAddress == address(0),
            "Cannot use ETH in this auction"
        );

        uint256 count = currentBids[auctionId][_msgSender()];
        require(count > 0, "Not in current bids");

        mapping(uint256 => AuctionProgress) storage auctionBids =
            bids[auctionId];

        // Iterate currentBids and increment currentPrice
        for (uint256 i = 0; i < auction.totalSupply; i++) {
            AuctionProgress storage progress = auctionBids[i];
            if (progress.bidder == _msgSender()) {
                progress.currentPrice = progress.currentPrice.add(msg.value);
                emit BidIncreased(
                    auctionId,
                    auction.paymentTokenAddress,
                    i,
                    _msgSender(),
                    progress.currentPrice,
                    block.timestamp,
                    tx.origin
                );
            }
        }
    }

    /// @notice Place bid on auction with the specified price with ETH
    /// @param auctionId Auction Id
    function makeBidETH(uint256 auctionId)
        external
        payable
        isBidAvailable(auctionId)
    {
        uint256 minIndex = 0;
        uint256 minPrice = getMinPrice(auctionId);

        AuctionInfo storage auction = auctions[auctionId];
        require(
            auction.paymentTokenAddress == address(0),
            "Cannot use ETH in this auction"
        );
        require(
            msg.value >= auction.startPrice && msg.value > minPrice,
            "Cannot place bid at low price"
        );

        mapping(address => uint256) storage auctionCurrentBids =
            currentBids[auctionId];
        require(
            auctionCurrentBids[_msgSender()] < 1,
            "Max bid per wallet exceeded"
        );

        mapping(uint256 => AuctionProgress) storage auctionBids =
            bids[auctionId];

        for (uint256 i = 0; i < auction.totalSupply; i++) {
            // Just place the bid if remaining
            if (auctionBids[i].currentPrice == 0) {
                minIndex = i;
                break;
            } else if (auctionBids[i].currentPrice == minPrice) {
                // Get last minimum price bidder
                minIndex = i;
            }
        }

        if (auctionBids[minIndex].currentPrice != 0) {
            // return previous bidders tokens
            (bool sent, bytes memory data) =
                address(auctionBids[minIndex].bidder).call{
                    value: auctionBids[minIndex].currentPrice
                }("");
            require(sent, "Failed to send Ether");

            auctionCurrentBids[auctionBids[minIndex].bidder]--;

            emit BidReplaced(
                auctionId,
                auction.paymentTokenAddress,
                minIndex,
                auctionBids[minIndex].bidder,
                auctionBids[minIndex].currentPrice,
                block.timestamp,
                tx.origin
            );
        }

        auctionBids[minIndex].currentPrice = msg.value;
        auctionBids[minIndex].bidder = _msgSender();

        auctionCurrentBids[_msgSender()] = auctionCurrentBids[_msgSender()].add(
            1
        );

        emit BidPlaced(
            auctionId,
            auction.paymentTokenAddress,
            minIndex,
            _msgSender(),
            msg.value,
            block.timestamp,
            tx.origin
        );
    }

    /// @notice Increase the caller's bid price
    /// @param auctionId Auction Id
    /// @param increaseAmount The incrementing price than the original bid
    function increaseMyBid(uint256 auctionId, uint256 increaseAmount) external {
        require(emergencyStop == false, "Emergency stopped");
        require(auctionId <= totalAuctionCount, "Auction id is invalid");
        require(increaseAmount > 0, "Wrong amount");
        require(
            block.timestamp < auctions[auctionId].endTime,
            "Auction is ended"
        );

        AuctionInfo storage auction = auctions[auctionId];

        require(auction.paymentTokenAddress != address(0), "Wrong function");

        uint256 count = currentBids[auctionId][_msgSender()];
        require(count > 0, "Not in current bids");

        IERC20(auction.paymentTokenAddress).transferFrom(
            _msgSender(),
            address(this),
            increaseAmount * count
        );

        mapping(uint256 => AuctionProgress) storage auctionBids =
            bids[auctionId];

        // Iterate currentBids and increment currentPrice
        for (uint256 i = 0; i < auction.totalSupply; i++) {
            AuctionProgress storage progress = auctionBids[i];
            if (progress.bidder == _msgSender()) {
                progress.currentPrice = progress.currentPrice.add(
                    increaseAmount
                );
                emit BidIncreased(
                    auctionId,
                    auction.paymentTokenAddress,
                    i,
                    _msgSender(),
                    progress.currentPrice,
                    block.timestamp,
                    tx.origin
                );
            }
        }
    }

    /// @notice Place bid on auction with the specified price
    /// @param auctionId Auction Id
    /// @param bidPrice ERC20 token amount
    function makeBid(uint256 auctionId, uint256 bidPrice)
        external
        isBidAvailable(auctionId)
    {
        uint256 minIndex = 0;
        uint256 minPrice = getMinPrice(auctionId);

        AuctionInfo storage auction = auctions[auctionId];
        require(auction.paymentTokenAddress != address(0), "Wrong function");
        IERC20 paymentToken = IERC20(auction.paymentTokenAddress);
        require(
            bidPrice >= auction.startPrice && bidPrice > minPrice,
            "Cannot place bid at low price"
        );

        uint256 allowance = paymentToken.allowance(_msgSender(), address(this));
        require(allowance >= bidPrice, "Check the token allowance");

        mapping(address => uint256) storage auctionCurrentBids =
            currentBids[auctionId];
        require(
            auctionCurrentBids[_msgSender()] < 1,
            "Max bid per wallet exceeded"
        );

        mapping(uint256 => AuctionProgress) storage auctionBids =
            bids[auctionId];

        for (uint256 i = 0; i < auction.totalSupply; i++) {
            // Just place the bid if remaining
            if (auctionBids[i].currentPrice == 0) {
                minIndex = i;
                break;
            } else if (auctionBids[i].currentPrice == minPrice) {
                // Get last minimum price bidder
                minIndex = i;
            }
        }

        // Replace current minIndex bidder with the msg.sender
        paymentToken.transferFrom(_msgSender(), address(this), bidPrice);

        if (auctionBids[minIndex].currentPrice != 0) {
            // return previous bidders tokens
            paymentToken.transferFrom(
                address(this),
                auctionBids[minIndex].bidder,
                auctionBids[minIndex].currentPrice
            );
            auctionCurrentBids[auctionBids[minIndex].bidder]--;

            emit BidReplaced(
                auctionId,
                auction.paymentTokenAddress,
                minIndex,
                auctionBids[minIndex].bidder,
                auctionBids[minIndex].currentPrice,
                block.timestamp,
                tx.origin
            );
        }

        auctionBids[minIndex].currentPrice = bidPrice;
        auctionBids[minIndex].bidder = _msgSender();

        auctionCurrentBids[_msgSender()] = auctionCurrentBids[_msgSender()].add(
            1
        );

        emit BidPlaced(
            auctionId,
            auction.paymentTokenAddress,
            minIndex,
            _msgSender(),
            bidPrice,
            block.timestamp,
            tx.origin
        );
    }

    modifier isBidAvailable(uint256 auctionId) {
        require(
            !emergencyStop &&
                auctionId <= totalAuctionCount &&
                auctions[auctionId].startTime <= block.timestamp &&
                auctions[auctionId].endTime > block.timestamp
        );
        _;
    }

    /// @notice Check the auction is finished
    /// @param auctionId Auction Id
    /// @return bool true if finished, otherwise false
    function isAuctionFinished(uint256 auctionId) external view returns (bool) {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        return (emergencyStop || auctions[auctionId].endTime < block.timestamp);
    }

    /// @notice Get remaining time for the auction
    /// @param auctionId Auction Id
    /// @return uint the remaining time for the auction
    function getTimeRemaining(uint256 auctionId)
        external
        view
        returns (uint256)
    {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        return auctions[auctionId].endTime - block.timestamp;
    }

    /// @notice Start emergency, only owner action
    function setEmergencyStart() external onlyOwner {
        emergencyStop = true;
        emit EmergencyStarted();
    }

    /// @notice Stop emergency, only owner action
    function setEmergencyStop() external onlyOwner {
        emergencyStop = false;
        emit EmergencyStopped();
    }

    /// @notice Change start time for auction
    /// @param auctionId Auction Id
    /// @param startTime new start time
    function setStartTimeForAuction(uint256 auctionId, uint256 startTime)
        external
        onlyOwner
    {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        auctions[auctionId].startTime = startTime;
    }

    /// @notice Change end time for auction
    /// @param auctionId Auction Id
    /// @param endTime new end time
    function setEndTimeForAuction(uint256 auctionId, uint256 endTime)
        external
        onlyOwner
    {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        auctions[auctionId].endTime = endTime;
    }

    /// @notice Change total supply for auction
    /// @param auctionId Auction Id
    /// @param totalSupply new Total supply
    function setTotalSupplyForAuction(uint256 auctionId, uint256 totalSupply)
        external
        onlyOwner
    {
        require(totalSupply > 0, "Total supply should be greater than 0");
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        auctions[auctionId].totalSupply = totalSupply;
    }

    /// @notice Change start price for auction
    /// @param auctionId Auction Id
    /// @param startPrice new Total supply
    function setStartPriceForAuction(uint256 auctionId, uint256 startPrice)
        external
        onlyOwner
    {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        auctions[auctionId].startPrice = startPrice;
    }

    /// @notice Change ERC20 token address for auction
    /// @param auctionId Auction Id
    /// @param paymentTokenAddress new ERC20 token address
    function setPaymentTokenAddressForAuction(
        uint256 auctionId,
        address paymentTokenAddress
    ) external onlyOwner {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        auctions[auctionId].paymentTokenAddress = paymentTokenAddress;
    }

    /// @notice Change auction item address for auction
    /// @param auctionId Auction Id
    /// @param auctionItemAddress new Auctioned item address
    function setAuctionItemAddress(
        uint256 auctionId,
        address auctionItemAddress
    ) external onlyOwner {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        auctions[auctionId].auctionItemAddress = auctionItemAddress;
    }

    /// @notice Change auction item token id
    /// @param auctionId Auction Id
    /// @param auctionItemTokenId new token id
    function setAuctionItemTokenId(
        uint256 auctionId,
        uint256 auctionItemTokenId
    ) external onlyOwner {
        require(auctionId <= totalAuctionCount, "Invalid auction id");
        auctions[auctionId].auctionItemTokenId = auctionItemTokenId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
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

pragma solidity >=0.6.0 <0.8.0;

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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}