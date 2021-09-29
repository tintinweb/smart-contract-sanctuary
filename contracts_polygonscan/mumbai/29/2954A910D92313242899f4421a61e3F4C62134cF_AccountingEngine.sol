/**
 *Submitted for verification at polygonscan.com on 2021-09-28
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

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


// File contracts/AccountingEngine.sol
pragma solidity ^0.8.2;

interface DebtAuctionLike {
  function startAuction(
    address stablecoinReceiver,
    uint256 initialGovernanceTokenBid,
    uint256 debtLotSize
  ) external returns (uint256 auctionId);

  function shutdown() external;

  function live() external returns (uint256);
}

interface SurplusAuctionLike {
  function startAuction(uint256 debtToSell, uint256 bidAmount)
    external
    returns (uint256 auctionId);

  function shutdown(uint256) external;

  function live() external returns (uint256);
}

interface LedgerLike {
  function debt(address) external view returns (uint256);

  function unbackedDebt(address) external view returns (uint256);

  function settleUnbackedDebt(uint256) external;

  function allowModification(address) external;

  function denyModification(address) external;
}

contract AccountingEngine is Initializable {
  // --- Data ---
  struct QueuedDebt {
    uint256 index; // Index in active auctions
    uint256 debt; // Amount of debt
    uint256 timestamp; // Time the debt was added
  }

  mapping(address => uint256) public authorizedAccounts;
  LedgerLike public ledger; // CDP Engine
  SurplusAuctionLike public surplusAuction; // Surplus Auction
  DebtAuctionLike public debtAuction; // Debt Auction

  uint256 public debtCount;
  uint256[] public pendingDebts; // Array of debt waiting for delay
  mapping(uint256 => QueuedDebt) public debtQueue; // debt queue
  uint256 public totalQueuedDebt; // Debt waiting for delay            [rad]
  uint256 public totalDebtOnAuction; // On-auction debt        [rad]

  uint256 public popDebtDelay; // Debt auction delay             [seconds]
  uint256 public intialDebtAuctionBid; // Debt auction initial lot size  [wad]
  uint256 public debtAuctionLotSize; // Debt auction fixed bid size    [rad]

  uint256 public surplusAuctionLotSize; // Flap fixed lot size    [rad]
  uint256 public surplusBuffer; // Surplus buffer         [rad]

  uint256 public live; // Active Flag

  // --- Events ---
  event GrantAuthorization(address indexed account);
  event RevokeAuthorization(address indexed account);
  event UpdateParameter(bytes32 indexed parameter, uint256 data);
  event UpdateParameter(bytes32 indexed parameter, address data);
  event PushDebtToQueue(
    uint256 indexed queueId,
    uint256 debt,
    uint256 timestamp
  );
  event PopDebtFromQueue(
    uint256 indexed queueId,
    uint256 debt,
    uint256 timestamp
  );
  event SettleUnbackedDebt(uint256 amount);
  event SettleUnbackedDebtFromAuction(uint256 amount);
  event AuctionDebt(
    uint256 indexed auctionId,
    uint256 debtOnAuction,
    uint256 initialCollateralBid
  );
  event AuctionSurplus(uint256 indexed auctionId, uint256 surplusOnAuction);

  // --- Init ---
  function initialize(
    address ledger_,
    address surplusAuction_,
    address debtAuction_
  ) public initializer {
    authorizedAccounts[msg.sender] = 1;
    ledger = LedgerLike(ledger_);
    surplusAuction = SurplusAuctionLike(surplusAuction_);
    debtAuction = DebtAuctionLike(debtAuction_);
    live = 1;
    emit GrantAuthorization(msg.sender);
  }

  // --- Auth ---
  function grantAuthorization(address user) external isAuthorized {
    authorizedAccounts[user] = 1;
    emit GrantAuthorization(msg.sender);
  }

  function revokeAuthorization(address user) external isAuthorized {
    authorizedAccounts[user] = 0;
    emit RevokeAuthorization(msg.sender);
  }

  modifier isAuthorized() {
    require(authorizedAccounts[msg.sender] == 1, "Core/not-authorized");
    _;
  }

  // --- Math ---
  function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x <= y ? x : y;
  }

  // --- Administration ---
  function updateIntialDebtAuctionBid(uint256 data) external isAuthorized {
    intialDebtAuctionBid = data;
    emit UpdateParameter("intialDebtAuctionBid", data);
  }

  function updateDebtAuctionLotSize(uint256 data) external isAuthorized {
    debtAuctionLotSize = data;
    emit UpdateParameter("debtAuctionLotSize", data);
  }

  function updateSurplusBuffer(uint256 data) external isAuthorized {
    surplusBuffer = data;
    emit UpdateParameter("surplusBuffer", data);
  }

  function updatePopDebtDelay(uint256 data) external isAuthorized {
    popDebtDelay = data;
    emit UpdateParameter("popDebtDelay", data);
  }

  function updateSurplusAuctionLotSize(uint256 data) external isAuthorized {
    surplusAuctionLotSize = data;
    emit UpdateParameter("surplusAuctionLotSize", data);
  }

  function updateSurplusAuction(address data) external isAuthorized {
    surplusAuction = SurplusAuctionLike(data);
    emit UpdateParameter("surplusAuction", data);
  }

  function updateDebtAuction(address data) external isAuthorized {
    debtAuction = DebtAuctionLike(data);
    emit UpdateParameter("debtAuction", data);
  }

  function removeDebtFromQueue(uint256 queueId) internal {
    uint256 lastDebtInList = pendingDebts[pendingDebts.length - 1];
    if (queueId != lastDebtInList) {
      // Swap auction to remove to last on the list
      uint256 _index = debtQueue[queueId].index;
      pendingDebts[_index] = lastDebtInList;
      debtQueue[lastDebtInList].index = _index;
    }
    pendingDebts.pop();
    delete debtQueue[queueId];
  }

  // Push to debt-queue
  function pushDebtToQueue(uint256 tab)
    external
    isAuthorized
    returns (uint256 queueId)
  {
    queueId = ++debtCount;

    pendingDebts.push(queueId);

    debtQueue[queueId].index = pendingDebts.length - 1;
    debtQueue[queueId].debt = tab;
    debtQueue[queueId].timestamp = block.timestamp;

    totalQueuedDebt = totalQueuedDebt + tab;
    emit PushDebtToQueue(queueId, tab, block.timestamp);
  }

  // Pop from debt-queue
  function popDebtFromQueue(uint256 queueId) external {
    require(
      debtQueue[queueId].timestamp + popDebtDelay <= block.timestamp,
      "AccountingEngine/popDebtDelay-not-finished"
    );
    totalQueuedDebt = totalQueuedDebt - debtQueue[queueId].debt;
    removeDebtFromQueue(queueId);
    emit PopDebtFromQueue(queueId, debtQueue[queueId].debt, block.timestamp);
  }

  // Debt settlement
  function settleUnbackedDebt(uint256 rad) external {
    require(
      rad <= ledger.debt(address(this)),
      "AccountingEngine/insufficient-surplus"
    );
    require(
      rad <=
        ledger.unbackedDebt(address(this)) -
          totalQueuedDebt -
          totalDebtOnAuction,
      "AccountingEngine/insufficient-debt"
    );
    ledger.settleUnbackedDebt(rad);
    emit SettleUnbackedDebt(rad);
  }

  function settleUnbackedDebtFromAuction(uint256 rad) external {
    require(
      rad <= totalDebtOnAuction,
      "AccountingEngine/not-enough-totalDebtOnAuction"
    );
    require(
      rad <= ledger.debt(address(this)),
      "AccountingEngine/insufficient-surplus"
    );
    totalDebtOnAuction = totalDebtOnAuction - rad;
    ledger.settleUnbackedDebt(rad);
    emit SettleUnbackedDebtFromAuction(rad);
  }

  // Debt auction
  function auctionDebt() external returns (uint256 id) {
    require(
      debtAuctionLotSize <=
        ledger.unbackedDebt(address(this)) -
          totalQueuedDebt -
          totalDebtOnAuction,
      "AccountingEngine/insufficient-debt"
    );
    require(
      ledger.debt(address(this)) == 0,
      "AccountingEngine/surplus-not-zero"
    );
    totalDebtOnAuction = totalDebtOnAuction + debtAuctionLotSize;
    id = debtAuction.startAuction(
      address(this),
      intialDebtAuctionBid,
      debtAuctionLotSize
    );
    emit AuctionDebt(id, debtAuctionLotSize, intialDebtAuctionBid);
  }

  // Surplus auction
  function auctionSurplus() external returns (uint256 id) {
    require(
      ledger.debt(address(this)) >=
        ledger.unbackedDebt(address(this)) +
          surplusAuctionLotSize +
          surplusBuffer,
      "AccountingEngine/insufficient-surplus"
    );
    require(
      ledger.unbackedDebt(address(this)) -
        totalQueuedDebt -
        totalDebtOnAuction ==
        0,
      "AccountingEngine/debt-not-zero"
    );
    id = surplusAuction.startAuction(surplusAuctionLotSize, 0);
    emit AuctionSurplus(id, surplusAuctionLotSize);
  }

  // The number of debts in the queue
  function countPendingDebts() external view returns (uint256) {
    return pendingDebts.length;
  }

  // Return the entire array of active auctions
  function listPendingDebts() external view returns (uint256[] memory) {
    return pendingDebts;
  }

  function shutdown() external isAuthorized {
    require(live == 1, "AccountingEngine/not-live");
    live = 0;
    totalQueuedDebt = 0;
    totalDebtOnAuction = 0;
    surplusAuction.shutdown(ledger.debt(address(surplusAuction)));
    debtAuction.shutdown();
    ledger.settleUnbackedDebt(
      min(ledger.debt(address(this)), ledger.unbackedDebt(address(this)))
    );
  }
}