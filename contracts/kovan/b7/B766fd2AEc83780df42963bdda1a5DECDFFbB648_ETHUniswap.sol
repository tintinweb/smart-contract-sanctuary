/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

// SPDX-License-Identifier: MIT;

pragma solidity >= 0.6.6;

// import '@uniswap/v2-periphery/contracts/interfaces/IERC20.sol';
// import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
// import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
// import '@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol';
// import './IMasterChef.sol';

contract IMasterChef {
    
    function deposit(uint256 _pid, uint256 _amount) public {}
 
    function withdraw(uint256 _pid, uint256 _amount) public {}

    function emergencyWithdraw(uint256 _pid) public {}
}

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

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

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


contract ETHUniswap {

    bool public successFund;

    event ExchangeTokenToToken(
        uint[] amounts
    );

    event ExchangeTokenToEth(
        uint[] amounts
    );

    event ExchangeEthToToken(
        uint[] amounts
    );

    event AddLiquidity(
        uint amountA,
        uint amountB, 
        uint liquidity
    );

    event AddLiquidityETH(
        uint amountToken,
        uint amountETH, 
        uint liquidity
    );

    event RemoveLiquidity(
        uint amountA,
        uint amountB
    );

    event RemoveLiquidityETH(
        uint amountToken,
        uint amountETH
    );

    IUniswapV2Router02 uniswapRouter02;
    IUniswapV2Factory uniswapFactory;
    // IMasterChef masterChef;

    // receive() external payable {

    // }
    fallback () external payable {

    }

    constructor(IUniswapV2Router02 _uniswapRouter02, IUniswapV2Factory _uniswapFactory/*, IMasterChef _masterChef*/) public {
        uniswapRouter02 = _uniswapRouter02;
        uniswapFactory = _uniswapFactory;
        // masterChef = _masterChef;
    }


       /////////////////////////////// SWAP ///////////////////////////////////////

    function swapTokenToToken(address _tokenA, address _tokenB, uint256 _amountAIn) external {

        require(IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountAIn), 'transferFrom failed.');
        require(IERC20(_tokenA).approve(address(uniswapRouter02), _amountAIn), 'approve failed.');

        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = _tokenB;

        uint[] memory amounts = uniswapRouter02.swapExactTokensForTokens(_amountAIn, 0, path, msg.sender, block.timestamp);

        emit ExchangeTokenToToken(amounts);
    }  

    function swapTokenToEth(address _tokenA, uint256 _amountAIn) external {

        require(IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountAIn), 'transferFrom failed.');
        require(IERC20(_tokenA).approve(address(uniswapRouter02), _amountAIn), 'approve failed.');

        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = uniswapRouter02.WETH();

        uint[] memory amounts = uniswapRouter02.swapExactTokensForETH(_amountAIn, 0, path, msg.sender, block.timestamp);

        emit ExchangeTokenToEth(amounts);
    }

    function swapEthToToken(address _tokenB) external payable {

        address[] memory path = new address[](2);
        path[0] = uniswapRouter02.WETH();
        path[1] = _tokenB;

        uint[] memory amounts = uniswapRouter02.swapExactETHForTokens{value : msg.value}(0, path, msg.sender, block.timestamp);

        emit ExchangeEthToToken(amounts);
    }
 
    function addLiquidity(address _tokenA, address _tokenB, uint _amountADesired, uint _amountBDesired) external {

        require(IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountADesired), 'transferFrom failed.');
        require(IERC20(_tokenA).approve(address(uniswapRouter02), _amountADesired), 'approve failed.');
        
        require(IERC20(_tokenB).transferFrom(msg.sender, address(this), _amountBDesired), 'transferFrom failed.');
        require(IERC20(_tokenB).approve(address(uniswapRouter02), _amountBDesired), 'approve failed.');

        (uint amountA, uint amountB, uint liquidity) = uniswapRouter02.addLiquidity(_tokenA, _tokenB, _amountADesired, _amountBDesired, 0, 0, msg.sender, block.timestamp);

        emit AddLiquidity(amountA, amountB, liquidity);
    }

    function addLiquidityETH(address _token, uint _amountDesired) external payable {
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amountDesired), 'transferFrom failed.');
        require(IERC20(_token).approve(address(uniswapRouter02), _amountDesired), 'approve failed.');

        (uint amountToken, uint amountETH, uint liquidity) = uniswapRouter02.addLiquidityETH{value: msg.value}(_token, _amountDesired, 0, 0, msg.sender, block.timestamp);

        emit AddLiquidityETH(amountToken, amountETH, liquidity);
    }


    function removeLiquidity(address _tokenA, address _tokenB, address _pair, uint _liquidity) external {
        require(IERC20(_pair).transferFrom(msg.sender, _pair, _liquidity), 'transferFrom failed.');
        require(IERC20(_pair).approve(address(uniswapRouter02), _liquidity), 'approve failed.');
        
        (uint amountA, uint amountB) = uniswapRouter02.removeLiquidity(_tokenA, _tokenB, _liquidity, 0, 0, msg.sender, block.timestamp);

        emit RemoveLiquidity(amountA, amountB);
    }

    function removeLiquidityETH(address _token, address _pair, uint _amountDesired) external {

        require(IERC20(_pair).transferFrom(msg.sender, _pair, _amountDesired), 'transferFrom failed.');
        require(IERC20(_pair).approve(address(uniswapRouter02), _amountDesired), 'approve failed.');
        
        (uint amountToken, uint amountETH) = uniswapRouter02.removeLiquidityETH(_token, _amountDesired, 0, 0, msg.sender, block.timestamp);

        emit RemoveLiquidityETH(amountToken, amountETH);
    }

//     /////////////////////////////// Farming ///////////////////////////////////////
    
//     // function depositFarm(uint256 _pid, uint256 _amount) external {
//     //     masterChef.deposit(_pid, _amount);
//     // }

//     // function withdrawFarm(uint256 _pid, uint256 _amount) external {
//     //     masterChef.withdraw(_pid, _amount);
//     // }

//     // function emergencyWithdrawFarm(uint256 _pid) external {
//     //     masterChef.emergencyWithdraw(_pid);
//     // }

//     // function harvestFarm(uint256 _pid) external {
//     //     masterChef.deposit(_pid, 0);
//     // }


    function getPair(address tokenA, address tokenB) external view returns (address pair) {
        return uniswapFactory.getPair(tokenA, tokenB);
    }


//     function getReserves(address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB){
//         return UniswapV2Library.getReserves(address(uniswapFactory), tokenA, tokenB);
//     }


}