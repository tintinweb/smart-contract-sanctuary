/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

// Dependency file: @uniswap/lib/contracts/libraries/TransferHelper.sol

// pragma solidity >=0.6.0;

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


// Dependency file: contracts/interfaces/ITaalBridge.sol

// pragma solidity >=0.6.2;

interface ITaalBridge {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function WTAL() external pure returns (address);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint amountOutMinX,
        address[] calldata pathx,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        uint amountOutX,
        address[] calldata pathx,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        uint amountOutMinX,
        address[] calldata pathx,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        uint amountOutX,
        address[] calldata pathx,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint amountOutMinX,
        address[] calldata pathx,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        uint amountOutX,
        address[] calldata pathx,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint amountOutMinX,
        address[] calldata pathx,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        uint amountOutMinX,
        address[] calldata pathx,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint amountOutMinX,
        address[] calldata pathx,
        address to,
        uint deadline
    ) external;
}


// Dependency file: contracts/libraries/SafeMath.sol

// pragma solidity =0.6.6;

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


// Dependency file: taalswap-core/contracts/interfaces/ITaalPair.sol

// pragma solidity >=0.5.0;

interface ITaalPair {
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


// Dependency file: contracts/libraries/TaalLibrary.sol

// pragma solidity >=0.5.0;

// import '/Users/peter/Documents/develop/taalswap-periphery/node_modules/taalswap-core/contracts/interfaces/ITaalPair.sol';

// import "contracts/libraries/SafeMath.sol";

library TaalLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'TaalLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'TaalLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                // init code hash
                // hex'e91389f3e161a2ac9db6e5380c1750a30dfe06b6685cb0b61800599094cdfc92'        // Mainnet
                hex'84a2a9c191a42b0a806d1a4cc9cd6f883edd8081be5ad3a58393bcc2984aadd7'        // Ropsten
                // hex'c7185d17dddb851bbf0dc38ead1e9d917434a22bfdf5838d6d340e536c11ee99'        // Klaytn
                // hex'c4d074200a9f2cb31991155eea9423bc813f6acd85ee962a64f55032cf46f6b5'       // Baobab
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = ITaalPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'TaalLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'TaalLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'TaalLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'TaalLibrary: INSUFFICIENT_LIQUIDITY');
//        uint amountInWithFee = amountIn.mul(998);
        uint amountInWithFee = amountIn.mul(9975);
        uint numerator = amountInWithFee.mul(reserveOut);
//        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'TaalLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'TaalLibrary: INSUFFICIENT_LIQUIDITY');
//        uint numerator = reserveIn.mul(amountOut).mul(1000);
//        uint denominator = reserveOut.sub(amountOut).mul(998);
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(9975);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'TaalLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'TaalLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}


// Dependency file: contracts/interfaces/IERC20.sol

// pragma solidity >=0.5.0;

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


// Dependency file: contracts/interfaces/IWETH.sol

// pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// Dependency file: contracts/interfaces/IWTAL.sol

// pragma solidity >=0.5.0;

interface IWTAL {
    function deposit(uint) external returns(bool);
    function withdraw(uint) external returns (bool);
}


// Root file: contracts/XSwapBridge.sol

pragma solidity =0.6.6;

// import '/Users/peter/Documents/develop/taalswap-periphery/node_modules/@uniswap/lib/contracts/libraries/TransferHelper.sol';
// import 'contracts/interfaces/ITaalBridge.sol';
// import 'contracts/libraries/SafeMath.sol';
// import '/Users/peter/Documents/develop/taalswap-periphery/node_modules/taalswap-core/contracts/interfaces/ITaalPair.sol';
// import 'contracts/libraries/TaalLibrary.sol';
// import 'contracts/interfaces/IERC20.sol';
// import 'contracts/interfaces/IWETH.sol';
// import 'contracts/interfaces/IWTAL.sol';

