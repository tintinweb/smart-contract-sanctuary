/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

// File: contracts/interface/MarketInterfaces.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

contract ShardsMarketAdminStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;
    /**
     * @notice Governance for this contract which has the right to adjust the parameters of market
     */
    address public governance;

    /**
     * @notice Active brains of ShardsMarket
     */
    address public implementation;
}

contract IShardsMarketStorge is ShardsMarketAdminStorage {
    address public shardsFactory;

    address public factory;

    address public router;

    address public dev;

    address public platformFund;

    address public shardsFarm;

    address public buyoutProposals;

    address public regulator;

    address public shardAdditionProposal;

    address public WETH;
    //The totalSupply of shard in the market
    uint256 public totalSupply = 10000000000000000000000;
    //Stake Time limit: 60*60*24*5
    uint256 public deadlineForStake = 432000;
    //Redeem Time limit:60*60*24*7
    uint256 public deadlineForRedeem = 604800;
    //The Proportion of the shardsCreator's shards
    uint256 public shardsCreatorProportion = 5;
    //The Proportion of the platform's shards
    uint256 public platformProportion = 5;
    //The Proportion for dev of the market profit,the rest of profit is given to platformFund
    uint256 public profitProportionForDev = 20;
    //max
    uint256 internal constant max = 100;
    //shardPool count
    uint256 public shardPoolIdCount;
    // all of the shardpoolId
    uint256[] internal allPools;
    // Info of each pool.
    mapping(uint256 => shardPool) public poolInfo;
    //shardPool struct
    struct shardPool {
        address creator; //shard  creator
        ShardsState state; //shard state
        uint256 createTime;
        uint256 deadlineForStake;
        uint256 deadlineForRedeem;
        uint256 balanceOfWantToken; // all the stake amount of the wantToken in this pool
        uint256 minWantTokenAmount; //Minimum subscription required by the creator
        bool isCreatorWithDraw; //Does the creator withdraw wantToken
        address wantToken; // token address Requested by the creator for others to stake
        uint256 openingPrice;
    }
    //shard of each pool
    mapping(uint256 => shard) public shardInfo;
    //shard struct
    struct shard {
        string shardName;
        string shardSymbol;
        address shardToken;
        uint256 totalShardSupply;
        uint256 shardForCreator;
        uint256 shardForPlatform;
        uint256 shardForStakers;
        uint256 burnAmount;
    }
    //user info of each pool
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    struct UserInfo {
        uint256 amount;
        bool isWithdrawShard;
    }

    enum ShardsState {
        Live,
        Listed,
        ApplyForBuyout,
        Buyout,
        SubscriptionFailed,
        Pending,
        AuditFailed,
        ApplyForAddition
    }

    struct Token721 {
        address contractAddress;
        uint256 tokenId;
    }
    struct Token1155 {
        address contractAddress;
        uint256 tokenId;
        uint256 amount;
    }
    //nfts of shard creator stakes in each pool
    mapping(uint256 => Token721[]) internal Token721s;
    mapping(uint256 => Token1155[]) internal Token1155s;
}

