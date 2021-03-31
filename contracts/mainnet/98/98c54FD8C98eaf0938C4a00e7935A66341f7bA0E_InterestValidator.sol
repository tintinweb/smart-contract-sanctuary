/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

pragma solidity 0.8.2;


// SPDX-License-Identifier: AGPL-3.0-or-later
struct BassetPersonal {
    // Address of the bAsset
    address addr;
    // Address of the bAsset
    address integrator;
    // An ERC20 can charge transfer fee, for example USDT, DGX tokens.
    bool hasTxFee; // takes a byte in storage
    // Status of the bAsset
    BassetStatus status;
}

struct BassetData {
    // 1 Basset * ratio / ratioScale == x Masset (relative value)
    // If ratio == 10e8 then 1 bAsset = 10 mAssets
    // A ratio is divised as 10^(18-tokenDecimals) * measurementMultiple(relative value of 1 base unit)
    uint128 ratio;
    // Amount of the Basset that is held in Collateral
    uint128 vaultBalance;
}

// Status of the Basset - has it broken its peg?
enum BassetStatus {
    Default,
    Normal,
    BrokenBelowPeg,
    BrokenAbovePeg,
    Blacklisted,
    Liquidating,
    Liquidated,
    Failed
}

struct BasketState {
    bool undergoingRecol;
    bool failed;
}

struct InvariantConfig {
    uint256 a;
    WeightLimits limits;
}

struct WeightLimits {
    uint128 min;
    uint128 max;
}

struct FeederConfig {
    uint256 supply;
    uint256 a;
    WeightLimits limits;
}

struct AmpData {
    uint64 initialA;
    uint64 targetA;
    uint64 rampStartTime;
    uint64 rampEndTime;
}

struct FeederData {
    uint256 swapFee;
    uint256 redemptionFee;
    uint256 govFee;
    uint256 pendingFees;
    uint256 cacheSize;
    BassetPersonal[] bAssetPersonal;
    BassetData[] bAssetData;
    AmpData ampData;
    WeightLimits weightLimits;
}

struct AssetData {
    uint8 idx;
    uint256 amt;
    BassetPersonal personal;
}

struct Asset {
    uint8 idx;
    address addr;
    bool exists;
}

abstract contract IFeederPool {
    // Mint
    function mint(
        address _input,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 mintOutput);

    function mintMulti(
        address[] calldata _inputs,
        uint256[] calldata _inputQuantities,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 mintOutput);

    function getMintOutput(address _input, uint256 _inputQuantity)
        external
        view
        virtual
        returns (uint256 mintOutput);

    function getMintMultiOutput(address[] calldata _inputs, uint256[] calldata _inputQuantities)
        external
        view
        virtual
        returns (uint256 mintOutput);

    // Swaps
    function swap(
        address _input,
        address _output,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 swapOutput);

    function getSwapOutput(
        address _input,
        address _output,
        uint256 _inputQuantity
    ) external view virtual returns (uint256 swapOutput);

    // Redemption
    function redeem(
        address _output,
        uint256 _mAssetQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 outputQuantity);

    function redeemProportionately(
        uint256 _mAssetQuantity,
        uint256[] calldata _minOutputQuantities,
        address _recipient
    ) external virtual returns (uint256[] memory outputQuantities);

    function redeemExactBassets(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities,
        uint256 _maxMassetQuantity,
        address _recipient
    ) external virtual returns (uint256 mAssetRedeemed);

    function getRedeemOutput(address _output, uint256 _mAssetQuantity)
        external
        view
        virtual
        returns (uint256 bAssetOutput);

    function getRedeemExactBassetsOutput(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities
    ) external view virtual returns (uint256 mAssetAmount);

    // Views
    function getPrice() public view virtual returns (uint256 price, uint256 k);

    function getConfig() external view virtual returns (FeederConfig memory config);

    function getBasset(address _token)
        external
        view
        virtual
        returns (BassetPersonal memory personal, BassetData memory data);

    function getBassets()
        external
        view
        virtual
        returns (BassetPersonal[] memory personal, BassetData[] memory data);

    // SavingsManager
    function collectPlatformInterest()
        external
        virtual
        returns (uint256 mintAmount, uint256 newSupply);
}

