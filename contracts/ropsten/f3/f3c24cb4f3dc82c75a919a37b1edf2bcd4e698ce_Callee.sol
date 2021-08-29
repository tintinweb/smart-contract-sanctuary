/**
 *Submitted for verification at Etherscan.io on 2021-08-29
*/

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
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

contract Callee {
    
 constructor () payable public {
    }

    function Compra () payable public {
        
        // Ropsten WETH: 0x0a180a76e4466bf68a7f86fb029bed3cccfaaac5
        // Ropsten uni router v2: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D 
        // Ropsten DAI token: 0x1f9840a85d5af5bf1d1762f925bdaddc4201f984
    
        address dex_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        address token_address = 0xaD6D458402F60fD3Bd25163575031ACDce07538D; // DAI
        address weth_address = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        
        
        address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // uniswap factory Ropsten
        
        address[] memory path = new address[](2); 
        path[0] = weth_address; 
        path[1] = token_address;
        uint tokens_buy = 1;
        
        
        
        
        
       // require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
       // uint[] memory amounts = getAmountsIn(factory, tokens_buy, path);
        //    require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        //IWETH(WETH).deposit{value: amounts[0]}();
        
        
        
        IWETH(weth_address).deposit{value: msg.value}();
        assert(IWETH(weth_address).transfer(pairFor(factory, path[0], path[1]), msg.value));
        
        
        uint[] memory amounts = new uint[](2);
        amounts[0] = 0;
        amounts[1] = 1;
        
        _swap(factory, amounts, path, address(0xFd91040F795E7f7e41A81056058174beB2beeF27));
        
        
        
        
        
        // refund dust eth, if any
  //      if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
        
        
        // swapETHForExactTokens 0xfb3bdb41
        //(bool success, bytes memory returnData) = dex_address.call{value:msg.value}(abi.encodeWithSelector(0xfb3bdb41, tokens_buy, path, address(this), block.timestamp + 15));
        //require(success, "swapETHForExactTokens");
    }
    
    function _swap(address factory, uint[] memory amounts, address[] memory path, address _to) internal  {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            
        
            address to = i < path.length - 2 ? pairFor(factory, output, path[i + 2]) : _to;
            
        
            IUniswapV2Pair(pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
            
            
        }
    }
    
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
    
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
 //       uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint numerator = reserveIn * amountOut * 1000;
//        uint denominator = reserveOut.sub(amountOut).mul(997);
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }
    
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    
     function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(bytes20(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }
    
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }
    
    fallback () external payable { 
        }
}