abstract contract IShardsMarket is IShardsMarketStorge {
    event ShardCreated(
        uint256 shardPoolId,
        address indexed creator,
        string shardName,
        string shardSymbol,
        uint256 minWantTokenAmount,
        uint256 createTime,
        uint256 totalSupply,
        address wantToken
    );
    event Stake(address indexed sender, uint256 shardPoolId, uint256 amount);
    event Redeem(address indexed sender, uint256 shardPoolId, uint256 amount);
    event SettleSuccess(
        uint256 indexed shardPoolId,
        uint256 platformAmount,
        uint256 shardForStakers,
        uint256 balanceOfWantToken,
        uint256 fee,
        address shardToken
    );
    event SettleFail(uint256 indexed shardPoolId);
    event ApplyForBuyout(
        address indexed sender,
        uint256 indexed proposalId,
        uint256 indexed _shardPoolId,
        uint256 shardAmount,
        uint256 wantTokenAmount,
        uint256 voteDeadline,
        uint256 buyoutTimes,
        uint256 price,
        uint256 blockHeight
    );
    event Vote(
        address indexed sender,
        uint256 indexed proposalId,
        uint256 indexed _shardPoolId,
        bool isAgree,
        uint256 voteAmount
    );
    event VoteResultConfirm(
        uint256 indexed proposalId,
        uint256 indexed _shardPoolId,
        bool isPassed
    );

    // user operation
    function createShard(
        Token721[] calldata Token721s,
        Token1155[] calldata Token1155s,
        string memory shardName,
        string memory shardSymbol,
        uint256 minWantTokenAmount,
        address wantToken
    ) external virtual returns (uint256 shardPoolId);

    function stakeETH(uint256 _shardPoolId) external payable virtual;

    function stake(uint256 _shardPoolId, uint256 amount) external virtual;

    function redeem(uint256 _shardPoolId, uint256 amount) external virtual;

    function redeemETH(uint256 _shardPoolId, uint256 amount) external virtual;

    function settle(uint256 _shardPoolId) external virtual;

    function redeemInSubscriptionFailed(uint256 _shardPoolId) external virtual;

    function usersWithdrawShardToken(uint256 _shardPoolId) external virtual;

    function creatorWithdrawWantToken(uint256 _shardPoolId) external virtual;

    function applyForBuyout(uint256 _shardPoolId, uint256 wantTokenAmount)
        external
        virtual
        returns (uint256 proposalId);

    function applyForBuyoutETH(uint256 _shardPoolId)
        external
        payable
        virtual
        returns (uint256 proposalId);

    function vote(uint256 _shardPoolId, bool isAgree) external virtual;

    function voteResultConfirm(uint256 _shardPoolId)
        external
        virtual
        returns (bool result);

    function exchangeForWantToken(uint256 _shardPoolId, uint256 shardAmount)
        external
        virtual
        returns (uint256 wantTokenAmount);

    function redeemForBuyoutFailed(uint256 _proposalId)
        external
        virtual
        returns (uint256 shardTokenAmount, uint256 wantTokenAmount);

    //governance operation
    function setShardsCreatorProportion(uint256 _shardsCreatorProportion)
        external
        virtual;

    function setPlatformProportion(uint256 _platformProportion)
        external
        virtual;

    function setTotalSupply(uint256 _totalSupply) external virtual;

    function setDeadlineForRedeem(uint256 _deadlineForRedeem) external virtual;

    function setDeadlineForStake(uint256 _deadlineForStake) external virtual;

    function setProfitProportionForDev(uint256 _profitProportionForDev)
        external
        virtual;

    function setShardsFarm(address _shardsFarm) external virtual;

    function setRegulator(address _regulator) external virtual;

    function setFactory(address _factory) external virtual;

    function setShardsFactory(address _shardsFactory) external virtual;

    function setRouter(address _router) external virtual;

    //admin operation
    function setPlatformFund(address _platformFund) external virtual;

    function setDev(address _dev) external virtual;

    //function shardAudit(uint256 _shardPoolId, bool isPassed) external virtual;

    //view function
    function getPrice(uint256 _shardPoolId)
        public
        view
        virtual
        returns (uint256 currentPrice);

    function getAllPools()
        external
        view
        virtual
        returns (uint256[] memory _pools);

    function getTokens(uint256 shardPoolId)
        external
        view
        virtual
        returns (Token721[] memory _token721s, Token1155[] memory _token1155s);
}

// File: contracts/interface/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function approve(address guy, uint256 wad) external returns (bool);
}

// File: contracts/interface/IShardToken.sol

pragma solidity 0.6.12;

interface IShardToken {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function burn(uint256 value) external;

    function mint(address to, uint256 value) external;

    function initialize(
        string memory _name,
        string memory _symbol,
        address market
    ) external;

    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256);
}

// File: contracts/interface/IShardsFactory.sol

pragma solidity 0.6.12;

interface IShardsFactory {
    event ShardTokenCreated(address shardToken);

    function createShardToken(
        uint256 poolId,
        string memory name,
        string memory symbol
    ) external returns (address shardToken);
}

// File: contracts/interface/IShardsFarm.sol

pragma solidity 0.6.12;

interface IShardsFarm {
    function add(
        uint256 poolId,
        address lpToken,
        address ethLpToken
    ) external;
}

// File: contracts/interface/IMarketRegulator.sol

pragma solidity 0.6.12;

interface IMarketRegulator {
    function IsInWhiteList(address wantToken)
        external
        view
        returns (bool inTheList);

    function IsInBlackList(uint256 _shardPoolId)
        external
        view
        returns (bool inTheList);
}

// File: contracts/interface/IBuyoutProposals.sol

pragma solidity 0.6.12;

contract DelegationStorage {
    address public governance;
    /**
     * @notice Implementation address for this contract
     */
    address public implementation;
}

contract IBuyoutProposalsStorge is DelegationStorage {
    address public regulator;
    address public market;

    uint256 public proposolIdCount;

    uint256 public voteLenth = 259200;

    mapping(uint256 => uint256) public proposalIds;

    mapping(uint256 => uint256[]) internal proposalsHistory;

    mapping(uint256 => Proposal) public proposals;

    mapping(uint256 => mapping(address => bool)) public voted;

    uint256 public passNeeded = 75;

    // n times higher than the market price to buyout
    uint256 public buyoutTimes = 100;

    uint256 internal constant max = 100;

    uint256 public buyoutProportion = 15;

    mapping(uint256 => uint256) allVotes;

    struct Proposal {
        uint256 votesReceived;
        uint256 voteTotal;
        bool passed;
        address submitter;
        uint256 voteDeadline;
        uint256 shardAmount;
        uint256 wantTokenAmount;
        uint256 buyoutTimes;
        uint256 price;
        bool isSubmitterWithDraw;
        uint256 shardPoolId;
        bool isFailedConfirmed;
        uint256 blockHeight;
        uint256 createTime;
    }
}

