// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./Governable.sol";
import "./interfaces/IERC1155.sol";
import "./NFTIndexer.sol";

contract EnglishAuctionNFT is Configurable, IERC721Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint    internal constant TypeErc721                = 0;
    uint    internal constant TypeErc1155               = 1;
    address internal constant DeadAddress               = 0x000000000000000000000000000000000000dEaD;
    address internal constant UniSwapContract           = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    struct Pool {
        // address of pool creator
        address payable creator;
        // pool name
        string name;
        // address of sell token
        address token0;
        // token id of token0
        uint tokenId;
        // amount of token id of token0
        uint tokenAmount0;
        // minimum amount of ETH that creator want to swap
        uint amountMin1;
        // minimum incremental amount of token1
        uint amountMinIncr1;
        // how many seconds the pool will be live since last bid
        uint confirmTime;
        // the timestamp in seconds the pool will be closed
        uint closeAt;
        // NFT token type
        uint nftType;
    }

    Pool[] public pools;

    // pool index => a flag that if creator is claimed the pool
    mapping(uint => bool) public creatorClaimedP;
    // pool index => the candidate of winner who bid the highest amount1 in current round
    mapping(uint => address payable) public currentBidderP;
    // pool index => the highest amount1 in current round
    mapping(uint => uint) public currentBidderAmount1P;

    // name => pool index + 1
    mapping(string => uint) public myNameP;

    // account => array of pool index
    mapping(address => uint[]) public myBidP;
    // account => pool index => bid amount1
    mapping(address => mapping(uint => uint)) public myBidderAmount1P;
    // account => pool index => claim flag
    mapping(address => mapping(uint => bool)) public myClaimedP;

    // pool index => bid count; v1.15.0
    mapping(uint => uint) public bidCountP;
    // pool index => address of buy token; v1.16.0
    mapping(uint => address) public token1P;

    // check if token0 in whitelist
    bool public checkToken0;

    // token0 address => true or false
    mapping(address => bool) public token0List;

    uint256 public fee;

    uint256 public feeMax;

    address payable public feeTo;

    // pool add time after bid
    mapping(uint => bool) public poolTime;

    address indexer;

    // the timestamp in seconds the pool will start
    mapping(uint => uint) public startAt;

    // promo token list
    mapping(address => uint256) public promoTokenList;

    event Created(address indexed sender, uint indexed index, Pool pool, address token1, uint startTime);
    event Bid(address sender, uint index, uint amount1, uint closeAt);
    event Claimed(address sender, uint index);
    event AuctionClosed(address indexed sender, uint indexed index);

    function initialize(address _governor) public override initializer {
        super.initialize(_governor);
    }

    function createErc721(
        // name of the pool
        string memory name,
        // address of token0
        address token0,
        // address of token1
        address token1,
        // token id of token0
        uint tokenId,
        // minimum amount of token1
        uint amountMin1,
        // minimum incremental amount of token1
        uint amountMinIncr1,
        // confirmation time
        uint confirmTime,
        // add close time after bid
        bool addTime
    ) external payable {
        if (checkToken0) {
            require(token0List[token0], "invalid token0");
        }
        uint tokenAmount0 = 1;
        uint[3] memory amounts = [tokenAmount0, amountMin1, amountMinIncr1];
        _create(name, token0, token1, tokenId, amounts, confirmTime, TypeErc721, addTime, now);
        if (token1 != address(0)) {
            token1P[pools.length-1] = token1;
        }
    }

    function createErc721WithStartTime(
        // name of the pool
        string memory name,
        // address of token0
        address token0,
        // address of token1
        address token1,
        // token id of token0
        uint tokenId,
        // minimum amount of token1
        uint amountMin1,
        // minimum incremental amount of token1
        uint amountMinIncr1,
        // confirmation time
        uint confirmTime,
        // add close time after bid
        bool addTime,

        uint startTime
    ) external payable {
        if (checkToken0) {
            require(token0List[token0], "invalid token0");
        }
        uint tokenAmount0 = 1;
        uint[3] memory amounts = [tokenAmount0, amountMin1, amountMinIncr1];
        _create(name, token0, token1, tokenId, amounts, confirmTime, TypeErc721, addTime, startTime);
        if (token1 != address(0)) {
            token1P[pools.length-1] = token1;
        }
    }

    function createErc1155WithStartTime(
        // name of the pool
        string memory name,
        // address of token0
        address token0,
        // address of token1
        address token1,
        // token id of token0
        uint tokenId,
        // amount of token id of token0
        uint tokenAmount0,
        // minimum amount of token1
        uint amountMin1,
        // minimum incremental amount of token1
        uint amountMinIncr1,
        // confirmation time
        uint confirmTime,
        // add close time after bid
        bool addTime,

        uint startTime
    ) external payable {
        if (checkToken0) {
            require(token0List[token0], "invalid token0");
        }
        uint[3] memory amounts = [tokenAmount0, amountMin1, amountMinIncr1];
        _create(name, token0, token1, tokenId, amounts, confirmTime, TypeErc1155, addTime, startTime);
        if (token1 != address(0)) {
            token1P[pools.length-1] = token1;
        }
    }

    function createErc1155(
        // name of the pool
        string memory name,
        // address of token0
        address token0,
        // address of token1
        address token1,
        // token id of token0
        uint tokenId,
        // amount of token id of token0
        uint tokenAmount0,
        // minimum amount of token1
        uint amountMin1,
        // minimum incremental amount of token1
        uint amountMinIncr1,
        // confirmation time
        uint confirmTime,
        // add close time after bid
        bool addTime
    ) external payable {
        if (checkToken0) {
            require(token0List[token0], "invalid token0");
        }
        uint[3] memory amounts = [tokenAmount0, amountMin1, amountMinIncr1];
        _create(name, token0, token1, tokenId, amounts, confirmTime, TypeErc1155, addTime, now);
        if (token1 != address(0)) {
            token1P[pools.length-1] = token1;
        }
    }

    function _create(
        // name of the pool
        string memory name,
        // address of token0
        address token0,
        // address of token1
        address token1,
        // token id of token0
        uint tokenId,
        // 0: uint tokenAmount0, amount of token id of token0
        // 1: uint amountMin1, minimum amount of token1
        // 2: uint amountMinIncr1, minimum incremental amount of token1
        uint[3] memory amounts,
        // confirmation time
        uint confirmTime,
        // NFT token type
        uint nftType,

        bool addTime,

        uint startTime
    ) private
    {
        address payable creator = msg.sender;

        require(startTime > 0, "start time should not be zero");
        require(amounts[0] != 0, "the value of tokenAmount0 is zero");
        require(amounts[2] != 0, "the value of amountMinIncr1 is zero");
        require(confirmTime >= 5 minutes, "the value of confirmTime less than 5 minutes");
        require(confirmTime <= 7 days, "the value of confirmTime is exceeded 7 days");
        require(bytes(name).length <= 15, "the length of name is too long");

        // creator pool
        Pool memory pool;
        pool.creator = creator;
        pool.name = name;
        pool.token0 = token0;
        pool.tokenId = tokenId;
        pool.tokenAmount0 = amounts[0];
        pool.amountMin1 = amounts[1];
        pool.amountMinIncr1 = amounts[2];
        pool.confirmTime = confirmTime;
        pool.closeAt = startTime.add(confirmTime);
        pool.nftType = nftType;

        uint index = pools.length;
        pools.push(pool);
        poolTime[pools.length - 1] = addTime;

        startAt[index] = startTime;

        // transfer tokenId of token0 to this contract
        if (nftType == TypeErc721) {
            IERC721(token0).safeTransferFrom(creator, address(this), tokenId);
            NFTIndexer(indexer).new721Auction(token0, tokenId, pools.length - 1);
        } else {
            IERC1155(token0).safeTransferFrom(creator, address(this), tokenId, amounts[0], "");
            NFTIndexer(indexer).new1155Auction(token0, creator, tokenId, pools.length - 1);
        }

        emit Created(creator, index, pool, token1, startTime);
    }

    function bid(
        // pool index
        uint index,
        // amount of token1
        uint amount1
    ) external payable
        isPoolExist(index)
        isPoolStarted(index)
        isPoolNotClosed(index)
    {
        address payable sender = msg.sender;

        Pool storage pool = pools[index];
        require(pool.creator != sender, "creator can't bid the pool created by self");
        require(amount1 != 0, "the value of amount1 is zero");
        require(amount1 >= pool.amountMin1, "the bid amount is lower than minimum bidder amount");

        require(amount1 >= currentBidderAmount(index), "the bid amount is lower than the current bidder amount");

        address token1 = token1P[index];
        if (token1 == address(0)) {
            require(amount1 == msg.value, "invalid ETH amount");
        } else {
            IERC20(token1).safeTransferFrom(sender, address(this), amount1);
            IERC20(token1).safeApprove(address(this), 0);
        }

        // return ETH to previous bidder
        if (currentBidderP[index] != address(0) && currentBidderAmount1P[index] > 0) {
            if (token1 == address(0)) {
                currentBidderP[index].transfer(currentBidderAmount1P[index]);
            } else {
                IERC20(token1).safeTransfer(currentBidderP[index], currentBidderAmount1P[index]);
            }
        }

        // update closeAt
        if (poolTime[index] == true) {
            pool.closeAt = now.add(pool.confirmTime);
        }

        // record new winner
        currentBidderP[index] = sender;
        currentBidderAmount1P[index] = amount1;
        bidCountP[index] = bidCountP[index] + 1;

        myBidP[sender].push(index);
        myBidderAmount1P[sender][index] = amount1;

        emit Bid(sender, index, amount1, pool.closeAt);
    }

    function creatorClaim(uint index) external
        isPoolExist(index)
        isPoolClosed(index)
    {
        address payable sender = msg.sender;
        require(isCreator(sender, index), "sender is not pool creator");
        require(!creatorClaimedP[index], "creator has claimed this pool");

        _creatorClaim(index);

        if (currentBidderP[index] != address(0)) {
            address bidder = currentBidderP[index];
            if (!myClaimedP[bidder][index]) {
                _bidderClaim(bidder, index);
            }
        }
    }

    function bidderClaim(uint index) external
        isPoolExist(index)
        isPoolClosed(index)
    {
        address payable sender = msg.sender;
        require(currentBidderP[index] == sender, "sender is not the winner of this pool");
        require(!myClaimedP[sender][index], "sender has claimed this pool");

        _bidderClaim(sender, index);

        if (!creatorClaimedP[index]) {
            _creatorClaim(index);
        }
    }

    function _creatorClaim(uint index) internal {
        creatorClaimedP[index] = true;
        Pool memory pool = pools[index];

        if (currentBidderP[index] != address(0)) {
            address payable winner = currentBidderP[index];
            uint amount1 = currentBidderAmount1P[index];

            uint256 auctionFee = 0;
            if (feeTo != address(0) && fee > 0) {
                if (promoTokenList[token1P[index]] != 0) {
                    auctionFee = amount1.mul(promoTokenList[token1P[index]]).div(feeMax);
                } else {
                    auctionFee = amount1.mul(fee).div(feeMax);
                }
            }

            if (amount1 > 0) {
                if (token1P[index] == address(0)) {
                    // transfer ETH to creator
                    if (auctionFee > 0) {
                        feeTo.transfer(auctionFee);
                    }
                    pool.creator.transfer(amount1.sub(auctionFee));
                } else {
                    IERC20(token1P[index]).safeTransfer(pool.creator, amount1.sub(auctionFee));
                    if (auctionFee > 0) {
                        IERC20(token1P[index]).safeTransfer(feeTo, auctionFee);
                    }
                }
            }
        } else {
            // transfer token0 back to creator
            if (pool.nftType == TypeErc721) {
                IERC721(pool.token0).safeTransferFrom(address(this), pool.creator, pool.tokenId);
            } else {
                IERC1155(pool.token0).safeTransferFrom(address(this), pool.creator, pool.tokenId, pool.tokenAmount0, "");
            }
        }

        emit Claimed(pool.creator, index);
    }

    function _bidderClaim(address sender, uint index) internal {
        myClaimedP[sender][index] = true;

        Pool memory pool = pools[index];
      
        // transfer token0 to bidder
        if (pool.nftType == TypeErc721) {
            IERC721(pool.token0).safeTransferFrom(address(this), sender, pool.tokenId);
        } else {
            IERC1155(pool.token0).safeTransferFrom(address(this), sender, pool.tokenId, pool.tokenAmount0, "");
        }

        emit Claimed(sender, index);
    }

    function closeAuction(uint index) external
        isPoolExist(index)
        isPoolNotClosed(index)
    {
        address payable sender = msg.sender;
        require(isCreator(sender, index), "sender is not pool creator");

        Pool storage pool = pools[index];
        pool.closeAt = now;

        emit AuctionClosed(sender, index);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external returns(bytes4) {
        return this.onERC1155Received.selector;
    }

    function getPoolCount() external view returns (uint) {
        return pools.length;
    }

    function getStartTime(uint index) external view returns (uint) {
        return startAt[index];
    }

    function setFee(uint256 _fee) external governance returns (bool) {
        fee = _fee;
        return  true;
    }

    function setFeeMax(uint256 _feeMax) external governance returns (bool) {
        feeMax = _feeMax;
        return  true;
    }

    function setFeeTo(address payable _feeTo) external governance returns (bool) {
        feeTo = _feeTo;
        return  true;
    }

    function setCheckToken0(bool _checkToken0) external governance returns (bool) {
        checkToken0 = _checkToken0;
        return  true;
    }

    function setIndexer(address _indexer) external governance returns (bool) {
        indexer = _indexer;
        return  true;
    }

    function setToken0List(address _token0, bool enable) external governance returns (bool) {
        token0List[_token0] = enable;
        return  true;
    }

    function setPoolTime(uint index, bool add) external governance returns (bool) {
        poolTime[index] = add;
        return  true;
    }

    function currentBidderAmount(uint index) public view returns (uint) {
        Pool memory pool = pools[index];
        uint amount = pool.amountMin1;

        if (currentBidderP[index] != address(0)) {
            amount = currentBidderAmount1P[index].add(pool.amountMinIncr1);
        } else if (pool.amountMin1 == 0) {
            amount = pool.amountMinIncr1;
        }

        return amount;
    }

    function isCreator(address target, uint index) private view returns (bool) {
        if (pools[index].creator == target) {
            return true;
        }
        return false;
    }

    modifier isPoolClosed(uint index) {
        require(pools[index].closeAt <= now, "this pool is not closed");
        _;
    }

    modifier isPoolNotClosed(uint index) {
        require(pools[index].closeAt > now, "this pool is closed");
        _;
    }

    modifier isPoolExist(uint index) {
        require(index < pools.length, "this pool does not exist");
        _;
    }

    modifier isPoolStarted(uint index) {
        require(startAt[index] <= now, "this pool is not started yet");
        _;
    }

    function setPromoToken(address _promoToken, uint256 _fee) external governance returns (bool) {
        promoTokenList[_promoToken] = _fee;
        return true;
    }

    function getTokenRate(address _promoToken) external view returns (uint) {
        uint rate = fee;
        if (promoTokenList[_promoToken] != 0) {
            rate = promoTokenList[_promoToken];
        }
        return rate;
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

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity ^0.6.0;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


contract Governable is Initializable {
    address public governor;

    event GovernorshipTransferred(address indexed previousGovernor, address indexed newGovernor);

    /**
     * @dev Contract initializer.
     * called once by the factory at time of deployment
     */
    function initialize(address governor_) virtual public initializer {
        governor = governor_;
        emit GovernorshipTransferred(address(0), governor);
    }

    modifier governance() {
        require(msg.sender == governor);
        _;
    }

    /**
     * @dev Allows the current governor to relinquish control of the contract.
     * @notice Renouncing to governorship will leave the contract without an governor.
     * It will not be possible to call the functions with the `governance`
     * modifier anymore.
     */
    function renounceGovernorship() public governance {
        emit GovernorshipTransferred(governor, address(0));
        governor = address(0);
    }

    /**
     * @dev Allows the current governor to transfer control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function transferGovernorship(address newGovernor) public governance {
        _transferGovernorship(newGovernor);
    }

    /**
     * @dev Transfers control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function _transferGovernorship(address newGovernor) internal {
        require(newGovernor != address(0));
        emit GovernorshipTransferred(governor, newGovernor);
        governor = newGovernor;
    }
}


contract Configurable is Governable {

    mapping (bytes32 => uint) internal config;
    
    function getConfig(bytes32 key) public view returns (uint) {
        return config[key];
    }
    function getConfig(bytes32 key, uint index) public view returns (uint) {
        return config[bytes32(uint(key) ^ index)];
    }
    function getConfig(bytes32 key, address addr) public view returns (uint) {
        return config[bytes32(uint(key) ^ uint(addr))];
    }

    function _setConfig(bytes32 key, uint value) internal {
        if(config[key] != value)
            config[key] = value;
    }
    function _setConfig(bytes32 key, uint index, uint value) internal {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function _setConfig(bytes32 key, address addr, uint value) internal {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
    
    function setConfig(bytes32 key, uint value) external governance {
        _setConfig(key, value);
    }
    function setConfig(bytes32 key, uint index, uint value) external governance {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function setConfig(bytes32 key, address addr, uint value) public governance {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transfered from `from` to `to` by `operator`.
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

pragma solidity ^0.6.0;

import "./Governable.sol";


contract NFTIndexer is Governable {

    mapping (address => mapping(uint256 => uint256)) public NFT721Auction;

    mapping (address => mapping(uint256 => uint256)) public NFT721Fixswap;

    mapping (address => mapping(uint256 => mapping(address => uint256))) public NFT1155Auction;

    mapping (address => mapping(uint256 => mapping(address => uint256))) public NFT1155Fixswap;

    address public auction;
    address public fixswap;

    modifier onlyAuction() {
        require(msg.sender == auction || msg.sender == governor, "only auction");
        _;
    }

    modifier onlyFixswap() {
        require(msg.sender == fixswap || msg.sender == governor, "only fixswap");
        _;
    }

    function initialize(address _governor) public override initializer {
        super.initialize(_governor);
    }

    function setAuction(address _auction) external governance returns (bool) {
        auction = _auction;
    }

    function setFixswap(address _fixswap) external governance returns (bool) {
        fixswap = _fixswap;
    }

    function new721Auction(address _token, uint256 _tokenId, uint256 _poolId) public  onlyAuction {
        NFT721Auction[_token][_tokenId] = _poolId;
    }
    
    function new1155Auction(address _token, address _creator, uint256 _tokenId, uint256 _poolId) public  onlyAuction {
        NFT1155Auction[_token][_tokenId][_creator] = _poolId;
    }

    function new721Fixswap(address _token, uint256 _tokenId, uint256 _poolId) public  onlyFixswap {
        NFT721Fixswap[_token][_tokenId] = _poolId;
    }
    
    function new1155Fixswap(address _token, address _creator, uint256 _tokenId, uint256 _poolId) public onlyFixswap{
        NFT1155Fixswap[_token][_tokenId][_creator] = _poolId;
    }

    function del721Auction(address _token, uint256 _tokenId) public  onlyAuction {
        delete NFT721Auction[_token][_tokenId];
    }
    
    function del1155Auction(address _token, address _creator, uint256 _tokenId) public  onlyAuction {
        delete NFT1155Auction[_token][_tokenId][_creator];
    }

    function del721Fixswap(address _token, uint256 _tokenId) public  onlyFixswap {
        delete NFT721Fixswap[_token][_tokenId];
    }
    
    function del1155Fixswap(address _token, address _creator, uint256 _tokenId) public onlyFixswap{
        delete NFT1155Fixswap[_token][_tokenId][_creator];
    }

    function get721Auction(address _token, uint256 _tokenId) public view returns(uint256) {
        return NFT721Auction[_token][_tokenId];
    }

    function get721Fixswap(address _token, uint256 _tokenId) public view returns(uint256) {
        return NFT721Fixswap[_token][_tokenId];
    }

    function get1155Auction(address _token, address _creator, uint256 _tokenId) public view returns(uint256) {
        return NFT1155Auction[_token][_tokenId][_creator];
    }

    function get1155Fixswap(address _token, address _creator, uint256 _tokenId) public view returns(uint256) {
        return NFT1155Fixswap[_token][_tokenId][_creator];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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