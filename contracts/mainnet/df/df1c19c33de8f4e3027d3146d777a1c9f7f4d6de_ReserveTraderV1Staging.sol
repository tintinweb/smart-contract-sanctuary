pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


interface ReserveTraderV1Interface {
    // events
    event AddedAccount(address account);
    event RemovedAccount(address account);
    event CallTradeReserve(bytes data, bool ok, bytes returnData);
    event Call(address target, uint256 amount, bytes data, bool ok, bytes returnData);

    
    // callable by accounts
    function callTradeReserve(
        bytes calldata data
    ) external returns (bool ok, bytes memory returnData);

    // only callable by owner
    function addAccount(address account) external;
    function removeAccount(address account) external;
    function callAny(
        address payable target, uint256 amount, bytes calldata data
    ) external returns (bool ok, bytes memory returnData);

    // view functions
    function getAccounts() external view returns (address[] memory);
    function getTradeReserve() external view returns (address tradeReserve);
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


contract ReserveTraderV1Staging is ReserveTraderV1Interface, TwoStepOwnable {
    // Track all authorized accounts.
    address[] private _accounts;

    // Indexes start at 1, as 0 signifies non-inclusion
    mapping (address => uint256) private _accountIndexes;
    
    address private immutable _TRADE_RESERVE;

    constructor(address tradeReserve, address[] memory initialAccounts) public {
        _TRADE_RESERVE = tradeReserve;
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

    function callTradeReserve(
        bytes calldata data
    ) external override returns (bool ok, bytes memory returnData) {
        require(
            _accountIndexes[msg.sender] != 0,
            "Only authorized accounts may trigger calls."
        );
        
        // Call the Trade Serve and supply the specified amount and data.
        (ok, returnData) = _TRADE_RESERVE.call(data);
        
        if (!ok) {
            assembly {
                revert(add(returnData, 32), returndatasize())
            }
        }

        emit CallTradeReserve(data, ok, returnData);
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

    function getTradeReserve() external view override returns (address tradeReserve) {
        return _TRADE_RESERVE;
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