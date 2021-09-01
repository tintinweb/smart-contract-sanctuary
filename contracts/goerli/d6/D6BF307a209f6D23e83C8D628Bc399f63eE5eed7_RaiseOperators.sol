/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// Sources flattened with hardhat v2.4.0 https://hardhat.org

// File openzeppelin-solidity/contracts/access/[email protected]

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


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


// File contracts/role/interface/IRaiseOperators.sol

/**
 * @title IRaiseOperators
 * @notice Interface for RaiseOperators contract
 */

pragma solidity 0.5.12;

contract IRaiseOperators {
    function isInvestor(address _account) external view returns (bool);

    function isIssuer(address _account) external view returns (bool);

    function addInvestor(address _account) external;

    function removeInvestor(address _account) external;

    function addIssuer(address _account) external;

    function removeIssuer(address _account) external;
}


// File contracts/role/raise/RaiseOperatorable.sol

/**
 * @title RaiseOperatorable
 * @author Team 3301 <[email protected]>
 * @dev RaiseOperatorable contract stores RaiseOperators contract address, and modifiers for
 *      contracts.
 */

pragma solidity 0.5.12;



contract RaiseOperatorable is Operatorable {
    IRaiseOperators internal raiseOperatorsInst;
    address private raiseOperatorsPending;

    event RaiseOperatorsContractChanged(address indexed caller, address indexed raiseOperatorsAddress);
    event RaiseOperatorsContractPending(address indexed caller, address indexed raiseOperatorsAddress);

    /**
     * @dev Reverts if sender does not have the investor role associated.
     */
    modifier onlyInvestor() {
        require(isInvestor(msg.sender), "RaiseOperatorable: caller is not investor");
        _;
    }

    /**
     * @dev Reverts if sender does not have the issuer role associated.
     */
    modifier onlyIssuer() {
        require(isIssuer(msg.sender), "RaiseOperatorable: caller is not issuer");
        _;
    }

    /**
     * @dev Initialization instead of constructor, called once. The setOperatorsContract function can be called only by Admin role with
     * confirmation through the operators contract.
     * @param _baseOperators BaseOperators contract address.
     */
    function initialize(address _baseOperators, address _raiseOperators) public initializer {
        super.initialize(_baseOperators);
        _setRaiseOperatorsContract(_raiseOperators);
    }

    /**
     * @dev Set the new the address of Operators contract, should be confirmed from operators contract by calling confirmFor(addr)
     * where addr is the address of current contract instance. This is done to prevent the case when the new contract address is
     *broken and control of the contract can be lost in such case
     * @param _raiseOperators RaiseOperators contract address.
     */
    function setRaiseOperatorsContract(address _raiseOperators) public onlyAdmin {
        require(
            _raiseOperators != address(0),
            "RaiseOperatorable: address of new raiseOperators contract can not be zero"
        );
        raiseOperatorsPending = _raiseOperators;
        emit RaiseOperatorsContractPending(msg.sender, _raiseOperators);
    }

    /**
     * @dev The function should be called from new operators contract by admin to insure that operatorsPending address
     *       is the real contract address.
     */
    function confirmRaiseOperatorsContract() public {
        require(
            raiseOperatorsPending != address(0),
            "RaiseOperatorable: address of pending raiseOperators contract can not be zero"
        );
        require(
            msg.sender == raiseOperatorsPending,
            "RaiseOperatorable: should be called from new raiseOperators contract"
        );
        _setRaiseOperatorsContract(raiseOperatorsPending);
    }

    /**
     * @return The address of the RaiseOperators contract.
     */
    function getRaiseOperatorsContract() public view returns (address) {
        return address(raiseOperatorsInst);
    }

    /**
     * @return The pending RaiseOperators contract address
     */
    function getRaiseOperatorsPending() public view returns (address) {
        return raiseOperatorsPending;
    }

    /**
     * @return If '_account' has investor privileges.
     */
    function isInvestor(address _account) public view returns (bool) {
        return raiseOperatorsInst.isInvestor(_account);
    }

    /**
     * @return If '_account' has issuer privileges.
     */
    function isIssuer(address _account) public view returns (bool) {
        return raiseOperatorsInst.isIssuer(_account);
    }

    /** INTERNAL FUNCTIONS */
    function _setRaiseOperatorsContract(address _raiseOperators) internal {
        require(
            _raiseOperators != address(0),
            "RaiseOperatorable: address of new raiseOperators contract can not be zero"
        );
        raiseOperatorsInst = IRaiseOperators(_raiseOperators);
        emit RaiseOperatorsContractChanged(msg.sender, _raiseOperators);
    }
}


// File contracts/role/raise/RaiseOperators.sol

/**
 * @title RaiseOperators
 * @author Team 3301 <[email protected]>
 * @dev For managing account privileges associated to the capital raise process: investors, and issuers.
 */

pragma solidity 0.5.12;



contract RaiseOperators is Operatorable {
    using Roles for Roles.Role;

    Roles.Role private _investors;
    Roles.Role private _issuers;

    event InvestorAdded(address indexed caller, address indexed account);
    event InvestorRemoved(address indexed caller, address indexed account);
    event IssuerAdded(address indexed caller, address indexed account);
    event IssuerRemoved(address indexed caller, address indexed account);

    /**
     * @dev Confirms RaiseOperator contract address once acive.
     * @param _address Address of RaiseOperators contract.
     */
    function confirmFor(address _address) public onlyAdmin {
        RaiseOperatorable(_address).confirmRaiseOperatorsContract();
    }

    /* --------------- INVESTOR --------------- */
    /**
     * @return If '_account' has investor privileges.
     */
    function isInvestor(address _account) public view returns (bool) {
        return _investors.has(_account);
    }

    /**
     * @dev Operator or relay can give '_account' address investor privileges if the contract is not paused.
     * @param _account address that should be given investor privileges.
     */
    function addInvestor(address _account) public onlyOperatorOrRelay {
        _addInvestor(_account);
    }

    /**
     * @dev Operator or relay can revoke '_account' address investor privileges if the contract is not paused.
     * @param _account address that should be revoked investor privileges.
     */
    function removeInvestor(address _account) public onlyOperatorOrRelay {
        _removeInvestor(_account);
    }

    /* --------------- ISSUER --------------- */
    /**
     * @return If '_account' has issuer privileges.
     */
    function isIssuer(address _account) public view returns (bool) {
        return _issuers.has(_account);
    }

    /**
     * @dev Operator/Admin can give '_account' address issuer privileges if the contract is not paused.
     * @param _account address that should be given issuer privileges.
     */
    function addIssuer(address _account) public onlyOperator {
        _addIssuer(_account);
    }

    /**
     * @dev Operator/Admin can revoke '_account' address issuer privileges if the contract is not paused.
     * @param _account address that should be revoked issuer privileges.
     */
    function removeIssuer(address _account) public onlyOperator {
        _removeIssuer(_account);
    }

    /* --------------- INTERNAL --------------- */
    function _addInvestor(address _account) internal {
        _investors.add(_account);
        emit InvestorAdded(msg.sender, _account);
    }

    function _removeInvestor(address _account) internal {
        _investors.remove(_account);
        emit InvestorRemoved(msg.sender, _account);
    }

    function _addIssuer(address _account) internal {
        _issuers.add(_account);
        emit IssuerAdded(msg.sender, _account);
    }

    function _removeIssuer(address _account) internal {
        _issuers.remove(_account);
        emit IssuerRemoved(msg.sender, _account);
    }
}