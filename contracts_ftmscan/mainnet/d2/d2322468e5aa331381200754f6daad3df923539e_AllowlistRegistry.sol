// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./CalldataValidation.sol";
import "./IAllowlist.sol";

/*******************************************************
 *                      Interfaces
 *******************************************************/
interface IAllowlistFactory {
  function cloneAllowlist(string memory, address) external returns (address);
}

interface IProtocolOwnership {
  function ownerAddressByName(string memory) external view returns (address);
}

/*******************************************************
 *                   Main Contract Logic
 *******************************************************/
contract AllowlistRegistry {
  address public factoryAddress;
  string[] public registeredProtocols; // Array of all protocols which have successfully completed registration
  mapping(string => address) public allowlistAddressByOriginName; // Address of protocol specific allowlist
  address public protocolOwnershipAddress; // Address of temporary protocol ownership contract (TODO: Implement DNSSEC validation on Fantom)

  constructor(address _factoryAddress, address _protocolOwnershipAddress) {
    factoryAddress = _factoryAddress;
    protocolOwnershipAddress = _protocolOwnershipAddress;
  }

  /**
   * @notice Determine protocol onwer address given an origin name
   * @param originName is the domain name for a protocol (ie. "yearn.finance")
   * @return ownerAddress Returns the address of the domain controller if the domain is registered on ENS
   */
  function protocolOwnerAddressByOriginName(string memory originName)
    public
    view
    returns (address ownerAddress)
  {
    ownerAddress = IProtocolOwnership(protocolOwnershipAddress).ownerAddressByName(originName);
  }

  /**
   * @notice Begin protocol registration
   * @param originName is the domain name for a protocol (ie. "yearn.finance")
   * @dev Only valid protocol owners can begin registration
   * @dev Beginning registration generates a smart contract each protocol can use
   *      to manage their conditions and validation implementation logic
   * @dev Only fully registered protocols appear on the registration list
   */
  function registerProtocol(string memory originName) public {
    // Make sure caller is protocol owner
    address protocolOwnerAddress = protocolOwnerAddressByOriginName(originName);
    require(
      protocolOwnerAddress == msg.sender,
      "Only protocol owners can register protocols"
    );

    // Make sure protocol is not already registered
    bool protocolIsAlreadyRegistered = allowlistAddressByOriginName[
      originName
    ] != address(0);
    require(
      protocolIsAlreadyRegistered == false,
      "Protocol is already registered"
    );

    // Clone, register and initialize allowlist
    address allowlistAddress = IAllowlistFactory(factoryAddress).cloneAllowlist(
      originName,
      protocolOwnerAddress
    );
    allowlistAddressByOriginName[originName] = allowlistAddress;

    // Register protocol
    registeredProtocols.push(originName);
  }

  /**
   * @notice Return a list of fully registered protocols
   */
  function registeredProtocolsList() public view returns (string[] memory) {
    return registeredProtocols;
  }

  /**
   * @notice Allow protocol owners to override and replace existing allowlist
   * @dev This method is destructive and cannot be undone
   * @dev Protocols can only re-register if they have already registered once
   */
  function reregisterProtocol(
    string memory originName,
    IAllowlist.Condition[] memory conditions
  ) public {
    address protocolOwnerAddress = protocolOwnerAddressByOriginName(originName);
    bool callerIsProtocolOwner = protocolOwnerAddress == msg.sender;
    bool protocolIsRegistered = allowlistAddressByOriginName[originName] !=
      address(0);

    // Only owner can re-register
    require(
      callerIsProtocolOwner,
      "Only protocol owners can replace their allowlist with a new allowlist"
    );

    // Only registered protocols can re-register
    require(protocolIsRegistered, "Protocol is not yet registered");

    // Delete existing allowlist
    delete allowlistAddressByOriginName[originName];

    // Clone, re-register and initialize allowlist
    IAllowlistFactory allowlistFactory = IAllowlistFactory(factoryAddress);
    address allowlistAddress = allowlistFactory.cloneAllowlist(
      originName,
      address(this)
    );
    allowlistAddressByOriginName[originName] = allowlistAddress;

    // Add conditions to new allowlist
    IAllowlist allowlist = IAllowlist(allowlistAddress);
    allowlist.addConditions(conditions);
    IAllowlist(allowlist).setOwnerAddress(protocolOwnerAddress);
  }

  /**
   * @notice Determine whether or not a given target and calldata is valid
   * @dev In order to be valid, target and calldata must pass the allowlist conditions tests
   * @param targetAddress The target address of the method call
   * @param data The raw calldata of the call
   * @return isValid True if valid, false if not
   */
  function validateCalldataByOrigin(
    string memory originName,
    address targetAddress,
    bytes calldata data
  ) public view returns (bool isValid) {
    address allowlistAddress = allowlistAddressByOriginName[originName];
    isValid = CalldataValidation.validateCalldataByAllowlist(
      allowlistAddress,
      targetAddress,
      data
    );
  }
}