// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Auth is Initializable {

  address public mainAdmin;
  address public contractAdmin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
  event ContractAdminUpdated(address indexed _newOwner);

  function initialize(address _mainAdmin) virtual public initializer {
    mainAdmin = _mainAdmin;
    contractAdmin = _mainAdmin;
  }

  modifier onlyMainAdmin() {
    require(_isMainAdmin(), "onlyMainAdmin");
    _;
  }

  modifier onlyContractAdmin() {
    require(_isContractAdmin() || _isMainAdmin(), "onlyContractAdmin");
    _;
  }

  function transferOwnership(address _newOwner) onlyMainAdmin external {
    require(_newOwner != address(0x0));
    mainAdmin = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function updateContractAdmin(address _newAdmin) onlyMainAdmin external {
    require(_newAdmin != address(0x0));
    contractAdmin = _newAdmin;
    emit ContractAdminUpdated(_newAdmin);
  }

  function _isMainAdmin() public view returns (bool) {
    return msg.sender == mainAdmin;
  }

  function _isContractAdmin() public view returns (bool) {
    return msg.sender == contractAdmin;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "../libs/fota/Auth.sol";
import "../libs/zeppelin/token/BEP20/IBEP20.sol";

contract Whitelist is Auth {
  IBEP20 public busdToken;
  IBEP20 public usdtToken;
  uint public totalSlots;
  uint public price;
  uint public totalWhitelisted;
  mapping (address => bool) public whiteList;
  address private fundAdmin;

  enum PaymentCurrency {
    busd,
    usdt
  }

  event SlotReserved(address indexed user, uint totalWhitelisted);
  event TotalSlotUpdated(uint totalSlots);

  function initialize(
    address _mainAdmin
  ) override public initializer {
    Auth.initialize(_mainAdmin);
    busdToken = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    usdtToken = IBEP20(0x55d398326f99059fF775485246999027B3197955);
    totalSlots = 5000;
    price = 500e18;
  }

  // ADMIN FUNCTIONS

  function updateTotalSlot(uint _totalSlots) external onlyMainAdmin {
    require(_totalSlots >= totalWhitelisted, "Whitelist: invalid total slot");
    totalSlots = _totalSlots;
    emit TotalSlotUpdated(totalSlots);
  }

  function updatePrice(uint _price) external onlyMainAdmin {
    require(totalWhitelisted == 0 && _price > 0, "Whitelist: invalid price");
    price = _price;
  }

  function updateFundAdmin(address _address) external onlyMainAdmin {
    require(_address != address(0), "Whitelist: address invalid");
    fundAdmin = _address;
  }

  // PUBLIC FUNCTIONS

  function reserve(PaymentCurrency _paymentCurrency) public {
    require(!whiteList[msg.sender], "Whitelist: already whiteListed");
    whiteList[msg.sender] = true;
    require(totalWhitelisted < totalSlots, "Whitelist: fully whiteListed");
    totalWhitelisted += 1;
    _takeFund(_paymentCurrency);
    emit SlotReserved(msg.sender, totalWhitelisted);
  }

  // PRIVATE FUNCTIONS

  function _takeFund(PaymentCurrency _paymentCurrency) private {
    IBEP20 usdToken = _paymentCurrency == PaymentCurrency.busd ? busdToken : usdtToken;
    require(usdToken.allowance(msg.sender, address(this)) >= price, "Whitelist: please approve usd token first");
    require(usdToken.balanceOf(msg.sender) >= price, "Whitelist: insufficient balance");
    require(usdToken.transferFrom(msg.sender, address(this), price), "Whitelist: transfer usd token failed");
    usdToken.transfer(fundAdmin, usdToken.balanceOf(address(this)));
  }

  // TODO for testing purpose

  function setUsdToken(address _busdToken, address _usdtToken) external onlyMainAdmin {
    busdToken = IBEP20(_busdToken);
    usdtToken = IBEP20(_usdtToken);
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