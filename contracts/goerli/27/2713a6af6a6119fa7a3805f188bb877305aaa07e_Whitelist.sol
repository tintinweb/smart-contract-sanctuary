/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// Sources flattened with hardhat v2.4.0 https://hardhat.org

// File contracts/role/interface/IBaseOperators.sol

/**
 * @title IBaseOperators
 * @notice Interface for BaseOperators contract
 */

pragma solidity 0.5.12;

interface IBaseOperators {
    function isOperator(address _account) external view returns (bool);

    function isAdmin(address _account) external view returns (bool);

    function isSystem(address _account) external view returns (bool);

    function isRelay(address _account) external view returns (bool);

    function isMultisig(address _contract) external view returns (bool);

    function confirmFor(address _address) external;

    function addOperator(address _account) external;

    function removeOperator(address _account) external;

    function addAdmin(address _account) external;

    function removeAdmin(address _account) external;

    function addSystem(address _account) external;

    function removeSystem(address _account) external;

    function addRelay(address _account) external;

    function removeRelay(address _account) external;

    function addOperatorAndAdmin(address _account) external;

    function removeOperatorAndAdmin(address _account) external;
}


// File contracts/helpers/Initializable.sol

pragma solidity 0.5.12;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(
            initializing || isConstructor() || !initialized,
            "Initializable: Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        // solhint-disable-next-line
        assembly {
            cs := extcodesize(address)
        }
        return cs == 0;
    }

    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}


// File contracts/role/base/Operatorable.sol

/**
 * @title Operatorable
 * @author Team 3301 <[email protected]>
 * @dev Operatorable contract stores the BaseOperators contract address, and modifiers for
 *       contracts.
 */

pragma solidity 0.5.12;


contract Operatorable is Initializable {
    IBaseOperators internal operatorsInst;
    address private operatorsPending;

    event OperatorsContractChanged(address indexed caller, address indexed operatorsAddress);
    event OperatorsContractPending(address indexed caller, address indexed operatorsAddress);

    /**
     * @dev Reverts if sender does not have operator role associated.
     */
    modifier onlyOperator() {
        require(isOperator(msg.sender), "Operatorable: caller does not have the operator role");
        _;
    }

    /**
     * @dev Reverts if sender does not have admin role associated.
     */
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Operatorable: caller does not have the admin role");
        _;
    }

    /**
     * @dev Reverts if sender does not have system role associated.
     */
    modifier onlySystem() {
        require(isSystem(msg.sender), "Operatorable: caller does not have the system role");
        _;
    }

    /**
     * @dev Reverts if sender does not have multisig privileges.
     */
    modifier onlyMultisig() {
        require(isMultisig(msg.sender), "Operatorable: caller does not have multisig role");
        _;
    }

    /**
     * @dev Reverts if sender does not have admin or system role associated.
     */
    modifier onlyAdminOrSystem() {
        require(isAdminOrSystem(msg.sender), "Operatorable: caller does not have the admin role nor system");
        _;
    }

    /**
     * @dev Reverts if sender does not have operator or system role associated.
     */
    modifier onlyOperatorOrSystem() {
        require(isOperatorOrSystem(msg.sender), "Operatorable: caller does not have the operator role nor system");
        _;
    }

    /**
     * @dev Reverts if sender does not have the relay role associated.
     */
    modifier onlyRelay() {
        require(isRelay(msg.sender), "Operatorable: caller does not have relay role associated");
        _;
    }

    /**
     * @dev Reverts if sender does not have relay or operator role associated.
     */
    modifier onlyOperatorOrRelay() {
        require(
            isOperator(msg.sender) || isRelay(msg.sender),
            "Operatorable: caller does not have the operator role nor relay"
        );
        _;
    }

    /**
     * @dev Reverts if sender does not have relay or admin role associated.
     */
    modifier onlyAdminOrRelay() {
        require(
            isAdmin(msg.sender) || isRelay(msg.sender),
            "Operatorable: caller does not have the admin role nor relay"
        );
        _;
    }

    /**
     * @dev Reverts if sender does not have the operator, or system, or relay role associated.
     */
    modifier onlyOperatorOrSystemOrRelay() {
        require(
            isOperator(msg.sender) || isSystem(msg.sender) || isRelay(msg.sender),
            "Operatorable: caller does not have the operator role nor system nor relay"
        );
        _;
    }

    /**
     * @dev Reverts if sender does not have the operator, or admin, or relay role associated.
     */
    modifier onlyOperatorOrAdminOrRelay() {
        require(
            isOperator(msg.sender) || isAdmin(msg.sender) || isRelay(msg.sender),
            "Operatorable: caller does not have the operator role nor admin nor relay"
        );
        _;
    }

    /**
     * @dev Initialization instead of constructor, called once. The setOperatorsContract function can be called only by Admin role with
     *       confirmation through the operators contract.
     * @param _baseOperators BaseOperators contract address.
     */
    function initialize(address _baseOperators) public initializer {
        _setOperatorsContract(_baseOperators);
    }

    /**
     * @dev Set the new the address of Operators contract, should be confirmed from operators contract by calling confirmFor(addr)
     *       where addr is the address of current contract instance. This is done to prevent the case when the new contract address is
     *       broken and control of the contract can be lost in such case
     * @param _baseOperators BaseOperators contract address.
     */
    function setOperatorsContract(address _baseOperators) public onlyAdmin {
        require(_baseOperators != address(0), "Operatorable: address of new operators contract can not be zero");
        operatorsPending = _baseOperators;
        emit OperatorsContractPending(msg.sender, _baseOperators);
    }

    /**
     * @dev The function should be called from new operators contract by admin to ensure that operatorsPending address
     *       is the real contract address.
     */
    function confirmOperatorsContract() public {
        require(operatorsPending != address(0), "Operatorable: address of new operators contract can not be zero");
        require(msg.sender == operatorsPending, "Operatorable: should be called from new operators contract");
        _setOperatorsContract(operatorsPending);
    }

    /**
     * @return The address of the BaseOperators contract.
     */
    function getOperatorsContract() public view returns (address) {
        return address(operatorsInst);
    }

    /**
     * @return The pending address of the BaseOperators contract.
     */
    function getOperatorsPending() public view returns (address) {
        return operatorsPending;
    }

    /**
     * @return If '_account' has operator privileges.
     */
    function isOperator(address _account) public view returns (bool) {
        return operatorsInst.isOperator(_account);
    }

    /**
     * @return If '_account' has admin privileges.
     */
    function isAdmin(address _account) public view returns (bool) {
        return operatorsInst.isAdmin(_account);
    }

    /**
     * @return If '_account' has system privileges.
     */
    function isSystem(address _account) public view returns (bool) {
        return operatorsInst.isSystem(_account);
    }

    /**
     * @return If '_account' has relay privileges.
     */
    function isRelay(address _account) public view returns (bool) {
        return operatorsInst.isRelay(_account);
    }

    /**
     * @return If '_contract' has multisig privileges.
     */
    function isMultisig(address _contract) public view returns (bool) {
        return operatorsInst.isMultisig(_contract);
    }

    /**
     * @return If '_account' has admin or system privileges.
     */
    function isAdminOrSystem(address _account) public view returns (bool) {
        return (operatorsInst.isAdmin(_account) || operatorsInst.isSystem(_account));
    }

    /**
     * @return If '_account' has operator or system privileges.
     */
    function isOperatorOrSystem(address _account) public view returns (bool) {
        return (operatorsInst.isOperator(_account) || operatorsInst.isSystem(_account));
    }

    /** INTERNAL FUNCTIONS */
    function _setOperatorsContract(address _baseOperators) internal {
        require(_baseOperators != address(0), "Operatorable: address of new operators contract cannot be zero");
        operatorsInst = IBaseOperators(_baseOperators);
        emit OperatorsContractChanged(msg.sender, _baseOperators);
    }
}


