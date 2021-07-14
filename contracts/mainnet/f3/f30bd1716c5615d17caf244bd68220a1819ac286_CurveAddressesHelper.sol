/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface ICalculationsCurve {
  function isCurveLpToken(address) external view returns (bool);
}

interface IV2Vault {
  function token() external view returns (address);
}

interface IAddressesGenerator {
  function assetsAddresses() external view returns (address[] memory);
}

interface ICurveAddressesProvider {
  function max_id() external view returns (uint256);

  function get_registry() external view returns (address);

  function get_address(uint256) external view returns (address);
}

interface IGaugeController {
  function n_gauges() external view returns (uint256);
  
  function gauges(uint256) external view returns (address);
}

interface IMetapoolFactory {
  function get_underlying_coins(address)
    external
    view
    returns (address[8] memory);
}

interface IRegistry {
  function get_pool_from_lp_token(address) external view returns (address);
  
  function gauge_controller() external view returns (address);

  function get_underlying_coins(address)
    external
    view
    returns (address[8] memory);

  function get_gauges(address) external view returns (address[10] memory);
  
  function pool_count() external view returns (uint256);
  
  function pool_list(uint256) external view returns (address);
  
  function coin_count() external view returns (uint256);
  
  function get_coin(uint256) external view returns (address);
  
  function get_lp_token(address) external view returns (address);
}

interface IYearnAddressesProvider {
    function addressById(string memory) external view returns (address);
}

