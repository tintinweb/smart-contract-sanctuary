// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./ComptrollerInterface.sol";
import "./CTokenInterface.sol";
import "./CEthInterface.sol";

interface PriceFeed {
    function getUnderlyingPrice(address cToken) external view returns (uint256);
}

contract LaverageETHContract {
    //erc20 token
    IERC20 dai;

    //cErc20 Token
    CErc20 cDai;
    CEth cEth;

    //token decimal
    uint8 constant DAI_DACIMAL = 18;
    uint8 constant CTOKEN_DACIMAL = 8;

    //uniswap router
    IUniswapV2Router02 uni;

    Comptroller comptroller;
    PriceFeed priceFeed;

    constructor(
        address _daiAddress,
        address _cDaiAddress,
        address _cEthAddress,
        address _comptrollerAddress,
        address _priceFeedAddress,
        address _uniRouterAddress
    ) {
        dai = IERC20(_daiAddress);
        cDai = CErc20(_cDaiAddress);
        cEth = CEth(_cEthAddress);
        comptroller = Comptroller(_comptrollerAddress);
        priceFeed = PriceFeed(_priceFeedAddress);
        uni = IUniswapV2Router02(_uniRouterAddress);
    }

    mapping(address => uint256) public initialBalance;
    mapping(address => uint256) public laverageBalance;
    mapping(address => bool) public hasStaked;

    mapping(address => uint256) private accountsDaiBalance;
    mapping(address => uint256) private accountsEthBalance;

    event MyLog(string, uint256);
    event OpenLaveragePositionSuccess(bool);
    event CloseLaveragePositionSuccess(bool);
    event BorrowDai(string, uint256);
    event SwapToken(string, uint256);
    event Redeem(string, uint256);
    event DepositSuccess(bool);
    event Withdraw(string, uint256);

    function initialBalanceOf(address _address) private view returns (uint256) {
        return initialBalance[_address];
    }

    function laverageBalanceOf(address _address)
        private
        view
        returns (uint256)
    {
        return laverageBalance[_address];
    }

    function estimateDaiToEthOutAmount(uint256 _balance)
        private
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = address(dai);
        path[1] = uni.WETH();

        uint256[] memory amountOuts = uni.getAmountsOut(_balance, path);
        return amountOuts[1];
    }

    function estimateEthToDaiOutAmount(uint256 _balance)
        private
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = uni.WETH();
        path[1] = address(dai);

        uint256[] memory amountOuts = uni.getAmountsOut(_balance, path);
        return amountOuts[1];
    }

    function estimateDaiToEthMinimunOutAmount(uint256 __balance)
        private
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = address(dai);
        path[1] = uni.WETH();

        uint256[] memory amountOuts = uni.getAmountsOut(__balance, path);

        // return with minimun amount with slipage 5%
        uint256 result = amountOuts[1] - ((amountOuts[1] * 5) / 100);
        return result;
    }

    //get collateral factor percantage
    function getCollateralFactorPercentage() private view returns (uint256) {
        (bool isListed, uint256 collateralFactorMantissa) = comptroller.markets(
            address(cDai)
        );
        //return as percentage
        uint256 percentCalcutage = collateralFactorMantissa / 1e16;
        return percentCalcutage;
    }

    // Enter the ETH market so you can borrow another type of asset
    function enterMarkets() private returns (bool) {
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cEth);
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        if (errors[0] != 0) {
            revert("Comptroller.enterMarkets failed.");
        }
        return true;
    }

    function maxBorrowDaiAmount() private view returns (uint256) {
        // Get my account's total liquidity value in Compound
        (uint256 error, uint256 liquidity, uint256 shortfall) = comptroller
            .getAccountLiquidity(address(this));
        if (error != 0) {
            revert("Comptroller.getAccountLiquidity failed.");
        }
        require(shortfall == 0, "account underwater");
        require(liquidity > 0, "account has excess collateral");

        // get maximum amount of dai that  we can borrow.
        uint256 daiPrice = priceFeed.getUnderlyingPrice(address(cDai));
        uint256 maxBorrowDai = liquidity / daiPrice;

        // get amount of Dai that we can to borrow by calculate with colateral factor percentage
        uint256 colateralFactorPercentage = getCollateralFactorPercentage();
        uint256 amountDaiToBorrow = (maxBorrowDai * colateralFactorPercentage) /
            100;

        uint256 borrowAmount = amountDaiToBorrow * (10**DAI_DACIMAL);
        return borrowAmount;
    }

    //get cEth of contract balance
    function cEthBalance() private view returns (uint256) {
        return cEth.balanceOf(address(this));
    }

    function borrowDai() private returns (bool) {
        // borrow Dai
        uint256 borrowAmount = maxBorrowDaiAmount();
        accountsDaiBalance[msg.sender] += borrowAmount;
        cDai.borrow(borrowAmount);
        emit BorrowDai("borrowAmount", borrowAmount);
        return true;
    }

    function swapAllDaiToETH() private returns (uint256) {
        // Get the borrow balance
        uint256 daiBalance = accountsDaiBalance[msg.sender];

        // swap all dai of user balance to eth
        require(dai.approve(address(uni), daiBalance), "approve failed.");
        address[] memory path = new address[](2);
        path[0] = address(dai);
        path[1] = uni.WETH();

        uint256 minAmountOut = estimateDaiToEthMinimunOutAmount(daiBalance);

        uint256[] memory swapOutAmounts = uni.swapExactTokensForETH(
            daiBalance,
            minAmountOut,
            path,
            address(this),
            block.timestamp
        );
        accountsDaiBalance[msg.sender] -= swapOutAmounts[0];
        accountsEthBalance[msg.sender] += swapOutAmounts[1];
        emit SwapToken("Swap all dai to eth", swapOutAmounts[1]);
        return swapOutAmounts[1];
    }

    function swapSpecificDaiToETH(uint256 _amountIn) private returns (uint256) {
        // swap dai to eth
        require(dai.approve(address(uni), _amountIn), "approve failed.");
        address[] memory path = new address[](2);
        path[0] = address(dai);
        path[1] = uni.WETH();

        uint256 minAmountOut = estimateDaiToEthMinimunOutAmount(_amountIn);

        uint256[] memory swapOutAmounts = uni.swapExactTokensForETH(
            _amountIn,
            minAmountOut,
            path,
            address(this),
            block.timestamp
        );
        accountsDaiBalance[msg.sender] -= swapOutAmounts[0];
        accountsEthBalance[msg.sender] += swapOutAmounts[1];
        emit SwapToken("Swap specific dai to eth", swapOutAmounts[1]);
        return swapOutAmounts[1];
    }

    function swapAllEthToDai() private returns (uint256) {
        uint256 contractEthBalanceRemain = accountsEthBalance[msg.sender];

        // swap eth to dai
        address[] memory path = new address[](2);

        path[0] = uni.WETH();
        path[1] = address(dai);

        uint256 amountOut = contractEthBalanceRemain;

        uint256[] memory swapOutAmounts = uni.swapExactETHForTokens{
            value: amountOut
        }(0, path, address(this), block.timestamp);

        accountsEthBalance[msg.sender] -= swapOutAmounts[0];
        accountsDaiBalance[msg.sender] += swapOutAmounts[1];
        emit SwapToken("Swap all eth to dai", swapOutAmounts[1]);
        return swapOutAmounts[1];
    }

    function openLaveragePosition() public payable {
        require(
            hasStaked[msg.sender] == false,
            "Plase close the previous laverage position first"
        );

        // Supply ETH as collateral, get cETH in return
        cEth.mint{value: msg.value}();

        // enter market to enable borrow
        require(enterMarkets() == true, "Enter market failed");

        //store user balance
        initialBalance[msg.sender] = msg.value;
        hasStaked[msg.sender] = true;

        //laverage ratio target 1.5x of initial balance
        laverageBalance[msg.sender] = initialBalance[msg.sender];
        uint256 laverageRatioTarget = (initialBalance[msg.sender] * 150) / 100;

        uint256 estimateNextSwappedETH = 0;

        // Loop for laverage eth until cover the laverage Ratio Target
        while (laverageBalance[msg.sender] <= laverageRatioTarget) {
            // borrow dai
            require(borrowDai() == true, "borrow dai failed");

            estimateNextSwappedETH = estimateDaiToEthOutAmount(
                accountsDaiBalance[msg.sender]
            );

            //if next estimate laverage exceed the laverageRatioTarget should be swap specific dai amount for match the laverageRatioTarget
            if (
                laverageBalance[msg.sender] + estimateNextSwappedETH >
                laverageRatioTarget
            ) {
                // estimate specific dai to meet the ratio target
                uint256 missingAmountToMeetTarget = laverageRatioTarget -
                    laverageBalance[msg.sender];
                uint256 totalSpecificEth = estimateNextSwappedETH -
                    missingAmountToMeetTarget;
                uint256 estimateSpecificDai = estimateEthToDaiOutAmount(
                    totalSpecificEth
                );

                // swap specific dai to eth
                uint256 swapOutAmount = swapSpecificDaiToETH(
                    estimateSpecificDai
                );
                laverageBalance[msg.sender] += swapOutAmount;

                break;
            } else {
                //if next estimate laverage is not exeed the laverageRatioTarget swap all dai that we have to eth
                uint256 swapOutAmount = swapAllDaiToETH();
                laverageBalance[msg.sender] += swapOutAmount;

                // Supply more ETH as collateral
                uint256 mintBalance = accountsEthBalance[msg.sender];
                cEth.mint{value: mintBalance}();
                accountsEthBalance[msg.sender] -= mintBalance;
            }
        }
        emit OpenLaveragePositionSuccess(true);
    }

    //get borrowed dai balance
    function daiBorrowedBalace() private returns (uint256) {
        uint256 balanceBorrow = cDai.borrowBalanceCurrent(address(this));
        emit MyLog("Borrowed Dai Balace", balanceBorrow);
        return balanceBorrow;
    }

    function repayDai() private returns (bool) {
        //if have remaining eth sell all remaining eth to dai
        uint256 ethBalance = accountsEthBalance[msg.sender];
        if (ethBalance > 0) {
            require(swapAllEthToDai() > 0, "swap eth to dai failed");
        }

        //repay borrow dai
        uint256 daiBalance = accountsDaiBalance[msg.sender];

        uint256 borrowedDai = daiBorrowedBalace();
        if (accountsDaiBalance[msg.sender] > borrowedDai) {
            dai.approve(address(cDai), borrowedDai);
            require(cDai.repayBorrow(borrowedDai) == 0, "repayBorrow failed");
            accountsDaiBalance[msg.sender] =
                accountsDaiBalance[msg.sender] -
                borrowedDai;
        } else {
            dai.approve(address(cDai), daiBalance);
            require(cDai.repayBorrow(daiBalance) == 0, "repayBorrow failed");
            accountsDaiBalance[msg.sender] = 0;
        }

        return true;
    }

    function getAccountLiquidity() private view returns (uint256) {
        (uint256 error, uint256 liquidity, uint256 shortfall) = comptroller
            .getAccountLiquidity(address(this));

        return liquidity;
    }

    function getAvailableLiquidity() private view returns (uint256) {
        uint256 accountLiquidity = getAccountLiquidity();
        uint256 ethPrice = priceFeed.getUnderlyingPrice(address(cEth));

        // calculate available liquidity
        uint256 maxLiquidity = (accountLiquidity * (10**18)) / ethPrice;

        // use 70 from 75 percent collateral percentage
        uint256 availableLiquidity = (maxLiquidity * 70) / 100;
        return availableLiquidity;
    }

    //estimate redeem balance that we can redeem
    function estimateRedeemBalance() private returns (uint256) {
        uint256 availableLiquidity = getAvailableLiquidity();
        uint256 ethBalance = cEth.balanceOfUnderlying(address(this));

        // return estimate redeem balance
        if (availableLiquidity > ethBalance) {
            // redeem balance must be less than available liquidity
            uint256 totalRedeem = availableLiquidity - ethBalance;
            emit Redeem("Redeem eth", totalRedeem);
            return totalRedeem;
        } else {
            emit MyLog(
                "availableLiquidity < ethBalance So redeem amount = 0",
                0
            );
            return 0;
        }
    }


    //redeem all Eth that we supplied as colateral
    function redeemAllEth() private returns (bool) {
        uint256 supplied = cEth.balanceOf(address(this));

        uint256 redeemResult = cEth.redeem(supplied);
        emit Redeem("Redeem All eth", redeemResult);
        return true;
    }

    function forceRedeem() private returns (bool) {
        uint256 beforeRedeemAmount = address(this).balance;
        uint256 borrowedDai = daiBorrowedBalace();

        if (borrowedDai == 0) {
            require(redeemAllEth() == true, "redeem all eth failed");
            uint256 afterRedeemAmount = address(this).balance;
            accountsEthBalance[msg.sender] +=
                afterRedeemAmount -
                beforeRedeemAmount;
            return true;
        } else {
            uint256 redeemBalance = estimateRedeemBalance();
            uint256 redeemResult = cEth.redeemUnderlying(redeemBalance);
            emit Redeem("Redeem eth", redeemResult);

            uint256 afterRedeemAmount = address(this).balance;
            accountsEthBalance[msg.sender] +=
                afterRedeemAmount -
                beforeRedeemAmount;
            return true;
        }
    }

    //withdraw eth
    function withdraw() private returns (bool) {
        uint256 accountBalance = accountsEthBalance[msg.sender];
        require(
            address(this).balance >= accountBalance,
            "insufficient fund to withdraw"
        );
        payable(msg.sender).transfer(accountBalance);
        emit Withdraw("Withdraw success", accountBalance);
        return true;
    }

    //close position
    function closeLaveragePosition() external {
        require(hasStaked[msg.sender] == true, "please open position first");
        uint256 remainingBorrowedDai = daiBorrowedBalace();

        //loop until remaining Borrowed Dai = 0
        while (remainingBorrowedDai > 0) {
            require(repayDai() == true, "repay failed");

            uint256 availableLiquidity = getAvailableLiquidity();
            uint256 ethBalance = cEth.balanceOfUnderlying(address(this));

            // redeem balance must be less than available liquidity
            if (availableLiquidity < ethBalance) {
                emit MyLog(
                    "availableLiquidity < ethBalance So redeem amount = 0",
                    0
                );
                break;
            }

            require(forceRedeem() == true, "redeem failed");
            remainingBorrowedDai = daiBorrowedBalace();
        }

        swapAllDaiToETH();
        require(withdraw() == true, "withdraw failed");

        comptroller.exitMarket(address(cEth));

        hasStaked[msg.sender] = false;
        initialBalance[msg.sender] = 0;
        laverageBalance[msg.sender] = 0;
        accountsEthBalance[msg.sender] = 0;
        accountsDaiBalance[msg.sender] = 0;

        emit CloseLaveragePositionSuccess(true);
    }

    // Need this to receive ETH when `openLaveragePosition` executes
    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

