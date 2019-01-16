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

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public;
    function setResolver(bytes32 node, address resolver) public;
    function setOwner(bytes32 node, address owner) public;
    function setTTL(bytes32 node, uint64 ttl) public;
    function owner(bytes32 node) public view returns (address);
    function resolver(bytes32 node) public view returns (address);
    function ttl(bytes32 node) public view returns (uint64);

}

contract ResolverInterface {
    function PublicResolver(address ensAddr) public;
    function setAddr(bytes32 node, address addr) public;
    function setHash(bytes32 node, bytes32 hash) public;
    function addr(bytes32 node) public view returns (address);
    function hash(bytes32 node) public view returns (bytes32);
    function supportsInterface(bytes4 interfaceID) public pure returns (bool);
}


contract TopmonksRegistrar is Ownable {
    bytes32 public rootNode;
    ENS public ens;
    ResolverInterface public resolver;

    modifier onlyDomainOwner(bytes32 subnode) {
        address currentOwner = ens.owner(keccak256(abi.encodePacked(rootNode, subnode)));
        require(currentOwner == 0 || currentOwner == msg.sender, "Only owner");
        _;
    }

    constructor(bytes32 _node, address _ensAddr, address _resolverAddr) public {
        rootNode = _node;
        ens = ENS(_ensAddr);
        resolver = ResolverInterface(_resolverAddr);
    }

    function setRootNode(bytes32 _node) public onlyOwner {
        rootNode = _node;
    }

    function setResolver(address _resolverAddr) public onlyOwner {
        resolver = ResolverInterface(_resolverAddr);
    }

    function setNodeOwner(address _newOwner) public onlyOwner {
        ens.setOwner(rootNode, _newOwner);
    }

    function setSubnodeOwner(bytes32 _subnode, address _addr) public onlyOwner {
        ens.setSubnodeOwner(rootNode, _subnode, _addr);
    }

    function register(bytes32 _subnode, address _addr) public onlyDomainOwner(_subnode) {
        ens.setSubnodeOwner(rootNode, _subnode, this);
        bytes32 node = keccak256(abi.encodePacked(rootNode, _subnode));
        ens.setResolver(node, resolver);
        resolver.setAddr(node, _addr);
        ens.setSubnodeOwner(rootNode, _subnode, _addr);
    }
}