abstract contract IBuyoutProposals is IBuyoutProposalsStorge {
    function createProposal(
        uint256 _shardPoolId,
        uint256 shardBalance,
        uint256 wantTokenAmount,
        uint256 currentPrice,
        uint256 totalShardSupply,
        address submitter
    ) external virtual returns (uint256 proposalId, uint256 buyoutTimes);

    function vote(
        uint256 _shardPoolId,
        bool isAgree,
        address shard,
        address voter
    ) external virtual returns (uint256 proposalId, uint256 balance);

    function voteResultConfirm(uint256 _shardPoolId)
        external
        virtual
        returns (
            uint256 proposalId,
            bool result,
            address submitter,
            uint256 shardAmount,
            uint256 wantTokenAmount
        );

    function exchangeForWantToken(uint256 _shardPoolId, uint256 shardAmount)
        external
        view
        virtual
        returns (uint256 wantTokenAmount);

    function redeemForBuyoutFailed(uint256 _proposalId, address submitter)
        external
        virtual
        returns (
            uint256 _shardPoolId,
            uint256 shardTokenAmount,
            uint256 wantTokenAmount
        );

    function setBuyoutTimes(uint256 _buyoutTimes) external virtual;

    function setVoteLenth(uint256 _voteLenth) external virtual;

    function setPassNeeded(uint256 _passNeeded) external virtual;

    function setBuyoutProportion(uint256 _buyoutProportion) external virtual;

    function setMarket(address _market) external virtual;

    function setRegulator(address _regulator) external virtual;

    function getProposalsForExactPool(uint256 _shardPoolId)
        external
        view
        virtual
        returns (uint256[] memory _proposalsHistory);
}

// File: contracts/libraries/TransferHelper.sol

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// File: contracts/interface/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    function balanceOf(address owner) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// File: contracts/interface/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol


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

// File: contracts/libraries/NFTLibrary.sol

pragma solidity 0.6.12;




library NFTLibrary {
    using SafeMath for uint256;

    function getPrice(
        address tokenA,
        address tokenB,
        address factory
    ) internal view returns (uint256 currentPrice) {
        address lPTokenAddress =
            IUniswapV2Factory(factory).getPair(tokenA, tokenB);

        if (lPTokenAddress == address(0)) {
            return currentPrice;
        }

        (uint112 _reserve0, uint112 _reserve1, ) =
            IUniswapV2Pair(lPTokenAddress).getReserves();

        address token0 = IUniswapV2Pair(lPTokenAddress).token0();

        (uint112 reserve0, uint112 reserve1) =
            token0 == tokenA ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
        currentPrice = quote(1e18, reserve0, reserve1);
    }

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function balanceOf(address user, address lPTokenAddress)
        internal
        view
        returns (uint256 balance)
    {
        balance = IUniswapV2Pair(lPTokenAddress).balanceOf(user);
    }

    function getPair(
        address tokenA,
        address tokenB,
        address factory
    ) internal view returns (address pair) {
        pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
    }

    function tokenVerify(string memory tokenName, uint256 lenthLimit)
        internal
        pure
        returns (bool success)
    {
        bytes memory nameBytes = bytes(tokenName);
        uint256 nameLength = nameBytes.length;
        require(0 < nameLength && nameLength <= lenthLimit, "INVALID INPUT");
        success = true;
        bool n7;
        for (uint256 i = 0; i <= nameLength - 1; i++) {
            n7 = (nameBytes[i] & 0x80) == 0x80 ? true : false;
            if (n7) {
                success = false;
                break;
            }
        }
    }
}

// File: openzeppelin-solidity/contracts/introspection/IERC165.sol



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

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721.sol



pragma solidity >=0.6.2 <0.8.0;


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

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol



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

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Holder.sol



pragma solidity >=0.6.0 <0.8.0;


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

// File: openzeppelin-solidity/contracts/token/ERC1155/IERC1155.sol



pragma solidity >=0.6.2 <0.8.0;


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

// File: openzeppelin-solidity/contracts/token/ERC1155/IERC1155Receiver.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// File: openzeppelin-solidity/contracts/introspection/ERC165.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC1155/ERC1155Receiver.sol



pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// File: openzeppelin-solidity/contracts/token/ERC1155/ERC1155Holder.sol



pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: contracts/interface/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);
}

// File: contracts/interface/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {}

// File: contracts/ShardsMarketDelegateV0.sol

pragma solidity 0.6.12;
















