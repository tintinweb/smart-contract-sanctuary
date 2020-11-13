pragma solidity >=0.4.24;

//import '@uniswap/v2-periphery/contracts/libraries/SafeMath.sol';

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library RB_SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint) {
        require(y != 0);
        return x / y;    
    }
}

library RB_UnsignedSafeMath {
    function add(int x, int y) internal pure returns (int z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(int x, int y) internal pure returns (int z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(int x, int y) internal pure returns (int z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(int x, int y) internal pure returns (int) {
        require(y != 0);
        return x / y;    
    }
}


//import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

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
    function swap(uint amount0Out, uint amount1Out, address to, bytes /* calldata */ data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


/** Calculates the Delta for a rebase based on the ratio
*** between the price of two different token pairs on 
*** Uniswap 
***
*** - minimalist design
*** - low gas design
*** - free for anyone to call. 
***
****/
contract RebaseDelta {

    using RB_SafeMath for uint256;
    using RB_UnsignedSafeMath for int256;
    
    uint256 private constant PRICE_PRECISION = 10**24;

    function getPrice(IUniswapV2Pair pair_, bool flip_) 
    public
    view
    returns (uint256) 
    {
        require(address(pair_) != address(0));

        (uint256 reserves0, uint256 reserves1, ) = pair_.getReserves();

        if (flip_) {
            (reserves0, reserves1) = (reserves1, reserves0);            
        }

        // reserves0 = base (probably ETH/WETH)
        // reserves1 = token of interest (maybe ampleforthgold or paxusgold etc)

        // multiply to equate decimals, multiply up to PRICE_PRECISION

        uint256 price = (reserves1.mul(PRICE_PRECISION)).div(reserves0);

        return price;
    }

    // calculates the supply delta for moving the price of token X to the price
    // of token Y (with the understanding that they are both priced in a common
    // tokens value, i.e. WETH).  
    function calculate(IUniswapV2Pair X_,
                      bool flipX_,
                      uint256 decimalsX_,
                      uint256 SupplyX_, 
                      IUniswapV2Pair Y_,
                      bool flipY_,
                      uint256 decimalsY_)
    public
    view
    returns (int256)
    {
        uint256 px = getPrice(X_, flipX_);
        require(px != uint256(0));
        uint256 py = getPrice(Y_, flipY_);
        require(py != uint256(0));

        uint256 targetSupply = (SupplyX_.mul(py)).div(px);

        // adust for decimals
        if (decimalsX_ == decimalsY_) {
            // do nothing
        }
        else if (decimalsX_ > decimalsY_) {
            uint256 ddg = (10**decimalsX_).div(10**decimalsY_);
            require (ddg != uint256(0));
            targetSupply = targetSupply.mul(ddg); 
        }
        else {
            uint256 ddl = (10**decimalsY_).div(10**decimalsX_);
            require (ddl != uint256(0));
            targetSupply = targetSupply.div(ddl);        
        }

        int256 delta = int256(SupplyX_).sub(int256(targetSupply));

        return delta;
    }
}