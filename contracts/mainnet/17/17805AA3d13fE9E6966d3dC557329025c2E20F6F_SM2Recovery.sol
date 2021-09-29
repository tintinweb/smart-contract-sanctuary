// Contracts by dYdX Foundation. Individual files are released under different licenses.
//
// https://dydx.community
// https://github.com/dydxfoundation/governance-contracts
//
// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeERC20 } from '../../../dependencies/open-zeppelin/SafeERC20.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { VersionedInitializable } from '../../../utils/VersionedInitializable.sol';

/**
 * @title SM2Recovery
 * @author dYdX
 *
 * @notice Distributes funds to stakers as part of the Safety Module v1 -> v2 recovery process.
 */
contract SM2Recovery is
  VersionedInitializable
{
  using SafeERC20 for IERC20;

  // ============ Events ============

  event Claimed(
    address staker,
    uint256 amount
  );

  // ============ Constants ============

  IERC20 public immutable TOKEN;

  // ============ Storage ============

  mapping(address => uint256) internal _OWED_AMOUNTS_;

  // ============ Constructor ============

  constructor(
    IERC20 token
  ) {
    TOKEN = token;
  }

  // ============ External Functions ============

  function initialize()
    external
    initializer
  {
    // Hard-coded list of amounts owed, calculated by taking the staked amount for each address and
    // adding 10% additional compensation.
    //
    // Snapshot taken on September 14, 2021 UTC, last tx was on September 9, 2021 UTC.
    _OWED_AMOUNTS_[0x8031EEC1118D1321387b1870F32984f72b447b04] = 64268082313114004568;
    _OWED_AMOUNTS_[0x5AcABC3222A7b74884bEC8efe28A7A69A7920818] = 552458868361822400896;
    _OWED_AMOUNTS_[0x5F5A46a8471F60b1E9F2eD0b8fc21Ba8b48887D8] = 235077596410469150;
    _OWED_AMOUNTS_[0x0DB0f4506F5De744052D90f04E3fcA3D1dD3600d] = 384593000000000000000;
    _OWED_AMOUNTS_[0x7457865bA58C4Fe72Fc43Ec8fDF61c818CAA93F4] = 1300887470344112802478;
    _OWED_AMOUNTS_[0x9c4d592042F959254485d443bBc337d29572264F] = 3300000000000000000000;
    _OWED_AMOUNTS_[0x80D0d54050C15971b21e877D95441800f5AA9ee8] = 11000000000000000000000;
    _OWED_AMOUNTS_[0x5B53d310c73Afd70f03b7a373b3e2451983228c1] = 1280981223066754379678;
    _OWED_AMOUNTS_[0x3286188FeA86932334F566E03722EEFd432a0E02] = 1317109351284421555527;
    _OWED_AMOUNTS_[0xE3666187c7Fbd30ea514a00747f27BeF2Df27d69] = 1477556477490299423613;
    _OWED_AMOUNTS_[0xDf6Db53933ebca389eC348fF1959C01364071144] = 7095256507486694584870;
    _OWED_AMOUNTS_[0xd6137678698f5304bEf86262332Be671618d5d08] = 7055301000000000000000;
    _OWED_AMOUNTS_[0xc4a69B137d22b52A36328F3ac6d5Aa9984fAab8E] = 4784593000000000000000;
    _OWED_AMOUNTS_[0x302240E264d6CA3d83E7567f8A9150AacaB735bc] = 5674396523298561944146;
    _OWED_AMOUNTS_[0x429f13e4ec5E57c9AE2388c5020E372F73fe168A] = 1286368590769499516847;
    _OWED_AMOUNTS_[0xe70949032907349A132E6793140679b43072F1E6] = 1718241113998470540361;
    _OWED_AMOUNTS_[0x57e2D81A82ACCCfaD9133929805CFf7f6dFc3bF4] = 181238687144559973685;
    _OWED_AMOUNTS_[0xC1AB8632e3f7fF2b62BcFC5c5DEba3aAA21799c9] = 2365000000000000000000;
    _OWED_AMOUNTS_[0x4F56A59804D464f44A3efc336FDf18A442fA8a72] = 1279861000000000000000;
    _OWED_AMOUNTS_[0x8C5bA8D0017C92527Daa77b145919A77614dfd9e] = 1281509901429422484117;
    _OWED_AMOUNTS_[0x7baf9864ecb3cEc21523508C86a1a3EFcE2408be] = 342338041811379508166;
    _OWED_AMOUNTS_[0x88cE8A4b8896Fab3556Cf23308F3387C55b0d0B7] = 4785681587877185155372;
    _OWED_AMOUNTS_[0xaCe95175B107f0d6A7A2949F7Af83d7A3528fB4e] = 1298458905663869980155;
    _OWED_AMOUNTS_[0x2e10104bD7B3e7C659f6F802166Be3FCdCd0C097] = 885095539863312510574;
    _OWED_AMOUNTS_[0x190fdb62971A2B0Ec9f037D4a0DaC1B062CCeaBD] = 4513484494342160884;
    _OWED_AMOUNTS_[0x0485A925b92F64D195B5f65D0B4C3B72004e98A4] = 4113076000000000000000;
    _OWED_AMOUNTS_[0x1b90B46F9Bd6BDcF0adDc4D0601dFAD832FDB1bD] = 1100000000000000000000;
    _OWED_AMOUNTS_[0x4CAe5BED586f6E73Ae54EbD40A4AC4eD2c477C34] = 5500000000000000000000;
    _OWED_AMOUNTS_[0x2245bE89Fc8faB94ed982e859Aa3212A4e4eB7e5] = 1282856631838285955062;
    _OWED_AMOUNTS_[0x0Dd6a8de365b2800F828E95feEf637027ceBfDc6] = 588558977171078055937;
    _OWED_AMOUNTS_[0xFF3f61fC642612D7799535132f5B7c5C0855d428] = 1433114383428671659805;
    _OWED_AMOUNTS_[0xb97d9350F32C1366016e2C0a55E4A210D1158b22] = 550000000000000000000;
    _OWED_AMOUNTS_[0xE629E1F7d250d39AF4d704B486B094A4bA91Ef3b] = 1287201041172069164377;
    _OWED_AMOUNTS_[0xaEaB8114f8920A0522F422618c5b9a2c618527c3] = 17835682575238615124669;
    _OWED_AMOUNTS_[0x0772C1EfC61Ff9cC902730d92B90403792edFC31] = 10790308971643820273711;
    _OWED_AMOUNTS_[0x961f4A36510cbB4ee58EE8FEaf65DC7E36A8e892] = 550000000000000000000;
    _OWED_AMOUNTS_[0x0F70c8C6236F4335B791637B8603F711F9829a27] = 10607091128313405834737;
    _OWED_AMOUNTS_[0x54276623b82377Ff9cD0a2a9CCB3e5b7430dDc66] = 342603963320765173769;
    _OWED_AMOUNTS_[0xb92667E34cB6753449ADF464f18ce1833Caf26e0] = 3474416779777843867269;
    _OWED_AMOUNTS_[0x89Cffe1B398FBF0Eb64BE9C08ebcE777Cec47500] = 7055765746048851547169;
    _OWED_AMOUNTS_[0x431c7CA252ba1c41ac11E67b2593e930608A60ed] = 732600000000000000000;
    _OWED_AMOUNTS_[0x34Fa1d4cc23735f72e38A44C6bEb4bf066862720] = 1279861000000000000000;
    _OWED_AMOUNTS_[0x5ef5a01b069dDf4B71d1fe8C1b23064Ffc3Cda92] = 3300000000000000000000;
    _OWED_AMOUNTS_[0xFd920E06Db76196987d94f2904D9467B9BE01ccd] = 1288537049417628862842;
    _OWED_AMOUNTS_[0xbc113aC29567eE89363E4d07462823F60b8B5528] = 2640000000000000000000;
    _OWED_AMOUNTS_[0xD70A24Be28cFAe9Dba87e7eB580B53Cc8Ae4Fe58] = 342533776463304204728;
    _OWED_AMOUNTS_[0x3B7b41F27b89F07269A0599F15fBa723f21f2442] = 546879927158663152683;
    _OWED_AMOUNTS_[0x9cd4b3F7f05240B5e07F0512ED7976ad4de81467] = 3814116914721288096590;
    _OWED_AMOUNTS_[0x19B003465B3b310463f8b925663F746a67c0DB95] = 1279948951048054429868;
    _OWED_AMOUNTS_[0x482AbC7795CcfB657DD09c9F0b67312F4ECCFD07] = 3724793551879978926290;
    _OWED_AMOUNTS_[0xcD1d9B792B3F8e19E742DC4f49a24e5637D72786] = 10484148886716091999320;
    _OWED_AMOUNTS_[0x51447CE0A502366658168Bf5AAf96f51d22AdcEE] = 1282928920964317728794;
    _OWED_AMOUNTS_[0xE3939654Deae5f54fD3e6B84b3A7F75f245062d8] = 11029668754351092393909;
    _OWED_AMOUNTS_[0x6649371d9236eCcDD7aF96fBA9435D78502354C1] = 1317091832283544853303;
    _OWED_AMOUNTS_[0x405B0C43d66D3406FaB0abc0eCee2359CeCe1c4B] = 715032626619900552466;
    _OWED_AMOUNTS_[0xE8b67eBf4825FEC2AB6c010A01064f5fa54672a5] = 2200000000000000000000;
  }

  function claim()
    external
    returns (uint256)
  {
    address staker = msg.sender;
    uint256 owedAmount = _OWED_AMOUNTS_[staker];

    // Update storage.
    _OWED_AMOUNTS_[staker] = 0;

    // Transfer the owed amount. Will revert if full amount is not available.
    TOKEN.safeTransfer(staker, owedAmount);
    emit Claimed(staker, owedAmount);
    return owedAmount;
  }

  function getOwedAmount(
    address staker
  )
    external
    view
    returns (uint256)
  {
    return _OWED_AMOUNTS_[staker];
  }

  // ============ Internal Functions ============

  /**
   * @dev Returns the revision of the implementation contract.
   *
   * @return The revision number.
   */
  function getRevision()
    internal
    pure
    override
    returns (uint256)
  {
    return 1;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import { IERC20 } from '../../interfaces/IERC20.sol';
import { SafeMath } from './SafeMath.sol';
import { Address } from './Address.sol';

/**
 * @title SafeERC20
 * @dev From https://github.com/OpenZeppelin/openzeppelin-contracts
 * Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function callOptionalReturn(IERC20 token, bytes memory data) private {
    require(address(token).isContract(), 'SafeERC20: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = address(token).call(data);
    require(success, 'SafeERC20: low-level call failed');

    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

/**
 * @title VersionedInitializable
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 */
abstract contract VersionedInitializable {
    /**
   * @dev Indicates that the contract has been initialized.
   */
    uint256 internal lastInitializedRevision = 0;

   /**
   * @dev Modifier to use in the initializer function of a contract.
   */
    modifier initializer() {
        uint256 revision = getRevision();
        require(revision > lastInitializedRevision, "Contract instance has already been initialized");

        lastInitializedRevision = revision;

        _;

    }

    /// @dev returns the revision number of the contract.
    /// Needs to be defined in the inherited class as a constant.
    function getRevision() internal pure virtual returns(uint256);


    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

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
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "berlin",
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}