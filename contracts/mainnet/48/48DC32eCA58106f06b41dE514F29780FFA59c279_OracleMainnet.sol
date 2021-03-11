import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interface/uniswap/IUniswapV2Factory.sol";
import "./interface/uniswap/IUniswapV2Pair.sol";
import "./interface/curve/ICurvePool.sol";
import "./interface/curve/ICurveRegistry.sol";
import "./interface/mooniswap/IMooniFactory.sol";
import "./interface/mooniswap/IMooniswap.sol";
import "./Governable.sol";

pragma solidity 0.6.12;

contract OracleMainnet is Governable {

  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  //Addresses for factories and registries for different DEX platforms. Functions will be added to allow to alter these when needed.
  address public uniswapFactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address public sushiswapFactoryAddress = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
  address public curveRegistryAddress = 0x7D86446dDb609eD0F5f8684AcF30380a356b2B4c;
  address public oneInchFactoryAddress = 0xbAF9A5d4b0052359326A6CDAb54BABAa3a3A9643;
  uint256 public precisionDecimals = 18;

  IUniswapV2Factory uniswapFactory = IUniswapV2Factory(uniswapFactoryAddress);
  IUniswapV2Factory sushiswapFactory = IUniswapV2Factory(sushiswapFactoryAddress);
  ICurveRegistry curveRegistry = ICurveRegistry(curveRegistryAddress);
  IMooniFactory oneInchFactory = IMooniFactory(oneInchFactoryAddress);

  //Key tokens are used to find liquidity for any given token on Uni, Sushi and Curve.
  address[] public keyTokens = [
  0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, //USDC
  0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, //WETH
  0x6B175474E89094C44Da98b954EedeAC495271d0F, //DAI
  0xdAC17F958D2ee523a2206206994597C13D831ec7, //USDT
  0xa47c8bf37f92aBed4A126BDA807A7b7498661acD, //UST
  0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, //WBTC
  0xdB25f211AB05b1c97D595516F45794528a807ad8, //EURS
  0x514910771AF9Ca656af840dff83E8264EcF986CA  //LINK
  ];
  //Pricing tokens are Key tokens with good liquidity with the defined output token on Uniswap.
  address[] public pricingTokens = [
  0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, //USDC
  0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, //WETH
  0x6B175474E89094C44Da98b954EedeAC495271d0F, //DAI
  0xdAC17F958D2ee523a2206206994597C13D831ec7, //USDT
  0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, //WBTC
  0xdB25f211AB05b1c97D595516F45794528a807ad8  //EURS
  ];
  //The defined output token is the unit in which prices of input tokens are given.
  address public definedOutputToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //USDC

  //Below are addresses of LP tokens for which it is known that the get_underlying functions of Curve Registry do not work because of errors in the Curve contract.
  //The exceptions are split. In the first exception the get_underlying_coins is called with get_balances.
  //In the second exception get_coins and get_balances are called.
  address[] public curveExceptionList0 = [
  0xFd2a8fA60Abd58Efe3EeE34dd494cD491dC14900,
  0x02d341CcB60fAaf662bC0554d13778015d1b285C
  ];
  address[] public curveExceptionList1 = [
  0x49849C98ae39Fff122806C06791Fa73784FB3675,
  0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3,
  0xaA17A236F2bAdc98DDc0Cf999AbB47D47Fc0A6Cf
  ];

  modifier validKeyToken(address keyToken){
      require(checkKeyToken(keyToken), "Not a Key Token");
      _;
  }
  modifier validPricingToken(address pricingToken){
      require(checkPricingToken(pricingToken), "Not a Pricing Token");
      _;
  }
  modifier validException(address exception){
      (bool check0, bool check1) = checkCurveException(exception);
      require(check0 || check1, "Not an exception");
      _;
  }

  event FactoryChanged(address newFactory, address oldFactory);
  event RegistryChanged(address newRegistry, address oldRegistry);
  event KeyTokenAdded(address newKeyToken);
  event PricingTokenAdded(address newPricingToken);
  event KeyTokenRemoved(address keyToken);
  event PricingTokenRemoved(address pricingToken);
  event DefinedOutuptChanged(address newOutputToken, address oldOutputToken);
  event CurveExceptionAdded(address newException, uint256 exceptionList);
  event CurveExceptionRemoved(address oldException, uint256 exceptionList);

  constructor(address _storage)
  Governable(_storage) public {}

  function changeUniFactory(address newFactory) external onlyGovernance {
    address oldFactory = uniswapFactoryAddress;
    uniswapFactoryAddress = newFactory;
    uniswapFactory = IUniswapV2Factory(uniswapFactoryAddress);
    emit FactoryChanged(newFactory, oldFactory);
  }
  function changeSushiFactory(address newFactory) external onlyGovernance {
    address oldFactory = sushiswapFactoryAddress;
    sushiswapFactoryAddress = newFactory;
    sushiswapFactory = IUniswapV2Factory(sushiswapFactoryAddress);
    emit FactoryChanged(newFactory, oldFactory);
  }
  function changeCurveRegistry(address newRegistry) external onlyGovernance {
    address oldRegistry = curveRegistryAddress;
    curveRegistryAddress = newRegistry;
    curveRegistry = ICurveRegistry(curveRegistryAddress);
    emit RegistryChanged(newRegistry, oldRegistry);
  }
  function changeOneInchFactory(address newFactory) external onlyGovernance {
    address oldFactory = oneInchFactoryAddress;
    oneInchFactoryAddress = newFactory;
    oneInchFactory = IMooniFactory(oneInchFactoryAddress);
    emit FactoryChanged(newFactory, oldFactory);
  }

  function addKeyToken(address newToken) external onlyGovernance {
    require((checkKeyToken(newToken)==false), "Already a key token");
    keyTokens.push(newToken);
    emit KeyTokenAdded(newToken);
  }
  function addPricingToken(address newToken) public onlyGovernance validKeyToken(newToken) {
    require((checkPricingToken(newToken)==false), "Already a pricing token");
    pricingTokens.push(newToken);
    emit PricingTokenAdded(newToken);
  }

  function removeKeyToken(address keyToken) external onlyGovernance validKeyToken(keyToken) {
    uint256 i;
    for ( i=0;i<keyTokens.length;i++) {
      if (keyToken == keyTokens[i]){
        break;
      }
    }
    while (i<keyTokens.length-1) {
      keyTokens[i] = keyTokens[i+1];
      i++;
    }
    keyTokens.pop();
    emit KeyTokenRemoved(keyToken);

    if (checkPricingToken(keyToken)) {
      removePricingToken(keyToken);
    }
  }
  function removePricingToken(address pricingToken) public onlyGovernance validPricingToken(pricingToken) {
    uint256 i;
    for (i=0;i<pricingTokens.length;i++) {
      if (pricingToken == pricingTokens[i]){
        break;
      }
    }
    while (i<pricingTokens.length-1) {
      pricingTokens[i] = pricingTokens[i+1];
      i++;
    }
    pricingTokens.pop();
    emit PricingTokenRemoved(pricingToken);
  }
  function changeDefinedOutput(address newOutputToken) external onlyGovernance validKeyToken(newOutputToken) {
    address oldOutputToken = definedOutputToken;
    definedOutputToken = newOutputToken;
    emit DefinedOutuptChanged(newOutputToken, oldOutputToken);
  }

  function addCurveException(address newException, uint256 exceptionList) external onlyGovernance {
    (bool check0, bool check1) = checkCurveException(newException);
    require(check0==false && check1 == false, "Already an exception");
    require(exceptionList <= 1, 'Only accepts 0 or 1');
    if (exceptionList == 0) {
      curveExceptionList0.push(newException);
    } else {
      curveExceptionList1.push(newException);
    }
    emit CurveExceptionAdded(newException, exceptionList);
  }
  function removeCurveException(address exception) external onlyGovernance validException(exception) {
    (bool check0,) = checkCurveException(exception);
    uint256 i;
    uint256 j;
    uint256 list;
    if (check0) {
      list = 0;
      for (i=0;i<curveExceptionList0.length;i++) {
        if (exception == curveExceptionList0[i]){
          break;
        }
      }
      while (i<curveExceptionList0.length-1) {
        curveExceptionList0[i] = curveExceptionList0[i+1];
        i++;
      }
      curveExceptionList0.pop();
    } else {
      list = 1;
      for (j=0;j<curveExceptionList1.length;j++) {
        if (exception == curveExceptionList1[j]){
          break;
        }
      }
      while (j<curveExceptionList1.length-1) {
        curveExceptionList1[j] = curveExceptionList1[j+1];
        j++;
      }
      curveExceptionList1.pop();
    }
    emit CurveExceptionRemoved(exception, list);
  }

  //Main function of the contract. Gives the price of a given token in the defined output token.
  //The contract allows for input tokens to be LP tokens from Uniswap, Sushiswap, Curve and 1Inch.
  //In case of LP token, the underlying tokens will be found and valued to get the price.
  function getPrice(address token) external view returns (uint256) {
    if (token == definedOutputToken) {
      return (10**precisionDecimals);
    }
    bool uniSushiLP;
    bool curveLP;
    bool oneInchLP;
    (uniSushiLP, curveLP, oneInchLP) = isLPCheck(token);
    uint256 priceToken;
    uint256 tokenValue;
    uint256 price;
    uint256 i;
    if (uniSushiLP || oneInchLP) {
      address[2] memory tokens;
      uint256[2] memory amounts;
      (tokens, amounts) = (uniSushiLP)? getUniUnderlying(token):getOneInchUnderlying(token);
      for (i=0;i<2;i++) {
        priceToken = computePrice(tokens[i]);
        if (priceToken == 0) {
          price = 0;
          return price;
        }
        tokenValue = priceToken*amounts[i]/10**precisionDecimals;
        price = price + tokenValue;
      }
      return price;
    } else if (curveLP) {
      address[8] memory tokens;
      uint256[8] memory amounts;
      (tokens, amounts) = getCurveUnderlying(token);
      for (i=0;i<tokens.length;i++) {
        if (tokens[i] == address(0)) {
          break;
        }
        priceToken = computePrice(tokens[i]);
        if (priceToken == 0) {
          price = 0;
          return price;
        }
        tokenValue = priceToken*amounts[i]/10**precisionDecimals;
        price = price + tokenValue;
      }
      return price;
    } else {
      return computePrice(token);
    }
  }

  function isLPCheck(address token) public view returns(bool, bool, bool) {
    bool isOneInch = isOneInchCheck(token);
    bool isUniSushi = isUniSushiCheck(token);
    bool isCurve = isCurveCheck(token);
    return (isUniSushi, isCurve, isOneInch);
  }

  //Checks if address is 1Inch LP
  function isOneInchCheck(address token) internal view returns (bool) {
    bool oneInchLP = oneInchFactory.isPool(token);
    return oneInchLP;
  }

  //Checks if address is Uni or Sushi LP. This is done in two steps, because the second step seems to cause errors for some tokens.
  //Only the first step is not deemed accurate enough, as any token could be called UNI-V2.
  function isUniSushiCheck(address token) internal view returns (bool) {
    IUniswapV2Pair pair = IUniswapV2Pair(token);
    string memory uniSymbol = "UNI-V2";
    string memory sushiSymbol = "SLP";
    string memory symbol = pair.symbol();
    if (isEqualString(symbol, uniSymbol)) {
      return checkFactory(pair, uniswapFactoryAddress);
    } else if (isEqualString(symbol, sushiSymbol)) {
      return checkFactory(pair, sushiswapFactoryAddress);
    } else {
      return false;
    }
  }

  function isEqualString(string memory arg1, string memory arg2) internal view returns (bool) {
    bool check = (keccak256(abi.encodePacked(arg1)) == keccak256(abi.encodePacked(arg2)))? true:false;
    return check;
  }

  function checkFactory(IUniswapV2Pair pair, address compareFactory) internal view returns (bool) {
    try pair.factory{gas: 3000}() returns (address factory) {
      bool check = (factory == compareFactory)? true:false;
      return check;
    } catch {
      return false;
    }
  }

  //Checks if address is Curve LP
  function isCurveCheck(address token) internal view returns (bool) {
    address pool = curveRegistry.get_pool_from_lp_token(token);
    bool check = (pool != address(0))? true:false;
    return check;
  }

  //Get underlying tokens and amounts for Uni/Sushi LPs
  function getUniUnderlying(address token) public view returns (address[2] memory, uint256[2] memory) {
    IUniswapV2Pair pair = IUniswapV2Pair(token);
    address[2] memory tokens;
    uint256[2] memory amounts;
    tokens[0] = pair.token0();
    tokens[1] = pair.token1();
    uint256 token0Decimals = ERC20(tokens[0]).decimals();
    uint256 token1Decimals = ERC20(tokens[1]).decimals();
    uint256 supplyDecimals = ERC20(token).decimals();
    (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
    uint256 totalSupply = pair.totalSupply();
    if (reserve0 == 0 || reserve1 == 0 || totalSupply == 0) {
      amounts[0] = 0;
      amounts[1] = 0;
      return (tokens, amounts);
    }
    amounts[0] = reserve0*10**(supplyDecimals-token0Decimals+precisionDecimals)/totalSupply;
    amounts[1] = reserve1*10**(supplyDecimals-token1Decimals+precisionDecimals)/totalSupply;
    return (tokens, amounts);
  }

  //Get underlying tokens and amounts for 1Inch LPs
  function getOneInchUnderlying(address token) public view returns (address[2] memory, uint256[2] memory) {
    IMooniswap pair = IMooniswap(token);
    address[2] memory tokens;
    uint256[2] memory amounts;
    tokens[0] = pair.token0();
    tokens[1] = pair.token1();
    uint256 token0Decimals = (tokens[0]==address(0))? 18:ERC20(tokens[0]).decimals();
    uint256 token1Decimals = ERC20(tokens[1]).decimals();
    uint256 supplyDecimals = ERC20(token).decimals();
    uint256 reserve0 = pair.getBalanceForRemoval(tokens[0]);
    uint256 reserve1 = pair.getBalanceForRemoval(tokens[1]);
    uint256 totalSupply = pair.totalSupply();
    if (reserve0 == 0 || reserve1 == 0 || totalSupply == 0) {
      amounts[0] = 0;
      amounts[1] = 0;
      return (tokens, amounts);
    }
    amounts[0] = reserve0*10**(supplyDecimals-token0Decimals+precisionDecimals)/totalSupply;
    amounts[1] = reserve1*10**(supplyDecimals-token1Decimals+precisionDecimals)/totalSupply;

    //1INCH uses ETH, instead of WETH in pools. For further calculations we continue with WETH instead.
    //ETH will always be the first in the pair, so no need to check tokens[1]
    if (tokens[0] == address(0)) {
      tokens[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }
    return (tokens, amounts);
  }

  //Get underlying tokens and amounts for Curve LPs. Curve gives responses in arrays with length 8. There is no need to change their size.
  function getCurveUnderlying(address token) public view returns (address[8] memory, uint256[8] memory) {
    address pool = curveRegistry.get_pool_from_lp_token(token);
    (bool exception0, bool exception1) = checkCurveException(token);
    address[8] memory tokens;
    uint256[8] memory reserves;
    if (exception0) {
      tokens = curveRegistry.get_underlying_coins(pool);
      reserves = curveRegistry.get_balances(pool);
    } else if (exception1) {
      tokens = curveRegistry.get_coins(pool);
      reserves = curveRegistry.get_balances(pool);
    } else {
      tokens = curveRegistry.get_underlying_coins(pool);
      reserves = curveRegistry.get_underlying_balances(pool);
    }

    //Some pools work with ETH instead of WETH. For further calculations and functionality this is changed to WETH address.
    uint256[8] memory decimals;
    uint256 i;
    uint256 totalSupply = IERC20(token).totalSupply();
    uint256 supplyDecimals = ERC20(token).decimals();
    uint256[8] memory amounts;
    for (i=0;i<tokens.length;i++) {
      if (tokens[i] == address(0)){
        break;
      } else if (tokens[i]==0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE){
        decimals[i] = 18;
        tokens[i] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
      } else {
        decimals[i] = ERC20(tokens[i]).decimals();
      }

      amounts[i] = reserves[i]*10**(supplyDecimals-decimals[i]+precisionDecimals)/totalSupply;
      //Curve has errors in their registry, where amounts are stored with the wrong number of decimals
      //This steps accounts for this. In general there will never be more than 1 of any underlying token
      //per curve LP token. If it is more, the decimals are corrected.
      if (amounts[i] > 10**precisionDecimals) {
        amounts[i] = amounts[i]*10**(decimals[i]-18);
      }
    }
    return (tokens, amounts);
  }

  //Check address for the Curve exception lists.
  function checkCurveException(address token) internal view returns (bool, bool) {
    uint256 i;
    for (i=0;i<curveExceptionList0.length;i++) {
      if (token == curveExceptionList0[i]) {
        return (true, false);
      }
    }
    for (i=0;i<curveExceptionList1.length;i++) {
      if (token == curveExceptionList1[i]) {
        return (false, true);
      }
    }
    return (false, false);
  }

  //General function to compute the price of a token vs the defined output token.
  function computePrice(address token) public view returns (uint256) {
    uint256 price;
    if (token == definedOutputToken) {
      price = 10**precisionDecimals;
    } else if (token == address(0)) {
      price = 0;
    } else {
      (address keyToken, address pool, bool uni, bool sushi) = getLargestPool(token,keyTokens);
      uint256 priceVsKeyToken;
      uint256 keyTokenPrice;
      if (keyToken == address(0)) {
        price = 0;
      } else if (uni) {
        priceVsKeyToken = getPriceVsTokenUni(token,keyToken);
        keyTokenPrice = getKeyTokenPrice(keyToken);
        price = priceVsKeyToken*keyTokenPrice/10**precisionDecimals;
      } else if (sushi) {
        priceVsKeyToken = getPriceVsTokenSushi(token,keyToken);
        keyTokenPrice = getKeyTokenPrice(keyToken);
        price = priceVsKeyToken*keyTokenPrice/10**precisionDecimals;
      } else {
        priceVsKeyToken = getPriceVsTokenCurve(token,keyToken,pool);
        keyTokenPrice = getKeyTokenPrice(keyToken);
        price = priceVsKeyToken*keyTokenPrice/10**precisionDecimals;
      }
    }
    return (price);
  }

  //Checks the results of the different largest pool functions and returns the largest.
  function getLargestPool(address token, address[] memory tokenList) public view returns (address, address, bool, bool) {
    (address uniSushiKeyToken, uint256 uniSushiLiquidity, bool isUni) = getUniSushiLargestPool(token, tokenList);
    (address curveKeyToken, address curvePool, uint256 curveLiquidity) = getCurveLargestPool(token, tokenList);
    if (uniSushiLiquidity > curveLiquidity) {
      bool isSushi = (isUni)? false:true;
      return (uniSushiKeyToken, address(0), isUni, isSushi);
    } else {
      return (curveKeyToken, curvePool, false, false);
    }
  }

  //Gives the Uniswap pool with largest liquidity for a given token and a given tokenset (either keyTokens or pricingTokens)
  function getUniSushiLargestPool(address token, address[] memory tokenList) internal view returns (address, uint256, bool) {
    uint256 largestPoolSize = 0;
    address largestKeyToken;
    uint256 poolSize;
    uint256 i;
    uint256 poolSizeUni;
    uint256 poolSizeSushi;
    bool largestPoolisUni;
    for (i=0;i<tokenList.length;i++) {
      address pairAddressUni = uniswapFactory.getPair(token,tokenList[i]);
      address pairAddressSushi = sushiswapFactory.getPair(token,tokenList[i]);
      if (pairAddressUni!=address(0)) {
        poolSizeUni = getUniPoolSize(pairAddressUni, token);
      }
      if (pairAddressSushi!=address(0)) {
        poolSizeSushi = getUniPoolSize(pairAddressSushi, token);
      }
      bool uniDex = (poolSizeUni > poolSizeSushi);
      poolSize = (uniDex)? poolSizeUni:poolSizeSushi;
      if (poolSize > largestPoolSize) {
        largestPoolSize = poolSize;
        largestKeyToken = tokenList[i];
        largestPoolisUni = uniDex;
      }
    }
    return (largestKeyToken, largestPoolSize, largestPoolisUni);
  }

  function getUniPoolSize(address pairAddress, address token) internal view returns(uint256) {
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
    address token0 = pair.token0();
    (uint112 poolSize0, uint112 poolSize1,) = pair.getReserves();
    uint256 poolSize = (token==token0)? poolSize0:poolSize1;
    return poolSize;
  }

  //Gives the Curve pool with largest liquidity for a given token and a given tokenset (either keyTokens or pricingTokens)
  //Curve can have multiple pools for a given pair. Research showed that the largest pool is always given as first instance, so only the first needs to be called.
  //In Curve USD based tokens are often pooled with 3Pool. In this case liquidity is the same with USDC, DAI and USDT. When liquidity is found with USDC
  //the loop is stopped, as no larger liquidity will be found with any other asset and this reduces calls.
  function getCurveLargestPool(address token, address[] memory tokenList) internal view returns (address, address, uint256) {
    uint256 largestPoolSize = 0;
    address largestPoolAddress;
    address largestKeyToken;
    uint256 poolSize;
    uint256 i;
    for (i=0;i<tokenList.length;i++) {
      address poolAddress = curveRegistry.find_pool_for_coins(token, tokenList[i],0);
      if (poolAddress == address(0)) {
        continue;
      }
      address lpToken = curveRegistry.get_lp_token(poolAddress);
      (bool exception0,) = checkCurveException(lpToken);
      if (exception0) {
        continue;
      }
      poolSize = getCurveBalance(token, tokenList[i], poolAddress);
      if (poolSize > largestPoolSize) {
        largestPoolSize = poolSize;
        largestKeyToken = tokenList[i];
        largestPoolAddress = poolAddress;
        if (largestKeyToken == definedOutputToken) {
          return (largestKeyToken, largestPoolAddress, largestPoolSize);
        }
      }
    }
    return (largestKeyToken, largestPoolAddress, largestPoolSize);
  }

  //Gives the balance of a given token in a given pool.
  function getCurveBalance(address tokenFrom, address tokenTo, address pool) internal view returns (uint256) {
    uint256 balance;
    (int128 indexFrom,,bool underlying) = curveRegistry.get_coin_indices(pool, tokenFrom, tokenTo);
    uint256[8] memory balances;
    if (underlying) {
      balances = curveRegistry.get_underlying_balances(pool);
      uint256 decimals = ERC20(tokenFrom).decimals();
      balance = balances[uint256(indexFrom)];
      if (balance > 10**(decimals+10)) {
        balance = balance*10**(decimals-18);
      }
    } else {
      balances = curveRegistry.get_balances(pool);
      balance = balances[uint256(indexFrom)];
    }
    return balance;
  }

  //Generic function giving the price of a given token vs another given token on Uniswap.
  function getPriceVsTokenUni(address token0, address token1) internal view returns (uint256) {
    address pairAddress = uniswapFactory.getPair(token0,token1);
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
    (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
    uint256 token0Decimals = ERC20(token0).decimals();
    uint256 token1Decimals = ERC20(token1).decimals();
    uint256 price;
    if (token0 == pair.token0()) {
      price = (reserve1*10**(token0Decimals-token1Decimals+precisionDecimals))/reserve0;
    } else {
      price = (reserve0*10**(token0Decimals-token1Decimals+precisionDecimals))/reserve1;
    }
    return price;
  }

  //Generic function giving the price of a given token vs another given token on Sushiswap.
  function getPriceVsTokenSushi(address token0, address token1) internal view returns (uint256) {
    address pairAddress = sushiswapFactory.getPair(token0,token1);
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
    (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
    uint256 token0Decimals = ERC20(token0).decimals();
    uint256 token1Decimals = ERC20(token1).decimals();
    uint256 price;
    if (token0 == pair.token0()) {
      price = (reserve1*10**(token0Decimals-token1Decimals+precisionDecimals))/reserve0;
    } else {
      price = (reserve0*10**(token0Decimals-token1Decimals+precisionDecimals))/reserve1;
    }
    return price;
  }

  //Generic function giving the price of a given token vs another given token on Curve.
  function getPriceVsTokenCurve(address token0, address token1, address poolAddress) internal view returns (uint256) {
    ICurvePool pool = ICurvePool(poolAddress);
    (int128 indexFrom, int128 indexTo, bool underlying) = curveRegistry.get_coin_indices(poolAddress, token0, token1);
    uint256 decimals0 = ERC20(token0).decimals();
    uint256 decimals1 = ERC20(token1).decimals();
    //Accuracy is impacted when one of the tokens has low decimals.
    //This addition does not impact the outcome of computation, other than increased accuracy.
    if (decimals0 < 4 || decimals1 < 4) {
      decimals0 = decimals0 + 4;
      decimals1 = decimals1 + 4;
    }
    uint256 amount1;
    uint256 price;
    if (underlying) {
      amount1 = pool.get_dy_underlying(indexFrom, indexTo, 10**decimals0);
      price = amount1*10**(precisionDecimals-decimals1);
    } else {
      amount1 = pool.get_dy(indexFrom, indexTo, 10**decimals0);
      price = amount1*10**(precisionDecimals-decimals1);
    }
    return price;
  }

  //Gives the price of a given keyToken.
  function getKeyTokenPrice(address token) internal view returns (uint256) {
    bool isPricingToken = checkPricingToken(token);
    uint256 price;
    uint256 priceVsPricingToken;
    if (token == definedOutputToken) {
      price = 10**precisionDecimals;
    } else if (isPricingToken) {
      price = getPriceVsTokenUni(token,definedOutputToken);
    } else {
      uint256 pricingTokenPrice;
      (address pricingToken, address pricingPool, bool uni, bool sushi) = getLargestPool(token,pricingTokens);
      if (uni) {
        priceVsPricingToken = getPriceVsTokenUni(token,pricingToken);
      } else if (sushi) {
        priceVsPricingToken = getPriceVsTokenSushi(token,pricingToken);
      } else {
        priceVsPricingToken = getPriceVsTokenCurve(token,pricingToken,pricingPool);
      }
      pricingTokenPrice = (pricingToken == definedOutputToken)? 10**precisionDecimals:getPriceVsTokenUni(pricingToken,definedOutputToken);
      price = priceVsPricingToken*pricingTokenPrice/10**precisionDecimals;
    }
    return price;
  }

  //Checks if a given token is in the pricingTokens list.
  function checkPricingToken(address token) public view returns (bool) {
    uint256 i;
    for (i=0;i<pricingTokens.length;i++) {
      if (token == pricingTokens[i]) {
        return true;
      }
    }
    return false;
  }

  //Checks if a given token is in the keyTokens list.
  function checkKeyToken(address token) public view returns (bool) {
    uint256 i;
    for (i=0;i<keyTokens.length;i++) {
      if (token == keyTokens[i]) {
        return true;
      }
    }
    return false;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

/**
 *Submitted for verification at Etherscan.io on 2020-05-05
*/

// File: contracts/interfaces/IUniswapV2Pair.sol

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

pragma solidity >=0.5.0;

interface ICurvePool {
  function get_dy (int128 i, int128 j, uint256 dx) external view returns (uint256);
  function get_dy_underlying (int128 i, int128 j, uint256 dx) external view returns (uint256);

}

pragma solidity >=0.5.0;

interface ICurveRegistry {
  function get_coins(address _pool) external view returns (address[8] memory);
  function get_underlying_coins(address _pool) external view returns (address[8] memory);
  function get_balances(address _pool) external view returns (uint256[8] memory);
  function get_underlying_balances(address _pool) external view returns (uint256[8] memory);
  function get_pool_from_lp_token(address _lp_token) external view returns (address);
  function get_lp_token(address _pool) external view returns (address);
  function pool_count() external view returns (uint256);
  function pool_list(uint256) external view returns (address);
  function get_decimals(address _pool) external view returns (uint256[8] memory);
  function get_underlying_decimals(address _pool) external view returns (uint256[8] memory);
  function get_coin_indices(address _pool, address _from, address _to) external view returns (int128, int128, bool);
  function find_pool_for_coins(address _from, address _to, uint256 i) external view returns (address);
}

pragma solidity >=0.5.0;

interface IMooniFactory {
  function isPool(address token) external view returns(bool);
  function getAllPools() external view returns(address[] memory);
}

pragma solidity >=0.5.0;

interface IMooniswap {
  function getBalanceForRemoval(address token) external view returns(uint256);
  function token0() external view returns(address);
  function token1() external view returns(address);
  function totalSupply() external view returns(uint256);
}

pragma solidity >=0.5.16;

import "./Storage.sol";

contract Governable {

  Storage public store;

  constructor(address _store) public {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity >=0.5.16;

contract Storage {

  address public governance;
  address public controller;

  constructor() public {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}