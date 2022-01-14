/**
 *Submitted for verification at FtmScan.com on 2022-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/*******************************************************
 *                      Interfaces
 *******************************************************/
interface IComptroller {
  function isMarketListed(address) external view returns (bool);
}

interface IRegistryAdapter {
  function assetsTokensAddresses() external view returns (address[] memory);

  function comptrollerAddress() external view returns (address);
}

interface IAddressesProvider {
  function addressById(string memory) external view returns (address);
}

/*******************************************************
 *                      Implementation
 *******************************************************/
contract AllowlistImplementationIronBank {
  address public addressesProviderAddress;

  constructor(address _addressesProviderAddress) {
    addressesProviderAddress = _addressesProviderAddress;
  }

  /**
   * @notice Determine whether a given token is a valid market underlying token
   * @param tokenAddress The market token address to test
   * @return Returns true if the token address is a valid underlying token, false if not
   */
  function isMarketUnderlyingToken(address tokenAddress)
    public
    view
    returns (bool)
  {
    address[] memory tokensAddresses = registryAdapter()
      .assetsTokensAddresses();
    for (uint256 tokenIdx; tokenIdx < tokensAddresses.length; tokenIdx++) {
      address currentTokenAddress = tokensAddresses[tokenIdx];
      if (currentTokenAddress == tokenAddress) {
        return true;
      }
    }
    return false;
  }

  /**
   * @notice Determine whether or not a given address is the current comptroller
   * @param comptrollerAddress The address to test
   * @return Returns true if the address is the correct comptroller
   */
  function isComptroller(address comptrollerAddress)
    public
    view
    returns (bool)
  {
    return comptrollerAddress == address(comptroller());
  }

  /**
   * @notice Determine whether or not a given market is a valid market
   * @param marketAddress The market address to test
   * @return Returns true if the market is valid and false if not
   */
  function isMarket(address marketAddress) public view returns (bool) {
    return comptroller().isMarketListed(marketAddress);
  }

  /**
   * @notice Determine whether or not a given market is a valid market
   * @param marketAddresses The market addresses to test
   * @return Returns true if the market is valid and false if not
   */
  function areMarkets(address[] memory marketAddresses)
    public
    view
    returns (bool)
  {
    for (uint256 marketIdx; marketIdx < marketAddresses.length; marketIdx++) {
      address marketAddress = marketAddresses[marketIdx];
      if (!isMarket(marketAddress)) {
        return false;
      }
    }
    return true;
  }

  /**
   * @dev Internal convienence method used to fetch comptroller interface
   */
  function comptroller() internal view returns (IComptroller) {
    address comptrollerAddress = registryAdapter().comptrollerAddress();
    return IComptroller(comptrollerAddress);
  }

  /**
   * @dev Internal convienence method used to fetch registry adapter interface
   */
  function registryAdapter() internal view returns (IRegistryAdapter) {
    address registryAdapterAddress = IAddressesProvider(
      addressesProviderAddress
    ).addressById("REGISTRY_ADAPTER_IRON_BANK");
    return IRegistryAdapter(registryAdapterAddress);
  }
}