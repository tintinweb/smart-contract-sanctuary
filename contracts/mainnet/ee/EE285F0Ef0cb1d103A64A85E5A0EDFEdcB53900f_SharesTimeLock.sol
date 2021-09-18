// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./base/DelegationModule.sol";
import "./libraries/LowGasSafeMath.sol";
import "./interfaces/ISharesTimeLock.sol";


contract SharesTimeLock is ISharesTimeLock, DelegationModule, Ownable() {
  using LowGasSafeMath for uint256;
  using TransferHelper for address;

/** ========== Constants ==========  */

  /**
   * @dev Token used for dividend payments and given to users for deposits.
   * Must be an ERC20DividendsOwned with this contract set as the owner.
   */
  address public immutable override dividendsToken;

  /**
   * @dev Minimum number of seconds shares can be locked for.
   */
  uint32 public immutable override minLockDuration;

  /**
   * @dev Maximum number of seconds shares can be locked for.
   */
  uint32 public immutable override maxLockDuration;

  /**
   * @dev Minimum early withdrawal fee added to every dynamic withdrawal fee.
   */
  uint256 public immutable override minEarlyWithdrawalFee;

  /**
   * @dev Base early withdrawal fee expressed as a fraction of 1e18.
   * This is the fee paid if tokens are withdrawn immediately after being locked.
   * It is multiplied by the dividend multiplier, and added to the minimum early withdrawal fee.
   */
  uint256 public immutable override baseEarlyWithdrawalFee;

  /**
   * @dev Maximum dividends multiplier for a lock duration of `maxLockDuration`
   */
  uint256 public immutable override maxDividendsBonusMultiplier;

/** ========== Storage ==========  */

  /**
   * @dev Array of token locks.
   */
  Lock[] public override locks;

  /**
   * @dev Account which receives fees taken for early withdrawals.
   */
  address public override feeRecipient;

  /**
   * @dev Minimum amount of tokens that can be deposited.
   * If zero, there is no minimum.
   */
  uint96 public override minimumDeposit;

  /**
   * @dev Accumulated early withdrawal fees.
   */
  uint96 public override pendingFees;

  /**
   * @dev Allows all locked tokens to be withdrawn with no fees.
   */
  bool public override emergencyUnlockTriggered;

/** ========== Queries ==========  */

  /**
   * @dev Returns the number of locks that have been created.
   */
  function getLocksLength() external view override returns (uint256) {
    return locks.length;
  }

  /**
   * @dev Returns the dividends multiplier for `duration` expressed as a fraction of 1e18.
   */
  function getDividendsMultiplier(uint256 duration) public view override returns (uint256 multiplier) {
    require(duration >= minLockDuration && duration <= maxLockDuration, "OOB");
    uint256 durationRange = maxLockDuration - minLockDuration;
    uint256 overMinimum = duration - minLockDuration;
    return uint256(1e18).add(
      maxDividendsBonusMultiplier.mul(overMinimum) / durationRange
    );
  }

  /**
   * @dev Returns the withdrawal fee and withdrawable shares for a withdrawal of a
   * lock created at `lockedAt` with a duration of `lockDuration`, if it was withdrawan
   * now.
   *
   * The early withdrawal fee is 0 if the full duration has passed or the emergency unlock
   * has been triggered; otherwise, it is calculated as the fraction of the total duration
   * that has not elapsed multiplied by the maximum base withdrawal fee and the dividends
   * multiplier, plus the minimum withdrawal fee.
   */
  function getWithdrawalParameters(
    uint256 amount,
    uint256 lockedAt,
    uint256 lockDuration
  )
    public
    view
    override
    returns (uint256 dividendShares, uint256 earlyWithdrawalFee)
  {
    uint256 multiplier = getDividendsMultiplier(lockDuration);
    dividendShares = amount.mul(multiplier) / uint256(1e18);
    uint256 unlockAt = lockedAt + lockDuration;
    if (block.timestamp >= unlockAt || emergencyUnlockTriggered) {
      earlyWithdrawalFee = 0;
    } else {
      uint256 timeRemaining = unlockAt - block.timestamp;
      uint256 minimumFee = amount.mul(minEarlyWithdrawalFee) / uint256(1e18);
      uint256 dynamicFee = amount.mul(
        baseEarlyWithdrawalFee.mul(timeRemaining).mul(multiplier)
      ) / uint256(1e36 * lockDuration);
      earlyWithdrawalFee = minimumFee.add(dynamicFee);
    }
  }

/** ========== Constructor ==========  */

  constructor(
    address depositToken_,
    address dividendsToken_,
    uint32 minLockDuration_,
    uint32 maxLockDuration_,
    uint256 minEarlyWithdrawalFee_,
    uint256 baseEarlyWithdrawalFee_,
    uint256 maxDividendsBonusMultiplier_
  ) DelegationModule(depositToken_) {
    dividendsToken = dividendsToken_;
    require(minLockDuration_ < maxLockDuration_, "min>=max");
    require(
      minEarlyWithdrawalFee_.add(baseEarlyWithdrawalFee_.mul(maxDividendsBonusMultiplier_)) <= 1e36,
      "maxFee"
    );
    minLockDuration = minLockDuration_;
    maxLockDuration = maxLockDuration_;
    maxDividendsBonusMultiplier = maxDividendsBonusMultiplier_;
    minEarlyWithdrawalFee = minEarlyWithdrawalFee_;
    baseEarlyWithdrawalFee = baseEarlyWithdrawalFee_;
  }

/** ========== Controls ==========  */

  /**
   * @dev Trigger an emergency unlock which allows all locked tokens to be withdrawn
   * with zero fees.
   */
  function triggerEmergencyUnlock() external override onlyOwner {
    require(!emergencyUnlockTriggered, "already triggered");
    emergencyUnlockTriggered = true;
    emit EmergencyUnlockTriggered();
  }

  /**
   * @dev Set the minimum deposit to `minimumDeposit_`. If it is 0, there will be no minimum.
   */
  function setMinimumDeposit(uint96 minimumDeposit_) external override onlyOwner {
    minimumDeposit = minimumDeposit_;
    emit MinimumDepositSet(minimumDeposit_);
  }

  /**
   * @dev Set the account which receives fees taken for early withdrawals.
   */
  function setFeeRecipient(address feeRecipient_) external override onlyOwner {
    feeRecipient = feeRecipient_;
    emit FeeRecipientSet(feeRecipient_);
  }

/** ========== Fees ==========  */

  /**
   * @dev Transfers accumulated early withdrawal fees to the fee recipient.
   */
  function distributeFees() external override {
    address recipient = feeRecipient;
    require(recipient != address(0), "no recipient");
    uint256 amount = pendingFees;
    require(amount > 0, "no fees");
    pendingFees = 0;
    depositToken.safeTransfer(recipient, amount);
    emit FeesTransferred(amount);
  }

/** ========== Locks ==========  */

  /**
   * @dev Lock `amount` of `depositToken` for `duration` seconds.
   *
   * Mints an amount of dividend tokens equal to the amount of tokens locked
   * times 1 + (duration-minDuration) / (maxDuration - minDuration).
   *
   * Uses transferFrom - caller must have approved the contract to spend `amount`
   * of `depositToken`.
   *
   * If the emergency unlock has been triggered, deposits will fail.
   *
   * `amount` must be greater than `minimumDeposit`.
   */
  function deposit(uint256 amount, uint32 duration) external override returns (uint256 lockId) {
    require(amount >= minimumDeposit, "min deposit");
    require(!emergencyUnlockTriggered, "deposits blocked");
    _depositToModule(msg.sender, amount);
    uint256 multiplier = getDividendsMultiplier(duration);
    uint256 dividendShares = amount.mul(multiplier) / 1e18;
    IERC20DividendsOwned(dividendsToken).mint(msg.sender, dividendShares);
    lockId = locks.length;
    locks.push(Lock({
      amount: amount,
      lockedAt: uint32(block.timestamp),
      lockDuration: duration,
      owner: msg.sender
    }));
    emit LockCreated(
      lockId,
      msg.sender,
      amount,
      dividendShares,
      duration
    );
  }

  /**
   * @dev Withdraw the tokens locked in `lockId`.
   * The caller will incur an early withdrawal fee if the lock duration has not elapsed.
   * All of the dividend tokens received when the lock was created will be burned from the
   * caller's account.
   * This can only be executed by the lock owner.
   */
  function destroyLock(uint256 lockId) external override {
    withdraw(lockId, locks[lockId].amount);
  }

  function withdraw(uint256 lockId, uint256 amount) public override {
    Lock storage lock = locks[lockId];
    require(msg.sender == lock.owner, "!owner");
    lock.amount = lock.amount.sub(amount, "insufficient locked tokens");
    (uint256 owed, uint256 dividendShares) = _withdraw(lock, amount);
    if (lock.amount == 0) {
      delete locks[lockId];
      emit LockDestroyed(lockId, msg.sender, owed, dividendShares);
    } else {
      emit PartialWithdrawal(lockId, msg.sender, owed, dividendShares);
    }
  }

  function _withdraw(Lock memory lock, uint256 amount) internal returns (uint256 owed, uint256 dividendShares) {
    uint256 earlyWithdrawalFee;
    (dividendShares, earlyWithdrawalFee) = getWithdrawalParameters(
      amount,
      uint256(lock.lockedAt),
      uint256(lock.lockDuration)
    );
    owed = amount.sub(earlyWithdrawalFee);

    IERC20DividendsOwned(dividendsToken).burn(msg.sender, dividendShares);
    if (earlyWithdrawalFee > 0) {
      _withdrawFromModule(msg.sender, address(this), amount);
      depositToken.safeTransfer(msg.sender, owed);
      pendingFees = safe96(uint256(pendingFees).add(earlyWithdrawalFee));
      emit FeesReceived(earlyWithdrawalFee);
    } else {
      _withdrawFromModule(msg.sender, msg.sender, amount);
    }
  }

  function safe96(uint256 n) internal pure returns (uint96) {
    require(n < 2**96, "amount exceeds 96 bits");
    return uint96(n);
  }

  /**
   * @dev Delegate all voting shares the caller has in its sub-delegation module
   * to `delegatee`.
   * This will revert if the sub-delegation module does not exist.
   */
  function delegate(address delegatee) external override {
    _delegateFromModule(msg.sender, delegatee);
  }
}


