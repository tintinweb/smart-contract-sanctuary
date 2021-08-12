pragma solidity >=0.5.0 <0.7.0;

import "@gnosis.pm/safe-contracts/contracts/base/Module.sol";
import "@gnosis.pm/safe-contracts/contracts/base/ModuleManager.sol";
import "@gnosis.pm/safe-contracts/contracts/base/OwnerManager.sol";
import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}


contract HeritageModule is Module {

    string public constant NAME = "Heritage Modulee";
    string public constant VERSION = "0.1.0";

    uint256 public threshold;
    address[] public heirs;

    event StartInheritTimelapse();
    event Inherit();

    // heirPercentage mapping maps heir's address to heir inheritance percentage.
    mapping (address => uint256) public heirPercentage;
    // askInherit store heirs agreement to inherit.
    mapping (address => bool) public askInherit;
    // readyToInherit mapping maps data hash to 
    uint256 public readyToInherit = 0;
    // timelapse between inherit and confirmInherit
    uint256 public timelapse;

    // One of the heirs need to deposit an amount of ERC20 tokens before calling the inherit function
    // Address of the ERC20 token
    address public ERC20DepositAddress;
    // Amount to deposit
    uint256 public ERC20ToDepositAmount;
    // Amount already in the Safe 
    uint256 public ERC20AlreadyDepositedAmount;
   
    modifier onlyHeir() {
        require(heirPercentage[msg.sender] > 0, "Method can only be called by a heir");
        _;
    }

    /// @dev Setup function sets initial storage of contract.
    /// @param _heirs List of heirs addresses.
    /// @param _percentages List of heirs heritence percentages.
    /// @param _threshold Required number of heirs to confirm the inheritage.
    /// @param _timelapse Timelapse between inherit and confirmInherit.
    function setup(
        address[] memory _heirs,
        uint256[] memory _percentages,
        uint256 _threshold,
        uint256 _timelapse,
        address _ERC20DepositAddress,
        uint256 _ERC20ToDepositAmount
    )
        public
    {
        _checkConfigParams(_heirs, _percentages, _threshold);
        setManager();
        _reconfigure(_heirs, _percentages, _threshold, _timelapse, _ERC20DepositAddress, _ERC20ToDepositAmount);
    }

    /// @dev Setup function sets initial storage of contract.
    /// @param _heirs List of heirs addresses.
    /// @param _percentages List of heirs heritence percentages.
    /// @param _threshold Required number of heirs to confirm the inheritage.
    /// @param _timelapse Timelapse between inherit and confirmInherit.
    function reconfigure(
        address[] memory _heirs,
        uint256[] memory _percentages,
        uint256 _threshold,
        uint256 _timelapse,
        address _ERC20DepositAddress,
        uint256 _ERC20ToDepositAmount
    )
        public
        authorized
    {
        _checkConfigParams(_heirs, _percentages, _threshold);
        _reconfigure(_heirs, _percentages, _threshold, _timelapse, _ERC20DepositAddress, _ERC20ToDepositAmount);
    }

    /// @dev Make inheritage impossible (till the next call of `reconfigure`).
    function turnOffSocialRecovery()
        public
        authorized
    {
        for (uint i = 0; i < heirs.length; ++i) {
            address heir = heirs[i];
            heirPercentage[heir] = 0;
            askInherit[heir] = false;
        }
        heirs = new address[](0);
        threshold = 1; // more than the number of heirs
        readyToInherit = 0;
    }

    function _checkConfigParams(address[] memory _heirs, uint256[] memory _percentages, uint256 _threshold)
        pure internal
    {
        require(_threshold <= _heirs.length, "Threshold cannot exceed heirs count");
        require(_threshold >= 1, "Threshold must be superior to 0");
        require(_percentages.length == _heirs.length, "Heirs and percentages arrays must have the same lenght");
        uint256 percentageTotal = 0;
        for (uint i = 0; i < _percentages.length; i++) {
            require(_percentages[i] > 0, "Percentages must be superior to 0");
            percentageTotal += _percentages[i];
        }
        require(percentageTotal <= 100, "Percentages total must be inferior or equal to 100");
    }

    /// @dev Setup function sets initial storage of contract.
    /// @param _heirs List of heirs addresses.
    /// @param _percentages List of heirs heritence percentages.
    /// @param _threshold Required number of heirs to confirm the inheritage.
    /// @param _timelapse Timelapse between inherit and confirmInherit.
    function _reconfigure(
        address[] memory _heirs,
        uint256[] memory _percentages,
        uint256 _threshold,
        uint256 _timelapse,
        address _ERC20DepositAddress,
        uint256 _ERC20ToDepositAmount
    )
        internal
    {
        // reset old percentages
        for (uint256 i = 0; i < heirs.length; i++) {
            address heir = heirs[i];
            heirPercentage[heir] = 0;
        }
        // Set allowed heirs.
        for (uint256 i = 0; i < _heirs.length; i++) {
            address heir = _heirs[i];
            require(heir != address(0), "Invalid heir address provided");
            heirPercentage[heir] = _percentages[i];
        }
        heirs = _heirs;
        threshold = _threshold;
        timelapse = _timelapse;
        readyToInherit = 0;
        ERC20DepositAddress = _ERC20DepositAddress;
        ERC20ToDepositAmount = _ERC20ToDepositAmount;
    }

    function askForInherit()
        public
        onlyHeir
    {
        askInherit[msg.sender] = true;
    }

    
    function inherit()
        public
        onlyHeir
    {
        require(readyToInherit == 0, "Inherit already in progress");
        require(isConfirmedByRequiredHeirs(), "Inherit has not enough confirmations");
        if(ERC20ToDepositAmount == 0) {
            readyToInherit = now + timelapse;
            emit StartInheritTimelapse();
        } else {
            IERC20 toDepositToken = IERC20(ERC20DepositAddress);
            uint256 alreadyDeposited = toDepositToken.balanceOf(address(manager));
            if(alreadyDeposited > 0) {
                ERC20AlreadyDepositedAmount = alreadyDeposited;
            } else {
                // ERC20AlreadyDepositedAmount need to be > 0 to call confirmDeposit
                ERC20AlreadyDepositedAmount = 1;
            }
        }
    }

    function confirmDeposit()
        public
        onlyHeir
    {
        require(readyToInherit == 0, "Inherit already in progress");
        require(ERC20AlreadyDepositedAmount > 0, "Inherit function should be called first");
        IERC20 toDepositToken = IERC20(ERC20DepositAddress);
        uint256 depositedAmount = toDepositToken.balanceOf(address(manager));
        require(depositedAmount >= ERC20ToDepositAmount + ERC20AlreadyDepositedAmount, "Deposit not completed");
        readyToInherit = now + timelapse;
        emit StartInheritTimelapse();
    }

    /// @dev Split the Safe content between heirs.
    /// @param _erc20Addresses List of erc20 tokens to split between heirs.
    function confirmInherit(address[] memory _erc20Addresses)
        public
        onlyHeir
    {
        require(readyToInherit > 0, "Inherit function should be called first");
        require(now >= readyToInherit, "Timelapse not completed");
        IERC20 toDepositToken = IERC20(ERC20DepositAddress);
        uint256 depositedAmount = toDepositToken.balanceOf(address(manager));
        require(depositedAmount >= ERC20ToDepositAmount + ERC20AlreadyDepositedAmount, "Deposit not completed");
        readyToInherit = 0;
        ERC20AlreadyDepositedAmount=0;
        for (uint256 i = 0; i < heirs.length; i++) {
            askInherit[heirs[i]] = false;
        }
        // Split ETH between heirs
        uint ethBalance = address(manager).balance;
        for (uint256 i = 0; i < heirs.length; i++) {
            uint heritage = (heirPercentage[heirs[i]] * ethBalance) / 100;
            manager.execTransactionFromModule(heirs[i], heritage, "0x", Enum.Operation.Call);
        }
        // Split ERC-20 tokens between heirs
        for (uint256 tokenIndex = 0; tokenIndex < _erc20Addresses.length; tokenIndex++) {
            IERC20 token = IERC20(_erc20Addresses[tokenIndex]);
            uint erc20Balance = token.balanceOf(address(manager));
            if(erc20Balance > 0) {
                for (uint256 i = 0; i < heirs.length; i++) {
                    uint256 heritage = (heirPercentage[heirs[i]] * erc20Balance) / 100;
                    bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", heirs[i], heritage);
                    manager.execTransactionFromModule(_erc20Addresses[tokenIndex], 0, data, Enum.Operation.Call);
                }
            }
        }
        emit Inherit();
        // Send NFT to the first heir
        /* for (uint256 tokenIndex = 0; tokenIndex < _erc721Addresses.length; tokenIndex++) {
            bytes memory data = abi.encodeWithSignature("transferFrom(address,address,uint256)", address(manager), heirs[0], _erc721Addresses[tokenIndex].id);
            manager.execTransactionFromModule(_erc721Addresses[tokenIndex].contractAddress, 0, data, Enum.Operation.Call);
        } */
        // emit SafeRecovered(prevOwner, oldOwner, newOwner);
    }

    /// @dev Check if there is enough confirmation to inherit.
    /// @return Confirmation status.
    function isConfirmedByRequiredHeirs()
        public
        view
        returns (bool)
    {
        uint256 confirmationCount;
        for (uint256 i = 0; i < heirs.length; i++) {
            if (askInherit[heirs[i]])
                confirmationCount++;
            if (confirmationCount == threshold)
                return true;
        }
        return false;
    }


    /// @dev Returns array of heirs.
    /// @return Array of heirs.
    function getHeirs()public view returns(address [] memory) {
        return heirs;
    }

    /// @dev Returns array of heirs.
    /// @return Array of heirs.
    function getHeirsPercentage()public view returns(uint256 [] memory) {
        uint[] memory percentages = new uint[](heirs.length);
        for(uint256 i = 0; i < heirs.length; i++) {
            percentages[i] = heirPercentage[heirs[i]];
        }
        return percentages;
    }

    /// @dev Returns time left before confirmInherit
    /// @return uint time left before confirmInherit.
    function getTimelapse()
        public
        view
        returns (uint)
    {
        if(now >= readyToInherit) {
            return 0;
        } else {
            return readyToInherit - now;
        }
    }
}

