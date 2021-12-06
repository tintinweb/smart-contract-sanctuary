/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-05
*/

// File: contracts/interfaces/IRequiemQPairManager.sol



pragma solidity ^0.8.10;

interface IRequiemQPairManager {
    event Exchange(address pair, uint256 amountOut, address output);
    struct Swap {
        address pool;
        address tokenIn;
        address tokenOut;
        uint256 swapAmount; // tokenInAmount / tokenOutAmount
        uint256 limitReturnAmount; // minAmountOut / maxAmountIn
        uint256 maxPrice;
    }

    function factory() external view returns (address);

    function formula() external view returns (address);

    function WETH() external view returns (address);

    function createPair(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint32 tokenWeightA,
        uint32 swapFee,
        address to
    ) external returns (uint256 liquidity);

    function createPairETH(
        address token,
        uint256 amountToken,
        uint32 tokenWeight,
        uint32 swapFee,
        address to
    ) external payable returns (uint256 liquidity);

    function addLiquidity(
        address pair,
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
        address pair,
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
        address pair,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address pair,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address pair,
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
        address pair,
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

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address pair,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address pair,
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
}

// File: contracts/interfaces/ERC20/IERC20.sol



pragma solidity ^0.8.10;

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
// File: contracts/interfaces/IWETH.sol


// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.10;


/**
 * @dev Interface for WETH9.
 * See https://github.com/gnosis/canonical-weth/blob/0dd1ea3e295eef916d0c6223ec63141137d22d67/contracts/WETH9.sol
 */
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// File: contracts/libraries/TransferHelper.sol



pragma solidity >=0.8.10;

// solhint-disable avoid-low-level-calls, reason-string

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// File: contracts/interfaces/IRequiemSwap.sol



pragma solidity ^0.8.10;

interface IRequiemSwap {
    // this funtion requires the correctly calculated amounts as input
    // the others are supposed to implement that calculation
    // no return value required since the amounts are already known
    function onSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address to
    ) external;

    //
    function onSwapGivenIn(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address to
    ) external returns (uint256);

    function onSwapGivenOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 amountInMax,
        address to
    ) external returns (uint256);

    function calculateSwapGivenIn(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256);

    function calculateSwapGivenOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) external view returns (uint256);
}

// File: contracts/interfaces/IRequiemERC20.sol



pragma solidity ^0.8.10;

// solhint-disable func-name-mixedcase

interface IRequiemERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
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
}

// File: contracts/interfaces/IRequiemPair.sol



pragma solidity ^0.8.10;


// solhint-disable func-name-mixedcase

interface IRequiemPair is IRequiemERC20 {

    event PaidProtocolFee(uint112 collectedFee0, uint112 collectedFee1);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function getCollectedFees() external view returns (uint112 _collectedFee0, uint112 _collectedFee1);

    function getTokenWeights() external view returns (uint32 tokenWeight0, uint32 tokenWeight1);

    function getSwapFee() external view returns (uint32);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(
        address,
        address,
        uint32,
        uint32
    ) external;
}

// File: contracts/interfaces/IRequiemFormula.sol


pragma solidity >=0.5.16;

/*
    Bancor Formula interface
*/
interface IRequiemFormula {

    function getReserveAndWeights(address pair, address tokenA) external view returns (
        address tokenB,
        uint reserveA,
        uint reserveB,
        uint32 tokenWeightA,
        uint32 tokenWeightB,
        uint32 swapFee
    );

    function getFactoryReserveAndWeights(address factory, address pair, address tokenA) external view returns (
        address tokenB,
        uint reserveA,
        uint reserveB,
        uint32 tokenWeightA,
        uint32 tokenWeightB,
        uint32 swapFee
    );

    function getAmountIn(
        uint amountOut,
        uint reserveIn, uint reserveOut,
        uint32 tokenWeightIn, uint32 tokenWeightOut,
        uint32 swapFee
    ) external view returns (uint amountIn);

    function getPairAmountIn(address pair, address tokenIn, uint amountOut) external view returns (uint amountIn);

    function getAmountOut(
        uint amountIn,
        uint reserveIn, uint reserveOut,
        uint32 tokenWeightIn, uint32 tokenWeightOut,
        uint32 swapFee
    ) external view returns (uint amountOut);

    function getPairAmountOut(address pair, address tokenIn, uint amountIn) external view returns (uint amountOut);

    function getAmountsIn(
        address tokenIn,
        address tokenOut,
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getFactoryAmountsIn(
        address factory,
        address tokenIn,
        address tokenOut,
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsOut(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getFactoryAmountsOut(
        address factory,
        address tokenIn,
        address tokenOut,
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function ensureConstantValue(uint reserve0, uint reserve1, uint balance0Adjusted, uint balance1Adjusted, uint32 tokenWeight0) external view returns (bool);
    function getReserves(address pair, address tokenA, address tokenB) external view returns (uint reserveA, uint reserveB);
    function getOtherToken(address pair, address tokenA) external view returns (address tokenB);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);
    function mintLiquidityFee(
        uint totalLiquidity,
        uint112 reserve0,
        uint112  reserve1,
        uint32 tokenWeight0,
        uint32 tokenWeight1,
        uint112  collectedFee0,
        uint112 collectedFee1) external view returns (uint amount);
}

// File: contracts/interfaces/IRequiemFactory.sol



pragma solidity >=0.5.16;

interface IRequiemFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint32 tokenWeight0, uint32 swapFee, uint);
    function feeTo() external view returns (address);
    function formula() external view returns (address);
    function protocolFee() external view returns (uint);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB, uint32 tokenWeightA, uint32 swapFee) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function isPair(address) external view returns (bool);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB, uint32 tokenWeightA, uint32 swapFee) external returns (address pair);
    function getWeightsAndSwapFee(address pair) external view returns (uint32 tokenWeight0, uint32 tokenWeight1, uint32 swapFee);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setProtocolFee(uint) external;
}

