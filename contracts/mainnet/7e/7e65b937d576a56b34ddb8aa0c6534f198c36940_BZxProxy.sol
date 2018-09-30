/**
 * Copyright 2017–2018, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */
 
pragma solidity 0.4.24;


/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="fb899e969894bbc9">[email&#160;protected]</a>π.com>, Eenae <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="33525f564b564a735e5a4b514a4756401d5a5c">[email&#160;protected]</a>>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /// @dev Constant for unlocked guard state - non-zero to prevent extra gas costs.
  /// See: https://github.com/OpenZeppelin/openzeppelin-solidity/issues/1056
  uint private constant REENTRANCY_GUARD_FREE = 1;

  /// @dev Constant for locked guard state
  uint private constant REENTRANCY_GUARD_LOCKED = 2;

  /**
   * @dev We use a single lock for the whole contract.
   */
  uint private reentrancyLock = REENTRANCY_GUARD_FREE;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one `nonReentrant` function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and an `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(reentrancyLock == REENTRANCY_GUARD_FREE);
    reentrancyLock = REENTRANCY_GUARD_LOCKED;
    _;
    reentrancyLock = REENTRANCY_GUARD_FREE;
  }

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

contract GasTracker {
    uint internal gasUsed;

    modifier tracksGas() {
        // tx call 21k gas
        gasUsed = gasleft() + 21000;

        _; // modified function body inserted here

        gasUsed = 0; // zero out the storage so we don&#39;t persist anything
    }
}

contract BZxEvents {

    event LogLoanAdded (
        bytes32 indexed loanOrderHash,
        address adder,
        address indexed maker,
        address indexed feeRecipientAddress,
        uint lenderRelayFee,
        uint traderRelayFee,
        uint maxDuration,
        uint makerRole
    );

    event LogLoanTaken (
        address indexed lender,
        address indexed trader,
        address collateralTokenAddressFilled,
        address positionTokenAddressFilled,
        uint loanTokenAmountFilled,
        uint collateralTokenAmountFilled,
        uint positionTokenAmountFilled,
        uint loanStartUnixTimestampSec,
        bool active,
        bytes32 indexed loanOrderHash
    );

    event LogLoanCancelled(
        address indexed maker,
        uint cancelLoanTokenAmount,
        uint remainingLoanTokenAmount,
        bytes32 indexed loanOrderHash
    );

    event LogLoanClosed(
        address indexed lender,
        address indexed trader,
        address loanCloser,
        bool isLiquidation,
        bytes32 indexed loanOrderHash
    );

    event LogPositionTraded(
        bytes32 indexed loanOrderHash,
        address indexed trader,
        address sourceTokenAddress,
        address destTokenAddress,
        uint sourceTokenAmount,
        uint destTokenAmount
    );

    event LogMarginLevels(
        bytes32 indexed loanOrderHash,
        address indexed trader,
        uint initialMarginAmount,
        uint maintenanceMarginAmount,
        uint currentMarginAmount
    );

    event LogWithdrawProfit(
        bytes32 indexed loanOrderHash,
        address indexed trader,
        uint profitWithdrawn,
        uint remainingPosition
    );

    event LogPayInterestForOrder(
        bytes32 indexed loanOrderHash,
        address indexed lender,
        uint amountPaid,
        uint totalAccrued,
        uint loanCount
    );

    event LogPayInterestForPosition(
        bytes32 indexed loanOrderHash,
        address indexed lender,
        address indexed trader,
        uint amountPaid,
        uint totalAccrued
    );

    event LogChangeTraderOwnership(
        bytes32 indexed loanOrderHash,
        address indexed oldOwner,
        address indexed newOwner
    );

    event LogChangeLenderOwnership(
        bytes32 indexed loanOrderHash,
        address indexed oldOwner,
        address indexed newOwner
    );

    event LogIncreasedLoanableAmount(
        bytes32 indexed loanOrderHash,
        address indexed lender,
        uint loanTokenAmountAdded,
        uint loanTokenAmountFillable
    );
}

contract BZxObjects {

    struct ListIndex {
        uint index;
        bool isSet;
    }

    struct LoanOrder {
        address loanTokenAddress;
        address interestTokenAddress;
        address collateralTokenAddress;
        address oracleAddress;
        uint loanTokenAmount;
        uint interestAmount;
        uint initialMarginAmount;
        uint maintenanceMarginAmount;
        uint maxDurationUnixTimestampSec;
        bytes32 loanOrderHash;
    }

    struct LoanOrderAux {
        address maker;
        address feeRecipientAddress;
        uint lenderRelayFee;
        uint traderRelayFee;
        uint makerRole;
        uint expirationUnixTimestampSec;
    }

    struct LoanPosition {
        address trader;
        address collateralTokenAddressFilled;
        address positionTokenAddressFilled;
        uint loanTokenAmountFilled;
        uint loanTokenAmountUsed;
        uint collateralTokenAmountFilled;
        uint positionTokenAmountFilled;
        uint loanStartUnixTimestampSec;
        uint loanEndUnixTimestampSec;
        bool active;
    }

    struct PositionRef {
        bytes32 loanOrderHash;
        uint positionId;
    }

    struct InterestData {
        address lender;
        address interestTokenAddress;
        uint interestTotalAccrued;
        uint interestPaidSoFar;
    }

}

contract BZxStorage is BZxObjects, BZxEvents, ReentrancyGuard, Ownable, GasTracker {
    uint internal constant MAX_UINT = 2**256 - 1;

    address public bZRxTokenContract;
    address public vaultContract;
    address public oracleRegistryContract;
    address public bZxTo0xContract;
    address public bZxTo0xV2Contract;
    bool public DEBUG_MODE = false;

    // Loan Orders
    mapping (bytes32 => LoanOrder) public orders; // mapping of loanOrderHash to on chain loanOrders
    mapping (bytes32 => LoanOrderAux) public orderAux; // mapping of loanOrderHash to on chain loanOrder auxiliary parameters
    mapping (bytes32 => uint) public orderFilledAmounts; // mapping of loanOrderHash to loanTokenAmount filled
    mapping (bytes32 => uint) public orderCancelledAmounts; // mapping of loanOrderHash to loanTokenAmount cancelled
    mapping (bytes32 => address) public orderLender; // mapping of loanOrderHash to lender (only one lender per order)

    // Loan Positions
    mapping (uint => LoanPosition) public loanPositions; // mapping of position ids to loanPositions
    mapping (bytes32 => mapping (address => uint)) public loanPositionsIds; // mapping of loanOrderHash to mapping of trader address to position id

    // Lists
    mapping (address => bytes32[]) public orderList; // mapping of lenders and trader addresses to array of loanOrderHashes
    mapping (bytes32 => mapping (address => ListIndex)) public orderListIndex; // mapping of loanOrderHash to mapping of lenders and trader addresses to ListIndex objects

    mapping (bytes32 => uint[]) public orderPositionList; // mapping of loanOrderHash to array of order position ids

    PositionRef[] public positionList; // array of loans that need to be checked for liquidation or expiration
    mapping (uint => ListIndex) public positionListIndex; // mapping of position ids to ListIndex objects

    // Other Storage
    mapping (bytes32 => mapping (uint => uint)) public interestPaid; // mapping of loanOrderHash to mapping of position ids to amount of interest paid so far to a lender
    mapping (address => address) public oracleAddresses; // mapping of oracles to their current logic contract
    mapping (bytes32 => mapping (address => bool)) public preSigned; // mapping of hash => signer => signed
    mapping (address => mapping (address => bool)) public allowedValidators; // mapping of signer => validator => approved
}

contract BZxProxiable {
    mapping (bytes4 => address) public targets;

    mapping (bytes4 => bool) public targetIsPaused;

    function initialize(address _target) public;
}

contract BZxProxy is BZxStorage, BZxProxiable {
    
    constructor(
        address _settings) 
        public
    {
        require(_settings.delegatecall(bytes4(keccak256("initialize(address)")), _settings), "BZxProxy::constructor: failed");
    }
    
    function() 
        public
        payable 
    {
        require(!targetIsPaused[msg.sig], "BZxProxy::Function temporarily paused");

        address target = targets[msg.sig];
        require(target != address(0), "BZxProxy::Target not found");

        bytes memory data = msg.data;
        assembly {
            let result := delegatecall(gas, target, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function initialize(
        address)
        public
    {
        revert();
    }
}