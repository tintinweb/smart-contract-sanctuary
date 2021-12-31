/**
 *Submitted for verification at Etherscan.io on 2021-12-31
*/

/**
 *Submitted for verification at Etherscan.io on 2020-05-28
*/

pragma solidity ^0.5.4;

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
    function init(address _owner, address[] calldata _modules) external {
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
        if (address(this).balance > 0) {
            emit Received(address(this).balance, address(0), "");
        }
    }
    
    /**
     * @dev Enables/Disables a module.
     * @param _module The target module.
     * @param _value Set to true to authorise the module.
     */
    function authoriseModule(address _module, bool _value) external moduleOnly {
        if (authorised[_module] != _value) {
            emit AuthorisedModule(_module, _value);
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
    function invoke(address _target, uint _value, bytes calldata _data) external moduleOnly returns (bytes memory _result) {
        bool success;
        // solium-disable-next-line security/no-call-value
        (success, _result) = _target.call.value(_value)(_data);
        if(!success) {
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize)
                revert(0, returndatasize)
            }
        }
        emit Invoked(msg.sender, _target, _value, _data);
    }

    /**
     * @dev This method makes it possible for the wallet to comply to interfaces expecting the wallet to
     * implement specific static methods. It delegates the static call to a target contract if the data corresponds
     * to an enabled method, or logs the call otherwise.
     */
    function() external payable {
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
        require(modules[_module].exists, "MR: module does not exist");
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
        require(upgraders[_upgrader].exists, "MR: upgrader does not exist");
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
    function isRegisteredModule(address[] calldata _modules) external view returns (bool) {
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




/**
 * @title BaseModule
 * @dev Basic module that contains some methods common to all modules.
 * @author Julien Niset - <[email protected]>
 */
contract BaseModule is Module {

    // The adddress of the module registry.
    ModuleRegistry internal registry;

    event ModuleCreated(bytes32 name);
    event ModuleInitialised(address wallet);

    constructor(ModuleRegistry _registry, bytes32 _name) public {
        registry = _registry;
        emit ModuleCreated(_name);
    }

    /**
     * @dev Throws if the sender is not the target wallet of the call.
     */
    modifier onlyWallet(BaseWallet _wallet) {
        require(msg.sender == address(_wallet), "BM: caller must be wallet");
        _;
    }

    /**
     * @dev Throws if the sender is not the owner of the target wallet or the module itself.
     */
    modifier onlyWalletOwner(BaseWallet _wallet) {
        require(msg.sender == address(this) || isOwner(_wallet, msg.sender), "BM: must be an owner for the wallet");
        _;
    }

    /**
     * @dev Throws if the sender is not the owner of the target wallet.
     */
    modifier strictOnlyWalletOwner(BaseWallet _wallet) {
        require(isOwner(_wallet, msg.sender), "BM: msg.sender must be an owner for the wallet");
        _;
    }

    /**
     * @dev Inits the module for a wallet by logging an event.
     * The method can only be called by the wallet itself.
     * @param _wallet The wallet.
     */
    function init(BaseWallet _wallet) public onlyWallet(_wallet) {
        emit ModuleInitialised(address(_wallet));
    }

    /**
     * @dev Adds a module to a wallet. First checks that the module is registered.
     * @param _wallet The target wallet.
     * @param _module The modules to authorise.
     */
    function addModule(BaseWallet _wallet, Module _module) external strictOnlyWalletOwner(_wallet) {
        require(registry.isRegisteredModule(address(_module)), "BM: module is not registered");
        _wallet.authoriseModule(address(_module), true);
    }

    /**
    * @dev Utility method enbaling anyone to recover ERC20 token sent to the
    * module by mistake and transfer them to the Module Registry. 
    * @param _token The token to recover.
    */
    function recoverToken(address _token) external {
        uint total = ERC20(_token).balanceOf(address(this));
        ERC20(_token).transfer(address(registry), total);
    }

    /**
     * @dev Helper method to check if an address is the owner of a target wallet.
     * @param _wallet The target wallet.
     * @param _addr The address.
     */
    function isOwner(BaseWallet _wallet, address _addr) internal view returns (bool) {
        return _wallet.owner() == _addr;
    }

    /**
     * @dev Helper method to invoke a wallet.
     * @param _wallet The target wallet.
     * @param _to The target address for the transaction.
     * @param _value The value of the transaction.
     * @param _data The data of the transaction.
     */
    function invokeWallet(address _wallet, address _to, uint256 _value, bytes memory _data) internal returns (bytes memory _res) {
        bool success;
        // solium-disable-next-line security/no-call-value
        (success, _res) = _wallet.call(abi.encodeWithSignature("invoke(address,uint256,bytes)", _to, _value, _data));
        if(success && _res.length > 0) { //_res is empty if _wallet is an "old" BaseWallet that can't return output values
            (_res) = abi.decode(_res, (bytes));
        } else if (_res.length > 0) {
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize)
                revert(0, returndatasize)
            }
        } else if(!success) {
            revert("BM: wallet invoke reverted");
        }
    }
}



/**
 * @title RelayerModule
 * @dev Base module containing logic to execute transactions signed by eth-less accounts and sent by a relayer. 
 * @author Julien Niset - <[email protected]>
 */
