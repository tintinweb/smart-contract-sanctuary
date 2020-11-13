/* solium-disable function-order */
pragma solidity 0.5.17;

import {IBondedECDSAKeepFactory} from "@keep-network/keep-ecdsa/contracts/api/IBondedECDSAKeepFactory.sol";

import {VendingMachine} from "./VendingMachine.sol";
import {DepositFactory} from "../proxy/DepositFactory.sol";

import {IRelay} from "@summa-tx/relay-sol/contracts/Relay.sol";
import "../external/IMedianizer.sol";

import {ITBTCSystem} from "../interfaces/ITBTCSystem.sol";
import {ISatWeiPriceFeed} from "../interfaces/ISatWeiPriceFeed.sol";
import {DepositLog} from "../DepositLog.sol";

import {TBTCDepositToken} from "./TBTCDepositToken.sol";
import "./TBTCToken.sol";
import "./FeeRebateToken.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./KeepFactorySelection.sol";

/// @title TBTC System.
/// @notice This contract acts as a central point for access control,
///         value governance, and price feed.
/// @dev    Governable values should only affect new deposit creation.
contract TBTCSystem is Ownable, ITBTCSystem, DepositLog {

    using SafeMath for uint256;
    using KeepFactorySelection for KeepFactorySelection.Storage;

    event EthBtcPriceFeedAdditionStarted(address _priceFeed, uint256 _timestamp);
    event LotSizesUpdateStarted(uint64[] _lotSizes, uint256 _timestamp);
    event SignerFeeDivisorUpdateStarted(uint16 _signerFeeDivisor, uint256 _timestamp);
    event CollateralizationThresholdsUpdateStarted(
        uint16 _initialCollateralizedPercent,
        uint16 _undercollateralizedThresholdPercent,
        uint16 _severelyUndercollateralizedThresholdPercent,
        uint256 _timestamp
    );
    event KeepFactoriesUpdateStarted(
        address _keepStakedFactory,
        address _fullyBackedFactory,
        address _factorySelector,
        uint256 _timestamp
    );

    event EthBtcPriceFeedAdded(address _priceFeed);
    event LotSizesUpdated(uint64[] _lotSizes);
    event AllowNewDepositsUpdated(bool _allowNewDeposits);
    event SignerFeeDivisorUpdated(uint16 _signerFeeDivisor);
    event CollateralizationThresholdsUpdated(
        uint16 _initialCollateralizedPercent,
        uint16 _undercollateralizedThresholdPercent,
        uint16 _severelyUndercollateralizedThresholdPercent
    );
    event KeepFactoriesUpdated(
        address _keepStakedFactory,
        address _fullyBackedFactory,
        address _factorySelector
    );

    uint256 initializedTimestamp = 0;
    uint256 pausedTimestamp;
    uint256 constant pausedDuration = 10 days;

    ISatWeiPriceFeed public priceFeed;
    IRelay public relay;

    KeepFactorySelection.Storage keepFactorySelection;

    uint16 public keepSize;
    uint16 public keepThreshold;

    // Parameters governed by the TBTCSystem owner
    bool private allowNewDeposits = false;
    uint16 private signerFeeDivisor = 2000; // 1/2000 == 5bps == 0.05% == 0.0005
    uint16 private initialCollateralizedPercent = 150; // percent
    uint16 private undercollateralizedThresholdPercent = 125;  // percent
    uint16 private severelyUndercollateralizedThresholdPercent = 110; // percent
    uint64[] lotSizesSatoshis = [10**6, 10**7, 2 * 10**7, 5 * 10**7, 10**8]; // [0.01, 0.1, 0.2, 0.5, 1.0] BTC

    uint256 constant governanceTimeDelay = 48 hours;
    uint256 constant keepFactoriesUpgradeabilityPeriod = 180 days;

    uint256 private signerFeeDivisorChangeInitiated;
    uint256 private lotSizesChangeInitiated;
    uint256 private collateralizationThresholdsChangeInitiated;
    uint256 private keepFactoriesUpdateInitiated;

    uint16 private newSignerFeeDivisor;
    uint64[] newLotSizesSatoshis;
    uint16 private newInitialCollateralizedPercent;
    uint16 private newUndercollateralizedThresholdPercent;
    uint16 private newSeverelyUndercollateralizedThresholdPercent;
    address private newKeepStakedFactory;
    address private newFullyBackedFactory;
    address private newFactorySelector;

    // price feed
    uint256 constant priceFeedGovernanceTimeDelay = 90 days;
    uint256 ethBtcPriceFeedAdditionInitiated;
    IMedianizer nextEthBtcPriceFeed;

    constructor(address _priceFeed, address _relay) public {
        priceFeed = ISatWeiPriceFeed(_priceFeed);
        relay = IRelay(_relay);
    }

    /// @notice        Initialize contracts
    /// @dev           Only the Deposit factory should call this, and only once.
    /// @param _defaultKeepFactory       ECDSA keep factory backed by KEEP stake.
    /// @param _depositFactory    Deposit Factory. More info in `DepositFactory`.
    /// @param _masterDepositAddress  Master Deposit address. More info in `Deposit`.
    /// @param _tbtcToken         TBTCToken. More info in `TBTCToken`.
    /// @param _tbtcDepositToken  TBTCDepositToken (TDT). More info in `TBTCDepositToken`.
    /// @param _feeRebateToken    FeeRebateToken (FRT). More info in `FeeRebateToken`.
    /// @param _keepThreshold     Signing group honesty threshold.
    /// @param _keepSize          Signing group size.
    function initialize(
        IBondedECDSAKeepFactory _defaultKeepFactory,
        DepositFactory _depositFactory,
        address payable _masterDepositAddress,
        TBTCToken _tbtcToken,
        TBTCDepositToken _tbtcDepositToken,
        FeeRebateToken _feeRebateToken,
        VendingMachine _vendingMachine,
        uint16 _keepThreshold,
        uint16 _keepSize
    ) external onlyOwner {
        require(initializedTimestamp == 0, "already initialized");

        keepFactorySelection.initialize(_defaultKeepFactory);
        keepThreshold = _keepThreshold;
        keepSize = _keepSize;
        initializedTimestamp = block.timestamp;
        allowNewDeposits = true;

        setTbtcDepositToken(_tbtcDepositToken);

        _vendingMachine.setExternalAddresses(
            _tbtcToken,
            _tbtcDepositToken,
            _feeRebateToken
        );
        _depositFactory.setExternalDependencies(
            _masterDepositAddress,
            this,
            _tbtcToken,
            _tbtcDepositToken,
            _feeRebateToken,
            address(_vendingMachine)
        );
    }

    /// @notice Returns whether new deposits should be allowed.
    /// @return True if new deposits should be allowed by the emergency pause button
    function getAllowNewDeposits() external view returns (bool) {
        return allowNewDeposits;
    }

    /// @notice Return the lowest lot size currently enabled for deposits.
    /// @return The lowest lot size, in satoshis.
    function getMinimumLotSize() public view returns (uint256) {
        return lotSizesSatoshis[0];
    }

    /// @notice Return the largest lot size currently enabled for deposits.
    /// @return The largest lot size, in satoshis.
    function getMaximumLotSize() external view returns (uint256) {
        return lotSizesSatoshis[lotSizesSatoshis.length - 1];
    }

    /// @notice One-time-use emergency function to disallow future deposit creation for 10 days.
    function emergencyPauseNewDeposits() external onlyOwner {
        require(pausedTimestamp == 0, "emergencyPauseNewDeposits can only be called once");
        uint256 sinceInit = block.timestamp - initializedTimestamp;
        require(sinceInit < 180 days, "emergencyPauseNewDeposits can only be called within 180 days of initialization");
        pausedTimestamp = block.timestamp;
        allowNewDeposits = false;
        emit AllowNewDepositsUpdated(false);
    }

    /// @notice Anyone can reactivate deposit creations after the pause duration is over.
    function resumeNewDeposits() external {
        require(! allowNewDeposits, "New deposits are currently allowed");
        require(pausedTimestamp != 0, "Deposit has not been paused");
        require(block.timestamp.sub(pausedTimestamp) >= pausedDuration, "Deposits are still paused");
        allowNewDeposits = true;
        emit AllowNewDepositsUpdated(true);
    }

    function getRemainingPauseTerm() external view returns (uint256) {
        require(! allowNewDeposits, "New deposits are currently allowed");
        return (block.timestamp.sub(pausedTimestamp) >= pausedDuration)?
            0:
            pausedDuration.sub(block.timestamp.sub(pausedTimestamp));
    }

    /// @notice Set the system signer fee divisor.
    /// @dev    This can be finalized by calling `finalizeSignerFeeDivisorUpdate`
    ///         Anytime after `governanceTimeDelay` has elapsed.
    /// @param _signerFeeDivisor The signer fee divisor.
    function beginSignerFeeDivisorUpdate(uint16 _signerFeeDivisor)
        external onlyOwner
    {
        require(
            _signerFeeDivisor > 9,
            "Signer fee divisor must be greater than 9, for a signer fee that is <= 10%"
        );
        require(
            _signerFeeDivisor < 5000,
            "Signer fee divisor must be less than 5000, for a signer fee that is > 0.02%"
        );

        newSignerFeeDivisor = _signerFeeDivisor;
        signerFeeDivisorChangeInitiated = block.timestamp;
        emit SignerFeeDivisorUpdateStarted(_signerFeeDivisor, block.timestamp);
    }

    /// @notice Set the allowed deposit lot sizes.
    /// @dev    Lot size array should always contain 10**8 satoshis (1 BTC) and
    ///         cannot contain values less than 50000 satoshis (0.0005 BTC) or
    ///         greater than 10**10 satoshis (100 BTC). Lot size array must not
    ///         have duplicates and it must be sorted.
    ///         This can be finalized by calling `finalizeLotSizesUpdate`
    ///         anytime after `governanceTimeDelay` has elapsed.
    /// @param _lotSizes Array of allowed lot sizes.
    function beginLotSizesUpdate(uint64[] calldata _lotSizes)
        external onlyOwner
    {
        bool hasSingleBitcoin = false;
        for (uint i = 0; i < _lotSizes.length; i++) {
            if (_lotSizes[i] == 10**8) {
                hasSingleBitcoin = true;
            } else if (_lotSizes[i] < 50 * 10**3) {
                // Failed the minimum requirement, break on out.
                revert("Lot sizes less than 0.0005 BTC are not allowed");
            } else if (_lotSizes[i] > 10 * 10**9) {
                // Failed the maximum requirement, break on out.
                revert("Lot sizes greater than 100 BTC are not allowed");
            } else if (i > 0 && _lotSizes[i] == _lotSizes[i-1]) {
                revert("Lot size array must not have duplicates");
            } else if (i > 0 && _lotSizes[i] < _lotSizes[i-1]) {
                revert("Lot size array must be sorted");
            }
        }

        require(hasSingleBitcoin, "Lot size array must always contain 1 BTC");

        emit LotSizesUpdateStarted(_lotSizes, block.timestamp);
        newLotSizesSatoshis = _lotSizes;
        lotSizesChangeInitiated = block.timestamp;
    }

    /// @notice Set the system collateralization levels
    /// @dev    This can be finalized by calling `finalizeCollateralizationThresholdsUpdate`
    ///         Anytime after `governanceTimeDelay` has elapsed.
    /// @param _initialCollateralizedPercent default signing bond percent for new deposits
    /// @param _undercollateralizedThresholdPercent first undercollateralization trigger
    /// @param _severelyUndercollateralizedThresholdPercent second undercollateralization trigger
    function beginCollateralizationThresholdsUpdate(
        uint16 _initialCollateralizedPercent,
        uint16 _undercollateralizedThresholdPercent,
        uint16 _severelyUndercollateralizedThresholdPercent
    ) external onlyOwner {
        require(
            _initialCollateralizedPercent <= 300,
            "Initial collateralized percent must be <= 300%"
        );
        require(
            _initialCollateralizedPercent > 100,
            "Initial collateralized percent must be >= 100%"
        );
        require(
            _initialCollateralizedPercent > _undercollateralizedThresholdPercent,
            "Undercollateralized threshold must be < initial collateralized percent"
        );
        require(
            _undercollateralizedThresholdPercent > _severelyUndercollateralizedThresholdPercent,
            "Severe undercollateralized threshold must be < undercollateralized threshold"
        );

        newInitialCollateralizedPercent = _initialCollateralizedPercent;
        newUndercollateralizedThresholdPercent = _undercollateralizedThresholdPercent;
        newSeverelyUndercollateralizedThresholdPercent = _severelyUndercollateralizedThresholdPercent;
        collateralizationThresholdsChangeInitiated = block.timestamp;
        emit CollateralizationThresholdsUpdateStarted(
            _initialCollateralizedPercent,
            _undercollateralizedThresholdPercent,
            _severelyUndercollateralizedThresholdPercent,
            block.timestamp
        );
    }

    /// @notice Sets the addresses of the KEEP-staked ECDSA keep factory,
    ///         ETH-only-backed ECDSA keep factory and the selection strategy
    ///         that will choose between the two factories for new deposits.
    ///         When the ETH-only-backed factory and strategy are not set TBTCSystem
    ///         will use KEEP-staked factory. When both factories and strategy
    ///         are set, TBTCSystem load balances between two factories based on
    ///         the selection strategy.
    /// @dev It can be finalized by calling `finalizeKeepFactoriesUpdate`
    ///      any time after `governanceTimeDelay` has elapsed. This can be
    ///      called more than once until finalized to reset the values and
    ///      timer. An update can only be initialized before
    ///      `keepFactoriesUpgradeabilityPeriod` elapses after system initialization;
    ///      after that, no further updates can be initialized, though any pending
    ///      update can be finalized. All calls must set all three properties to
    ///      their desired value; leaving a value as 0, even if it was previously
    ///      set, will update that value to be 0. ETH-bond-only factory or the
    ///      strategy are allowed to be set as zero addresses.
    /// @param _keepStakedFactory Address of the KEEP staked based factory.
    /// @param _fullyBackedFactory Address of the ETH-bond-only-based factory.
    /// @param _factorySelector Address of the keep factory selection strategy.
    function beginKeepFactoriesUpdate(
        address _keepStakedFactory,
        address _fullyBackedFactory,
        address _factorySelector
    )
        external onlyOwner
    {
        uint256 sinceInit = block.timestamp - initializedTimestamp;
        require(
            sinceInit < keepFactoriesUpgradeabilityPeriod,
            "beginKeepFactoriesUpdate can only be called within 180 days of initialization"
        );

        // It is required that KEEP staked factory address is configured as this is
        // a default choice factory. Fully backed factory and factory selector
        // are optional for the system to work, hence they don't have to be provided.
        require(
            _keepStakedFactory != address(0),
            "KEEP staked factory must be a nonzero address"
        );

        newKeepStakedFactory = _keepStakedFactory;
        newFullyBackedFactory = _fullyBackedFactory;
        newFactorySelector = _factorySelector;
        keepFactoriesUpdateInitiated = block.timestamp;

        emit KeepFactoriesUpdateStarted(
            _keepStakedFactory,
            _fullyBackedFactory,
            _factorySelector,
            block.timestamp
        );
    }

    /// @notice Add a new ETH/BTC price feed contract to the priecFeed.
    /// @dev This can be finalized by calling `finalizeEthBtcPriceFeedAddition`
    ///      anytime after `priceFeedGovernanceTimeDelay` has elapsed.
    function beginEthBtcPriceFeedAddition(IMedianizer _ethBtcPriceFeed) external onlyOwner {
        bool ethBtcActive;
        (, ethBtcActive) = _ethBtcPriceFeed.peek();
        require(ethBtcActive, "Cannot add inactive feed");

        nextEthBtcPriceFeed = _ethBtcPriceFeed;
        ethBtcPriceFeedAdditionInitiated = block.timestamp;
        emit EthBtcPriceFeedAdditionStarted(address(_ethBtcPriceFeed), block.timestamp);
    }

    modifier onlyAfterGovernanceDelay(
        uint256 _changeInitializedTimestamp,
        uint256 _delay
    ) {
        require(_changeInitializedTimestamp > 0, "Change not initiated");
        require(
            block.timestamp.sub(_changeInitializedTimestamp) >= _delay,
            "Governance delay has not elapsed"
        );
        _;
    }

    /// @notice Finish setting the system signer fee divisor.
    /// @dev `beginSignerFeeDivisorUpdate` must be called first, once `governanceTimeDelay`
    ///       has passed, this function can be called to set the signer fee divisor to the
    ///       value set in `beginSignerFeeDivisorUpdate`
    function finalizeSignerFeeDivisorUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(signerFeeDivisorChangeInitiated, governanceTimeDelay)
    {
        signerFeeDivisor = newSignerFeeDivisor;
        emit SignerFeeDivisorUpdated(newSignerFeeDivisor);
        newSignerFeeDivisor = 0;
        signerFeeDivisorChangeInitiated = 0;
    }
    /// @notice Finish setting the accepted system lot sizes.
    /// @dev `beginLotSizesUpdate` must be called first, once `governanceTimeDelay`
    ///       has passed, this function can be called to set the lot sizes to the
    ///       value set in `beginLotSizesUpdate`
    function finalizeLotSizesUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(lotSizesChangeInitiated, governanceTimeDelay) {

        lotSizesSatoshis = newLotSizesSatoshis;
        emit LotSizesUpdated(newLotSizesSatoshis);
        lotSizesChangeInitiated = 0;
        newLotSizesSatoshis.length = 0;

        refreshMinimumBondableValue();
    }

    /// @notice Finish setting the system collateralization levels
    /// @dev `beginCollateralizationThresholdsUpdate` must be called first, once `governanceTimeDelay`
    ///       has passed, this function can be called to set the collateralization thresholds to the
    ///       value set in `beginCollateralizationThresholdsUpdate`
    function finalizeCollateralizationThresholdsUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(
            collateralizationThresholdsChangeInitiated,
            governanceTimeDelay
        ) {

        initialCollateralizedPercent = newInitialCollateralizedPercent;
        undercollateralizedThresholdPercent = newUndercollateralizedThresholdPercent;
        severelyUndercollateralizedThresholdPercent = newSeverelyUndercollateralizedThresholdPercent;

        emit CollateralizationThresholdsUpdated(
            newInitialCollateralizedPercent,
            newUndercollateralizedThresholdPercent,
            newSeverelyUndercollateralizedThresholdPercent
        );

        newInitialCollateralizedPercent = 0;
        newUndercollateralizedThresholdPercent = 0;
        newSeverelyUndercollateralizedThresholdPercent = 0;
        collateralizationThresholdsChangeInitiated = 0;
    }

    /// @notice Finish setting addresses of the KEEP-staked ECDSA keep factory,
    ///         ETH-only-backed ECDSA keep factory, and the selection strategy
    ///         that will choose between the two factories for new deposits.
    /// @dev `beginKeepFactoriesUpdate` must be called first; once
    ///      `governanceTimeDelay` has passed, this function can be called to
    ///      set factories addresses to the values set in `beginKeepFactoriesUpdate`.
    function finalizeKeepFactoriesUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(
            keepFactoriesUpdateInitiated,
            governanceTimeDelay
        ) {

        keepFactorySelection.setFactories(
            newKeepStakedFactory,
            newFullyBackedFactory,
            newFactorySelector
        );

        emit KeepFactoriesUpdated(
            newKeepStakedFactory,
            newFullyBackedFactory,
            newFactorySelector
        );

        keepFactoriesUpdateInitiated = 0;
        newKeepStakedFactory = address(0);
        newFullyBackedFactory = address(0);
        newFactorySelector = address(0);
    }

    /// @notice Finish adding a new price feed contract to the priceFeed.
    /// @dev `beginEthBtcPriceFeedAddition` must be called first; once
    ///      `ethBtcPriceFeedAdditionInitiated` has passed, this function can be
    ///      called to append a new price feed.
    function finalizeEthBtcPriceFeedAddition()
            external
            onlyOwner
            onlyAfterGovernanceDelay(
                ethBtcPriceFeedAdditionInitiated,
                priceFeedGovernanceTimeDelay
            ) {
        // This process interacts with external contracts, so
        // Checks-Effects-Interactions it.
        IMedianizer _nextEthBtcPriceFeed = nextEthBtcPriceFeed;
        nextEthBtcPriceFeed = IMedianizer(0);
        ethBtcPriceFeedAdditionInitiated = 0;

        emit EthBtcPriceFeedAdded(address(_nextEthBtcPriceFeed));

        priceFeed.addEthBtcFeed(_nextEthBtcPriceFeed);
    }

    /// @notice Gets the system signer fee divisor.
    /// @return The signer fee divisor.
    function getSignerFeeDivisor() external view returns (uint16) { return signerFeeDivisor; }

    /// @notice Gets the allowed lot sizes
    /// @return Uint64 array of allowed lot sizes
    function getAllowedLotSizes() external view returns (uint64[] memory){
        return lotSizesSatoshis;
    }

    /// @notice Get the system undercollateralization level for new deposits
    function getUndercollateralizedThresholdPercent() external view returns (uint16) {
        return undercollateralizedThresholdPercent;
    }

    /// @notice Get the system severe undercollateralization level for new deposits
    function getSeverelyUndercollateralizedThresholdPercent() external view returns (uint16) {
        return severelyUndercollateralizedThresholdPercent;
    }

    /// @notice Get the system initial collateralized level for new deposits.
    function getInitialCollateralizedPercent() external view returns (uint16) {
        return initialCollateralizedPercent;
    }

    /// @notice Get the price of one satoshi in wei.
    /// @dev Reverts if the price of one satoshi is 0 wei, or if the price of
    ///      one satoshi is 1 ether. Can only be called by a deposit with minted
    ///      TDT.
    /// @return The price of one satoshi in wei.
    function fetchBitcoinPrice() external view returns (uint256) {
        require(
            tbtcDepositToken.exists(uint256(msg.sender)),
            "Caller must be a Deposit contract"
        );

        return _fetchBitcoinPrice();
    }

    // Difficulty Oracle
    function fetchRelayCurrentDifficulty() external view returns (uint256) {
        return relay.getCurrentEpochDifficulty();
    }

    function fetchRelayPreviousDifficulty() external view returns (uint256) {
        return relay.getPrevEpochDifficulty();
    }

    /// @notice Get the time remaining until the signer fee divisor can be updated.
    function getRemainingSignerFeeDivisorUpdateTime() external view returns (uint256) {
        return getRemainingChangeTime(
            signerFeeDivisorChangeInitiated,
            governanceTimeDelay
        );
    }

    /// @notice Get the time remaining until the lot sizes can be updated.
    function getRemainingLotSizesUpdateTime() external view returns (uint256) {
        return getRemainingChangeTime(
            lotSizesChangeInitiated,
            governanceTimeDelay
        );
    }

    /// @notice Get the time remaining until the collateralization thresholds can be updated.
    function getRemainingCollateralizationThresholdsUpdateTime() external view returns (uint256) {
        return getRemainingChangeTime(
            collateralizationThresholdsChangeInitiated,
            governanceTimeDelay
        );
    }

    /// @notice Get the time remaining until the Keep ETH-only-backed ECDSA keep
    ///         factory and the selection strategy that will choose between it
    ///         and the KEEP-backed factory can be updated.
    function getRemainingKeepFactoriesUpdateTime() external view returns (uint256) {
        return getRemainingChangeTime(
            keepFactoriesUpdateInitiated,
            governanceTimeDelay
        );
    }

    /// @notice Get the time remaining until the signer fee divisor can be updated.
    function getRemainingEthBtcPriceFeedAdditionTime() external view returns (uint256) {
        return getRemainingChangeTime(
            ethBtcPriceFeedAdditionInitiated,
            priceFeedGovernanceTimeDelay
        );
    }

    /// @notice Get the time remaining until Keep factories can no longer be updated.
    function getRemainingKeepFactoriesUpgradeabilityTime() external view returns (uint256) {
        return getRemainingChangeTime(
            initializedTimestamp,
            keepFactoriesUpgradeabilityPeriod
        );
    }

    /// @notice Refreshes the minimum bondable value required from the operator
    /// to join the sortition pool for tBTC. The minimum bondable value is
    /// equal to the current minimum lot size collateralized 150% multiplied by
    /// the current BTC price.
    /// @dev It is recommended to call this function on tBTC initialization and
    /// after minimum lot size update.
    function refreshMinimumBondableValue() public {
        keepFactorySelection.setMinimumBondableValue(
            calculateBondRequirementWei(getMinimumLotSize()),
            keepSize,
            keepThreshold
        );
    }

    /// @notice Returns the time delay used for governance actions except for
    ///         price feed additions.
    function getGovernanceTimeDelay() external pure returns (uint256) {
        return governanceTimeDelay;
    }

    /// @notice Returns the time period when keep factories upgrades are allowed.
    function getKeepFactoriesUpgradeabilityPeriod() public pure returns (uint256) {
        return keepFactoriesUpgradeabilityPeriod;
    }

    /// @notice Returns the time delay used for price feed addition governance
    ///         actions.
    function getPriceFeedGovernanceTimeDelay() external pure returns (uint256) {
        return priceFeedGovernanceTimeDelay;
    }

    /// @notice Gets a fee estimate for creating a new Deposit.
    /// @return Uint256 estimate.
    function getNewDepositFeeEstimate()
        external
        view
        returns (uint256)
    {
        IBondedECDSAKeepFactory _keepFactory = keepFactorySelection.selectFactory();
        return _keepFactory.openKeepFeeEstimate();
    }

    /// @notice Request a new keep opening.
    /// @param _requestedLotSizeSatoshis Lot size in satoshis.
    /// @param _maxSecuredLifetime Duration of stake lock in seconds.
    /// @return Address of a new keep.
    function requestNewKeep(
        uint64 _requestedLotSizeSatoshis,
        uint256 _maxSecuredLifetime
    )
        external
        payable
        returns (address)
    {
        require(tbtcDepositToken.exists(uint256(msg.sender)), "Caller must be a Deposit contract");
        require(isAllowedLotSize(_requestedLotSizeSatoshis), "provided lot size not supported");

        IBondedECDSAKeepFactory _keepFactory = keepFactorySelection.selectFactoryAndRefresh();
        uint256 bond = calculateBondRequirementWei(_requestedLotSizeSatoshis);
        return _keepFactory.openKeep.value(msg.value)(keepSize, keepThreshold, msg.sender, bond, _maxSecuredLifetime);
    }

    /// @notice Check if a lot size is allowed.
    /// @param _requestedLotSizeSatoshis Lot size to check.
    /// @return True if lot size is allowed, false otherwise.
    function isAllowedLotSize(uint64 _requestedLotSizeSatoshis) public view returns (bool){
        for( uint i = 0; i < lotSizesSatoshis.length; i++){
            if (lotSizesSatoshis[i] == _requestedLotSizeSatoshis){
                return true;
            }
        }
        return false;
    }

    /// @notice Calculates bond requirement in wei for the given lot size in
    ///         satoshis based on the current ETHBTC price.
    /// @param _requestedLotSizeSatoshis Lot size in satoshis.
    /// @return Bond requirement in wei.
    function calculateBondRequirementWei(
        uint256 _requestedLotSizeSatoshis
    ) internal view returns (uint256) {
        uint256 lotSizeInWei = _fetchBitcoinPrice().mul(_requestedLotSizeSatoshis);
        return lotSizeInWei.mul(initialCollateralizedPercent).div(100);
    }

    function _fetchBitcoinPrice() internal view returns (uint256) {
        uint256 price = priceFeed.getPrice();
        if (price == 0 || price > 10 ** 18) {
            // This is if a sat is worth 0 wei, or is worth >1 ether. Revert at
            // once.
            revert("System returned a bad price");
        }
        return price;
    }

    /// @notice Get the time remaining until the function parameter timer value can be updated.
    function getRemainingChangeTime(
        uint256 _changeTimestamp,
        uint256 _delayAmount
    ) internal view returns (uint256){
        require(_changeTimestamp > 0, "Update not initiated");
        uint256 elapsed = block.timestamp.sub(_changeTimestamp);
        if (elapsed >= _delayAmount) {
            return 0;
        } else {
            return _delayAmount.sub(elapsed);
        }
    }
}
