/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/interfaces/IOAXDEX_OracleLiquidityProvider.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.6.11;

interface IOAXDEX_OracleLiquidityProvider {

    function factory() external view returns (address);
    function WETH() external view returns (address);
    function oaxToken() external view returns (address);

    // **** ADD LIQUIDITY ****
    function addLiquidity(
        address tokenA,
        address tokenB,
        bool addingTokenA,
        uint staked,
        uint afterIndex,
        uint amountIn,
        uint expire,
        uint deadline
    ) external returns (uint256 index);
    function addLiquidityETH(
        address tokenA,
        bool addingTokenA,
        uint staked,
        uint afterIndex,
        uint amountAIn,
        uint expire,
        uint deadline
    ) external payable returns (uint index);

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool removingTokenA,
        address to,
        uint unstake,
        uint afterIndex,
        uint amountOut,
        uint256 reserveOut, 
        uint expire,
        uint deadline
    ) external;
    function removeLiquidityETH(
        address tokenA,
        bool removingTokenA,
        address to,
        uint unstake,
        uint afterIndex,
        uint amountOut,
        uint256 reserveOut, 
        uint expire,
        uint deadline
    ) external;
    function removeAllLiquidity(
        address tokenA,
        address tokenB,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeAllLiquidityETH(
        address tokenA,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
}


// File contracts/interfaces/IOAXDEX_OraclePair.sol


pragma solidity =0.6.11;

interface IOAXDEX_OraclePair {
    struct Offer {
        address provider;
        uint256 staked;
        uint256 amount;
        uint256 reserve;
        uint256 expire;
        bool privateReplenish;
        bool isActive;
        uint256 prev;
        uint256 next;
    }

    event SetLive(bool isLive);
    event NewProvider(address indexed provider, uint256 index);
    event AddLiquidity(address indexed provider, bool indexed direction, uint256 staked, uint256 amount, uint256 expire);
    event Replenish(address indexed provider, bool indexed direction, uint256 amountIn, uint256 expire);
    event RemoveLiquidity(address indexed provider, bool indexed direction, uint256 unstake, uint256 amountOut, uint256 reserveOut, uint256 expire);
    event Swap(address indexed to, bool indexed direction, uint256 price, uint256 amountIn, uint256 amountOut, uint256 tradeFee, uint256 protocolFee);
    event SwappedOneProvider(address indexed provider, bool indexed direction, uint256 amountOut, uint256 amountIn);

    function counter() external view returns (uint256);
    function first(bool direction) external view returns (uint256);
    function queueSize(bool direction) external view returns (uint256);
    function offers(bool direction, uint256 index) external view returns (
        address provider,
        uint256 staked,
        uint256 amount,
        uint256 reserve,
        uint256 expire,
        bool privateReplenish,
        bool isActive,
        uint256 prev,
        uint256 next
    );
    function providerOfferIndex(address provider) external view returns (uint256 index);

    function factory() external view returns (address);
    function governance() external view returns (address);
    function oracleLiquidityProvider() external view returns (address);
    function oaxToken() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function scaleDirection() external view returns (bool);
    function scaler() external view returns (uint256);

    function lastOaxBalance() external view returns (uint256);
    function lastToken0Balance() external view returns (uint256);
    function lastToken1Balance() external view returns (uint256);
    function protocolFeeBalance0() external view returns (uint256);
    function protocolFeeBalance1() external view returns (uint256);

    function isLive() external view returns (bool);

    function getLastBalances() external view returns (uint256, uint256);
    function getBalances() external view returns (uint256, uint256, uint256);

    function getLatestPrice(bool direction, bytes calldata payload) external view returns (uint256);
    function getAmountOut(address tokenIn, uint256 amountIn, bytes calldata data) external view returns (uint256 amountOut);
    function getAmountIn(address tokenOut, uint256 amountOut, bytes calldata data) external view returns (uint256 amountIn);

    function getQueue(bool direction, uint256 start, uint256 end) external view returns (uint256[] memory index, address[] memory provider, uint256[] memory amount, uint256[] memory staked, uint256[] memory expire);
    function getQueueFromIndex(bool direction, uint256 from, uint256 count) external view returns (uint256[] memory index, address[] memory provider, uint256[] memory amount, uint256[] memory staked, uint256[] memory expire);
    function getProviderOffer(address _provider, bool direction) external view returns (uint256 index, uint256 staked, uint256 amount, uint256 reserve, uint256 expire, bool privateReplenish);
    function findPosition(bool direction, uint256 staked, uint256 _afterIndex) external view returns (uint256 afterIndex, uint256 nextIndex);
    function addLiquidity(address provider, bool direction, uint256 afterIndex, uint256 expire) external returns (uint256 index);
    function setPrivateReplenish(bool _replenish) external;
    function replenish(address provider, bool direction, uint256 afterIndex, uint amountIn, uint256 expire) external;
    function removeLiquidity(address provider, bool direction, uint256 unstake, uint256 afterIndex, uint256 amountOut, uint256 reserveOut, uint256 expire) external;
    function removeAllLiquidity(address provider) external returns (uint256 amount0, uint256 amount1, uint256 staked);
    function purgeExpire(bool direction, uint256 startingIndex, uint256 limit) external returns (uint256 purge);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function sync() external;

    function initialize(address _token0, address _token1) external;
    function setLive(bool _isLive) external;
    function redeemProtocolFee() external;
}


// File contracts/interfaces/IOAXDEX_PausableFactory.sol


pragma solidity =0.6.11;

interface IOAXDEX_PausableFactory {
    function isLive() external returns (bool);
    function setLive(bool _isLive) external;
    function setLiveForPair(address pair, bool live) external;
}


// File contracts/interfaces/IOAXDEX_FactoryBase.sol


pragma solidity =0.6.11;
interface IOAXDEX_FactoryBase is IOAXDEX_PausableFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint newSize);
    event Shutdowned();
    event Restarted();
    event PairShutdowned(address indexed pair);
    event PairRestarted(address indexed pair);

    function governance() external view returns (address);
    function pairCreator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}


