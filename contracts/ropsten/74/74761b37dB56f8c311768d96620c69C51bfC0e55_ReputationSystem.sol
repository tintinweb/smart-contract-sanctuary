// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

uint256 constant SECONDS_IN_THE_YEAR = 365 * 24 * 60 * 60; // 365 days * 24 hours * 60 minutes * 60 seconds
uint256 constant MAX_INT = type(uint256).max;

uint256 constant DECIMALS = 10**18;

uint256 constant PRECISION = 10**25;
uint256 constant PERCENTAGE_100 = 100 * PRECISION;

uint256 constant BLOCKS_PER_DAY = 6450;
uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

uint256 constant APY_TOKENS = DECIMALS;

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "./interfaces/IReputationSystem.sol";
import "./interfaces/IContractsRegistry.sol";

import "./abstract/AbstractDependant.sol";

import "./Globals.sol";

contract ReputationSystem is IReputationSystem, Initializable, AbstractDependant {
    using SafeMath for uint256;
    using Math for uint256;

    uint8 internal constant REPUTATION_PRECISION = 31; // should not be changed

    uint256 public constant MAXIMUM_REPUTATION = 3 * PRECISION; // 3
    uint256 public constant MINIMUM_REPUTATION = PRECISION / 10; // 0.1

    uint256 public constant PERCENTAGE_OF_TRUSTED_VOTERS = 15 * PRECISION;
    uint256 public constant LEAST_TRUSTED_VOTER_REPUTATION = 20; // 2.0
    uint256 public constant MINIMUM_TRUSTED_VOTERS = 5;

    address public claimVoting;

    uint256 internal _trustedVoterReputationThreshold; // 2.0

    uint256[] internal _roundedReputations; // 0.1 is 1, 3 is 30, 0 is empty

    uint256 internal _votedOnceCount;

    mapping(address => uint256) internal _reputation; // user -> reputation (0.1 * PRECISION to 3.0 * PRECISION)

    event ReputationSet(address user, uint256 newReputation);

    modifier onlyClaimVoting() {
        require(
            claimVoting == msg.sender,
            "ReputationSystem: Caller is not a ClaimVoting contract"
        );
        _;
    }

    function __ReputationSystem_init(address[] calldata team) external initializer {
        _trustedVoterReputationThreshold = 20;
        _roundedReputations = new uint256[](REPUTATION_PRECISION);

        _initTeamReputation(team);
    }

    function _initTeamReputation(address[] memory team) internal {
        for (uint8 i = 0; i < team.length; i++) {
            _setNewReputation(team[i], MAXIMUM_REPUTATION);
        }

        _recalculateTrustedVoterReputationThreshold();
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        claimVoting = _contractsRegistry.getClaimVotingContract();
    }

    function setNewReputation(address voter, uint256 newReputation)
        external
        override
        onlyClaimVoting
    {
        _setNewReputation(voter, newReputation);
        _recalculateTrustedVoterReputationThreshold();
    }

    function _setNewReputation(address voter, uint256 newReputation) internal {
        require(newReputation >= PRECISION.div(10), "ReputationSystem: reputation too low");
        require(newReputation <= PRECISION.mul(3), "ReputationSystem: reputation too high");

        uint256 voterReputation = _reputation[voter];

        if (voterReputation == 0) {
            _votedOnceCount++;
            voterReputation = PRECISION;
        }

        uint256 flooredOldReputation = voterReputation.mul(10).div(PRECISION);

        _reputation[voter] = newReputation;

        uint256 flooredNewReputation = newReputation.mul(10).div(PRECISION);

        emit ReputationSet(voter, newReputation);

        if (flooredOldReputation == flooredNewReputation) {
            return;
        }

        if (_roundedReputations[flooredOldReputation] > 0) {
            _roundedReputations[flooredOldReputation]--;
        }

        _roundedReputations[flooredNewReputation]++;
    }

    function _recalculateTrustedVoterReputationThreshold() internal {
        uint256 trustedVotersAmount =
            Math.max(
                MINIMUM_TRUSTED_VOTERS,
                _votedOnceCount.mul(PERCENTAGE_OF_TRUSTED_VOTERS).div(PERCENTAGE_100)
            );
        uint256 votersAmount;

        for (uint8 i = REPUTATION_PRECISION - 1; i >= LEAST_TRUSTED_VOTER_REPUTATION; i--) {
            uint256 roundedReputationVoters = _roundedReputations[i];
            votersAmount = votersAmount.add(roundedReputationVoters);

            if (votersAmount >= trustedVotersAmount) {
                if (
                    votersAmount >= trustedVotersAmount.mul(3).div(2) &&
                    votersAmount > roundedReputationVoters
                ) {
                    i++;
                }

                _trustedVoterReputationThreshold = i;
                break;
            }

            if (i == LEAST_TRUSTED_VOTER_REPUTATION) {
                _trustedVoterReputationThreshold = LEAST_TRUSTED_VOTER_REPUTATION;
            }
        }
    }

    function getNewReputation(address voter, uint256 percentageWithPrecision)
        external
        view
        override
        returns (uint256)
    {
        uint256 reputationVoter = _reputation[voter];

        return
            getNewReputation(
                reputationVoter == 0 ? PRECISION : reputationVoter,
                percentageWithPrecision
            );
    }

    function getNewReputation(uint256 voterReputation, uint256 percentageWithPrecision)
        public
        pure
        override
        returns (uint256)
    {
        require(
            percentageWithPrecision <= PERCENTAGE_100,
            "ReputationSystem: Percentage can't be more than 100%"
        );
        require(voterReputation >= PRECISION.div(10), "ReputationSystem: reputation too low");
        require(voterReputation <= PRECISION.mul(3), "ReputationSystem: reputation too high");

        if (percentageWithPrecision >= PRECISION.mul(50)) {
            return
                Math.min(
                    MAXIMUM_REPUTATION,
                    voterReputation.add(percentageWithPrecision.div(100).div(20))
                );
        } else {
            uint256 squared = PERCENTAGE_100.sub(percentageWithPrecision.mul(2));
            uint256 fraction = squared.mul(squared).div(2).div(PERCENTAGE_100).div(100);

            return
                fraction < voterReputation
                    ? Math.max(MINIMUM_REPUTATION, voterReputation.sub(fraction))
                    : MINIMUM_REPUTATION;
        }
    }

    function hasVotedOnce(address user) external view override returns (bool) {
        return _reputation[user] > 0;
    }

    /// @dev this function will count voters as trusted that have initial reputation >= 2.0
    /// regardless of how many times have they voted
    function isTrustedVoter(address user) external view override returns (bool) {
        return _reputation[user] >= _trustedVoterReputationThreshold.mul(PRECISION).div(10);
    }

    /// @notice this function returns reputation threshold multiplied by 10**25
    function getTrustedVoterReputationThreshold() external view override returns (uint256) {
        return _trustedVoterReputationThreshold.mul(PRECISION).div(10);
    }

    /// @notice this function returns reputation multiplied by 10**25
    function reputation(address user) external view override returns (uint256) {
        return _reputation[user] == 0 ? PRECISION : _reputation[user];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "../interfaces/IContractsRegistry.sol";

abstract contract AbstractDependant {
    /// @dev keccak256(AbstractDependant.setInjector(address)) - 1
    bytes32 private constant _INJECTOR_SLOT =
        0xd6b8f2e074594ceb05d47c27386969754b6ad0c15e5eb8f691399cd0be980e76;

    modifier onlyInjectorOrZero() {
        address _injector = injector();

        require(_injector == address(0) || _injector == msg.sender, "Dependant: Not an injector");
        _;
    }

    function setInjector(address _injector) external onlyInjectorOrZero {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            sstore(slot, _injector)
        }
    }

    /// @dev has to apply onlyInjectorOrZero() modifier
    function setDependencies(IContractsRegistry) external virtual;

    function injector() public view returns (address _injector) {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            _injector := sload(slot)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IContractsRegistry {
    function getUniswapRouterContract() external view returns (address);

    function getUniswapBMIToETHPairContract() external view returns (address);

    function getWETHContract() external view returns (address);

    function getDAIContract() external view returns (address);

    function getBMIContract() external view returns (address);

    function getPriceFeedContract() external view returns (address);

    function getPolicyBookRegistryContract() external view returns (address);

    function getPolicyBookFabricContract() external view returns (address);

    function getBMIDAIStakingContract() external view returns (address);

    function getRewardsGeneratorContract() external view returns (address);

    function getBMIUtilityNFTContract() external view returns (address);

    function getLiquidityMiningContract() external view returns (address);

    function getClaimingRegistryContract() external view returns (address);

    function getPolicyRegistryContract() external view returns (address);

    function getLiquidityRegistryContract() external view returns (address);

    function getClaimVotingContract() external view returns (address);

    function getReinsurancePoolContract() external view returns (address);

    function getPolicyBookAdminContract() external view returns (address);

    function getPolicyQuoteContract() external view returns (address);

    function getLegacyBMIStakingContract() external view returns (address);

    function getBMIStakingContract() external view returns (address);

    function getSTKBMIContract() external view returns (address);

    function getVBMIContract() external view returns (address);

    function getLegacyLiquidityMiningStakingContract() external view returns (address);

    function getLiquidityMiningStakingContract() external view returns (address);

    function getReputationSystemContract() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IReputationSystem {
    /// @notice sets new reputation for the voter
    function setNewReputation(address voter, uint256 newReputation) external;

    /// @notice returns voter's new reputation
    function getNewReputation(address voter, uint256 percentageWithPrecision)
        external
        view
        returns (uint256);

    /// @notice alternative way of knowing new reputation
    function getNewReputation(uint256 voterReputation, uint256 percentageWithPrecision)
        external
        pure
        returns (uint256);

    /// @notice returns true if the user voted at least once
    function hasVotedOnce(address user) external view returns (bool);

    /// @notice returns true if user's reputation is grater than or equal to trusted voter threshold
    function isTrustedVoter(address user) external view returns (bool);

    /// @notice this function returns reputation threshold multiplied by 10**25
    function getTrustedVoterReputationThreshold() external view returns (uint256);

    /// @notice this function returns reputation multiplied by 10**25
    function reputation(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
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