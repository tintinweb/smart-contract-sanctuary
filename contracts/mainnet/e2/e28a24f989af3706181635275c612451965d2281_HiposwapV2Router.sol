// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

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

// File: contracts/interfaces/IHiposwapV2Pair.sol

pragma solidity >=0.5.0;

interface IHiposwapV2Pair {
    

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
    event _Maker(address indexed sender, address token, uint amount, uint time);

    
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function currentPoolId0() external view returns (uint);
    function currentPoolId1() external view returns (uint);
    function getMakerPool0(uint poolId) external view returns (uint _balance, uint _swapOut, uint _swapIn);
    function getMakerPool1(uint poolId) external view returns (uint _balance, uint _swapOut, uint _swapIn);
    function getReserves() external view returns (uint reserve0, uint reserve1);
    function getBalance() external view returns (uint _balance0, uint _balance1);
    function getMaker(address mkAddress) external view returns (uint,address,uint,uint);
    function getFees() external view returns (uint _fee0, uint _fee1);
    function getFeeAdmins() external view returns (uint _feeAdmin0, uint _feeAdmin1);
    function getAvgTimes() external view returns (uint _avgTime0, uint _avgTime1);
    function transferFeeAdmin(address to) external;
    function getFeePercents() external view returns (uint _feeAdminPercent, uint _feePercent, uint _totalPercent);
    function setFeePercents(uint _feeAdminPercent, uint _feePercent, uint _totalPercent) external;
    function getRemainPercent() external view returns (uint);
    function getTotalPercent() external view returns (uint);
    
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function order(address to) external returns (address token, uint amount);
    function retrieve(uint amount0, uint amount1, address sender, address to) external returns (uint, uint);
    function getAmountA(address to, uint amountB) external view returns(uint amountA, uint _amountB, uint rewardsB, uint remainA);
    function getAmountB(address to, uint amountA) external view returns(uint _amountA, uint amountB, uint rewardsB, uint remainA);

    function initialize(address, address) external;
}

// File: contracts/interfaces/IHiposwapV2Factory.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

abstract contract IHiposwapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view virtual returns (address);
    function uniswapFactory() external view virtual returns (address);
    function WETH() external pure virtual returns (address);

    function getPair(address tokenA, address tokenB) external view virtual returns (address pair);
    function allPairs(uint) external view virtual returns (address pair);
    function allPairsLength() external view virtual returns (uint);

    function createPair(address tokenA, address tokenB) external virtual returns (address pair);

    function setFeeTo(address) external virtual;
    function setUniswapFactory(address _factory) external virtual;
    
    function getContribution(address tokenA, address tokenB, address tokenMain, address mkAddress) external view virtual returns (address pairAddress, uint contribution);
    
    function getMaxMakerAmount(address tokenA, address tokenB) external view virtual returns (uint amountA, uint amountB);
    function getMaxMakerAmountETH(address token) external view virtual returns (uint amount, uint amountETH);
    function addMaker(address tokenA, address tokenB, uint amountA, uint amountB, address to, uint deadline) external virtual returns (address token, uint amount);
    function addMakerETH(address token, uint amountToken, address to, uint deadline) external payable virtual returns (address _token, uint amount);
    function removeMaker(address tokenA, address tokenB, uint amountA, uint amountB, address to, uint deadline) external virtual returns (uint amount0, uint amount1);
    function removeMakerETH(address token, uint amountToken, uint amountETH, address to, uint deadline) external virtual returns (uint _amountToken, uint _amountETH);
    function removeMakerETHSupportingFeeOnTransferTokens(address token, uint amountToken, uint amountETH, address to, uint deadline) external virtual returns (uint _amountETH);
    
    function collectFees(address tokenA, address tokenB) external virtual;
    function collectFees(address pair) external virtual;
    function setFeePercents(address tokenA, address tokenB, uint _feeAdminPercent, uint _feePercent, uint _totalPercent) external virtual;
    function setFeePercents(address pair, uint _feeAdminPercent, uint _feePercent, uint _totalPercent) external virtual;
}

