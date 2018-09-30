pragma solidity 0.4.24;

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

/**
 * @title Eliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
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
   * and hash the result
   */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}

library Utils {

    /**
     * @notice Converts a number to its string/bytes representation
     *
     * @param _v the uint to convert
     */
    function uintToBytes(uint256 _v) internal pure returns (bytes) {
        uint256 v = _v;
        if (v == 0) {
            return "0";
        }

        uint256 digits = 0;
        uint256 v2 = v;
        while (v2 > 0) {
            v2 /= 10;
            digits += 1;
        }

        bytes memory result = new bytes(digits);

        for (uint256 i = 0; i < digits; i++) {
            result[digits - i - 1] = bytes1((v % 10) + 48);
            v /= 10;
        }

        return result;
    }

    /**
     * @notice Retrieves the address from a signature
     *
     * @param _hash the message that was signed (any length of bytes)
     * @param _signature the signature (65 bytes)
     */
    function addr(bytes _hash, bytes _signature) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n";
        bytes memory encoded = abi.encodePacked(prefix, uintToBytes(_hash.length), _hash);
        bytes32 prefixedHash = keccak256(encoded);

        return ECRecovery.recover(prefixedHash, _signature);
    }

}

/// @notice RenExBrokerVerifier implements the BrokerVerifier contract,
/// verifying broker signatures for order opening and fund withdrawal.
contract RenExBrokerVerifier is Ownable {
    string public VERSION; // Passed in as a constructor parameter.

    // Events
    event LogBalancesContractUpdated(address previousBalancesContract, address nextBalancesContract);
    event LogBrokerRegistered(address broker);
    event LogBrokerDeregistered(address broker);

    // Storage
    mapping(address => bool) public brokers;
    mapping(address => uint256) public traderNonces;

    address public balancesContract;

    modifier onlyBalancesContract() {
        require(msg.sender == balancesContract, "not authorized");
        _;
    }

    /// @notice The contract constructor.
    ///
    /// @param _VERSION A string defining the contract version.
    constructor(string _VERSION) public {
        VERSION = _VERSION;
    }

    /// @notice Allows the owner of the contract to update the address of the
    /// RenExBalances contract.
    ///
    /// @param _balancesContract The address of the new balances contract
    function updateBalancesContract(address _balancesContract) external onlyOwner {
        emit LogBalancesContractUpdated(balancesContract, _balancesContract);

        balancesContract = _balancesContract;
    }

    /// @notice Approved an address to sign order-opening and withdrawals.
    /// @param _broker The address of the broker.
    function registerBroker(address _broker) external onlyOwner {
        require(!brokers[_broker], "already registered");
        brokers[_broker] = true;
        emit LogBrokerRegistered(_broker);
    }

    /// @notice Reverts the a broker&#39;s registration.
    /// @param _broker The address of the broker.
    function deregisterBroker(address _broker) external onlyOwner {
        require(brokers[_broker], "not registered");
        brokers[_broker] = false;
        emit LogBrokerDeregistered(_broker);
    }

    /// @notice Verifies a broker&#39;s signature for an order opening.
    /// The data signed by the broker is a prefixed message and the order ID.
    ///
    /// @param _trader The trader requesting the withdrawal.
    /// @param _signature The 65-byte signature from the broker.
    /// @param _orderID The 32-byte order ID.
    /// @return True if the signature is valid, false otherwise.
    function verifyOpenSignature(
        address _trader,
        bytes _signature,
        bytes32 _orderID
    ) external view returns (bool) {
        bytes memory data = abi.encodePacked("Republic Protocol: open: ", _trader, _orderID);
        address signer = Utils.addr(data, _signature);
        return (brokers[signer] == true);
    }

    /// @notice Verifies a broker&#39;s signature for a trader withdrawal.
    /// The data signed by the broker is a prefixed message, the trader address
    /// and a 256-bit trader nonce, which is incremented every time a valid
    /// signature is checked.
    ///
    /// @param _trader The trader requesting the withdrawal.
    /// @param _signature 65-byte signature from the broker.
    /// @return True if the signature is valid, false otherwise.
    function verifyWithdrawSignature(
        address _trader,
        bytes _signature
    ) external onlyBalancesContract returns (bool) {
        bytes memory data = abi.encodePacked("Republic Protocol: withdraw: ", _trader, traderNonces[_trader]);
        address signer = Utils.addr(data, _signature);
        if (brokers[signer]) {
            traderNonces[_trader] += 1;
            return true;
        }
        return false;
    }
}