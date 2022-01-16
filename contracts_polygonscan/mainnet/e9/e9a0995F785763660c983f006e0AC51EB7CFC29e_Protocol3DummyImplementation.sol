// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminModule {

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
    ) external {}

    function updateMinTick(address pool_, uint minTick_) public {}

    function addBorrowMarket(
        address pool_,
        address[] memory tokens_
    ) public {}

    function updateBorrowLimit(address pool_, uint128 normal_, uint128 extended_) public {}

    function enableBorrow(address pool_, address token_) external {}

    function disableBorrow(address pool_, address token_) external {}

    function updatePriceSlippage(address pool_, uint priceSlippage_) public {}

    function updateTicksCheck(
        address pool_,
        uint24[] memory tickSlippages_,
        uint24[] memory timeAgos_
    ) public {}

    function addChainlinkOracle(address[] memory tokens_, address[] memory oracles_) public {}

}

contract UserModule {

    function getFeeAccruedWrapper(uint256 NFTID_, address poolAddr_)
        public
        view
        returns (uint256 amount0_, uint256 amount1_)
    {}

    function getNetNFTLiquidity(
        address poolAddr_,
        int24 tickLower_,
        int24 tickUpper_,
        uint128 liquidity_
    ) public view returns (uint256 amount0Total_, uint256 amount1Total_) {}

    function getNetNFTDebt(uint256 NFTID_, address poolAddr_)
        public
        view
        returns (uint256[] memory borrowBalances_)
    {}

    function getOverallPosition(uint256 NFTID_)
        public
        view
        returns (
            address poolAddr_,
            address token0_,
            address token1_,
            uint128 liquidity_,
            uint256 totalSupplyInUsd_,
            uint256 totalNormalSupplyInUsd_,
            uint256 totalBorrowInUsd_,
            uint256 totalNormalBorrowInUsd_
        )
    {}
    
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata
    ) external returns (bytes4) {}

    function withdraw(uint96 NFTID_) external {}

    function addLiquidity(
        uint96 NFTID_,
        uint256 amount0_,
        uint256 amount1_,
        uint256 minAmount0_,
        uint256 minAmount1_,
        uint256 deadline_
    ) external returns (uint256 exactAmount0_, uint256 exactAmount1_) {}

    function removeLiquidity(
        uint96 NFTID_,
        uint256 liquidity_,
        uint256 amount0Min_,
        uint256 amount1Min_
    )
        external
        returns (uint256 exactAmount0_, uint256 exactAmount1_)
    {}

    function borrow(
        uint96 NFTID_,
        address token_,
        uint256 amount_
    ) external {}

    function payback(
        uint96 NFTID_,
        address token_,
        uint256 amount_
    ) external returns (uint exactAmount_) {}

    function collectFees(uint96 NFTID_)
        external
        returns (uint256 amount0_, uint256 amount1_)
    {}

    function liquidate(
        uint96 NFTID_,
        uint amount0Min_,
        uint amount1Min_
    ) external returns (
        uint exactAmount0_,
        uint exactAmount1_,
        address[] memory markets_,
        uint[] memory paybackAmts_
    ) {}

    struct LiquidateVariables {
        uint exactAmount0;
        uint exactAmount1;
        address[] markets;
        uint[] paybackAmts;
    }

    function liquidate(
        uint96 NFTID_,
        uint amount0Min_,
        uint amount1Min_,
        address[] memory rewardTokens_,
        uint256[] memory startTime_,
        uint256[] memory endTime_,
        address[] memory refundee_
    ) external returns (LiquidateVariables memory v_) {}

    function depositNFT(uint96 NFTID_)
        external
    {}

    function withdrawNFT(uint96 NFTID_) external {}

    function stake(
        address rewardToken_,
        uint256 startTime_,
        uint256 endTime_,
        address refundee_,
        uint96 NFTID_
    ) external {}

    function unstake(
        address rewardToken_,
        uint256 startTime_,
        uint256 endTime_,
        address refundee_,
        uint96 NFTID_
    ) external {}

    function claimRewards(
        address rewardToken_,
        uint96 NFTID_
    ) external returns (uint256 rewards_) {}

}

contract ReadModule {

    function poolEnabled(address pool_) external view returns (bool) {}

    function position(address owner_, uint NFTID_) external view returns (bool) {}

    function isStaked(uint NFTID_) external view returns (bool) {}

    function minTick(address pool_) external view returns (uint) {}

    function borrowBalRaw(uint NFTID_, address token_) external view returns (uint) {}

    function borrowAllowed(address pool_, address token_) external view returns (bool) {}

    function poolMarkets(address pool_) external view returns (address[] memory) {}

    function borrowLimit(address pool_) external view returns (uint128 normal_, uint128 extended_) {}

    function priceSlippage(address pool_) external view returns (uint) {}

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

    function tickCheck(address pool_) external view returns (TickCheck memory tickCheck_) {}

}

contract Protocol3DummyImplementation is AdminModule, UserModule, ReadModule {

    receive() external payable {}
    
}