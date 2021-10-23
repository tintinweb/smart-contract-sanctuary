/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

// File: contracts\interfaces\UniswapRouterInterfaceV5.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface UniswapRouterInterfaceV5{
	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapTokensForExactTokens(
		uint amountOut,
		uint amountInMax,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);
}

// File: contracts\interfaces\AggregatorInterfaceV5.sol

pragma solidity 0.8.7;

interface AggregatorInterfaceV5{
    enum OrderType { MARKET_OPEN, MARKET_CLOSE, LIMIT_OPEN, LIMIT_CLOSE }
    function getPrice(uint,OrderType,uint) external returns(uint);
    function tokenPriceDai() external view returns(uint);
    function pairMinOpenLimitSlippageP(uint) external view returns(uint);
    function closeFeeP(uint) external view returns(uint);
    function linkFee(uint,uint) external view returns(uint);
    function openFeeP(uint) external view returns(uint);
    function pairMinLeverage(uint) external view returns(uint);
    function pairMaxLeverage(uint) external view returns(uint);
    function pairsCount() external view returns(uint);
    function tokenDaiReservesLp() external view returns(uint, uint);
    function referralP(uint) external view returns(uint);
    function nftLimitOrderFeeP(uint) external view returns(uint);
}

// File: contracts\interfaces\TokenInterfaceV5.sol

pragma solidity 0.8.7;

