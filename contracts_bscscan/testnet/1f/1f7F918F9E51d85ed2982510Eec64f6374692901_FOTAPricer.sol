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
    require(_isMainAdmin(), "onlyMainAdmin");
    _;
  }

  function transferOwnership(address _newOwner) onlyMainAdmin external {
    require(_newOwner != address(0x0));
    mainAdmin = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function _isMainAdmin() public view returns (bool) {
    return msg.sender == mainAdmin;
  }
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "../libs/fota/Auth.sol";

contract PriceAuth is Auth {
  address normalPriceAdmin;
  address minMaxPriceAdmin;
  address absMinMaxPriceAdmin;

  function initialize(
    address _mainAdmin,
    address _normalPriceAdmin,
    address _minMaxPriceAdmin,
    address _absMinMaxPriceAdmin
  ) public {
    Auth.initialize(_mainAdmin);
    normalPriceAdmin = _normalPriceAdmin;
    minMaxPriceAdmin = _minMaxPriceAdmin;
    absMinMaxPriceAdmin = _absMinMaxPriceAdmin;
  }

  modifier onlyNormalPriceAdmin() {
    require(msg.sender == normalPriceAdmin || _isMainAdmin(), "onlyNormalPriceAdmin");
    _;
  }

  modifier onlyMinMaxPriceAdmin() {
    require(msg.sender == minMaxPriceAdmin || _isMainAdmin(), "onlyMinMaxPriceAdmin");
    _;
  }

  modifier onlyAbsMinMaxPriceAdmin() {
    require(msg.sender == absMinMaxPriceAdmin || _isMainAdmin(), "onlyAbsMinMaxPriceAdmin");
    _;
  }

  function updateNormalPriceAdmin(address _normalPriceAdmin) onlyMainAdmin external {
    require(_normalPriceAdmin != address(0), "Invalid address");
    normalPriceAdmin = _normalPriceAdmin;
  }

  function updateMinMaxPriceAdmin(address _minMaxPriceAdmin) onlyMainAdmin external {
    require(_minMaxPriceAdmin != address(0), "Invalid address");
    minMaxPriceAdmin = _minMaxPriceAdmin;
  }

  function updateAbsMinMaxPriceAdmin(address _absMinMaxPriceAdmin) onlyMainAdmin external {
    require(_absMinMaxPriceAdmin != address(0), "Invalid address");
    absMinMaxPriceAdmin = _absMinMaxPriceAdmin;
  }
}

contract FOTAPricer is PriceAuth {

  uint public fotaPrice; // decimal 3
  uint public minPrice;
  uint public maxPrice;
  uint public absMinPrice;
  uint public absMaxPrice;

  event FOTAPriceSynced(
    uint newPrice,
    uint timestamp
  );
  event Warning(
    uint fotaPrice,
    uint minPrice,
    uint maxPrice,
    uint absMinPrice,
    uint absMaxPrice
  );

  function initialize(
    address _mainAdmin,
    address _normalPriceAdmin,
    address _minMaxPriceAdmin,
    address _absMinMaxPriceAdmin,
    uint _fotaPrice
  ) public initializer {
    PriceAuth.initialize(_mainAdmin, _normalPriceAdmin, _minMaxPriceAdmin, _absMinMaxPriceAdmin);
    fotaPrice = _fotaPrice;
    absMinPrice = _fotaPrice / 3;
    absMaxPrice = _fotaPrice * 3;
    _updateMinMaxPrice(_fotaPrice * 90 / 100, fotaPrice * 105 / 100);
  }

  function syncFOTAPrice(uint _fotaPrice) external onlyNormalPriceAdmin {
    require(
      _fotaPrice >= minPrice &&
      _fotaPrice <= maxPrice &&
      _fotaPrice >= absMinPrice &&
      _fotaPrice <= absMaxPrice, "Price is invalid");
    fotaPrice = _fotaPrice;
    emit FOTAPriceSynced(fotaPrice, block.timestamp);
  }

  function updateMinMaxPrice(uint _minPrice, uint _maxPrice) external onlyMinMaxPriceAdmin {
    _updateMinMaxPrice(_minPrice, _maxPrice);
  }

  function updateAbsMinMaxPrice(uint _absMinPrice, uint _absMaxPrice) external onlyAbsMinMaxPriceAdmin {
    require(_absMaxPrice > _absMinPrice, "Price is invalid");
    absMinPrice = _absMinPrice;
    absMaxPrice = _absMaxPrice;
  }

  function _updateMinMaxPrice(uint _minPrice, uint _maxPrice) private {
    if (_minPrice < absMinPrice || _maxPrice > absMaxPrice) {
      emit Warning(fotaPrice, minPrice, maxPrice, absMinPrice, absMaxPrice);
    } else {
      minPrice = _minPrice;
      maxPrice = _maxPrice;
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