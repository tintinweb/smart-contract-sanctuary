pragma solidity ^0.6.12;





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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/*
  The contract determines which addresses are permitted
*/
contract PermittedAddresses is Ownable {
  event AddNewPermittedAddress(address newAddress, uint256 addressType);
  event RemovePermittedAddress(address Address);

  // Mapping to permitted addresses
  mapping (address => bool) public permittedAddresses;
  mapping (address => uint256) public addressesTypes;

  enum Types { EMPTY, EXCHANGE_PORTAL, POOL_PORTAL, DEFI_PORTAL, STABLE_COIN }

  /**
  * @dev contructor
  *
  * @param _exchangePortal      Exchange portal contract
  * @param _poolPortal          Pool portal contract
  * @param _stableCoin          Stable coins addresses to permitted
  * @param _defiPortal          Defi portal
  */
  constructor(
    address _exchangePortal,
    address _poolPortal,
    address _stableCoin,
    address _defiPortal
  ) public
  {
    _enableAddress(_exchangePortal, uint256(Types.EXCHANGE_PORTAL));
    _enableAddress(_poolPortal, uint256(Types.POOL_PORTAL));
    _enableAddress(_defiPortal, uint256(Types.DEFI_PORTAL));
    _enableAddress(_stableCoin, uint256(Types.STABLE_COIN));
  }


  /**
  * @dev adding a new address to permittedAddresses
  *
  * @param _newAddress    The new address to permit
  */
  function addNewAddress(address _newAddress, uint256 addressType) public onlyOwner {
    _enableAddress(_newAddress, addressType);
  }

  /**
  * @dev update address type as owner for case if wrong address type was set
  *
  * @param _newAddress    The new address to permit
  */
  function updateAddressType(address _newAddress, uint256 addressType) public onlyOwner {
    addressesTypes[_newAddress] = addressType;
  }

  /**
  * @dev Disables an address, meaning SmartFunds will no longer be able to connect to them
  * if they're not already connected
  *
  * @param _address    The address to disable
  */
  function disableAddress(address _address) public onlyOwner {
    permittedAddresses[_address] = false;
    emit RemovePermittedAddress(_address);
  }

  /**
  * @dev Enables/disables an address
  *
  * @param _newAddress    The new address to set
  * @param addressType    Address type
  */
  function _enableAddress(address _newAddress, uint256 addressType) private {
    permittedAddresses[_newAddress] = true;
    addressesTypes[_newAddress] = addressType;

    emit AddNewPermittedAddress(_newAddress, addressType);
  }

  /**
  * @dev check if input address has the same type as addressType
  */
  function isMatchTypes(address _address, uint256 addressType) public view returns(bool){
    return addressesTypes[_address] == addressType;
  }

  /**
  * @dev return address type
  */
  function getType(address _address) public view returns(uint256){
    return addressesTypes[_address];
  }
}