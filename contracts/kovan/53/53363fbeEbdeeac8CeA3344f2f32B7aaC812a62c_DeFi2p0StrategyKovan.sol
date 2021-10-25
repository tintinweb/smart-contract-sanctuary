// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
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

    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

contract DeFi2p0StrategyKovan is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable constant WETH = IERC20Upgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20Upgradeable constant RGT = IERC20Upgradeable(0xD291E7a03283640FDc51b121aC401383A46cC623);
    IERC20Upgradeable constant SPELL = IERC20Upgradeable(0x090185f2135308BaD17527004364eBcC2D37e5F6);
    IERC20Upgradeable constant OHM = IERC20Upgradeable(0x383518188C0C6d7730D91b2c03a03C837814a899); // 9 decimals
    IERC20Upgradeable constant ALCX = IERC20Upgradeable(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
    IERC20Upgradeable constant ICE = IERC20Upgradeable(0xf16e81dce15B08F326220742020379B855B87DF9);
    IERC20Upgradeable constant INV = IERC20Upgradeable(0x41D5D79431A913C4aE7d69a668ecdfE5fF9DFB68);
    IERC20Upgradeable constant TOKE = IERC20Upgradeable(0x2e9d63788249371f1DFC918a52f8d799F4a38C94);

    IRouter constant router = IRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    address public vault;
    uint public watermark; // In USD (18 decimals)
    uint public profitFeePerc;

    event TargetComposition (uint targetPool);
    event CurrentComposition (
        uint RGTCurrentPool, uint SPELLCurrentPool,
        uint OHMCurrentPool, uint ALCXCurrentPool,
        uint ICECurrentPool, uint INVCurrentPool, uint TOKECurrentPool
    );
    event InvestRGT(uint WETHAmt, uint RGTAmt);
    event InvestSPELL(uint WETHAmt, uint SPELLAmt);
    event InvestOHM(uint WETHAmt, uint OHMAmt);
    event InvestALCX(uint WETHAmt, uint OHMAmt);
    event InvestICE(uint WETHAmt, uint OHMAmt);
    event InvestINV(uint WETHAmt, uint OHMAmt);
    event InvestTOKE(uint WETHAmt, uint OHMAmt);
    event Withdraw(uint amount, uint WETHAmt);
    event WithdrawRGT(uint lpTokenAmt, uint WETHAmt);
    event WithdrawSPELL(uint lpTokenAmt, uint WETHAmt);
    event WithdrawOHM(uint lpTokenAmt, uint WETHAmt);
    event WithdrawALCX(uint lpTokenAmt, uint WETHAmt);
    event WithdrawICE(uint lpTokenAmt, uint WETHAmt);
    event WithdrawINV(uint lpTokenAmt, uint WETHAmt);
    event WithdrawTOKE(uint lpTokenAmt, uint WETHAmt);
    event CollectProfitAndUpdateWatermark(uint currentWatermark, uint lastWatermark, uint fee);
    event AdjustWatermark(uint currentWatermark, uint lastWatermark);
    event Reimburse(uint WETHAmt);
    event EmergencyWithdraw(uint WETHAmt);

    modifier onlyVault {
        require(msg.sender == vault, "Only vault");
        _;
    }

    function initialize() external initializer {
        profitFeePerc = 2000;

        // WETH.safeApprove(address(router), type(uint).max);
        // RGT.safeApprove(address(router), type(uint).max);
        // SPELL.safeApprove(address(router), type(uint).max);
        // OHM.safeApprove(address(router), type(uint).max);
        // ALCX.safeApprove(address(router), type(uint).max);
        // ICE.safeApprove(address(router), type(uint).max);
        // INV.safeApprove(address(router), type(uint).max);
        // TOKE.safeApprove(address(router), type(uint).max);
    }

    function invest(uint WETHAmt, uint[] calldata amountOutMinList) external onlyVault {
        WETH.safeTransferFrom(vault, address(this), WETHAmt);

        uint[] memory pools = getEachPoolInETH();
        uint pool = pools[0] + pools[1] + pools[2] + pools[3] + pools[4] + pools[5] + pools[6] + WETHAmt;
        uint targetPool = pool / 7;

        // Rebalancing invest
        if (
            targetPool > pools[0] &&
            targetPool > pools[1] &&
            targetPool > pools[2] &&
            targetPool > pools[3] &&
            targetPool > pools[4] &&
            targetPool > pools[5] &&
            targetPool > pools[6]
        ) {
            investRGT(targetPool - pools[0], amountOutMinList[3]);
            investSPELL(targetPool - pools[1], amountOutMinList[4]);
            investOHM(targetPool - pools[2], amountOutMinList[5]);
            investALCX(targetPool - pools[3], amountOutMinList[6]);
            investICE(targetPool - pools[4], amountOutMinList[7]);
            investINV(targetPool - pools[5], amountOutMinList[8]);
            investTOKE(targetPool - pools[6], amountOutMinList[9]);
        } else {
            uint furthest;
            uint farmIndex;
            uint diff;

            if (targetPool > pools[0]) {
                diff = targetPool - pools[0];
                furthest = diff;
                farmIndex = 0;
            }
            if (targetPool > pools[1]) {
                diff = targetPool - pools[1];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 1;
                }
            }
            if (targetPool > pools[2]) {
                diff = targetPool - pools[2];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 2;
                }
            }
            if (targetPool > pools[3]) {
                diff = targetPool - pools[3];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 3;
                }
            }
            if (targetPool > pools[4]) {
                diff = targetPool - pools[4];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 4;
                }
            }
            if (targetPool > pools[5]) {
                diff = targetPool - pools[5];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 5;
                }
            }
            if (targetPool > pools[6]) {
                diff = targetPool - pools[6];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 6;
                }
            }

            if (farmIndex == 0) investRGT(WETHAmt, amountOutMinList[3]);
            else if (farmIndex == 1) investSPELL(WETHAmt, amountOutMinList[4]);
            else if (farmIndex == 2) investOHM(WETHAmt, amountOutMinList[5]);
            else if (farmIndex == 3) investALCX(WETHAmt, amountOutMinList[6]);
            else if (farmIndex == 4) investICE(WETHAmt, amountOutMinList[7]);
            else if (farmIndex == 5) investINV(WETHAmt, amountOutMinList[8]);
            else investTOKE(WETHAmt, amountOutMinList[9]);
        }

        emit TargetComposition(targetPool);
        emit CurrentComposition(pools[0], pools[1], pools[2], pools[3], pools[4], pools[5], pools[6]);
    }

    function investRGT(uint WETHAmt, uint amountOutMin) private {
        uint RGTAmt = swap(address(WETH), address(RGT), WETHAmt, amountOutMin);
        emit InvestRGT(WETHAmt, RGTAmt);
    }

    function investSPELL(uint WETHAmt, uint amountOutMin) private {
        uint SPELLAmt = swap(address(WETH), address(SPELL), WETHAmt, amountOutMin);
        emit InvestSPELL(WETHAmt, SPELLAmt);
    }

    function investOHM(uint WETHAmt, uint amountOutMin) private {
        address[] memory path = new address[](3);
        path[0] = address(WETH);
        path[1] = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI
        path[2] = address(OHM);
        uint OHMAmt = router.swapExactTokensForTokens(WETHAmt, amountOutMin, path, address(this), block.timestamp)[2];
        emit InvestOHM(WETHAmt, OHMAmt);
    }

    function investALCX(uint WETHAmt, uint amountOutMin) private {
        uint ALCXAmt = swap(address(WETH), address(ALCX), WETHAmt, amountOutMin);
        emit InvestALCX(WETHAmt, ALCXAmt);
    }

    function investICE(uint WETHAmt, uint amountOutMin) private {
        uint ICEAmt = swap(address(WETH), address(ICE), WETHAmt, amountOutMin);
        emit InvestICE(WETHAmt, ICEAmt);
    }

    function investINV(uint WETHAmt, uint amountOutMin) private {
        uint INVAmt = swap(address(WETH), address(INV), WETHAmt, amountOutMin);
        emit InvestINV(WETHAmt, INVAmt);
    }

    function investTOKE(uint WETHAmt, uint amountOutMin) private {
        uint TOKEAmt = swap(address(WETH), address(TOKE), WETHAmt, amountOutMin);
        emit InvestTOKE(WETHAmt, TOKEAmt);
    }

    /// @param amount Amount to withdraw in USD
    function withdraw(uint amount, uint[] calldata amountOutMinList) external onlyVault returns (uint WETHAmt) {
        uint sharePerc = amount * 1e18 / getAllPoolInUSD();

        withdrawRGT(sharePerc, amountOutMinList[1]);
        withdrawSPELL(sharePerc, amountOutMinList[2]);
        withdrawOHM(sharePerc, amountOutMinList[3]);
        withdrawALCX(sharePerc, amountOutMinList[4]);
        withdrawICE(sharePerc, amountOutMinList[5]);
        withdrawINV(sharePerc, amountOutMinList[6]);
        withdrawTOKE(sharePerc, amountOutMinList[7]);

        WETHAmt = WETH.balanceOf(address(this));
        WETH.safeTransfer(vault, WETHAmt);
        emit Withdraw(amount, WETHAmt);
    }

    function withdrawRGT(uint sharePerc, uint amountOutMin) private {
        uint RGTAmt = RGT.balanceOf(address(this)) * sharePerc / 1e18;
        uint WETHAmt = swap(address(RGT), address(WETH), RGTAmt, amountOutMin);
        emit WithdrawRGT(RGTAmt, WETHAmt);
    }

    function withdrawSPELL(uint sharePerc, uint amountOutMin) private {
        uint SPELLAmt = SPELL.balanceOf(address(this)) * sharePerc / 1e18;
        uint WETHAmt = swap(address(SPELL), address(WETH), SPELLAmt, amountOutMin);
        emit WithdrawSPELL(SPELLAmt, WETHAmt);
    }

    function withdrawOHM(uint sharePerc, uint amountOutMin) private {
        uint OHMAmt = OHM.balanceOf(address(this)) * sharePerc / 1e18;
        address[] memory path = new address[](3);
        path[0] = address(OHM);
        path[1] = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI
        path[2] = address(WETH);
        uint WETHAmt = router.swapExactTokensForTokens(OHMAmt, amountOutMin, path, address(this), block.timestamp)[2];
        emit WithdrawOHM(OHMAmt, WETHAmt);
    }

    function withdrawALCX(uint sharePerc, uint amountOutMin) private {
        uint ALCXAmt = ALCX.balanceOf(address(this)) * sharePerc / 1e18;
        uint WETHAmt = swap(address(ALCX), address(WETH), ALCXAmt, amountOutMin);
        emit WithdrawALCX(ALCXAmt, WETHAmt);
    }

    function withdrawICE(uint sharePerc, uint amountOutMin) private {
        uint ICEAmt = ICE.balanceOf(address(this)) * sharePerc / 1e18;
        uint WETHAmt = swap(address(ICE), address(WETH), ICEAmt, amountOutMin);
        emit WithdrawICE(ICEAmt, WETHAmt);
    }

    function withdrawINV(uint sharePerc, uint amountOutMin) private {
        uint INVAmt = INV.balanceOf(address(this)) * sharePerc / 1e18;
        uint WETHAmt = swap(address(INV), address(WETH), INVAmt, amountOutMin);
        emit WithdrawINV(INVAmt, WETHAmt);
    }

    function withdrawTOKE(uint sharePerc, uint amountOutMin) private {
        uint TOKEAmt = TOKE.balanceOf(address(this)) * sharePerc / 1e18;
        uint WETHAmt = swap(address(TOKE), address(WETH), TOKEAmt, amountOutMin);
        emit WithdrawTOKE(TOKEAmt, WETHAmt);
    }

    function collectProfitAndUpdateWatermark() public onlyVault returns (uint fee) {
        uint currentWatermark = getAllPoolInUSD();
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
    function reimburse(uint farmIndex, uint amount, uint tokenPriceMin) external onlyVault returns (uint WETHAmt) {
        if (farmIndex == 0) withdrawRGT(amount * 1e18 / getRGTPoolInETH(), tokenPriceMin);
        else if (farmIndex == 1) withdrawSPELL(amount * 1e18 / getSPELLPoolInETH(), tokenPriceMin);
        else if (farmIndex == 2) withdrawOHM(amount * 1e18 / getOHMPoolInETH(), tokenPriceMin);
        else if (farmIndex == 3) withdrawALCX(amount * 1e18 / getALCXPoolInETH(), tokenPriceMin);
        else if (farmIndex == 4) withdrawICE(amount * 1e18 / getICEPoolInETH(), tokenPriceMin);
        else if (farmIndex == 5) withdrawINV(amount * 1e18 / getINVPoolInETH(), tokenPriceMin);
        else if (farmIndex == 6) withdrawTOKE(amount * 1e18 / getTOKEPoolInETH(), tokenPriceMin);

        WETHAmt = WETH.balanceOf(address(this));
        WETH.safeTransfer(vault, WETHAmt);
        emit Reimburse(WETHAmt);
    }

    function emergencyWithdraw() external onlyVault {
        // 1e18 == 100% of share
        withdrawRGT(1e18, 0);
        withdrawSPELL(1e18, 0);
        withdrawOHM(1e18, 0);
        withdrawALCX(1e18, 0);
        withdrawICE(1e18, 0);
        withdrawINV(1e18, 0);
        withdrawTOKE(1e18, 0);

        uint WETHAmt = WETH.balanceOf(address(this));
        WETH.safeTransfer(vault, WETHAmt);
        watermark = 0;
        emit EmergencyWithdraw(WETHAmt);
    }

    function setVault(address _vault) external {
        require(vault == address(0), "Vault set");
        vault = _vault;
    }

    function setProfitFeePerc(uint _profitFeePerc) external onlyVault {
        profitFeePerc = _profitFeePerc;
    }

    function swap(address from, address to, uint amount, uint amountOutMin) private returns (uint) {
        return router.swapExactTokensForTokens(
            amount, amountOutMin, getPath(from, to), address(this), block.timestamp
        )[1];
    }

    function getPath(address tokenA, address tokenB) private pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
    }

    function getRGTPoolInETH() private view returns (uint) {
        uint RGTAmt = RGT.balanceOf(address(this));
        if (RGTAmt == 0) return 0;
        uint RGTPriceInETH = router.getAmountsOut(1e18, getPath(address(RGT), address(WETH)))[1];
        return RGTAmt * RGTPriceInETH / 1e18;
    }

    function getSPELLPoolInETH() private view returns (uint) {
        uint SPELLAmt = SPELL.balanceOf(address(this));
        if (SPELLAmt == 0) return 0;
        uint SPELLPriceInETH = router.getAmountsOut(1e18, getPath(address(SPELL), address(WETH)))[1];
        return SPELLAmt * SPELLPriceInETH / 1e18;
    }

    function getOHMPoolInETH() private view returns (uint) {
        uint OHMAmt = OHM.balanceOf(address(this));
        if (OHMAmt == 0) return 0;
        address[] memory path = new address[](3);
        path[0] = address(OHM);
        path[1] = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI
        path[2] = address(WETH);
        uint OHMPriceInETH = router.getAmountsOut(1e9, path)[2];
        return OHMAmt * OHMPriceInETH / 1e9;
    }

    function getALCXPoolInETH() private view returns (uint) {
        uint ALCXAmt = ALCX.balanceOf(address(this));
        if (ALCXAmt == 0) return 0;
        uint ALCXPriceInETH = router.getAmountsOut(1e18, getPath(address(ALCX), address(WETH)))[1];
        return ALCXAmt * ALCXPriceInETH / 1e18;
    }

    function getICEPoolInETH() private view returns (uint) {
        uint ICEAmt = ICE.balanceOf(address(this));
        if (ICEAmt == 0) return 0;
        uint ICEPriceInETH = router.getAmountsOut(1e18, getPath(address(ICE), address(WETH)))[1];
        return ICEAmt * ICEPriceInETH / 1e18;
    }

    function getINVPoolInETH() private view returns (uint) {
        uint INVAmt = INV.balanceOf(address(this));
        if (INVAmt == 0) return 0;
        uint INVPriceInETH = router.getAmountsOut(1e18, getPath(address(INV), address(WETH)))[1];
        return INVAmt * INVPriceInETH / 1e18;
    }

    function getTOKEPoolInETH() private view returns (uint) {
        uint TOKEAmt = TOKE.balanceOf(address(this));
        if (TOKEAmt == 0) return 0;
        uint TOKEPriceInETH = router.getAmountsOut(1e18, getPath(address(TOKE), address(WETH)))[1];
        return TOKEAmt * TOKEPriceInETH / 1e18;
    }

    function getEachPoolInETH() private view returns (uint[] memory pools) {
        pools = new uint[](7);
        pools[0] = getRGTPoolInETH();
        pools[1] = getSPELLPoolInETH();
        pools[2] = getOHMPoolInETH();
        pools[3] = getALCXPoolInETH();
        pools[4] = getICEPoolInETH();
        pools[5] = getINVPoolInETH();
        pools[6] = getTOKEPoolInETH();
    }

    /// @notice This function return only farms TVL in ETH
    function getAllPoolInETH() public view returns (uint) {
        uint[] memory pools = getEachPoolInETH();
        return pools[0] + pools[1] + pools[2] + pools[3] + pools[4] + pools[5] + pools[6];
    }

    function getAllPoolInUSD() public view returns (uint) {
        uint WETHPriceInUSD = uint(IChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419).latestAnswer()); // 8 decimals
        require(WETHPriceInUSD > 0, "ChainLink error");
        return getAllPoolInETH() * WETHPriceInUSD / 1e8;
    }

    function getCurrentCompositionPerc() external view returns (uint[] memory percentages) {
        uint[] memory pools = getEachPoolInETH();
        uint allPool = pools[0] + pools[1] + pools[2];
        percentages = new uint[](7);
        percentages[0] = pools[0] * 10000 / allPool;
        percentages[1] = pools[1] * 10000 / allPool;
        percentages[2] = pools[2] * 10000 / allPool;
        percentages[3] = pools[3] * 10000 / allPool;
        percentages[4] = pools[4] * 10000 / allPool;
        percentages[5] = pools[5] * 10000 / allPool;
        percentages[6] = pools[6] * 10000 / allPool;
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