pragma solidity >=0.5.0 <0.7.0;
import "../common/Enum.sol";


/// @title Executor - A contract that can execute transactions
/// @author Richard Meissner - <[email protected]>
contract Executor {

    function execute(address to, uint256 value, bytes memory data, Enum.Operation operation, uint256 txGas)
        internal
        returns (bool success)
    {
        if (operation == Enum.Operation.Call)
            success = executeCall(to, value, data, txGas);
        else if (operation == Enum.Operation.DelegateCall)
            success = executeDelegateCall(to, data, txGas);
        else
            success = false;
    }

    function executeCall(address to, uint256 value, bytes memory data, uint256 txGas)
        internal
        returns (bool success)
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function executeDelegateCall(address to, bytes memory data, uint256 txGas)
        internal
        returns (bool success)
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
        }
    }
}

pragma solidity >=0.5.0 <0.7.0;
import "../common/MasterCopy.sol";
import "./ModuleManager.sol";


/// @title Module - Base class for modules.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract Module is MasterCopy {

    ModuleManager public manager;

    modifier authorized() {
        require(msg.sender == address(manager), "Method can only be called from manager");
        _;
    }

    function setManager()
        internal
    {
        // manager can only be 0 at initalization of contract.
        // Check ensures that setup function can only be called once.
        require(address(manager) == address(0), "Manager has already been set");
        manager = ModuleManager(msg.sender);
    }
}