// File contracts/interfaces/IOAXDEX_OracleFactory.sol


pragma solidity =0.6.11;
interface IOAXDEX_OracleFactory is IOAXDEX_FactoryBase {
    event ParamSet(bytes32 name, bytes32 value);
    event ParamSet2(bytes32 name, bytes32 value1, bytes32 value2);
    event OracleAdded(address indexed token0, address indexed token1, address oracle);
    event OracleScores(address indexed oracle, uint256 score);
    event Whitelisted(address indexed who, bool allow);

    function oracleLiquidityProvider() external view returns (address);

    function tradeFee() external view returns (uint256);
    function protocolFee() external view returns (uint256);
    function protocolFeeTo() external view returns (address);

    function securityScoreOracle() external view returns (address);
    function minOracleScore() external view returns (uint256);

    function oracles(address token0, address token1) external view returns (address oracle);
    function minLotSize(address token) external view returns (uint256);
    function isOracle(address) external view returns (bool);
    function oracleScores(address oracle) external view returns (uint256);

    function whitelisted(uint256) external view returns (address);
    function whitelistedInv(address) external view returns (uint256);
    function isWhitelisted(address) external returns (bool);

    function setOracleLiquidityProvider(address _oracleRouter, address _oracleLiquidityProvider) external;

    function setOracle(address from, address to, address oracle) external;
    function addOldOracleToNewPair(address from, address to, address oracle) external;
    function setTradeFee(uint256) external;
    function setProtocolFee(uint256) external;
    function setProtocolFeeTo(address) external;
    function setSecurityScoreOracle(address, uint256) external;
    function setMinLotSize(address token, uint256 _minLotSize) external;

    function updateOracleScore(address oracle) external;

    function whitelistedLength() external view returns (uint256);
    function allWhiteListed() external view returns(address[] memory list, bool[] memory allowed);
    function setWhiteList(address _who, bool _allow) external;

    function checkAndGetOracleSwapParams(address tokenA, address tokenB) external view returns (address oracle, uint256 _tradeFee, uint256 _protocolFee);
    function checkAndGetOracle(address tokenA, address tokenB) external view returns (address oracle);
}


// File contracts/interfaces/IOAXDEX_Governance.sol


pragma solidity =0.6.11;

interface IOAXDEX_Governance {

    struct NewStake {
        uint256 amount;
        uint256 timestamp;
    }
    struct VotingConfig {
        uint256 minExeDelay;
        uint256 minVoteDuration;
        uint256 maxVoteDuration;
        uint256 minOaxTokenToCreateVote;
        uint256 minQuorum;
    }

    event ParamSet(bytes32 indexed name, bytes32 value);
    event ParamSet2(bytes32 name, bytes32 value1, bytes32 value2);
    event AddVotingConfig(bytes32 name, 
        uint256 minExeDelay,
        uint256 minVoteDuration,
        uint256 maxVoteDuration,
        uint256 minOaxTokenToCreateVote,
        uint256 minQuorum);
    event SetVotingConfig(bytes32 indexed configName, bytes32 indexed paramName, uint256 minExeDelay);

