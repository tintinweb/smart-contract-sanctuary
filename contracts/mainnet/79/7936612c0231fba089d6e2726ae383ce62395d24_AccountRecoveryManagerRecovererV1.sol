pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


interface AccountRecoveryManagerRecovererV1Interface {
    // events
    event AddedAccount(address account);
    event RemovedAccount(address account);
    event CallRecover(address wallet, address newUserSigningKey);
    event Call(address target, uint256 amount, bytes data, bool ok, bytes returnData);

    
    // callable by accounts
    function callRecover(
        address wallet, address newUserSigningKey
    ) external;

    // only callable by owner
    function addAccount(address account) external;
    function removeAccount(address account) external;
    function callAny(
        address payable target, uint256 amount, bytes calldata data
    ) external returns (bool ok, bytes memory returnData);

    // view functions
    function getAccounts() external view returns (address[] memory);
    function getAccountRecoveryManager() external view returns (address accountRecoveryManager);
}

interface DharmaAccountRecoveryManagerV2Interface {
  function recover(address wallet, address newUserSigningKey) external;
}

contract TwoStepOwnable {
  address private _owner;

  address private _newPotentialOwner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initialize contract by setting transaction submitter as initial owner.
   */
  constructor() internal {
    _owner = tx.origin;
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
    require(isOwner(), "TwoStepOwnable: caller is not the owner.");
    _;
  }

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows a new account (`newOwner`) to accept ownership.
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(
      newOwner != address(0),
      "TwoStepOwnable: new potential owner is the zero address."
    );

    _newPotentialOwner = newOwner;
  }

  /**
   * @dev Cancel a transfer of ownership to a new account.
   * Can only be called by the current owner.
   */
  function cancelOwnershipTransfer() public onlyOwner {
    delete _newPotentialOwner;
  }

  /**
   * @dev Transfers ownership of the contract to the caller.
   * Can only be called by a new potential owner set by the current owner.
   */
  function acceptOwnership() public {
    require(
      msg.sender == _newPotentialOwner,
      "TwoStepOwnable: current owner must set caller as new potential owner."
    );

    delete _newPotentialOwner;

    emit OwnershipTransferred(_owner, msg.sender);

    _owner = msg.sender;
  }
}


contract AccountRecoveryManagerRecovererV1 is AccountRecoveryManagerRecovererV1Interface, TwoStepOwnable {
    // Track all authorized accounts.
    address[] private _accounts;

    // Indexes start at 1, as 0 signifies non-inclusion
    mapping (address => uint256) private _accountIndexes;
    
    DharmaAccountRecoveryManagerV2Interface private immutable _ACCOUNT_RECOVERY_MANAGER;

    constructor(address accountRecoveryManager, address[] memory initialAccounts) public {
        _ACCOUNT_RECOVERY_MANAGER = DharmaAccountRecoveryManagerV2Interface(accountRecoveryManager);
        for (uint256 i; i < initialAccounts.length; i++) {
            address account = initialAccounts[i];
            _addAccount(account);
        }
    }

    function addAccount(address account) external override onlyOwner {
        _addAccount(account);
    }

    function removeAccount(address account) external override onlyOwner {
        _removeAccount(account);
    }

    function callRecover(
        address wallet, address newUserSigningKey
    ) external override {
        require(
            _accountIndexes[msg.sender] != 0,
            "Only authorized accounts may trigger calls."
        );
        
        // Call the recover function on the Account Recovery Manager
        _ACCOUNT_RECOVERY_MANAGER.recover(wallet, newUserSigningKey);
        
        emit CallRecover(wallet, newUserSigningKey);
    }

    function callAny(
        address payable target, uint256 amount, bytes calldata data
    ) external override onlyOwner returns (bool ok, bytes memory returnData) {
        // Call the specified target and supply the specified amount and data.
        (ok, returnData) = target.call{value: amount}(data);

        emit Call(target, amount, data, ok, returnData);
    }
    
    function getAccounts() external view override returns (address[] memory) {
        return _accounts;
    }

    function getAccountRecoveryManager() external view override returns (address accountRecoveryManager) {
        return address(_ACCOUNT_RECOVERY_MANAGER);
    }

    function _addAccount(address account) internal {
        require(
            _accountIndexes[account] == 0,
            "Account matching the provided account already exists."
        );
        _accounts.push(account);
        _accountIndexes[account] = _accounts.length;

        emit AddedAccount(account);
    }
    
    function _removeAccount(address account) internal {
        uint256 removedAccountIndex = _accountIndexes[account];
        require(
            removedAccountIndex != 0,
            "No account found matching the provided account."
        );

        // swap account to remove with the last one then pop from the array.
        address lastAccount = _accounts[_accounts.length - 1];
        _accounts[removedAccountIndex - 1] = lastAccount;
        _accountIndexes[lastAccount] = removedAccountIndex;
        _accounts.pop();
        delete _accountIndexes[account];

        emit RemovedAccount(account); 
    }
}