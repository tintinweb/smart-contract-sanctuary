// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface IPair is IERC20Upgradeable {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniV3Router {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external returns (uint amountOut);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }
    function increaseLiquidity(
       IncreaseLiquidityParams calldata params
    ) external returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external returns (uint256 amount0, uint256 amount1);

    function positions(
        uint256 tokenId
    ) external view returns (uint96, address, address, address, uint24, int24, int24, uint128, uint256, uint256, uint128, uint128);
}

interface IDaoL1Vault is IERC20Upgradeable {
    function deposit(uint amount) external;
    function withdraw(uint share) external returns (uint);
    function getAllPoolInUSD() external view returns (uint);
    function getAllPoolInETH() external view returns (uint);
    function getAllPoolInETHExcludeVestedILV() external view returns (uint);
}

interface IDaoL1VaultUniV3 is IERC20Upgradeable {
    function deposit(uint amount0, uint amount1) external;
    function withdraw(uint share) external returns (uint, uint);
    function getAllPoolInUSD() external view returns (uint);
    function getAllPoolInETH() external view returns (uint);
}

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

contract MVFStrategy is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IPair;

    IERC20Upgradeable constant WETH = IERC20Upgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20Upgradeable constant AXS = IERC20Upgradeable(0xBB0E17EF65F82Ab018d8EDd776e8DD940327B28b);
    IERC20Upgradeable constant SLP = IERC20Upgradeable(0xCC8Fa225D80b9c7D42F96e9570156c65D6cAAa25);
    IERC20Upgradeable constant ILV = IERC20Upgradeable(0x767FE9EDC9E0dF98E07454847909b5E959D7ca0E);
    IERC20Upgradeable constant GHST = IERC20Upgradeable(0x3F382DbD960E3a9bbCeaE22651E88158d2791550);
    IERC20Upgradeable constant REVV = IERC20Upgradeable(0x557B933a7C2c45672B610F8954A3deB39a51A8Ca);
    IERC20Upgradeable constant MVI = IERC20Upgradeable(0x72e364F2ABdC788b7E918bc238B21f109Cd634D7);

    IERC20Upgradeable constant AXSETH = IERC20Upgradeable(0x0C365789DbBb94A29F8720dc465554c587e897dB);
    IERC20Upgradeable constant SLPETH = IERC20Upgradeable(0x8597fa0773888107E2867D36dd87Fe5bAFeAb328);
    IERC20Upgradeable constant ILVETH = IERC20Upgradeable(0x6a091a3406E0073C3CD6340122143009aDac0EDa);
    IERC20Upgradeable constant GHSTETH = IERC20Upgradeable(0xFbA31F01058DB09573a383F26a088f23774d4E5d);
    IPair constant REVVETH = IPair(0x724d5c9c618A2152e99a45649a3B8cf198321f46);

    IRouter constant uniV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniV3Router constant uniV3Router = IUniV3Router(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IRouter constant sushiRouter = IRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // Sushi

    IDaoL1Vault public AXSETHVault;
    IDaoL1Vault public SLPETHVault;
    IDaoL1Vault public ILVETHVault;
    IDaoL1VaultUniV3 public GHSTETHVault;

    uint constant AXSETHTargetPerc = 2000;
    uint constant SLPETHTargetPerc = 1500;
    uint constant ILVETHTargetPerc = 2000;
    uint constant GHSTETHTargetPerc = 1000;
    uint constant REVVETHTargetPerc = 1000;
    uint constant MVITargetPerc = 2500;

    address public vault;
    uint public watermark; // In USD (18 decimals)
    uint public profitFeePerc;

    event TargetComposition (uint AXSETHTargetPool, uint SLPETHTargetPool, uint ILVETHTargetPool, uint GHSTETHTargetPool, uint REVVETHTargetPool, uint MVITargetPool);
    event CurrentComposition (uint AXSETHCurrentPool, uint SLPETHCurrentPool, uint ILVETHCurrentPool, uint GHSTETHCurrentPool, uint REVVETHCurrentPool, uint MVICurrentPool);
    event InvestAXSETH(uint WETHAmt, uint AXSETHAmt);
    event InvestSLPETH(uint WETHAmt, uint SLPETHAmt);
    event InvestILVETH(uint WETHAmt, uint ILVETHAmt);
    event InvestGHSTETH(uint WETHAmt, uint GHSTAmt);
    event InvestREVVETH(uint WETHAmt, uint REVVETHAmt);
    event InvestMVI(uint WETHAmt, uint MVIAmt);
    event Withdraw(uint amount, uint WETHAmt);
    event WithdrawAXSETH(uint lpTokenAmt, uint WETHAmt);
    event WithdrawSLPETH(uint lpTokenAmt, uint WETHAmt);
    event WithdrawILVETH(uint lpTokenAmt, uint WETHAmt);
    event WithdrawGHSTETH(uint GHSTAmt, uint WETHAmt);
    event WithdrawREVVETH(uint lpTokenAmt, uint WETHAmt);
    event WithdrawMVI(uint lpTokenAmt, uint WETHAmt);
    event CollectProfitAndUpdateWatermark(uint currentWatermark, uint lastWatermark, uint fee);
    event AdjustWatermark(uint currentWatermark, uint lastWatermark);
    event Reimburse(uint WETHAmt);
    event EmergencyWithdraw(uint WETHAmt);

    modifier onlyVault {
        require(msg.sender == vault, "Only vault");
        _;
    }

    function initialize(
        address _AXSETHVault, address _SLPETHVault, address _ILVETHVault, address _GHSTETHVault
    ) external initializer {
        __Ownable_init();

        AXSETHVault = IDaoL1Vault(_AXSETHVault);
        SLPETHVault = IDaoL1Vault(_SLPETHVault);
        ILVETHVault = IDaoL1Vault(_ILVETHVault);
        GHSTETHVault = IDaoL1VaultUniV3(_GHSTETHVault);

        profitFeePerc = 2000;

        WETH.safeApprove(address(sushiRouter), type(uint).max);
        WETH.safeApprove(address(uniV2Router), type(uint).max);
        WETH.safeApprove(address(uniV3Router), type(uint).max);

        AXS.safeApprove(address(sushiRouter), type(uint).max);
        SLP.safeApprove(address(sushiRouter), type(uint).max);
        ILV.safeApprove(address(sushiRouter), type(uint).max);
        GHST.safeApprove(address(uniV3Router), type(uint).max);
        REVV.safeApprove(address(uniV2Router), type(uint).max);
        MVI.safeApprove(address(uniV2Router), type(uint).max);

        AXSETH.safeApprove(address(sushiRouter), type(uint).max);
        AXSETH.safeApprove(address(AXSETHVault), type(uint).max);
        SLPETH.safeApprove(address(sushiRouter), type(uint).max);
        SLPETH.safeApprove(address(SLPETHVault), type(uint).max);
        ILVETH.safeApprove(address(sushiRouter), type(uint).max);
        ILVETH.safeApprove(address(ILVETHVault), type(uint).max);
        GHST.safeApprove(address(GHSTETHVault), type(uint).max);
        WETH.safeApprove(address(GHSTETHVault), type(uint).max);
        REVVETH.safeApprove(address(uniV2Router), type(uint).max);
    }

    function invest(uint WETHAmt) external onlyVault {
        WETH.safeTransferFrom(vault, address(this), WETHAmt);
        WETHAmt = WETH.balanceOf(address(this));

        uint[] memory pools = getEachPool(false);
        uint pool = pools[0] + pools[1] + pools[2] + pools[3] + pools[4] + pools[5] + WETHAmt;
        uint AXSETHTargetPool = pool * 2000 / 10000; // 20%
        uint SLPETHTargetPool = pool * 1500 / 10000; // 15%
        uint ILVETHTargetPool = AXSETHTargetPool; // 20%
        uint GHSTETHTargetPool = pool * 1000 / 10000; // 10%
        uint REVVETHTargetPool = GHSTETHTargetPool; // 10%
        uint MVITargetPool = pool * 2500 / 10000; // 25%

        // Rebalancing invest
        if (
            AXSETHTargetPool > pools[0] &&
            SLPETHTargetPool > pools[1] &&
            ILVETHTargetPool > pools[2] &&
            GHSTETHTargetPool > pools[3] &&
            REVVETHTargetPool > pools[4] &&
            MVITargetPool > pools[5]
        ) {
            uint WETHAmt1000 = WETHAmt * 1000 / 10000;
            uint WETHAmt750 = WETHAmt * 750 / 10000;
            uint WETHAmt500 = WETHAmt * 500 / 10000;

            // AXS-ETH (10%-10%)
            investAXSETH(WETHAmt1000);
            // SLP-ETH (7.5%-7.5%)
            investSLPETH(WETHAmt750);
            // ILV-ETH (10%-10%)
            investILVETH(WETHAmt1000);
            // GHST-ETH (5%-5%)
            investGHSTETH(WETHAmt500);
            // REVV-ETH (5%-5%)
            investREVVETH(WETHAmt500);
            // MVI (25%)
            investMVI(WETHAmt * 2500 / 10000);
        } else {
            uint furthest;
            uint farmIndex;
            uint diff;

            if (AXSETHTargetPool > pools[0]) {
                diff = AXSETHTargetPool - pools[0];
                furthest = diff;
                farmIndex = 0;
            }
            if (SLPETHTargetPool > pools[1]) {
                diff = SLPETHTargetPool - pools[1];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 1;
                }
            }
            if (ILVETHTargetPool > pools[2]) {
                diff = ILVETHTargetPool - pools[2];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 2;
                }
            }
            if (GHSTETHTargetPool > pools[3]) {
                diff = GHSTETHTargetPool - pools[3];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 3;
                }
            }
            if (REVVETHTargetPool > pools[4]) {
                diff = AXSETHTargetPool - pools[4];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 4;
                }
            }
            if (MVITargetPool > pools[5]) {
                diff = MVITargetPool - pools[5];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 5;
                }
            }

            if (farmIndex == 0) investAXSETH(WETHAmt / 2);
            else if (farmIndex == 1) investSLPETH(WETHAmt / 2);
            else if (farmIndex == 2) investILVETH(WETHAmt / 2);
            else if (farmIndex == 3) investGHSTETH(WETHAmt / 2);
            else if (farmIndex == 4) investREVVETH(WETHAmt / 2);
            else investMVI(WETHAmt);
        }

        emit TargetComposition(AXSETHTargetPool, SLPETHTargetPool, ILVETHTargetPool, GHSTETHTargetPool, REVVETHTargetPool, MVITargetPool);
        emit CurrentComposition(pools[0], pools[1], pools[2], pools[3], pools[4], pools[5]);
    }

    function investAXSETH(uint WETHAmt) private {
        uint AXSAmt = sushiSwap(address(WETH), address(AXS), WETHAmt);
        (,,uint AXSETHAmt) = sushiRouter.addLiquidity(address(AXS), address(WETH), AXSAmt, WETHAmt, 0, 0, address(this), block.timestamp);
        AXSETHVault.deposit(AXSETHAmt);
        emit InvestAXSETH(WETHAmt, AXSETHAmt);
    }

    function investSLPETH(uint WETHAmt) private {
        uint SLPAmt = sushiSwap(address(WETH), address(SLP), WETHAmt);
        (,,uint SLPETHAmt) = sushiRouter.addLiquidity(address(SLP), address(WETH), SLPAmt, WETHAmt, 0, 0, address(this), block.timestamp);
        SLPETHVault.deposit(SLPETHAmt);
        emit InvestSLPETH(WETHAmt, SLPETHAmt);
    }

    function investILVETH(uint WETHAmt) private {
        uint ILVAmt = sushiSwap(address(WETH), address(ILV), WETHAmt);
        (,,uint ILVETHAmt) = sushiRouter.addLiquidity(address(ILV), address(WETH), ILVAmt, WETHAmt, 0, 0, address(this), block.timestamp);
        ILVETHVault.deposit(ILVETHAmt);
        emit InvestILVETH(WETHAmt, ILVETHAmt);
    }

    function investGHSTETH(uint WETHAmt) private {
        uint GHSTAmt = uniV3Swap(address(WETH), address(GHST), 10000, WETHAmt);
        GHSTETHVault.deposit(GHSTAmt, WETHAmt);
    }

    function investREVVETH(uint WETHAmt) private {
        uint REVVAmt = uniV2Swap(address(WETH), address(REVV), WETHAmt);
        (,,uint REVVETHAmt) = uniV2Router.addLiquidity(address(REVV), address(WETH), REVVAmt, WETHAmt, 0, 0, address(this), block.timestamp);
        emit InvestREVVETH(WETHAmt, REVVETHAmt);
    }

    function investMVI(uint WETHAmt) private {
        uint MVIAmt = uniV2Swap(address(WETH), address(MVI), WETHAmt);
        emit InvestMVI(WETHAmt, MVIAmt);
    }

    /// @param amount Amount to withdraw in USD
    function withdraw(uint amount) external onlyVault returns (uint WETHAmt) {
        uint sharePerc = amount * 1e18 / getAllPoolInUSD(false);
        uint WETHAmtBefore = WETH.balanceOf(address(this));
        withdrawAXSETH(sharePerc);
        withdrawSLPETH(sharePerc);
        withdrawILVETH(sharePerc);
        withdrawGHSTETH(sharePerc);
        withdrawREVVETH(sharePerc);
        withdrawMVI(sharePerc);
        WETHAmt = WETH.balanceOf(address(this)) - WETHAmtBefore;
        WETH.safeTransfer(vault, WETHAmt);
        emit Withdraw(amount, WETHAmt);
    }

    function withdrawAXSETH(uint sharePerc) private {
        uint AXSETHAmt = AXSETHVault.withdraw(AXSETHVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint AXSAmt, uint WETHAmt) = sushiRouter.removeLiquidity(address(AXS), address(WETH), AXSETHAmt, 0, 0, address(this), block.timestamp);
        uint _WETHAmt = sushiSwap(address(AXS), address(WETH), AXSAmt);
        emit WithdrawAXSETH(AXSETHAmt, WETHAmt + _WETHAmt);
    }

    function withdrawSLPETH(uint sharePerc) private {
        uint SLPETHAmt = SLPETHVault.withdraw(SLPETHVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint SLPAmt, uint WETHAmt) = sushiRouter.removeLiquidity(address(SLP), address(WETH), SLPETHAmt, 0, 0, address(this), block.timestamp);
        uint _WETHAmt = sushiSwap(address(SLP), address(WETH), SLPAmt);
        emit WithdrawSLPETH(SLPETHAmt, WETHAmt + _WETHAmt);
    }

    function withdrawILVETH(uint sharePerc) private {
        uint ILVETHAmt = ILVETHVault.withdraw(ILVETHVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint ILVAmt, uint WETHAmt) = sushiRouter.removeLiquidity(address(ILV), address(WETH), ILVETHAmt, 0, 0, address(this), block.timestamp);
        uint _WETHAmt = sushiSwap(address(ILV), address(WETH), ILVAmt);
        emit WithdrawILVETH(ILVETHAmt, WETHAmt + _WETHAmt);
    }

    function withdrawGHSTETH(uint sharePerc) private {
        (uint GHSTAmt, uint WETHAmt) = GHSTETHVault.withdraw(GHSTETHVault.balanceOf(address(this)) * sharePerc / 1e18);
        uniV3Swap(address(GHST), address(WETH), 10000, GHSTAmt);
        emit WithdrawGHSTETH(GHSTAmt, WETHAmt);
    }

    function withdrawREVVETH(uint sharePerc) private {
        uint REVVETHAmt = REVVETH.balanceOf(address(this)) * sharePerc / 1e18;
        (uint REVVAmt, uint WETHAmt) = uniV2Router.removeLiquidity(address(REVV), address(WETH), REVVETHAmt, 0, 0, address(this), block.timestamp);
        uint _WETHAmt = uniV2Swap(address(REVV), address(WETH), REVVAmt);
        emit WithdrawREVVETH(REVVETHAmt, WETHAmt + _WETHAmt);
    }

    function withdrawMVI(uint sharePerc) private {
        uint MVIAmt = MVI.balanceOf(address(this)) * sharePerc / 1e18;
        uint WETHAmt = (uniV2Router.swapExactTokensForTokens(
            MVIAmt, 0, getPath(address(MVI), address(WETH)), address(this), block.timestamp
        ))[1];
        emit WithdrawMVI(MVIAmt, WETHAmt);
    }

    function collectProfitAndUpdateWatermark() public onlyVault returns (uint fee) {
        uint currentWatermark = getAllPoolInUSD(false);
        uint lastWatermark = watermark;
        if (lastWatermark == 0) { // First invest or after emergency withdrawal
            watermark = currentWatermark;
        } else {
            if (currentWatermark > lastWatermark) {
                uint profit = currentWatermark - lastWatermark;
                fee = profit * profitFeePerc / 10000;
                watermark = currentWatermark - fee;
            }
        }
        emit CollectProfitAndUpdateWatermark(currentWatermark, lastWatermark, fee);
    }

    /// @param signs True for positive, false for negative
    function adjustWatermark(uint amount, bool signs) external onlyVault {
        uint lastWatermark = watermark;
        watermark = signs == true ? watermark + amount : watermark - amount;
        emit AdjustWatermark(watermark, lastWatermark);
    }

    /// @param amount Amount to reimburse to vault contract in ETH
    function reimburse(uint farmIndex, uint amount) external onlyVault returns (uint WETHAmt) {
        if (farmIndex == 0) withdrawAXSETH(amount * 1e18 / getAXSETHPool());
        else if (farmIndex == 1) withdrawSLPETH(amount * 1e18 / getSLPETHPool());
        else if (farmIndex == 2) withdrawILVETH(amount * 1e18 / getILVETHPool(false));
        else if (farmIndex == 3) withdrawGHSTETH(amount * 1e18 / getGHSTETHPool());
        else if (farmIndex == 4) withdrawREVVETH(amount * 1e18 / getREVVETHPool());
        else if (farmIndex == 5) withdrawMVI(amount * 1e18 / getMVIPool());
        WETHAmt = WETH.balanceOf(address(this));
        WETH.safeTransfer(vault, WETHAmt);
        emit Reimburse(WETHAmt);
    }

    function emergencyWithdraw() external onlyVault {
        // 1e18 == 100% of share
        withdrawAXSETH(1e18);
        withdrawSLPETH(1e18);
        withdrawILVETH(1e18);
        withdrawGHSTETH(1e18);
        withdrawREVVETH(1e18);
        withdrawMVI(1e18);
        uint WETHAmt = WETH.balanceOf(address(this));
        WETH.safeTransfer(vault, WETHAmt);
        watermark = 0;
        emit EmergencyWithdraw(WETHAmt);
    }

    function sushiSwap(address from, address to, uint amount) private returns (uint) {
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;
        return (sushiRouter.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp))[1];
    }

    function uniV2Swap(address from, address to, uint amount) private returns (uint) {
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;
        return (uniV2Router.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp))[1];
    }

    function uniV3Swap(address tokenIn, address tokenOut, uint24 fee, uint amountIn) private returns (uint amountOut) {
        IUniV3Router.ExactInputSingleParams memory params =
            IUniV3Router.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        amountOut = uniV3Router.exactInputSingle(params);
    }

    function setVault(address _vault) external onlyOwner {
        require(vault == address(0), "Vault set");
        vault = _vault;
    }

    function setProfitFeePerc(uint _profitFeePerc) external onlyVault {
        profitFeePerc = _profitFeePerc;
    }

    function getPath(address tokenA, address tokenB) private pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
    }

    function getAXSETHPool() private view returns (uint) {
        return AXSETHVault.getAllPoolInETH();
    }

    function getSLPETHPool() private view returns (uint) {
        return SLPETHVault.getAllPoolInETH();
    }

    function getILVETHPool(bool includeVestedILV) private view returns (uint) {
        return includeVestedILV ? 
            ILVETHVault.getAllPoolInETH(): 
            ILVETHVault.getAllPoolInETHExcludeVestedILV();
    }

    function getGHSTETHPool() private view returns (uint) {
        return GHSTETHVault.getAllPoolInETH();
    }

    function getREVVETHPool() private view returns (uint) {
        uint REVVETHAmt = REVVETH.balanceOf(address(this));
        if (REVVETHAmt == 0) return 0;
        uint REVVPrice = (uniV2Router.getAmountsOut(1e18, getPath(address(REVV), address(WETH))))[1];
        (uint112 reserveREVV, uint112 reserveWETH,) = REVVETH.getReserves();
        uint totalReserve = reserveREVV * REVVPrice / 1e18 + reserveWETH;
        uint pricePerFullShare = totalReserve * 1e18 / REVVETH.totalSupply();
        return REVVETHAmt * pricePerFullShare / 1e18;
    }

    function getMVIPool() private view returns (uint) {
        uint MVIAmt = MVI.balanceOf(address(this));
        if (MVIAmt == 0) return 0;
        uint MVIPrice = (uniV2Router.getAmountsOut(1e18, getPath(address(MVI), address(WETH))))[1];
        return MVIAmt * MVIPrice / 1e18;
    }

    function getEachPool(bool includeVestedILV) private view returns (uint[] memory pools) {
        pools = new uint[](6);
        pools[0] = getAXSETHPool();
        pools[1] = getSLPETHPool();
        pools[2] = getILVETHPool(includeVestedILV);
        pools[3] = getGHSTETHPool();
        pools[4] = getREVVETHPool();
        pools[5] = getMVIPool();
    }

    /// @notice This function return only farms TVL in ETH
    function getAllPool(bool includeVestedILV) public view returns (uint) {
        uint[] memory pools = getEachPool(includeVestedILV);
        return pools[0] + pools[1] + pools[2] + pools[3] + pools[4] + pools[5]; 
    }

    function getAllPoolInUSD(bool includeVestedILV) public view returns (uint) {
        uint ETHPriceInUSD = uint(IChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419).latestAnswer()); // 8 decimals
        return getAllPool(includeVestedILV) * ETHPriceInUSD / 1e8;
    }

    function getCurrentCompositionPerc() external view returns (uint[] memory percentages) {
        uint[] memory pools = getEachPool(false);
        uint allPool = pools[0] + pools[1] + pools[2] + pools[3] + pools[4] + pools[5];
        percentages = new uint[](6);
        percentages[0] = pools[0] * 10000 / allPool;
        percentages[1] = pools[1] * 10000 / allPool;
        percentages[2] = pools[2] * 10000 / allPool;
        percentages[3] = pools[3] * 10000 / allPool;
        percentages[4] = pools[4] * 10000 / allPool;
        percentages[5] = pools[5] * 10000 / allPool;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

