pragma solidity ^0.4.17;


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





/**
 * @title Eliptic curve signature operations
 *
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 */

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using his signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    //Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

}

/**
 * @title EthealWhitelist
 * @author thesved
 * @notice EthealWhitelist contract which handles KYC
 */
contract EthealWhitelist is Ownable {
    using ECRecovery for bytes32;

    // signer address for offchain whitelist signing
    address public signer;

    // storing whitelisted addresses
    mapping(address => bool) public isWhitelisted;

    event WhitelistSet(address indexed _address, bool _state);

    ////////////////
    // Constructor
    ////////////////
    function EthealWhitelist(address _signer) {
        require(_signer != address(0));

        signer = _signer;
    }

    /// @notice set signing address after deployment
    function setSigner(address _signer) public onlyOwner {
        require(_signer != address(0));

        signer = _signer;
    }

    ////////////////
    // Whitelisting: only owner
    ////////////////

    ///&#160;@notice Set whitelist state for an address.
    function setWhitelist(address _addr, bool _state) public onlyOwner {
        require(_addr != address(0));
        isWhitelisted[_addr] = _state;
        WhitelistSet(_addr, _state);
    }

    ///&#160;@notice Set whitelist state for multiple addresses
    function setManyWhitelist(address[] _addr, bool _state) public onlyOwner {
        for (uint256 i = 0; i < _addr.length; i++) {
            setWhitelist(_addr[i], _state);
        }
    }

    /// @notice offchain whitelist check
    function isOffchainWhitelisted(address _addr, bytes _sig) public view returns (bool) {
        bytes32 hash = keccak256("\x19Ethereum Signed Message:\n20",_addr);
        return hash.recover(_sig) == signer;
    }
}