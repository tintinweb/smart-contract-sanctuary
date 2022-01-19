// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "../interfaces/IVault.sol";
import "../libraries/ERC20Extends.sol";
import "../libraries/UniV3PMExtends.sol";
import "../storage/SmartPoolStorage.sol";
import "./UniV3Liquidity.sol";

pragma abicoder v2;
/// @title Position Management
/// @notice Provide asset operation functions, allow authorized identities to perform asset operations, and achieve the purpose of increasing the net value of the Vault
contract AutoLiquidity is UniV3Liquidity {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UniV3SwapExtends for mapping(address => mapping(address => bytes));

    //Vault purchase and redemption token
    IERC20 public ioToken;
    //Vault contract address
    IVault public vault;
    //Underlying asset
    EnumerableSet.AddressSet internal underlyings;

    event TakeFee(SmartPoolStorage.FeeType ft, address token, address rewards, uint256 fee);

    /// @notice Binding vaults and subscription redemption token
    /// @dev Only bind once and cannot be modified
    /// @param _vault Vault address
    /// @param _ioToken Subscription and redemption token
    function bind(address _vault, address _ioToken) external onlyGovernance {
        vault = IVault(_vault);
        ioToken = IERC20(_ioToken);
    }

    //Only allow vault contract access
    modifier onlyVault() {
        require(extAuthorize(), "!vault");
        _;
    }

    /// @notice ext authorize
    function extAuthorize() internal override view returns (bool){
        return msg.sender == address(vault);
    }

    /// @notice in work tokenId array
    /// @dev read in works NFT array
    /// @return tokenIds NFT array
    function worksPos() public view returns (uint256[] memory tokenIds){
        uint256 length = works.length();
        tokenIds = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            tokenIds[i] = works.at(i);
        }
    }

    /// @notice in underlyings token address array
    /// @dev read in underlyings token address array
    /// @return tokens address array
    function getUnderlyings() public view returns (address[] memory tokens){
        uint256 length = underlyings.length();
        tokens = new address[](length);
        for (uint256 i = 0; i < underlyings.length(); i++) {
            tokens[i] = underlyings.at(i);
        }
    }


    /// @notice Set the underlying asset token address
    /// @dev Only allow the governance identity to set the underlying asset token address
    /// @param ts The underlying asset token address array to be added
    function setUnderlyings(address[] memory ts) public onlyGovernance {
        for (uint256 i = 0; i < ts.length; i++) {
            if (!underlyings.contains(ts[i])) {
                underlyings.add(ts[i]);
            }
        }
    }

    /// @notice Delete the underlying asset token address
    /// @dev Only allow the governance identity to delete the underlying asset token address
    /// @param ts The underlying asset token address array to be deleted
    function removeUnderlyings(address[] memory ts) public onlyGovernance {
        for (uint256 i = 0; i < ts.length; i++) {
            if (underlyings.contains(ts[i])) {
                underlyings.remove(ts[i]);
            }
        }
    }

    /// @notice swap after handle
    /// @param tokenOut token address
    /// @param amountOut token amount
    function swapAfter(
        address tokenOut,
        uint256 amountOut) internal override {
        uint256 fee = vault.calcRatioFee(SmartPoolStorage.FeeType.TURNOVER_FEE, amountOut);
        if (fee > 0) {
            address rewards = getRewards();
            IERC20(tokenOut).safeTransfer(rewards, fee);
            emit TakeFee(SmartPoolStorage.FeeType.TURNOVER_FEE, tokenOut, rewards, fee);
        }
    }

    /// @notice collect after handle
    /// @param token0 token address
    /// @param token1 token address
    /// @param amount0 token amount
    /// @param amount1 token amount
    function collectAfter(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1) internal override {
        uint256 fee0 = vault.calcRatioFee(SmartPoolStorage.FeeType.TURNOVER_FEE, amount0);
        uint256 fee1 = vault.calcRatioFee(SmartPoolStorage.FeeType.TURNOVER_FEE, amount1);
        address rewards = getRewards();
        if (fee0 > 0) {
            IERC20(token0).safeTransfer(rewards, fee0);
            emit TakeFee(SmartPoolStorage.FeeType.TURNOVER_FEE, token0, rewards, fee0);
        }
        if (fee1 > 0) {
            IERC20(token1).safeTransfer(rewards, fee1);
            emit TakeFee(SmartPoolStorage.FeeType.TURNOVER_FEE, token1, rewards, fee1);
        }
    }


    /// @notice Asset transfer used to upgrade the contract
    /// @param to address
    function withdrawAll(address to) external onlyGovernance {
        for (uint256 i = 0; i < underlyings.length(); i++) {
            IERC20 token = IERC20(underlyings.at(i));
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                token.safeTransfer(to, balance);
            }
        }
    }

    /// @notice Withdraw asset
    /// @dev Only vault contract can withdraw asset
    /// @param to Withdraw address
    /// @param amount Withdraw amount
    /// @param scale Withdraw percentage
    function withdraw(address to, uint256 amount, uint256 scale) external onlyVault {
        uint256 surplusAmount = ioToken.balanceOf(address(this));
        if (surplusAmount < amount) {
            uint256 length = underlyings.length();
            uint256[] memory balances = new uint256[](length);
            uint256[] memory withdrawAmounts = new uint256[](length);
            for (uint256 i = 0; i < length; i++) {
                address token = underlyings.at(i);
                uint256 balance = IERC20(token).balanceOf(address(this));
                balances[i] = balance;
                withdrawAmounts[i] = balance.mul(scale).div(1e18);
            }
            _decreaseLiquidityByScale(scale);
            for (uint256 i = 0; i < length; i++) {
                address token = underlyings.at(i);
                uint256 balance = IERC20(token).balanceOf(address(this));
                uint256 decreaseAmount = balance.sub(balances[i]);
                uint256 swapAmount = withdrawAmounts[i].add(decreaseAmount);
                if (token != address(ioToken) && swapAmount > 0) {
                    exactInput(token, address(ioToken), swapAmount, 0);
                }
            }
        }
        surplusAmount = ioToken.balanceOf(address(this));
        if (surplusAmount < amount) {
            amount = surplusAmount;
        }
        ioToken.safeTransfer(to, amount);
    }

    /// @notice Withdraw underlying asset
    /// @dev Only vault contract can withdraw underlying asset
    /// @param to Withdraw address
    /// @param scale Withdraw percentage
    function withdrawOfUnderlying(address to, uint256 scale) external onlyVault {
        uint256 length = underlyings.length();
        uint256[] memory balances = new uint256[](length);
        uint256[] memory withdrawAmounts = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            address token = underlyings.at(i);
            uint256 balance = IERC20(token).balanceOf(address(this));
            balances[i] = balance;
            withdrawAmounts[i] = balance.mul(scale).div(1e18);
        }
        _decreaseLiquidityByScale(scale);
        for (uint256 i = 0; i < length; i++) {
            address token = underlyings.at(i);
            uint256 balance = IERC20(token).balanceOf(address(this));
            uint256 decreaseAmount = balance.sub(balances[i]);
            uint256 transferAmount = withdrawAmounts[i].add(decreaseAmount);
            IERC20(token).safeTransfer(to, transferAmount);
        }
    }

    /// @notice Decrease liquidity by scale
    /// @dev Decrease liquidity by provided scale
    /// @param scale Scale of the liquidity
    function _decreaseLiquidityByScale(uint256 scale) internal {
        uint256 length = works.length();
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = works.at(i);
            (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint128 liquidity,
            ,
            ,
            ,
            ) = UniV3PMExtends.PM.positions(tokenId);
            if (liquidity > 0) {
                uint256 _decreaseLiquidity = uint256(liquidity).mul(scale).div(1e18);
                (uint256 amount0, uint256 amount1) = decreaseLiquidity(tokenId, uint128(_decreaseLiquidity), 0, 0);
                collect(tokenId, uint128(amount0), uint128(amount1));
            }
        }
    }

    /// @notice Total asset
    /// @dev This function calculates the net worth or AUM
    /// @return Total asset
    function assets() public view returns (uint256){
        uint256 total = idleAssets();
        total = total.add(liquidityAssets());
        return total;
    }

    /// @notice idle asset
    /// @dev This function calculates idle asset
    /// @return idle asset
    function idleAssets() public view returns (uint256){
        uint256 total;
        for (uint256 i = 0; i < underlyings.length(); i++) {
            address token = underlyings.at(i);
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (token == address(ioToken)) {
                total = total.add(balance);
            } else {
                uint256 _estimateAmountOut = estimateAmountOut(token, address(ioToken), balance);
                total = total.add(_estimateAmountOut);
            }
        }
        return total;
    }

    /// @notice at work liquidity asset
    /// @dev This function calculates liquidity asset
    /// @return liquidity asset
    function liquidityAssets() public view returns (uint256){
        uint256 total;
        address ioTokenAddr = address(ioToken);
        uint256 length = works.length();
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = works.at(i);
            total = total.add(calcLiquidityAssets(tokenId, ioTokenAddr));
        }
        return total;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "../base/GovIdentity.sol";