contract CurveAddressesHelper {
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
    yearnAddressesProvider = IYearnAddressesProvider(_yearnAddressesProviderAddress);
    curveAddressesProvider = ICurveAddressesProvider(_curveAddressesProviderAddress);
  }

  function registryAddress() public view returns (address) {
    return curveAddressesProvider.get_registry();
  }

  function metapoolFactoryAddress() public view returns (address) {
    return curveAddressesProvider.get_address(3);
  }

  function registry() internal view returns (IRegistry) {
    return IRegistry(registryAddress());
  }

  function underlyingTokensAddressesFromLpAddress(address lpAddress)
    public
    view
    returns (address[] memory)
  {
    address[] memory underlyingTokensAddresses = new address[](16);
    uint256 currentIdx;
    address[8] memory registryUnderlyingTokensAddresses =
      registryTokensAddressesFromLpAddress(lpAddress);
    address[8] memory metapoolUnderlyingTokensAddresses =
      metapoolTokensAddressesFromLpAddress(lpAddress);
    for (
      uint256 tokenIdx;
      tokenIdx < registryUnderlyingTokensAddresses.length;
      tokenIdx++
    ) {
      address tokenAddress = registryUnderlyingTokensAddresses[tokenIdx];
      if (tokenAddress != address(0)) {
        underlyingTokensAddresses[currentIdx] = tokenAddress;
        currentIdx++;
      }
    }
    for (
      uint256 tokenIdx;
      tokenIdx < metapoolUnderlyingTokensAddresses.length;
      tokenIdx++
    ) {
      address tokenAddress = metapoolUnderlyingTokensAddresses[tokenIdx];
      if (tokenAddress != address(0)) {
        underlyingTokensAddresses[currentIdx] = tokenAddress;
        currentIdx++;
      }
    }
    bytes memory encodedAddresses = abi.encode(underlyingTokensAddresses);
    assembly {
      mstore(add(encodedAddresses, 0x40), currentIdx)
    }
    address[] memory filteredAddresses =
      abi.decode(encodedAddresses, (address[]));
    return filteredAddresses;
  }

  function registryTokensAddressesFromLpAddress(address lpAddress)
    public
    view
    returns (address[8] memory)
  {
    address[8] memory tokensAddresses =
      registry().get_underlying_coins(lpAddress);
    return tokensAddresses;
  }

  function metapoolTokensAddressesFromLpAddress(address lpAddress)
    public
    view
    returns (address[8] memory)
  {
    address[8] memory tokensAddresses =
      IMetapoolFactory(metapoolFactoryAddress()).get_underlying_coins(
        lpAddress
      );
    return tokensAddresses;
  }

  function poolAddressFromLpAddress(address lpAddress)
    public
    view
    returns (address)
  {
    address[8] memory metapoolTokensAddresses =
      metapoolTokensAddressesFromLpAddress(lpAddress);
    for (uint256 tokenIdx; tokenIdx < 8; tokenIdx++) {
      address tokenAddress = metapoolTokensAddresses[tokenIdx];
      if (tokenAddress != address(0)) {
        return lpAddress;
      }
    }
    return registry().get_pool_from_lp_token(lpAddress);
  }

  function gaugeAddressesFromLpAddress(address lpAddress)
    public
    view
    returns (address[] memory)
  {
    address poolAddress = poolAddressFromLpAddress(lpAddress);
    address[] memory gaugeAddresses =
      gaugeAddressesFromPoolAddress(poolAddress);
    return gaugeAddresses;
  }
  
  function gaugeAddressesFromPoolAddress(address poolAddress)
    public
    view
    returns (address[] memory)
  {
    address[10] memory _gaugesAddresses = registry().get_gauges(poolAddress);
    address[] memory filteredGaugesAddresses = new address[](10);
    uint256 numberOfGauges;
    for (uint256 gaugeIdx; gaugeIdx < _gaugesAddresses.length; gaugeIdx++) {
      address gaugeAddress = _gaugesAddresses[gaugeIdx];
      if (gaugeAddress == address(0)) {
        break;
      }
      filteredGaugesAddresses[gaugeIdx] = gaugeAddress;
      numberOfGauges++;
    }
    bytes memory encodedAddresses = abi.encode(filteredGaugesAddresses);
    assembly {
      mstore(add(encodedAddresses, 0x40), numberOfGauges)
    }
    filteredGaugesAddresses = abi.decode(encodedAddresses, (address[]));
    return filteredGaugesAddresses;
  }

  function yearnGaugesAddresses()
    public
    view
    returns (address[] memory)
  {
    uint256 gaugesLength;
    address[] memory _yearnPoolsAddresses = yearnPoolsAddresses();
    address[] memory _yearnGaugesAddresses =
      new address[](_yearnPoolsAddresses.length * 8);
    for (
      uint256 poolIdx = 0;
      poolIdx < _yearnPoolsAddresses.length;
      poolIdx++
    ) {
      address poolAddress = _yearnPoolsAddresses[poolIdx];
      address[] memory _gaugesAddresses = gaugeAddressesFromPoolAddress(poolAddress);
      for (uint256 gaugeIdx; gaugeIdx < _gaugesAddresses.length; gaugeIdx++) {
        address gaugeAddress = _gaugesAddresses[gaugeIdx];
        _yearnGaugesAddresses[gaugesLength] = gaugeAddress;
        gaugesLength++;
      }
    }
    bytes memory encodedAddresses = abi.encode(_yearnGaugesAddresses);
    assembly {
        mstore(add(encodedAddresses, 0x40), gaugesLength)
    }
    address[] memory filteredAddresses =
        abi.decode(encodedAddresses, (address[]));
    return filteredAddresses;
  }

  function lpsAddresses() external view returns (address[] memory) {
    address[] memory _poolsAddresses = poolsAddresses();
    uint256 numberOfPools = _poolsAddresses.length;
    address[] memory _lpsAddresses = new address[](numberOfPools);
    for (uint256 poolIdx; poolIdx < numberOfPools; poolIdx++) {
        address poolAddress = _poolsAddresses[poolIdx];
        _lpsAddresses[poolIdx] = registry().get_lp_token(poolAddress);
    }
    return _lpsAddresses;
  }
  
  function gaugesAddresses() external view returns (address[] memory) {
    IGaugeController gaugeController = IGaugeController(registry().gauge_controller());
    uint256 numberOfGauges = gaugeController.n_gauges();
    address[] memory _gaugesAddresses = new address[](numberOfGauges);
    for (uint256 gaugeIdx; gaugeIdx < numberOfGauges; gaugeIdx++) {
        _gaugesAddresses[gaugeIdx] = gaugeController.gauges(gaugeIdx);
    }
    return _gaugesAddresses;
  }

  function coinsAddresses() external view returns (address[] memory) {
    uint256 numberOfCoins = registry().coin_count();
    address[] memory _coinsAddresses = new address[](numberOfCoins);
    for (uint256 coinIdx; coinIdx < numberOfCoins; coinIdx++) {
        _coinsAddresses[coinIdx] = registry().get_coin(coinIdx);
    }
    return _coinsAddresses;
  }

  function poolsAddresses() public view returns (address[] memory) {
    uint256 numberOfPools = registry().pool_count();
    address[] memory _poolsAddresses = new address[](numberOfPools);
    for (uint256 poolIdx; poolIdx < numberOfPools; poolIdx++) {
        _poolsAddresses[poolIdx] = registry().pool_list(poolIdx);
    }
    return _poolsAddresses;
  }

  function yearnPoolsAddresses() public view returns (address[] memory) {
    address[] memory _yearnLpsAddresses = yearnLpsAddresses();
    address[] memory _yearnPoolsAddresses =
      new address[](_yearnLpsAddresses.length);
    for (uint256 lpIdx = 0; lpIdx < _yearnLpsAddresses.length; lpIdx++) {
      address lpAddress = _yearnLpsAddresses[lpIdx];
      address poolAddress = poolAddressFromLpAddress(lpAddress);
      _yearnPoolsAddresses[lpIdx] = poolAddress;
    }
    return _yearnPoolsAddresses;
  }
  
  function getAddress(string memory _address) public view returns (address) {
    return yearnAddressesProvider.addressById(_address);
  }
  
  function yearnVaultsAddresses() internal view returns (address[] memory) {
    address[] memory vaultsAddresses =
      IAddressesGenerator(getAddress("ADDRESSES_GENERATOR_V2_VAULTS")).assetsAddresses();
    uint256 currentIdx = 0;
    for (uint256 vaultIdx = 0; vaultIdx < vaultsAddresses.length; vaultIdx++) {
      address vaultAddress = vaultsAddresses[vaultIdx];
      bool isCurveLpVault =
        ICalculationsCurve(getAddress("CALCULATIONS_CURVE")).isCurveLpToken(
          IV2Vault(vaultAddress).token()
        );
      if (isCurveLpVault) {
        vaultsAddresses[currentIdx] = vaultAddress;
        currentIdx++;
      }
    }
    bytes memory encodedVaultsAddresses = abi.encode(vaultsAddresses);
    assembly {
      mstore(add(encodedVaultsAddresses, 0x40), currentIdx)
    }
    address[] memory filteredVaultsAddresses =
      abi.decode(encodedVaultsAddresses, (address[]));
    return filteredVaultsAddresses;
  }

  function yearnLpsAddresses() public view returns (address[] memory) {
    address[] memory _vaultsAddresses = yearnVaultsAddresses();
    address[] memory _lpsAddresses = new address[](_vaultsAddresses.length);
    for (uint256 vaultIdx = 0; vaultIdx < _vaultsAddresses.length; vaultIdx++) {
      address vaultAddress = _vaultsAddresses[vaultIdx];
      IV2Vault vault = IV2Vault(vaultAddress);
      address lpTokenAddress = vault.token();
      _lpsAddresses[vaultIdx] = lpTokenAddress;
    }
    return _lpsAddresses;
  }
}