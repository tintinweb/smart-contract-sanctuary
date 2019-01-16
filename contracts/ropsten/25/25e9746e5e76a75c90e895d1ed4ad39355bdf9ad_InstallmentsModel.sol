pragma solidity ^0.4.24;

// File: contracts/interfaces/ERC165.sol

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// File: contracts/diaspore/interfaces/Model.sol

/**
    The abstract contract Model defines the whole lifecycle of a debt on the DebtEngine.

    Models can be used without previous approbation, this is meant
    to avoid centralization on the development of RCN; this implies that not all models are secure.
    Models can have back-doors, bugs and they have not guarantee of being autonomous.

    The DebtEngine is meant to be the User of this model,
    so all the methods with the ability to perform state changes should only be callable by the DebtEngine.

    @author Agustin Aguilar
*/
contract Model is ERC165 {
    // ///
    // Events
    // ///

    /**
        @dev This emits when create a new debt.
    */
    event Created(bytes32 indexed _id);

    /**
        @dev This emits when the status of debt change.

        @param _timestamp Timestamp of the registry
        @param _status New status of the registry
    */
    event ChangedStatus(bytes32 indexed _id, uint256 _timestamp, uint256 _status);

    /**
        @dev This emits when the obligation of debt change.

        @param _timestamp Timestamp of the registry
        @param _debt New debt of the registry
    */
    event ChangedObligation(bytes32 indexed _id, uint256 _timestamp, uint256 _debt);

    /**
        @dev This emits when the frequency of debt change.

        @param _timestamp Timestamp of the registry
        @param _frequency New frequency of each installment
    */
    event ChangedFrequency(bytes32 indexed _id, uint256 _timestamp, uint256 _frequency);

    /**
        @param _timestamp Timestamp of the registry
    */
    event ChangedDueTime(bytes32 indexed _id, uint256 _timestamp, uint256 _status);

    /**
        @param _timestamp Timestamp of the registry
        @param _dueTime New dueTime of each installment
    */
    event ChangedFinalTime(bytes32 indexed _id, uint256 _timestamp, uint64 _dueTime);

    /**
        @dev This emits when the call addDebt function.

        @param _amount New amount of the debt, old amount plus added
    */
    event AddedDebt(bytes32 indexed _id, uint256 _amount);

    /**
        @dev This emits when the call addPaid function.

        If the registry is fully paid on the call and the amount parameter exceeds the required
            payment amount, the event emits the real amount paid on the payment.

        @param _paid Real amount paid
    */
    event AddedPaid(bytes32 indexed _id, uint256 _paid);

    // Model interface selector
    bytes4 internal debtModelInterface =
    this.isOperator.selector
    ^ this.validate.selector
    ^ this.getStatus.selector
    ^ this.getPaid.selector
    ^ this.getObligation.selector
    ^ this.getClosingObligation.selector
    ^ this.getDueTime.selector
    ^ this.getFinalTime.selector
    ^ this.getFrequency.selector
    ^ this.getEstimateObligation.selector
    ^ this.create.selector
    ^ this.addPaid.selector
    ^ this.addDebt.selector
    ^ this.run.selector;

    uint256 public constant STATUS_ONGOING = 1;
    uint256 public constant STATUS_PAID = 2;
    uint256 public constant STATUS_ERROR = 4;

    // ///
    // Meta
    // ///

    /**
        If called for any address with the ability to modify the state of the model registries,
            this method should return True.

        @dev Some contracts may check if the DebtEngine is
            an operator to know if the model is operative or not.

        @param operator Address of the target request operator

        @return True if operator is able to modify the state of the model
    */
    function isOperator(address operator) external view returns (bool canOperate);

    /**
        Validates the data for the creation of a new registry, if returns True the
            same data should be compatible with the create method.

        @dev This method can revert the call or return false, and both meant an invalid data.

        @param data Data to validate

        @return True if the data can be used to create a new registry
    */
    function validate(bytes data) external view returns (bool isValid);

    // ///
    // Getters
    // ///

    /**
        Exposes the current status of the registry. The possible values are:

        1: Ongoing - The debt is still ongoing and waiting to be paid
        2: Paid - The debt is already paid and
        5: Error - There was an Error with the registry

        @dev This method should always be called by the DebtEngine

        @param id Id of the registry

        @return The current status value
    */
    function getStatus(bytes32 id) external view returns (uint256 status);

    /**
        Returns the total paid amount on the registry.

        @dev it should equal to the sum of all real addPaid

        @param id Id of the registry

        @return Total paid amount
    */
    function getPaid(bytes32 id) external view returns (uint256 paid);

    /**
        If the returned amount does not depend on any interactions and only on the model logic,
            the defined flag will be True; if the amount is an estimation of the future debt,
            the flag will be set to False.

        If timestamp equals the current moment, the defined flag should always be True.

        @dev This can be a gas-intensive method to call, consider calling the run method before.

        @param id Id of the registry
        @param timestamp Timestamp of the obligation query

        @return amount Amount pending to pay on the given timestamp
        @return defined True If the amount returned is fixed and can&#39;t change
    */
    function getObligation(bytes32 id, uint64 timestamp) external view returns (uint256 amount, bool defined);

    /**
        The amount required to fully paid a registry.

        All registries should be payable in a single time, even when it has multiple installments.

        If the registry discounts interest for early payment, those discounts should be
            taken into account in the returned amount.

        @dev This can be a gas-intensive method to call, consider calling the run method before.

        @param id Id of the registry

        @return amount Amount required to fully paid the loan on the current timestamp
    */
    function getClosingObligation(bytes32 id) external view returns (uint256 amount);

    /**
        The timestamp of the next required payment.

        After this moment, if the payment goal is not met the debt will be considered overdue.

            The getObligation method can be used to know the required payment on the future timestamp.

        @param id Id of the registry

        @return timestamp The timestamp of the next due time
    */
    function getDueTime(bytes32 id) external view returns (uint256 timestamp);

    // ///
    // Metadata
    // ///

    /**
        If the loan has multiple installments returns the duration of each installment in seconds,
            if the loan has not installments it should return 1.

        @param id Id of the registry

        @return frequency Frequency of each installment
    */
    function getFrequency(bytes32 id) external view returns (uint256 frequency);

    /**
        The registry could be paid before or after the date, but the debt will always be
            considered overdue if paid after this timestamp.

        This is the estimated final payment date of the debt if it&#39;s always paid on each exact dueTime.

        @param id Id of the registry

        @return timestamp Timestamp of the final due time
    */
    function getFinalTime(bytes32 id) external view returns (uint256 timestamp);

    /**
        Similar to getFinalTime returns the expected payment remaining if paid always on the exact dueTime.

        If the model has no interest discounts for early payments,
            this method should return the same value as getClosignObligation.

        @param id Id of the registry

        @return amount Expected payment amount
    */
    function getEstimateObligation(bytes32 id) external view returns (uint256 amount);

    // ///
    // State interface
    // ///

    /**
        Creates a new registry using the provided data and id, it should fail if the id already exists
            or if calling validate(data) returns false or throws.

        @dev This method should only be callable by an operator

        @param id Id of the registry to create
        @param data Data to construct the new registry

        @return success True if the registry was created
    */
    function create(bytes32 id, bytes data) external returns (bool success);

    /**
        If the registry is fully paid on the call and the amount parameter exceeds the required
            payment amount, the method returns the real amount used on the payment.

        The payment taken should always be the same as the requested unless the registry
            is fully paid on the process.

        @dev This method should only be callable by an operator

        @param id If of the registry
        @param amount Amount to pay

        @return real Real amount paid
    */
    function addPaid(bytes32 id, uint256 amount) external returns (uint256 real);

    /**
        Adds a new amount to be paid on the debt model,
            each model can handle the addition of more debt freely.

        @dev This method should only be callable by an operator

        @param id Id of the registry
        @param amount Debt amount to add to the registry

        @return added True if the debt was added
    */
    function addDebt(bytes32 id, uint256 amount) external returns (bool added);

    // ///
    // Utils
    // ///

    /**
        Runs the internal clock of a registry, this is used to compute the last changes on the state.
            It can make transactions cheaper by avoiding multiple calculations when calling views.

        Not all models have internal clocks, a model without an internal clock should always return false.

        Calls to this method should be possible from any address,
            multiple calls to run shouldn&#39;t affect the internal calculations of the model.

        @dev If the call had no effect the method would return False,
            that is no sign of things going wrong, and the call shouldn&#39;t be wrapped on a require

        @param id If of the registry

        @return effect True if the run performed a change on the state
    */
    function run(bytes32 id) external returns (bool effect);
}

