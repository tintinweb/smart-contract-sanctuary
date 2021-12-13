// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./lib/IUniswapV2Router02.sol";
import "./lib/IUniswapV2Factory.sol";
import "./lib/IMintClubBond.sol";
import "./lib/IWETH.sol";
import "./lib/Math.sol";

/**
* @title MintClubZapV5 extension contract (5.0.0)
*/

contract MintClubZapV5 is Context {
    using SafeERC20 for IERC20;

    // Copied from MintClubBond
    uint256 private constant BUY_TAX = 3;
    uint256 private constant SELL_TAX = 13;
    uint256 private constant MAX_TAX = 1000;

    address private constant DEFAULT_BENEFICIARY = 0x82CA6d313BffE56E9096b16633dfD414148D66b1;

    // MARK: - Mainnet configs

    // IUniswapV2Factory private constant PANCAKE_FACTORY = IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    // IUniswapV2Router02 private constant PANCAKE_ROUTER = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    // IMintClubBond private constant BOND = IMintClubBond(0x8BBac0C7583Cc146244a18863E708bFFbbF19975);
    // uint256 private constant DEAD_LINE = 0xf000000000000000000000000000000000000000000000000000000000000000;
    // address private constant MINT_CONTRACT = address(0x1f3Af095CDa17d63cad238358837321e95FC5915);
    // address private constant WBNB_CONTRACT = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    // MARK: - Testnet configs

    IUniswapV2Factory private constant PANCAKE_FACTORY = IUniswapV2Factory(0x6725F303b657a9451d8BA641348b6761A6CC7a17);
    IUniswapV2Router02 private constant PANCAKE_ROUTER = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
    IMintClubBond private constant BOND = IMintClubBond(0xB9B492B5D470ae0eB2BB07a87062EC97615d8b09);
    uint256 private constant DEAD_LINE = 0xf000000000000000000000000000000000000000000000000000000000000000;
    address private constant MINT_CONTRACT = address(0x4d24BF63E5d6E03708e2DFd5cc8253B3f22FE913);
    address private constant WBNB_CONTRACT = address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);

    constructor() {
        // Approve infinite MINT tokens spendable by bond contract
        // MINT will be stored temporarily during the swap transaction
        _approveToken(MINT_CONTRACT, address(BOND));
    }

    receive() external payable {}

    // MINT and others (parameter) -> Mint Club Tokens
    function estimateZapIn(address from, address to, uint256 fromAmount) external view returns (uint256 tokensToReceive, uint256 mintTokenTaxAmount) {
        uint256 mintAmount;

        if (from == MINT_CONTRACT) {
            mintAmount = fromAmount;
        } else {
            address[] memory path = _getPathToMint(from);

            mintAmount = PANCAKE_ROUTER.getAmountsOut(fromAmount, path)[path.length - 1];
        }

        return BOND.getMintReward(to, mintAmount);
    }

    function estimateZapInInitial(address from, uint256 fromAmount) external view returns (uint256 tokensToReceive, uint256 mintTokenTaxAmount) {
        uint256 mintAmount;

        if (from == MINT_CONTRACT) {
            mintAmount = fromAmount;
        } else {
            address[] memory path = _getPathToMint(from);

            mintAmount = PANCAKE_ROUTER.getAmountsOut(fromAmount, path)[path.length - 1];
        }

        uint256 taxAmount = mintAmount * BUY_TAX / MAX_TAX;
        uint256 newSupply = Math.floorSqrt(2 * 1e18 * (mintAmount - taxAmount));

        return (newSupply, taxAmount);
    }

    // Get required MINT token amount to buy X amount of Mint Club tokens
    function getReserveAmountToBuy(address tokenAddress, uint256 tokensToBuy) public view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);

        uint256 newTokenSupply = token.totalSupply() + tokensToBuy;
        uint256 reserveRequired = (newTokenSupply ** 2 - token.totalSupply() ** 2) / (2 * 1e18);
        reserveRequired = reserveRequired * MAX_TAX / (MAX_TAX - BUY_TAX); // Deduct tax amount

        return reserveRequired;
    }

    // MINT and others -> Mint Club Tokens (parameter)
    function estimateZapInReverse(address from, address to, uint256 tokensToReceive) external view returns (uint256 fromAmountRequired, uint256 mintTokenTaxAmount) {
        uint256 reserveRequired = getReserveAmountToBuy(to, tokensToReceive);

        if (from == MINT_CONTRACT) {
            fromAmountRequired = reserveRequired;
        } else {
            address[] memory path = _getPathToMint(from);

            fromAmountRequired = PANCAKE_ROUTER.getAmountsIn(reserveRequired, path)[0];
        }

        mintTokenTaxAmount = reserveRequired * BUY_TAX / MAX_TAX;
    }

    function estimateZapInReverseInitial(address from, uint256 tokensToReceive) external view returns (uint256 fromAmountRequired, uint256 mintTokenTaxAmount) {
        uint256 reserveRequired = tokensToReceive ** 2 / 2e18;

        if (from == MINT_CONTRACT) {
            fromAmountRequired = reserveRequired;
        } else {
            address[] memory path = _getPathToMint(from);

            fromAmountRequired = PANCAKE_ROUTER.getAmountsIn(reserveRequired, path)[0];
        }

        mintTokenTaxAmount = reserveRequired * BUY_TAX / MAX_TAX;
    }

    // Mint Club Tokens (parameter) -> MINT and others
    function estimateZapOut(address from, address to, uint256 fromAmount) external view returns (uint256 toAmountToReceive, uint256 mintTokenTaxAmount) {
        uint256 mintToRefund;
        (mintToRefund, mintTokenTaxAmount) = BOND.getBurnRefund(from, fromAmount);

        if (to == MINT_CONTRACT) {
            toAmountToReceive = mintToRefund;
        } else {
            address[] memory path = _getPathFromMint(to);

            toAmountToReceive = PANCAKE_ROUTER.getAmountsOut(mintToRefund, path)[path.length - 1];
        }
    }

    // Get amount of Mint Club tokens to receive X amount of MINT tokens
    function getTokenAmountFor(address tokenAddress, uint256 mintTokenAmount) public view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);

        uint256 reserveAfterSell = BOND.reserveBalance(tokenAddress) - mintTokenAmount;
        uint256 supplyAfterSell = Math.floorSqrt(2 * 1e18 * reserveAfterSell);

        return token.totalSupply() - supplyAfterSell;
    }

    // Mint Club Tokens -> MINT and others (parameter)
    function estimateZapOutReverse(address from, address to, uint256 toAmount) external view returns (uint256 tokensRequired, uint256 mintTokenTaxAmount) {
        uint256 mintTokenAmount;
        if (to == MINT_CONTRACT) {
            mintTokenAmount = toAmount;
        } else {
            address[] memory path = _getPathFromMint(to);
            mintTokenAmount = PANCAKE_ROUTER.getAmountsIn(toAmount, path)[0];
        }

        mintTokenTaxAmount = mintTokenAmount * SELL_TAX / MAX_TAX;
        tokensRequired = getTokenAmountFor(from, mintTokenAmount + mintTokenTaxAmount);
    }

    function zapInBNB(address to, uint256 minAmountOut, address beneficiary) public payable {
        // First, wrap BNB to WBNB
        IWETH(WBNB_CONTRACT).deposit{value: msg.value}();

        // Swap WBNB to MINT
        uint256 mintAmount = _swap(WBNB_CONTRACT, MINT_CONTRACT, msg.value);

        // Finally, buy target tokens with swapped MINT
        _buyMintClubTokenAndSend(to, mintAmount, minAmountOut, _getBeneficiary(beneficiary));
    }

    function zapIn(address from, address to, uint256 amountIn, uint256 minAmountOut, address beneficiary) public {
        // First, pull tokens to this contract
        IERC20 token = IERC20(from);
        require(token.allowance(_msgSender(), address(this)) >= amountIn, 'NOT_ENOUGH_ALLOWANCE');
        IERC20(from).safeTransferFrom(_msgSender(), address(this), amountIn);

        // Swap to MINT if necessary
        uint256 mintAmount;
        if (from == MINT_CONTRACT) {
            mintAmount = amountIn;
        } else {
            mintAmount = _swap(from, MINT_CONTRACT, amountIn);
        }

        // Finally, buy target tokens with swapped MINT
        _buyMintClubTokenAndSend(to, mintAmount, minAmountOut, _getBeneficiary(beneficiary));
    }

    function createAndZapIn(string memory name, string memory symbol, uint256 maxTokenSupply, address token, uint256 tokenAmount, uint256 minAmountOut, address beneficiary) external {
        address newToken = BOND.createToken(name, symbol, maxTokenSupply);

        // We need `minAmountOut` here token->MINT can be front ran and slippage my happen
        zapIn(token, newToken, tokenAmount, minAmountOut, _getBeneficiary(beneficiary));
    }

    function createAndZapInBNB(string memory name, string memory symbol, uint256 maxTokenSupply, uint256 minAmountOut, address beneficiary) external payable {
        address newToken = BOND.createToken(name, symbol, maxTokenSupply);

        zapInBNB(newToken, minAmountOut, _getBeneficiary(beneficiary));
    }

    function zapOut(address from, address to, uint256 amountIn, uint256 minAmountOut, address beneficiary) external {
        uint256 mintAmount = _receiveAndSwapToMint(from, amountIn, _getBeneficiary(beneficiary));

        // Swap to MINT if necessary
        IERC20 toToken;
        uint256 amountOut;
        if (to == MINT_CONTRACT) {
            toToken = IERC20(MINT_CONTRACT);
            amountOut = mintAmount;
        } else {
            toToken = IERC20(to);
            amountOut = _swap(MINT_CONTRACT, to, mintAmount);
        }

        // Check slippage limit
        require(amountOut >= minAmountOut, 'ZAP_SLIPPAGE_LIMIT_EXCEEDED');

        // Send the token to the user
        require(toToken.transfer(_msgSender(), amountOut), 'BALANCE_TRANSFER_FAILED');
    }

    function zapOutBNB(address from, uint256 amountIn, uint256 minAmountOut, address beneficiary) external {
        uint256 mintAmount = _receiveAndSwapToMint(from, amountIn, _getBeneficiary(beneficiary));

        // Swap to MINT to BNB
        uint256 amountOut = _swap(MINT_CONTRACT, WBNB_CONTRACT, mintAmount);
        IWETH(WBNB_CONTRACT).withdraw(amountOut);

        // Check slippage limit
        require(amountOut >= minAmountOut, 'ZAP_SLIPPAGE_LIMIT_EXCEEDED');

        // TODO: FIXME!!!!!

        // Send BNB to user
        (bool sent, ) = _msgSender().call{value: amountOut}("");
        require(sent, "BNB_TRANSFER_FAILED");
    }

    function _buyMintClubTokenAndSend(address tokenAddress, uint256 mintAmount, uint256 minAmountOut, address beneficiary) internal {
        // Finally, buy target tokens with swapped MINT (can be reverted due to slippage limit)
        BOND.buy(tokenAddress, mintAmount, minAmountOut, _getBeneficiary(beneficiary));

        // BOND.buy doesn't return any value, so we need to calculate the purchased amount
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(_msgSender(), token.balanceOf(address(this))), 'BALANCE_TRANSFER_FAILED');
    }

    function _receiveAndSwapToMint(address from, uint256 amountIn, address beneficiary) internal returns (uint256) {
        // First, pull tokens to this contract
        IERC20 token = IERC20(from);
        require(token.allowance(_msgSender(), address(this)) >= amountIn, 'NOT_ENOUGH_ALLOWANCE');
        IERC20(from).safeTransferFrom(_msgSender(), address(this), amountIn);

        // Approve infinitely to this contract
        if (token.allowance(address(this), address(BOND)) < amountIn) {
            require(token.approve(address(BOND), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff), 'APPROVE_FAILED');
        }

        // Sell tokens to MINT
        // NOTE: ignore minRefund (set as 0) for now, we should check it later on zapOut
        BOND.sell(from, amountIn, 0, _getBeneficiary(beneficiary));
        IERC20 mintToken = IERC20(MINT_CONTRACT);

        return mintToken.balanceOf(address(this));
    }


    function _getPathToMint(address from) internal pure returns (address[] memory path) {
        if (from == WBNB_CONTRACT) {
            path = new address[](2);
            path[0] = WBNB_CONTRACT;
            path[1] = MINT_CONTRACT;
        } else {
            path = new address[](3);
            path[0] = from;
            path[1] = WBNB_CONTRACT;
            path[2] = MINT_CONTRACT;
        }
    }

    function _getPathFromMint(address to) internal pure returns (address[] memory path) {
        if (to == WBNB_CONTRACT) {
            path = new address[](2);
            path[0] = MINT_CONTRACT;
            path[1] = WBNB_CONTRACT;
        } else {
            path = new address[](3);
            path[0] = MINT_CONTRACT;
            path[1] = WBNB_CONTRACT;
            path[2] = to;
        }
    }

    function _approveToken(address tokenAddress, address spender) internal {
        IERC20 token = IERC20(tokenAddress);
        if (token.allowance(address(this), spender) > 0) {
            return;
        } else {
            token.safeApprove(spender, type(uint256).max);
        }
    }

    /**
        @notice This function is used to swap ERC20 <> ERC20
        @param from The token address to swap from.
        @param to The token address to swap to.
        @param amount The amount of tokens to swap
        @return boughtAmount The quantity of tokens bought
    */
    function _swap(address from, address to, uint256 amount) internal returns (uint256 boughtAmount) {
        if (from == to) {
            return amount;
        }

        _approveToken(from, address(PANCAKE_ROUTER));

        address[] memory path;

        if (to == MINT_CONTRACT) {
            path = _getPathToMint(from);
        } else if (from == MINT_CONTRACT) {
            path = _getPathFromMint(to);
        } else {
            revert('INVALID_PATH');
        }

        // Check if there's a liquidity pool for paths
        // path.length is always 2 or 3
        for (uint8 i = 0; i < path.length - 1; i++) {
            address pair = PANCAKE_FACTORY.getPair(path[i], path[i + 1]);
            require(pair != address(0), 'INVALID_SWAP_PATH');
        }

        boughtAmount = PANCAKE_ROUTER.swapExactTokensForTokens(
            amount,
            1, // amountOutMin
            path,
            address(this), // to: Recipient of the output tokens
            DEAD_LINE
        )[path.length - 1];

        require(boughtAmount > 0, 'SWAP_ERROR');
    }

    // Prevent self referral
    function _getBeneficiary(address beneficiary) internal view returns (address) {
        if (beneficiary == address(0) || beneficiary == _msgSender()) {
           return DEFAULT_BENEFICIARY;
        } else {
            return beneficiary;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

pragma solidity ^0.8.6;

interface IUniswapV2Router02 {
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

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external
        returns (
            uint256[] memory amounts
        );

    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) external view
        returns (
            uint[] memory amounts
        );

    function getAmountsIn(
        uint amountOut,
        address[] memory path
    ) external view
        returns (
            uint[] memory amounts
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IMintClubBond {
    function reserveBalance(
        address tokenAddress
    ) external view returns (
        uint256 reserveBalance
    );

    function getMintReward(
        address tokenAddress,
        uint256 reserveAmount
    ) external view returns (
        uint256 toMint, // token amount to be minted
        uint256 taxAmount
    );

    function getBurnRefund(
        address tokenAddress,
        uint256 tokenAmount
    ) external view returns (
        uint256 mintToRefund,
        uint256 mintTokenTaxAmount
    );

    function buy(
        address tokenAddress,
        uint256 reserveAmount,
        uint256 minReward,
        address beneficiary
    ) external;

    function sell(
        address tokenAddress,
        uint256 tokenAmount,
        uint256 minRefund,
        address beneficiary
    ) external;

    function createToken(
        string memory name,
        string memory symbol,
        uint256 maxTokenSupply
    ) external returns (
        address tokenAddress
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

library Math {
    /**
     * @dev returns the largest integer smaller than or equal to the square root of a positive integer
     *
     * @param _num a positive integer
     *
     * @return the largest integer smaller than or equal to the square root of the positive integer
     */
    function floorSqrt(uint256 _num) internal pure returns (uint256) {
        uint256 x = _num / 2 + 1;
        uint256 y = (x + _num / x) / 2;
        while (x > y) {
            x = y;
            y = (x + _num / x) / 2;
        }
        return x;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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