contract RelayerModule is Module {

    uint256 constant internal BLOCKBOUND = 10000;

    mapping (address => RelayerConfig) public relayer; 

    struct RelayerConfig {
        uint256 nonce;
        mapping (bytes32 => bool) executedTx;
    }

    event TransactionExecuted(address indexed wallet, bool indexed success, bytes32 signedHash);

    /**
     * @dev Throws if the call did not go through the execute() method.
     */
    modifier onlyExecute {
        require(msg.sender == address(this), "RM: must be called via execute()");
        _;
    }

    /* ***************** Abstract method ************************* */

    /**
    * @dev Gets the number of valid signatures that must be provided to execute a
    * specific relayed transaction.
    * @param _wallet The target wallet.
    * @param _data The data of the relayed transaction.
    * @return The number of required signatures.
    */
    function getRequiredSignatures(BaseWallet _wallet, bytes memory _data) internal view returns (uint256);

    /**
    * @dev Validates the signatures provided with a relayed transaction.
    * The method MUST throw if one or more signatures are not valid.
    * @param _wallet The target wallet.
    * @param _data The data of the relayed transaction.
    * @param _signHash The signed hash representing the relayed transaction.
    * @param _signatures The signatures as a concatenated byte array.
    */
    function validateSignatures(BaseWallet _wallet, bytes memory _data, bytes32 _signHash, bytes memory _signatures) internal view returns (bool);

    /* ************************************************************ */

    /**
    * @dev Executes a relayed transaction.
    * @param _wallet The target wallet.
    * @param _data The data for the relayed transaction
    * @param _nonce The nonce used to prevent replay attacks.
    * @param _signatures The signatures as a concatenated byte array.
    * @param _gasPrice The gas price to use for the gas refund.
    * @param _gasLimit The gas limit to use for the gas refund.
    */
    function execute(
        BaseWallet _wallet,
        bytes calldata _data,
        uint256 _nonce,
        bytes calldata _signatures,
        uint256 _gasPrice,
        uint256 _gasLimit
    )
        external
        returns (bool success)
    {
        uint startGas = gasleft();
        bytes32 signHash = getSignHash(address(this), address(_wallet), 0, _data, _nonce, _gasPrice, _gasLimit);
        require(checkAndUpdateUniqueness(_wallet, _nonce, signHash), "RM: Duplicate request");
        require(verifyData(address(_wallet), _data), "RM: the wallet authorized is different then the target of the relayed data");
        uint256 requiredSignatures = getRequiredSignatures(_wallet, _data);
        if((requiredSignatures * 65) == _signatures.length) {
            if(verifyRefund(_wallet, _gasLimit, _gasPrice, requiredSignatures)) {
                if(requiredSignatures == 0 || validateSignatures(_wallet, _data, signHash, _signatures)) {
                    // solium-disable-next-line security/no-call-value
                    (success,) = address(this).call(_data);
                    refund(_wallet, startGas - gasleft(), _gasPrice, _gasLimit, requiredSignatures, msg.sender);
                }
            }
        }
        emit TransactionExecuted(address(_wallet), success, signHash);
    }

    /**
    * @dev Gets the current nonce for a wallet.
    * @param _wallet The target wallet.
    */
    function getNonce(BaseWallet _wallet) external view returns (uint256 nonce) {
        return relayer[address(_wallet)].nonce;
    }

    /**
    * @dev Generates the signed hash of a relayed transaction according to ERC 1077.
    * @param _from The starting address for the relayed transaction (should be the module)
    * @param _to The destination address for the relayed transaction (should be the wallet)
    * @param _value The value for the relayed transaction
    * @param _data The data for the relayed transaction
    * @param _nonce The nonce used to prevent replay attacks.
    * @param _gasPrice The gas price to use for the gas refund.
    * @param _gasLimit The gas limit to use for the gas refund.
    */
    function getSignHash(
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data,
        uint256 _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(byte(0x19), byte(0), _from, _to, _value, _data, _nonce, _gasPrice, _gasLimit))
        ));
    }

    /**
    * @dev Checks if the relayed transaction is unique.
    * @param _wallet The target wallet.
    * @param _nonce The nonce
    * @param _signHash The signed hash of the transaction
    */
    function checkAndUpdateUniqueness(BaseWallet _wallet, uint256 _nonce, bytes32 _signHash) internal returns (bool) {
        if(relayer[address(_wallet)].executedTx[_signHash] == true) {
            return false;
        }
        relayer[address(_wallet)].executedTx[_signHash] = true;
        return true;
    }

    /**
    * @dev Checks that a nonce has the correct format and is valid.
    * It must be constructed as nonce = {block number}{timestamp} where each component is 16 bytes.
    * @param _wallet The target wallet.
    * @param _nonce The nonce
    */
    function checkAndUpdateNonce(BaseWallet _wallet, uint256 _nonce) internal returns (bool) {
        if(_nonce <= relayer[address(_wallet)].nonce) {
            return false;
        }
        uint256 nonceBlock = (_nonce & 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000) >> 128;
        if(nonceBlock > block.number + BLOCKBOUND) {
            return false;
        }
        relayer[address(_wallet)].nonce = _nonce;
        return true;
    }

    /**
    * @dev Recovers the signer at a given position from a list of concatenated signatures.
    * @param _signedHash The signed hash
    * @param _signatures The concatenated signatures.
    * @param _index The index of the signature to recover.
    */
    function recoverSigner(bytes32 _signedHash, bytes memory _signatures, uint _index) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(_signatures, add(0x20,mul(0x41,_index))))
            s := mload(add(_signatures, add(0x40,mul(0x41,_index))))
            v := and(mload(add(_signatures, add(0x41,mul(0x41,_index)))), 0xff)
        }
        require(v == 27 || v == 28);
        return ecrecover(_signedHash, v, r, s);
    }

    /**
    * @dev Refunds the gas used to the Relayer. 
    * For security reasons the default behavior is to not refund calls with 0 or 1 signatures. 
    * @param _wallet The target wallet.
    * @param _gasUsed The gas used.
    * @param _gasPrice The gas price for the refund.
    * @param _gasLimit The gas limit for the refund.
    * @param _signatures The number of signatures used in the call.
    * @param _relayer The address of the Relayer.
    */
    function refund(BaseWallet _wallet, uint _gasUsed, uint _gasPrice, uint _gasLimit, uint _signatures, address _relayer) internal {
        uint256 amount = 29292 + _gasUsed; // 21000 (transaction) + 7620 (execution of refund) + 672 to log the event + _gasUsed
        // only refund if gas price not null, more than 1 signatures, gas less than gasLimit
        if(_gasPrice > 0 && _signatures > 1 && amount <= _gasLimit) {
            if(_gasPrice > tx.gasprice) {
                amount = amount * tx.gasprice;
            }
            else {
                amount = amount * _gasPrice;
            }
            _wallet.invoke(_relayer, amount, "");
        }
    }

    /**
    * @dev Returns false if the refund is expected to fail.
    * @param _wallet The target wallet.
    * @param _gasUsed The expected gas used.
    * @param _gasPrice The expected gas price for the refund.
    */
    function verifyRefund(BaseWallet _wallet, uint _gasUsed, uint _gasPrice, uint _signatures) internal view returns (bool) {
        if(_gasPrice > 0
            && _signatures > 1
            && (address(_wallet).balance < _gasUsed * _gasPrice || _wallet.authorised(address(this)) == false)) {
            return false;
        }
        return true;
    }

    /**
    * @dev Checks that the wallet address provided as the first parameter of the relayed data is the same
    * as the wallet passed as the input of the execute() method. 
    @return false if the addresses are different.
    */
    function verifyData(address _wallet, bytes memory _data) private pure returns (bool) {
        require(_data.length >= 36, "RM: Invalid dataWallet");
        address dataWallet;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            //_data = {length:32}{sig:4}{_wallet:32}{...}
            dataWallet := mload(add(_data, 0x24))
        }
        return dataWallet == _wallet;
    }

    /**
    * @dev Parses the data to extract the method signature.
    */
    function functionPrefix(bytes memory _data) internal pure returns (bytes4 prefix) {
        require(_data.length >= 4, "RM: Invalid functionPrefix");
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            prefix := mload(add(_data, 0x20))
        }
    }
}



