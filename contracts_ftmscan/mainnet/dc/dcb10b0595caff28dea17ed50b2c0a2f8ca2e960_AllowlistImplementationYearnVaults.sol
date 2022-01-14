/**
 *Submitted for verification at FtmScan.com on 2022-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/*******************************************************
 *                      Interfaces
 *******************************************************/
interface IRegistry {
  function isRegistered(address) external view returns (bool);

  function numVaults(address) external view returns (uint256);

  function vaults(address, uint256) external view returns (address);
}

interface IRegistryAdapter {
  function registryAddress() external view returns (address);
}

interface IVault {
  function token() external view returns (address);
}

interface IAllowlistFactory {
  function protocolOwnerAddressByOriginName(string memory originName)
    external
    view
    returns (address ownerAddress);
}

interface IAddressesProvider {
  function addressById(string memory) external view returns (address);
}

/*******************************************************
 *                      Implementation
 *******************************************************/
contract AllowlistImplementationYearnVaults {
  string public constant protocolOriginName = "yearn.finance"; // Protocol owner name (must match the registered domain of the registered allowlist)
  address public addressesProviderAddress; // Used to fetch current registry
  address public allowlistFactoryAddress; // Used to fetch protocol owner
  mapping(address => bool) public isZapInContract; // Used to test zap in contracts
  mapping(address => bool) public isZapOutContract; // Used to test zap out contracts
  mapping(address => bool) public isMigratorContract; // Used to test migrator contracts
  mapping(address => bool) public isPickleJarContract; // Used to test the pickle jar zap

  constructor(
    address _addressesProviderAddress,
    address _allowlistFactoryAddress
  ) {
    addressesProviderAddress = _addressesProviderAddress; // Set address provider address (can be updated by owner)
    allowlistFactoryAddress = _allowlistFactoryAddress; // Set allowlist factory address (can only be set once)
  }

  /**
   * @notice Only allow protocol owner to perform certain actions
   */
  modifier onlyOwner() {
    require(msg.sender == ownerAddress(), "Caller is not the protocol owner");
    _;
  }

  /**
   * @notice Fetch owner address from factory
   */
  function ownerAddress() public view returns (address protcolOwnerAddress) {
    protcolOwnerAddress = IAllowlistFactory(allowlistFactoryAddress)
      .protocolOwnerAddressByOriginName(protocolOriginName);
  }

  /**
   * @notice Set whether or not a contract is a valid zap in contract
   * @param contractAddress Address of zap in contract
   * @param allowed If true contract is a valid zap in contract, if false, contract is not
   */
  function setIsZapInContract(address contractAddress, bool allowed)
    public
    onlyOwner
  {
    isZapInContract[contractAddress] = allowed;
  }

  /**
   * @notice Set whether or not a contract is a valid zap out contract
   * @param contractAddress Address of zap out contract
   * @param allowed If true contract is a valid zap out contract, if false, contract is not
   */
  function setIsZapOutContract(address contractAddress, bool allowed)
    public
    onlyOwner
  {
    isZapOutContract[contractAddress] = allowed;
  }

  /**
   * @notice Set whether or not a contract is a valid migrator
   * @param contractAddress Address of migrator contract
   * @param allowed If true contract is a valid migrator, if false, contract is not
   */
  function setIsMigratorContract(address contractAddress, bool allowed)
    public
    onlyOwner
  {
    isMigratorContract[contractAddress] = allowed;
  }

  /**
   * @notice Set whether or not a contract is a valid zap out contract
   * @param contractAddress Address of zap out contract
   * @param allowed If true contract is a valid zap out contract, if false, contract is not
   */
  function setIsPickleJarContract(address contractAddress, bool allowed)
    public
    onlyOwner
  {
    isPickleJarContract[contractAddress] = allowed;
  }

  /**
   * @notice Determine whether or not a vault address is a valid vault
   * @param tokenAddress The vault token address to test
   * @return Returns true if the valid address is valid and false if not
   */
  function isVaultUnderlyingToken(address tokenAddress)
    public
    view
    returns (bool)
  {
    return registry().isRegistered(tokenAddress);
  }

  /**
   * @notice Determine whether or not a vault address is a valid vault
   * @param vaultAddress The vault address to test
   * @return Returns true if the valid address is valid and false if not
   */
  function isVault(address vaultAddress) public view returns (bool) {
    IVault vault = IVault(vaultAddress);
    address tokenAddress;
    try vault.token() returns (address _tokenAddress) {
      tokenAddress = _tokenAddress;
    } catch {
      return false;
    }
    uint256 numVaults = registry().numVaults(tokenAddress);
    for (uint256 vaultIdx; vaultIdx < numVaults; vaultIdx++) {
      address currentVaultAddress = registry().vaults(tokenAddress, vaultIdx);
      if (currentVaultAddress == vaultAddress) {
        return true;
      }
    }
    return false;
  }

  /*******************************************************
   *                    Convienence methods
   *******************************************************/

  /**
   * @dev Fetch registry adapter address
   */
  function registryAdapterAddress() public view returns (address) {
    return IAddressesProvider(
      addressesProviderAddress
    ).addressById("REGISTRY_ADAPTER_V2_VAULTS");
  }

  /**
   * @dev Fetch registry adapter interface
   */
  function registryAdapter() internal view returns (IRegistryAdapter) {
    return IRegistryAdapter(registryAdapterAddress());
  }

  /**
   * @dev Fetch registry address
   */
  function registryAddress() public view returns (address) {
    return registryAdapter().registryAddress();
  }

  /**
   * @dev Fetch registry interface
   */
  function registry() internal view returns (IRegistry) {
    return IRegistry(registryAddress());
  }
}