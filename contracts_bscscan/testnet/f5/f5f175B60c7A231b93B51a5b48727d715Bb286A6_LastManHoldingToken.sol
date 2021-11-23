//SPDX-License-Identifier: MIT

import "./interfaces/IDEXFactory.sol";
import "./interfaces/IDEXRouter.sol";
import "./interfaces/IPancakePair.sol";

import "./utils/math/SafeMath.sol";
import "./BaseToken.sol";
import "./SafeToken.sol";
import "./LockToken.sol";

pragma solidity ^0.8.6;

contract LastManHoldingToken is
    BaseToken("Last Man Holding", "LAST", 1000000000000 * (10**18), 18),
    SafeToken,
    LockToken
{
    using SafeMath for uint256;

    mapping(address => bool) excludeFee;
    mapping(address => bool) excludeMaxTxn;
    mapping(address => bool) blackList;

    // Special wallets
    address devAddress = 0xF474Cf03ccEfF28aBc65C9cbaE594F725c80e12d;
    address lpAddress = 0x9207B6e0CB717ee22b29901267F564Aa2C033F8a;
    address autoBuyBackAddress = 0x30943711d1799597cFA24466c53260d5F4Ca161b;
    address manualBuyBackAddress = 0x980A75eCd1309eA12fa2ED87A8744fBfc9b863D5;

    // Distribution ratio over the tax bunch.
    // Sum of ratio should be 100(%)
    // if it < 100, remain token will be in the contract.
    uint8 devDividenRatio = 20;
    uint8 lpDividenRatio = 20;
    uint8 autoBuyBackDividenRatio = 30;
    uint8 manualBuyBackDividenRatio = 30;

    // uint256 buyBackUpperLimit = 2 * 10**16;

    IDEXRouter router;
    mapping(address => bool) pairs;
    bool swapEnabled = true;
    bool buyBackEnable = true;
    uint256 swapThreshold; // 0.02%
    uint256 totalBuy = 1;
    uint256 totalSell = 0;
    uint256 mainTokenTotalBuy = 0; // each increasement is 0.01 of main token.
    uint256 mainTokenTotalSell = 0;

    uint8 constant BUY_IN_TAX = 10;
    uint8 constant SELL_OUT_TAX = 30;
    uint8 constant TX_BUY = 1;
    uint8 constant TX_SELL = 2;
    uint8 constant SELL_THRESHOLD = 70;

    // We use 1% percentage.
    // 1 = 0.01 Main token
    uint256 private maxAmountOfMainTokenUserCanBuy = 200000000 * 10**18; // 2 million main token
    address _tokenCreator;

    address public pancakeSwapPair = DEAD;

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    // address ETH_AXS = 0xBB0E17EF65F82Ab018d8EDd776e8DD940327B28b;
    address _distributeTokenAddress;
    address public pair;

    constructor() {
        // PancakeSwap mainnet router address
        // 0x10ED43C718714eb63d5aA57B78B54704E256024E

        // PancakeSwap testnet router address
        // 0xD99D1c33F9fC3444f8101754aBC46c52416550D1

        // Uniswap mainnet router address
        // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

        router = IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        pancakeSwapPair = IDEXFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        _allowances[address(this)][address(router)] = ~uint256(0);
        // By default we distribute BNB.
        _distributeTokenAddress = router.WETH();

        address owner_ = msg.sender;
        _tokenCreator = msg.sender;

        excludeFee[owner_] = true;
        excludeMaxTxn[owner_] = true;
        excludeFee[address(this)] = true;
        excludeMaxTxn[address(this)] = true;

        _balances[owner_] = _totalSupply;
        emit Transfer(address(0), owner_, _totalSupply);

        swapThreshold = _totalSupply / 5000;

        initWallets();
    }

    function setSwapThreshold(uint256 threshold) public onlyOwner {
        swapThreshold = threshold;
    }

    function setDistributeToken(address tokenAddress) public onlyOwner {
        _distributeTokenAddress = tokenAddress;
    }

    function configureDividen(
        uint8 dev,
        uint8 lp,
        uint8 autoBuyBack,
        uint8 manualBuyBack
    ) public {
        require(
            dev + lp + autoBuyBack + manualBuyBack <= 100,
            "Total of dividen must <= 100"
        );
        devDividenRatio = dev;
        lpDividenRatio = lp;
        autoBuyBackDividenRatio = autoBuyBack;
        manualBuyBackDividenRatio = manualBuyBack;
    }

    function initWallets() private onlyOwner {
        toggleExcludeAllFeeForWallet(_tokenCreator, true);
        toggleExcludeAllFeeForWallet(devAddress, true);
        toggleExcludeAllFeeForWallet(lpAddress, true);
        toggleExcludeAllFeeForWallet(autoBuyBackAddress, true);
        toggleExcludeAllFeeForWallet(manualBuyBackAddress, true);

        setWhiteList(_tokenCreator, true);
        setWhiteList(devAddress, true);
        setWhiteList(lpAddress, true);
        setWhiteList(autoBuyBackAddress, true);
        setWhiteList(manualBuyBackAddress, true);
    }

    /**
        Set a wallet to be excluded from tax fee
     */
    function toggleExcludeAllFeeForWallet(address wallet, bool isExcludeFee)
        public
        onlyOwner
    {
        excludeFee[wallet] = isExcludeFee;
        excludeMaxTxn[wallet] = isExcludeFee;
    }

    /**
        Set/Unset an address to blacklist
     */
    function setBlacklist(address user, bool exempt) public onlyOwner {
        blackList[user] = exempt;
    }

    /**
        Set address of dev wallet
     */
    function setDevWalletAddress(address dev) public onlyOwner {
        setWhiteList(devAddress, false);
        toggleExcludeAllFeeForWallet(devAddress, false);
        devAddress = dev;
        toggleExcludeAllFeeForWallet(devAddress, true);
        setWhiteList(devAddress, true);
    }

    /**
        Set address of liquidity provider wallet
     */
    function setLPWalletAddress(address lp) public onlyOwner {
        setWhiteList(lpAddress, false);
        toggleExcludeAllFeeForWallet(lpAddress, false);
        lpAddress = lp;
        toggleExcludeAllFeeForWallet(lpAddress, true);
        setWhiteList(lpAddress, true);
    }

    /**
        Set address of auto buy back wallet
     */
    function setAutoBuyBackWalletAddress(address add) public onlyOwner {
        setWhiteList(autoBuyBackAddress, false);
        toggleExcludeAllFeeForWallet(autoBuyBackAddress, false);
        autoBuyBackAddress = add;
        toggleExcludeAllFeeForWallet(autoBuyBackAddress, true);
        setWhiteList(autoBuyBackAddress, true);
    }

    /**
        Set address of manual buy back wallet
     */
    function setManualBuyBackWalletAddress(address add) public onlyOwner {
        setWhiteList(manualBuyBackAddress, false);
        toggleExcludeAllFeeForWallet(manualBuyBackAddress, false);
        manualBuyBackAddress = add;
        toggleExcludeAllFeeForWallet(manualBuyBackAddress, true);
        setWhiteList(manualBuyBackAddress, true);
    }

    /**
     * Transfer the token from sender to recipient
     * THe logic of tax applied here.
     */
    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal override open(sender, recipient) returns (bool) {
        // Buy back we simply do the basic transfer.
        // this won't happen in anyother case.
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        // for the lp, dev, simply do basic transfer
        if (excludeFee[sender] || excludeFee[recipient]) {
            return _basicTransfer(sender, recipient, amount);
        }

        uint8 transferType = _transferType(sender, recipient);
        uint256 fee = 0;
        if (transferType == TX_BUY) {
            // user buy token
            isNotBlockSell(sender, recipient);
            canBuyToken(recipient, amount);
            totalBuy = totalBuy.add(amount);
            mainTokenTotalBuy = getPriceOfToken(amount);
        } else if (transferType == TX_SELL) {
            isNotBlockSell(sender, recipient);
            canSellToken(sender, amount);
            totalSell = totalSell.add(amount);
            mainTokenTotalSell += getPriceOfToken(amount);
        }
        fee = calculateFee(sender, recipient, amount);

        uint256 amountReceived = amount.sub(fee);
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[address(this)] = _balances[address(this)].add(fee);
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if (_balances[address(this)] > swapThreshold) {
            swapBackAndDistributeDividen();
        }
        emit Transfer(sender, recipient, amountReceived);

        return true;
    }

    /**
        Set max amount of MainToken that user can buy in a swap
     */
    function setMaxMainTokenAmountUserCanBuy(uint256 amountOfMainToken)
        public
        onlyOwner
    {
        require(
            amountOfMainToken < 10**19,
            "Invalid amount of the main token.."
        );

        maxAmountOfMainTokenUserCanBuy = amountOfMainToken * 10**16;
    }

    /**
     * Returns buy/sell the ratio of this token (LAST)
     */
    function tokenBuySellRatio() public view returns (uint256) {
        if (totalSell == 0) {
            return 100;
        }
        return totalBuy.mul(100).div(totalSell); // percentage
    }

    /**
     * Returns the buy/sell ratio of the main token in percentage
     * E.g. 200 = 200%
     */
    function originalBuySellRatio() public view returns (uint256) {
        if (mainTokenTotalSell == 0) {
            return 100;
        }
        return mainTokenTotalBuy.mul(100).div(mainTokenTotalSell);
    }

    /**
        Set an address to be tax-free
     */
    function setExcludeFee(address holder, bool exempt) external onlyOwner {
        excludeFee[holder] = exempt;
    }

    /**
        Set an address to be unlimited buy/sell
     */
    function setExcludeMaxTxn(address holder, bool exempt) external onlyOwner {
        excludeMaxTxn[holder] = exempt;
    }

    /**
     *  Withdraw all bnb accidentally sent to this address
     */
    function withdrawAllBNB() external {
        require(msg.sender == safeManager);
        safeManager.transfer(address(this).balance);
    }

    function isNotBlockSell(address sender, address recipient) private view {
        require(
            !blackList[sender] && !blackList[recipient],
            "Address is blacklisted"
        );
    }

    function canSellToken(address sender, uint256 amount) private view {
        require(
            excludeMaxTxn[sender] || sellPressure(amount) < SELL_THRESHOLD,
            "Sell Limit Exceeded"
        );
    }

    function canBuyToken(address buyer, uint256 amount) private view {
        require(
            excludeMaxTxn[buyer] ||
                _balances[buyer].add(amount) <
                getMaxTokenUserCanSwapFromPool(pancakeSwapPair),
            "Buy Limit Exceeded"
        );
    }

    function getPoolInfo()
        public
        view
        returns (
            uint112,
            uint112,
            uint32
        )
    {
        IPancakePair swapPair = IPancakePair(pancakeSwapPair);
        return swapPair.getReserves();
    }

    function getMaxTokenUserCanSwapFromPool(address poolAddress)
        private
        view
        returns (uint256)
    {
        if (poolAddress == DEAD) {
            return _totalSupply;
        }

        IPancakePair swapPair = IPancakePair(poolAddress);

        (uint112 noOfToken0, uint112 noOfToken1, ) = swapPair.getReserves();
        uint112 higher = noOfToken0;
        uint112 lower = noOfToken1;
        if (higher < lower) {
            higher = noOfToken1;
            lower = noOfToken0;
        }
        return (higher * maxAmountOfMainTokenUserCanBuy) / lower;
    }

    function getPriceOfToken(uint256 tokenAmount)
        private
        view
        returns (uint256)
    {
        IPancakePair swapPair = IPancakePair(pancakeSwapPair);

        (uint112 noOfToken0, uint112 noOfToken1, ) = swapPair.getReserves();
        uint112 higher = noOfToken0;
        uint112 lower = noOfToken1;
        if (higher < lower) {
            higher = noOfToken1;
            lower = noOfToken0;
        }

        uint256 amountWithoutDecimal = tokenAmount.div(10**_decimals);
        return (amountWithoutDecimal * lower * 100) / higher;
    }

    function sellPressure(uint256 amount) private view returns (uint256) {
        return totalSell.add(amount).mul(100).div(totalBuy);
    }

    /**
     * Returns the transfer type.
     * 1 if user is buying
     * 2 if user is selling
     * 0 if user do the simple transfer between two wallet.
     */
    function _transferType(address sender, address recipient)
        private
        view
        returns (uint8)
    {
        if (sender.code.length > 0) {
            // in case of the wallet, there's no codee => length = 0.
            return TX_BUY; // buy
        } else if (recipient.code.length > 0) {
            return TX_SELL; // sell
        }

        return 0; // normal transfer
    }

    function calculateFee(
        address sender,
        address recipient,
        uint256 amount
    ) private view returns (uint256) {
        uint8 transferType = _transferType(sender, recipient);
        uint8 taxRate = 0;
        if (transferType == TX_BUY) {
            taxRate = BUY_IN_TAX;
        } else if (transferType == TX_SELL) {
            taxRate = SELL_OUT_TAX;
        }
        uint256 fee = amount.mul(taxRate).div(100);
        return fee;
    }

    function takeFee(address sender, uint256 feeAmount) private {
        _balances[sender] -= feeAmount;
        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);
    }

    // TODO NguyenHuynh: need to remove this
    // this used for mainet testing of eth.
    // we'll remove it on beforem merge into develop
    function initLiquidity(uint256 ethAmount, uint256 thisAmount)
        public
        onlyOwner
    {
        approve(address(router), ethAmount);
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            thisAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function swapBNBToDistributeToken(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = _distributeTokenAddress;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, address(this), block.timestamp);
    }

    // TODO: private this after test
    // Swap THIS token into bnb (eth).
    function swapTokenToBnb() public onlyOwner {
        IBEP20 tokenContract = IBEP20(address(this));
        uint256 amount = _balances[address(this)];
        tokenContract.approve(address(router), amount);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function distributeBnb(address recipient, uint256 amount) private {
        (bool result, ) = payable(recipient).call{value: amount, gas: 30000}(
            ""
        );
        if (result) {
            emit SwapbackSuccess("Distributed successfully!");
        }
    }

    function distributeMainToken(address recipient, uint256 amount) private {
        IBEP20(_distributeTokenAddress).transfer(recipient, amount);
    }

    /**
     * fromToken: address of THIS token
     */
    // TODO: private this after test
    function swapBackAndDistributeDividen() public onlyOwner swapping {
        swapTokenToBnb();

        distributeDividen();
    }

    // TODO Make this function private after test.
    function distributeDividen() public onlyOwner {
        if (_distributeTokenAddress == router.WETH()) {
            // distribute by bnb (eth)
            uint256 bnbBalance = address(this).balance;
            distributeBnb(devAddress, bnbBalance.mul(devDividenRatio).div(100));
            distributeBnb(lpAddress, bnbBalance.mul(lpDividenRatio).div(100));
            distributeBnb(
                manualBuyBackAddress,
                bnbBalance.mul(manualBuyBackDividenRatio).div(100)
            );
            distributeBnb(
                autoBuyBackAddress,
                bnbBalance.mul(autoBuyBackDividenRatio).div(100)
            );
        } else {
            // distribute by any other token
            swapBNBToDistributeToken(address(this).balance);
            IBEP20 distributeContract = IBEP20(_distributeTokenAddress);
            uint256 distributeBalance = distributeContract.balanceOf(
                address(this)
            );
            distributeMainToken(
                devAddress,
                distributeBalance.mul(devDividenRatio).div(100)
            );
            distributeMainToken(
                lpAddress,
                distributeBalance.mul(lpDividenRatio).div(100)
            );
            distributeMainToken(
                manualBuyBackAddress,
                distributeBalance.mul(manualBuyBackDividenRatio).div(100)
            );
            distributeMainToken(
                autoBuyBackAddress,
                distributeBalance.mul(autoBuyBackDividenRatio).div(100)
            );
        }
    }

    event SwapbackSuccess(string message);
    event SwapBackFailed(string message);
    event SwapBNBForTokens(uint256 amount, address[] path);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IPancakePair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: MIT

import "./interfaces/IBEP20.sol";
import "./Ownable.sol";
import "./utils/math/SafeMath.sol";

pragma solidity ^0.8.6;

contract BaseToken is Ownable, IBEP20 {
    using SafeMath for uint256;

    address BNB = 0xB8c77482e45F1F44dE1745F52C74426C631bDD52;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    string _name;
    string _symbol;
    uint8 _decimals;
    uint256 _totalSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        _decimals = decimals_;
    }

    receive() external payable {}

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != ~uint256(0)) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        return _basicTransfer(sender, recipient, amount);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }
}

