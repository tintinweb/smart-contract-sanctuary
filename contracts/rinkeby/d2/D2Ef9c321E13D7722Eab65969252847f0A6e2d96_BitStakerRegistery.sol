/**
 *Submitted for verification at Etherscan.io on 2019-04-07
*/

pragma solidity ^0.5.2;

/**
 * @title RegistryInterface Interface 
 */
interface RegistryInterface {
    function logic(address logicAddr) external view returns (bool);
    function record(address currentOwner, address nextOwner) external;
}


/**
 * @title Address Registry Record
 */
contract AddressRecord {

    /**
     * @dev address registry of system, logic and wallet addresses
     */
    address public registry;

    /**
     * @dev Throws if the logic is not authorised
     */
    modifier logicAuth(address logicAddr) {
        require(logicAddr != address(0), "logic-proxy-address-required");
        require(RegistryInterface(registry).logic(logicAddr), "logic-not-authorised");
        _;
    }

}


/**
 * @title User Auth
 */
contract UserAuth is AddressRecord {

    event LogSetOwner(address indexed owner);
    address public owner;

    /**
     * @dev Throws if not called by owner or contract itself
     */
    modifier auth {
        require(isAuth(msg.sender), "permission-denied");
        _;
    }

    /**
     * @dev sets new owner
     */
    function setOwner(address nextOwner) public auth {
        RegistryInterface(registry).record(owner, nextOwner);
        owner = nextOwner;
        emit LogSetOwner(nextOwner);
    }

    /**
     * @dev checks if called by owner or contract itself
     * @param src is the address initiating the call
     */
    function isAuth(address src) public view returns (bool) {
        if (src == owner) {
            return true;
        } else if (src == address(this)) {
            return true;
        }
        return false;
    }
}


/**
 * @dev logging the execute events
 */
contract UserNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed guy,
        bytes32 indexed foo,
        bytes32 bar,
        uint wad,
        bytes fax
    );

    modifier note {
        bytes32 foo;
        bytes32 bar;
        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }
        emit LogNote(
            msg.sig, 
            msg.sender, 
            foo, 
            bar, 
            msg.value,
            msg.data
        );
        _;
    }
}


/**
 * @title User Owned Contract Wallet
 */
contract UserWallet is UserAuth, UserNote {

    event LogExecute(address target, uint srcNum, uint sessionNum);

    /**
     * @dev sets the "address registry", owner's last activity, owner's active period and initial owner
     */
    constructor() public {
        registry = msg.sender;
        owner = msg.sender;
    }

    function() external payable {}

    /**
     * @dev Execute authorised calls via delegate call
     * @param _target logic proxy address
     * @param _data delegate call data
     * @param _src to find the source
     * @param _session to find the session
     */
    function execute(
        address _target, // modules addresses
        bytes memory _data,
        uint _src,
        uint _session
    ) 
        public
        payable
        note
        auth
        logicAuth(_target)
        returns (bytes memory response)
    {
        emit LogExecute(
            _target,
            _src,
            _session
        );
        
        // call contract in current context
        assembly {
            let succeeded := delegatecall(sub(gas, 5000), _target, add(_data, 0x20), mload(_data), 0, 0)
            let size := returndatasize

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
                case 1 {
                    // throw if delegatecall failed
                    revert(add(response, 0x20), size)
                }
        }
    }

}


/// @title AddressRegistry
/// @notice 
/// @dev 
contract AddressRegistry {
    event LogSetAddress(string name, address addr);

    /// @notice Registry of role and address
    mapping(bytes32 => address) registry;

    /**
     * @dev Check if msg.sender is admin or owner.
     */
    modifier isAdmin() {
        require(
            msg.sender == getAddress("admin") || 
            msg.sender == getAddress("owner"),
            "permission-denied"
        );
        _;
    }

    /// @dev Get the address from system registry 
    /// @param _name (string)
    /// @return  (address) Returns address based on role
    function getAddress(string memory _name) public view returns(address) {
        return registry[keccak256(abi.encodePacked(_name))];
    }

    /// @dev Set new address in system registry 
    /// @param _name (string) Role name
    /// @param _userAddress (string) User Address
    function setAddress(string memory _name, address _userAddress) public isAdmin {
        registry[keccak256(abi.encodePacked(_name))] = _userAddress;
        emit LogSetAddress(_name, _userAddress);
    }
}


