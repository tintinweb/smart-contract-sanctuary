/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "./utils/AddressArrayUtils.sol";
import "./utils/PercentUtils.sol";
import "./KeepRegistry.sol";
import "./IRandomBeacon.sol";


interface OperatorContract {
    function entryVerificationFee() external view returns(uint256);
    function groupCreationFee() external view returns(uint256);
    function groupProfitFee() external view returns(uint256);
    function gasPriceCeiling() external view returns(uint256);
    function sign(
        uint256 requestId,
        bytes calldata previousEntry
    ) external payable;
    function numberOfGroups() external view returns(uint256);
    function createGroup(uint256 newEntry, address payable submitter) external payable;
    function isGroupSelectionPossible() external view returns (bool);
}

/// @title KeepRandomBeaconServiceImplV1
/// @notice Initial version of service contract that works under Keep Random
/// Beacon proxy and allows upgradability. The purpose of the contract is to have
/// up-to-date logic for threshold random number generation. Updated contracts
/// must inherit from this contract and have to be initialized under updated version
/// name.
/// @dev Warning: you can't set constants directly in the contract and must use
/// initialize() please see openzeppelin upgradeable contracts approach for more
/// info.
contract KeepRandomBeaconServiceImplV1 is ReentrancyGuard, IRandomBeacon {
    using SafeMath for uint256;
    using PercentUtils for uint256;
    using AddressArrayUtils for address[];

    event RelayEntryRequested(uint256 requestId);

    /// @dev Fraction in % of the estimated cost of DKG that is included
    /// in relay request fee.
    uint256 internal _dkgContributionMargin;

    /// @dev Every relay request payment includes DKG contribution that is added to
    /// the DKG fee pool, once the pool value reaches the required minimum, a new
    /// relay entry will trigger the creation of a new group. Expressed in wei.
    uint256 internal _dkgFeePool;

    /// @dev Rewards not paid out to the operators are sent to request subsidy pool to
    /// subsidize new requests: 1% of the subsidy pool is returned to the requester's
    /// surplus address. Expressed in wei.
    uint256 internal _requestSubsidyFeePool;

    /// @dev Each service contract tracks its own requests and these are independent
    /// from operator contracts which track signing requests instead.
    uint256 internal _requestCounter;

    /// @dev Previous entry value produced by the beacon.
    bytes internal _previousEntry;

    /// @dev The cost of executing executeCallback() code of this contract, includes
    /// everything but the logic of the external contract called.
    /// The value is used to estimate the cost of executing a callback and is
    /// used for calculating callback call surplus reimbursement for requestor.
    ///
    /// This value has to be updated in case of EVM opcode price change, but since
    /// upgrading service contract is easy, it is not a worrisome problem.
    uint256 internal _baseCallbackGas;

    struct Callback {
        address callbackContract;
        uint256 callbackFee;
        uint256 callbackGas;
        address payable surplusRecipient;
    }

    mapping(uint256 => Callback) internal _callbacks;

    /// @dev KeepRegistry contract with a list of approved operator contracts and upgraders.
    address internal _registry;

    address[] internal _operatorContracts;

    /// @dev Mapping to store new implementation versions that inherit from this contract.
    mapping (string => bool) internal _initialized;

    /// @dev Seed used as the first random beacon value.
    /// It's a G1 point G * PI =
    /// G * 31415926535897932384626433832795028841971693993751058209749445923078164062862
    /// Where G is the generator of G1 abstract cyclic group.
    bytes constant internal _beaconSeed =
    hex"15c30f4b6cf6dbbcbdcc10fe22f54c8170aea44e198139b776d512d8f027319a1b9e8bfaf1383978231ce98e42bafc8129f473fc993cf60ce327f7d223460663";

    /// @dev Throws if called by any account other than the operator contract
    /// upgrader authorized for this service contract.
    modifier onlyOperatorContractUpgrader() {
        address operatorContractUpgrader = KeepRegistry(_registry).operatorContractUpgraderFor(address(this));
        require(operatorContractUpgrader == msg.sender, "Caller is not operator contract upgrader");
        _;
    }

    constructor() public {
        _initialized["KeepRandomBeaconServiceImplV1"] = true;
    }

    /// @notice Initialize Keep Random Beacon service contract implementation.
    /// @param dkgContributionMargin Fraction in % of the estimated cost of DKG that is included in relay
    /// request fee.
    /// @param registry KeepRegistry contract linked to this contract.
    function initialize(
        uint256 dkgContributionMargin,
        address registry
    )
        public
    {
        require(!initialized(), "Contract is already initialized.");
        require(registry != address(0), "Incorrect registry address");

        _initialized["KeepRandomBeaconServiceImplV1"] = true;
        _dkgContributionMargin = dkgContributionMargin;
        _previousEntry = _beaconSeed;
        _registry = registry;
        _baseCallbackGas = 10226;
    }

    /// @notice Checks if this contract is initialized.
    function initialized() public view returns (bool) {
        return _initialized["KeepRandomBeaconServiceImplV1"];
    }

    /// @notice Adds operator contract
    /// @param operatorContract Address of the operator contract.
    function addOperatorContract(address operatorContract) public onlyOperatorContractUpgrader {
        require(
            KeepRegistry(_registry).isApprovedOperatorContract(operatorContract),
            "Operator contract is not approved"
        );
        _operatorContracts.push(operatorContract);
    }

    /// @notice Removes operator contract
    /// @param operatorContract Address of the operator contract.
    function removeOperatorContract(address operatorContract) public onlyOperatorContractUpgrader {
        _operatorContracts.removeAddress(operatorContract);
    }

    /// @notice Add funds to DKG fee pool.
    function fundDkgFeePool() public payable {
        _dkgFeePool += msg.value;
    }

    /// @notice Add funds to request subsidy fee pool.
    function fundRequestSubsidyFeePool() public payable {
        _requestSubsidyFeePool += msg.value;
    }

    /// @notice Selects an operator contract from the available list using modulo
    /// operation with seed value weighted by the number of active groups on each
    /// operator contract.
    /// @param seed Cryptographically generated random value.
    /// @return Address of operator contract.
    function selectOperatorContract(uint256 seed) public view returns (address) {

        uint256 totalNumberOfGroups;

        uint256 approvedContractsCounter;
        address[] memory approvedContracts = new address[](_operatorContracts.length);

        for (uint i = 0; i < _operatorContracts.length; i++) {
            if (KeepRegistry(_registry).isApprovedOperatorContract(_operatorContracts[i])) {
                totalNumberOfGroups += OperatorContract(_operatorContracts[i]).numberOfGroups();
                approvedContracts[approvedContractsCounter] = _operatorContracts[i];
                approvedContractsCounter++;
            }
        }

        require(totalNumberOfGroups > 0, "Total number of groups must be greater than zero.");

        uint256 selectedIndex = seed % totalNumberOfGroups;

        uint256 selectedContract;
        uint256 indexByGroupCount;

        for (uint256 i = 0; i < approvedContractsCounter; i++) {
            indexByGroupCount += OperatorContract(approvedContracts[i]).numberOfGroups();
            if (selectedIndex < indexByGroupCount) {
                return approvedContracts[selectedContract];
            }
            selectedContract++;
        }

        return approvedContracts[selectedContract];
    }

    /// @notice Creates a request to generate a new relay entry, which will include
    /// a random number (by signing the previous entry's random number).
    /// @return An uint256 representing uniquely generated entry Id.
    function requestRelayEntry() public payable returns (uint256) {
        return requestRelayEntry(address(0), 0);
    }

    /// @notice Creates a request to generate a new relay entry (random number).
    /// @param callbackContract Callback contract address. Callback is called
    /// once a new relay entry has been generated. Callback contract must
    /// declare public `__beaconCallback(uint256)` function that is going to be
    /// executed with the result, once ready.
    /// @param callbackGas Gas required for the callback (2 million gas max).
    /// The customer needs to ensure they provide a sufficient callback gas
    /// to cover the gas fee of executing the callback. Any surplus is returned
    /// to the customer. If the callback gas amount turns to be not enough to
    /// execute the callback, callback execution is skipped.
    /// @return An uint256 representing uniquely generated relay request ID. It
    /// is also returned as part of the event.
    function requestRelayEntry(
        address callbackContract,
        uint256 callbackGas
    ) public nonReentrant payable returns (uint256) {
        require(
            callbackGas <= 2000000,
            "Callback gas exceeds 2000000 gas limit"
        );

        require(
            msg.value >= entryFeeEstimate(callbackGas),
            "Payment is less than required minimum."
        );

        (
            uint256 entryVerificationFee,
            uint256 dkgContributionFee,
            uint256 groupProfitFee,
            uint256 gasPriceCeiling
        ) = entryFeeBreakdown();

        uint256 callbackFee = msg.value.sub(entryVerificationFee)
            .sub(dkgContributionFee).sub(groupProfitFee);

        _dkgFeePool += dkgContributionFee;

        OperatorContract operatorContract = OperatorContract(
            selectOperatorContract(uint256(keccak256(_previousEntry)))
        );

        uint256 selectedOperatorContractFee = operatorContract.groupProfitFee().add(
            operatorContract.entryVerificationFee()
        );

        _requestCounter++;
        uint256 requestId = _requestCounter;

        operatorContract.sign.value(
            selectedOperatorContractFee.add(callbackFee)
        )(requestId, _previousEntry);

        // If selected operator contract is cheaper than expected return the
        // surplus to the subsidy fee pool.
        // We do that instead of returning the surplus to the requestor to have
        // a consistent beacon pricing for customers without fluctuations caused
        // by different operator contracts being selected.
        uint256 surplus = entryVerificationFee.add(groupProfitFee).sub(selectedOperatorContractFee);
        _requestSubsidyFeePool = _requestSubsidyFeePool.add(surplus);

        if (callbackContract != address(0)) {
            _callbacks[requestId] = Callback(callbackContract, callbackFee, callbackGas, msg.sender);
        }

        // Send 1% of the request subsidy pool to the requestor.
        if (_requestSubsidyFeePool >= 100) {
            uint256 amount = _requestSubsidyFeePool.percent(1);
            _requestSubsidyFeePool -= amount;
            (bool success, ) = msg.sender.call.value(amount)("");
            require(success, "Failed send subsidy fee");
        }

        emit RelayEntryRequested(requestId);
        return requestId;
    }

    /// @notice Store valid entry returned by operator contract and call customer
    /// specified callback if required.
    /// @param requestId Request id tracked internally by this contract.
    /// @param entry The generated random number.
    /// @param submitter Relay entry submitter.
    function entryCreated(uint256 requestId, bytes memory entry, address payable submitter) public {
        require(
            _operatorContracts.contains(msg.sender),
            "Only authorized operator contract can call relay entry."
        );

        _previousEntry = entry;
        uint256 entryAsNumber = uint256(keccak256(entry));
        emit RelayEntryGenerated(requestId, entryAsNumber);

        createGroupIfApplicable(entryAsNumber, submitter);
    }

    /// @notice Executes customer specified callback for the relay entry request.
    /// @param requestId Request id tracked internally by this contract.
    /// @param entry The generated random number.
    function executeCallback(uint256 requestId, uint256 entry) public {
        require(
            _operatorContracts.contains(msg.sender),
            "Only authorized operator contract can call execute callback."
        );

        require(
            _callbacks[requestId].callbackContract != address(0),
            "Callback contract not found"
        );

        _callbacks[requestId].callbackContract.call(
            abi.encodeWithSignature("__beaconCallback(uint256)", entry)
        );

        delete _callbacks[requestId];
    }

    /// @notice Triggers the selection process of a new candidate group if the
    /// DKG fee pool equals or exceeds DKG cost estimate.
    /// @param entry The generated random number.
    /// @param submitter Relay entry submitter - operator.
    function createGroupIfApplicable(uint256 entry, address payable submitter) internal {
        address latestOperatorContract = _operatorContracts[_operatorContracts.length.sub(1)];
        uint256 groupCreationFee = OperatorContract(latestOperatorContract).groupCreationFee();

        if (_dkgFeePool >= groupCreationFee && OperatorContract(latestOperatorContract).isGroupSelectionPossible()) {
            OperatorContract(latestOperatorContract).createGroup.value(groupCreationFee)(entry, submitter);
            _dkgFeePool = _dkgFeePool.sub(groupCreationFee);
        }
    }

    /// @notice Get base callback gas required for relay entry callback.
    function baseCallbackGas() public view returns(uint256) {
        return _baseCallbackGas;
    }

    /// @notice Get the minimum payment in wei for relay entry callback.
    /// @param _callbackGas Gas required for the callback.
    function callbackFee(
        uint256 _callbackGas,
        uint256 _gasPriceCeiling
    ) internal view returns(uint256) {
        // gas for the callback itself plus additional operational costs of
        // executing the callback
        uint256 callbackGas = _callbackGas == 0 ? 0 : _callbackGas.add(_baseCallbackGas);
        // We take the gas price from the price feed to not let malicious
        // miner-requestors manipulate the gas price when requesting relay entry
        // and underpricing expensive callbacks.
        return callbackGas.mul(_gasPriceCeiling);
    }

    /// @notice Get the entry fee estimate in wei for relay entry request.
    /// @param callbackGas Gas required for the callback.
    function entryFeeEstimate(uint256 callbackGas) public view returns(uint256) {
        require(
            callbackGas <= 2000000,
            "Callback gas exceeds 2000000 gas limit"
        );

        (
            uint256 entryVerificationFee,
            uint256 dkgContributionFee,
            uint256 groupProfitFee,
            uint256 gasPriceCeiling
        ) = entryFeeBreakdown();

        return entryVerificationFee
            .add(dkgContributionFee)
            .add(groupProfitFee)
            .add(callbackFee(callbackGas, gasPriceCeiling));
    }

    /// @notice Get the entry fee breakdown in wei for relay entry request.
    function entryFeeBreakdown() public view returns(
        uint256 entryVerificationFee,
        uint256 dkgContributionFee,
        uint256 groupProfitFee,
        uint256 gasPriceCeiling
    ) {
        // Select the most expensive entry verification from all the operator contracts
        // and the highest group profit fee from all the operator contracts. We do not
        // know what is going to be the gas price at the moment of submitting an entry,
        // thus we can't calculate at this point which contract is the most expensive
        // based on the entry verification gas and group profit fee. Hence, we need to
        // select maximum of both those values separately.
        for (uint i = 0; i < _operatorContracts.length; i++) {
            OperatorContract operator = OperatorContract(_operatorContracts[i]);

            if (operator.numberOfGroups() > 0) {
                uint256 operatorBid = operator.entryVerificationFee();
                if (operatorBid > entryVerificationFee) {
                    entryVerificationFee = operatorBid;
                }

                operatorBid = operator.groupProfitFee();
                if (operatorBid > groupProfitFee) {
                    groupProfitFee = operatorBid;
                }

                operatorBid = operator.gasPriceCeiling();
                if (operatorBid > gasPriceCeiling) {
                    gasPriceCeiling = operatorBid;
                }
            }
        }

        // Use DKG gas estimate from the latest operator contract since it will be used for the next group creation.
        address latestOperatorContract = _operatorContracts[_operatorContracts.length.sub(1)];
        uint256 groupCreationFee = OperatorContract(latestOperatorContract).groupCreationFee();

        return (
            entryVerificationFee,
            groupCreationFee.percent(_dkgContributionMargin),
            groupProfitFee,
            gasPriceCeiling
        );
    }

    /// @notice Returns DKG contribution margin - a fraction in % of the
    /// estimated cost of DKG that is included in relay request fee.
    function dkgContributionMargin() public view returns(uint256) {
        return _dkgContributionMargin;
    }

    /// @notice Returns the current DKG fee pool value.
    /// Every relay request payment includes DKG contribution that is added to
    /// the DKG fee pool, once the pool value reaches the required minimum, a new
    /// relay entry will trigger the creation of a new group. Expressed in wei.
    function dkgFeePool() public view returns(uint256) {
        return _dkgFeePool;
    }

    /// @notice Returns the current value of request subsidy pool.
    /// Rewards not paid out to the operators are sent to request subsidy pool to
    /// subsidize new requests: 1% of the subsidy pool is returned to the requester's
    /// surplus address. Expressed in wei.
    function requestSubsidyFeePool() public view returns(uint256) {
        return _requestSubsidyFeePool;
    }

    /// @notice Returns callback surplus recipient for the provided request id.
    function callbackSurplusRecipient(uint256 requestId) public view returns(address payable) {
        return _callbacks[requestId].surplusRecipient;
    }

    /// @notice Gets version of the current implementation.
    function version() public pure returns (string memory) {
        return "V1";
    }
}
