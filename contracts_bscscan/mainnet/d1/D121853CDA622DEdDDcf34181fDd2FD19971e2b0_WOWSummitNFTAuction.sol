// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IERC721 {
    function mint(
        address recipient,
        uint256 tokenId,
        string memory uri
    ) external;
}

contract WOWSummitNFTAuction {
    using SafeMath for uint256; //add safeMath

    // keep track of counters
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address public dev; // developer address
    address public team; // address of the team

    uint256 distribution; // distribution percentage between the DAO and the team

    IERC721 public immutable NFT;

    struct Auction {
        uint256 originalQuantity; // quantity of the NFT's to give
        string uri; // URI of the NFT
        IERC20 auctionToken;
        // uint256 basePrice; // base price of the asset
        uint256 minBidAmt; // minimum amount at which auction should increase
        uint256 incrementRate; // rate at which the big should increment
        uint256 startTime; // time at which the auction will start
        uint256 expiry; // expiry of the auction
        uint256 totalBidders; // total number of bids
        uint256 totalBidAmt; // total bid amount
        uint256 burnRate; // by default zero, can be enabled later
        mapping(address => uint256) bids; // mapping of all the bids with amount they staked
        mapping(address => uint256) bidderPosition;
        mapping(address => bool) hasClaimed;
    }

    // store the mapping of added NFTs for the sale
    mapping(uint256 => Auction) public auctions;

    event Bid(
        uint256 indexed auctionId,
        address indexed user,
        uint256 indexed amount
    );

    event Claim(
        uint256 indexed auctionId,
        address indexed user,
        uint256 indexed tokenId
    );

    event NewAuction(uint256 indexed auctionId);

    event IncrementRate(uint256 indexed asset, uint256 indexed incrementRate);

    event ChangeSalesDistribution(uint256 indexed newDistributionRate);

    event ChangeBurnRate(uint256 indexed newBurnRate);

    modifier onlyDev() {
        require(msg.sender == dev, "auction: wrong developer");
        _;
    }

    modifier onlyTeam() {
        require(msg.sender == team, "auction: wrong team");
        _;
    }

    constructor(
        IERC721 _NFTAddress,
        address _dev,
        address _team
    ) {
        NFT = _NFTAddress;
        dev = _dev;
        team = _team;
    }

    /**
     * @dev A user can bid, he provide amount in ratio with minBidAmt
     * @param _auctionId id of the auction
     * @param _amt Amount users want to bid
     */
    function bid(uint256 _auctionId, uint256 _amt) public {
        Auction storage auction = auctions[_auctionId];

        require(auction.startTime < block.timestamp, "auction: not yet started");
        require(_amt > 0, "auction: amount should be greater than zero");
        require(auction.expiry > block.timestamp, "Auction: Auction is not over yet");
        require(
            auction.minBidAmt < _amt && // _amt should be > than last bidded price
                _amt.sub(auction.minBidAmt).mod(auction.incrementRate) == 0, // proposed bid is multiple of minimum bid amount
            "auction: invalid amount"
        );
        require(auction.minBidAmt < _amt, "big amount is too less");

        // return the previous amount
        if (auction.bids[msg.sender] > 0) {
            auction.auctionToken.transfer(msg.sender, auction.bids[msg.sender]);
        }

        // update the amount user has staked
        uint256 newBidderAmt = _amt;
        auction.bids[msg.sender] = newBidderAmt;
 
        // auction.highestBidAmt = _amt.add(newBidderAmt);
        // // update the highest bid amount
        // if (auction.highestBidAmt < _amt.add(newBidderAmt)) {
        //     auction.highestBidAmt = _amt.add(newBidderAmt);
        // }

        // update last bid amount
        auction.minBidAmt = _amt;

        // update the totalBidAmt
        auction.totalBidAmt = auction.totalBidAmt.add(_amt);

        // update number of bidders
        auction.totalBidders = auction.totalBidders.add(1);

        // store index to distribute the reward
        auction.bidderPosition[msg.sender] = auction.totalBidders;

        // transfer the tokens to contract
        auction.auctionToken.transferFrom(msg.sender, address(this), _amt);

        // emit bid event
        emit Bid(_auctionId, msg.sender, _amt);
    }

    /**
     * After the auction has ended users can claim their NFTs or the auction tokens (in case they do not win)
     * @param _auctionId id of the auction
     */
    function claim(uint256 _auctionId) public {
        Auction storage auction = auctions[_auctionId];

        require(
            auction.hasClaimed[msg.sender] == false,
            "auction: Already claimed"
        );
        require(auction.bids[msg.sender] > 0, "auction: invalid user");

        require(
            auction.expiry < block.timestamp,
            "Auction: Auction is not over yet"
        );

        if (
            auction.totalBidders.sub(auction.bidderPosition[msg.sender]) < auction.originalQuantity
        ) {
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            auction.hasClaimed[msg.sender] = true;
            NFT.mint(msg.sender, tokenId, auction.uri);
            emit Claim(
                _auctionId,
                msg.sender,
                tokenId
            );
        } else {
            auction.auctionToken.transfer(msg.sender, auction.bids[msg.sender]);
        }
    }

    /**
     * Returns the bid amount provided by user
     * @param _auctionId id of the auction
     * @param _user address of the user
     */
    function getBid(uint256 _auctionId, address _user)
        public
        view
        returns (uint256)
    {
        Auction storage auction = auctions[_auctionId];
        return auction.bids[_user];
    }

    /**
     * Returns position of the bidder
     * @param _auctionId id of the auction
     * @param _user address of the user
     */
    function getBidderPosition(uint256 _auctionId, address _user)
        public
        view
        returns (uint256)
    {
        Auction storage auction = auctions[_auctionId];
        return auction.bidderPosition[_user];
    }

    /*
    DEV FUNCTIONS
    */
    /**
     * Add new NFT for sale
     * @param _auctionId The address of the asset should be sold
     * @param _uri uri of the NFT
     * @param _quantity The quantity of the asset should be sold
     * @param _minBidAmt Minimum bid amount to be provided to participate in auction
     * @param _incrementRate The rate at which the bids should be incremented
     * @param _expiry Expiry of the NFT sale
     * @param _auctionToken The token in which the auction should commence
     */

    function add(
        uint256 _auctionId,
        string memory _uri,
        uint256 _quantity,
        uint256 _minBidAmt,
        uint256 _incrementRate,
        uint256 _expiry,
        uint256 _startTime,
        IERC20 _auctionToken
    ) external onlyDev {
        require(
            _quantity > 0,
            "auction: _quantity should be greater than zero"
        );
        require(
            _expiry > block.timestamp,
            "auction: _expiry should be a future block"
        );
        require(
            _minBidAmt > 0,
            "auction: _minBidAmt should be greater than zero"
        );
        Auction storage auction = auctions[_auctionId];
        // check if the asset is already added
        require(auction.minBidAmt == 0);
        auction.uri = _uri;
        auction.originalQuantity = _quantity;
        // auction.basePrice = _basePrice;
        auction.minBidAmt = _minBidAmt;
        auction.incrementRate = _incrementRate;
        auction.expiry = _expiry;
        auction.auctionToken = _auctionToken;
        auction.startTime = _startTime;
        emit NewAuction(_auctionId);
    }

    function changeStartTime(uint256 _auctionId, uint256 _startTime) public onlyDev{
        Auction storage auction = auctions[_auctionId];
        auction.startTime = _startTime;
    }

    function changeExpiry(uint256 _auctionId, uint256 _expiry) public onlyDev{
        Auction storage auction = auctions[_auctionId];
        auction.expiry = _expiry;
    }

    function changeIncrementRate(uint256 _auctionId, uint256 _incrementRate)
        external
        onlyDev
    {
        require(_incrementRate > 0, "auction: invalid inputs");
        Auction storage auction = auctions[_auctionId];
        auction.incrementRate = _incrementRate;
        emit IncrementRate(_auctionId, _incrementRate);
    }

    // set distribution percentage to DAO, in decimal of 4
    // eg. for 50% set value to be 50000
    function changeSalesDistribution(uint256 _newDistribution)
        external
        onlyDev
    {
        distribution = _newDistribution;
        emit ChangeSalesDistribution(_newDistribution);
    }

    // for 50% set value to be 50000
    function changeBurnRate(uint256 _auctionId, uint256 _newBurnRate)
        external
        onlyDev
    {
        Auction storage auction = auctions[_auctionId];
        auction.burnRate = _newBurnRate;
        emit ChangeBurnRate(_newBurnRate);
    }

    function distributeSales(uint256 _auctionId) external onlyDev {
        Auction storage auction = auctions[_auctionId];
        require(
            auction.expiry <= block.timestamp,
            "auction: the auction isn't expired"
        );

        uint256 saleAmount;

        // burn tokens
        if (auction.burnRate > 0) {
            uint256 burnAmount =
                auction.minBidAmt.mul(auction.burnRate).div(1000000);
            auction.auctionToken.transfer(address(0), burnAmount);
            saleAmount = auction.minBidAmt.sub(burnAmount);
        } else {
            saleAmount = auction.minBidAmt;
        }

        // distribute funds to developer w.r.t to already set distribution
        uint256 devShare = saleAmount.mul(distribution).div(1000000);
        auction.auctionToken.transfer(dev, devShare);
        // distribute remaining balance to the team
        auction.auctionToken.transfer(team, saleAmount.sub(devShare));
    }

    function changeDev(address _newDev) public onlyDev {
        dev  = _newDev;
    }

    function changeTeam(address _newTeam) public onlyTeam {
        team  = _newTeam;
    }
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

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

