/**
 *Submitted for verification at Etherscan.io on 2020-06-05
*/

pragma solidity >=0.6.6;
import "./libraries/SafeMath.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IDTOPeggedSwapRouter.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/DTOPeggedSwapLibrary.sol";
import "./interfaces/IDTOPeggedSwapFactory.sol";
import "./interfaces/IDTOPeggedSwapPair.sol";
import './ChainIdHolding.sol';
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract DTOPeggedSwapRouter is IDTOPeggedSwapRouter, ChainIdHolding {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountTokenA,
        uint amountTokenB
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IDTOPeggedSwapFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IDTOPeggedSwapFactory(factory).createPair(tokenA, tokenB);
        }
        (amountA, amountB) = (amountTokenA, amountTokenB);
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountTokenA,
        uint amountTokenB,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountTokenA, amountTokenB);
        address pair = DTOPeggedSwapLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IDTOPeggedSwapPair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenIn,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenIn,
            msg.value
        );
        address pair = DTOPeggedSwapLibrary.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IDTOPeggedSwapPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = DTOPeggedSwapLibrary.pairFor(factory, tokenA, tokenB);
        IDTOPeggedSwapPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IDTOPeggedSwapPair(pair).burn(to);
        (address token0,) = DTOPeggedSwapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = DTOPeggedSwapLibrary.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        IDTOPeggedSwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = DTOPeggedSwapLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IDTOPeggedSwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
        address pair = DTOPeggedSwapLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IDTOPeggedSwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        (address input, address output) = (path[0], path[1]);
        (address token0,) = DTOPeggedSwapLibrary.sortTokens(input, output);
        uint amountOut = amounts[1];
        (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
        address to = _to;
        IDTOPeggedSwapPair(DTOPeggedSwapLibrary.pairFor(factory, input, output)).swap(
            amount0Out, amount1Out, to, new bytes(0)
        );
    }
    function swapExactTokensForTokens(
        uint amountIn,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path.length == 2, "Swap path must be 2 tokens");
        (, uint _reserveOut) = DTOPeggedSwapLibrary.getReserves(factory, path[0], path[1]);
        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = getAmountOut(amountIn, IERC20(path[0]).decimals(), IERC20(path[1]).decimals(), _reserveOut);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, DTOPeggedSwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path.length == 2, "Swap path must be 2 tokens");
        (uint _reserveIn,) = DTOPeggedSwapLibrary.getReserves(factory, path[0], path[1]);
        amounts = new uint[](2);
        amounts[1] = amountOut;

        amounts[0] = getAmountIn(amountOut, IERC20(path[0]).decimals(), IERC20(path[1]).decimals(), _reserveIn);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, DTOPeggedSwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'DTOPeggedSwapRouter: INVALID_PATH');
        require(path.length == 2, "Swap path must be 2 tokens");

        (, uint _reserveOut) = DTOPeggedSwapLibrary.getReserves(factory, path[0], path[1]);
        amounts = new uint[](2);
        amounts[0] = msg.value;

        amounts[1] = getAmountOut(msg.value, 18, IERC20(path[1]).decimals(), _reserveOut);

        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(DTOPeggedSwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'DTOPeggedSwapRouter: INVALID_PATH');

        require(path.length == 2, "Swap path must be 2 tokens");
        (uint _reserveIn,) = DTOPeggedSwapLibrary.getReserves(factory, path[0], path[1]);
        amounts = new uint[](2);
        amounts[1] = amountOut;

        amounts[0] = getAmountIn(amountOut, IERC20(path[0]).decimals(), IERC20(path[1]).decimals(), _reserveIn);

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, DTOPeggedSwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'DTOPeggedSwapRouter: INVALID_PATH');

        require(path.length == 2, "Swap path must be 2 tokens");
        (, uint _reserveOut) = DTOPeggedSwapLibrary.getReserves(factory, path[0], path[1]);
        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = getAmountOut(amountIn, IERC20(path[0]).decimals(), IERC20(path[1]).decimals(), _reserveOut);

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, DTOPeggedSwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'DTOPeggedSwapRouter: INVALID_PATH');

        require(path.length == 2, "Swap path must be 2 tokens");
        (uint _reserveIn,) = DTOPeggedSwapLibrary.getReserves(factory, path[0], path[1]);
        amounts = new uint[](2);
        amounts[1] = amountOut;

        amounts[0] = getAmountIn(amountOut, IERC20(path[0]).decimals(), IERC20(path[1]).decimals(), _reserveIn);

        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(DTOPeggedSwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        (address input, address output) = (path[0], path[1]);
        (address token0,) = DTOPeggedSwapLibrary.sortTokens(input, output);
        IDTOPeggedSwapPair pair = IDTOPeggedSwapPair(DTOPeggedSwapLibrary.pairFor(factory, input, output));
        uint amountInput;
        uint amountOutput;
        { // scope to avoid stack too deep errors
            (uint reserveInput, uint reserveOutput) = DTOPeggedSwapLibrary.getReserves(factory, input, output);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = getAmountOut(amountInput, IERC20(input).decimals(), IERC20(output).decimals(), reserveOutput);
        }
        (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
        pair.swap(amount0Out, amount1Out, _to, new bytes(0));
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, DTOPeggedSwapLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        //uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
     address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        require(path[0] == WETH, 'DTOPeggedSwapRouter: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(DTOPeggedSwapLibrary.pairFor(factory, path[0], path[1]), amountIn));
        //uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'DTOPeggedSwapRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, DTOPeggedSwapLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
      IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint8 decimalsA, uint8 decimalsB) public pure virtual override returns (uint amountB) {
        return DTOPeggedSwapLibrary.quote(amountA, decimalsA, decimalsB);
    }

    function getAmountOut(uint amountIn, uint8 decimalsIn, uint8 decimalsOut, uint256 reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return DTOPeggedSwapLibrary.getAmountOut(amountIn, decimalsIn, decimalsOut, reserveOut);
    }

    function getAmountIn(uint amountOut, uint8 decimalsIn, uint8 decimalsOut, uint reserveIn)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return DTOPeggedSwapLibrary.getAmountIn(amountOut, decimalsIn, decimalsOut, reserveIn);
    }
}

