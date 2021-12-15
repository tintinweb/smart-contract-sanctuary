pragma solidity >=0.8.0;

import './interfaces/IBaoziRouter02.sol';
import './interfaces/IWTRX.sol';
import './interfaces/external/ITRC20.sol';
import './interfaces/external/IBaoziFactory.sol';
import './interfaces/external/IBaoziTRC20.sol';

import './libraries/BaoziLibrary.sol';
import './libraries/SafeMath.sol';
import './libraries/TransferHelper.sol';

contract BaoziRouter is IBaoziRouter02 {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WTRX;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'BaoziRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WTRX) {
        factory = _factory;
        WTRX = _WTRX;
    }

    receive() external payable { // TODO ASSERT
        require(msg.sender == WTRX); // only accept TRX via fallback from the WTRX contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) { // TODO ASSERT
        // create the pair if it doesn't exist yet
        if (IBaoziFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IBaoziFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = BaoziLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = BaoziLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'BaoziRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = BaoziLibrary.quote(amountBDesired, reserveB, reserveA);
                require(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'BaoziRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
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
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = IBaoziFactory(factory).getPair(tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IBaoziPair(pair).mint(to);
    }
    function addLiquidityTRX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountTRX, uint liquidity) { // TODO WTRX
        (amountToken, amountTRX) = _addLiquidity(
            token,
            WTRX,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountTRXMin
        );
        address pair = IBaoziFactory(factory).getPair(token, WTRX);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWTRX(WTRX).deposit{value: amountTRX}();
        require(IWTRX(WTRX).transfer(pair, amountTRX));
        liquidity = IBaoziPair(pair).mint(to);
        // refund dust eth, if any
        unchecked {
            if (msg.value > amountTRX) TransferHelper.safeTransferTRX(msg.sender, msg.value - amountTRX);
        }
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = IBaoziFactory(factory).getPair(tokenA, tokenB);
        require(IBaoziTRC20(pair).transferFrom(msg.sender, pair, liquidity)); // send liquidity to pair
        (uint amount0, uint amount1) = IBaoziPair(pair).burn(to);
        (address token0,) = BaoziLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'BaoziRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'BaoziRouter: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityTRX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountTRX) {
        (amountToken, amountTRX) = removeLiquidity(
            token,
            WTRX,
            liquidity,
            amountTokenMin,
            amountTRXMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWTRX(WTRX).withdraw(amountTRX);
        TransferHelper.safeTransferTRX(to, amountTRX);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = IBaoziFactory(factory).getPair(tokenA, tokenB);
        uint value = approveMax ? type(uint256).max : liquidity;
        IBaoziTRC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityTRXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountTRX) {
        address pair = IBaoziFactory(factory).getPair(token, WTRX);
        uint value = approveMax ? type(uint256).max : liquidity;
        IBaoziTRC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountTRX) = removeLiquidityTRX(token, liquidity, amountTokenMin, amountTRXMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityTRXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountTRX) {
        (, amountTRX) = removeLiquidity(
            token,
            WTRX,
            liquidity,
            amountTokenMin,
            amountTRXMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, ITRC20(token).balanceOf(address(this)));
        IWTRX(WTRX).withdraw(amountTRX);
        TransferHelper.safeTransferTRX(to, amountTRX);
    }
    function removeLiquidityTRXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountTRX) {
        address pair = IBaoziFactory(factory).getPair(token, WTRX);
        uint value = approveMax ? type(uint256).max : liquidity;
        IBaoziTRC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountTRX = removeLiquidityTRXSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountTRXMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        unchecked {
            for (uint256 i; i < path.length - 1; i++) { // TODO PATH LENGTH
                (address input, address output) = (path[i], path[i + 1]);
                (address token0,) = BaoziLibrary.sortTokens(input, output);
                uint amountOut = amounts[i + 1];
                (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
                address to = i < path.length - 2 ? BaoziLibrary.pairFor(factory, output, path[i + 2]) : _to;
                IBaoziPair(BaoziLibrary.pairFor(factory, input, output)).swap(
                    amount0Out, amount1Out, to, ''
                );
            }
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = BaoziLibrary.getAmountsOut(factory, amountIn, path);
        unchecked {
            require(amounts[amounts.length - 1] >= amountOutMin, 'BaoziRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        }
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BaoziLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = BaoziLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'BaoziRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BaoziLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactTRXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WTRX, 'BaoziRouter: INVALID_PATH');
        amounts = BaoziLibrary.getAmountsOut(factory, msg.value, path);
        unchecked {
            require(amounts[amounts.length - 1] >= amountOutMin, 'BaoziRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        }
        IWTRX(WTRX).deposit{value: amounts[0]}();
        require(IWTRX(WTRX).transfer(BaoziLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactTRX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        unchecked {
            require(path[path.length - 1] == WTRX, 'BaoziRouter: INVALID_PATH');
            amounts = BaoziLibrary.getAmountsIn(factory, amountOut, path);
            require(amounts[0] <= amountInMax, 'BaoziRouter: EXCESSIVE_INPUT_AMOUNT');
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, BaoziLibrary.pairFor(factory, path[0], path[1]), amounts[0]
            );
            _swap(amounts, path, address(this));
            IWTRX(WTRX).withdraw(amounts[amounts.length - 1]);
            TransferHelper.safeTransferTRX(to, amounts[amounts.length - 1]);
        }
    }
    function swapExactTokensForTRX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        unchecked {
            require(path[path.length - 1] == WTRX, 'BaoziRouter: INVALID_PATH');
            amounts = BaoziLibrary.getAmountsOut(factory, amountIn, path);
            require(amounts[amounts.length - 1] >= amountOutMin, 'BaoziRouter: INSUFFICIENT_OUTPUT_AMOUNT');
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, BaoziLibrary.pairFor(factory, path[0], path[1]), amounts[0]
            );
            _swap(amounts, path, address(this));
            IWTRX(WTRX).withdraw(amounts[amounts.length - 1]);
            TransferHelper.safeTransferTRX(to, amounts[amounts.length - 1]);
        }
    }
    function swapTRXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WTRX, 'BaoziRouter: INVALID_PATH');
        amounts = BaoziLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'BaoziRouter: EXCESSIVE_INPUT_AMOUNT');
        IWTRX(WTRX).deposit{value: amounts[0]}();
        require(IWTRX(WTRX).transfer(BaoziLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        unchecked {
            if (msg.value > amounts[0]) TransferHelper.safeTransferTRX(msg.sender, msg.value - amounts[0]);
        }
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = BaoziLibrary.sortTokens(input, output);
            IBaoziPair pair = IBaoziPair(BaoziLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = ITRC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = BaoziLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? BaoziLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BaoziLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = ITRC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            ITRC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'BaoziRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTRXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
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
        require(path[0] == WTRX, 'BaoziRouter: INVALID_PATH');
        uint amountIn = msg.value;
        IWTRX(WTRX).deposit{value: amountIn}();
        require(IWTRX(WTRX).transfer(BaoziLibrary.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = ITRC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            ITRC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'BaoziRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForTRXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        require(path[path.length - 1] == WTRX, 'BaoziRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BaoziLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = ITRC20(WTRX).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'BaoziRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWTRX(WTRX).withdraw(amountOut);
        TransferHelper.safeTransferTRX(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) external pure virtual override returns (uint amountB) {
        return BaoziLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        external
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return BaoziLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        external
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return BaoziLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        external
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return BaoziLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        external
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return BaoziLibrary.getAmountsIn(factory, amountOut, path);
    }
}

pragma solidity >=0.6.0;
pragma abicoder v1;

// helper methods for interacting with TRC20 tokens and sending TRX that do not consistently return true/false
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

    function safeTransferTRX(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: TRX_TRANSFER_FAILED');
    }
}

pragma solidity >=0.8.0;
pragma abicoder v1;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        z = x - y;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        z = x * y;
    }
}

pragma solidity >=0.5.0;
pragma abicoder v1;

import '../interfaces/external/IBaoziPair.sol';
import '../interfaces/external/IBaoziFactory.sol';

library BaoziLibrary {

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'BaoziLibrary: EQUAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'BaoziLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        return IBaoziFactory(factory).getPair(tokenA, tokenB);
        /*(address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(
            keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'994ab8116737216ba43eccc5feddeeaab97aeb6e02f375dfba583bce5c0bf745' // init code hash
            ))
        )));*/
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IBaoziPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA != 0, 'BaoziLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA != 0 && reserveB != 0, 'BaoziLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn != 0, 'BaoziLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn != 0 && reserveOut != 0, 'BaoziLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 9975;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 10000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut != 0, 'BaoziLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn != 0 && reserveOut != 0, 'BaoziLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut * 10000;
        uint denominator = (reserveOut - amountOut) * 9975;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        //unchecked {
            require(path.length >= 2, 'BaoziLibrary: INVALID_PATH');
            amounts = new uint[](path.length);
            amounts[0] = amountIn;
            for (uint i; i < path.length - 1; i++) {
                (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
                amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
            }
            return amounts;
        //}
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'BaoziLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

pragma solidity >=0.5.0;

interface ITRC20 {
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

pragma solidity >=0.5.0;

interface IBaoziTRC20 {
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

pragma solidity >=0.5.0;

import './IBaoziTRC20.sol';

interface IBaoziPair is IBaoziTRC20 {
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

    function initialize(address _token0, address _token1) external;
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
}

pragma solidity >=0.5.0;

interface IBaoziFactory {
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

interface IWTRX {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity >=0.6.2;

import './IBaoziRouter01.sol';
pragma abicoder v1;
interface IBaoziRouter02 is IBaoziRouter01 {
    function removeLiquidityTRXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline
    ) external returns (uint amountTRX);
    function removeLiquidityTRXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountTRX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTRXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForTRXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;
pragma abicoder v1;
interface IBaoziRouter01 {
    function factory() external view returns (address);
    function WTRX() external view returns (address);

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
    function addLiquidityTRX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountTRX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityTRX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountTRX);
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
    function removeLiquidityTRXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountTRX);
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
    function swapExactTRXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactTRX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForTRX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapTRXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}