    event Stake(address indexed who, uint256 value);
    event Unstake(address indexed who, uint256 value);

    event NewVote(address indexed vote);
    event NewPoll(address indexed poll);
    event Vote(address indexed account, address indexed vote, uint256 option);
    event Poll(address indexed account, address indexed poll, uint256 option);
    event Executed(address indexed vote);
    event Veto(address indexed vote);

    function votingConfigs(bytes32) external view returns (uint256 minExeDelay,
        uint256 minVoteDuration,
        uint256 maxVoteDuration,
        uint256 minOaxTokenToCreateVote,
        uint256 minQuorum);
    function votingConfigProfiles(uint256) external view returns (bytes32);

    function oaxToken() external view returns (address);
    function freezedStake(address) external view returns (uint256 amount, uint256 timestamp);
    function stakeOf(address) external view returns (uint256);
    function totalStake() external view returns (uint256);

    function votingRegister() external view returns (address);
    function votingExecutor(uint256) external view returns (address);
    function votingExecutorInv(address) external view returns (uint256);
    function isVotingExecutor(address) external view returns (bool);
    function admin() external view returns (address);
    function minStakePeriod() external view returns (uint256);

    function voteCount() external view returns (uint256);
    function votingIdx(address) external view returns (uint256);
    function votings(uint256) external view returns (address);


	function votingConfigProfilesLength() external view returns(uint256);
	function getVotingConfigProfiles(uint256 start, uint256 length) external view returns(bytes32[] memory profiles);
    function getVotingParams(bytes32) external view returns (uint256 _minExeDelay, uint256 _minVoteDuration, uint256 _maxVoteDuration, uint256 _minOaxTokenToCreateVote, uint256 _minQuorum);

    function setVotingRegister(address _votingRegister) external;
    function votingExecutorLength() external view returns (uint256);
    function initVotingExecutor(address[] calldata _setVotingExecutor) external;
    function setVotingExecutor(address _setVotingExecutor, bool _bool) external;
    function initAdmin(address _admin) external;
    function setAdmin(address _admin) external;
    function addVotingConfig(bytes32 name, uint256 minExeDelay, uint256 minVoteDuration, uint256 maxVoteDuration, uint256 minOaxTokenToCreateVote, uint256 minQuorum) external;
    function setVotingConfig(bytes32 configName, bytes32 paramName, uint256 paramValue) external;
    function setMinStakePeriod(uint _minStakePeriod) external;

    function stake(uint256 value) external;
    function unlockStake() external;
    function unstake(uint256 value) external;
    function allVotings() external view returns (address[] memory);
    function getVotingCount() external view returns (uint256);
    function getVotings(uint256 start, uint256 count) external view returns (address[] memory _votings);

    function isVotingContract(address votingContract) external view returns (bool);

    function getNewVoteId() external returns (uint256);
    function newVote(address vote, bool isExecutiveVote) external;
    function voted(bool poll, address account, uint256 option) external;
    function executed() external;
    function veto(address voting) external;
    function closeVote(address vote) external;
}


// File contracts/libraries/TransferHelper.sol


pragma solidity =0.6.11;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/libraries/SafeMath.sol



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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File contracts/interfaces/IERC20.sol


pragma solidity =0.6.11;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


// File contracts/interfaces/IWETH.sol


pragma solidity =0.6.11;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File contracts/OAXDEX_OracleLiquidityProvider.sol