contract XSwapBridge is ITaalBridge {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WETH;
    address public immutable override WTAL;
    address public immutable bridgeOperator;

    event SwapExactETHForTokens(        // -> xswapExactTokensForTokens
        address indexed to,
        uint indexed amountIn,
        uint indexed amountOutMin,
        address[] pathx
    );
    event SwapETHForExactTokens(        // -> xswapTokensForExactTokens
        address indexed to,
        uint indexed amountOut,
        uint indexed amountInMax,
        address[] pathx
    );
    event SwapTokensForExactETH(        // -> x
        address indexed to,
        uint indexed amountOut,
        uint indexed amountInMax,
        address[] pathx
    );
    event SwapExactTokensForETH(        // -> x
        address indexed to,
        uint indexed amountIn,
        uint indexed amountOutMin,
        address[] pathx
    );
    event SwapExactTokensForTokens(     // -> x
        address indexed to,
        uint indexed amountIn,
        uint indexed amountOutMin,
        address[] pathx
    );
    event SwapTokensForExactTokens(     // -> x
        address indexed to,
        uint indexed amountOut,
        uint indexed amountInMax,
        address[] pathx
    );
    event SwapExactTokensForTokensSupportingFeeOnTransferTokens(        // -> xswapExactTokensForTokens
        address indexed to,
        uint indexed amountIn,
        uint indexed amountOutMin,
        address[] pathx
    );
    event SwapExactETHForTokensSupportingFeeOnTransferTokens(           // -> xswapExactTokensForTokens
        address indexed to,
        uint indexed amountIn,
        uint indexed amountOutMin,
        address[] pathx
    );
    event SwapExactTokensForETHSupportingFeeOnTransferTokens(           // -< swapExactTokensForETH
        address indexed to,
        uint indexed amountIn,
        uint indexed amountOutMin,
        address[] pathx
    );

    event  SetBridge(address indexed _bridge);

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'XSwapBridge: EXPIRED');
        _;
    }

    modifier limitedAccess() {
        require(msg.sender == bridgeOperator,
            'XSwapBridge: only limited access allowed');
        _;
    }

    constructor(address _factory, address _WETH, address _WTAL, address _bridge) public {
        factory = _factory;
        WETH = _WETH;
        WTAL = _WTAL;
        bridgeOperator = _bridge;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual
    {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = TaalLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? TaalLibrary.pairFor(factory, output, path[i + 2]) : _to;
            ITaalPair(TaalLibrary.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint amountOutMinX,
        address[] calldata pathx,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts)
    {
        // Always TAL is output
        amounts = TaalLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'XSwapBridge: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, TaalLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        // _swap(amounts, path, to);
        _swap(amounts, path, address(this));
        uint amountOut = amounts[amounts.length - 1];
        TransferHelper.safeTransfer(
            path[path.length - 1], WTAL, amountOut
        );

        emit SwapExactTokensForTokens(to, amountOut, amountOutMinX, pathx);
    }
    function xswapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) limitedAccess returns (uint[] memory amounts)
    {
        // Always TAL is input
        amounts = TaalLibrary.getAmountsOut(factory, amountIn, path);
        // 아래 조건으로 인해 실행이 안될 경우는 ?
        // 무조건 성공하개 처리...
        // require(amounts[amounts.length - 1] >= amountOutMin, 'XSwapBridge: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], WTAL, address(this), amounts[0]
        );
        require(IERC20(path[0]).balanceOf(address(this)) >= amounts[0], 'XSwapBridge: WTAL_WITHDRAW_FAILED');
        TransferHelper.safeTransfer(
            path[0], TaalLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        uint amountOutX,
        address[] calldata pathx,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts)
    {
        // Always TAL is output
        amounts = TaalLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'XSwapBridge: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, TaalLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        // _swap(amounts, path, to);
        _swap(amounts, path, address(this));
        uint amountOutRlt = amounts[amounts.length - 1];
        TransferHelper.safeTransfer(
            path[path.length - 1], WTAL, amountOutRlt
        );
        emit SwapTokensForExactTokens(to, amountOutX, amountOutRlt, pathx);
    }
    // 당분간 사용안함...
    function xswapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) limitedAccess returns (uint[] memory amounts)
    {
        // Always TAL is input
        amounts = TaalLibrary.getAmountsIn(factory, amountOut, path);
        // 아래 조건으로 인해 실행이 안될 경우는 ?
        require(amounts[0] <= amountInMax, 'XSwapBridge: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], WTAL, address(this), amounts[0]
        );
        require(IERC20(path[0]).balanceOf(address(this)) >= amounts[0], 'XSwapBridge: WTAL_WITHDRAW_FAILED');
        TransferHelper.safeTransfer(
            path[0], TaalLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        uint amountOutMinX,
        address[] calldata pathx,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint[] memory amounts)
    {
        // Always TAL is output
        require(path[0] == WETH, 'XSwapBridge: INVALID_PATH');
        amounts = TaalLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'XSwapBridge: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(TaalLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        // _swap(amounts, path, to);
        _swap(amounts, path, address(this));
        uint amountOut = amounts[amounts.length - 1];
        TransferHelper.safeTransfer(
            path[path.length - 1], WTAL, amountOut
        );
        emit SwapExactETHForTokens(to, amountOut, amountOutMinX, pathx);
        // => xswapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    }

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        uint amountOutX,
        address[] calldata pathx,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts)
    {
        // Always TAL is output
        // require(path[path.length - 1] == WETH, 'XSwapBridge: INVALID_PATH');
        amounts = TaalLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'XSwapBridge: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, TaalLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        // IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        // TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
        uint amountOutRlt = amounts[amounts.length - 1];
        TransferHelper.safeTransfer(
            path[path.length - 1], WTAL, amountOutRlt
        );
        emit SwapTokensForExactETH(to, amountOutX, amountOutRlt, pathx);
    }
    // 당분간 사용안함...
    function xswapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) limitedAccess returns (uint[] memory amounts)
    {
        // Always TAL is input
        require(path[path.length - 1] == WETH, 'XSwapBridge: INVALID_PATH');
        amounts = TaalLibrary.getAmountsIn(factory, amountOut, path);
        // 아래 조건으로 인해 실행이 안될 경우는 ?
        require(amounts[0] <= amountInMax, 'XSwapBridge: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], WTAL, address(this), amounts[0]
        );
        require(IERC20(path[0]).balanceOf(address(this)) >= amounts[0], 'XSwapBridge: WTAL_WITHDRAW_FAILED');
        TransferHelper.safeTransfer(
            path[0], TaalLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint amountOutMinX,
        address[] calldata pathx,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts)
    {
        // Always TAL is output
        // require(path[path.length - 1] == WETH, 'XSwapBridge: INVALID_PATH');
        amounts = TaalLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'XSwapBridge: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, TaalLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        // IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        // TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
        uint amountOut = amounts[amounts.length - 1];
        TransferHelper.safeTransfer(
            path[path.length - 1], WTAL, amountOut
        );
        emit SwapExactTokensForETH(to, amountOut, amountOutMinX, pathx);
    }
    function xswapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) limitedAccess returns (uint[] memory amounts)
    {
        // Always TAL is input
        // require(path[path.length - 1] == WETH, 'XSwapBridge: INVALID_PATH');
        amounts = TaalLibrary.getAmountsOut(factory, amountIn, path);
        // 아래 조건으로 인해 실행이 안될 경우는 ?
        // 무조건 성공하게 처리...
        // require(amounts[amounts.length - 1] >= amountOutMin, 'XSwapBridge: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], WTAL, address(this), amounts[0]
        );
        require(IERC20(path[0]).balanceOf(address(this)) >= amounts[0], 'XSwapBridge: WTAL_WITHDRAW_FAILED');
        TransferHelper.safeTransfer(
            path[0], TaalLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        uint amountOutX,
        address[] calldata pathx,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint[] memory amounts)
    {
        // Always TAL is output
        require(path[0] == WETH, 'XSwapBridge: INVALID_PATH');
        amounts = TaalLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'XSwapBridge: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(TaalLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        // _swap(amounts, path, to);
        _swap(amounts, path, address(this));
        uint amountOutRlt = amounts[amounts.length - 1];
        TransferHelper.safeTransfer(
            path[path.length - 1], WTAL, amountOutRlt
        );
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
        emit SwapETHForExactTokens(to, amountOutX, amountOutRlt, pathx);
        // => xswapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(
        address[] memory path,
        address _to
    ) internal virtual
    {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = TaalLibrary.sortTokens(input, output);
            ITaalPair pair = ITaalPair(TaalLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1,) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = TaalLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? TaalLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint amountOutMinX,
        address[] calldata pathx,
        address to,
        uint deadline
    ) external virtual override ensure(deadline)
    {
        // Always TAL is output
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, TaalLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        // uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        // _swapSupportingFeeOnTransferTokens(path, to);
        // require(
        //    IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
        //    'XSwapBridge: INSUFFICIENT_OUTPUT_AMOUNT'
        //);
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(path[path.length - 1]).balanceOf(address(this)).sub(balanceBefore);
        require(
            amountOut >= amountOutMin,
            'XSwapBridge: INSUFFICIENT_OUTPUT_AMOUNT'
        );
        TransferHelper.safeTransfer(
            path[path.length - 1], WTAL, amountOut
        );
        emit SwapExactTokensForTokensSupportingFeeOnTransferTokens(to, amountOut, amountOutMinX, pathx);
        // => xswapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        uint amountOutMinX,
        address[] calldata pathx,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline)
    {
        // Always TAL is output
        require(path[0] == WETH, 'XSwapBridge: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(TaalLibrary.pairFor(factory, path[0], path[1]), amountIn));
        // uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        // _swapSupportingFeeOnTransferTokens(path, to);
        // uint amountOut = IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore);
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(path[path.length - 1]).balanceOf(address(this)).sub(balanceBefore);
        require(
            amountOut >= amountOutMin,
            'XSwapBridge: INSUFFICIENT_OUTPUT_AMOUNT'
        );
        TransferHelper.safeTransfer(
            path[path.length - 1], WTAL, amountOut
        );
        emit SwapExactETHForTokensSupportingFeeOnTransferTokens(to, amountOut, amountOutMinX, pathx);
        // => xswapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint amountOutMinX,
        address[] calldata pathx,
        address to,
        uint deadline
    ) external virtual override ensure(deadline)
    {
        // Always TAL is output
        require(path[path.length - 1] == WETH, 'XSwapBridge: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, TaalLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        // _swapSupportingFeeOnTransferTokens(path, address(this));
        // uint amountOut = IERC20(WETH).balanceOf(address(this));
        // require(amountOut >= amountOutMin, 'XSwapBridge: INSUFFICIENT_OUTPUT_AMOUNT');
        // IWETH(WETH).withdraw(amountOut);
        // TransferHelper.safeTransferETH(to, amountOut);
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(path[path.length - 1]).balanceOf(address(this)).sub(balanceBefore);
        require(
            amountOut >= amountOutMin,
            'XSwapBridge: INSUFFICIENT_OUTPUT_AMOUNT'
        );
        TransferHelper.safeTransfer(
            path[path.length - 1], WTAL, amountOut
        );
        emit SwapExactTokensForETHSupportingFeeOnTransferTokens(to, amountOut, amountOutMinX, pathx);
        // => xswapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) public pure virtual override returns (uint amountB)
    {
        return TaalLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) public pure virtual override returns (uint amountOut)
    {
        return TaalLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) public pure virtual override returns (uint amountIn)
    {
        return TaalLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) public view virtual override returns (uint[] memory amounts)
    {
        return TaalLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(
        uint amountOut,
        address[] memory path
    ) public view virtual override returns (uint[] memory amounts)
    {
        return TaalLibrary.getAmountsIn(factory, amountOut, path);
    }

//    function setBridgeOp(address _bridge) public onlyOwner {
//        bridgeOperator = _bridge;
//        emit SetBridge(_bridge);
//    }
}