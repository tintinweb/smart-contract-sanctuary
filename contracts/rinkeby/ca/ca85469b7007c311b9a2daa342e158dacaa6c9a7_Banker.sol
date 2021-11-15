//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IBanker.sol";
import "../interfaces/IAddressManager.sol";
import "../interfaces/IStrategyAssetValue.sol";
import "../interfaces/IStrategyBase.sol";

/**
 * @notice Banker Contract
 * @author Maxos
 */
contract Banker is IBanker, ReentrancyGuardUpgradeable {
  /*** Constants ***/

  // USDC token
  IERC20Upgradeable public constant  USDC_TOKEN = IERC20Upgradeable(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

  /*** Storage Properties ***/

  // Strategy settings
  struct StrategySettings {
    uint256 insuranceAP; // insurance allocation percentage, scaled by 10e2
    uint256 desiredAssetAP; // desired asset allocation percentage, scaled by 10e2
    uint256 assetValue; // asset value in strategy
    uint256 reportedAt; // last reported time
  }

  // Interest rate
  struct InterestRate {
    uint256 interestRate; // current annual interest rate, scaled by 10e2
    uint256 lastInterestPaymentTime; // last time that we paid interest
  }

  // Next interest rate
  struct NextInterestRate {
    uint256 interestRate; // next interest rate
    uint256 nextRateStartTime;  // next rate start time
  }

  // MaxUSD redemption queue to the strategy, defined in IBanker like this
  // struct RedemptionRequest {
  //   address beneficiary; // redemption requestor
  //   uint256 amount; // MaxUSD amount to redeem
  //   uint256 requestedAt; // redemption request time
  // }

  // Strategy addresses
  address[] public strategies;

  // Returns if strategy is valid
  mapping(address => bool) public isValidStrategy;

  // Information per strategy
  mapping(address => StrategySettings) public strategySettings;

  // MaxUSD Liabilities
  uint256 public maxUSDLiabilities;

  // Redemption request dealy time
  uint256 public redemptionDelayTime;

  // Redemption request queue
  mapping(uint256 => RedemptionRequest) internal _redemptionRequestQueue;
  uint256 private first;
  uint256 private last;

  // Turn on/off option
  bool public isTurnOff;

  // Address manager
  address public addressManager;


  /*** Banker Settings Here */

  // MaxUSD annual interest rate
  InterestRate public maxUSDInterestRate;
  
  // MaxUSD next annual interest rate
  NextInterestRate public maxUSDNextInterestRate;

  // Mint percentage of MaxUSD and MaxBanker, scaled by 10e2
  // If mintDepositPercentage is 8000, we mint 80% of MaxUSD and 20% of MaxBanker
  uint256 public override mintDepositPercentage;

  // MaxBanker price, scaled by 10e18
  uint256 public maxBankerPrice;

  // Celling MaxSD price, scaled by 10e18
  uint256 public cellingMaxUSDPrice;

  // MaxBanker per stake
  uint256 public maxBankerPerStake;

  // Staking available
  uint256 public stakingAvailable;

  // Stake strike price, scaled by 10e18
  uint256 public stakeStrikePrice;

  // Stake lockup time
  uint256 public stakeLockupTime;


  /*** Contract Logic Starts Here */

  modifier onlyManager() {
    require(msg.sender == IAddressManager(addressManager).manager(), "No manager");
    _;
  }

  modifier onlyTreasuryContract() {
    require(isValidStrategy[msg.sender] && msg.sender == IAddressManager(addressManager).treasuryContract(), "No treasury");
    _;
  }

  modifier onlyTurnOn() {
    require(!isTurnOff, "Turn off");
    _;
  }

  /**
   * @notice Initialize the banker contract
   * @dev If mintDepositPercentage is 8000, we mint 80% of MaxUSD and 20% of MaxBanker
   * @param _addressManager Address manager contract
   * @param _mintDepositPercentage Mint percentage of MaxUSD and MaxBanker, scaled by 10e2
   * @param _redemptionDelayTime Delay time for the redemption request
   */
  function initialize(
    address _addressManager,
    uint256 _mintDepositPercentage,
    uint256 _redemptionDelayTime
  ) public initializer {
    __ReentrancyGuard_init();

    addressManager = _addressManager;

    // set mintDepositPercentage
    require(_mintDepositPercentage <= 10000, "Invalid percentage");
    mintDepositPercentage = _mintDepositPercentage;

    // set initial interest rate
    maxUSDInterestRate.interestRate = 0;
    maxUSDInterestRate.lastInterestPaymentTime = block.timestamp;

    // set redemptionDelayTime
    redemptionDelayTime = _redemptionDelayTime;

    // initialize redemption request queue parameters
    first = 1;
    last = 0;
  }

  /**
   * @notice Set `turnoff` switch to true
   * @dev Turn off all activities except for redeeming from strategies (except treasury) and redeeming MaxUSD from the treasury
   */
  function turnOff() external onlyManager {
    require(!isTurnOff, "Already turn off");
    isTurnOff = true;
  }

  /**
   * @notice Set `turnoff` switch to false
   * @dev Turn on all activities
   */
  function turnOn() external onlyManager {
    require(isTurnOff, "Already turn on");
    isTurnOff = false;
  }

  /**
   * @notice Add a new strategy
   * @dev Set isValidStrategy to true
   * @param _strategy Strategy address
   * @param _insuranceAP Insurance allocation percentage, scaled by 10e2
   * @param _desiredAssetAP Desired asset allocation percentage, scaled by 10e2
   */
  function addStrategy(
    address _strategy,
    uint256 _insuranceAP,
    uint256 _desiredAssetAP
  ) external onlyManager {
    require(!isValidStrategy[_strategy], "Already exists");
    require(_insuranceAP <= 10000, "InsuranceAP overflow");
    require(_desiredAssetAP <= 10000, "DesiredAssetAP overflow");
    isValidStrategy[_strategy] = true;

    strategies.push(_strategy);
    strategySettings[_strategy].insuranceAP = _insuranceAP;
    strategySettings[_strategy].desiredAssetAP = _desiredAssetAP;
  }

  /**
   * @notice Remove strategy
   * @dev Set isValidStrategy to false
   * @param _strategy Strategy address
   */
  function removeStrategy(address _strategy) external onlyManager {
    require(isValidStrategy[_strategy], "Not exist");
    isValidStrategy[_strategy] = false;

    for (uint256 i; i < strategies.length; i++) {
      if (strategies[i] == _strategy) {
        strategies[i] = strategies[strategies.length - 1];
        strategies.pop();

        break;
      }
    }
  }

  /**
   * @notice Set insurance allocation percentage to the strategy
   * @param _strategies Strategy addresses
   * @param _insuranceAPs Insurance allocation percentages, scaled by 10e2
   */
  function setStrategyInsuranceAPs(address[] memory _strategies, uint256[] memory _insuranceAPs)
    external
    onlyManager
    onlyTurnOn
  {
    require(_strategies.length == _insuranceAPs.length, "Data error");

    // set insuranceAP
    for (uint256 i; i < _strategies.length; i++) {
      require(isValidStrategy[_strategies[i]], "Invalid strategy");
      strategySettings[_strategies[i]].insuranceAP = _insuranceAPs[i];
    }

    // check if insuranceAP isn't overflowed
    uint256 sumInsuranceAP;
    for (uint256 j; j < strategies.length; j++) {
      sumInsuranceAP += strategySettings[strategies[j]].insuranceAP;
    }
    require(sumInsuranceAP <= 10000, "InsuranceAP overflow");
  }

  /**
   * @notice Set desired asset allocation percentage to the strategy
   * @dev Invest/redeem token in/from the strategy based on the new allocation percentage
   * @param _strategies Strategy addresses
   * @param _desiredAssetAPs Desired asset allocation percentages, scaled by 10e2
   */
  function setStrategyDesiredAssetAPs(address[] memory _strategies, uint256[] memory _desiredAssetAPs)
    external
    onlyManager
    onlyTurnOn
    nonReentrant
  {
    require(_strategies.length == _desiredAssetAPs.length, "Data error");

    // set desiredAssetAP
    for (uint256 i; i < _strategies.length; i++) {
      require(isValidStrategy[_strategies[i]], "Invalid strategy");
      strategySettings[_strategies[i]].desiredAssetAP = _desiredAssetAPs[i];
    }

    // check if desiredAssetAP isn't overflowed
    uint256 sumDesiredAssetAP;
    for (uint256 j; j < strategies.length; j++) {
      sumDesiredAssetAP += strategySettings[strategies[j]].desiredAssetAP;
    }
    require(sumDesiredAssetAP <= 10000, "DesiredAssetAP overflow");
  }

  /**
   * @notice Batch set of the insurance and desired asset allocation percentages
   * @dev Invest/redeem token in/from the strategy based on the new allocation
   * @param _strategies Strategy addresses
   * @param _insuranceAPs Insurance allocation percentages, scaled by 10e2
   * @param _desiredAssetAPs Desired asset allocation percentages, scaled by 10e2
   */
  function batchAllocation(
    address[] memory _strategies,
    uint256[] memory _insuranceAPs,
    uint256[] memory _desiredAssetAPs
  ) external onlyManager onlyTurnOn nonReentrant {
    // invest()
    // redeem()
  }

  /**
   * @notice Allocate assets to strategies
   */
  function allocate() external onlyManager onlyTurnOn nonReentrant {
    uint256 totalAssetValue = getTotalAssetValue();
    address treasury = IAddressManager(addressManager).treasuryContract();

    // redeem to Treasury
    int256 diffAmount;
    for (uint256 i; i < strategies.length; i++) {
      // ignore Treasury
      if (strategies[i] != treasury) {
        diffAmount = int256(strategySettings[strategies[i]].assetValue - totalAssetValue * strategySettings[strategies[i]].desiredAssetAP);
        if (diffAmount > 0) {
          IStrategyBase(strategies[i]).redeem(treasury, uint256(diffAmount));
        }
      }
    }

    // calculate total amount to invest
    int256 totalAmountToAllocate = int256(strategySettings[treasury].assetValue - totalAssetValue * strategySettings[treasury].desiredAssetAP);

    // invest
    uint256 strategyAmountToAllocate;
    for (uint256 j = 0; j <  strategies.length; j++) {
      // investment done
      if (totalAmountToAllocate <= 0) break;

      // transfer fund from treasury to strategies
      if (strategies[j] != treasury) {
        diffAmount = int256(totalAssetValue * strategySettings[strategies[j]].desiredAssetAP - strategySettings[strategies[j]].assetValue);
        if (diffAmount > 0) {
          strategyAmountToAllocate = uint256(totalAmountToAllocate > diffAmount ? diffAmount: totalAmountToAllocate);
          totalAmountToAllocate -= int256(strategyAmountToAllocate);
          require(totalAmountToAllocate >= 0, "Allocation fauiler");
          require(USDC_TOKEN.transferFrom(treasury, strategies[j], strategyAmountToAllocate), "Investment failure");
          // TODO: Remove the invest() comments later
          // IStrategyBase(strategies[j]).invest(uint256(diffAmount));
        }
      }
    }
  }

  /**
   * @notice Update annual interest rate and MaxUSDLiabilities for MaxUSD holders
   * @param _interestRate Interest rate earned since the last recored one, scaled by 10e2
   */
  function payInterest(uint256 _interestRate) external onlyManager onlyTurnOn {
    // update interest rate
    maxUSDInterestRate.interestRate = _interestRate;
    maxUSDInterestRate.lastInterestPaymentTime = block.timestamp;

    // update MaxUSDLiabilities
    maxUSDLiabilities = calculateMaxUSDLiabilities(_interestRate);
  }

  /**
   * @notice Set mint percentage of MaxUSD and MaxBanker
   * @dev mint percentage is scaled by 10e2
   * @param _mintDepositPercentage mint percentage of MaxUSD and MaxBanker
   */
  function setMintDepositPercentage(uint256 _mintDepositPercentage) external onlyManager {
    mintDepositPercentage = _mintDepositPercentage;
  }

  /**
   * @notice Set redemption request delay time
   * @param _redemptionDelayTime Redemption request dealy time
   */
  function setRedemptionDelayTime(uint256 _redemptionDelayTime) external onlyManager {
    redemptionDelayTime = _redemptionDelayTime;
  }

  /**
   * @notice Increase MaxUSDLiabilities
   * @param _amount USD amount to deposit
   */
  function increaseMaxUSDLiabilities(uint256 _amount) external override onlyTreasuryContract onlyTurnOn {
    maxUSDLiabilities += _amount;
  }

  /**
   * @notice Add redemption request to the queue
   * @param _requestor redemption requestor
   * @param _amount USD amount to redeem
   * @param _requestedAt requested time
   */
  function addRedemptionRequest(address _requestor, uint256 _amount, uint256 _requestedAt) external override onlyTreasuryContract onlyTurnOn {
    last++;
    _redemptionRequestQueue[last] = RedemptionRequest({ requestor: _requestor, amount: _amount, requestedAt: _requestedAt });
  }

  /**
   * @notice Get the MaxUSD holder's current MaxUSDLiablity
   * @param _maxUSDHolder MaxUSD holder
   */
  function getUserMaxUSDLiability(address _maxUSDHolder) external view override returns (uint256) {
    // address maxUSD = IAddressManager(addressManager).maxUSD();
    // uint256 totalShare = IERC20Upgradeable(maxUSD).totalSupply();
    // uint256 holderShare = IERC20Upgradeable(maxUSD).balanceOf(_maxUSDHolder);

    // return maxUSDLiabilities / totalShare * holderShare;

    // Assume that only one user(manager) deposits
    return maxUSDLiabilities;
  }

  /**
   * @notice Set next interest rate and start time
   * @param _interestRate next interest rate
   * @param _startTime next rate start time
   */
  function setNextInterestRateAndTime(uint256 _interestRate, uint256 _startTime) external onlyManager {
    maxUSDNextInterestRate.interestRate = _interestRate;
    maxUSDNextInterestRate.nextRateStartTime = _startTime;
  }

  /**
   * @notice Get total asset values across the strategies
   * @dev Set every strategy value and update time
   * @return (uint256) Total asset value scaled by 10e2, Ex: 100 USD is represented by 10,000
   */
  function getTotalAssetValue() public returns (uint256) {
    uint256 totalAssetValue;
    uint256 strategyAssetValue;
    for (uint256 i; i < strategies.length; i++) {
      strategyAssetValue = IStrategyAssetValue(strategies[i]).strategyAssetValue();
      totalAssetValue += strategyAssetValue;
      strategySettings[strategies[i]].assetValue = strategyAssetValue;
      strategySettings[strategies[i]].reportedAt = block.timestamp;
    }

    return totalAssetValue;
  }

  /**
   * @notice Calculate MaxUSDLiabilities with the interest rate given
   * @param _interestRate Interest rate scaled by 10e2
   * @return (uint256) MaxUSDLiabilities
   */
  function calculateMaxUSDLiabilities(uint256 _interestRate) public view returns (uint256) {
    uint256 passedDays = (block.timestamp - maxUSDInterestRate.lastInterestPaymentTime) / 1 days;
    return maxUSDLiabilities * (1 + _interestRate/10000) ** (passedDays / 365);
  }

  /**
   * @notice Decrease MaxUSDLiabilities
   * @param _amount USD amount to redeem
   */
  function decreaseMaxUSDLiabilities(uint256 _amount) internal onlyTurnOn {
    maxUSDLiabilities -= _amount;
  }

  /**
   * @notice Remove redemption request from the queue
   * @return (address, uint256, uint256) requestor, amount, requestedAt
   */
  function _removeRedemptionRequest() internal onlyTurnOn returns (address, uint256, uint256) {
    require(last >= first, "Empty redemption queue");

    address requestor = _redemptionRequestQueue[first].requestor;
    uint256 amount = _redemptionRequestQueue[first].amount;
    uint256 requestedAt = _redemptionRequestQueue[first].requestedAt;

    delete _redemptionRequestQueue[first];
    first++;

    return (requestor, amount, requestedAt);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IBanker {
  // MaxUSD redemption queue to the strategy
  struct RedemptionRequest {
      address requestor; // redemption requestor
      uint256 amount; // MaxUSD amount to redeem
      uint256 requestedAt; // redemption request time
  }

  function mintDepositPercentage() external view returns (uint256);
  function increaseMaxUSDLiabilities(uint256 _amount) external;
  function addRedemptionRequest(address _beneficiary, uint256 _amount, uint256 _reqestedAt) external;
  function getUserMaxUSDLiability(address _maxUSDHolder) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAddressManager {
  function manager() external view returns (address);

  function bankerContract() external view returns (address);

  function treasuryContract() external view returns (address);

  function maxUSD() external view returns (address);

  function maxBanker() external view returns (address);

  function investor() external view returns (address);

  function yearnUSDCStrategy() external view returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IStrategyAssetValue {
  function strategyAssetValue() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IStrategyBase {
  function invest(uint256 amount) external;

  function redeem(address beneficiary, uint256 amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

