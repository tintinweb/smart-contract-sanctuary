/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @title The Owned contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract Owned {

  address public owner;
  address private pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address _to)
    external
    onlyOwner()
  {
    pendingOwner = _to;

    emit OwnershipTransferRequested(owner, _to);
  }

  /**
   * @dev Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
  {
    require(msg.sender == pendingOwner, "Must be proposed owner");

    address oldOwner = owner;
    owner = msg.sender;
    pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only callable by owner");
    _;
  }

}

contract PendingRegistrations is Owned{
    
  bytes4 constant private REGISTER_REQUEST_SELECTOR = 0x7633d239;
  
  //minimum LINK required to call register    
  uint256 private minLINKWei; 
  
 address immutable public LINK_ADDRESS;
  
  event MinLINKChanged(
    uint256 from,
    uint256 to
  );
  
 event RegistrationRequested(
    bytes32 hash, 
    string name, 
    bytes encryptedEmail, 
    address upkeepContract, 
    uint32 gasLimit,
    address adminAddress, 
    bytes checkData
  );
  
  event RegistrationApproved(
    bytes32 hash, 
    string displayName,
    uint256 upkeepId
  );
  
  constructor(
    address LINKAddress,
    uint256 _minLINKWei
  ) {
      LINK_ADDRESS = LINKAddress;
      minLINKWei = _minLINKWei;
  }
    /**
   * @notice register can only be called through transferAndCall on LINK contract
   * @param _name name of the upkeep to be registered
   * @param _encryptedEmail Amount of LINK sent (specified in wei)
   * @param _upkeepContract address to peform upkeep on
   * @param _gasLimit amount of gas to provide the target contract when
   * performing upkeep
   * @param _adminAddress address to cancel upkeep and withdraw remaining funds
   * @param _checkData data passed to the contract when checking for upkeep
   */
  function register(string memory _name, bytes calldata _encryptedEmail, address _upkeepContract, uint32 _gasLimit, address _adminAddress, bytes calldata _checkData)  
    external
    onlyLINK()
 { 
    bytes32 hash = keccak256(msg.data);
    emit RegistrationRequested(hash, _name, _encryptedEmail, _upkeepContract, _gasLimit, _adminAddress, _checkData);
 }
 
 //owner calls this function after registering upkeep on the Registry contract 
  function approved(bytes32 _hash, string memory _displayName, uint256 _upkeepId) 
  onlyOwner() 
  external
  { 
    emit RegistrationApproved(_hash,_displayName,_upkeepId);
  }
  
  function setMinLINKWei(uint256 _minLINKWei)
    onlyOwner()
    external
  {
      emit MinLINKChanged(minLINKWei,_minLINKWei);
      minLINKWei = _minLINKWei;
  }
  
  function getMinLINKWei()
  external
  view
  returns (uint256)
  {
      return minLINKWei;
  }
  
    /**
   * @notice Called when LINK is sent to the contract via `transferAndCall`
   * @param _sender Address of the sender
   * @param _amount Amount of LINK sent (specified in wei)
   * @param _data Payload of the transaction
   */
  function onTokenTransfer(
    address _sender,
    uint256 _amount,
    bytes calldata _data
  )
    external
    onlyLINK()
    permittedFunctionsForLINK(_data)
  {
    require(_amount >= minLINKWei, "Insufficient payment");
    (bool success, ) = address(this).delegatecall(_data); // calls register
    require(success, "Unable to create request");    
  }
  
  /**
   * @dev Reverts if not sent from the LINK token
   */
  modifier onlyLINK() {
    require(msg.sender == LINK_ADDRESS, "Must use LINK token");
    _;
  }
  
    /**
   * @dev Reverts if the given data does not begin with the `register` function selector
   * @param _data The data payload of the request
   */
  modifier permittedFunctionsForLINK(bytes memory _data) {
    bytes4 funcSelector;
    assembly {
      // solhint-disable-next-line avoid-low-level-calls
      funcSelector := mload(add(_data, 32))
    }
    require(funcSelector == REGISTER_REQUEST_SELECTOR, "Must use whitelisted functions");
    _;
  }

}