/// @title LogicRegistry
/// @notice
/// @dev LogicRegistry 
contract LogicRegistry is AddressRegistry {

    event LogEnableStaticLogic(address logicAddress);
    event LogEnableLogic(address logicAddress);
    event LogDisableLogic(address logicAddress);

    /// @notice Map of static proxy state
    mapping(address => bool) public logicProxiesStatic;
    
    /// @notice Map of logic proxy state
    mapping(address => bool) public logicProxies;

    /// @dev 
    /// @param _logicAddress (address)
    /// @return  (bool)
    function logic(address _logicAddress) public view returns (bool) {
        if (logicProxiesStatic[_logicAddress] || logicProxies[_logicAddress]) {
            return true;
        }
        return false;
    }

    /// @dev 
    /// @param _logicAddress (address)
    /// @return  (bool)
    function logicStatic(address _logicAddress) public view returns (bool) {
        if (logicProxiesStatic[_logicAddress]) {
            return true;
        }
        return false;
    }

    /// @dev Sets the static logic proxy to true
    /// static proxies mostly contains the logic for withdrawal of assets
    /// and can never be false to freely let user withdraw their assets
    /// @param _logicAddress (address)
    function enableStaticLogic(address _logicAddress) public isAdmin {
        logicProxiesStatic[_logicAddress] = true;
        emit LogEnableStaticLogic(_logicAddress);
    }

    /// @dev Enable logic proxy address
    /// @param _logicAddress (address)
    function enableLogic(address _logicAddress) public isAdmin {
        logicProxies[_logicAddress] = true;
        emit LogEnableLogic(_logicAddress);
    }

    /// @dev Disable logic proxy address
    /// @param _logicAddress (address)
    function disableLogic(address _logicAddress) public isAdmin {
        logicProxies[_logicAddress] = false;
        emit LogDisableLogic(_logicAddress);
    }

}


/**
 * @dev Deploys a new proxy instance and sets msg.sender as owner of proxy
 */
contract WalletRegistry is LogicRegistry {
    
    event Created(address indexed sender, address indexed owner, address proxy);
    event LogRecord(address indexed currentOwner, address indexed nextOwner, address proxy);
    
    /// @notice Address to UserWallet proxy map
    mapping(address => UserWallet) public proxies;
    
    /// @dev Deploys a new proxy instance and sets custom owner of proxy
    /// Throws if the owner already have a UserWallet
    /// @return proxy ()
    function build() public returns (UserWallet proxy) {
        proxy = build(msg.sender);
    }

    /// @dev update the proxy record whenever owner changed on any proxy
    /// Throws if msg.sender is not a proxy contract created via this contract
    /// @return proxy () UserWallet
    function build(address _owner) public returns (UserWallet proxy) {
        require(proxies[_owner] == UserWallet(0), "multiple-proxy-per-user-not-allowed");
        proxy = new UserWallet();
        proxies[address(this)] = proxy; // will be changed via record() in next line execution
        proxy.setOwner(_owner);
        emit Created(msg.sender, _owner, address(proxy));
    }

    /// @dev Transafers ownership
    /// @param _currentOwner (address) Current Owner
    /// @param _nextOwner (address) Next Owner
    function record(address _currentOwner, address _nextOwner) public {
        require(msg.sender == address(proxies[_currentOwner]), "invalid-proxy-or-owner");
        require(proxies[_nextOwner] == UserWallet(0), "multiple-proxy-per-user-not-allowed");
        proxies[_nextOwner] = proxies[_currentOwner];
        proxies[_currentOwner] = UserWallet(0);
        emit LogRecord(_currentOwner, _nextOwner, address(proxies[_nextOwner]));
    }

}


/// @title BitStakerRegistery
/// @dev Initializing Registry
contract BitStakerRegistery is WalletRegistry {

    constructor() public {
        registry[keccak256(abi.encodePacked("admin"))] = msg.sender;
        registry[keccak256(abi.encodePacked("owner"))] = msg.sender;
    }
}

