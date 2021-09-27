//SourceUnit: market.prod.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface TRC721TokenReceiver {
    function onTRC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

interface CoolCats {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract CoolCatsMarket is TRC721TokenReceiver {
    using SafeMath for uint256;
    
    //// MARKET
    bool public isMarketEnabled = false;
    
    // Market
    struct MarketLot {
        uint256 tokenId;
        bool isForSale;
        address owner;
        uint256 price;
        uint bidsCount;
        uint256 maxBidPrice;
    }
    
    struct Bid {
        uint256 id;
        uint256 tokenId;
        uint256 price;
        address payer;
        bool    active;
        string  status;
    }
    
    mapping (uint256 => MarketLot) public marketLots;  // tokenId -> Token information
    uint256 public bidsCount;
    mapping (uint256 => Bid) public bids;
    mapping (address => mapping(uint256=>uint256)) public bidsByUser;
    mapping (uint256 => mapping(uint256=>uint256)) public bidsByToken;
    mapping (address => uint256) public bidsCountByUser;
    
    CoolCats private coolCats;
    uint256 private _mainFee;

    uint256 private constant _fee1 = 125;
    uint256 private constant _fee2 = 875;

    address payable private _feeaddress1;
    address payable private _feeaddress2;
    address private _owner;
    
    uint256 catPrice = 1500 trx;
    uint256 minOfferPrice = 1500 trx;
    uint256 minBidPrice = 100 trx;
    
    constructor(address _coolCats, uint256 mainFee) public {
        require(msg.sender == tx.origin, "token address is not a contract");
        coolCats = CoolCats(_coolCats);
        _owner = msg.sender;
        _feeaddress1 = payable(0x41101708ac72e610ad34d176903f2ed2a102e3a514);
        _feeaddress2 = payable(0x41b9753cf45f48536e83e4ed7550cbb4d85c5b59a9);
        _mainFee = mainFee;
        _marketEnabled = false;
    }
    
    function enableMarket() public onlyOwner marketLock {
        _marketEnabled = true;
    }
    
    function disableMarket() public onlyOwner marketLock {
        _marketEnabled = false;
    }
    
    function setMinOfferPrice(uint256 _newPrice) public onlyOwner {
        require(_newPrice > 0, "Negative value");
        minOfferPrice = _newPrice;
    }
    
    function setMinBidPrice(uint256 _newPrice) public onlyOwner {
        require(_newPrice > 0, "Negative value");
        minBidPrice = _newPrice;
    }
    
    function setMainFee(uint256 mainFee) public onlyOwner {
        require(mainFee > 0, "Negative value");
        _mainFee = mainFee;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only for owner");
        _;
    }
    
    modifier canOperate(uint256 _tokenId) {
        if (marketLots[_tokenId].isForSale) {
            require(marketLots[_tokenId].owner == msg.sender, "Access denied");
        } else {
            address tokenOwner = coolCats.ownerOf(_tokenId);
            require(
                tokenOwner == msg.sender,
                "Access denied"
            );
        }
        _;
    }
    
    bool _marketLock = false;
    modifier marketLock {
        if (_marketLock) {
            require(!_marketLock, "Market locked");
        }
        _marketLock = true;
        _;
        _marketLock = false;
    }

    bool _marketEnabled = true;
    modifier marketEnabled {
        require(_marketEnabled, "Market disabled");
        _;
    }
    
    event TokenOnSale(uint256 indexed _tokenId, address indexed _owner, uint256 _price);
    event TokenNotOnSale(uint256 indexed _tokenId, address indexed _owner);
    event TokenMarketPriceChange(uint256 indexed _tokenId, address indexed _owner, uint256 _oldPrice, uint256 _newPrice);

    event MarketTrade(uint256 indexed _tokenId, address indexed _from, address indexed _to, address buyer, uint256 _price);
    event NewBid(uint256 indexed _id, uint256 indexed _tokenId, address indexed _payer, uint256 _price);
    event BidCancelled(uint256 indexed _id, uint256 indexed _tokenId, address indexed _payer, uint256 _price, string reason);
    event BidAccepted(uint256 indexed _id, uint256 indexed _tokenId, address indexed _payer, uint256 _price);
    event TRC721Received(address operator, address _from, uint256 tokenId);
    