interface TokenInterfaceV5{
    function burn(address, uint256) external;
    function mint(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint256);
    function hasRole(bytes32, address) external view returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

// File: contracts\interfaces\NftInterfaceV5.sol

pragma solidity 0.8.7;

interface NftInterfaceV5{
    function balanceOf(address) external view returns (uint);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function tokenOfOwnerByIndex(address, uint) external view returns(uint);
}

// File: contracts\interfaces\VaultInterfaceV5.sol

pragma solidity 0.8.7;

interface VaultInterfaceV5{
	function sendDaiToTrader(address, uint) external;
}

// File: contracts\interfaces\StorageInterfaceV5.sol

pragma solidity 0.8.7;






interface StorageInterfaceV5{
    enum LimitOrder { TP, SL, LIQ, OPEN }
    struct Trader{
        uint leverageUnlocked;
        address referral;
        uint referralRewardsTotal;  // 1e18
    }
    struct Trade{
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken;       // 1e18
        uint positionSizeDai;       // 1e18
        uint openPrice;             // PRECISION
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION
        uint sl;                    // PRECISION
    }
    struct TradeInfo{
        uint tokenId;
        uint tokenPriceDai;         // PRECISION
        uint openInterestDai;       // 1e18
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder{
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize;          // 1e18 (DAI or GFARM2)
        uint spreadReductionP;
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION (%)
        uint sl;                    // PRECISION (%)
        uint minPrice;              // PRECISION
        uint maxPrice;              // PRECISION
        uint block;
        uint tokenId;               // index in supportedTokens
    }
    struct PendingMarketOrder{
        Trade trade;
        uint block;
        uint wantedPrice;           // PRECISION
        uint slippageP;             // PRECISION (%)
        uint spreadReductionP;
        uint tokenId;               // index in supportedTokens
    }
    struct PendingNftOrder{
        address nftHolder;
        uint nftId;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }
    function PRECISION() external pure returns(uint);
    function gov() external view returns(address);
    function dev() external view returns(address);
    function dai() external view returns(TokenInterfaceV5);
    function token() external view returns(TokenInterfaceV5);
    function linkErc677() external view returns(TokenInterfaceV5);
    function tokenDaiRouter() external view returns(UniswapRouterInterfaceV5);
    function priceAggregator() external view returns(AggregatorInterfaceV5);
    function vault() external view returns(VaultInterfaceV5);
    function trading() external view returns(address);
    function callbacks() external view returns(address);
    function handleTokens(address,uint,bool) external;
    function transferDai(address, address, uint) external;
    function transferLinkToAggregator(address, uint, uint) external;
    function unregisterTrade(address, uint, uint) external;
    function unregisterPendingMarketOrder(uint, bool) external;
    function unregisterOpenLimitOrder(address, uint, uint) external;
    function hasOpenLimitOrder(address, uint, uint) external view returns(bool);
    function storePendingMarketOrder(PendingMarketOrder memory, uint, bool) external;
    function storeReferral(address, address) external;
    function openTrades(address, uint, uint) external view returns(Trade memory);
    function openTradesInfo(address, uint, uint) external view returns(TradeInfo memory);
    function updateSl(address, uint, uint, uint) external;
    function updateTp(address, uint, uint, uint) external;
    function getOpenLimitOrder(address, uint, uint) external view returns(OpenLimitOrder memory);
    function spreadReductionsP(uint) external view returns(uint);
    function positionSizeTokenDynamic(uint,uint) external view returns(uint);
    function maxSlP() external view returns(uint);
    function storeOpenLimitOrder(OpenLimitOrder memory) external;
    function reqID_pendingMarketOrder(uint) external view returns(PendingMarketOrder memory);
    function storePendingNftOrder(PendingNftOrder memory, uint) external;
    function updateOpenLimitOrder(OpenLimitOrder calldata) external;
    function firstEmptyTradeIndex(address, uint) external view returns(uint);
    function firstEmptyOpenLimitIndex(address, uint) external view returns(uint);
    function increaseNftRewards(uint, uint) external;
    function nftSuccessTimelock() external view returns(uint);
    function currentPercentProfit(uint,uint,bool,uint) external view returns(int);
    function reqID_pendingNftOrder(uint) external view returns(PendingNftOrder memory);
    function setNftLastSuccess(uint) external;
    function updateTrade(Trade memory) external;
    function nftLastSuccess(uint) external view returns(uint);
    function unregisterPendingNftOrder(uint) external;
    function handleDevGovFees(uint, uint, bool, bool) external returns(uint);
    function distributeLpRewards(uint) external;
    function getReferral(address) external view returns(address);
    function increaseReferralRewards(address, uint) external;
    function storeTrade(Trade memory, TradeInfo memory) external;
    function setLeverageUnlocked(address, uint) external;
    function getLeverageUnlocked(address) external view returns(uint);
    function openLimitOrdersCount(address, uint) external view returns(uint);
    function maxOpenLimitOrdersPerPair() external view returns(uint);
    function openTradesCount(address, uint) external view returns(uint);
    function pendingMarketOpenCount(address, uint) external view returns(uint);
    function pendingMarketCloseCount(address, uint) external view returns(uint);
    function maxTradesPerPair() external view returns(uint);
    function maxTradesPerBlock() external view returns(uint);
    function tradesPerBlock(uint) external view returns(uint);
    function pendingOrderIdsCount(address) external view returns(uint);
    function maxPendingMarketOrders() external view returns(uint);
    function maxGainP() external view returns(uint);
    function defaultLeverageUnlocked() external view returns(uint);
    function openInterestDai(uint, uint) external view returns(uint);
    function getPendingOrderIds(address) external view returns(uint[] memory);
    function traders(address) external view returns(Trader memory);
    function nfts(uint) external view returns(NftInterfaceV5);
}

// File: contracts\GFarmTestnetTradingVaultV5.sol


pragma solidity 0.8.7;

contract GFarmTestnetTradingVaultV5{

	// Useful constant
	uint public constant PRECISION = 1e5;

	// Contracts & Addresses
	StorageInterfaceV5 public storageT;

	// Variables
    uint public maxBalanceDai;      // 1e18
    uint public currentBalanceDai;  // block
    uint public waitBlocksBase;     // block
    uint public refillLiqP;         // PRECISION (%)
    uint public power;              // no decimal
    uint public lastRefill;         // block
    uint public swapFeeP;           // PRECISION (%)

    // Mappings
    mapping(address => uint) public daiToClaim;

    // Events
    event DaiDeposited(address caller,  uint amount, uint newCurrentBalanceDai, uint newMaxBalanceDai);
    event DaiWithdrawn(address caller, uint amount, uint newCurrentBalanceDai, uint newMaxBalanceDai);
    event DaiSent(address caller, address trader, uint amount,uint newCurrentBalanceDai, uint maxBalanceDai);
    event DaiToClaim(address caller, address trader, uint amount,uint currentBalanceDai, uint maxBalanceDai);
    event DaiClaimed(address trader, uint amount, uint newCurrentBalanceDai, uint maxBalanceDai);
    event DaiRefilled(address caller, uint daiAmount, uint newCurrentBalanceDai, uint maxBalanceDai, uint tokensMinted);

    event AddressUpdated(string name, address a);
    event NumberUpdated(string name, uint value);

    constructor(
        StorageInterfaceV5 _storageT,
        uint _waitBlocksBase, 
        uint _refillLiqP, 
        uint _power,
        uint _swapFeeP
    ){ 
        require(address(_storageT) != address(0), "ADDRESS_0");
        storageT = _storageT;
        waitBlocksBase = _waitBlocksBase;
        refillLiqP = _refillLiqP;
        power = _power;
        swapFeeP = _swapFeeP;
    }

    // Modifiers
    modifier onlyGov(){ require(msg.sender == storageT.gov(), "GOV_ONLY"); _; }
    modifier onlyCallbacks(){ require(msg.sender == storageT.callbacks(), "CALLBACKS_ONLY"); _; }

    // CAREFUL: IF ADDRESS WRONG, CONTRACT CAN BE STUCK
    function setStorageT(StorageInterfaceV5 _storageT) external onlyGov{
        require(_storageT.gov() == storageT.gov(), "WRONG_CONTRACT");
        storageT = _storageT;
        emit AddressUpdated("storageT", address(_storageT));
    }

    // Manage state
    function setWaitBlocksBase(uint _waitBlocksBase) external onlyGov{
        require(_waitBlocksBase >= 100, "BELOW_100");
    	waitBlocksBase = _waitBlocksBase;
        emit NumberUpdated("waitBlocksBase", _waitBlocksBase);
    }
    function setRefillLiqP(uint _refillLiqP) external onlyGov{
        require(_refillLiqP > 0, "VALUE_0");
        require(_refillLiqP <= 3*PRECISION/10, "ABOVE_0_POINT_3");
    	refillLiqP = _refillLiqP;
        emit NumberUpdated("refillLiqP", _refillLiqP);
    }
	function setPower(uint _power) external onlyGov{
        require(_power >= 2, "BELOW_2");
        require(_power <= 10, "ABOVE_10");
    	power = _power;
        emit NumberUpdated("power", _power);
    }
    function setSwapFeeP(uint _swapFeeP) external onlyGov{
        require(_swapFeeP <= PRECISION, "ABOVE_1");
        swapFeeP = _swapFeeP;
        emit NumberUpdated("swapFeeP", _swapFeeP);
    }

    // External functions (interaction)
    function depositDai(uint _amount) external onlyGov{
        require(_amount > 0, "AMOUNT_0");
        storageT.dai().transferFrom(msg.sender, address(this), _amount);

        currentBalanceDai += _amount;
        maxBalanceDai += _amount;

        emit DaiDeposited(msg.sender, _amount, currentBalanceDai, maxBalanceDai);
    }
    function withdrawDai(uint _amount) external onlyGov{
        require(_amount > 0, "AMOUNT_0");
        require(_amount <= currentBalanceDai, "BALANCE_TOO_LOW");
        storageT.dai().transfer(msg.sender, _amount);

        currentBalanceDai -= _amount;
        maxBalanceDai -= _amount;

        emit DaiWithdrawn(msg.sender, _amount, currentBalanceDai, maxBalanceDai);
    }
    function sendDaiToTrader(address _trader, uint _amount) external onlyCallbacks{
        _amount -= swapFeeP * _amount / 100 / PRECISION;
        _amount = _amount * slippageAmm(_amount) / PRECISION;

        if(_amount <= currentBalanceDai){
            currentBalanceDai -= _amount;
            storageT.dai().transfer(_trader, _amount);
            emit DaiSent(msg.sender, _trader, _amount, currentBalanceDai, maxBalanceDai);
        }else{
            daiToClaim[_trader] += _amount;
            emit DaiToClaim(msg.sender, _trader, _amount, currentBalanceDai, maxBalanceDai);
        }
    }
    function claimDai() external{
        uint amount = daiToClaim[msg.sender];
        require(amount > 0, "NOTHING_TO_CLAIM");
        require(currentBalanceDai > amount, "BALANCE_TOO_LOW");

        currentBalanceDai -= amount;
        storageT.dai().transfer(msg.sender, amount);
        daiToClaim[msg.sender] = 0;

        emit DaiClaimed(msg.sender, amount, currentBalanceDai, maxBalanceDai);
    }
    function refill() external{
    	require(currentBalanceDai < maxBalanceDai, "ALREADY_FULL");
    	require(canRefill(), "TOO_EARLY");

    	(uint tokenReserve, ) = storageT.priceAggregator().tokenDaiReservesLp();
    	uint tokensToMint = tokenReserve*refillLiqP/100/PRECISION;

    	storageT.handleTokens(address(this), tokensToMint, true);

        storageT.token().approve(address(storageT.tokenDaiRouter()), tokensToMint);
    	uint[] memory amounts = storageT.tokenDaiRouter().swapExactTokensForTokens(
            tokensToMint,
            0,
            tokenToDaiPath(),
            address(this),
            block.timestamp + 300
        );

        currentBalanceDai += amounts[1];
        lastRefill = block.number;

        emit DaiRefilled(msg.sender, amounts[1], currentBalanceDai, maxBalanceDai, tokensToMint);
    }

    // View functions
    function canRefill() public view returns(bool){
        return block.number >= lastRefill + blocksToWait(currentBalanceDai, maxBalanceDai);
    }
    function blocksToWait(uint _currentBalanceDai, uint _maxBalanceDai) public view returns(uint){
        uint blocks = (_currentBalanceDai*PRECISION/_maxBalanceDai)**power*waitBlocksBase/(PRECISION**power);
        return blocks >= 1 ? blocks : 1;
    }
    function slippageAmm(uint _amount) private view returns(uint){
        (, uint daiReserve) = storageT.priceAggregator().tokenDaiReservesLp();
        return PRECISION**2/(PRECISION+_amount*PRECISION/daiReserve);
    }
    function tokenToDaiPath() private view returns(address[] memory){
        address[] memory path = new address[](2);
        path[0] = address(storageT.token());
        path[1] = address(storageT.dai());
        return path;
    }

    // Useful backend function
    function backend(address _trader) external view returns(uint,uint,uint,StorageInterfaceV5.Trader memory,uint[] memory, StorageInterfaceV5.PendingMarketOrder[] memory, uint[][5] memory){
        uint[] memory pendingIds = storageT.getPendingOrderIds(_trader);

        StorageInterfaceV5.PendingMarketOrder[] memory pendingMarket = new StorageInterfaceV5.PendingMarketOrder[](pendingIds.length);
        for(uint i = 0; i < pendingIds.length; i++){
            pendingMarket[i] = storageT.reqID_pendingMarketOrder(pendingIds[i]);
        }

        uint[][5] memory nftIds;
        for(uint j = 0; j < 5; j++){
            uint nftsCount = storageT.nfts(j).balanceOf(_trader);
            nftIds[j] = new uint[](nftsCount);
            for(uint i = 0; i < nftsCount; i++){ 
                nftIds[j][i] = storageT.nfts(j).tokenOfOwnerByIndex(_trader, i); 
            }
        }

        return (
            storageT.dai().allowance(_trader, address(storageT)),
            storageT.dai().balanceOf(_trader),
            storageT.linkErc677().allowance(_trader, address(storageT)),
            storageT.traders(_trader),
            pendingIds, 
            pendingMarket, 
            nftIds
        );
    }
}