/**
 * @title OnlyOwnerModule
 * @dev Module that extends BaseModule and RelayerModule for modules where the execute() method
 * must be called with one signature frm the owner.
 * @author Julien Niset - <[email protected]>
 */
contract OnlyOwnerModule is BaseModule, RelayerModule {

    // bytes4 private constant IS_ONLY_OWNER_MODULE = bytes4(keccak256("isOnlyOwnerModule()"));

   /**
    * @dev Returns a constant that indicates that the module is an OnlyOwnerModule.
    * @return The constant bytes4(keccak256("isOnlyOwnerModule()"))
    */
    function isOnlyOwnerModule() external pure returns (bytes4) {
        // return IS_ONLY_OWNER_MODULE;
        return this.isOnlyOwnerModule.selector;
    }

    /**
     * @dev Adds a module to a wallet. First checks that the module is registered.
     * Unlike its overrided parent, this method can be called via the RelayerModule's execute()
     * @param _wallet The target wallet.
     * @param _module The modules to authorise.
     */
    function addModule(BaseWallet _wallet, Module _module) external onlyWalletOwner(_wallet) {
        require(registry.isRegisteredModule(address(_module)), "BM: module is not registered");
        _wallet.authoriseModule(address(_module), true);
    }

    // *************** Implementation of RelayerModule methods ********************* //

    // Overrides to use the incremental nonce and save some gas
    function checkAndUpdateUniqueness(BaseWallet _wallet, uint256 _nonce, bytes32 /* _signHash */) internal returns (bool) {
        return checkAndUpdateNonce(_wallet, _nonce);
    }

    function validateSignatures(
        BaseWallet _wallet,
        bytes memory /* _data */,
        bytes32 _signHash,
        bytes memory _signatures
    )
        internal
        view
        returns (bool)
    {
        address signer = recoverSigner(_signHash, _signatures, 0);
        return isOwner(_wallet, signer); // "OOM: signer must be owner"
    }

    function getRequiredSignatures(BaseWallet /* _wallet */, bytes memory /* _data */) internal view returns (uint256) {
        return 1;
    }
}

/**
 * @title BaseTransfer
 * @dev Module containing internal methods to execute or approve transfers
 * @author Olivier VDB - <[email protected]>
 */
contract BaseTransfer is BaseModule {

    // Empty calldata
    bytes constant internal EMPTY_BYTES = "";
    // Mock token address for ETH
    address constant internal ETH_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // *************** Events *************************** //

    event Transfer(address indexed wallet, address indexed token, uint256 indexed amount, address to, bytes data);
    event Approved(address indexed wallet, address indexed token, uint256 amount, address spender);
    event CalledContract(address indexed wallet, address indexed to, uint256 amount, bytes data);

    // *************** Internal Functions ********************* //

    /**
    * @dev Helper method to transfer ETH or ERC20 for a wallet.
    * @param _wallet The target wallet.
    * @param _token The ERC20 address.
    * @param _to The recipient.
    * @param _value The amount of ETH to transfer
    * @param _data The data to *log* with the transfer.
    */
    function doTransfer(BaseWallet _wallet, address _token, address _to, uint256 _value, bytes memory _data) internal {
        if(_token == ETH_TOKEN) {
            invokeWallet(address(_wallet), _to, _value, EMPTY_BYTES);
        }
        else {
            bytes memory methodData = abi.encodeWithSignature("transfer(address,uint256)", _to, _value);
            invokeWallet(address(_wallet), _token, 0, methodData);
        }
        emit Transfer(address(_wallet), _token, _value, _to, _data);
    }

    /**
    * @dev Helper method to approve spending the ERC20 of a wallet.
    * @param _wallet The target wallet.
    * @param _token The ERC20 address.
    * @param _spender The spender address.
    * @param _value The amount of token to transfer.
    */
    function doApproveToken(BaseWallet _wallet, address _token, address _spender, uint256 _value) internal {
        bytes memory methodData = abi.encodeWithSignature("approve(address,uint256)", _spender, _value);
        invokeWallet(address(_wallet), _token, 0, methodData);
        emit Approved(address(_wallet), _token, _value, _spender);
    }

    /**
    * @dev Helper method to call an external contract.
    * @param _wallet The target wallet.
    * @param _contract The contract address.
    * @param _value The ETH value to transfer.
    * @param _data The method data.
    */
    function doCallContract(BaseWallet _wallet, address _contract, uint256 _value, bytes memory _data) internal {
        invokeWallet(address(_wallet), _contract, _value, _data);
        emit CalledContract(address(_wallet), _contract, _value, _data);
    }
}


/* The MIT License (MIT)

Copyright (c) 2016 Smart Contract Solutions, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }

    /**
    * @dev Returns ceil(a / b).
    */
    function ceil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        if(a % b == 0) {
            return c;
        }
        else {
            return c + 1;
        }
    }

    // from DSMath - operations on fixed precision floats

    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }
}




/**
 * @title LimitManager
 * @dev Module to transfer tokens (ETH or ERC20) based on a security context (daily limit, whitelist, etc).
 * @author Julien Niset - <[email protected]>
 */