import "../interfaces/uniswap-v3/Path.sol";
import "../libraries/ERC20Extends.sol";
import "../libraries/UniV3SwapExtends.sol";
import "../libraries/UniV3PMExtends.sol";

pragma abicoder v2;
/// @title Position Management
/// @notice Provide asset operation functions, allow authorized identities to perform asset operations, and achieve the purpose of increasing the net value of the fund
contract UniV3Liquidity is GovIdentity {

    using SafeMath for uint256;
    using Path for bytes;
    using EnumerableSet for EnumerableSet.UintSet;
    using UniV3SwapExtends for mapping(address => mapping(address => bytes));

    //Swap route
    mapping(address => mapping(address => bytes)) public swapRoute;
    //Position list
    mapping(bytes32 => uint256) public history;
    //position mapping owner
    mapping(uint256 => address) public positionOwners;
    //available token limit
    mapping(address => mapping(address => uint256)) public tokenLimit;
    //Working positions
    EnumerableSet.UintSet internal works;

    //Swap
    event Swap(address sender, address fromToken, address toToken, uint256 amountIn, uint256 amountOut);
    //Create positoin
    event Mint(address sender, uint256 tokenId, uint128 liquidity);
    //Increase liquidity
    event IncreaseLiquidity(address sender, uint256 tokenId, uint128 liquidity);
    //Decrease liquidity
    event DecreaseLiquidity(address sender, uint256 tokenId, uint128 liquidity);
    //Collect asset
    event Collect(address sender, uint256 tokenId, uint256 amount0, uint256 amount1);

    //Only allow governance, strategy, ext authorize
    modifier onlyAssetsManager() {
        require(
            msg.sender == getGovernance()
            || isAdmin(msg.sender)
            || isStrategist(msg.sender)
            || extAuthorize(), "!AM");
        _;
    }

    //Only position owner
    modifier onlyPositionManager(uint256 tokenId) {
        require(
            msg.sender == getGovernance()
            || isAdmin(msg.sender)
            || positionOwners[tokenId] == msg.sender
            || extAuthorize(), "!PM");
        _;
    }



    /// @notice extend authorize
    function extAuthorize() internal virtual view returns (bool){
        return false;
    }


    /// @notice swap after handle
    function swapAfter(
        address,
        uint256) internal virtual {

    }

    /// @notice collect after handle
    function collectAfter(
        address,
        address,
        uint256,
        uint256) internal virtual {

    }

    /// @notice Check current position
    /// @dev Check the current UniV3 position by pool token ID.
    /// @param pool liquidity pool
    /// @param tickLower Tick lower bound
    /// @param tickUpper Tick upper bound
    /// @return atWork Position status
    /// @return has Check if the position ID exist
    /// @return tokenId Position ID
    function checkPos(
        address pool,
        int24 tickLower,
        int24 tickUpper
    ) public view returns (bool atWork, bool has, uint256 tokenId){
        bytes32 pk = UniV3PMExtends.positionKey(pool, tickLower, tickUpper);
        tokenId = history[pk];
        atWork = works.contains(tokenId);
        has = tokenId > 0 ? true : false;
    }

    /// @notice Update strategist's available token limit
    /// @param strategist strategist's
    /// @param token token address
    /// @param amount limit amount
    function setTokenLimit(address strategist, address token, int256 amount) public onlyAdminOrGovernance {
        if (amount > 0) {
            tokenLimit[strategist][token] += uint256(amount);
        } else {
            tokenLimit[strategist][token] -= uint256(amount);
        }
    }

    /// @notice Authorize UniV3 contract to move vault asset
    /// @dev Only allow governance and admin identities to execute authorized functions to reduce miner fee consumption
    /// @param token Authorized target token
    function safeApproveAll(address token) public virtual onlyAdminOrGovernance {
        ERC20Extends.safeApprove(token, address(UniV3PMExtends.PM), type(uint256).max);
        ERC20Extends.safeApprove(token, address(UniV3SwapExtends.SRT), type(uint256).max);
    }

    /// @notice Multiple functions of the contract can be executed at the same time
    /// @dev Only the assets manager identities are allowed to execute multiple function calls,
    /// and the execution of multiple functions can ensure the consistency of the execution results
    /// @param data Encode data of multiple execution functions
    /// @return results Execution result
    function multicall(bytes[] calldata data) external onlyAssetsManager returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            if (!success) {
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }
            results[i] = result;
        }
    }


    /// @notice Set asset swap route
    /// @dev Only the governance and admin identity is allowed to set the asset swap path, and the firstToken and lastToken contained in the path will be used as the underlying asset token address by default
    /// @param path Swap path byte code
    function settingSwapRoute(bytes memory path) external onlyAdminOrGovernance {
        require(path.valid(), 'path is not valid');
        address fromToken = path.getFirstAddress();
        address toToken = path.getLastAddress();
        swapRoute[fromToken][toToken] = path;
    }

    /// @notice Estimated to obtain the target token amount
    /// @dev Only allow the asset transaction path that has been set to be estimated
    /// @param from Source token address
    /// @param to Target token address
    /// @param amountIn Source token amount
    /// @return amountOut Target token amount
    function estimateAmountOut(
        address from,
        address to,
        uint256 amountIn
    ) public view returns (uint256 amountOut){
        return swapRoute.estimateAmountOut(from, to, amountIn);
    }

    /// @notice Estimate the amount of source tokens that need to be provided
    /// @dev Only allow the governance identity to set the underlying asset token address
    /// @param from Source token address
    /// @param to Target token address
    /// @param amountOut Expect to get the target token amount
    /// @return amountIn Source token amount
    function estimateAmountIn(
        address from,
        address to,
        uint256 amountOut
    ) public view returns (uint256 amountIn){
        return swapRoute.estimateAmountIn(from, to, amountOut);
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Initiate a transaction with a known input amount and return the output amount
    /// @param tokenIn Token in address
    /// @param tokenOut Token out address
    /// @param amountIn Token in amount
    /// @param amountOutMinimum Expected to get minimum token out amount
    /// @return amountOut Token out amount
    function exactInput(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) public onlyAssetsManager returns (uint256 amountOut) {
        bool _isStrategist = isStrategist(msg.sender);
        if (_isStrategist) {
            require(tokenLimit[msg.sender][tokenIn] >= amountIn, '!check limit');
        }
        amountOut = swapRoute.exactInput(tokenIn, tokenOut, amountIn, address(this), amountOutMinimum);
        if (_isStrategist) {
            tokenLimit[msg.sender][tokenIn] -= amountIn;
            tokenLimit[msg.sender][tokenOut] += amountOut;
        }
        swapAfter(tokenOut, amountOut);
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @dev Initiate a transaction with a known output amount and return the input amount
    /// @param tokenIn Token in address
    /// @param tokenOut Token out address
    /// @param amountOut Token out amount
    /// @param amountInMaximum Expect to input the maximum amount of tokens
    /// @return amountIn Token in amount
    function exactOutput(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 amountInMaximum
    ) public onlyAssetsManager returns (uint256 amountIn) {
        amountIn = swapRoute.exactOutput(tokenIn, tokenOut, address(this), amountOut, amountInMaximum);
        if (isStrategist(msg.sender)) {
            require(tokenLimit[msg.sender][tokenIn] >= amountIn, '!check limit');
            tokenLimit[msg.sender][tokenIn] -= amountIn;
            tokenLimit[msg.sender][tokenOut] += amountOut;
        }
        swapAfter(tokenOut, amountOut);
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @notice Create position
    /// @dev Repeated creation of the same position will cause an error, you need to change tickLower Or tickUpper
    /// @param token0 Liquidity pool token 0 contract address
    /// @param token1 Liquidity pool token 1 contract address
    /// @param fee Target liquidity pool rate
    /// @param tickLower Expect to place the lower price boundary of the target liquidity pool
    /// @param tickUpper Expect to place the upper price boundary of the target liquidity pool
    /// @param amount0Desired Desired token 0 amount
    /// @param amount1Desired Desired token 1 amount
    function mint(
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) public onlyAssetsManager
    {
        bool _isStrategist = isStrategist(msg.sender);
        if (_isStrategist) {
            require(tokenLimit[msg.sender][token0] >= amount0Desired, '!check limit');
            require(tokenLimit[msg.sender][token1] >= amount1Desired, '!check limit');
        }
        (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
        ) = UniV3PMExtends.PM.mint(INonfungiblePositionManager.MintParams({
        token0 : token0,
        token1 : token1,
        fee : fee,
        tickLower : tickLower,
        tickUpper : tickUpper,
        amount0Desired : amount0Desired,
        amount1Desired : amount1Desired,
        amount0Min : 0,
        amount1Min : 0,
        recipient : address(this),
        deadline : block.timestamp
        }));
        if (_isStrategist) {
            tokenLimit[msg.sender][token0] -= amount0;
            tokenLimit[msg.sender][token1] -= amount1;
        }
        address pool = UniV3PMExtends.getPool(tokenId);
        bytes32 pk = UniV3PMExtends.positionKey(pool, tickLower, tickUpper);
        history[pk] = tokenId;
        positionOwners[tokenId] = msg.sender;
        works.add(tokenId);
        emit Mint(msg.sender, tokenId, liquidity);
    }

    /// @notice Increase liquidity
    /// @dev Use checkPos to check the position ID
    /// @param tokenId Position ID
    /// @param amount0 Desired Desired token 0 amount
    /// @param amount1 Desired Desired token 1 amount
    /// @param amount0Min Minimum token 0 amount
    /// @param amount1Min Minimum token 1 amount
    /// @return liquidity The amount of liquidity
    /// @return amount0 Actual token 0 amount being added
    /// @return amount1 Actual token 1 amount being added
    function increaseLiquidity(
        uint256 tokenId,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min
    ) public onlyPositionManager(tokenId) returns (
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    ){
        (
        ,
        ,
        address token0,
        address token1,
        ,
        ,
        ,
        ,
        ,
        ,
        ,

        ) = UniV3PMExtends.PM.positions(tokenId);
        address po = positionOwners[tokenId];
        if (isStrategist(po)) {
            require(tokenLimit[po][token0] >= amount0Desired, '!check limit');
            require(tokenLimit[po][token1] >= amount1Desired, '!check limit');
        }
        (liquidity, amount0, amount1) = UniV3PMExtends.PM.increaseLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams({
        tokenId : tokenId,
        amount0Desired : amount0Desired,
        amount1Desired : amount1Desired,
        amount0Min : amount0Min,
        amount1Min : amount1Min,
        deadline : block.timestamp
        }));
        if (isStrategist(po)) {
            tokenLimit[po][token0] -= amount0;
            tokenLimit[po][token1] -= amount1;
        }
        if (!works.contains(tokenId)) {
            works.add(tokenId);
        }
        emit IncreaseLiquidity(msg.sender, tokenId, liquidity);
    }

    /// @notice Decrease liquidity
    /// @dev Use checkPos to query the position ID
    /// @param tokenId Position ID
    /// @param liquidity Expected reduction amount of liquidity
    /// @param amount0Min Minimum amount of token 0 to be reduced
    /// @param amount1Min Minimum amount of token 1 to be reduced
    /// @return amount0 Actual amount of token 0 being reduced
    /// @return amount1 Actual amount of token 1 being reduced
    function decreaseLiquidity(
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0Min,
        uint256 amount1Min
    ) public onlyPositionManager(tokenId) returns (uint256 amount0, uint256 amount1){
        (amount0, amount1) = UniV3PMExtends.PM.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams({
        tokenId : tokenId,
        liquidity : liquidity,
        amount0Min : amount0Min,
        amount1Min : amount1Min,
        deadline : block.timestamp
        }));
        emit DecreaseLiquidity(msg.sender, tokenId, liquidity);
    }

    /// @notice Collect position asset
    /// @dev Use checkPos to check the position ID
    /// @param tokenId Position ID
    /// @param amount0Max Maximum amount of token 0 to be collected
    /// @param amount1Max Maximum amount of token 1 to be collected
    /// @return amount0 Actual amount of token 0 being collected
    /// @return amount1 Actual amount of token 1 being collected
    function collect(
        uint256 tokenId,
        uint128 amount0Max,
        uint128 amount1Max
    ) public onlyPositionManager(tokenId) returns (uint256 amount0, uint256 amount1){
        (amount0, amount1) = UniV3PMExtends.PM.collect(INonfungiblePositionManager.CollectParams({
        tokenId : tokenId,
        recipient : address(this),
        amount0Max : amount0Max,
        amount1Max : amount1Max
        }));
        (
        ,
        ,
        address token0,
        address token1,
        ,
        ,
        ,
        uint128 liquidity,
        ,
        ,
        ,
        ) = UniV3PMExtends.PM.positions(tokenId);
        address po = positionOwners[tokenId];
        if (isStrategist(po)) {
            tokenLimit[po][token0] += amount0;
            tokenLimit[po][token1] += amount1;
        }
        if (liquidity == 0) {
            works.remove(tokenId);
        }
        collectAfter(token0, token1, amount0, amount1);
        emit Collect(msg.sender, tokenId, amount0, amount1);
    }

    /// @notice calc tokenId asset
    /// @dev This function calc tokenId asset
    /// @return tokenId asset
    function calcLiquidityAssets(uint256 tokenId, address toToken) internal view returns (uint256) {
        (
        ,
        ,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        ,
        ,
        ,
        ) = UniV3PMExtends.PM.positions(tokenId);
        (uint256 amount0, uint256 amount1) = UniV3PMExtends.getAmountsForLiquidity(
            token0, token1, fee, tickLower, tickUpper, liquidity);
        (uint256 fee0, uint256 fee1) = UniV3PMExtends.getFeesForLiquidity(tokenId);
        (amount0, amount1) = (amount0.add(fee0), amount1.add(fee1));
        uint256 total;
        if (token0 == toToken) {
            total = amount0;
        } else {
            uint256 _estimateAmountOut = swapRoute.estimateAmountOut(token0, toToken, amount0);
            total = _estimateAmountOut;
        }
        if (token1 == toToken) {
            total = total.add(amount1);
        } else {
            uint256 _estimateAmountOut = swapRoute.estimateAmountOut(token1, toToken, amount1);
            total = total.add(_estimateAmountOut);
        }
        return total;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library SmartPoolStorage {

    bytes32 public constant sSlot = keccak256("SmartPoolStorage.storage.location");

    struct Storage {
        mapping(FeeType => Fee) fees;
        mapping(address => uint256) nets;
        address token;
        address am;
        uint256 cap;
        uint256 lup;
        bool bind;
        bool suspend;
        bool allowJoin;
        bool allowExit;
    }

    struct Fee {
        uint256 ratio;
        uint256 denominator;
        uint256 lastTimestamp;
        uint256 minLine;
    }

    enum FeeType{
        JOIN_FEE, EXIT_FEE, MANAGEMENT_FEE, PERFORMANCE_FEE,TURNOVER_FEE
    }

    function load() internal pure returns (Storage storage s) {
        bytes32 loc = sSlot;
        assembly {
            s.slot := loc
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../interfaces/uniswap-v3/INonfungiblePositionManager.sol";
import "../interfaces/uniswap-v3/IUniswapV3Pool.sol";
import "../interfaces/uniswap-v3/TickMath.sol";
import "../interfaces/uniswap-v3/LiquidityAmounts.sol";
import "../interfaces/uniswap-v3/FixedPoint128.sol";
import "../interfaces/uniswap-v3/PoolAddress.sol";


/// @title UniV3 extends libraries
/// @notice libraries
library UniV3PMExtends {

    //Nonfungible Position Manager
    INonfungiblePositionManager constant internal PM = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    /// @notice Position id
    /// @dev Position ID
    /// @param addr any address
    /// @param tickLower Tick lower price bound
    /// @param tickUpper Tick upper price bound
    /// @return ABI encode
    function positionKey(
        address addr,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(addr, tickLower, tickUpper));
    }

    /// @notice get pool by tokenId
    /// @param tokenId position Id
    function getPool(uint256 tokenId) internal view returns (address){
        (
        ,
        ,
        address token0,
        address token1,
        uint24 fee,
        ,
        ,
        ,
        ,
        ,
        ,
        ) = PM.positions(tokenId);
        return PoolAddress.getPool(token0, token1, fee);
    }

    /// @notice Calculate the number of redeemable tokens based on the amount of liquidity
    /// @dev Used when redeeming liquidity
    /// @param token0 Token 0 address
    /// @param token1 Token 1 address
    /// @param fee Fee rate
    /// @param tickLower Tick lower price bound
    /// @param tickUpper Tick upper price bound
    /// @param liquidity Liquidity amount
    /// @return amount0 Token 0 amount
    /// @return amount1 Token 1 amount
    function getAmountsForLiquidity(
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal view returns (uint256 amount0, uint256 amount1) {
        (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(PoolAddress.getPool(token0, token1, fee)).slot0();
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            liquidity
        );
    }

    ///@notice Calculate unreceived handling fees for liquid positions
    /// @param tokenId Position ID
    /// @return fee0 Token 0 fee amount
    /// @return fee1 Token 1 fee amount
    function getFeesForLiquidity(
        uint256 tokenId
    ) internal view returns (uint256 fee0, uint256 fee1){
        (
        ,
        ,
        ,
        ,
        ,
        ,
        ,
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
        ) = PM.positions(tokenId);
        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = getFeeGrowthInside(tokenId);
        fee0 = tokensOwed0 + FullMath.mulDiv(
            feeGrowthInside0X128 - feeGrowthInside0LastX128,
            liquidity,
            FixedPoint128.Q128
        );
        fee1 = tokensOwed1 + FullMath.mulDiv(
            feeGrowthInside1X128 - feeGrowthInside1LastX128,
            liquidity,
            FixedPoint128.Q128
        );
    }

    /// @notice Retrieves fee growth data
    function getFeeGrowthInside(
        uint256 tokenId
    ) internal view returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        (
        ,
        ,
        ,
        ,
        ,
        int24 tickLower,
        int24 tickUpper,
        ,
        ,
        ,
        ,
        ) = PM.positions(tokenId);
        IUniswapV3Pool pool = IUniswapV3Pool(getPool(tokenId));
        (,int24 tickCurrent,,,,,) = pool.slot0();
        uint256 feeGrowthGlobal0X128 = pool.feeGrowthGlobal0X128();
        uint256 feeGrowthGlobal1X128 = pool.feeGrowthGlobal1X128();

        (
        ,
        ,
        uint256 lowerFeeGrowthOutside0X128,
        uint256 lowerFeeGrowthOutside1X128,
        ,
        ,
        ,
        ) = pool.ticks(tickLower);

        (
        ,
        ,
        uint256 upperFeeGrowthOutside0X128,
        uint256 upperFeeGrowthOutside1X128,
        ,
        ,
        ,
        ) = pool.ticks(tickUpper);

        // calculate fee growth below
        uint256 feeGrowthBelow0X128;
        uint256 feeGrowthBelow1X128;
        if (tickCurrent >= tickLower) {
            feeGrowthBelow0X128 = lowerFeeGrowthOutside0X128;
            feeGrowthBelow1X128 = lowerFeeGrowthOutside1X128;
        } else {
            feeGrowthBelow0X128 = feeGrowthGlobal0X128 - lowerFeeGrowthOutside0X128;
            feeGrowthBelow1X128 = feeGrowthGlobal1X128 - lowerFeeGrowthOutside1X128;
        }

        // calculate fee growth above
        uint256 feeGrowthAbove0X128;
        uint256 feeGrowthAbove1X128;
        if (tickCurrent < tickUpper) {
            feeGrowthAbove0X128 = upperFeeGrowthOutside0X128;
            feeGrowthAbove1X128 = upperFeeGrowthOutside1X128;
        } else {
            feeGrowthAbove0X128 = feeGrowthGlobal0X128 - upperFeeGrowthOutside0X128;
            feeGrowthAbove1X128 = feeGrowthGlobal1X128 - upperFeeGrowthOutside1X128;
        }

        feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
        feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/// @title ERC20 extends libraries
/// @notice libraries
library ERC20Extends {

    using SafeERC20 for IERC20;

    /// @notice Safe approve
    /// @dev Avoid errors that occur in some ERC20 token authorization restrictions
    /// @param token Approval token address
    /// @param to Approval address
    /// @param amount Approval amount
    function safeApprove(address token, address to, uint256 amount) internal {
        IERC20 tokenErc20 = IERC20(token);
        uint256 allowance = tokenErc20.allowance(address(this), to);
        if (allowance < amount) {
            if (allowance > 0) {
                tokenErc20.safeApprove(to, 0);
            }
            tokenErc20.safeApprove(to, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "../storage/SmartPoolStorage.sol";
pragma abicoder v2;

/// @title Vault - the vault interface
/// @notice This contract extends ERC20, defines basic vault functions and rewrites ERC20 transferFrom function
interface IVault {

    /// @notice Vault cap
    /// @dev The max number of vault to be issued
    /// @return Max vault cap
    function getCap() external view returns (uint256);

    /// @notice Get fee by type
    /// @dev (0=JOIN_FEE,1=EXIT_FEE,2=MANAGEMENT_FEE,3=PERFORMANCE_FEE,4=TURNOVER_FEE)
    /// @param ft Fee type
    function getFee(SmartPoolStorage.FeeType ft) external view returns (SmartPoolStorage.Fee memory);

    /// @notice Calculate the fee by ratio
    /// @dev This is used to calculate join and redeem fee
    /// @param ft Fee type
    /// @param vaultAmount vault amount
    function calcRatioFee(SmartPoolStorage.FeeType ft, uint256 vaultAmount) external view returns (uint256);


    /// @notice The net worth of the vault from the time the last fee collected
    /// @dev This is used to calculate the performance fee
    /// @param account Account address
    /// @return The net worth of the vault
    function accountNetValue(address account) external view returns (uint256);

    /// @notice The current vault net worth
    /// @dev This is used to update and calculate account net worth
    /// @return The net worth of the vault
    function globalNetValue() external view returns (uint256);

    /// @notice Convert vault amount to cash amount
    /// @dev This converts the user vault amount to cash amount when a user redeems the vault
    /// @param vaultAmount Redeem vault amount
    /// @return Cash amount
    function convertToCash(uint256 vaultAmount) external view returns (uint256);

    /// @notice Convert cash amount to share amount
    /// @dev This converts cash amount to share amount when a user buys the vault
    /// @param cashAmount Join cash amount
    /// @return share amount
    function convertToShare(uint256 cashAmount) external view returns (uint256);

    /// @notice Vault token address for joining and redeeming
    /// @dev This is address is created when the vault is first created.
    /// @return Vault token address
    function ioToken() external view returns (address);

    /// @notice Vault mangement contract address
    /// @dev The vault management contract address is bind to the vault when the vault is created
    /// @return Vault management contract address
    function AM() external view returns (address);

    /// @notice Vault total asset
    /// @dev This calculates vault net worth or AUM
    /// @return Vault total asset
    function assets()external view returns(uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
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
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/uniswap-v3/ISwapRouter.sol";
import "../interfaces/uniswap-v3/IUniswapV3Pool.sol";
import "../interfaces/uniswap-v3/PoolAddress.sol";
import "../interfaces/uniswap-v3/Path.sol";

import "./SafeMathExtends.sol";

pragma abicoder v2;

/// @title UniV3 Swap extends libraries
/// @notice libraries
library UniV3SwapExtends {

    using Path for bytes;
    using SafeMath for uint256;
    using SafeMathExtends for uint256;

    //x96
    uint256 constant internal x96 = 2 ** 96;

    //fee denominator
    uint256 constant internal denominator = 1000000;

    //Swap Router
    ISwapRouter constant internal SRT = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    /// @notice Estimated to obtain the target token amount
    /// @dev Only allow the asset transaction path that has been set to be estimated
    /// @param self Mapping path
    /// @param from Source token address
    /// @param to Target token address
    /// @param amountIn Source token amount
    /// @return amountOut Target token amount
    function estimateAmountOut(
        mapping(address => mapping(address => bytes)) storage self,
        address from,
        address to,
        uint256 amountIn
    ) internal view returns (uint256 amountOut){
        if (amountIn == 0) {return 0;}
        bytes memory path = self[from][to];
        amountOut = amountIn;
        while (true) {
            (address fromToken, address toToken, uint24 fee) = path.getFirstPool().decodeFirstPool();
            address _pool = PoolAddress.getPool(fromToken, toToken, fee);
            (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(_pool).slot0();
            address token0 = fromToken < toToken ? fromToken : toToken;
            amountOut = amountOut.mul(denominator.sub(uint256(fee))).div(denominator);
            if (token0 == toToken) {
                amountOut = amountOut.sqrt().mul(x96).div(sqrtPriceX96) ** 2;
            } else {
                amountOut = amountOut.sqrt().mul(sqrtPriceX96).div(x96) ** 2;
            }
            bool hasMultiplePools = path.hasMultiplePools();
            if (hasMultiplePools) {
                path = path.skipToken();
            } else {
                break;
            }
        }
    }

    /// @notice Estimate the amount of source tokens that need to be provided
    /// @dev Only allow the governance identity to set the underlying asset token address
    /// @param self Mapping path
    /// @param from Source token address
    /// @param to Target token address
    /// @param amountOut Expected target token amount
    /// @return amountIn Source token amount
    function estimateAmountIn(
        mapping(address => mapping(address => bytes)) storage self,
        address from,
        address to,
        uint256 amountOut
    ) internal view returns (uint256 amountIn){
        if (amountOut == 0) {return 0;}
        bytes memory path = self[from][to];
        amountIn = amountOut;
        while (true) {
            (address fromToken, address toToken, uint24 fee) = path.getFirstPool().decodeFirstPool();
            address _pool = PoolAddress.getPool(fromToken, toToken, fee);
            (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(_pool).slot0();
            address token0 = fromToken < toToken ? fromToken : toToken;
            if (token0 == toToken) {
                amountIn = amountIn.sqrt().mul(sqrtPriceX96).div(x96) ** 2;
            } else {
                amountIn = amountIn.sqrt().mul(x96).div(sqrtPriceX96) ** 2;
            }
            amountIn = amountIn.mul(denominator).div(denominator.sub(uint256(fee)));
            bool hasMultiplePools = path.hasMultiplePools();
            if (hasMultiplePools) {
                path = path.skipToken();
            } else {
                break;
            }
        }
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Initiate a transaction with a known input amount and return the output amount
    /// @param self Mapping path
    /// @param from Input token address
    /// @param to Output token address
    /// @param amountIn Token in amount
    /// @param recipient Recipient address
    /// @param amountOutMinimum Expected to get minimum token out amount
    /// @return Token out amount
    function exactInput(
        mapping(address => mapping(address => bytes)) storage self,
        address from,
        address to,
        uint256 amountIn,
        address recipient,
        uint256 amountOutMinimum
    ) internal returns (uint256){
        bytes memory path = self[from][to];
        return SRT.exactInput(
            ISwapRouter.ExactInputParams({
        path : path,
        recipient : recipient,
        deadline : block.timestamp,
        amountIn : amountIn,
        amountOutMinimum : amountOutMinimum
        }));
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @dev Initiate a transaction with a known output amount and return the input amount
    /// @param self Mapping path
    /// @param from Input token address
    /// @param to Output token address
    /// @param recipient Recipient address
    /// @param amountOut Token out amount
    /// @param amountInMaximum Expect to input the maximum amount of tokens
    /// @return Token in amount
    function exactOutput(
        mapping(address => mapping(address => bytes)) storage self,
        address from,
        address to,
        address recipient,
        uint256 amountOut,
        uint256 amountInMaximum
    ) internal returns (uint256){
        bytes memory path = self[to][from];
        return SRT.exactOutput(
            ISwapRouter.ExactOutputParams({
        path : path,
        recipient : recipient,
        deadline : block.timestamp,
        amountOut : amountOut,
        amountInMaximum : amountInMaximum
        }));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import './BytesLib.sol';

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Check the legitimacy of the path
    /// @param path The encoded swap path
    /// @return Legal path
    function valid(bytes memory path)internal pure returns(bool) {
        return path.length>=POP_OFFSET;
    }

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Gets the segment corresponding to the last pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the last pool in the path
    function getLastPool(bytes memory path) internal pure returns (bytes memory) {
        if(path.length==POP_OFFSET){
            return path;
        }else{
            return path.slice(path.length-POP_OFFSET, path.length);
        }
    }

    /// @notice Gets the first address of the path
    /// @param path The encoded swap path
    /// @return address
    function getFirstAddress(bytes memory path)internal pure returns(address){
        return path.toAddress(0);
    }

    /// @notice Gets the last address of the path
    /// @param path The encoded swap path
    /// @return address
    function getLastAddress(bytes memory path)internal pure returns(address){
        return path.toAddress(path.length-ADDR_SIZE);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../storage/GovIdentityStorage.sol";

/// @title manager role
/// @notice provide a unified identity address pool
contract GovIdentity {

    constructor() {
        _init();
    }

    function _init() internal{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.governance = msg.sender;
        identity.rewards = msg.sender;
        identity.strategist[msg.sender]=true;
        identity.admin[msg.sender]=true;
    }

    modifier onlyAdmin() {
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        require(isAdmin(msg.sender), "!admin");
        _;
    }

    modifier onlyStrategist() {
        require(isStrategist(msg.sender), "!strategist");
        _;
    }

    modifier onlyGovernance() {
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        require(msg.sender == identity.governance, "!governance");
        _;
    }

    modifier onlyStrategistOrGovernance() {
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        require(identity.strategist[msg.sender] || msg.sender == identity.governance, "!governance and !strategist");
        _;
    }

    modifier onlyAdminOrGovernance() {
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        require(identity.admin[msg.sender] || msg.sender == identity.governance, "!governance and !admin");
        _;
    }

    function setGovernance(address _governance) public onlyGovernance{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.governance = _governance;
    }

    function setRewards(address _rewards) public onlyGovernance{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.rewards = _rewards;
    }

    function setStrategist(address _strategist,bool enable) public onlyGovernance{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.strategist[_strategist]=enable;
    }

    function setAdmin(address _admin,bool enable) public onlyGovernance{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.admin[_admin]=enable;
    }

    function getGovernance() public view returns(address){
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        return identity.governance;
    }

    function getRewards() public view returns(address){
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        return identity.rewards ;
    }

    function isStrategist(address _strategist) public view returns(bool){
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        return identity.strategist[_strategist];
    }

    function isAdmin(address _admin) public view returns(bool){
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        return identity.admin[_admin];
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    //Uniswap V3 Factory
    address constant private factory = address(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @dev Returns the pool for the given token pair and fee. The pool contract may or may not exist.
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (address) {
        return computeAddress(getPoolKey(tokenA, tokenB, fee));
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0 : tokenA, token1 : tokenB, fee : fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './FullMath.sol';
import './FixedPoint96.sol';

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
        FullMath.mulDiv(
            uint256(liquidity) << FixedPoint96.RESOLUTION,
            sqrtRatioBX96 - sqrtRatioAX96,
            sqrtRatioBX96
        ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = - 887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = - MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(- int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141;
        // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool {

    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
    external
    view
    returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);


    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
    external
    view
    returns (
        uint128 liquidityGross,
        int128 liquidityNet,
        uint256 feeGrowthOutside0X128,
        uint256 feeGrowthOutside1X128,
        int56 tickCumulativeOutside,
        uint160 secondsPerLiquidityOutsideX128,
        uint32 secondsOutside,
        bool initialized
    );


}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

pragma experimental ABIEncoderV2;
interface INonfungiblePositionManager is IERC721
{
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
    external
    view
    returns (
        uint96 nonce,
        address operator,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
    external
    payable
    returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
    external
    payable
    returns (
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
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
pragma solidity ^0.7.6;

// a library for performing various math operations

library SafeMathExtends {

    uint256 internal constant BONE = 10 ** 18;

    // Add two numbers together checking for overflows
    function badd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    // subtract two numbers and return diffecerence when it underflows
    function bsubSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    // Subtract two numbers checking for underflows
    function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
        (uint256 c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    // Multiply two 18 decimals numbers
    function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint256 c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint256 c2 = c1 / BONE;
        return c2;
    }

    // Divide two 18 decimals numbers
    function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ERR_DIV_ZERO");
        uint256 c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL");
        // bmul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL");
        //  badd require
        uint256 c2 = c1 / b;
        return c2;
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import './IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.5.0 <=0.8.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0;
        // Least significant 256 bits of the product
        uint256 prod1;
        // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = - denominator & denominator;

        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv;
        // inverse mod 2**8
        inv *= 2 - denominator * inv;
        // inverse mod 2**16
        inv *= 2 - denominator * inv;
        // inverse mod 2**32
        inv *= 2 - denominator * inv;
        // inverse mod 2**64
        inv *= 2 - denominator * inv;
        // inverse mod 2**128
        inv *= 2 - denominator * inv;
        // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
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
pragma solidity ^0.7.6;

library GovIdentityStorage {

  bytes32 public constant govSlot = keccak256("GovIdentityStorage.storage.location");

  struct Identity{
    address governance;
    address rewards;
    mapping(address=>bool) strategist;
    mapping(address=>bool) admin;
  }

  function load() internal pure returns (Identity storage gov) {
    bytes32 loc = govSlot;
    assembly {
      gov.slot := loc
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
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