pragma solidity >=0.5.0 <0.7.0;
import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "./Executor.sol";
import "./Module.sol";


/// @title Module Manager - A contract that manages modules that can execute transactions via this contract
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract ModuleManager is SelfAuthorized, Executor {

    event EnabledModule(Module module);
    event DisabledModule(Module module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);

    address internal constant SENTINEL_MODULES = address(0x1);

    mapping (address => address) internal modules;

    function setupModules(address to, bytes memory data)
        internal
    {
        require(modules[SENTINEL_MODULES] == address(0), "Modules have already been initialized");
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
        if (to != address(0))
            // Setup has to complete successfully or transaction fails.
            require(executeDelegateCall(to, data, gasleft()), "Could not finish initialization");
    }

    /// @dev Allows to add a module to the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Enables the module `module` for the Safe.
    /// @param module Module to be whitelisted.
    function enableModule(Module module)
        public
        authorized
    {
        // Module address cannot be null or sentinel.
        require(address(module) != address(0) && address(module) != SENTINEL_MODULES, "Invalid module address provided");
        // Module cannot be added twice.
        require(modules[address(module)] == address(0), "Module has already been added");
        modules[address(module)] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = address(module);
        emit EnabledModule(module);
    }

    /// @dev Allows to remove a module from the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Disables the module `module` for the Safe.
    /// @param prevModule Module that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(Module prevModule, Module module)
        public
        authorized
    {
        // Validate module address and check that it corresponds to module index.
        require(address(module) != address(0) && address(module) != SENTINEL_MODULES, "Invalid module address provided");
        require(modules[address(prevModule)] == address(module), "Invalid prevModule, module pair provided");
        modules[address(prevModule)] = modules[address(module)];
        modules[address(module)] = address(0);
        emit DisabledModule(module);
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes memory data, Enum.Operation operation)
        public
        returns (bool success)
    {
        // Only whitelisted modules are allowed.
        require(msg.sender != SENTINEL_MODULES && modules[msg.sender] != address(0), "Method can only be called from an enabled module");
        // Execute transaction without further confirmations.
        success = execute(to, value, data, operation, gasleft());
        if (success) emit ExecutionFromModuleSuccess(msg.sender);
        else emit ExecutionFromModuleFailure(msg.sender);
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations and return data
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModuleReturnData(address to, uint256 value, bytes memory data, Enum.Operation operation)
        public
        returns (bool success, bytes memory returnData)
    {
        success = execTransactionFromModule(to, value, data, operation);
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            // Load free memory location
            let ptr := mload(0x40)
            // We allocate memory for the return data by setting the free memory location to
            // current free memory location + data size + 32 bytes for data size value
            mstore(0x40, add(ptr, add(returndatasize(), 0x20)))
            // Store the size
            mstore(ptr, returndatasize())
            // Store the data
            returndatacopy(add(ptr, 0x20), 0, returndatasize())
            // Point the return data to the correct memory location
            returnData := ptr
        }
    }

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(Module module)
        public
        view
        returns (bool)
    {
        return SENTINEL_MODULES != address(module) && modules[address(module)] != address(0);
    }

    /// @dev Returns array of first 10 modules.
    /// @return Array of modules.
    function getModules()
        public
        view
        returns (address[] memory)
    {
        (address[] memory array,) = getModulesPaginated(SENTINEL_MODULES, 10);
        return array;
    }

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return Array of modules.
    function getModulesPaginated(address start, uint256 pageSize)
        public
        view
        returns (address[] memory array, address next)
    {
        // Init array with max page size
        array = new address[](pageSize);

        // Populate return array
        uint256 moduleCount = 0;
        address currentModule = modules[start];
        while(currentModule != address(0x0) && currentModule != SENTINEL_MODULES && moduleCount < pageSize) {
            array[moduleCount] = currentModule;
            currentModule = modules[currentModule];
            moduleCount++;
        }
        next = currentModule;
        // Set correct size of returned array
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            mstore(array, moduleCount)
        }
    }
}