pragma solidity =0.6.11;
contract OAXDEX_OracleLiquidityProvider is IOAXDEX_OracleLiquidityProvider {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WETH;
    address public immutable override oaxToken;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'OAXDEX_Router: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
        oaxToken = IOAXDEX_Governance(IOAXDEX_OracleFactory(_factory).governance()).oaxToken();
    }
    
    receive() external payable {
        require(msg.sender == WETH, 'OAXDEX_Router: Transfer failed'); // only accept ETH via fallback from the WETH contract
    }


    // **** ADD LIQUIDITY ****
    function addLiquidity(
        address tokenA,
        address tokenB,
        bool addingTokenA,
        uint staked,
        uint afterIndex,
        uint amountIn,
        uint expire,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint256 index) {
        // create the pair if it doesn't exist yet
        if (IOAXDEX_OracleFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IOAXDEX_OracleFactory(factory).createPair(tokenA, tokenB);
        }
        address pair = pairFor(tokenA, tokenB);

        if (staked > 0)
            TransferHelper.safeTransferFrom(oaxToken, msg.sender, pair, staked);
        if (amountIn > 0)
            TransferHelper.safeTransferFrom(addingTokenA ? tokenA : tokenB, msg.sender, pair, amountIn);

        bool direction = (tokenA < tokenB) ? !addingTokenA : addingTokenA;
        (index) = IOAXDEX_OraclePair(pair).addLiquidity(msg.sender, direction, afterIndex, expire);
    }
    function addLiquidityETH(
        address tokenA,
        bool addingTokenA,
        uint staked,
        uint afterIndex,
        uint amountAIn,
        uint expire,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint index) {
        // create the pair if it doesn't exist yet
        if (IOAXDEX_OracleFactory(factory).getPair(tokenA, WETH) == address(0)) {
            IOAXDEX_OracleFactory(factory).createPair(tokenA, WETH);
        }
        uint ETHIn = msg.value;
        address pair = pairFor(tokenA, WETH);

        if (staked > 0)
            TransferHelper.safeTransferFrom(oaxToken, msg.sender, pair, staked);

        if (addingTokenA) {
            if (amountAIn > 0)
                TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountAIn);
        } else {
            IWETH(WETH).deposit{value: ETHIn}();
            require(IWETH(WETH).transfer(pair, ETHIn), 'OAXDEX_Router: Transfer failed');
        }
        bool direction = (tokenA < WETH) ? !addingTokenA : addingTokenA;
        (index) = IOAXDEX_OraclePair(pair).addLiquidity(msg.sender, direction, afterIndex, expire);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool removingTokenA,
        address to,
        uint unstake,
        uint afterIndex,
        uint amountOut,
        uint256 reserveOut, 
        uint expire,
        uint deadline
    ) public virtual override ensure(deadline) {
        address pair = pairFor(tokenA, tokenB);
        bool direction = (tokenA < tokenB) ? !removingTokenA : removingTokenA;
        IOAXDEX_OraclePair(pair).removeLiquidity(msg.sender, direction, unstake, afterIndex, amountOut, reserveOut, expire);
        
        if (unstake > 0)
            TransferHelper.safeTransfer(oaxToken, to, unstake);
        if (amountOut > 0 || reserveOut > 0) {
            address token = removingTokenA ? tokenA : tokenB;
            TransferHelper.safeTransfer(token, to, amountOut.add(reserveOut));
        }
    }
    function removeLiquidityETH(
        address tokenA,
        bool removingTokenA,
        address to,
        uint unstake,
        uint afterIndex,
        uint amountOut,
        uint256 reserveOut, 
        uint expire,
        uint deadline
    ) public virtual override ensure(deadline) {
        address pair = pairFor(tokenA, WETH);
        bool direction = (tokenA < WETH) ? !removingTokenA : removingTokenA;
        IOAXDEX_OraclePair(pair).removeLiquidity(msg.sender, direction, unstake, afterIndex, amountOut, reserveOut, expire);

        if (unstake > 0)
            TransferHelper.safeTransfer(oaxToken, to, unstake);

        amountOut = amountOut.add(reserveOut);
        if (amountOut > 0) {
            if (removingTokenA) {
                TransferHelper.safeTransfer(tokenA, to, amountOut);
            } else {
                IWETH(WETH).withdraw(amountOut);
                TransferHelper.safeTransferETH(to, amountOut);
            }
        }
    }
    function removeAllLiquidity(
        address tokenA,
        address tokenB,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = pairFor(tokenA, tokenB);
        (uint256 amount0, uint256 amount1, uint256 staked) = IOAXDEX_OraclePair(pair).removeAllLiquidity(msg.sender);
        (amountA, amountB) = (tokenA < tokenB) ? (amount0, amount1) : (amount1, amount0);
        TransferHelper.safeTransfer(tokenA, to, amountA);
        TransferHelper.safeTransfer(tokenB, to, amountB);
        TransferHelper.safeTransfer(oaxToken, to, staked);  
    }
    function removeAllLiquidityETH(
        address tokenA,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        address pair = pairFor(tokenA, WETH);
        (uint256 amount0, uint256 amount1, uint256 staked) = IOAXDEX_OraclePair(pair).removeAllLiquidity(msg.sender);
        (amountToken, amountETH) = (tokenA < WETH) ? (amount0, amount1) : (amount1, amount0);
        TransferHelper.safeTransfer(tokenA, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
        TransferHelper.safeTransfer(oaxToken, to, staked);
    }

    // **** LIBRARY FUNCTIONS ****
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'OAXDEX_Router: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'OAXDEX_Router: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                /*oracle*/hex'2686095fecb101ea387966370b161d58b4782c9a95682190d80945491038f0e6' // oracle init code hash
            ))));
    }

}