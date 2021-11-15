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

interface IDaoL1Vault is IERC20Upgradeable {
    function deposit(uint amount) external;
    function withdraw(uint share) external returns (uint);
    function getAllPoolInUSD() external view returns (uint);
    function getAllPoolInETH() external view returns (uint);
}

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

contract StonksStrategyKovan is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable constant UST = IERC20Upgradeable(0xa47c8bf37f92aBed4A126BDA807A7b7498661acD);
    IERC20Upgradeable constant mMSFT = IERC20Upgradeable(0x41BbEDd7286dAab5910a1f15d12CBda839852BD7);
    IERC20Upgradeable constant mTWTR = IERC20Upgradeable(0xEdb0414627E6f1e3F082DE65cD4F9C693D78CCA9);
    IERC20Upgradeable constant mTSLA = IERC20Upgradeable(0x21cA39943E91d704678F5D00b6616650F066fD63);
    IERC20Upgradeable constant mGOOGL = IERC20Upgradeable(0x59A921Db27Dd6d4d974745B7FfC5c33932653442);
    IERC20Upgradeable constant mAMZN = IERC20Upgradeable(0x0cae9e4d663793c2a2A0b211c1Cf4bBca2B9cAa7);
    IERC20Upgradeable constant mAAPL = IERC20Upgradeable(0xd36932143F6eBDEDD872D5Fb0651f4B72Fd15a84);
    IERC20Upgradeable constant mNFLX = IERC20Upgradeable(0xC8d674114bac90148d11D3C1d33C61835a0F9DCD);

    IERC20Upgradeable constant mMSFTUST = IERC20Upgradeable(0xeAfAD3065de347b910bb88f09A5abE580a09D655);
    IERC20Upgradeable constant mTWTRUST = IERC20Upgradeable(0x34856be886A2dBa5F7c38c4df7FD86869aB08040);
    IERC20Upgradeable constant mTSLAUST = IERC20Upgradeable(0x5233349957586A8207c52693A959483F9aeAA50C);
    IERC20Upgradeable constant mGOOGLUST = IERC20Upgradeable(0x4b70ccD1Cf9905BE1FaEd025EADbD3Ab124efe9a);
    IERC20Upgradeable constant mAMZNUST = IERC20Upgradeable(0x0Ae8cB1f57e3b1b7f4f5048743710084AA69E796);
    IERC20Upgradeable constant mAAPLUST = IERC20Upgradeable(0xB022e08aDc8bA2dE6bA4fECb59C6D502f66e953B);
    IERC20Upgradeable constant mNFLXUST = IERC20Upgradeable(0xC99A74145682C4b4A6e9fa55d559eb49A6884F75);

    IRouter constant uniRouter = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    IDaoL1Vault public mMSFTUSTVault;
    IDaoL1Vault public mTWTRUSTVault;
    IDaoL1Vault public mTSLAUSTVault;
    IDaoL1Vault public mGOOGLUSTVault;
    IDaoL1Vault public mAMZNUSTVault;
    IDaoL1Vault public mAAPLUSTVault;
    IDaoL1Vault public mNFLXUSTVault;

    address public vault;
    uint public watermark; // In USD (18 decimals)
    uint public profitFeePerc;

    event TargetComposition (uint targetPool);
    event CurrentComposition (
        uint mMSFTUSTCurrentPool, uint mTWTRUSTCurrentPool, uint mTSLAUSTCurrentPool, uint mGOOGLUSTCurrentPool,
        uint mAMZNUSTCurrentPool, uint mAAPLUSTCurrentPool, uint mNFLXUSTCurrentPool
    );
    event InvestMMSFTUST(uint USTAmtIn, uint mMSFTUSTAmt);
    event InvestMTWTRUST(uint USTAmtIn, uint mTWTRUSTAmt);
    event InvestMTSLAUST(uint USTAmtIn, uint mTSLAUSTAmt);
    event InvestMGOOGLUST(uint USTAmtIn, uint mGOOGLUSTAmt);
    event InvestMAMZNUST(uint USTAmtIn, uint mAMZNUSTAmt);
    event InvestMAAPLUST(uint USTAmtIn, uint mAAPLUSTAmt);
    event InvestMNFLXUST(uint USTAmtIn, uint mNFLXUSTAmt);
    event Withdraw(uint amtWithdraw, uint USTAmtOut);
    event WithdrawMMSFTUST(uint lpTokenAmt, uint USTAmt);
    event WithdrawMTWTRUST(uint lpTokenAmt, uint USTAmt);
    event WithdrawMTSLAUST(uint lpTokenAmt, uint USTAmt);
    event WithdrawMGOOGLUST(uint lpTokenAmt, uint USTAmt);
    event WithdrawMAMZNUST(uint lpTokenAmt, uint USTAmt);
    event WithdrawMAAPLUST(uint lpTokenAmt, uint USTAmt);
    event WithdrawMNFLXUST(uint lpTokenAmt, uint USTAmt);
    event CollectProfitAndUpdateWatermark(uint currentWatermark, uint lastWatermark, uint fee);
    event AdjustWatermark(uint currentWatermark, uint lastWatermark);
    event Reimburse(uint USTAmt);
    event EmergencyWithdraw(uint USTAmt);

    modifier onlyVault {
        require(msg.sender == vault, "Only vault");
        _;
    }

    function initialize(
        IDaoL1Vault _mMSFTUSTVault,
        IDaoL1Vault _mTWTRUSTVault,
        IDaoL1Vault _mTSLAUSTVault,
        IDaoL1Vault _mGOOGLUSTVault,
        IDaoL1Vault _mAMZNUSTVault,
        IDaoL1Vault _mAAPLUSTVault,
        IDaoL1Vault _mNFLXUSTVault
    ) external initializer {
        __Ownable_init();

        mMSFTUSTVault = _mMSFTUSTVault;
        mTWTRUSTVault = _mTWTRUSTVault;
        mTSLAUSTVault = _mTSLAUSTVault;
        mGOOGLUSTVault = _mGOOGLUSTVault;
        mAMZNUSTVault = _mAMZNUSTVault;
        mAAPLUSTVault = _mAAPLUSTVault;
        mNFLXUSTVault = _mNFLXUSTVault;

        profitFeePerc = 2000;

        // UST.safeApprove(address(uniRouter), type(uint).max);
        // mMSFT.safeApprove(address(uniRouter), type(uint).max);
        // mTWTR.safeApprove(address(uniRouter), type(uint).max);
        // mTSLA.safeApprove(address(uniRouter), type(uint).max);
        // mGOOGL.safeApprove(address(uniRouter), type(uint).max);
        // mAMZN.safeApprove(address(uniRouter), type(uint).max);
        // mAAPL.safeApprove(address(uniRouter), type(uint).max);
        // mNFLX.safeApprove(address(uniRouter), type(uint).max);

        // mMSFTUST.safeApprove(address(mMSFTUSTVault), type(uint).max);
        // mMSFTUST.safeApprove(address(uniRouter), type(uint).max);
        // mTWTRUST.safeApprove(address(mTWTRUSTVault), type(uint).max);
        // mTWTRUST.safeApprove(address(uniRouter), type(uint).max);
        // mTSLAUST.safeApprove(address(mTSLAUSTVault), type(uint).max);
        // mTSLAUST.safeApprove(address(uniRouter), type(uint).max);
        // mGOOGLUST.safeApprove(address(mGOOGLUSTVault), type(uint).max);
        // mGOOGLUST.safeApprove(address(uniRouter), type(uint).max);
        // mAMZNUST.safeApprove(address(mAMZNUSTVault), type(uint).max);
        // mAMZNUST.safeApprove(address(uniRouter), type(uint).max);
        // mAAPLUST.safeApprove(address(mAAPLUSTVault), type(uint).max);
        // mAAPLUST.safeApprove(address(uniRouter), type(uint).max);
        // mNFLXUST.safeApprove(address(mNFLXUSTVault), type(uint).max);
        // mNFLXUST.safeApprove(address(uniRouter), type(uint).max);
    }

    function invest(uint USTAmt) external onlyVault {
        UST.safeTransferFrom(vault, address(this), USTAmt);

        uint[] memory pools = getEachPoolInUSD();
        uint pool = pools[0] + pools[1] + pools[2] + pools[3] + pools[4] + pools[5] + pools[6] + USTAmt;
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
            investMMSFTUST(targetPool - pools[0]);
            investMTWTRUST(targetPool - pools[1]);
            investMTSLAUST(targetPool - pools[2]);
            investMGOOGLUST(targetPool - pools[3]);
            investMAMZNUST(targetPool - pools[4]);
            investMAAPLUST(targetPool - pools[5]);
            investMNFLXUST(targetPool - pools[6]);
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

            if (farmIndex == 0) investMMSFTUST(USTAmt);
            else if (farmIndex == 1) investMTWTRUST(USTAmt);
            else if (farmIndex == 2) investMTSLAUST(USTAmt);
            else if (farmIndex == 3) investMGOOGLUST(USTAmt);
            else if (farmIndex == 4) investMAMZNUST(USTAmt);
            else if (farmIndex == 5) investMNFLXUST(USTAmt);
            else investMNFLXUST(USTAmt);
        }

        emit TargetComposition(targetPool);
        emit CurrentComposition(pools[0], pools[1], pools[2], pools[3], pools[4], pools[5], pools[6]);
    }

    function investMMSFTUST(uint USTAmt) private {
        uint halfUST = USTAmt / 2;
        uint mMSFTAmt = swap(address(UST), address(mMSFT), halfUST, 0);
        (,,uint mMSFTUSTAmt) = uniRouter.addLiquidity(address(mMSFT), address(UST), mMSFTAmt, halfUST, 0, 0, address(this), block.timestamp);
        mMSFTUSTVault.deposit(mMSFTUSTAmt);
        emit InvestMMSFTUST(USTAmt, mMSFTUSTAmt);
    }

    function investMTWTRUST(uint USTAmt) private {
        uint halfUST = USTAmt / 2;
        uint mTWTRAmt = swap(address(UST), address(mTWTR), halfUST, 0);
        (,,uint mTWTRUSTAmt) = uniRouter.addLiquidity(address(mTWTR), address(UST), mTWTRAmt, halfUST, 0, 0, address(this), block.timestamp);
        mTWTRUSTVault.deposit(mTWTRUSTAmt);
        emit InvestMTWTRUST(USTAmt, mTWTRUSTAmt);
    }

    function investMTSLAUST(uint USTAmt) private {
        uint halfUST = USTAmt / 2;
        uint mTSLAAmt = swap(address(UST), address(mTSLA), halfUST, 0);
        (,,uint mTSLAUSTAmt) = uniRouter.addLiquidity(address(mTSLA), address(UST), mTSLAAmt, halfUST, 0, 0, address(this), block.timestamp);
        mTSLAUSTVault.deposit(mTSLAUSTAmt);
        emit InvestMTSLAUST(USTAmt, mTSLAUSTAmt);
    }

    function investMGOOGLUST(uint USTAmt) private {
        uint halfUST = USTAmt / 2;
        uint mGOOGLAmt = swap(address(UST), address(mGOOGL), halfUST, 0);
        (,,uint mGOOGLUSTAmt) = uniRouter.addLiquidity(address(mGOOGL), address(UST), mGOOGLAmt, halfUST, 0, 0, address(this), block.timestamp);
        mGOOGLUSTVault.deposit(mGOOGLUSTAmt);
        emit InvestMGOOGLUST(USTAmt, mGOOGLUSTAmt);
    }

    function investMAMZNUST(uint USTAmt) private {
        uint halfUST = USTAmt / 2;
        uint mAMZNAmt = swap(address(UST), address(mAMZN), halfUST, 0);
        (,,uint mAMZNUSTAmt) = uniRouter.addLiquidity(address(mAMZN), address(UST), mAMZNAmt, halfUST, 0, 0, address(this), block.timestamp);
        mAMZNUSTVault.deposit(mAMZNUSTAmt);
        emit InvestMAMZNUST(USTAmt, mAMZNUSTAmt);
    }

    function investMAAPLUST(uint USTAmt) private {
        uint halfUST = USTAmt / 2;
        uint mAAPLAmt = swap(address(UST), address(mAAPL), halfUST, 0);
        (,,uint mAAPLUSTAmt) = uniRouter.addLiquidity(address(mAAPL), address(UST), mAAPLAmt, halfUST, 0, 0, address(this), block.timestamp);
        mAAPLUSTVault.deposit(mAAPLUSTAmt);
        emit InvestMAAPLUST(USTAmt, mAAPLUSTAmt);
    }

    function investMNFLXUST(uint USTAmt) private {
        uint halfUST = USTAmt / 2;
        uint mNFLXAmt = swap(address(UST), address(mNFLX), halfUST, 0);
        (,,uint mNFLXUSTAmt) = uniRouter.addLiquidity(address(mNFLX), address(UST), mNFLXAmt, halfUST, 0, 0, address(this), block.timestamp);
        mNFLXUSTVault.deposit(mNFLXUSTAmt);
        emit InvestMNFLXUST(USTAmt, mNFLXUSTAmt);
    }

    /// @param amount Amount to withdraw in USD
    function withdraw(uint amount, uint[] calldata tokenPrice) external onlyVault returns (uint USTAmt) {
        uint sharePerc = amount * 1e18 / getAllPoolInUSD();
        uint USTAmtBefore = UST.balanceOf(address(this));
        withdrawMMSFTUST(sharePerc, tokenPrice[0]);
        withdrawMTWTRUST(sharePerc, tokenPrice[1]);
        withdrawMTSLAUST(sharePerc, tokenPrice[2]);
        withdrawMGOOGLUST(sharePerc, tokenPrice[3]);
        withdrawMAMZNUST(sharePerc, tokenPrice[4]);
        withdrawMAAPLUST(sharePerc, tokenPrice[5]);
        withdrawMNFLXUST(sharePerc, tokenPrice[6]);
        USTAmt = UST.balanceOf(address(this)) - USTAmtBefore;
        UST.safeTransfer(vault, USTAmt);
        emit Withdraw(amount, USTAmt);
    }

    function withdrawMMSFTUST(uint sharePerc, uint mMSFTPrice) private {
        uint mMSFTUSTAmt = mMSFTUSTVault.withdraw(mMSFTUSTVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint mMSFTAmt, uint USTAmt) = uniRouter.removeLiquidity(address(mMSFT), address(UST), mMSFTUSTAmt, 0, 0, address(this), block.timestamp);
        uint _USTAmt = swap(address(mMSFT), address(UST), mMSFTAmt, mMSFTAmt * mMSFTPrice / 1e18);
        emit WithdrawMMSFTUST(mMSFTUSTAmt, USTAmt + _USTAmt);
    }
    
    function withdrawMTWTRUST(uint sharePerc, uint mTWTRPrice) private {
        uint mTWTRUSTAmt = mTWTRUSTVault.withdraw(mTWTRUSTVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint mTWTRAmt, uint USTAmt) = uniRouter.removeLiquidity(address(mTWTR), address(UST), mTWTRUSTAmt, 0, 0, address(this), block.timestamp);
        uint _USTAmt = swap(address(mTWTR), address(UST), mTWTRAmt, mTWTRAmt * mTWTRPrice / 1e18);
        emit WithdrawMTWTRUST(mTWTRUSTAmt, USTAmt + _USTAmt);
    }

    function withdrawMTSLAUST(uint sharePerc, uint mTSLAPrice) private {
        uint mTSLAUSTAmt = mTSLAUSTVault.withdraw(mTSLAUSTVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint mTSLAAmt, uint USTAmt) = uniRouter.removeLiquidity(address(mTSLA), address(UST), mTSLAUSTAmt, 0, 0, address(this), block.timestamp);
        uint _USTAmt = swap(address(mTSLA), address(UST), mTSLAAmt, mTSLAAmt * mTSLAPrice / 1e18);
        emit WithdrawMTSLAUST(mTSLAUSTAmt, USTAmt + _USTAmt);
    }

    function withdrawMGOOGLUST(uint sharePerc, uint mGOOGLPrice) private {
        uint mGOOGLUSTAmt = mGOOGLUSTVault.withdraw(mGOOGLUSTVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint mGOOGLAmt, uint USTAmt) = uniRouter.removeLiquidity(address(mGOOGL), address(UST), mGOOGLUSTAmt, 0, 0, address(this), block.timestamp);
        uint _USTAmt = swap(address(mGOOGL), address(UST), mGOOGLAmt, mGOOGLAmt * mGOOGLPrice / 1e18);
        emit WithdrawMGOOGLUST(mGOOGLUSTAmt, USTAmt + _USTAmt);
    }

    function withdrawMAMZNUST(uint sharePerc, uint mAMZNPrice) private {
        uint mAMZNUSTAmt = mAMZNUSTVault.withdraw(mAMZNUSTVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint mAMZNAmt, uint USTAmt) = uniRouter.removeLiquidity(address(mAMZN), address(UST), mAMZNUSTAmt, 0, 0, address(this), block.timestamp);
        uint _USTAmt = swap(address(mAMZN), address(UST), mAMZNAmt, mAMZNAmt * mAMZNPrice / 1e18);
        emit WithdrawMAMZNUST(mAMZNUSTAmt, USTAmt + _USTAmt);
    }

    function withdrawMAAPLUST(uint sharePerc, uint mAAPLPrice) private {
        uint mAAPLUSTAmt = mAAPLUSTVault.withdraw(mAAPLUSTVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint mAAPLAmt, uint USTAmt) = uniRouter.removeLiquidity(address(mAAPL), address(UST), mAAPLUSTAmt, 0, 0, address(this), block.timestamp);
        uint _USTAmt = swap(address(mAAPL), address(UST), mAAPLAmt, mAAPLAmt * mAAPLPrice / 1e18);
        emit WithdrawMAAPLUST(mAAPLUSTAmt, USTAmt + _USTAmt);
    }

    function withdrawMNFLXUST(uint sharePerc, uint mNFLXPrice) private {
        uint mNFLXUSTAmt = mNFLXUSTVault.withdraw(mNFLXUSTVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint mNFLXAmt, uint USTAmt) = uniRouter.removeLiquidity(address(mNFLX), address(UST), mNFLXUSTAmt, 0, 0, address(this), block.timestamp);
        uint _USTAmt = swap(address(mNFLX), address(UST), mNFLXAmt, mNFLXAmt * mNFLXPrice / 1e18);
        emit WithdrawMNFLXUST(mNFLXUSTAmt, USTAmt + _USTAmt);
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

    /// @param amount Amount to reimburse to vault contract in USD
    function reimburse(uint farmIndex, uint amount) external onlyVault returns (uint USTAmt) {
        if (farmIndex == 0) withdrawMMSFTUST(amount * 1e18 / getMMSFTUSTPoolInUSD(), 0);
        else if (farmIndex == 1) withdrawMTWTRUST(amount * 1e18 / getMTWTRUSTPoolInUSD(), 0);
        else if (farmIndex == 2) withdrawMTSLAUST(amount * 1e18 / getMTSLAUSTPoolInUSD(), 0);
        else if (farmIndex == 3) withdrawMGOOGLUST(amount * 1e18 / getMGOOGLUSTPoolInUSD(), 0);
        else if (farmIndex == 4) withdrawMAMZNUST(amount * 1e18 / getMAMZNUSTPoolInUSD(), 0);
        else if (farmIndex == 5) withdrawMAAPLUST(amount * 1e18 / getMAAPLUSTPoolInUSD(), 0);
        else if (farmIndex == 6) withdrawMNFLXUST(amount * 1e18 / getMNFLXUSTPoolInUSD(), 0);
        USTAmt = UST.balanceOf(address(this));
        UST.safeTransfer(vault, USTAmt);
        emit Reimburse(USTAmt);
    }

    function emergencyWithdraw() external onlyVault {
        // 1e18 == 100% of share
        withdrawMMSFTUST(1e18, 0);
        withdrawMTWTRUST(1e18, 0);
        withdrawMTSLAUST(1e18, 0);
        withdrawMGOOGLUST(1e18, 0);
        withdrawMAMZNUST(1e18, 0);
        withdrawMAAPLUST(1e18, 0);
        withdrawMNFLXUST(1e18, 0);
        uint USTAmt = UST.balanceOf(address(this));
        UST.safeTransfer(vault, USTAmt);
        watermark = 0;

        emit EmergencyWithdraw(USTAmt);
    }

    function swap(address from, address to, uint amount, uint amountOutMin) private returns (uint) {
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;
        return uniRouter.swapExactTokensForTokens(amount, amountOutMin, path, address(this), block.timestamp)[1];
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

    function getMMSFTUSTPoolInUSD() private view returns (uint) {
        return mMSFTUSTVault.getAllPoolInUSD();
    }

    function getMTWTRUSTPoolInUSD() private view returns (uint) {
        return mTWTRUSTVault.getAllPoolInUSD();
    }

    function getMTSLAUSTPoolInUSD() private view returns (uint) {
        return mTSLAUSTVault.getAllPoolInUSD();
    }

    function getMGOOGLUSTPoolInUSD() private view returns (uint) {
        return mGOOGLUSTVault.getAllPoolInUSD();
    }

    function getMAMZNUSTPoolInUSD() private view returns (uint) {
        return mAMZNUSTVault.getAllPoolInUSD();
    }

    function getMAAPLUSTPoolInUSD() private view returns (uint) {
        return mAAPLUSTVault.getAllPoolInUSD();
    }

    function getMNFLXUSTPoolInUSD() private view returns (uint) {
        return mNFLXUSTVault.getAllPoolInUSD();
    }

    function getEachPoolInUSD() private view returns (uint[] memory pools) {
        pools = new uint[](7);
        pools[0] = getMMSFTUSTPoolInUSD();
        pools[1] = getMTWTRUSTPoolInUSD();
        pools[2] = getMTSLAUSTPoolInUSD();
        pools[3] = getMGOOGLUSTPoolInUSD();
        pools[4] = getMAMZNUSTPoolInUSD();
        pools[5] = getMAAPLUSTPoolInUSD();
        pools[6] = getMNFLXUSTPoolInUSD();
    }

    /// @notice This function return only farms TVL in ETH
    function getAllPoolInETH() public view returns (uint) {
        uint USTPriceInETH = uint(IChainlink(0xa20623070413d42a5C01Db2c8111640DD7A5A03a).latestAnswer());
        require(USTPriceInETH > 0, "ChainLink error");
        return getAllPoolInUSD() * USTPriceInETH / 1e18;
    }

    /// @notice This function return only farms TVL in USD
    function getAllPoolInUSD() public view returns (uint) {
        uint[] memory pools = getEachPoolInUSD();
        return pools[0] + pools[1] + pools[2] + pools[3] + pools[4] + pools[5] + pools[6];
    }

    function getCurrentCompositionPerc() external view returns (uint[] memory percentages) {
        uint[] memory pools = getEachPoolInUSD();
        uint allPool = getAllPoolInUSD();
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

