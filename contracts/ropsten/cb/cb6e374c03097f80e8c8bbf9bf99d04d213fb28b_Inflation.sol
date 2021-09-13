// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import  "../../genesis/implementation/FlareDaemon.sol";
import "../../genesis/interface/IFlareDaemonize.sol";
import "../../genesis/interface/IInflationGenesis.sol";
import "../../utils/implementation/GovernedAndFlareDaemonized.sol";
import "../lib/InflationAnnum.sol";
import "../lib/InflationAnnums.sol";
import "../interface/IIInflationPercentageProvider.sol";
import "../interface/IIInflationReceiver.sol";
import "../interface/IIInflationSharingPercentageProvider.sol";
import "../lib/RewardService.sol"; 
import "../interface/IISupply.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../utils/implementation/SafePct.sol";

/**
 * @title Inflation
 * @notice A contract to manage the process of recognizing, authorizing, minting, and funding
 *   native tokens for Flare services that are rewardable by inflation.
 * @dev Please see docs/specs/Inflation.md to better understand this terminology.
 **/
contract Inflation is IInflationGenesis, GovernedAndFlareDaemonized, IFlareDaemonize {
    using InflationAnnums for InflationAnnums.InflationAnnumsState;
    using SafeMath for uint256;
    using SafePct for uint256;

    // Composable contracts
    IIInflationPercentageProvider public inflationPercentageProvider;
    IIInflationSharingPercentageProvider public inflationSharingPercentageProvider;
    IISupply public supply;

    // The annums
    InflationAnnums.InflationAnnumsState private inflationAnnums;       // Inflation annum data

    // Instance vars
    uint256 public lastAuthorizationTs;                                 // The last time inflation was authorized
    mapping(IIInflationReceiver => TopupConfiguration)
        internal topupConfigurations;                                   // A topup configuration for a contract
                                                                        //   receiving inflation.
    uint256 public totalSelfDestructReceivedWei;
    //slither-disable-next-line uninitialized-state                     // no problem, will be zero initialized anyway
    uint256 public totalSelfDestructWithdrawnWei;
    uint256 immutable public rewardEpochStartTs;                        // Do not start inflation annums before this
    uint256 public rewardEpochStartedTs;                                // When the first reward epoch was started

    // Constants
    string internal constant ERR_IS_ZERO = "address is 0";
    string internal constant ERR_OUT_OF_BALANCE = "out of balance";
    string internal constant ERR_TOPUP_LOW = "topup low";
    string internal constant ERR_GET_ANNUAL_PERCENT = "unknown error. getAnnualPercentageBips";
    string internal constant ERR_SUPPLY_UPDATE = "unknown error. updateAuthorizedInflationAndCirculatingSupply";
    string internal constant ERR_REQUEST_MINT = "unknown error. requestMinting";

    uint256 internal constant BIPS100 = 1e4;                            // 100% in basis points
    uint256 internal constant DEFAULT_TOPUP_FACTOR_X100 = 120;
    // DO NOT UPDATE - this affects supply contract, which is expected to be updated once a day
    uint256 internal constant AUTHORIZE_TIME_FRAME_SEC = 1 days;

    event InflationAuthorized(uint256 amountWei);
    event MintingReceived(uint256 amountWei, uint256 selfDestructAmountWei);
    event TopupRequested(uint256 amountWei);
    event InflationPercentageProviderSet(IIInflationPercentageProvider inflationPercentageProvider);
    event InflationSharingPercentageProviderSet(
        IIInflationSharingPercentageProvider inflationSharingPercentageProvider);
    event RewardServiceTopupComputed(IIInflationReceiver inflationReceiver, uint256 amountWei);
    event RewardServiceDailyAuthorizedInflationComputed(IIInflationReceiver inflationReceiver, uint256 amountWei);
    event RewardServiceTopupRequestReceived(IIInflationReceiver inflationReceiver, uint256 amountWei);
    event SupplySet(IISupply oldSupply, IISupply newSupply);
    event TopupConfigurationSet(TopupConfiguration topupConfiguration);
    event NewAnnumInitialized(
        uint16 daysInAnnum,
        uint256 startTimeStamp,
        uint256 endTimeStamp,
        uint256 inflatableSupplyWei,
        uint256 recognizedInflationWei,
        uint256 totalAuthorizedInflationWei,
        uint256 totalInflationTopupRequestedWei,
        uint256 totalInflationTopupReceivedWei,
        uint256 totalInflationTopupWithdrawnWei
    );

    /**
     * @dev This modifier ensures that this contract's balance matches the expected balance.
     */
    modifier mustBalance {
        _;
        require (getExpectedBalance() == address(this).balance, ERR_OUT_OF_BALANCE);
    }

    modifier notZero(address _address) {
        require(_address != address(0), ERR_IS_ZERO);
        _;
    }

    constructor (
        address _governance, 
        FlareDaemon _flareDaemon,
        IIInflationPercentageProvider _inflationPercentageProvider,
        IIInflationSharingPercentageProvider _inflationSharingPercentageProvider,
        uint256 _rewardEpochStartTs
    )
        GovernedAndFlareDaemonized(_governance, _flareDaemon)
        notZero(address(_inflationPercentageProvider))
        notZero(address(_inflationSharingPercentageProvider))
    {
        inflationPercentageProvider = _inflationPercentageProvider;
        inflationSharingPercentageProvider = _inflationSharingPercentageProvider;
        rewardEpochStartTs = _rewardEpochStartTs;
    }

    /**
     * @notice Get a tuple of totals across inflation annums.
     * @return _totalAuthorizedInflationWei     Total inflation authorized to be mintable
     * @return _totalInflationTopupRequestedWei Total inflation requested to be topped up for rewarding
     * @return _totalInflationTopupReceivedWei  Total inflation received for funding reward services
     * @return _totalInflationTopupWithdrawnWei Total inflation used for funding reward services
     * @return _totalRecognizedInflationWei     Total inflation recognized for rewarding
     * @return _totalSelfDestructReceivedWei    Total balance received as a self-destruct recipient
     * @return _totalSelfDestructWithdrawnWei   Total self-destruct balance withdrawn
     */
    function getTotals()
        external view 
        returns (
            uint256 _totalAuthorizedInflationWei,
            uint256 _totalInflationTopupRequestedWei,
            uint256 _totalInflationTopupReceivedWei,
            uint256 _totalInflationTopupWithdrawnWei,
            uint256 _totalRecognizedInflationWei,
            uint256 _totalSelfDestructReceivedWei,
            uint256 _totalSelfDestructWithdrawnWei
        )
    {
        _totalAuthorizedInflationWei = inflationAnnums.totalAuthorizedInflationWei;
        _totalInflationTopupRequestedWei = inflationAnnums.totalInflationTopupRequestedWei;
        _totalInflationTopupReceivedWei = inflationAnnums.totalInflationTopupReceivedWei;
        _totalInflationTopupWithdrawnWei = inflationAnnums.totalInflationTopupWithdrawnWei;
        _totalRecognizedInflationWei = inflationAnnums.totalRecognizedInflationWei;
        _totalSelfDestructReceivedWei = totalSelfDestructReceivedWei;
        _totalSelfDestructWithdrawnWei = totalSelfDestructWithdrawnWei;
    }

    /**
     * @notice Given an index, return the annum at that index.
     * @param _index    The index of the annum to fetch.
     * @return          The inflation annum state.
     * @dev Expect library to revert if index not found.
     */
    function getAnnum(uint256 _index) external view returns(InflationAnnum.InflationAnnumState memory) {
        return inflationAnnums.getAnnum(_index);
    }

    /**
     * @notice Return the current annum.
     * @return The inflation annum state of the current annum.
     * @dev Expect library to revert if there is no current annum.
     */
    function getCurrentAnnum() external view returns(InflationAnnum.InflationAnnumState memory) {
        return inflationAnnums.getCurrentAnnum();
    }

    /**
     * @notice Receive newly minted native tokens from the FlareDaemon.
     * @dev Assume that the amount received will be >= last topup requested across all services.
     *   If there is not enough balance sent to cover the topup request, expect library method will revert.
     *   Also assume that any balance received greater than the topup request calculated
     *   came from self-destructor sending a balance to this contract.
     */
    function receiveMinting() external override payable onlyFlareDaemon mustBalance {
        uint256 amountPostedWei = inflationAnnums.receiveTopupRequest();
        // Assume that if we received (or already have) more than we posted, 
        // it must be amounts sent from a contract self-destruct
        // recipient in this block.
        uint256 prevBalance = getExpectedBalance();
        uint256 selfDestructProceeds = address(this).balance.sub(prevBalance);
        if (selfDestructProceeds > 0) {
            totalSelfDestructReceivedWei = totalSelfDestructReceivedWei.add(selfDestructProceeds);
        }
        emit MintingReceived(amountPostedWei, selfDestructProceeds);
    }

    /**
     * @notice Set a reference to a provider of the annual inflation percentage.
     * @param _inflationPercentageProvider  A contract providing the annual inflation percentage.
     * @dev Assume that referencing contract has reasonablness limitations on percentages.
     */
    function setInflationPercentageProvider(
        IIInflationPercentageProvider _inflationPercentageProvider
    )
        external
        notZero(address(_inflationPercentageProvider))
        onlyGovernance
    {
        inflationPercentageProvider = _inflationPercentageProvider;

        emit InflationPercentageProviderSet(_inflationPercentageProvider);
    }

    /**
     * @notice Set a reference to a provider of sharing percentages by inflation receiver.
     * @param _inflationSharingPercentageProvider   A contract providing sharing percentages.
     * @dev Assume that sharing percentages sum to 100% if at least one exists, but
     *   if no sharing percentages are defined, then no inflation will be authorized.
     */
    function setInflationSharingPercentageProvider(
        IIInflationSharingPercentageProvider _inflationSharingPercentageProvider
    )
        external
        notZero(address(_inflationSharingPercentageProvider))
        onlyGovernance
    {
        inflationSharingPercentageProvider = _inflationSharingPercentageProvider;

        emit InflationSharingPercentageProviderSet(_inflationSharingPercentageProvider);
    }

    /**
     * @notice Set a reference to the Supply contract.
     * @param _supply   The Supply contract.
     * @dev The supply contract is used to get and update the inflatable balance.
     */
    function setSupply(IISupply _supply) external notZero(address(_supply)) onlyGovernance {
        emit SupplySet(supply, _supply);
        supply = _supply;
    }

    /**
     * @notice Set the topup configuration for a reward service.
     * @param _inflationReceiver    The reward service to receive the inflation funds for distribution.
     * @param _topupType            The type to signal how the topup amounts are to be calculated.
     *                              FACTOROFDAILYAUTHORIZED = Use a factor of last daily authorized to set a
     *                              target balance for a reward service to maintain as a reserve for claiming.
     *                              ALLAUTHORIZED = Mint enough native tokens to topup reward service contract to hold
     *                              all authorized but unrequested rewards.
     * @param _topupFactorX100      If _topupType == FACTOROFDAILYAUTHORIZED, then this factor (times 100)
     *                              is multipled by last daily authorized inflation to obtain the
     *                              maximum balance that a reward service can hold at any given time. If it holds less,
     *                              then this max amount is used to compute the mint request topup required to 
     *                              bring the reward service contract native token balance up to that amount.
     * @dev Topup factor, if _topupType == FACTOROFDAILYAUTHORIZED, must be greater than 100.
     */
    function setTopupConfiguration(
        IIInflationReceiver _inflationReceiver, 
        TopupType _topupType, 
        uint256 _topupFactorX100
    )
        external
        notZero(address(_inflationReceiver))
        onlyGovernance
    {
        if (_topupType == TopupType.FACTOROFDAILYAUTHORIZED) {
            require(_topupFactorX100 > 100, ERR_TOPUP_LOW);
        }
        TopupConfiguration storage topupConfiguration = topupConfigurations[_inflationReceiver];
        topupConfiguration.topupType = _topupType;
        topupConfiguration.topupFactorX100 = _topupFactorX100;
        topupConfiguration.configured = true;

        emit TopupConfigurationSet(topupConfiguration);
    }

    /**
     * @notice Given an inflation receiver, get the topup configuration.
     * @param _inflationReceiver    The reward service.
     * @return _topupConfiguration  The configurartion of how the topup requests are calculated for a given
     *                              reward service.
     */
    function getTopupConfiguration(
        IIInflationReceiver _inflationReceiver
    )
        external
        notZero(address(_inflationReceiver))
        returns(TopupConfiguration memory _topupConfiguration)
    {
        TopupConfiguration storage topupConfiguration = topupConfigurations[_inflationReceiver];
        if (!topupConfiguration.configured) {
            topupConfiguration.topupType = TopupType.FACTOROFDAILYAUTHORIZED;
            topupConfiguration.topupFactorX100 = DEFAULT_TOPUP_FACTOR_X100;
            topupConfiguration.configured = true;
        }
        _topupConfiguration.topupType = topupConfiguration.topupType;
        _topupConfiguration.topupFactorX100 = topupConfiguration.topupFactorX100;
        _topupConfiguration.configured = topupConfiguration.configured;
    }

    /**
     * @notice Pulsed by the FlareDaemon to trigger timing-based events for the inflation process.
     * @dev There are two events:
     *   1) an annual event to recognize inflation for a new annum
     *   2) a daily event to:
     *     a) authorize mintable inflation for rewarding
     *     b) request minting of enough native tokens to topup reward services for claiming reserves
     */
    function daemonize() external virtual override notZero(address(supply)) onlyFlareDaemon returns(bool) {
        // If inflation rewarding not started yet, blow off processing until it does.
        if (block.timestamp < rewardEpochStartTs) {
            return true;
        }

        // If inflation rewarding started and we have not updated when it started, do so now.
        if (rewardEpochStartedTs == 0) {
            rewardEpochStartedTs = block.timestamp;
        }

        // Is it time to recognize an initial inflation annum?
        if (inflationAnnums.getCount() == 0) {
            _initNewAnnum(block.timestamp);
        } else {
            uint256 currentAnnumEndTimeStamp = inflationAnnums.getCurrentAnnum().endTimeStamp;

            // Is it time to recognize a new inflation annum?
            if (block.timestamp > currentAnnumEndTimeStamp) {
                _initNewAnnum(currentAnnumEndTimeStamp.add(1));
            }
        }

        // Is it time to authorize new inflation? Do it daily.
        if (lastAuthorizationTs.add(AUTHORIZE_TIME_FRAME_SEC) < block.timestamp) {

            // Update time we last authorized.
            lastAuthorizationTs = block.timestamp;

            // Authorize inflation for current sharing percentges.
            uint256 amountAuthorizedWei = inflationAnnums.authorizeDailyInflation(
                block.timestamp,
                inflationSharingPercentageProvider.getSharingPercentages()
            );

            emit InflationAuthorized(amountAuthorizedWei);

            // Call supply contract to keep inflatable balance and circulating supply updated.
            try supply.updateAuthorizedInflationAndCirculatingSupply(amountAuthorizedWei) {
            } catch Error(string memory message) {
                revert(message);
            } catch {
                revert(ERR_SUPPLY_UPDATE);
            }

            // Time to compute topup amount for inflation receivers.
            uint256 topupRequestWei = inflationAnnums.computeTopupRequest(this);

            emit TopupRequested(topupRequestWei);

            // Send mint request to the daemon.
            try flareDaemon.requestMinting(topupRequestWei) {
            } catch Error(string memory message) {
                revert(message);
            } catch {
                revert(ERR_REQUEST_MINT);
            }
        }
        return true;
    }

    function switchToFallbackMode() external view override onlyFlareDaemon returns (bool) {
        // do nothing - there is no fallback mode in Inflation
        return false;
    }

    function _initNewAnnum(uint256 startTs) internal {
        uint256 inflatableSupply = supply.getInflatableBalance();

        try inflationPercentageProvider.getAnnualPercentageBips() returns(uint256 annualPercentBips) {
            inflationAnnums.initializeNewAnnum(startTs, inflatableSupply, annualPercentBips);
        } catch Error(string memory message) {
            revert(message);
        } catch {
            revert(ERR_GET_ANNUAL_PERCENT);
        }

        InflationAnnum.InflationAnnumState memory inflationAnnum = inflationAnnums.getCurrentAnnum();

        emit NewAnnumInitialized(
            inflationAnnum.daysInAnnum, 
            inflationAnnum.startTimeStamp,
            inflationAnnum.endTimeStamp,
            inflatableSupply,
            inflationAnnum.recognizedInflationWei,
            inflationAnnum.rewardServices.totalAuthorizedInflationWei,
            inflationAnnum.rewardServices.totalInflationTopupRequestedWei,
            inflationAnnum.rewardServices.totalInflationTopupReceivedWei,
            inflationAnnum.rewardServices.totalInflationTopupWithdrawnWei
        );
    }

    /**
     * @notice Compute the expected balance of this contract.
     * @param _balanceExpectedWei   The computed balance expected.
     */
    function getExpectedBalance() private view returns(uint256 _balanceExpectedWei) {
        return inflationAnnums.totalInflationTopupReceivedWei        
            .sub(inflationAnnums.totalInflationTopupWithdrawnWei)
            .add(totalSelfDestructReceivedWei)
            .sub(totalSelfDestructWithdrawnWei);
    }
}

