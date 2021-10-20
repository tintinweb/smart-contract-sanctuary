pragma solidity ^0.5.16;

// Inheritance
import "./Owned.sol";
import "./interfaces/IDelegateApprovals.sol";

// Internal references
import "./EternalStorage.sol";

contract DelegateApprovals is Owned, IDelegateApprovals {
    bytes32 public constant BURN_FOR_ADDRESS = "BurnForAddress";
    bytes32 public constant ISSUE_FOR_ADDRESS = "IssueForAddress";
    bytes32 public constant CLAIM_FOR_ADDRESS = "ClaimForAddress";
    bytes32 public constant EXCHANGE_FOR_ADDRESS = "ExchangeForAddress";
    bytes32 public constant APPROVE_ALL = "ApproveAll";

    bytes32[5] private _delegatableFunctions = [
        APPROVE_ALL,
        BURN_FOR_ADDRESS,
        ISSUE_FOR_ADDRESS,
        CLAIM_FOR_ADDRESS,
        EXCHANGE_FOR_ADDRESS
    ];

    /* ========== STATE VARIABLES ========== */
    EternalStorage public eternalStorage;

    constructor(address _owner, EternalStorage _eternalStorage) public Owned(_owner) {
        eternalStorage = _eternalStorage;
    }

    /* ========== VIEWS ========== */

    // Move it to setter and associatedState

    // util to get key based on action name + address of authoriser + address for delegate
    function _getKey(
        bytes32 _action,
        address _authoriser,
        address _delegate
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_action, _authoriser, _delegate));
    }

    // hash of actionName + address of authoriser + address for the delegate
    function canBurnFor(address authoriser, address delegate) external view returns (bool) {
        return _checkApproval(BURN_FOR_ADDRESS, authoriser, delegate);
    }

    function canIssueFor(address authoriser, address delegate) external view returns (bool) {
        return _checkApproval(ISSUE_FOR_ADDRESS, authoriser, delegate);
    }

    function canClaimFor(address authoriser, address delegate) external view returns (bool) {
        return _checkApproval(CLAIM_FOR_ADDRESS, authoriser, delegate);
    }

    function canExchangeFor(address authoriser, address delegate) external view returns (bool) {
        return _checkApproval(EXCHANGE_FOR_ADDRESS, authoriser, delegate);
    }

    function approvedAll(address authoriser, address delegate) public view returns (bool) {
        return eternalStorage.getBooleanValue(_getKey(APPROVE_ALL, authoriser, delegate));
    }

    // internal function to check approval based on action
    // if approved for all actions then will return true
    // before checking specific approvals
    function _checkApproval(
        bytes32 action,
        address authoriser,
        address delegate
    ) internal view returns (bool) {
        if (approvedAll(authoriser, delegate)) return true;

        return eternalStorage.getBooleanValue(_getKey(action, authoriser, delegate));
    }

    /* ========== SETTERS ========== */

    // Approve All
    function approveAllDelegatePowers(address delegate) external {
        _setApproval(APPROVE_ALL, msg.sender, delegate);
    }

    // Removes all delegate approvals
    function removeAllDelegatePowers(address delegate) external {
        for (uint i = 0; i < _delegatableFunctions.length; i++) {
            _withdrawApproval(_delegatableFunctions[i], msg.sender, delegate);
        }
    }

    // Burn on behalf
    function approveBurnOnBehalf(address delegate) external {
        _setApproval(BURN_FOR_ADDRESS, msg.sender, delegate);
    }

    function removeBurnOnBehalf(address delegate) external {
        _withdrawApproval(BURN_FOR_ADDRESS, msg.sender, delegate);
    }

    // Issue on behalf
    function approveIssueOnBehalf(address delegate) external {
        _setApproval(ISSUE_FOR_ADDRESS, msg.sender, delegate);
    }

    function removeIssueOnBehalf(address delegate) external {
        _withdrawApproval(ISSUE_FOR_ADDRESS, msg.sender, delegate);
    }

    // Claim on behalf
    function approveClaimOnBehalf(address delegate) external {
        _setApproval(CLAIM_FOR_ADDRESS, msg.sender, delegate);
    }

    function removeClaimOnBehalf(address delegate) external {
        _withdrawApproval(CLAIM_FOR_ADDRESS, msg.sender, delegate);
    }

    // Exchange on behalf
    function approveExchangeOnBehalf(address delegate) external {
        _setApproval(EXCHANGE_FOR_ADDRESS, msg.sender, delegate);
    }

    function removeExchangeOnBehalf(address delegate) external {
        _withdrawApproval(EXCHANGE_FOR_ADDRESS, msg.sender, delegate);
    }

    function _setApproval(
        bytes32 action,
        address authoriser,
        address delegate
    ) internal {
        require(delegate != address(0), "Can't delegate to address(0)");
        eternalStorage.setBooleanValue(_getKey(action, authoriser, delegate), true);
        emit Approval(authoriser, delegate, action);
    }

    function _withdrawApproval(
        bytes32 action,
        address authoriser,
        address delegate
    ) internal {
        // Check approval is set otherwise skip deleting approval
        if (eternalStorage.getBooleanValue(_getKey(action, authoriser, delegate))) {
            eternalStorage.deleteBooleanValue(_getKey(action, authoriser, delegate));
            emit WithdrawApproval(authoriser, delegate, action);
        }
    }

    function setEternalStorage(EternalStorage _eternalStorage) external onlyOwner {
        require(address(_eternalStorage) != address(0), "Can't set eternalStorage to address(0)");
        eternalStorage = _eternalStorage;
        emit EternalStorageUpdated(address(eternalStorage));
    }

    /* ========== EVENTS ========== */
    event Approval(address indexed authoriser, address delegate, bytes32 action);
    event WithdrawApproval(address indexed authoriser, address delegate, bytes32 action);
    event EternalStorageUpdated(address newEternalStorage);
}

