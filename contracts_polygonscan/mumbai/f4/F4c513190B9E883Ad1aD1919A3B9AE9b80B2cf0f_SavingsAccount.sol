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


// File contracts/SavingsAccount.sol
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

contract SavingsAccount is Initializable {
  uint256 constant ONE = 10**27;

  mapping(address => uint256) public authorizedAccounts;
  mapping(address => uint256) public savings; // Normalised Savings [wad]

  uint256 public totalSavings; // Total Normalised Savings  [wad]
  uint256 public savingsRate; // The Savings Rate          [ray]
  uint256 public accumulatedRates; // The Rate Accumulator          [ray]

  LedgerLike public ledger; // CDP Engine
  address public accountingEngine; // Debt Engine
  uint256 public lastUpdated; // Time of last drip     [unix epoch time]

  uint256 public live; // Active Flag

  // --- Events ---
  event GrantAuthorization(address indexed account);
  event RevokeAuthorization(address indexed account);
  event UpdateParameter(bytes32 indexed parameter, uint256 data);
  event UpdateParameter(bytes32 indexed parameter, address data);
  event UpdateAccumulatedRate(
    uint256 timestamp,
    uint256 accumulatedRateDelta,
    uint256 nextAccumulatedRate
  );
  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);

  // --- Init ---
  function initialize(address ledger_) public initializer {
    authorizedAccounts[msg.sender] = 1;
    ledger = LedgerLike(ledger_);
    savingsRate = ONE;
    accumulatedRates = ONE;
    lastUpdated = block.timestamp;
    live = 1;
    emit GrantAuthorization(msg.sender);
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
      "SavingsAccount/not-authorized"
    );
    _;
  }

  modifier isLive() {
    require(live == 1, "SavingsAccount/not-live");
    _;
  }

  // --- Math ---
  function rpow(
    uint256 x,
    uint256 n,
    uint256 base
  ) internal pure returns (uint256 z) {
    assembly {
      switch x
      case 0 {
        switch n
        case 0 {
          z := base
        }
        default {
          z := 0
        }
      }
      default {
        switch mod(n, 2)
        case 0 {
          z := base
        }
        default {
          z := x
        }
        let half := div(base, 2) // for rounding.
        for {
          n := div(n, 2)
        } n {
          n := div(n, 2)
        } {
          let xx := mul(x, x)
          if iszero(eq(div(xx, x), x)) {
            revert(0, 0)
          }
          let xxRound := add(xx, half)
          if lt(xxRound, xx) {
            revert(0, 0)
          }
          x := div(xxRound, base)
          if mod(n, 2) {
            let zx := mul(z, x)
            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
              revert(0, 0)
            }
            let zxRound := add(zx, half)
            if lt(zxRound, zx) {
              revert(0, 0)
            }
            z := div(zxRound, base)
          }
        }
      }
    }
  }

  function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = (x * y) / ONE;
  }

  // --- Administration ---

  function updateSavingsRate(uint256 data) external isAuthorized isLive {
    require(data >= ONE, "SavingsAccount/savingsRate-lt-one");
    updateAccumulatedRate();
    savingsRate = data;
    emit UpdateParameter("savingsRate", data);
  }

  function updateAccountingEngine(address addr) external isAuthorized {
    accountingEngine = addr;
    emit UpdateParameter("accountingEngine", addr);
  }

  function shutdown() external isAuthorized {
    live = 0;
    savingsRate = ONE;
  }

  // --- Savings Rate Accumulation ---
  function updateAccumulatedRate()
    public
    returns (uint256 nextAccumulatedRate)
  {
    require(
      block.timestamp >= lastUpdated,
      "SavingsAccount/invalid-block.timestamp"
    );
    nextAccumulatedRate = rmul(
      rpow(savingsRate, block.timestamp - lastUpdated, ONE),
      accumulatedRates
    );
    uint256 accumulatedRateDelta = nextAccumulatedRate - accumulatedRates;
    accumulatedRates = nextAccumulatedRate;
    lastUpdated = block.timestamp;
    ledger.createUnbackedDebt(
      address(accountingEngine),
      address(this),
      totalSavings * accumulatedRateDelta
    );
    emit UpdateAccumulatedRate(
      block.timestamp,
      accumulatedRateDelta,
      nextAccumulatedRate
    );
  }

  // --- Savings Management ---
  function deposit(uint256 wad) external {
    updateAccumulatedRate();
    savings[msg.sender] = savings[msg.sender] + wad;
    totalSavings = totalSavings + wad;
    ledger.transferDebt(msg.sender, address(this), accumulatedRates * wad);
    emit Deposit(msg.sender, wad);
  }

  function withdraw(uint256 wad) external {
    savings[msg.sender] = savings[msg.sender] - wad;
    totalSavings = totalSavings - wad;
    ledger.transferDebt(address(this), msg.sender, accumulatedRates * wad);
    emit Withdraw(msg.sender, wad);
  }
}