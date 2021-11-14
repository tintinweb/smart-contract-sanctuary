// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IUniswapFactory.sol";
import "./interfaces/IUniswapRouter02.sol";
import "./interfaces/IExchangeTokens.sol";

contract ExchangeTokens is IExchangeTokens, ReentrancyGuard {
    mapping(bytes32 => address) public aggregatorAddress;
    // address private immutable PANCAKE_ROUTER; // 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private immutable UNORE_TOKEN; // 0x474021845C4643113458ea4414bdb7fB74A01A77
    address public immutable override USDT_TOKEN; //
    address[] public dexList;

    event ConvertedToUSDT(
        address indexed _dexAddress,
        address indexed _convertToken,
        uint256 _convertAmount,
        uint256 _desiredAmount,
        uint256 _convertedAmount
    );

    constructor(
        address _unoToken,
        address _usdtToken,
        address[] memory _dexList
    ) {
        require(_dexList.length != 0, "UnoRe: no dex list");
        dexList = _dexList;
        UNORE_TOKEN = _unoToken;
        USDT_TOKEN = _usdtToken;
    }

    receive() external payable {}

    function getDexListLength() external view returns (uint256) {
        return dexList.length;
    }

    function addDex(address _dexAddress) external nonReentrant {
        require(_dexAddress != address(0), "UnoRe: zero address");
        for (uint256 ii = 0; ii < dexList.length; ii++) {
            if (_dexAddress == dexList[ii]) {
                return;
            }
        }
        dexList.push(_dexAddress);
    }

    // check all dex list registered here and then swap to USDT.
    function tokenConvertForUSDT(address _token, uint256 _convertAmount) external override returns (uint256) {
        uint256 maxConvertedAmount = 0;
        uint256 desiredIndex = 0;
        for (uint256 ii = 0; ii < dexList.length; ii++) {
            if (maxConvertedAmount < _getEstimatedAmount(dexList[ii], _token, _convertAmount)) {
                maxConvertedAmount = _getEstimatedAmount(dexList[ii], _token, _convertAmount);
                desiredIndex = ii;
            }
        }
        require(maxConvertedAmount > 0, "UnoRe: no pairs");
        uint256 convertedAmount = _convertTokenForUSDT(dexList[desiredIndex], _token, _convertAmount, maxConvertedAmount);
        return convertedAmount;
    }

    // dex will be determined in front end. Just only swap to USDT.
    function tokenConvertForUSDTFixed(
        address _dexAddress,
        address _token,
        uint256 _convertAmount
    ) external override returns (uint256) {
        uint256 desiredAmount = _getEstimatedAmount(_dexAddress, _token, _convertAmount);
        require(desiredAmount > 0, "UnoRe: no pair");
        uint256 convertedAmount = _convertTokenForUSDT(_dexAddress, _token, _convertAmount, desiredAmount);
        return convertedAmount;
    }

    /**
     * Returns the estimated USDT amount.
     */
    function _getEstimatedAmount(
        address _dexAddress,
        address _token,
        uint256 _convertAmount
    ) private view returns (uint256) {
        IUniswapRouter02 _uniswapRounter = IUniswapRouter02(_dexAddress);
        address _factory = _uniswapRounter.factory();
        address inpToken = _token;
        if (_token == address(0)) {
            inpToken = _uniswapRounter.WETH();
        }
        // console.log("[get estimate amount]", _token, inpToken, USDT_TOKEN);
        if (IUniswapFactory(_factory).getPair(inpToken, USDT_TOKEN) != address(0)) {
            address[] memory path = new address[](2);
            path[0] = inpToken;
            path[1] = USDT_TOKEN;
            uint256[] memory amounts = _uniswapRounter.getAmountsOut(_convertAmount, path);
            return (amounts[1] * 999) / 1000;
        }
        return 0;
    }

    function _convertTokenForUSDT(
        address _dexAddress,
        address _token,
        uint256 _convertAmount,
        uint256 _desiredAmount
    ) private returns (uint256) {
        IUniswapRouter02 _uniswapRounter = IUniswapRouter02(_dexAddress);
        address _factory = _uniswapRounter.factory();
        uint256 usdtBalanceBeforeSwap = IERC20(USDT_TOKEN).balanceOf(msg.sender);
        address inpToken = _uniswapRounter.WETH();
        if (_token != address(0)) {
            inpToken = _token;
            IERC20(_token).approve(address(_uniswapRounter), _convertAmount);
        }
        if (IUniswapFactory(_factory).getPair(inpToken, USDT_TOKEN) != address(0)) {
            address[] memory path = new address[](2);
            path[0] = inpToken;
            path[1] = USDT_TOKEN;
            if (_token == address(0)) {
                _uniswapRounter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _convertAmount}(
                    _desiredAmount,
                    path,
                    msg.sender,
                    block.timestamp
                );
            } else {
                _uniswapRounter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _convertAmount,
                    _desiredAmount,
                    path,
                    msg.sender,
                    block.timestamp
                );
            }
        }
        uint256 usdtBalanceAfterSwap = IERC20(USDT_TOKEN).balanceOf(msg.sender);
        emit ConvertedToUSDT(_dexAddress, _token, _convertAmount, _desiredAmount, usdtBalanceAfterSwap - usdtBalanceBeforeSwap);
        return usdtBalanceAfterSwap - usdtBalanceBeforeSwap;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExchangeTokens {
    function USDT_TOKEN() external view returns (address);

    function tokenConvertForUSDT(address _token, uint256 _convertAmount) external returns (uint256);

    function tokenConvertForUSDTFixed(
        address _dexAddress,
        address _token,
        uint256 _convertAmount
    ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IUniswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IUniswapRouter01 {
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IUniswapRouter01.sol";

interface IUniswapRouter02 is IUniswapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

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