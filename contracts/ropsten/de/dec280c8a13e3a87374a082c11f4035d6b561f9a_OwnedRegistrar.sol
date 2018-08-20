pragma solidity ^0.4.20;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract OwnerResolver {
    ENS public ens;
    
    constructor(ENS _ens) public {
        ens = _ens;
    }
    
    function addr(bytes32 node) view returns(address) {
        return ens.owner(node);
    }
    
    function supportsInterface(bytes4 interfaceID) view returns (bool) {
        return interfaceID == 0x01ffc9a7 || interfaceID == 0x3b3b57de;
    }
}

contract OwnedRegistrar is Ownable {

    ENS public ens;
    OwnerResolver public resolver;

    event Associate(bytes32 indexed node, bytes32 indexed subnode, address indexed owner);
    event Disassociate(bytes32 indexed node, bytes32 indexed subnode);
    
    constructor(ENS _ens) public {
        ens = _ens;
        resolver = new OwnerResolver(_ens);
    }
    
    function associate(bytes32 node, bytes32[] labels, address[] owners) public onlyOwner {
        require(ens.owner(node) == address(this));
        require(labels.length == owners.length);
        
        for(uint i = 0; i < labels.length; i++) {
            ens.setSubnodeOwner(node, labels[i], address(this));
            
            bytes32 subnode = keccak256(abi.encodePacked(node, labels[i]));
            if(owners[i] == 0) {
                ens.setResolver(subnode, 0);
            } else {
                ens.setResolver(subnode, resolver);
            }
            ens.setOwner(subnode, owners[i]);
            
            emit Associate(node, labels[i], owners[i]); 
        }
    }
}