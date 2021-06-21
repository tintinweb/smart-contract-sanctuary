/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-16
*/

//SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.7.4;

/**
 * $$$$$$$\                   $$$$$$$$\                  $$\
 * $$  __$$\                  \__$$  __|                 $$ |
 * $$ |  $$ | $$$$$$\   $$$$$$\  $$ | $$$$$$\   $$$$$$\  $$ | $$$$$$$\
 * $$$$$$$\ |$$  __$$\ $$  __$$\ $$ |$$  __$$\ $$  __$$\ $$ |$$  _____|
 * $$  __$$\ $$ /  $$ |$$ /  $$ |$$ |$$ /  $$ |$$ /  $$ |$$ |\$$$$$$\
 * $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |$$ |  $$ |$$ |  $$ |$$ | \____$$\
 * $$$$$$$  |\$$$$$$  |\$$$$$$$ |$$ |\$$$$$$  |\$$$$$$  |$$ |$$$$$$$  |
 * \_______/  \______/  \____$$ |\__| \______/  \______/ \__|\_______/
 *                     $$\   $$ |
 *                     \$$$$$$  |
 *                      \______/
 *
 * BogTools / Bogged Finance
 * https://bogtools.io/
 * https://bogged.finance/
 * Telegram: https://t.me/bogtools
 *
 * License: https://github.com/BogTools/BOGSwap-Contracts/blob/master/LICENSE
 */

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferBNB(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}

pragma solidity >=0.5.0;

interface IDEXPair {
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

interface IDEXFactory {
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

pragma solidity ^0.7.4;

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IBOGDEXUtils {
    function getBaseTokens() external view returns (address[] memory);
    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);
    function pairFor(uint256 dexID, address tokenA, address tokenB) external view returns (address pair);
    function getReserves(uint256 dexID, address tokenA, address tokenB) external view returns (uint reserveA, uint reserveB);
    function getPairBalances(uint256 dexID, address tokenA, address tokenB) external view returns (uint256 balanceA, uint256 balanceB);
    function getAmountOut(uint256 dexID, uint amountIn, uint reserveIn, uint reserveOut) external view returns (uint amountOut);
    function getAmountIn(uint256 dexID, uint amountOut, uint reserveIn, uint reserveOut) external view returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] memory path, uint256[] memory dexPath) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] memory path, uint256[] memory dexPath) external view returns (uint[] memory amounts);
    function getPathReserves(address[] memory path, uint256[] memory dexPath) external view returns (uint256[] memory reservesIn, uint256[] memory reservesOut);
    function isValidPath(address[] memory path, uint256[] memory dexPath) external view returns (bool valid);
    function getLargestBasePair(address token) external view returns (uint256 dexID, address pair, address baseToken);
    function getLargestDEX(address tokenA, address tokenB) external view returns (uint256 dexID, address factory, address pair);
}

contract BOGRouterV1 {
    using SafeMath for uint256;

    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    IBOGDEXUtils utils;

    constructor (IBOGDEXUtils _utils) {
        utils = _utils;
    }

    receive() external payable {
        assert(msg.sender == WBNB);
    }

    function _swap(address[] memory path, uint256[] memory dexPath, address _to) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address token0,) = utils.sortTokens(path[i], path[i + 1]);
            IDEXPair pair = IDEXPair(utils.pairFor(dexPath[i], path[i], path[i + 1]));
            uint256 amountInput;
            uint256 amountOutput;
            { // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) = path[i] == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IBEP20(path[i]).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = utils.getAmountOut(dexPath[i], amountInput, reserveInput, reserveOutput);
            }
            (uint256 amount0Out, uint256 amount1Out) = path[i] == token0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
            address to = i < path.length - 2 ? utils.pairFor(dexPath[i+1], path[i + 1], path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function makeTokenTokenSwap(uint256 amountIn, uint256 amountOutMin, address[] calldata path, uint256[] calldata dexPath, address to) external {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, utils.pairFor(dexPath[0], path[0], path[1]), amountIn
        );
        uint256 balanceBefore = IBEP20(path[path.length - 1]).balanceOf(to);
        _swap(path, dexPath, to);
        require(
            IBEP20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'BOGRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function makeBNBTokenSwap(uint256 amountOutMin, address[] calldata path, uint256[] calldata dexPath, address to) external payable {
        require(path[0] == WBNB, 'BOGRouter: INVALID_PATH');
        uint256 amountIn = msg.value;
        IWBNB(WBNB).deposit{value: amountIn}();
        assert(IWBNB(WBNB).transfer(utils.pairFor(dexPath[0], path[0], path[1]), amountIn));
        uint256 balanceBefore = IBEP20(path[path.length - 1]).balanceOf(to);
        _swap(path, dexPath, to);
        require(
            IBEP20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'BOGRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function makeTokenBNBSwap(uint256 amountIn, uint256 amountOutMin, address[] calldata path, uint256[] calldata dexPath, address to) external {
        require(path[path.length - 1] == WBNB, 'BOGRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, utils.pairFor(dexPath[0], path[0], path[1]), amountIn
        );
        _swap(path, dexPath, address(this));
        uint256 amountOut = IBEP20(WBNB).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'BOGRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWBNB(WBNB).withdraw(amountOut);
        TransferHelper.safeTransferBNB(to, amountOut);
    }
}