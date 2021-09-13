// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../interface/IIFtsoManager.sol";
import "../interface/IIFtso.sol";
import "../lib/FtsoManagerSettings.sol";
import "../../genesis/implementation/FlareDaemon.sol";
import "../../genesis/interface/IFlareDaemonize.sol";
import "../../genesis/interface/IIPriceSubmitter.sol";
import "../../governance/implementation/Governed.sol";
import "../../inflation/interface/IISupply.sol";
import "../../tokenPools/interface/IIFtsoRewardManager.sol";
import "../../token/implementation/CleanupBlockNumberManager.sol";
import "../../utils/implementation/GovernedAndFlareDaemonized.sol";
import "../../utils/implementation/RevertErrorTracking.sol";
import "../../utils/interface/IIFtsoRegistry.sol";
import "../../utils/interface/IIVoterWhitelister.sol";


/**
 * FtsoManager is in charge of:
 * - defining reward epochs (few days)
 * - per reward epoch choose a single block that represents vote power of this epoch.
 * - keep track of all FTSO contracts
 * - per price epoch (few minutes)
 *    - randomly choose one FTSO for rewarding.
 *    - trigger finalize price reveal epoch
 *    - determines addresses and reward weights and triggers rewardDistribution
 */    
contract FtsoManager is IIFtsoManager, GovernedAndFlareDaemonized, IFlareDaemonize, RevertErrorTracking {
    using FtsoManagerSettings for FtsoManagerSettings.State;

    struct RewardEpochData {
        uint256 votepowerBlock;
        uint256 startBlock;
        uint256 startTimestamp;
    }

    uint256 public constant MAX_TRUSTED_ADDRESSES_LENGTH = 5;

    string internal constant ERR_FIRST_EPOCH_START_TS_IN_FUTURE = "First epoch start timestamp in future";
    string internal constant ERR_REWARD_EPOCH_DURATION_ZERO = "Reward epoch 0";
    string internal constant ERR_REWARD_EPOCH_START_TOO_SOON = "Reward epoch start too soon";
    string internal constant ERR_REWARD_EPOCH_NOT_INITIALIZED = "Reward epoch not initialized yet";
    string internal constant ERR_REWARD_EPOCH_START_CONDITION_INVALID = "Reward epoch start condition invalid";
    string internal constant ERR_REWARD_EPOCH_DURATION_CONDITION_INVALID = "Reward epoch duration condition invalid";
    string internal constant ERR_PRICE_EPOCH_DURATION_ZERO = "Price epoch 0";
    string internal constant ERR_VOTE_POWER_INTERVAL_FRACTION_ZERO = "Vote power interval fraction 0";
    string internal constant ERR_REVEAL_PRICE_EPOCH_DURATION_ZERO = "Reveal price epoch 0";
    string internal constant ERR_REVEAL_PRICE_EPOCH_TOO_LONG = "Reveal price epoch too long";
    string internal constant ERR_GOV_PARAMS_NOT_INIT_FOR_FTSOS = "Gov. params not initialized";
    string internal constant ERR_GOV_PARAMS_INVALID = "Gov. params invalid";
    string internal constant ERR_ASSET_FTSO_NOT_MANAGED = "Asset FTSO not managed by ftso manager";
    string internal constant ERR_NOT_FOUND = "Not found";
    string internal constant ERR_ALREADY_ADDED = "Already added";
    string internal constant ERR_FTSO_ASSET_FTSO_ZERO = "Asset ftsos list empty";
    string internal constant ERR_FTSO_EQUALS_ASSET_FTSO = "ftso equals asset ftso";
    string internal constant ERR_FTSO_SYMBOLS_MUST_MATCH = "FTSO symbols must match";
    string internal constant ERR_REWARD_EXPIRY_OFFSET_INVALID = "Reward expiry invalid";
    string internal constant ERR_MAX_TRUSTED_ADDRESSES_LENGTH_EXCEEDED = "Max trusted addresses length exceeded";
    string internal constant ERR_CLOSING_EXPIRED_REWARD_EPOCH_FAIL = "Unknown fail when closing expired";
    string internal constant ERR_SET_CLEANUP_BLOCK_FAIL = "unknown fail. setting cleanup block";
    string internal constant ERR_PRICE_EPOCH_FINALIZE_FAIL = "unknown fail. finalize price epoch";
    string internal constant ERR_DISTRIBUTE_REWARD_FAIL = "unknown fail. distribute rewards";
    string internal constant ERR_FALLBACK_FINALIZE_FAIL = "unknown fail. fallback finalize price epoch";
    string internal constant ERR_INIT_EPOCH_REVEAL_FAIL = "unknown fail. init epoch for reveal";
    string internal constant ERR_FALLBACK_INIT_EPOCH_REVEAL_FAIL = "unknown fail. fallback init epoch for reveal";

    bool public override active;
    RewardEpochData[] public rewardEpochs;
    address public lastRewardedFtsoAddress;

    FtsoManagerSettings.State public settings;

    // price epoch data
    uint256 immutable internal firstPriceEpochStartTs;
    uint256 immutable internal priceEpochDurationSeconds;
    uint256 immutable internal revealEpochDurationSeconds;
    uint256 internal lastUnprocessedPriceEpoch;
    uint256 internal lastUnprocessedPriceEpochRevealEnds;

    // reward Epoch data
    uint256 immutable public rewardEpochDurationSeconds;
    uint256 immutable public rewardEpochsStartTs;
    uint256 immutable internal votePowerIntervalFraction;
    uint256 internal currentRewardEpochEnds;
    uint256 internal nextRewardEpochToExpire;

    mapping(IIFtso => bool) internal managedFtsos;
    mapping(IIFtso => bool) internal notInitializedFtsos;

    IIPriceSubmitter public immutable priceSubmitter;
    IIFtsoRewardManager public rewardManager;
    IIFtsoRegistry public ftsoRegistry;
    IIVoterWhitelister public voterWhitelister;
    IISupply public supply;
    CleanupBlockNumberManager public cleanupBlockNumberManager;

    // indicates if lastUnprocessedPriceEpoch is initialized for reveal
    // it has to be finalized before new reward epoch can start
    bool private priceEpochInitialized;

    // fallback mode
    bool internal fallbackMode; // all ftsos in fallback mode
    mapping(IIFtso => bool) internal ftsoInFallbackMode;

    constructor(
        address _governance,
        FlareDaemon _flareDaemon,
        IIPriceSubmitter _priceSubmitter,
        uint256 _firstEpochStartTs,
        uint256 _priceEpochDurationSeconds,
        uint256 _revealEpochDurationSeconds,
        uint256 _rewardEpochsStartTs,
        uint256 _rewardEpochDurationSeconds,
        uint256 _votePowerIntervalFraction
    ) 
        GovernedAndFlareDaemonized(_governance, _flareDaemon)
    {
        require(block.timestamp >= _firstEpochStartTs, ERR_FIRST_EPOCH_START_TS_IN_FUTURE);
        require(_rewardEpochDurationSeconds > 0, ERR_REWARD_EPOCH_DURATION_ZERO);
        require(_priceEpochDurationSeconds > 0, ERR_PRICE_EPOCH_DURATION_ZERO);
        require(_revealEpochDurationSeconds > 0, ERR_REVEAL_PRICE_EPOCH_DURATION_ZERO);
        require(_votePowerIntervalFraction > 0, ERR_VOTE_POWER_INTERVAL_FRACTION_ZERO);

        require(_revealEpochDurationSeconds < _priceEpochDurationSeconds, ERR_REVEAL_PRICE_EPOCH_TOO_LONG);
        require(_firstEpochStartTs + _revealEpochDurationSeconds <= _rewardEpochsStartTs, 
            ERR_REWARD_EPOCH_START_TOO_SOON);
        require((_rewardEpochsStartTs - _revealEpochDurationSeconds - _firstEpochStartTs) %
            _priceEpochDurationSeconds == 0, ERR_REWARD_EPOCH_START_CONDITION_INVALID);
        require(_rewardEpochDurationSeconds % _priceEpochDurationSeconds == 0,
            ERR_REWARD_EPOCH_DURATION_CONDITION_INVALID);

        // reward epoch
        rewardEpochDurationSeconds = _rewardEpochDurationSeconds;
        rewardEpochsStartTs = _rewardEpochsStartTs;
        votePowerIntervalFraction = _votePowerIntervalFraction;
        currentRewardEpochEnds = _rewardEpochsStartTs + _rewardEpochDurationSeconds;

        // price epoch
        firstPriceEpochStartTs = _firstEpochStartTs;
        priceEpochDurationSeconds = _priceEpochDurationSeconds;
        revealEpochDurationSeconds = _revealEpochDurationSeconds;
        lastUnprocessedPriceEpochRevealEnds = _rewardEpochsStartTs;
        lastUnprocessedPriceEpoch = (_rewardEpochsStartTs - _firstEpochStartTs) / _priceEpochDurationSeconds;

        priceSubmitter = _priceSubmitter;
    }

    function setContractAddresses(
        IIFtsoRewardManager _rewardManager,
        IIFtsoRegistry _ftsoRegistry,
        IIVoterWhitelister _voterWhitelister,
        IISupply _supply,
        CleanupBlockNumberManager _cleanupBlockNumberManager
    )
        external
        onlyGovernance
    {
        rewardManager = _rewardManager;
        ftsoRegistry = _ftsoRegistry;
        voterWhitelister = _voterWhitelister;
        supply = _supply;
        cleanupBlockNumberManager = _cleanupBlockNumberManager;
    }
    
    /**
     * @notice Activates FTSO manager (daemonize() runs jobs)
     */
    function activate() external override onlyGovernance {
        active = true;
    }

    /**
     * @notice Runs task triggered by Daemon.
     * The tasks include the following by priority
     * - finalizePriceEpoch     
     * - Set governance parameters and initialize epochs
     * - finalizeRewardEpoch 
     */
    function daemonize() external override onlyFlareDaemon returns (bool) {
        // flare daemon trigger. once every block
        if (!active) return false;

        if (rewardEpochs.length == 0) {
            _initializeFirstRewardEpoch();
        } else {
            // all three conditions can be executed in the same block,
            // but are split into three `if else if` groups to reduce gas usage per one block
            if (priceEpochInitialized && lastUnprocessedPriceEpochRevealEnds <= block.timestamp) {
                // finalizes initialized price epoch if reveal period is over
                // sets priceEpochInitialized = false
                _finalizePriceEpoch();
            } else if (!priceEpochInitialized && currentRewardEpochEnds <= block.timestamp) {
                // initialized price epoch must be finalized before new reward epoch can start
                // advance currentRewardEpochEnds
                _finalizeRewardEpoch();
                _closeExpiredRewardEpochs();
                _cleanupOnRewardEpochFinalization();
            } else if (lastUnprocessedPriceEpochRevealEnds <= block.timestamp) {
                // new price epoch can be initialized after previous was finalized 
                // and after new reward epoch was started (if needed)
                // initializes price epoch and sets governance parameters on ftsos and price submitter
                // advance lastUnprocessedPriceEpochRevealEnds, sets priceEpochInitialized = true
                _initializeCurrentEpochFTSOStatesForReveal(); 
            }
        }
        return true;
    }

    function switchToFallbackMode() external override onlyFlareDaemon returns (bool) {
        if (!fallbackMode) {
            fallbackMode = true;
            emit FallbackMode(true);
            return true;
        }
        return false;
    }

     /**
     * @notice Adds FTSO to the list of rewarded FTSOs
     * All ftsos in multi asset ftso must be managed by this ftso manager
     */
    function addFtso(IIFtso _ftso) external override onlyGovernance {
        _addFtso(_ftso, true);
    }

    /**
     * @notice Removes FTSO from the list of the rewarded FTSOs - revert if ftso is used in multi asset ftso
     * @dev Deactivates _ftso
     */
    function removeFtso(IIFtso _ftso) external override onlyGovernance {
        uint256 ftsoIndex = ftsoRegistry.getFtsoIndex(_ftso.symbol());
        voterWhitelister.removeFtso(ftsoIndex);
        ftsoRegistry.removeFtso(_ftso);
        _cleanFtso(_ftso);
    }
    
    /**
     * @notice Replaces one ftso with another - symbols must match
     * All ftsos in multi asset ftso must be managed by this ftso manager
     * @dev Deactivates _ftsoToRemove
     */
    function replaceFtso(
        IIFtso _ftsoToRemove,
        IIFtso _ftsoToAdd,
        bool _copyCurrentPrice,
        bool _copyAssetOrAssetFtsos
    )
        external override
        onlyGovernance
    {
        // should compare strings but it is not supported - comparing hashes instead
        require(keccak256(abi.encode(_ftsoToRemove.symbol())) == keccak256(abi.encode(_ftsoToAdd.symbol())), 
            ERR_FTSO_SYMBOLS_MUST_MATCH);

        // Check if it already exists
        IIFtso[] memory availableFtsos = _getFtsos();
        uint256 len = availableFtsos.length;
        uint256 k = 0;
        while (k < len) {
            if (availableFtsos[k] == _ftsoToRemove) {
                break;
            }
            ++k;
        }
        if (k == len) {
            revert(ERR_NOT_FOUND);
        }

        if (_copyCurrentPrice) {
            (uint256 currentPrice, uint256 timestamp) = _ftsoToRemove.getCurrentPrice();
            _ftsoToAdd.updateInitialPrice(currentPrice, timestamp);
        }

        if (_copyAssetOrAssetFtsos) {
            IIVPToken asset = _ftsoToRemove.getAsset();
            if (address(asset) != address(0)) { // copy asset if exists
                _ftsoToAdd.setAsset(asset);
            } else { // copy assetFtsos list if not empty
                IIFtso[] memory assetFtsos = _ftsoToRemove.getAssetFtsos();
                if (assetFtsos.length > 0) {
                    _ftsoToAdd.setAssetFtsos(assetFtsos);
                }
            }
        }
        // Add without duplicate check
        _addFtso(_ftsoToAdd, false);
        
        // replace old contract with the new one in multi asset ftsos
        IIFtso[] memory contracts = _getFtsos();

        uint256 ftsosLen = contracts.length;
        for (uint256 i = 0; i < ftsosLen; i++) {
            IIFtso ftso = contracts[i];
            if (ftso == _ftsoToRemove) {
                continue;
            }
            IIFtso[] memory assetFtsos = ftso.getAssetFtsos();
            uint256 assetFtsosLen = assetFtsos.length;
            if (assetFtsosLen > 0) {
                bool changed = false;
                for (uint256 j = 0; j < assetFtsosLen; j++) {
                    if (assetFtsos[j] == _ftsoToRemove) {
                        assetFtsos[j] = _ftsoToAdd;
                        changed = true;
                    }
                }
                if (changed) {
                    ftso.setAssetFtsos(assetFtsos);
                }
            }
        }

        // cleanup old contract
        _cleanFtso(_ftsoToRemove);
    }
    
    /**
     * @notice Set asset for FTSO
     */
    function setFtsoAsset(IIFtso _ftso, IIVPToken _asset) external override onlyGovernance {
        _ftso.setAsset(_asset);
    }

    /**
     * @notice Set asset FTSOs for FTSO - all ftsos should already be managed by this ftso manager
     */
    function setFtsoAssetFtsos(IIFtso _ftso, IIFtso[] memory _assetFtsos) external override onlyGovernance {
        uint256 len = _assetFtsos.length;
        require (len > 0, ERR_FTSO_ASSET_FTSO_ZERO);
        for (uint256 i = 0; i < len; i++) {
            if (_ftso == _assetFtsos[i]) {
                revert(ERR_FTSO_EQUALS_ASSET_FTSO);
            }
        }

        _checkAssetFtsosAreManaged(_assetFtsos);
        _ftso.setAssetFtsos(_assetFtsos);
    }

    /**
     * @notice Set fallback mode
     */
    function setFallbackMode(bool _fallbackMode) external override onlyGovernance {
        fallbackMode = _fallbackMode;
        emit FallbackMode(_fallbackMode);
    }

    /**
     * @notice Set fallback mode for ftso
     */
    function setFtsoFallbackMode(IIFtso _ftso, bool _fallbackMode) external override onlyGovernance {
        require(managedFtsos[_ftso], ERR_NOT_FOUND);
        ftsoInFallbackMode[_ftso] = _fallbackMode;
        emit FtsoFallbackMode(_ftso, _fallbackMode);
    }

    /**
     * @notice Sets governance parameters for FTSOs
     */
    function setGovernanceParameters(
        uint256 _maxVotePowerNatThresholdFraction,
        uint256 _maxVotePowerAssetThresholdFraction,
        uint256 _lowAssetUSDThreshold,
        uint256 _highAssetUSDThreshold,
        uint256 _highAssetTurnoutThresholdBIPS,
        uint256 _lowNatTurnoutThresholdBIPS,
        uint256 _rewardExpiryOffsetSeconds,
        address[] memory _trustedAddresses
    )
        external override onlyGovernance 
    {
        require(_maxVotePowerNatThresholdFraction > 0, ERR_GOV_PARAMS_INVALID);
        require(_maxVotePowerAssetThresholdFraction > 0, ERR_GOV_PARAMS_INVALID);
        require(_highAssetUSDThreshold >= _lowAssetUSDThreshold, ERR_GOV_PARAMS_INVALID);
        require(_highAssetTurnoutThresholdBIPS <= 1e4, ERR_GOV_PARAMS_INVALID);
        require(_lowNatTurnoutThresholdBIPS <= 1e4, ERR_GOV_PARAMS_INVALID);
        require(_rewardExpiryOffsetSeconds > 0, ERR_REWARD_EXPIRY_OFFSET_INVALID);
        require(_trustedAddresses.length <= MAX_TRUSTED_ADDRESSES_LENGTH, ERR_MAX_TRUSTED_ADDRESSES_LENGTH_EXCEEDED);
        settings._setState(
            _maxVotePowerNatThresholdFraction,
            _maxVotePowerAssetThresholdFraction,
            _lowAssetUSDThreshold,
            _highAssetUSDThreshold,
            _highAssetTurnoutThresholdBIPS,
            _lowNatTurnoutThresholdBIPS,
            _rewardExpiryOffsetSeconds,
            _trustedAddresses
        );
    }

    function getVotePowerIntervalFraction() external view returns (uint256) {
        return votePowerIntervalFraction;
    }
    
    function getPriceSubmitter() external view override returns (IPriceSubmitter) {
        return priceSubmitter;
    }

    /**
     * @dev half-closed intervals - end time not included
     */
    function getCurrentPriceEpochData() external view override 
        returns (
            uint256 priceEpochId,
            uint256 priceEpochStartTimestamp,
            uint256 priceEpochEndTimestamp,
            uint256 priceEpochRevealEndTimestamp,
            uint256 currentTimestamp
        )
    {
        uint256 epochId = _getCurrentPriceEpochId();
        return (
            epochId,
            firstPriceEpochStartTs + epochId * priceEpochDurationSeconds,
            firstPriceEpochStartTs + (epochId + 1) * priceEpochDurationSeconds,
            firstPriceEpochStartTs + (epochId + 1) * priceEpochDurationSeconds + revealEpochDurationSeconds,
            block.timestamp
        );
    }
    
    /**
     * @notice Gets vote power block of the specified reward epoch
     * @param _rewardEpoch          Reward epoch sequence number
     */
    function getRewardEpochVotePowerBlock(uint256 _rewardEpoch) external view override returns (uint256) {
        return rewardEpochs[_rewardEpoch].votepowerBlock;
    }

    /*
     * @notice Returns the list of FTSOs
     */
    function getFtsos() external view override returns (IIFtso[] memory _ftsos) {
        return _getFtsos();
    }

    function getPriceEpochConfiguration() external view override 
        returns (
            uint256 _firstPriceEpochStartTs,
            uint256 _priceEpochDurationSeconds,
            uint256 _revealEpochDurationSeconds
        )
    {
        return (firstPriceEpochStartTs, priceEpochDurationSeconds, revealEpochDurationSeconds);
    }

    function getFallbackMode() external view override
        returns (
            bool _fallbackMode,
            IIFtso[] memory _ftsos,
            bool[] memory _ftsoInFallbackMode
        )
    {
        _fallbackMode = fallbackMode;
        _ftsos = _getFtsos();
        uint256 len = _ftsos.length;
        _ftsoInFallbackMode = new bool[](len);
        
        for (uint256 i = 0; i < len; i++) {
            _ftsoInFallbackMode[i] = ftsoInFallbackMode[_ftsos[i]];
        }
    }
        
    /**
     * @notice Returns current reward epoch index (one currently running)
     */
    function getCurrentRewardEpoch() public view override returns (uint256) {
        uint256 rewardEpochsLength = rewardEpochs.length;
        require(rewardEpochsLength != 0, ERR_REWARD_EPOCH_NOT_INITIALIZED);
        return rewardEpochsLength - 1;
    }

    function _addFtso(IIFtso _ftso, bool _addNewFtso) internal {
        require(settings.initialized, ERR_GOV_PARAMS_NOT_INIT_FOR_FTSOS);

        _checkAssetFtsosAreManaged(_ftso.getAssetFtsos());

        if (_addNewFtso) {
            // Check if symbol already exists in registry
            bytes32 symbol = keccak256(abi.encode(_ftso.symbol()));
            string[] memory supportedSymbols = ftsoRegistry.getSupportedSymbols();
            uint256 len = supportedSymbols.length;
            while (len > 0) {
                --len;
                if (keccak256(abi.encode(supportedSymbols[len])) == symbol) {
                    revert(ERR_ALREADY_ADDED);
                }
            }
        }

        _ftso.activateFtso(firstPriceEpochStartTs, priceEpochDurationSeconds, revealEpochDurationSeconds);

        // Set the vote power block
        if (rewardEpochs.length != 0) {
            _ftso.setVotePowerBlock(rewardEpochs[rewardEpochs.length - 1].votepowerBlock);
        }

        // Configure 
        _ftso.configureEpochs(
            settings.maxVotePowerNatThresholdFraction,
            settings.maxVotePowerAssetThresholdFraction,
            settings.lowAssetUSDThreshold,
            settings.highAssetUSDThreshold,
            settings.highAssetTurnoutThresholdBIPS,
            settings.lowNatTurnoutThresholdBIPS,
            settings.trustedAddresses
        );
        
        // skip first round of price finalization if price epoch was already initialized for reveal
        notInitializedFtsos[_ftso] = priceEpochInitialized;
        managedFtsos[_ftso] = true;
        uint256 ftsoIndex = ftsoRegistry.addFtso(_ftso);

        // When a new ftso is added we also add it to the voter whitelister contract
        if (_addNewFtso) {
            voterWhitelister.addFtso(ftsoIndex);
        }
        
        emit FtsoAdded(_ftso, true);
    }

    function _cleanFtso(IIFtso _ftso) internal {
        _ftso.deactivateFtso();
        // Since this is as mapping, we can also just delete it, as false is default value for non-existing keys
        delete ftsoInFallbackMode[_ftso];
        delete notInitializedFtsos[_ftso];
        delete managedFtsos[_ftso];
        _checkMultiAssetFtsosAreManaged(_getFtsos());
        emit FtsoAdded(_ftso, false);
    }

    /**
     * @notice Initializes first reward epoch. Also sets vote power block to FTSOs
     */
    function _initializeFirstRewardEpoch() internal {

        if (block.timestamp >= currentRewardEpochEnds - rewardEpochDurationSeconds) {
            IIFtso[] memory ftsos = _getFtsos();
            uint256 numFtsos = ftsos.length;
            // Prime the reward epoch array with a new reward epoch
            RewardEpochData memory epochData = RewardEpochData({
                votepowerBlock: block.number - 1,
                startBlock: block.number,
                startTimestamp: block.timestamp
            });

            rewardEpochs.push(epochData);

            for (uint256 i = 0; i < numFtsos; ++i) {
                ftsos[i].setVotePowerBlock(epochData.votepowerBlock);
            }
        }
    }

    /**
     * @notice Finalizes reward epoch
     */
    function _finalizeRewardEpoch() internal {
        IIFtso[] memory ftsos = _getFtsos();
        uint256 numFtsos = ftsos.length;

        uint256 lastRandom = block.timestamp;
        // Are there any FTSOs to process?
        if (numFtsos > 0) {
            for (uint256 i = 0; i < numFtsos; ++i) {
                lastRandom += ftsos[i].getCurrentRandom();
            }
        }

        lastRandom = uint256(keccak256(abi.encode(lastRandom)));
        // @dev when considering block boundary for vote power block:
        // - if far from now, it doesn't reflect last vote power changes
        // - if too small, possible loan attacks.     
        // IMPORTANT: currentRewardEpoch is actually the one just getting finalized!
        uint256 votepowerBlockBoundary = 
            (block.number - rewardEpochs[getCurrentRewardEpoch()].startBlock) / votePowerIntervalFraction;
        // note: votePowerIntervalFraction > 0
 
        if (votepowerBlockBoundary == 0) {
            votepowerBlockBoundary = 1;
        }
 
        //slither-disable-next-line weak-prng           // lastRandom calculated from ftso inputs
        uint256 votepowerBlocksAgo = lastRandom % votepowerBlockBoundary;
        // prevent block.number becoming votePowerBlock
        // if  lastRandom % votepowerBlockBoundary == 0  
        if (votepowerBlocksAgo == 0) {
            votepowerBlocksAgo = 1;
        }
        
        RewardEpochData memory epochData = RewardEpochData({
            votepowerBlock: block.number - votepowerBlocksAgo, 
            startBlock: block.number,
            startTimestamp: block.timestamp
        });
        rewardEpochs.push(epochData);
        for (uint256 i = 0; i < numFtsos; i++) {
            ftsos[i].setVotePowerBlock(epochData.votepowerBlock);
        }

        emit RewardEpochFinalized(epochData.votepowerBlock, epochData.startBlock);

        // Advance reward epoch end-time
        currentRewardEpochEnds += rewardEpochDurationSeconds;
    }

    /**
     * @notice Closes expired reward epochs
     */
    function _closeExpiredRewardEpochs() internal {
        uint256 currentRewardEpoch = getCurrentRewardEpoch();
        uint256 expiryThreshold = block.timestamp - settings.rewardExpiryOffsetSeconds;
        // NOTE: start time of (i+1)th reward epoch is the end time of i-th  
        // This loop is clearly bounded by the value currentRewardEpoch, which is
        // always kept to the value of rewardEpochs.length - 1 in code and this value
        // does not change in the loop.
        while (
            nextRewardEpochToExpire < currentRewardEpoch && 
            rewardEpochs[nextRewardEpochToExpire + 1].startTimestamp <= expiryThreshold) 
        {   // Note: Since nextRewardEpochToExpire + 1 starts at that time
            // nextRewardEpochToExpire ends strictly before expiryThreshold, 
            try rewardManager.closeExpiredRewardEpoch(nextRewardEpochToExpire) {
                nextRewardEpochToExpire++;
            } catch Error(string memory message) {
                // closing of expired failed, which is not critical
                // just emit event for diagnostics
                emit ClosingExpiredRewardEpochFailed(nextRewardEpochToExpire);
                addRevertError(address(rewardManager), message);
                // Do not proceed with the loop.
                break;
            } catch {
                emit ClosingExpiredRewardEpochFailed(nextRewardEpochToExpire);
                addRevertError(address(rewardManager), ERR_CLOSING_EXPIRED_REWARD_EPOCH_FAIL);
                // Do not proceed with the loop.
                break;
            }
        }
    }

    /**
     * @notice Performs any cleanup needed immediately after a reward epoch is finalized
     */
    function _cleanupOnRewardEpochFinalization() internal {
        if (address(cleanupBlockNumberManager) == address(0)) {
            emit CleanupBlockNumberManagerUnset();
            return;
        }
        uint256 cleanupBlock = rewardEpochs[nextRewardEpochToExpire].votepowerBlock;
        
        try cleanupBlockNumberManager.setCleanUpBlockNumber(cleanupBlock) {
        } catch Error(string memory message) {
            // cleanup block number manager call failed, which is not critical
            // just emit event for diagnostics
            emit CleanupBlockNumberManagerFailedForBlock(cleanupBlock);
            addRevertError(address(cleanupBlockNumberManager), message);
        } catch {
            emit CleanupBlockNumberManagerFailedForBlock(cleanupBlock);
            addRevertError(address(cleanupBlockNumberManager), ERR_SET_CLEANUP_BLOCK_FAIL);
        }
    }

    function _finalizePriceEpochFailed(IIFtso ftso, string memory message) internal {
        emit FinalizingPriceEpochFailed(
            ftso, 
            lastUnprocessedPriceEpoch, 
            IFtso.PriceFinalizationType.WEIGHTED_MEDIAN
        );

        addRevertError(address(ftso), message);

        _fallbackFinalizePriceEpoch(ftso);
    }

    /**
     * @notice Finalizes price epoch
     */
    function _finalizePriceEpoch() internal {
        IIFtso[] memory ftsos = _getFtsos();
        uint256 numFtsos = ftsos.length;

        // Are there any FTSOs to process?
        if (numFtsos > 0 && !fallbackMode) {
            // choose winning ftso
            uint256 chosenFtsoId;
            if (lastRewardedFtsoAddress == address(0)) {
                // pump not yet primed
                //slither-disable-next-line weak-prng           // only used for first epoch
                chosenFtsoId = uint256(keccak256(abi.encode(
                        block.difficulty, block.timestamp
                    ))) % numFtsos;
            } else {
                // at least one finalize with real FTSO
                uint256 currentRandomSum = 0;
                for (uint256 i = 0; i < numFtsos; i++) {
                    currentRandomSum += ftsos[i].getCurrentRandom(); // may overflow but it is still ok
                }
                //slither-disable-next-line weak-prng           // ftso random calculated safely from inputs
                chosenFtsoId = uint256(keccak256(abi.encode(
                        currentRandomSum, block.timestamp
                    ))) % numFtsos;
            }
            address[] memory addresses;
            uint256[] memory weights;
            uint256 totalWeight;

            // On the off chance that the winning FTSO does not have any
            // recipient within the truncated price distribution to
            // receive rewards, find the next FTSO that does have reward
            // recipients and declare it the winner. Start with the next ftso.
            bool wasDistributed = false;
            address rewardedFtsoAddress = address(0);
            for (uint256 i = 0; i < numFtsos; i++) {
                //slither-disable-next-line weak-prng           // not a random, just choosing next
                uint256 id = (chosenFtsoId + i) % numFtsos;
                IIFtso ftso = ftsos[id];

                // skip finalizing ftso, as it is not initialized for reveal and tx would revert
                if (notInitializedFtsos[ftso]) {
                    delete notInitializedFtsos[ftso];
                    continue;
                }

                try ftso.finalizePriceEpoch(lastUnprocessedPriceEpoch, !wasDistributed) returns (
                    address[] memory _addresses,
                    uint256[] memory _weights,
                    uint256 _totalWeight
                ) {
                    if (!wasDistributed && _addresses.length > 0) { // change also in FTSO if condition changes
                        (addresses, weights, totalWeight) = (_addresses, _weights, _totalWeight);
                        wasDistributed = true;
                        rewardedFtsoAddress = address(ftso);
                    }
                } catch Error(string memory message) {
                    _finalizePriceEpochFailed(ftso, message);
                } catch {
                    _finalizePriceEpochFailed(ftso, ERR_PRICE_EPOCH_FINALIZE_FAIL);
                }
            }

            uint256 currentRewardEpoch = getCurrentRewardEpoch();

            if (wasDistributed) {
                try rewardManager.distributeRewards(
                    addresses,
                    weights,
                    totalWeight,
                    lastUnprocessedPriceEpoch,
                    rewardedFtsoAddress,
                    priceEpochDurationSeconds,
                    currentRewardEpoch,
                    _getPriceEpochEndTime(lastUnprocessedPriceEpoch) - 1, // actual end time (included)
                    rewardEpochs[currentRewardEpoch].votepowerBlock) {
                } catch Error(string memory message) {
                    emit DistributingRewardsFailed(rewardedFtsoAddress, lastUnprocessedPriceEpoch);
                    addRevertError(address(rewardManager), message);
                } catch {
                    emit DistributingRewardsFailed(rewardedFtsoAddress, lastUnprocessedPriceEpoch);
                    addRevertError(address(rewardManager), ERR_DISTRIBUTE_REWARD_FAIL);
                }
            }

            lastRewardedFtsoAddress = rewardedFtsoAddress;
            emit PriceEpochFinalized(rewardedFtsoAddress, currentRewardEpoch);
        } else {
            // only for fallback mode
            for (uint256 i = 0; i < numFtsos; i++) {
                IIFtso ftso = ftsos[i];
                // skip finalizing ftso, as it is not initialized for reveal and tx would revert
                if (notInitializedFtsos[ftso]) {
                    delete notInitializedFtsos[ftso];
                    continue;
                }
                _fallbackFinalizePriceEpoch(ftso);
            }

            lastRewardedFtsoAddress = address(0);
            emit PriceEpochFinalized(address(0), getCurrentRewardEpoch());
        }
        
        priceEpochInitialized = false;
    }

    function _fallbackFinalizePriceEpochFailed(IIFtso _ftso, string memory message) internal {
        emit FinalizingPriceEpochFailed(
            _ftso, 
            lastUnprocessedPriceEpoch, 
            IFtso.PriceFinalizationType.TRUSTED_ADDRESSES
        );
        addRevertError(address(_ftso), message);

        // if reverts we want to propagate up to daemon
        _ftso.forceFinalizePriceEpoch(lastUnprocessedPriceEpoch);
    }

    function _fallbackFinalizePriceEpoch(IIFtso _ftso) internal {
        try _ftso.averageFinalizePriceEpoch(lastUnprocessedPriceEpoch) {
        } catch Error(string memory message) {
            _fallbackFinalizePriceEpochFailed(_ftso, message);
        } catch {
            _fallbackFinalizePriceEpochFailed(_ftso, ERR_FALLBACK_FINALIZE_FAIL);
        }
    }

    /**
     * @notice Initializes epoch states in FTSOs for reveal. 
     * Prior to initialization it sets governance parameters, if 
     * governance has changed them. It also sets price submitter trusted addresses.
     */
    function _initializeCurrentEpochFTSOStatesForReveal() internal {
        if (settings.changed) {
            priceSubmitter.setTrustedAddresses(settings.trustedAddresses);
        }

        IIFtso[] memory ftsos = _getFtsos();
        uint256 numFtsos = ftsos.length;

        // circulating supply is used only when ftso is not in fallback mode
        uint256 circulatingSupplyNat;
        if (numFtsos > 0 && !fallbackMode) {
            uint256 votePowerBlock = rewardEpochs[rewardEpochs.length - 1].votepowerBlock;
            circulatingSupplyNat = supply.getCirculatingSupplyAtCached(votePowerBlock);
        }

        for (uint256 i = 0; i < numFtsos; i++) {
            IIFtso ftso = ftsos[i];
            if (settings.changed) {
                ftso.configureEpochs(
                    settings.maxVotePowerNatThresholdFraction,
                    settings.maxVotePowerAssetThresholdFraction,
                    settings.lowAssetUSDThreshold,
                    settings.highAssetUSDThreshold,
                    settings.highAssetTurnoutThresholdBIPS,
                    settings.lowNatTurnoutThresholdBIPS,
                    settings.trustedAddresses
                );
            }

            try ftso.initializeCurrentEpochStateForReveal(
                circulatingSupplyNat,
                fallbackMode || ftsoInFallbackMode[ftso]) {
            } catch Error(string memory message) {
                _initializeCurrentEpochStateForRevealFailed(ftso, message);
            } catch {
                _initializeCurrentEpochStateForRevealFailed(ftso, ERR_INIT_EPOCH_REVEAL_FAIL);
            }

        }
        settings.changed = false;

        // Advance price epoch id and end-time
        uint256 currentPriceEpochId = _getCurrentPriceEpochId();
        lastUnprocessedPriceEpoch = currentPriceEpochId;
        lastUnprocessedPriceEpochRevealEnds = _getPriceEpochRevealEndTime(currentPriceEpochId);

        priceEpochInitialized = true;
    }

    function _initializeCurrentEpochStateForRevealFailed(IIFtso ftso, string memory message) internal {
        emit InitializingCurrentEpochStateForRevealFailed(ftso, _getCurrentPriceEpochId());
        addRevertError(address(ftso), message);

        // if it was already called with fallback = true, just mark as not initialized, else retry
        if (fallbackMode || ftsoInFallbackMode[ftso]) {
            notInitializedFtsos[ftso] = true;
        } else {
            try ftso.initializeCurrentEpochStateForReveal(0, true) {
            } catch Error(string memory message1) {
                notInitializedFtsos[ftso] = true;
                emit InitializingCurrentEpochStateForRevealFailed(ftso, _getCurrentPriceEpochId());
                addRevertError(address(ftso), message1);
            } catch {
                notInitializedFtsos[ftso] = true;
                emit InitializingCurrentEpochStateForRevealFailed(ftso, _getCurrentPriceEpochId());
                addRevertError(address(ftso), ERR_FALLBACK_INIT_EPOCH_REVEAL_FAIL);
            }
        }
    }

    /**
     * @notice Check if asset ftsos are managed by this ftso manager, revert otherwise
     */
    function _checkAssetFtsosAreManaged(IIFtso[] memory _assetFtsos) internal view {
        uint256 len = _assetFtsos.length;
        for (uint256 i = 0; i < len; i++) {
            if (!managedFtsos[_assetFtsos[i]]) {
                revert(ERR_ASSET_FTSO_NOT_MANAGED);
            }
        }
    }

    /**
     * @notice Check if all multi asset ftsos are managed by this ftso manager, revert otherwise
     */
    function _checkMultiAssetFtsosAreManaged(IIFtso[] memory _ftsos) internal view {
        uint256 len = _ftsos.length;
        for (uint256 i = 0; i < len; i++) {
            _checkAssetFtsosAreManaged(_ftsos[i].getAssetFtsos());
        }
    }

    /**
     * @notice Returns price epoch reveal end time.
     * @param _priceEpochId The price epoch id.
     * @dev half-closed interval - end time not included
     */
    function _getPriceEpochRevealEndTime(uint256 _priceEpochId) internal view returns (uint256) {
        return firstPriceEpochStartTs + (_priceEpochId + 1) * priceEpochDurationSeconds + revealEpochDurationSeconds;
    }

    /**
     * @notice Returns price epoch end time.
     * @param _forPriceEpochId The price epoch id of the end time to fetch.
     * @dev half-closed interval - end time not included
     */
    function _getPriceEpochEndTime(uint256 _forPriceEpochId) internal view returns (uint256) {
        return firstPriceEpochStartTs + ((_forPriceEpochId + 1) * priceEpochDurationSeconds);
    }

    /**
     * @notice Returns current price epoch id. The calculation in this function
     * should fully match to definition of current epoch id in FTSO contracts.
     */
    function _getCurrentPriceEpochId() internal view returns (uint256) {
        return (block.timestamp - firstPriceEpochStartTs) / priceEpochDurationSeconds;
    }

    function _getFtsos() private view returns (IIFtso[] memory) {
        return ftsoRegistry.getSupportedFtsos();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../../ftso/interface/IIFtso.sol";
import "../../userInterfaces/IFtsoManager.sol";
import "../../token/interface/IIVPToken.sol";


interface IIFtsoManager is IFtsoManager {

    event ClosingExpiredRewardEpochFailed(uint256 _rewardEpoch);
    event CleanupBlockNumberManagerUnset();
    event CleanupBlockNumberManagerFailedForBlock(uint256 blockNumber);

    function activate() external;

    function setGovernanceParameters(
        uint256 _maxVotePowerNatThresholdFraction,
        uint256 _maxVotePowerAssetThresholdFraction,
        uint256 _lowAssetUSDThreshold,
        uint256 _highAssetUSDThreshold,
        uint256 _highAssetTurnoutThresholdBIPS,
        uint256 _lowNatTurnoutThresholdBIPS,
        uint256 _rewardExpiryOffsetSeconds,
        address[] memory _trustedAddresses
    ) external;

    function addFtso(IIFtso _ftso) external;

    function removeFtso(IIFtso _ftso) external;

    function replaceFtso(
        IIFtso _ftsoToRemove,
        IIFtso _ftsoToAdd,
        bool copyCurrentPrice,
        bool copyAssetOrAssetFtsos
    ) external;

    function setFtsoAsset(IIFtso _ftso, IIVPToken _asset) external;

    function setFtsoAssetFtsos(IIFtso _ftso, IIFtso[] memory _assetFtsos) external;

    function setFallbackMode(bool _fallbackMode) external;

    function setFtsoFallbackMode(IIFtso _ftso, bool _fallbackMode) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../../genesis/interface/IFtsoGenesis.sol";
import "../../userInterfaces/IFtso.sol";
import "../../token/interface/IIVPToken.sol";


interface IIFtso is IFtso, IFtsoGenesis {

    /// function finalizePriceReveal
    /// called by reward manager only on correct timing.
    /// if price reveal period for epoch x ended. finalize.
    /// iterate list of price submissions
    /// find weighted median
    /// find adjucant 50% of price submissions.
    /// Allocate reward for any price submission which is same as a "winning" submission
    function finalizePriceEpoch(uint256 _epochId, bool _returnRewardData) external
        returns(
            address[] memory _eligibleAddresses,
            uint256[] memory _natWeights,
            uint256 _totalNatWeight
        );

    function averageFinalizePriceEpoch(uint256 _epochId) external;

    function forceFinalizePriceEpoch(uint256 _epochId) external;

    // activateFtso will be called by ftso manager once ftso is added 
    // before this is done, FTSO can't run
    function activateFtso(
        uint256 _firstEpochStartTs,
        uint256 _epochPeriod,
        uint256 _revealPeriod
    ) external;

    function deactivateFtso() external;

    // update initial price and timestamp - only if not active
    function updateInitialPrice(uint256 _initialPriceUSD, uint256 _initialPriceTimestamp) external;

    function configureEpochs(
        uint256 _maxVotePowerNatThresholdFraction,
        uint256 _maxVotePowerAssetThresholdFraction,
        uint256 _lowAssetUSDThreshold,
        uint256 _highAssetUSDThreshold,
        uint256 _highAssetTurnoutThresholdBIPS,
        uint256 _lowNatTurnoutThresholdBIPS,
        address[] memory _trustedAddresses
    ) external;

    function setAsset(IIVPToken _asset) external;

    function setAssetFtsos(IIFtso[] memory _assetFtsos) external;

    // current vote power block will update per reward epoch. 
    // the FTSO doesn't have notion of reward epochs.
    // reward manager only can set this data. 
    function setVotePowerBlock(uint256 _blockNumber) external;

    function initializeCurrentEpochStateForReveal(uint256 _circulatingSupplyNat, bool _fallbackMode) external;
  
    /**
     * @notice Returns the FTSO asset
     * @dev Asset is null in case of multi-asset FTSO
     */
    function getAsset() external view returns (IIVPToken);

    /**
     * @notice Returns the Asset FTSOs
     * @dev AssetFtsos is not null only in case of multi-asset FTSO
     */
    function getAssetFtsos() external view returns (IIFtso[] memory);

    /**
     * @notice Returns current configuration of epoch state
     * @return _maxVotePowerNatThresholdFraction        High threshold for native token vote power per voter
     * @return _maxVotePowerAssetThresholdFraction      High threshold for asset vote power per voter
     * @return _lowAssetUSDThreshold            Threshold for low asset vote power
     * @return _highAssetUSDThreshold           Threshold for high asset vote power
     * @return _highAssetTurnoutThresholdBIPS   Threshold for high asset turnout
     * @return _lowNatTurnoutThresholdBIPS      Threshold for low nat turnout
     * @return _trustedAddresses                Trusted addresses - use their prices if low nat turnout is not achieved
     */
    function epochsConfiguration() external view 
        returns (
            uint256 _maxVotePowerNatThresholdFraction,
            uint256 _maxVotePowerAssetThresholdFraction,
            uint256 _lowAssetUSDThreshold,
            uint256 _highAssetUSDThreshold,
            uint256 _highAssetTurnoutThresholdBIPS,
            uint256 _lowNatTurnoutThresholdBIPS,
            address[] memory _trustedAddresses
        );

    /**
     * @notice Returns parameters necessary for approximately replicating vote weighting.
     * @return _assets                  the list of Assets that are accounted in vote
     * @return _assetMultipliers        weight of each asset in (multiasset) ftso, mutiplied by TERA
     * @return _totalVotePowerNat       total native token vote power at block
     * @return _totalVotePowerAsset     total combined asset vote power at block
     * @return _assetWeightRatio        ratio of combined asset vp vs. native token vp (in BIPS)
     * @return _votePowerBlock          vote powewr block for given epoch
     */
    function getVoteWeightingParameters() external view 
        returns (
            IIVPToken[] memory _assets,
            uint256[] memory _assetMultipliers,
            uint256 _totalVotePowerNat,
            uint256 _totalVotePowerAsset,
            uint256 _assetWeightRatio,
            uint256 _votePowerBlock
        );

    function wNat() external view returns (IIVPToken);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


/**
 * @title A library used for Ftso Manager settings management
 */
library FtsoManagerSettings {
    struct State {
        // struct holding settings related to FTSOs
        // configurable settings
        uint256 maxVotePowerNatThresholdFraction; // high threshold for native token vote power per voter
        uint256 maxVotePowerAssetThresholdFraction; // high threshold for asset vote power per voter
        uint256 lowAssetUSDThreshold; // threshold for low asset vote power (in scaled USD)
        uint256 highAssetUSDThreshold; // threshold for high asset vote power (in scaled USD)
        uint256 highAssetTurnoutThresholdBIPS; // threshold for high asset turnout (in BIPS)
        // actual vote power in (W)NATs / total native token circulating supply (in BIPS)
        uint256 lowNatTurnoutThresholdBIPS;
        uint256 rewardExpiryOffsetSeconds; // Reward epoch closed earlier than 
                                           //block.timestamp - rewardExpiryOffsetSeconds expire
        address[] trustedAddresses; //trusted addresses will be used as a fallback mechanism for setting the price
        bool changed;
        bool initialized;
    }

    function _setState (
        State storage _state,
        uint256 _maxVotePowerNatThresholdFraction,
        uint256 _maxVotePowerAssetThresholdFraction,
        uint256 _lowAssetUSDThreshold,
        uint256 _highAssetUSDThreshold,
        uint256 _highAssetTurnoutThresholdBIPS,
        uint256 _lowNatTurnoutThresholdBIPS,
        uint256 _rewardExpiryOffsetSeconds,
        address[] memory _trustedAddresses
    ) 
        internal
    {
        if (_state.maxVotePowerNatThresholdFraction != _maxVotePowerNatThresholdFraction) {
            _state.changed = true;
            _state.maxVotePowerNatThresholdFraction = _maxVotePowerNatThresholdFraction;
        }
        if (_state.maxVotePowerAssetThresholdFraction != _maxVotePowerAssetThresholdFraction) {
            _state.changed = true;
            _state.maxVotePowerAssetThresholdFraction = _maxVotePowerAssetThresholdFraction;
        }
        if (_state.lowAssetUSDThreshold != _lowAssetUSDThreshold) {
            _state.changed = true;
            _state.lowAssetUSDThreshold = _lowAssetUSDThreshold;
        }
        if (_state.highAssetUSDThreshold != _highAssetUSDThreshold) {
            _state.changed = true;
            _state.highAssetUSDThreshold = _highAssetUSDThreshold;
        }
        if (_state.highAssetTurnoutThresholdBIPS != _highAssetTurnoutThresholdBIPS) {
            _state.changed = true;
            _state.highAssetTurnoutThresholdBIPS = _highAssetTurnoutThresholdBIPS;
        }
        if (_state.lowNatTurnoutThresholdBIPS != _lowNatTurnoutThresholdBIPS) {
            _state.changed = true;
            _state.lowNatTurnoutThresholdBIPS = _lowNatTurnoutThresholdBIPS;
        }
        if (_state.rewardExpiryOffsetSeconds != _rewardExpiryOffsetSeconds) {
            _state.changed = true;
            _state.rewardExpiryOffsetSeconds = _rewardExpiryOffsetSeconds;
        }
        if (_state.trustedAddresses.length != _trustedAddresses.length) {
            _state.trustedAddresses = _trustedAddresses;
            _state.changed = true;
        } else {
            for (uint i = 0; i < _trustedAddresses.length; i++) {
                if (_state.trustedAddresses[i] != _trustedAddresses[i]) {
                    _state.changed = true;
                    _state.trustedAddresses[i] = _trustedAddresses[i];
                }
            }
        }
        _state.initialized = true;
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

import "../../userInterfaces/IPriceSubmitter.sol";
interface IIPriceSubmitter is IPriceSubmitter {

    /**
     * Sets ftso registry, voter whitelist and ftso manager contracts.
     * Only governance can call this method.
     * If replacing the registry or the whitelist and the old one is not empty, make sure to replicate the state,
     * otherwise internal whitelist bitmaps won't match.
     */
    function setContractAddresses(
        IFtsoRegistryGenesis _ftsoRegistry,
        address _voterWhitelister,
        address _ftsoManager
    ) external;

    /**
     * Set trusted addresses that are always allowed to submit and reveal.
     * Only ftso manager can call this method.
     */
    function setTrustedAddresses(address[] memory _trustedAddresses) external;

    /**
     * Called from whitelister when new voter has been whitelisted.
     */
    function voterWhitelisted(address _voter, uint256 _ftsoIndex) external;
    
    /**
     * Called from whitelister when one or more voters have been removed.
     */
    function votersRemovedFromWhitelist(address[] memory _voters, uint256 _ftsoIndex) external;

    /**
     * Returns a list of trusted addresses that are always allowed to submit and reveal.
     */
    function getTrustedAddresses() external view returns (address[] memory);
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
pragma solidity 0.7.6;

import "../../userInterfaces/IFtsoRewardManager.sol";

interface IIFtsoRewardManager is IFtsoRewardManager {

    event DailyAuthorizedInflationSet(uint256 authorizedAmountWei);
    event InflationReceived(uint256 amountReceivedWei);

    function activate() external;
    function deactivate() external;
    function closeExpiredRewardEpoch(uint256 _rewardEpochId) external;

    function distributeRewards(
        address[] memory addresses,
        uint256[] memory weights,
        uint256 totalWeight,
        uint256 epochId,
        address ftso,
        uint256 priceEpochDurationSeconds,
        uint256 currentRewardEpoch,
        uint256 priceEpochEndTime,
        uint256 votePowerBlock
    ) external;

    /**
     * @notice Returns the information on unclaimed reward of `_dataProvider` for `_rewardEpoch`
     * @param _rewardEpoch          reward epoch number
     * @param _dataProvider         address representing the data provider
     * @return _amount              number representing the unclaimed amount
     * @return _weight              number representing the share that has not yet been claimed
     */
    function getUnclaimedReward(
        uint256 _rewardEpoch,
        address _dataProvider
    )
        external view
        returns (
            uint256 _amount,
            uint256 _weight
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../../governance/implementation/Governed.sol";
import "../../token/interface/IICleanable.sol";


/**
 * @title Token history cleanup manager
 * @notice Maintains the list of cleanable tokens for which history cleanup can be collectively cleaned u 
 */
contract CleanupBlockNumberManager is Governed {

    string internal constant ERR_CONTRACT_NOT_FOUND = "contract not found";
    string internal constant ERR_TRIGGER_CONTRACT_OR_GOVERNANCE_ONLY = "trigger or governance only";

    IICleanable[] public registeredTokens;
    address public triggerContract;

    event RegistrationUpdated (IICleanable theContract, bool add);
    event CleanupBlockNumberSet (IICleanable theContract, uint256 blockNumber, bool success);
        
    modifier onlyTriggerOrGovernance {
        require(
            msg.sender == address(triggerContract) || 
            msg.sender == governance, ERR_TRIGGER_CONTRACT_OR_GOVERNANCE_ONLY
        );
        _;
    }

    constructor(address _governance) Governed(_governance) {
        /* empty block */
    }

    /**
     * @notice Sets trigger contract address. 
     * @dev Usually this is FTSO Manager contract address.
     */
    function setTriggerContractAddress(address _triggerContract) external onlyGovernance {
        triggerContract = _triggerContract;
    }
    /**
     * @notice Register a contract of which history cleanup index is to be managed
     * @param _cleanableToken     The address of the contract to be managed.
     * @dev when using this function take care that call of setCleanupBlockNumber
     * is permitted by this object
     */
    function registerToken(IICleanable _cleanableToken) external onlyGovernance {
        uint256 len = registeredTokens.length;

        for (uint256 i = 0; i < len; i++) {
            if (_cleanableToken == registeredTokens[i]) {
                return; // already registered
            }
        }

        registeredTokens.push(_cleanableToken);
        emit RegistrationUpdated (_cleanableToken, true);
    }

    /**
     * @notice Unregiseter a contract from history cleanup index management
     * @param _cleanableToken     The address of the contract to unregister.
     */
    function unregisterToken(IICleanable _cleanableToken) external onlyGovernance {        
        uint256 len = registeredTokens.length;

        for (uint256 i = 0; i < len; i++) {
            if (_cleanableToken == registeredTokens[i]) {
                registeredTokens[i] = registeredTokens[len -1];
                registeredTokens.pop();
                emit RegistrationUpdated (_cleanableToken, false);
                return;
            }
        }

        revert(ERR_CONTRACT_NOT_FOUND);
    }

    /**
     * @notice Sets clean up block number on managed cleanable tokens
     * @param _blockNumber cleanup block number
     */
    function setCleanUpBlockNumber(uint256 _blockNumber) external onlyTriggerOrGovernance {
        uint256 len = registeredTokens.length;
        for (uint256 i = 0; i < len; i++) {
            try registeredTokens[i].setCleanupBlockNumber(_blockNumber) {
                emit CleanupBlockNumberSet(registeredTokens[i], _blockNumber, true);
            } catch {
                emit CleanupBlockNumberSet(registeredTokens[i], _blockNumber, false);
            }
        }
    }
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


/**
 * @title Revert Error Tracking
 * @notice A contract to track and store revert errors
 **/
contract RevertErrorTracking {

    struct RevertedError {
        uint192 lastErrorBlock;
        uint64 numErrors;
        address fromContract;
        uint64 errorTypeIndex;
        string errorMessage;
    }

    struct LastErrorData {
        uint192 totalRevertedErrors;
        uint64 lastErrorTypeIndex;
    }

    string internal constant INDEX_TOO_HIGH = "start index high";

    mapping(bytes32 => RevertedError) internal revertedErrors;
    bytes32 [] internal revertErrorHashes;
    LastErrorData public errorData;

    event ContractRevertError(address theContract, uint256 atBlock, string theMessage);

    /**
     * @notice Returns latest reverted error
     * @return _lastErrorBlock         Block number of last reverted error
     * @return _numErrors              Number of times same error with same contract address has been reverted
     * @return _errorString            Revert error message
     * @return _erroringContract       Array of addresses of the reverting contracts
     * @return _totalRevertedErrors    Total number of revert errors across all contracts
     */
    function showLastRevertedError () external view 
        returns(
            uint256[] memory _lastErrorBlock,
            uint256[] memory _numErrors,
            string[] memory _errorString,
            address[] memory _erroringContract,
            uint256 _totalRevertedErrors
        )
    {
        return showRevertedErrors(errorData.lastErrorTypeIndex, 1);
    }
    
    /**
     * @notice Adds caught error to reverted errors mapping
     * @param revertedContract         Address of the reverting contract
     * @param message                  Reverte message
     */
    function addRevertError(address revertedContract, string memory message) public {
        bytes32 errorStringHash = keccak256(abi.encode(revertedContract, message));

        revertedErrors[errorStringHash].numErrors += 1;
        revertedErrors[errorStringHash].lastErrorBlock = uint192(block.number);
        emit ContractRevertError(revertedContract, block.number, message);
        errorData.totalRevertedErrors += 1;
        
        if (revertedErrors[errorStringHash].numErrors > 1) {
            // not first time this errors
            return;
        }

        // first time we recieve this error string.
        revertErrorHashes.push(errorStringHash);
        revertedErrors[errorStringHash].fromContract = revertedContract;
        revertedErrors[errorStringHash].errorMessage = message;
        revertedErrors[errorStringHash].errorTypeIndex = uint64(revertErrorHashes.length - 1);

        errorData.lastErrorTypeIndex = revertedErrors[errorStringHash].errorTypeIndex;        
    }

    /**
     * @notice Returns latest reverted error
     * @param startIndex               Starting index in the error list array
     * @param numErrorTypesToShow      Number of error types to show
     * @return _lastErrorBlock         Array of last block number this error reverted
     * @return _numErrors              Number of times the same error with same contract address has been tracked
     * @return _errorString            Array of revert error messages
     * @return _erroringContract       Array of addresses of the reverting contracts
     * @return _totalRevertedErrors    Total number of errors reverted across all contracts
     */
    function showRevertedErrors (uint startIndex, uint numErrorTypesToShow) public view 
        returns(
            uint256[] memory _lastErrorBlock,
            uint256[] memory _numErrors,
            string[] memory _errorString,
            address[] memory _erroringContract,
            uint256 _totalRevertedErrors
        )
    {
        require(startIndex < revertErrorHashes.length, INDEX_TOO_HIGH);
        uint256 numReportElements = 
            revertErrorHashes.length >= startIndex + numErrorTypesToShow ?
            numErrorTypesToShow :
            revertErrorHashes.length - startIndex;

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
            bytes32 hash = revertErrorHashes[startIndex + i];

            _lastErrorBlock[i] = revertedErrors[hash].lastErrorBlock;
            _numErrors[i] = revertedErrors[hash].numErrors;
            _errorString[i] = revertedErrors[hash].errorMessage;
            _erroringContract[i] = revertedErrors[hash].fromContract;
        }
        _totalRevertedErrors = errorData.totalRevertedErrors;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../../ftso/interface/IIFtso.sol";
import "../../ftso/interface/IIFtsoManager.sol";
import "../../userInterfaces/IFtsoRegistry.sol";


interface IIFtsoRegistry is IFtsoRegistry {

    function setFtsoManagerAddress(IIFtsoManager _ftsoManager) external;

    // returns ftso index
    function addFtso(IIFtso _ftsoContract) external returns(uint256);

    function removeFtso(IIFtso _ftso) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../../userInterfaces/IVoterWhitelister.sol";


interface IIVoterWhitelister is IVoterWhitelister {
    /**
     * Set the maximum number of voters in the whitelist for FTSO at index `_ftsoIndex`.
     * Possibly removes several voters with the least votepower from the whitelist.
     * Only governance can call this method.
     */
    function setMaxVotersForFtso(uint256 _ftsoIndex, uint256 _newMaxVoters) external;

    /**
     * Set the maximum number of voters in the whitelist for a new FTSO.
     * Only governance can call this method.
     */
    function setDefaultMaxVotersForFtso(uint256 _defaultMaxVotersForFtso) external;

    /**
     * Create whitelist with default size for ftso.
     * Only ftso manager can call this method.
     */
    function addFtso(uint256 _ftsoIndex) external;
    
    /**
     * Clear whitelist for ftso at `_ftsoIndex`.
     * Only ftso manager can call this method.
     */
    function removeFtso(uint256 _ftsoIndex) external;

    /**
     * Remove `_trustedAddress` from whitelist for ftso at `_ftsoIndex`.
     */
    function removeTrustedAddressFromWhitelist(address _trustedAddress, uint256 _ftsoIndex) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IPriceSubmitter.sol";
import "../ftso/interface/IIFtso.sol";

interface IFtsoManager {

    event FtsoAdded(IIFtso ftso, bool add);
    event FallbackMode(bool fallbackMode);
    event FtsoFallbackMode(IIFtso ftso, bool fallbackMode);
    event RewardEpochFinalized(uint256 votepowerBlock, uint256 startBlock);
    event PriceEpochFinalized(address chosenFtso, uint256 rewardEpochId);
    event InitializingCurrentEpochStateForRevealFailed(IIFtso ftso, uint256 epochId);
    event FinalizingPriceEpochFailed(IIFtso ftso, uint256 epochId, IFtso.PriceFinalizationType failingType);
    event DistributingRewardsFailed(address ftso, uint256 epochId);

    function active() external view returns (bool);
    
    function getPriceSubmitter() external view returns (IPriceSubmitter);

    function getCurrentRewardEpoch() external view returns (uint256);

    function getRewardEpochVotePowerBlock(uint256 _rewardEpoch) external view returns (uint256);
    
    function getCurrentPriceEpochData() external view 
        returns (
            uint256 _priceEpochId,
            uint256 _priceEpochStartTimestamp,
            uint256 _priceEpochEndTimestamp,
            uint256 _priceEpochRevealEndTimestamp,
            uint256 _currentTimestamp
        );

    function getFtsos() external view returns (IIFtso[] memory _ftsos);

    function getPriceEpochConfiguration() external view 
        returns (
            uint256 _firstPriceEpochStartTs,
            uint256 _priceEpochDurationSeconds,
            uint256 _revealEpochDurationSeconds
        );

    function getFallbackMode() external view 
        returns (
            bool _fallbackMode,
            IIFtso[] memory _ftsos,
            bool[] memory _ftsoInFallbackMode
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../../userInterfaces/IVPToken.sol";
import "../../userInterfaces/IGovernanceVotePower.sol";
import "./IIVPContract.sol";
import "./IIGovernanceVotePower.sol";
import "./IICleanable.sol";

interface IIVPToken is IVPToken, IICleanable {
    /**
     * Sets new governance vote power contract that allows token owners to participate in governance voting
     * and delegate governance vote power. 
     */
    function setGovernanceVotePower(IIGovernanceVotePower _governanceVotePower) external;
    
    /**
    * @notice Get the total vote power at block `_blockNumber` using cache.
    *   It tries to read the cached value and if not found, reads the actual value and stores it in cache.
    *   Can only be used if `_blockNumber` is in the past, otherwise reverts.    
    * @param _blockNumber The block number at which to fetch.
    * @return The total vote power at the block (sum of all accounts' vote powers).
    */
    function totalVotePowerAtCached(uint256 _blockNumber) external returns(uint256);
    
    /**
    * @notice Get the vote power of `_owner` at block `_blockNumber` using cache.
    *   It tries to read the cached value and if not found, reads the actual value and stores it in cache.
    *   Can only be used if _blockNumber is in the past, otherwise reverts.    
    * @param _owner The address to get voting power.
    * @param _blockNumber The block number at which to fetch.
    * @return Vote power of `_owner` at `_blockNumber`.
    */
    function votePowerOfAtCached(address _owner, uint256 _blockNumber) external returns(uint256);

    /**
     * Return vote powers for several addresses in a batch.
     * @param _owners The list of addresses to fetch vote power of.
     * @param _blockNumber The block number at which to fetch.
     * @return A list of vote powers.
     */    
    function batchVotePowerOfAt(
        address[] memory _owners, 
        uint256 _blockNumber
    ) external view returns(uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


interface IFtsoGenesis {
    
    /**
     * @notice Submits price hash for current epoch - only price submitter
     * @param _sender               Sender address
     * @param _epochId              Target epoch id to which hashes are submitted
     * @param _hash                 Hashed price and random number
     * @notice Emits PriceHashSubmitted event. 
     */
    function submitPriceHashSubmitter(address _sender, uint256 _epochId, bytes32 _hash) external;

    /**
     * @notice Reveals submitted price during epoch reveal period - only price submitter
     * @param _voter                Voter address
     * @param _epochId              Id of the epoch in which the price hash was submitted
     * @param _price                Submitted price in USD
     * @param _random               Submitted random number
     * @notice The hash of _price and _random must be equal to the submitted hash
     * @notice Emits PriceRevealed event
     */
    function revealPriceSubmitter(
        address _voter,
        uint256 _epochId,
        uint256 _price,
        uint256 _random,
        uint256 _wNatVP
    ) external;

    /**
     * @notice Get (and cache) wNat vote power for specified voter and given epoch id
     * @param _voter                Voter address
     * @param _epochId              Id of the epoch in which the price hash was submitted
     * @return wNat vote power
     */
    function wNatVotePowerCached(address _voter, uint256 _epochId) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IFtso {
    enum PriceFinalizationType {
        // initial state
        NOT_FINALIZED,
        // median calculation used to decide price
        WEIGHTED_MEDIAN,
        // low turnout - price decided from average of trusted addresses
        TRUSTED_ADDRESSES,
        // low turnout + no votes from trusted addresses - price copied from previous epoch
        PREVIOUS_PRICE_COPIED,
        // price decided from average of trusted addresses - triggered due to an exception
        TRUSTED_ADDRESSES_EXCEPTION,
        // previous price copied - triggered due to an exception
        PREVIOUS_PRICE_COPIED_EXCEPTION
    }

    // events
    event PriceHashSubmitted(
        address indexed submitter, uint256 indexed epochId, bytes32 hash, uint256 timestamp
    );

    event PriceRevealed(
        address indexed voter, uint256 indexed epochId, uint256 price, uint256 random, uint256 timestamp,
        uint256 votePowerNat, uint256 votePowerAsset
    );

    event PriceFinalized(
        uint256 indexed epochId, uint256 price, bool rewardedFtso,
        uint256 lowRewardPrice, uint256 highRewardPrice, PriceFinalizationType finalizationType,
        uint256 timestamp
    );

    event PriceEpochInitializedOnFtso(
        uint256 indexed epochId, uint256 endTime, uint256 timestamp
    );

    event LowTurnout(
        uint256 indexed epochId,
        uint256 natTurnout,
        uint256 lowNatTurnoutThresholdBIPS,
        uint256 timestamp
    );

    /**
     * @notice Returns if FTSO is active
     */
    function active() external view returns (bool);

    /**
     * @notice Returns the FTSO symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Returns current epoch id
     */
    function getCurrentEpochId() external view returns (uint256);

    /**
     * @notice Returns id of the epoch which was opened for price submission at the specified timestamp
     * @param _timestamp            Timestamp as seconds from unix epoch
     */
    function getEpochId(uint256 _timestamp) external view returns (uint256);

    /**
     * @notice Returns random number of the specified epoch
     * @param _epochId              Id of the epoch
     */
    function getRandom(uint256 _epochId) external view returns (uint256);
    
    /**
     * @notice Returns asset price consented in specific epoch
     * @param _epochId              Id of the epoch
     * @return Price in USD multiplied by ASSET_PRICE_USD_DECIMALS
     */
    function getEpochPrice(uint256 _epochId) external view returns (uint256);

    /**
     * @notice Returns current epoch data
     * @return _epochId                 Current epoch id
     * @return _epochSubmitEndTime      End time of the current epoch price submission as seconds from unix epoch
     * @return _epochRevealEndTime      End time of the current epoch price reveal as seconds from unix epoch
     * @return _votePowerBlock          Vote power block for the current epoch
     * @return _fallbackMode            Current epoch in fallback mode - only votes from trusted addresses will be used
     * @dev half-closed intervals - end time not included
     */
    function getPriceEpochData() external view returns (
        uint256 _epochId,
        uint256 _epochSubmitEndTime,
        uint256 _epochRevealEndTime,
        uint256 _votePowerBlock,
        bool _fallbackMode
    );

    /**
     * @notice Returns current epoch data
     * @return _firstEpochStartTime         First epoch start time
     * @return _submitPeriod                Submit period in seconds
     * @return _revealPeriod                Reveal period in seconds
     */
    function getPriceEpochConfiguration() external view returns (
        uint256 _firstEpochStartTime,
        uint256 _submitPeriod,
        uint256 _revealPeriod
    );
    
    /**
     * @notice Returns asset price submitted by voter in specific epoch
     * @param _epochId              Id of the epoch
     * @param _voter                Address of the voter
     * @return Price in USD multiplied by ASSET_PRICE_USD_DECIMALS
     */
    function getEpochPriceForVoter(uint256 _epochId, address _voter) external view returns (uint256);

    /**
     * @notice Returns current asset price
     * @return _price               Price in USD multiplied by ASSET_PRICE_USD_DECIMALS
     * @return _timestamp           Time when price was updated for the last time
     */
    function getCurrentPrice() external view returns (uint256 _price, uint256 _timestamp);

    /**
     * @notice Returns current random number
     */
    function getCurrentRandom() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGovernanceVotePower} from "./IGovernanceVotePower.sol";
import {IVPContractEvents} from "./IVPContractEvents.sol";

interface IVPToken is IERC20 {
    /**
     * @notice Delegate by percentage `_bips` of voting power to `_to` from `msg.sender`.
     * @param _to The address of the recipient
     * @param _bips The percentage of voting power to be delegated expressed in basis points (1/100 of one percent).
     *   Not cummulative - every call resets the delegation value (and value of 0 undelegates `to`).
     **/
    function delegate(address _to, uint256 _bips) external;
    
    /**
     * @notice Explicitly delegate `_amount` of voting power to `_to` from `msg.sender`.
     * @param _to The address of the recipient
     * @param _amount An explicit vote power amount to be delegated.
     *   Not cummulative - every call resets the delegation value (and value of 0 undelegates `to`).
     **/    
    function delegateExplicit(address _to, uint _amount) external;

    /**
    * @notice Revoke all delegation from sender to `_who` at given block. 
    *    Only affects the reads via `votePowerOfAtCached()` in the block `_blockNumber`.
    *    Block `_blockNumber` must be in the past. 
    *    This method should be used only to prevent rogue delegate voting in the current voting block.
    *    To stop delegating use delegate/delegateExplicit with value of 0 or undelegateAll/undelegateAllExplicit.
    * @param _who Address of the delegatee
    * @param _blockNumber The block number at which to revoke delegation.
    */
    function revokeDelegationAt(address _who, uint _blockNumber) external;
    
    /**
     * @notice Undelegate all voting power for delegates of `msg.sender`
     *    Can only be used with percentage delegation.
     *    Does not reset delegation mode back to NOTSET.
     **/
    function undelegateAll() external;
    
    /**
     * @notice Undelegate all explicit vote power by amount delegates for `msg.sender`.
     *    Can only be used with explicit delegation.
     *    Does not reset delegation mode back to NOTSET.
     * @param _delegateAddresses Explicit delegation does not store delegatees' addresses, 
     *   so the caller must supply them.
     * @return The amount still delegated (in case the list of delegates was incomplete).
     */
    function undelegateAllExplicit(address[] memory _delegateAddresses) external returns (uint256);


    /**
     * @dev Should be compatible with ERC20 method
     */
    function name() external view returns (string memory);

    /**
     * @dev Should be compatible with ERC20 method
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Should be compatible with ERC20 method
     */
    function decimals() external view returns (uint8);
    

    /**
     * @notice Total amount of tokens at a specific `_blockNumber`.
     * @param _blockNumber The block number when the totalSupply is queried
     * @return The total amount of tokens at `_blockNumber`
     **/
    function totalSupplyAt(uint _blockNumber) external view returns(uint256);

    /**
     * @dev Queries the token balance of `_owner` at a specific `_blockNumber`.
     * @param _owner The address from which the balance will be retrieved.
     * @param _blockNumber The block number when the balance is queried.
     * @return The balance at `_blockNumber`.
     **/
    function balanceOfAt(address _owner, uint _blockNumber) external view returns (uint256);

    
    /**
     * @notice Get the current total vote power.
     * @return The current total vote power (sum of all accounts' vote powers).
     */
    function totalVotePower() external view returns(uint256);
    
    /**
    * @notice Get the total vote power at block `_blockNumber`
    * @param _blockNumber The block number at which to fetch.
    * @return The total vote power at the block  (sum of all accounts' vote powers).
    */
    function totalVotePowerAt(uint _blockNumber) external view returns(uint256);

    /**
     * @notice Get the current vote power of `_owner`.
     * @param _owner The address to get voting power.
     * @return Current vote power of `_owner`.
     */
    function votePowerOf(address _owner) external view returns(uint256);
    
    /**
    * @notice Get the vote power of `_owner` at block `_blockNumber`
    * @param _owner The address to get voting power.
    * @param _blockNumber The block number at which to fetch.
    * @return Vote power of `_owner` at `_blockNumber`.
    */
    function votePowerOfAt(address _owner, uint256 _blockNumber) external view returns(uint256);


    /**
     * @notice Get the delegation mode for '_who'. This mode determines whether vote power is
     *  allocated by percentage or by explicit value. Once the delegation mode is set, 
     *  it never changes, even if all delegations are removed.
     * @param _who The address to get delegation mode.
     * @return delegation mode: 0 = NOTSET, 1 = PERCENTAGE, 2 = AMOUNT (i.e. explicit)
     */
    function delegationModeOf(address _who) external view returns(uint256);
        
    /**
    * @notice Get current delegated vote power `_from` delegator delegated `_to` delegatee.
    * @param _from Address of delegator
    * @param _to Address of delegatee
    * @return The delegated vote power.
    */
    function votePowerFromTo(address _from, address _to) external view returns(uint256);
    
    /**
    * @notice Get delegated the vote power `_from` delegator delegated `_to` delegatee at `_blockNumber`.
    * @param _from Address of delegator
    * @param _to Address of delegatee
    * @param _blockNumber The block number at which to fetch.
    * @return The delegated vote power.
    */
    function votePowerFromToAt(address _from, address _to, uint _blockNumber) external view returns(uint256);
    
    /**
     * @notice Compute the current undelegated vote power of `_owner`
     * @param _owner The address to get undelegated voting power.
     * @return The unallocated vote power of `_owner`
     */
    function undelegatedVotePowerOf(address _owner) external view returns(uint256);
    
    /**
     * @notice Get the undelegated vote power of `_owner` at given block.
     * @param _owner The address to get undelegated voting power.
     * @param _blockNumber The block number at which to fetch.
     * @return The undelegated vote power of `_owner` (= owner's own balance minus all delegations from owner)
     */
    function undelegatedVotePowerOfAt(address _owner, uint256 _blockNumber) external view returns(uint256);
    
    /**
    * @notice Get the vote power delegation `delegationAddresses` 
    *  and `_bips` of `_who`. Returned in two separate positional arrays.
    * @param _who The address to get delegations.
    * @return _delegateAddresses Positional array of delegation addresses.
    * @return _bips Positional array of delegation percents specified in basis points (1/100 or 1 percent)
    * @return _count The number of delegates.
    * @return _delegationMode The mode of the delegation (NOTSET=0, PERCENTAGE=1, AMOUNT=2).
    */
    function delegatesOf(address _who)
        external view 
        returns (
            address[] memory _delegateAddresses,
            uint256[] memory _bips,
            uint256 _count, 
            uint256 _delegationMode
        );
        
    /**
    * @notice Get the vote power delegation `delegationAddresses` 
    *  and `pcts` of `_who`. Returned in two separate positional arrays.
    * @param _who The address to get delegations.
    * @param _blockNumber The block for which we want to know the delegations.
    * @return _delegateAddresses Positional array of delegation addresses.
    * @return _bips Positional array of delegation percents specified in basis points (1/100 or 1 percent)
    * @return _count The number of delegates.
    * @return _delegationMode The mode of the delegation (NOTSET=0, PERCENTAGE=1, AMOUNT=2).
    */
    function delegatesOfAt(address _who, uint256 _blockNumber)
        external view 
        returns (
            address[] memory _delegateAddresses, 
            uint256[] memory _bips, 
            uint256 _count, 
            uint256 _delegationMode
        );

    /**
     * Returns VPContract used for readonly operations (view methods).
     * The only non-view method that might be called on it is `revokeDelegationAt`.
     *
     * @notice `readVotePowerContract` is almost always equal to `writeVotePowerContract`
     * except during upgrade from one VPContract to a new version (which should happen
     * rarely or never and will be anounced before).
     *
     * @notice You shouldn't call any methods on VPContract directly, all are exposed
     * via VPToken (and state changing methods are forbidden from direct calls). 
     * This is the reason why this method returns `IVPContractEvents` - it should only be used
     * for listening to events (`Revoke` only).
     */
    function readVotePowerContract() external view returns (IVPContractEvents);

    /**
     * Returns VPContract used for state changing operations (non-view methods).
     * The only non-view method that might be called on it is `revokeDelegationAt`.
     *
     * @notice `writeVotePowerContract` is almost always equal to `readVotePowerContract`
     * except during upgrade from one VPContract to a new version (which should happen
     * rarely or never and will be anounced before). In the case of upgrade,
     * `writeVotePowerContract` will be replaced first to establish delegations, and
     * after some perio (e.g. after a reward epoch ends) `readVotePowerContract` will be set equal to it.
     *
     * @notice You shouldn't call any methods on VPContract directly, all are exposed
     * via VPToken (and state changing methods are forbidden from direct calls). 
     * This is the reason why this method returns `IVPContractEvents` - it should only be used
     * for listening to events (`Delegate` and `Revoke` only).
     */
    function writeVotePowerContract() external view returns (IVPContractEvents);
    
    /**
     * When set, allows token owners to participate in governance voting
     * and delegate governance vote power.
     */
    function governanceVotePower() external view returns (IGovernanceVotePower);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IGovernanceVotePower {
    /**
     * @notice Delegate all governance vote power of `msg.sender` to `_to`.
     * @param _to The address of the recipient
     **/
    function delegate(address _to) external;

    /**
     * @notice Undelegate all governance vote power that `msg.sender` has delegated.
     **/
    function undelegate() external;

    /**
    * @notice Get the governance vote power of `_who` at block `_blockNumber`
    * @param _who The address to get voting power.
    * @param _blockNumber The block number at which to fetch.
    * @return Governance vote power of `_who` at `_blockNumber`.
    */
    function votePowerOfAt(address _who, uint256 _blockNumber) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../../userInterfaces/IVPToken.sol";
import "../../userInterfaces/IVPContractEvents.sol";
import "./IICleanable.sol";

interface IIVPContract is IICleanable, IVPContractEvents {
    /**
     * Update vote powers when tokens are transfered.
     * Also update delegated vote powers for percentage delegation
     * and check for enough funds for explicit delegations.
     **/
    function updateAtTokenTransfer(
        address _from, 
        address _to, 
        uint256 _fromBalance,
        uint256 _toBalance,
        uint256 _amount
    ) external;

    /**
     * @notice Delegate `_bips` percentage of voting power to `_to` from `_from`
     * @param _from The address of the delegator
     * @param _to The address of the recipient
     * @param _balance The delegator's current balance
     * @param _bips The percentage of voting power to be delegated expressed in basis points (1/100 of one percent).
     *   Not cummulative - every call resets the delegation value (and value of 0 revokes delegation).
     **/
    function delegate(
        address _from, 
        address _to, 
        uint256 _balance, 
        uint256 _bips
    ) external;
    
    /**
     * @notice Explicitly delegate `_amount` of voting power to `_to` from `msg.sender`.
     * @param _from The address of the delegator
     * @param _to The address of the recipient
     * @param _balance The delegator's current balance
     * @param _amount An explicit vote power amount to be delegated.
     *   Not cummulative - every call resets the delegation value (and value of 0 undelegates `to`).
     **/    
    function delegateExplicit(
        address _from, 
        address _to, 
        uint256 _balance, 
        uint _amount
    ) external;    

    /**
     * @notice Revoke all delegation from sender to `_who` at given block. 
     *    Only affects the reads via `votePowerOfAtCached()` in the block `_blockNumber`.
     *    Block `_blockNumber` must be in the past. 
     *    This method should be used only to prevent rogue delegate voting in the current voting block.
     *    To stop delegating use delegate/delegateExplicit with value of 0 or undelegateAll/undelegateAllExplicit.
     * @param _from The address of the delegator
     * @param _who Address of the delegatee
     * @param _balance The delegator's current balance
     * @param _blockNumber The block number at which to revoke delegation.
     **/
    function revokeDelegationAt(
        address _from, 
        address _who, 
        uint256 _balance,
        uint _blockNumber
    ) external;
    
        /**
     * @notice Undelegate all voting power for delegates of `msg.sender`
     *    Can only be used with percentage delegation.
     *    Does not reset delegation mode back to NOTSET.
     * @param _from The address of the delegator
     **/
    function undelegateAll(
        address _from,
        uint256 _balance
    ) external;
    
    /**
     * @notice Undelegate all explicit vote power by amount delegates for `msg.sender`.
     *    Can only be used with explicit delegation.
     *    Does not reset delegation mode back to NOTSET.
     * @param _from The address of the delegator
     * @param _delegateAddresses Explicit delegation does not store delegatees' addresses, 
     *   so the caller must supply them.
     * @return The amount still delegated (in case the list of delegates was incomplete).
     */
    function undelegateAllExplicit(
        address _from, 
        address[] memory _delegateAddresses
    ) external returns (uint256);
    
    /**
    * @notice Get the vote power of `_who` at block `_blockNumber`
    *   Reads/updates cache and upholds revocations.
    * @param _who The address to get voting power.
    * @param _blockNumber The block number at which to fetch.
    * @return Vote power of `_who` at `_blockNumber`.
    */
    function votePowerOfAtCached(address _who, uint256 _blockNumber) external returns(uint256);
    
    /**
     * @notice Get the current vote power of `_who`.
     * @param _who The address to get voting power.
     * @return Current vote power of `_who`.
     */
    function votePowerOf(address _who) external view returns(uint256);
    
    /**
    * @notice Get the vote power of `_who` at block `_blockNumber`
    * @param _who The address to get voting power.
    * @param _blockNumber The block number at which to fetch.
    * @return Vote power of `_who` at `_blockNumber`.
    */
    function votePowerOfAt(address _who, uint256 _blockNumber) external view returns(uint256);

    /**
     * Return vote powers for several addresses in a batch.
     * @param _owners The list of addresses to fetch vote power of.
     * @param _blockNumber The block number at which to fetch.
     * @return A list of vote powers.
     */    
    function batchVotePowerOfAt(
        address[] memory _owners, 
        uint256 _blockNumber
    )
        external view returns(uint256[] memory);

    /**
    * @notice Get current delegated vote power `_from` delegator delegated `_to` delegatee.
    * @param _from Address of delegator
    * @param _to Address of delegatee
    * @param _balance The delegator's current balance
    * @return The delegated vote power.
    */
    function votePowerFromTo(
        address _from, 
        address _to, 
        uint256 _balance
    ) external view returns(uint256);
    
    /**
    * @notice Get delegated the vote power `_from` delegator delegated `_to` delegatee at `_blockNumber`.
    * @param _from Address of delegator
    * @param _to Address of delegatee
    * @param _balance The delegator's current balance
    * @param _blockNumber The block number at which to fetch.
    * @return The delegated vote power.
    */
    function votePowerFromToAt(
        address _from, 
        address _to, 
        uint256 _balance,
        uint _blockNumber
    ) external view returns(uint256);

    /**
     * @notice Compute the current undelegated vote power of `_owner`
     * @param _owner The address to get undelegated voting power.
     * @param _balance Owner's current balance
     * @return The unallocated vote power of `_owner`
     */
    function undelegatedVotePowerOf(
        address _owner,
        uint256 _balance
    ) external view returns(uint256);

    /**
     * @notice Get the undelegated vote power of `_owner` at given block.
     * @param _owner The address to get undelegated voting power.
     * @param _blockNumber The block number at which to fetch.
     * @return The undelegated vote power of `_owner` (= owner's own balance minus all delegations from owner)
     */
    function undelegatedVotePowerOfAt(
        address _owner, 
        uint256 _balance,
        uint256 _blockNumber
    ) external view returns(uint256);

    /**
     * @notice Get the delegation mode for '_who'. This mode determines whether vote power is
     *  allocated by percentage or by explicit value.
     * @param _who The address to get delegation mode.
     * @return Delegation mode (NOTSET=0, PERCENTAGE=1, AMOUNT=2))
     */
    function delegationModeOf(address _who) external view returns (uint256);
    
    /**
    * @notice Get the vote power delegation `_delegateAddresses` 
    *  and `pcts` of an `_owner`. Returned in two separate positional arrays.
    * @param _owner The address to get delegations.
    * @return _delegateAddresses Positional array of delegation addresses.
    * @return _bips Positional array of delegation percents specified in basis points (1/100 or 1 percent)
    * @return _count The number of delegates.
    * @return _delegationMode The mode of the delegation (NOTSET=0, PERCENTAGE=1, AMOUNT=2).
    */
    function delegatesOf(
        address _owner
    )
        external view 
        returns (
            address[] memory _delegateAddresses, 
            uint256[] memory _bips,
            uint256 _count,
            uint256 _delegationMode
        );

    /**
    * @notice Get the vote power delegation `delegationAddresses` 
    *  and `pcts` of an `_owner`. Returned in two separate positional arrays.
    * @param _owner The address to get delegations.
    * @param _blockNumber The block for which we want to know the delegations.
    * @return _delegateAddresses Positional array of delegation addresses.
    * @return _bips Positional array of delegation percents specified in basis points (1/100 or 1 percent)
    * @return _count The number of delegates.
    * @return _delegationMode The mode of the delegation (NOTSET=0, PERCENTAGE=1, AMOUNT=2).
    */
    function delegatesOfAt(
        address _owner,
        uint256 _blockNumber
    )
        external view 
        returns (
            address[] memory _delegateAddresses, 
            uint256[] memory _bips,
            uint256 _count,
            uint256 _delegationMode
        );

    /**
     * The VPToken (or some other contract) that owns this VPContract.
     * All state changing methods may be called only from this address.
     * This is because original msg.sender is sent in `_from` parameter
     * and we must be sure that it cannot be faked by directly calling VPContract.
     * Owner token is also used in case of replacement to recover vote powers from balances.
     */
    function ownerToken() external view returns (IVPToken);
    
    /**
     * Return true if this IIVPContract is configured to be used as a replacement for other contract.
     * It means that vote powers are not necessarily correct at the initialization, therefore
     * every method that reads vote power must check whether it is initialized for that address and block.
     */
    function isReplacement() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../../userInterfaces/IVPToken.sol";
import "../../userInterfaces/IGovernanceVotePower.sol";

interface IIGovernanceVotePower is IGovernanceVotePower {
    /**
     * Update vote powers when tokens are transfered.
     **/
    function updateAtTokenTransfer(
        address _from, 
        address _to, 
        uint256 _fromBalance,
        uint256 _toBalance,
        uint256 _amount
    ) external;
    
    /**
     * Set the cleanup block number.
     * Historic data for the blocks before `cleanupBlockNumber` can be erased,
     * history before that block should never be used since it can be inconsistent.
     * In particular, cleanup block number must be before current vote power block.
     * @param _blockNumber The new cleanup block number.
     */
    function setCleanupBlockNumber(uint256 _blockNumber) external;
    
    /**
     * Set the contract that is allowed to call history cleaning methods.
     */
    function setCleanerContract(address _cleanerContract) external;
        
   /**
    * @notice Get the token that this governance vote power contract belongs to.
    */
    function ownerToken() external view returns(IVPToken);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IICleanable {
    /**
     * Set the contract that is allowed to call history cleaning methods.
     */
    function setCleanerContract(address _cleanerContract) external;
    
    /**
     * Set the cleanup block number.
     * Historic data for the blocks before `cleanupBlockNumber` can be erased,
     * history before that block should never be used since it can be inconsistent.
     * In particular, cleanup block number must be before current vote power block.
     * @param _blockNumber The new cleanup block number.
     */
    function setCleanupBlockNumber(uint256 _blockNumber) external;
    
    /**
     * Set the contract that is allowed to set cleanupBlockNumber.
     * Usually this will be an instance of CleanupBlockNumberManager.
     */
    function setCleanupBlockNumberManager(address _cleanupBlockNumberManager) external;
    
    /**
     * Get the current cleanup block number.
     */
    function cleanupBlockNumber() external view returns (uint256);
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
pragma solidity 0.7.6;

interface IVPContractEvents {
    /**
     * Event triggered when an account delegates or undelegates another account. 
     * Definition: `votePowerFromTo(from, to)` is `changed` from `priorVotePower` to `newVotePower`.
     * For undelegation, `newVotePower` is 0.
     *
     * Note: the event is always emitted from VPToken's `writeVotePowerContract`.
     */
    event Delegate(address indexed from, address indexed to, uint256 priorVotePower, uint256 newVotePower);
    
    /**
     * Event triggered only when account `delegator` revokes delegation to `delegatee`
     * for a single block in the past (typically the current vote block).
     *
     * Note: the event is always emitted from VPToken's `writeVotePowerContract` and/or `readVotePowerContract`.
     */
    event Revoke(address indexed delegator, address indexed delegatee, uint256 votePower, uint256 blockNumber);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../genesis/interface/IFtsoGenesis.sol";
import "../genesis/interface/IFtsoRegistryGenesis.sol";

interface IPriceSubmitter {
    /**
     * Event emitted when price hashes were submitted through PriceSubmitter.
     * @param submitter the address of the sender
     * @param epochId current price epoch id
     * @param ftsos array of ftsos that correspond to the indexes in call
     * @param hashes the submitted hashes
     * @param timestamp current block timestamp
     */
    event PriceHashesSubmitted(
        address indexed submitter,
        uint256 indexed epochId,
        IFtsoGenesis[] ftsos,
        bytes32[] hashes,
        uint256 timestamp
    );

    /**
     * Event emitted when prices were revealed through PriceSubmitter.
     * @param voter the address of the sender
     * @param epochId id of the epoch in which the price hash was submitted
     * @param ftsos array of ftsos that correspond to the indexes in the call
     * @param prices the submitted prices
     * @param timestamp current block timestamp
     */
    event PricesRevealed(
        address indexed voter,
        uint256 indexed epochId,
        IFtsoGenesis[] ftsos,
        uint256[] prices,
        uint256[] randoms,
        uint256 timestamp
    );
    
    /**
     * @notice Submits price hashes for current epoch
     * @param _epochId              Target epoch id to which hashes are submitted
     * @param _ftsoIndices          List of ftso indices
     * @param _hashes               List of hashed price and random number
     * @notice Emits PriceHashesSubmitted event
     */
    function submitPriceHashes(
        uint256 _epochId,
        uint256[] memory _ftsoIndices,
        bytes32[] memory _hashes
    ) external;

    /**
     * @notice Reveals submitted prices during epoch reveal period
     * @param _epochId              Id of the epoch in which the price hashes was submitted
     * @param _ftsoIndices          List of ftso indices
     * @param _prices               List of submitted prices in USD
     * @param _randoms              List of submitted random numbers
     * @notice The hash of _price and _random must be equal to the submitted hash
     * @notice Emits PricesRevealed event
     */
    function revealPrices(
        uint256 _epochId,
        uint256[] memory _ftsoIndices,
        uint256[] memory _prices,
        uint256[] memory _randoms
    ) external;

    /**
     * Returns bitmap of all ftso's for which `_voter` is allowed to submit prices/hashes.
     * If voter is allowed to vote for ftso at index (see *_FTSO_INDEX), the corrsponding
     * bit in the result will be 1.
     */    
    function voterWhitelistBitmap(address _voter) external view returns (uint256);

    function getVoterWhitelister() external view returns (address);
    function getFtsoRegistry() external view returns (IFtsoRegistryGenesis);
    function getFtsoManager() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IFtsoGenesis.sol";


interface IFtsoRegistryGenesis {

    function getFtsos(uint256[] memory _indices) external view returns(IFtsoGenesis[] memory _ftsos);
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

interface IFtsoRewardManager {

    event RewardClaimed(
        address indexed dataProvider,
        address indexed whoClaimed,
        address indexed sentTo,
        uint256 rewardEpoch, 
        uint256 amount
    );
    
    event RewardsDistributed(
        address indexed ftso,
        uint256 epochId,
        address[] addresses,
        uint256[] rewards
    );

    event FeePercentageChanged(
        address indexed dataProvider,
        uint256 value,
        uint256 validFromEpoch
    );

    event RewardClaimsExpired(
        uint256 rewardEpochId
    );    

    /**
     * @notice Allows a percentage delegator to claim rewards.
     * @notice This function is intended to be used to claim rewards in case of delegation by percentage.
     * @param _recipient            address to transfer funds to
     * @param _rewardEpochs         array of reward epoch numbers to claim for
     * @return _rewardAmount        amount of total claimed rewards
     * @dev Reverts if `msg.sender` is delegating by amount
     */
    function claimReward(address payable _recipient, uint256[] memory _rewardEpochs)
        external returns (uint256 _rewardAmount);

    /**
     * @notice Allows the sender to claim the rewards from specified data providers.
     * @notice This function is intended to be used to claim rewards in case of delegation by amount.
     * @param _recipient            address to transfer funds to
     * @param _rewardEpochs         array of reward epoch numbers to claim for
     * @param _dataProviders        array of addresses representing data providers to claim the reward from
     * @return _rewardAmount        amount of total claimed rewards
     * @dev Function can be used by a percentage delegator but is more gas consuming than `claimReward`.
     */
    function claimRewardFromDataProviders(
        address payable _recipient,
        uint256[] memory _rewardEpochs,
        address[] memory _dataProviders
    )
        external
        returns (uint256 _rewardAmount);

    /**
     * @notice Allows data provider to set (or update last) fee percentage.
     * @param _feePercentageBIPS    number representing fee percentage in BIPS
     * @return _validFromEpoch      reward epoch number when the setting becomes effective.
     */
    function setDataProviderFeePercentage(uint256 _feePercentageBIPS)
        external returns (uint256 _validFromEpoch);

    /**
     * @notice Returns the current fee percentage of `_dataProvider`
     * @param _dataProvider         address representing data provider
     */
    function getDataProviderCurrentFeePercentage(address _dataProvider)
        external view returns (uint256 _feePercentageBIPS);

    /**
     * @notice Returns the scheduled fee percentage changes of `_dataProvider`
     * @param _dataProvider         address representing data provider
     * @return _feePercentageBIPS   positional array of fee percentages in BIPS
     * @return _validFromEpoch      positional array of block numbers the fee setings are effective from
     * @return _fixed               positional array of boolean values indicating if settings are subjected to change
     */
    function getDataProviderScheduledFeePercentageChanges(address _dataProvider) external view 
        returns (
            uint256[] memory _feePercentageBIPS,
            uint256[] memory _validFromEpoch,
            bool[] memory _fixed
        );

    /**
     * @notice Returns information on epoch reward
     * @param _rewardEpoch          reward epoch number
     * @return _totalReward         number representing the total epoch reward
     * @return _claimedReward       number representing the amount of total epoch reward that has been claimed
     */
    function getEpochReward(uint256 _rewardEpoch) external view
        returns (uint256 _totalReward, uint256 _claimedReward);

    /**
     * @notice Returns the state of rewards for `_beneficiary` at `_rewardEpoch`
     * @param _beneficiary          address of reward beneficiary
     * @param _rewardEpoch          reward epoch number
     * @return _dataProviders       positional array of addresses representing data providers
     * @return _rewardAmounts       positional array of reward amounts
     * @return _claimed             positional array of boolean values indicating if reward is claimed
     * @return _claimable           boolean value indicating if rewards are claimable
     * @dev Reverts when queried with `_beneficary` delegating by amount
     */
    function getStateOfRewards(
        address _beneficiary,
        uint256 _rewardEpoch
    )
        external view 
        returns (
            address[] memory _dataProviders,
            uint256[] memory _rewardAmounts,
            bool[] memory _claimed,
            bool _claimable
        );

    /**
     * @notice Returns the state of rewards for `_beneficiary` at `_rewardEpoch` from `_dataProviders`
     * @param _beneficiary          address of reward beneficiary
     * @param _rewardEpoch          reward epoch number
     * @param _dataProviders        positional array of addresses representing data providers
     * @return _rewardAmounts       positional array of reward amounts
     * @return _claimed             positional array of boolean values indicating if reward is claimed
     * @return _claimable           boolean value indicating if rewards are claimable
     */
    function getStateOfRewardsFromDataProviders(
        address _beneficiary,
        uint256 _rewardEpoch,
        address[] memory _dataProviders
    )
        external view
        returns (
            uint256[] memory _rewardAmounts,
            bool[] memory _claimed,
            bool _claimable
        );

    /**
     * @notice Returns the start and the end of the reward epoch range for which the reward is claimable
     * @param _startEpochId         the oldest epoch id that allows reward claiming
     * @param _endEpochId           the newest epoch id that allows reward claiming
     */
    function getEpochsWithClaimableRewards() external view 
        returns (
            uint256 _startEpochId,
            uint256 _endEpochId
        );

    /**
     * @notice Returns the array of claimable epoch ids for which the reward has not yet been claimed
     * @param _beneficiary          address of reward beneficiary
     * @return _epochIds            array of epoch ids
     * @dev Reverts when queried with `_beneficary` delegating by amount
     */
    function getEpochsWithUnclaimedRewards(address _beneficiary) external view returns (
        uint256[] memory _epochIds
    );

    /**
     * @notice Returns the information on claimed reward of `_dataProvider` for `_rewardEpoch` by `_claimer`
     * @param _rewardEpoch          reward epoch number
     * @param _dataProvider         address representing the data provider
     * @param _claimer              address representing the claimer
     * @return _claimed             boolean indicating if reward has been claimed
     * @return _amount              number representing the claimed amount
     */
    function getClaimedReward(
        uint256 _rewardEpoch,
        address _dataProvider,
        address _claimer
    )
        external view
        returns (
            bool _claimed,
            uint256 _amount
        );

    /**
     * @notice Return reward epoch that will expire, when new reward epoch will start
     * @return Reward epoch id that will expire next
     */
    function getRewardEpochToExpireNext() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../ftso/interface/IIFtso.sol";
import "../genesis/interface/IFtsoRegistryGenesis.sol";

interface IFtsoRegistry is IFtsoRegistryGenesis {

    function getFtso(uint256 _ftsoIndex) external view returns(IIFtso _activeFtsoAddress);
    function getFtsoBySymbol(string memory _symbol) external view returns(IIFtso _activeFtsoAddress);
    function getSupportedIndices() external view returns(uint256[] memory _supportedIndices);
    function getSupportedSymbols() external view returns(string[] memory _supportedSymbols);
    function getSupportedFtsos() external view returns(IIFtso[] memory _ftsos);
    function getFtsoIndex(string memory _symbol) external view returns (uint256 _assetIndex);
    function getFtsoSymbol(uint256 _ftsoIndex) external view returns (string memory _symbol);
    function getCurrentPrice(uint256 _ftsoIndex) external view returns(uint256 _price, uint256 _timestamp);
    function getCurrentPrice(string memory _symbol) external view returns(uint256 _price, uint256 _timestamp);

    function getSupportedIndicesAndFtsos() external view 
        returns(uint256[] memory _supportedIndices, IIFtso[] memory _ftsos);

    function getSupportedSymbolsAndFtsos() external view 
        returns(string[] memory _supportedSymbols, IIFtso[] memory _ftsos);

    function getSupportedIndicesAndSymbols() external view 
        returns(uint256[] memory _supportedIndices, string[] memory _supportedSymbols);

    function getSupportedIndicesSymbolsAndFtsos() external view 
        returns(uint256[] memory _supportedIndices, string[] memory _supportedSymbols, IIFtso[] memory _ftsos);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IVoterWhitelister {
    /**
     * Raised when an account is removed from the voter whitelist.
     */
    event VoterWhitelisted(address voter, uint256 ftsoIndex);
    
    /**
     * Raised when an account is removed from the voter whitelist.
     */
    event VoterRemovedFromWhitelist(address voter, uint256 ftsoIndex);

    /**
     * Request to whitelist `_voter` account to ftso at `_ftsoIndex`. Will revert if vote power too low.
     * May be called by any address.
     */
    function requestWhitelistingVoter(address _voter, uint256 _ftsoIndex) external;

    /**
     * Request to whitelist `_voter` account to all active ftsos.
     * May be called by any address.
     * It returns an array of supported ftso indices and success flag per index.
     */
    function requestFullVoterWhitelisting(
        address _voter
    ) 
        external 
        returns (
            uint256[] memory _supportedIndices,
            bool[] memory _success
        );

    /**
     * Maximum number of voters in the whitelist for a new FTSO.
     */
    function defaultMaxVotersForFtso() external view returns (uint256);
    
    /**
     * Maximum number of voters in the whitelist for FTSO at index `_ftsoIndex`.
     */
    function maxVotersForFtso(uint256 _ftsoIndex) external view returns (uint256);

    /**
     * Get whitelisted price providers for ftso with `_symbol`
     */
    function getFtsoWhitelistedPriceProvidersBySymbol(string memory _symbol) external view returns (address[] memory);

    /**
     * Get whitelisted price providers for ftso at `_ftsoIndex`
     */
    function getFtsoWhitelistedPriceProviders(uint256 _ftsoIndex) external view returns (address[] memory);
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