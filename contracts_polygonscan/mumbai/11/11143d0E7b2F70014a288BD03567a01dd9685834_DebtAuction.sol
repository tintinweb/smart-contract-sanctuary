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


// File contracts/DebtAuction.sol
pragma solidity ^0.8.2;

interface LedgerLike {
  function transferDebt(
    address,
    address,
    uint256
  ) external;

  function createUnbackedDebt(
    address,
    address,
    uint256
  ) external;
}

interface TokenLike {
  function mint(address, uint256) external;
}

interface AccountingEngineLike {
  function totalDebtOnAuction() external returns (uint256);

  function settleUnbackedDebtFromAuction(uint256) external;
}

contract DebtAuction is Initializable {
  uint256 constant ONE = 1.00E18;

  // --- Data ---
  struct Auction {
    uint256 index; // Index in active array
    uint256 debtLotSize; // unbacked stablecoin to recover from the auction       [rad]
    uint256 governanceTokenBid; // governanceTokens in return for debtLotSize  [wad]
    address highestBidder; // high bidder
    uint48 bidExpiry; // bid expiry time         [unix epoch time]
    uint48 auctionExpiry; // auction expiry time     [unix epoch time]
  }

  mapping(address => uint256) public authorizedAccounts;
  mapping(uint256 => Auction) public auctions;

  LedgerLike public ledger; // CDP Engine
  TokenLike public governanceToken;

  uint256 public minBidIncrement; // minimum bid increase [wad]
  uint256 public restartMultiplier; // governanceTokenBid increase for restartAuction [wad]
  uint48 public maxBidDuration; // bid lifetime         [seconds]
  uint48 public maxAuctionDuration; // total auction length  [seconds]
  uint256 public auctionCount;
  uint256 public live; // Active Flag
  uint256[] public activeAuctions; // Array of active auction ids
  address public accountingEngine; // not used until shutdown

  // --- Events ---
  event GrantAuthorization(address indexed account);
  event RevokeAuthorization(address indexed account);
  event UpdateParameter(bytes32 indexed parameter, uint256 data);
  event StartAuction(
    uint256 indexed auctionId,
    address indexed initialBidder,
    uint256 auctionExpiry,
    uint256 debtLotSize,
    uint256 initialGovernanceTokenBid
  );
  event RestartAuction(
    uint256 indexed auctionId,
    uint256 auctionExpiry,
    uint256 updatedGovernanceTokenBid
  );
  event PlaceBid(
    uint256 indexed auctionId,
    address indexed bidder,
    uint256 governanceTokenBid,
    uint256 debtLotSize,
    uint256 auctionExpiry
  );
  event SettleAuction(
    uint256 indexed auctionId,
    address indexed winningBidder,
    uint256 governanceTokenMinted
  );
  event EmergencyCloseAuction(
    uint256 indexed auctionId,
    address indexed refundAddress,
    uint256 debtRefunded
  );

  // --- Init ---
  function initialize(address ledger_, address governanceToken_)
    public
    initializer
  {
    authorizedAccounts[msg.sender] = 1;
    ledger = LedgerLike(ledger_);
    governanceToken = TokenLike(governanceToken_);
    live = 1;
    emit GrantAuthorization(msg.sender);

    minBidIncrement = 1.05E18; // 5% minimum bid increase
    restartMultiplier = 1.50E18; // 50% governanceTokenBid increase for restartAuction
    maxBidDuration = 3 hours; // 3 hours bid lifetime         [seconds]
    maxAuctionDuration = 2 days; // 2 days total auction length  [seconds]
  }

  // --- Auth ---
  function grantAuthorization(address user) external isAuthorized {
    authorizedAccounts[user] = 1;
    emit GrantAuthorization(user);
  }

  function revokeAuthorization(address user) external isAuthorized {
    authorizedAccounts[user] = 0;
    emit RevokeAuthorization(user);
  }

  modifier isAuthorized() {
    require(
      authorizedAccounts[msg.sender] == 1,
      "SurplusAuction/not-authorized"
    );
    _;
  }

  // --- Math ---
  function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    if (x > y) {
      z = y;
    } else {
      z = x;
    }
  }

  // --- Admin ---
  function updateMinBidIncrement(uint256 data) external isAuthorized {
    require(data > ONE, "DebtAuction/min-bid-increment-lte-ONE");
    minBidIncrement = data;
    emit UpdateParameter("minBidIncrement", data);
  }

  function updateRestartMultiplier(uint256 data) external isAuthorized {
    require(data > ONE, "DebtAuction/restart-multiplier-lte-ONE");
    restartMultiplier = data;
    emit UpdateParameter("restartMultiplier", data);
  }

  function updateMaxBidDuration(uint48 data) external isAuthorized {
    maxBidDuration = data;
    emit UpdateParameter("maxBidDuration", data);
  }

  function updateMaxAuctionDuration(uint256 data) external isAuthorized {
    maxAuctionDuration = uint48(data);
    emit UpdateParameter("maxAuctionDuration", data);
  }

  // --- Auction ---
  function removeAuction(uint256 auctionId) internal {
    uint256 lastAuctionIdInList = activeAuctions[activeAuctions.length - 1];
    if (auctionId != lastAuctionIdInList) {
      // Swap auction to remove to last on the list
      uint256 _index = auctions[auctionId].index;
      activeAuctions[_index] = lastAuctionIdInList;
      auctions[lastAuctionIdInList].index = _index;
    }
    activeAuctions.pop();
    delete auctions[auctionId];
  }

  function startAuction(
    address stablecoinReceiver,
    uint256 initialGovernanceTokenBid,
    uint256 debtLotSize
  ) external isAuthorized returns (uint256 auctionId) {
    require(live == 1, "DebtAuction/not-live");
    auctionId = ++auctionCount;

    activeAuctions.push(auctionId);

    auctions[auctionId].index = activeAuctions.length - 1;
    auctions[auctionId].debtLotSize = debtLotSize;
    auctions[auctionId].governanceTokenBid = initialGovernanceTokenBid;
    auctions[auctionId].highestBidder = stablecoinReceiver;
    auctions[auctionId].auctionExpiry =
      uint48(block.timestamp) +
      maxAuctionDuration;

    emit StartAuction(
      auctionId,
      stablecoinReceiver,
      auctions[auctionId].auctionExpiry,
      debtLotSize,
      initialGovernanceTokenBid
    );
  }

  function restartAuction(uint256 auctionId) external {
    require(
      auctions[auctionId].auctionExpiry < block.timestamp,
      "DebtAuction/not-finished"
    );
    require(
      auctions[auctionId].bidExpiry == 0,
      "DebtAuction/bid-already-placed"
    );
    auctions[auctionId].governanceTokenBid =
      (restartMultiplier * auctions[auctionId].governanceTokenBid) /
      ONE;
    auctions[auctionId].auctionExpiry =
      uint48(block.timestamp) +
      maxAuctionDuration;
    emit RestartAuction(
      auctionId,
      auctions[auctionId].auctionExpiry,
      auctions[auctionId].governanceTokenBid
    );
  }

  function placeBid(
    uint256 auctionId,
    uint256 governanceTokenBid,
    uint256 debtLotSize
  ) external {
    require(live == 1, "DebtAuction/not-live");
    require(
      auctions[auctionId].highestBidder != address(0),
      "DebtAuction/highestBidder-not-set"
    );
    require(
      auctions[auctionId].bidExpiry > block.timestamp ||
        auctions[auctionId].bidExpiry == 0,
      "DebtAuction/already-finished-bidExpiry"
    );
    require(
      auctions[auctionId].auctionExpiry > block.timestamp,
      "DebtAuction/already-finished-end"
    );

    require(
      debtLotSize == auctions[auctionId].debtLotSize,
      "DebtAuction/not-matching-bid"
    );
    require(
      governanceTokenBid < auctions[auctionId].governanceTokenBid,
      "DebtAuction/governanceTokenBid-not-lower"
    );
    require(
      minBidIncrement * governanceTokenBid <=
        auctions[auctionId].governanceTokenBid * ONE,
      "DebtAuction/insufficient-decrease"
    );

    if (msg.sender != auctions[auctionId].highestBidder) {
      ledger.transferDebt(
        msg.sender,
        auctions[auctionId].highestBidder,
        debtLotSize
      );

      // on first placeBid, clear as much totalDebtOnAuction as possible
      if (auctions[auctionId].bidExpiry == 0) {
        uint256 totalDebtOnAuction = AccountingEngineLike(
          auctions[auctionId].highestBidder
        ).totalDebtOnAuction();
        AccountingEngineLike(auctions[auctionId].highestBidder)
          .settleUnbackedDebtFromAuction(min(debtLotSize, totalDebtOnAuction));
      }

      auctions[auctionId].highestBidder = msg.sender;
    }

    auctions[auctionId].governanceTokenBid = governanceTokenBid;
    auctions[auctionId].bidExpiry = uint48(block.timestamp) + maxBidDuration;
    emit PlaceBid(
      auctionId,
      msg.sender,
      governanceTokenBid,
      debtLotSize,
      auctions[auctionId].bidExpiry
    );
  }

  function settleAuction(uint256 auctionId) external {
    require(live == 1, "DebtAuction/not-live");
    require(
      auctions[auctionId].bidExpiry != 0 &&
        (auctions[auctionId].bidExpiry < block.timestamp ||
          auctions[auctionId].auctionExpiry < block.timestamp),
      "DebtAuction/not-finished"
    );
    governanceToken.mint(
      auctions[auctionId].highestBidder,
      auctions[auctionId].governanceTokenBid
    );
    removeAuction(auctionId);
    emit SettleAuction(
      auctionId,
      auctions[auctionId].highestBidder,
      auctions[auctionId].governanceTokenBid
    );
  }

  // The number of active auctions
  function countActiveAuctions() external view returns (uint256) {
    return activeAuctions.length;
  }

  // Return the entire array of active auctions
  function listActiveAuctions() external view returns (uint256[] memory) {
    return activeAuctions;
  }

  // --- Shutdown ---
  function shutdown() external isAuthorized {
    live = 0;
    accountingEngine = msg.sender;
  }

  function emergencyCloseAuction(uint256 auctionId) external {
    require(live == 0, "DebtAuction/still-live");
    require(
      auctions[auctionId].highestBidder != address(0),
      "DebtAuction/highestBidder-not-set"
    );
    ledger.createUnbackedDebt(
      accountingEngine,
      auctions[auctionId].highestBidder,
      auctions[auctionId].debtLotSize
    );
    removeAuction(auctionId);
    emit EmergencyCloseAuction(
      auctionId,
      auctions[auctionId].highestBidder,
      auctions[auctionId].debtLotSize
    );
  }
}