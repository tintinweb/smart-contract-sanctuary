/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-08
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IERC20 {
  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);
}

interface ICurveRegistry {
  function get_pool_from_lp_token(address arg0) external view returns (address);

  function get_underlying_coins(address arg0)
    external
    view
    returns (address[8] memory);

  function get_virtual_price_from_lp_token(address arg0)
    external
    view
    returns (uint256);
}

interface ICryptoPool {
  function balances(uint256) external view returns (uint256);

  function price_oracle(uint256) external view returns (uint256);

  function coins(uint256) external view returns (address);
}

interface ILp {
  function totalSupply() external view returns (uint256);
}

interface IOracle {
  function getPriceUsdcRecommended(address tokenAddress)
    external
    view
    returns (uint256);

  function usdcAddress() external view returns (address);
}

interface IYearnAddressesProvider {
  function addressById(string memory) external view returns (address);
}

interface ICurveAddressesProvider {
  function get_registry() external view returns (address);

  function get_address(uint256) external view returns (address);
}

interface ICalculationsChainlink {
  function oracleNamehashes(address) external view returns (bytes32);
}

contract CalculationsCurve {
  address public ownerAddress;
  address public yearnAddressesProviderAddress;
  address public curveAddressesProviderAddress;
  IYearnAddressesProvider internal yearnAddressesProvider;
  ICurveAddressesProvider internal curveAddressesProvider;

  constructor(
    address _yearnAddressesProviderAddress,
    address _curveAddressesProviderAddress
  ) {
    curveAddressesProviderAddress = _curveAddressesProviderAddress;
    yearnAddressesProviderAddress = _yearnAddressesProviderAddress;
    ownerAddress = msg.sender;
    yearnAddressesProvider = IYearnAddressesProvider(
      _yearnAddressesProviderAddress
    );
    curveAddressesProvider = ICurveAddressesProvider(
      _curveAddressesProviderAddress
    );
  }

  function oracle() internal view returns (IOracle) {
    return IOracle(yearnAddressesProvider.addressById("ORACLE"));
  }

  function curveRegistry() internal view returns (ICurveRegistry) {
    return ICurveRegistry(curveAddressesProvider.get_registry());
  }

  function getCurvePriceUsdc(address lpAddress) public view returns (uint256) {
    if (isLpCryptoPool(lpAddress)) {
      return cryptoPoolLpPriceUsdc(lpAddress);
    }
    uint256 basePrice = getBasePrice(lpAddress);
    uint256 virtualPrice = getVirtualPrice(lpAddress);
    IERC20 usdc = IERC20(oracle().usdcAddress());
    uint256 decimals = usdc.decimals();
    uint256 decimalsAdjustment = 18 - decimals;
    uint256 priceUsdc = (virtualPrice * basePrice * (10**decimalsAdjustment)) /
      10**(decimalsAdjustment + 18);
    return priceUsdc;
  }

  function cryptoPoolLpTotalValueUsdc(address lpAddress)
    public
    view
    returns (uint256)
  {
    address poolAddress = curveRegistry().get_pool_from_lp_token(lpAddress);


      address[] memory underlyingTokensAddresses
     = cryptoPoolUnderlyingTokensAddressesByPoolAddress(poolAddress);
    uint256 totalValue;
    for (
      uint256 tokenIdx;
      tokenIdx < underlyingTokensAddresses.length;
      tokenIdx++
    ) {
      uint256 tokenValueUsdc = cryptoPoolTokenAmountUsdc(poolAddress, tokenIdx);
      totalValue += tokenValueUsdc;
    }
    return totalValue;
  }

  function cryptoPoolLpPriceUsdc(address lpAddress)
    public
    view
    returns (uint256)
  {
    uint256 totalValueUsdc = cryptoPoolLpTotalValueUsdc(lpAddress);
    uint256 totalSupply = ILp(lpAddress).totalSupply();
    uint256 priceUsdc = (totalValueUsdc * 10**18) / totalSupply;
    return priceUsdc;
  }

  struct TokenAmount {
    address tokenAddress;
    string tokenSymbol;
    uint256 amountUsdc;
  }

  function cryptoPoolTokenAmountsUsdc(address poolAddress)
    public
    view
    returns (TokenAmount[] memory)
  {

      address[] memory underlyingTokensAddresses
     = cryptoPoolUnderlyingTokensAddressesByPoolAddress(poolAddress);
    TokenAmount[] memory _tokenAmounts = new TokenAmount[](
      underlyingTokensAddresses.length
    );
    for (
      uint256 tokenIdx;
      tokenIdx < underlyingTokensAddresses.length;
      tokenIdx++
    ) {
      address tokenAddress = underlyingTokensAddresses[tokenIdx];
      string memory tokenSymbol = IERC20(tokenAddress).symbol();
      uint256 amountUsdc = cryptoPoolTokenAmountUsdc(poolAddress, tokenIdx);
      _tokenAmounts[tokenIdx] = TokenAmount({
        tokenAddress: tokenAddress,
        tokenSymbol: tokenSymbol,
        amountUsdc: amountUsdc
      });
    }
    return _tokenAmounts;
  }

  function cryptoPoolTokenAmountUsdc(address poolAddress, uint256 tokenIdx)
    public
    view
    returns (uint256)
  {
    ICryptoPool pool = ICryptoPool(poolAddress);
    address tokenAddress = pool.coins(tokenIdx);
    uint8 decimals = IERC20(tokenAddress).decimals();
    uint256 tokenPrice;
    if (tokenIdx == 0) {
      tokenPrice = 1 * 10**18;
    } else {
      tokenPrice = pool.price_oracle(tokenIdx - 1);
    }
    uint256 tokenBalance = pool.balances(tokenIdx) * 10**(18 - decimals);
    uint256 tokenValueUsdc = (tokenPrice * tokenBalance) / 10**18 / 10**12;
    return tokenValueUsdc;
  }

  function cryptoPoolUnderlyingTokensAddressesByPoolAddress(address poolAddress)
    public
    view
    returns (address[] memory)
  {
    uint256 numberOfTokens;
    address[] memory _tokensAddresses = new address[](8);
    for (uint256 coinIdx; coinIdx < 8; coinIdx++) {
      (bool success, bytes memory data) = address(poolAddress).staticcall(
        abi.encodeWithSignature("coins(uint256)", coinIdx)
      );
      if (success) {
        address tokenAddress = abi.decode(data, (address));
        _tokensAddresses[coinIdx] = tokenAddress;
        numberOfTokens++;
      } else {
        break;
      }
    }
    bytes memory encodedAddresses = abi.encode(_tokensAddresses);
    assembly {
      mstore(add(encodedAddresses, 0x40), numberOfTokens)
    }
    address[] memory filteredAddresses = abi.decode(
      encodedAddresses,
      (address[])
    );
    return filteredAddresses;
  }

  function getBasePrice(address lpAddress) public view returns (uint256) {
    address poolAddress = curveRegistry().get_pool_from_lp_token(lpAddress);
    address underlyingCoinAddress = getUnderlyingCoinFromPool(poolAddress);
    uint256 basePriceUsdc = oracle().getPriceUsdcRecommended(
      underlyingCoinAddress
    );
    return basePriceUsdc;
  }

  function getVirtualPrice(address lpAddress) public view returns (uint256) {
    return curveRegistry().get_virtual_price_from_lp_token(lpAddress);
  }

  function isCurveLpToken(address lpAddress) public view returns (bool) {
    address poolAddress = curveRegistry().get_pool_from_lp_token(lpAddress);
    bool tokenHasCurvePool = poolAddress != address(0);
    return tokenHasCurvePool;
  }

  function isLpCryptoPool(address lpAddress) public view returns (bool) {
    address poolAddress = curveRegistry().get_pool_from_lp_token(lpAddress);
    (bool success, ) = address(poolAddress).staticcall(
      abi.encodeWithSignature("price_oracle(uint256)", 0)
    );
    return success;
  }

  function isPoolCryptoPool(address poolAddress) public view returns (bool) {
    (bool success, ) = address(poolAddress).staticcall(
      abi.encodeWithSignature("price_oracle(uint256)", 0)
    );
    return success;
  }

  function isBasicToken(address tokenAddress) public view returns (bool) {
    return
      ICalculationsChainlink(
        yearnAddressesProvider.addressById("CALCULATIONS_CHAINLINK")
      ).oracleNamehashes(tokenAddress) != bytes32(0);
  }

  function getUnderlyingCoinFromPool(address poolAddress)
    public
    view
    returns (address)
  {
    address[8] memory coins = curveRegistry().get_underlying_coins(poolAddress);

    // Look for preferred coins (basic coins)
    address preferredCoinAddress;
    for (uint256 coinIdx = 0; coinIdx < 8; coinIdx++) {
      address coinAddress = coins[coinIdx];
      if (isBasicToken(coinAddress)) {
        preferredCoinAddress = coinAddress;
        break;
      } else if (coinAddress != address(0)) {
        preferredCoinAddress = coinAddress;
      }
      // Found preferred coin and we're at the end of the token array
      if (
        (preferredCoinAddress != address(0) && coinAddress == address(0)) ||
        coinIdx == 7
      ) {
        break;
      }
    }
    return preferredCoinAddress;
  }

  function getPriceUsdc(address assetAddress) public view returns (uint256) {
    if (isCurveLpToken(assetAddress)) {
      return getCurvePriceUsdc(assetAddress);
    }
    revert();
  }

  /**
   * Allow storage slots to be manually updated
   */
  function updateSlot(bytes32 slot, bytes32 value) external {
    require(msg.sender == ownerAddress, "Ownable: Admin only");
    assembly {
      sstore(slot, value)
    }
  }
}