//SPDX-License-Identifier: MIT

import "./Ownable.sol";

pragma solidity ^0.8.6;

contract SafeToken is Ownable {
    address payable safeManager;

    constructor() {
        safeManager = payable(msg.sender);
    }

    function getSafeManager() public view returns (address) {
        return safeManager;
    }

    function setSafeManager(address payable _safeManager) public onlyOwner {
        safeManager = _safeManager;
    }

    function withdrawBNB(uint256 _amount) external {
        require(msg.sender == safeManager);
        safeManager.transfer(_amount);
    }
}

//SPDX-License-Identifier: MIT

import "./Ownable.sol";

pragma solidity ^0.8.6;

contract LockToken is Ownable {
    bool public isOpen = false;
    mapping(address => bool) private _whiteList;
    modifier open(address from, address to) {
        require(isOpen || _whiteList[from] || _whiteList[to], "Not Open");
        _;
    }

    constructor() {
        _whiteList[msg.sender] = true;
        _whiteList[address(this)] = true;
    }

    function openTrade() external onlyOwner {
        isOpen = true;
    }

    function stopTrade() external onlyOwner {
        isOpen = false;
    }

    function includeToWhiteList(address[] memory _users) external onlyOwner {
        for (uint8 i = 0; i < _users.length; i++) {
            _whiteList[_users[i]] = true;
        }
    }

    function setWhiteList(address user, bool exempt) public onlyOwner {
        _whiteList[user] = exempt;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}