// File: contracts/libraries/SafeMath.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

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
}

// File: contracts/libraries/HiposwapV2Library.sol

pragma solidity >=0.5.0;






library HiposwapV2Library {
    using SafeMath for uint;
    
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'HiposwapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'HiposwapV2Library: ZERO_ADDRESS');
    }

    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        
        address pair = pairFor(factory, tokenA, tokenB);
        if (pair == address(0)) {
            return (0, 0);
        }
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    
    // calculates the CREATE2 address for a pair without making any external calls
    function makerPairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'2603bd3b15dbef4d28f9036d8301021d5edc3ae2f073f054721f61b9bf1fa5f3' // init code hash
            ))));
    }
    
    function getMakerReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1) = IHiposwapV2Pair(makerPairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'HiposwapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'HiposwapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }
    
    function getMakerAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint makerReserve, uint remainPercent, uint totalPercent) internal pure returns (uint amountOut) {
        require(amountIn >= 10, 'HiposwapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'HiposwapV2Library: INSUFFICIENT_LIQUIDITY');
        amountOut = getAmountOut(amountIn / 10, reserveIn, reserveOut, remainPercent, totalPercent).mul(10);
        require(amountOut <= makerReserve, 'HiposwapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
    }
    
    // function getMakerAmountsOut(address hipoFactory, address uniFactory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
    //     require(path.length >= 2, 'HiposwapV2Library: INVALID_PATH');
    //     amounts = new uint[](path.length);
    //     amounts[0] = amountIn;
    //     for (uint i; i < path.length - 1; i++) {
    //         (uint reserveIn, uint reserveOut) = getReserves(uniFactory, path[i], path[i + 1]);
    //         (, uint makerReserveOut) = getMakerReserves(hipoFactory, path[i], path[i + 1]);
    //         amounts[i + 1] = getMakerAmountOut(amounts[i], reserveIn, reserveOut, makerReserveOut);
    //     }
    // }
    
    function getMakerAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint makerReserve, uint remainPercent, uint totalPercent) internal pure returns (uint amountIn) {
        require(amountOut >= 10 && amountOut <= makerReserve, 'HiposwapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'HiposwapV2Library: INSUFFICIENT_LIQUIDITY');
        amountIn = getAmountIn(amountOut / 10, reserveIn, reserveOut, remainPercent, totalPercent).sub(1).mul(10).add(1);
    }
    
    // function getMakerAmountsIn(address hipoFactory, address uniFactory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
    //     require(path.length >= 2, 'HiposwapV2Library: INVALID_PATH');
    //     amounts = new uint[](path.length);
    //     amounts[amounts.length - 1] = amountOut;
    //     for (uint i = path.length - 1; i > 0; i--) {
    //         (uint reserveIn, uint reserveOut) = getReserves(uniFactory, path[i - 1], path[i]);
    //         (, uint makerReserveOut) = getMakerReserves(hipoFactory, path[i - 1], path[i]);
    //         amounts[i - 1] = getMakerAmountIn(amounts[i], reserveIn, reserveOut, makerReserveOut);
    //     }
    // }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint remainPercent, uint totalPercent) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'HiposwapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'HiposwapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(remainPercent);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(totalPercent).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint remainPercent, uint totalPercent) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'HiposwapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'HiposwapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(totalPercent);
        uint denominator = reserveOut.sub(amountOut).mul(remainPercent);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    // function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
    //     require(path.length >= 2, 'HiposwapV2Library: INVALID_PATH');
    //     amounts = new uint[](path.length);
    //     amounts[0] = amountIn;
    //     for (uint i; i < path.length - 1; i++) {
    //         (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
    //         amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    //     }
    // }

    // performs chained getAmountIn calculations on any number of pairs
    // function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
    //     require(path.length >= 2, 'HiposwapV2Library: INVALID_PATH');
    //     amounts = new uint[](path.length);
    //     amounts[amounts.length - 1] = amountOut;
    //     for (uint i = path.length - 1; i > 0; i--) {
    //         (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
    //         amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    //     }
    // }
}

// File: contracts/libraries/TransferHelper.sol

// SPDX-License-Identifier: GPL-3.0-or-later

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

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: contracts/interfaces/IHiposwapV2Router.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

interface IHiposwapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

    //function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    //function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    //function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    //function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    //function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

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
    
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getMakerAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint makerReserve, uint remainPercent, uint totalPercent) external pure returns (uint amountOut);
    function getMakerAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint makerReserve, uint remainPercent, uint totalPercent) external pure returns (uint amountIn);
    function getHipoReserves(address tokenA, address tokenB) external view returns (uint r0, uint r1);
    function getMakerAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getMakerAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    
}

