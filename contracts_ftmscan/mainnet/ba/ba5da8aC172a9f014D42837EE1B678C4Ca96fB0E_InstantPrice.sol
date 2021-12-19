/**
 *Submitted for verification at FtmScan.com on 2021-12-19
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "SafeMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "SafeMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "SafeMath: Mul Overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "SafeMath: Div by Zero");
        c = a / b;
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "SafeMath: uint128 Overflow");
        c = uint128(a);
    }
}

library SoulSwapLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'SoulSwapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SoulSwapLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'f3dcc3c6c6e34d3981dd429ac942301b9ebdd05de1be17f646b55476c44dc951' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
            address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
                (address token0,) = sortTokens(tokenA, tokenB);
                (uint reserve0, uint reserve1,) = ISoulSwapPair(pairFor(factory, tokenA, tokenB)).getReserves();
                (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'SoulSwapLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'SoulSwapLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'SoulSwapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'SoulSwapLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'SoulSwapLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'SoulSwapLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'SoulSwapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'SoulSwapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

interface ISoulSwapPair {
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

interface ISoulSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    event SetFeeTo(address indexed user, address indexed _feeTo);
    event SetMigrator(address indexed user, address indexed _migrator);
    event FeeToSetter(address indexed user, address indexed _feeToSetter);

    function feeTo() external view returns (address _feeTo);
    function feeToSetter() external view returns (address _feeToSetter);
    function migrator() external view returns (address _migrator);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setMigrator(address) external;
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IERC20Detailed {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    // Mutative functions
    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}

interface ISummoner {
    function userInfo(uint pid, address user) external view returns(uint, uint, uint, uint, uint, uint, uint);
    function poolInfo(uint pid) external view returns (address, uint, uint, uint);
    function poolLength() external view returns (uint);
    function totalAllocPoint() external view returns (uint);
    function soulPerSecond() external view returns (uint);
    function pendingSoul(uint pid, address user) external view returns (uint);
    function deposit(uint pid, uint amount) external;
}

interface IToken {
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
} 

contract InstantPrice {
  using SafeMath for uint256;

  address BOND_CONTRACT = 0xEdaECfc744F3BDeAF6556AEEbfcDedd79437a01F;    
  address public constant WFTM_ADDRESS = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; // WFTM
  address public constant USDC_ADDRESS = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75; // USDC
  address public constant USDC_MARKET = 0x160653F02b6597E7Db00BA8cA826cf43D2f39556; // USDC-FTM
  address public constant FACTORY_ADDRESS = 0x1120e150dA9def6Fe930f4fEDeD18ef57c0CA7eF; // SoulSwap Factory

  address public constant soulFtm = 0xa2527Af9DABf3E3B4979d7E0493b5e2C6e63dC57;
  address public constant soulUsdc = 0xC0A301f1E5E0Fe37a31657e8F60a41b14d01B0Ef;
  address public constant seanceFtm = 0x8542bEAC34282aFe5Bb6951Eb6DCE0B3783b7faB;
  address public constant ftmUsdc = 0x160653F02b6597E7Db00BA8cA826cf43D2f39556;
  address public constant ftmDai = 0xF3d6E8Ecece8647B456d57375Ce0B51B8F0cD40b;
  address public constant ftmBnb = 0x52966a12e3211c92909C28603ca3df8465c06c82;
  address public constant ftmEth = 0xC615a5fd68265D9Ec6eF60805998fa5Bb71972Cb;
  address public constant ftmBtc = 0xecB41D6B5885E75a149EDA173e92267aa271D895;
  address public constant usdcDai = 0x406dE3A93f6B4179E3B21a3d81226B43e1918fd9;


function usdcValue(uint pid, address lpAddress) public view returns (uint dollarValue) {
    if ( pid != 1 && pid != 9 ) {
        uint ftmPrice = currentFtmPriceInUsdc(); // price of FTM
        uint ftmAmount = IToken(WFTM_ADDRESS).balanceOf(lpAddress); // units of FTM
        return ftmPrice * ftmAmount * 2; // ttl FTM value (in USDC)
    }

    else if ( pid == 1 || pid == 9 ) {
        uint usdcAmount = IToken(USDC_ADDRESS).balanceOf(lpAddress); // usdc units
        return usdcAmount * 2;
    }
}

//   function reserveValue(uint pid) public view returns (uint) {
//     // address lpAddress = getAddress(pid);
//     address token0 = ISoulSwapPair(lpAddress).token0();
//     address token1 = ISoulSwapPair(lpAddress).token1();
    
//     return
//     token0 == WFTM_ADDRESS || token1 == WFTM_ADDRESS 
//         ? lpAddress.balanceOf(WFTM_ADDRESS) * 2
//         : token0 == USDC_ADDRESS ? currentTokenPrice(lpAddress, token1)
//         : token1 == USDC_ADDRESS ? currentTokenPrice(lpAddress, token0) : 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
        
//     // currentTokenPrice()
//     // ftmPrice = currentTokenPrice(USDC_MARKET, WFTM_ADDRESS); // FTM PRICE
//   }

  function contractUsdTokensSum(address _contract, address[] memory _tokens) public view returns (uint256) {
    uint256[] memory balances = getContractTokensBalanceOfArray(_contract, _tokens);
    return usdcTokensSum(_tokens, balances);
  }

  function contractFtmTokensSum(address _contract, address[] memory _tokens) public view returns (uint256) {
    uint256[] memory balances = getContractTokensBalanceOfArray(_contract, _tokens);
    return ftmTokensSum(_tokens, balances);
  }

  function usdcTokensSum(address[] memory _tokens, uint256[] memory _balances) public view returns (uint256) {
    uint256 ftmTokensSumAmount = ftmTokensSum(_tokens, _balances);
    uint256 ftmPriceInUsdc = currentFtmPriceInUsdc();
    return ftmTokensSumAmount.mul(ftmPriceInUsdc).div(1 ether);
  }

  function ftmTokensSum(address[] memory _tokens, uint256[] memory _balances) public view returns (uint256) {
    uint256 len = _tokens.length;
    require(len == _balances.length, "LENGTHS_NOT_EQUAL");

    uint256 sum = 0;
    for (uint256 i = 0; i < len; i++) {
      _balances[i] = amountToNative(_balances[i], getTokenDecimals(_tokens[i]));
      sum = sum.add(currentTokenFtmPrice(_tokens[i]).mul(_balances[i]).div(1 ether));
    }
    return sum;
  }

  function currentFtmPriceInUsdc() public view returns (uint256) {
    return currentTokenPrice(USDC_MARKET, WFTM_ADDRESS);
  }

  function currentTokenUsdcPrice(address _token) public view returns (uint256 price) {
    uint256 ftmPriceInUsdc = currentFtmPriceInUsdc();
    uint256 tokenFtmPrice = currentTokenFtmPrice(_token);
    return tokenFtmPrice.mul(ftmPriceInUsdc).div(1 ether);
  }

//   function currentLpUsdcPrice(uint pid) public view returns (uint256 price) {
//     // if (pid == 0 || pid == 1) {
//     //     balanceOf()
//     // }
//     uint256 ftmPriceInUsdc = currentFtmPriceInUsdc();
//     uint256 tokenFtmPrice = currentTokenFtmPrice(_token);
//     return tokenFtmPrice.mul(ftmPriceInUsdc).div(1 ether);
//   }

  function currentTokenFtmPrice(address _token) public view returns (uint256 price) {
    if (_token == WFTM_ADDRESS) {
      return uint256(1 ether);
    }
    address market = ISoulSwapFactory(FACTORY_ADDRESS).getPair(_token, WFTM_ADDRESS);
    if (market == address(0)) {
      market = ISoulSwapFactory(FACTORY_ADDRESS).getPair(WFTM_ADDRESS, _token);
      return currentTokenPrice(market, _token);
    } else {
      return currentTokenPrice(market, _token);
    }
  }

  function currentTokenPrice(address soulswapMarket, address _token) public view returns (uint256 price) {
    (uint112 reserve0, uint112 reserve1, ) = ISoulSwapPair(soulswapMarket).getReserves();
    address token0 = ISoulSwapPair(soulswapMarket).token0();
    address token1 = ISoulSwapPair(soulswapMarket).token1();

    uint8 tokenInDecimals = getTokenDecimals(_token);
    uint8 tokenOutDecimals = getTokenDecimals(_token == token0 ? token1 : token0);

    uint256 inAmount = 1 ether;
    if (tokenInDecimals < uint8(18)) {
      inAmount = inAmount.div(10**uint256(uint8(18) - tokenInDecimals));
    }

    price = SoulSwapLibrary.getAmountOut(
      inAmount,
      _token == token0 ? reserve0 : reserve1,
      _token == token0 ? reserve1 : reserve0
    );

    if (tokenInDecimals > tokenOutDecimals) {
      return price.mul(10**uint256(tokenInDecimals - tokenOutDecimals));
    } else {
      return price;
    }
  }

  function getContractTokensBalanceOfArray(address _contract, address[] memory tokens)
    public
    view
    returns (uint256[] memory balances)
  {
    uint256 len = tokens.length;
    balances = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      balances[i] = IERC20Detailed(tokens[i]).balanceOf(_contract);
    }
  }

  function getTokenDecimals(address _token) public view returns (uint8 decimals) {
    try IERC20Detailed(_token).decimals() returns (uint8 _decimals) {
      decimals = _decimals;
    } catch (
      bytes memory /*lowLevelData*/
    ) {
      decimals = uint8(18);
    }
  }

  function amountToNative(uint256 amount, uint8 decimals) public pure returns (uint256) {
    if (decimals == uint8(18)) {
      return amount;
    }
    return amount.mul(10**uint256(uint8(18) - decimals));
  }
}