contract LimitManager is BaseModule {

    // large limit when the limit can be considered disabled
    uint128 constant internal LIMIT_DISABLED = uint128(-1); // 3.40282366920938463463374607431768211455e+38

    using SafeMath for uint256;

    struct LimitManagerConfig {
        // The global limit
        Limit limit;
        // whitelist
        DailySpent dailySpent;
    } 

    struct Limit {
        // the current limit
        uint128 current;
        // the pending limit if any
        uint128 pending;
        // when the pending limit becomes the current limit
        uint64 changeAfter;
    }

    struct DailySpent {
        // The amount already spent during the current period
        uint128 alreadySpent;
        // The end of the current period
        uint64 periodEnd;
    }

    // wallet specific storage
    mapping (address => LimitManagerConfig) internal limits;
    // The default limit
    uint256 public defaultLimit;

    // *************** Events *************************** //

    event LimitChanged(address indexed wallet, uint indexed newLimit, uint64 indexed startAfter);

    // *************** Constructor ********************** //

    constructor(uint256 _defaultLimit) public {
        defaultLimit = _defaultLimit;
    }

    // *************** External/Public Functions ********************* //

    /**
     * @dev Inits the module for a wallet by setting the limit to the default value.
     * @param _wallet The target wallet.
     */
    function init(BaseWallet _wallet) public onlyWallet(_wallet) {
        Limit storage limit = limits[address(_wallet)].limit;
        if(limit.current == 0 && limit.changeAfter == 0) {
            limit.current = uint128(defaultLimit);
        }
    }

    /**
     * @dev Changes the global limit. 
     * The limit is expressed in ETH and the change is pending for the security period.
     * @param _wallet The target wallet.
     * @param _newLimit The new limit.
     * @param _securityPeriod The security period.
     */
    function changeLimit(BaseWallet _wallet, uint256 _newLimit, uint256 _securityPeriod) internal {
        Limit storage limit = limits[address(_wallet)].limit;
        // solium-disable-next-line security/no-block-members
        uint128 currentLimit = (limit.changeAfter > 0 && limit.changeAfter < now) ? limit.pending : limit.current;
        limit.current = currentLimit;
        limit.pending = uint128(_newLimit);
        // solium-disable-next-line security/no-block-members
        limit.changeAfter = uint64(now.add(_securityPeriod));
        // solium-disable-next-line security/no-block-members
        emit LimitChanged(address(_wallet), _newLimit, uint64(now.add(_securityPeriod)));
    }

    // *************** Internal Functions ********************* //

    /**
    * @dev Gets the current global limit for a wallet.
    * @param _wallet The target wallet.
    * @return the current limit expressed in ETH.
    */
    function getCurrentLimit(BaseWallet _wallet) public view returns (uint256 _currentLimit) {
        Limit storage limit = limits[address(_wallet)].limit;
        _currentLimit = uint256(currentLimit(limit.current, limit.pending, limit.changeAfter));
    }

    /**
    * @dev Gets a pending limit for a wallet if any.
    * @param _wallet The target wallet.
    * @return the pending limit (in ETH) and the time at chich it will become effective.
    */
    function getPendingLimit(BaseWallet _wallet) external view returns (uint256 _pendingLimit, uint64 _changeAfter) {
        Limit storage limit = limits[address(_wallet)].limit;
        // solium-disable-next-line security/no-block-members
        return ((now < limit.changeAfter)? (uint256(limit.pending), limit.changeAfter) : (0,0));
    }

    /**
    * @dev Gets the amount of tokens that has not yet been spent during the current period.
    * @param _wallet The target wallet.
    * @return the amount of tokens (in ETH) that has not been spent yet and the end of the period.
    */
    function getDailyUnspent(BaseWallet _wallet) external view returns (uint256 _unspent, uint64 _periodEnd) {
        uint256 globalLimit = getCurrentLimit(_wallet);
        DailySpent storage expense = limits[address(_wallet)].dailySpent;
        // solium-disable-next-line security/no-block-members
        if(now > expense.periodEnd) {
            _unspent = globalLimit;
            _periodEnd = uint64(now + 24 hours);
        }
        else {
            _periodEnd = expense.periodEnd;
            if(expense.alreadySpent < globalLimit) {
                _unspent = globalLimit - expense.alreadySpent;
            }
        }
    }

    /**
    * @dev Helper method to check if a transfer is within the limit.
    * If yes the daily unspent for the current period is updated.
    * @param _wallet The target wallet.
    * @param _amount The amount for the transfer
    */
    function checkAndUpdateDailySpent(BaseWallet _wallet, uint _amount) internal returns (bool) {
        Limit storage limit = limits[address(_wallet)].limit;
        uint128 current = currentLimit(limit.current, limit.pending, limit.changeAfter);
        if(isWithinDailyLimit(_wallet, current, _amount)) {
            updateDailySpent(_wallet, current, _amount);
            return true;
        }
        return false;
    }

    /**
    * @dev Helper method to update the daily spent for the current period.
    * @param _wallet The target wallet.
    * @param _limit The current limit for the wallet.
    * @param _amount The amount to add to the daily spent.
    */
    function updateDailySpent(BaseWallet _wallet, uint128 _limit, uint _amount) internal {
        if(_limit != LIMIT_DISABLED) {
            DailySpent storage expense = limits[address(_wallet)].dailySpent;
            if (expense.periodEnd < now) {
                expense.periodEnd = uint64(now + 24 hours);
                expense.alreadySpent = uint128(_amount);
            }
            else {
                expense.alreadySpent += uint128(_amount);
            }
        }
    }

    /**
    * @dev Checks if a transfer amount is withing the daily limit for a wallet.
    * @param _wallet The target wallet.
    * @param _limit The current limit for the wallet.
    * @param _amount The transfer amount.
    * @return true if the transfer amount is withing the daily limit.
    */
    function isWithinDailyLimit(BaseWallet _wallet, uint _limit, uint _amount) internal view returns (bool)  {
        DailySpent storage expense = limits[address(_wallet)].dailySpent;
        if(_limit == LIMIT_DISABLED) {
            return true;
        }
        else if (expense.periodEnd < now) {
            return (_amount <= _limit);
        } else {
            return (expense.alreadySpent + _amount <= _limit && expense.alreadySpent + _amount >= expense.alreadySpent);
        }
    }

    /**
    * @dev Helper method to get the current limit from a Limit struct.
    * @param _current The value of the current parameter
    * @param _pending The value of the pending parameter
    * @param _changeAfter The value of the changeAfter parameter
    */
    function currentLimit(uint128 _current, uint128 _pending, uint64 _changeAfter) internal view returns (uint128) {
        if(_changeAfter > 0 && _changeAfter < now) {
            return _pending;
        }
        return _current;
    }

}

/**
 * @title Managed
 * @dev Basic contract that defines a set of managers. Only the owner can add/remove managers.
 * @author Julien Niset - <[email protected]>
 */
contract Managed is Owned {

    // The managers
    mapping (address => bool) public managers;

    /**
     * @dev Throws if the sender is not a manager.
     */
    modifier onlyManager {
        require(managers[msg.sender] == true, "M: Must be manager");
        _;
    }

    event ManagerAdded(address indexed _manager);
    event ManagerRevoked(address indexed _manager);

    /**
    * @dev Adds a manager. 
    * @param _manager The address of the manager.
    */
    function addManager(address _manager) external onlyOwner {
        require(_manager != address(0), "M: Address must not be null");
        if(managers[_manager] == false) {
            managers[_manager] = true;
            emit ManagerAdded(_manager);
        }        
    }

    /**
    * @dev Revokes a manager.
    * @param _manager The address of the manager.
    */
    function revokeManager(address _manager) external onlyOwner {
        require(managers[_manager] == true, "M: Target must be an existing manager");
        delete managers[_manager];
        emit ManagerRevoked(_manager);
    }
}

contract KyberNetwork {

    function getExpectedRate(
        ERC20 src,
        ERC20 dest,
        uint srcQty
    )
        public
        view
        returns (uint expectedRate, uint slippageRate);

    function trade(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address payable destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    )
        public
        payable
        returns(uint);
}





