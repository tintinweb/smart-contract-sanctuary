/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File @openzeppelin/contracts/proxy/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File contracts/test-contracts/FactoryProxyUpgraded.sol

/*

          88888888                         88888888
       8888    888888                   888888    8888
     888    88  8888888               8888  8888     888
    888        888888888             888888888888     888
   888        88888888888           8888888888888      888
   888      8888888888888           888888888888       888
    888     888888888888             888888888        888
     888     888  88888      _=_      8888888  88    888
       8888    888888      q(-_-)p      888888    8888
          88888888         '_) (_`         88888888
             88            /__/  \            88
             88          _(<_   / )_          88
            8888        (__\_\_|_/__)        8888

_____ ______   ________  ________   _________  ________  ________          ________ ________  ________ _________  ________  ________      ___    ___ 
|\   _ \  _   \|\   __  \|\   ___  \|\___   ___\\   __  \|\   __  \        |\  _____\\   __  \|\   ____\\___   ___\\   __  \|\   __  \    |\  \  /  /|
\ \  \\\__\ \  \ \  \|\  \ \  \\ \  \|___ \  \_\ \  \|\  \ \  \|\  \       \ \  \__/\ \  \|\  \ \  \___\|___ \  \_\ \  \|\  \ \  \|\  \   \ \  \/  / /
 \ \  \\|__| \  \ \   __  \ \  \\ \  \   \ \  \ \ \   _  _\ \   __  \       \ \   __\\ \   __  \ \  \       \ \  \ \ \  \\\  \ \   _  _\   \ \    / / 
  \ \  \    \ \  \ \  \ \  \ \  \\ \  \   \ \  \ \ \  \\  \\ \  \ \  \       \ \  \_| \ \  \ \  \ \  \____   \ \  \ \ \  \\\  \ \  \\  \|   \/  /  /  
   \ \__\    \ \__\ \__\ \__\ \__\\ \__\   \ \__\ \ \__\\ _\\ \__\ \__\       \ \__\   \ \__\ \__\ \_______\  \ \__\ \ \_______\ \__\\ _\ __/  / /    
    \|__|     \|__|\|__|\|__|\|__| \|__|    \|__|  \|__|\|__|\|__|\|__|        \|__|    \|__|\|__|\|_______|   \|__|  \|_______|\|__|\|__|\___/ /     
                                                                                                                                         \|___|/      
*/

pragma solidity ^0.8.0;

