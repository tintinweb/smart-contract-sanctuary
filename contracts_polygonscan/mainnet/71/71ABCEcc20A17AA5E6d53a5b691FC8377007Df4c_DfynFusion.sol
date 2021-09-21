//SPDX-License-Identifier: Unlicense
pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IWETH.sol";
import "./uniswap/Math.sol";

contract DfynFusion is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public apeFeeBps;
    address payable public feeTreasury;
    IWETH public wNative;
    IUniswapV2Router02 public exchangeRouter;
    uint256 public exchangeSwapFeeNumerator; // 3 for Uniswap, 25 for Pancakeswap
    uint256 public exchangeSwapFeeDenominator; // 1000 for Uniswap, 10000 for Pancakeswap
    uint256 MAX;

    constructor(
        uint256 _apeFeeBps,
        address payable _feeTreasury,
        address _exchangeRouter,
        address _wNative,
        uint256 _exchangeSwapFeeNumerator,
        uint256 _exchangeSwapFeeDenominator
    ) public {
        apeFeeBps = _apeFeeBps;
        feeTreasury = _feeTreasury;
        exchangeRouter = IUniswapV2Router02(_exchangeRouter);
        wNative = IWETH(_wNative);
        exchangeSwapFeeNumerator = _exchangeSwapFeeNumerator;
        exchangeSwapFeeDenominator = _exchangeSwapFeeDenominator;
        MAX = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }

    receive() external payable {}

    struct InputToken {
        address token;
        uint256 amount;
        address[] tokenToNativePath;
    }

    struct InputLP {
        address token;
        uint256 amount;
        address[] token0ToNativePath;
        address[] token1ToNativePath;
    }

    function transferNativeFeeToTreasury(uint256 amount)
        private
        returns (uint256)
    {
        if (apeFeeBps == 0) {
            return amount;
        }
        uint256 fee = apeFeeBps.mul(amount).div(10000);
        TransferHelper.safeTransferETH(feeTreasury, fee);
        return amount.sub(fee);
    }

    function transferTokenFeeToTreasury(address token, uint256 amount)
        private
        returns (uint256)
    {
        if (apeFeeBps == 0) {
            return amount;
        }
        uint256 fee = apeFeeBps.mul(amount).div(10000);
        IERC20(token).safeTransfer(feeTreasury, fee);
        return amount.sub(fee);
    }

    function swapTokensToNative(
        InputToken[] memory inputTokens,
        InputLP[] memory inputLPs,
        uint256 minOutputAmount
    ) public payable {
        if (inputLPs.length > 0) {
            _transferTokensToApe(inputLPs);
            _swapTokensForWNative(_removeLiquidity(inputLPs));
        }
        if (inputTokens.length > 0) {
            _transferTokensToApe(inputTokens);
            _swapTokensForWNative(inputTokens);
        }
        uint256 wNativeBalance = wNative.balanceOf(address(this));
        wNative.withdraw(wNativeBalance);
        uint256 amountOut = wNativeBalance.add(msg.value);
        amountOut = transferNativeFeeToTreasury(amountOut);
        require(
            amountOut >= minOutputAmount,
            "Expect amountOut to be greater than minOutputAmount."
        );
        TransferHelper.safeTransferETH(msg.sender, amountOut);
    }

    function swapTokensToToken(
        InputToken[] memory inputTokens,
        InputLP[] memory inputLPs,
        address[] memory nativeToOutputPath,
        uint256 minOutputAmount
    ) public payable {
        if (msg.value > 0) {
            wNative.deposit{value: msg.value}();
        }
        if (inputLPs.length > 0) {
            _transferTokensToApe(inputLPs);
            _swapTokensForWNative(_removeLiquidity(inputLPs));
        }
        if (inputTokens.length > 0) {
            _transferTokensToApe(inputTokens);
            _swapTokensForWNative(inputTokens);
        }
        uint256 wNativeBalance = wNative.balanceOf(address(this));
        uint256 amountOut = _swapWNativeForToken(
            wNativeBalance,
            nativeToOutputPath
        );
        amountOut = transferTokenFeeToTreasury(
            nativeToOutputPath[nativeToOutputPath.length - 1],
            amountOut
        );
        require(
            amountOut >= minOutputAmount,
            "Expect amountOut to be greater than minOutputAmount."
        );
        IERC20(nativeToOutputPath[nativeToOutputPath.length - 1]).safeTransfer(
            msg.sender,
            amountOut
        );
    }

    function swapTokensToLP(
        InputToken[] memory inputTokens,
        InputLP[] memory inputLPs,
        address[] memory nativeToToken0Path,
        address[] memory nativeToToken1Path,
        address outputLP,
        uint256 minOutputAmount
    ) public payable {
        address token0 = IUniswapV2Pair(outputLP).token0();
        address token1 = IUniswapV2Pair(outputLP).token1();
        if (msg.value > 0) {
            wNative.deposit{value: msg.value}();
        }
        if (inputLPs.length > 0) {
            _transferTokensToApe(inputLPs);
            _swapTokensForWNativeExcept(
                _removeLiquidity(inputLPs),
                token0,
                token1
            );
        }
        if (inputTokens.length > 0) {
            _transferTokensToApe(inputTokens);
            _swapTokensForWNativeExcept(inputTokens, token0, token1);
        }
        uint256 wNativeBalance = wNative.balanceOf(address(this));
        _swapWNativeForToken(wNativeBalance.div(2), nativeToToken0Path);
        _swapWNativeForToken(
            wNativeBalance.sub(wNativeBalance.div(2)),
            nativeToToken1Path
        );
        uint256 amountOut = _optimalSwapToLp(
            outputLP,
            token0,
            token1,
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this))
        );
        amountOut = transferTokenFeeToTreasury(outputLP, amountOut);
        require(
            amountOut >= minOutputAmount,
            "Expect amountOut to be greater than minOutputAmount."
        );
        IERC20(outputLP).safeTransfer(msg.sender, amountOut);
    }

    // Token version
    function _transferTokensToApe(InputToken[] memory inputTokens)
        private
        returns (uint256[] memory)
    {
        uint256[] memory outputAmounts = new uint256[](inputTokens.length);
        for (uint256 i = 0; i < inputTokens.length; i++) {
            IERC20(inputTokens[i].token).safeTransferFrom(
                msg.sender,
                address(this),
                inputTokens[i].amount
            );
            outputAmounts[i] = inputTokens[i].amount;
        }
        return outputAmounts;
    }

    // LP version
    function _transferTokensToApe(InputLP[] memory inputLPs)
        private
        returns (uint256[] memory)
    {
        uint256[] memory outputAmounts = new uint256[](inputLPs.length);
        for (uint256 i = 0; i < inputLPs.length; i++) {
            IERC20(inputLPs[i].token).safeTransferFrom(
                msg.sender,
                address(this),
                inputLPs[i].amount
            );
            outputAmounts[i] = inputLPs[i].amount;
        }
        return outputAmounts;
    }

    function _removeLiquidity(InputLP[] memory inputLPs)
        private
        returns (InputToken[] memory)
    {
        InputToken[] memory outputTokens = new InputToken[](
            inputLPs.length * 2
        );
        for (uint256 i = 0; i < inputLPs.length; i++) {
            IERC20(inputLPs[i].token).approve(address(exchangeRouter), MAX);
            (uint256 amount0, uint256 amount1) = exchangeRouter.removeLiquidity(
                inputLPs[i].token0ToNativePath[0],
                inputLPs[i].token1ToNativePath[0],
                inputLPs[i].amount,
                0,
                0,
                address(this),
                now + 60
            );
            outputTokens[i * 2] = InputToken(
                inputLPs[i].token0ToNativePath[0],
                amount0,
                inputLPs[i].token0ToNativePath
            );
            outputTokens[(i * 2) + 1] = InputToken(
                inputLPs[i].token1ToNativePath[0],
                amount1,
                inputLPs[i].token1ToNativePath
            );
        }
        return outputTokens;
    }

    function _swapTokensForWNative(InputToken[] memory inputTokens)
        private
        returns (uint256)
    {
        uint256 totalNative = 0;
        for (uint256 i = 0; i < inputTokens.length; i++) {
            // Swap non wNative token
            if (inputTokens[i].token != address(wNative)) {
                IERC20(inputTokens[i].token).approve(
                    address(exchangeRouter),
                    MAX
                );
                uint256[] memory amountOuts = exchangeRouter
                    .swapExactTokensForTokens(
                        inputTokens[i].amount,
                        0,
                        inputTokens[i].tokenToNativePath,
                        address(this),
                        now + 60
                    );
                totalNative = totalNative.add(
                    amountOuts[amountOuts.length - 1]
                );
            }
        }
        return totalNative;
    }

    function _swapTokensForWNativeExcept(
        InputToken[] memory inputTokens,
        address token0,
        address token1
    ) private returns (uint256) {
        uint256 totalNative = 0;
        for (uint256 i = 0; i < inputTokens.length; i++) {
            // Skip token0, token1 and wNative
            if (
                inputTokens[i].token != token0 &&
                inputTokens[i].token != token1 &&
                inputTokens[i].token != address(wNative)
            ) {
                IERC20(inputTokens[i].token).approve(
                    address(exchangeRouter),
                    MAX
                );
                uint256[] memory amountOuts = exchangeRouter
                    .swapExactTokensForTokens(
                        inputTokens[i].amount,
                        0,
                        inputTokens[i].tokenToNativePath,
                        address(this),
                        now + 60
                    );
                totalNative = totalNative.add(
                    amountOuts[amountOuts.length - 1]
                );
            }
        }
        return totalNative;
    }

    function _swapWNativeForToken(uint256 amount, address[] memory path)
        private
        returns (uint256)
    {
        if (amount == 0 || path[path.length - 1] == address(wNative)) {
            return amount;
        }
        wNative.approve(address(exchangeRouter), MAX);
        uint256[] memory amountOuts = exchangeRouter.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            now + 60
        );
        return amountOuts[amountOuts.length - 1];
    }

    function _optimalSwapToLp(
        address outputLP,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) private returns (uint256) {
        IERC20(token0).approve(address(exchangeRouter), MAX);
        IERC20(token1).approve(address(exchangeRouter), MAX);
        (
            uint256 token0Amount,
            uint256 token1Amount
        ) = _optimalSwapForAddingLiquidity(
                outputLP,
                token0,
                token1,
                amount0,
                amount1
            );
        (
            uint256 addedToken0,
            uint256 addedToken1,
            uint256 lpAmount
        ) = exchangeRouter.addLiquidity(
                token0,
                token1,
                token0Amount,
                token1Amount,
                0,
                0,
                address(this),
                now + 60
            );

        // Transfer dust
        if (token0Amount.sub(addedToken0) > 0) {
            IERC20(token0).safeTransfer(
                msg.sender,
                token0Amount.sub(addedToken0)
            );
        }

        if (token1Amount.sub(addedToken1) > 0) {
            IERC20(token1).safeTransfer(
                msg.sender,
                token1Amount.sub(addedToken1)
            );
        }

        return lpAmount;
    }

    function _optimalSwapForAddingLiquidity(
        address lp,
        address token0,
        address token1,
        uint256 token0Amount,
        uint256 token1Amount
    ) private returns (uint256, uint256) {
        (uint256 res0, uint256 res1, ) = IUniswapV2Pair(lp).getReserves();
        if (res0.mul(token1Amount) == res1.mul(token0Amount)) {
            return (token0Amount, token1Amount);
        }

        bool reverse = token0Amount.mul(res1) < token1Amount.mul(res0);

        uint256 optimalSwapAmount = reverse
            ? calculateOptimalSwapAmount(token1Amount, token0Amount, res1, res0)
            : calculateOptimalSwapAmount(
                token0Amount,
                token1Amount,
                res0,
                res1
            );

        address[] memory path = new address[](2);
        (path[0], path[1]) = reverse ? (token1, token0) : (token0, token1);
        if (optimalSwapAmount > 0) {
            uint256[] memory amountOuts = exchangeRouter
                .swapExactTokensForTokens(
                    optimalSwapAmount,
                    0,
                    path,
                    address(this),
                    now + 60
                );
            if (reverse) {
                token0Amount = token0Amount.add(
                    amountOuts[amountOuts.length - 1]
                );
                token1Amount = token1Amount.sub(optimalSwapAmount);
            } else {
                token0Amount = token0Amount.sub(optimalSwapAmount);
                token1Amount = token1Amount.add(
                    amountOuts[amountOuts.length - 1]
                );
            }
        }

        return (token0Amount, token1Amount);
    }

    function calculateOptimalSwapAmount(
        uint256 amtA,
        uint256 amtB,
        uint256 resA,
        uint256 resB
    ) public view returns (uint256) {
        require(
            amtA.mul(resB) >= amtB.mul(resA),
            "Expect amtA value to be greater than amtB value"
        );

        uint256 a = exchangeSwapFeeDenominator.sub(exchangeSwapFeeNumerator);
        uint256 b = uint256(
            exchangeSwapFeeDenominator.mul(2).sub(exchangeSwapFeeNumerator)
        ).mul(resA);
        uint256 _c = (amtA.mul(resB)).sub(amtB.mul(resA));
        uint256 c = _c.mul(exchangeSwapFeeDenominator).div(amtB.add(resB)).mul(
            resA
        );

        uint256 d = a.mul(c).mul(4);
        uint256 e = Math.sqrt(b.mul(b).add(d));

        uint256 numerator = e.sub(b);
        uint256 denominator = a.mul(2);

        return numerator.div(denominator);
    }

    function getWNativeToTokenAmount(
        uint256 wNativeAmount,
        address[] memory nativeToOutputPath
    ) public view returns (uint256) {
        if (wNativeAmount == 0) {
            return 0;
        }
        if (
            nativeToOutputPath[nativeToOutputPath.length - 1] ==
            address(wNative)
        ) {
            uint256 output = wNativeAmount;
            uint256 fee = apeFeeBps.mul(output).div(10000);
            return output.sub(fee);
        }
        uint256[] memory amountOuts = exchangeRouter.getAmountsOut(
            wNativeAmount,
            nativeToOutputPath
        );
        uint256 output = amountOuts[amountOuts.length - 1];
        uint256 fee = apeFeeBps.mul(output).div(10000);
        return output.sub(fee);
    }

    function getWNativeToLpAmount(
        uint256 wNativeAmount,
        address[] memory nativeToToken0Path,
        address[] memory nativeToToken1Path
    ) public view returns (uint256) {
        if (wNativeAmount == 0) {
            return 0;
        }
        address token0 = nativeToToken0Path[nativeToToken0Path.length - 1];
        address token1 = nativeToToken1Path[nativeToToken1Path.length - 1];
        address lp = IUniswapV2Factory(exchangeRouter.factory()).getPair(
            token0,
            token1
        );
        uint256 token0Amount;
        uint256 token1Amount;

        // STEP 1: Swap wNative to token0 and token1
        if (
            nativeToToken0Path[nativeToToken0Path.length - 1] ==
            address(wNative)
        ) {
            token0Amount = wNativeAmount.div(2);
        } else {
            uint256[] memory amountOuts0 = exchangeRouter.getAmountsOut(
                wNativeAmount.div(2),
                nativeToToken0Path
            );
            token0Amount = amountOuts0[amountOuts0.length - 1];
        }

        if (
            nativeToToken1Path[nativeToToken1Path.length - 1] ==
            address(wNative)
        ) {
            token1Amount = wNativeAmount.div(2);
        } else {
            uint256[] memory amountOuts1 = exchangeRouter.getAmountsOut(
                wNativeAmount.div(2),
                nativeToToken1Path
            );
            token1Amount = amountOuts1[amountOuts1.length - 1];
        }

        // STEP 2: Optimal swap for adding liquidity
        (uint256 res0, uint256 res1, ) = IUniswapV2Pair(lp).getReserves();
        if (res0.mul(token1Amount) != res1.mul(token0Amount)) {
            bool reverse = token0Amount.mul(res1) < token1Amount.mul(res0);
            uint256 swapAmount = reverse
                ? calculateOptimalSwapAmount(
                    token1Amount,
                    token0Amount,
                    res1,
                    res0
                )
                : calculateOptimalSwapAmount(
                    token0Amount,
                    token1Amount,
                    res0,
                    res1
                );

            address[] memory swapPath = new address[](2);
            if (reverse) {
                swapPath[0] = token1;
                swapPath[1] = token0;
            } else {
                swapPath[0] = token0;
                swapPath[1] = token1;
            }
            uint256[] memory optimalSwapAmountOuts = exchangeRouter
                .getAmountsOut(swapAmount, swapPath);
            uint256 optimalSwapAmountOut = optimalSwapAmountOuts[
                optimalSwapAmountOuts.length - 1
            ];
            if (reverse) {
                token0Amount = token0Amount.add(optimalSwapAmountOut);
                token1Amount = token1Amount.sub(swapAmount);
                res0 = res0.sub(optimalSwapAmountOut);
                res1 = res1.add(swapAmount);
            } else {
                token0Amount = token0Amount.sub(swapAmount);
                token1Amount = token1Amount.add(optimalSwapAmountOut);
                res0 = res0.add(swapAmount);
                res1 = res1.sub(optimalSwapAmountOut);
            }
        }

        // STEP 3: Calculate lp token output
        uint256 totalSupply = IUniswapV2Pair(lp).totalSupply();
        uint256 outputOptimal0 = token0Amount.mul(totalSupply).div(res0);
        uint256 outputOptimal1 = token1Amount.mul(totalSupply).div(res1);

        uint256 output = outputOptimal0 > outputOptimal1
            ? outputOptimal1
            : outputOptimal0;

        // STEP 4: Calculate fee
        uint256 fee = apeFeeBps.mul(output).div(10000);
        return output.sub(fee);
    }

    function setApeFeeBps(uint256 _apeFeeBps) public onlyOwner {
        apeFeeBps = _apeFeeBps;
    }

    function setFeeTreasury(address _feeTreasury) public onlyOwner {
        feeTreasury = payable(_feeTreasury);
    }

    function setExchange(
        address router,
        uint256 _exchangeSwapFeeNumerator,
        uint256 _exchangeSwapFeeDenominator
    ) public onlyOwner {
        exchangeRouter = IUniswapV2Router02(router);
        exchangeSwapFeeNumerator = _exchangeSwapFeeNumerator;
        exchangeSwapFeeDenominator = _exchangeSwapFeeDenominator;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity >=0.5.16;

// a library for performing various math operations

library Math {
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

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}