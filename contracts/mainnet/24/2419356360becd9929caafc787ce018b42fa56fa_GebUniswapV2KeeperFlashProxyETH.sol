/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

pragma solidity 0.6.7;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


abstract contract AuctionHouseLike {
    function bids(uint256) virtual external view returns (uint, uint);
    function buyCollateral(uint256 id, uint256 wad) external virtual;
    function liquidationEngine() view public virtual returns (LiquidationEngineLike);
    function collateralType() view public virtual returns (bytes32);
}

abstract contract SAFEEngineLike {
    mapping (bytes32 => mapping (address => uint256))  public tokenCollateral;  // [wad]
    function canModifySAFE(address, address) virtual public view returns (uint);
    function collateralTypes(bytes32) virtual public view returns (uint, uint, uint, uint, uint);
    function coinBalance(address) virtual public view returns (uint);
    function safes(bytes32, address) virtual public view returns (uint, uint);
    function modifySAFECollateralization(bytes32, address, address, address, int, int) virtual public;
    function approveSAFEModification(address) virtual public;
    function transferInternalCoins(address, address, uint) virtual public;
}

abstract contract CollateralJoinLike {
    function decimals() virtual public returns (uint);
    function collateral() virtual public returns (CollateralLike);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;
}

abstract contract CoinJoinLike {
    function safeEngine() virtual public returns (SAFEEngineLike);
    function systemCoin() virtual public returns (CollateralLike);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;
}

abstract contract CollateralLike {
    function approve(address, uint) virtual public;
    function transfer(address, uint) virtual public;
    function transferFrom(address, address, uint) virtual public;
    function deposit() virtual public payable;
    function withdraw(uint) virtual public;
    function balanceOf(address) virtual public view returns (uint);
}

abstract contract LiquidationEngineLike {
    function chosenSAFESaviour(bytes32, address) virtual public view returns (address);
    function safeSaviours(address) virtual public view returns (uint256);
    function liquidateSAFE(bytes32 collateralType, address safe) virtual external returns (uint256 auctionId);
    function safeEngine() view public virtual returns (SAFEEngineLike);
}