contract ModuleKeys {
    // Governance
    // ===========
    // keccak256("Governance");
    bytes32 internal constant KEY_GOVERNANCE =
        0x9409903de1e6fd852dfc61c9dacb48196c48535b60e25abf92acc92dd689078d;
    //keccak256("Staking");
    bytes32 internal constant KEY_STAKING =
        0x1df41cd916959d1163dc8f0671a666ea8a3e434c13e40faef527133b5d167034;
    //keccak256("ProxyAdmin");
    bytes32 internal constant KEY_PROXY_ADMIN =
        0x96ed0203eb7e975a4cbcaa23951943fa35c5d8288117d50c12b3d48b0fab48d1;

    // mStable
    // =======
    // keccak256("OracleHub");
    bytes32 internal constant KEY_ORACLE_HUB =
        0x8ae3a082c61a7379e2280f3356a5131507d9829d222d853bfa7c9fe1200dd040;
    // keccak256("Manager");
    bytes32 internal constant KEY_MANAGER =
        0x6d439300980e333f0256d64be2c9f67e86f4493ce25f82498d6db7f4be3d9e6f;
    //keccak256("Recollateraliser");
    bytes32 internal constant KEY_RECOLLATERALISER =
        0x39e3ed1fc335ce346a8cbe3e64dd525cf22b37f1e2104a755e761c3c1eb4734f;
    //keccak256("MetaToken");
    bytes32 internal constant KEY_META_TOKEN =
        0xea7469b14936af748ee93c53b2fe510b9928edbdccac3963321efca7eb1a57a2;
    // keccak256("SavingsManager");
    bytes32 internal constant KEY_SAVINGS_MANAGER =
        0x12fe936c77a1e196473c4314f3bed8eeac1d757b319abb85bdda70df35511bf1;
    // keccak256("Liquidator");
    bytes32 internal constant KEY_LIQUIDATOR =
        0x1e9cb14d7560734a61fa5ff9273953e971ff3cd9283c03d8346e3264617933d4;
    // keccak256("InterestValidator");
    bytes32 internal constant KEY_INTEREST_VALIDATOR =
        0xc10a28f028c7f7282a03c90608e38a4a646e136e614e4b07d119280c5f7f839f;
}

interface INexus {
    function governor() external view returns (address);

    function getModule(bytes32 key) external view returns (address);

    function proposeModule(bytes32 _key, address _addr) external;

    function cancelProposedModule(bytes32 _key) external;

    function acceptProposedModule(bytes32 _key) external;

    function acceptProposedModules(bytes32[] calldata _keys) external;

    function requestLockModule(bytes32 _key) external;

    function cancelLockModule(bytes32 _key) external;

    function lockModule(bytes32 _key) external;
}

abstract contract ImmutableModule is ModuleKeys {
    INexus public immutable nexus;

    /**
     * @dev Initialization function for upgradable proxy contracts
     * @param _nexus Nexus contract address
     */
    constructor(address _nexus) {
        require(_nexus != address(0), "Nexus address is zero");
        nexus = INexus(_nexus);
    }

    /**
     * @dev Modifier to allow function calls only from the Governor.
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function _onlyGovernor() internal view {
        require(msg.sender == _governor(), "Only governor can execute");
    }

    /**
     * @dev Modifier to allow function calls only from the Governance.
     *      Governance is either Governor address or Governance address.
     */
    modifier onlyGovernance() {
        require(
            msg.sender == _governor() || msg.sender == _governance(),
            "Only governance can execute"
        );
        _;
    }

    /**
     * @dev Modifier to allow function calls only from the ProxyAdmin.
     */
    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "Only ProxyAdmin can execute");
        _;
    }

    /**
     * @dev Modifier to allow function calls only from the Manager.
     */
    modifier onlyManager() {
        require(msg.sender == _manager(), "Only manager can execute");
        _;
    }

    /**
     * @dev Returns Governor address from the Nexus
     * @return Address of Governor Contract
     */
    function _governor() internal view returns (address) {
        return nexus.governor();
    }

    /**
     * @dev Returns Governance Module address from the Nexus
     * @return Address of the Governance (Phase 2)
     */
    function _governance() internal view returns (address) {
        return nexus.getModule(KEY_GOVERNANCE);
    }

    /**
     * @dev Return Staking Module address from the Nexus
     * @return Address of the Staking Module contract
     */
    function _staking() internal view returns (address) {
        return nexus.getModule(KEY_STAKING);
    }

    /**
     * @dev Return ProxyAdmin Module address from the Nexus
     * @return Address of the ProxyAdmin Module contract
     */
    function _proxyAdmin() internal view returns (address) {
        return nexus.getModule(KEY_PROXY_ADMIN);
    }

    /**
     * @dev Return MetaToken Module address from the Nexus
     * @return Address of the MetaToken Module contract
     */
    function _metaToken() internal view returns (address) {
        return nexus.getModule(KEY_META_TOKEN);
    }

    /**
     * @dev Return OracleHub Module address from the Nexus
     * @return Address of the OracleHub Module contract
     */
    function _oracleHub() internal view returns (address) {
        return nexus.getModule(KEY_ORACLE_HUB);
    }

    /**
     * @dev Return Manager Module address from the Nexus
     * @return Address of the Manager Module contract
     */
    function _manager() internal view returns (address) {
        return nexus.getModule(KEY_MANAGER);
    }

    /**
     * @dev Return SavingsManager Module address from the Nexus
     * @return Address of the SavingsManager Module contract
     */
    function _savingsManager() internal view returns (address) {
        return nexus.getModule(KEY_SAVINGS_MANAGER);
    }

    /**
     * @dev Return Recollateraliser Module address from the Nexus
     * @return  Address of the Recollateraliser Module contract (Phase 2)
     */
    function _recollateraliser() internal view returns (address) {
        return nexus.getModule(KEY_RECOLLATERALISER);
    }
}

