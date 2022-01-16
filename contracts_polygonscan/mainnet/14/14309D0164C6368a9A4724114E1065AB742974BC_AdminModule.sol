pragma solidity ^0.8.0;


import "../common/variables.sol";
import "./events.sol";
import "../../../infiniteProxy/IProxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ERC20Interface is IERC20 {
    function decimals() external view returns (uint8);
}

interface IUniswapV3Pool {

    function token0() external view returns (address);

    function token1() external view returns (address);

}

contract AdminModule is Variables, Events {

    modifier onlyOwner {
        require(IProxy(address(this)).getAdmin() == msg.sender, "not-an-admin");
        _;
    }

    modifier poolEnabled(address pool_) {
        require(poolEnabled_[pool_], "pool-not-enabled");
        _;
    }
    
    /**
    * @dev To list a new pool to allow borrowing.
    * @param pool_ address of uniswap pool
    * @param minTick_ minimum tick difference (upperTick - lowerTick) position should have
    * @param borrowLimitNormal_ borrow limit normal (subtract same token from borrow & supply side)
    * @param borrowLimitExtended_ borrow limit extended (total borrow / total deposit)
    * @param priceSlippage_ allowed price slippage of uniswapPrice + slippage < chainlinkPrice < uniswapPrice - slippage
    * @param tickSlippages_ ticks slippage. Tracking 5 past checkpoints to see the liquidator has not manipulated the pool
    * @param timeAgos_ time ago for checkpoint to check slippage.
    * @param borrowMarkets_ allowed tokens for borrow.
    */
    function listPool(
        address pool_,
        uint minTick_,
        uint128 borrowLimitNormal_,
        uint128 borrowLimitExtended_,
        uint priceSlippage_,
        uint24[] memory tickSlippages_,
        uint24[] memory timeAgos_,
        address[] memory borrowMarkets_,
        address[] memory oracles_
    ) external onlyOwner {
        require(!poolEnabled_[pool_], "pool-already-enabled");
        poolEnabled_[pool_] = true;
        updateMinTick(pool_, minTick_);
        addBorrowMarket(pool_, borrowMarkets_);
        updateBorrowLimit(pool_, borrowLimitNormal_, borrowLimitExtended_);
        updatePriceSlippage(pool_, priceSlippage_);
        updateTicksCheck(pool_, tickSlippages_, timeAgos_);
        addChainlinkOracle(borrowMarkets_, oracles_);
        emit listPoolLog(pool_);
    }

    /**
    * @dev To update min tick for NFT deposit
    * @param pool_ address of uniswap pool
    * @param minTick_ minimum tick difference (upperTick - lowerTick) position should have
    */
    function updateMinTick(address pool_, uint minTick_) public onlyOwner poolEnabled(pool_) {
        _minTick[pool_] = minTick_;
        emit updateMinTickLog(pool_, minTick_);
    }

    /**
    * @dev To list a new pool to allow borrowing.
    * @param pool_ address of uniswap pool
    * @param tokens_ allowed tokens for borrow.
    */
    function addBorrowMarket(
        address pool_,
        address[] memory tokens_
    ) public onlyOwner poolEnabled(pool_) {
        for (uint i = 0; i < tokens_.length; i++) {
            require(!_borrowAllowed[pool_][tokens_[i]], "market-already-exist");

            address[] memory markets_ = _poolMarkets[pool_];
            for (uint j = 0; j < markets_.length; j++) {
                require(markets_[j] != tokens_[i], "market-already-exist");
            }
            _poolMarkets[pool_].push(tokens_[i]);
            _borrowAllowed[pool_][tokens_[i]] = true;
        }

        // first 2 tokens in markets should always be token0 & token1
        require(_poolMarkets[pool_][0] == IUniswapV3Pool(pool_).token0(), "first-market-not-token0");
        require(_poolMarkets[pool_][1] == IUniswapV3Pool(pool_).token1(), "first-market-not-token1");

        emit addBorrowMarketLog(pool_, tokens_);
    }

    /**
    * @dev updates borrow Limit for a particular Uniswap pool. 85% = 8500, 90% = 9000.
    * @param pool_ address of uniswap pool
    * @param normal_ normal borrow limit
    * @param extended_ extended borrow limit
    */
    function updateBorrowLimit(address pool_, uint128 normal_, uint128 extended_) public onlyOwner poolEnabled(pool_) {
        _borrowLimit[pool_] = BorrowLimit(normal_, extended_);
        emit updateBorrowLimitLog(pool_, normal_, extended_);
    }

    /**
    * @dev enable a token for borrow. Needs to be already be added in markets.
    * @param pool_ address of uniswap pool
    * @param token_ address of token
    */
    function enableBorrow(address pool_, address token_) external onlyOwner poolEnabled(pool_) {
        require(!_borrowAllowed[pool_][token_], "token-already-enabled");
        bool isOk_;
        address[] memory markets_ = _poolMarkets[pool_];
        for (uint i = 0; i < markets_.length; i++) {
            if (markets_[i] == token_) {
                isOk_ = true;
                break;
            }
        }
        require(isOk_, "use-addBorrowMarket()");
        _borrowAllowed[pool_][token_] = true;

        emit enableBorrowLog(pool_, token_);
    }

    /**
    * @dev disable borrow for a specific token. Needs to be already be added in markets.
    * @param pool_ address of uniswap pool
    * @param token_ address of token
    */
    function disableBorrow(address pool_, address token_) external onlyOwner poolEnabled(pool_) {
        require(_borrowAllowed[pool_][token_], "token-already-disabled");
        _borrowAllowed[pool_][token_] = false;
        emit disableBorrowLog(pool_, token_);
    }

    /**
    * @dev updates the price slippage for a particular pool which is used to compare difference between Uniswap & Chainklink oracle
    * @param pool_ address of uniswap pool
    * @param priceSlippage_ max acceptable slippage. 1 = 0.01%, 100 = 1%.
    */
    function updatePriceSlippage(address pool_, uint priceSlippage_) public onlyOwner poolEnabled(pool_) {
        _priceSlippage[pool_] = priceSlippage_;
        emit updatePriceSlippageLog(pool_, priceSlippage_);
    }

    /**
    * @dev updates the max allowed ticks slippages at different time instant.
    * @param pool_ address of uniswap pool
    * @param tickSlippages_ 1 = 1 tick difference, 600 = 600 ticks differece
    * @param timeAgos_ time ago in seconds
    */
    function updateTicksCheck(
        address pool_,
        uint24[] memory tickSlippages_,
        uint24[] memory timeAgos_
    ) public onlyOwner poolEnabled(pool_) {
        require(tickSlippages_.length == 5, "length-should-be-5");
        require(timeAgos_.length == 5, "length-should-be-5");
        _tickCheck[pool_] = TickCheck(
            tickSlippages_[0],
            timeAgos_[0],
            tickSlippages_[1],
            timeAgos_[1],
            tickSlippages_[2],
            timeAgos_[2],
            tickSlippages_[3],
            timeAgos_[3],
            tickSlippages_[4],
            timeAgos_[4]
        );
        emit updateTicksCheckLog(pool_, tickSlippages_, timeAgos_);
    }

    function addChainlinkOracle(address[] memory tokens_, address[] memory oracles_) public onlyOwner {
        for (uint i = 0; i < tokens_.length; i++) {
            _chainlinkOracle[tokens_[i]] = oracles_[i];
        }
        emit addChainlinkOracleLog(tokens_, oracles_);
    }

}

