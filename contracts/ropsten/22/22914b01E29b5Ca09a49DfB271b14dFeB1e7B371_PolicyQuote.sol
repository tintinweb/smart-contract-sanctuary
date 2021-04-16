// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

uint256 constant SECONDS_IN_THE_YEAR = 365 * 24 * 60 * 60; // 365 days * 24 hours * 60 minutes * 60 seconds
uint256 constant MAX_INT = 2**256 - 1;

uint256 constant PRECISION = 10**25;
uint256 constant PERCENTAGE_100 = 100 * PRECISION;

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "./interfaces/IPolicyBook.sol";
import "./interfaces/IPolicyQuote.sol";

import "./Globals.sol";

contract PolicyQuote is IPolicyQuote {
  using Math for uint256;
	using SafeMath for uint256;
  
  uint256 public constant RISKY_ASSET_THRESHOLD_PERCENTAGE = 70 * PRECISION;
  uint256 public constant MAXIMUM_COST_NOT_RISKY_PERCENTAGE = 30 * PRECISION;
  uint256 public constant MAXIMUM_COST_100_UTILIZATION_PERCENTAGE = 150 * PRECISION;

  uint256 public constant MINIMUM_COST_PERCENTAGE = 2 * PRECISION;   

  function calculateWhenNotRisky(uint256 _utilizationRatioPercentage) private pure returns (uint256) {
    return (_utilizationRatioPercentage.mul(MAXIMUM_COST_NOT_RISKY_PERCENTAGE)).div(RISKY_ASSET_THRESHOLD_PERCENTAGE);
  }

  function calculateWhenIsRisky(uint256 _utilizationRatioPercentage) private pure returns (uint256) {
    uint256 riskyRelation =
      (PRECISION.mul(_utilizationRatioPercentage.sub(RISKY_ASSET_THRESHOLD_PERCENTAGE))).div(
        (PERCENTAGE_100.sub(RISKY_ASSET_THRESHOLD_PERCENTAGE))
      );

    return
      MAXIMUM_COST_NOT_RISKY_PERCENTAGE.add(
        (riskyRelation.mul(MAXIMUM_COST_100_UTILIZATION_PERCENTAGE.sub(MAXIMUM_COST_NOT_RISKY_PERCENTAGE))).div(
          PRECISION
        )
      );
  }

  function getQuoteEpochs(uint256 _epochs, uint256 _tokens, address _policyBookAddr)
    external view override returns (uint256)
  {
    (, uint256 _currentEpochNumber, uint256 _totalCoverTokens) = IPolicyBook(_policyBookAddr).getUpdatedEpochsInfo();
    uint256 _totalSeconds = IPolicyBook(_policyBookAddr).getTotalSecondsOfEpochs(_epochs, _currentEpochNumber);

    return _getQuote(
      _totalSeconds, 
      _tokens,
      _totalCoverTokens,
      IPolicyBook(_policyBookAddr).totalLiquidity()
    );
  }

  function getQuote(uint256 _durationSeconds, uint256 _tokens, address _policyBookAddr)
    external view override returns (uint256)
  {
    return _getQuote(
      _durationSeconds, 
      _tokens,       
      IPolicyBook(_policyBookAddr).totalCoverTokens(),
      IPolicyBook(_policyBookAddr).totalLiquidity()
    );
  }

  function _getQuote(
    uint256 _durationSeconds, 
    uint256 _tokens,     
    uint256 _totalCoverTokens,
    uint256 _totalLiquidity
  ) 
    internal pure returns (uint256)
  {
    require(_tokens > 0, "PolicyQuote: Tokens amount must be greater than zero");
    require(_totalLiquidity > 0, "PolicyBook: The pool is empty");
    require(_totalCoverTokens.add(_tokens) <= _totalLiquidity, "PolicyBook: Requiring more than there exists");    

    uint256 utilizationRatioPercentage = ((_totalCoverTokens.add(_tokens)).mul(PERCENTAGE_100)).div(_totalLiquidity);

    uint256 annualInsuranceCostPercentage;

    if (utilizationRatioPercentage < RISKY_ASSET_THRESHOLD_PERCENTAGE) {
      annualInsuranceCostPercentage = calculateWhenNotRisky(utilizationRatioPercentage);
    } else {
      annualInsuranceCostPercentage = calculateWhenIsRisky(utilizationRatioPercentage);
    }

    annualInsuranceCostPercentage = Math.max(annualInsuranceCostPercentage, MINIMUM_COST_PERCENTAGE);
      
    uint256 actualInsuranceCostPercentage = 
      (_durationSeconds.mul(annualInsuranceCostPercentage)).div(SECONDS_IN_THE_YEAR);

    return (_tokens.mul(actualInsuranceCostPercentage)).div(PERCENTAGE_100);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IPolicyBookFabric.sol";

interface IPolicyBook {
  enum WithdrawalStatus {NONE, PENDING, READY, EXPIRED, IN_QUEUE}

  struct PolicyHolder {
    uint256 coverTokens;
    uint256 startEpochNumber;
    uint256 endEpochNumber;

    uint256 payed;
    uint256 payedToProtocol;
  }

  struct WithdrawalInfo {
    uint256 withdrawalAmount;
    uint256 readyToWithdrawDate;
  }

  function whitelisted() external view returns (bool);

  function EPOCH_DURATION() external view returns (uint256);

  function totalLiquidity() external view returns (uint256);

  function totalCoverTokens() external view returns (uint256);

  function epochStartTime() external view returns (uint256);

  function READY_TO_WITHDRAW_PERIOD() external view returns (uint256);

  function aggregatedQueueAmount() external view returns (uint256);

  function withdrawalsInfo(address _userAddr)
    external
    view
    returns (
      uint256 _withdrawalAmount,
      uint256 _readyToWithdrawDate
    );

  function whitelist(bool _whitelisted) external;

  // @TODO: should we let DAO to change contract address?
  /// @notice Returns address of contract this PolicyBook covers, access: ANY
  /// @return _contract is address of covered contract
  function insuranceContractAddress() external view returns (address _contract);

  /// @notice Returns type of contract this PolicyBook covers, access: ANY
  /// @return _type is type of contract
  function contractType() external view returns (IPolicyBookFabric.ContractType _type);    

  /// @notice get DAI equivalent
  function convertDAIXtoDAI(uint256 _amount) external view returns (uint256);    

  /// @notice get DAIx equivalent
  function convertDAIToDAIx(uint256 _amount) external view returns (uint256);

  function __PolicyBook_init(
    address _insuranceContract,
    IPolicyBookFabric.ContractType _contractType,    
    string calldata _description,
    string calldata _projectSymbol    
  ) external;

  function getWithdrawalStatus(address _userAddr) external view returns (WithdrawalStatus);

  /// @notice returns how many BMI tokens needs to approve in order to submit a claim
  function getClaimApprovalAmount(address user) external view returns (uint256);
  
  /// @notice submits new claim of the policy book
  function submitClaimAndInitializeVoting() external;

  /// @notice submits new appeal claim of the policy book
  function submitAppealAndInitializeVoting() external;

  /// @notice updates info on claim acceptance
  function commitClaim(address claimer, uint256 claimAmount) external;

  /// @notice Let user to buy policy by supplying DAI, access: ANY
  /// @param _durationSeconds is number of seconds to cover
  /// @param _coverTokens is number of tokens to cover  
  function buyPolicy(
    uint256 _durationSeconds,
    uint256 _coverTokens
  ) external;
  
  /// @notice converts epochs to seconds considering current epoch end time
  function getTotalSecondsOfEpochs(uint256 _epochs, uint256 _currentEpochNumber) 
    external 
    view 
    returns (uint256);

  /// @notice returns the future update
  function getUpdatedEpochsInfo() 
    external 
    view
    returns (
      uint256 lastEpochUpdate, 
      uint256 newEpochNumber, 
      uint256 newTotalCoverTokens
    ); 

  /// @notice Let user to add liquidity by supplying DAI, access: ANY
  /// @param _liqudityAmount is amount of DAI tokens to secure
  function addLiquidity(uint256 _liqudityAmount) external;

  /// @notice Let liquidityMining contract to add liqiudity for another user by supplying DAI, access: ONLY LM
  /// @param _liquidityHolderAddr is address of address to assign cover
  /// @param _liqudityAmount is amount of DAI tokens to secure
  function addLiquidityFromLM(address _liquidityHolderAddr, uint256 _liqudityAmount) external;

  function addLiquidityAndStake(uint256 _liquidityAmount, uint256 _bmiDAIxAmount) external;

  function addLiquidityAndStakeWithPermit(
    uint256 _liquidityAmount,      
    uint256 _bmiDAIxAmount,    
    uint8 v,
    bytes32 r, 
    bytes32 s
  ) external;

  function isExitFromQueuePossible(address _userAddr) external view returns (bool, uint256);

  function updateEpochsInfo() external;

  function updateWithdrawalQueue(uint256 _lastIndexToUpdate) external;

  function leaveQueue() external;

  function unlockTokens() external;

  function getWithdrawalQueue() external view returns (address[] memory _resultArr);

  function getIndexInQueue(address _userAddr) external view returns (uint256);

  function requestWithdrawal(uint256 _tokensToWithdraw) external;

  function requestWithdrawalWithPermit(
    uint256 _tokensToWithdraw,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;

  /// @notice Let user to withdraw deposited liqiudity, access: ANY
  function withdrawLiquidity() external;  

  /// @notice Getting user stats, access: ANY 
  function userStats(address _user)
    external
    view    
    returns (
      PolicyHolder memory
    );

  /// @notice Getting number stats, access: ANY
  /// @return _maxCapacities is a max token amount that a user can buy
  /// @return _totalDaiLiquidity is PolicyBook's liquidity
  /// @return _annualProfitYields is its APY  
  function numberStats()
    external
    view
    returns (
      uint256 _maxCapacities,
      uint256 _totalDaiLiquidity,
      uint256 _annualProfitYields
    );

  /// @notice Getting stats, access: ANY
  /// @return _name is the name of PolicyBook
  /// @return _insuredContract is an addres of insured contract
  /// @return _contractType is a type of insured contract  
  /// @return _whitelisted is a state of whitelisting
  function stats()
    external
    view
    returns (
      string memory _name,
      address _insuredContract,
      IPolicyBookFabric.ContractType _contractType,
      bool _whitelisted
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IPolicyBookFabric {
  enum ContractType {STABLECOIN, DEFI, CONTRACT, EXCHANGE}

  /// @notice Create new Policy Book contract, access: ANY
  /// @param _contract is Contract to create policy book for
  /// @param _contractType is Contract to create policy book for
  /// @param _description is bmiDAIx token desription for this policy book
  /// @param _projectSymbol replaces x in bmiDAIx token symbol  
  /// @return _policyBook is address of created contract
  function create(
    address _contract,
    ContractType _contractType,
    string calldata _description,
    string calldata _projectSymbol
  ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IPolicyQuote {
  /// @notice Let user to calculate policy cost in DAI, access: ANY
  function getQuoteEpochs(
    uint256 _epochsNumber, 
    uint256 _tokens, 
    address _policyBookAddr
    ) external view returns (uint256);

  /// @notice Let user to calculate policy cost in DAI, access: ANY
  /// @param _durationSeconds is number of seconds to cover
  /// @param _tokens is number of tokens to cover
  /// @param _policyBookAddr is address of policy book
  /// @return _daiTokens is amount of DAI policy costs
  function getQuote(
    uint256 _durationSeconds,
    uint256 _tokens,
    address _policyBookAddr
  ) external view returns (uint256 _daiTokens);
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