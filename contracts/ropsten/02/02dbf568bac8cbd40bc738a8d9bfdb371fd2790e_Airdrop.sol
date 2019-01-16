pragma solidity ^0.4.24;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}




contract AirdropperRole {
  using Roles for Roles.Role;

  event AirdropperAdded(address indexed account);
  event AirdropperRemoved(address indexed account);

  Roles.Role private Airdroppers;

  constructor() internal {
    _addAirdropper(msg.sender);
  }

  modifier onlyAirdropper() {
    require(isAirdropper(msg.sender));
    _;
  }

  function isAirdropper(address account) public view returns (bool) {
    return Airdroppers.has(account);
  }

  function addAirdropper(address account) public onlyAirdropper {
    _addAirdropper(account);
  }

  function renounceAirdropper() public {
    _removeAirdropper(msg.sender);
  }

  function _addAirdropper(address account) internal {
    Airdroppers.add(account);
    emit AirdropperAdded(account);
  }

  function _removeAirdropper(address account) internal {
    Airdroppers.remove(account);
    emit AirdropperRemoved(account);
  }
}




/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}



contract Token {
    function transfer(address to, uint value) public returns (bool);
}

contract Airdrop is Ownable,AirdropperRole {

    function simplesend(address _tokenAddr, address  _to, uint256  _value) public 
        onlyAirdropper   
        returns (bool _success) {
        assert((Token(_tokenAddr).transfer(_to, _value)) == true);
        return true;

    }

    function multisend(address _tokenAddr, address[] memory _to, uint256[] memory _value) public 
        onlyAirdropper
        returns (bool _success) {
          
        assert(_to.length == _value.length);
        assert(_to.length <= 150);
        // loop through to addresses and send value
        for (uint8 i = 0; i < _to.length; i++) {
            assert((Token(_tokenAddr).transfer(_to[i], _value[i])) == true);
        }
        return true;

    }

}