// File: contracts/RequiemQPairManager.sol



pragma solidity >=0.8.10;









// solhint-disable not-rely-on-time, var-name-mixedcase, max-line-length, reason-string

contract RequiemQPairManager is IRequiemQPairManager {
    address public immutable override factory;
    address public immutable override formula;
    address public immutable override WETH;
    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Router: EXPIRED");
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        formula = IRequiemFactory(_factory).formula();
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH);
        // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        (uint256 reserveA, uint256 reserveB) = IRequiemFormula(formula).getReserves(pair, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = IRequiemFormula(formula).quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "Router: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = IRequiemFormula(formula).quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "Router: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _addLiquidityToken(
        address pair,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        (amountA, amountB) = _addLiquidity(pair, tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
    }

    function createPair(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint32 tokenWeightA,
        uint32 swapFee,
        address to
    ) public virtual override returns (uint256 liquidity) {
        address pair = IRequiemFactory(factory).createPair(tokenA, tokenB, tokenWeightA, swapFee);
        _addLiquidityToken(pair, tokenA, tokenB, amountA, amountB, 0, 0);
        liquidity = IRequiemPair(pair).mint(to);
    }

    function addLiquidity(
        address pair,
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
        virtual
        override
        ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidityToken(pair, tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        liquidity = IRequiemPair(pair).mint(to);
    }

    function _addLiquidityETH(
        address pair,
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to
    )
        internal
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = _addLiquidity(pair, token, WETH, amountTokenDesired, msg.value, amountTokenMin, amountETHMin);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        transferETHTo(amountETH, pair);
        liquidity = IRequiemPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    function createPairETH(
        address token,
        uint256 amountToken,
        uint32 tokenWeight,
        uint32 swapFee,
        address to
    ) public payable virtual override returns (uint256 liquidity) {
        address pair = IRequiemFactory(factory).createPair(token, WETH, tokenWeight, swapFee);
        (, , liquidity) = _addLiquidityETH(pair, token, amountToken, 0, 0, to);
    }

    function addLiquidityETH(
        address pair,
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        public
        payable
        virtual
        override
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH, liquidity) = _addLiquidityETH(pair, token, amountTokenDesired, amountTokenMin, amountETHMin, to);
    }

     // **** REMOVE LIQUIDITY ****
    function _removeLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) internal returns (uint256 amountA, uint256 amountB) {
        require(IRequiemFactory(factory).isPair(pair), "Router: Invalid pair");
        IRequiemPair(pair).transferFrom(msg.sender, pair, liquidity);
        // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IRequiemPair(pair).burn(to);
        (address token0, ) = IRequiemFormula(formula).sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "Router: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "Router: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        (amountA, amountB) = _removeLiquidity(pair, tokenA, tokenB, liquidity, amountAMin, amountBMin, to);
    }

    function removeLiquidityETH(
        address pair,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) = _removeLiquidity(pair, token, WETH, liquidity, amountTokenMin, amountETHMin, address(this));
        TransferHelper.safeTransfer(token, to, amountToken);
        transferAll(ETH_ADDRESS, to, amountETH);
    }

    function removeLiquidityWithPermit(
        address pair,
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
    ) external virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        {
            uint256 value = approveMax ? type(uint256).max : liquidity;
            IRequiemPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        }
        (amountA, amountB) = _removeLiquidity(pair, tokenA, tokenB, liquidity, amountAMin, amountBMin, to);
    }

    function removeLiquidityETHWithPermit(
        address pair,
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
    ) external virtual override returns (uint256 amountToken, uint256 amountETH) {
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IRequiemPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(pair, token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address pair,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountETH) {
        (, amountETH) = removeLiquidity(pair, token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        transferAll(ETH_ADDRESS, to, amountETH);
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address pair,
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
    ) external virtual override returns (uint256 amountETH) {
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IRequiemPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(pair, token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    function transferETHTo(uint256 amount, address to) internal {
        IWETH(WETH).deposit{value: amount}();
        assert(IWETH(WETH).transfer(to, amount));
    }

    function transferAll(
        address token,
        address to,
        uint256 amount
    ) internal returns (bool) {
        if (amount == 0) {
            return true;
        }

        if (isETH(token)) {
            IWETH(WETH).withdraw(amount);
            TransferHelper.safeTransferETH(to, amount);
        } else {
            TransferHelper.safeTransfer(token, to, amount);
        }
        return true;
    }

    function isETH(address token) internal pure returns (bool) {
        return (token == ETH_ADDRESS);
    }
}