// File: contracts/interfaces/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: contracts/interfaces/IERC20.sol

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

// File: contracts/HiposwapV2Router.sol

pragma solidity =0.6.6;









contract HiposwapV2Router is IHiposwapV2Router{
    using SafeMath for uint;
    address public immutable override factory;
    address public immutable override WETH;
    
    uint public constant MIN_RESERVE_UPDATE_TIME = 10 minutes;
    
    struct Reserve {
        uint reserve0;
        uint reserve1;
        uint time;
    }
    mapping(address => Reserve) public rs;
    
    constructor(address _factory) public {
        factory = _factory;
        WETH = IHiposwapV2Factory(_factory).WETH();
    }
    
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'HiposwapV2Router: EXPIRED');
        _;
    }
    
    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }
    
    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = HiposwapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? HiposwapV2Library.makerPairFor(factory, output, path[i + 2]) : _to;
            IHiposwapV2Pair(HiposwapV2Library.makerPairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = getMakerAmountsOutUpdateReserve(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'HiposwapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, HiposwapV2Library.makerPairFor(factory, path[0], path[1]), amounts[0]
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
        amounts = getMakerAmountsInUpdateReserve(amountOut, path);
        require(amounts[0] <= amountInMax, 'HiposwapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, HiposwapV2Library.makerPairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'HiposwapV2Router: INVALID_PATH');
        amounts = getMakerAmountsOutUpdateReserve(msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'HiposwapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(HiposwapV2Library.makerPairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'HiposwapV2Router: INVALID_PATH');
        amounts = getMakerAmountsInUpdateReserve(amountOut, path);
        require(amounts[0] <= amountInMax, 'HiposwapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, HiposwapV2Library.makerPairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'HiposwapV2Router: INVALID_PATH');
        amounts = getMakerAmountsOutUpdateReserve(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'HiposwapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, HiposwapV2Library.makerPairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'HiposwapV2Router: INVALID_PATH');
        amounts = getMakerAmountsInUpdateReserve(amountOut, path);
        require(amounts[0] <= msg.value, 'HiposwapV2Router: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(HiposwapV2Library.makerPairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, address token1) = HiposwapV2Library.sortTokens(input, output);
            IHiposwapV2Pair pair = IHiposwapV2Pair(HiposwapV2Library.makerPairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            Reserve storage r = rs[address(pair)];
            if (now > r.time.add(10)) {
                (r.reserve0, r.reserve1) = HiposwapV2Library.getReserves(IHiposwapV2Factory(factory).uniswapFactory(), token0, token1);
                r.time = now;
            }
            (uint reserveInput, uint reserveOutput) = input == token0 ? (r.reserve0, r.reserve1) : (r.reserve1, r.reserve0);
            (uint makerReserveInput, uint makerReserveOut) = HiposwapV2Library.getMakerReserves(factory, input, output);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(makerReserveInput);
            amountOutput = HiposwapV2Library.getAmountOut(amountInput / 10, reserveInput, reserveOutput, pair.getRemainPercent(), pair.getTotalPercent()).mul(10);
            require(amountOutput <= makerReserveOut, "HiposwapV2Pair: INSUFFICIENT_OUTPUT_AMOUNT");
            if (input == token0) {
                r.reserve0 = r.reserve0.add(amountInput / 10);
                r.reserve1 = r.reserve1.sub(amountOutput / 10);
            } else {
                r.reserve1 = r.reserve1.add(amountInput / 10);
                r.reserve0 = r.reserve0.sub(amountOutput / 10);
            }
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? HiposwapV2Library.makerPairFor(factory, output, path[i + 2]) : _to;
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
            path[0], msg.sender, HiposwapV2Library.makerPairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'HiposwapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
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
        require(path[0] == WETH, 'HiposwapV2Router: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(HiposwapV2Library.makerPairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'HiposwapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        require(path[path.length - 1] == WETH, 'HiposwapV2Router: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, HiposwapV2Library.makerPairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'HiposwapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }
    

    
    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return HiposwapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getMakerAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint makerReserve, uint remainPercent, uint totalPercent) external pure virtual override
        returns (uint amountOut) {
        return HiposwapV2Library.getMakerAmountOut(amountIn, reserveIn, reserveOut, makerReserve, remainPercent, totalPercent);
    }

    function getMakerAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint makerReserve, uint remainPercent, uint totalPercent) external pure virtual override
        returns (uint amountIn) {
        return HiposwapV2Library.getMakerAmountIn(amountOut, reserveIn, reserveOut, makerReserve, remainPercent, totalPercent);
    }

    // function getMakerAmountsOut(uint amountIn, address[] calldata path) external view virtual override
    //     returns (uint[] memory amounts) {
    //     return HiposwapV2Library.getMakerAmountsOut(factory, IHiposwapV2Factory(factory).uniswapFactory(), amountIn, path);
    // }

    // function getMakerAmountsIn(uint amountOut, address[] calldata path) external view virtual override
    //     returns (uint[] memory amounts) {
    //     return HiposwapV2Library.getMakerAmountsIn(factory, IHiposwapV2Factory(factory).uniswapFactory(), amountOut, path);
    // }
    
    function getHipoReserves(address tokenA, address tokenB) external view virtual override returns (uint r0, uint r1){
        Reserve memory r = rs[HiposwapV2Library.makerPairFor(factory, tokenA, tokenB)];
        (r0, r1) = (r.reserve0, r.reserve1);
    }
    
    function getMakerAmountsOut(uint amountIn, address[] calldata path) external view virtual override returns (uint[] memory amounts) {
        require(path.length >= 2, 'HiposwapV2Router: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            IHiposwapV2Pair pair = IHiposwapV2Pair(HiposwapV2Library.makerPairFor(factory, path[i], path[i + 1]));
            Reserve memory r = rs[address(pair)];
            uint r0 = r.reserve0;
            uint r1 = r.reserve1;
            if (now > r.time.add(MIN_RESERVE_UPDATE_TIME)) {
                (address token0, address token1) = HiposwapV2Library.sortTokens(path[i], path[i + 1]);
                (r0, r1) = HiposwapV2Library.getReserves(IHiposwapV2Factory(factory).uniswapFactory(), token0, token1);
            }
            (uint reserveIn, uint reserveOut) = path[i] < path[i + 1] ? (r0, r1) : (r1, r0);
            (, uint makerReserveOut) = HiposwapV2Library.getMakerReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = HiposwapV2Library.getMakerAmountOut(amounts[i], reserveIn, reserveOut, makerReserveOut, pair.getRemainPercent(), pair.getTotalPercent());
        }
    }
    
    function getMakerAmountsIn(uint amountOut, address[] calldata path) external view virtual override returns (uint[] memory amounts) {
        require(path.length >= 2, 'HiposwapV2Router: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            IHiposwapV2Pair pair = IHiposwapV2Pair(HiposwapV2Library.makerPairFor(factory, path[i - 1], path[i]));
            Reserve memory r = rs[address(pair)];
            uint r0 = r.reserve0;
            uint r1 = r.reserve1;
            if (now > r.time.add(MIN_RESERVE_UPDATE_TIME)) {
                (address token0, address token1) = HiposwapV2Library.sortTokens(path[i - 1], path[i]);
                (r0, r1) = HiposwapV2Library.getReserves(IHiposwapV2Factory(factory).uniswapFactory(), token0, token1);
            }
            (uint reserveIn, uint reserveOut) = path[i - 1] < path[i] ? (r0, r1) : (r1, r0);
            (, uint makerReserveOut) = HiposwapV2Library.getMakerReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = HiposwapV2Library.getMakerAmountIn(amounts[i], reserveIn, reserveOut, makerReserveOut, pair.getRemainPercent(), pair.getTotalPercent());
        }
    }
    
    function getMakerAmountsOutUpdateReserve(uint amountIn, address[] memory path) internal returns (uint[] memory amounts) {
        require(path.length >= 2, 'HiposwapV2Router: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            IHiposwapV2Pair pair = IHiposwapV2Pair(HiposwapV2Library.makerPairFor(factory, path[i], path[i + 1]));
            Reserve storage r = rs[address(pair)];
            if (now > r.time.add(MIN_RESERVE_UPDATE_TIME)) {
                (address token0, address token1) = HiposwapV2Library.sortTokens(path[i], path[i + 1]);
                (r.reserve0, r.reserve1) = HiposwapV2Library.getReserves(IHiposwapV2Factory(factory).uniswapFactory(), token0, token1);
                r.time = now;
            }
            (uint reserveIn, uint reserveOut) = path[i] < path[i + 1] ? (r.reserve0, r.reserve1) : (r.reserve1, r.reserve0);
            (, uint makerReserveOut) = HiposwapV2Library.getMakerReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = HiposwapV2Library.getMakerAmountOut(amounts[i], reserveIn, reserveOut, makerReserveOut, pair.getRemainPercent(), pair.getTotalPercent());
            if (path[i] < path[i + 1]) {
                r.reserve0 = r.reserve0.add(amounts[i] / 10);
                r.reserve1 = r.reserve1.sub(amounts[i + 1] / 10);
            } else {
                r.reserve1 = r.reserve1.add(amounts[i] / 10);
                r.reserve0 = r.reserve0.sub(amounts[i + 1] / 10);
            }
        }
    }
    
    function getMakerAmountsInUpdateReserve(uint amountOut, address[] memory path) internal returns (uint[] memory amounts) {
        require(path.length >= 2, 'HiposwapV2Router: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            IHiposwapV2Pair pair = IHiposwapV2Pair(HiposwapV2Library.makerPairFor(factory, path[i - 1], path[i]));
            Reserve storage r = rs[address(pair)];
            if (now > r.time.add(MIN_RESERVE_UPDATE_TIME)) {
                (address token0, address token1) = HiposwapV2Library.sortTokens(path[i - 1], path[i]);
                (r.reserve0, r.reserve1) = HiposwapV2Library.getReserves(IHiposwapV2Factory(factory).uniswapFactory(), token0, token1);
                r.time = now;
            }
            (uint reserveIn, uint reserveOut) = path[i - 1] < path[i] ? (r.reserve0, r.reserve1) : (r.reserve1, r.reserve0);
            (, uint makerReserveOut) = HiposwapV2Library.getMakerReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = HiposwapV2Library.getMakerAmountIn(amounts[i], reserveIn, reserveOut, makerReserveOut, pair.getRemainPercent(), pair.getTotalPercent());
            
            if (path[i - 1] < path[i]) {
                r.reserve0 = r.reserve0.add(amounts[i - 1] / 10);
                r.reserve1 = r.reserve1.sub(amounts[i] / 10);
            } else {
                r.reserve1 = r.reserve1.add(amounts[i - 1] / 10);
                r.reserve0 = r.reserve0.sub(amounts[i] / 10);
            }
        }
    }
    
}