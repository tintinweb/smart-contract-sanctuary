pragma solidity =0.6.6;

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

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
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

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
}

interface UniswapOracleProxy {
    function quote(address tokenIn, address tokenOut, uint amountIn) external view returns (uint);
}

interface UniswapRouter {
    function quote(uint amountA, uint reserveA, uint reserveB) external view returns (uint amountB);
}

contract UniswapInsuranceQuote {
    using SafeMath for uint;
    UniswapOracleProxy constant ORACLE = UniswapOracleProxy(0x0b5A6b318c39b60e7D8462F888e7fbA89f75D02F);
    UniswapRouter constant ROUTER = UniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    function getReserves(IUniswapV2Pair pair, address tokenOut) public view returns (uint, uint) {
        (uint _reserve0, uint _reserve1,) = pair.getReserves();
        if (tokenOut == pair.token1()) {
            return (_reserve0, _reserve1);
        } else {
            return (_reserve1, _reserve0);
        }
    }
    
    function oracleQuoteOnly(IUniswapV2Pair pair, address tokenOut, uint amountIn) external view returns (uint) {
        (uint _amountIn, uint _baseOut, address _tokenIn) = calculateReturn(pair, amountIn);
        
        if (_tokenIn == tokenOut) {
            _tokenIn = pair.token1();
            uint _temp = _amountIn;
            _amountIn = _baseOut;
            _baseOut = _temp;
        }
        return ORACLE.quote(_tokenIn, tokenOut, _amountIn);
    }
    
    function routerQuoteOnly(IUniswapV2Pair pair, address tokenOut, uint amountIn) external view returns (uint) {
        (uint _amountIn, uint _baseOut, address _tokenIn) = calculateReturn(pair, amountIn);
        (uint _reserveA, uint _reserveB) = getReserves(pair, tokenOut);
        
        if (_tokenIn == tokenOut) {
            _tokenIn = pair.token1();
            uint _temp = _amountIn;
            _amountIn = _baseOut;
            _baseOut = _temp;
        }
        return ROUTER.quote(_amountIn, _reserveA, _reserveB);
    }
    
    function calculateReturn(IUniswapV2Pair pair, uint amountIn) public view returns (uint balanceA, uint balanceB, address tokenA) {
        tokenA = pair.token0();
        address _tokenB = pair.token1();
        balanceA = IERC20(tokenA).balanceOf(address(pair));
        balanceB = IERC20(_tokenB).balanceOf(address(pair));
        uint _totalSupply = pair.totalSupply();
        
        balanceA = balanceA.mul(amountIn).div(_totalSupply);
        balanceB = balanceB.mul(amountIn).div(_totalSupply);
    }
    
    function quote(IUniswapV2Pair pair, address tokenOut, uint amountIn) external view returns (uint) {
        (uint _amountIn, uint _baseOut, address _tokenIn) = calculateReturn(pair, amountIn);
        (uint _reserveA, uint _reserveB) = getReserves(pair, tokenOut);
        
        if (_tokenIn == tokenOut) {
            _tokenIn = pair.token1();
            uint _temp = _amountIn;
            _amountIn = _baseOut;
            _baseOut = _temp;
        }
        uint _quote1 = ORACLE.quote(_tokenIn, tokenOut, _amountIn);
        uint _quote2 = ROUTER.quote(_amountIn, _reserveA, _reserveB);
        uint _quote = Math.max(_quote1, _quote2);
        return _baseOut.add(_quote);
    }
}