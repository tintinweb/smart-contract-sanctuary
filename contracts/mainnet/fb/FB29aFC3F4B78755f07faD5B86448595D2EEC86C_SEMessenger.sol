// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "./messenger/IMessenger.sol";

/**
 * @title MessengerRegistry
 * @dev MessengerRegistry is a contract to register openly distributed Messengers
 */
contract MessengerRegistry {
    struct Messenger {
        address ownerAddress;
        address messengerAddress;
        string specificationUrl;
        uint256 precision;
        uint256 requestsCounter;
        uint256 fulfillsCounter;
        uint256 id;
    }

    /// @dev array to store the messengers
    Messenger[] public messengers;
    /// @dev (messengerAddress=>bool) to check if the Messenger was
    mapping(address => bool) public registeredMessengers;
    /// @dev (userAddress=>messengerAddress[]) to register the messengers of an owner
    mapping(address => uint256[]) public ownerMessengers;
    /// @dev (userAddress=>messengerAddress[]) to register the owner of a Messenger
    address public slaRegistry;

    event MessengerRegistered(
        address indexed ownerAddress,
        address indexed messengerAddress,
        string specificationUrl,
        uint256 precision,
        uint256 id
    );

    event MessengerModified(
        address indexed ownerAddress,
        address indexed messengerAddress,
        string specificationUrl,
        uint256 precision,
        uint256 id
    );

    /**
     * @dev sets the SLARegistry contract address and can only be called
     * once
     */
    function setSLARegistry() external {
        // Only able to trigger this function once
        require(
            address(slaRegistry) == address(0),
            "SLARegistry address has already been set"
        );

        slaRegistry = msg.sender;
    }

    /**
     * @dev function to register a new Messenger
     */
    function registerMessenger(
        address _callerAddress,
        address _messengerAddress,
        string calldata _specificationUrl
    ) external {
        require(
            msg.sender == slaRegistry,
            "Should only be called using the SLARegistry contract"
        );
        require(
            !registeredMessengers[_messengerAddress],
            "messenger already registered"
        );

        IMessenger messenger = IMessenger(_messengerAddress);
        address messengerOwner = messenger.owner();
        require(
            messengerOwner == _callerAddress,
            "Should only be called by the messenger owner"
        );
        uint256 precision = messenger.messengerPrecision();
        uint256 requestsCounter = messenger.requestsCounter();
        uint256 fulfillsCounter = messenger.fulfillsCounter();
        registeredMessengers[_messengerAddress] = true;
        uint256 id = messengers.length - 1;
        ownerMessengers[messengerOwner].push(id);

        messengers.push(
            Messenger({
                ownerAddress: messengerOwner,
                messengerAddress: _messengerAddress,
                specificationUrl: _specificationUrl,
                precision: precision,
                requestsCounter: requestsCounter,
                fulfillsCounter: fulfillsCounter,
                id: id
            })
        );

        emit MessengerRegistered(
            messengerOwner,
            _messengerAddress,
            _specificationUrl,
            precision,
            id
        );
    }

    /**
     * @dev function to modifyMessenger a Messenger
     */
    function modifyMessenger(
        string calldata _specificationUrl,
        uint256 _messengerId
    ) external {
        Messenger storage storedMessenger = messengers[_messengerId];
        IMessenger messenger = IMessenger(storedMessenger.messengerAddress);
        require(
            msg.sender == messenger.owner(),
            "Can only be modified by the owner"
        );
        storedMessenger.specificationUrl = _specificationUrl;
        storedMessenger.ownerAddress = msg.sender;
        emit MessengerModified(
            storedMessenger.ownerAddress,
            storedMessenger.messengerAddress,
            storedMessenger.specificationUrl,
            storedMessenger.precision,
            storedMessenger.id
        );
    }

    function getMessengers() external view returns (Messenger[] memory) {
        Messenger[] memory returnMessengers =
            new Messenger[](messengers.length);
        for (uint256 index = 0; index < messengers.length; index++) {
            IMessenger messenger =
                IMessenger(messengers[index].messengerAddress);
            uint256 requestsCounter = messenger.requestsCounter();
            uint256 fulfillsCounter = messenger.fulfillsCounter();
            returnMessengers[index] = Messenger({
                ownerAddress: messengers[index].ownerAddress,
                messengerAddress: messengers[index].messengerAddress,
                specificationUrl: messengers[index].specificationUrl,
                precision: messengers[index].precision,
                requestsCounter: requestsCounter,
                fulfillsCounter: fulfillsCounter,
                id: messengers[index].id
            });
        }
        return returnMessengers;
    }

    function getMessengersLength() external view returns (uint256) {
        return messengers.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SLARegistry
 * @dev SLARegistry is a contract for handling creation of service level
 * agreements and keeping track of the created agreements
 */
contract PeriodRegistry is Ownable {
    using SafeMath for uint256;

    enum PeriodType {Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly}

    /// @dev struct to store the definition of a period
    struct PeriodDefinition {
        bool initialized;
        uint256[] starts;
        uint256[] ends;
    }

    /// @dev (periodType=>PeriodDefinition) hourly/weekly/biWeekly/monthly/yearly are periodTypes
    mapping(PeriodType => PeriodDefinition) public periodDefinitions;

    /**
     * @dev event to log a new period initialized
     *@param periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     *@param periodsAdded 2. amount of periods added
     */
    event PeriodInitialized(PeriodType periodType, uint256 periodsAdded);

    /**
     * @dev event to log a new period initialized
     *@param periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     *@param periodsAdded 2. amount of periods added
     */
    event PeriodModified(PeriodType periodType, uint256 periodsAdded);

    /**
     * @dev public function for creating canonical service level agreements
     *@param _periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     *@param _periodStarts 2. array of the starts of the period
     *@param _periodEnds 3. array of the ends of the period
     */
    function initializePeriod(
        PeriodType _periodType,
        uint256[] memory _periodStarts,
        uint256[] memory _periodEnds
    ) public onlyOwner {
        PeriodDefinition storage periodDefinition =
            periodDefinitions[_periodType];
        require(
            !periodDefinition.initialized,
            "Period type already initialized"
        );
        require(
            _periodStarts.length == _periodEnds.length,
            "Period type starts and ends should match"
        );
        require(_periodStarts.length > 0, "Period length can't be 0");
        for (uint256 index = 0; index < _periodStarts.length; index++) {
            require(
                _periodStarts[index] < _periodEnds[index],
                "Start should be before end"
            );
            if (index < _periodStarts.length - 1) {
                require(
                    _periodStarts[index + 1].sub(_periodEnds[index]) == 1,
                    "Start of a period should be 1 second after the end of the previous period"
                );
            }
            periodDefinition.starts.push(_periodStarts[index]);
            periodDefinition.ends.push(_periodEnds[index]);
        }
        periodDefinition.initialized = true;
        emit PeriodInitialized(_periodType, _periodStarts.length);
    }

    /**
     * @dev function to add new periods to certain period type
     *@param _periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     *@param _periodStarts 2. array of uint256 of the period starts to add
     *@param _periodEnds 3. array of uint256 of the period starts to add
     */
    function addPeriodsToPeriodType(
        PeriodType _periodType,
        uint256[] memory _periodStarts,
        uint256[] memory _periodEnds
    ) public onlyOwner {
        require(_periodStarts.length > 0, "Period length can't be 0");
        PeriodDefinition storage periodDefinition =
            periodDefinitions[_periodType];
        require(periodDefinition.initialized, "Period was not initialized yet");
        for (uint256 index = 0; index < _periodStarts.length; index++) {
            require(
                _periodStarts[index] < _periodEnds[index],
                "Start should be before end"
            );
            if (index < _periodStarts.length.sub(1)) {
                require(
                    _periodStarts[index + 1].sub(_periodEnds[index]) == 1,
                    "Start of a period should be 1 second after the end of the previous period"
                );
            }
            periodDefinition.starts.push(_periodStarts[index]);
            periodDefinition.ends.push(_periodEnds[index]);
        }
        emit PeriodModified(_periodType, _periodStarts.length);
    }

    /**
     * @dev public function to get the start and end of a period
     *@param _periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     *@param _periodId 2. period id to get start and end
     */
    function getPeriodStartAndEnd(PeriodType _periodType, uint256 _periodId)
        public
        view
        returns (uint256 start, uint256 end)
    {
        start = periodDefinitions[_periodType].starts[_periodId];
        end = periodDefinitions[_periodType].ends[_periodId];
    }

    /**
     * @dev public function to check if a periodType id is initialized
     *@param _periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     */
    function isInitializedPeriod(PeriodType _periodType)
        public
        view
        returns (bool initialized)
    {
        PeriodDefinition memory periodDefinition =
            periodDefinitions[_periodType];
        initialized = periodDefinition.initialized;
    }

    /**
     * @dev public function to check if a period id is valid i.e. it belongs to the added id array
     *@param _periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     *@param _periodId 2. period id to get start and end
     */
    function isValidPeriod(PeriodType _periodType, uint256 _periodId)
        public
        view
        returns (bool valid)
    {
        PeriodDefinition memory periodDefinition =
            periodDefinitions[_periodType];
        valid = periodDefinition.starts.length.sub(1) >= _periodId;
    }

    /**
     * @dev public function to check if a period has finished
     *@param _periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     *@param _periodId 2. period id to get start and end
     */
    function periodIsFinished(PeriodType _periodType, uint256 _periodId)
        public
        view
        returns (bool finished)
    {
        require(
            isValidPeriod(_periodType, _periodId),
            "Period data is not valid"
        );
        finished =
            periodDefinitions[_periodType].ends[_periodId] < block.timestamp;
    }

    /**
     * @dev public function to check if a period has started
     *@param _periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     *@param _periodId 2. period id to get start and end
     */
    function periodHasStarted(PeriodType _periodType, uint256 _periodId)
        public
        view
        returns (bool started)
    {
        require(
            isValidPeriod(_periodType, _periodId),
            "Period data is not valid"
        );
        started =
            periodDefinitions[_periodType].starts[_periodId] < block.timestamp;
    }

    /**
     * @dev public function to get the periodDefinitions
     */
    function getPeriodDefinitions()
        public
        view
        returns (PeriodDefinition[] memory)
    {
        // 6 period types
        PeriodDefinition[] memory periodDefinition = new PeriodDefinition[](6);
        periodDefinition[0] = periodDefinitions[PeriodType.Hourly];
        periodDefinition[1] = periodDefinitions[PeriodType.Daily];
        periodDefinition[2] = periodDefinitions[PeriodType.Weekly];
        periodDefinition[3] = periodDefinitions[PeriodType.BiWeekly];
        periodDefinition[4] = periodDefinitions[PeriodType.Monthly];
        periodDefinition[5] = periodDefinitions[PeriodType.Yearly];
        return periodDefinition;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./SLARegistry.sol";
import "./SLORegistry.sol";
import "./StakeRegistry.sol";
import "./PeriodRegistry.sol";
import "./Staking.sol";

/**
 * @title SLA
 * @dev SLA is a service level agreement contract used for service downtime
 * compensation
 */
contract SLA is Staking {
    using SafeMath for uint256;

    enum Status {NotVerified, Respected, NotRespected}

    struct PeriodSLI {
        uint256 timestamp;
        uint256 sli;
        Status status;
    }

    //
    string public ipfsHash;
    address public immutable messengerAddress;
    SLARegistry public slaRegistry;
    PeriodRegistry private immutable periodRegistry;
    SLORegistry private immutable sloRegistry;
    uint256 public immutable creationBlockNumber;
    uint128 public immutable initialPeriodId;
    uint128 public immutable finalPeriodId;
    PeriodRegistry.PeriodType public immutable periodType;
    /// @dev extra data for customized workflows
    bytes32[] public extraData;

    bool private _breachedContract = false;
    uint256 public nextVerifiablePeriod;

    /// @dev periodId=>PeriodSLI mapping
    mapping(uint256 => PeriodSLI) public periodSLIs;

    /**
     * @dev event for SLI creation logging
     * @param timestamp 1. the time the SLI has been registered
     * @param sli 2. the value of the SLI
     * @param periodId 3. the id of the given period
     */
    event SLICreated(uint256 timestamp, uint256 sli, uint256 periodId);

    /**
     * @dev event for Stake loging
     * @param tokenAddress 1. -
     * @param periodId 2. -
     * @param amount 3. -
     * @param caller 4. -
     */
    event Stake(
        address indexed tokenAddress,
        uint256 indexed periodId,
        address indexed caller,
        uint256 amount
    );
    /**
     * @dev event for Stake loging
     * @param tokenAddress 1. -
     * @param periodId 2. -
     * @param amount 3. -
     * @param caller 4. -
     */
    event ProviderWithdraw(
        address indexed tokenAddress,
        uint256 indexed periodId,
        address indexed caller,
        uint256 amount
    );
    /**
     * @dev event for Stake loging
     * @param tokenAddress 1. -
     * @param periodId 2. -
     * @param amount 3. -
     * @param caller 4. -
     */
    event UserWithdraw(
        address indexed tokenAddress,
        uint256 indexed periodId,
        address indexed caller,
        uint256 amount
    );

    /**
     * @dev throws if called by any address other than the messenger contract.
     */
    modifier onlyMessenger() {
        require(
            msg.sender == messengerAddress,
            "Only Messenger can call this function"
        );
        _;
    }

    /**
     * @dev throws if called by any address other than the messenger contract.
     */
    modifier onlySLARegistry() {
        require(
            msg.sender == address(slaRegistry),
            "Only SLARegistry can call this function"
        );
        _;
    }

    /**
     * @dev throws if called with an amount less or equal to zero.
     */
    modifier notZero(uint256 _amount) {
        require(_amount > 0, "amount cannot be 0");
        _;
    }

    /**
     * @param _owner 1. -
     * @param _ipfsHash 3. -
     * @param _messengerAddress 3. -
     * @param _initialPeriodId 4. -
     * @param _finalPeriodId 4. -
     * @param _periodType 5. -
     * @param _whitelisted 8. -
     * @param _extraData 9. -
     * @param _slaID 10. -
     */
    constructor(
        address _owner,
        bool _whitelisted,
        PeriodRegistry.PeriodType _periodType,
        address _messengerAddress,
        uint128 _initialPeriodId,
        uint128 _finalPeriodId,
        uint128 _slaID,
        string memory _ipfsHash,
        bytes32[] memory _extraData,
        uint64 _leverage
    )
        public
        Staking(
            SLARegistry(msg.sender),
            _periodType,
            _whitelisted,
            _slaID,
            _leverage,
            _owner
        )
    {
        transferOwnership(_owner);
        ipfsHash = _ipfsHash;
        messengerAddress = _messengerAddress;
        slaRegistry = SLARegistry(msg.sender);
        periodRegistry = slaRegistry.periodRegistry();
        sloRegistry = slaRegistry.sloRegistry();
        creationBlockNumber = block.number;
        initialPeriodId = _initialPeriodId;
        finalPeriodId = _finalPeriodId;
        periodType = _periodType;
        extraData = _extraData;
        nextVerifiablePeriod = _initialPeriodId;
    }

    /**
     * @dev external function to register SLI's and check them against the SLORegistry
     * @param _sli 1. the value of the SLI to check
     * @param _periodId 2. the id of the given period
     */
    function registerSLI(uint256 _sli, uint256 _periodId)
        external
        onlyMessenger
    {
        emit SLICreated(block.timestamp, _sli, _periodId);
        nextVerifiablePeriod = _periodId + 1;
        PeriodSLI storage periodSLI = periodSLIs[_periodId];
        periodSLI.sli = _sli;
        periodSLI.timestamp = block.timestamp;
        (uint256 sloValue, ) = sloRegistry.registeredSLO(address(this));
        if (sloRegistry.isRespected(_sli, address(this))) {
            periodSLI.status = Status.Respected;
            uint256 precision = 10000;
            uint256 deviation =
                _sli.sub(sloValue).mul(precision).div(
                    _sli.add(sloValue).div(2)
                );
            uint256 normalizedPeriodId = _periodId.sub(initialPeriodId).add(1);
            uint256 rewardPercentage =
                deviation.mul(normalizedPeriodId).div(
                    finalPeriodId - initialPeriodId + 1
                );
            _setRespectedPeriodReward(_periodId, rewardPercentage, precision);
        } else {
            periodSLI.status = Status.NotRespected;
            _setUsersCompensation(_periodId);
            _breachedContract = true;
        }
    }

    function isAllowedPeriod(uint256 _periodId) external view returns (bool) {
        if (_periodId < initialPeriodId) return false;
        if (_periodId > finalPeriodId) return false;
        return true;
    }

    function contractFinished() public view returns (bool) {
        (, uint256 endOfLastValidPeriod) =
            periodRegistry.getPeriodStartAndEnd(periodType, finalPeriodId);
        return
            _breachedContract == true ||
            (block.timestamp >= endOfLastValidPeriod &&
                periodSLIs[finalPeriodId].status != Status.NotVerified);
    }

    /**
     *@dev stake _amount tokens into the _token contract
     *@param _amount 1. amount to be staked
     *@param _token 2. address of the ERC to be staked
     */

    function stakeTokens(uint256 _amount, address _token)
        external
        notZero(_amount)
    {
        bool isContractFinished = contractFinished();
        require(
            !isContractFinished,
            "Can only stake on not finished contracts"
        );
        _stake(_amount, _token);
        emit Stake(_token, nextVerifiablePeriod, msg.sender, _amount);
        StakeRegistry stakeRegistry = slaRegistry.stakeRegistry();
        stakeRegistry.registerStakedSla(msg.sender);
    }

    function withdrawProviderTokens(uint256 _amount, address _tokenAddress)
        external
        notZero(_amount)
    {
        bool isContractFinished = contractFinished();
        emit ProviderWithdraw(
            _tokenAddress,
            nextVerifiablePeriod,
            msg.sender,
            _amount
        );
        _withdrawProviderTokens(_amount, _tokenAddress, isContractFinished);
    }

    /**
     *@dev withdraw _amount tokens from the _token contract
     *@param _amount 1. amount to be staked
     *@param _tokenAddress 2. address of the ERC to be staked
     */

    function withdrawUserTokens(uint256 _amount, address _tokenAddress)
        external
        notZero(_amount)
    {
        if (msg.sender != owner()) {
            bool isContractFinished = contractFinished();
            require(isContractFinished, "Only for finished contract");
        }
        emit UserWithdraw(
            _tokenAddress,
            nextVerifiablePeriod,
            msg.sender,
            _amount
        );
        _withdrawUserTokens(_amount, _tokenAddress);
    }

    function getStakersLength() external view returns (uint256) {
        return stakers.length;
    }

    function breachedContract() external view returns (bool) {
        return _breachedContract;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./SLA.sol";
import "./SLORegistry.sol";
import "./PeriodRegistry.sol";
import "./MessengerRegistry.sol";
import "./StakeRegistry.sol";
import "./messenger/IMessenger.sol";

/**
 * @title SLARegistry
 * @dev SLARegistry is a contract for handling creation of service level
 * agreements and keeping track of the created agreements
 */
contract SLARegistry {
    using SafeMath for uint256;

    /// @dev SLO registry
    SLORegistry public sloRegistry;
    /// @dev Periods registry
    PeriodRegistry public periodRegistry;
    /// @dev Messengers registry
    MessengerRegistry public messengerRegistry;
    /// @dev Stake registry
    StakeRegistry public stakeRegistry;
    /// @dev stores the addresses of created SLAs
    SLA[] public SLAs;
    /// @dev stores the indexes of service level agreements owned by an user
    mapping(address => uint256[]) private userToSLAIndexes;
    /// @dev to check if registered SLA
    mapping(address => bool) private registeredSLAs;
    // value to lock past periods on SLA deployment
    bool public immutable checkPastPeriod;

    /**
     * @dev event for service level agreement creation logging
     * @param sla 1. The address of the created service level agreement contract
     * @param owner 2. The address of the owner of the service level agreement
     */
    event SLACreated(SLA indexed sla, address indexed owner);

    /**
     * @dev event for service level agreement creation logging
     * @param periodId 1. -
     * @param sla 2. -
     * @param caller 3. -
     */
    event SLIRequested(
        uint256 periodId,
        address indexed sla,
        address indexed caller
    );

    /**
     * @dev event for service level agreement creation logging
     * @param sla 1. -
     * @param caller 2. -
     */
    event ReturnLockedValue(address indexed sla, address indexed caller);

    /**
     * @dev constructor
     * @param _sloRegistry 1. SLO Registry
     * @param _periodRegistry 2. Periods registry
     * @param _messengerRegistry 3. Messenger registry
     * @param _stakeRegistry 4. Stake registry
     * @param _checkPastPeriod 5. -
     */
    constructor(
        SLORegistry _sloRegistry,
        PeriodRegistry _periodRegistry,
        MessengerRegistry _messengerRegistry,
        StakeRegistry _stakeRegistry,
        bool _checkPastPeriod
    ) public {
        sloRegistry = _sloRegistry;
        sloRegistry.setSLARegistry();
        periodRegistry = _periodRegistry;
        stakeRegistry = _stakeRegistry;
        stakeRegistry.setSLARegistry();
        messengerRegistry = _messengerRegistry;
        messengerRegistry.setSLARegistry();
        checkPastPeriod = _checkPastPeriod;
    }

    /**
     * @dev public function for creating canonical service level agreements
     * @param _sloValue 1. -
     * @param _sloType 2. -
     * @param _ipfsHash 3. -
     * @param _periodType 4. -
     * @param _initialPeriodId 5. -
     * @param _finalPeriodId 6. -
     * @param _messengerAddress 7. -
     * @param _whitelisted 8. -
     * @param _extraData 9. -
     * @param _leverage 10. -
     */
    function createSLA(
        uint256 _sloValue,
        SLORegistry.SLOType _sloType,
        bool _whitelisted,
        address _messengerAddress,
        PeriodRegistry.PeriodType _periodType,
        uint128 _initialPeriodId,
        uint128 _finalPeriodId,
        string memory _ipfsHash,
        bytes32[] memory _extraData,
        uint64 _leverage
    ) public {
        bool validPeriod =
            periodRegistry.isValidPeriod(_periodType, _initialPeriodId);
        require(validPeriod, "First period id not valid");
        validPeriod = periodRegistry.isValidPeriod(_periodType, _finalPeriodId);
        require(validPeriod, "Final period id not valid");
        bool initializedPeriod =
            periodRegistry.isInitializedPeriod(_periodType);
        require(initializedPeriod, "Period type not initialized yet");
        require(
            _finalPeriodId >= _initialPeriodId,
            "invalid finalPeriodId and initialPeriodId"
        );

        if (checkPastPeriod) {
            bool periodHasStarted =
                periodRegistry.periodHasStarted(_periodType, _initialPeriodId);
            require(!periodHasStarted, "Period has started");
        }
        bool registeredMessenger =
            messengerRegistry.registeredMessengers(_messengerAddress);
        require(registeredMessenger == true, "messenger not registered");

        SLA sla =
            new SLA(
                msg.sender,
                _whitelisted,
                _periodType,
                _messengerAddress,
                _initialPeriodId,
                _finalPeriodId,
                uint128(SLAs.length),
                _ipfsHash,
                _extraData,
                _leverage
            );

        sloRegistry.registerSLO(_sloValue, _sloType, address(sla));
        stakeRegistry.lockDSLAValue(
            msg.sender,
            address(sla),
            _finalPeriodId - _initialPeriodId + 1
        );
        SLAs.push(sla);
        registeredSLAs[address(sla)] = true;
        uint256 index = SLAs.length.sub(1);
        userToSLAIndexes[msg.sender].push(index);
        emit SLACreated(sla, msg.sender);
    }

    /**
     * @dev Gets SLI information for the specified SLA and SLO
     * @param _periodId 1. id of the period
     * @param _sla 2. SLA Address
     * @param _ownerApproval 3. if approval by owner or msg.sender
     */
    function requestSLI(
        uint256 _periodId,
        SLA _sla,
        bool _ownerApproval
    ) public {
        require(isRegisteredSLA(address(_sla)), "invalid SLA");
        require(_periodId == _sla.nextVerifiablePeriod(), "invalid periodId");
        (, , SLA.Status status) = _sla.periodSLIs(_periodId);
        require(status == SLA.Status.NotVerified, "invalid SLA status");
        bool breachedContract = _sla.breachedContract();
        require(!breachedContract, "breached contract");
        bool slaAllowedPeriodId = _sla.isAllowedPeriod(_periodId);
        require(slaAllowedPeriodId, "invalid period Id");
        PeriodRegistry.PeriodType slaPeriodType = _sla.periodType();
        bool periodFinished =
            periodRegistry.periodIsFinished(slaPeriodType, _periodId);
        require(periodFinished, "period not finished");
        address slaMessenger = _sla.messengerAddress();
        SLIRequested(_periodId, address(_sla), msg.sender);
        IMessenger(slaMessenger).requestSLI(
            _periodId,
            address(_sla),
            _ownerApproval,
            msg.sender
        );
        stakeRegistry.distributeVerificationRewards(
            address(_sla),
            msg.sender,
            _periodId
        );
    }

    function returnLockedValue(SLA _sla) public {
        require(isRegisteredSLA(address(_sla)), "invalid SLA");
        require(msg.sender == _sla.owner(), "msg.sender not owner");
        uint256 lastValidPeriodId = _sla.finalPeriodId();
        PeriodRegistry.PeriodType periodType = _sla.periodType();
        (, uint256 endOfLastValidPeriod) =
            periodRegistry.getPeriodStartAndEnd(periodType, lastValidPeriodId);

        (, , SLA.Status lastPeriodStatus) = _sla.periodSLIs(lastValidPeriodId);
        require(
            _sla.breachedContract() ||
                (block.timestamp >= endOfLastValidPeriod &&
                    lastPeriodStatus != SLA.Status.NotVerified),
            "Should only withdraw for finished contracts"
        );
        ReturnLockedValue(address(_sla), msg.sender);
        stakeRegistry.returnLockedValue(address(_sla));
    }

    /**
     * @dev function to declare this SLARegistry contract as SLARegistry of _messengerAddress
     * @param _messengerAddress 1. address of the messenger
     */

    function registerMessenger(
        address _messengerAddress,
        string memory _specificationUrl
    ) public {
        IMessenger(_messengerAddress).setSLARegistry();
        messengerRegistry.registerMessenger(
            msg.sender,
            _messengerAddress,
            _specificationUrl
        );
    }

    /**
     * @dev public view function that returns the service level agreements that
     * the given user is the owner of
     * @param _user Address of the user for which to return the service level
     * agreements
     * @return array of SLAs
     */
    function userSLAs(address _user) public view returns (SLA[] memory) {
        uint256 count = userToSLAIndexes[_user].length;
        SLA[] memory SLAList = new SLA[](count);
        uint256[] memory userSLAIndexes = userToSLAIndexes[_user];

        for (uint256 i = 0; i < count; i++) {
            SLAList[i] = (SLAs[userSLAIndexes[i]]);
        }

        return (SLAList);
    }

    /**
     * @dev public view function that returns all the service level agreements
     * @return SLA[] array of SLAs
     */
    function allSLAs() public view returns (SLA[] memory) {
        return (SLAs);
    }

    /**
     * @dev public view function that returns true if _slaAddress was deployed using this SLARegistry
     * @param _slaAddress address of the SLA to be checked
     */
    function isRegisteredSLA(address _slaAddress) public view returns (bool) {
        return registeredSLAs[_slaAddress];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

/**
 * @title SLORegistry
 * @dev SLORegistry is a contract for handling creation of service level
 * objectives and querying those service level objectives
 */
contract SLORegistry {
    enum SLOType {
        EqualTo,
        NotEqualTo,
        SmallerThan,
        SmallerOrEqualTo,
        GreaterThan,
        GreaterOrEqualTo
    }

    struct SLO {
        uint256 sloValue;
        SLOType sloType;
    }
    /**
     * @dev SLO Registered event
     * @param sla 1. -
     * @param sloValue 2. -
     * @param sloType 3. -
     */
    event SLORegistered(address indexed sla, uint256 sloValue, SLOType sloType);

    address private slaRegistry;
    mapping(address => SLO) public registeredSLO;

    modifier onlySLARegistry {
        require(
            msg.sender == slaRegistry,
            "Should only be called using the SLARegistry contract"
        );
        _;
    }

    function setSLARegistry() public {
        // Only able to trigger this function once
        require(
            address(slaRegistry) == address(0),
            "SLARegistry address has already been set"
        );
        slaRegistry = msg.sender;
    }

    /**
     * @dev public function for creating service level objectives
     * @param _sloValue 1. -
     * @param _sloType 2. -
     * @param _slaAddress 3. -
     */
    function registerSLO(
        uint256 _sloValue,
        SLOType _sloType,
        address _slaAddress
    ) public onlySLARegistry {
        registeredSLO[_slaAddress] = SLO({
            sloValue: _sloValue,
            sloType: _sloType
        });
        emit SLORegistered(_slaAddress, _sloValue, _sloType);
    }

    /**
     * @dev external view function to check a value against the SLO
     * @param _value The SLI value to check against the SL
     * @return boolean with the SLO honored state
     */
    function isRespected(uint256 _value, address _slaAddress)
        public
        view
        returns (bool)
    {
        SLO memory slo = registeredSLO[_slaAddress];
        SLOType sloType = slo.sloType;
        uint256 sloValue = slo.sloValue;

        if (sloType == SLOType.EqualTo) {
            return _value == sloValue;
        }

        if (sloType == SLOType.NotEqualTo) {
            return _value != sloValue;
        }

        if (sloType == SLOType.SmallerThan) {
            return _value < sloValue;
        }

        if (sloType == SLOType.SmallerOrEqualTo) {
            return _value <= sloValue;
        }

        if (sloType == SLOType.GreaterThan) {
            return _value > sloValue;
        }

        if (sloType == SLOType.GreaterOrEqualTo) {
            return _value >= sloValue;
        }
        revert("isRespected wasn't executed properly");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./SLA.sol";
import "./messenger/IMessenger.sol";
import "./SLARegistry.sol";
import "./StringUtils.sol";

/**
 * @title StakeRegistry
 * @dev StakeRegistry is a contract to register the staking activity of the platform, along
 with controlling certain admin privileged parameters
 */
contract StakeRegistry is Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    /// @dev struct to return on getActivePool function.
    struct ActivePool {
        address SLAAddress;
        uint256 stake;
        string assetName;
        address assetAddress;
    }

    struct LockedValue {
        uint256 lockedValue;
        uint256 slaPeriodIdsLength;
        uint256 dslaDepositByPeriod;
        uint256 dslaPlatformReward;
        uint256 dslaMessengerReward;
        uint256 dslaUserReward;
        uint256 dslaBurnedByVerification;
        mapping(uint256 => bool) verifiedPeriods;
    }

    address public DSLATokenAddress;
    SLARegistry public slaRegistry;

    //______ onlyOwner modifiable parameters ______

    /// @dev corresponds to the burn rate of DSLA tokens, but divided by 1000 i.e burn percentage = DSLAburnRate/1000 %
    uint256 private _DSLAburnRate = 3;
    /// @dev (ownerAddress => slaAddress => LockedValue) stores the locked value by the staker
    mapping(address => LockedValue) public slaLockedValue;
    /// @dev DSLA deposit by period to create SLA
    uint256 private _dslaDepositByPeriod = 1000 ether;
    /// @dev DSLA rewarded to the foundation
    uint256 private _dslaPlatformReward = 250 ether;
    /// @dev DSLA rewarded to the Messenger creator
    uint256 private _dslaMessengerReward = 250 ether;
    /// @dev DSLA rewarded to user calling the period verification
    uint256 private _dslaUserReward = 250 ether;
    /// @dev DSLA burned after every period verification
    uint256 private _dslaBurnedByVerification = 250 ether;
    /// @dev max token length for allowedTokens array of Staking contracts
    uint256 private _maxTokenLength = 1;
    /// @dev max times of hedge leverage
    uint64 private _maxLeverage = 100;

    /// @dev array with the allowed tokens addresses of the StakeRegistry
    address[] public allowedTokens;

    /// @dev (userAddress => SLA[]) with user staked SLAs to get tokenPool
    mapping(address => SLA[]) public userStakedSlas;

    /**
     * @dev event to log a verifiation reward distributed
     * @param sla 1. The address of the created service level agreement contract
     * @param requester 2. -
     * @param userReward 3. -
     * @param platformReward 4. -
     * @param messengerReward 5. -
     * @param burnedDSLA 6. -
     */
    event VerificationRewardDistributed(
        address indexed sla,
        address indexed requester,
        uint256 userReward,
        uint256 platformReward,
        uint256 messengerReward,
        uint256 burnedDSLA
    );

    /**
     * @dev event to log modifications on the staking parameters
     *@param DSLAburnRate 1. (DSLAburnRate/1000)% of DSLA to be burned after a reward/compensation is paid
     *@param dslaDepositByPeriod 2. DSLA deposit by period to create SLA
     *@param dslaPlatformReward 3. DSLA rewarded to Stacktical team
     *@param dslaUserReward 4. DSLA rewarded to user calling the period verification
     *@param dslaBurnedByVerification 5. DSLA burned after every period verification
     */
    event StakingParametersModified(
        uint256 DSLAburnRate,
        uint256 dslaDepositByPeriod,
        uint256 dslaPlatformReward,
        uint256 dslaMessengerReward,
        uint256 dslaUserReward,
        uint256 dslaBurnedByVerification,
        uint256 maxTokenLength,
        uint64 maxLeverage
    );

    /**
     * @dev event to log modifications on the staking parameters
     *@param sla 1. -
     *@param owner 2. -
     *@param amount 3. -
     */

    event LockedValueReturned(
        address indexed sla,
        address indexed owner,
        uint256 amount
    );

    /**
     * @dev event to log modifications on the staking parameters
     *@param dTokenAddress 1. -
     *@param sla 2. -
     *@param name 3. -
     *@param symbol 4. -
     */
    event DTokenCreated(
        address indexed dTokenAddress,
        address indexed sla,
        string name,
        string symbol
    );

    /**
     * @dev event to log modifications on the staking parameters
     *@param sla 1. -
     *@param owner 2. -
     *@param amount 3. -
     */
    event ValueLocked(
        address indexed sla,
        address indexed owner,
        uint256 amount
    );

    /**
     * @param _dslaTokenAddress 1. DSLA Token
     */
    constructor(address _dslaTokenAddress) public {
        require(
            _dslaDepositByPeriod ==
                _dslaPlatformReward
                    .add(_dslaMessengerReward)
                    .add(_dslaUserReward)
                    .add(_dslaBurnedByVerification),
            "Staking parameters should match on summation"
        );
        DSLATokenAddress = _dslaTokenAddress;
        allowedTokens.push(_dslaTokenAddress);
    }

    /// @dev Throws if called by any address other than the SLARegistry contract or Chainlink Oracle.
    modifier onlySLARegistry() {
        require(
            msg.sender == address(slaRegistry),
            "Can only be called by SLARegistry"
        );
        _;
    }

    /**
     * @dev sets the SLARegistry contract address and can only be called
     * once
     */
    function setSLARegistry() external {
        // Only able to trigger this function once
        require(
            address(slaRegistry) == address(0),
            "SLARegistry address has already been set"
        );

        slaRegistry = SLARegistry(msg.sender);
    }

    /**
     *@dev add a token to ve allowed for staking
     *@param _tokenAddress 1. address of the new allowed token
     */
    function addAllowedTokens(address _tokenAddress) external onlyOwner {
        require(!isAllowedToken(_tokenAddress), "token already added");
        allowedTokens.push(_tokenAddress);
    }

    function isAllowedToken(address _tokenAddress) public view returns (bool) {
        for (uint256 index = 0; index < allowedTokens.length; index++) {
            if (allowedTokens[index] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }

    /**
     *@dev public view function that returns true if the _owner has staked on _sla
     *@param _user 1. address to check
     *@param _sla 2. sla to check
     *@return bool, true if _sla was staked by _user
     */

    function slaWasStakedByUser(address _user, address _sla)
        public
        view
        returns (bool)
    {
        for (uint256 index = 0; index < userStakedSlas[_user].length; index++) {
            if (address(userStakedSlas[_user][index]) == _sla) {
                return true;
            }
        }
        return false;
    }

    /**
     *@dev register the sending SLA contract as staked by _owner
     *@param _owner 1. SLA contract to stake
     */
    function registerStakedSla(address _owner) external returns (bool) {
        require(
            slaRegistry.isRegisteredSLA(msg.sender),
            "Only for registered SLAs"
        );
        if (!slaWasStakedByUser(_owner, msg.sender)) {
            userStakedSlas[_owner].push(SLA(msg.sender));
        }
        return true;
    }

    /**
     *@dev to create dTokens for staking
     *@param _name 1. token name
     *@param _symbol 2. token symbol
     */
    function createDToken(string calldata _name, string calldata _symbol)
        external
        returns (address)
    {
        require(
            slaRegistry.isRegisteredSLA(msg.sender),
            "Only for registered SLAs"
        );
        ERC20PresetMinterPauser dToken =
            new ERC20PresetMinterPauser(_name, _symbol);
        dToken.grantRole(dToken.MINTER_ROLE(), msg.sender);
        emit DTokenCreated(address(dToken), msg.sender, _name, _symbol);
        return address(dToken);
    }

    function lockDSLAValue(
        address _slaOwner,
        address _sla,
        uint256 _periodIdsLength
    ) external onlySLARegistry nonReentrant {
        uint256 lockedValue = _dslaDepositByPeriod.mul(_periodIdsLength);
        ERC20(DSLATokenAddress).safeTransferFrom(
            _slaOwner,
            address(this),
            lockedValue
        );
        slaLockedValue[_sla] = LockedValue({
            lockedValue: lockedValue,
            slaPeriodIdsLength: _periodIdsLength,
            dslaDepositByPeriod: _dslaDepositByPeriod,
            dslaPlatformReward: _dslaPlatformReward,
            dslaMessengerReward: _dslaMessengerReward,
            dslaUserReward: _dslaUserReward,
            dslaBurnedByVerification: _dslaBurnedByVerification
        });
        emit ValueLocked(_sla, _slaOwner, lockedValue);
    }

    function distributeVerificationRewards(
        address _sla,
        address _verificationRewardReceiver,
        uint256 _periodId
    ) external onlySLARegistry nonReentrant {
        LockedValue storage _lockedValue = slaLockedValue[_sla];
        require(
            !_lockedValue.verifiedPeriods[_periodId],
            "Period rewards already distributed"
        );
        _lockedValue.verifiedPeriods[_periodId] = true;
        _lockedValue.lockedValue = _lockedValue.lockedValue.sub(
            _lockedValue.dslaDepositByPeriod
        );
        ERC20(DSLATokenAddress).safeTransfer(
            _verificationRewardReceiver,
            _lockedValue.dslaUserReward
        );
        ERC20(DSLATokenAddress).safeTransfer(
            owner(),
            _lockedValue.dslaPlatformReward
        );
        ERC20(DSLATokenAddress).safeTransfer(
            IMessenger(SLA(_sla).messengerAddress()).owner(),
            _lockedValue.dslaMessengerReward
        );
        _burnDSLATokens(_lockedValue.dslaBurnedByVerification);
        emit VerificationRewardDistributed(
            _sla,
            _verificationRewardReceiver,
            _lockedValue.dslaUserReward,
            _lockedValue.dslaPlatformReward,
            _lockedValue.dslaMessengerReward,
            _lockedValue.dslaBurnedByVerification
        );
    }

    function returnLockedValue(address _sla)
        external
        onlySLARegistry
        nonReentrant
    {
        LockedValue storage _lockedValue = slaLockedValue[_sla];
        uint256 remainingBalance = _lockedValue.lockedValue;
        require(remainingBalance > 0, "locked value is empty");
        _lockedValue.lockedValue = 0;
        ERC20(DSLATokenAddress).safeTransfer(
            SLA(_sla).owner(),
            remainingBalance
        );
        emit LockedValueReturned(_sla, SLA(_sla).owner(), remainingBalance);
    }

    function _burnDSLATokens(uint256 _amount) internal {
        bytes4 BURN_SELECTOR = bytes4(keccak256(bytes("burn(uint256)")));
        (bool _success, ) =
            DSLATokenAddress.call(
                abi.encodeWithSelector(BURN_SELECTOR, _amount)
            );
        require(_success, "DSLA burn process was not successful");
    }

    /**
     * @dev returns the active pools owned by a user.
     * @param _slaOwner 1. owner of the active pool
     * @return ActivePool[], array of structs: {SLAAddress,stake,assetName}
     */
    function getActivePool(address _slaOwner)
        external
        view
        returns (ActivePool[] memory)
    {
        bytes4 NAME_SELECTOR = bytes4(keccak256(bytes("name()")));
        uint256 stakeCounter = 0;
        // Count the stakes of the user, checking every SLA staked
        for (
            uint256 index = 0;
            index < userStakedSlas[_slaOwner].length;
            index++
        ) {
            SLA currentSLA = SLA(userStakedSlas[_slaOwner][index]);
            stakeCounter = stakeCounter.add(
                currentSLA.getAllowedTokensLength()
            );
        }

        ActivePool[] memory activePools = new ActivePool[](stakeCounter);
        // to insert on activePools array
        uint256 stakePosition = 0;
        for (
            uint256 index = 0;
            index < userStakedSlas[_slaOwner].length;
            index++
        ) {
            SLA currentSLA = userStakedSlas[_slaOwner][index];
            for (
                uint256 tokenIndex = 0;
                tokenIndex < currentSLA.getAllowedTokensLength();
                tokenIndex++
            ) {
                (address tokenAddress, uint256 stake) =
                    currentSLA.getTokenStake(_slaOwner, tokenIndex);
                (, bytes memory tokenNameBytes) =
                    tokenAddress.staticcall(
                        abi.encodeWithSelector(NAME_SELECTOR)
                    );
                ActivePool memory currentActivePool =
                    ActivePool({
                        SLAAddress: address(currentSLA),
                        stake: stake,
                        assetName: string(tokenNameBytes),
                        assetAddress: tokenAddress
                    });
                activePools[stakePosition] = currentActivePool;
                stakePosition = stakePosition.add(1);
            }
        }
        return activePools;
    }

    //_______ OnlyOwner functions _______
    function setStakingParameters(
        uint256 DSLAburnRate,
        uint256 dslaDepositByPeriod,
        uint256 dslaPlatformReward,
        uint256 dslaMessengerReward,
        uint256 dslaUserReward,
        uint256 dslaBurnedByVerification,
        uint256 maxTokenLength,
        uint64 maxLeverage
    ) external onlyOwner {
        _DSLAburnRate = DSLAburnRate;
        _dslaDepositByPeriod = dslaDepositByPeriod;
        _dslaPlatformReward = dslaPlatformReward;
        _dslaMessengerReward = dslaMessengerReward;
        _dslaUserReward = dslaUserReward;
        _dslaBurnedByVerification = dslaBurnedByVerification;
        _maxTokenLength = maxTokenLength;
        _maxLeverage = maxLeverage;
        require(
            _dslaDepositByPeriod ==
                _dslaPlatformReward
                    .add(_dslaMessengerReward)
                    .add(_dslaUserReward)
                    .add(_dslaBurnedByVerification),
            "Staking parameters should match on summation"
        );
        emit StakingParametersModified(
            DSLAburnRate,
            dslaDepositByPeriod,
            dslaPlatformReward,
            dslaMessengerReward,
            dslaUserReward,
            dslaBurnedByVerification,
            maxTokenLength,
            maxLeverage
        );
    }

    function getStakingParameters()
        external
        view
        returns (
            uint256 DSLAburnRate,
            uint256 dslaDepositByPeriod,
            uint256 dslaPlatformReward,
            uint256 dslaMessengerReward,
            uint256 dslaUserReward,
            uint256 dslaBurnedByVerification,
            uint256 maxTokenLength,
            uint64 maxLeverage
        )
    {
        DSLAburnRate = _DSLAburnRate;
        dslaDepositByPeriod = _dslaDepositByPeriod;
        dslaPlatformReward = _dslaPlatformReward;
        dslaMessengerReward = _dslaMessengerReward;
        dslaUserReward = _dslaUserReward;
        dslaBurnedByVerification = _dslaBurnedByVerification;
        maxTokenLength = _maxTokenLength;
        maxLeverage = _maxLeverage;
    }

    function periodIsVerified(address _sla, uint256 _periodId)
        external
        view
        returns (bool)
    {
        return slaLockedValue[_sla].verifiedPeriods[_periodId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./StakeRegistry.sol";
import "./SLARegistry.sol";
import "./PeriodRegistry.sol";
import "./StringUtils.sol";

contract Staking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    /// @dev StakeRegistry contract
    StakeRegistry private stakeRegistry;
    /// @dev SLARegistry contract
    PeriodRegistry private immutable periodRegistry;
    /// @dev current SLA id
    uint128 public immutable slaID;

    /// @dev (tokenAddress=>uint256) total pooled token balance
    mapping(address => uint256) public providerPool;
    /// @dev (tokenAddress=>uint256) total pooled token balance
    mapping(address => uint256) public usersPool;

    ///@dev (tokenAddress=>dTokenAddress) to keep track of dToken for users
    mapping(address => ERC20PresetMinterPauser) public duTokenRegistry;
    ///@dev (tokenAddress=>dTokenAddress) to keep track of dToken for provider
    mapping(address => ERC20PresetMinterPauser) public dpTokenRegistry;

    /// @dev address[] of the stakers of the SLA contract
    address[] public stakers;
    /// @dev (slaOwner=>bool)
    mapping(address => bool) public registeredStakers;
    /// @dev DSLA token address to burn fees
    address public immutable dslaTokenAddress;
    /// @dev array with the allowed tokens addresses for the current SLA
    address[] public allowedTokens;

    /// @dev corresponds to the burn rate of DSLA tokens, but divided by 1000 i.e burn percentage = burnRate/1000 %
    uint256 public immutable DSLAburnRate;

    /// @dev PeriodRegistry period type of the SLA contract
    PeriodRegistry.PeriodType private immutable periodType;

    /// @dev boolean to declare if contract is whitelisted
    bool public immutable whitelistedContract;
    /// @dev (userAddress=bool) to declare whitelisted addresses
    mapping(address => bool) public whitelist;

    uint64 public immutable leverage;

    modifier onlyAllowedToken(address _token) {
        require(isAllowedToken(_token) == true, "token is not allowed");
        _;
    }

    modifier onlyWhitelisted {
        if (whitelistedContract == true) {
            require(whitelist[msg.sender] == true, "Not whitelisted");
        }
        _;
    }

    /**
     * @dev event for provider reward log
     * @param periodId 1. id of the period
     * @param tokenAddress 2. address of the token
     * @param rewardPercentage 3. reward percentage for the provider
     * @param rewardPercentagePrecision 4. reward percentage for the provider
     * @param rewardAmount 5. amount rewarded
     */
    event ProviderRewardGenerated(
        uint256 indexed periodId,
        address indexed tokenAddress,
        uint256 rewardPercentage,
        uint256 rewardPercentagePrecision,
        uint256 rewardAmount
    );

    event UserCompensationGenerated(
        uint256 indexed periodId,
        address indexed tokenAddress,
        uint256 usersStake,
        uint256 leverage,
        uint256 compensation
    );

    event DTokensCreated(
        address indexed tokenAddress,
        address indexed dpTokenAddress,
        string dpTokenName,
        string dpTokenSymbol,
        address indexed duTokenAddress,
        string duTokenName,
        string duTokenSymbol
    );

    /**
     *@param _slaRegistryAddress 1. period type of the SLA
     *@param _periodType 3. period type of the SLA
     *@param _whitelistedContract 5. enables the white list feature
     *@param _slaID 6. identifies the SLA to uniquely to emit dTokens
     */
    constructor(
        SLARegistry _slaRegistry,
        PeriodRegistry.PeriodType _periodType,
        bool _whitelistedContract,
        uint128 _slaID,
        uint64 _leverage,
        address _contractOwner
    ) public {
        stakeRegistry = _slaRegistry.stakeRegistry();
        periodRegistry = _slaRegistry.periodRegistry();
        periodType = _periodType;
        whitelistedContract = _whitelistedContract;
        (uint256 _DSLAburnRate, , , , , , , uint64 _maxLeverage) =
            stakeRegistry.getStakingParameters();
        dslaTokenAddress = stakeRegistry.DSLATokenAddress();
        DSLAburnRate = _DSLAburnRate;
        whitelist[_contractOwner] = true;
        slaID = _slaID;
        require(
            _leverage <= _maxLeverage && _leverage >= 1,
            "Incorrect leverage"
        );
        leverage = _leverage;
    }

    function addUsersToWhitelist(address[] memory _userAddresses)
        public
        onlyOwner
    {
        for (uint256 index = 0; index < _userAddresses.length; index++) {
            if (whitelist[_userAddresses[index]] == false) {
                whitelist[_userAddresses[index]] = true;
            }
        }
    }

    function removeUsersFromWhitelist(address[] calldata _userAddresses)
        external
        onlyOwner
    {
        for (uint256 index = 0; index < _userAddresses.length; index++) {
            if (whitelist[_userAddresses[index]] == true) {
                whitelist[_userAddresses[index]] = false;
            }
        }
    }

    /**
     *@dev add a token to ve allowed for staking
     *@param _tokenAddress 1. address of the new allowed token
     */
    function addAllowedTokens(address _tokenAddress) external onlyOwner {
        (, , , , , , uint256 maxTokenLength, ) =
            stakeRegistry.getStakingParameters();
        require(!isAllowedToken(_tokenAddress), "Token already added");
        require(
            stakeRegistry.isAllowedToken(_tokenAddress),
            "Token not allowed by the SLARegistry contract"
        );
        allowedTokens.push(_tokenAddress);
        require(
            maxTokenLength >= allowedTokens.length,
            "Allowed tokens length greater than max token length"
        );
        string memory dTokenID = StringUtils.uintToStr(slaID);
        string memory duTokenName =
            string(abi.encodePacked("DSLA-SHORT-", dTokenID));
        string memory duTokenSymbol =
            string(abi.encodePacked("DSLA-SP-", dTokenID));
        string memory dpTokenName =
            string(abi.encodePacked("DSLA-LONG-", dTokenID));
        string memory dpTokenSymbol =
            string(abi.encodePacked("DSLA-LP-", dTokenID));

        ERC20PresetMinterPauser duToken =
            ERC20PresetMinterPauser(
                stakeRegistry.createDToken(duTokenName, duTokenSymbol)
            );
        ERC20PresetMinterPauser dpToken =
            ERC20PresetMinterPauser(
                stakeRegistry.createDToken(dpTokenName, dpTokenSymbol)
            );

        dpTokenRegistry[_tokenAddress] = dpToken;
        duTokenRegistry[_tokenAddress] = duToken;
        emit DTokensCreated(
            _tokenAddress,
            address(dpToken),
            dpTokenName,
            dpTokenName,
            address(duToken),
            duTokenName,
            duTokenName
        );
    }

    /**
     *@dev increase the amount staked per token
     *@param _amount 1. amount to be staked
     *@param _tokenAddress 2. address of the token
     *@notice providers can stake at any time
     *@notice users can stake at any time but no more than provider pool
     */
    function _stake(uint256 _amount, address _tokenAddress)
        internal
        onlyAllowedToken(_tokenAddress)
        onlyWhitelisted
    {
        ERC20(_tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        //duTokens
        if (msg.sender != owner()) {
            (uint256 providerStake, uint256 usersStake) =
                (providerPool[_tokenAddress], usersPool[_tokenAddress]);
            require(
                usersStake.add(_amount).mul(leverage) <= providerStake,
                "Incorrect user stake"
            );
            ERC20PresetMinterPauser duToken = duTokenRegistry[_tokenAddress];
            uint256 p0 = duToken.totalSupply();

            // if there's no minted tokens, then create 1-1 proportion
            if (p0 == 0) {
                duToken.mint(msg.sender, _amount);
            } else {
                uint256 t0 = usersPool[_tokenAddress];
                // mint dTokens proportionally
                uint256 mintedDUTokens = _amount.mul(p0).div(t0);
                duToken.mint(msg.sender, mintedDUTokens);
            }
            usersPool[_tokenAddress] = usersPool[_tokenAddress].add(_amount);
            //dpTokens
        } else {
            ERC20PresetMinterPauser dpToken = dpTokenRegistry[_tokenAddress];
            uint256 p0 = dpToken.totalSupply();

            if (p0 == 0) {
                dpToken.mint(msg.sender, _amount);
            } else {
                uint256 t0 = providerPool[_tokenAddress];
                // mint dTokens proportionally
                uint256 mintedDPTokens = _amount.mul(p0).div(t0);
                dpToken.mint(msg.sender, mintedDPTokens);
            }

            providerPool[_tokenAddress] = providerPool[_tokenAddress].add(
                _amount
            );
        }

        if (registeredStakers[msg.sender] == false) {
            registeredStakers[msg.sender] = true;
            stakers.push(msg.sender);
        }
    }

    /**
     *@dev sets the provider reward
     *@notice it calculates the usersStake and calculates the provider reward from it.
     * @param _periodId 1. id of the period
     * @param _rewardPercentage to calculate the provider reward
     * @param _precision used to avoid getting 0 after division in the SLA's registerSLI function
     */
    function _setRespectedPeriodReward(
        uint256 _periodId,
        uint256 _rewardPercentage,
        uint256 _precision
    ) internal {
        for (uint256 index = 0; index < allowedTokens.length; index++) {
            address tokenAddress = allowedTokens[index];
            uint256 usersStake = usersPool[tokenAddress];
            uint256 reward = usersStake.mul(_rewardPercentage).div(_precision);

            usersPool[tokenAddress] = usersPool[tokenAddress].sub(reward);

            providerPool[tokenAddress] = providerPool[tokenAddress].add(reward);

            emit ProviderRewardGenerated(
                _periodId,
                tokenAddress,
                _rewardPercentage,
                _precision,
                reward
            );
        }
    }

    /**
     *@dev sets the users compensation pool
     *@notice it calculates the usersStake and calculates the users compensation from it
     */
    function _setUsersCompensation(uint256 _periodId) internal {
        for (uint256 index = 0; index < allowedTokens.length; index++) {
            address tokenAddress = allowedTokens[index];
            uint256 usersStake = usersPool[tokenAddress];
            uint256 compensation = usersStake.mul(leverage);
            providerPool[tokenAddress] = providerPool[tokenAddress].sub(
                compensation
            );
            usersPool[tokenAddress] = usersPool[tokenAddress].add(compensation);
            emit UserCompensationGenerated(
                _periodId,
                tokenAddress,
                usersStake,
                leverage,
                compensation
            );
        }
    }

    /**
     *@dev withdraw staked tokens. Only dpToken owners can withdraw,
     *@param _amount 1. amount to be withdrawn
     *@param _tokenAddress 2. address of the token
     *@param _contractFinished 3. contract finished
     */
    function _withdrawProviderTokens(
        uint256 _amount,
        address _tokenAddress,
        bool _contractFinished
    ) internal onlyAllowedToken(_tokenAddress) {
        uint256 providerStake = providerPool[_tokenAddress];
        uint256 usersStake = usersPool[_tokenAddress];
        if (!_contractFinished) {
            require(
                providerStake.sub(_amount) >= usersStake.mul(leverage),
                "Incorrect withdraw"
            );
        }
        ERC20PresetMinterPauser dpToken = dpTokenRegistry[_tokenAddress];
        uint256 p0 = dpToken.totalSupply();
        uint256 t0 = providerPool[_tokenAddress];
        // Burn duTokens in a way that it doesn't affect the PoolTokens/LPTokens average
        // t0/p0 = (t0-_amount)/(p0-burnedDPTokens)
        // burnedDPTokens = _amount*p0/t0
        uint256 burnedDPTokens = _amount.mul(p0).div(t0);
        dpToken.burnFrom(msg.sender, burnedDPTokens);
        providerPool[_tokenAddress] = providerPool[_tokenAddress].sub(_amount);
        ERC20(_tokenAddress).safeTransfer(msg.sender, _amount);
    }

    /**
     *@dev withdraw staked tokens. Only duToken owners can withdraw,
     *@param _amount 1. amount to be withdrawn
     *@param _tokenAddress 2. address of the token
     */
    function _withdrawUserTokens(uint256 _amount, address _tokenAddress)
        internal
        onlyAllowedToken(_tokenAddress)
    {
        ERC20PresetMinterPauser duToken = duTokenRegistry[_tokenAddress];
        uint256 p0 = duToken.totalSupply();
        uint256 t0 = usersPool[_tokenAddress];
        // Burn duTokens in a way that it doesn't affect the PoolTokens/LPTokens
        // average for current period.
        // t0/p0 = (t0-_amount)/(p0-burnedDUTokens)
        // burnedDUTokens = _amount*p0/t0
        uint256 burnedDUTokens = _amount.mul(p0).div(t0);
        duToken.burnFrom(msg.sender, burnedDUTokens);
        usersPool[_tokenAddress] = usersPool[_tokenAddress].sub(_amount);
        ERC20(_tokenAddress).safeTransfer(msg.sender, _amount);
    }

    /**
     *@dev use this function to evaluate the length of the allowed tokens length
     *@return allowedTokens.length
     */
    function getAllowedTokensLength() external view returns (uint256) {
        return allowedTokens.length;
    }

    function getTokenStake(address _staker, uint256 _allowedTokenIndex)
        external
        view
        returns (address tokenAddress, uint256 stake)
    {
        address allowedTokenAddress = allowedTokens[_allowedTokenIndex];
        if (_staker == owner()) {
            return (allowedTokenAddress, providerPool[allowedTokenAddress]);
        } else {
            ERC20PresetMinterPauser dToken =
                duTokenRegistry[allowedTokenAddress];
            uint256 dTokenSupply = dToken.totalSupply();
            if (dTokenSupply == 0) {
                return (allowedTokenAddress, 0);
            }
            uint256 dTokenBalance = dToken.balanceOf(_staker);
            return (
                allowedTokenAddress,
                usersPool[allowedTokenAddress].mul(dTokenBalance).div(
                    dTokenSupply
                )
            );
        }
    }

    /**
     *@dev checks in the allowedTokens array if there's a token with _tokenAddress value
     *@param _tokenAddress 1. token address to check exixtence
     *@return true if _tokenAddress exists in the allowedTokens array
     */
    function isAllowedToken(address _tokenAddress) public view returns (bool) {
        for (uint256 index = 0; index < allowedTokens.length; index++) {
            if (allowedTokens[index] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }
}

// solhint-disable-line
pragma solidity 0.6.6;

library StringUtils {
    function addressToString(address _address)
        external
        pure
        returns (string memory)
    {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    function bytes32ToStr(bytes32 _bytes32)
        external
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function bytesToUint(bytes calldata b)
        external
        pure
        returns (uint256 result)
    {
        result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
                result = result * 10 + (uint8(b[i]) - 48);
            }
        }
        return result;
    }

    /*
        ORACLIZE_API
        Copyright (c) 2015-2016 Oraclize SRL
        Copyright (c) 2016 Oraclize LTD
        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:
        The above copyright notice and this permission notice shall be included in
        all copies or substantial portions of the Software.
        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
        THE SOFTWARE.
    */
    function uintToStr(uint256 _i)
        external
        pure
        returns (string memory _uintAsString)
    {
        uint256 number = _i;
        if (number == 0) {
            return "0";
        }
        uint256 j = number;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (number != 0) {
            bstr[k--] = bytes1(uint8(48 + (number % 10)));
            number /= 10;
        }
        return string(bstr);
    }
}

pragma solidity 0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IMessenger
 * @dev Interface to create new Messenger contract to add lo Messenger lists
 */

abstract contract IMessenger is Ownable {
    struct SLIRequest {
        address slaAddress;
        uint256 periodId;
    }

    /**
     * @dev event emitted when having a response from Chainlink with the SLI
     * @param slaAddress 1. SLA address to store the SLI
     * @param periodId 2. id of the Chainlink request
     * @param requestId 3. id of the Chainlink request
     * @param chainlinkResponse 4. response from Chainlink
     */
    event SLIReceived(
        address indexed slaAddress,
        uint256 periodId,
        bytes32 indexed requestId,
        bytes32 chainlinkResponse
    );

    /**
     * @dev sets the SLARegistry contract address and can only be called once
     */
    function setSLARegistry() external virtual;

    /**
     * @dev creates a ChainLink request to get a new SLI value for the
     * given params. Can only be called by the SLARegistry contract or Chainlink Oracle.
     * @param _periodId 1. id of the period to be queried
     * @param _slaAddress 2. address of the receiver SLA
     * @param _slaAddress 2. if approval by owner or msg.sender
     */

    function requestSLI(
        uint256 _periodId,
        address _slaAddress,
        bool _ownerApproval,
        address _callerAddress
    ) external virtual;

    /**
     * @dev callback function for the Chainlink SLI request which stores
     * the SLI in the SLA contract
     * @param _requestId the ID of the ChainLink request
     * @param _chainlinkResponseUint256 response object from Chainlink Oracles
     */
    function fulfillSLI(bytes32 _requestId, uint256 _chainlinkResponseUint256)
        external
        virtual;

    /**
     * @dev gets the messenger precision
     */
    function messengerPrecision() external view virtual returns (uint256);

    /**
     * @dev gets the slaRegistryAddress
     */
    function slaRegistryAddress() external view virtual returns (address);

    /**
     * @dev gets the chainlink oracle contract address
     */
    function oracle() external view virtual returns (address);

    /**
     * @dev gets the chainlink job id
     */
    function jobId() external view virtual returns (bytes32);

    /**
     * @dev gets the fee amount of LINK token
     */
    function fee() external view virtual returns (uint256);

    /**
     * @dev returns the requestsCounter
     */
    function requestsCounter() external view virtual returns (uint256);

    /**
     * @dev returns the fulfillsCounter
     */
    function fulfillsCounter() external view virtual returns (uint256);
}

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../../StringUtils.sol";
import "../../PeriodRegistry.sol";
import "../../StakeRegistry.sol";

/**
 * @title NetworkAnalytics
 * @dev contract to get the network analytics for the staking efficiency use case
 */

contract NetworkAnalytics is Ownable, ChainlinkClient, ReentrancyGuard {
    using SafeERC20 for ERC20;

    struct AnalyticsRequest {
        bytes32 networkName;
        uint256 periodId;
        PeriodRegistry.PeriodType periodType;
    }

    /// @dev Period registry
    PeriodRegistry private periodRegistry;
    /// @dev StakeRegistry
    StakeRegistry private stakeRegistry;

    /// @dev bytes32 to store the available network names
    bytes32[] public networkNames;
    /// @dev (networkName=>periodType=>periodId=>bytes32) to store ipfsHash of the analytics corresponding to periodId
    mapping(bytes32 => mapping(PeriodRegistry.PeriodType => mapping(uint256 => bytes32)))
        public periodAnalytics;
    /// @dev (networkName=>periodType=>periodId=>bool) to state if a network-periodType-periodId was already requested
    mapping(bytes32 => mapping(PeriodRegistry.PeriodType => mapping(uint256 => bool)))
        public periodAnalyticsRequested;

    /// @dev Mapping that stores chainlink analytics request information
    mapping(bytes32 => AnalyticsRequest) public requestIdToAnalyticsRequest;
    /// @dev Array with all request IDs
    bytes32[] public requests;
    /// @dev Chainlink oracle address
    address private oracle;
    /// @dev chainlink jobId
    bytes32 private jobId;
    /// @dev fee for Chainlink querys. Currently 0.1 LINK
    uint256 private baseFee = 0.1 ether;
    /// @dev fee for Chainlink querys. Currently 0.1 LINK
    uint256 public fee;

    /**
     * @dev event emitted when modifying the callerReward
     * @param owner 1. -
     * @param newValue 2. -
     */
    event CallerRewardModified(address indexed owner, uint256 newValue);

    /**
     * @dev event emitted when modifying the jobId
     * @param owner 1. -
     * @param jobId 2. -
     * @param fee 3. -
     */
    event JobIdModified(address indexed owner, bytes32 jobId, uint256 fee);

    /**
     * @dev event emitted when having a response from Chainlink with the SLI
     * @param networkName 1. network name
     * @param periodType 2. id of the period
     * @param periodId 3. id of the period
     * @param ipfsHash 4. hash of the ipfs object
     */
    event AnalyticsReceived(
        bytes32 networkName,
        PeriodRegistry.PeriodType periodType,
        uint256 periodId,
        bytes32 ipfsHash
    );

    /**
     * @dev parameterize the variables according to network
     * @notice sets the Chainlink parameters (oracle address, token address, jobId) and sets the SLARegistry to 0x0 address
     * @param _chainlinkOracle 1. the address of the oracle to create requests to
     * @param _chainlinkToken 2. the address of LINK token contract
     * @param _jobId 3. the job id for the HTTPGet job
     * @param _periodRegistry 4. period registry
     * @param _stakeRegistry 5. stake registry
     * @param _feeMultiplier 6. states the amount of paid nodes running behind the precoordinator, to set the fee
     */
    constructor(
        address _chainlinkOracle,
        address _chainlinkToken,
        bytes32 _jobId,
        PeriodRegistry _periodRegistry,
        StakeRegistry _stakeRegistry,
        uint256 _feeMultiplier
    ) public {
        jobId = _jobId;
        setChainlinkToken(_chainlinkToken);
        oracle = _chainlinkOracle;
        periodRegistry = _periodRegistry;
        stakeRegistry = _stakeRegistry;
        fee = _feeMultiplier.mul(baseFee);
    }

    function isValidNetwork(bytes32 _networkName) public view returns (bool) {
        for (uint256 index; index < networkNames.length; index++) {
            if (networkNames[index] == _networkName) return true;
        }
        return false;
    }

    /**
     * @dev function to add a valid network name
     * @param _networkName 1. bytes32 network name
     */
    function addNetwork(bytes32 _networkName)
        external
        onlyOwner
        returns (bool)
    {
        require(
            isValidNetwork(_networkName) == false,
            "Network name already registered"
        );
        networkNames.push(_networkName);
        return false;
    }

    /**
     * @dev function to add multiple valid network names
     * @param _networkNames 1. bytes32[] network names
     */
    function addMultipleNetworks(bytes32[] calldata _networkNames)
        external
        onlyOwner
        returns (bool)
    {
        for (uint256 index = 0; index < _networkNames.length; index++) {
            if (!isValidNetwork(_networkNames[index])) {
                networkNames.push(_networkNames[index]);
            }
        }
        return false;
    }

    /**
     * @dev Request analytics object for the current period.
     * @param _periodId 1. id of the canonical period to be analyzed
     * @param _periodType 2. type of period to be queried
     * @param _networkName 3. network name to publish analytics
     * @param _ownerApproval 4. used to choose if the call is going to be funded by the contract owner, to avoid a block by contract owner
     */
    function requestAnalytics(
        uint256 _periodId,
        PeriodRegistry.PeriodType _periodType,
        bytes32 _networkName,
        bool _ownerApproval
    ) public nonReentrant {
        require(isValidNetwork(_networkName), "Invalid network name");
        bool periodIsFinished =
            periodRegistry.periodIsFinished(_periodType, _periodId);
        require(periodIsFinished == true, "Period has not finished yet");
        require(
            periodAnalyticsRequested[_networkName][_periodType][_periodId] ==
                false,
            "Analytics already requested"
        );
        if (_ownerApproval) {
            ERC20(chainlinkTokenAddress()).safeTransferFrom(
                owner(),
                address(this),
                fee
            );
        } else {
            ERC20(chainlinkTokenAddress()).safeTransferFrom(
                msg.sender,
                address(this),
                fee
            );
        }

        Chainlink.Request memory request =
            buildChainlinkRequest(
                jobId,
                address(this),
                this.fulFillAnalytics.selector
            );

        (uint256 start, uint256 end) =
            periodRegistry.getPeriodStartAndEnd(_periodType, _periodId);

        request.add("job_type", "staking_efficiency_analytics");
        request.add("network_name", StringUtils.bytes32ToStr(_networkName));
        request.add("period_id", StringUtils.uintToStr(_periodId));
        request.add(
            "period_type",
            StringUtils.uintToStr(uint256(uint8(_periodType)))
        );
        request.add("sla_monitoring_start", StringUtils.uintToStr(start));
        request.add("sla_monitoring_end", StringUtils.uintToStr(end));

        bytes32 requestId = sendChainlinkRequestTo(oracle, request, fee);
        requests.push(requestId);
        requestIdToAnalyticsRequest[requestId] = AnalyticsRequest({
            networkName: _networkName,
            periodId: _periodId,
            periodType: _periodType
        });
        periodAnalyticsRequested[_networkName][_periodType][_periodId] = true;
    }

    /**
     * @dev callback function for the Chainlink SLI request which stores
     * the SLI in the SLA contract
     * @param _requestId the ID of the ChainLink request
     * @param _chainlinkResponse response object from Chainlink Oracles
     */
    function fulFillAnalytics(bytes32 _requestId, bytes32 _chainlinkResponse)
        external
        recordChainlinkFulfillment(_requestId)
        nonReentrant
    {
        AnalyticsRequest memory request =
            requestIdToAnalyticsRequest[_requestId];

        emit AnalyticsReceived(
            request.networkName,
            request.periodType,
            request.periodId,
            _chainlinkResponse
        );

        periodAnalytics[request.networkName][request.periodType][
            request.periodId
        ] = _chainlinkResponse;
    }

    /**
     * @dev sets a new jobId, which is a agreement Id of a PreCoordinator contract
     * @param _jobId the id of the PreCoordinator agreement
     * @param _feeMultiplier how many Chainlink nodes would be paid on the agreement id, to set the fee value
     */
    function setChainlinkJobID(bytes32 _jobId, uint256 _feeMultiplier)
        external
        onlyOwner
    {
        jobId = _jobId;
        fee = _feeMultiplier.mul(baseFee);
        emit JobIdModified(msg.sender, _jobId, fee);
    }

    function getNetworkNames()
        external
        view
        returns (bytes32[] memory networks)
    {
        networks = networkNames;
    }
}

pragma solidity 0.6.6;

pragma experimental ABIEncoderV2;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "../../SLA.sol";
import "../../PeriodRegistry.sol";
import "../../StringUtils.sol";
import "./NetworkAnalytics.sol";
import "../../messenger/IMessenger.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @title SEMessenger
 * @dev Staking efficiency Messenger
 */

contract SEMessenger is ChainlinkClient, IMessenger, ReentrancyGuard {
    using SafeERC20 for ERC20;

    /// @dev Mapping that stores chainlink sli request information
    mapping(bytes32 => SLIRequest) public requestIdToSLIRequest;
    /// @dev Array with all request IDs
    bytes32[] public requests;
    /// @dev The address of the SLARegistry contract
    address private _slaRegistryAddress;
    /// @dev Network analytics contract address
    address public immutable networkAnalyticsAddress;
    /// @dev Chainlink oracle address
    address private immutable _oracle;
    /// @dev chainlink jobId
    bytes32 private _jobId;
    // @dev fee for Chainlink querys. Currently 0.1 LINK
    uint256 private constant _baseFee = 0.1 ether;
    /// @dev fee for Chainlink querys. Currently 0.1 LINK
    uint256 private _fee;
    /// @dev to multiply the SLI value and get better precision. Useful to deploy SLO correctly
    uint256 private constant _messengerPrecision = 10**3;

    uint256 private _requestsCounter;
    uint256 private _fulfillsCounter;

    /**
     * @dev parameterize the variables according to network
     * @notice sets the Chainlink parameters (oracle address, token address, jobId) and sets the SLARegistry to 0x0 address
     * @param _messengerChainlinkOracle 1. the address of the oracle to create requests to
     * @param _messengerChainlinkToken 2. the address of LINK token contract
     * @param _messengerJobId 3. the job id for Staking efficiency job
     * @param _networkAnalyticsAddress 4. Network analytics contract address
     * @param _feeMultiplier 6. states the amount of paid nodes running behind the precoordinator, to set the fee
     */
    constructor(
        address _messengerChainlinkOracle,
        address _messengerChainlinkToken,
        bytes32 _messengerJobId,
        address _networkAnalyticsAddress,
        uint256 _feeMultiplier
    ) public {
        _jobId = _messengerJobId;
        setChainlinkToken(_messengerChainlinkToken);
        _oracle = _messengerChainlinkOracle;
        networkAnalyticsAddress = _networkAnalyticsAddress;
        _fee = _feeMultiplier * _baseFee;
    }

    /**
     * @dev event emitted when modifying the jobId
     * @param owner 1. -
     * @param jobId 2. -
     * @param fee 3. -
     */
    event JobIdModified(address indexed owner, bytes32 jobId, uint256 fee);

    /**
     * @dev event emitted when modifying the jobId
     * @param caller 1. -
     * @param requestsCounter 2. -
     * @param requestId 3. -
     */
    event SLIRequested(
        address indexed caller,
        uint256 requestsCounter,
        bytes32 requestId
    );

    /// @dev Throws if called by any address other than the SLARegistry contract or Chainlink Oracle.
    modifier onlySLARegistry() {
        require(
            msg.sender == _slaRegistryAddress,
            "Can only be called by SLARegistry"
        );
        _;
    }

    /**
     * @dev sets the SLARegistry contract address and can only be called
     * once
     */
    function setSLARegistry() public override {
        // Only able to trigger this function once
        require(
            _slaRegistryAddress == address(0),
            "SLARegistry address has already been set"
        );

        _slaRegistryAddress = msg.sender;
    }

    /**
     * @dev creates a ChainLink request to get a new SLI value for the
     * given params. Can only be called by the SLARegistry contract or Chainlink Oracle.
     * @param _periodId 1. value of the period id
     * @param _slaAddress 2. SLA Address
     * @param _messengerOwnerApproval 3. if approval by owner or msg sender
     */
    function requestSLI(
        uint256 _periodId,
        address _slaAddress,
        bool _messengerOwnerApproval,
        address _callerAddress
    ) public override onlySLARegistry nonReentrant {
        SLA sla = SLA(_slaAddress);
        PeriodRegistry.PeriodType periodType = sla.periodType();
        // extraData[0] is the networkName for StakingEfficiency use case
        bytes32 networkName = sla.extraData(0);
        bytes32 ipfsAnalytics =
            NetworkAnalytics(networkAnalyticsAddress).periodAnalytics(
                networkName,
                periodType,
                _periodId
            );
        require(
            ipfsAnalytics != 0,
            "Network analytics object is not assigned yet"
        );
        if (_messengerOwnerApproval) {
            ERC20(chainlinkTokenAddress()).safeTransferFrom(
                owner(),
                address(this),
                _fee
            );
        } else {
            ERC20(chainlinkTokenAddress()).safeTransferFrom(
                _callerAddress,
                address(this),
                _fee
            );
        }
        Chainlink.Request memory request =
            buildChainlinkRequest(
                _jobId,
                address(this),
                this.fulfillSLI.selector
            );
        request.add("job_type", "staking_efficiency");
        request.add("period_id", StringUtils.uintToStr(_periodId));
        request.add("sla_address", StringUtils.addressToString(_slaAddress));
        request.add(
            "network_analytics_address",
            StringUtils.addressToString(networkAnalyticsAddress)
        );

        // Sends the request with 0.1 LINK to the oracle contract
        bytes32 requestId = sendChainlinkRequestTo(_oracle, request, _fee);

        requests.push(requestId);

        requestIdToSLIRequest[requestId] = SLIRequest({
            slaAddress: _slaAddress,
            periodId: _periodId
        });

        _requestsCounter += 1;
        emit SLIRequested(_callerAddress, _requestsCounter, requestId);
    }

    /**
     * @dev callback function for the Chainlink SLI request which stores
     * the SLI in the SLA contract
     * @param _requestId the ID of the ChainLink request
     * @param _chainlinkResponseUint256 response object from Chainlink Oracles
     */
    function fulfillSLI(bytes32 _requestId, uint256 _chainlinkResponseUint256)
        external
        override
        nonReentrant
        recordChainlinkFulfillment(_requestId)
    {
        bytes32 _chainlinkResponse = bytes32(_chainlinkResponseUint256);
        SLIRequest memory request = requestIdToSLIRequest[_requestId];
        emit SLIReceived(
            request.slaAddress,
            request.periodId,
            _requestId,
            _chainlinkResponse
        );
        (uint256 hits, uint256 misses) = parseSLIData(_chainlinkResponse);
        uint256 total = hits.add(misses);
        uint256 stakingEfficiency =
            hits.mul(100 * _messengerPrecision).div(total);
        SLA(request.slaAddress).registerSLI(
            stakingEfficiency,
            request.periodId
        );

        _fulfillsCounter += 1;
    }

    /**
     * @dev recieves a string of "hits,misses" data and returns hits and misses as uint256
     * @param sliData the ID of the ChainLink request
     */
    function parseSLIData(bytes32 sliData)
        public
        pure
        returns (uint256, uint256)
    {
        bytes memory bytesSLIData = bytes(StringUtils.bytes32ToStr(sliData));
        uint256 sliDataLength = bytesSLIData.length;
        bytes memory bytesHits = new bytes(sliDataLength);
        bytes memory bytesMisses = new bytes(sliDataLength);
        for (uint256 index; index < sliDataLength; index++) {
            if (bytesSLIData[index] == bytes1(",")) {
                for (uint256 index2 = 0; index2 < index; index2++) {
                    bytesHits[index2] = bytesSLIData[index2];
                }
                for (
                    uint256 index3 = 0;
                    index3 < sliDataLength - index - 1;
                    index3++
                ) {
                    bytesMisses[index3] = bytesSLIData[index + 1 + index3];
                }
            }
        }
        uint256 hits = StringUtils.bytesToUint(bytesHits);
        uint256 misses = StringUtils.bytesToUint(bytesMisses);
        return (hits, misses);
    }

    /**
     * @dev sets a new jobId, which is a agreement Id of a PreCoordinator contract
     * @param _newJobId the id of the PreCoordinator agreement
     * @param _feeMultiplier how many Chainlink nodes would be paid on the agreement id, to set the fee value
     */
    function setChainlinkJobID(bytes32 _newJobId, uint256 _feeMultiplier)
        external
        onlyOwner
    {
        _jobId = _newJobId;
        _fee = _feeMultiplier * _baseFee;
        emit JobIdModified(msg.sender, _newJobId, _fee);
    }

    /**
     * @dev returns the value of the sla registry address
     */
    function slaRegistryAddress() external view override returns (address) {
        return _slaRegistryAddress;
    }

    /**
     * @dev returns the value of the messenger precision
     */
    function messengerPrecision() external view override returns (uint256) {
        return _messengerPrecision;
    }

    /**
     * @dev returns the chainlink oracle contract address
     */
    function oracle() external view override returns (address) {
        return _oracle;
    }

    /**
     * @dev returns the chainlink job id
     */
    function jobId() external view override returns (bytes32) {
        return _jobId;
    }

    /**
     * @dev returns the chainlink fee value on LINK tokens
     */
    function fee() external view override returns (uint256) {
        return _fee;
    }

    /**
     * @dev returns the requestsCounter
     */
    function requestsCounter() external view override returns (uint256) {
        return _requestsCounter;
    }

    /**
     * @dev returns the fulfillsCounter
     */
    function fulfillsCounter() external view override returns (uint256) {
        return _fulfillsCounter;
    }
}

pragma solidity ^0.6.0;

import { CBORChainlink } from "./vendor/CBORChainlink.sol";
import { BufferChainlink } from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param _id The Job Specification ID
   * @param _callbackAddress The callback address
   * @param _callbackFunction The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 _id,
    address _callbackAddress,
    bytes4 _callbackFunction
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = _id;
    self.callbackAddress = _callbackAddress;
    self.callbackFunctionId = _callbackFunction;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param _data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory _data)
    internal pure
  {
    BufferChainlink.init(self.buf, _data.length);
    BufferChainlink.append(self.buf, _data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The string value to add
   */
  function add(Request memory self, string memory _key, string memory _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeString(_value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The bytes value to add
   */
  function addBytes(Request memory self, string memory _key, bytes memory _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeBytes(_value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The int256 value to add
   */
  function addInt(Request memory self, string memory _key, int256 _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeInt(_value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The uint256 value to add
   */
  function addUint(Request memory self, string memory _key, uint256 _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeUInt(_value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _values The array of string values to add
   */
  function addStringArray(Request memory self, string memory _key, string[] memory _values)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.startArray();
    for (uint256 i = 0; i < _values.length; i++) {
      self.buf.encodeString(_values[i]);
    }
    self.buf.endSequence();
  }
}

pragma solidity ^0.6.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";
import "./interfaces/PointerInterface.sol";
import { ENSResolver as ENSResolver_Chainlink } from "./vendor/ENSResolver.sol";
import "./vendor/SafeMathChainlink.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
contract ChainlinkClient {
  using Chainlink for Chainlink.Request;
  using SafeMathChainlink for uint256;

  uint256 constant internal LINK = 10**18;
  uint256 constant private AMOUNT_OVERRIDE = 0;
  address constant private SENDER_OVERRIDE = address(0);
  uint256 constant private ARGS_VERSION = 1;
  bytes32 constant private ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 constant private ENS_ORACLE_SUBNAME = keccak256("oracle");
  address constant private LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private ens;
  bytes32 private ensNode;
  LinkTokenInterface private link;
  ChainlinkRequestInterface private oracle;
  uint256 private requestCount = 1;
  mapping(bytes32 => address) private pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param _specId The Job Specification ID that the request will be created for
   * @param _callbackAddress The callback address that the response will be sent to
   * @param _callbackFunctionSignature The callback function signature to use for the callback address
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 _specId,
    address _callbackAddress,
    bytes4 _callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(_specId, _callbackAddress, _callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param _req The initialized Chainlink Request
   * @param _payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory _req, uint256 _payment)
    internal
    returns (bytes32)
  {
    return sendChainlinkRequestTo(address(oracle), _req, _payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param _oracle The address of the oracle for the request
   * @param _req The initialized Chainlink Request
   * @param _payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(address _oracle, Chainlink.Request memory _req, uint256 _payment)
    internal
    returns (bytes32 requestId)
  {
    requestId = keccak256(abi.encodePacked(this, requestCount));
    _req.nonce = requestCount;
    pendingRequests[requestId] = _oracle;
    emit ChainlinkRequested(requestId);
    require(link.transferAndCall(_oracle, _payment, encodeRequest(_req)), "unable to transferAndCall to oracle");
    requestCount += 1;

    return requestId;
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param _requestId The request ID
   * @param _payment The amount of LINK sent for the request
   * @param _callbackFunc The callback function specified for the request
   * @param _expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunc,
    uint256 _expiration
  )
    internal
  {
    ChainlinkRequestInterface requested = ChainlinkRequestInterface(pendingRequests[_requestId]);
    delete pendingRequests[_requestId];
    emit ChainlinkCancelled(_requestId);
    requested.cancelOracleRequest(_requestId, _payment, _callbackFunc, _expiration);
  }

  /**
   * @notice Sets the stored oracle address
   * @param _oracle The address of the oracle contract
   */
  function setChainlinkOracle(address _oracle) internal {
    oracle = ChainlinkRequestInterface(_oracle);
  }

  /**
   * @notice Sets the LINK token address
   * @param _link The address of the LINK token contract
   */
  function setChainlinkToken(address _link) internal {
    link = LinkTokenInterface(_link);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress()
    internal
    view
    returns (address)
  {
    return address(link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress()
    internal
    view
    returns (address)
  {
    return address(oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param _oracle The address of the oracle contract that will fulfill the request
   * @param _requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address _oracle, bytes32 _requestId)
    internal
    notPendingRequest(_requestId)
  {
    pendingRequests[_requestId] = _oracle;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param _ens The address of the ENS contract
   * @param _node The ENS node hash
   */
  function useChainlinkWithENS(address _ens, bytes32 _node)
    internal
  {
    ens = ENSInterface(_ens);
    ensNode = _node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS()
    internal
  {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Encodes the request to be sent to the oracle contract
   * @dev The Chainlink node expects values to be in order for the request to be picked up. Order of types
   * will be validated in the oracle contract.
   * @param _req The initialized Chainlink Request
   * @return The bytes payload for the `transferAndCall` method
   */
  function encodeRequest(Chainlink.Request memory _req)
    private
    view
    returns (bytes memory)
  {
    return abi.encodeWithSelector(
      oracle.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      _req.id,
      _req.callbackAddress,
      _req.callbackFunctionId,
      _req.nonce,
      ARGS_VERSION,
      _req.buf.buf);
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param _requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 _requestId)
    internal
    recordChainlinkFulfillment(_requestId)
    // solhint-disable-next-line no-empty-blocks
  {}

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param _requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 _requestId) {
    require(msg.sender == pendingRequests[_requestId],
            "Source must be the oracle of the request");
    delete pendingRequests[_requestId];
    emit ChainlinkFulfilled(_requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param _requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 _requestId) {
    require(pendingRequests[_requestId] == address(0), "Request is already pending");
    _;
  }
}

pragma solidity ^0.6.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion, // Currently unused, always "1"
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

pragma solidity ^0.6.0;

interface ENSInterface {

  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);


  function setSubnodeOwner(bytes32 node, bytes32 label, address _owner) external;
  function setResolver(bytes32 node, address _resolver) external;
  function setOwner(bytes32 node, address _owner) external;
  function setTTL(bytes32 node, uint64 _ttl) external;
  function owner(bytes32 node) external view returns (address);
  function resolver(bytes32 node) external view returns (address);
  function ttl(bytes32 node) external view returns (uint64);

}

pragma solidity ^0.6.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

pragma solidity ^0.6.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

pragma solidity ^0.6.0;

/**
* @dev A library for working with mutable byte buffers in Solidity.
*
* Byte buffers are mutable and expandable, and provide a variety of primitives
* for writing to them. At any time you can fetch a bytes object containing the
* current contents of the buffer. The bytes object should not be stored between
* operations, as it may change due to resizing of the buffer.
*/
library BufferChainlink {
  /**
  * @dev Represents a mutable buffer. Buffers have a current value (buf) and
  *      a capacity. The capacity may be longer than the current value, in
  *      which case it can be extended without the need to allocate more memory.
  */
  struct buffer {
    bytes buf;
    uint capacity;
  }

  /**
  * @dev Initializes a buffer with an initial capacity.
  * @param buf The buffer to initialize.
  * @param capacity The number of bytes of space to allocate the buffer.
  * @return The buffer, for chaining.
  */
  function init(buffer memory buf, uint capacity) internal pure returns(buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
  * @dev Initializes a new buffer from an existing bytes object.
  *      Changes to the buffer may mutate the original value.
  * @param b The bytes object to initialize the buffer with.
  * @return A new buffer.
  */
  function fromBytes(bytes memory b) internal pure returns(buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint a, uint b) private pure returns(uint) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
  * @dev Sets buffer length to 0.
  * @param buf The buffer to truncate.
  * @return The original buffer, for chaining..
  */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
  * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The start offset to write to.
  * @param data The data to append.
  * @param len The number of bytes to copy.
  * @return The original buffer, for chaining.
  */
  function write(buffer memory buf, uint off, bytes memory data, uint len) internal pure returns(buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint dest;
    uint src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    uint mask = 256 ** (32 - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }

    return buf;
  }

  /**
  * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @param len The number of bytes to copy.
  * @return The original buffer, for chaining.
  */
  function append(buffer memory buf, bytes memory data, uint len) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
  * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
  * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write the byte at.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function writeUint8(buffer memory buf, uint off, uint8 data) internal pure returns(buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
  * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns(buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
  * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
  *      exceed the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @param len The number of bytes to write (left-aligned).
  * @return The original buffer, for chaining.
  */
  function write(buffer memory buf, uint off, bytes32 data, uint len) private pure returns(buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint mask = 256 ** len - 1;
    // Right-align data
    data = data >> (8 * (32 - len));
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + sizeof(buffer length) + off + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
  * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function writeBytes20(buffer memory buf, uint off, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
  * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chhaining.
  */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
  * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
  * @dev Writes an integer to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @param len The number of bytes to write (right-aligned).
  * @return The original buffer, for chaining.
  */
  function writeInt(buffer memory buf, uint off, uint data, uint len) private pure returns(buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint mask = 256 ** len - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
    * @dev Appends a byte to the end of the buffer. Resizes if doing so would
    * exceed the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer.
    */
  function appendInt(buffer memory buf, uint data, uint len) internal pure returns(buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

pragma solidity ^0.6.0;

import { BufferChainlink } from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  function encodeType(BufferChainlink.buffer memory buf, uint8 major, uint value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if(value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if(value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if(value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else if(value <= 0xFFFFFFFFFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    encodeType(buf, MAJOR_TYPE_INT, value);
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value >= 0) {
      encodeType(buf, MAJOR_TYPE_INT, uint(value));
    } else {
      encodeType(buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - value));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeType(buf, MAJOR_TYPE_BYTES, value.length);
    buf.append(value);
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeType(buf, MAJOR_TYPE_STRING, bytes(value).length);
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

pragma solidity ^0.6.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

pragma solidity ^0.6.0;

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
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
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
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
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
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
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
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

import "../access/AccessControl.sol";
import "../GSN/Context.sol";
import "../token/ERC20/ERC20.sol";
import "../token/ERC20/ERC20Burnable.sol";
import "../token/ERC20/ERC20Pausable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC20PresetMinterPauser is Context, AccessControl, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) public ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC20.sol";
import "../../utils/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
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
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 100
  },
  "evmVersion": "istanbul",
  "libraries": {
    "/Users/matiasbn/Desktop/stacktical/stacktical-dsla-contracts/contracts/StringUtils.sol": {
      "StringUtils": "0xC7183212c2b0D4A62A542F7C4c3060Db55BE0bd2"
    }
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