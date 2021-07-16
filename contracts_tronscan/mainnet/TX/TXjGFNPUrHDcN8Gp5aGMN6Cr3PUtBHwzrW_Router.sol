//SourceUnit: Router.sol

/*! ICR.route.sol*/

pragma solidity 0.5.12;

interface ITRC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address spender, uint256 value) external returns(bool);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
}

interface IFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 index);

    function createPair(address tokenA, address tokenB) external returns(address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function feeTo() external view returns(address);
    function feeToSetter() external view returns(address);
    function getPair(address tokenA, address tokenB) external view returns(address pair);
    function allPairs(uint256) external view returns(address pair);
    function allPairsLength() external view returns(uint256);
}

interface IPair {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function mint(address to) external returns(uint256 liquidity);
    function burn(address to) external returns(uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;

    function MINIMUM_LIQUIDITY() external pure returns(uint256);
    function factory() external view returns(address);
    function token0() external view returns(address);
    function token1() external view returns(address);
    function getReserves() external view returns(uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns(uint256);
    function price1CumulativeLast() external view returns(uint256);
    function kLast() external view returns(uint256);
}

interface IWTRX {
    function deposit() external payable;
    function withdraw(uint256) external;
}

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

library TransferHelper {
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (token == 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C || data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferTRX(address to, uint256 value) internal {
        (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: TRX_TRANSFER_FAILED');
    }
}

library SwapLibrary {
    using SafeMath for uint256;

    function sortTokens(address tokenA, address tokenB) internal pure returns(address token0, address token1) {
        require(tokenA != tokenB, 'SwapLibrary: IDENTICAL_ADDRESSES');

        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        require(token0 != address(0), 'SwapLibrary: ZERO_ADDRESS');
    }

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns(uint256 amountB) {
        require(amountA > 0, 'SwapLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'SwapLibrary: INSUFFICIENT_LIQUIDITY');
        
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns(uint256 amountOut) {
        require(amountIn > 0, 'SwapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'SwapLibrary: INSUFFICIENT_LIQUIDITY');

        uint256 amountInWithFee = amountIn.mul(997);

        amountOut = amountInWithFee.mul(reserveOut) / reserveIn.mul(1000).add(amountInWithFee);
    }

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) internal pure returns(uint256 amountIn) {
        require(amountOut > 0, 'SwapLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'SwapLibrary: INSUFFICIENT_LIQUIDITY');

        amountIn = (reserveIn.mul(amountOut).mul(1000) / reserveOut.sub(amountOut).mul(997)).add(1);
    }

    function pairFor(address factory, address tokenA, address tokenB) internal view returns(address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);

        pair = IFactory(factory).getPair(token0, token1);

        require(pair != address(0), "SwapLibrary: UNDEFINED_PAIR");
    }

    function getReserves(address factory, address tokenA, address tokenB) internal view returns(uint256 reserveA, uint256 reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getAmountsOut(address factory, uint256 amountIn, address[] memory path) internal view returns(uint256[] memory amounts) {
        require(path.length >= 2, 'SwapLibrary: INVALID_PATH');

        amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        for(uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);

            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    function getAmountsIn(address factory, uint256 amountOut, address[] memory path) internal view returns(uint256[] memory amounts) {
        require(path.length >= 2, 'SwapLibrary: INVALID_PATH');

        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;

        for(uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);

            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

contract Router {
    using SafeMath for uint256;

    address public factory;
    address public wtrx;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'Router: EXPIRED');
        _;
    }

    constructor(address _factory, address _wtrx) public {
        factory = _factory;
        wtrx = _wtrx;
    }

    function() payable external {
        assert(msg.sender == wtrx);
    }

    function _addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin) internal returns(uint256 amountA, uint256 amountB) {
        if(IFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IFactory(factory).createPair(tokenA, tokenB);
        }

        (uint256 reserveA, uint256 reserveB) = SwapLibrary.getReserves(factory, tokenA, tokenB);

        if(reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        }
        else {
            uint256 amountBOptimal = SwapLibrary.quote(amountADesired, reserveA, reserveB);

            if(amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'Router: INSUFFICIENT_B_AMOUNT');

                (amountA, amountB) = (amountADesired, amountBOptimal);
            }
            else {
                uint256 amountAOptimal = SwapLibrary.quote(amountBDesired, reserveB, reserveA);

                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'Router: INSUFFICIENT_A_AMOUNT');

                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    
    function _swap(uint256[] memory amounts, address[] memory path, address _to) internal {
        for(uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = SwapLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < path.length - 2 ? SwapLibrary.pairFor(factory, output, path[i + 2]) : _to;

            IPair(SwapLibrary.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external  ensure(deadline) returns(uint256 amountA, uint256 amountB, uint256 liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);

        address pair = SwapLibrary.pairFor(factory, tokenA, tokenB);

        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);

        liquidity = IPair(pair).mint(to);
    }

    function addLiquidityTRX(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountTRXMin, address to, uint256 deadline) external payable ensure(deadline) returns(uint256 amountToken, uint256 amountTRX, uint256 liquidity) {
        (amountToken, amountTRX) = _addLiquidity(token, wtrx, amountTokenDesired, msg.value, amountTokenMin, amountTRXMin);

        address pair = SwapLibrary.pairFor(factory, token, wtrx);

        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);

        IWTRX(wtrx).deposit.value(amountTRX)();
        assert(ITRC20(wtrx).transfer(pair, amountTRX));

        liquidity = IPair(pair).mint(to);
        
        if(msg.value > amountTRX) TransferHelper.safeTransferTRX(msg.sender, msg.value - amountTRX);
    }

    function removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) public ensure(deadline) returns(uint256 amountA, uint256 amountB) {
        address pair = SwapLibrary.pairFor(factory, tokenA, tokenB);

        ITRC20(pair).transferFrom(msg.sender, pair, liquidity);
        (uint256 amount0, uint256 amount1) = IPair(pair).burn(to);

        (address token0,) = SwapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);

        require(amountA >= amountAMin, 'Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'Router: INSUFFICIENT_B_AMOUNT');
    }

    function removeLiquidityTRX(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountTRXMin, address to, uint256 deadline) public ensure(deadline) returns(uint256 amountToken, uint256 amountTRX) {
        (amountToken, amountTRX) = removeLiquidity(token, wtrx, liquidity, amountTokenMin, amountTRXMin, address(this), deadline);

        TransferHelper.safeTransfer(token, to, amountToken);
        IWTRX(wtrx).withdraw(amountTRX);
        TransferHelper.safeTransferTRX(to, amountTRX);
    }

    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external ensure(deadline) returns(uint256[] memory amounts) {
        amounts = SwapLibrary.getAmountsOut(factory, amountIn, path);

        require(amounts[amounts.length - 1] >= amountOutMin, 'Router: INSUFFICIENT_OUTPUT_AMOUNT');

        TransferHelper.safeTransferFrom(path[0], msg.sender, SwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]);

        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external ensure(deadline) returns(uint256[] memory amounts) {
        amounts = SwapLibrary.getAmountsIn(factory, amountOut, path);

        require(amounts[0] <= amountInMax, 'Router: EXCESSIVE_INPUT_AMOUNT');

        TransferHelper.safeTransferFrom(path[0], msg.sender, SwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]);

        _swap(amounts, path, to);
    }

    function swapExactTRXForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable ensure(deadline) returns(uint256[] memory amounts) {
        require(path[0] == wtrx, 'Router: INVALID_PATH');

        amounts = SwapLibrary.getAmountsOut(factory, msg.value, path);

        require(amounts[amounts.length - 1] >= amountOutMin, 'Router: INSUFFICIENT_OUTPUT_AMOUNT');

        IWTRX(wtrx).deposit.value(amounts[0])();

        assert(ITRC20(wtrx).transfer(SwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]));

        _swap(amounts, path, to);
    }

    function swapTRXForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline) external payable ensure(deadline) returns(uint256[] memory amounts) {
        require(path[0] == wtrx, 'Router: INVALID_PATH');

        amounts = SwapLibrary.getAmountsIn(factory, amountOut, path);

        require(amounts[0] <= msg.value, 'Router: EXCESSIVE_INPUT_AMOUNT');

        IWTRX(wtrx).deposit.value(amounts[0])();
        assert(ITRC20(wtrx).transfer(SwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]));

        _swap(amounts, path, to);
        
        if(msg.value > amounts[0]) TransferHelper.safeTransferTRX(msg.sender, msg.value - amounts[0]);
    }

    function swapExactTokensForTRX(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external ensure(deadline) returns(uint256[] memory amounts) {
        require(path[path.length - 1] == wtrx, 'Router: INVALID_PATH');

        amounts = SwapLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'Router: INSUFFICIENT_OUTPUT_AMOUNT');

        TransferHelper.safeTransferFrom(path[0], msg.sender, SwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]);

        _swap(amounts, path, address(this));

        IWTRX(wtrx).withdraw(amounts[amounts.length - 1]);

        TransferHelper.safeTransferTRX(to, amounts[amounts.length - 1]);
    }

    function swapTokensForExactTRX(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external ensure(deadline) returns(uint256[] memory amounts) {
        require(path[path.length - 1] == wtrx, 'Router: INVALID_PATH');

        amounts = SwapLibrary.getAmountsIn(factory, amountOut, path);

        require(amounts[0] <= amountInMax, 'Router: EXCESSIVE_INPUT_AMOUNT');

        TransferHelper.safeTransferFrom(path[0], msg.sender, SwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]);

        _swap(amounts, path, address(this));

        IWTRX(wtrx).withdraw(amounts[amounts.length - 1]);

        TransferHelper.safeTransferTRX(to, amounts[amounts.length - 1]);
    }
    
    function getAmountsIn(uint256 amountOut, address[] memory path) public view returns (uint256[] memory amounts) {
        return SwapLibrary.getAmountsIn(factory, amountOut, path);
    }
    
    function getAmountsOut(uint256 amountIn, address[] memory path) public view returns(uint256[] memory amounts) {
        return SwapLibrary.getAmountsOut(factory, amountIn, path);
    }

    function calcPairLiquidity(uint256 amountA, address tokenA, address tokenB, bool reverse) external view returns(uint256 amountB, uint256 share) {
        (uint256 reserveA, uint256 reserveB) = SwapLibrary.getReserves(factory, tokenA, tokenB);

        amountB = reverse ? SwapLibrary.quote(amountA, reserveB, reserveA) : SwapLibrary.quote(amountA, reserveA, reserveB);
        share = reverse ? amountA.mul(100) / reserveB.add(amountA) : amountA.mul(100) / reserveA.add(amountA);
    }

    function calcPairSwap(uint256 amountA, address tokenA, address tokenB, bool reverse) external view returns(uint256 amountB, uint256 priceImpact) {
        (uint256 reserveA, uint256 reserveB) = SwapLibrary.getReserves(factory, tokenA, tokenB);

        amountB = reverse ? SwapLibrary.getAmountIn(amountA, reserveA, reserveB) : SwapLibrary.getAmountOut(amountA, reserveA, reserveB);
        priceImpact = reverse ? reserveA.sub(reserveA.sub(amountB)).mul(10000) / reserveA : reserveB.sub(reserveB.sub(amountB)).mul(10000) / reserveB;
    }

    function getPair(address owner, address tokenA, address tokenB) external view returns(address pair, uint256 totalSupply, uint256 supply, uint256 reserveA, uint256 reserveB) {
        pair = SwapLibrary.pairFor(factory, tokenA, tokenB);
        totalSupply = ITRC20(pair).totalSupply();
        supply = ITRC20(pair).balanceOf(owner);
        
        (address token0,) = SwapLibrary.sortTokens(tokenA, tokenB);

        if(token0 != tokenA) (reserveB, reserveA) = SwapLibrary.getReserves(factory, tokenA, tokenB);
        else (reserveA, reserveB) = SwapLibrary.getReserves(factory, tokenA, tokenB);
    }

    function getPairs(address owner, uint256 start, uint256 limit) external view returns(uint256 count, address[] memory from, address[] memory to, uint256[] memory supply) {
        count = IFactory(factory).allPairsLength();

        from = new address[](limit);
        to = new address[](limit);
        supply = new uint256[](limit);

        uint256 matches = 0;

        for(uint256 i = start; i < start + limit && i < count; i++) {
            address pair = IFactory(factory).allPairs(i);

            from[matches] = IPair(pair).token0();
            to[matches] = IPair(pair).token1();
            supply[matches++] = ITRC20(pair).balanceOf(owner);
        }
    }
}