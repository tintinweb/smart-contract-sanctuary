/**
 *Submitted for verification at polygonscan.com on 2021-07-07
*/

// File: contracts/helpers/interface/IWhitelist.sol

pragma solidity 0.5.12;

/**
 * @title IWhitelist
 * @notice Interface for Whitelist contract
 */
contract IWhitelist {
    function isWhitelisted(address _account) external view returns (bool);

    function toggleWhitelist(address _account, bool _toggled) external;
}

// File: contracts/role/interface/IBaseOperators.sol

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

// File: contracts/helpers/Initializable.sol

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

// File: contracts/role/base/Operatorable.sol

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

// File: contracts/role/interface/IRaiseOperators.sol

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

// File: contracts/role/interface/ITraderOperators.sol

/**
 * @title ITraderOperators
 * @notice Interface for TraderOperators contract
 */

pragma solidity 0.5.12;

contract ITraderOperators {
    function isTrader(address _account) external view returns (bool);

    function addTrader(address _account) external;

    function removeTrader(address _account) external;
}

// File: contracts/role/interface/IBlockerOperators.sol

/**
 * @title IBlockerOperators
 * @notice Interface for BlockerOperators contract
 */

pragma solidity 0.5.12;

contract IBlockerOperators {
    function isBlocker(address _account) external view returns (bool);

    function addBlocker(address _account) external;

    function removeBlocker(address _account) external;
}

// File: contracts/routers/OnboardRouter.sol

/**
 * @title OnboardRouter
 * @author Team 3301 <[email protected]>
 * @dev OnboardRouter contract, that allows one individual transaction to onboard a particular subset of users onto
 *      the Sygnum platform, instead of having to initiate X amount of transactions.
 */

pragma solidity 0.5.12;







