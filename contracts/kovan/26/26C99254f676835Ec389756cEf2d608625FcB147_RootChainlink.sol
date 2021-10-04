// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "./BaseUpgradeabililtyProxy.sol";

contract RootChainlink is BaseUpgradeabililtyProxy {
  address private _admin;

  constructor (address admin) {
    _admin = admin;
  }

  function implement(address implementation) external onlyAdmin {
    upgradeTo(implementation);
  }

  modifier onlyAdmin() {
    require(
      msg.sender == _admin,
      "RootChainlink: Not admin"
    );

    _;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
import "../wallet/Data.sol";
import "./Address.sol";

contract BaseUpgradeabililtyProxy {
  // solhint-disable-next-line no-empty-blocks
  function initialize() public virtual {}

  bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  event Upgraded(address indexed implementation);
  event ValueReceived(address user, uint amount);

  function implementation() public view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      impl := sload(slot)
    }
  }

  function upgradeTo(address newImplementation) internal {
    setImplementation(newImplementation);

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory reason) = newImplementation.delegatecall(abi.encodeWithSignature("initialize()"));
    require(success, string(reason));

    emit Upgraded(newImplementation);
  }

  function setImplementation(address newImplementation) internal {
    require(UpgradesAddress.isContract(newImplementation),
      "Cannot set a proxy implementation to a non-contract address");
    bytes32 slot = IMPLEMENTATION_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newImplementation)
    }
  }

  receive() external payable {
    emit ValueReceived(msg.sender, msg.value);
  }

  // solhint-disable-next-line no-complex-fallback
  fallback () external payable {
    address _impl = implementation();
    require(_impl != address(0), "implementation not set");

    // solhint-disable-next-line no-inline-assembly
    assembly {
      calldatacopy(0, 0, calldatasize())

      let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

      returndatacopy(0, 0, returndatasize())

      switch result
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "../token/IVufi.sol";
import "../oracle/IOracle.sol";
import "../external/IFractionalExponents.sol";

contract RewardStore {
  struct Global {
    uint256 rate;
    uint256 stored;
    uint256 lastCycle;
    uint256 nextCycle;
  }
}

contract CycleStore {
  struct Global {
    uint256 start;
    uint256 period;
    uint256 current;
    uint256 nextCpi;
    uint256 lastCpi;
  }

  struct Coupons {
    uint256 outstanding;
  }

  struct Store {
    uint256 peged;
    uint256 rewards;
    uint256 pegToCoupons;
    Coupons coupons;
  }
}

contract AccountStore {
  enum Status {
    Frozen,
    Fluid,
    Locked
  }

  struct Store {
    uint256 deposited;
    uint256 balance;
    mapping(uint256 => uint256) coupons;
    mapping(address => uint256) couponAllowances;
    uint256 fluidUntil;
    uint256 lockedUntil;
    uint256 rewards;
    uint256 rewardsPaid;
  }
}

contract ProposalStore {
  enum Vote {
    UNDECIDED,
    APPROVE,
    REJECT
  }

  struct Store {
    uint256 start;
    uint256 period;
    uint256 approve;
    uint256 reject;
    mapping(address => Vote) votes;
    bool _initialized;
  }
}

contract EntrepotStore {
  struct Contracts {
    IVufi vufi;
    IOracle oracle;
    address exponents;
    address pool;
    address usdc;
    address factory;
    address chainUsdcUsd;
    address chaiManualDollarSpending;
    address chaiDollarSpending;
  }

  struct Balance {
    uint256 supply;
    uint256 peg;
    uint256 deposited;
    uint256 redeemable;
    uint256 debt;
    uint256 coupons;
    uint256 totalRewords;
    uint256 pegToCoupons;
  }

  struct DataJoin {
    Contracts contracts;
    Balance balance;
    CycleStore.Global cycle;
    RewardStore.Global reward;
    address admin;

    mapping(address => ProposalStore.Store) proposals;
    mapping(address => AccountStore.Store) accounts;
    mapping(uint256 => CycleStore.Store) cycles;
  }
}

contract Data {
  EntrepotStore.DataJoin internal _data;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

library UpgradesAddress {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly { size := extcodesize(account) }
    return size > 0;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVufi is IERC20 {
  function mint(address to, uint256 amount) external;
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../external/Decimal.sol";

abstract contract IOracle {
  function setup() public virtual;
  function capture() public virtual returns (Decimal.D256 memory, bool);
  function pair() external virtual view returns (address);
  function targetPrice() external virtual view returns (Decimal.D256 memory);
  function updateDollarSpendingPower() public virtual returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

interface IFractionalExponents {
  function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) external view returns (uint256, uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
  using SafeMath for uint256;

  // ============ Constants ============

  uint256 internal constant BASE = 10 ** 18;

  // ============ Structs ============


  struct D256 {
    uint256 value;
  }

  // ============ Static Functions ============

  function zero()
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : 0});
  }

  function one()
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : BASE});
  }

  function from(
    uint256 a
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : a.mul(BASE)});
  }

  function ratio(
    uint256 a,
    uint256 b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : getPartial(a, BASE, b)});
  }

  // ============ Self Functions ============

  function add(
    D256 memory self,
    uint256 b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.add(b.mul(BASE))});
  }

  function sub(
    D256 memory self,
    uint256 b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.sub(b.mul(BASE))});
  }

  function sub(
    D256 memory self,
    uint256 b,
    string memory reason
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.sub(b.mul(BASE), reason)});
  }

  function mul(
    D256 memory self,
    uint256 b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.mul(b)});
  }

  function div(
    D256 memory self,
    uint256 b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.div(b)});
  }

  function pow(
    D256 memory self,
    uint256 b
  )
  internal
  pure
  returns (D256 memory)
  {
    if (b == 0) {
      return from(1);
    }

    D256 memory temp = D256({value : self.value});
    for (uint256 i = 1; i < b; i++) {
      temp = mul(temp, self);
    }

    return temp;
  }

  function add(
    D256 memory self,
    D256 memory b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.add(b.value)});
  }

  function sub(
    D256 memory self,
    D256 memory b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.sub(b.value)});
  }

  function sub(
    D256 memory self,
    D256 memory b,
    string memory reason
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : self.value.sub(b.value, reason)});
  }

  function mul(
    D256 memory self,
    D256 memory b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : getPartial(self.value, b.value, BASE)});
  }

  function div(
    D256 memory self,
    D256 memory b
  )
  internal
  pure
  returns (D256 memory)
  {
    return D256({value : getPartial(self.value, BASE, b.value)});
  }

  function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
    return self.value == b.value;
  }

  function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
    return compareTo(self, b) == 2;
  }

  function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
    return compareTo(self, b) == 0;
  }

  function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
    return compareTo(self, b) > 0;
  }

  function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
    return compareTo(self, b) < 2;
  }

  function isZero(D256 memory self) internal pure returns (bool) {
    return self.value == 0;
  }

  function asUint256(D256 memory self) internal pure returns (uint256) {
    return self.value.div(BASE);
  }

  // ============ Core Methods ============

  function getPartial(
    uint256 target,
    uint256 numerator,
    uint256 denominator
  )
  private
  pure
  returns (uint256)
  {
    return target.mul(numerator).div(denominator);
  }

  function compareTo(
    D256 memory a,
    D256 memory b
  )
  private
  pure
  returns (uint256)
  {
    if (a.value == b.value) {
      return 1;
    }
    return a.value > b.value ? 2 : 0;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}