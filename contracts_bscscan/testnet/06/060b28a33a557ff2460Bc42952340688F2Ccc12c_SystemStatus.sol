pragma solidity ^0.5.16;

// Inheritance
import "./Owned.sol";
import "./interfaces/ISystemStatus.sol";

contract SystemStatus is Owned, ISystemStatus {
    mapping(bytes32 => mapping(address => Status)) public accessControl;

    uint248 public constant SUSPENSION_REASON_UPGRADE = 1;

    bytes32 public constant SECTION_SYSTEM = "System";
    bytes32 public constant SECTION_ISSUANCE = "Issuance";
    bytes32 public constant SECTION_EXCHANGE = "Exchange";
    bytes32 public constant SECTION_PHANT_EXCHANGE = "PhantExchange";
    bytes32 public constant SECTION_PHANT = "Phant";

    Suspension public systemSuspension;

    Suspension public issuanceSuspension;

    Suspension public exchangeSuspension;

    mapping(bytes32 => Suspension) public phantExchangeSuspension;

    mapping(bytes32 => Suspension) public phantSuspension;

    constructor(address _owner) public Owned(_owner) {}

    /* ========== VIEWS ========== */
    function requireSystemActive() external view {
        _internalRequireSystemActive();
    }

    function requireIssuanceActive() external view {
        // Issuance requires the system be active
        _internalRequireSystemActive();

        // and issuance itself of course
        _internalRequireIssuanceActive();
    }

    function requireExchangeActive() external view {
        // Exchanging requires the system be active
        _internalRequireSystemActive();

        // and exchanging itself of course
        _internalRequireExchangeActive();
    }

    function requirePhantExchangeActive(bytes32 currencyKey) external view {
        // Phant exchange and transfer requires the system be active
        _internalRequireSystemActive();
        _internalRequirePhantExchangeActive(currencyKey);
    }

    function requirePhantActive(bytes32 currencyKey) external view {
        // Phant exchange and transfer requires the system be active
        _internalRequireSystemActive();
        _internalRequirePhantActive(currencyKey);
    }

    function requirePhantsActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view {
        // Phant exchange and transfer requires the system be active
        _internalRequireSystemActive();
        _internalRequirePhantActive(sourceCurrencyKey);
        _internalRequirePhantActive(destinationCurrencyKey);
    }

    function requireExchangeBetweenPhantsAllowed(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view {
        // Phant exchange and transfer requires the system be active
        _internalRequireSystemActive();

        // and exchanging must be active
        _internalRequireExchangeActive();

        // and the phant exchanging between the phants must be active
        _internalRequirePhantExchangeActive(sourceCurrencyKey);
        _internalRequirePhantExchangeActive(destinationCurrencyKey);

        // and finally, the phants cannot be suspended
        _internalRequirePhantActive(sourceCurrencyKey);
        _internalRequirePhantActive(destinationCurrencyKey);
    }

    function isSystemUpgrading() external view returns (bool) {
        return systemSuspension.suspended && systemSuspension.reason == SUSPENSION_REASON_UPGRADE;
    }

    function getPhantExchangeSuspensions(bytes32[] calldata phants)
        external
        view
        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons)
    {
        exchangeSuspensions = new bool[](phants.length);
        reasons = new uint256[](phants.length);

        for (uint i = 0; i < phants.length; i++) {
            exchangeSuspensions[i] = phantExchangeSuspension[phants[i]].suspended;
            reasons[i] = phantExchangeSuspension[phants[i]].reason;
        }
    }

    function getPhantSuspensions(bytes32[] calldata phants)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons)
    {
        suspensions = new bool[](phants.length);
        reasons = new uint256[](phants.length);

        for (uint i = 0; i < phants.length; i++) {
            suspensions[i] = phantSuspension[phants[i]].suspended;
            reasons[i] = phantSuspension[phants[i]].reason;
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function updateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external onlyOwner {
        _internalUpdateAccessControl(section, account, canSuspend, canResume);
    }

    function updateAccessControls(
        bytes32[] calldata sections,
        address[] calldata accounts,
        bool[] calldata canSuspends,
        bool[] calldata canResumes
    ) external onlyOwner {
        require(
            sections.length == accounts.length &&
                accounts.length == canSuspends.length &&
                canSuspends.length == canResumes.length,
            "Input array lengths must match"
        );
        for (uint i = 0; i < sections.length; i++) {
            _internalUpdateAccessControl(sections[i], accounts[i], canSuspends[i], canResumes[i]);
        }
    }

    function suspendSystem(uint256 reason) external {
        _requireAccessToSuspend(SECTION_SYSTEM);
        systemSuspension.suspended = true;
        systemSuspension.reason = uint248(reason);
        emit SystemSuspended(systemSuspension.reason);
    }

    function resumeSystem() external {
        _requireAccessToResume(SECTION_SYSTEM);
        systemSuspension.suspended = false;
        emit SystemResumed(uint256(systemSuspension.reason));
        systemSuspension.reason = 0;
    }

    function suspendIssuance(uint256 reason) external {
        _requireAccessToSuspend(SECTION_ISSUANCE);
        issuanceSuspension.suspended = true;
        issuanceSuspension.reason = uint248(reason);
        emit IssuanceSuspended(reason);
    }

    function resumeIssuance() external {
        _requireAccessToResume(SECTION_ISSUANCE);
        issuanceSuspension.suspended = false;
        emit IssuanceResumed(uint256(issuanceSuspension.reason));
        issuanceSuspension.reason = 0;
    }

    function suspendExchange(uint256 reason) external {
        _requireAccessToSuspend(SECTION_EXCHANGE);
        exchangeSuspension.suspended = true;
        exchangeSuspension.reason = uint248(reason);
        emit ExchangeSuspended(reason);
    }

    function resumeExchange() external {
        _requireAccessToResume(SECTION_EXCHANGE);
        exchangeSuspension.suspended = false;
        emit ExchangeResumed(uint256(exchangeSuspension.reason));
        exchangeSuspension.reason = 0;
    }

    function suspendPhantExchange(bytes32 currencyKey, uint256 reason) external {
        bytes32[] memory currencyKeys = new bytes32[](1);
        currencyKeys[0] = currencyKey;
        _internalSuspendPhantExchange(currencyKeys, reason);
    }

    function suspendPhantsExchange(bytes32[] calldata currencyKeys, uint256 reason) external {
        _internalSuspendPhantExchange(currencyKeys, reason);
    }

    function resumePhantExchange(bytes32 currencyKey) external {
        bytes32[] memory currencyKeys = new bytes32[](1);
        currencyKeys[0] = currencyKey;
        _internalResumePhantsExchange(currencyKeys);
    }

    function resumePhantsExchange(bytes32[] calldata currencyKeys) external {
        _internalResumePhantsExchange(currencyKeys);
    }

    function suspendPhant(bytes32 currencyKey, uint256 reason) external {
        bytes32[] memory currencyKeys = new bytes32[](1);
        currencyKeys[0] = currencyKey;
        _internalSuspendPhants(currencyKeys, reason);
    }

    function suspendPhants(bytes32[] calldata currencyKeys, uint256 reason) external {
        _internalSuspendPhants(currencyKeys, reason);
    }

    function resumePhant(bytes32 currencyKey) external {
        bytes32[] memory currencyKeys = new bytes32[](1);
        currencyKeys[0] = currencyKey;
        _internalResumePhants(currencyKeys);
    }

    function resumePhants(bytes32[] calldata currencyKeys) external {
        _internalResumePhants(currencyKeys);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _requireAccessToSuspend(bytes32 section) internal view {
        require(accessControl[section][msg.sender].canSuspend, "Restricted to access control list");
    }

    function _requireAccessToResume(bytes32 section) internal view {
        require(accessControl[section][msg.sender].canResume, "Restricted to access control list");
    }

    function _internalRequireSystemActive() internal view {
        require(
            !systemSuspension.suspended,
            systemSuspension.reason == SUSPENSION_REASON_UPGRADE
                ? "Phantom is suspended, upgrade in progress... please stand by"
                : "Phantom is suspended. Operation prohibited"
        );
    }

    function _internalRequireIssuanceActive() internal view {
        require(!issuanceSuspension.suspended, "Issuance is suspended. Operation prohibited");
    }

    function _internalRequireExchangeActive() internal view {
        require(!exchangeSuspension.suspended, "Exchange is suspended. Operation prohibited");
    }

    function _internalRequirePhantExchangeActive(bytes32 currencyKey) internal view {
        require(!phantExchangeSuspension[currencyKey].suspended, "Phant exchange suspended. Operation prohibited");
    }

    function _internalRequirePhantActive(bytes32 currencyKey) internal view {
        require(!phantSuspension[currencyKey].suspended, "Phant is suspended. Operation prohibited");
    }

    function _internalSuspendPhants(bytes32[] memory currencyKeys, uint256 reason) internal {
        _requireAccessToSuspend(SECTION_PHANT);
        for (uint i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];
            phantSuspension[currencyKey].suspended = true;
            phantSuspension[currencyKey].reason = uint248(reason);
            emit PhantSuspended(currencyKey, reason);
        }
    }

    function _internalResumePhants(bytes32[] memory currencyKeys) internal {
        _requireAccessToResume(SECTION_PHANT);
        for (uint i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];
            emit PhantResumed(currencyKey, uint256(phantSuspension[currencyKey].reason));
            delete phantSuspension[currencyKey];
        }
    }

    function _internalSuspendPhantExchange(bytes32[] memory currencyKeys, uint256 reason) internal {
        _requireAccessToSuspend(SECTION_PHANT_EXCHANGE);
        for (uint i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];
            phantExchangeSuspension[currencyKey].suspended = true;
            phantExchangeSuspension[currencyKey].reason = uint248(reason);
            emit PhantExchangeSuspended(currencyKey, reason);
        }
    }

    function _internalResumePhantsExchange(bytes32[] memory currencyKeys) internal {
        _requireAccessToResume(SECTION_PHANT_EXCHANGE);
        for (uint i = 0; i < currencyKeys.length; i++) {
            bytes32 currencyKey = currencyKeys[i];
            emit PhantExchangeResumed(currencyKey, uint256(phantExchangeSuspension[currencyKey].reason));
            delete phantExchangeSuspension[currencyKey];
        }
    }

    function _internalUpdateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) internal {
        require(
            section == SECTION_SYSTEM ||
                section == SECTION_ISSUANCE ||
                section == SECTION_PHANT,
            "Invalid section supplied"
        );
        accessControl[section][account].canSuspend = canSuspend;
        accessControl[section][account].canResume = canResume;
        emit AccessControlUpdated(section, account, canSuspend, canResume);
    }

    /* ========== EVENTS ========== */

    event SystemSuspended(uint256 reason);
    event SystemResumed(uint256 reason);

    event IssuanceSuspended(uint256 reason);
    event IssuanceResumed(uint256 reason);

    event ExchangeSuspended(uint256 reason);
    event ExchangeResumed(uint256 reason);

    event PhantExchangeSuspended(bytes32 currencyKey, uint256 reason);
    event PhantExchangeResumed(bytes32 currencyKey, uint256 reason);

    event PhantSuspended(bytes32 currencyKey, uint256 reason);
    event PhantResumed(bytes32 currencyKey, uint256 reason);

    event AccessControlUpdated(bytes32 indexed section, address indexed account, bool canSuspend, bool canResume);
}

pragma solidity >=0.4.24;

interface ISystemStatus {
    struct Status {
        bool canSuspend;
        bool canResume;
    }

    struct Suspension {
        bool suspended;
        // reason is an integer code,
        // 0 => no reason, 1 => upgrading, 2+ => defined by system usage
        uint248 reason;
    }

    // Views
    function accessControl(bytes32 section, address account) external view returns (bool canSuspend, bool canResume);

    function requireSystemActive() external view;

    function requireIssuanceActive() external view;

    function requireExchangeActive() external view;

    function requireExchangeBetweenPhantsAllowed(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function requirePhantActive(bytes32 currencyKey) external view;

    function requirePhantsActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function systemSuspension() external view returns (bool suspended, uint248 reason);

    function issuanceSuspension() external view returns (bool suspended, uint248 reason);

    function exchangeSuspension() external view returns (bool suspended, uint248 reason);

    function phantExchangeSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function phantSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function getPhantExchangeSuspensions(bytes32[] calldata phants)
        external
        view
        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons);

    function getPhantSuspensions(bytes32[] calldata phants)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    // Restricted functions
    function suspendPhant(bytes32 currencyKey, uint256 reason) external;

    function updateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external;
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