contract TokenPriceProvider is Managed {

    // Mock token address for ETH
    address constant internal ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    using SafeMath for uint256;

    mapping(address => uint256) public cachedPrices;

    // Address of the KyberNetwork contract
    KyberNetwork public kyberNetwork;

    constructor(KyberNetwork _kyberNetwork) public {
        kyberNetwork = _kyberNetwork;
    }

    function setPrice(ERC20 _token, uint256 _price) public onlyManager {
        cachedPrices[address(_token)] = _price;
    }

    function setPriceForTokenList(ERC20[] calldata _tokens, uint256[] calldata _prices) external onlyManager {
        for(uint16 i = 0; i < _tokens.length; i++) {
            setPrice(_tokens[i], _prices[i]);
        }
    }

    /**
     * @dev Converts the value of _amount tokens in ether.
     * @param _amount the amount of tokens to convert (in 'token wei' twei)
     * @param _token the ERC20 token contract
     * @return the ether value (in wei) of _amount tokens with contract _token
     */
    function getEtherValue(uint256 _amount, address _token) external view returns (uint256) {
        uint256 decimals = ERC20(_token).decimals();
        uint256 price = cachedPrices[_token];
        return price.mul(_amount).div(10**decimals);
    }

    //
    // The following is added to be backward-compatible with Argent's old backend
    //

    function setKyberNetwork(KyberNetwork _kyberNetwork) external onlyManager {
        kyberNetwork = _kyberNetwork;
    }

    function syncPrice(ERC20 _token) external {
        require(address(kyberNetwork) != address(0), "Kyber sync is disabled");
        (uint256 expectedRate,) = kyberNetwork.getExpectedRate(_token, ERC20(ETH_TOKEN_ADDRESS), 10000);
        cachedPrices[address(_token)] = expectedRate;
    }

    function syncPriceForTokenList(ERC20[] calldata _tokens) external {
        require(address(kyberNetwork) != address(0), "Kyber sync is disabled");
        for(uint16 i = 0; i < _tokens.length; i++) {
            (uint256 expectedRate,) = kyberNetwork.getExpectedRate(_tokens[i], ERC20(ETH_TOKEN_ADDRESS), 10000);
            cachedPrices[address(_tokens[i])] = expectedRate;
        }
    }
}

/**
 * @title Storage
 * @dev Base contract for the storage of a wallet.
 * @author Julien Niset - <[email protected]>
 */
contract Storage {

    /**
     * @dev Throws if the caller is not an authorised module.
     */
    modifier onlyModule(BaseWallet _wallet) {
        require(_wallet.authorised(msg.sender), "TS: must be an authorized module to call this method");
        _;
    }
}


/**
 * @title GuardianStorage
 * @dev Contract storing the state of wallets related to guardians and lock.
 * The contract only defines basic setters and getters with no logic. Only modules authorised
 * for a wallet can modify its state.
 * @author Julien Niset - <[email protected]>
 * @author Olivier Van Den Biggelaar - <[email protected]>
 */
contract GuardianStorage is Storage {

    struct GuardianStorageConfig {
        // the list of guardians
        address[] guardians;
        // the info about guardians
        mapping (address => GuardianInfo) info;
        // the lock's release timestamp
        uint256 lock; 
        // the module that set the last lock
        address locker;
    }

    struct GuardianInfo {
        bool exists;
        uint128 index;
    }

    // wallet specific storage
    mapping (address => GuardianStorageConfig) internal configs;

    // *************** External Functions ********************* //

    /**
     * @dev Lets an authorised module add a guardian to a wallet.
     * @param _wallet The target wallet.
     * @param _guardian The guardian to add.
     */
    function addGuardian(BaseWallet _wallet, address _guardian) external onlyModule(_wallet) {
        GuardianStorageConfig storage config = configs[address(_wallet)];
        config.info[_guardian].exists = true;
        config.info[_guardian].index = uint128(config.guardians.push(_guardian) - 1);
    }

    /**
     * @dev Lets an authorised module revoke a guardian from a wallet.
     * @param _wallet The target wallet.
     * @param _guardian The guardian to revoke.
     */
    function revokeGuardian(BaseWallet _wallet, address _guardian) external onlyModule(_wallet) {
        GuardianStorageConfig storage config = configs[address(_wallet)];
        address lastGuardian = config.guardians[config.guardians.length - 1];
        if (_guardian != lastGuardian) {
            uint128 targetIndex = config.info[_guardian].index;
            config.guardians[targetIndex] = lastGuardian;
            config.info[lastGuardian].index = targetIndex;
        }
        config.guardians.length--;
        delete config.info[_guardian];
    }

    /**
     * @dev Returns the number of guardians for a wallet.
     * @param _wallet The target wallet.
     * @return the number of guardians.
     */
    function guardianCount(BaseWallet _wallet) external view returns (uint256) {
        return configs[address(_wallet)].guardians.length;
    }
    
    /**
     * @dev Gets the list of guaridans for a wallet.
     * @param _wallet The target wallet.
     * @return the list of guardians.
     */
    function getGuardians(BaseWallet _wallet) external view returns (address[] memory) {
        GuardianStorageConfig storage config = configs[address(_wallet)];
        address[] memory guardians = new address[](config.guardians.length);
        for (uint256 i = 0; i < config.guardians.length; i++) {
            guardians[i] = config.guardians[i];
        }
        return guardians;
    }

    /**
     * @dev Checks if an account is a guardian for a wallet.
     * @param _wallet The target wallet.
     * @param _guardian The account.
     * @return true if the account is a guardian for a wallet.
     */
    function isGuardian(BaseWallet _wallet, address _guardian) external view returns (bool) {
        return configs[address(_wallet)].info[_guardian].exists;
    }

    /**
     * @dev Lets an authorised module set the lock for a wallet.
     * @param _wallet The target wallet.
     * @param _releaseAfter The epoch time at which the lock should automatically release.
     */
    function setLock(BaseWallet _wallet, uint256 _releaseAfter) external onlyModule(_wallet) {
        configs[address(_wallet)].lock = _releaseAfter;
        if(_releaseAfter != 0 && msg.sender != configs[address(_wallet)].locker) {
            configs[address(_wallet)].locker = msg.sender;
        }
    }

    /**
     * @dev Checks if the lock is set for a wallet.
     * @param _wallet The target wallet.
     * @return true if the lock is set for the wallet.
     */
    function isLocked(BaseWallet _wallet) external view returns (bool) {
        return configs[address(_wallet)].lock > now;
    }

    /**
     * @dev Gets the time at which the lock of a wallet will release.
     * @param _wallet The target wallet.
     * @return the time at which the lock of a wallet will release, or zero if there is no lock set.
     */
    function getLock(BaseWallet _wallet) external view returns (uint256) {
        return configs[address(_wallet)].lock;
    }

    /**
     * @dev Gets the address of the last module that modified the lock for a wallet.
     * @param _wallet The target wallet.
     * @return the address of the last module that modified the lock for a wallet.
     */
    function getLocker(BaseWallet _wallet) external view returns (address) {
        return configs[address(_wallet)].locker;
    }
}


