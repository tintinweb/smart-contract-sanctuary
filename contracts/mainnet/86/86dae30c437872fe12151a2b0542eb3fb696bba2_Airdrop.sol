pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/ECRecovery.sol

/**
 * @title Eliptic curve signature operations
 *
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 *
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 *
 */

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
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
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * @dev and hash the result
   */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      "\x19Ethereum Signed Message:\n32",
      hash
    );
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/Airdrop.sol

contract KMHTokenInterface {
  function checkRole(address addr, string roleName) public view;

  function mint(address _to, uint256 _amount) public returns (bool);
}

contract NameRegistryInterface {
  function registerName(address addr, string name) public;
  function finalizeName(address addr, string name) public;
}

// Pausable is Ownable
contract Airdrop is Pausable {
  using SafeMath for uint;
  using ECRecovery for bytes32;

  event Distribution(address indexed to, uint256 amount);

  mapping(bytes32 => address) public users;
  mapping(bytes32 => uint) public unclaimedRewards;

  address public signer;

  KMHTokenInterface public token;
  NameRegistryInterface public nameRegistry;

  constructor(address _token, address _nameRegistry, address _signer) public {
    require(_token != address(0));
    require(_nameRegistry != address(0));
    require(_signer != address(0));

    token = KMHTokenInterface(_token);
    nameRegistry = NameRegistryInterface(_nameRegistry);
    signer = _signer;
  }

  function setSigner(address newSigner) public onlyOwner {
    require(newSigner != address(0));

    signer = newSigner;
  }

  function claim(
    address receiver,
    bytes32 id,
    string username,
    bool verified,
    uint256 amount,
    bytes32 inviterId,
    uint256 inviteReward,
    bytes sig
  ) public whenNotPaused {
    require(users[id] == address(0));

    bytes32 proveHash = getProveHash(receiver, id, username, verified, amount, inviterId, inviteReward);
    address proveSigner = getMsgSigner(proveHash, sig);
    require(proveSigner == signer);

    users[id] = receiver;

    uint256 unclaimedReward = unclaimedRewards[id];
    if (unclaimedReward > 0) {
      unclaimedRewards[id] = 0;
      _distribute(receiver, unclaimedReward.add(amount));
    } else {
      _distribute(receiver, amount);
    }

    if (verified) {
      nameRegistry.finalizeName(receiver, username);
    } else {
      nameRegistry.registerName(receiver, username);
    }

    if (inviterId == 0) {
      return;
    }

    if (users[inviterId] == address(0)) {
      unclaimedRewards[inviterId] = unclaimedRewards[inviterId].add(inviteReward);
    } else {
      _distribute(users[inviterId], inviteReward);
    }
  }

  function getAccountState(bytes32 id) public view returns (address addr, uint256 unclaimedReward) {
    addr = users[id];
    unclaimedReward = unclaimedRewards[id];
  }

  function getProveHash(
    address receiver, bytes32 id, string username, bool verified, uint256 amount, bytes32 inviterId, uint256 inviteReward
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(receiver, id, username, verified, amount, inviterId, inviteReward));
  }

  function getMsgSigner(bytes32 proveHash, bytes sig) public pure returns (address) {
    return proveHash.recover(sig);
  }

  function _distribute(address to, uint256 amount) internal {
    token.mint(to, amount);
    emit Distribution(to, amount);
  }
}