pragma solidity ^0.8.0;


import "../../common/ILiquidity.sol";

contract Variables {

    // status for re-entrancy. 1 = allow/non-entered, 2 = disallow/entered
    uint256 internal _status;

    ILiquidity constant internal liquidity = ILiquidity(address(0x4EE6eCAD1c2Dae9f525404De8555724e3c35d07B)); // TODO: add the core liquidity address

    // pool => bool. To enable a pool
    mapping (address => bool) internal poolEnabled_;

    // owner => NFT ID => borrow Position details
    mapping (address => mapping (uint => bool)) internal _position;

    // NFT ID => staked Position details
    mapping (uint => bool) internal _isStaked;

    // rewards accrued at the time of unstaking. NFTID -> token address -> reward amount
    mapping (uint => mapping(address => uint)) internal _rewardAccrued;

    // pool => minimum tick. Minimum tick difference a position should have to deposit (upperTick - lowerTick)
    mapping (address => uint) internal _minTick;

    // NFT ID => token => uint
    mapping (uint => mapping (address => uint)) internal _borrowBalRaw;

    // pool => token => bool
    mapping (address => mapping (address => bool)) internal _borrowAllowed;

    // pool => array or tokens. Market of borrow tokens for particular pool.
    // first 2 markets are always token0 & token1
    mapping(address => address[]) internal _poolMarkets;

    // normal. 8500 = 0.85.
    // extended. 9500 = 0.95.
    // extended meaning max totalborrow/totalsupply ratio
    // normal meaning canceling the same token borrow & supply and calculate ratio from rest of the token meaining
    // if NFT has 1 ETH & 4000 USDC (at 1 ETH = 4000 USDC) and debt of 0.5 ETH & 5000 USDC then the ratio would be
    // extended = (2000 + 5000) / (4000 + 4000) = 7/8
    // normal = (0 + 1000) / (2000) = 1/2
    struct BorrowLimit {
        uint128 normal;
        uint128 extended;
    }

    // pool address => Borrow limit
    mapping (address => BorrowLimit) internal _borrowLimit;

    // pool => _priceSlippage
    // 1 = 0.01%. 10000 = 100%
    // used to check Uniswap and chainlink price
    mapping (address => uint) internal _priceSlippage;

    // Tick checkpoints
    // 5 checkpoints Eg:-
    // Past 10 sec.
    // Past 30 sec.
    // Past 60 sec.
    // Past 120 sec.
    // Past 300 sec.
    struct TickCheck {
        uint24 tickSlippage1;
        uint24 secsAgo1;
        uint24 tickSlippage2;
        uint24 secsAgo2;
        uint24 tickSlippage3;
        uint24 secsAgo3;
        uint24 tickSlippage4;
        uint24 secsAgo4;
        uint24 tickSlippage5;
        uint24 secsAgo5;
    }

    // pool => TickCheck
    mapping (address => TickCheck) internal _tickCheck;

    // token => oracle contract. Price in USD.
    mapping (address => address) internal _chainlinkOracle;

}