// File: contracts/utils/Ownable.sol

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Ownable() public {
        owner = msg.sender; 
    }

    /**
        @dev Transfers the ownership of the contract.

        @param _to Address of the new owner
    */
    function transferTo(address _to) public onlyOwner returns (bool) {
        require(_to != address(0));
        owner = _to;
        return true;
    } 
}

// File: contracts/utils/BytesUtils.sol

contract BytesUtils {
    function readBytes32(bytes data, uint256 index) internal pure returns (bytes32 o) {
        require(data.length / 32 > index, "Reading bytes out of bounds");
        assembly {
            o := mload(add(data, add(32, mul(32, index))))
        }
    }
    function read(bytes data, uint256 offset, uint256 length) internal pure returns (bytes32 o) {
        require(data.length >= offset + length, "Reading bytes out of bounds");
        assembly {
            o := mload(add(data, add(32, offset)))
            let lb := sub(32, length)
            if lb { o := div(o, exp(2, mul(lb, 8))) }
        }
    }

    function decode(
        bytes _data,
        uint256 _la
    ) internal pure returns (bytes32 _a) {
        require(_data.length >= _la, "Reading bytes out of bounds");
        assembly {
            _a := mload(add(_data, 32))
            let l := sub(32, _la)
            if l { _a := div(_a, exp(2, mul(l, 8))) }
        }
    }

    function decode(
        bytes _data,
        uint256 _la,
        uint256 _lb
    ) internal pure returns (bytes32 _a, bytes32 _b) {
        uint256 o;
        assembly {
            let s := add(_data, 32)
            _a := mload(s)
            let l := sub(32, _la)
            if l { _a := div(_a, exp(2, mul(l, 8))) }
            o := add(s, _la)
            _b := mload(o)
            l := sub(32, _lb)
            if l { _b := div(_b, exp(2, mul(l, 8))) }
            o := sub(o, s)
        }
        require(_data.length >= o, "Reading bytes out of bounds");
    }

    function decode(
        bytes _data,
        uint256 _la,
        uint256 _lb,
        uint256 _lc
    ) internal pure returns (bytes32 _a, bytes32 _b, bytes32 _c) {
        uint256 o;
        assembly {
            let s := add(_data, 32)
            _a := mload(s)
            let l := sub(32, _la)
            if l { _a := div(_a, exp(2, mul(l, 8))) }
            o := add(s, _la)
            _b := mload(o)
            l := sub(32, _lb)
            if l { _b := div(_b, exp(2, mul(l, 8))) }
            o := add(o, _lb)
            _c := mload(o)
            l := sub(32, _lc)
            if l { _c := div(_c, exp(2, mul(l, 8))) }
            o := sub(o, s)
        }
        require(_data.length >= o, "Reading bytes out of bounds");
    }

    function decode(
        bytes _data,
        uint256 _la,
        uint256 _lb,
        uint256 _lc,
        uint256 _ld
    ) internal pure returns (bytes32 _a, bytes32 _b, bytes32 _c, bytes32 _d) {
        uint256 o;
        assembly {
            let s := add(_data, 32)
            _a := mload(s)
            let l := sub(32, _la)
            if l { _a := div(_a, exp(2, mul(l, 8))) }
            o := add(s, _la)
            _b := mload(o)
            l := sub(32, _lb)
            if l { _b := div(_b, exp(2, mul(l, 8))) }
            o := add(o, _lb)
            _c := mload(o)
            l := sub(32, _lc)
            if l { _c := div(_c, exp(2, mul(l, 8))) }
            o := add(o, _lc)
            _d := mload(o)
            l := sub(32, _ld)
            if l { _d := div(_d, exp(2, mul(l, 8))) }
            o := sub(o, s)
        }
        require(_data.length >= o, "Reading bytes out of bounds");
    }

    function decode(
        bytes _data,
        uint256 _la,
        uint256 _lb,
        uint256 _lc,
        uint256 _ld,
        uint256 _le
    ) internal pure returns (bytes32 _a, bytes32 _b, bytes32 _c, bytes32 _d, bytes32 _e) {
        uint256 o;
        assembly {
            let s := add(_data, 32)
            _a := mload(s)
            let l := sub(32, _la)
            if l { _a := div(_a, exp(2, mul(l, 8))) }
            o := add(s, _la)
            _b := mload(o)
            l := sub(32, _lb)
            if l { _b := div(_b, exp(2, mul(l, 8))) }
            o := add(o, _lb)
            _c := mload(o)
            l := sub(32, _lc)
            if l { _c := div(_c, exp(2, mul(l, 8))) }
            o := add(o, _lc)
            _d := mload(o)
            l := sub(32, _ld)
            if l { _d := div(_d, exp(2, mul(l, 8))) }
            o := add(o, _ld)
            _e := mload(o)
            l := sub(32, _le)
            if l { _e := div(_e, exp(2, mul(l, 8))) }
            o := sub(o, s)
        }
        require(_data.length >= o, "Reading bytes out of bounds");
    }
}