// File contracts/helpers/interface/IWhitelistable.sol

pragma solidity 0.5.12;

/**
 * @title IWhitelistable
 * @notice Interface for whitelistable contract.
 */
contract IWhitelistable {
    function confirmWhitelistContract() external;
}


// File contracts/helpers/Whitelist.sol

/**
 * @title Whitelist
 * @author Team 3301 <[email protected]>
 * @dev Whitelist contract with whitelist/unwhitelist functionality for particular addresses.  Whitelisting/unwhitelisting
 *      is controlled by operators/system/relays in Operatorable contract.
 */

pragma solidity 0.5.12;


contract Whitelist is Operatorable {
    mapping(address => bool) public whitelisted;

    event WhitelistToggled(address indexed account, bool whitelisted);

    /**
     * @dev Reverts if _account is not whitelisted.
     * @param _account address to determine if whitelisted.
     */
    modifier whenWhitelisted(address _account) {
        require(isWhitelisted(_account), "Whitelist: account is not whitelisted");
        _;
    }

    /**
     * @dev Reverts if address is empty.
     * @param _address address to validate.
     */
    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "Whitelist: invalid address");
        _;
    }

    /**
     * @dev Getter to determine if address is whitelisted.
     * @param _account address to determine if whitelisted or not.
     * @return bool is whitelisted
     */
    function isWhitelisted(address _account) public view returns (bool) {
        return whitelisted[_account];
    }

    /**
     * @dev Toggle whitelisted/unwhitelisted on _account address, with _toggled being true/false.
     * @param _account address to toggle.
     * @param _toggled whitelist/unwhitelist.
     */
    function toggleWhitelist(address _account, bool _toggled)
        public
        onlyValidAddress(_account)
        onlyOperatorOrSystemOrRelay
    {
        whitelisted[_account] = _toggled;
        emit WhitelistToggled(_account, whitelisted[_account]);
    }

    /**
     * @dev Batch whitelisted/unwhitelist multiple addresses, with _toggled being true/false.
     * @param _addresses address array.
     * @param _toggled whitelist/unwhitelist.
     */
    function batchToggleWhitelist(address[] memory _addresses, bool _toggled) public {
        require(_addresses.length <= 256, "Whitelist: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            toggleWhitelist(_addresses[i], _toggled);
        }
    }

    /**
     * @dev Confirms whitelist contract address once active.
     * @param _address Whitelistable contract addres.
     */
    function confirmFor(address _address) public onlyAdmin {
        require(_address != address(0), "Whitelist: address cannot be empty");
        IWhitelistable(_address).confirmWhitelistContract();
    }
}