/**
 * @title TransferStorage
 * @dev Contract storing the state of wallets related to transfers (limit and whitelist).
 * The contract only defines basic setters and getters with no logic. Only modules authorised
 * for a wallet can modify its state.
 * @author Julien Niset - <[email protected]>
 */
contract TransferStorage is Storage {

    // wallet specific storage
    mapping (address => mapping (address => uint256)) internal whitelist;

    // *************** External Functions ********************* //

    /**
     * @dev Lets an authorised module add or remove an account from the whitelist of a wallet.
     * @param _wallet The target wallet.
     * @param _target The account to add/remove.
     * @param _value True for addition, false for revokation.
     */
    function setWhitelist(BaseWallet _wallet, address _target, uint256 _value) external onlyModule(_wallet) {
        whitelist[address(_wallet)][_target] = _value;
    }

    /**
     * @dev Gets the whitelist state of an account for a wallet.
     * @param _wallet The target wallet.
     * @param _target The account.
     * @return the epoch time at which an account strats to be whitelisted, or zero if the account is not whitelisted.
     */
    function getWhitelist(BaseWallet _wallet, address _target) external view returns (uint256) {
        return whitelist[address(_wallet)][_target];
    }
}










/**
 * @title TransferManager
 * @dev Module to transfer and approve tokens (ETH or ERC20) or data (contract call) based on a security context (daily limit, whitelist, etc).
 * This module is the V2 of TokenTransfer.
 * @author Julien Niset - <[email protected]>
 */