contract OnboardRouter is Operatorable {
    IWhitelist internal whitelistInst;
    IRaiseOperators internal raiseOperatorsInst;
    ITraderOperators internal traderOperatorsInst;
    IBlockerOperators internal blockerOperatorsInst;

    event WhitelistContractChanged(address indexed caller, address indexed whitelistAddress);
    event BaseOperatorsContractChanged(address indexed caller, address indexed baseOperatorsAddress);
    event RaiseOperatorsContractChanged(address indexed caller, address indexed raiseOperatorsAddress);
    event TraderOperatorsContractChanged(address indexed caller, address indexed traderOperatorsAddress);
    event BlockerOperatorsContractChanged(address indexed caller, address indexed blockerOperatorsAddress);

    /**
     * @dev Initialization instead of constructor, called once. The setOperatorsContract function can be called only by Admin role with
     *       confirmation through the operators contract.
     * @param _baseOperators BaseOperators contract address.
     * @param _raiseOperators RaiseOperators contract address.
     * @param _traderOperators TraderOperators contract address.
     * @param _blockerOperators BlockerOperators contract address.
     */
    function initialize(
        address _whitelist,
        address _baseOperators,
        address _raiseOperators,
        address _traderOperators,
        address _blockerOperators
    ) public initializer {
        _setWhitelistContract(_whitelist);
        _setBaseOperatorsContract(_baseOperators);
        _setRaiseOperatorsContract(_raiseOperators);
        _setTraderOperatorsContract(_traderOperators);
        _setBlockerOperatorsContract(_blockerOperators);
    }

    /**
     * @dev Admin can give '_account' address system privileges, whitelist them on the shared whitelist contract, and the passed in whitelist address i.e. Equity Token, or the default whitelist.
     * @param _account address that should be given system privileges.
     * @param _whitelist Whitelist contract address.
     */
    function onboardSystem(address _account, address _whitelist) public onlyAdmin {
        _toggleWhitelist(_account, _whitelist, true);
        operatorsInst.addSystem(_account);
    }

    /**
     * @dev Admin can revoke '_account' address system privileges, de-whitelist them on the shared whitelist contract, and the passed in whitelist address i.e. Equity Token, or the default whitelist.
     * @param _account address that should be revoked system privileges.
     * @param _whitelist Whitelist contract address.
     */
    function deboardSystem(address _account, address _whitelist) public onlyAdmin {
        _toggleWhitelist(_account, _whitelist, false);
        operatorsInst.removeSystem(_account);
    }

    /**
     * @dev Admin can give '_account' address super admin privileges, whitelist them on the shared whitelist contract, and the passed in whitelist address i.e. Equity Token, or the default whitelist.
     * @param _account address that should be given super admin privileges.
     * @param _whitelist Whitelist contract address.
     */
    function onboardSuperAdmin(address _account, address _whitelist) public onlyAdmin {
        _toggleWhitelist(_account, _whitelist, true);
        operatorsInst.addOperatorAndAdmin(_account);
        traderOperatorsInst.addTrader(_account);
    }

    /**
     * @dev Admin can revoke '_account' address super admin privileges, de-whitelist them on the shared whitelist contract, and the passed in whitelist address i.e. Equity Token, or the default whitelist.
     * @param _account address that should be revoked super admin privileges.
     * @param _whitelist Whitelist contract address.
     */
    function deboardSuperAdmin(address _account, address _whitelist) public onlyAdmin {
        _toggleWhitelist(_account, _whitelist, false);
        operatorsInst.removeOperatorAndAdmin(_account);
        traderOperatorsInst.removeTrader(_account);
    }

    /**
     * @dev Operator or System can give '_account' address investor privileges, whitelist them on the shared whitelist contract, and the passed in whitelist address i.e. Equity Token, or the default whitelist.
     * @param _account address that should be given investor privileges.
     * @param _whitelist Whitelist contract address.
     */
    function onboardInvestor(address _account, address _whitelist) public onlyOperatorOrSystem {
        _toggleWhitelist(_account, _whitelist, true);
        raiseOperatorsInst.addInvestor(_account);
    }

    /**
     * @dev Operator or System can revoke '_account' address investor privileges, de-whitelist them on the shared whitelist contract, and the passed in whitelist address i.e. Equity Token, or the default whitelist.
     * @param _account address that should be revoked investor privileges.
     * @param _whitelist Whitelist contract address.
     */
    function deboardInvestor(address _account, address _whitelist) public onlyOperatorOrSystem {
        _toggleWhitelist(_account, _whitelist, false);
        raiseOperatorsInst.removeInvestor(_account);
    }

    /**
     * @dev Admin can give '_account' address trader privileges, whitelist them on the shared whitelist contract, and the passed in whitelist address i.e. Equity Token, or the default whitelist.
     * @param _account address that should be given trader privileges.
     * @param _whitelist Whitelist contract address.
     */
    function onboardTrader(address _account, address _whitelist) public onlyAdmin {
        _toggleWhitelist(_account, _whitelist, true);
        traderOperatorsInst.addTrader(_account);
    }

    /**
     * @dev Admin can revoke '_account' address trader privileges, de-whitelist them on the shared whitelist contract, and the passed in whitelist address i.e. Equity Token, or the default whitelist.
     * @param _account address that should be revoked trader privileges.
     * @param _whitelist Whitelist contract address.
     */
    function deboardTrader(address _account, address _whitelist) public onlyAdmin {
        _toggleWhitelist(_account, _whitelist, false);
        traderOperatorsInst.removeTrader(_account);
    }

    /**
     * @dev Admin can give '_account' address blocker privileges, whitelist them on the shared whitelist contract, and the passed in whitelist address i.e. Equity Token, or the default whitelist.
     * @param _account address that should be given blocker privileges.
     * @param _whitelist Whitelist contract address.
     */
    function onboardBlocker(address _account, address _whitelist) public onlyAdmin {
        _toggleWhitelist(_account, _whitelist, true);
        blockerOperatorsInst.addBlocker(_account);
    }

    /**
     * @dev Admin can revoke '_account' address blocker privileges, de-whitelist them on the shared whitelist contract, and the passed in whitelist address i.e. Equity Token, or the default whitelist.
     * @param _account address that should be revoked blocker privileges.
     * @param _whitelist Whitelist contract address.
     */
    function deboardBlocker(address _account, address _whitelist) public onlyAdmin {
        _toggleWhitelist(_account, _whitelist, false);
        blockerOperatorsInst.removeBlocker(_account);
    }

    /**
     * @dev Admin can change admin '_account' address to only trader privileges, whitelist them on the shared whitelist contract, and the passed in whitelist address i.e. Equity Token, or the default whitelist.
     * @param _account address that should be given trader privileges.
     * @param _whitelist Whitelist contract address.
     */
    function changeAdminToTrader(address _account, address _whitelist) public onlyAdmin {
        _toggleWhitelist(_account, _whitelist, true);
        operatorsInst.removeAdmin(_account);
        traderOperatorsInst.addTrader(_account);
    }

    /**
     * @dev Admin can change admin '_account' address to superAdmin privileges, whitelist them on the shared whitelist contract, and the passed in whitelist address i.e. Equity Token, or the default whitelist.
     * @param _account address that should be given trader privileges.
     * @param _whitelist Whitelist contract address.
     */
    function changeAdminToSuperAdmin(address _account, address _whitelist) public onlyAdmin {
        require(isAdmin(_account), "OnboardRouter: selected account does not have admin privileges");

        _toggleWhitelist(_account, _whitelist, true);
        operatorsInst.addOperator(_account);
        traderOperatorsInst.addTrader(_account);
    }

    /**
     * @dev Admin can change operator '_account' address to trader privileges, whitelist them on the shared whitelist contract, and the passed in whitelist address i.e. Equity Token, or the default whitelist.
     * @param _account address that should be given trader privileges.
     * @param _whitelist Whitelist contract address.
     */
    function changeOperatorToTrader(address _account, address _whitelist) public onlyAdmin {
        _toggleWhitelist(_account, _whitelist, true);
        operatorsInst.removeOperator(_account);
        traderOperatorsInst.addTrader(_account);
    }

    /**
     * @dev Admin can change operator '_account' address to superAdmin privileges, whitelist them on the shared whitelist contract, and the passed in whitelist address i.e. Equity Token, or the default whitelist.
     * @param _account address that should be given trader privileges.
     * @param _whitelist Whitelist contract address.
     */
    function changeOperatorToSuperAdmin(address _account, address _whitelist) public onlyAdmin {
        require(isOperator(_account), "OnboardRouter: selected account does not have operator privileges");

        _toggleWhitelist(_account, _whitelist, true);
        operatorsInst.addAdmin(_account);
        traderOperatorsInst.addTrader(_account);
    }

    /**
     * @dev Admin can change trader '_account' address to admin privileges, de-whitelist them on the shared whitelist contract, and the passed in whitelist address i.e. Equity Token, or the default whitelist.
     * @param _account address that should be given trader privileges.
     * @param _whitelist Whitelist contract address.
     */
    function changeTraderToAdmin(address _account, address _whitelist) public onlyAdmin {
        _toggleWhitelist(_account, _whitelist, false);
        operatorsInst.addAdmin(_account);
        traderOperatorsInst.removeTrader(_account);
    }

    /**
     * @dev Admin can change trader '_account' address to operator privileges, whitelist them on the shared whitelist contract, and the passed in whitelist address i.e. Equity Token, or the default whitelist.
     * @param _account address that should be given trader privileges.
     * @param _whitelist Whitelist contract address.
     */
    function changeTraderToOperator(address _account, address _whitelist) public onlyAdmin {
        _toggleWhitelist(_account, _whitelist, false);
        operatorsInst.addOperator(_account);
        traderOperatorsInst.removeTrader(_account);
    }

    /**
     * @dev Admin can change superadmin '_account' address to admin privileges, de-whitelist them on the shared whitelist contract, and the passed in whitelist address i.e. Equity Token, or the default whitelist.
     * @param _account address that should be given trader privileges.
     * @param _whitelist Whitelist contract address.
     */
    function changeSuperAdminToAdmin(address _account, address _whitelist) public onlyAdmin {
        require(isAdmin(_account), "OnboardRouter: account is not admin");
        _toggleWhitelist(_account, _whitelist, false);
        operatorsInst.removeOperator(_account);
        traderOperatorsInst.removeTrader(_account);
    }

    /**
     * @dev Admin can change superadmin '_account' address to operator privileges, de-whitelist them on the shared whitelist contract, and the passed in whitelist address i.e. Equity Token, or the default whitelist.
     * @param _account address that should be given trader privileges.
     * @param _whitelist Whitelist contract address.
     */
    function changeSuperAdminToOperator(address _account, address _whitelist) public onlyAdmin {
        require(isAdmin(_account), "OnboardRouter: account is not admin");
        _toggleWhitelist(_account, _whitelist, false);
        operatorsInst.removeAdmin(_account);
        traderOperatorsInst.removeTrader(_account);
    }

    /**
     * @dev Change address of Whitelist contract.
     * @param _whitelist Whitelist contract address.
     */
    function changeWhitelistContract(address _whitelist) public onlyAdmin {
        _setWhitelistContract(_whitelist);
    }

    /**
     * @dev Change address of BaseOperators contract.
     * @param _baseOperators BaseOperators contract address.
     */
    function changeBaseOperatorsContract(address _baseOperators) public onlyAdmin {
        _setBaseOperatorsContract(_baseOperators);
    }

    /**
     * @dev Change address of RaiseOperators contract.
     * @param _raiseOperators RaiseOperators contract address.
     */
    function changeRaiseOperatorsContract(address _raiseOperators) public onlyAdmin {
        _setRaiseOperatorsContract(_raiseOperators);
    }

    /**
     * @dev Change address of TraderOperators contract.
     * @param _traderOperators TraderOperators contract address.
     */
    function changeTraderOperatorsContract(address _traderOperators) public onlyAdmin {
        _setTraderOperatorsContract(_traderOperators);
    }

    /**
     * @dev Change address of BlockerOperators contract.
     * @param _blockerOperators BlockerOperators contract address.
     */
    function changeBlockerOperatorsContract(address _blockerOperators) public onlyAdmin {
        _setBlockerOperatorsContract(_blockerOperators);
    }

    /**
     * @return Stored address of the Whitelist contract.
     */
    function getWhitelistContract() public view returns (address) {
        return address(whitelistInst);
    }

    /**
     * @return Stored address of the BaseOperators contract.
     */
    function getBaseOperatorsContract() public view returns (address) {
        return address(operatorsInst);
    }

    /**
     * @return Stored address of the RaiseOperators contract.
     */
    function getRaiseOperatorsContract() public view returns (address) {
        return address(raiseOperatorsInst);
    }

    /**
     * @return Stored address of the TraderOperators contract.
     */
    function getTraderOperatorsContract() public view returns (address) {
        return address(traderOperatorsInst);
    }

    /**
     * @return Stored address of the BlockerOperators contract.
     */
    function getBlockerOperatorsContract() public view returns (address) {
        return address(blockerOperatorsInst);
    }

    /** INTERNAL FUNCTIONS */
    function _toggleWhitelist(
        address _account,
        address _whitelist,
        bool _toggle
    ) internal {
        whitelistInst.toggleWhitelist(_account, _toggle);
        if (_whitelist != address(0)) {
            _toggleSecondaryWhitelist(_account, _whitelist, _toggle); // non-default
        }
    }

    function _toggleSecondaryWhitelist(
        address _account,
        address _whitelist,
        bool _toggle
    ) internal {
        IWhitelist(_whitelist).toggleWhitelist(_account, _toggle);
    }

    function _setWhitelistContract(address _whitelist) internal {
        require(_whitelist != address(0), "OnboardRouter: address of new whitelist contract cannot be zero");
        whitelistInst = IWhitelist(_whitelist);
        emit WhitelistContractChanged(msg.sender, _whitelist);
    }

    function _setBaseOperatorsContract(address _baseOperators) internal {
        require(_baseOperators != address(0), "OnboardRouter: address of new baseOperators contract cannot be zero");
        operatorsInst = IBaseOperators(_baseOperators);
        emit BaseOperatorsContractChanged(msg.sender, _baseOperators);
    }

    function _setRaiseOperatorsContract(address _raiseOperators) internal {
        require(_raiseOperators != address(0), "OnboardRouter: address of new raiseOperators contract cannot be zero");
        raiseOperatorsInst = IRaiseOperators(_raiseOperators);
        emit RaiseOperatorsContractChanged(msg.sender, _raiseOperators);
    }

    function _setTraderOperatorsContract(address _traderOperators) internal {
        require(
            _traderOperators != address(0),
            "OnboardRouter: address of new traderOperators contract cannot be zero"
        );
        traderOperatorsInst = ITraderOperators(_traderOperators);
        emit TraderOperatorsContractChanged(msg.sender, _traderOperators);
    }

    function _setBlockerOperatorsContract(address _blockerOperators) internal {
        require(
            _blockerOperators != address(0),
            "OnboardRouter: address of new blockerOperators contract cannot be zero"
        );
        blockerOperatorsInst = IBlockerOperators(_blockerOperators);
        emit BlockerOperatorsContractChanged(msg.sender, _blockerOperators);
    }
}