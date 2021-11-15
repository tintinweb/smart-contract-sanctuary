pragma solidity 0.7.5;

import {Distributor} from './Distributor.sol';
import {IDistributorFactory} from '../interfaces/IDistributorFactory.sol';

contract DistributorFactory is IDistributorFactory {
  mapping(uint256 => address) private _roundAddresses;
  uint256 private _rounds;

  function getDistributorOfRound(uint256 round) external view override returns (address) {
    return _roundAddresses[round];
  }

  function getRoundsCount() external view override returns (uint256) {
    return _rounds;
  }

  /**
   * @dev Creates a new distribution round
   * @param merkleRoot the root of the distribution merkle tree
   * @param drainer the address of the drainer of the funds
   */
  function createRound(bytes32 merkleRoot, address drainer) external override returns (uint256) {
    uint256 myRound = _rounds++;
    Distributor distributorRound = new Distributor(myRound, merkleRoot, drainer);
    _roundAddresses[myRound] = address(distributorRound);
    emit RoundCreated(myRound, address(distributorRound), drainer);
    return myRound;
  }
}

pragma solidity 0.7.5;

import {BaseDistributor} from './BaseDistributor.sol';

import {IERC20} from '../interfaces/IERC20.sol';
import {SafeERC20} from '../open-zeppelin/SafeERC20.sol';

contract Distributor is BaseDistributor {
  using SafeERC20 for IERC20;

  uint256 public immutable ROUND;

  constructor(
    uint256 round,
    bytes32 merkleRoot,
    address drainer
  ) public BaseDistributor(merkleRoot, drainer) {
    ROUND = round;
  }

  /**
   * @dev Executes the claiming process, transfering the specified amount of
   * funds to the claimer
   * @param claimer the address of the claimer
   * @param asset the address of the asset
   * @param amount the amount of the token to claim
   */
  function _processClaim(
    address claimer,
    address asset,
    uint256 amount
  ) internal override {
    IERC20(asset).safeTransfer(claimer, amount);
  }
}

pragma solidity 0.7.5;

interface IDistributorFactory {
  event RoundCreated(uint256 round, address distributor, address drainer);

  function getDistributorOfRound(uint256 round) external view returns (address);

  function getRoundsCount() external view returns (uint256);

  function createRound(bytes32 merkleRoot, address drainer) external returns (uint256);
}

pragma solidity 0.7.5;

import {IERC20} from '../interfaces/IERC20.sol';
import {Ownable} from '../open-zeppelin/Ownable.sol';

import {SafeERC20} from '../open-zeppelin/SafeERC20.sol';
import {MerkleProof} from '../open-zeppelin/MerkleProof.sol';

import {IBaseDistributor} from '../interfaces/IBaseDistributor.sol';

abstract contract BaseDistributor is IBaseDistributor, Ownable {
  using SafeERC20 for IERC20;

  bytes32 public immutable override MERKLE_ROOT;

  /**
   * @dev Bitmap to store which claim is already executed. Each claim is identified by
   * an index so we can store 256 claims per uint256
   */
  mapping(uint256 => uint256) internal _claimed;

  constructor(bytes32 merkleRoot, address owner) {
    MERKLE_ROOT = merkleRoot;

    transferOwnership(owner);
  }

  /**
   * @dev Executes the claiming process
   * @param claimer the address of the claimer
   * @param asset the address of the asset
   * @param amount the amount of the token to claim
   */
  function _processClaim(
    address claimer,
    address asset,
    uint256 amount
  ) internal virtual;

  /**
   * @dev Returns if the claim is already executed
   * @param index the index of the leaf
   */
  function isClaimed(uint256 index) public view override returns (bool) {
    // Calc which word the index belongs to
    uint256 claimedWordIndex = index / 256;
    // Calc the index position within the word
    uint256 claimedBitIndex = index % 256;
    // Retrieve whether the index is marked as claimed
    uint256 claimedWord = _claimed[claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  /**
   * @dev Set an specific claim as executed
   * @param index the index of the leaf
   */
  function _setClaimed(uint256 index) private {
    // Calc which word the index belongs to
    uint256 claimedWordIndex = index / 256;
    // Calc the index position within the word
    uint256 claimedBitIndex = index % 256;
    // Mark the specific index position as claimed
    _claimed[claimedWordIndex] = _claimed[claimedWordIndex] | (1 << claimedBitIndex);
  }

  /**
   * @dev Execute the token claim
   * @param index the index of the leaf
   * @param claimer the address of the claimer
   * @param asset the address of the asset
   * @param amount the amount of the token to claim
   * @param merkleProof the array of proofs
   */
  function claim(
    uint256 index,
    address claimer,
    address asset,
    uint256 amount,
    bytes32[] memory merkleProof
  ) public override {
    require(!isClaimed(index), 'already claimed');
    require(verifyClaim(index, claimer, asset, amount, merkleProof), 'Distributor: Invalid proof.');

    _setClaimed(index);
    _processClaim(claimer, asset, amount);
    emit Claimed(claimer, asset, amount);
  }

  /**
   * @dev Verify the claim proof, so whether its part of the distribution tree
   * @param index the index of the leaf
   * @param claimer the address of the claimer
   * @param asset the address of the asset
   * @param amount the amount of the token to claim
   * @param merkleProof the array of proofs
   */
  function verifyClaim(
    uint256 index,
    address claimer,
    address asset,
    uint256 amount,
    bytes32[] memory merkleProof
  ) public view override returns (bool) {
    bytes32 _leaf = keccak256(abi.encodePacked(index, claimer, asset, amount));
    return MerkleProof.verify(merkleProof, MERKLE_ROOT, _leaf);
  }

  /**
   * @dev Drain the existing token funds of the contract
   * @param asset the address of the asset to drain
   * @param to the address of the recipient
   */
  function drain(address asset, address to) external override onlyOwner {
    uint256 amount = IERC20(asset).balanceOf(address(this));
    IERC20(asset).safeTransfer(to, amount);
    emit Drained(asset, to, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * From https://github.com/OpenZeppelin/openzeppelin-contracts
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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import {IERC20} from '../interfaces/IERC20.sol';
import {SafeMath} from './SafeMath.sol';
import {Address} from './Address.sol';

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

import './Context.sol';

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
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
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

library MerkleProof {
  /**
   * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
   * defined by `root`. For this, a `proof` must be provided, containing
   * sibling hashes on the branch from the leaf to the root of the tree. Each
   * pair of leaves and each pair of pre-images are assumed to be sorted.
   */
  function verify(
    bytes32[] memory proof,
    bytes32 root,
    bytes32 leaf
  ) internal pure returns (bool) {
    bytes32 computedHash = leaf;

    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (computedHash <= proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

    // Check if the computed hash (root) is equal to the provided root
    return computedHash == root;
  }
}

pragma solidity 0.7.5;

interface IBaseDistributor {
  event Claimed(address claimer, address asset, uint256 amount);

  event Drained(address asset, address to, uint256 amount);

  function MERKLE_ROOT() external view returns (bytes32);

  function isClaimed(uint256 index) external view returns (bool);

  function claim(
    uint256 index,
    address claimer,
    address asset,
    uint256 amount,
    bytes32[] memory merkleProof
  ) external;

  function verifyClaim(
    uint256 index,
    address claimer,
    address asset,
    uint256 amount,
    bytes32[] memory merkleProof
  ) external view returns (bool);

  function drain(address asset, address to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

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

pragma solidity ^0.7.5;

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

pragma solidity ^0.7.5;

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