pragma solidity >=0.5.0 <0.7.0;
import "../common/SelfAuthorized.sol";

/// @title OwnerManager - Manages a set of owners and a threshold to perform actions.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract OwnerManager is SelfAuthorized {

    event AddedOwner(address owner);
    event RemovedOwner(address owner);
    event ChangedThreshold(uint256 threshold);

    address internal constant SENTINEL_OWNERS = address(0x1);

    mapping(address => address) internal owners;
    uint256 ownerCount;
    uint256 internal threshold;

    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    function setupOwners(address[] memory _owners, uint256 _threshold)
        internal
    {
        // Threshold can only be 0 at initialization.
        // Check ensures that setup function can only be called once.
        require(threshold == 0, "Owners have already been setup");
        // Validate that threshold is smaller than number of added owners.
        require(_threshold <= _owners.length, "Threshold cannot exceed owner count");
        // There has to be at least one Safe owner.
        require(_threshold >= 1, "Threshold needs to be greater than 0");
        // Initializing Safe owners.
        address currentOwner = SENTINEL_OWNERS;
        for (uint256 i = 0; i < _owners.length; i++) {
            // Owner address cannot be null.
            address owner = _owners[i];
            require(owner != address(0) && owner != SENTINEL_OWNERS, "Invalid owner address provided");
            // No duplicate owners allowed.
            require(owners[owner] == address(0), "Duplicate owner address provided");
            owners[currentOwner] = owner;
            currentOwner = owner;
        }
        owners[currentOwner] = SENTINEL_OWNERS;
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    /// @dev Allows to add a new owner to the Safe and update the threshold at the same time.
    ///      This can only be done via a Safe transaction.
    /// @notice Adds the owner `owner` to the Safe and updates the threshold to `_threshold`.
    /// @param owner New owner address.
    /// @param _threshold New threshold.
    function addOwnerWithThreshold(address owner, uint256 _threshold)
        public
        authorized
    {
        // Owner address cannot be null.
        require(owner != address(0) && owner != SENTINEL_OWNERS, "Invalid owner address provided");
        // No duplicate owners allowed.
        require(owners[owner] == address(0), "Address is already an owner");
        owners[owner] = owners[SENTINEL_OWNERS];
        owners[SENTINEL_OWNERS] = owner;
        ownerCount++;
        emit AddedOwner(owner);
        // Change threshold if threshold was changed.
        if (threshold != _threshold)
            changeThreshold(_threshold);
    }

    /// @dev Allows to remove an owner from the Safe and update the threshold at the same time.
    ///      This can only be done via a Safe transaction.
    /// @notice Removes the owner `owner` from the Safe and updates the threshold to `_threshold`.
    /// @param prevOwner Owner that pointed to the owner to be removed in the linked list
    /// @param owner Owner address to be removed.
    /// @param _threshold New threshold.
    function removeOwner(address prevOwner, address owner, uint256 _threshold)
        public
        authorized
    {
        // Only allow to remove an owner, if threshold can still be reached.
        require(ownerCount - 1 >= _threshold, "New owner count needs to be larger than new threshold");
        // Validate owner address and check that it corresponds to owner index.
        require(owner != address(0) && owner != SENTINEL_OWNERS, "Invalid owner address provided");
        require(owners[prevOwner] == owner, "Invalid prevOwner, owner pair provided");
        owners[prevOwner] = owners[owner];
        owners[owner] = address(0);
        ownerCount--;
        emit RemovedOwner(owner);
        // Change threshold if threshold was changed.
        if (threshold != _threshold)
            changeThreshold(_threshold);
    }

    /// @dev Allows to swap/replace an owner from the Safe with another address.
    ///      This can only be done via a Safe transaction.
    /// @notice Replaces the owner `oldOwner` in the Safe with `newOwner`.
    /// @param prevOwner Owner that pointed to the owner to be replaced in the linked list
    /// @param oldOwner Owner address to be replaced.
    /// @param newOwner New owner address.
    function swapOwner(address prevOwner, address oldOwner, address newOwner)
        public
        authorized
    {
        // Owner address cannot be null.
        require(newOwner != address(0) && newOwner != SENTINEL_OWNERS, "Invalid owner address provided");
        // No duplicate owners allowed.
        require(owners[newOwner] == address(0), "Address is already an owner");
        // Validate oldOwner address and check that it corresponds to owner index.
        require(oldOwner != address(0) && oldOwner != SENTINEL_OWNERS, "Invalid owner address provided");
        require(owners[prevOwner] == oldOwner, "Invalid prevOwner, owner pair provided");
        owners[newOwner] = owners[oldOwner];
        owners[prevOwner] = newOwner;
        owners[oldOwner] = address(0);
        emit RemovedOwner(oldOwner);
        emit AddedOwner(newOwner);
    }

    /// @dev Allows to update the number of required confirmations by Safe owners.
    ///      This can only be done via a Safe transaction.
    /// @notice Changes the threshold of the Safe to `_threshold`.
    /// @param _threshold New threshold.
    function changeThreshold(uint256 _threshold)
        public
        authorized
    {
        // Validate that threshold is smaller than number of owners.
        require(_threshold <= ownerCount, "Threshold cannot exceed owner count");
        // There has to be at least one Safe owner.
        require(_threshold >= 1, "Threshold needs to be greater than 0");
        threshold = _threshold;
        emit ChangedThreshold(threshold);
    }

    function getThreshold()
        public
        view
        returns (uint256)
    {
        return threshold;
    }

    function isOwner(address owner)
        public
        view
        returns (bool)
    {
        return owner != SENTINEL_OWNERS && owners[owner] != address(0);
    }

    /// @dev Returns array of owners.
    /// @return Array of Safe owners.
    function getOwners()
        public
        view
        returns (address[] memory)
    {
        address[] memory array = new address[](ownerCount);

        // populate return array
        uint256 index = 0;
        address currentOwner = owners[SENTINEL_OWNERS];
        while(currentOwner != SENTINEL_OWNERS) {
            array[index] = currentOwner;
            currentOwner = owners[currentOwner];
            index ++;
        }
        return array;
    }
}

