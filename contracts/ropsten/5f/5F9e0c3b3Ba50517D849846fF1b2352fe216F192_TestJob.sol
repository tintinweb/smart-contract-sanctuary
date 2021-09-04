// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import '../interfaces/external/IKeep3rV1.sol';

contract TestJob {
  uint32 public COOLDOWN = 3 minutes;
  address keep3r;
  uint256 lastWork;

  error Cooldown();
  error NoKeeper();

  constructor(address _keep3r) {
    keep3r = _keep3r;
  }

  function workable() public view returns (bool) {
    return block.timestamp - lastWork < COOLDOWN;
  }

  function work() external validateAndPayKeeper(msg.sender) {
    if (!workable()) revert Cooldown();
  }

  modifier validateAndPayKeeper(address _keeper) {
    if (!IKeep3rV1(keep3r).isKeeper(_keeper)) revert NoKeeper();
    _;
    IKeep3rV1(keep3r).worked(_keeper);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

// solhint-disable func-name-mixedcase
interface IKeep3rV1 is IERC20, IERC20Metadata {
  // structs
  struct Checkpoint {
    uint32 fromBlock;
    uint256 votes;
  }

  // events
  event DelegateChanged(address indexed _delegator, address indexed _fromDelegate, address indexed _toDelegate);
  event DelegateVotesChanged(address indexed _delegate, uint256 _previousBalance, uint256 _newBalance);
  event SubmitJob(address indexed _job, address indexed _liquidity, address indexed _provider, uint256 _block, uint256 _credit);
  event ApplyCredit(address indexed _job, address indexed _liquidity, address indexed _provider, uint256 _block, uint256 _credit);
  event RemoveJob(address indexed _job, address indexed _liquidity, address indexed _provider, uint256 _block, uint256 _credit);
  event UnbondJob(address indexed _job, address indexed _liquidity, address indexed _provider, uint256 _block, uint256 _credit);
  event JobAdded(address indexed _job, uint256 _block, address _governance);
  event JobRemoved(address indexed _job, uint256 _block, address _governance);
  event KeeperWorked(address indexed _credit, address indexed _job, address indexed _keeper, uint256 _block, uint256 _amount);
  event KeeperBonding(address indexed _keeper, uint256 _block, uint256 _active, uint256 _bond);
  event KeeperBonded(address indexed _keeper, uint256 _block, uint256 _activated, uint256 _bond);
  event KeeperUnbonding(address indexed _keeper, uint256 _block, uint256 _deactive, uint256 _bond);
  event KeeperUnbound(address indexed _keeper, uint256 _block, uint256 _deactivated, uint256 _bond);
  event KeeperSlashed(address indexed _keeper, address indexed _slasher, uint256 _block, uint256 _slash);
  event KeeperDispute(address indexed _keeper, uint256 _block);
  event KeeperResolved(address indexed _keeper, uint256 _block);
  event AddCredit(address indexed _credit, address indexed _job, address indexed _creditor, uint256 _block, uint256 _amount);

  // variables
  function KPRH() external returns (address);

  function delegates(address _delegator) external view returns (address);

  function checkpoints(address _account, uint32 _checkpoint) external view returns (Checkpoint memory);

  function numCheckpoints(address _account) external view returns (uint32);

  function DOMAIN_TYPEHASH() external returns (bytes32);

  function DOMAINSEPARATOR() external returns (bytes32);

  function DELEGATION_TYPEHASH() external returns (bytes32);

  function PERMIT_TYPEHASH() external returns (bytes32);

  function nonces(address _user) external view returns (uint256);

  function BOND() external returns (uint256);

  function UNBOND() external returns (uint256);

  function LIQUIDITYBOND() external returns (uint256);

  function FEE() external returns (uint256);

  function BASE() external returns (uint256);

  function ETH() external returns (address);

  function bondings(address _user, address _bonding) external view returns (uint256);

  function unbondings(address _user, address _bonding) external view returns (uint256);

  function partialUnbonding(address _keeper, address _bonding) external view returns (uint256);

  function pendingbonds(address _keeper, address _bonding) external view returns (uint256);

  function bonds(address _keeper, address _bonding) external view returns (uint256);

  function votes(address _delegator) external view returns (uint256);

  function totalBonded() external returns (uint256);

  function firstSeen(address _keeper) external view returns (uint256);

  function disputes(address _keeper) external view returns (bool);

  function lastJob(address _keeper) external view returns (uint256);

  function workCompleted(address _keeper) external view returns (uint256);

  function jobs(address _job) external view returns (bool);

  function credits(address _job, address _credit) external view returns (uint256);

  function liquidityProvided(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256);

  function liquidityUnbonding(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256);

  function liquidityAmountsUnbonding(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256);

  function jobProposalDelay(address _job) external view returns (uint256);

  function liquidityApplied(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256);

  function liquidityAmount(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256);

  function keepers(address _keeper) external view returns (bool);

  function blacklist(address _keeper) external view returns (bool);

  function keeperList(uint256 _index) external view returns (address);

  function jobList(uint256 _index) external view returns (address);

  function governance() external returns (address);

  function pendingGovernance() external returns (address);

  function liquidityAccepted(address _liquidity) external view returns (bool);

  function liquidityPairs(uint256 _index) external view returns (address);

  // methods
  function getCurrentVotes(address _account) external view returns (uint256);

  function addCreditETH(address _job) external payable;

  function addCredit(
    address _credit,
    address _job,
    uint256 _amount
  ) external;

  function addVotes(address _voter, uint256 _amount) external;

  function removeVotes(address _voter, uint256 _amount) external;

  function addKPRCredit(address _job, uint256 _amount) external;

  function approveLiquidity(address _liquidity) external;

  function revokeLiquidity(address _liquidity) external;

  function pairs() external view returns (address[] memory);

  function addLiquidityToJob(
    address _liquidity,
    address _job,
    uint256 _amount
  ) external;

  function applyCreditToJob(
    address _provider,
    address _liquidity,
    address _job
  ) external;

  function unbondLiquidityFromJob(
    address _liquidity,
    address _job,
    uint256 _amount
  ) external;

  function removeLiquidityFromJob(address _liquidity, address _job) external;

  function mint(uint256 _amount) external;

  function burn(uint256 _amount) external;

  function worked(address _keeper) external;

  function receipt(
    address _credit,
    address _keeper,
    uint256 _amount
  ) external;

  function receiptETH(address _keeper, uint256 _amount) external;

  function addJob(address _job) external;

  function getJobs() external view returns (address[] memory);

  function removeJob(address _job) external;

  function setKeep3rHelper(address _keep3rHelper) external;

  function setGovernance(address _governance) external;

  function acceptGovernance() external;

  function isKeeper(address _keeper) external returns (bool);

  function isMinKeeper(
    address _keeper,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) external returns (bool);

  function isBondedKeeper(
    address _keeper,
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) external returns (bool);

  function bond(address _bonding, uint256 _amount) external;

  function getKeepers() external view returns (address[] memory);

  function activate(address _bonding) external;

  function unbond(address _bonding, uint256 _amount) external;

  function slash(
    address _bonded,
    address _keeper,
    uint256 _amount
  ) external;

  function withdraw(address _bonding) external;

  function dispute(address _keeper) external;

  function revoke(address _keeper) external;

  function resolve(address _keeper) external;

  function permit(
    address _owner,
    address _spender,
    uint256 _amount,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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