pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


interface DharmaTradeBotV1Interface {
  struct LimitOrderArguments {
    address account;
    address assetToSupply;        // Ether = address(0)
    address assetToReceive;       // Ether = address(0)
    uint256 maximumAmountToSupply;
    uint256 maximumPriceToAccept; // represented as a mantissa (n * 10^18)
    uint256 expiration;
    bytes32 salt;
  }

  struct LimitOrderExecutionArguments {
    uint256 amountToSupply; // will be lower than maximum for partial fills
    bytes signatures;
    address tradeTarget;
    bytes tradeData;
  }

  function processLimitOrder(
    LimitOrderArguments calldata args,
    LimitOrderExecutionArguments calldata executionArgs
  ) external returns (uint256 amountReceived);
}


interface TradeBotCommanderV1Interface {
    // events
    event AddedAccount(address account);
    event RemovedAccount(address account);
    event Call(address target, uint256 amount, bytes data, bool ok, bytes returnData);
    
    // callable by accounts
    function processLimitOrder(
        DharmaTradeBotV1Interface.LimitOrderArguments calldata args,
        DharmaTradeBotV1Interface.LimitOrderExecutionArguments calldata executionArgs
    ) external returns (bool ok, uint256 amountReceived);

    // only callable by owner
    function addAccount(address account) external;
    function removeAccount(address account) external;
    function callAny(
        address payable target, uint256 amount, bytes calldata data
    ) external returns (bool ok, bytes memory returnData);

    // view functions
    function getAccounts() external view returns (address[] memory);
    function getTradeBot() external view returns (address tradeBot);
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


contract TradeBotCommanderV1 is TradeBotCommanderV1Interface, TwoStepOwnable {
    // Track all authorized accounts.
    address[] private _accounts;

    // Indexes start at 1, as 0 signifies non-inclusion
    mapping (address => uint256) private _accountIndexes;
    
    DharmaTradeBotV1Interface private immutable _TRADE_BOT;

    constructor(address tradeBot, address[] memory initialAccounts) public {
        _TRADE_BOT = DharmaTradeBotV1Interface(tradeBot);
        for (uint256 i; i < initialAccounts.length; i++) {
            address account = initialAccounts[i];
            _addAccount(account);
        }
    }
    
    function processLimitOrder(
        DharmaTradeBotV1Interface.LimitOrderArguments calldata args,
        DharmaTradeBotV1Interface.LimitOrderExecutionArguments calldata executionArgs
    ) external override returns (bool ok, uint256 amountReceived) {
        require(
            _accountIndexes[msg.sender] != 0,
            "Only authorized accounts may trigger limit orders."
        );
        
        amountReceived = _TRADE_BOT.processLimitOrder(
            args, executionArgs
        );

        ok = true;
    }

    function addAccount(address account) external override onlyOwner {
        _addAccount(account);
    }

    function removeAccount(address account) external override onlyOwner {
        _removeAccount(account);
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

    function getTradeBot() external view override returns (address tradeBot) {
        return address(_TRADE_BOT);
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