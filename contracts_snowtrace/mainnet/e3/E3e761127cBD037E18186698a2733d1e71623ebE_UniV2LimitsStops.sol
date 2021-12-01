pragma solidity 0.8.6;


import "IERC20.sol";
import "Ownable.sol";
import "SafeERC20.sol";
import "IUniswapV2Router02.sol";


// Comments referenced throughout
// *1:
// Reduce amountOutMin proportionally so that the price of execution is the same
// as what was intended by the user. This is done so that the trade executes at
// the price intended by the user, even though they'll receive less than if
// that'd market bought/sold at that price (because they pay for the execution
// in regular ETH tx fees with normal Uniswap market orders). The naive way is
// to do the trade, then take the output token, and trade some of that for
// whatever the fee is paid in - this will execute at the intended price, but
// is gas inefficient because it then requires sending the output tokens here
// (and then requiring an additional transfer to the user), rather than inputing
// the recipient into the Uniswap trade. Instead, we can have 2 Uniswap trades
// (in the worst case scenario where the fee token isn't one of the traded tokens)
// that sends the fee in the 1st, and reduce amountOutMin in the 2nd proportional
// to the fees spent, such that the total execution price is the same as what was
// intended by the user, even though there are fewer input tokens to spend on the
// trade
// *2:
// Can't do `tradeInput = (inputAmount - inputSpentOnFee)` because of stack too deep