pragma solidity >=0.5.16;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'ds-math-div-zero');
        return a / b;
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.6.6;
interface IDTOPeggedSwapRouter {
    function factory() external view returns (address);
    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountTokenA,
        uint amountTokenB,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenIn,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint8 decimalsA, uint8 decimalsB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint8 decimalsIn, uint8 decimalsOut, uint256 reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint8 decimalsIn, uint8 decimalsOut, uint reserveIn) external pure returns (uint amountIn);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.6;

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

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity >=0.6.6;
import "./SafeMath.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IDTOPeggedSwapPair.sol";

library DTOPeggedSwapLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'DTOPeggedSwapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'DTOPeggedSwapLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'4bc474950f451485db3736a90b3b84b0148f50fd8bd7af0124f9c66e6936f4d2' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1) = IDTOPeggedSwapPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint8 decimalsA, uint8 decimalsB) internal pure returns (uint amountB) {
        require(amountA > 0, 'DTOPeggedSwapLibrary: INSUFFICIENT_AMOUNT');
        if (decimalsA > decimalsB) {
            amountB = amountA.div(10**(decimalsA - decimalsB));
        } else {
            amountB = amountA.mul(10**(decimalsB - decimalsA));
        }
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint8 decimalsIn, uint8 decimalsOut, uint256 reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'DTOPeggedSwapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        uint amountInWithFee = amountIn.mul(997).div(1000);
        amountOut = quote(amountInWithFee, decimalsIn, decimalsOut);
        require(amountOut <= reserveOut, "DTOPeggedSwapLibrary: INSUFFICIENT_LIQUIDITY");
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint8 decimalsIn, uint8 decimalsOut, uint reserveIn) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'DTOPeggedSwapLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        uint amountInWithFee = quote(amountOut, decimalsOut, decimalsIn);
        amountIn = amountInWithFee.mul(1000).div(997);
        amountIn = amountIn.add(1);
        require(reserveIn >= amountIn, 'DTOPeggedSwapLibrary: INSUFFICIENT_LIQUIDITY');
    }
}

pragma solidity >=0.5.0;

interface IDTOPeggedSwapFactory {
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

pragma solidity >=0.5.0;
import "./IDTOPeggedSwapERC20.sol";
interface IDTOPeggedSwapPair is IDTOPeggedSwapERC20 {
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
    event Sync(uint reserve0, uint reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint reserve0, uint reserve1);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.16;

abstract contract ChainIdHolding {
    uint256 public chainId;

    constructor() internal {
        uint256 _cid;
        assembly {
            _cid := chainid()
        }
        chainId = _cid;
    }
}

pragma solidity >=0.5.0;

interface IDTOPeggedSwapERC20 {
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
}