interface Comptroller {
    function markets(address) external view returns (bool, uint256);

    function enterMarkets(address[] calldata)
        external
        returns (uint256[] memory);

    function getAccountLiquidity(address)
        external
        view
        returns (uint256, uint256, uint256);

    function closeFactorMantissa() external view returns (uint);

    function exitMarket(address cToken) external returns (uint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

interface CErc20 {
    function balanceOf(address) external view returns (uint);

    function mint(uint) external returns (uint);

    function exchangeRateCurrent() external returns (uint);

    function supplyRatePerBlock() external returns (uint);

    function balanceOfUnderlying(address) external returns (uint);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function borrow(uint) external returns (uint);

    function borrowBalanceCurrent(address) external returns (uint);

    function borrowRatePerBlock() external view returns (uint);

    function repayBorrow(uint) external returns (uint);

    function liquidateBorrow(address borrower, uint amount, address collateral) external returns (uint);

    function totalBorrowsCurrent() external returns (uint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

interface CEth {
    function balanceOf(address owner) external view returns (uint);

    function mint() external payable;

    function borrow(uint256) external returns (uint256);

    function repayBorrow() external payable;

    function borrowBalanceCurrent(address) external returns (uint256);

    function redeem(uint redeemTokens) external payable returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function exchangeRateCurrent() external returns (uint);

    function balanceOfUnderlying(address) external returns (uint);

    function liquidateBorrow(address borrower, uint amount, address collateral) external returns (uint);

    function totalBorrowsCurrent() external returns (uint);

}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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