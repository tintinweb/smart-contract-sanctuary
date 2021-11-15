// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../utils/ERC2771Context.sol";

import "../interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

/* solhint-disable max-line-length */
/* solhint-disable var-name-mixedcase */
/* solhint-disable func-param-name-mixedcase */
/* solhint-disable no-empty-blocks */

contract UniswapInteractionProxy is ERC2771Context {

    address public UNISWAP_V2_ROUTER;
    address public UNISWAP_V2_FACTORY;

    address payable public owner;
    address public proxy;

    IUniswapV2Router01 internal _router;
    IUniswapV2Factory internal _factory;

    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {
        owner = payable(_msgSender());
        proxy = msg.sender;
    }

    /**
     * @notice making functions callable via owner or proxy incase proxy does not use GSN
     */
    
    modifier onlyOwnerOrProxy {
        require(_msgSender() == owner || _msgSender() == proxy, "ONLY_OWNER");
        _;
    }

    function initialize(address router_, address factory_) external {

        UNISWAP_V2_ROUTER = router_;
        UNISWAP_V2_FACTORY = factory_;

        _router = IUniswapV2Router01(UNISWAP_V2_ROUTER);
        _factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);
    }

    function versionRecipient() external pure returns (string memory) {
        return "2.2.2";
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external onlyOwnerOrProxy {

        IERC20 _tokenA = IERC20(tokenA);
        IERC20 _tokenB = IERC20(tokenB);

        uint256 _allowanceA = _tokenA.allowance(owner, address(this));
        uint256 _allowanceB = _tokenB.allowance(owner, address(this));

        require(_allowanceA > 0 && _allowanceB > 0, "BOTH_TOKENS_NOT_APPROVED_TO_PROXY");

        _tokenA.transferFrom(owner, address(this), _allowanceA) &&
        _tokenA.approve(UNISWAP_V2_ROUTER, _tokenA.balanceOf(address(this)));

        _tokenB.transferFrom(owner, address(this), _allowanceB) &&
        _tokenB.approve(UNISWAP_V2_ROUTER, _tokenB.balanceOf(address(this)));

        (,, uint liquidity) = _router.addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline);

        address lpToken = _factory.getPair(tokenA, tokenB);
        IERC20(lpToken).transfer(owner, liquidity);
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable {

        IERC20 _token = IERC20(token);

        uint256 _allowance = _token.allowance(owner, address(this));

        require(_allowance > 0, "TOKENS_NOT_APPROVED_TO_PROXY");

        _token.transferFrom(owner, address(this), _allowance) &&
        _token.approve(UNISWAP_V2_ROUTER, _token.balanceOf(address(this)));

        (,, uint liquidity) = _router.addLiquidityETH{value: msg.value}(token, amountTokenDesired, amountTokenMin, amountETHMin, to, deadline);

        IERC20 lpToken = IERC20(_factory.getPair(token, _router.WETH()));
        lpToken.transfer(owner, liquidity);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external onlyOwnerOrProxy returns (uint amountA, uint amountB){

        IERC20 _token = IERC20(_factory.getPair(tokenA, tokenB));
        uint256 _allowance = _token.allowance(owner, address(this));

        require(_allowance > 0, "LP_TOKEN_NOT_APPROVED_TO_PROXY");

        _token.transferFrom(owner, address(this), _allowance) &&
        _token.approve(UNISWAP_V2_ROUTER, _token.balanceOf(address(this)));

        (amountA, amountB) = _router.removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);

        IERC20 _tokenA = IERC20(tokenA);
        IERC20 _tokenB = IERC20(tokenB);

        _tokenA.transfer(owner, amountA);
        _tokenB.transfer(owner, amountB);
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external onlyOwnerOrProxy returns (uint amountToken, uint amountETH) {

        IERC20 _token = IERC20(_factory.getPair(token, _router.WETH()));
        uint256 _allowance = _token.allowance(owner, address(this));

        require(_allowance > 0, "LP_TOKEN_NOT_APPROVED_TO_PROXY");

        _token.transferFrom(owner, address(this), _allowance) &&
        _token.approve(UNISWAP_V2_ROUTER, _token.balanceOf(address(this)));

        (amountToken, amountETH) = _router.removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);

        IERC20 _tokenA = IERC20(token);
        
        _tokenA.transfer(owner, amountToken);
        owner.transfer(amountETH);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external onlyOwnerOrProxy returns (uint[] memory) {

        /* The first element of path is the input token, 
         * the last is the output token
         * any intermediate elements represent intermediate tokens to trade through
         */

        address inputToken = path[0];
        address outputToken = path[path.length -1];

        IERC20 _inputToken = IERC20(inputToken);
        IERC20 _outputToken = IERC20(outputToken);

        uint256 _allowance = _inputToken.allowance(owner, address(this));

        if(_allowance > 0)  _inputToken.transferFrom(owner, address(this), amountInMax) &&
        _inputToken.approve(UNISWAP_V2_ROUTER, _inputToken.balanceOf(address(this)));
        
        uint[] memory amounts = _router.swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline);

        _outputToken.transfer(owner, amounts[amounts.length-1]);

        return amounts;
    }

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable onlyOwnerOrProxy
        returns (uint[] memory) {

        address outputToken = path[path.length -1];
        IERC20 _outputToken = IERC20(outputToken);
        
        uint[] memory amounts = _router.swapExactETHForTokens{value: msg.value}(amountOutMin, path, to, deadline);

        _outputToken.transfer(owner, amounts[amounts.length-1]);

        return amounts;      
    }

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external onlyOwnerOrProxy
        returns (uint[] memory) {

        address inputToken = path[0];

        IERC20 _inputToken = IERC20(inputToken);

        uint256 _allowance = _inputToken.allowance(owner, address(this));

        if(_allowance > 0)  _inputToken.transferFrom(owner, address(this), amountInMax) &&
        _inputToken.approve(UNISWAP_V2_ROUTER, _inputToken.balanceOf(address(this)));
        
        uint[] memory amounts = _router.swapTokensForExactETH(amountOut, amountInMax, path, to, deadline);

        owner.transfer(amounts[amounts.length-1]);

        return amounts;

    }

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external onlyOwnerOrProxy
        returns (uint[] memory) {

        address inputToken = path[0];

        IERC20 _inputToken = IERC20(inputToken);

        uint256 _allowance = _inputToken.allowance(owner, address(this));

        if(_allowance > 0)  _inputToken.transferFrom(owner, address(this), amountIn) &&
        _inputToken.approve(UNISWAP_V2_ROUTER, _inputToken.balanceOf(address(this)));
        
        uint[] memory amounts = _router.swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);

        owner.transfer(amounts[amounts.length-1]);

        return amounts;

    }

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable onlyOwnerOrProxy
        returns (uint[] memory) {

        address outputToken = path[path.length -1];
        IERC20 _outputToken = IERC20(outputToken);
        
        uint[] memory amounts = _router.swapETHForExactTokens{value: msg.value}(amountOut, path, to, deadline);

        _outputToken.transfer(owner, amounts[amounts.length-1]);

        return amounts;  
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./Context.sol";

/*
 * @dev Context variant with ERC2771 support.
 */

/* solhint-disable no-inline-assembly */

abstract contract ERC2771Context is Context {
    address internal _trustedForwarder;

    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5||0.7.6||0.6.12||0.5.16;

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

pragma solidity 0.8.5||0.7.6||0.6.12||0.5.16;

/*
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