// File: contracts/diaspore/model/InstallmentsModel.sol

contract InstallmentsModel is BytesUtils, Ownable, Model {
    mapping(bytes4 => bool) private _supportedInterface;

    constructor() public {
        _supportedInterface[this.owner.selector] = true;
        _supportedInterface[this.validate.selector] = true;
        _supportedInterface[this.getStatus.selector] = true;
        _supportedInterface[this.getPaid.selector] = true;
        _supportedInterface[this.getObligation.selector] = true;
        _supportedInterface[this.getClosingObligation.selector] = true;
        _supportedInterface[this.getDueTime.selector] = true;
        _supportedInterface[this.getFinalTime.selector] = true;
        _supportedInterface[this.getFrequency.selector] = true;
        _supportedInterface[this.getEstimateObligation.selector] = true;
        _supportedInterface[this.addDebt.selector] = true; // ??? Not supported
        _supportedInterface[this.run.selector] = true;
        _supportedInterface[this.fixClock.selector] = true;
        _supportedInterface[this.create.selector] = true;
        _supportedInterface[this.addPaid.selector] = true;
        _supportedInterface[this.configs.selector] = true;
        _supportedInterface[this.states.selector] = true;
        _supportedInterface[this.engine.selector] = true;
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return 
            interfaceId == this.supportsInterface.selector ||
            interfaceId == debtModelInterface ||
            _supportedInterface[interfaceId];
    }

    address public engine;

    mapping(bytes32 => Config) public configs;
    mapping(bytes32 => State) public states;

    uint256 public constant L_DATA = 16 + 32 + 3 + 5 + 4;

    uint256 private constant U_128_OVERFLOW = 2 ** 128;
    uint256 private constant U_64_OVERFLOW = 2 ** 64;
    uint256 private constant U_40_OVERFLOW = 2 ** 40;
    uint256 private constant U_24_OVERFLOW = 2 ** 24;

    event _setClock(bytes32 _id, uint64 _to);
    event _setStatus(bytes32 _id, uint8 _status);
    event _setPaidBase(bytes32 _id, uint128 _paidBase);
    event _setInterest(bytes32 _id, uint128 _interest);

    struct Config {
        uint24 installments;
        uint32 timeUnit;
        uint40 duration;
        uint64 lentTime;
        uint128 cuota;
        uint256 interestRate;
        bytes32 id;
    }

    struct State {
        uint8 status;
        uint64 clock;
        uint64 lastPayment;
        uint128 paid;
        uint128 paidBase;
        uint128 interest;
    }

    modifier onlyEngine {
        require(msg.sender == engine, "Only engine allowed");
        _;
    }

    function setEngine(address _engine) external onlyOwner returns (bool) {
        engine = _engine;
        return true;
    }

    function encodeData(
        uint128 _cuota,
        uint256 _interestRate,
        uint24 _installments,
        uint40 _duration,
        uint32 _timeUnit
    ) external pure returns (bytes) {
        return abi.encodePacked(_cuota, _interestRate, _installments, _duration, _timeUnit);
    }

    function create(bytes32 id, bytes data) external onlyEngine returns (bool) {
        require(configs[id].cuota == 0, "Entry already exist");
        
        (uint128 cuota, uint256 interestRate, uint24 installments, uint40 duration, uint32 timeUnit) = _decodeData(data);
        _validate(cuota, interestRate, installments, duration, timeUnit);

        configs[id] = Config({
            installments: installments,
            duration: duration,
            lentTime: uint64(now),
            cuota: cuota,
            interestRate: interestRate,
            timeUnit: timeUnit,
            id: id
        });

        states[id].clock = duration;

        emit Created(id);
        emit _setClock(id, duration);

        return true;
    }

    function addPaid(bytes32 id, uint256 amount) external onlyEngine returns (uint256 real) {
        Config storage config = configs[id];
        State storage state = states[id];

        _advanceClock(id, uint64(now) - config.lentTime);

        if (state.status != STATUS_PAID) {
            // State & config memory load
            uint256 paid = state.paid;
            uint256 duration = config.duration;
            uint256 interest = state.interest;

            // Payment aux
            require(available < U_128_OVERFLOW, "Amount overflow");
            uint256 available = amount;

            // Aux variables
            uint256 unpaidInterest;
            uint256 pending;
            uint256 target;
            uint256 baseDebt;
            uint256 clock;

            do {
                clock = state.clock;

                baseDebt = _baseDebt(clock, duration, config.installments, config.cuota);
                pending = baseDebt + interest - paid;

                // min(pending, available)
                target = pending < available ? pending : available;

                // Calc paid base
                unpaidInterest = interest - (paid - state.paidBase);

                // max(target - unpaidInterest, 0)
                state.paidBase += uint128(target > unpaidInterest ? target - unpaidInterest : 0);
                emit _setPaidBase(id, state.paidBase);

                paid += target;
                available -= target;

                // Check fully paid
                // All installments paid + interest
                if (clock / duration >= config.installments && baseDebt + interest <= paid) {
                    // Registry paid!
                    state.status = uint8(STATUS_PAID);
                    emit _setStatus(id, uint8(STATUS_PAID));
                    break;
                }

                // If installment fully paid, advance to next one
                if (pending == target) {
                    _advanceClock(id, clock + duration - (clock % duration));
                }
            } while (available != 0);

            require(paid < U_128_OVERFLOW, "Paid overflow");
            state.paid = uint128(paid);
            state.lastPayment = state.clock;

            real = amount - available;
            emit AddedPaid(id, real);
        }
    }

    function addDebt(bytes32 id, uint256 amount) external onlyEngine returns (bool) {
        revert("Not implemented!");
    }

    function fixClock(bytes32 id, uint64 target) external returns (bool) {
        if (target <= now) {
            Config storage config = configs[id];
            State storage state = states[id];
            uint64 lentTime = config.lentTime;
            require(lentTime >= target, "Clock can&#39;t go negative");
            uint64 targetClock = config.lentTime - target;
            require(targetClock > state.clock, "Clock is ahead of target");
            return _advanceClock(id, targetClock);
        }
    }

    function isOperator(address _target) external view returns (bool) {
        return engine == _target;
    }

    function getStatus(bytes32 id) external view returns (uint256) {
        Config storage config = configs[id];
        State storage state = states[id];
        require(config.lentTime != 0, "The registry does not exist");
        return state.status == STATUS_PAID ? STATUS_PAID : STATUS_ONGOING;
    }

    function getPaid(bytes32 id) external view returns (uint256) {
        return states[id].paid;
    }

    function getObligation(bytes32 id, uint64 timestamp) external view returns (uint256, bool) {
        State storage state = states[id];
        Config storage config = configs[id];

        // Can&#39;t be before creation
        if (timestamp < config.lentTime) {
            return (0, true);
        } 

        // Static storage loads        
        uint256 currentClock = timestamp - config.lentTime;

        uint256 base = _baseDebt(
            currentClock,
            config.duration,
            config.installments,
            config.cuota
        );

        uint256 interest;
        uint256 prevInterest = state.interest;
        uint256 clock = state.clock;
        bool defined;

        if (clock >= currentClock) {
            interest = prevInterest;
            defined = true;
        } else {
            // We need to calculate the new interest, on a view!
            (interest, currentClock) = _simRunClock(
                clock,
                currentClock,
                prevInterest,
                config,
                state
            );

            defined = prevInterest == interest;
        }
        
        uint256 debt = base + interest;
        uint256 paid = state.paid;
        return (debt > paid ? debt - paid : 0, defined);
    }

    function _simRunClock(
        uint256 _clock,
        uint256 _targetClock,
        uint256 _prevInterest,
        Config _config,
        State _state
    ) internal pure returns (uint256 interest, uint256 clock) {
        (interest, clock) = _runAdvanceClock({
            _clock: _clock,
            _timeUnit: _config.timeUnit,
            _interest: _prevInterest,
            _duration: _config.duration,
            _cuota: _config.cuota,
            _installments: _config.installments,
            _paidBase: _state.paidBase,
            _interestRate: _config.interestRate,
            _targetClock: _targetClock
        });
    }

    function run(bytes32 id) external returns (bool) {
        Config storage config = configs[id];
        return _advanceClock(id, uint64(now) - config.lentTime);
    }

    function validate(bytes data) external view returns (bool) {
        (uint128 cuota, uint256 interestRate, uint24 installments, uint40 duration, uint32 timeUnit) = _decodeData(data);
        _validate(cuota, interestRate, installments, duration, timeUnit);
        return true;
    }

    function getClosingObligation(bytes32 id) external view returns (uint256) {
        return _getClosingObligation(id);
    }

    function getDueTime(bytes32 id) external view returns (uint256) {
        Config storage config = configs[id];
        uint256 last = states[id].lastPayment;
        uint256 duration = config.duration;
        last = last != 0 ? last : duration;
        return last - (last % duration) + config.lentTime;
    }

    function getFinalTime(bytes32 id) external view returns (uint256) {
        Config storage config = configs[id];
        return config.lentTime + (uint256(config.duration) * (uint256(config.installments)));
    }

    function getFrequency(bytes32 id) external view returns (uint256) {
        return configs[id].duration;
    }

    function getEstimateObligation(bytes32 id) external view returns (uint256) {
        return _getClosingObligation(id);
    }

    function _advanceClock(bytes32 id, uint256 _target) internal returns (bool) {
        Config storage config = configs[id];
        State storage state = states[id];

        uint256 clock = state.clock;
        if (clock < _target) {
            (uint256 newInterest, uint256 newClock) = _runAdvanceClock({
                _clock: state.clock,
                _timeUnit: config.timeUnit,
                _interest: state.interest,
                _duration: config.duration,
                _cuota: config.cuota,
                _installments: config.installments,
                _paidBase: state.paidBase,
                _interestRate: config.interestRate,
                _targetClock: _target
            });

            require(newClock < U_64_OVERFLOW, "Clock overflow");
            require(newInterest < U_128_OVERFLOW, "Interest overflow");

            emit _setClock(id, uint64(newClock));

            if (newInterest != 0) {
                emit _setInterest(id, uint128(newInterest));
            }

            state.clock = uint64(newClock);
            state.interest = uint128(newInterest);

            return true;
        }
    }

    function _getClosingObligation(bytes32 id) internal view returns (uint256) {
        State storage state = states[id];
        Config storage config = configs[id];

        // Static storage loads
        uint256 installments = config.installments;
        uint256 cuota = config.cuota;
        uint256 currentClock = uint64(now) - config.lentTime;

        uint256 interest;
        uint256 clock = state.clock;

        if (clock >= currentClock) {
            interest = state.interest;
        } else {
            (interest,) = _runAdvanceClock({
                _clock: clock,
                _timeUnit: config.timeUnit,
                _interest: state.interest,
                _duration: config.duration,
                _cuota: cuota,
                _installments: installments,
                _paidBase: state.paidBase,
                _interestRate: config.interestRate,
                _targetClock: currentClock
            });
        }

        uint256 debt = cuota * installments + interest;
        uint256 paid = state.paid;
        return debt > paid ? debt - paid : 0;
    }


    function _runAdvanceClock(
        uint256 _clock,
        uint256 _timeUnit,
        uint256 _interest,
        uint256 _duration,
        uint256 _cuota,
        uint256 _installments,
        uint256 _paidBase,
        uint256 _interestRate,
        uint256 _targetClock
    ) internal pure returns (uint256 interest, uint256 clock) {
        // Advance clock to lentTime if never advanced before
        clock = _clock;
        interest = _interest;

        // Aux variables
        uint256 delta;
        bool installmentCompleted;
        
        do {
            // Delta to next installment and absolute delta (no exceeding 1 installment)
            (delta, installmentCompleted) = _calcDelta({
                _targetDelta: _targetClock - clock,
                _clock: clock,
                _duration: _duration,
                _installments: _installments
            });

            // Running debt
            uint256 newInterest = _newInterest({
                _clock: clock,
                _timeUnit: _timeUnit,
                _duration: _duration,
                _installments: _installments,
                _cuota: _cuota,
                _paidBase: _paidBase,
                _delta: delta,
                _interestRate: _interestRate
            });

            // Don&#39;t change clock unless we have a change
            if (installmentCompleted || newInterest > 0) {
                clock += delta;
                interest += newInterest;
            } else {
                break;
            }
        } while (clock < _targetClock);
    }

    function _calcDelta(
        uint256 _targetDelta,
        uint256 _clock,
        uint256 _duration,
        uint256 _installments
    ) internal pure returns (uint256 delta, bool installmentCompleted) {
        uint256 nextInstallmentDelta = _duration - _clock % _duration;
        if (nextInstallmentDelta <= _targetDelta && _clock / _duration < _installments) {
            delta = nextInstallmentDelta;
            installmentCompleted = true;
        } else {
            delta = _targetDelta;
            installmentCompleted = false;
        }
    }

    function _newInterest(
        uint256 _clock,
        uint256 _timeUnit,
        uint256 _duration,
        uint256 _installments,
        uint256 _cuota,
        uint256 _paidBase,
        uint256 _delta,
        uint256 _interestRate
    ) internal pure returns (uint256) {
        uint256 runningDebt = _baseDebt(_clock, _duration, _installments, _cuota) - _paidBase;
        uint256 newInterest = (100000 * (_delta / _timeUnit) * runningDebt) / (_interestRate / _timeUnit);
        require(newInterest < U_128_OVERFLOW, "New interest overflow");
        return newInterest;
    }

    function _baseDebt(
        uint256 clock,
        uint256 duration,
        uint256 installments,
        uint256 cuota
    ) internal pure returns (uint256 base) {
        uint256 installment = clock / duration;
        return uint128(installment < installments ? installment * cuota : installments * cuota);
    }

    function _validate(
        uint256 _cuota,
        uint256 _interestRate,
        uint256 _installments,
        uint256 _installmentDuration,
        uint256 _timeUnit
    ) internal pure {
        require(_cuota > 0, "Cuota can&#39;t be 0");
        require(_interestRate > 0, "Interest rate can&#39;t be 0");
        require(_installments > 0, "Installments can&#39;t be 0");
        require(_installmentDuration > 0, "Installment duration can&#39;t be 0");
        require(_timeUnit <= _installmentDuration, "Time unit can&#39;t be lower than installment duration");
        require(_interestRate > _timeUnit, "Interest rate by time unit is too low");
        require(_timeUnit > 0, "Time unit can&#39;be 0");
    }

    function _decodeData(
        bytes _data
    ) internal pure returns (uint128, uint256, uint24, uint40, uint32) {
        require(_data.length == L_DATA, "Invalid data length");
        (
            bytes32 cuota,
            bytes32 interestRate,
            bytes32 installments,
            bytes32 duration,
            bytes32 timeUnit
        ) = decode(_data, 16, 32, 3, 5, 4);
        return (uint128(cuota), uint256(interestRate), uint24(installments), uint40(duration), uint32(timeUnit));
    }
}