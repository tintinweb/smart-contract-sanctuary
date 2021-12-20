/**
 *Submitted for verification at polygonscan.com on 2021-12-20
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
	function receiveDaiFromTrader(address, uint, uint) external;
	function currentBalanceDai() external view returns(uint);
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

// File: contracts\GNSTradingVaultV5.sol


pragma solidity 0.8.7;

contract GNSTradingVaultV5{

    uint public constant PRECISION = 1e5;
    StorageInterfaceV5 public immutable storageT;
    address public constant rewardDistributor = 0xC66FbE50Dd33c9AAdd65707F7088D597C86fE00F;

    // PARAMS
    // 1. Refill
    uint public blocksBaseRefill = 2500;    // block
    uint public refillLiqP = 0.1 * 1e5;     // PRECISION (%)
    uint public powerRefill = 5;            // no decimal    

    // 2. Deplete
    uint public blocksBaseDeplete = 10000;  // block
    uint public blocksMinDeplete = 2000;    // block
    uint public depleteLiqP = 0.3 * 1e5;    // PRECISION (%)
    uint public coeffDepleteP = 100;        // %
    uint public thresholdDepleteP = 10;     // %

    // 3. Staking
    uint public withdrawTimelock = 43200;   // blocks
    uint public maxWithdrawP = 25;          // %

    // 4. Trading
    uint public swapFeeP = 0.3 * 1e5;       // PRECISION (%)

    // STATE
    // 1. DAI balance
    uint public maxBalanceDai;      // 1e18
    uint public currentBalanceDai;  // 1e18
    uint public lastActionBlock;    // block

    // 2. DAI staking rewards
    uint public accDaiPerDai;       // 1e18
    uint public rewardsDai;         // 1e18

    // 3. MATIC staking rewards
    uint public maticPerBlock;      // 1e18
    uint public accMaticPerDai;     // 1e18
    uint public maticStartBlock;    // 1e18
    uint public maticEndBlock;      // 1e18
    uint public maticLastRewardBlock;     // 1e18
    uint public rewardsMatic;       // 1e18

    // 4. Mappings
    struct User{
        uint daiDeposited;
        uint maxDaiDeposited;
        uint withdrawBlock;
        uint debtDai;
        uint debtMatic;
    }
    mapping(address => User) public users;
    mapping(address => uint) public daiToClaim;

    // EVENTS
    event Deposited(address caller,  uint amount, uint newCurrentBalanceDai, uint newMaxBalanceDai);
    event Withdrawn(address caller, uint amount, uint newCurrentBalanceDai, uint newMaxBalanceDai);
    event Sent(address caller, address trader, uint amount,uint newCurrentBalanceDai, uint maxBalanceDai);
    event ToClaim(address caller, address trader, uint amount,uint currentBalanceDai, uint maxBalanceDai);
    event Claimed(address trader, uint amount, uint newCurrentBalanceDai, uint maxBalanceDai);
    event Refilled(address caller, uint daiAmount, uint newCurrentBalanceDai, uint maxBalanceDai, uint tokensMinted);
    event Depleted(address caller, uint daiAmount, uint newCurrentBalanceDai, uint maxBalanceDai, uint tokensBurnt);
    event ReceivedFromTrader(address caller, address trader, uint daiAmount, uint vaultFeeDai, uint newCurrentBalanceDai, uint maxBalanceDai);
    event AddressUpdated(string name, address a);
    event NumberUpdated(string name, uint value);

    constructor(StorageInterfaceV5 _storageT){ 
        require(address(_storageT) != address(0), "ADDRESS_0");
        storageT = _storageT;
    }

    modifier onlyGov(){ require(msg.sender == storageT.gov(), "GOV_ONLY"); _; }
    modifier onlyCallbacks(){ require(msg.sender == storageT.callbacks(), "CALLBACKS_ONLY"); _; }

    // Manage state
    function setBlocksBaseRefill(uint _blocksBaseRefill) external onlyGov{
        require(_blocksBaseRefill >= 1000, "BELOW_1000");
        blocksBaseRefill = _blocksBaseRefill;
        emit NumberUpdated("blocksBaseRefill", _blocksBaseRefill);
    }
    function setBlocksBaseDeplete(uint _blocksBaseDeplete) external onlyGov{
        require(_blocksBaseDeplete >= 1000, "BELOW_1000");
        blocksBaseDeplete = _blocksBaseDeplete;
        emit NumberUpdated("blocksBaseDeplete", _blocksBaseDeplete);
    }
    function setBlocksMinDeplete(uint _blocksMinDeplete) external onlyGov{
        require(_blocksMinDeplete >= 1000, "BELOW_1000");
        blocksMinDeplete = _blocksMinDeplete;
        emit NumberUpdated("blocksMinDeplete", _blocksMinDeplete);
    }
    function setRefillLiqP(uint _refillLiqP) external onlyGov{
        require(_refillLiqP > 0, "VALUE_0");
        require(_refillLiqP <= 3*PRECISION/10, "ABOVE_0_POINT_3");
        refillLiqP = _refillLiqP;
        emit NumberUpdated("refillLiqP", _refillLiqP);
    }
    function setDepleteLiqP(uint _depleteLiqP) external onlyGov{
        require(_depleteLiqP > 0, "VALUE_0");
        require(_depleteLiqP <= 3*PRECISION/10, "ABOVE_0_POINT_3");
        depleteLiqP = _depleteLiqP;
        emit NumberUpdated("depleteLiqP", _depleteLiqP);
    }
    function setPowerRefill(uint _powerRefill) external onlyGov{
        require(_powerRefill >= 2, "BELOW_2");
        require(_powerRefill <= 10, "ABOVE_10");
        powerRefill = _powerRefill;
        emit NumberUpdated("powerRefill", _powerRefill);
    }
    function setCoeffDepleteP(uint _coeffDepleteP) external onlyGov{
        coeffDepleteP = _coeffDepleteP;
        emit NumberUpdated("coeffDepleteP", _coeffDepleteP);
    }
    function setThresholdDepleteP(uint _thresholdDepleteP) external onlyGov{
        require(_thresholdDepleteP <= 100, "ABOVE_100");
        thresholdDepleteP = _thresholdDepleteP;
        emit NumberUpdated("thresholdDepleteP", _thresholdDepleteP);
    }
    function setSwapFeeP(uint _swapFeeP) external onlyGov{
        require(_swapFeeP <= PRECISION, "ABOVE_1");
        swapFeeP = _swapFeeP;
        emit NumberUpdated("swapFeeP", _swapFeeP);
    }
    function setWithdrawTimelock(uint _withdrawTimelock) external onlyGov{
        require(_withdrawTimelock > 43200, "LESS_THAN_1_DAY");
        withdrawTimelock = _withdrawTimelock;
        emit NumberUpdated("withdrawTimelock", _withdrawTimelock);
    }
    function setMaxWithdrawP(uint _maxWithdrawP) external onlyGov{
        require(_maxWithdrawP >= 10, "BELOW_10");
        require(_maxWithdrawP <= 100, "ABOVE_100");
        maxWithdrawP = _maxWithdrawP;
        emit NumberUpdated("maxWithdrawP", _maxWithdrawP);
    }

    // Refill
    function refill() external{
        require(currentBalanceDai < maxBalanceDai, "ALREADY_FULL");
        require(block.number >= lastActionBlock + blocksBetweenRefills(currentBalanceDai, maxBalanceDai), "TOO_EARLY");

        (uint tokenReserve, ) = storageT.priceAggregator().tokenDaiReservesLp();
        uint tokensToMint = tokenReserve*refillLiqP/100/PRECISION;

        storageT.handleTokens(address(this), tokensToMint, true);

        address[] memory tokenToDaiPath = new address[](2);
        tokenToDaiPath[0] = address(storageT.token());
        tokenToDaiPath[1] = address(storageT.dai());

        storageT.token().approve(address(storageT.tokenDaiRouter()), tokensToMint);
        uint[] memory amounts = storageT.tokenDaiRouter().swapExactTokensForTokens(
            tokensToMint,
            0,
            tokenToDaiPath,
            address(this),
            block.timestamp + 300
        );

        currentBalanceDai += amounts[1];
        lastActionBlock = block.number;

        emit Refilled(msg.sender, amounts[1], currentBalanceDai, maxBalanceDai, tokensToMint);
    }
    function blocksBetweenRefills(uint _currentBalanceDai, uint _maxBalanceDai) public view returns(uint){
        uint blocks = (_currentBalanceDai*PRECISION/_maxBalanceDai)**powerRefill*blocksBaseRefill/(PRECISION**powerRefill);
        return blocks >= 1 ? blocks : 1;
    }

    // Deplete
    function deplete() external{
        require(currentBalanceDai > maxBalanceDai*(100+thresholdDepleteP)/100, "NOT_FULL");
        require(block.number >= lastActionBlock + blocksBetweenDepletes(currentBalanceDai, maxBalanceDai), "TOO_EARLY");

        (, uint daiReserve) = storageT.priceAggregator().tokenDaiReservesLp();
        uint daiToBuy = daiReserve*depleteLiqP/100/PRECISION;

        address[] memory daiToTokenPath = new address[](2);
        daiToTokenPath[0] = address(storageT.dai());
        daiToTokenPath[1] = address(storageT.token());

        require(storageT.dai().approve(address(storageT.tokenDaiRouter()), daiToBuy));
        uint[] memory amounts = storageT.tokenDaiRouter().swapExactTokensForTokens(
            daiToBuy,
            0,
            daiToTokenPath,
            address(this),
            block.timestamp + 300
        );

        storageT.handleTokens(address(this), amounts[1], false);

        currentBalanceDai -= daiToBuy;
        lastActionBlock = block.number;

        emit Depleted(msg.sender, daiToBuy, currentBalanceDai, maxBalanceDai, amounts[1]);
    }
    function blocksBetweenDepletes(uint _currentBalanceDai, uint _maxBalanceDai) public view returns(uint){
        uint blocks = blocksBaseDeplete - (100*_currentBalanceDai - _maxBalanceDai*(100+thresholdDepleteP))*coeffDepleteP/_currentBalanceDai;
        return blocks >= blocksMinDeplete ? blocks : blocksMinDeplete;
    }

    // Staking (user interaction)
    function harvest() public{
        User storage u = users[msg.sender];

        require(storageT.dai().transfer(msg.sender, pendingRewardDai()));
        u.debtDai = u.daiDeposited * accDaiPerDai / 1e18;

        uint pendingMatic = pendingRewardMatic();
        accMaticPerDai = pendingAccMaticPerDai();
        maticLastRewardBlock = block.number;
        u.debtMatic = u.daiDeposited * accMaticPerDai / 1e18;
        payable(msg.sender).transfer(pendingMatic);
    }
    function depositDai(uint _amount) external{
        User storage user = users[msg.sender];

        require(_amount > 0, "AMOUNT_0");
        require(storageT.dai().transferFrom(msg.sender, address(this), _amount));

        harvest();

        currentBalanceDai += _amount;
        maxBalanceDai += _amount;

        user.daiDeposited += _amount;
        user.maxDaiDeposited = user.daiDeposited;
        user.debtDai = user.daiDeposited * accDaiPerDai / 1e18;
        user.debtMatic = user.daiDeposited * accMaticPerDai / 1e18;

        emit Deposited(msg.sender, _amount, currentBalanceDai, maxBalanceDai);
    }
    function withdrawDai(uint _amount) external{
        User storage user = users[msg.sender];

        require(_amount > 0, "AMOUNT_0");
        require(_amount <= currentBalanceDai, "BALANCE_TOO_LOW");
        require(_amount <= user.daiDeposited, "WITHDRAWING_MORE_THAN_DEPOSITED");
        require(_amount <= user.maxDaiDeposited * maxWithdrawP / 100, "MAX_WITHDRAW_P");
        require(block.number >= user.withdrawBlock + withdrawTimelock, "TOO_EARLY");

        harvest();

        currentBalanceDai -= _amount;
        maxBalanceDai -= _amount;

        user.daiDeposited -= _amount;
        user.withdrawBlock = block.number;
        user.debtDai = user.daiDeposited * accDaiPerDai / 1e18;
        user.debtMatic = user.daiDeposited * accMaticPerDai / 1e18;

        require(storageT.dai().transfer(msg.sender, _amount));

        emit Withdrawn(msg.sender, _amount, currentBalanceDai, maxBalanceDai);
    }

    // MATIC incentives
    function distributeRewardMatic(uint _startBlock, uint _endBlock) external payable{
        require(msg.sender == rewardDistributor, "WRONG_CALLER");
        require(msg.value > 0, "AMOUNT_0");
        require(_startBlock < _endBlock, "START_AFTER_END");
        require(_startBlock > block.number, "START_BEFORE_NOW");
        require(_endBlock - _startBlock >= 100000, "TOO_SHORT");
        require(_endBlock - _startBlock <= 1500000, "TOO_LONG");
        require(block.number > maticEndBlock, "LAST_MATIC_DISTRIBUTION_NOT_ENDED");
        require(maxBalanceDai > 0, "NO_DAI_STAKED");

        accMaticPerDai = pendingAccMaticPerDai();
        rewardsMatic += msg.value;
        maticLastRewardBlock = 0;

        maticPerBlock = msg.value / (_endBlock - _startBlock);
        maticStartBlock = _startBlock;
        maticEndBlock = _endBlock;
    }
    function pendingAccMaticPerDai() view private returns(uint){
        if(maxBalanceDai == 0){ return accMaticPerDai; }
        
        uint pendingRewardBlocks = 0;
        if(block.number > maticStartBlock){
            if(block.number <= maticEndBlock){
                pendingRewardBlocks = maticLastRewardBlock == 0 ? block.number - maticStartBlock : block.number - maticLastRewardBlock;
            }else if(maticLastRewardBlock <= maticEndBlock){
                pendingRewardBlocks = maticLastRewardBlock == 0 ? maticEndBlock - maticStartBlock : maticEndBlock - maticLastRewardBlock;
            }
        }
        return accMaticPerDai + pendingRewardBlocks*maticPerBlock*1e18/maxBalanceDai;
    }
    function pendingRewardMatic() public view returns(uint){
        User memory u = users[msg.sender];
        return u.daiDeposited * pendingAccMaticPerDai() / 1e18 - u.debtMatic;
    }

    // DAI incentives
    function distributeRewardDai(uint _amount) public onlyCallbacks{        
        if(maxBalanceDai > 0){
            currentBalanceDai -= _amount;
            accDaiPerDai += _amount * 1e18 / maxBalanceDai;
            rewardsDai += _amount;
        }
    }
    function pendingRewardDai() public view returns(uint){
        User memory u = users[msg.sender];
        return u.daiDeposited * accDaiPerDai / 1e18 - u.debtDai;
    }

    // Handle traders DAI when a trade is closed
    function sendDaiToTrader(address _trader, uint _amount) external onlyCallbacks{
        _amount -= swapFeeP * _amount / 100 / PRECISION;

        if(_amount <= currentBalanceDai){
            currentBalanceDai -= _amount;
            require(storageT.dai().transfer(_trader, _amount));
            emit Sent(msg.sender, _trader, _amount, currentBalanceDai, maxBalanceDai);
        }else{
            daiToClaim[_trader] += _amount;
            emit ToClaim(msg.sender, _trader, _amount, currentBalanceDai, maxBalanceDai);
        }
    }
    function claimDai() external{
        uint amount = daiToClaim[msg.sender];
        require(amount > 0, "NOTHING_TO_CLAIM");
        require(currentBalanceDai > amount, "BALANCE_TOO_LOW");

        currentBalanceDai -= amount;
        require(storageT.dai().transfer(msg.sender, amount));
        daiToClaim[msg.sender] = 0;

        emit Claimed(msg.sender, amount, currentBalanceDai, maxBalanceDai);
    }

    // Handle DAI from opened trades
    function receiveDaiFromTrader(address _trader, uint _amount, uint _vaultFee) external onlyCallbacks{
        storageT.transferDai(address(storageT), address(this), _amount);
        currentBalanceDai += _amount;

        distributeRewardDai(_vaultFee);

        emit ReceivedFromTrader(msg.sender, _trader, _amount, _vaultFee, currentBalanceDai, maxBalanceDai);
    }

    // Useful backend function (ignore)
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