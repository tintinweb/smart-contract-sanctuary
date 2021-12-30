// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './ISwapper.sol';
import '../token/IERC20.sol';
import './IUniswapV2Factory.sol';
import './IUniswapV2Router02.sol';
import '../oracle/IOracleManager.sol';
import '../utils/Admin.sol';
import '../utils/NameVersion.sol';
import '../library/SafeERC20.sol';

contract Swapper is ISwapper, Admin, NameVersion {

    using SafeERC20 for IERC20;

    uint256 constant ONE = 1e18;

    IUniswapV2Factory public immutable factory;

    IUniswapV2Router02 public immutable router;

    IOracleManager public immutable oracleManager;

    address public immutable tokenB0;

    address public immutable tokenWETH;

    uint256 public immutable maxSlippageRatio;

    // fromToken => toToken => path
    mapping (address => mapping (address => address[])) public paths;

    // tokenBX => oracle symbolId
    mapping (address => bytes32) public oracleSymbolIds;

    constructor (
        address factory_,
        address router_,
        address oracleManager_,
        address tokenB0_,
        address tokenWETH_,
        uint256 maxSlippageRatio_,
        string memory nativePriceSymbol // BNBUSD for BSC, ETHUSD for Ethereum
    ) NameVersion('Swapper', '3.0.1')
    {
        factory = IUniswapV2Factory(factory_);
        router = IUniswapV2Router02(router_);
        oracleManager = IOracleManager(oracleManager_);
        tokenB0 = tokenB0_;
        tokenWETH = tokenWETH_;
        maxSlippageRatio = maxSlippageRatio_;

        require(
            factory.getPair(tokenB0_, tokenWETH_) != address(0),
            'Swapper.constructor: no native path'
        );
        require(
            IERC20(tokenB0_).decimals() == 18 && IERC20(tokenWETH_).decimals() == 18,
            'Swapper.constructor: only token of decimals 18'
        );

        address[] memory path = new address[](2);

        (path[0], path[1]) = (tokenB0_, tokenWETH_);
        paths[tokenB0_][tokenWETH_] = path;

        (path[0], path[1]) = (tokenWETH_, tokenB0_);
        paths[tokenWETH_][tokenB0_] = path;

        bytes32 symbolId = keccak256(abi.encodePacked(nativePriceSymbol));
        require(oracleManager.value(symbolId) != 0, 'Swapper.constructor: no native price');
        oracleSymbolIds[tokenWETH_] = symbolId;

        IERC20(tokenB0_).safeApprove(router_, type(uint256).max);
    }

    function setPath(string memory priceSymbol, address[] calldata path) external _onlyAdmin_ {
        uint256 length = path.length;

        require(length >= 2, 'Swapper.setPath: invalid path length');
        require(path[0] == tokenB0, 'Swapper.setPath: path should begin with tokenB0');
        for (uint256 i = 1; i < length; i++) {
            require(factory.getPair(path[i-1], path[i]) != address(0), 'Swapper.setPath: path broken');
        }

        address[] memory revertedPath = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            revertedPath[length-i-1] = path[i];
        }

        address tokenBX = path[length-1];
        paths[tokenB0][tokenBX] = path;
        paths[tokenBX][tokenB0] = revertedPath;

        require(
            IERC20(tokenBX).decimals() == 18,
            'Swapper.setPath: only token of decimals 18'
        );

        bytes32 symbolId = keccak256(abi.encodePacked(priceSymbol));
        require(oracleManager.value(symbolId) != 0, 'Swapper.setPath: no price');
        oracleSymbolIds[tokenBX] = symbolId;

        IERC20(tokenBX).safeApprove(address(router), type(uint256).max);
    }

    function getPath(address tokenBX) external view returns (address[] memory) {
        return paths[tokenB0][tokenBX];
    }

    function isSupportedToken(address tokenBX) external view returns (bool) {
        address[] storage path1 = paths[tokenB0][tokenBX];
        address[] storage path2 = paths[tokenBX][tokenB0];
        return path1.length >= 2 && path2.length >= 2;
    }

    function getTokenPrice(address tokenBX) public view returns (uint256) {
        return oracleManager.value(oracleSymbolIds[tokenBX]);
    }

    receive() external payable {}

    //================================================================================

    function swapExactB0ForBX(address tokenBX, uint256 amountB0)
    external returns (uint256 resultB0, uint256 resultBX)
    {
        uint256 price = getTokenPrice(tokenBX);
        uint256 minAmountBX = amountB0 * (ONE - maxSlippageRatio) / price;
        (resultB0, resultBX) = _swapExactTokensForTokens(tokenB0, tokenBX, amountB0, minAmountBX);
    }

    function swapExactBXForB0(address tokenBX, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX)
    {
        uint256 price = getTokenPrice(tokenBX);
        uint256 minAmountB0 = amountBX * price / ONE * (ONE - maxSlippageRatio) / ONE;
        (resultBX, resultB0) = _swapExactTokensForTokens(tokenBX, tokenB0, amountBX, minAmountB0);
    }

    function swapB0ForExactBX(address tokenBX, uint256 maxAmountB0, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX)
    {
        uint256 price = getTokenPrice(tokenBX);
        uint256 maxB0 = amountBX * price / ONE * (ONE + maxSlippageRatio) / ONE;
        if (maxAmountB0 >= maxB0) {
            (resultB0, resultBX) = _swapTokensForExactTokens(tokenB0, tokenBX, maxB0, amountBX);
        } else {
            uint256 minAmountBX = maxAmountB0 * (ONE - maxSlippageRatio) / price;
            (resultB0, resultBX) = _swapExactTokensForTokens(tokenB0, tokenBX, maxAmountB0, minAmountBX);
        }
    }

    function swapBXForExactB0(address tokenBX, uint256 amountB0, uint256 maxAmountBX)
    external returns (uint256 resultB0, uint256 resultBX)
    {
        uint256 price = getTokenPrice(tokenBX);
        uint256 maxBX = amountB0 * (ONE + maxSlippageRatio) / price;
        if (maxAmountBX >= maxBX) {
            (resultBX, resultB0) = _swapTokensForExactTokens(tokenBX, tokenB0, maxBX, amountB0);
        } else {
            uint256 minAmountB0 = maxAmountBX * price / ONE * (ONE - maxSlippageRatio) / ONE;
            (resultBX, resultB0) = _swapExactTokensForTokens(tokenBX, tokenB0, maxAmountBX, minAmountB0);
        }
    }

    function swapExactB0ForETH(uint256 amountB0)
    external returns (uint256 resultB0, uint256 resultBX)
    {
        uint256 price = getTokenPrice(tokenWETH);
        uint256 minAmountBX = amountB0 * (ONE - maxSlippageRatio) / price;
        (resultB0, resultBX) = _swapExactTokensForTokens(tokenB0, tokenWETH, amountB0, minAmountBX);
    }

    function swapExactETHForB0()
    external payable returns (uint256 resultB0, uint256 resultBX)
    {
        uint256 price = getTokenPrice(tokenWETH);
        uint256 amountBX = msg.value;
        uint256 minAmountB0 = amountBX * price / ONE * (ONE - maxSlippageRatio) / ONE;
        (resultBX, resultB0) = _swapExactTokensForTokens(tokenWETH, tokenB0, amountBX, minAmountB0);
    }

    function swapB0ForExactETH(uint256 maxAmountB0, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX)
    {
        uint256 price = getTokenPrice(tokenWETH);
        uint256 maxB0 = amountBX * price / ONE * (ONE + maxSlippageRatio) / ONE;
        if (maxAmountB0 >= maxB0) {
            (resultB0, resultBX) = _swapTokensForExactTokens(tokenB0, tokenWETH, maxB0, amountBX);
        } else {
            uint256 minAmountBX = maxAmountB0 * (ONE - maxSlippageRatio) / price;
            (resultB0, resultBX) = _swapExactTokensForTokens(tokenB0, tokenWETH, maxAmountB0, minAmountBX);
        }
    }

    function swapETHForExactB0(uint256 amountB0)
    external payable returns (uint256 resultB0, uint256 resultBX)
    {
        uint256 price = getTokenPrice(tokenWETH);
        uint256 maxAmountBX = msg.value;
        uint256 maxBX = amountB0 * (ONE + maxSlippageRatio) / price;
        if (maxAmountBX >= maxBX) {
            (resultBX, resultB0) = _swapTokensForExactTokens(tokenWETH, tokenB0, maxBX, amountB0);
        } else {
            uint256 minAmountB0 = maxAmountBX * price / ONE * (ONE - maxSlippageRatio) / ONE;
            (resultBX, resultB0) = _swapExactTokensForTokens(tokenWETH, tokenB0, maxAmountBX, minAmountB0);
        }
    }

    //================================================================================

    function _swapExactTokensForTokens(address token1, address token2, uint256 amount1, uint256 amount2)
    internal returns (uint256 result1, uint256 result2)
    {
        if (amount1 == 0) return (0, 0);

        uint256[] memory res;
        if (token1 == tokenWETH) {
            res = router.swapExactETHForTokens{value: amount1}(
                amount2,
                paths[token1][token2],
                msg.sender,
                block.timestamp + 3600
            );
        } else if (token2 == tokenWETH) {
            IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);
            res = router.swapExactTokensForETH(
                amount1,
                amount2,
                paths[token1][token2],
                msg.sender,
                block.timestamp + 3600
            );
        } else {
            IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);
            res = router.swapExactTokensForTokens(
                amount1,
                amount2,
                paths[token1][token2],
                msg.sender,
                block.timestamp + 3600
            );
        }

        result1 = res[0];
        result2 = res[res.length - 1];
    }

    function _swapTokensForExactTokens(address token1, address token2, uint256 amount1, uint256 amount2)
    internal returns (uint256 result1, uint256 result2)
    {
        if (amount1 == 0 || amount2 == 0) {
            if (amount1 > 0 && token1 == tokenWETH) {
                _sendETH(msg.sender, amount1);
            }
            return (0, 0);
        }

        uint256[] memory res;
        if (token1 == tokenWETH) {
            res = router.swapETHForExactTokens{value: amount1}(
                amount2,
                paths[token1][token2],
                msg.sender,
                block.timestamp + 3600
            );
        } else if (token2 == tokenWETH) {
            IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);
            res = router.swapTokensForExactETH(
                amount2,
                amount1,
                paths[token1][token2],
                msg.sender,
                block.timestamp + 3600
            );
        } else {
            IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);
            res = router.swapTokensForExactTokens(
                amount2,
                amount1,
                paths[token1][token2],
                msg.sender,
                block.timestamp + 3600
            );
        }

        result1 = res[0];
        result2 = res[res.length - 1];

        if (token1 == tokenWETH) {
            _sendETH(msg.sender, address(this).balance);
        } else {
            IERC20(token1).safeTransfer(msg.sender, IERC20(token1).balanceOf(address(this)));
        }
    }

    function _sendETH(address to, uint256 amount) internal {
        (bool success, ) = payable(to).call{value: amount}('');
        require(success, 'Swapper._sendETH: fail');
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/IAdmin.sol';
import '../utils/INameVersion.sol';
import './IUniswapV2Factory.sol';
import './IUniswapV2Router02.sol';
import '../oracle/IOracleManager.sol';

interface ISwapper is IAdmin, INameVersion {

    function factory() external view returns (IUniswapV2Factory);

    function router() external view returns (IUniswapV2Router02);

    function oracleManager() external view returns (IOracleManager);

    function tokenB0() external view returns (address);

    function tokenWETH() external view returns (address);

    function maxSlippageRatio() external view returns (uint256);

    function oracleSymbolIds(address tokenBX) external view returns (bytes32);

    function setPath(string memory priceSymbol, address[] calldata path) external;

    function getPath(address tokenBX) external view returns (address[] memory);

    function isSupportedToken(address tokenBX) external view returns (bool);

    function getTokenPrice(address tokenBX) external view returns (uint256);

    function swapExactB0ForBX(address tokenBX, uint256 amountB0)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapExactBXForB0(address tokenBX, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapB0ForExactBX(address tokenBX, uint256 maxAmountB0, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapBXForExactB0(address tokenBX, uint256 amountB0, uint256 maxAmountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapExactB0ForETH(uint256 amountB0)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapExactETHForB0()
    external payable returns (uint256 resultB0, uint256 resultBX);

    function swapB0ForExactETH(uint256 maxAmountB0, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapETHForExactB0(uint256 amountB0)
    external payable returns (uint256 resultB0, uint256 resultBX);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';
import '../utils/IAdmin.sol';

interface IOracleManager is INameVersion, IAdmin {

    event NewOracle(bytes32 indexed symbolId, address indexed oracle);

    function getOracle(bytes32 symbolId) external view returns (address);

    function getOracle(string memory symbol) external view returns (address);

    function setOracle(address oracleAddress) external;

    function delOracle(bytes32 symbolId) external;

    function delOracle(string memory symbol) external;

    function value(bytes32 symbolId) external view returns (uint256);

    function getValue(bytes32 symbolId) external view returns (uint256);

    function updateValue(
        bytes32 symbolId,
        uint256 timestamp_,
        uint256 value_,
        uint8   v_,
        bytes32 r_,
        bytes32 s_
    ) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IAdmin.sol';

abstract contract Admin is IAdmin {

    address public admin;

    modifier _onlyAdmin_() {
        require(msg.sender == admin, 'Admin: only admin');
        _;
    }

    constructor () {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './INameVersion.sol';

/**
 * @dev Convenience contract for name and version information
 */
abstract contract NameVersion is INameVersion {

    bytes32 public immutable nameId;
    bytes32 public immutable versionId;

    constructor (string memory name, string memory version) {
        nameId = keccak256(abi.encodePacked(name));
        versionId = keccak256(abi.encodePacked(version));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../token/IERC20.sol";
import "./Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
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

pragma solidity >=0.8.0 <0.9.0;

interface IAdmin {

    event NewAdmin(address indexed newAdmin);

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface INameVersion {

    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);

}

// SPDX-License-Identifier: MIT

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

pragma solidity >=0.8.0 <0.9.0;

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