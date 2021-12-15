pragma solidity ^0.4.24;

/**
 * @title BaseWallet
 * @dev Simple modular wallet that authorises modules to call its invoke() method.
 * Based on https://gist.github.com/Arachnid/a619d31f6d32757a4328a428286da186 by 
 * @author Julien Niset - <[email protected]>
 */
contract BaseWallet {

    // The implementation of the proxy
    address public implementation;
    // The owner 
    address public owner;
    // The authorised modules
    mapping (address => bool) public authorised;
    // The enabled static calls
    mapping (bytes4 => address) public enabled;
    // The number of modules
    uint public modules;
    
    event AuthorisedModule(address indexed module, bool value);
    event EnabledStaticCall(address indexed module, bytes4 indexed method);
    event Invoked(address indexed module, address indexed target, uint indexed value, bytes data);
    event Received(uint indexed value, address indexed sender, bytes data);
    event OwnerChanged(address owner);
    
    /**
     * @dev Throws if the sender is not an authorised module.
     */
    modifier moduleOnly {
        require(authorised[msg.sender], "BW: msg.sender not an authorized module");
        _;
    }

    /**
     * @dev Inits the wallet by setting the owner and authorising a list of modules.
     * @param _owner The owner.
     * @param _modules The modules to authorise.
     */
    function init(address _owner, address[] _modules) external {
        require(owner == address(0) && modules == 0, "BW: wallet already initialised");
        require(_modules.length > 0, "BW: construction requires at least 1 module");
        owner = _owner;
        modules = _modules.length;
        for(uint256 i = 0; i < _modules.length; i++) {
            require(authorised[_modules[i]] == false, "BW: module is already added");
            authorised[_modules[i]] = true;
            Module(_modules[i]).init(this);
            emit AuthorisedModule(_modules[i], true);
        }
    }
    
    /**
     * @dev Enables/Disables a module.
     * @param _module The target module.
     * @param _value Set to true to authorise the module.
     */
    function authoriseModule(address _module, bool _value) external moduleOnly {
        if (authorised[_module] != _value) {
            if(_value == true) {
                modules += 1;
                authorised[_module] = true;
                Module(_module).init(this);
            }
            else {
                modules -= 1;
                require(modules > 0, "BW: wallet must have at least one module");
                delete authorised[_module];
            }
            emit AuthorisedModule(_module, _value);
        }
    }

    /**
    * @dev Enables a static method by specifying the target module to which the call
    * must be delegated.
    * @param _module The target module.
    * @param _method The static method signature.
    */
    function enableStaticCall(address _module, bytes4 _method) external moduleOnly {
        require(authorised[_module], "BW: must be an authorised module for static call");
        enabled[_method] = _module;
        emit EnabledStaticCall(_module, _method);
    }

    /**
     * @dev Sets a new owner for the wallet.
     * @param _newOwner The new owner.
     */
    function setOwner(address _newOwner) external moduleOnly {
        require(_newOwner != address(0), "BW: address cannot be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
    
    /**
     * @dev Performs a generic transaction.
     * @param _target The address for the transaction.
     * @param _value The value of the transaction.
     * @param _data The data of the transaction.
     */
    function invoke(address _target, uint _value, bytes _data) external moduleOnly {
        // solium-disable-next-line security/no-call-value
        require(_target.call.value(_value)(_data), "BW: call to target failed");
        emit Invoked(msg.sender, _target, _value, _data);
    }

    /**
     * @dev This method makes it possible for the wallet to comply to interfaces expecting the wallet to
     * implement specific static methods. It delegates the static call to a target contract if the data corresponds 
     * to an enabled method, or logs the call otherwise.
     */
    function() public payable {
        if(msg.data.length > 0) { 
            address module = enabled[msg.sig];
            if(module == address(0)) {
                emit Received(msg.value, msg.sender, msg.data);
            } 
            else {
                require(authorised[module], "BW: must be an authorised module for static call");
                // solium-disable-next-line security/no-inline-assembly
                assembly {
                    calldatacopy(0, 0, calldatasize())
                    let result := staticcall(gas, module, 0, calldatasize(), 0, 0)
                    returndatacopy(0, 0, returndatasize())
                    switch result 
                    case 0 {revert(0, returndatasize())} 
                    default {return (0, returndatasize())}
                }
            }
        }
    }
}

/**
 * @title Module
 * @dev Interface for a module. 
 * A module MUST implement the addModule() method to ensure that a wallet with at least one module
 * can never end up in a "frozen" state.
 * @author Julien Niset - <[email protected]>
 */
interface Module {

    /**
     * @dev Inits a module for a wallet by e.g. setting some wallet specific parameters in storage.
     * @param _wallet The wallet.
     */
    function init(BaseWallet _wallet) external;

    /**
     * @dev Adds a module to a wallet.
     * @param _wallet The target wallet.
     * @param _module The modules to authorise.
     */
    function addModule(BaseWallet _wallet, Module _module) external;

    /**
    * @dev Utility method to recover any ERC20 token that was sent to the
    * module by mistake. 
    * @param _token The token to recover.
    */
    function recoverToken(address _token) external;
}

/**
 * @title Upgrader
 * @dev Interface for a contract that can upgrade wallets by enabling/disabling modules. 
 * @author Julien Niset - <[email protected]>
 */
interface Upgrader {

    /**
     * @dev Upgrades a wallet by enabling/disabling modules.
     * @param _wallet The owner.
     */
    function upgrade(address _wallet, address[] _toDisable, address[] _toEnable) external;

    function toDisable() external view returns (address[]);

    function toEnable() external view returns (address[]);
}

/**
 * @title Owned
 * @dev Basic contract to define an owner.
 * @author Julien Niset - <[email protected]>
 */
contract Owned {

    // The owner
    address public owner;

    event OwnerChanged(address indexed _newOwner);

    /**
     * @dev Throws if the sender is not the owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Lets the owner transfer ownership of the contract to a new owner.
     * @param _newOwner The new owner.
     */
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}

/**
 * ERC20 contract interface.
 */
contract ERC20 {
    function totalSupply() public view returns (uint);
    function decimals() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

/**
 * @title ModuleRegistry
 * @dev Registry of authorised modules. 
 * Modules must be registered before they can be authorised on a wallet.
 * @author Julien Niset - <[email protected]>
 */
contract ModuleRegistry is Owned {

    mapping (address => Info) internal modules;
    mapping (address => Info) internal upgraders;

    event ModuleRegistered(address indexed module, bytes32 name);
    event ModuleDeRegistered(address module);
    event UpgraderRegistered(address indexed upgrader, bytes32 name);
    event UpgraderDeRegistered(address upgrader);

    struct Info {
        bool exists;
        bytes32 name;
    }

    /**
     * @dev Registers a module.
     * @param _module The module.
     * @param _name The unique name of the module.
     */
    function registerModule(address _module, bytes32 _name) external onlyOwner {
        require(!modules[_module].exists, "MR: module already exists");
        modules[_module] = Info({exists: true, name: _name});
        emit ModuleRegistered(_module, _name);
    }

    /**
     * @dev Deregisters a module.
     * @param _module The module.
     */
    function deregisterModule(address _module) external onlyOwner {
        require(modules[_module].exists, "MR: module does not exists");
        delete modules[_module];
        emit ModuleDeRegistered(_module);
    }

        /**
     * @dev Registers an upgrader.
     * @param _upgrader The upgrader.
     * @param _name The unique name of the upgrader.
     */
    function registerUpgrader(address _upgrader, bytes32 _name) external onlyOwner {
        require(!upgraders[_upgrader].exists, "MR: upgrader already exists");
        upgraders[_upgrader] = Info({exists: true, name: _name});
        emit UpgraderRegistered(_upgrader, _name);
    }

    /**
     * @dev Deregisters an upgrader.
     * @param _upgrader The _upgrader.
     */
    function deregisterUpgrader(address _upgrader) external onlyOwner {
        require(upgraders[_upgrader].exists, "MR: upgrader does not exists");
        delete upgraders[_upgrader];
        emit UpgraderDeRegistered(_upgrader);
    }

    /**
    * @dev Utility method enbaling the owner of the registry to claim any ERC20 token that was sent to the
    * registry.
    * @param _token The token to recover.
    */
    function recoverToken(address _token) external onlyOwner {
        uint total = ERC20(_token).balanceOf(address(this));
        ERC20(_token).transfer(msg.sender, total);
    } 

    /**
     * @dev Gets the name of a module from its address.
     * @param _module The module address.
     * @return the name.
     */
    function moduleInfo(address _module) external view returns (bytes32) {
        return modules[_module].name;
    }

    /**
     * @dev Gets the name of an upgrader from its address.
     * @param _upgrader The upgrader address.
     * @return the name.
     */
    function upgraderInfo(address _upgrader) external view returns (bytes32) {
        return upgraders[_upgrader].name;
    }

    /**
     * @dev Checks if a module is registered.
     * @param _module The module address.
     * @return true if the module is registered.
     */
    function isRegisteredModule(address _module) external view returns (bool) {
        return modules[_module].exists;
    }

    /**
     * @dev Checks if a list of modules are registered.
     * @param _modules The list of modules address.
     * @return true if all the modules are registered.
     */
    function isRegisteredModule(address[] _modules) external view returns (bool) {
        for(uint i = 0; i < _modules.length; i++) {
            if (!modules[_modules[i]].exists) {
                return false;
            }
        }
        return true;
    }  

    /**
     * @dev Checks if an upgrader is registered.
     * @param _upgrader The upgrader address.
     * @return true if the upgrader is registered.
     */
    function isRegisteredUpgrader(address _upgrader) external view returns (bool) {
        return upgraders[_upgrader].exists;
    } 

}