pragma solidity ^0.8.0;


contract Events {

    event listPoolLog(address indexed pool_);

    event updateMinTickLog(address indexed pool_, uint minTick_);

    event addBorrowMarketLog(address pool_, address[] tokens_);

    event updateBorrowLimitLog(address pool_, uint128 normal_, uint128 extended_);

    event enableBorrowLog(address pool_, address token_);

    event disableBorrowLog(address pool_, address token_);

    event updatePriceSlippageLog(address pool_, uint priceSlippage_);

    event updateTicksCheckLog(address pool_, uint24[] tickSlippages_, uint24[] timeAgos_);

    event setInitialBorrowRateLog(address token_);

    event addChainlinkOracleLog(address[] tokens_, address[] oracles_);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IProxy {

    function getAdmin() external view returns (address);

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

pragma solidity ^0.8.0;


interface ILiquidity {

    function supply(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function withdraw(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function borrow(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function payback(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function updateInterest(
        address token_
    ) external view returns (
        uint newSupplyExchangePrice,
        uint newBorrowExchangePrice
    );

    function isProtocol(address protocol_) external view returns (bool);

    function protocolSupplyLimit(address protocol_, address token_) external view returns (uint256);

    function protocolBorrowLimit(address protocol_, address token_) external view returns (uint256);

    function totalSupplyRaw(address token_) external view returns (uint256);

    function totalBorrowRaw(address token_) external view returns (uint256);

    function protocolRawSupply(address protocol_, address token_) external view returns (uint256);

    function protocolRawBorrow(address protocol_, address token_) external view returns (uint256);

    struct Rates {
        uint96 lastSupplyExchangePrice; // last stored exchange price. Increases overtime.
        uint96 lastBorrowExchangePrice; // last stored exchange price. Increases overtime.
        uint48 lastUpdateTime; // in sec
        uint16 utilization; // utilization. 10000 = 100%
    }

    function rate(address token_) external view returns (Rates memory);

}