pragma solidity >=0.4.24;

interface IDelegateApprovals {
    // Views
    function canBurnFor(address authoriser, address delegate) external view returns (bool);

    function canIssueFor(address authoriser, address delegate) external view returns (bool);

    function canClaimFor(address authoriser, address delegate) external view returns (bool);

    function canExchangeFor(address authoriser, address delegate) external view returns (bool);

    // Mutative
    function approveAllDelegatePowers(address delegate) external;

    function removeAllDelegatePowers(address delegate) external;

    function approveBurnOnBehalf(address delegate) external;

    function removeBurnOnBehalf(address delegate) external;

    function approveIssueOnBehalf(address delegate) external;

    function removeIssueOnBehalf(address delegate) external;

    function approveClaimOnBehalf(address delegate) external;

    function removeClaimOnBehalf(address delegate) external;

    function approveExchangeOnBehalf(address delegate) external;

    function removeExchangeOnBehalf(address delegate) external;
}

pragma solidity ^0.5.16;

// Inheritance
import "./Owned.sol";

contract State is Owned {
    // the address of the contract that can modify variables
    // this can only be changed by the owner of this contract
    address public associatedContract;

    constructor(address _associatedContract) internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== SETTERS ========== */

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract) external onlyOwner {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContract {
        require(msg.sender == associatedContract, "Only the associated contract can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractUpdated(address associatedContract);
}

pragma solidity ^0.5.16;

contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

pragma solidity ^0.5.16;

// Inheritance
import "./Owned.sol";
import "./State.sol";

/**
 * @notice  This contract is based on the code available from this blog
 * https://blog.colony.io/writing-upgradeable-contracts-in-solidity-6743f0eecc88/
 * Implements support for storing a keccak256 key and value pairs. It is the more flexible
 * and extensible option. This ensures data schema changes can be implemented without
 * requiring upgrades to the storage contract.
 */
contract EternalStorage is Owned, State {
    constructor(address _owner, address _associatedContract) public Owned(_owner) State(_associatedContract) {}

    /* ========== DATA TYPES ========== */
    mapping(bytes32 => uint) internal UIntStorage;
    mapping(bytes32 => string) internal StringStorage;
    mapping(bytes32 => address) internal AddressStorage;
    mapping(bytes32 => bytes) internal BytesStorage;
    mapping(bytes32 => bytes32) internal Bytes32Storage;
    mapping(bytes32 => bool) internal BooleanStorage;
    mapping(bytes32 => int) internal IntStorage;

    // UIntStorage;
    function getUIntValue(bytes32 record) external view returns (uint) {
        return UIntStorage[record];
    }

    function setUIntValue(bytes32 record, uint value) external onlyAssociatedContract {
        UIntStorage[record] = value;
    }

    function deleteUIntValue(bytes32 record) external onlyAssociatedContract {
        delete UIntStorage[record];
    }

    // StringStorage
    function getStringValue(bytes32 record) external view returns (string memory) {
        return StringStorage[record];
    }

    function setStringValue(bytes32 record, string calldata value) external onlyAssociatedContract {
        StringStorage[record] = value;
    }

    function deleteStringValue(bytes32 record) external onlyAssociatedContract {
        delete StringStorage[record];
    }

    // AddressStorage
    function getAddressValue(bytes32 record) external view returns (address) {
        return AddressStorage[record];
    }

    function setAddressValue(bytes32 record, address value) external onlyAssociatedContract {
        AddressStorage[record] = value;
    }

    function deleteAddressValue(bytes32 record) external onlyAssociatedContract {
        delete AddressStorage[record];
    }

    // BytesStorage
    function getBytesValue(bytes32 record) external view returns (bytes memory) {
        return BytesStorage[record];
    }

    function setBytesValue(bytes32 record, bytes calldata value) external onlyAssociatedContract {
        BytesStorage[record] = value;
    }

    function deleteBytesValue(bytes32 record) external onlyAssociatedContract {
        delete BytesStorage[record];
    }

    // Bytes32Storage
    function getBytes32Value(bytes32 record) external view returns (bytes32) {
        return Bytes32Storage[record];
    }

    function setBytes32Value(bytes32 record, bytes32 value) external onlyAssociatedContract {
        Bytes32Storage[record] = value;
    }

    function deleteBytes32Value(bytes32 record) external onlyAssociatedContract {
        delete Bytes32Storage[record];
    }

    // BooleanStorage
    function getBooleanValue(bytes32 record) external view returns (bool) {
        return BooleanStorage[record];
    }

    function setBooleanValue(bytes32 record, bool value) external onlyAssociatedContract {
        BooleanStorage[record] = value;
    }

    function deleteBooleanValue(bytes32 record) external onlyAssociatedContract {
        delete BooleanStorage[record];
    }

    // IntStorage
    function getIntValue(bytes32 record) external view returns (int) {
        return IntStorage[record];
    }

    function setIntValue(bytes32 record, int value) external onlyAssociatedContract {
        IntStorage[record] = value;
    }

    function deleteIntValue(bytes32 record) external onlyAssociatedContract {
        delete IntStorage[record];
    }
}