pragma solidity >=0.5.0 <0.7.0;


/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

pragma solidity >=0.5.0 <0.7.0;
import "./SelfAuthorized.sol";


/// @title MasterCopy - Base for master copy contracts (should always be first super contract)
///         This contract is tightly coupled to our proxy contract (see `proxies/GnosisSafeProxy.sol`)
/// @author Richard Meissner - <[email protected]>
contract MasterCopy is SelfAuthorized {

    event ChangedMasterCopy(address masterCopy);

    // masterCopy always needs to be first declared variable, to ensure that it is at the same location as in the Proxy contract.
    // It should also always be ensured that the address is stored alone (uses a full word)
    address private masterCopy;

    /// @dev Allows to upgrade the contract. This can only be done via a Safe transaction.
    /// @param _masterCopy New contract address.
    function changeMasterCopy(address _masterCopy)
        public
        authorized
    {
        // Master copy address cannot be null.
        require(_masterCopy != address(0), "Invalid master copy address provided");
        masterCopy = _masterCopy;
        emit ChangedMasterCopy(_masterCopy);
    }
}

pragma solidity >=0.5.0 <0.7.0;


/// @title SelfAuthorized - authorizes current contract to perform actions
/// @author Richard Meissner - <[email protected]>
contract SelfAuthorized {
    modifier authorized() {
        require(msg.sender == address(this), "Method can only be called from this contract");
        _;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
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