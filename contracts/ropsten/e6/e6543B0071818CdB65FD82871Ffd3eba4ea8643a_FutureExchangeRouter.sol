pragma solidity ^0.8.0;
import "../common/ERC20.sol";
import "./interfaces/ILiquidityToken.sol";

contract LiquidityToken is ILiquidityToken, ERC20 {
    constructor() ERC20("Liquidity Token", "LQT", 18) public {
    }
     
    function mint(address to, uint256 amount) external override onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external override onlyOwner {
        _burn(msg.sender, amount);
    }
}

pragma solidity ^0.8.0;
import "../../common/interfaces/IERC20.sol";

interface ILiquidityToken is IERC20{
    
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}

pragma solidity ^0.8.0;
import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "./Ownable.sol";

contract ERC20 is IERC20, Ownable {
    string public override name;
    string public override symbol;
    uint8 public override decimals;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    uint256 public override totalSupply;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowance[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {_approve(sender, msg.sender, currentAllowance - amount);}

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Error: transfer from the zero address");
        require(recipient != address(0), "Error: transfer to the zero address");

        uint256 senderBalance = balanceOf[sender];
        require(senderBalance >= amount, "Error: transfer amount exceeds balance");
        unchecked {balanceOf[sender] = senderBalance - amount;}
        balanceOf[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Error: mint to the zero address");

        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Error: burn from the zero address");

        uint256 accountBalance = balanceOf[account];
        require(accountBalance >= amount, "Error: burn amount exceeds balance");
        unchecked {balanceOf[account] = accountBalance - amount;}
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Error: approve from the zero address");
        require(spender != address(0), "Error: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

pragma solidity ^0.8.0;

import "./interfaces/IOwnable.sol";

abstract contract Ownable is IOwnable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";

interface IERC20 is IERC20Metadata {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

interface IERC20Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
}

pragma solidity ^0.8.0;

import "./interfaces/IFutureExchangeRouter.sol";
import "./interfaces/IWETH.sol";
import "../future-token/interfaces/IFutureTokenFactory.sol";
import "../future-token/interfaces/IFutureToken.sol";
import "../common/interfaces/IERC20.sol";
import "./libraries/PrecogV2Library.sol";
import "./libraries/SafeMath.sol";
import "../LiquidityToken/interfaces/ILiquidityToken.sol";
import "../LiquidityToken/LiquidityToken.sol";

contract FutureExchangeRouter is IFutureExchangeRouter {
    using SafeMath for uint256;

    address public override futureTokenFactory;
    address public weth;
    
    
    mapping(address => address[]) listFutureTokensInPair;
    mapping(address => address) getLiquidityToken;
    
    constructor(address _futureTokenFactory, address _weth) {
        futureTokenFactory = _futureTokenFactory;
        weth = _weth;
    }

    receive() external payable {
        assert(msg.sender == weth); // only accept ETH via fallback from the WETH contract
    }
    
    function getListFutureTokensInPair(address token) external view override returns(address[] memory) {
        return listFutureTokensInPair[token];
    }
   

    function isFutureToken(
        address tokenA,
        address tokenB,
        uint256 expiryDate
    ) internal view returns (address) {
        address futureToken = IFutureTokenFactory(futureTokenFactory).getFutureToken(tokenA, tokenB, expiryDate);
        require(futureToken != address(0), "Future Exchange Router: FUTURE_TOKEN_DOES_NOT_EXISTS");
        return futureToken;
    }
   

    function addLiquidityFuture(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 expiryDate
    ) override external {
        address futureToken = IFutureTokenFactory(futureTokenFactory).getFutureToken(tokenA, tokenB, expiryDate);
        
        if (futureToken == address(0)) {
            futureToken = IFutureTokenFactory(futureTokenFactory).createFutureToken(tokenA, tokenB, expiryDate);
            listFutureTokensInPair[tokenA].push(futureToken);
            listFutureTokensInPair[tokenB].push(futureToken);
        }
        
        uint256 reserveA = IERC20(tokenA).balanceOf(futureToken);
        uint256 reserveB = IERC20(tokenB).balanceOf(futureToken);
        if (reserveA != 0 && reserveB != 0) {
            require(
                reserveB != PrecogV2Library.quote(amountA, reserveA, reserveB), 
                "Future Exchange Router: LIQUIDITY_AMOUNT_INVALID"
            );   
        }
        address liquidityToken = getLiquidityToken[futureToken];
        uint256 liquiditySupply = ILiquidityToken(liquidityToken).totalSupply();
        uint256 liquidityAmount;
        if (liquiditySupply == 0){
            liquidityAmount = sqrt(reserveA*reserveB);
            ILiquidityToken(liquidityToken).mint(msg.sender, liquidityAmount);
        }
        else{
            liquidityAmount = liquiditySupply * amountA / reserveA;
            ILiquidityToken(liquidityToken).mint(msg.sender, liquidityAmount);
        }
        IERC20(tokenA).transferFrom(msg.sender, futureToken, amountA);
        IERC20(tokenB).transferFrom(msg.sender, futureToken, amountB);
    }
    
    function withdrawLiquidityFuture(address futureToken, uint256 amountLiquidity, address to) override external {
        address liquidityToken = getLiquidityToken[futureToken];
        
        uint256 liquidityTokenSupply = ILiquidityToken(liquidityToken).totalSupply();
        
        ILiquidityToken(liquidityToken).transferFrom(msg.sender, futureToken, amountLiquidity);
        
        (uint256 reserveA, uint256 reserveB) = IFutureToken(futureToken).getReserves();
                
        address tokenA = IFutureToken(futureToken).token0();
        address tokenB = IFutureToken(futureToken).token1();
        
        uint256 amountA = (reserveA * amountLiquidity)/liquidityTokenSupply;
        uint256 amountB = (reserveB * amountLiquidity)/liquidityTokenSupply;
        
        ILiquidityToken(liquidityToken).burn(amountLiquidity);
        
        IERC20(tokenA).transferFrom(futureToken, to, amountA);
        IERC20(tokenB).transferFrom(futureToken, to, amountB);
    }

    function sqrt(uint x) internal pure returns (uint){
       uint n = x / 2;
       uint lstX = 0;
       while (n != lstX){
           lstX = n;
           n = (n + x/n) / 2; 
       }
       return uint(n);
   }
    
    function swapFuture(
        address tokenIn,
        address tokenOut,
        uint256 expiryDate,
        address to,
        uint256 amountIn
    ) external override {
        address futureToken = isFutureToken(tokenIn, tokenOut, expiryDate);
        uint256 amountOut = getAmountsOutFuture(amountIn, tokenIn, tokenOut, expiryDate);
        uint256 amountMint = getAmountMint(futureToken, tokenOut, amountOut);
        IERC20(tokenIn).transferFrom(msg.sender, futureToken, amountIn);
        IFutureTokenFactory(futureTokenFactory).transferFromFuture(tokenOut, futureToken, address(this), amountOut);
        IFutureTokenFactory(futureTokenFactory).mintFuture(futureToken, to, amountMint);
    }
    
    function closeFuture(
        address tokenIn,
        address tokenOut,
        uint256 expiryDate,
        address to,
        uint256 amountOut
    ) external override {
        address futureToken = isFutureToken(tokenIn, tokenOut, expiryDate);
        uint256 amountMinted = getAmountMint(futureToken, tokenOut, amountOut);
        IERC20(futureToken).transferFrom(msg.sender, futureTokenFactory, amountMinted);
        IFutureTokenFactory(futureTokenFactory).burnFuture(futureToken, amountMinted);
        IERC20(tokenOut).transfer(to, amountOut);
    }

    function getAmountMint(address futureToken, address tokenOut, uint amountOut) internal view returns(uint amountMint) {
        amountMint = amountOut;
        uint256 decimalFuture = IERC20(futureToken).decimals();
        uint256 decimalOut = IERC20(tokenOut).decimals();        
        if (decimalFuture > decimalOut) 
            amountMint *= 10 ** (decimalFuture - decimalOut);
        if (decimalFuture < decimalOut) 
            amountMint /= 10 ** (decimalOut - decimalFuture);
    }

    // **** LIBRARY FUNCTIONS ****
    function getAmountsOutFuture(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        uint256 deadline
    ) public view override returns (uint256) {
        return PrecogV2Library.getAmountsOutFuture(futureTokenFactory, amountIn, tokenIn, tokenOut, deadline);
    }

    function getAmountsInFuture(
        uint256 amountOut,
        address tokenIn,
        address tokenOut,
        uint256 deadline
    ) public view override returns (uint256) {
        return PrecogV2Library.getAmountsInFuture(futureTokenFactory, amountOut, tokenIn, tokenOut, deadline);
    }
    
}

pragma solidity ^0.8.0;

interface IFutureExchangeRouter {
    
    function futureTokenFactory() external view returns (address);
    
    function getListFutureTokensInPair(address token) external view returns(address[] memory);
    
    function getAmountsOutFuture(uint256 amountIn, address tokenIn, address tokenOut, uint256 deadline) external view returns (uint256);
    
    function getAmountsInFuture(uint256 amountOut, address tokenIn, address tokenOut, uint256 deadline) external view returns (uint256);
    
    function addLiquidityFuture(address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 deadline) external;
    
    function withdrawLiquidityFuture(address liquidityToken, uint256 amountLiquidity, address to) external;
    
    function swapFuture(address tokenA, address tokenB, uint deadline, address to, uint amount) external;
    
    function closeFuture(address tokenA, address tokenB, uint deadline, address to, uint amount) external;
}

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

pragma solidity ^0.8.0;

import "../../future-token/interfaces/IFutureTokenFactory.sol";
import "../../future-token/interfaces/IFutureToken.sol";

import "./SafeMath.sol";

library PrecogV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "PrecogV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "PrecogV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            bytes20(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"8bbe3b87a8ff316d03607692c9e315540483dd03b2a3eff7147a4e04f4503f25" // init code hash
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReservesFuture(
        address factory,
        address tokenA,
        address tokenB,
        uint256 deadline
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        address futureToken =
            IFutureTokenFactory(factory).getFutureToken(
                tokenA,
                tokenB,
                deadline
            );
        (uint256 reserve0, uint256 reserve1) =
            IFutureToken(futureToken).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "PrecogV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "PrecogV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "PrecogV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "PrecogV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "PrecogV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "PrecogV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOutFuture(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "PrecogV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "PrecogV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = amountIn.mul(reserveOut);
        uint256 denominator = reserveIn.add(amountIn);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountInFuture(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "PrecogV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "PrecogV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut);
        uint256 denominator = reserveOut.sub(amountOut);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOutFuture(
        address factory,
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        uint256 deadline
    ) internal view returns (uint256 amountOut) {
        (uint256 reserveIn, uint256 reserveOut) =
            getReservesFuture(factory, tokenIn, tokenOut, deadline);
        amountOut = getAmountOutFuture(amountIn, reserveIn, reserveOut);
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsInFuture(
        address factory,
        uint256 amountOut,
        address tokenIn,
        address tokenOut,
        uint256 deadline
    ) internal view returns (uint256 amountIn) {
        (uint256 reserveIn, uint256 reserveOut) =
            getReservesFuture(factory, tokenIn, tokenOut, deadline);
        amountIn = getAmountInFuture(amountOut, reserveIn, reserveOut);
    }
}

pragma solidity ^0.8.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

pragma solidity ^0.8.0;

interface IFutureToken {
    function token0() external view returns (address);
    
    function token1() external view returns (address);
    
    function expiryDate() external view returns (uint256);
    
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function getReserves() external view returns (uint256 reserve0, uint256 reserve1);
}

pragma solidity ^0.8.0;

interface IFutureTokenFactory {
    function exchange() external view returns (address);
    
    event futureTokenCreated(
        address indexed token0,
        address indexed token1,
        address futureTokenAddress,
        uint256 i
    );

    function getFutureToken(address tokenA, address tokenB, uint256 deadline) external view returns (address);

    function allFutureTokens(uint256 index) external view returns (address);

    function createFutureToken(address tokenA, address tokenB, uint256 deadline) external returns (address);

    function mintFuture(address futureToken, address to, uint256 amount) external;

    function burnFuture(address futureToken, uint256 amount) external;

    function transferFromFuture(address token, address from, address to, uint256 amount) external;
}

