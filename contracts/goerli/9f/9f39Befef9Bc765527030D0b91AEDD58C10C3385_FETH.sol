// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;



import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract FETH is Initializable {
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;
  using Math for uint256;

  string public constant name = "Foundation Locked Wrapped Ether";
  string public constant symbol = "FETH";
  uint8 public constant decimals = 18;

  uint256 public constant ESCROW_LENGTH = 24 hours;
  uint256 public constant ESCROW_INTERVAL = 1 hours;

  struct LockedEscrow {
    uint256 expiration;
    uint256 totalAmount;
  }

  address payable public foundationMarket;

  mapping(address => uint256) private freedBalance;
  mapping(address => mapping(address => uint256)) public allowance;

  mapping(address => mapping(uint256 => LockedEscrow)) private accountToIndexToEscrow;
  mapping(address => uint256) private accountToEscrowStartIndex;

  event Approval(address indexed from, address indexed spender, uint256 amount);
  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Withdrawal(address indexed from, address indexed to, uint256 amount);
  event AddToEscrow(address indexed account, uint256 indexed expiration, uint256 amount);
  event RemoveFromEscrow(address indexed account, uint256 indexed expiration, uint256 amount);

  modifier onlyFoundationMarket() {
    require(msg.sender == foundationMarket, "Only escrow manager can call this function");
    _;
  }

  function initialize(address payable _foundationMarket) public initializer {
    require(_foundationMarket.isContract(), "Escrow manager must be a contract");
    foundationMarket = _foundationMarket;
  }

  /**
   * @notice Adds funds to an account which are locked for a period of time.
   * @dev This is only called by the escrow manager contract.
   */
  function marketDepositFor(address account, uint256 amount)
    public
    payable
    onlyFoundationMarket
    returns (uint256 expiration)
  {
    require(account != address(0), "Cannot deposit for lockup with address 0");
    require(amount > 0, "Must deposit positive amount");

    // Lockup expires after 24 hours rounded up to the next hour for a total of [24-25) hours
    expiration = ESCROW_LENGTH + block.timestamp.ceilDiv(ESCROW_INTERVAL) * ESCROW_INTERVAL;


    // Update available escrow
    _freeFromEscrow(account);
    if (msg.value < amount) {
      unchecked {
        uint256 delta = amount - msg.value;

        require(freedBalance[account] >= delta, "Insufficient available funds");
        freedBalance[account] -= delta;
      }
    } else {
      require(msg.value == amount, "Must deposit exact amount");
    }

    // Add to locked escrow
    uint256 escrowIndex = accountToEscrowStartIndex[account];
    while (true) {
      LockedEscrow storage escrow = accountToIndexToEscrow[account][escrowIndex];
      if (escrow.expiration == 0) {

        escrow.expiration = expiration;
        escrow.totalAmount = amount;
        break;
      } else if (escrow.expiration == expiration) {

        unchecked {
          escrow.totalAmount += amount;
        }
        break;
      }

      unchecked {
        escrowIndex++;
      }
    }

    emit AddToEscrow(account, expiration, amount);
  }

  /**
   * @notice Removes a account's lockup and returns ETH to the caller.
   * @dev This is only called by the escrow manager contract.
   */
  function marketWithdrawFrom(
    address account,
    uint256 expiration,
    uint256 amount
  ) public onlyFoundationMarket {

    _removeFromLockedEscrow(account, expiration, amount);
    payable(msg.sender).sendValue(amount);
    emit Withdrawal(account, msg.sender, amount);
  }

  /**
   * @notice Remove an account's lockup, making the ETH available to withdraw.
   * @dev This is only called by the escrow manager contract.
   */
  function marketUnlockFor(
    address account,
    uint256 expiration,
    uint256 amount
  ) public onlyFoundationMarket {

    _removeFromLockedEscrow(account, expiration, amount);
    freedBalance[account] += amount;
  }

  /**
   * @notice Withdraw all ETH available to your account.
   */
  function withdrawAvailableBalance() public {
    _freeFromEscrow(msg.sender);
    uint256 amount = freedBalance[msg.sender];
    require(amount > 0, "Nothing to withdraw");
    freedBalance[msg.sender] -= amount;
    payable(msg.sender).sendValue(amount);
    emit Withdrawal(msg.sender, msg.sender, amount);
  }

  /**
   * @notice Approves the spender to transfer from your account.
   */
  function approve(address spender, uint256 amount) public returns (bool) {
    allowance[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  /**
   * @notice Transfers an amount from your account.
   */
  function transfer(address to, uint256 amount) public returns (bool) {
    return transferFrom(msg.sender, to, amount);
  }

  /**
   * @notice Transfers an amount from the account specified.
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public returns (bool) {
    _freeFromEscrow(from);

    if (from != msg.sender && allowance[from][msg.sender] != type(uint256).max) {
      require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
      allowance[from][msg.sender] -= amount;
    }

    freedBalance[from] -= amount;
    freedBalance[to] += amount;

    emit Transfer(from, to, amount);

    return true;
  }

  /**
   * @dev Removes the specified amount from locked escrow, potentially before its expiration.
   */
  function _removeFromLockedEscrow(
    address account,
    uint256 expiration,
    uint256 amount
  ) private {
    uint256 escrowIndex = accountToEscrowStartIndex[account];
    while (true) {
      LockedEscrow storage escrow = accountToIndexToEscrow[account][escrowIndex];

      if (escrow.expiration == expiration) {
        // If the first locked escrow is empty, remove it
        if (escrow.totalAmount == amount && escrowIndex == accountToEscrowStartIndex[account]) {

          delete accountToIndexToEscrow[account][escrowIndex];

          // Bump the escrow index unless it's the last one
          if (accountToIndexToEscrow[account][escrowIndex + 1].expiration != 0) {
            accountToEscrowStartIndex[account]++;
          }
        } else {

          // If it's not the first locked escrow, we may have an entry with 0 totalAmount but expiration will be set
          escrow.totalAmount -= amount;
        }
        break;
      }
      require(escrow.expiration != 0, "Escrow not found");
      escrowIndex++;
    }
    emit RemoveFromEscrow(account, expiration, amount);
  }

  /**
   * @dev Moves expired escrow to the available balance.
   */
  function _freeFromEscrow(address account) private {
    unchecked {
      uint256 escrowIndex = accountToEscrowStartIndex[account];
      while (true) {
        LockedEscrow storage escrow = accountToIndexToEscrow[account][escrowIndex];
        if (escrow.expiration == 0 || escrow.expiration >= block.timestamp) {

          break;
        }

        freedBalance[account] += escrow.totalAmount;
        delete accountToIndexToEscrow[account][escrowIndex];
        escrowIndex++;
      }
      accountToEscrowStartIndex[account] = escrowIndex;
    }
  }

  /**
   * @notice Returns the total amount of ETH locked in this contract.
   */
  function totalSupply() public view returns (uint256) {
    return address(this).balance;
  }

  /**
   * @notice Returns the balance of an account available to transfer or withdraw.
   */
  function balanceOf(address account) public view returns (uint256) {
    return freedBalance[account] + _countExpiredLockup(account);
  }

  // TODO do we flip and use total for `balanceOf`?

  /**
   * @notice Returns the total balance of an account, including locked up funds.
   */
  function totalBalanceOf(address account) public view returns (uint256) {
    return freedBalance[account] + _countTotalLockup(account);
  }

  /**
   * @notice Returns the balance and each outstanding lockup bucket for an account.
   */
  function getLockups(address account)
    public
    view
    returns (
      uint256 available,
      uint256 totalBalance,
      uint256[] memory expiry,
      uint256[] memory amount
    )
  {
    available = balanceOf(account);
    totalBalance = totalBalanceOf(account);
    uint256 lockedCount;
    uint256 escrowIndex = accountToEscrowStartIndex[account];
    while (true) {
      LockedEscrow memory escrow = accountToIndexToEscrow[account][escrowIndex];
      if (escrow.expiration == 0) {
        break;
      }
      if (escrow.expiration >= block.timestamp) {
        lockedCount++;
      }
      escrowIndex++;
    }
    expiry = new uint256[](lockedCount);
    amount = new uint256[](lockedCount);
    uint256 i;
    escrowIndex = accountToEscrowStartIndex[account];
    while (true) {
      LockedEscrow memory escrow = accountToIndexToEscrow[account][escrowIndex + i];
      if (escrow.expiration == 0) {
        break;
      }
      if (escrow.expiration >= block.timestamp) {
        expiry[i] = escrow.expiration;
        amount[i] = escrow.totalAmount;
      }
      i++;
    }
  }

  /**
   * @dev Returns the total amount of locked ETH for an account that has expired.
   */
  function _countExpiredLockup(address account) private view returns (uint256 amountExpired) {
    uint256 escrowIndex = accountToEscrowStartIndex[account];
    while (true) {
      LockedEscrow memory escrow = accountToIndexToEscrow[account][escrowIndex];
      if (escrow.expiration == 0 || escrow.expiration >= block.timestamp) {
        break;
      }
      amountExpired += escrow.totalAmount;
      escrowIndex++;
    }
  }

  /**
   * @dev Returns the total amount of locked ETH for an account that has or has not expired.
   */
  function _countTotalLockup(address account) private view returns (uint256 amount) {
    uint256 escrowIndex = accountToEscrowStartIndex[account];
    while (true) {
      LockedEscrow memory escrow = accountToIndexToEscrow[account][escrowIndex];
      if (escrow.expiration == 0) {
        break;
      }
      amount += escrow.totalAmount;
      escrowIndex++;
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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