// SPDX-License-Identifier: MIT
// WARNING, WARNING, WARNING
// If you modify this contract, you need to re-install the binary into the validator 
// genesis file for the chain you wish to run. See ./docs/CompilingContracts.md for more information.
// You have been warned. That is all.
pragma solidity 0.7.6;
pragma abicoder v2;

import "../../governance/implementation/GovernedAtGenesis.sol";
import "../interface/IInflationGenesis.sol";
import "../interface/IFlareDaemonize.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../utils/implementation/SafePct.sol";


/**
 * @title Flare Daemon contract
 * @notice This contract exists to coordinate regular daemon-like polling of contracts
 *   that are registered to receive said polling. The trigger method is called by the 
 *   validator right at the end of block state transition.
 */
contract FlareDaemon is GovernedAtGenesis {
    using SafeMath for uint256;
    using SafePct for uint256;

    //====================================================================
    // Data Structures
    //====================================================================
    struct DaemonizedError {
        uint192 lastErrorBlock;
        uint64 numErrors;
        address fromContract;
        uint64 errorTypeIndex;
        string errorMessage;
    }

    struct LastErrorData {
        uint192 totalDaemonizedErrors;
        uint64 lastErrorTypeIndex;
    }

    struct Registration {
        IFlareDaemonize daemonizedContract;
        uint256 gasLimit;
    }

    string internal constant ERR_OUT_OF_BALANCE = "out of balance";
    string internal constant ERR_NOT_INFLATION = "not inflation";
    string internal constant ERR_TOO_MANY = "too many";
    string internal constant ERR_TOO_BIG = "too big";
    string internal constant ERR_TOO_OFTEN = "too often";
    string internal constant ERR_INFLATION_ZERO = "inflation zero";
    string internal constant ERR_BLOCK_NUMBER_SMALL = "block.number small";
    string internal constant INDEX_TOO_HIGH = "start index high";
    string internal constant UPDATE_GAP_TOO_SHORT = "time gap too short";
    string internal constant MAX_MINT_TOO_HIGH = "max mint too high";
    string internal constant MAX_MINT_IS_ZERO = "max mint is zero";
    string internal constant ERR_DUPLICATE_ADDRESS = "dup address";
    string internal constant ERR_ADDRESS_ZERO = "address zero";
    string internal constant ERR_OUT_OF_GAS = "out of gas";
    string internal constant ERR_INFLATION_MINT_RECEIVE_FAIL = "unknown error. receiveMinting";

    uint256 internal constant MAX_DAEMONIZE_CONTRACTS = 10;
    // Initial max mint request - 50 million native token
    uint256 internal constant MAX_MINTING_REQUEST_DEFAULT = 50000000 ether;
    // How often can inflation request minting from the validator - 23 hours constant
    uint256 internal constant MAX_MINTING_FREQUENCY_SEC = 23 hours;
    // How often can the maximal mint request amount be updated
    uint256 internal constant MAX_MINTING_REQUEST_FREQUENCY_SEC = 24 hours;
    // By how much can the maximum be increased (as a percentage of the previous maximum)
    uint256 internal constant MAX_MINTING_REQUEST_INCREASE_PERCENT = 110;
    // upper estimate of gas needed after error occurs in call to daemonizedContract.daemonize()
    uint256 internal constant MIN_GAS_LEFT_AFTER_DAEMONIZE = 300000;
    // lower estimate for gas needed for daemonize() call in trigger
    uint256 internal constant MIN_GAS_FOR_DAEMONIZE_CALL = 5000;

    IInflationGenesis public inflation;
    uint256 public systemLastTriggeredAt;
    uint256 public totalMintingRequestedWei;
    uint256 public totalMintingReceivedWei;
    uint256 public totalMintingWithdrawnWei;
    uint256 public totalSelfDestructReceivedWei;
    uint256 public maxMintingRequestWei;
    uint256 public lastMintRequestTs;
    uint256 public lastUpdateMaxMintRequestTs;
    LastErrorData public errorData;
    uint256 public blockHoldoff;

    uint256 private lastBalance;
    uint256 private expectedMintRequest;
    bool private initialized;

    // track deamonized contracts
    IFlareDaemonize[] internal daemonizeContracts;
    mapping (IFlareDaemonize => uint256) internal gasLimits;
    mapping (IFlareDaemonize => uint256) internal blockHoldoffsRemaining;

    // track daemonize errors
    mapping(bytes32 => DaemonizedError) internal daemonizedErrors;
    bytes32 [] internal daemonizeErrorHashes;

    event ContractDaemonized(address theContract, uint256 gasConsumed);
    event ContractDaemonizeErrored(address theContract, uint256 atBlock, string theMessage, uint256 gasConsumed);
    event ContractHeldOff(address theContract, uint256 blockHoldoffsRemaining);
    event ContractsSkippedOutOfGas(uint256 numberOfSkippedConstracts);
    event MintingRequested(uint256 amountWei);
    event MintingReceived(uint256 amountWei);
    event MintingWithdrawn(uint256 amountWei);
    event RegistrationUpdated(IFlareDaemonize theContract, bool add);
    event SelfDestructReceived(uint256 amountWei);
    event InflationSet(IInflationGenesis theNewContract, IInflationGenesis theOldContract);

    /**
     * @dev As there is not a constructor, this modifier exists to make sure the inflation
     *   contract is set for methods that require it.
     */
    modifier inflationSet {
        // Don't revert...just report.
        if (address(inflation) == address(0)) {
            addDaemonizeError(address(this), ERR_INFLATION_ZERO, 0);
        }
        _;
    }

    /**
     * @dev This modifier ensures that this contract's balance matches the expected balance.
     */
    modifier mustBalance {
        _;
        // We should be in balance - don't revert, just report...
        uint256 contractBalanceExpected = getExpectedBalance();
        if (contractBalanceExpected != address(this).balance) {
            addDaemonizeError(address(this), ERR_OUT_OF_BALANCE, 0);
        }
    }

    /**
     * @dev Access control to protect methods to allow only minters to call select methods
     *   (like transferring balance out).
     */
    modifier onlyInflation (address _inflation) {
        require (address(inflation) == _inflation, ERR_NOT_INFLATION);
        _;
    }
    
    /**
     * @dev Access control to protect trigger() method. 
     * Please note that the sender address is the same as deployed FlareDaemon address in this case.
     */
    modifier onlySystemTrigger {
        require (msg.sender == 0x1000000000000000000000000000000000000002);
        _;
    }

    //====================================================================
    // Constructor for pre-compiled code
    //====================================================================

    /**
     * @dev This constructor should contain no code as this contract is pre-loaded into the genesis block.
     *   The super constructor is called for testing convenience.
     */
    constructor() GovernedAtGenesis(address(0)) {
        /* empty block */
    }

    //====================================================================
    // Functions
    //====================================================================  

    /**
     * @notice Register contracts to be polled by the daemon process.
     * @param _registrations    An array of Registration structures of IFlareDaemonize contracts to daemonize
     *                          and gas limits for each contract.
     * @dev A gas limit of zero will set no limit for the contract but the validator has an overall
     *   limit for the trigger() method.
     * @dev If any registrations already exist, they will be unregistered.
     * @dev Contracts will be daemonized in the order in which presented via the _registrations array.
     */
    function registerToDaemonize(Registration[] calldata _registrations) external onlyGovernance {
        // Make sure there are not too many contracts to register.
        uint256 registrationsLength = _registrations.length;
        require(registrationsLength <= MAX_DAEMONIZE_CONTRACTS, ERR_TOO_MANY);

        // Unregister everything first
        _unregisterAll();

        // Loop over all contracts to register
        for (uint256 registrationIndex = 0; registrationIndex < registrationsLength; registrationIndex++) {
            // Address cannot be zero
            require(address(_registrations[registrationIndex].daemonizedContract) != address(0), ERR_ADDRESS_ZERO);

            uint256 daemonizeContractsLength = daemonizeContracts.length;
            // Make sure no dups...yes, inefficient. Registration should not be done often.
            for (uint256 i = 0; i < daemonizeContractsLength; i++) {
                require(_registrations[registrationIndex].daemonizedContract != daemonizeContracts[i], 
                    ERR_DUPLICATE_ADDRESS); // already registered
            }
            // Store off the registered contract to daemonize, in the order presented.
            daemonizeContracts.push(_registrations[registrationIndex].daemonizedContract);
            // Record the gas limit for the contract.
            gasLimits[_registrations[registrationIndex].daemonizedContract] = 
                _registrations[registrationIndex].gasLimit;
            // Clear any blocks being held off for the given contract, if any. Contracts may be re-presented
            // if only order is being modified, for example.
            blockHoldoffsRemaining[_registrations[registrationIndex].daemonizedContract] = 0;
            emit RegistrationUpdated (_registrations[registrationIndex].daemonizedContract, true);
        }
    }

    /**
     * @notice Queue up a minting request to send to the validator at next trigger.
     * @param _amountWei    The amount to mint.
     */
    function requestMinting(uint256 _amountWei) external onlyInflation(msg.sender) {
        require(_amountWei <= maxMintingRequestWei, ERR_TOO_BIG);
        require(_getNextMintRequestAllowedTs() < block.timestamp, ERR_TOO_OFTEN);
        if (_amountWei > 0) {
            lastMintRequestTs = block.timestamp;
            totalMintingRequestedWei = totalMintingRequestedWei.add(_amountWei);
            emit MintingRequested(_amountWei);
        }
    }

    /**
     * @notice Set number of blocks that must elapse before a daemonized contract exceeding gas limit can have
     *   its daemonize() method called again.
     * @param _blockHoldoff    The number of blocks to holdoff.
     */
    function setBlockHoldoff(uint256 _blockHoldoff) external onlyGovernance {
        blockHoldoff = _blockHoldoff;
    }

    /**
     * @notice Set limit on how much can be minted per request.
     * @param _maxMintingRequestWei    The request maximum in wei.
     * @notice this number can't be udated too often
     */
    function setMaxMintingRequest(uint256 _maxMintingRequestWei) external onlyGovernance {
        // make sure increase amount is reasonable
        require(
            _maxMintingRequestWei <= (maxMintingRequestWei.mulDiv(MAX_MINTING_REQUEST_INCREASE_PERCENT,100)),
            MAX_MINT_TOO_HIGH
        );
        require(_maxMintingRequestWei > 0, MAX_MINT_IS_ZERO);
        // make sure enough time since last update
        require(
            block.timestamp > lastUpdateMaxMintRequestTs + MAX_MINTING_REQUEST_FREQUENCY_SEC,
            UPDATE_GAP_TOO_SHORT
        );

        maxMintingRequestWei = _maxMintingRequestWei;
        lastUpdateMaxMintRequestTs = block.timestamp;
    }

    /**
     * @notice Sets the inflation contract, which will receive minted inflation funds for funding to
     *   rewarding contracts.
     * @param _inflation   The inflation contract.
     */
    function setInflation(IInflationGenesis _inflation) external onlyGovernance {
        require(address(_inflation) != address(0), ERR_INFLATION_ZERO);
        emit InflationSet(inflation, _inflation);
        inflation = _inflation;
        if (maxMintingRequestWei == 0) {
            maxMintingRequestWei = MAX_MINTING_REQUEST_DEFAULT;
        }
    }

    /**
     * @notice The meat of this contract. Poll all registered contracts, calling the daemonize() method of each,
     *   in the order in which registered.
     * @return  _toMintWei     Return the amount to mint back to the validator. The asked for balance will show
     *                          up in the next block (it is actually added right before this block's state transition,
     *                          but well after this method call will see it.)
     * @dev This method watches for balances being added to this contract and handles appropriately - legit
     *   mint requests as made via requestMinting, and also self-destruct sending to this contract, should
     *   it happen for some reason.
     */
    //slither-disable-next-line reentrancy-eth      // method protected by reentrancy guard (see comment below)
    function trigger() external virtual inflationSet mustBalance onlySystemTrigger returns (uint256 _toMintWei) {
        return triggerInternal();
    }
    
    /**
     * @notice Unregister all contracts from being polled by the daemon process.
     */
    function unregisterAll() external onlyGovernance {
        _unregisterAll();
    }

    function getDaemonizedContractsData() external view 
        returns(
            IFlareDaemonize[] memory _daemonizeContracts,
            uint256[] memory _gasLimits,
            uint256[] memory _blockHoldoffsRemaining
        )
    {
        uint256 len = daemonizeContracts.length;
        _daemonizeContracts = new IFlareDaemonize[](len);
        _gasLimits = new uint256[](len);
        _blockHoldoffsRemaining = new uint256[](len);

        for (uint256 i; i < len; i++) {
            IFlareDaemonize daemonizeContract = daemonizeContracts[i];
            _daemonizeContracts[i] = daemonizeContract;
            _gasLimits[i] = gasLimits[daemonizeContract];
            _blockHoldoffsRemaining[i] = blockHoldoffsRemaining[daemonizeContract];
        }
    }

    function getNextMintRequestAllowedTs() external view returns(uint256) {
        return _getNextMintRequestAllowedTs();
    }

    function showLastDaemonizedError () external view 
        returns(
            uint256[] memory _lastErrorBlock,
            uint256[] memory _numErrors,
            string[] memory _errorString,
            address[] memory _erroringContract,
            uint256 _totalDaemonizedErrors
        )
    {
        return showDaemonizedErrors(errorData.lastErrorTypeIndex, 1);
    }

    /**
     * @notice Set the governance address to a hard-coded known address.
     * @dev This should be done at contract deployment time.
     * @return The governance address.
     */
    function initialiseFixedAddress() public override returns(address) {
        if (!initialized) {
            initialized = true;
            address governanceAddress = super.initialiseFixedAddress();
            return governanceAddress;
        } else {
            return governance;
        }
    }

    function showDaemonizedErrors (uint startIndex, uint numErrorTypesToShow) public view 
        returns(
            uint256[] memory _lastErrorBlock,
            uint256[] memory _numErrors,
            string[] memory _errorString,
            address[] memory _erroringContract,
            uint256 _totalDaemonizedErrors
        )
    {
        require(startIndex < daemonizeErrorHashes.length, INDEX_TOO_HIGH);
        uint256 numReportElements = 
            daemonizeErrorHashes.length >= startIndex + numErrorTypesToShow ?
            numErrorTypesToShow :
            daemonizeErrorHashes.length - startIndex;

        _lastErrorBlock = new uint256[] (numReportElements);
        _numErrors = new uint256[] (numReportElements);
        _errorString = new string[] (numReportElements);
        _erroringContract = new address[] (numReportElements);

        // we have error data error type.
        // error type is hash(error_string, source contract)
        // per error type we report how many times it happened.
        // what was last block it happened.
        // what is the error string.
        // what is the erroring contract
        for (uint i = 0; i < numReportElements; i++) {
            bytes32 hash = daemonizeErrorHashes[startIndex + i];

            _lastErrorBlock[i] = daemonizedErrors[hash].lastErrorBlock;
            _numErrors[i] = daemonizedErrors[hash].numErrors;
            _errorString[i] = daemonizedErrors[hash].errorMessage;
            _erroringContract[i] = daemonizedErrors[hash].fromContract;
        }
        _totalDaemonizedErrors = errorData.totalDaemonizedErrors;
    }

    /**
     * @notice Implementation of the trigger() method. The external wrapper has extra guard for msg.sender.
     */
    //slither-disable-next-line reentrancy-eth      // method protected by reentrancy guard (see comment below)
    function triggerInternal() internal returns (uint256 _toMintWei) {
        // only one trigger() call per block allowed
        // this also serves as reentrancy guard, since any re-entry will happen in the same block
        require(block.number > systemLastTriggeredAt, ERR_BLOCK_NUMBER_SMALL);
        systemLastTriggeredAt = block.number;

        uint256 currentBalance = address(this).balance;

        // Did the validator or a self-destructor conjure some native token?
        if (currentBalance > lastBalance) {
            uint256 balanceExpected = lastBalance.add(expectedMintRequest);
            // Did we get what was last asked for?
            if (currentBalance == balanceExpected) {
                // Yes, so assume it all came from the validator.
                uint256 minted = expectedMintRequest;
                totalMintingReceivedWei = totalMintingReceivedWei.add(minted);
                emit MintingReceived(minted);
                //slither-disable-next-line arbitrary-send          // only sent to inflation, set by governance
                try inflation.receiveMinting{ value: minted }() {
                    totalMintingWithdrawnWei = totalMintingWithdrawnWei.add(minted);
                    emit MintingWithdrawn(minted);
                } catch Error(string memory message) {
                    addDaemonizeError(address(this), message, 0);
                } catch {
                    addDaemonizeError(address(this), ERR_INFLATION_MINT_RECEIVE_FAIL, 0);
                }
            } else if (currentBalance < balanceExpected) {
                // No, and if less, there are two possibilities: 1) the validator did not
                // send us what we asked (not possible unless a bug), or 2) an attacker
                // sent us something in between a request and a mint. Assume 2.
                uint256 selfDestructReceived = currentBalance.sub(lastBalance);
                totalSelfDestructReceivedWei = totalSelfDestructReceivedWei.add(selfDestructReceived);
                emit SelfDestructReceived(selfDestructReceived);
            } else {
                // No, so assume we got a minting request (perhaps zero...does not matter)
                // and some self-destruct proceeds (unlikely but can happen).
                totalMintingReceivedWei = totalMintingReceivedWei.add(expectedMintRequest);
                uint256 selfDestructReceived = currentBalance.sub(lastBalance).sub(expectedMintRequest);
                totalSelfDestructReceivedWei = totalSelfDestructReceivedWei.add(selfDestructReceived);
                emit MintingReceived(expectedMintRequest);
                emit SelfDestructReceived(selfDestructReceived);
                //slither-disable-next-line arbitrary-send          // only sent to inflation, set by governance
                try inflation.receiveMinting{ value: expectedMintRequest }() {
                    totalMintingWithdrawnWei = totalMintingWithdrawnWei.add(expectedMintRequest);
                    emit MintingWithdrawn(expectedMintRequest);
                } catch Error(string memory message) {
                    addDaemonizeError(address(this), message, 0);
                } catch {
                    addDaemonizeError(address(this), ERR_INFLATION_MINT_RECEIVE_FAIL, 0);
                }
            }
        }

        uint256 len = daemonizeContracts.length;

        // Perform trigger operations here
        for (uint256 i = 0; i < len; i++) {
            IFlareDaemonize daemonizedContract = daemonizeContracts[i];
            uint256 blockHoldoffRemainingForContract = blockHoldoffsRemaining[daemonizedContract];
            if (blockHoldoffRemainingForContract > 0) {
                blockHoldoffsRemaining[daemonizedContract] = blockHoldoffRemainingForContract - 1;
                emit ContractHeldOff(address(daemonizedContract), blockHoldoffRemainingForContract);
            } else {
                // Figure out what gas to limit call by
                uint256 gasLimit = gasLimits[daemonizedContract];
                uint256 startGas = gasleft();
                // End loop if there isn't enough gas left for any daemonize call
                if (startGas < MIN_GAS_LEFT_AFTER_DAEMONIZE + MIN_GAS_FOR_DAEMONIZE_CALL) {
                    emit ContractsSkippedOutOfGas(len - i);
                    break;
                }
                // Calculate the gas limit for the next call
                uint256 useGas = startGas - MIN_GAS_LEFT_AFTER_DAEMONIZE;
                if (gasLimit > 0 && gasLimit < useGas) {
                    useGas = gasLimit;
                }
                // Run daemonize for the contract, consume errors, and record
                try daemonizedContract.daemonize{gas: useGas}() {
                    emit ContractDaemonized(address(daemonizedContract), (startGas - gasleft()));
                // Catch all requires with messages
                } catch Error(string memory message) {
                    addDaemonizeError(address(daemonizedContract), message, (startGas - gasleft()));
                    daemonizedContract.switchToFallbackMode();
                // Catch everything else...out of gas, div by zero, asserts, etc.
                } catch {
                    uint256 endGas = gasleft();
                    // Interpret out of gas errors
                    if (gasLimit > 0 && startGas.sub(endGas) >= gasLimit) {
                        addDaemonizeError(address(daemonizedContract), ERR_OUT_OF_GAS, (startGas - endGas));
                        // When daemonize() fails with out-of-gas, try to fix it in two steps:
                        // 1) try to switch contract to fallback mode
                        //    (to allow the contract's daemonize() to recover in fallback mode in next block)
                        // 2) if constract is already in fallback mode or fallback mode is not supported
                        //    (switchToFallbackMode() returns false), start the holdoff for this contract
                        bool switchedToFallback = daemonizedContract.switchToFallbackMode();
                        if (!switchedToFallback) {
                            blockHoldoffsRemaining[daemonizedContract] = blockHoldoff;
                        }
                    } else {
                        // Don't know error cause...just log it as unknown
                        addDaemonizeError(address(daemonizedContract), "unknown", (startGas - endGas));
                        daemonizedContract.switchToFallbackMode();
                    }
                }
            }
        }

        // Get any requested minting and return to validator
        _toMintWei = getPendingMintRequest();
        if (_toMintWei > 0) {
            expectedMintRequest = _toMintWei;
            emit MintingRequested(_toMintWei);
        } else {
            expectedMintRequest = 0;            
        }

        lastBalance = address(this).balance;
    }

    function addDaemonizeError(address daemonizedContract, string memory message, uint256 gasConsumed) internal {
        bytes32 errorStringHash = keccak256(abi.encode(daemonizedContract, message));

        DaemonizedError storage daemonizedError = daemonizedErrors[errorStringHash];
        if (daemonizedError.numErrors == 0) {
            // first time we recieve this error string.
            daemonizeErrorHashes.push(errorStringHash);
            daemonizedError.fromContract = daemonizedContract;
            // limit message length to fit in fixed number of storage words (to make gas usage predictable)
            daemonizedError.errorMessage = truncateString(message, 64);
            daemonizedError.errorTypeIndex = uint64(daemonizeErrorHashes.length - 1);
        }
        daemonizedError.numErrors += 1;
        daemonizedError.lastErrorBlock = uint192(block.number);
        emit ContractDaemonizeErrored(daemonizedContract, block.number, message, gasConsumed);

        errorData.totalDaemonizedErrors += 1;
        errorData.lastErrorTypeIndex = daemonizedError.errorTypeIndex;        
    }

    /**
     * @notice Unregister all contracts from being polled by the daemon process.
     */
    function _unregisterAll() private {

        uint256 len = daemonizeContracts.length;

        for (uint256 i = 0; i < len; i++) {
            IFlareDaemonize daemonizedContract = daemonizeContracts[daemonizeContracts.length - 1];
            daemonizeContracts.pop();
            emit RegistrationUpdated (daemonizedContract, false);
        }
    }

    /**
     * @notice Net totals to obtain the expected balance of the contract.
     */
    function getExpectedBalance() private view returns(uint256 _balanceExpectedWei) {
        _balanceExpectedWei = totalMintingReceivedWei.
            sub(totalMintingWithdrawnWei).
            add(totalSelfDestructReceivedWei);
    }

    /**
     * @notice Net total received from total requested.
     */
    function getPendingMintRequest() private view returns(uint256 _mintRequestPendingWei) {
        _mintRequestPendingWei = totalMintingRequestedWei.sub(totalMintingReceivedWei);
    }


    function _getNextMintRequestAllowedTs() internal view returns (uint256) {
        return (lastMintRequestTs + MAX_MINTING_FREQUENCY_SEC);
    }

    function truncateString(string memory _str, uint256 _maxlength) private pure returns (string memory) {
        bytes memory strbytes = bytes(_str);
        if (strbytes.length <= _maxlength) {
            return _str;
        }
        bytes memory result = new bytes(_maxlength);
        for (uint256 i = 0; i < _maxlength; i++) {
            result[i] = strbytes[i];
        }
        return string(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


/// Any contracts that want to recieve a trigger from Flare daemon should 
///     implement IFlareDaemonize
interface IFlareDaemonize {

    /// Implement this function for recieving a trigger from FlareDaemon.
    function daemonize() external returns (bool);
    
    /// This function will be called after an error is caught in daemonize().
    /// It will switch the contract to a simpler fallback mode, which hopefully works when full mode doesn't.
    /// Not every contract needs to support fallback mode (FtsoManager does), so this method may be empty.
    /// Switching back to normal mode is left to the contract (typically a governed method call).
    /// This function may be called due to low-gas error, so it shouldn't use more than ~30.000 gas.
    /// @return true if switched to fallback mode, false if already in fallback mode or if falback not supported
    function switchToFallbackMode() external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


interface IInflationGenesis {
    /**
     * @notice Receive newly minted native tokens from the FlareDaemon.
     * @dev Assume that the amount received will be >= last topup requested across all services.
     *   If there is not enough balance sent to cover the topup request, expect library method will revert.
     *   Also assume that any balance received greater than the topup request calculated
     *   came from self-destructor sending a balance to this contract.
     */
    function receiveMinting() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
import { FlareDaemon } from "../../genesis/implementation/FlareDaemon.sol";
import { Governed } from "../../governance/implementation/Governed.sol";


contract GovernedAndFlareDaemonized is Governed {

    FlareDaemon public immutable flareDaemon;

    modifier onlyFlareDaemon () {
        require (msg.sender == address(flareDaemon), "only flare daemon");
        _;
    }

    constructor(address _governance, FlareDaemon _flareDaemon) Governed(_governance) {
        require(address(_flareDaemon) != address(0), "flare daemon zero");
        flareDaemon = _flareDaemon;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../../utils/implementation/DateTimeLibrary.sol";
import "./RewardServices.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../utils/implementation/SafePct.sol";


/**
 * @title Inflation Annum library
 * @notice A library to manage an inflation annum. 
 **/
library InflationAnnum {    
    using BokkyPooBahsDateTimeLibrary for uint256;
    using InflationAnnum for InflationAnnum.InflationAnnumState;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SafePct for uint256;

    /**
     * @dev `InflationAnnumState` is state structure used by this library to manage
     *   an inflation annum.
     */
    struct InflationAnnumState {
        uint256 recognizedInflationWei;
        uint16 daysInAnnum;
        uint256 startTimeStamp;
        uint256 endTimeStamp;
        RewardServices.RewardServicesState rewardServices;
    }

    uint256 internal constant BIPS100 = 1e4;                            // 100% in basis points

    /**
     * @notice Helper function to compute recognized inflation.
     * @param _inflatableBalance                The balance used to recognize inflation.
     * @param _annualInflationPercentageBips    The annual percentage used to recognize inflation.
     * @return The computed recognized inflation.
     */
    function _computeRecognizedInflationWei(
        uint256 _inflatableBalance, 
        uint256 _annualInflationPercentageBips
    ) 
        internal pure
        returns(uint256)
    {
        return _inflatableBalance.mulDiv(
            _annualInflationPercentageBips, 
            BIPS100);
    }

    /**
     * @notice Helper function to compute the number of days in an annum.
     * @param _startTimeStamp   The start time of the annum in question.
     * @return  The number of days in the annum.
     */
    function _computeDaysInAnnum(uint256 _startTimeStamp, uint256 _endTimeStamp) internal pure returns(uint16) { 
        uint256 daysInAnnum = _startTimeStamp.diffDays(_endTimeStamp.add(1));
        return daysInAnnum.toUint16();
    }

    /**
     * @notice Helper function to compute the number of days remaining in an annum.
     * @param _atTimeStamp  Compute the number of days for the annum at this time stamp.
     * @return The number of days computed.
     * @dev If _atTimeStamp is after the end of the annum, 0 days will be returned.
     */
    function _computeDaysRemainingInAnnum(
        InflationAnnumState storage _self, 
        uint256 _atTimeStamp
    )
        internal view
        returns(uint256)
    {
        uint256 endTimeStamp = _self.endTimeStamp;
        if (_atTimeStamp > endTimeStamp) {
            return 0;
        } else {
            return _atTimeStamp.diffDays(endTimeStamp);
        }
    }

    /**
     * @notice Given a start time stamp, compute the end time stamp for an annum.
     * @param _startTimeStamp The start time stamp for an annum.
     * @return The end time stamp for the annum.
     */
    function _getAnnumEndsTs(uint256 _startTimeStamp) internal pure returns (uint256) {
        // This should cover passing through Feb 29
        return _startTimeStamp.addYears(1).subSeconds(1);
    }

    /**
     * @notice Compute the number of periods remaining within an annum.
     * @param _atTimeStamp  Compute periods remaining at this time stamp.
     * @return The number of periods remaining.
     * @dev The number of periods must include the current day.
     */
    function getPeriodsRemaining(
        InflationAnnumState storage _self, 
        uint256 _atTimeStamp
    )
        internal view 
        returns(uint256)
    {
        assert(_atTimeStamp <= _self.endTimeStamp);
        // Add 1 to the periods remaining because the difference between days does not count the current day.
        return _computeDaysRemainingInAnnum(_self, _atTimeStamp).add(1);
    }

    /**
     * @notice Initialize a new annum data structure.
     * @param _startTimeStamp       The start time stamp of the new annum.
     * @param _inflatableBalanceWei The inflatable balance used to calculate recognized inflation for the new annum.
     * @param _annualInflationPercentageBips The annual inflation percentage in bips to calc recognized inflation.
     * @dev A newly created InflationAnnumState is expected to exist.
     */
    function initialize(
        InflationAnnumState storage _self,
        uint256 _startTimeStamp, 
        uint256 _inflatableBalanceWei, 
        uint256 _annualInflationPercentageBips
    ) 
        internal
    {
        _self.startTimeStamp = _startTimeStamp;
        _self.recognizedInflationWei = _computeRecognizedInflationWei(
            _inflatableBalanceWei, 
            _annualInflationPercentageBips);
        _self.endTimeStamp = _getAnnumEndsTs(_startTimeStamp);
        _self.daysInAnnum = _computeDaysInAnnum(_startTimeStamp, _self.endTimeStamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../implementation/Inflation.sol";
import "./InflationAnnum.sol";
import "./RewardServices.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../utils/implementation/SafePct.sol";
import "../interface/IIInflationSharingPercentageProvider.sol";


/**
 * @title Inflation Annums library
 * @notice A library to manage a collection of inflation annum and associated totals.
 * @dev Operations such as authorizing daily inflation are dispatched from this collection
 *  library because the result of the authorization is added to the total authorized across
 *  all annums, which is a concern of this library and not the concern of a given annum, nor the caller.
 **/
library InflationAnnums {    
    using InflationAnnum for InflationAnnum.InflationAnnumState;
    using RewardServices for RewardServices.RewardServicesState;
    using SafeMath for uint256;
    using SafePct for uint256;

    /**
     * @dev `InflationAnnumsState` is state structure used by this library to manage
     *   a collection of inflation annums and associated totals.
     */
    struct InflationAnnumsState {
        // Collection of annums
        InflationAnnum.InflationAnnumState[] inflationAnnums;
        uint256 currentAnnum;
        // Balances
        uint256 totalRecognizedInflationWei;
        uint256 totalAuthorizedInflationWei;
        uint256 totalInflationTopupRequestedWei;
        uint256 totalInflationTopupReceivedWei;
        uint256 totalInflationTopupWithdrawnWei;
    }

    string internal constant ERR_NO_ANNUM = "no annum";
    string internal constant ERR_TOO_EARLY = "too early";

    /**
     * @notice Dispatch inflation authorization to be performed across all reward services according to their
     *   sharing percentage for the current annum, and then maintain sum total of inflation
     *   authorized across all annums.
     * @param _atTimeStamp  The timestamp at which the number of daily periods remaining in the current
     *   annum will be calculated.
     * @param _sharingPercentages   An array of the sharing percentages by inflation receiver used to
     *   allocate authorized inflation.
     * @return _amountAuthorizedWei The amount of inflation authorized for this authorization cycle.
     * @dev Invariant: total inflation authorized cannot be greater than total inflation recognized. 
     */
    function authorizeDailyInflation(
        InflationAnnumsState storage _self,
        uint256 _atTimeStamp, 
        SharingPercentage[] memory _sharingPercentages
    ) 
        internal
        returns(uint256 _amountAuthorizedWei)
    {
        // Get the current annum
        InflationAnnum.InflationAnnumState storage currentAnnum = getCurrentAnnum(_self);

        // Authorize daily inflation for the current annum, across reward services, given
        // sharing percentages.
        _amountAuthorizedWei = currentAnnum.rewardServices.authorizeDailyInflation(
            _self.totalRecognizedInflationWei,
            _self.totalAuthorizedInflationWei, 
            currentAnnum.getPeriodsRemaining(_atTimeStamp), 
            _sharingPercentages);
        // Accumulate total authorized inflation across all annums
        _self.totalAuthorizedInflationWei = _self.totalAuthorizedInflationWei.add(_amountAuthorizedWei);
        // Make sure that total authorized never exceeds total recognized
        assert(_self.totalAuthorizedInflationWei <= _self.totalRecognizedInflationWei);
    }

    /**
     * @notice Dispatch topup request calculations across reward services and sum up total mint request made
     *   to fund topup of reward services.
     * @param _inflation    The Inflation contract containing the topup confguration of each reward service.
     * @return _topupRequestWei The amount of native token requested to be minted across reward services for 
     *   this cycle.
     * @dev Invariant: total inflation topup requested cannot exceed total inflation authorized
     */
    function computeTopupRequest(
        InflationAnnumsState storage _self,
        Inflation _inflation
    )
        internal
        returns(uint256 _topupRequestWei)
    {
        // Get the current annum
        InflationAnnum.InflationAnnumState storage currentAnnum = getCurrentAnnum(_self);
        // Compute the topup
        _topupRequestWei = currentAnnum.rewardServices.computeTopupRequest(_inflation);
        // Sum the topup request total across annums
        _self.totalInflationTopupRequestedWei = _self.totalInflationTopupRequestedWei.add(_topupRequestWei);
        // Make sure that total topup requested can never exceed inflation authorized
        assert(_self.totalInflationTopupRequestedWei <= _self.totalAuthorizedInflationWei);
    }

    /**
     * @notice Receive minted native tokens (and fund) to satisfy reward services topup requests.
     * @return _amountPostedWei The native tokens posted (funded) to reward service contracts.
     * @dev Invariants:
     *   1) Native tokens topup received cannot exceed native tokens topup requested
     *   2) Native tokens topup withdrawn for funding cannot exceed native tokens topup received
     */
    function receiveTopupRequest(
        InflationAnnumsState storage _self
    )
        internal
        returns(uint256 _amountPostedWei)
    {
        // Get the current annum
        InflationAnnum.InflationAnnumState storage currentAnnum = getCurrentAnnum(_self);

        // Receive minting of topup request. Post to received and withdrawn buckets for each reward service.
        _amountPostedWei = currentAnnum.rewardServices.receiveTopupRequest();
        // Post the amount of native tokens received into the Inflation contract
        _self.totalInflationTopupReceivedWei = _self.totalInflationTopupReceivedWei.add(_amountPostedWei);
        // Received should never be more than requested
        assert(_self.totalInflationTopupReceivedWei <= _self.totalInflationTopupRequestedWei);
        // Post amount withdrawn and transferred to reward service contracts
        _self.totalInflationTopupWithdrawnWei = _self.totalInflationTopupWithdrawnWei.add(_amountPostedWei);
        // Withdrawn should never be more than received
        assert(_self.totalInflationTopupWithdrawnWei <= _self.totalInflationTopupReceivedWei);
    }

    /**
     * @notice Get the number of inflation annums.
     * @return The count.
     */
    function getCount(InflationAnnumsState storage _self) internal view returns(uint256) {
        return _self.inflationAnnums.length;
    }

    /**
     * @notice Given an index, return a given inflation annum data.
     * @param _index    The index of the annum to fetch.
     * @return _inflationAnnum  Returns InflationAnnum.InflationAnnumState found at _index.
     * @dev Will revert if index not found.
     */
    function getAnnum(
        InflationAnnumsState storage _self,
        uint256 _index
    )
        internal view
        returns (InflationAnnum.InflationAnnumState storage _inflationAnnum)
    {
        require(_index < getCount(_self), ERR_NO_ANNUM);
        _inflationAnnum = _self.inflationAnnums[_index];
    }

    /**
     * @notice Return inflation annum data for the current annum.
     * @return _inflationAnnum  Returns InflationAnnum.InflationAnnumState for the current annum.
     * @dev Will revert if no current annum.
     */
    function getCurrentAnnum(
        InflationAnnumsState storage _self
    )
        internal view 
        returns (InflationAnnum.InflationAnnumState storage _inflationAnnum)
    {
        require(getCount(_self) > 0, ERR_NO_ANNUM);
        _inflationAnnum = _self.inflationAnnums[_self.currentAnnum];
    }

    /**
     * @notice Initialize a new annum, add it to the annum collection, maintian running total
     *   of recognized inflation resulting from new annum, and set current annum pointer.
     * @param _startTimeStamp                   The timestamp to start the annum.
     * @param _inflatableBalance                The balance to use when recognizing inflation for the annum.
     * @param _annualInflationPercentageBips    The inflation percentage in bips to use when recognizing inflation.
     */
    function initializeNewAnnum(
        InflationAnnumsState storage _self,
        uint256 _startTimeStamp, 
        uint256 _inflatableBalance, 
        uint256 _annualInflationPercentageBips
    ) 
        internal
    {
        // Start time cannot be before last annum ends
        if (getCount(_self) > 0) {
            require(_startTimeStamp > getCurrentAnnum(_self).endTimeStamp, ERR_TOO_EARLY);
        }
        // Create an empty annum
        InflationAnnum.InflationAnnumState storage inflationAnnum = _self.inflationAnnums.push();
        // Initialize it with newly passed in annum info
        inflationAnnum.initialize(_startTimeStamp, _inflatableBalance, _annualInflationPercentageBips);
        // Accumulate total recognized inflation across annums 
        _self.totalRecognizedInflationWei = 
            _self.totalRecognizedInflationWei.add(inflationAnnum.recognizedInflationWei);
        // Reposition index pointing to current annum
        if (_self.inflationAnnums.length > 1) {
            _self.currentAnnum = _self.currentAnnum.add(1);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IIInflationPercentageProvider {
    /**
     * Return the annual inflation rate in bips.
     */
    function getAnnualPercentageBips() external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IIInflationReceiver {
    /**
     * Notify the receiver that it is entitled to receive `_toAuthorizeWei` inflation amount.
     * @param _toAuthorizeWei the amount of inflation that can be awarded in the coming day
     */
    function setDailyAuthorizedInflation(uint256 _toAuthorizeWei) external;
    
    /**
     * Receive native tokens from inflation.
     */
    function receiveInflation() external payable;

    /**
     * Inflation receivers have a reference to the Inflation contract.
     */
    function getInflationAddress() external returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../interface/IIInflationReceiver.sol";

struct SharingPercentage {
    IIInflationReceiver inflationReceiver;
    uint256 percentBips;
}

interface IIInflationSharingPercentageProvider {
    /**
     * Return the shared percentage per inflation receiver.
     * @dev Assumption is that implementer edited that percents sum to 100 pct and
     *   that receiver addresses are valid.
     */
    function getSharingPercentages() external returns(SharingPercentage[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../interface/IIInflationReceiver.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../utils/implementation/SafePct.sol";


enum TopupType{ FACTOROFDAILYAUTHORIZED, ALLAUTHORIZED }

/**
* @notice A struct that defines how mint request topups will be computed for a reward service.
* @param topupType             The type to signal how the topup amounts are to be calculated.
*                              FACTOROFDAILYAUTHORIZED = Use a factor of last daily authorized to set a
*                              target balance for a reward service to maintain as a reserve for claiming.
*                              ALLAUTHORIZED = Mint enough native tokens to topup reward service contract to hold
*                              all authorized but unrequested rewards.
* @param topupFactorX100       If _topupType == FACTOROFDAILYAUTHORIZED, then this factor (times 100)
*                              is multipled by last daily authorized inflation to obtain the
*                              maximum balance that a reward service can hold at any given time. If it holds less,
*                              then this max amount is used to compute the mint request topup required to 
*                              bring the reward service contract native token balance up to that amount.
*/
struct TopupConfiguration {
    TopupType topupType;                            // Topup algo type
    uint256 topupFactorX100;                        // Topup factor, times 100, if applicable for type
    bool configured;                                // Flag to indicate whether initially configured
}

/**
 * @title Reward Service library
 * @notice A library representing a reward service. A reward service consists of a reward contract and
 *   associated inflation-related totals. When a topup configuration is applied, a reward service can
 *   also make minting requests to topup native tokens within a reward contract.
 * @dev A reward service exists within the context of a given inflation annum.
 **/
library RewardService {    
    using SafeMath for uint256;
    using SafePct for uint256;

    /**
     * @dev `RewardServiceState` is state structure used by this library to manage
     *   an a reward service tracking authorize inflation.
     */
    struct RewardServiceState {
        IIInflationReceiver inflationReceiver;          // The target rewarding contract
        uint256 authorizedInflationWei;                 // Total authorized inflation for this reward service
        uint256 lastDailyAuthorizedInflationWei;        // Last daily authorized inflation amount
        uint256 inflationTopupRequestedWei;             // Total inflation topup requested to be minted
        uint256 inflationTopupReceivedWei;              // Total inflation minting received
        uint256 inflationTopupWithdrawnWei;             // Total inflation minting sent to rewarding service contract
    }

    event RewardServiceTopupComputed(IIInflationReceiver inflationReceiver, uint256 amountWei);

    /**
     * @notice Maintain authorized inflation total for service.
     * @param _amountWei Amount to add.
     */
    function addAuthorizedInflation(RewardServiceState storage _self, uint256 _amountWei) internal {
        _self.authorizedInflationWei = _self.authorizedInflationWei.add(_amountWei);
        _self.lastDailyAuthorizedInflationWei = _amountWei;
    }

    /**
     * @notice Maintain topup native tokens received total for service. 
     * @param _amountWei Amount to add.
     */
    function addTopupReceived(RewardServiceState storage _self, uint256 _amountWei) internal {
        _self.inflationTopupReceivedWei = _self.inflationTopupReceivedWei.add(_amountWei);
    }

    /**
     * @notice Maintain topup native tokens withdrawn (funded) total for service. 
     * @param _amountWei Amount to add.
     */
    function addTopupWithdrawn(RewardServiceState storage _self, uint256 _amountWei) internal {
        _self.inflationTopupWithdrawnWei = _self.inflationTopupWithdrawnWei.add(_amountWei);
    }

    /**
     * @notice Given a topup configuration, compute the topup request for the reward contract associated
     *   to the service.
     * @param _topupConfiguration   The topup configuration defining the algo used to compute the topup amount.
     * @return _topupRequestWei     The topup request amount computed.
     */
    function computeTopupRequest(
        RewardServiceState storage _self,
        TopupConfiguration memory _topupConfiguration
    )
        internal 
        returns (uint256 _topupRequestWei)
    {
        // Get the balance of the inflation receiver
        uint256 inflationReceiverBalanceWei = address(_self.inflationReceiver).balance;
        if (_topupConfiguration.topupType == TopupType.FACTOROFDAILYAUTHORIZED) {
            // Compute a topup request based purely on the given factor, the last daily authorization, and
            // the balance that is sitting in the reward service contract.
            uint256 requestedBalanceWei = _self.lastDailyAuthorizedInflationWei
                .mulDiv(_topupConfiguration.topupFactorX100, 100);
            uint256 rawTopupRequestWei = 0;
            // If current balance is less then requested, request some more.
            if (requestedBalanceWei > inflationReceiverBalanceWei) {
                rawTopupRequestWei = requestedBalanceWei.sub(inflationReceiverBalanceWei);
            }
            // Compute what is already pending to be topped up
            uint256 topupPendingWei = getPendingTopup(_self);
            // If what is pending to topup is greater than the raw request, request no more.
            if (topupPendingWei > rawTopupRequestWei) {
                _topupRequestWei = 0;
            } else {
                // Back out any request that is already pending
                _topupRequestWei = rawTopupRequestWei.sub(topupPendingWei);
            }
            // And finally, in any case, topup requested cannot be more than the net of 
            // authorized, pending, and received
            uint256 maxTopupRequestWei = _self.authorizedInflationWei
                .sub(topupPendingWei)
                .sub(_self.inflationTopupReceivedWei);
            if (_topupRequestWei > maxTopupRequestWei) {
                _topupRequestWei = maxTopupRequestWei;
            }
        } else if (_topupConfiguration.topupType == TopupType.ALLAUTHORIZED) {
            _topupRequestWei = _self.authorizedInflationWei
                .sub(_self.inflationTopupRequestedWei);
        } else { // This code is unreachable since TopupType currently has only 2 constructors
            _topupRequestWei = 0;
            assert(false);
        }
        _self.inflationTopupRequestedWei = _self.inflationTopupRequestedWei.add(_topupRequestWei);
        
        emit RewardServiceTopupComputed(_self.inflationReceiver, _topupRequestWei);
    }

    /**
     * @notice Compute a pending topup request.
     * @return _pendingTopupWei The amount pending to be minted.
     */
    function getPendingTopup(
        RewardServiceState storage _self
    )
        internal view
        returns(uint256 _pendingTopupWei)
    {
        return _self.inflationTopupRequestedWei.sub(_self.inflationTopupReceivedWei);        
    }

    /**
     * @notice Initial a new reward service.
     * @dev Assume service is already instantiated.
     */
    function initialize(
        RewardServiceState storage _self,
        IIInflationReceiver _inflationReceiver
    ) 
        internal
    {
        _self.inflationReceiver = _inflationReceiver;
        _self.authorizedInflationWei = 0;
        _self.lastDailyAuthorizedInflationWei = 0;
        _self.inflationTopupRequestedWei = 0;
        _self.inflationTopupReceivedWei = 0;
        _self.inflationTopupWithdrawnWei = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


interface IISupply {

    /**
     * @notice Sets inflation contract. Only governance can call this method.
     */
    function setInflation(address _inflation) external;

    /**
     * @notice Updates authorized inflation and circulating supply - emits event if error
     * @param _inflationAuthorizedWei               Authorized inflation
     * @dev Also updates the burn address amount
    */
    function updateAuthorizedInflationAndCirculatingSupply(uint256 _inflationAuthorizedWei) external;

    /**
     * @notice Get approximate circulating supply for given block number from cache - only past block
     * @param _blockNumber                          Block number
     * @return _circulatingSupplyWei Return approximate circulating supply for last known block <= _blockNumber
    */
    function getCirculatingSupplyAtCached(uint256 _blockNumber) external returns(uint256 _circulatingSupplyWei);

    /**
     * @notice Get approximate circulating supply for given block number
     * @param _blockNumber                          Block number
     * @return _circulatingSupplyWei Return approximate circulating supply for last known block <= _blockNumber
    */
    function getCirculatingSupplyAt(uint256 _blockNumber) external view returns(uint256 _circulatingSupplyWei);

    /**
     * @notice Get total inflatable balance (initial genesis amount + total authorized inflation)
     * @return _inflatableBalanceWei Return inflatable balance
    */
    function getInflatableBalance() external view returns(uint256 _inflatableBalanceWei);
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @dev Compute percentages safely without phantom overflows.
 *
 * Intermediate operations can overflow even when the result will always
 * fit into computed type. Developers usually
 * assume that overflows raise errors. `SafePct` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafePct {
    using SafeMath for uint256;
    /**
     * Requirements:
     *
     * - intermediate operations must revert on overflow
     */
    function mulDiv(uint256 x, uint256 y, uint256 z) internal pure returns (uint256) {
        require(z > 0, "Division by zero");

        if (x == 0) return 0;
        uint256 xy = x * y;
        if (xy / x == y) { // no overflow happened - same as in SafeMath mul
            return xy / z;
        }

        //slither-disable-next-line divide-before-multiply
        uint256 a = x / z;
        uint256 b = x % z; // x = a * z + b

        //slither-disable-next-line divide-before-multiply
        uint256 c = y / z;
        uint256 d = y % z; // y = c * z + d

        return (a.mul(c).mul(z)).add(a.mul(d)).add(b.mul(c)).add(b.mul(d).div(z));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./GovernedBase.sol";


/**
 * @title Governed At Genesis
 * @dev This contract enforces a fixed governance address when the constructor
 *  is not executed on a contract (for instance when directly loaded to the genesis block).
 *  This is required to fix governance on a contract when the network starts, at such point
 *  where theoretically no accounts yet exist, and leaving it ungoverned could result in a race
 *  to claim governance by an unauthorized address.
 **/
contract GovernedAtGenesis is GovernedBase {
    constructor(address _governance) GovernedBase(_governance) { }

    /**
     * @notice Set governance to a fixed address when constructor is not called.
     **/
    function initialiseFixedAddress() public virtual returns (address) {
        address governanceAddress = address(0xfffEc6C83c8BF5c3F4AE0cCF8c45CE20E4560BD7);
        
        super.initialise(governanceAddress);
        return governanceAddress;
    }

    /**
     * @notice Disallow initialise to be called
     * @param _governance The governance address for initial claiming
     **/
    // solhint-disable-next-line no-unused-vars
    function initialise(address _governance) public override pure {
        assert(false);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


/**
 * @title Governed Base
 * @notice This abstract base class defines behaviors for a governed contract.
 * @dev This class is abstract so that specific behaviors can be defined for the constructor.
 *   Contracts should not be left ungoverned, but not all contract will have a constructor
 *   (for example those pre-defined in genesis).
 **/
abstract contract GovernedBase {
    address public governance;
    address public proposedGovernance;
    bool private initialised;

    event GovernanceProposed(address proposedGovernance);
    event GovernanceUpdated (address oldGovernance, address newGoveranance);

    modifier onlyGovernance () {
        require (msg.sender == governance, "only governance");
        _;
    }

    constructor(address _governance) {
        if (_governance != address(0)) {
            initialise(_governance);
        }
    }

    /**
     * @notice First of a two step process for turning over governance to another address.
     * @param _governance The address to propose to receive governance role.
     * @dev Must hold governance to propose another address.
     */
    function proposeGovernance(address _governance) external onlyGovernance {
        proposedGovernance = _governance;
        emit GovernanceProposed(_governance);
    }

    /**
     * @notice Once proposed, claimant can claim the governance role as the second of a two-step process.
     */
    function claimGovernance() external {
        require(msg.sender == proposedGovernance, "not claimaint");

        emit GovernanceUpdated(governance, proposedGovernance);
        governance = proposedGovernance;
        proposedGovernance = address(0);
    }

    /**
     * @notice In a one-step process, turn over governance to another address.
     * @dev Must hold governance to transfer.
     */
    function transferGovernance(address _governance) external onlyGovernance {
        emit GovernanceUpdated(governance, _governance);
        governance = _governance;
        proposedGovernance = address(0);
    }

    /**
     * @notice Initialize the governance address if not first initialized.
     */
    function initialise(address _governance) public virtual {
        require(initialised == false, "initialised != false");

        initialised = true;
        emit GovernanceUpdated(governance, _governance);
        governance = _governance;
        proposedGovernance = address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import { GovernedBase } from "./GovernedBase.sol";


/**
 * @title Governed
 * @dev For deployed, governed contracts, enforce a non-zero address at create time.
 **/
contract Governed is GovernedBase {
    constructor(address _governance) GovernedBase(_governance) {
        require(_governance != address(0), "_governance zero");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint public constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint public constant SECONDS_PER_HOUR = 60 * 60;
    uint public constant SECONDS_PER_MINUTE = 60;
    int public constant OFFSET19700101 = 2440588;

    uint public constant DOW_MON = 1;
    uint public constant DOW_TUE = 2;
    uint public constant DOW_WED = 3;
    uint public constant DOW_THU = 4;
    uint public constant DOW_FRI = 5;
    uint public constant DOW_SAT = 6;
    uint public constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int tempL = days + 68569 + offset
    // int tempN = 4 * tempL / 146097
    // tempL = tempL - (146097 * tempN + 3) / 4
    // year = 4000 * (tempL + 1) / 1461001
    // tempL = tempL - 1461 * year / 4 + 31
    // month = 80 * tempL / 2447
    // dd = tempL - 2447 * month / 80
    // tempL = month / 11
    // month = month + 2 - 12 * tempL
    // year = 100 * (tempN - 49) + year + tempL
    // ------------------------------------------------------------------------
    //solhint-disable max-line-length
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        /* solhint-disable var-name-mixedcase */
        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        /* solhint-enable var-name-mixedcase */
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint year, 
        uint month, 
        uint day, 
        uint hour, 
        uint minute, 
        uint second) internal pure returns (uint timestamp) {
        timestamp = 
            _daysFromDate(year, month, day) * 
            SECONDS_PER_DAY + 
            hour * 
            SECONDS_PER_HOUR + 
            minute * 
            SECONDS_PER_MINUTE + 
            second;
    }

    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint timestamp) internal pure returns (
        uint year, 
        uint month, 
        uint day, 
        uint hour, 
        uint minute, 
        uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(
        uint year, 
        uint month, 
        uint day, 
        uint hour, 
        uint minute, 
        uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        // When adding a year to feb 29th
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    /**
     * @dev removed since it can be a cause of errors 
     * adding and removing a year may not end up on the same point in time    
     */
    // function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
    //     (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    //     year -= _years;
    //     uint daysInMonth = _getDaysInMonth(year, month);
    //     if (day > daysInMonth) {
    //         day = daysInMonth;
    //     }
    //     newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
    //     require(newTimestamp <= timestamp);
    // }

    /**
     * @dev removed since it can be a cause of errors 
     * adding and removing a month may not end up on the same point in time 
     * Intendet functionality:
     * 31.5 + 1 month => 30.6
     * 30.6 - 1 month => 30.5 
     * this may cause problems
     */
    // function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
    //     (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    //     uint yearMonth = year * 12 + (month - 1) - _months;
    //     year = yearMonth / 12;
    //     month = yearMonth % 12 + 1;
    //     uint daysInMonth = _getDaysInMonth(year, month);
    //     if (day > daysInMonth) {
    //         day = daysInMonth;
    //     }
    //     newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
    //     require(newTimestamp <= timestamp);
    // }

    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
    
    function getDaysInYear(uint timestamp) internal pure returns (uint daysInYear) {
        return isLeapYear(timestamp) ? 366 : 365;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../../utils/implementation/DateTimeLibrary.sol";
import "../implementation/Inflation.sol";
import "../interface/IIInflationReceiver.sol";
import "./RewardService.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../utils/implementation/SafePct.sol";
import "../interface/IIInflationSharingPercentageProvider.sol";
import "./RewardService.sol";


/**
 * @title Reward Services library
 * @notice A library to manage a collection of reward services, their associated totals, and to perform operations
 *   that impact or involve the collection, such as calculating topup amounts across services.
 * @dev There are two concepts that are helpful to understand. A sharing percentage associates an inflation receiver
 *   with a sharing percentage used to calculate percentage of authorized inflation a given reward contract
 *   is entitled to receive for distributing rewards. A reward service is associtated to a topup configuration, which
 *   dictates how much native token will be minted and sent for claiming reserves, and it stores totals for a given 
 *   inflation
 *   receiver, for a given annum.
 **/
library RewardServices {    
    using BokkyPooBahsDateTimeLibrary for uint256;
    using RewardService for RewardService.RewardServiceState;
    using SafeMath for uint256;
    using SafePct for uint256;

    /**
     * @dev `RewardServicesState` is state structure used by this library to manage
     *   a collection of reward services and associated totals.
     */
    struct RewardServicesState {
        // Collection of annums
        RewardService.RewardServiceState[] rewardServices;
        // Balances
        uint256 totalAuthorizedInflationWei;
        uint256 totalInflationTopupRequestedWei;
        uint256 totalInflationTopupReceivedWei;
        uint256 totalInflationTopupWithdrawnWei;
    }

    uint256 internal constant BIPS100 = 1e4;                            // 100% in basis points

    event RewardServiceDailyAuthorizedInflationComputed(IIInflationReceiver inflationReceiver, uint256 amountWei);
    event RewardServiceTopupRequestReceived(IIInflationReceiver inflationReceiver, uint256 amountWei);

    /**
     * @notice For all sharing percentages, compute authorized daily inflation for current cycle
     *  and then allocate it across associated inflation receivers according to their sharing percentages, 
     *  updating reward service totals along the way. Finally,
     *  set the daily authorized inflation for the given inflation receiver.
     * @param _totalRecognizedInflationWei The total recognized inflation across all annums.
     * @param _totalAuthorizedInflationWei The total authorized inflation across all annums.
     * @param _periodsRemaining The number of periods remaining in the current annum.
     * @param _sharingPercentages An array of inflation sharing percentages.
     * @return _amountAuthorizedWei The inflation authorized for this cycle.
     * @dev This method requires totals across all annums so as to continually calculate
     *   the amount remaining to be authorized regardless of timing slippage between annums should it
     *   occur.
     */
    function authorizeDailyInflation(
        RewardServicesState storage _self,
        uint256 _totalRecognizedInflationWei,
        uint256 _totalAuthorizedInflationWei,
        uint256 _periodsRemaining,
        SharingPercentage[] memory _sharingPercentages
    )
        internal
        returns(uint256 _amountAuthorizedWei)
    {
        // If there are no sharing percentages, then there is nothing to authorize.
        if (_sharingPercentages.length == 0) {
            _amountAuthorizedWei = 0;
            return _amountAuthorizedWei;
        }
        
        // Compute amount to allocate
        uint256 amountToAuthorizeRemaingWei = _totalRecognizedInflationWei
            .sub(_totalAuthorizedInflationWei)
            .div(_periodsRemaining);
        // Set up return value with amount authorized
        _amountAuthorizedWei = amountToAuthorizeRemaingWei;
        // Accumulate authorized total...note that this total is for a given annum, for a given service
        _self.totalAuthorizedInflationWei = _self.totalAuthorizedInflationWei.add(amountToAuthorizeRemaingWei);
        // Start with total bips in denominator
        uint256 divisorRemaining = BIPS100;
        // Loop over sharing percentages
        for (uint256 i; i < _sharingPercentages.length; i++) {
            // Compute the amount to authorize for a given service
            uint256 toAuthorizeWei = amountToAuthorizeRemaingWei.mulDiv(
                _sharingPercentages[i].percentBips, 
                divisorRemaining
            );
            // Reduce the numerator by amount just computed
            amountToAuthorizeRemaingWei = amountToAuthorizeRemaingWei.sub(toAuthorizeWei);
            // Reduce the divisor by the bips just allocated
            divisorRemaining = divisorRemaining.sub(_sharingPercentages[i].percentBips);
            // Try to find a matching reward service for the given sharing percentage.
            // New sharing percentages can be added at any time. And if one gets removed,  
            // we don't remove that reward service for a given annum, since its total still
            // remains applicable.
            ( bool found, uint256 rewardServiceIndex ) = 
                findRewardService(_self, _sharingPercentages[i].inflationReceiver);
            if (found) {
                // Get the existing reward service
                RewardService.RewardServiceState storage rewardService = _self.rewardServices[rewardServiceIndex];
                // Accumulate the amount authorized for the service
                rewardService.addAuthorizedInflation(toAuthorizeWei);
            } else {
                // Initialize a new reward service
                RewardService.RewardServiceState storage rewardService = _self.rewardServices.push();
                rewardService.initialize(_sharingPercentages[i].inflationReceiver);
                // Accumulate the amount authorized for the service
                rewardService.addAuthorizedInflation(toAuthorizeWei);                
            }                
            // Signal the inflation receiver of the reward service (the actual rewarding contract)
            // with amount just authorized.
            _sharingPercentages[i].inflationReceiver.setDailyAuthorizedInflation(toAuthorizeWei);
            
            emit RewardServiceDailyAuthorizedInflationComputed(
                _sharingPercentages[i].inflationReceiver, 
                toAuthorizeWei);
        }
    }

    /**
     * @notice Given topup configurations as maintained by an instantiated Inflation contract, compute
     *   the topup minting requests needed to topup reward contracts with native token reserves to satisfy claim
     *   requests.
     * @param _inflation    The Inflation contract holding the topup configurations.
     * @return _topupRequestWei The topup request to mint native tokens across reward services for this cycle.
     */
    function computeTopupRequest(
        RewardServicesState storage _self,
        Inflation _inflation
    )
        internal
        returns (uint256 _topupRequestWei)
    {
        for (uint256 i; i < _self.rewardServices.length; i++) {
            TopupConfiguration memory topupConfiguration = 
                _inflation.getTopupConfiguration(_self.rewardServices[i].inflationReceiver);
            _topupRequestWei = _topupRequestWei.add(_self.rewardServices[i].computeTopupRequest(topupConfiguration));
        }
        _self.totalInflationTopupRequestedWei = _self.totalInflationTopupRequestedWei.add(_topupRequestWei);
        // Make sure topup requested never exceeds the amount authorized
        assert(_self.totalInflationTopupRequestedWei <= _self.totalAuthorizedInflationWei);
    }

    /**
     * @notice Given an inflation receiver, return the index of the associated reward service.
     * @param _inflationReceiver The inflation receiver.
     * @return _found   True if the reward service was found.
     * @return _index   The index on the rewardServices array of the found service. Index is undefined
     *   if the reward service was not found.
     */
    function findRewardService(
        RewardServicesState storage _self,
        IIInflationReceiver _inflationReceiver
    ) 
        internal view
        returns(bool _found, uint256 _index)
    {
        // The number of these is expected to be low.
        _found = false;
        for (uint256 i; i < _self.rewardServices.length; i++) {
            if (address(_self.rewardServices[i].inflationReceiver) == address(_inflationReceiver)) {
                _index = i;
                _found = true;
                break;
            }
        }
    }

    /**
     * @notice Receive a topup request of minted native tokens and disburse amongst requestors.
     * @return _amountPostedWei The total amount of native tokens funded.
     * @dev Assume value is siting in Inflation contract waiting to be posted and transmitted.
     *   This function is atomic, so if for some reason not enough native tokens got minted, this
     *   function will fail until all topup requests can be satisfied.
     */
    function receiveTopupRequest(
        RewardServicesState storage _self
    ) 
        internal 
        returns(uint256 _amountPostedWei)
    {
        // Spin through all reward services
        for (uint256 i; i < _self.rewardServices.length; i++) {
            // Get the pending topup for the service
            uint256 pendingTopupWei = _self.rewardServices[i].getPendingTopup();
            // Accumulate topup received
            _self.rewardServices[i].addTopupReceived(pendingTopupWei);
            _self.totalInflationTopupReceivedWei = _self.totalInflationTopupReceivedWei.add(pendingTopupWei);
            // Transfer topup to rewarding service contract
            _self.rewardServices[i].inflationReceiver.receiveInflation{ value: pendingTopupWei }();
            // Accumulate topup withdrawn
            _self.rewardServices[i].addTopupWithdrawn(pendingTopupWei);
            _self.totalInflationTopupWithdrawnWei = _self.totalInflationTopupWithdrawnWei.add(pendingTopupWei);
            // Accumulate amount posted
            _amountPostedWei = _amountPostedWei.add(pendingTopupWei);
            
            emit RewardServiceTopupRequestReceived(_self.rewardServices[i].inflationReceiver, pendingTopupWei);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
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
  }
}