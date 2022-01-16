pragma solidity ^0.8.0;


import "../common/variables.sol";

contract ReadModule is Variables {

    function poolEnabled(address pool_) external view returns (bool) {
        return poolEnabled_[pool_];
    }

    // Return true if the NFT is deposited and the owner is the owner_
    function position(address owner_, uint NFTID_) external view returns (bool) {
        return _position[owner_][NFTID_];
    }

    function isStaked(uint NFTID_) external view returns (bool) {
        return _isStaked[NFTID_];
    }

    function minTick(address pool_) external view returns (uint) {
        return _minTick[pool_];
    }

    function borrowBalRaw(uint NFTID_, address token_) external view returns (uint) {
        return _borrowBalRaw[NFTID_][token_];
    }

    function borrowAllowed(address pool_, address token_) external view returns (bool) {
        return _borrowAllowed[pool_][token_];
    }

    function poolMarkets(address pool_) external view returns (address[] memory) {
        return _poolMarkets[pool_];
    }

    function borrowLimit(address pool_) external view returns (uint128 normal_, uint128 extended_) {
        normal_ = _borrowLimit[pool_].normal;
        extended_ = _borrowLimit[pool_].extended;
    }

    function priceSlippage(address pool_) external view returns (uint) {
        return _priceSlippage[pool_];
    }

    function tickCheck(address pool_) external view returns (TickCheck memory tickCheck_) {
        tickCheck_= _tickCheck[pool_];
    }

}

pragma solidity ^0.8.0;


import "../../common/ILiquidity.sol";

contract Variables {

    // status for re-entrancy. 1 = allow/non-entered, 2 = disallow/entered
    uint256 internal _status;

    ILiquidity constant internal liquidity = ILiquidity(address(0xAFA64764FE83E6796df18De44b739074D68Fd715)); // TODO: add the core liquidity address

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