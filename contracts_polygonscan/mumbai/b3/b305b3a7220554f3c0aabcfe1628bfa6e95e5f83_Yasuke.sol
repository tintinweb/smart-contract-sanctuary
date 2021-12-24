/**
 *Submitted for verification at polygonscan.com on 2021-12-23
*/

//SPDX-License-Identifier: MIT-0

//Nifty Row NFT Marketplace Contract (Project Yasuke)
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

library Models {
    struct Asset {
        uint256 tokenId;
        address owner;
        address issuer;
        address contractAddress;
        string symbol;
        string name;
    }

    struct AuctionInfo {
        uint256 auctionId;
        uint256 tokenId;
        address owner;
        uint256 startBlock;
        uint256 endBlock;
        uint256 currentBlock;
        uint256 sellNowPrice;
        address highestBidder;
        uint256 highestBid;
        bool cancelled;
        uint256 minimumBid;
        address[] bidders;
        uint256[] bids;
        bool started;
        bool finished;
        bool sellNowTriggered;
    }
}

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


interface YasukeInterface {
    function startAuction(
        uint256 tokenId,
        uint256 auctionId,
        uint256 startBlock,
        uint256 endBlock,
        uint256 currentBlock,
        uint256 sellNowPrice,
        uint256 minimumBid
    ) external;

    function issueToken(
        uint256 tokenId,        
        address payable owner,
        string memory _uri,
        string memory _name,
        string memory _symbol
    ) external;

    function getTokenInfo(uint256 tokenId) external view returns (Models.Asset memory);

    function getAuctionInfo(uint256 tokenId, uint256 auctionId) external view returns (Models.AuctionInfo memory);

    function placeBid(uint256 tokenId, uint256 auctionId) external payable;

    function withdraw(uint256 tokenId, uint256 auctionId) external;

    function cancelAuction(uint256 tokenId, uint256 auctionId) external;

    event LogBid(address, uint256);

    event LogWithdrawal(address, uint256, uint256);

    event LogCanceled();
}

interface StorageInterface {
    function setAdmin(address _admin, address parent) external;

    function startAuction(Models.AuctionInfo memory ai, address sender) external;

    function getAuction(uint256 tokenId, uint256 auctionId) external view returns (Models.AuctionInfo memory);

    function getSellNowPrice(uint256 tokenId, uint256 auctionId) external view returns (uint256);

    function getHighestBid(uint256 tokenId, uint256 auctionId) external view returns (uint256);

    function getMinimumBid(uint256 tokenId, uint256 auctionId) external view returns (uint256);

    function getStartBlock(uint256 tokenId, uint256 auctionId) external view returns (uint256);

    function getCurrentBlock(uint256 tokenId, uint256 auctionId) external view returns (uint256);

    function isCancelled(uint256 tokenId, uint256 auctionId) external view returns (bool);

    function setCancelled(
        uint256 tokenId,
        uint256 auctionId,
        bool cancelled
    ) external;

    function isStarted(uint256 tokenId, uint256 auctionId) external view returns (bool);
    function isFinished(uint256 tokenId, uint256 auctionId) external view returns (bool);
    function isSellNowTriggered(uint256 tokenId, uint256 auctionId) external view returns (bool);

    function isInAuction(uint256 tokenId) external view returns (bool);

    function setStarted(
        uint256 tokenId,
        uint256 auctionId,
        bool started
    ) external;

    function setFinished(
        uint256 tokenId,
        uint256 auctionId,
        bool started
    ) external;    

    function setSellNowTriggered(
        uint256 tokenId,
        uint256 auctionId,
        bool started
    ) external;        

    function setInAuction(uint256 tokenId, bool started) external;

    function setHighestBid(
        uint256 tokenId,
        uint256 auctionId,
        uint256 highestBid
    ) external;

    function setEndBlock(
        uint256 tokenId,
        uint256 auctionId,
        uint256 endBlock
    ) external;

    function getEndBlock(uint256 tokenId, uint256 auctionId) external view returns (uint256);

    function setHighestBidder(
        uint256 tokenId,
        uint256 auctionId,
        address highestBidder
    ) external;

    function getHighestBidder(uint256 tokenId, uint256 auctionId) external view returns (address);

    function setOwner(uint256 tokenId, address owner) external;

    function getOwner(uint256 tokenId) external view returns (address);

    function addBidder(
        uint256 tokenId,
        uint256 auctionId,
        address bidder
    ) external;

    function addBid(
        uint256 tokenId,
        uint256 auctionId,
        uint256 bid
    ) external;

    function getBids(uint256 tokenId, uint256 auctionId) external view returns (uint256[] memory);