contract FactoryProxyUpgraded is Initializable {
    /*************************** Events ***************************/
    event Deployed(address addr, bytes32 salt);

    /*************************** Global Variables ***************************/
    /* The factory owner */
    address public factoryOwner;

    /* The array of template creators */
    address[] public templateCreator;

    /* Types of deployable proxies */
    struct ProxyTypes {
        bytes templateByteCode;
        address[] adminAddress;
        bool isPublic;
        bool enabled;
    }

    /* Types of deployable address */
    struct ImplementationTypes {
        address templateAddress;
        address[] adminAddress;
        bool isPublic;
        bool enabled;
    }

    /* Types of deployable implementation templates */
    mapping(string => ImplementationTypes) public implTemplateTypes;

    /* Types of deployable proxy templates */
    mapping(string => ProxyTypes) public proxyTemplateTypes;

    string public newData = "I AM A TEST ADDITION";

    /*************************** Constructor ***************************/
    constructor(address _factoryOwner) {
        // Instantiates the owner as a template creator and owner of the contracts
        factoryOwner = _factoryOwner;
        templateCreator.push(_factoryOwner);
    }

    function initialize(address _factoryOwner) public initializer {
        // Check to make sure this is only run once
        factoryOwner = _factoryOwner;
        templateCreator.push(_factoryOwner);
    }

    /*************************** Constructor ***************************/

    /*************************** Getters ***************************/

    function getFactoryOwner() external view returns (address) {
        return factoryOwner;
    }

    function getTemplateCreators() external view returns (address[] memory) {
        return templateCreator;
    }

    function getTemplateBytes(string calldata _templateName)
        external
        view
        returns (bytes memory)
    {
        return proxyTemplateTypes[_templateName].templateByteCode;
    }

    function getTemplateAddress(string calldata _templateName)
        external
        view
        returns (address)
    {
        return implTemplateTypes[_templateName].templateAddress;
    }

    function getNewData() external view returns (string memory) {
        return newData;
    }

    function setNewData() public {
        newData = "TRY THIS";
    }

    /*************************** Getters ***************************/

    /*************************** Setters ***************************/

    /** @dev Adds a new proxy template contract type
     * @param _templateName Name of the template (informational)
     * @param _templateByteCode Generated byte code of the deployed contract
     * @param _isPublic Does the contract have any special admin locks?
     */
    function addProxyTemplateType(
        string calldata _templateName,
        bytes memory _templateByteCode,
        bool _isPublic
    ) public onlyFactoryOwnerOrCreator {
        ProxyTypes memory tempTemplate;

        tempTemplate.templateByteCode = _templateByteCode;
        tempTemplate.adminAddress = new address[](1);
        tempTemplate.adminAddress[0] = msg.sender;
        tempTemplate.isPublic = _isPublic;
        tempTemplate.enabled = true;

        proxyTemplateTypes[_templateName] = (tempTemplate);
    }

    /** @dev Removes a Proxy template contract type
     * @param _templateName index of the template in the array
     */
    function toggleProxyStatus(string calldata _templateName)
        public
        onlyFactoryOwner
    {
        proxyTemplateTypes[_templateName].enabled = !proxyTemplateTypes[
            _templateName
        ].enabled;
    }

    /** @dev Adds a new implementation template contract type
     * @param _templateName Name of the template (informational)
     * @param _templateAddress Generated byte code of the deployed contract
     * @param _isPublic Does the contract have any special admin locks?
     */
    function addImplTemplateType(
        string calldata _templateName,
        address _templateAddress,
        bool _isPublic
    ) public onlyFactoryOwnerOrCreator {
        ImplementationTypes memory tempTemplate;

        tempTemplate.templateAddress = _templateAddress;
        tempTemplate.adminAddress = new address[](1);
        tempTemplate.adminAddress[0] = msg.sender;
        tempTemplate.isPublic = _isPublic;
        tempTemplate.enabled = true;

        implTemplateTypes[_templateName] = (tempTemplate);
    }

    /** @dev Removes a implementation template contract type
     * @param _templateName index of the template in the mapping
     */
    function toggleImplStatus(string calldata _templateName)
        public
        onlyFactoryOwner
    {
        implTemplateTypes[_templateName].enabled = !implTemplateTypes[
            _templateName
        ].enabled;
    }

    /** @dev Sets a new factory owner
     * @param _newFactoryOwner New factory owner
     */
    function setNewFactoryOwner(address _newFactoryOwner)
        public
        onlyFactoryOwner
    {
        factoryOwner = _newFactoryOwner;
    }

    /** @dev Adds a new template creator (someone who is able to deploy new templates)
     * @param _newTemplateCreator New template creator
     */
    function setTemplateCreator(address _newTemplateCreator)
        public
        onlyFactoryOwner
    {
        templateCreator.push(_newTemplateCreator);
    }

    /** @dev Removes a template creator
     * @param _newTemplateCreator Address of the to be removed creator
     */
    function removeTemplateCreator(address _newTemplateCreator)
        public
        onlyFactoryOwner
    {
        for (uint256 i = 0; i < templateCreator.length - 1; i++) {
            if (templateCreator[i] == _newTemplateCreator) {
                templateCreator[i] = templateCreator[i + 1];
            }
        }
        delete templateCreator[templateCreator.length - 1];
    }

    /** @dev Adds implementation admin to a specific template
     * @param _pooName Template address
     * @param _newAdmin New template owner
     */
    function addImplAdmin(string calldata _pooName, address _newAdmin)
        public
        onlyFactoryOwner
    {
        for (
            uint256 i = 0;
            i < implTemplateTypes[_pooName].adminAddress.length;
            i++
        ) {
            if (implTemplateTypes[_pooName].adminAddress[i] == _newAdmin) {
                revert("This admin already exists");
            }
        }

        implTemplateTypes[_pooName].adminAddress.push(_newAdmin);
    }

    /** @dev Adds proxy admin to a specific template
     * @param _pooName Template address
     * @param _newAdmin New template owner
     */
    function addProxyAdmin(string calldata _pooName, address _newAdmin)
        public
        onlyFactoryOwner
    {
        for (
            uint256 i = 0;
            i < proxyTemplateTypes[_pooName].adminAddress.length;
            i++
        ) {
            if (proxyTemplateTypes[_pooName].adminAddress[i] == _newAdmin) {
                revert("This admin already exists");
            }
        }

        proxyTemplateTypes[_pooName].adminAddress.push(_newAdmin);
    }

    /** @dev Toggles whether a implementation is public
     * @param _pooName Implementation name
     */
    function toggleImplPublic(string calldata _pooName)
        public
        isAdminImpl(_pooName)
    {
        implTemplateTypes[_pooName].isPublic = !implTemplateTypes[_pooName]
            .isPublic;
    }

    /** @dev Toggles whether a proxy is public
     * @param _proxyName Proxy name
     */
    function toggleProxyPublic(string calldata _proxyName)
        public
        isAdminProxy(_proxyName)
    {
        proxyTemplateTypes[_proxyName].isPublic = !proxyTemplateTypes[_proxyName]
            .isPublic;
    }

    /*************************** Setters ***************************/

    /*************************** Mutators ***************************/

    /** @dev Deploys a new template contract
     * @param _proxy Name index of the template you would like to create
     * @param _implementation Name index of the template you would like to create
     * @param _args Name index of the template you would like to create
     */
    function createTemplate(
        string calldata _proxy,
        string calldata _implementation,
        bytes calldata _args
    )
        public
        isAdminOrPublicImpl(_implementation)
        isAdminOrPublicProxy(_proxy)
        returns (address addr)
    {
        bytes memory _tempMemory = proxyTemplateTypes[_proxy].templateByteCode;
        bytes memory _bytecode = abi.encodePacked(
            _tempMemory,
            abi.encode(
                implTemplateTypes[_implementation].templateAddress,
                address(this),
                _args
            )
        );

        bytes32 _salt = keccak256(
            abi.encodePacked(block.number, _implementation)
        );

        assembly {
            addr := create2(
                0, // wei sent with current call
                // Actual code starts after skipping the first 32 bytes
                add(_bytecode, 0x20),
                mload(_bytecode), // Load the size of code contained in the first 32 bytes
                _salt // Salt from function arguments
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr, _salt);

        return addr;
    }

    /** @dev Call to one of the template addresses as factory owner
     * @param _templateAddress Address of the template
     * @param _data Data of the call
     */
    function transact(address _templateAddress, bytes memory _data)
        public
        onlyFactoryOwner
        returns (bool success, bytes memory result)
    {
        (success, result) = _templateAddress.call(_data);
    }

    /*************************** Mutators ***************************/

    /*************************** Modifiers ***************************/

    modifier onlyFactoryOwner() {
        require(msg.sender == factoryOwner);
        _;
    }

    modifier onlyFactoryOwnerOrCreator() {
        for (uint256 i = 0; i < templateCreator.length; i++) {
            if (
                templateCreator[i] == msg.sender || factoryOwner == msg.sender
            ) {
                _;
            }
        }
    }

    modifier isAdminOrPublicProxy(string calldata _templateName) {
        require(
            proxyTemplateTypes[_templateName].enabled,
            "Proxy template not enabled"
        );

        if (proxyTemplateTypes[_templateName].isPublic) {
            _;
        } else {
            for (
                uint256 i = 0;
                i < proxyTemplateTypes[_templateName].adminAddress.length;
                i++
            ) {
                if (
                    proxyTemplateTypes[_templateName].adminAddress[i] ==
                    msg.sender ||
                    factoryOwner == msg.sender
                ) {
                    _;
                }
            }
        }
    }

    modifier isAdminOrPublicImpl(string calldata _templateName) {
        require(
            implTemplateTypes[_templateName].enabled,
            "Implementation template not enabled"
        );

        if (implTemplateTypes[_templateName].isPublic) {
            _;
        } else {
            for (
                uint256 i = 0;
                i < implTemplateTypes[_templateName].adminAddress.length;
                i++
            ) {
                if (
                    implTemplateTypes[_templateName].adminAddress[i] ==
                    msg.sender ||
                    factoryOwner == msg.sender
                ) {
                    _;
                }
            }
        }
    }

    modifier isAdminProxy(string calldata _templateName) {
        for (
            uint256 i = 0;
            i < proxyTemplateTypes[_templateName].adminAddress.length;
            i++
        ) {
            if (
                proxyTemplateTypes[_templateName].adminAddress[i] ==
                msg.sender ||
                factoryOwner == msg.sender
            ) {
                _;
            }
        }
    }

    modifier isAdminImpl(string calldata _templateName) {
        for (
            uint256 i = 0;
            i < implTemplateTypes[_templateName].adminAddress.length;
            i++
        ) {
            if (
                implTemplateTypes[_templateName].adminAddress[i] ==
                msg.sender ||
                factoryOwner == msg.sender
            ) {
                _;
            }
        }
    }

    /*************************** Modifiers ***************************/
}