    function addBid(uint256 _tokenId, uint256 _price) external payable marketEnabled marketLock {
        require(marketLots[_tokenId].isForSale, "Token not for sale");
        require(msg.value == _price, "Invalid value sent");
        require(_price >= minBidPrice, "Price too low");
        require(_price > marketLots[_tokenId].maxBidPrice, "Price must be greater than active max bid");
        require(_price <= marketLots[_tokenId].price, "Price must be a smaller than token price");
        
        marketLots[_tokenId].maxBidPrice = _price;
        
        Bid memory bid;
        bid = Bid({
            tokenId: _tokenId,
            price: _price,
            payer: msg.sender,
            active: true,
            id: bidsCount,
            status: 'PENDING'
        });
        
        bids[bidsCount] = bid;
        
        bidsByUser[msg.sender][bidsCountByUser[msg.sender]] = bid.id;
        bidsCountByUser[msg.sender]++;
        
        bidsByToken[_tokenId][marketLots[_tokenId].bidsCount] = bid.id;
        marketLots[_tokenId].bidsCount++;
        bidsCount++;
        
        emit NewBid(bid.id, _tokenId, msg.sender, _price);
    }
    
    function cancelBid(uint256 _bidId) external payable marketEnabled marketLock {
        require(bids[_bidId].payer == msg.sender, "Access denied");
        require(bids[_bidId].active, "Bid already cancelled");
        
        payable(bids[_bidId].payer).transfer(bids[_bidId].price);
        bids[_bidId].active = false;
        bids[_bidId].status = 'CANCELLED:BY_USER';
        
        if (bids[_bidId].price == marketLots[bids[_bidId].tokenId].maxBidPrice)
            _calcMaxBid(bids[_bidId].tokenId);
        
        emit BidCancelled(_bidId, bids[_bidId].tokenId, msg.sender, bids[_bidId].price, "Cancelled by user");
    }
    
    function _calcMaxBid(uint256 _tokenId) internal {
        uint256 _max = 0;
        for (uint256 i = 0; i < marketLots[_tokenId].bidsCount; i++) {
            uint256 bidId = bidsByToken[_tokenId][i];
            if (bids[bidId].active && bids[bidId].price > _max) _max = bids[bidId].price;
        }
        
        marketLots[_tokenId].maxBidPrice = _max;
    }
    
    function acceptBid(uint256 _tokenId, uint256 _bidId) external payable marketEnabled marketLock canOperate(_tokenId) {
        require(marketLots[_tokenId].isForSale, "Not for sale");
        require(bids[_bidId].active, "No active bid found");
        require(bids[_bidId].tokenId == _tokenId, "invalid token id");
        
        bids[_bidId].active = false;
        bids[_bidId].status = 'COMPLETE';
        
        uint256 fee = bids[_bidId].price.mul(_mainFee).div(1000);
        uint256 _a1fee = fee.mul(_fee1).div(1000);
        payable(_feeaddress1).transfer(_a1fee);
        payable(_feeaddress2).transfer(fee.sub(_a1fee));
        payable(marketLots[_tokenId].owner).transfer(bids[_bidId].price.sub(fee));
        
        marketLots[_tokenId].isForSale = false;
        for (uint256 i = 0; i < marketLots[_tokenId].bidsCount; i++) {
            uint256 bidId = bidsByToken[_tokenId][i];
            if (bids[bidId].active) {
                payable(bids[_bidId].payer).transfer(bids[_bidId].price);
                bids[bidId].active = false;
                bids[bidId].status = 'CANCELLED:MARKET_END';
                emit BidCancelled(bidId, _tokenId, bids[bidId].payer, bids[bidId].price, "Token sale ends");
            }
        }
        
        marketLots[_tokenId].bidsCount = 0;
        marketLots[bids[_bidId].tokenId].maxBidPrice = 0;
        emit BidAccepted(_bidId, _tokenId, bids[_bidId].payer, bids[_bidId].price);
        coolCats.safeTransferFrom(address(this), bids[_bidId].payer, _tokenId);
    }

