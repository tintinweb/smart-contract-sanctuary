pragma solidity ^0.4.21;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}




contract ENS {
    function owner(bytes32 node) constant returns (address);
    function resolver(bytes32 node) constant returns (Resolver);
    function ttl(bytes32 node) constant returns (uint64);
    function setOwner(bytes32 node, address owner);
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner);
    function setResolver(bytes32 node, address resolver);
    function setTTL(bytes32 node, uint64 ttl);
}

contract Resolver {
    function addr(bytes32 node) constant returns (address);
}

contract ENSResolver is Ownable {
    ENS public ens;

    function ENSResolver(address ensAddress) public {
        require(ensAddress != address(0));
        ens = ENS(ensAddress);
    }

    function setENS(address ensAddress) public onlyOwner {
        require(ensAddress != address(0));
        ens = ENS(ensAddress);
    }

    function resolve(bytes32 node) public view returns (address) {
        Resolver resolver = Resolver(ens.resolver(node));
        return resolver.addr(node);
    }
}