/// @title GEB Keeper Flash Proxy
/// @notice Trustless proxy that facilitates SAFE liquidation and bidding in auctions using Uniswap V2 flashswaps
/// @notice Single collateral version, only meant to work with ETH collateral types
contract GebUniswapV2KeeperFlashProxyETH {
    AuctionHouseLike       public auctionHouse;
    SAFEEngineLike         public safeEngine;
    CollateralLike         public weth;
    CollateralLike         public coin;
    CoinJoinLike           public coinJoin;
    CoinJoinLike           public ethJoin;
    IUniswapV2Pair         public uniswapPair;
    LiquidationEngineLike  public liquidationEngine;
    address payable        public caller;
    bytes32                public collateralType;

    uint256 public constant ZERO           = 0;
    uint256 public constant ONE            = 1;
    uint256 public constant THOUSAND       = 1000;
    uint256 public constant NET_OUT_AMOUNT = 997;

    /// @notice Constructor
    /// @param auctionHouseAddress Address of the auction house
    /// @param wethAddress WETH address
    /// @param systemCoinAddress System coin address
    /// @param uniswapPairAddress Uniswap V2 pair address
    /// @param coinJoinAddress CoinJoin address
    /// @param ethJoinAddress ETHJoin address
    constructor(
        address auctionHouseAddress,
        address wethAddress,
        address systemCoinAddress,
        address uniswapPairAddress,
        address coinJoinAddress,
        address ethJoinAddress
    ) public {
        require(auctionHouseAddress != address(0), "GebUniswapV2KeeperFlashProxyETH/null-auction-house");
        require(wethAddress != address(0), "GebUniswapV2KeeperFlashProxyETH/null-weth");
        require(systemCoinAddress != address(0), "GebUniswapV2KeeperFlashProxyETH/null-system-coin");
        require(uniswapPairAddress != address(0), "GebUniswapV2KeeperFlashProxyETH/null-uniswap-pair");
        require(coinJoinAddress != address(0), "GebUniswapV2KeeperFlashProxyETH/null-coin-join");
        require(ethJoinAddress != address(0), "GebUniswapV2KeeperFlashProxyETH/null-eth-join");

        auctionHouse        = AuctionHouseLike(auctionHouseAddress);
        weth                = CollateralLike(wethAddress);
        coin                = CollateralLike(systemCoinAddress);
        uniswapPair         = IUniswapV2Pair(uniswapPairAddress);
        coinJoin            = CoinJoinLike(coinJoinAddress);
        ethJoin             = CoinJoinLike(ethJoinAddress);
        collateralType      = auctionHouse.collateralType();
        liquidationEngine   = auctionHouse.liquidationEngine();
        safeEngine          = liquidationEngine.safeEngine();

        safeEngine.approveSAFEModification(address(auctionHouse));
    }

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "GebUniswapV2KeeperFlashProxyETH/add-overflow");
    }
    function subtract(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "GebUniswapV2KeeperFlashProxyETH/sub-underflow");
    }
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == ZERO || (z = x * y) / y == x, "GebUniswapV2KeeperFlashProxyETH/mul-overflow");
    }
    function wad(uint rad) internal pure returns (uint) {
        return rad / 10 ** 27;
    }

    // --- External Utils ---
    /// @notice Bids in a single auction
    /// @param auctionId Auction Id
    /// @param amount Amount to bid
    function bid(uint auctionId, uint amount) external {
        require(msg.sender == address(this), "GebUniswapV2KeeperFlashProxyETH/only-self");
        auctionHouse.buyCollateral(auctionId, amount);
    }
    /// @notice Bids in multiple auctions atomically
    /// @param auctionIds Auction IDs
    /// @param amounts Amounts to bid
    function multipleBid(uint[] calldata auctionIds, uint[] calldata amounts) external {
        require(msg.sender == address(this), "GebUniswapV2KeeperFlashProxyETH/only-self");
        for (uint i = ZERO; i < auctionIds.length; i++) {
            auctionHouse.buyCollateral(auctionIds[i], amounts[i]);
        }
    }
    /// @notice Callback for/from Uniswap V2
    /// @param _sender Requestor of the flashswap (must be this address)
    /// @param _amount0 Amount of token0
    /// @param _amount1 Amount of token1
    /// @param _data Data sent back from Uniswap
    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
        require(_sender == address(this), "GebUniswapV2KeeperFlashProxyETH/invalid-sender");
        require(msg.sender == address(uniswapPair), "GebUniswapV2KeeperFlashProxyETH/invalid-uniswap-pair");

        // join system coins
        uint amount = (_amount0 == ZERO ? _amount1 : _amount0);
        coin.approve(address(coinJoin), amount);
        coinJoin.join(address(this), amount);

        // bid
        (bool success, ) = address(this).call(_data);
        require(success, "GebUniswapV2KeeperFlashProxyETH/failed-bidding");

        // exit WETH
        ethJoin.exit(address(this), safeEngine.tokenCollateral(collateralType, address(this)));

        // repay loan
        uint pairBalanceTokenBorrow = coin.balanceOf(address(uniswapPair));
        uint pairBalanceTokenPay = weth.balanceOf(address(uniswapPair));
        uint amountToRepay = addition((
          multiply(multiply(THOUSAND, pairBalanceTokenPay), amount) /
          multiply(NET_OUT_AMOUNT, pairBalanceTokenBorrow)
        ), ONE);

        require(amountToRepay <= weth.balanceOf(address(this)), "GebUniswapV2KeeperFlashProxyETH/unprofitable");
        weth.transfer(address(uniswapPair), amountToRepay);

        // send profit back
        uint profit = weth.balanceOf(address(this));
        weth.withdraw(profit);
        caller.call{value: profit}("");
        caller = address(0x0);
    }

    // --- Internal Utils ---
    /// @notice Initiates a flashwap
    /// @param amount Amount to borrow
    /// @param data Callback data
    function _startSwap(uint amount, bytes memory data) internal {
        caller = msg.sender;

        uint amount0Out = address(coin) == uniswapPair.token0() ? amount : ZERO;
        uint amount1Out = address(coin) == uniswapPair.token1() ? amount : ZERO;

        uniswapPair.swap(amount0Out, amount1Out, address(this), data);
    }
    /// @notice Returns all available opportunities from a provided auction list
    /// @param auctionIds Auction IDs
    /// @return ids IDs of active auctions
    /// @return bidAmounts Rad amounts still requested by auctions
    /// @return totalAmount Wad amount to be borrowed
    function getOpenAuctionsBidSizes(uint[] memory auctionIds) internal returns (uint[] memory, uint[] memory, uint) {
        uint            amountToRaise;
        uint            totalAmount;
        uint            opportunityCount;

        uint[] memory   ids = new uint[](auctionIds.length);
        uint[] memory   bidAmounts = new uint[](auctionIds.length);

        for (uint i = ZERO; i < auctionIds.length; i++) {
            (, amountToRaise) = auctionHouse.bids(auctionIds[i]);

            if (amountToRaise > ZERO) {
                totalAmount                  = addition(totalAmount, addition(wad(amountToRaise), ONE));
                ids[opportunityCount]        = auctionIds[i];
                bidAmounts[opportunityCount] = amountToRaise;
                opportunityCount++;
            }
        }

        assembly {
            mstore(ids, opportunityCount)
            mstore(bidAmounts, opportunityCount)
        }

        return(ids, bidAmounts, totalAmount);
    }

    // --- Core Bidding and Settling Logic ---
    /// @notice Liquidates an underwater safe and settles the auction right away
    /// @dev It will revert for protected SAFEs (those that have saviours). Protected SAFEs need to be liquidated through the LiquidationEngine
    /// @param safe A SAFE's ID
    /// @return auction The auction ID
    function liquidateAndSettleSAFE(address safe) public returns (uint auction) {
        if (liquidationEngine.safeSaviours(liquidationEngine.chosenSAFESaviour(collateralType, safe)) == ONE) {
            require (liquidationEngine.chosenSAFESaviour(collateralType, safe) == address(0),
            "GebUniswapV2KeeperFlashProxyETH/safe-is-protected");
        }

        auction = liquidationEngine.liquidateSAFE(collateralType, safe);
        settleAuction(auction);
    }
    /// @notice Settle auction
    /// @param auctionId ID of the auction to be settled
    function settleAuction(uint auctionId) public {
        (, uint amountToRaise) = auctionHouse.bids(auctionId);
        require(amountToRaise > ZERO, "GebUniswapV2KeeperFlashProxyETH/auction-already-settled");

        bytes memory callbackData = abi.encodeWithSelector(this.bid.selector, auctionId, amountToRaise);

        _startSwap(addition(wad(amountToRaise), ONE), callbackData);
    }
    /// @notice Settle auctions
    /// @param auctionIds IDs of the auctions to be settled
    function settleAuction(uint[] memory auctionIds) public {
        (uint[] memory ids, uint[] memory bidAmounts, uint totalAmount) = getOpenAuctionsBidSizes(auctionIds);
        require(totalAmount > ZERO, "GebUniswapV2KeeperFlashProxyETH/all-auctions-already-settled");

        bytes memory callbackData = abi.encodeWithSelector(this.multipleBid.selector, ids, bidAmounts);

        _startSwap(totalAmount, callbackData);
    }

    // --- Fallback ---
    receive() external payable {
        require(msg.sender == address(weth), "GebUniswapV2KeeperFlashProxyETH/only-weth-withdrawals-allowed");
    }
}