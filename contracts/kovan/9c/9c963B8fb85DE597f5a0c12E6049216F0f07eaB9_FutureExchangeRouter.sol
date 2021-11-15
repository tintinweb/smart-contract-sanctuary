pragma solidity ^0.8.0;
import "../common/ERC20.sol";
import "./interfaces/ILiquidityToken.sol";

contract LiquidityToken is ILiquidityToken, ERC20 {
    constructor() ERC20("Liquidity Token", "LQT", 18){
    }
    
    function mint(address to, uint256 amount) external override{
        _mint(to, amount);
    }

    function burn(uint256 amount) external override{
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
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
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
import "../future-token/interfaces/IFutureTokenFactory.sol";
import "../future-token/interfaces/IFutureToken.sol";
import "../common/interfaces/IERC20.sol";
import "./libraries/PrecogV2Library.sol";
import "./libraries/SafeMath.sol";
import "../LiquidityToken/interfaces/ILiquidityToken.sol";
import "../LiquidityToken/LiquidityToken.sol";
import "../future-token/interfaces/IFutureContract.sol";


contract FutureExchangeRouter is IFutureExchangeRouter{
    using SafeMath for uint256;

    address public override futureTokenFactory;
    address public weth;

    mapping(address => address[]) listFutureContractsInPair;
    mapping(address => address) getLiquidityToken;

    constructor(address _futureTokenFactory, address _weth) {
        futureTokenFactory = _futureTokenFactory;
        weth = _weth;
    }

    receive() external payable {
        assert(msg.sender == weth); // only accept ETH via fallback from the WETH contract
    }

    function getListFutureContractsInPair(address token)
        external
        view
        override
        returns (address[] memory)
    {
        return listFutureContractsInPair[token];
    }

    function isFutureContract(
        address tokenA,
        address tokenB,
        uint256 expiryDate
    ) internal view returns (address) {
        address futureContract = IFutureTokenFactory(futureTokenFactory).getFutureContract(tokenA, tokenB, expiryDate);
        require(futureContract != address(0), "Future Exchange Router: FUTURE_TOKEN_DOES_NOT_EXISTS");
        return futureContract;
    }

    function addLiquidityFuture(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 expiryDate,
        string memory expirySymbol
    ) external override {
        address futureContract = IFutureTokenFactory(futureTokenFactory).getFutureContract(tokenA, tokenB, expiryDate);
        if (futureContract == address(0)) {
            futureContract = IFutureTokenFactory(futureTokenFactory).createFuture(tokenA, tokenB, expiryDate, expirySymbol);
            listFutureContractsInPair[tokenA].push(futureContract);
            listFutureContractsInPair[tokenB].push(futureContract);
        }
        
        uint256 reserveA = IERC20(tokenA).balanceOf(futureContract);
        uint256 reserveB = IERC20(tokenB).balanceOf(futureContract);
        if (reserveA != 0 && reserveB != 0) {
            require(
                amountB == PrecogV2Library.quote(amountA, reserveA, reserveB),
                "Future Exchange Router: LIQUIDITY_AMOUNT_INVALID"
            );
        }

        address liquidityToken = getLiquidityToken[futureContract];
        if (liquidityToken == address(0)) {
            getLiquidityToken[futureContract] = liquidityToken = address(new LiquidityToken());
        }
        
        uint256 liquiditySupply = ILiquidityToken(liquidityToken).totalSupply();
        uint256 liquidityAmount = liquiditySupply == 0
            ? sqrt(amountA * amountB)
            : (liquiditySupply * amountA) / reserveA;        
        ILiquidityToken(liquidityToken).mint(msg.sender, liquidityAmount);

        IERC20(tokenA).transferFrom(msg.sender, futureContract, amountA);
        IERC20(tokenB).transferFrom(msg.sender, futureContract, amountB);
    }
    
    function withdrawLiquidityFuture(
        address tokenA,
        address tokenB,
        uint256 expiryDate,         
        address to,
        uint256 amountLiquidity
    ) override external {
        address futureContract = IFutureTokenFactory(futureTokenFactory).getFutureContract(tokenA, tokenB, expiryDate);
        address liquidityToken = getLiquidityToken[futureContract];
        uint256 liquidityTokenSupply = ILiquidityToken(liquidityToken).totalSupply();
        
        ILiquidityToken(liquidityToken).transferFrom(msg.sender, address(this), amountLiquidity);
        ILiquidityToken(liquidityToken).burn(amountLiquidity);
        
        uint256 reserveA = IERC20(tokenA).balanceOf(futureContract);
        uint256 reserveB = IERC20(tokenB).balanceOf(futureContract);
        
        uint256 amountA = (reserveA * amountLiquidity) / liquidityTokenSupply;
        uint256 amountB = (reserveB * amountLiquidity) / liquidityTokenSupply;

        IERC20(tokenA).transferFrom(futureContract, to, amountA);
        IERC20(tokenB).transferFrom(futureContract, to, amountB);
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        uint256 n = x / 2;
        uint256 lstX = 0;
        while (n != lstX) {
            lstX = n;
            n = (n + x / n) / 2;
        }
        return uint256(n);
    }

    function swapFuture(
        address tokenIn,
        address tokenOut,
        uint256 expiryDate,
        address to,
        uint256 amountIn
    ) external override {
        address futureContract = isFutureContract(tokenIn, tokenOut, expiryDate);
        uint256 amountOut = getAmountsOutFuture(amountIn, tokenIn, tokenOut, expiryDate);
        address futureToken = IFutureTokenFactory(futureTokenFactory).getFutureToken(tokenIn, tokenOut, expiryDate);
        uint256 amountMint = getAmountMint(futureToken, tokenOut, amountOut);
        IERC20(tokenIn).transferFrom(msg.sender, futureContract, amountIn);
        IERC20(tokenOut).transferFrom(futureContract, address(this), amountOut);
        IFutureTokenFactory(futureTokenFactory).mintFuture(tokenIn, tokenOut, expiryDate, to, amountMint);
    }

    function closeFuture(
        address tokenIn,
        address tokenOut,
        uint256 expiryDate,
        address to,
        uint256 amountOut
    ) external override {
        address futureToken = IFutureTokenFactory(futureTokenFactory).getFutureToken(tokenIn, tokenOut, expiryDate);
        uint256 amountMinted = getAmountMint(futureToken, tokenOut, amountOut);
        IERC20(futureToken).transferFrom(msg.sender, futureTokenFactory, amountMinted);
        IFutureTokenFactory(futureTokenFactory).burnFuture(tokenIn, tokenOut, expiryDate, amountMinted);
        IERC20(tokenOut).transfer(to, amountOut);
    }

    function getAmountMint(
        address futureToken,
        address tokenOut,
        uint256 amountOut
    ) internal view returns (uint256 amountMint) {
        amountMint = amountOut;
        uint256 decimalFuture = IERC20(futureToken).decimals();
        uint256 decimalOut = IERC20(tokenOut).decimals();
        if (decimalFuture > decimalOut)
            amountMint *= 10 ** (decimalFuture - decimalOut);
        if (decimalFuture < decimalOut)
            amountMint /= 10 ** (decimalOut - decimalFuture);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint256 amount, 
        address tokenIn, 
        address tokenOut, 
        uint256 expiryDate
    ) public view returns(uint) {
        address futureContract = IFutureTokenFactory(futureTokenFactory).getFutureContract(tokenIn, tokenOut, expiryDate);
        uint256 reserveIn = IERC20(tokenIn).balanceOf(futureContract);
        uint256 reserveOut = IERC20(tokenOut).balanceOf(futureContract);
        if (reserveIn != 0 && reserveOut != 0) {
            return PrecogV2Library.quote(amount, reserveIn, reserveOut);
        }
        return 0;
    }

    function getAmountsOutFuture(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        uint256 deadline
    ) public view override returns (uint) {
        return PrecogV2Library.getAmountsOutFuture(futureTokenFactory, amountIn, tokenIn, tokenOut, deadline);
    }

    function getAmountsInFuture(
        uint256 amountOut,
        address tokenIn,
        address tokenOut,
        uint256 deadline
    ) public view override returns (uint) {
        return PrecogV2Library.getAmountsInFuture(futureTokenFactory, amountOut, tokenIn, tokenOut, deadline);
    }
}

pragma solidity ^0.8.0;

interface IFutureExchangeRouter {
    
    function futureTokenFactory() external view returns (address);
    
    function getListFutureContractsInPair(address token) external view returns(address[] memory);
    
    function getAmountsOutFuture(uint256 amountIn, address tokenIn, address tokenOut, uint256 expiryDate) external view returns (uint256);
    
    function getAmountsInFuture(uint256 amountOut, address tokenIn, address tokenOut, uint256 expiryDate) external view returns (uint256);
    
    function addLiquidityFuture(address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 expiryDate, string memory symbol) external;
    
    function withdrawLiquidityFuture(address tokenA, address tokenB, uint256 expiryDate, address to, uint256 amount) external;
    
    function swapFuture(address tokenA, address tokenB, uint expiryDate, address to, uint amount) external;
    
    function closeFuture(address tokenA, address tokenB, uint expiryDate, address to, uint amount) external;
}

pragma solidity ^0.8.0;

import "../../future-token/interfaces/IFutureTokenFactory.sol";
import "../../future-token/interfaces/IFutureToken.sol";

import "../../common/interfaces/IERC20.sol";

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

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "PrecogV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "PrecogV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOutFuture(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "PrecogV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "PrecogV2Library: INSUFFICIENT_LIQUIDITY");
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
        require(reserveIn > 0 && reserveOut > 0, "PrecogV2Library: INSUFFICIENT_LIQUIDITY");
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
        (uint256 reserveIn, uint256 reserveOut) = getReservesFuture(factory, tokenIn, tokenOut, deadline);
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
        (uint256 reserveIn, uint256 reserveOut) = getReservesFuture(factory, tokenIn, tokenOut, deadline);
        amountIn = getAmountInFuture(amountOut, reserveIn, reserveOut);
    }

    // fetches and sorts the reserves for a pair
    function getReservesFuture(
        address factory,
        address tokenA,
        address tokenB,
        uint256 deadline
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        address futureContract = IFutureTokenFactory(factory).getFutureContract(tokenA, tokenB, deadline);
        reserveA = IERC20(tokenA).balanceOf(futureContract);
        reserveB = IERC20(tokenB).balanceOf(futureContract);
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

interface IFutureContract {
    
    function token0() external view returns (address);
    
    function token1() external view returns (address);
    
    function expiryDate() external view returns (uint256);
}

pragma solidity ^0.8.0;

interface IFutureToken {
    
    function initialize(string memory symbol) external;
    
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
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
    
    function getFutureContract(address tokenA, address tokenB, uint expiryDate) external view returns (address);

    function getFutureToken(address tokenIn, address tokenOut, uint expiryDate) external view returns (address);

    function createFuture(address tokenA, address tokenB, uint expiryDate, string memory symbol) external returns (address);

    function mintFuture(address tokenIn, address tokenOut, uint expiryDate, address to, uint amount) external;

    function burnFuture(address tokenIn, address tokenOut, uint expiryDate, uint amount) external;
}

