// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "./libs/fota/Auth.sol";
import "./libs/fota/StringUtil.sol";

contract Citizen is Auth {
  using StringUtil for string;
  struct Resident {
    uint id;
    string userName;
    address inviter;
  }
  mapping (address => Resident) public residents;
  mapping (bytes24 => address) private userNameAddresses;
  uint totalResident;

  event Registered(address userAddress, string userName, address inviter, uint timestamp);

  function initialize(address _mainAdmin) override public initializer {
    super.initialize(_mainAdmin);
  }

  function register(address _address, string calldata _userName, address _inviter) external returns (uint) {
    if (_inviter != address(0)) {
      require(isCitizen(_inviter) && _address != _inviter, "Citizen: inviter is invalid");
    }
    require(_userName.validateUserName(), "Citizen: invalid userName");
    Resident storage resident = residents[_address];
    require(!isCitizen(_address), "Citizen: already an citizen");
    bytes24 _userNameAsKey = _userName.toBytes24();
    require(userNameAddresses[_userNameAsKey] == address(0), "Citizen: userName already exist");
    userNameAddresses[_userNameAsKey] = _address;

    totalResident += 1;
    resident.id = totalResident;
    resident.userName = _userName;
    resident.inviter = _inviter;
    emit Registered(_address, _userName, _inviter, block.timestamp);
    return resident.id;
  }

  function isCitizen(address _address) view public returns (bool) {
    Resident storage resident = residents[_address];
    return resident.id > 0;
  }

  function getInviter(address _address) view public returns (address) {
    Resident storage resident = residents[_address];
    return resident.inviter;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Auth is Initializable {

  address internal mainAdmin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
  function initialize(address _mainAdmin) virtual public initializer {
    mainAdmin = _mainAdmin;
  }

  modifier onlyMainAdmin() {
    require(isMainAdmin(), "onlyMainAdmin");
    _;
  }

  function transferOwnership(address _newOwner) onlyMainAdmin external {
    require(_newOwner != address(0x0));
    mainAdmin = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function isMainAdmin() public view returns (bool) {
    return msg.sender == mainAdmin;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

library StringUtil {
  struct slice {
    uint _length;
    uint _pointer;
  }

  function validateUserName(string calldata _username)
  internal
  pure
  returns (bool)
  {
    uint8 len = uint8(bytes(_username).length);
    if ((len < 4) || (len > 21)) return false;

    // only contain A-Z 0-9
    for (uint8 i = 0; i < len; i++) {
      if (
        (uint8(bytes(_username)[i]) < 48) ||
        (uint8(bytes(_username)[i]) > 57 && uint8(bytes(_username)[i]) < 65) ||
        (uint8(bytes(_username)[i]) > 90)
      ) return false;
    }
    // First char != '0'
    return uint8(bytes(_username)[0]) != 48;
  }

  function toBytes24(string memory source)
  internal
  pure
  returns (bytes24 result)
  {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly {
      result := mload(add(source, 24))
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