abstract contract PausableModule is ImmutableModule {
    /**
     * @dev Emitted when the pause is triggered by Governor
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by Governor
     */
    event Unpaused(address account);

    bool internal _paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Initializes the contract in unpaused state.
     * Hooks into the Module to give the Governor ability to pause
     * @param _nexus Nexus contract address
     */
    constructor(address _nexus) ImmutableModule(_nexus) {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     * @return Returns `true` when paused, otherwise `false`
     */
    function paused() external view returns (bool) {
        return _paused;
    }

    /**
     * @dev Called by the Governor to pause, triggers stopped state.
     */
    function pause() external onlyGovernor whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by Governor to unpause, returns to normal state.
     */
    function unpause() external onlyGovernor whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


/**
 * @title   InterestValidator
 * @author  mStable
 * @notice  Simply validates the platform interest collection from the Feeder Pools. Normally this function
 *          is supported by the SavingsManager, which then distributes the inflated tokens to SAVE contracts.
 *          However, given that fPools collect value internally, we simply want to provide protections here
 *          without actually inflating supply. As such, this code is forked from `savings/SavingsManager.sol`.
 * @dev     VERSION: 1.0
 *          DATE:    2021-03-01
 */
contract InterestValidator is PausableModule {
    event InterestCollected(
        address indexed feederPool,
        uint256 interest,
        uint256 newTotalSupply,
        uint256 apy
    );

    // Utils to help keep interest under check
    uint256 private constant SECONDS_IN_YEAR = 365 days;
    // Theoretical cap on APY to avoid excess inflation
    uint256 private constant MAX_APY = 15e18;

    mapping(address => uint256) public lastBatchCollected;

    constructor(address _nexus) PausableModule(_nexus) {}

    /**
     * @notice Collects and validates the interest of n feeder pools.
     * @dev First calls to calculate the interest that has accrued, and then validates the potential inflation
     * with respect to the previous timestamp.
     * @param _feeders     Addresses of the feeder pools on which to accrue interest
     */
    function collectAndValidateInterest(address[] calldata _feeders) external whenNotPaused {
        uint256 currentTime = block.timestamp;

        uint256 len = _feeders.length;

        for (uint256 i = 0; i < len; i++) {
            address feeder = _feeders[i];

            uint256 previousBatch = lastBatchCollected[feeder];
            uint256 timeSincePreviousBatch = currentTime - previousBatch;
            require(timeSincePreviousBatch > 12 hours, "Cannot collect twice in 12 hours");
            lastBatchCollected[feeder] = currentTime;

            // Batch collect
            (uint256 interestCollected, uint256 totalSupply) =
                IFeederPool(feeder).collectPlatformInterest();

            if (interestCollected > 0) {
                // Validate APY
                uint256 apy =
                    _validateCollection(totalSupply, interestCollected, timeSincePreviousBatch);

                emit InterestCollected(feeder, interestCollected, totalSupply, apy);
            } else {
                emit InterestCollected(feeder, interestCollected, totalSupply, 0);
            }
        }
    }

    /**
     * @dev Validates that an interest collection does not exceed a maximum APY. If last collection
     * was under 30 mins ago, simply check it does not exceed 10bps
     * @param _newSupply               New total supply of the mAsset
     * @param _interest                Increase in total supply since last collection
     * @param _timeSinceLastCollection Seconds since last collection
     */
    function _validateCollection(
        uint256 _newSupply,
        uint256 _interest,
        uint256 _timeSinceLastCollection
    ) internal pure returns (uint256 extrapolatedAPY) {
        // Percentage increase in total supply
        // e.g. (1e20 * 1e18) / 1e24 = 1e14 (or a 0.01% increase)
        // e.g. (5e18 * 1e18) / 1.2e24 = 4.1667e12
        // e.g. (1e19 * 1e18) / 1e21 = 1e16
        uint256 oldSupply = _newSupply - _interest;
        uint256 percentageIncrease = (_interest * 1e18) / oldSupply;

        //      If over 30 mins, extrapolate APY
        // e.g. day: (86400 * 1e18) / 3.154e7 = 2.74..e15
        // e.g. 30 mins: (1800 * 1e18) / 3.154e7 = 5.7..e13
        // e.g. epoch: (1593596907 * 1e18) / 3.154e7 = 50.4..e18
        uint256 yearsSinceLastCollection = (_timeSinceLastCollection * 1e18) / SECONDS_IN_YEAR;

        // e.g. 0.01% (1e14 * 1e18) / 2.74..e15 = 3.65e16 or 3.65% apr
        // e.g. (4.1667e12 * 1e18) / 5.7..e13 = 7.1e16 or 7.1% apr
        // e.g. (1e16 * 1e18) / 50e18 = 2e14
        extrapolatedAPY = (percentageIncrease * 1e18) / yearsSinceLastCollection;

        require(extrapolatedAPY < MAX_APY, "Interest protected from inflating past maxAPY");
    }
}