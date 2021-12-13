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
    IERC20Upgradeable constant SLP = IERC20Upgradeable(0xCC8Fa225D80b9c7D42F96e9570156c65D6cAAa25); // Depreciated
    IERC20Upgradeable constant ILV = IERC20Upgradeable(0x767FE9EDC9E0dF98E07454847909b5E959D7ca0E);
    IERC20Upgradeable constant GHST = IERC20Upgradeable(0x3F382DbD960E3a9bbCeaE22651E88158d2791550); // Depreciated
    IERC20Upgradeable constant MANA = IERC20Upgradeable(0x0F5D2fB29fb7d3CFeE444a200298f468908cC942); // Replaced SLP, GHST
    IERC20Upgradeable constant REVV = IERC20Upgradeable(0x557B933a7C2c45672B610F8954A3deB39a51A8Ca); // Depreciated
    IERC20Upgradeable constant WILD = IERC20Upgradeable(0x2a3bFF78B79A009976EeA096a51A948a3dC00e34); // Replaced REVV
    IERC20Upgradeable constant MVI = IERC20Upgradeable(0x72e364F2ABdC788b7E918bc238B21f109Cd634D7);

    IERC20Upgradeable constant AXSETH = IERC20Upgradeable(0x0C365789DbBb94A29F8720dc465554c587e897dB);
    IERC20Upgradeable constant SLPETH = IERC20Upgradeable(0x8597fa0773888107E2867D36dd87Fe5bAFeAb328); // Depreciated
    IERC20Upgradeable constant ILVETH = IERC20Upgradeable(0x6a091a3406E0073C3CD6340122143009aDac0EDa);
    IERC20Upgradeable constant GHSTETH = IERC20Upgradeable(0xFbA31F01058DB09573a383F26a088f23774d4E5d); // Depreciated
    IERC20Upgradeable constant MANAETH = IERC20Upgradeable(0x1bEC4db6c3Bc499F3DbF289F5499C30d541FEc97);
    IPair constant REVVETH = IPair(0x724d5c9c618A2152e99a45649a3B8cf198321f46); // Depreciated

    IRouter constant uniV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniV3Router constant uniV3Router = IUniV3Router(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IRouter constant sushiRouter = IRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    IDaoL1Vault public AXSETHVault;
    IDaoL1Vault public SLPETHVault; // Depreciated
    IDaoL1Vault public ILVETHVault;
    IDaoL1VaultUniV3 public GHSTETHVault; // Depreciated

    address public vault;
    uint public watermark; // In USD (18 decimals)
    uint public profitFeePerc;

    // New variable after upgraded
    IDaoL1Vault public MANAETHVault;

    event TargetComposition (uint AXSETHTargetPool, uint ILVETHTargetPool, uint MANAETHTargetPool, uint WILDTargetPool, uint MVITargetPool);
    event CurrentComposition (uint AXSETHCurrentPool, uint ILVETHCurrentPool, uint MANAETHCurrentPool, uint WILDCurrentPool, uint MVICurrentPool);
    event InvestAXSETH(uint WETHAmt, uint AXSETHAmt);
    event InvestILVETH(uint WETHAmt, uint ILVETHAmt);
    event InvestMANAETH(uint WETHAmt, uint MANAAmt);
    event InvestWILD(uint WETHAmt, uint WILDAmt);
    event InvestMVI(uint WETHAmt, uint MVIAmt);
    event Withdraw(uint amount, uint WETHAmt);
    event WithdrawAXSETH(uint lpTokenAmt, uint WETHAmt);
    event WithdrawILVETH(uint lpTokenAmt, uint WETHAmt);
    event WithdrawMANAETH(uint lpTokenAmt, uint WETHAmt);
    event WithdrawWILD(uint lpTokenAmt, uint WETHAmt);
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
        WILD.safeApprove(address(uniV2Router), type(uint).max);
        MVI.safeApprove(address(uniV2Router), type(uint).max);

        AXSETH.safeApprove(address(sushiRouter), type(uint).max);
        AXSETH.safeApprove(address(AXSETHVault), type(uint).max);
        SLPETH.safeApprove(address(sushiRouter), type(uint).max);
        SLPETH.safeApprove(address(SLPETHVault), type(uint).max);
        ILVETH.safeApprove(address(sushiRouter), type(uint).max);
        ILVETH.safeApprove(address(ILVETHVault), type(uint).max);
        GHST.safeApprove(address(GHSTETHVault), type(uint).max);
        WETH.safeApprove(address(GHSTETHVault), type(uint).max);
        WILD.safeApprove(address(uniV2Router), type(uint).max);
    }

    function invest(uint WETHAmt, uint[] calldata amountsOutMin) external onlyVault {
        _invest(WETHAmt, amountsOutMin);
    }

    function _invest(uint WETHAmt, uint[] calldata amountsOutMin) private {
        WETH.safeTransferFrom(vault, address(this), WETHAmt);

        uint[] memory pools = getEachPool(false);
        uint pool = pools[0] + pools[1] + pools[2] + pools[3] + pools[4] + WETHAmt;
        uint AXSETHTargetPool = pool * 2500 / 10000; // 25%
        uint ILVETHTargetPool = AXSETHTargetPool; // 25%
        uint MANAETHTargetPool = pool * 1500 / 10000; // 15%
        uint WILDTargetPool = pool * 500 / 10000; // 5%
        uint MVITargetPool = pool * 3000 / 10000; // 30%

        // Rebalancing invest
        if (
            AXSETHTargetPool > pools[0] &&
            ILVETHTargetPool > pools[1] &&
            MANAETHTargetPool > pools[2] &&
            WILDTargetPool > pools[3] &&
            MVITargetPool > pools[4]
        ) {
            investAXSETH(AXSETHTargetPool - pools[0], amountsOutMin[3]);
            investILVETH(ILVETHTargetPool - pools[1], amountsOutMin[4]);
            investMANAETH(MANAETHTargetPool - pools[2], amountsOutMin[5]);
            investWILD(WILDTargetPool - pools[3], amountsOutMin[6]);
            investMVI(MVITargetPool - pools[4], amountsOutMin[7]);
        } else {
            uint furthest;
            uint farmIndex;
            uint diff;

            if (AXSETHTargetPool > pools[0]) {
                diff = AXSETHTargetPool - pools[0];
                furthest = diff;
                farmIndex = 0;
            }
            if (ILVETHTargetPool > pools[1]) {
                diff = ILVETHTargetPool - pools[1];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 1;
                }
            }
            if (MANAETHTargetPool > pools[2]) {
                diff = MANAETHTargetPool - pools[2];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 2;
                }
            }
            if (WILDTargetPool > pools[3]) {
                diff = WILDTargetPool - pools[3];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 3;
                }
            }
            if (MVITargetPool > pools[4]) {
                diff = MVITargetPool - pools[4];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 4;
                }
            }

            if (farmIndex == 0) investAXSETH(WETHAmt, amountsOutMin[3]);
            else if (farmIndex == 1) investILVETH(WETHAmt, amountsOutMin[4]);
            else if (farmIndex == 2) investMANAETH(WETHAmt, amountsOutMin[5]);
            else if (farmIndex == 3) investWILD(WETHAmt, amountsOutMin[6]);
            else investMVI(WETHAmt, amountsOutMin[7]);
        }

        emit TargetComposition(AXSETHTargetPool, ILVETHTargetPool, MANAETHTargetPool, WILDTargetPool, MVITargetPool);
        emit CurrentComposition(pools[0], pools[1], pools[2], pools[3], pools[4]);
    }

    function investAXSETH(uint WETHAmt, uint amountOutMin) private {
        uint halfWETH = WETHAmt / 2;
        uint AXSAmt = uniV3Swap(address(WETH), address(AXS), 3000, halfWETH, amountOutMin);
        (,,uint AXSETHAmt) = sushiRouter.addLiquidity(address(AXS), address(WETH), AXSAmt, halfWETH, 0, 0, address(this), block.timestamp);
        AXSETHVault.deposit(AXSETHAmt);
        emit InvestAXSETH(WETHAmt, AXSETHAmt);
    }

    function investILVETH(uint WETHAmt, uint amountOutMin) private {
        uint halfWETH = WETHAmt / 2;
        uint ILVAmt = sushiSwap(address(WETH), address(ILV), halfWETH, amountOutMin);
        (,,uint ILVETHAmt) = sushiRouter.addLiquidity(address(ILV), address(WETH), ILVAmt, halfWETH, 0, 0, address(this), block.timestamp);
        ILVETHVault.deposit(ILVETHAmt);
        emit InvestILVETH(WETHAmt, ILVETHAmt);
    }

    function investMANAETH(uint WETHAmt, uint amountOutMin) private {
        uint halfWETH = WETHAmt / 2;
        uint MANAAmt = sushiSwap(address(WETH), address(MANA), halfWETH, amountOutMin);
        (,,uint MANAETHAmt) = sushiRouter.addLiquidity(address(MANA), address(WETH), MANAAmt, halfWETH, 0, 0, address(this), block.timestamp);
        MANAETHVault.deposit(MANAETHAmt);
        emit InvestMANAETH(WETHAmt, MANAETHAmt);
    }

    function investWILD(uint WETHAmt, uint amountOutMin) private {
        uint WILDAmt = uniV2Swap(address(WETH), address(WILD), WETHAmt, amountOutMin);
        emit InvestWILD(WETHAmt, WILDAmt);
    }

    function investMVI(uint WETHAmt, uint amountOutMin) private {
        uint MVIAmt = uniV2Swap(address(WETH), address(MVI), WETHAmt, amountOutMin);
        emit InvestMVI(WETHAmt, MVIAmt);
    }

    /// @param amount Amount to withdraw in USD
    function withdraw(uint amount, uint[] calldata amountsOutMin) external onlyVault returns (uint WETHAmt) {
        uint sharePerc = amount * 1e18 / getAllPoolInUSD(false);

        uint WETHAmtBefore = WETH.balanceOf(address(this));
        withdrawAXSETH(sharePerc, amountsOutMin[1]);
        withdrawILVETH(sharePerc, amountsOutMin[2]);
        withdrawMANAETH(sharePerc, amountsOutMin[3]);
        withdrawWILD(sharePerc, amountsOutMin[4]);
        withdrawMVI(sharePerc, amountsOutMin[5]);
        WETHAmt = WETH.balanceOf(address(this)) - WETHAmtBefore;

        WETH.safeTransfer(vault, WETHAmt);

        emit Withdraw(amount, WETHAmt);
    }

    function withdrawAXSETH(uint sharePerc, uint amountOutMin) private {
        uint AXSETHAmt = AXSETHVault.withdraw(AXSETHVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint AXSAmt, uint WETHAmt) = sushiRouter.removeLiquidity(address(AXS), address(WETH), AXSETHAmt, 0, 0, address(this), block.timestamp);
        uint _WETHAmt = uniV3Swap(address(AXS), address(WETH), 3000, AXSAmt, amountOutMin);
        emit WithdrawAXSETH(AXSETHAmt, WETHAmt + _WETHAmt);
    }

    function withdrawILVETH(uint sharePerc, uint amountOutMin) private {
        uint ILVETHAmt = ILVETHVault.withdraw(ILVETHVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint ILVAmt, uint WETHAmt) = sushiRouter.removeLiquidity(address(ILV), address(WETH), ILVETHAmt, 0, 0, address(this), block.timestamp);
        uint _WETHAmt = sushiSwap(address(ILV), address(WETH), ILVAmt, amountOutMin);
        emit WithdrawILVETH(ILVETHAmt, WETHAmt + _WETHAmt);
    }

    function withdrawMANAETH(uint sharePerc, uint amountOutMin) private {
        uint MANAETHAmt = MANAETHVault.withdraw(MANAETHVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint MANAAmt, uint WETHAmt) = sushiRouter.removeLiquidity(address(MANA), address(WETH), MANAETHAmt, 0, 0, address(this), block.timestamp);
        uint _WETHAmt = sushiSwap(address(MANA), address(WETH), MANAAmt, amountOutMin);
        emit WithdrawMANAETH(MANAETHAmt, WETHAmt + _WETHAmt);
    }

    function withdrawWILD(uint sharePerc, uint amountOutMin) private {
        uint WILDAmt = WILD.balanceOf(address(this)) * sharePerc / 1e18;
        uint WETHAmt = uniV2Swap(address(WILD), address(WETH), WILDAmt, amountOutMin);
        emit WithdrawWILD(WILDAmt, WETHAmt);
    }

    function withdrawMVI(uint sharePerc, uint amountOutMin) private {
        uint MVIAmt = MVI.balanceOf(address(this)) * sharePerc / 1e18;
        uint WETHAmt = uniV2Swap(address(MVI), address(WETH), MVIAmt, amountOutMin);
        emit WithdrawMVI(MVIAmt, WETHAmt);
    }

    function collectProfitAndUpdateWatermark() external onlyVault returns (uint fee) {
        uint currentWatermark = getAllPoolInUSD(false);
        uint lastWatermark = watermark;
        if (currentWatermark > lastWatermark) {
            uint profit = currentWatermark - lastWatermark;
            fee = profit * profitFeePerc / 10000;
            watermark = currentWatermark;
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
    function reimburse(uint farmIndex, uint amount, uint amountOutMin) external onlyVault returns (uint WETHAmt) {
        if (farmIndex == 0) withdrawAXSETH(amount * 1e18 / getAXSETHPool(), amountOutMin);
        else if (farmIndex == 1) withdrawILVETH(amount * 1e18 / getILVETHPool(false), amountOutMin);
        else if (farmIndex == 2) withdrawMANAETH(amount * 1e18 / getMANAETHPool(), amountOutMin);
        else if (farmIndex == 3) withdrawWILD(amount * 1e18 / getWILDPool(), amountOutMin);
        else if (farmIndex == 4) withdrawMVI(amount * 1e18 / getMVIPool(), amountOutMin);

        WETHAmt = WETH.balanceOf(address(this));
        WETH.safeTransfer(vault, WETHAmt);

        emit Reimburse(WETHAmt);
    }

    function emergencyWithdraw() external onlyVault {
        // 1e18 == 100% of share
        withdrawAXSETH(1e18, 0);
        withdrawILVETH(1e18, 0);
        withdrawMANAETH(1e18, 0);
        withdrawWILD(1e18, 0);
        withdrawMVI(1e18, 0);

        uint WETHAmt = WETH.balanceOf(address(this));
        WETH.safeTransfer(vault, WETHAmt);
        watermark = 0;

        emit EmergencyWithdraw(WETHAmt);
    }

    function sushiSwap(address from, address to, uint amount, uint amountOutMin) private returns (uint) {
        return sushiRouter.swapExactTokensForTokens(amount, amountOutMin, getPath(from, to), address(this), block.timestamp)[1];
    }

    function uniV2Swap(address from, address to, uint amount, uint amountOutMin) private returns (uint) {
        return uniV2Router.swapExactTokensForTokens(amount, amountOutMin, getPath(from, to), address(this), block.timestamp)[1];
    }

    function uniV3Swap(address tokenIn, address tokenOut, uint24 fee, uint amountIn, uint amountOutMin) private returns (uint amountOut) {
        IUniV3Router.ExactInputSingleParams memory params =
            IUniV3Router.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });
        amountOut = uniV3Router.exactInputSingle(params);
    }

    // This function only able to call once
    function swapTokensAndInvest(IDaoL1Vault _MANAETHVault, uint[] calldata amountsOutMin) external {
        // Setup L1 vault for MANA-ETH
        MANAETHVault = _MANAETHVault;

        // Approval for new tokens
        MANA.safeApprove(address(sushiRouter), type(uint).max);
        MANAETH.safeApprove(address(_MANAETHVault), type(uint).max);
        MANAETH.safeApprove(address(sushiRouter), type(uint).max);
        WILD.safeApprove(address(uniV2Router), type(uint).max);
        AXS.safeApprove(address(uniV3Router), type(uint).max); // Change router from Sushi to Uniswap V3

        // Swap out all REVV
        uint REVVETHAmt = REVVETH.balanceOf(address(this));
        (uint REVVAmt,) = uniV2Router.removeLiquidity(address(REVV), address(WETH), REVVETHAmt, 0, 0, address(this), block.timestamp);
        uniV2Swap(address(REVV), address(WETH), REVVAmt, amountsOutMin[0]);

        // Remove liquidity from SLP-ETH pool and swap out all SLP
        uint SLPETHAmt = SLPETHVault.withdraw(SLPETHVault.balanceOf(address(this)));
        sushiRouter.removeLiquidity(address(SLP), address(WETH), SLPETHAmt, 0, 0, address(this), block.timestamp);
        uint SLPAmt = SLP.balanceOf(address(this));
        SLP.safeApprove(address(uniV3Router), SLPAmt);
        uniV3Swap(address(SLP), address(WETH), 3000, SLPAmt, amountsOutMin[1]);

        // Remove liquidity from GHST-ETH pool and swap out all GHST
        (uint GHSTAmt,) = GHSTETHVault.withdraw(GHSTETHVault.balanceOf(address(this)));
        uniV3Swap(address(GHST), address(WETH), 10000, GHSTAmt, amountsOutMin[2]);

        // Transfer WETH to vault to call invest, because invest function need WETH from vault
        uint WETHAmt = WETH.balanceOf(address(this));
        WETH.safeTransfer(address(vault), WETHAmt);

        _invest(WETHAmt, amountsOutMin);
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
        uint AXSETHVaultPool = AXSETHVault.getAllPoolInETH();
        if (AXSETHVaultPool == 0) return 0;
        return AXSETHVaultPool * AXSETHVault.balanceOf(address(this)) / AXSETHVault.totalSupply();
    }

    function getILVETHPool(bool includeVestedILV) private view returns (uint) {
        uint _totalSupply = ILVETHVault.totalSupply();
        if (_totalSupply == 0) return 0;
        uint ILVETHVaultPool =  includeVestedILV ? 
            ILVETHVault.getAllPoolInETH(): 
            ILVETHVault.getAllPoolInETHExcludeVestedILV();
        return ILVETHVaultPool * ILVETHVault.balanceOf(address(this)) / _totalSupply;
    }

    function getMANAETHPool() private view returns (uint) {
        uint MANAETHVaultPool = MANAETHVault.getAllPoolInETH();
        if (MANAETHVaultPool == 0) return 0;
        return MANAETHVaultPool * MANAETHVault.balanceOf(address(this)) / MANAETHVault.totalSupply();
    }

    function getWILDPool() private view returns (uint) {
        uint WILDAmt = WILD.balanceOf(address(this));
        if (WILDAmt == 0) return 0;
        uint WILDPrice = uniV2Router.getAmountsOut(1e18, getPath(address(WILD), address(WETH)))[1];
        return WILDAmt * WILDPrice / 1e18;
    }

    function getMVIPool() private view returns (uint) {
        uint MVIAmt = MVI.balanceOf(address(this));
        if (MVIAmt == 0) return 0;
        uint MVIPrice = uniV2Router.getAmountsOut(1e18, getPath(address(MVI), address(WETH)))[1];
        return MVIAmt * MVIPrice / 1e18;
    }

    function getEachPool(bool includeVestedILV) private view returns (uint[] memory pools) {
        pools = new uint[](6);
        pools[0] = getAXSETHPool();
        pools[1] = getILVETHPool(includeVestedILV);
        pools[2] = getMANAETHPool();
        pools[3] = getWILDPool();
        pools[4] = getMVIPool();
    }

    /// @notice This function return only farms TVL in ETH
    function getAllPoolInETH(bool includeVestedILV) public view returns (uint) {
        uint[] memory pools = getEachPool(includeVestedILV);
        return pools[0] + pools[1] + pools[2] + pools[3] + pools[4];
    }

    function getAllPoolInUSD(bool includeVestedILV) public view returns (uint) {
        uint ETHPriceInUSD = uint(IChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419).latestAnswer()); // 8 decimals
        require(ETHPriceInUSD > 0, "ChainLink error");
        return getAllPoolInETH(includeVestedILV) * ETHPriceInUSD / 1e8;
    }

    function getCurrentCompositionPerc() external view returns (uint[] memory percentages) {
        uint[] memory pools = getEachPool(false);
        uint allPool = pools[0] + pools[1] + pools[2] + pools[3] + pools[4];
        percentages = new uint[](5);
        percentages[0] = pools[0] * 10000 / allPool;
        percentages[1] = pools[1] * 10000 / allPool;
        percentages[2] = pools[2] * 10000 / allPool;
        percentages[3] = pools[3] * 10000 / allPool;
        percentages[4] = pools[4] * 10000 / allPool;
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