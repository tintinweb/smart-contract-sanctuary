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
pragma solidity 0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IUniswapFactory.sol";
import "./interfaces/IUniswapRouter02.sol";
import "./interfaces/ITwapOraclePriceFeedFactory.sol";
import "./interfaces/ITwapOraclePriceFeed.sol";
import "./interfaces/IExchangeAgent.sol";
import "./libraries/TransferHelper.sol";

contract ExchangeAgent is IExchangeAgent, ReentrancyGuard {
    address public immutable override USDC_TOKEN;
    address public immutable UNISWAP_FACTORY;
    address public immutable TWAP_ORACLE_PRICE_FEED_FACTORY;
    address public immutable UNISWAP_ROUTER;
    address public immutable WETH;
    uint256 public slippage;
    uint256 private constant SLIPPAGE_PRECISION = 100;

    mapping(address => bool) public whiteList;
    address public owner;

    event ConvertedTokenToToken(
        address indexed _dexAddress,
        address indexed _convertToken,
        address indexed _convertedToken,
        uint256 _convertAmount,
        uint256 _desiredAmount,
        uint256 _convertedAmount
    );

    event ConvertedTokenToETH(
        address indexed _dexAddress,
        address indexed _convertToken,
        uint256 _convertAmount,
        uint256 _desiredAmount,
        uint256 _convertedAmount
    );

    event LogAddWhiteList(address indexed _exchangeAgent, address indexed _whiteListAddress);
    event LogRemoveWhiteList(address indexed _exchangeAgent, address indexed _whiteListAddress);
    event LogSetSlippage(address indexed _exchangeAgent, uint256 _slippage);

    constructor(
        address _usdcToken,
        address _WETH,
        address _twapOraclePriceFeedFactory,
        address _uniswapRouter,
        address _uniswapFactory
    ) {
        require(_usdcToken != address(0), "UnoRe: zero USDC address");
        require(_twapOraclePriceFeedFactory != address(0), "UnoRe: zero twapOraclePriceFeedFactory address");
        require(_uniswapRouter != address(0), "UnoRe: zero uniswapRouter address");
        require(_uniswapFactory != address(0), "UnoRe: zero uniswapFactory address");
        require(_WETH != address(0), "UnoRe: zero WETH address");
        USDC_TOKEN = _usdcToken;
        UNISWAP_FACTORY = _uniswapFactory;
        TWAP_ORACLE_PRICE_FEED_FACTORY = _twapOraclePriceFeedFactory;
        UNISWAP_ROUTER = _uniswapRouter;
        WETH = _WETH;
        owner = msg.sender;
        whiteList[msg.sender] = true;
        slippage = 5 * SLIPPAGE_PRECISION;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "UnoRe: ExchangeAgent Forbidden");
        _;
    }

    modifier onlyWhiteList() {
        require(whiteList[msg.sender], "UnoRe: ExchangeAgent Forbidden");
        _;
    }

    receive() external payable {}

    function addWhiteList(address _whiteListAddress) external onlyOwner {
        require(_whiteListAddress != address(0), "UnoRe: zero address");
        require(!whiteList[_whiteListAddress], "UnoRe: white list already");
        whiteList[_whiteListAddress] = true;
        emit LogAddWhiteList(address(this), _whiteListAddress);
    }

    function removeWhiteList(address _whiteListAddress) external onlyOwner {
        require(_whiteListAddress != address(0), "UnoRe: zero address");
        require(whiteList[_whiteListAddress], "UnoRe: white list removed or unadded already");
        whiteList[_whiteListAddress] = false;
        emit LogRemoveWhiteList(address(this), _whiteListAddress);
    }

    function setSlippage(uint256 _slippage) external onlyOwner {
        require(_slippage > 0, "UnoRe: zero slippage");
        require(_slippage < 100, "UnoRe: 100% slippage overflow");
        slippage = _slippage * SLIPPAGE_PRECISION;
        emit LogSetSlippage(address(this), _slippage);
    }

    // estimate token amount for amount in USDC
    function getTokenAmountForUSDC(address _token, uint256 _usdtAmount) external view override returns (uint256) {
        return _getNeededTokenAmount(USDC_TOKEN, _token, _usdtAmount);
    }

    // estimate ETH amount for amount in USDC
    function getETHAmountForUSDC(uint256 _usdtAmount) external view override returns (uint256) {
        return _getNeededTokenAmount(USDC_TOKEN, WETH, _usdtAmount);
    }

    function getETHAmountForToken(address _token, uint256 _tokenAmount) external view override returns (uint256) {
        return _getNeededTokenAmount(_token, WETH, _tokenAmount);
    }

    function getNeededTokenAmount(
        address _token0,
        address _token1,
        uint256 _token0Amount
    ) external view override returns (uint256) {
        return _getNeededTokenAmount(_token0, _token1, _token0Amount);
    }

    function convertForToken(
        address _token0,
        address _token1,
        uint256 _token0Amount
    ) external override onlyWhiteList nonReentrant returns (uint256) {
        uint256 twapPrice = 0;
        if (_token0 != address(0)) {
            require(IERC20(_token0).balanceOf(msg.sender) > 0, "UnoRe: zero balance");
            TransferHelper.safeTransferFrom(_token0, msg.sender, address(this), _token0Amount);
            twapPrice = _getNeededTokenAmount(_token0, _token1, _token0Amount);
        } else {
            twapPrice = _getNeededTokenAmount(WETH, _token1, _token0Amount);
        }
        require(twapPrice > 0, "UnoRe: no pairs");
        uint256 desiredAmount = (twapPrice * (100 * SLIPPAGE_PRECISION - slippage)) / 100 / SLIPPAGE_PRECISION;

        uint256 convertedAmount = _convertTokenForToken(UNISWAP_ROUTER, _token0, _token1, _token0Amount, desiredAmount);
        return convertedAmount;
    }

    function convertForETH(address _token, uint256 _convertAmount)
        external
        override
        onlyWhiteList
        nonReentrant
        returns (uint256)
    {
        require(IERC20(_token).balanceOf(msg.sender) > 0, "UnoRe: zero balance");
        if (_token != address(0)) {
            TransferHelper.safeTransferFrom(_token, msg.sender, address(this), _convertAmount);
        }
        uint256 twapPriceInUSDC = _getNeededTokenAmount(_token, WETH, _convertAmount);
        require(twapPriceInUSDC > 0, "UnoRe: no pairs");
        uint256 desiredAmount = (twapPriceInUSDC * (100 * SLIPPAGE_PRECISION - slippage)) / 100 / SLIPPAGE_PRECISION;

        uint256 convertedAmount = _convertTokenForETH(UNISWAP_ROUTER, _token, _convertAmount, desiredAmount);
        return convertedAmount;
    }

    function _convertTokenForToken(
        address _dexAddress,
        address _token0,
        address _token1,
        uint256 _convertAmount,
        uint256 _desiredAmount
    ) private returns (uint256) {
        IUniswapRouter02 _dexRouter = IUniswapRouter02(_dexAddress);
        address _factory = _dexRouter.factory();
        uint256 usdtBalanceBeforeSwap = IERC20(_token1).balanceOf(msg.sender);
        address inpToken = _dexRouter.WETH();
        if (_token0 != address(0)) {
            inpToken = _token0;
            TransferHelper.safeApprove(_token0, address(_dexRouter), _convertAmount);
        }
        if (IUniswapFactory(_factory).getPair(inpToken, _token1) != address(0)) {
            address[] memory path = new address[](2);
            path[0] = inpToken;
            path[1] = _token1;
            if (_token0 == address(0)) {
                _dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _convertAmount}(
                    _desiredAmount,
                    path,
                    msg.sender,
                    block.timestamp
                );
            } else {
                _dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _convertAmount,
                    _desiredAmount,
                    path,
                    msg.sender,
                    block.timestamp
                );
            }
        }
        uint256 usdtBalanceAfterSwap = IERC20(_token1).balanceOf(msg.sender);
        emit ConvertedTokenToToken(
            _dexAddress,
            _token0,
            _token1,
            _convertAmount,
            _desiredAmount,
            usdtBalanceAfterSwap - usdtBalanceBeforeSwap
        );
        return usdtBalanceAfterSwap - usdtBalanceBeforeSwap;
    }

    function _convertTokenForETH(
        address _dexAddress,
        address _token,
        uint256 _convertAmount,
        uint256 _desiredAmount
    ) private returns (uint256) {
        IUniswapRouter02 _dexRouter = IUniswapRouter02(_dexAddress);
        address _factory = _dexRouter.factory();
        uint256 ethBalanceBeforeSwap = address(msg.sender).balance;
        TransferHelper.safeApprove(_token, address(_dexRouter), _convertAmount);
        if (IUniswapFactory(_factory).getPair(_token, WETH) != address(0)) {
            address[] memory path = new address[](2);
            path[0] = _token;
            path[1] = WETH;
            _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                _convertAmount,
                _desiredAmount,
                path,
                msg.sender,
                block.timestamp
            );
        }
        uint256 ethBalanceAfterSwap = address(msg.sender).balance;
        emit ConvertedTokenToETH(_dexAddress, _token, _convertAmount, _desiredAmount, ethBalanceAfterSwap - ethBalanceBeforeSwap);
        return ethBalanceAfterSwap - ethBalanceBeforeSwap;
    }

    /**
     * @dev Get expected _token1 amount for _inputAmount of _token0
     * _desiredAmount should consider decimals based on _token1
     */
    function _getNeededTokenAmount(
        address _token0,
        address _token1,
        uint256 _token0Amount
    ) private view returns (uint256) {
        address pair = IUniswapFactory(UNISWAP_FACTORY).getPair(_token0, _token1);
        require(pair != address(0), "There's no pair");

        address twapOraclePriceFeed = ITwapOraclePriceFeedFactory(TWAP_ORACLE_PRICE_FEED_FACTORY).getTwapOraclePriceFeed(
            _token0,
            _token1
        );

        uint256 expectedToken1Amount = ITwapOraclePriceFeed(twapOraclePriceFeed).consult(_token0, _token0Amount);

        return expectedToken1Amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IExchangeAgent {
    function USDC_TOKEN() external view returns (address);

    function getTokenAmountForUSDC(address _token, uint256 _usdtAmount) external view returns (uint256);

    function getETHAmountForUSDC(uint256 _usdtAmount) external view returns (uint256);

    function getETHAmountForToken(address _token, uint256 _tokenAmount) external view returns (uint256);

    function getNeededTokenAmount(
        address _token0,
        address _token1,
        uint256 _token0Amount
    ) external view returns (uint256);

    function convertForToken(
        address _token0,
        address _token1,
        uint256 _token0Amount
    ) external returns (uint256);

    function convertForETH(address _token, uint256 _convertAmount) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface ITwapOraclePriceFeed {
    function update() external;

    function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface ITwapOraclePriceFeedFactory {
    function twapOraclePriceFeedList(address _pair) external view returns (address);

    function getTwapOraclePriceFeed(address _token0, address _token1) external view returns (address twapOraclePriceFeed);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

// from Uniswap TransferHelper library
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}