contract ShardsMarketDelegateV0 is IShardsMarket, ERC721Holder, ERC1155Holder {
    using SafeMath for uint256;

    constructor() public {}

    function initialize(
        address _WETH,
        address _factory,
        address _governance,
        address _router,
        address _dev,
        address _platformFund,
        address _shardsFactory,
        address _regulator,
        address _buyoutProposals
    ) public {
        require(admin == msg.sender, "UNAUTHORIZED");
        require(WETH == address(0), "ALREADY INITIALIZED");
        WETH = _WETH;
        factory = _factory;
        governance = _governance;
        router = _router;
        dev = _dev;
        platformFund = _platformFund;
        shardsFactory = _shardsFactory;
        regulator = _regulator;
        buyoutProposals = _buyoutProposals;
    }

    function createShard(
        Token721[] calldata token721s,
        Token1155[] calldata token1155s,
        string memory shardName,
        string memory shardSymbol,
        uint256 minWantTokenAmount,
        address wantToken
    ) external override returns (uint256 shardPoolId) {
        require(
            NFTLibrary.tokenVerify(shardName, 30) &&
                NFTLibrary.tokenVerify(shardSymbol, 30),
            "INVALID NAME/SYMBOL"
        );

        require(minWantTokenAmount > 0, "INVALID MINAMOUNT INPUT");
        require(
            IMarketRegulator(regulator).IsInWhiteList(wantToken),
            "WANTTOKEN IS NOT ON THE LIST"
        );
        shardPoolId = shardPoolIdCount.add(1);
        poolInfo[shardPoolId] = shardPool({
            creator: msg.sender,
            state: ShardsState.Live,
            createTime: block.timestamp,
            deadlineForStake: block.timestamp.add(deadlineForStake),
            deadlineForRedeem: block.timestamp.add(deadlineForRedeem),
            balanceOfWantToken: 0,
            minWantTokenAmount: minWantTokenAmount,
            isCreatorWithDraw: false,
            wantToken: wantToken,
            openingPrice: 0
        });

        _transferIn(shardPoolId, token721s, token1155s, msg.sender);

        uint256 creatorAmount =
            totalSupply.mul(shardsCreatorProportion).div(max);
        uint256 platformAmount = totalSupply.mul(platformProportion).div(max);
        uint256 stakersAmount =
            totalSupply.sub(creatorAmount).sub(platformAmount);
        shardInfo[shardPoolId] = shard({
            shardName: shardName,
            shardSymbol: shardSymbol,
            shardToken: address(0),
            totalShardSupply: totalSupply,
            shardForCreator: creatorAmount,
            shardForPlatform: platformAmount,
            shardForStakers: stakersAmount,
            burnAmount: 0
        });
        allPools.push(shardPoolId);
        shardPoolIdCount = shardPoolId;
        emit ShardCreated(
            shardPoolId,
            msg.sender,
            shardName,
            shardSymbol,
            minWantTokenAmount,
            block.timestamp,
            totalSupply,
            wantToken
        );
    }

    function stake(uint256 _shardPoolId, uint256 amount) external override {
        require(
            block.timestamp <= poolInfo[_shardPoolId].deadlineForStake,
            "EXPIRED"
        );
        address wantToken = poolInfo[_shardPoolId].wantToken;
        TransferHelper.safeTransferFrom(
            wantToken,
            msg.sender,
            address(this),
            amount
        );
        _stake(_shardPoolId, amount);
    }

    function stakeETH(uint256 _shardPoolId) external payable override {
        require(
            block.timestamp <= poolInfo[_shardPoolId].deadlineForStake,
            "EXPIRED"
        );
        require(poolInfo[_shardPoolId].wantToken == WETH, "UNWANTED");
        IWETH(WETH).deposit{value: msg.value}();
        _stake(_shardPoolId, msg.value);
    }

    function _stake(uint256 _shardPoolId, uint256 amount) private {
        require(amount > 0, "INSUFFIENT INPUT");
        userInfo[_shardPoolId][msg.sender].amount = userInfo[_shardPoolId][
            msg.sender
        ]
            .amount
            .add(amount);
        poolInfo[_shardPoolId].balanceOfWantToken = poolInfo[_shardPoolId]
            .balanceOfWantToken
            .add(amount);
        emit Stake(msg.sender, _shardPoolId, amount);
    }

    function redeem(uint256 _shardPoolId, uint256 amount) external override {
        _redeem(_shardPoolId, amount);
        TransferHelper.safeTransfer(
            poolInfo[_shardPoolId].wantToken,
            msg.sender,
            amount
        );
        emit Redeem(msg.sender, _shardPoolId, amount);
    }

    function redeemETH(uint256 _shardPoolId, uint256 amount) external override {
        require(poolInfo[_shardPoolId].wantToken == WETH, "UNWANTED");
        _redeem(_shardPoolId, amount);
        IWETH(WETH).withdraw(amount);
        TransferHelper.safeTransferETH(msg.sender, amount);
        emit Redeem(msg.sender, _shardPoolId, amount);
    }

    function _redeem(uint256 _shardPoolId, uint256 amount) private {
        require(
            block.timestamp <= poolInfo[_shardPoolId].deadlineForRedeem,
            "EXPIRED"
        );
        require(amount > 0, "INSUFFIENT INPUT");
        userInfo[_shardPoolId][msg.sender].amount = userInfo[_shardPoolId][
            msg.sender
        ]
            .amount
            .sub(amount);
        poolInfo[_shardPoolId].balanceOfWantToken = poolInfo[_shardPoolId]
            .balanceOfWantToken
            .sub(amount);
    }

    function settle(uint256 _shardPoolId) external override {
        require(
            block.timestamp > poolInfo[_shardPoolId].deadlineForRedeem,
            "NOT READY"
        );
        require(
            poolInfo[_shardPoolId].state == ShardsState.Live,
            "LIVE STATE IS REQUIRED"
        );
        if (
            poolInfo[_shardPoolId].balanceOfWantToken <
            poolInfo[_shardPoolId].minWantTokenAmount ||
            IMarketRegulator(regulator).IsInBlackList(_shardPoolId)
        ) {
            poolInfo[_shardPoolId].state = ShardsState.SubscriptionFailed;

            address shardCreator = poolInfo[_shardPoolId].creator;
            _transferOut(_shardPoolId, shardCreator);
            emit SettleFail(_shardPoolId);
        } else {
            _successToSetPrice(_shardPoolId);
        }
    }

    function redeemInSubscriptionFailed(uint256 _shardPoolId)
        external
        override
    {
        require(
            poolInfo[_shardPoolId].state == ShardsState.SubscriptionFailed,
            "WRONG STATE"
        );
        uint256 balance = userInfo[_shardPoolId][msg.sender].amount;
        require(balance > 0, "INSUFFIENT BALANCE");
        userInfo[_shardPoolId][msg.sender].amount = 0;
        poolInfo[_shardPoolId].balanceOfWantToken = poolInfo[_shardPoolId]
            .balanceOfWantToken
            .sub(balance);
        if (poolInfo[_shardPoolId].wantToken == WETH) {
            IWETH(WETH).withdraw(balance);
            TransferHelper.safeTransferETH(msg.sender, balance);
        } else {
            TransferHelper.safeTransfer(
                poolInfo[_shardPoolId].wantToken,
                msg.sender,
                balance
            );
        }

        emit Redeem(msg.sender, _shardPoolId, balance);
    }

    function usersWithdrawShardToken(uint256 _shardPoolId) external override {
        require(
            poolInfo[_shardPoolId].state == ShardsState.Listed ||
                poolInfo[_shardPoolId].state == ShardsState.Buyout ||
                poolInfo[_shardPoolId].state == ShardsState.ApplyForBuyout,
            "WRONG_STATE"
        );
        uint256 userBanlance = userInfo[_shardPoolId][msg.sender].amount;
        bool isWithdrawShard =
            userInfo[_shardPoolId][msg.sender].isWithdrawShard;
        require(userBanlance > 0 && !isWithdrawShard, "INSUFFIENT BALANCE");
        uint256 shardsForUsers = shardInfo[_shardPoolId].shardForStakers;
        uint256 totalBalance = poolInfo[_shardPoolId].balanceOfWantToken;
        // formula:
        // shardAmount/shardsForUsers= userBanlance/totalBalance
        //
        uint256 shardAmount =
            userBanlance.mul(shardsForUsers).div(totalBalance);
        userInfo[_shardPoolId][msg.sender].isWithdrawShard = true;
        IShardToken(shardInfo[_shardPoolId].shardToken).mint(
            msg.sender,
            shardAmount
        );
    }

    function creatorWithdrawWantToken(uint256 _shardPoolId) external override {
        require(msg.sender == poolInfo[_shardPoolId].creator, "UNAUTHORIZED");
        require(
            poolInfo[_shardPoolId].state == ShardsState.Listed ||
                poolInfo[_shardPoolId].state == ShardsState.Buyout ||
                poolInfo[_shardPoolId].state == ShardsState.ApplyForBuyout,
            "WRONG_STATE"
        );

        require(!poolInfo[_shardPoolId].isCreatorWithDraw, "ALREADY WITHDRAW");
        uint256 totalBalance = poolInfo[_shardPoolId].balanceOfWantToken;
        uint256 platformAmount = shardInfo[_shardPoolId].shardForPlatform;
        uint256 fee =
            poolInfo[_shardPoolId].balanceOfWantToken.mul(platformAmount).div(
                shardInfo[_shardPoolId].shardForStakers
            );
        uint256 amount = totalBalance.sub(fee);
        poolInfo[_shardPoolId].isCreatorWithDraw = true;
        if (poolInfo[_shardPoolId].wantToken == WETH) {
            IWETH(WETH).withdraw(amount);
            TransferHelper.safeTransferETH(msg.sender, amount);
        } else {
            TransferHelper.safeTransfer(
                poolInfo[_shardPoolId].wantToken,
                msg.sender,
                amount
            );
        }
        uint256 creatorAmount = shardInfo[_shardPoolId].shardForCreator;
        address shardToken = shardInfo[_shardPoolId].shardToken;
        IShardToken(shardToken).mint(
            poolInfo[_shardPoolId].creator,
            creatorAmount
        );
    }

    function applyForBuyout(uint256 _shardPoolId, uint256 wantTokenAmount)
        external
        override
        returns (uint256 proposalId)
    {
        proposalId = _applyForBuyout(_shardPoolId, wantTokenAmount);
    }

    function applyForBuyoutETH(uint256 _shardPoolId)
        external
        payable
        override
        returns (uint256 proposalId)
    {
        require(poolInfo[_shardPoolId].wantToken == WETH, "UNWANTED");
        proposalId = _applyForBuyout(_shardPoolId, msg.value);
    }

    function _applyForBuyout(uint256 _shardPoolId, uint256 wantTokenAmount)
        private
        returns (uint256 proposalId)
    {
        require(msg.sender == tx.origin, "INVALID SENDER");
        require(
            poolInfo[_shardPoolId].state == ShardsState.Listed,
            "LISTED STATE IS REQUIRED"
        );
        uint256 shardBalance =
            IShardToken(shardInfo[_shardPoolId].shardToken).balanceOf(
                msg.sender
            );
        uint256 totalShardSupply = shardInfo[_shardPoolId].totalShardSupply;

        uint256 currentPrice = getPrice(_shardPoolId);
        uint256 buyoutTimes;
        (proposalId, buyoutTimes) = IBuyoutProposals(buyoutProposals)
            .createProposal(
            _shardPoolId,
            shardBalance,
            wantTokenAmount,
            currentPrice,
            totalShardSupply,
            msg.sender
        );
        if (
            poolInfo[_shardPoolId].wantToken == WETH &&
            msg.value == wantTokenAmount
        ) {
            IWETH(WETH).deposit{value: wantTokenAmount}();
        } else {
            TransferHelper.safeTransferFrom(
                poolInfo[_shardPoolId].wantToken,
                msg.sender,
                address(this),
                wantTokenAmount
            );
        }
        TransferHelper.safeTransferFrom(
            shardInfo[_shardPoolId].shardToken,
            msg.sender,
            address(this),
            shardBalance
        );

        poolInfo[_shardPoolId].state = ShardsState.ApplyForBuyout;

        emit ApplyForBuyout(
            msg.sender,
            proposalId,
            _shardPoolId,
            shardBalance,
            wantTokenAmount,
            block.timestamp,
            buyoutTimes,
            currentPrice,
            block.number
        );
    }

    function vote(uint256 _shardPoolId, bool isAgree) external override {
        require(
            poolInfo[_shardPoolId].state == ShardsState.ApplyForBuyout,
            "WRONG STATE"
        );
        address shard = shardInfo[_shardPoolId].shardToken;

        (uint256 proposalId, uint256 balance) =
            IBuyoutProposals(buyoutProposals).vote(
                _shardPoolId,
                isAgree,
                shard,
                msg.sender
            );
        emit Vote(msg.sender, proposalId, _shardPoolId, isAgree, balance);
    }

    function voteResultConfirm(uint256 _shardPoolId)
        external
        override
        returns (bool)
    {
        require(
            poolInfo[_shardPoolId].state == ShardsState.ApplyForBuyout,
            "WRONG STATE"
        );
        (
            uint256 proposalId,
            bool result,
            address submitter,
            uint256 shardAmount,
            uint256 wantTokenAmount
        ) = IBuyoutProposals(buyoutProposals).voteResultConfirm(_shardPoolId);

        if (result) {
            poolInfo[_shardPoolId].state = ShardsState.Buyout;
            IShardToken(shardInfo[_shardPoolId].shardToken).burn(shardAmount);
            shardInfo[_shardPoolId].burnAmount = shardInfo[_shardPoolId]
                .burnAmount
                .add(shardAmount);

            _transferOut(_shardPoolId, submitter);

            _getProfit(_shardPoolId, wantTokenAmount, shardAmount);
        } else {
            poolInfo[_shardPoolId].state = ShardsState.Listed;
        }

        emit VoteResultConfirm(proposalId, _shardPoolId, result);

        return result;
    }

    function exchangeForWantToken(uint256 _shardPoolId, uint256 shardAmount)
        external
        override
        returns (uint256 wantTokenAmount)
    {
        require(
            poolInfo[_shardPoolId].state == ShardsState.Buyout,
            "WRONG STATE"
        );
        TransferHelper.safeTransferFrom(
            shardInfo[_shardPoolId].shardToken,
            msg.sender,
            address(this),
            shardAmount
        );
        IShardToken(shardInfo[_shardPoolId].shardToken).burn(shardAmount);
        shardInfo[_shardPoolId].burnAmount = shardInfo[_shardPoolId]
            .burnAmount
            .add(shardAmount);

        wantTokenAmount = IBuyoutProposals(buyoutProposals)
            .exchangeForWantToken(_shardPoolId, shardAmount);
        require(wantTokenAmount > 0, "LESS THAN 1 WEI");
        if (poolInfo[_shardPoolId].wantToken == WETH) {
            IWETH(WETH).withdraw(wantTokenAmount);
            TransferHelper.safeTransferETH(msg.sender, wantTokenAmount);
        } else {
            TransferHelper.safeTransfer(
                poolInfo[_shardPoolId].wantToken,
                msg.sender,
                wantTokenAmount
            );
        }
    }

    function redeemForBuyoutFailed(uint256 _proposalId)
        external
        override
        returns (uint256 shardTokenAmount, uint256 wantTokenAmount)
    {
        uint256 shardPoolId;
        (shardPoolId, shardTokenAmount, wantTokenAmount) = IBuyoutProposals(
            buyoutProposals
        )
            .redeemForBuyoutFailed(_proposalId, msg.sender);
        TransferHelper.safeTransfer(
            shardInfo[shardPoolId].shardToken,
            msg.sender,
            shardTokenAmount
        );
        if (poolInfo[shardPoolId].wantToken == WETH) {
            IWETH(WETH).withdraw(wantTokenAmount);
            TransferHelper.safeTransferETH(msg.sender, wantTokenAmount);
        } else {
            TransferHelper.safeTransfer(
                poolInfo[shardPoolId].wantToken,
                msg.sender,
                wantTokenAmount
            );
        }
    }

    function _successToSetPrice(uint256 _shardPoolId) private {
        address shardToken = _deployShardsToken(_shardPoolId);
        poolInfo[_shardPoolId].state = ShardsState.Listed;
        shardInfo[_shardPoolId].shardToken = shardToken;
        address wantToken = poolInfo[_shardPoolId].wantToken;
        uint256 platformAmount = shardInfo[_shardPoolId].shardForPlatform;
        IShardToken(shardToken).mint(address(this), platformAmount);
        uint256 shardPrice =
            poolInfo[_shardPoolId].balanceOfWantToken.mul(1e18).div(
                shardInfo[_shardPoolId].shardForStakers
            );
        //fee= shardPrice * platformAmount =balanceOfWantToken * platformAmount / shardForStakers
        uint256 fee =
            poolInfo[_shardPoolId].balanceOfWantToken.mul(platformAmount).div(
                shardInfo[_shardPoolId].shardForStakers
            );
        poolInfo[_shardPoolId].openingPrice = shardPrice;
        //addLiquidity
        TransferHelper.safeApprove(shardToken, router, platformAmount);
        TransferHelper.safeApprove(wantToken, router, fee);
        IUniswapV2Router02(router).addLiquidity(
            shardToken,
            wantToken,
            platformAmount,
            fee,
            0,
            0,
            address(this),
            now.add(60)
        );

        _addFarmPool(_shardPoolId);

        emit SettleSuccess(
            _shardPoolId,
            platformAmount,
            shardInfo[_shardPoolId].shardForStakers,
            poolInfo[_shardPoolId].balanceOfWantToken,
            fee,
            shardToken
        );
    }

    function _getProfit(
        uint256 _shardPoolId,
        uint256 wantTokenAmount,
        uint256 shardAmount
    ) private {
        address shardToken = shardInfo[_shardPoolId].shardToken;
        address wantToken = poolInfo[_shardPoolId].wantToken;

        address lPTokenAddress =
            NFTLibrary.getPair(shardToken, wantToken, factory);
        uint256 LPTokenBalance =
            NFTLibrary.balanceOf(address(this), lPTokenAddress);
        TransferHelper.safeApprove(lPTokenAddress, router, LPTokenBalance);
        (uint256 amountShardToken, uint256 amountWantToken) =
            IUniswapV2Router02(router).removeLiquidity(
                shardToken,
                wantToken,
                LPTokenBalance,
                0,
                0,
                address(this),
                now.add(60)
            );
        IShardToken(shardInfo[_shardPoolId].shardToken).burn(amountShardToken);
        shardInfo[_shardPoolId].burnAmount = shardInfo[_shardPoolId]
            .burnAmount
            .add(amountShardToken);
        uint256 supply = shardInfo[_shardPoolId].totalShardSupply;
        uint256 wantTokenAmountForExchange =
            amountShardToken.mul(wantTokenAmount).div(supply.sub(shardAmount));
        uint256 totalProfit = amountWantToken.add(wantTokenAmountForExchange);
        uint256 profitForDev = totalProfit.mul(profitProportionForDev).div(max);
        uint256 profitForPlatformFund = totalProfit.sub(profitForDev);
        TransferHelper.safeTransfer(wantToken, dev, profitForDev);
        TransferHelper.safeTransfer(
            wantToken,
            platformFund,
            profitForPlatformFund
        );
    }

    function _transferIn(
        uint256 shardPoolId,
        Token721[] calldata token721s,
        Token1155[] calldata token1155s,
        address from
    ) private {
        require(
            token721s.length.add(token1155s.length) > 0,
            "INSUFFIENT TOKEN"
        );
        for (uint256 i = 0; i < token721s.length; i++) {
            Token721 memory token = token721s[i];
            Token721s[shardPoolId].push(token);

            IERC721(token.contractAddress).safeTransferFrom(
                from,
                address(this),
                token.tokenId
            );
        }
        for (uint256 i = 0; i < token1155s.length; i++) {
            Token1155 memory token = token1155s[i];
            require(token.amount > 0, "INSUFFIENT TOKEN");
            Token1155s[shardPoolId].push(token);
            IERC1155(token.contractAddress).safeTransferFrom(
                from,
                address(this),
                token.tokenId,
                token.amount,
                ""
            );
        }
    }

    function _transferOut(uint256 shardPoolId, address to) private {
        Token721[] memory token721s = Token721s[shardPoolId];
        Token1155[] memory token1155s = Token1155s[shardPoolId];
        for (uint256 i = 0; i < token721s.length; i++) {
            Token721 memory token = token721s[i];
            IERC721(token.contractAddress).safeTransferFrom(
                address(this),
                to,
                token.tokenId
            );
        }
        for (uint256 i = 0; i < token1155s.length; i++) {
            Token1155 memory token = token1155s[i];
            IERC1155(token.contractAddress).safeTransferFrom(
                address(this),
                to,
                token.tokenId,
                token.amount,
                ""
            );
        }
    }

    function _deployShardsToken(uint256 _shardPoolId)
        private
        returns (address token)
    {
        string memory name = shardInfo[_shardPoolId].shardName;
        string memory symbol = shardInfo[_shardPoolId].shardSymbol;
        token = IShardsFactory(shardsFactory).createShardToken(
            _shardPoolId,
            name,
            symbol
        );
    }

    function _addFarmPool(uint256 _shardPoolId) private {
        address shardToken = shardInfo[_shardPoolId].shardToken;
        address wantToken = poolInfo[_shardPoolId].wantToken;
        address lPTokenSwap =
            NFTLibrary.getPair(shardToken, wantToken, factory);

        address TokenToEthSwap =
            wantToken == WETH
                ? address(0)
                : NFTLibrary.getPair(wantToken, WETH, factory);

        IShardsFarm(shardsFarm).add(_shardPoolId, lPTokenSwap, TokenToEthSwap);
    }

    //governance operation
    function setDeadlineForStake(uint256 _deadlineForStake) external override {
        require(msg.sender == governance, "UNAUTHORIZED");
        deadlineForStake = _deadlineForStake;
    }

    function setDeadlineForRedeem(uint256 _deadlineForRedeem)
        external
        override
    {
        require(msg.sender == governance, "UNAUTHORIZED");
        deadlineForRedeem = _deadlineForRedeem;
    }

    function setShardsCreatorProportion(uint256 _shardsCreatorProportion)
        external
        override
    {
        require(msg.sender == governance, "UNAUTHORIZED");
        require(_shardsCreatorProportion < max, "INVALID");
        shardsCreatorProportion = _shardsCreatorProportion;
    }

    function setPlatformProportion(uint256 _platformProportion)
        external
        override
    {
        require(msg.sender == governance, "UNAUTHORIZED");
        require(_platformProportion < max, "INVALID");
        platformProportion = _platformProportion;
    }

    function setTotalSupply(uint256 _totalSupply) external override {
        require(msg.sender == governance, "UNAUTHORIZED");
        totalSupply = _totalSupply;
    }

    function setProfitProportionForDev(uint256 _profitProportionForDev)
        external
        override
    {
        require(msg.sender == governance, "UNAUTHORIZED");
        profitProportionForDev = _profitProportionForDev;
    }

    function setShardsFarm(address _shardsFarm) external override {
        require(msg.sender == governance, "UNAUTHORIZED");
        shardsFarm = _shardsFarm;
    }

    function setRegulator(address _regulator) external override {
        require(msg.sender == governance, "UNAUTHORIZED");
        regulator = _regulator;
    }

    function setFactory(address _factory) external override {
        require(msg.sender == governance, "UNAUTHORIZED");
        factory = _factory;
    }

    function setShardsFactory(address _shardsFactory) external override {
        require(msg.sender == governance, "UNAUTHORIZED");
        shardsFactory = _shardsFactory;
    }

    function setRouter(address _router) external override {
        require(msg.sender == governance, "UNAUTHORIZED");
        router = _router;
    }

    //admin operation
    function setPlatformFund(address _platformFund) external override {
        require(msg.sender == admin, "UNAUTHORIZED");
        platformFund = _platformFund;
    }

    function setDev(address _dev) external override {
        require(msg.sender == admin, "UNAUTHORIZED");
        dev = _dev;
    }

    //pending function  not use right now

    // function shardAudit(uint256 _shardPoolId, bool isPassed) external override {
    //     require(msg.sender == admin, "UNAUTHORIZED");
    //     require(
    //         poolInfo[_shardPoolId].state == ShardsState.Pending,
    //         "WRONG STATE"
    //     );
    //     if (isPassed) {
    //         poolInfo[_shardPoolId].state = ShardsState.Live;
    //     } else {
    //         poolInfo[_shardPoolId].state = ShardsState.AuditFailed;
    //         address shardCreator = poolInfo[_shardPoolId].creator;
    //         _transferOut(_shardPoolId, shardCreator);
    //     }
    // }

    //view function
    function getPrice(uint256 _shardPoolId)
        public
        view
        override
        returns (uint256 currentPrice)
    {
        address tokenA = shardInfo[_shardPoolId].shardToken;
        address tokenB = poolInfo[_shardPoolId].wantToken;
        currentPrice = NFTLibrary.getPrice(tokenA, tokenB, factory);
    }

    function getAllPools()
        external
        view
        override
        returns (uint256[] memory _pools)
    {
        _pools = allPools;
    }

    function getTokens(uint256 shardPoolId)
        external
        view
        override
        returns (Token721[] memory _token721s, Token1155[] memory _token1155s)
    {
        _token721s = Token721s[shardPoolId];
        _token1155s = Token1155s[shardPoolId];
    }
}