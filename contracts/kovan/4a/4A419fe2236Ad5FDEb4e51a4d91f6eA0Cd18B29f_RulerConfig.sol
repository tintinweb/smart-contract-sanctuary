// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./interfaces/IRulerConfig.sol";
import "./utils/Ownable.sol";

/**
 * @title Ruler Config contract
 * @author crypto-pumpkin
 */
contract RulerConfig is Ownable, IRulerConfig {

  bool public override paused;
  address public override responder;
  address public override feeReceiver;
  address public override rERC20Impl;
  uint256 public override flashLoanRate = 0.00085 ether;
  uint256 public override depositFeeRate = 0.0005 ether;
  uint256 public override depositPauseWindow = 24 hours;
  uint256 public override collectFeeRate = 0.001 ether;

  constructor(address _responder, address _feeReceiver, address _rERC20Impl) {
    require(_responder != address(0), "_responder cannot be 0");
    require(_feeReceiver != address(0), "_feeReceiver cannot be 0");
    require(_rERC20Impl != address(0), "_rERC20Impl cannot be 0");
    responder = _responder;
    feeReceiver = _feeReceiver;
    rERC20Impl = _rERC20Impl;
    initializeOwner();
  }

  /// @notice flashloan rate can be anything
  function setFlashLoanRate(uint256 _newRate) external override onlyOwner {
    emit FlashLoanRateUpdated(flashLoanRate, _newRate);
    flashLoanRate = _newRate;
  }

  function setFeeReceiver(address _address) external override onlyOwner {
    require(_address != address(0), "address cannot be 0");
    emit AddressUpdated('feeReceiver', feeReceiver, _address);
    feeReceiver = _address;
  }

  /// @dev update this will only affect pools deployed after
  function setRERC20Impl(address _newImpl) external override onlyOwner {
    require(_newImpl != address(0), "_newImpl cannot be 0");
    emit RERC20ImplUpdated(rERC20Impl, _newImpl);
    rERC20Impl = _newImpl;
  }

  function setPaused(bool _paused) external override {
    require(msg.sender == owner() || msg.sender == responder, "not owner/responder");
    emit PausedStatusUpdated(paused, _paused);
    paused = _paused;
  }

  function setResponder(address _address) external override onlyOwner {
    require(_address != address(0), "address cannot be 0");
    emit AddressUpdated('responder', responder, _address);
    responder = _address;
  }

  /// @notice flashloan rate can be anything
  function setDepositPauseWindow(uint256 _newWindow) external override onlyOwner {
    emit DepositPauseWindow(depositPauseWindow, _newWindow);
    depositPauseWindow = _newWindow;
  }

  /// @notice deposit fee rate can be anything < 10%
  function setDepositFeeRate(uint256 _newFeeRate) external override onlyOwner {
    require(_newFeeRate < 0.1 ether, "fee rate must be < 10%");
    emit DepositFeeRateUpdated(depositFeeRate, _newFeeRate);
    depositFeeRate = _newFeeRate;
  }

  /// @notice deposit fee rate can be anything < 10%
  function setCollectFeeRate(uint256 _newFeeRate) external override onlyOwner {
    require(_newFeeRate < 0.1 ether, "fee rate must be < 10%");
    emit CollectFeeRateUpdated(collectFeeRate, _newFeeRate);
    collectFeeRate = _newFeeRate;
  }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

/**
 * @title IRulerConfig contract interface. See {RulerConfig}.
 * @author crypto-pumpkin
 */
interface IRulerConfig {
  event AddressUpdated(string _type, address old, address _new);
  event PausedStatusUpdated(bool old, bool _new);
  event RERC20ImplUpdated(address rERC20Impl, address newImpl);
  event FlashLoanRateUpdated(uint256 old, uint256 _new);
  event DepositPauseWindow(uint256 old, uint256 _new);
  event DepositFeeRateUpdated(uint256 old, uint256 _new);
  event CollectFeeRateUpdated(uint256 old, uint256 _new);

  // state vars
  function flashLoanRate() external view returns (uint256);
  function paused() external view returns (bool);
  function responder() external view returns (address);
  function feeReceiver() external view returns (address);
  function rERC20Impl() external view returns (address);
  function depositPauseWindow() external view returns (uint256);
  function depositFeeRate() external view returns (uint256);
  function collectFeeRate() external view returns (uint256);

  // access restriction - owner (dev) & responder
  function setPaused(bool _paused) external;

  // access restriction - owner (dev)
  function setFeeReceiver(address _addr) external;
  function setResponder(address _addr) external;
  function setRERC20Impl(address _addr) external;
  function setFlashLoanRate(uint256 _newRate) external;
  function setDepositPauseWindow(uint256 _newWindow) external;
  function setDepositFeeRate(uint256 _newFeeRate) external;
  function setCollectFeeRate(uint256 _newFeeRate) external;
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 * @author crypto-pumpkin
 *
 * By initialization, the owner account will be the one that called initializeOwner. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Ruler: Initializes the contract setting the deployer as the initial owner.
     */
    function initializeOwner() internal initializer {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 2000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}