pragma solidity 0.4.24;

interface IContractAddressLocator {
    function get(bytes32 interfaceName) external view returns (address);
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

/**
 * @title Contract Address Locator Proxy.
 * @dev Hold a contract address locator, which maps a unique interface name to every contract address in the system.
 * @dev On-chain, this contract is used for retrieving the address of any contract in the system.
 * @dev Off-chain, this contract may be used for replacing the contract address locator itself.
 * @dev Thus, system-upgrade (full or partial) can be executed as an atomic operation.
 */
contract ContractAddressLocatorProxy is IContractAddressLocator, Claimable {
    event Upgrade(IContractAddressLocator indexed prev, IContractAddressLocator indexed next);

    IContractAddressLocator private _contractAddressLocator;

    function getServer() external view returns (IContractAddressLocator) {
        return _contractAddressLocator;
    }

    function get(bytes32 interfaceName) external view returns (address) {
        return _contractAddressLocator.get(interfaceName);
    }

    function upgrade(IContractAddressLocator contractAddressLocator) external onlyOwner {
        require(contractAddressLocator != address(0));
        emit Upgrade(_contractAddressLocator, contractAddressLocator);
        _contractAddressLocator = contractAddressLocator;
    }
}