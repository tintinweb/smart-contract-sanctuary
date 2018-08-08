pragma solidity ^0.4.18;

// File: zeppelin/ownership/Ownable.sol

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
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/Certification.sol

contract Certification is Ownable {

  struct Certifier {
    bool valid;
    string id;
  }

  mapping (address => Certifier) public certifiers;

  event Certificate(bytes32 indexed certHash, bytes32 innerHash, address indexed certifier);
  event Revocation(bytes32 indexed certHash, bool invalid);

  function setCertifierInfo(address certifier, bool valid, string id)
  onlyOwner public {
    certifiers[certifier] = Certifier({
      valid: valid,
      id: id
    });
  }

  function computeCertHash(address certifier, bytes32 innerHash) pure public returns (bytes32) {
    return keccak256(certifier, innerHash);
  }

  function certify(bytes32 innerHash) public {
    require(certifiers[msg.sender].valid);
    Certificate(
      computeCertHash(msg.sender, innerHash),
      innerHash, msg.sender
    );
  }

  function revoke(bytes32 innerHash, address certifier, bool invalid) public {
    require(msg.sender == owner
      || (certifiers[msg.sender].valid && msg.sender == certifier)
    );
    Revocation(computeCertHash(certifier, innerHash), invalid);
  }

}