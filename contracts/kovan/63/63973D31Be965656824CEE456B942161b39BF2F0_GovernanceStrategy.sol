// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import {IGovernanceStrategy} from "./interfaces/IGovernanceStrategy.sol";
import {
    IGovernancePowerDelegationToken
} from "./interfaces/IGovernancePowerDelegationToken.sol";

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
    address public immutable STK_AAVE;

    /**
     * @dev Constructor, register tokens used for Voting and Proposition Powers.
     * @param stkAave The address of the stkAAVE Token Contract
     **/
    constructor(address stkAave) {
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
    function getTotalPropositionSupplyAt(uint256 blockNumber)
        public
        view
        override
        returns (uint256)
    {
        return IGovernancePowerDelegationToken(STK_AAVE).totalSupplyAt(blockNumber);
    }

    /**
     * @dev Returns the total supply of Outstanding Voting Tokens
     * @param blockNumber Blocknumber at which to evaluate
     * @return total supply at blockNumber
     **/
    function getTotalVotingSupplyAt(uint256 blockNumber)
        public
        view
        override
        returns (uint256)
    {
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
            IGovernancePowerDelegationToken(STK_AAVE).getPowerAtBlock(
                user,
                blockNumber,
                powerType
            );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IGovernancePowerDelegationToken {
    enum DelegationType {VOTING_POWER, PROPOSITION_POWER}

    /**
     * @dev emitted when a user delegates to another
     * @param delegator the delegator
     * @param delegatee the delegatee
     * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
     **/
    event DelegateChanged(
        address indexed delegator,
        address indexed delegatee,
        DelegationType delegationType
    );

    /**
     * @dev emitted when an action changes the delegated power of a user
     * @param user the user which delegated power has changed
     * @param amount the amount of delegated power for the user
     * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
     **/
    event DelegatedPowerChanged(
        address indexed user,
        uint256 amount,
        DelegationType delegationType
    );

    /**
     * @dev delegates the specific power to a delegatee
     * @param delegatee the user which delegated power has changed
     * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
     **/
    function delegateByType(address delegatee, DelegationType delegationType)
        external;

    /**
     * @dev delegates all the powers to a specific user
     * @param delegatee the user to which the power will be delegated
     **/
    function delegate(address delegatee) external;

    /**
     * @dev returns the delegatee of an user
     * @param delegator the address of the delegator
     **/
    function getDelegateeByType(
        address delegator,
        DelegationType delegationType
    ) external view returns (address);

    /**
     * @dev returns the current delegated power of a user. The current power is the
     * power delegated at the time of the last snapshot
     * @param user the user
     **/
    function getPowerCurrent(address user, DelegationType delegationType)
        external
        view
        returns (uint256);

    /**
     * @dev returns the delegated power of a user at a certain block
     * @param user the user
     **/
    function getPowerAtBlock(
        address user,
        uint256 blockNumber,
        DelegationType delegationType
    ) external view returns (uint256);

    /**
     * @dev returns the total supply at a certain block number
     **/
    function totalSupplyAt(uint256 blockNumber) external view returns (uint256);
}