/**
* @title    UniV2LimitsStops
* @notice   Wraps around an arbitrary UniV2 router contract and adds conditions
*           of price to create limit orders and stop losses. Ensures that
*           only a specific user can call a trade because the Autonomy Registry
*           forces that the first argument of the calldata is the user's address
*           and this contract knows that condition is true when the call is coming
*           from an appropriate proxy
* @author   Quantaf1re (James Key)
*/
contract UniV2LimitsStops is Ownable {

    using SafeERC20 for IERC20;

    address payable public immutable registry;
    address public immutable userVeriForwarder;
    address public immutable userFeeVeriForwarder;
    address public immutable WETH;
    FeeInfo private _defaultFeeInfo;
    uint256 private constant MAX_UINT = type(uint256).max;


    constructor(
        address payable registry_,
        address userVeriForwarder_,
        address userFeeVeriForwarder_,
        address WETH_,
        FeeInfo memory defaultFeeInfo
    ) Ownable() {
        registry = registry_;
        userVeriForwarder = userVeriForwarder_;
        userFeeVeriForwarder = userFeeVeriForwarder_;
        WETH = WETH_;
        _defaultFeeInfo = defaultFeeInfo;
    }


    struct FeeInfo {
        // Need a known instance of UniV2 that is guaranteed to have the token
        // that the default fee is paid in, along with enough liquidity, since
        // an arbitrary instance of UniV2 is passed to fcns in this contract
        IUniswapV2Router02 uni;
        address[] path;
        // Whether or not the fee token is AUTO, because that needs to
        // get sent to the user, since `transferFrom` is used from them directly
        // in the Registry to charge the fee
        bool isAUTO;
    }

    // Hold arguments for calling Uniswap to avoid stack to deep errors
    struct UniArgs{
        uint inputAmount;
        uint amountOutMin;
        uint amountOutMax;
        address[] path;
        uint deadline;
    }


    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
    ////                                                          ////
    ////-----------------------ETH to token-----------------------////
    ////                                                          ////
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////

    /**
     * @notice  Only calls swapExactAVAXForTokens if the output is above
     *          `amountOutMin` and below `amountOutMax`. `amountOutMax`
     *          is the 'stop price' when used as a stop loss, and
     *          `amountOutMin` is the 'limit price' when used as a limit
     *          order. When using this as a classic limit order, `amountOutMax`
     *          would be sent to the max uint value. When using this
     *          as a classic stop loss, `amountOutMin` would be set to 0.
     *          The min/max can also be used to limit downside during flash
     *          crashes, e.g. `amountOutMin` could be set to 10% lower then
     *          `amountOutMax` for a stop loss, if desired.
     */
    function ethToTokenRange(
        uint maxGasPrice,
        IUniswapV2Router02 uni,
        uint amountOutMin,
        uint amountOutMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable gasPriceCheck(maxGasPrice) {
        uint[] memory amounts = uni.swapExactAVAXForTokens{value: msg.value}(amountOutMin, path, to, deadline);
        require(amounts[amounts.length-1] <= amountOutMax, "LimitsStops: price too high");
    }

    function _ethToTokenPayDefault(
        address user,
        uint feeAmount,
        IUniswapV2Router02 uni,
        UniArgs memory uniArgs
    ) private {
        FeeInfo memory feeInfo = _defaultFeeInfo;
        if (feeInfo.isAUTO) {
            feeInfo.path[0] = WETH;
        }

        _ethToTokenPaySpecific(user, feeAmount, uni, feeInfo, uniArgs);
    }

    function _ethToTokenPaySpecific(
        address user,
        uint feeAmount,
        IUniswapV2Router02 uni,
        FeeInfo memory feeInfo,
        UniArgs memory uniArgs
    ) private {
        // Pay the execution fee
        uint tradeInput = msg.value;
        if (feeInfo.isAUTO) {
            tradeInput -= feeInfo.uni.swapAVAXForExactTokens{value: msg.value}(
                feeAmount,
                feeInfo.path,
                user,
                uniArgs.deadline
            )[0];
        } else {
            registry.transfer(feeAmount);
            tradeInput -= feeAmount;
        }

        // *1, *2
        uint[] memory amounts = uni.swapExactAVAXForTokens{value: tradeInput}(
            uniArgs.amountOutMin * tradeInput / msg.value,
            uniArgs.path,
            user,
            uniArgs.deadline
        );

        require(amounts[amounts.length-1] <= uniArgs.amountOutMax * tradeInput / msg.value, "LimitsStops: price too high");
    }

    /**
     * @notice  Only calls swapExactAVAXForTokens if the output is above
     *          `amountOutMin` and below `amountOutMax`. `amountOutMax`
     *          is the 'stop price' when used as a stop loss, and
     *          `amountOutMin` is the 'limit price' when used as a limit
     *          order. When using this as a classic limit order, `amountOutMax`
     *          would be sent to the max uint value. When using this
     *          as a classic stop loss, `amountOutMin` would be set to 0.
     *          The min/max can also be used to limit downside during flash
     *          crashes, e.g. `amountOutMin` could be set to 10% lower then
     *          `amountOutMax` for a stop loss, if desired. Additionally, 
     *          takes part of the trade and uses it to pay `feeAmount`,
     *          in the default fee token, to the registry
     */
    function ethToTokenRangePayDefault(
        address user,
        uint feeAmount,
        uint maxGasPrice,
        IUniswapV2Router02 uni,
        uint amountOutMin,
        uint amountOutMax,
        address[] calldata path,
        uint deadline
    ) external payable gasPriceCheck(maxGasPrice) userFeeVerified {
        _ethToTokenPayDefault(
            user,
            feeAmount,
            uni,
            UniArgs(0, amountOutMin, amountOutMax, path, deadline)
        );
    }

    /**
     * @notice  Only calls swapExactAVAXForTokens if the output is above
     *          `amountOutMin` and below `amountOutMax`. `amountOutMax`
     *          is the 'stop price' when used as a stop loss, and
     *          `amountOutMin` is the 'limit price' when used as a limit
     *          order. When using this as a classic limit order, `amountOutMax`
     *          would be sent to the max uint value. When using this
     *          as a classic stop loss, `amountOutMin` would be set to 0.
     *          The min/max can also be used to limit downside during flash
     *          crashes, e.g. `amountOutMin` could be set to 10% lower then
     *          `amountOutMax` for a stop loss, if desired. Additionally, 
     *          takes part of the trade and uses it to pay `feeAmount`,
     *          in the specified fee token, to the registry.
     *          WARNING: only use this if you want to do things non-standard
     */
    function ethToTokenRangePaySpecific(
        address user,
        uint feeAmount,
        uint maxGasPrice,
        IUniswapV2Router02 uni,
        FeeInfo memory feeInfo,
        uint amountOutMin,
        uint amountOutMax,
        address[] calldata path,
        uint deadline
    ) external payable gasPriceCheck(maxGasPrice) userFeeVerified {
        _ethToTokenPaySpecific(
            user,
            feeAmount,
            uni,
            feeInfo,
            UniArgs(0, amountOutMin, amountOutMax, path, deadline)
        );
    }


    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
    ////                                                          ////
    ////-----------------------Token to ETH-----------------------////
    ////                                                          ////
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////

    /**
     * @notice  Only calls swapExactTokensForAVAX if the output is above
     *          `amountOutMin` and below `amountOutMax`. `amountOutMax`
     *          is the 'stop price' when used as a stop loss, and
     *          `amountOutMin` is the 'limit price' when used as a limit
     *          order. When using this as a classic limit order, `amountOutMax`
     *          would be sent to the max uint value. When using this
     *          as a classic stop loss, `amountOutMin` would be set to 0.
     *          The min/max can also be used to limit downside during flash
     *          crashes, e.g. `amountOutMin` could be set to 10% lower then
     *          `amountOutMax` for a stop loss, if desired.
     */
    function tokenToEthRange(
        address user,
        uint maxGasPrice,
        IUniswapV2Router02 uni,
        uint inputAmount,
        uint amountOutMin,
        uint amountOutMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external gasPriceCheck(maxGasPrice) userVerified {
        transferApproveUnapproved(uni, path[0], inputAmount, user);
        uint[] memory amounts = uni.swapExactTokensForAVAX(inputAmount, amountOutMin, path, to, deadline);
        require(amounts[amounts.length-1] <= amountOutMax, "LimitsStops: price too high");
    }

    function _tokenToEthPayDefault(
        address user,
        uint feeAmount,
        IUniswapV2Router02 uni,
        UniArgs memory uniArgs
    ) private {
        FeeInfo memory feeInfo = _defaultFeeInfo;
        // The fee path only needs to be modified when not paying in ETH (since
        // the output of the trade is ETH and that can be used) and when the input
        // token isn't AUTO anyway (since that can be used without a 2nd trade)
        if (feeInfo.isAUTO && uniArgs.path[0] != feeInfo.path[feeInfo.path.length-1]) {
            address[] memory newFeePath = new address[](3);
            newFeePath[0] = uniArgs.path[0];               // src token
            newFeePath[1] = WETH;   // WETH_ since path in tokenToETH ends in WETH_
            newFeePath[2] = feeInfo.path[feeInfo.path.length-1];   // AUTO since feePath here ends in AUTO
            feeInfo.path = newFeePath;
        }

        _tokenToEthPaySpecific(user, feeAmount, uni, feeInfo, uniArgs);
    }

    function _tokenToEthPaySpecific(
        address user,
        uint feeAmount,
        IUniswapV2Router02 uni,
        FeeInfo memory feeInfo,
        UniArgs memory uniArgs
    ) private {
        // Pay the execution fee
        uint tradeInput = uniArgs.inputAmount;
        if (feeInfo.isAUTO) {
            // If the src token is AUTO
            if (uniArgs.path[0] == feeInfo.path[feeInfo.path.length-1]) {
                // The user already holds inputAmount of AUTO, so don't move them
                tradeInput -= feeAmount;
                transferApproveUnapproved(uni, uniArgs.path[0], tradeInput, user);
            } else {
                transferApproveUnapproved(uni, uniArgs.path[0], uniArgs.inputAmount, user);
                approveUnapproved(feeInfo.uni, uniArgs.path[0], uniArgs.inputAmount);
                tradeInput -= feeInfo.uni.swapTokensForExactTokens(feeAmount, uniArgs.inputAmount, feeInfo.path, user, uniArgs.deadline)[0];
            }
        } else {
            transferApproveUnapproved(uni, uniArgs.path[0], uniArgs.inputAmount, user);
        }

        // *1, *2
        uint[] memory amounts = uni.swapExactTokensForAVAX(
            tradeInput,
            uniArgs.amountOutMin * tradeInput / uniArgs.inputAmount,
            uniArgs.path,
            // Sending it all to the registry means that the fee will be kept
            // (if it's in ETH) and the excess sent to the user
            feeInfo.isAUTO ? user : registry,
            uniArgs.deadline
        );
        require(amounts[amounts.length-1] <= uniArgs.amountOutMax * tradeInput / uniArgs.inputAmount, "LimitsStops: price too high");
    }

    /**
     * @notice  Only calls swapExactTokensForAVAX if the output is above
     *          `amountOutMin` and below `amountOutMax`. `amountOutMax`
     *          is the 'stop price' when used as a stop loss, and
     *          `amountOutMin` is the 'limit price' when used as a limit
     *          order. When using this as a classic limit order, `amountOutMax`
     *          would be sent to the max uint value. When using this
     *          as a classic stop loss, `amountOutMin` would be set to 0.
     *          The min/max can also be used to limit downside during flash
     *          crashes, e.g. `amountOutMin` could be set to 10% lower then
     *          `amountOutMax` for a stop loss, if desired. Additionally, 
     *          takes part of the trade and uses it to pay `feeAmount`,
     *          in the default fee token, to the registry
     */
    function tokenToEthRangePayDefault(
        address user,
        uint feeAmount,
        uint maxGasPrice,
        IUniswapV2Router02 uni,
        uint inputAmount,
        uint amountOutMin,
        uint amountOutMax,
        address[] calldata path,
        uint deadline
    ) external gasPriceCheck(maxGasPrice) userFeeVerified {
        _tokenToEthPayDefault(
            user,
            feeAmount,
            uni,
            UniArgs(inputAmount, amountOutMin, amountOutMax, path, deadline)
        );
    }

    /**
     * @notice  Only calls swapExactTokensForAVAX if the output is above
     *          `amountOutMin` and below `amountOutMax`. `amountOutMax`
     *          is the 'stop price' when used as a stop loss, and
     *          `amountOutMin` is the 'limit price' when used as a limit
     *          order. When using this as a classic limit order, `amountOutMax`
     *          would be sent to the max uint value. When using this
     *          as a classic stop loss, `amountOutMin` would be set to 0.
     *          The min/max can also be used to limit downside during flash
     *          crashes, e.g. `amountOutMin` could be set to 10% lower then
     *          `amountOutMax` for a stop loss, if desired. Additionally, 
     *          takes part of the trade and uses it to pay `feeAmount`,
     *          in the specified fee token, to the registry.
     *          WARNING: only use this if you want to do things non-standard
     */
    function tokenToEthRangePaySpecific(
        address user,
        uint feeAmount,
        uint maxGasPrice,
        IUniswapV2Router02 uni,
        FeeInfo memory feeInfo,
        uint inputAmount,
        uint amountOutMin,
        uint amountOutMax,
        address[] calldata path,
        uint deadline
    ) external gasPriceCheck(maxGasPrice) userFeeVerified {
        _tokenToEthPaySpecific(
            user,
            feeAmount,
            uni,
            feeInfo,
            UniArgs(inputAmount, amountOutMin, amountOutMax, path, deadline)
        );
    }

    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
    ////                                                          ////
    ////----------------------Token to token----------------------////
    ////                                                          ////
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////

    /**
     * @notice  Only calls swapExactTokensForTokens if the output is above
     *          `amountOutMin` and below `amountOutMax`. `amountOutMax`
     *          is the 'stop price' when used as a stop loss, and
     *          `amountOutMin` is the 'limit price' when used as a limit
     *          order. When using this as a classic limit order, `amountOutMax`
     *          would be sent to the max uint value. When using this
     *          as a classic stop loss, `amountOutMin` would be set to 0.
     *          The min/max can also be used to limit downside during flash
     *          crashes, e.g. `amountOutMin` could be set to 10% lower then
     *          `amountOutMax` for a stop loss, if desired.
     */
    function tokenToTokenRange(
        address user,
        uint maxGasPrice,
        IUniswapV2Router02 uni,
        uint inputAmount,
        uint amountOutMin,
        uint amountOutMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external gasPriceCheck(maxGasPrice) userVerified {
        transferApproveUnapproved(uni, path[0], inputAmount, user);
        uint[] memory amounts = uni.swapExactTokensForTokens(inputAmount, amountOutMin, path, to, deadline);
        require(amounts[amounts.length-1] <= amountOutMax, "LimitsStops: price too high");
    }

    function _tokenToTokenPayDefault(
        address user,
        uint feeAmount,
        IUniswapV2Router02 uni,
        UniArgs memory uniArgs
    ) private {
        FeeInfo memory feeInfo = _defaultFeeInfo;
        // The fee path only needs to be modified when the src/dest tokens aren't
        // AUTO (if paying in AUTO), and when paying in ETH
        if (feeInfo.isAUTO && uniArgs.path[0] != feeInfo.path[feeInfo.path.length-1]) {
            address[] memory newFeePath = new address[](3);
            newFeePath[0] = uniArgs.path[0];                // src token
            newFeePath[1] = WETH;                  // WETH_ since path in tokenToETH ends in WETH_
            newFeePath[2] = feeInfo.path[feeInfo.path.length-1];   // AUTO since feePath here ends in AUTO
            feeInfo.path = newFeePath;
        } else if (!feeInfo.isAUTO) {
            feeInfo.path[0] = uniArgs.path[0];
        }

        _tokenToTokenPaySpecific(user, feeAmount, uni, feeInfo, uniArgs);
    }

    function _tokenToTokenPaySpecific(
        address user,
        uint feeAmount,
        IUniswapV2Router02 uni,
        FeeInfo memory feeInfo,
        UniArgs memory uniArgs
    ) private {
        // Pay the execution fee
        uint tradeInput = uniArgs.inputAmount;
        if (feeInfo.isAUTO) {
            // If the src token is AUTO
            if (uniArgs.path[0] == feeInfo.path[feeInfo.path.length-1]) {
                // The user already holds inputAmount of AUTO
                tradeInput -= feeAmount;
                transferApproveUnapproved(uni, uniArgs.path[0], tradeInput, user);
            // If the dest token is AUTO
            } else if (uniArgs.path[uniArgs.path.length-1] == feeInfo.path[feeInfo.path.length-1]) {
                // Do nothing because it'll all get sent to the user, and the
                // fee will be taken from them after that
                transferApproveUnapproved(uni, uniArgs.path[0], uniArgs.inputAmount, user);
            } else {
                transferApproveUnapproved(uni, uniArgs.path[0], uniArgs.inputAmount, user);
                approveUnapproved(feeInfo.uni, uniArgs.path[0], uniArgs.inputAmount);
                tradeInput -= feeInfo.uni.swapTokensForExactTokens(feeAmount, uniArgs.inputAmount, feeInfo.path, user, uniArgs.deadline)[0];
            }
        } else {
            transferApproveUnapproved(uni, uniArgs.path[0], uniArgs.inputAmount, user);
            approveUnapproved(feeInfo.uni, uniArgs.path[0], uniArgs.inputAmount);
            tradeInput -= feeInfo.uni.swapTokensForExactAVAX(feeAmount, uniArgs.inputAmount, feeInfo.path, registry, uniArgs.deadline)[0];
        }

        // *1, *2
        uint[] memory amounts = uni.swapExactTokensForTokens(
            tradeInput,
            uniArgs.amountOutMin * tradeInput / uniArgs.inputAmount,
            uniArgs.path,
            user,
            uniArgs.deadline
        );
        require(amounts[amounts.length-1] <= uniArgs.amountOutMax * tradeInput / uniArgs.inputAmount, "LimitsStops: price too high");
    }

    /**
     * @notice  Only calls swapExactTokensForTokens if the output is above
     *          `amountOutMin` and below `amountOutMax`. `amountOutMax`
     *          is the 'stop price' when used as a stop loss, and
     *          `amountOutMin` is the 'limit price' when used as a limit
     *          order. When using this as a classic limit order, `amountOutMax`
     *          would be sent to the max uint value. When using this
     *          as a classic stop loss, `amountOutMin` would be set to 0.
     *          The min/max can also be used to limit downside during flash
     *          crashes, e.g. `amountOutMin` could be set to 10% lower then
     *          `amountOutMax` for a stop loss, if desired. Additionally, 
     *          takes part of the trade and uses it to pay `feeAmount`,
     *          in the default fee token, to the registry
     */
    function tokenToTokenRangePayDefault(
        address user,
        uint feeAmount,
        uint maxGasPrice,
        IUniswapV2Router02 uni,
        uint inputAmount,
        uint amountOutMin,
        uint amountOutMax,
        address[] calldata path,
        uint deadline
    ) external gasPriceCheck(maxGasPrice) userFeeVerified {
        _tokenToTokenPayDefault(
            user,
            feeAmount,
            uni,
            UniArgs(inputAmount, amountOutMin, amountOutMax, path, deadline)
        );
    }

    /**
     * @notice  Only calls swapExactTokensForTokens if the output is above
     *          `amountOutMin` and below `amountOutMax`. `amountOutMax`
     *          is the 'stop price' when used as a stop loss, and
     *          `amountOutMin` is the 'limit price' when used as a limit
     *          order. When using this as a classic limit order, `amountOutMax`
     *          would be sent to the max uint value. When using this
     *          as a classic stop loss, `amountOutMin` would be set to 0.
     *          The min/max can also be used to limit downside during flash
     *          crashes, e.g. `amountOutMin` could be set to 10% lower then
     *          `amountOutMax` for a stop loss, if desired. Additionally, 
     *          takes part of the trade and uses it to pay `feeAmount`,
     *          in the specified fee token, to the registry.
     *          WARNING: only use this if you want to do things non-standard
     */
    function tokenToTokenRangePaySpecific(
        address user,
        uint feeAmount,
        uint maxGasPrice,
        IUniswapV2Router02 uni,
        FeeInfo memory feeInfo,
        uint inputAmount,
        uint amountOutMin,
        uint amountOutMax,
        address[] calldata path,
        uint deadline
    ) external gasPriceCheck(maxGasPrice) userFeeVerified {
        _tokenToTokenPaySpecific(
            user,
            feeAmount,
            uni,
            feeInfo,
            UniArgs(inputAmount, amountOutMin, amountOutMax, path, deadline)
        );
    }


    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
    ////                                                          ////
    ////-------------------------Helpers--------------------------////
    ////                                                          ////
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////

    function approveUnapproved(IUniswapV2Router02 uni, address tokenAddr, uint amount) private returns (IERC20 token) {
        token = IERC20(tokenAddr);
        if (token.allowance(address(this), address(uni)) < amount) {
            token.approve(address(uni), MAX_UINT);
        }
    }

    function transferApproveUnapproved(IUniswapV2Router02 uni, address tokenAddr, uint amount, address user) private {
        IERC20 token = approveUnapproved(uni, tokenAddr, amount);
        token.safeTransferFrom(user, address(this), amount);
    }

    function setDefaultFeeInfo(FeeInfo calldata newDefaultFee) external onlyOwner {
        _defaultFeeInfo = newDefaultFee;
    }

    function getDefaultFeeInfo() external view returns (FeeInfo memory) {
        return _defaultFeeInfo;
    }

    modifier userVerified() {
        require(msg.sender == userVeriForwarder, "LimitsStops: not userForw");
        _;
    }

    modifier userFeeVerified() {
        require(msg.sender == userFeeVeriForwarder, "LimitsStops: not userFeeForw");
        _;
    }

    modifier gasPriceCheck(uint maxGasPrice) {
        require(tx.gasprice <= maxGasPrice, "LimitsStops: gasPrice too high");
        _;
    }

    // Needed to receive excess ETH when calling swapAVAXForExactTokens
    receive() external payable {}
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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
    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity 0.8.6;

import "IUniswapV2Router01.sol";

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

pragma solidity 0.8.6;

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
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}