    function getBidders(uint256 tokenId, uint256 auctionId) external view returns (address[] memory);

    function addToken(uint256 tokenId, address payable owner, string memory uri, string memory name, string memory symbol) external;

    function setXendFeesPercentage(uint256 percentage) external;

    function getXendFeesPercentage() external view returns (uint256);

    function setIssuerFeesPercentage(uint256 percentage) external;

    function getIssuerFeesPercentage() external view returns (uint256);    

    function setXendFeesAddress(address payable xfAddress) external;

    function getXendFeesAddress() external view returns (address payable);    

    function echo() external view returns (bool);

    function getParent() external view returns (address);

    function getAdmin() external view returns (address);

    function changeTokenOwner(uint256 tokenId, address owner, address highestBidder) external;

    function getIssuer(uint256 tokenId) external view returns (address);

    function getAddress(uint256 tokenId) external view returns (address);

    function getName(uint256 tokenId) external view returns (string memory);

    function getSymbol(uint256 tokenId) external view returns (string memory);
}

contract Yasuke is YasukeInterface {
    using SafeMath for uint256;
    address internal minter;

    StorageInterface internal store;

    constructor(address storeAddress) {
        minter = msg.sender;
        store = StorageInterface(storeAddress);
        store.setAdmin(address(this), msg.sender);
    }

    function upgrade(address storeAddress) public {
        store = StorageInterface(storeAddress);
        store.setAdmin(address(this), msg.sender);
    }

    function testUpgrade() public view returns (address, address) {
        require(store.echo(), 'UF');
        return (store.getAdmin(), store.getParent());
    }

    function startAuction(
        uint256 tokenId,
        uint256 auctionId,
        uint256 startBlock,
        uint256 endBlock,
        uint256 currentBlock,
        uint256 sellNowPrice,
        uint256 minimumBid
    ) public override {
        require(!store.isInAuction(tokenId), 'AIP');
        require(!store.isStarted(tokenId, auctionId), 'AAS');
        Models.AuctionInfo memory ai = Models.AuctionInfo(
            auctionId,
            tokenId,
            msg.sender,
            startBlock,
            endBlock,
            currentBlock,
            sellNowPrice,
            address(0),
            0,
            false,
            minimumBid,
            store.getBidders(tokenId, auctionId),
            store.getBids(tokenId, auctionId),
            true,
            false,
            false
        );
        store.startAuction(ai, msg.sender);
    }

    function issueToken(
        uint256 tokenId,
        address payable owner,
        string memory _uri,
        string memory _name,
        string memory _symbol
    ) public override {
        store.addToken(tokenId, owner, _uri, _name, _symbol);
        store.setOwner(tokenId, owner);
    }

    function endBid(uint256 tokenId, uint256 auctionId) public {
        shouldBeStarted(tokenId, auctionId);
        store.setEndBlock(tokenId, auctionId, block.number); // forces the auction to end
    }

    function placeBid(uint256 tokenId, uint256 auctionId) public payable override {
        shouldBeStarted(tokenId, auctionId);
        require(msg.value > 0, 'CNB0');
        require(msg.sender != store.getOwner(tokenId), 'OCB');

        uint256 sellNowPrice = store.getSellNowPrice(tokenId, auctionId);

        uint256 newBid = msg.value;

        /**
            TODO: The frontend needs to know about this.  
            1. Add a new field to AuctionInfo that is set to true when the newBid >= sellNowPrice
            2. Set  highest bidder and highest bid  
         */
        if (newBid >= sellNowPrice && sellNowPrice != 0) {
            store.setEndBlock(tokenId, auctionId, block.number - 1); // forces the auction to end

            // refund bidder the difference if any
            uint256 difference = newBid.sub(sellNowPrice);
            if (difference > 0) {
                (bool sent, ) = payable(msg.sender).call{value: difference}('');
                require(sent, 'BFMB');
            }

            // bid should now be max bid
            newBid = sellNowPrice;
            store.setSellNowTriggered(tokenId, auctionId, true);
        } else {
            require(newBid > store.getHighestBid(tokenId, auctionId), 'BTL');
        }

        // get current highest bidder and highest bid
        address payable highestBidder = payable(store.getHighestBidder(tokenId, auctionId));
        uint256 highestBid = store.getHighestBid(tokenId, auctionId);

        // refund highest bidder their bid
        if (highestBidder != address(0)) {
            // this is the not first bid
            (bool sent, ) = payable(highestBidder).call{value: highestBid}('');
            require(sent, 'HBRF');
        }

        store.setHighestBidder(tokenId, auctionId, msg.sender);
        store.setHighestBid(tokenId, auctionId, newBid);
        store.addBidder(tokenId, auctionId, msg.sender);
        store.addBid(tokenId, auctionId, newBid);

        emit LogBid(msg.sender, newBid);

        if (newBid >= sellNowPrice && sellNowPrice != 0) {
            _withdrawal(tokenId, auctionId, true);
        }
    }

    function _withdrawal(uint256 tokenId, uint256 auctionId, bool withdrawOwner) internal {
        require(store.isStarted(tokenId, auctionId), 'BANS');
        require(block.number > store.getEndBlock(tokenId, auctionId) || store.isCancelled(tokenId, auctionId), 'ANE');
        bool cancelled = store.isCancelled(tokenId, auctionId);
        address owner = store.getOwner(tokenId);
        address highestBidder = store.getHighestBidder(tokenId, auctionId);

        if (cancelled) {
            // owner can not withdraw anything
            require(msg.sender != owner, 'AWC');
        }

        if (msg.sender == owner) {
            // withdraw funds from highest bidder
            _withdrawOwner(tokenId, auctionId);
        } else if (msg.sender == highestBidder) {
            // transfer the token from owner to highest bidder
            store.changeTokenOwner(tokenId, owner, highestBidder);

            // withdraw owner
            if(withdrawOwner) {
                _withdrawOwner(tokenId, auctionId);
            }
            store.setInAuction(tokenId, false); // we can create new auction
            store.setOwner(tokenId, highestBidder);
            store.setFinished(tokenId, auctionId, true);
            store.setStarted(tokenId, auctionId, false);
            store.setHighestBidder(tokenId, auctionId, address(0));
            store.setHighestBid(tokenId, auctionId, 0);
        }

        emit LogWithdrawal(msg.sender, tokenId, auctionId);
    }

    function _withdrawOwner(uint256 tokenId, uint256 auctionId) internal {
        address payable owner = payable(store.getOwner(tokenId));

        uint256 withdrawalAmount = store.getHighestBid(tokenId, auctionId);

        if (withdrawalAmount == 0) {
            return;
        }

        store.setHighestBid(tokenId, auctionId, 0);

        // we have to take fees
        uint256 xfp = store.getXendFeesPercentage();
        uint256 ifp = store.getIssuerFeesPercentage();

        if (store.getIssuer(tokenId) == owner) {
            // owner is issuer, xendFees is xendFees + issuerFees
            xfp = store.getXendFeesPercentage().add(store.getIssuerFeesPercentage());
            ifp = 0;
        }

        uint256 xendFees = (xfp.mul(withdrawalAmount)).div(100);
        uint256 issuerFees = (ifp.mul(withdrawalAmount)).div(100);

        withdrawalAmount = withdrawalAmount.sub(xendFees).sub(issuerFees);

        if (issuerFees > 0) {
            (bool sent, ) = payable(store.getIssuer(tokenId)).call{value: issuerFees}('');
            require(sent, 'CNSTI');
        }

        if (xendFees > 0) {
            (bool sent, ) = payable(store.getXendFeesAddress()).call{value: xendFees}('');
            require(sent, 'CNSTXND');
        }

        (bool sent, ) = payable(owner).call{value: withdrawalAmount}('');
        require(sent, 'WF');
    }

    function withdraw(uint256 tokenId, uint256 auctionId) public override {
        _withdrawal(tokenId, auctionId, true);
    }

    // TODO: Check if there are no bids before cancelling.
    function cancelAuction(uint256 tokenId, uint256 auctionId) public override {
        shouldBeStarted(tokenId, auctionId);
        require(store.getBids(tokenId, auctionId).length > 0);
        store.setCancelled(tokenId, auctionId, true);
        emit LogCanceled();
    }

    function getTokenInfo(uint256 tokenId) public view override returns (Models.Asset memory) {        
        Models.Asset memory a = Models.Asset(tokenId, store.getOwner(tokenId), store.getIssuer(tokenId), store.getAddress(tokenId), store.getName(tokenId), store.getSymbol(tokenId));
        return a;
    }

    function getAuctionInfo(uint256 tokenId, uint256 auctionId) public view override returns (Models.AuctionInfo memory) {
        Models.AuctionInfo memory b = store.getAuction(tokenId, auctionId);
        return b;
    }

    function shouldBeStarted(uint256 tokenId, uint256 auctionId) public view {
        require(block.number >= store.getStartBlock(tokenId, auctionId), 'ANC');
        require(block.number <= store.getEndBlock(tokenId, auctionId), 'AE');
        require(!store.isCancelled(tokenId, auctionId), 'AC');
        require(store.isStarted(tokenId, auctionId), 'ANS');
        require(store.isInAuction(tokenId), 'ANIP');
    }
}