    function putOnMarket(uint256 _tokenId, uint256 price) external canOperate(_tokenId) marketEnabled marketLock {
        require(!marketLots[_tokenId].isForSale, "Token already on sale");
        require(price >= minOfferPrice, "Price too low");
        require(coolCats.getApproved(_tokenId) == address(this) || coolCats.isApprovedForAll(msg.sender, address(this)), "Not approved");

        marketLots[_tokenId] = MarketLot(_tokenId, true, msg.sender, price, 0, 0);
        coolCats.safeTransferFrom(msg.sender, address(this), _tokenId);
        emit TokenOnSale(_tokenId, msg.sender, price);
    }
    
    function buyFromMarket(uint256 _tokenId) external payable marketEnabled marketLock {
        require(marketLots[_tokenId].isForSale, "Token not on sale");
        require(msg.value == marketLots[_tokenId].price, "Invalid value sent");
        
        uint256 fee = msg.value.mul(_mainFee).div(1000);
        uint256 _a1fee = fee.mul(_fee1).div(1000);
        payable(_feeaddress1).transfer(_a1fee);
        payable(_feeaddress2).transfer(fee.sub(_a1fee));
        payable(marketLots[_tokenId].owner).transfer(msg.value.sub(fee));
        
        marketLots[_tokenId].isForSale = false;
        for (uint256 i = 0; i < marketLots[_tokenId].bidsCount; i++) {
            uint256 bidId = bidsByToken[_tokenId][i];
            if (bids[bidId].active) {
                payable(bids[bidId].payer).transfer(bids[bidId].price);
                bids[bidId].active = false;
                bids[bidId].status = 'CANCELLED:MARKET_END';
                emit BidCancelled(bidId, _tokenId, bids[bidId].payer, bids[bidId].price, "Token sale ends");
            }
        }
        
        marketLots[_tokenId].bidsCount = 0;
        marketLots[_tokenId].maxBidPrice = 0;
        emit MarketTrade(_tokenId, marketLots[_tokenId].owner, msg.sender, msg.sender, msg.value);
        coolCats.safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    function changeLotPrice(uint256 _tokenId, uint256 newPrice) external canOperate(_tokenId) marketEnabled marketLock {
        require(marketLots[_tokenId].isForSale, "Not for sale");
        require(newPrice >= catPrice, "Price too low");

        emit TokenMarketPriceChange(_tokenId, msg.sender, marketLots[_tokenId].price, newPrice);

        marketLots[_tokenId].price = newPrice;
        for (uint256 i = 0; i < marketLots[_tokenId].bidsCount; i++) {
            uint256 bidId = bidsByToken[_tokenId][i];
            if (bids[bidId].active && bids[bidId].price < newPrice) {
                payable(bids[bidId].payer).transfer(bids[bidId].price);
                bids[bidId].active = false;
                bids[bidId].status = 'CANCELLED:PRICE_CHANGED';
                emit BidCancelled(bidId, _tokenId, bids[bidId].payer, bids[bidId].price, "Bid price smaller than new lot price");
            }   
        }
        
        _calcMaxBid(_tokenId);
    }

    function withdrawFromMarket(uint256 _tokenId) external canOperate(_tokenId) marketLock {
        _removeFromMarket(_tokenId);

        coolCats.safeTransferFrom(address(this), msg.sender, _tokenId);
        emit TokenNotOnSale(_tokenId, msg.sender);
    }


    function _removeFromMarket(uint256 _tokenId) internal {
        if (marketLots[_tokenId].isForSale) {
            for (uint256 i = 0; i < marketLots[_tokenId].bidsCount; i++) {
                uint256 bidId = bidsByToken[_tokenId][i];
                if (bids[bidId].active) {
                    payable(bids[bidId].payer).transfer(bids[bidId].price);
                    bids[bidId].active = false;
                    bids[bidId].status = 'CANCELLED:REMOVED_FROM_MARKET';
                    emit BidCancelled(bidId, _tokenId, bids[bidId].payer, bids[bidId].price, "Lot removed from market");
                }
            }
            
            delete marketLots[_tokenId];
        }
    }
    
    function onTRC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external override returns(bytes4){
        _data;
        emit TRC721Received(_operator, _from, _tokenId);
        return 0x5175f878;
        
    }
}