/**
 *Submitted for verification at Etherscan.io on 2020-12-10
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

interface IERC20 {
  function totalSupplyAt(uint256 blockNumber) external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);
}

interface IGovernancePowerDelegationToken {
  enum DelegationType {VOTING_POWER, PROPOSITION_POWER}

  /**
   * @dev get the power of a user at a specified block
   * @param user address of the user
   * @param blockNumber block number at which to get power
   * @param delegationType delegation type (propose/vote)
   **/
  function getPowerAtBlock(
    address user,
    uint256 blockNumber,
    DelegationType delegationType
  ) external view returns (uint256);
}

interface IGovernanceStrategy {
  /**
   * @dev Returns the Proposition Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Proposition Power
   * @return Power number
   **/
  function getPropositionPowerAt(address user, uint256 blockNumber) external view returns (uint256);

  /**
   * @dev Returns the total supply of Outstanding Proposition Tokens
   * @param blockNumber Blocknumber at which to evaluate
   * @return total supply at blockNumber
   **/
  function getTotalPropositionSupplyAt(uint256 blockNumber) external view returns (uint256);

  /**
   * @dev Returns the total supply of Outstanding Voting Tokens
   * @param blockNumber Blocknumber at which to evaluate
   * @return total supply at blockNumber
   **/
  function getTotalVotingSupplyAt(uint256 blockNumber) external view returns (uint256);

  /**
   * @dev Returns the Vote Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Vote Power
   * @return Vote number
   **/
  function getVotingPowerAt(address user, uint256 blockNumber) external view returns (uint256);
}

/**
 * @title Governance Strategy contract
 * @dev Smart contract containing logic to measure users' relative power to propose and vote.
 * User Power = User Power from Aave Token + User Power from stkAave Token.
 * User Power from Token = Token Power + Token Power as Delegatee [- Token Power if user has delegated]
 * Two wrapper functions linked to Aave Tokens's GovernancePowerDelegationERC20.sol implementation
 * - getPropositionPowerAt: fetching a user Proposition Power at a specified block
 * - getVotingPowerAt: fetching a user Voting Power at a specified block
 * @author Aave
 **/
contract GovernanceStrategy is IGovernanceStrategy {
  address public immutable AAVE;
  address public immutable STK_AAVE;

  /**
   * @dev Constructor, register tokens used for Voting and Proposition Powers.
   * @param aave The address of the AAVE Token contract.
   * @param stkAave The address of the stkAAVE Token Contract
   **/
  constructor(address aave, address stkAave) {
    AAVE = aave;
    STK_AAVE = stkAave;
  }

  /**
   * @dev Returns the total supply of Proposition Tokens Available for Governance
   * = AAVE Available for governance      + stkAAVE available
   * The supply of AAVE staked in stkAAVE are not taken into account so:
   * = (Supply of AAVE - AAVE in stkAAVE) + (Supply of stkAAVE)
   * = Supply of AAVE, Since the supply of stkAAVE is equal to the number of AAVE staked
   * @param blockNumber Blocknumber at which to evaluate
   * @return total supply at blockNumber
   **/
  function getTotalPropositionSupplyAt(uint256 blockNumber) public view override returns (uint256) {
    return IERC20(AAVE).totalSupplyAt(blockNumber);
  }

  /**
   * @dev Returns the total supply of Outstanding Voting Tokens
   * @param blockNumber Blocknumber at which to evaluate
   * @return total supply at blockNumber
   **/
  function getTotalVotingSupplyAt(uint256 blockNumber) public view override returns (uint256) {
    return getTotalPropositionSupplyAt(blockNumber);
  }

  /**
   * @dev Returns the Proposition Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Proposition Power
   * @return Power number
   **/
  function getPropositionPowerAt(address user, uint256 blockNumber)
    public
    view
    override
    returns (uint256)
  {
    return
      _getPowerByTypeAt(
        user,
        blockNumber,
        IGovernancePowerDelegationToken.DelegationType.PROPOSITION_POWER
      );
  }

  /**
   * @dev Returns the Vote Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Vote Power
   * @return Vote number
   **/
  function getVotingPowerAt(address user, uint256 blockNumber)
    public
    view
    override
    returns (uint256)
  {
    return
      _getPowerByTypeAt(
        user,
        blockNumber,
        IGovernancePowerDelegationToken.DelegationType.VOTING_POWER
      );
  }

  function _getPowerByTypeAt(
    address user,
    uint256 blockNumber,
    IGovernancePowerDelegationToken.DelegationType powerType
  ) internal view returns (uint256) {
    return
      IGovernancePowerDelegationToken(AAVE).getPowerAtBlock(user, blockNumber, powerType) +
      IGovernancePowerDelegationToken(STK_AAVE).getPowerAtBlock(user, blockNumber, powerType);
  }
}

