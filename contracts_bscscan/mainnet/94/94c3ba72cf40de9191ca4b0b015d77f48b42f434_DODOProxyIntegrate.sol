/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

// File: contracts/intf/IERC20.sol

// This is a file copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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
}

// File: contracts/lib/SafeMath.sol



/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// File: contracts/lib/SafeERC20.sol


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/DODOProxyIntegrate.sol

interface IDODOV1Helper {
    function querySellQuoteToken(address dodoV1Pool, uint256 quoteAmount) external view returns (uint256 receivedBaseAmount);
    function querySellBaseToken(address dodoV1Pool, uint256 baseAmount) external view returns (uint256 receivedQuoteAmount);
}

interface IDODOV2 {
    function querySellBase(
        address trader, 
        uint256 payBaseAmount
    ) external view  returns (uint256 receiveQuoteAmount,uint256 mtFee);

    function querySellQuote(
        address trader, 
        uint256 payQuoteAmount
    ) external view  returns (uint256 receiveBaseAmount,uint256 mtFee);
}


interface IDODOProxy {
    function dodoSwapV1(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool,
        uint256 deadLine
    ) external payable returns (uint256 returnAmount);

    function dodoSwapV2TokenToToken(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);
}


/*
    There are six swap functions in DODOProxy. Which are executed for different sources or versions
    
    - dodoSwapV1: Used for DODOV1 pools
    - dodoSwapV2ETHToToken: Used for DODOV2 pools and specify ETH as fromToken
    - dodoSwapV2TokenToETH: Used for DODOV2 pools and specify ETH as toToken
    - dodoSwapV2TokenToToken:  Used for DODOV2 pools and both fromToken and toToken are ERC20
    - externalSwap: Used for executing third-party protocols' aggregation algorithm
    - mixSwap: Used for executing DODO’s custom aggregation algorithm

    Note: Best Trading path is calculated by off-chain program. DODOProxy's swap functions is only used for executing.
*/
contract DODOProxyIntegrate {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    /*
        Note: The code example assumes user wanting to use the specify DODOV1 pool for swaping
    */
    function useDodoSwapV1() public {
        address dodoV1Pool = 0xBe60d4c4250438344bEC816Ec2deC99925dEb4c7; //BSC USDT - BUSD (BUSD as BaseToken, USDT as QuoteToken)
        address fromToken = 0x55d398326f99059fF775485246999027B3197955; //BSC USDT
        address toToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; //BSC BUSD
        uint256 fromTokenAmount = 1e18; //sellQuoteAmount
        uint256 slippage = 1;
 
        /*
            Note: (only used for DODOV1 pool)

            Users can estimate prices before spending gas. Include two situations

            Sell baseToken and estimate received quoteToken 
            Sell quoteToken and estimate received baseToken

            We provide a helper contract to help user easily estimating the received amount. 

            function querySellBaseToken(address dodoV1Pool, uint256 baseAmount) public view returns (uint256 receiveQuoteAmount);

            function querySellQuoteToken(address dodoV1Pool, uint256 quoteAmount) public view returns (uint256 receiveBaseAmount);

            Helper Contract address on multi chain:
            - ETH: 0x533dA777aeDCE766CEAe696bf90f8541A4bA80Eb
            - BSC: 0x0F859706AeE7FcF61D5A8939E8CB9dBB6c1EDA33
            - Polygon: 0xDfaf9584F5d229A9DBE5978523317820A8897C5A
            - HECO: 0xA0Bb1FbC23a547a8D448C7c8a2336F69A9dBa1AF
        */

        address dodoV1Helper = 0x0F859706AeE7FcF61D5A8939E8CB9dBB6c1EDA33; //BSC Helper

        IERC20(fromToken).transferFrom(msg.sender, address(this), fromTokenAmount);
        uint256 receivedBaseAmount = IDODOV1Helper(dodoV1Helper).querySellQuoteToken(dodoV1Pool, fromTokenAmount);
        uint256 minReturnAmount = receivedBaseAmount.mul(100 - slippage).div(100);
        
        address[] memory dodoPairs = new address[](1); //one-hop
        dodoPairs[0] = dodoV1Pool;
        
        /*
            Note: Differentiate sellBaseToken or sellQuoteToken. If sellBaseToken represents 0, sellQuoteToken represents 1. 
            At the same time, dodoSwapV1 supports multi-hop linear routing, so here we use 0,1 combination to represent the multi-hop directions to save gas consumption
            For example: 
                A - B - C (A - B sellBase and  B - C sellQuote)  Binary: 10, Decimal 2 (directions = 2)
                D - E - F (D - E sellQuote and E - F sellBase) Binary: 01, Decimal 1 (directions = 1) 
        */
        
        uint256 directions = 1; 
        uint256 deadline = block.timestamp + 60 * 10;

        /*
            Note: Users need to authorize their sellToken to DODOApprove contract before executing the trade.

            ETH DODOApprove: 0xCB859eA579b28e02B87A1FDE08d087ab9dbE5149
            BSC DODOApprove: 0xa128Ba44B2738A558A1fdC06d6303d52D3Cef8c1
            Polygon DODOApprove: 0x6D310348d5c12009854DFCf72e0DF9027e8cb4f4
            Heco DODOApprove: 0x68b6c06Ac8Aa359868393724d25D871921E97293
        */
        address dodoApprove = 0xa128Ba44B2738A558A1fdC06d6303d52D3Cef8c1;
        _generalApproveMax(fromToken, dodoApprove, fromTokenAmount);

        /*
            ETH DODOProxy: 0xa356867fDCEa8e71AEaF87805808803806231FdC
            BSC DODOProxy: 0x8F8Dd7DB1bDA5eD3da8C9daf3bfa471c12d58486
            Polygon DODOProxy: 0xa222e6a71D1A1Dd5F279805fbe38d5329C1d0e70
            Heco DODOProxy: 0xAc7cC7d2374492De2D1ce21e2FEcA26EB0d113e7
        */
        address dodoProxy = 0x8F8Dd7DB1bDA5eD3da8C9daf3bfa471c12d58486;
 
        uint256 returnAmount = IDODOProxy(dodoProxy).dodoSwapV1(
            fromToken,
            toToken,
            fromTokenAmount,
            minReturnAmount,
            dodoPairs,
            directions,
            false,
            deadline
        );

        IERC20(toToken).safeTransfer(msg.sender, returnAmount);
    }


    /*
        Note: The code example assumes user wanting to use the specify DODOV2 pool for swaping
    */
    function useDodoSwapV2() public {
        address dodoV2Pool = 0xD534fAE679f7F02364D177E9D44F1D15963c0Dd7; //BSC DODO - WBNB (DODO as BaseToken, WBNB as QuoteToken)
        address fromToken = 0x67ee3Cb086F8a16f34beE3ca72FAD36F7Db929e2; //BSC DODO
        address toToken = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //BSC WBNB
        uint256 fromTokenAmount = 1e18; //sellBaseAmount
        uint256 slippage = 1;

        /*
            Note: (only used for DODOV2 pool)

            Users can estimate prices before spending gas. Include two situations

            Sell baseToken and estimate received quoteToken 
            Sell quoteToken and estimate received baseToken

            DODOV2 Pool contract provides two view functions. Users can use directly.

            function querySellBase(address trader, uint256 payBaseAmount) external view  returns (uint256 receiveQuoteAmount,uint256 mtFee);

            function querySellQuote(address trader, uint256 payQuoteAmount) external view  returns (uint256 receiveBaseAmount,uint256 mtFee);
        */

        IERC20(fromToken).transferFrom(msg.sender, address(this), fromTokenAmount);
        (uint256 receivedQuoteAmount,) = IDODOV2(dodoV2Pool).querySellBase(msg.sender, fromTokenAmount);
        uint256 minReturnAmount = receivedQuoteAmount.mul(100 - slippage).div(100);
        
        address[] memory dodoPairs = new address[](1); //one-hop
        dodoPairs[0] = dodoV2Pool;
        
        /*
            Note: Differentiate sellBaseToken or sellQuoteToken. If sellBaseToken represents 0, sellQuoteToken represents 1. 
            At the same time, dodoSwapV1 supports multi-hop linear routing, so here we use 0,1 combination to represent the multi-hop directions to save gas consumption
            For example: 
                A - B - C (A - B sellBase and  B - C sellQuote)  Binary: 10, Decimal 2 (directions = 2)
                D - E - F (D - E sellQuote and E - F sellBase) Binary: 01, Decimal 1 (directions = 1) 
        */
        
        uint256 directions = 0; 
        uint256 deadline = block.timestamp + 60 * 10;

        /*
            Note: Users need to authorize their sellToken to DODOApprove contract before executing the trade.

            ETH DODOApprove: 0xCB859eA579b28e02B87A1FDE08d087ab9dbE5149
            BSC DODOApprove: 0xa128Ba44B2738A558A1fdC06d6303d52D3Cef8c1
            Polygon DODOApprove: 0x6D310348d5c12009854DFCf72e0DF9027e8cb4f4
            Heco DODOApprove: 0x68b6c06Ac8Aa359868393724d25D871921E97293
        */
        address dodoApprove = 0xa128Ba44B2738A558A1fdC06d6303d52D3Cef8c1;
        _generalApproveMax(fromToken, dodoApprove, fromTokenAmount);

        /*
            ETH DODOProxy: 0xa356867fDCEa8e71AEaF87805808803806231FdC
            BSC DODOProxy: 0x8F8Dd7DB1bDA5eD3da8C9daf3bfa471c12d58486
            Polygon DODOProxy: 0xa222e6a71D1A1Dd5F279805fbe38d5329C1d0e70
            Heco DODOProxy: 0xAc7cC7d2374492De2D1ce21e2FEcA26EB0d113e7
        */
        address dodoProxy = 0x8F8Dd7DB1bDA5eD3da8C9daf3bfa471c12d58486;
 
        uint256 returnAmount = IDODOProxy(dodoProxy).dodoSwapV2TokenToToken(
            fromToken,
            toToken,
            fromTokenAmount,
            minReturnAmount,
            dodoPairs,
            directions,
            false,
            deadline
        );

        IERC20(toToken).safeTransfer(msg.sender, returnAmount);
    }

    
    /*
        Note:For externalSwap or mixSwap functions need complex off-chain calculations or network requests. We recommended users to use DODO API (https://dodoex.github.io/docs/docs/tradeApi) directly. 
    */


    function _generalApproveMax(
        address token,
        address to,
        uint256 amount
    ) internal {
        uint256 allowance = IERC20(token).allowance(address(this), to);
        if (allowance < amount) {
            if (allowance > 0) {
                IERC20(token).safeApprove(to, 0);
            }
            IERC20(token).safeApprove(to, uint256(-1));
        }
    }
}