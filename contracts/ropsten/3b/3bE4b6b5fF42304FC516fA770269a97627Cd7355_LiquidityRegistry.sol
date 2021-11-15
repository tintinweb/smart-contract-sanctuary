// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./interfaces/IPolicyBook.sol";
import "./interfaces/IPolicyBookRegistry.sol";
import "./interfaces/IContractsRegistry.sol";
import "./interfaces/ILiquidityRegistry.sol";
import "./interfaces/IBMIDAIStaking.sol";

import "./abstract/AbstractDependant.sol";

contract LiquidityRegistry is ILiquidityRegistry, AbstractDependant {
  using SafeMath for uint256;
  using Math for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  IPolicyBookRegistry public policyBookRegistry;
  IBMIDAIStaking public bmiDaiStaking;

  // User address => policy books array
  mapping(address => EnumerableSet.AddressSet) private _policyBooks;

  event PolicyBookAdded(address _userAddr, address _policyBookAddress);
  event PolicyBookRemoved(address _userAddr, address _policyBookAddress);

  function setDependencies(IContractsRegistry _contractsRegistry) external override onlyInjectorOrZero { 
    policyBookRegistry = IPolicyBookRegistry(_contractsRegistry.getPolicyBookRegistryContract());
    bmiDaiStaking = IBMIDAIStaking(_contractsRegistry.getBMIDAIStakingContract());
  }

  modifier onlyEligibleContracts() {
    require(policyBookRegistry.isPolicyBook(msg.sender) || msg.sender == address(bmiDaiStaking),
      "LR: Not an eligible contract");
    _;
  }

  function tryToAddPolicyBook(address _userAddr, address _policyBookAddr) external override onlyEligibleContracts {
    if (IERC20(_policyBookAddr).balanceOf(_userAddr) > 0 || 
      bmiDaiStaking.balanceOf(_userAddr) > 0) {
      _policyBooks[_userAddr].add(_policyBookAddr);

      emit PolicyBookAdded(_userAddr, _policyBookAddr);
    }
  }

  function tryToRemovePolicyBook(address _userAddr, address _policyBookAddr) external override onlyEligibleContracts {
    if (IERC20(_policyBookAddr).balanceOf(_userAddr) == 0 &&
      bmiDaiStaking.balanceOf(_userAddr) == 0 &&
      IPolicyBook(_policyBookAddr).getWithdrawalStatus(_userAddr) == IPolicyBook.WithdrawalStatus.NONE) {
      _policyBooks[_userAddr].remove(_policyBookAddr);

      emit PolicyBookRemoved(_userAddr, _policyBookAddr);
    }
  }

  function getPolicyBooksArr(address _userAddr) external view returns (address[] memory _resultArr) {
    EnumerableSet.AddressSet storage policyBooksArr = _policyBooks[_userAddr];
    uint256 _policyBooksArrLength = policyBooksArr.length();

    _resultArr = new address[](_policyBooksArrLength);

    for (uint256 i = 0; i < _policyBooksArrLength; i++) {
      _resultArr[i] = policyBooksArr.at(i);
    }
  }

  function getLiquidityInfos(address _userAddr, uint256 _offset, uint256 _limit)
    external
    view
    returns (LiquidityInfo[] memory _resultArr)
  {
    EnumerableSet.AddressSet storage policyBooksArr = _policyBooks[_userAddr];

    uint256 _to = (_offset.add(_limit)).min(policyBooksArr.length()).max(_offset);

    _resultArr =  new LiquidityInfo[](_to - _offset);

    for (uint256 i = _offset; i < _to; i++) {
      address _currentPolicyBookAddr = policyBooksArr.at(i);

      (uint256 _lockedAmount, ) = IPolicyBook(_currentPolicyBookAddr).withdrawalsInfo(_userAddr);
      uint256 _availableAmount = IERC20(address(_currentPolicyBookAddr)).balanceOf(_userAddr);

      _resultArr[i] = LiquidityInfo(_currentPolicyBookAddr, _lockedAmount, _availableAmount, 0, 0, 0);

      if (IPolicyBook(_currentPolicyBookAddr).whitelisted()) {
        _resultArr[i].stakedAmount = bmiDaiStaking.totalStaked(_userAddr, address(_currentPolicyBookAddr));
        _resultArr[i].rewardsAmount = _getBMIProfit(_userAddr, _currentPolicyBookAddr);
        _resultArr[i].apy = bmiDaiStaking.getPolicyBookAPY(_currentPolicyBookAddr);
      }
    }
  }

  function _getBMIProfit(address _userAddr, address _policyBookAddr) internal view returns (uint256) {
    return bmiDaiStaking.getStakerBMIProfit(_userAddr, _policyBookAddr, 0, bmiDaiStaking.balanceOf(_userAddr));
  }

  function getWithdrawalRequests(address _userAddr, uint256 _offset, uint256 _limit)
    external
    view
    returns (uint256 _arrLength, WithdrawalRequestInfo[] memory _resultArr)
  {
    EnumerableSet.AddressSet storage policyBooksArr = _policyBooks[_userAddr];

    uint256 _to = (_offset.add(_limit)).min(policyBooksArr.length()).max(_offset);

    _resultArr =  new WithdrawalRequestInfo[](_to - _offset);

    for (uint256 i = _offset; i < _to; i++) {
      IPolicyBook _currentPolicyBook = IPolicyBook(policyBooksArr.at(i));

      IPolicyBook.WithdrawalStatus _currentStatus = _currentPolicyBook.getWithdrawalStatus(_userAddr);

      if (_currentStatus == IPolicyBook.WithdrawalStatus.NONE ||
        _currentStatus == IPolicyBook.WithdrawalStatus.IN_QUEUE) {
        continue;
      }

      (uint256 _requestAmount, uint256 _readyToWithdrawDate) = _currentPolicyBook.withdrawalsInfo(_userAddr);
      uint256 _endWithdrawDate;

      if (block.timestamp > _readyToWithdrawDate) {
        _endWithdrawDate = _readyToWithdrawDate.add(_currentPolicyBook.READY_TO_WITHDRAW_PERIOD());
      }

      _resultArr[_arrLength] = WithdrawalRequestInfo(
        address(_currentPolicyBook),
        _requestAmount,
        _currentPolicyBook.convertDAIXtoDAI(_requestAmount),
        _currentPolicyBook.totalLiquidity().sub(_currentPolicyBook.totalCoverTokens()),
        _readyToWithdrawDate,
        _endWithdrawDate
      );

      _arrLength++;
    }
  }

  function getWithdrawalQueueInfos(address _userAddr, uint256 _offset, uint256 _limit)
    external
    view
    returns (uint256 _arrLength, WithdrawalQueueInfo[] memory _resultArr)
  {
    EnumerableSet.AddressSet storage policyBooksArr = _policyBooks[_userAddr];

    uint256 _to = (_offset.add(_limit)).min(policyBooksArr.length()).max(_offset);

    _resultArr =  new WithdrawalQueueInfo[](_to - _offset);

    for (uint256 i = _offset; i < _to; i++) {
      IPolicyBook _currentPolicyBook = IPolicyBook(policyBooksArr.at(i));

      if (_currentPolicyBook.getWithdrawalStatus(_userAddr) != IPolicyBook.WithdrawalStatus.IN_QUEUE) {
        continue;
      }

      (uint256 _requestAmount, ) = _currentPolicyBook.withdrawalsInfo(_userAddr);
      (bool _isExitPossible, uint256 _userIndex) = _currentPolicyBook.isExitFromQueuePossible(_userAddr);

      if (!_isExitPossible) {
        _userIndex = _currentPolicyBook.getIndexInQueue(_userAddr);
      }

      _resultArr[_arrLength] = WithdrawalQueueInfo(
        address(_currentPolicyBook),
        _requestAmount,
        _currentPolicyBook.convertDAIXtoDAI(_requestAmount),
        _isExitPossible,
        _userIndex
      );

      _arrLength++;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "../interfaces/IContractsRegistry.sol";

abstract contract AbstractDependant {
    /// @dev keccak256(AbstractDependant.setInjector(address)) - 1
    bytes32 private constant _INJECTOR_SLOT = 0xd6b8f2e074594ceb05d47c27386969754b6ad0c15e5eb8f691399cd0be980e76;

    modifier onlyInjectorOrZero() { 
        address _injector = injector();

        require(_injector == address(0) || _injector == msg.sender, 
            "Dependant: Not an injector");
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

interface IBMIDAIStaking {
  struct StakingInfo {
    address policyBookAddress;

    uint256 stakingStartTime;
    uint256 stakingEndTime;

    uint256 stakedBmiDaiAmount;
    uint256 stakedDaiEquivalentAmount;
  }

  struct NFTsInfo {
    uint256 nftIndex;
    
    uint256 stakingStartTime;
    uint256 stakingEndTime;
    
    uint256 stakedBmiDaiAmount;
    uint256 reward;
  }

  function aggregateNFTs(address policyBookAddress, uint256[] calldata tokenIds) external;

  function stakeDAIx(uint256 amount, address policyBookAddress) external;

  function stakeDAIxWithPermit(
        uint256 bmiDaiAmount,          
        address policyBookAddress,
        uint8 v,
        bytes32 r, 
        bytes32 s
    ) external;

  function stakeDAIxFrom(address user, uint256 amount) external;

  function stakeDAIxFromWithPermit(
        address user,         
        uint256 bmiDaiAmount,
        uint8 v,
        bytes32 r, 
        bytes32 s
    ) external;

  function getPolicyBookAPY(address policyBookAddress) external view returns (uint256);

  function getBMIProfit(uint256 tokenId) external view returns (uint256);

  function getStakerBMIProfit(address staker, address policyBookAddress, uint256 offset, uint256 limit) 
    external
    view
    returns (uint256 totalProfit);

  function restakeBMIProfit(uint256 tokenId) external;

  function restakeStakerBMIProfit(address policyBookAddress) external;

  function withdrawBMIProfit(uint256 tokenID) external;

  function withdrawStakerBMIProfit(address policyBookAddress) external;

  function withdrawFundsWithProfit(uint256 tokenID) external;

  function withdrawStakerFundsWithProfit(address policyBookAddress) external;

  function stakingInfoByToken(uint256 tokenID) external view returns (StakingInfo memory);

  function totalStaked(address user, address policyBook) external view returns (uint256);

  function totalStaked(address user) external view returns (uint256);

  function balanceOf(address user) external view returns (uint256);
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

    function getLiquidityMiningNFTContract() external view returns (address);

    function getLiquidityMiningContract() external view returns (address);

    function getClaimingRegistryContract() external view returns (address);

    function getPolicyRegistryContract() external view returns (address);

    function getLiquidityRegistryContract() external view returns (address);  

    function getClaimVotingContract() external view returns (address);

    function getReinsurancePoolContract() external view returns (address);

    function getPolicyBookImplementation() external view returns (address);

    function getPolicyBookAdminContract() external view returns (address);

    function getPolicyQuoteContract() external view returns (address);

    function getBMIStakingContract() external view returns (address);

    function getSTKBMIContract() external view returns (address);

    function getVBMIContract() external view returns (address);

    function getLiquidityMiningStakingContract() external view returns (address);

    function getReputationSystemContract() external view returns (address);  
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

interface ILiquidityRegistry {
  struct LiquidityInfo {
    address policyBookAddr;

    uint256 lockedAmount;
    uint256 availableAmount;
    uint256 stakedAmount;

    uint256 rewardsAmount;
    uint256 apy;
  }

  struct WithdrawalRequestInfo {
    address policyBookAddr;

    uint256 requestAmount;
    uint256 requestDAIAmount;
    uint256 availableLiquidity;

    uint256 readyToWithdrawDate;
    uint256 endWithdrawDate;
  }

  struct WithdrawalQueueInfo {
    address policyBookAddr;

    uint256 requestAmount;
    uint256 requestDAIAmount;

    bool isExitPossible;
    uint256 userIndex;
  }

  function tryToAddPolicyBook(address _userAddr, address _policyBookAddr) external;

  function tryToRemovePolicyBook(address _userAddr, address _policyBookAddr) external;
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
pragma experimental ABIEncoderV2;

import "./IPolicyBookFabric.sol";

interface IPolicyBookRegistry {
  struct PolicyBookStats {
    string name;
    address insuredContract;
    IPolicyBookFabric.ContractType contractType;
    uint256 maxCapacity;
    uint256 totalDaiLiquidity;
    uint256 APY;
    bool whitelisted;
  }

  /// @notice Adds PolicyBook to registry, access: PolicyFabric
  function add(address _insuredContract, address _policyBook) external;

  /// @notice Checks if provided address is a PolicyBook
  function isPolicyBook(address _contract) external view returns (bool);

  /// @notice Returns number of registered PolicyBooks, access: ANY  
  function count() external view returns (uint256);

  /// @notice Listing registered PolicyBooks, access: ANY  
  /// @return _policyBooks is array of registered PolicyBook addresses
  function list(uint256 _offset, uint256 _limit)
    external
    view
    returns (      
      address[] memory _policyBooks
    );

  /// @notice Listing registered PolicyBooks, access: ANY  
  function listWithStats(uint256 _offset, uint256 _limit)
    external
    view
    returns (
      address[] memory _policyBooks,
      PolicyBookStats[] memory _stats
    );

  /// @notice Return existing Policy Book contract, access: ANY
  /// @param _contract is contract address to lookup for created IPolicyBook  
  function policyBookFor(address _contract) external view returns (address);

  /// @notice Getting stats from policy books, access: ANY
  /// @param _policyBooks is list of PolicyBooks addresses  
  function stats(address[] calldata _policyBooks)
    external
    view
    returns (
      PolicyBookStats[] memory _stats      
    );

  /// @notice Getting stats from policy books, access: ANY
  /// @param _insuredContracts is list of insuredContracts in registry  
  function statsByInsuredContracts(address[] calldata _insuredContracts)
    external
    view
    returns (
      PolicyBookStats[] memory _stats
    );
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

