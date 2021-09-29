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


// File contracts/DiscountCalculator.sol
pragma solidity ^0.8.2;

interface DiscountCalculator {
  // 1st arg: initial price               [ray]
  // 2nd arg: seconds since auction start [seconds]
  // returns: current auction price       [ray]
  function discountPrice(uint256, uint256) external view returns (uint256);
}

contract StairstepExponentialDecrease is DiscountCalculator, Initializable {
  uint256 constant RAY = 10**27;

  // --- Data ---
  mapping(address => uint256) public authorizedAccounts;
  uint256 public step; // Length of time between price drops [seconds]
  uint256 public factorPerStep; // Per-step multiplicative factor     [ray]

  // --- Events ---
  event GrantAuthorization(address indexed account);
  event RevokeAuthorization(address indexed account);
  event UpdateParameter(bytes32 indexed parameter, uint256 data);

  // --- Init ---
  // @notice: `factorPerStep` and `step` values must be correctly set for
  //     this contract to return a valid price
  function initialize() public initializer {
    authorizedAccounts[msg.sender] = 1;
    emit GrantAuthorization(msg.sender);
  }

  // --- Auth ---
  function grantAuthorization(address user) external isAuthorized {
    emit GrantAuthorization(user);
    authorizedAccounts[user] = 1;
  }

  function revokeAuthorization(address user) external isAuthorized {
    authorizedAccounts[user] = 0;
    emit RevokeAuthorization(user);
  }

  modifier isAuthorized() {
    require(
      authorizedAccounts[msg.sender] == 1,
      "StairstepExponentialDecrease/not-authorized"
    );
    _;
  }

  // --- Administration ---
  function updateFactorPerStep(uint256 data) external isAuthorized {
    require(data <= RAY, "StairstepExponentialDecrease/factorPerStep-gt-RAY");
    factorPerStep = data;
    emit UpdateParameter("factorPerStep", data);
  }

  function updateStep(uint256 data) external isAuthorized {
    step = data;
    emit UpdateParameter("step", data);
  }

  // --- Math ---
  function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x * y;
    require(y == 0 || z / y == x);
    z = z / RAY;
  }

  // optimized version from dss PR #78
  function rpow(
    uint256 x,
    uint256 n,
    uint256 b
  ) internal pure returns (uint256 z) {
    assembly {
      switch n
      case 0 {
        z := b
      }
      default {
        switch x
        case 0 {
          z := 0
        }
        default {
          switch mod(n, 2)
          case 0 {
            z := b
          }
          default {
            z := x
          }
          let half := div(b, 2) // for rounding.
          for {
            n := div(n, 2)
          } n {
            n := div(n, 2)
          } {
            let xx := mul(x, x)
            if shr(128, x) {
              revert(0, 0)
            }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) {
              revert(0, 0)
            }
            x := div(xxRound, b)
            if mod(n, 2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                revert(0, 0)
              }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) {
                revert(0, 0)
              }
              z := div(zxRound, b)
            }
          }
        }
      }
    }
  }

  // initialPrice: initial price
  // timeElapsed: seconds since the auction has started
  // step: seconds between a price drop
  // factorPerStep: factorPerStep encodes the percentage to decrease per step.
  //   For efficiency, the values is set as (1 - (% value / 100)) * RAY
  //   So, for a 1% decrease per step, factorPerStep would be (1 - 0.01) * RAY
  //
  // returns: initialPrice * (factorPerStep ^ timeElapsed)
  //
  //
  function discountPrice(uint256 initialPrice, uint256 timeElapsed)
    external
    view
    override
    returns (uint256)
  {
    return rmul(initialPrice, rpow(factorPerStep, timeElapsed / step, RAY));
  }
}