interface IERC20DividendsOwned {
  function mint(address to, uint256 amount) external;
  function burn(address from, uint256 amount) external;
  function distribute(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/* ---  External Libraries  --- */
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import "../libraries/TransferHelper.sol";
import "../libraries/CloneLibrary.sol";
import "./SubDelegationModuleImplementation.sol";
import "../interfaces/IDelegationModule.sol";


contract DelegationModule is IDelegationModule {
  using TransferHelper for address;
  address public immutable override moduleImplementation;
  address public immutable override depositToken;

  /**
   * @dev Contains the address of the sub-delegation module for a user
   * if one has been deployed.
   */
  mapping(address => ISubDelegationModule) public override subDelegationModuleForUser;

  constructor(address depositToken_) {
    depositToken = depositToken_;
    moduleImplementation = address(new SubDelegationModuleImplementation(depositToken_));
  }

  function getOrCreateModule(address account) internal returns (ISubDelegationModule module) {
    module = subDelegationModuleForUser[account];
    if (address(module) == address(0)) {
      module = ISubDelegationModule(CloneLibrary.createClone(moduleImplementation));
      subDelegationModuleForUser[account] = module;
      module.delegate(account);
      emit SubDelegationModuleCreated(account, address(module));
    }
  }

  /**
   * @dev Send `amount` of the delegatable token to the sub-delegation
   * module for `account`. 
   */
  function _depositToModule(address account, uint256 amount) internal {
    ISubDelegationModule module = getOrCreateModule(account);
    depositToken.safeTransferFrom(account, address(module), amount);
  }

  /**
   * @dev Withdraw the full balance of the delegatable token from the
   * sub-delegation module for `account` to `to`.
   */
  function _withdrawFromModule(address account, address to, uint256 amount) internal {
    ISubDelegationModule module = subDelegationModuleForUser[account];
    module.transfer(to, amount);
  }

  /**
   * @dev Delegates the balance of the sub-delegation module for `account`
   * to `delegatee`.
   */
  function _delegateFromModule(address account, address delegatee) internal {
    ISubDelegationModule module = subDelegationModuleForUser[account];
    module.delegate(delegatee);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../interfaces/IERC20Delegatable.sol";


/**
 * @dev This is a work-around for the delegation mechanic in COMP.
 * It allows the balance of a staked governance token to be held in separate wallets
 * for each user who makes a deposit so that they will retain the ability to control
 * their governance delegation individually.
 *
 * This is an implementation contract that should be used for a separate proxy per user.
 */
contract SubDelegationModuleImplementation {
  IERC20Delegatable public immutable token;
  address public immutable module;


  constructor(address _token) {
    token = IERC20Delegatable(_token);
    module = msg.sender;
  }

  function delegate(address to) external {
    require(msg.sender == module, "!module");
    token.delegate(to);
  }

  function transfer(address to, uint256 amount) external {
    require(msg.sender == module, "!module");
    token.transfer(to, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./ISubDelegationModule.sol";


interface IDelegationModule {
  event SubDelegationModuleCreated(address indexed account, address module);

  function moduleImplementation() external view returns (address);

  function depositToken() external view returns (address);

  function subDelegationModuleForUser(address) external view returns (ISubDelegationModule);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./IERC20Metadata.sol";


interface IERC20Delegatable is IERC20Metadata {
  function delegate(address delegatee) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
import "./IERC20.sol";


interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./IDelegationModule.sol";


interface ISharesTimeLock is IDelegationModule {
  event LockCreated(
    uint256 indexed lockId,
    address indexed account,
    uint256 amountLocked,
    uint256 dividendShares,
    uint32 duration
  );

  event LockDestroyed(
    uint256 indexed lockId,
    address indexed account,
    uint256 amount,
    uint256 dividendShares
  );

  event PartialWithdrawal(
    uint256 indexed lockId,
    address indexed account,
    uint256 amount,
    uint256 dividendShares
  );

  event MinimumDepositSet(uint256 minimumDeposit);

  event FeeRecipientSet(address feeRecipient);

  event FeesReceived(uint256 amount);

  event FeesTransferred(uint256 amount);

  event EmergencyUnlockTriggered();

  /**
   * @dev Struct for token locks.
   * @param amount Amount of tokens deposited.
   * @param lockedAt Timestamp the lock was created at.
   * @param lockDuration Duration of lock in seconds.
   * @param owner Account that made the deposit.
   */
  struct Lock {
    uint256 amount;
    uint32 lockedAt;
    uint32 lockDuration;
    address owner;
  }

  function emergencyUnlockTriggered() external view returns (bool);

  function dividendsToken() external view returns (address);

  function minLockDuration() external view returns (uint32);

  function maxLockDuration() external view returns (uint32);

  function minEarlyWithdrawalFee() external view returns (uint256);

  function baseEarlyWithdrawalFee() external view returns (uint256);

  function maxDividendsBonusMultiplier() external view returns (uint256);

  function locks(uint256) external view returns (uint256 amount, uint32 lockedAt, uint32 lockDuration, address owner);
  
  function feeRecipient() external view returns (address);

  function minimumDeposit() external view returns (uint96);

  function pendingFees() external view returns (uint96);

  function getLocksLength() external view returns (uint256);

  function setMinimumDeposit(uint96 minimumDeposit_) external;

  function setFeeRecipient(address feeRecipient_) external;

  function getDividendsMultiplier(uint256 duration) external view returns (uint256 multiplier);

  function getWithdrawalParameters(
    uint256 amount,
    uint256 lockedAt,
    uint256 lockDuration
  )
    external
    view
    returns (uint256 dividendShares, uint256 earlyWithdrawalFee);

  function triggerEmergencyUnlock() external;

  function distributeFees() external;

  function deposit(uint256 amount, uint32 duration) external returns (uint256);

  function delegate(address delegatee) external;

  function destroyLock(uint256 lockId) external;

  function withdraw(uint256 lockId, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;


interface ISubDelegationModule {
  function delegate(address to) external;
  function transfer(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/**
 * EIP 1167 Proxy Deployment
 * Originally from https://github.com/optionality/clone-factory/
 */
library CloneLibrary {
  function createClone(address target) internal returns (address result) {
    // Reserve 55 bytes for the deploy code + 17 bytes as a buffer to prevent overwriting
    // other memory in the final mstore
    bytes memory createCode = new bytes(72);
    assembly {
      let clone := add(createCode, 32)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), shl(96, target))
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), shl(96, target))
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/LowGasSafeMath.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash b83fcf497e895ae59b97c9d04e997023f69b5e97.

Subject to the GPL-2.0-or-later license
*************************************************************************************************/


/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
        require((z = x + y) >= x, errorMessage);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
        require((z = x - y) <= x, errorMessage);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y, errorMessage);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import "../interfaces/IERC20.sol";
/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash 6a31c618fc3180a6ee945b869d1ce4449f253ee6.

Subject to the GPL-2.0-or-later license
*************************************************************************************************/


library TransferHelper {
  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    (bool success, bytes memory data) =
      token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "STF");
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "ST");
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "STE");
  }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "none",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}