contract TransferManager is BaseModule, RelayerModule, OnlyOwnerModule, BaseTransfer, LimitManager {

    bytes32 constant NAME = "TransferManager";

    bytes4 private constant ERC20_TRANSFER = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 private constant ERC20_APPROVE = bytes4(keccak256("approve(address,uint256)"));
    bytes4 private constant ERC721_ISVALIDSIGNATURE_BYTES = bytes4(keccak256("isValidSignature(bytes,bytes)"));
    bytes4 private constant ERC721_ISVALIDSIGNATURE_BYTES32 = bytes4(keccak256("isValidSignature(bytes32,bytes)"));

    bytes constant internal EMPTY_BYTES = "";

    enum ActionType { Transfer }

    using SafeMath for uint256;

    // Mock token address for ETH
    address constant internal ETH_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct TokenManagerConfig {
        // Mapping between pending action hash and their timestamp
        mapping (bytes32 => uint256) pendingActions;
    }

    // wallet specific storage
    mapping (address => TokenManagerConfig) internal configs;

    // The security period
    uint256 public securityPeriod;
    // The execution window
    uint256 public securityWindow;
    // The Guardian storage
    GuardianStorage public guardianStorage;
    // The Token storage
    TransferStorage public transferStorage;
    // The Token price provider
    TokenPriceProvider public priceProvider;
    // The previous limit manager needed to migrate the limits
    LimitManager public oldLimitManager;

    // *************** Events *************************** //

    // event Transfer(address indexed wallet, address indexed token, uint256 amount, address to, bytes data);
    // event Approved(address indexed wallet, address indexed token, uint256 amount, address spender);
    // event CalledContract(address indexed wallet, address indexed to, uint256 amount, bytes data);
    event AddedToWhitelist(address indexed wallet, address indexed target, uint64 whitelistAfter);
    event RemovedFromWhitelist(address indexed wallet, address indexed target);
    event PendingTransferCreated(address indexed wallet, bytes32 indexed id, uint256 indexed executeAfter, address token, address to, uint256 amount, bytes data);
    event PendingTransferExecuted(address indexed wallet, bytes32 indexed id);
    event PendingTransferCanceled(address indexed wallet, bytes32 indexed id);

    // *************** Modifiers *************************** //

    /**
     * @dev Throws if the wallet is locked.
     */
    modifier onlyWhenUnlocked(BaseWallet _wallet) {
        // solium-disable-next-line security/no-block-members
        require(!guardianStorage.isLocked(_wallet), "TT: wallet must be unlocked");
        _;
    }

    // *************** Constructor ********************** //

    constructor(
        ModuleRegistry _registry,
        TransferStorage _transferStorage,
        GuardianStorage _guardianStorage,
        address _priceProvider,
        uint256 _securityPeriod,
        uint256 _securityWindow,
        uint256 _defaultLimit,
        LimitManager _oldLimitManager
    )
        BaseModule(_registry, NAME)
        LimitManager(_defaultLimit)
        public
    {
        transferStorage = _transferStorage;
        guardianStorage = _guardianStorage;
        priceProvider = TokenPriceProvider(_priceProvider);
        securityPeriod = _securityPeriod;
        securityWindow = _securityWindow;
        oldLimitManager = _oldLimitManager;
    }

    /**
     * @dev Inits the module for a wallet by setting up the isValidSignature (EIP 1271)
     * static call redirection from the wallet to the module and copying all the parameters
     * of the daily limit from the previous implementation of the LimitManager module.
     * @param _wallet The target wallet.
     */
    function init(BaseWallet _wallet) public onlyWallet(_wallet) {
        // setup static calls
        _wallet.enableStaticCall(address(this), ERC721_ISVALIDSIGNATURE_BYTES);
        _wallet.enableStaticCall(address(this), ERC721_ISVALIDSIGNATURE_BYTES32);
        
        // setup default limit for new deployment
        if(address(oldLimitManager) == address(0)) {
            super.init(_wallet);
            return;
        }
        // get limit from previous LimitManager
        uint256 currentLimit = oldLimitManager.getCurrentLimit(_wallet);
        (uint256 pendingLimit, uint64 changeAfter) = oldLimitManager.getPendingLimit(_wallet);
        // setup default limit for new wallets
        if(currentLimit == 0 && changeAfter == 0) {
            super.init(_wallet);
            return;
        }
        // migrate existing limit for existing wallets
        if(currentLimit == pendingLimit) {
            limits[address(_wallet)].limit.current = uint128(currentLimit);
        }
        else {
            limits[address(_wallet)].limit = Limit(uint128(currentLimit), uint128(pendingLimit), changeAfter);
        }
        // migrate daily pending if we are within a rolling period
        (uint256 unspent, uint64 periodEnd) = oldLimitManager.getDailyUnspent(_wallet);
        if(periodEnd > now) {
            limits[address(_wallet)].dailySpent = DailySpent(uint128(currentLimit.sub(unspent)), periodEnd);
        }
    }

    // *************** External/Public Functions ********************* //

    /**
    * @dev lets the owner transfer tokens (ETH or ERC20) from a wallet.
    * @param _wallet The target wallet.
    * @param _token The address of the token to transfer.
    * @param _to The destination address
    * @param _amount The amoutn of token to transfer
    * @param _data The data for the transaction
    */
    function transferToken(
        BaseWallet _wallet,
        address _token,
        address _to,
        uint256 _amount,
        bytes calldata _data
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        if(isWhitelisted(_wallet, _to)) {
            // transfer to whitelist
            doTransfer(_wallet, _token, _to, _amount, _data);
        }
        else {
            uint256 etherAmount = (_token == ETH_TOKEN) ? _amount : priceProvider.getEtherValue(_amount, _token);
            if (checkAndUpdateDailySpent(_wallet, etherAmount)) {
                // transfer under the limit
                doTransfer(_wallet, _token, _to, _amount, _data);
            }
            else {
                // transfer above the limit
                (bytes32 id, uint256 executeAfter) = addPendingAction(ActionType.Transfer, _wallet, _token, _to, _amount, _data);
                emit PendingTransferCreated(address(_wallet), id, executeAfter, _token, _to, _amount, _data);
            }
        }
    }

    /**
    * @dev lets the owner approve an allowance of ERC20 tokens for a spender (dApp).
    * @param _wallet The target wallet.
    * @param _token The address of the token to transfer.
    * @param _spender The address of the spender
    * @param _amount The amount of tokens to approve
    */
    function approveToken(
        BaseWallet _wallet,
        address _token,
        address _spender,
        uint256 _amount
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        if(isWhitelisted(_wallet, _spender)) {
            // approve to whitelist
            doApproveToken(_wallet, _token, _spender, _amount);
        }
        else {
            // get current alowance
            uint256 currentAllowance = ERC20(_token).allowance(address(_wallet), _spender);
            if(_amount <= currentAllowance) {
                // approve if we reduce the allowance
                doApproveToken(_wallet, _token, _spender, _amount);
            }
            else {
                // check if delta is under the limit
                uint delta = _amount - currentAllowance;
                uint256 deltaInEth = priceProvider.getEtherValue(delta, _token);
                require(checkAndUpdateDailySpent(_wallet, deltaInEth), "TM: Approve above daily limit");
                // approve if under the limit
                doApproveToken(_wallet, _token, _spender, _amount);
            }
        }
    }

    /**
    * @dev lets the owner call a contract.
    * @param _wallet The target wallet.
    * @param _contract The address of the contract.
    * @param _value The amount of ETH to transfer as part of call
    * @param _data The encoded method data
    */
    function callContract(
        BaseWallet _wallet,
        address _contract,
        uint256 _value,
        bytes calldata _data
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        // Make sure we don't call a module, the wallet itself, or an ERC20 method
        authoriseContractCall(_wallet, _contract, _data);

        if(isWhitelisted(_wallet, _contract)) {
            // call to whitelist
            doCallContract(_wallet, _contract, _value, _data);
        }
        else {
            require(checkAndUpdateDailySpent(_wallet, _value), "TM: Call contract above daily limit");
            // call under the limit
            doCallContract(_wallet, _contract, _value, _data);
        }
    }

    /**
    * @dev lets the owner do an ERC20 approve followed by a call to a contract.
    * We assume that the contract will pull the tokens and does not require ETH.
    * @param _wallet The target wallet.
    * @param _token The token to approve.
    * @param _contract The address of the contract.
    * @param _amount The amount of ERC20 tokens to approve.
    * @param _data The encoded method data
    */
    function approveTokenAndCallContract(
        BaseWallet _wallet,
        address _token,
        address _contract,
        uint256 _amount,
        bytes calldata _data
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        // Make sure we don't call a module, the wallet itself, or an ERC20 method
        authoriseContractCall(_wallet, _contract, _data);

        if(isWhitelisted(_wallet, _contract)) {
            doApproveToken(_wallet, _token, _contract, _amount);
            doCallContract(_wallet, _contract, 0, _data);
        }
        else {
            // get current alowance
            uint256 currentAllowance = ERC20(_token).allowance(address(_wallet), _contract);
            if(_amount <= currentAllowance) {
                // no need to approve more
                doCallContract(_wallet, _contract, 0, _data);
            }
            else {
                // check if delta is under the limit
                uint delta = _amount - currentAllowance;
                uint256 deltaInEth = priceProvider.getEtherValue(delta, _token);
                require(checkAndUpdateDailySpent(_wallet, deltaInEth), "TM: Approve above daily limit");
                // approve if under the limit
                doApproveToken(_wallet, _token, _contract, _amount);
                doCallContract(_wallet, _contract, 0, _data);
            }
        }
    }

    /**
     * @dev Adds an address to the whitelist of a wallet.
     * @param _wallet The target wallet.
     * @param _target The address to add.
     */
    function addToWhitelist(
        BaseWallet _wallet,
        address _target
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        require(!isWhitelisted(_wallet, _target), "TT: target already whitelisted");
        // solium-disable-next-line security/no-block-members
        uint256 whitelistAfter = now.add(securityPeriod);
        transferStorage.setWhitelist(_wallet, _target, whitelistAfter);
        emit AddedToWhitelist(address(_wallet), _target, uint64(whitelistAfter));
    }

    /**
     * @dev Removes an address from the whitelist of a wallet.
     * @param _wallet The target wallet.
     * @param _target The address to remove.
     */
    function removeFromWhitelist(
        BaseWallet _wallet,
        address _target
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        require(isWhitelisted(_wallet, _target), "TT: target not whitelisted");
        transferStorage.setWhitelist(_wallet, _target, 0);
        emit RemovedFromWhitelist(address(_wallet), _target);
    }

    /**
    * @dev Executes a pending transfer for a wallet.
    * The method can be called by anyone to enable orchestration.
    * @param _wallet The target wallet.
    * @param _token The token of the pending transfer.
    * @param _to The destination address of the pending transfer.
    * @param _amount The amount of token to transfer of the pending transfer.
    * @param _data The data associated to the pending transfer.
    * @param _block The block at which the pending transfer was created.
    */
    function executePendingTransfer(
        BaseWallet _wallet,
        address _token,
        address _to,
        uint _amount,
        bytes memory _data,
        uint _block
    )
        public
        onlyWhenUnlocked(_wallet)
    {
        bytes32 id = keccak256(abi.encodePacked(ActionType.Transfer, _token, _to, _amount, _data, _block));
        uint executeAfter = configs[address(_wallet)].pendingActions[id];
        require(executeAfter > 0, "TT: unknown pending transfer");
        uint executeBefore = executeAfter.add(securityWindow);
        require(executeAfter <= now && now <= executeBefore, "TT: transfer outside of the execution window");
        delete configs[address(_wallet)].pendingActions[id];
        doTransfer(_wallet, _token, _to, _amount, _data);
        emit PendingTransferExecuted(address(_wallet), id);
    }

    function cancelPendingTransfer(
        BaseWallet _wallet,
        bytes32 _id
    )
        public
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        require(configs[address(_wallet)].pendingActions[_id] > 0, "TT: unknown pending action");
        delete configs[address(_wallet)].pendingActions[_id];
        emit PendingTransferCanceled(address(_wallet), _id);
    }

    /**
     * @dev Lets the owner of a wallet change its global limit.
     * The limit is expressed in ETH. Changes to the limit take 24 hours.
     * @param _wallet The target wallet.
     * @param _newLimit The new limit.
     */
    function changeLimit(BaseWallet _wallet, uint256 _newLimit) public onlyWalletOwner(_wallet) onlyWhenUnlocked(_wallet) {
        changeLimit(_wallet, _newLimit, securityPeriod);
    }

    /**
     * @dev Convenience method to disable the limit
     * The limit is disabled by setting it to an arbitrary large value.
     * @param _wallet The target wallet.
     */
    function disableLimit(BaseWallet _wallet) external onlyWalletOwner(_wallet) onlyWhenUnlocked(_wallet) {
        changeLimit(_wallet, LIMIT_DISABLED, securityPeriod);
    }

    /**
    * @dev Checks if an address is whitelisted for a wallet.
    * @param _wallet The target wallet.
    * @param _target The address.
    * @return true if the address is whitelisted.
    */
    function isWhitelisted(BaseWallet _wallet, address _target) public view returns (bool _isWhitelisted) {
        uint whitelistAfter = transferStorage.getWhitelist(_wallet, _target);
        // solium-disable-next-line security/no-block-members
        return whitelistAfter > 0 && whitelistAfter < now;
    }

    /**
    * @dev Gets the info of a pending transfer for a wallet.
    * @param _wallet The target wallet.
    * @param _id The pending transfer ID.
    * @return the epoch time at which the pending transfer can be executed.
    */
    function getPendingTransfer(BaseWallet _wallet, bytes32 _id) external view returns (uint64 _executeAfter) {
        _executeAfter = uint64(configs[address(_wallet)].pendingActions[_id]);
    }

    /**
    * @dev Implementation of EIP 1271.
    * Should return whether the signature provided is valid for the provided data.
    * @param _data Arbitrary length data signed on the behalf of address(this)
    * @param _signature Signature byte array associated with _data
    */
    function isValidSignature(bytes memory _data, bytes memory _signature) public view returns (bytes4) {
        bytes32 msgHash = keccak256(abi.encodePacked(_data));
        isValidSignature(msgHash, _signature);
        return ERC721_ISVALIDSIGNATURE_BYTES;
    }

    /**
    * @dev Implementation of EIP 1271.
    * Should return whether the signature provided is valid for the provided data.
    * @param _msgHash Hash of a message signed on the behalf of address(this)
    * @param _signature Signature byte array associated with _msgHash
    */
    function isValidSignature(bytes32 _msgHash, bytes memory _signature) public view returns (bytes4) {
        require(_signature.length == 65, "TM: invalid signature length");
        address signer = recoverSigner(_msgHash, _signature, 0);
        require(isOwner(BaseWallet(msg.sender), signer), "TM: Invalid signer");
        return ERC721_ISVALIDSIGNATURE_BYTES32;
    }

    // *************** Internal Functions ********************* //

    /**
     * @dev Creates a new pending action for a wallet.
     * @param _action The target action.
     * @param _wallet The target wallet.
     * @param _token The target token for the action.
     * @param _to The recipient of the action.
     * @param _amount The amount of token associated to the action.
     * @param _data The data associated to the action.
     * @return the identifier for the new pending action and the time when the action can be executed
     */
    function addPendingAction(
        ActionType _action,
        BaseWallet _wallet,
        address _token,
        address _to,
        uint _amount,
        bytes memory _data
    )
        internal
        returns (bytes32 id, uint256 executeAfter)
    {
        id = keccak256(abi.encodePacked(_action, _token, _to, _amount, _data, block.number));
        require(configs[address(_wallet)].pendingActions[id] == 0, "TM: duplicate pending action");
        executeAfter = now.add(securityPeriod);
        configs[address(_wallet)].pendingActions[id] = executeAfter;
    }

    /**
    * @dev Make sure a contract call is not trying to call a module, the wallet itself, or an ERC20 method.
    * @param _wallet The target wallet.
    * @param _contract The address of the contract.
    * @param _data The encoded method data
     */
    function authoriseContractCall(BaseWallet _wallet, address _contract, bytes memory _data) internal view {
        require(!_wallet.authorised(_contract) && _contract != address(_wallet), "TM: Forbidden contract");
        bytes4 methodId = functionPrefix(_data);
        require(methodId != ERC20_TRANSFER && methodId != ERC20_APPROVE, "TM: Forbidden method");
    }

    // *************** Implementation of RelayerModule methods ********************* //

    // Overrides refund to add the refund in the daily limit.
    function refund(BaseWallet _wallet, uint _gasUsed, uint _gasPrice, uint _gasLimit, uint _signatures, address _relayer) internal {
        // 21000 (transaction) + 7620 (execution of refund) + 7324 (execution of updateDailySpent) + 672 to log the event + _gasUsed
        uint256 amount = 36616 + _gasUsed;
        if(_gasPrice > 0 && _signatures > 0 && amount <= _gasLimit) {
            if(_gasPrice > tx.gasprice) {
                amount = amount * tx.gasprice;
            }
            else {
                amount = amount * _gasPrice;
            }
            updateDailySpent(_wallet, uint128(getCurrentLimit(_wallet)), amount);
            invokeWallet(address(_wallet), _relayer, amount, EMPTY_BYTES);
        }
    }

    // Overrides verifyRefund to add the refund in the daily limit.
    function verifyRefund(BaseWallet _wallet, uint _gasUsed, uint _gasPrice, uint _signatures) internal view returns (bool) {
        if(_gasPrice > 0 && _signatures > 0 && (
            address(_wallet).balance < _gasUsed * _gasPrice
            || isWithinDailyLimit(_wallet, getCurrentLimit(_wallet), _gasUsed * _gasPrice) == false
            || _wallet.authorised(address(_wallet)) == false
        ))
        {
            return false;
        }
        return true;
    }
}