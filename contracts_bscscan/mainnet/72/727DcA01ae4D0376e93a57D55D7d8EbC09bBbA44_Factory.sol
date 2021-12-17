/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/Factory.sol


pragma solidity ^0.8.0;


interface IInstanceContract {
    function initialize(string memory name_, string memory symbol_, string memory contractURI_, address utilityToken_) external;
    function name() view external returns(string memory);
    function symbol() view external returns(string memory);
    function owner() view external returns(address);
}

contract Factory is Ownable {
    address public utility;
    address public implementation;
    mapping(bytes32 => address) public getInstance;
    address[] public instances;
       
    struct InstanceInfo {
        string name;
        string symbol;
        address creator;
    }
    mapping(address => InstanceInfo) private _instanceInfos;
    
    event InstanceCreated(string name, string symbol, address instance, uint256 length);
    constructor (address instance, string memory name, string memory symbol, string memory contractURI_, address utilityToken) {
        implementation = instance;
        utility = utilityToken;
        IInstanceContract(instance).initialize(name, symbol, contractURI_, utilityToken);
        Ownable(instance).transferOwnership(_msgSender());
        getInstance[keccak256(abi.encodePacked(name, symbol))] = instance;
        instances.push(instance);
        _instanceInfos[instance] = InstanceInfo(
            name,
            symbol,
            _msgSender()
        );
    }

    /**
    * @dev gives the count of instances
    */
    function instancesCount() external view returns (uint256) {
        return instances.length;
    }

    /**
    * @dev produces new instance with defined name and symbol
    * @param name name of new token
    * @param symbol symbol of new token
    * @return instance address of new contract
    */
    function produce(
        string memory name,
        string memory symbol,
        string memory contractURI
    ) 
        public 
        returns (address instance) 
    {
        // 1% from LP tokens should move to owner while user try to redeem
        return _produce(name, symbol, contractURI, utility);
    }

    /**
    * @dev produces new instance with defined name, symbol and utility token
    * @param name name of new token
    * @param symbol symbol of new token
    * @param utilityToken address of utility token
    * @return instance address of new contract
    */
    function produce(
        string memory name,
        string memory symbol,
        string memory contractURI,
        address utilityToken
    ) 
        public 
        returns (address instance) 
    {
        // 1% from LP tokens should move to owner while user try to redeem
        return _produce(name, symbol, contractURI, utilityToken);
    }
    
    function getInstanceInfo(
        uint256 instanceId
    ) public view returns(InstanceInfo memory) {
        
        address instance = instances[instanceId];
        return _instanceInfos[instance];
    }
    
    function _produce(
        string memory name,
        string memory symbol,
        string memory contractURI,
        address utilityToken
    ) internal returns (address instance) {
        _createInstanceValidate(name, symbol);
        address payable instanceCreated = payable(_createInstance(name, symbol));
        require(instanceCreated != address(0), "StakingFactory: INSTANCE_CREATION_FAILED");
        IInstanceContract(instanceCreated).initialize(name, symbol, contractURI, utilityToken);
        Ownable(instanceCreated).transferOwnership(_msgSender());
        instance = instanceCreated;        
    }
    
    function _createInstanceValidate(
        string memory name,
        string memory symbol
    ) internal view {
        require((bytes(name)).length != 0, "Factory: EMPTY NAME");
        require((bytes(symbol)).length != 0, "Factory: EMPTY SYMBOL");
        address instance = getInstance[keccak256(abi.encodePacked(name, symbol))];
        require(instance == address(0), "Factory: ALREADY_EXISTS");
    }

    function _createInstance(
        string memory name,
        string memory symbol
    ) internal returns (address instance) {
        
        instance = createClone(implementation);
        
        getInstance[keccak256(abi.encodePacked(name, symbol))] = instance;
        instances.push(instance);
        _instanceInfos[instance] = InstanceInfo(
            name,
            symbol,
            msg.sender
        );
        emit InstanceCreated(name, symbol, instance, instances.length);
    }

    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
        let clone := mload(0x40)
        mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
        mstore(add(clone, 0x14), targetBytes)
        mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
        result := create(0, clone, 0x37)
        }
    }
        
}