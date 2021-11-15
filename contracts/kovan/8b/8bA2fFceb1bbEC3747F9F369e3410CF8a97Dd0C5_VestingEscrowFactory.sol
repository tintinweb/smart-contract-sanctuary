// SPDX-License-Identifier: ISC
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IVestingEscrow } from "../interfaces/IVestingEscrow.sol";
import { ILyra } from "../interfaces/ILyra.sol";
import { IStakedLyra } from "../interfaces/IStakedLyra.sol";

/**
 * @title VestingEscrowFactory
 * @author Lyra
 * @dev Deploy VestingEscrow contracts to distribute ERC20 tokens
 */
contract VestingEscrowFactory is Ownable {
  /**
   * @dev Structs used to group escrow related data used in `deployVestingEscrow` function
   *
   * `recipient` The address of the recipient that will be receiving the tokens
   * `admin` The address of the admin that will have special execution permissions in the escrow contract.
   * `vestingAmount` Amount of tokens being vested for `recipient`
   * `vestingBegin` Epoch time when tokens begin to vest
   * `vestingCliff` Duration after which the first portion vests
   * `vestingEnd` Epoch Time until all the amount should be vested
   */
  struct EscrowData {
    address recipient;
    address admin;
    uint256 vestingAmount;
    uint256 vestingBegin;
    uint256 vestingCliff;
    uint256 vestingEnd;
  }

  /**
   * @dev Structs used to group user permit signature data used in `deployVestingEscrow` function
   *
   * `deadline` to be used on `token` permit
   * `v` to be used on `token` permit
   * `r` to be used on `token` permit
   * `s` to be used on `token` permit
   */
  struct UserPermit {
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  address public target;
  IStakedLyra public stakedToken;

  event VestingEscrowCreated(
    address indexed funder,
    address indexed token,
    address indexed recipient,
    address admin,
    address escrow,
    uint256 amount,
    uint256 vestingBegin,
    uint256 vestingCliff,
    uint256 vestingEnd
  );

  event TargetSet(address indexed oldTarget, address indexed newTarget);

  event StakedTokenSet(address indexed stakedToken);

  /**
   * @dev Stores the implementation target for the minimal proxies.
   *
   * Sets ownership to the account that deploys the contract.
   *
   * @param target_ The address of the target implementation
   */
  constructor(address target_) {
    _setTarget(target_);
  }

  /**
   * @dev Stores the implementation target for the minimal proxies.
   *
   * Requirements:
   *
   * - the caller must be the owner.
   *
   * @param target_ The address of the target implementation
   */
  function setTarget(address target_) external onlyOwner {
    _setTarget(target_);
  }

  /**
   * @dev Sets stakedToken address which will be used as a beacon for all the escrow contracts.
   * This is necessary as the safety module could be introduced after the deployment of the
   * escrow contracts.
   *
   * Requirements:
   *
   * - the caller must be the owner.
   * - `stakedToken_` should not be the zero address.
   *
   * @param stakedToken_ The address of the staked token implementation
   */
  function setStakedToken(address stakedToken_) external onlyOwner {
    require(stakedToken_ != address(0), "stakedToken is zero address");
    emit StakedTokenSet(stakedToken_);
    stakedToken = IStakedLyra(stakedToken_);
  }

  /**
   * @dev Deploys a minimal proxy, initialize the vesting data and fund the escrow contract.
   * Uses [EIP-2612 permit](https://eips.ethereum.org/EIPS/eip-2612[EIP-2612]) for approving to this factory the
   * amount of tokens to distribute.
   *
   * @param escrowData Escrow related data
   * @param userPermit User permit data
   * @return The address of the deployed contract
   */
  function deployVestingEscrow(EscrowData memory escrowData, UserPermit memory userPermit) external returns (address) {
    // Create the escrow contract
    address vestingEscrowContract = _createProxy();

    // Initialize the contract with the vesting data
    require(
      IVestingEscrow(vestingEscrowContract).initialize(
        escrowData.recipient,
        escrowData.vestingAmount,
        escrowData.vestingBegin,
        escrowData.vestingCliff,
        escrowData.vestingEnd
      ),
      "initialization failed"
    );

    // Transfer the ownership to the admin
    IVestingEscrow(vestingEscrowContract).transferOwnership(escrowData.admin);

    ILyra token = IVestingEscrow(vestingEscrowContract).token();

    // Use permit to increase allowance
    token.permit(
      msg.sender,
      address(this),
      escrowData.vestingAmount,
      userPermit.deadline,
      userPermit.v,
      userPermit.r,
      userPermit.s
    );

    // Transfer funds to the escrow contract
    token.transferFrom(msg.sender, vestingEscrowContract, escrowData.vestingAmount);

    emit VestingEscrowCreated(
      msg.sender,
      address(token),
      escrowData.recipient,
      escrowData.admin,
      vestingEscrowContract,
      escrowData.vestingAmount,
      escrowData.vestingBegin,
      escrowData.vestingCliff,
      escrowData.vestingEnd
    );

    return vestingEscrowContract;
  }

  /**
   * @dev Stores the implementation target for the minimal proxies.
   *
   * Requirements:
   *
   * - `target_` should not be the zero address.
   *
   * @param target_ The address of the target implementation
   */
  function _setTarget(address target_) internal {
    require(target_ != address(0), "target is zero address");
    emit TargetSet(target, target_);
    target = target_;
  }

  /**
   * @dev Deploys a new minimal proxy using the target implementation as target to delegate all the calls.
   * Implementation based on https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
   * @return addr The address of the proxy
   */
  function _createProxy() internal returns (address addr) {
    bytes20 targetBytes = bytes20(target);

    // solhint-disable-next-line no-inline-assembly
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      addr := create(0, clone, 0x37)
    }
  }
}

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

// SPDX-License-Identifier: ISC
pragma solidity 0.7.6;

import { ILyra } from "./ILyra.sol";

interface IVestingEscrow {
  function initialize(
    address recipient,
    uint256 vestingAmount,
    uint256 vestingBegin,
    uint256 vestingCliff,
    uint256 vestingEnd
  ) external returns (bool);

  function transferOwnership(address newOwner) external;

  function token() external returns (ILyra);
}

// SPDX-License-Identifier: ISC
pragma solidity 0.7.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Permit } from "@openzeppelin/contracts/drafts/IERC20Permit.sol";

// solhint-disable-next-line no-empty-blocks
interface ILyra is IERC20, IERC20Permit {

}

// SPDX-License-Identifier: ISC
pragma solidity 0.7.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakedLyra is IERC20 {
  function stake(address to, uint256 amount) external;

  function redeem(address to, uint256 amount) external;

  function cooldown() external;

  function claimRewards(address to, uint256 amount) external;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

