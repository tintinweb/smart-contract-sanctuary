/**
 *Submitted for verification at Etherscan.io on 2020-08-26
*/

// File: contracts/LiteSig.sol

pragma solidity 0.6.12;

/**
 * LiteSig is a lighter weight multisig based on https://github.com/christianlundkvist/simple-multisig
 * Owners aggregate signatures offline and then broadcast a transaction with the required number of signatures.
 * Unlike other multisigs, this is meant to have minimal administration functions and other features in order
 * to reduce the footprint and attack surface.
 */
contract LiteSig {

    //  Events triggered for incoming and outgoing transactions
    event Deposit(address indexed source, uint value);
    event Execution(uint indexed transactionId, address indexed destination, uint value, bytes data);
    event ExecutionFailure(uint indexed transactionId, address indexed destination, uint value, bytes data);

    // List of owner addresses - for external readers convenience only
    address[] public owners;

    // Mapping of owner address to keep track for lookups
    mapping(address => bool) ownersMap;

    // Nonce increments by one on each broadcast transaction to prevent replays
    uint public nonce = 0;

    // Number of required signatures from the list of owners
    uint public requiredSignatures = 0;

    // EIP712 Precomputed hashes:
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)")
    bytes32 constant EIP712DOMAINTYPE_HASH = 0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;

    // keccak256("LiteSig")
    bytes32 constant NAME_HASH = 0x3308695f49e3f28122810c848e1569a04488ca4f6a11835568450d7a38a86120;

    // keccak256("1")
    bytes32 constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    // keccak256("MultiSigTransaction(address destination,uint256 value,bytes data,uint256 nonce,address txOrigin)")
    bytes32 constant TXTYPE_HASH = 0x81336c6b66e18c614f29c0c96edcbcbc5f8e9221f35377412f0ea5d6f428918e;

    // keccak256("TOKENSOFT")
    bytes32 constant SALT = 0x9c360831104e550f13ec032699c5f1d7f17190a31cdaf5c83945a04dfd319eea;

    // Hash for EIP712, computed from data and contract address - ensures it can't be replayed against
    // other contracts or chains
    bytes32 public DOMAIN_SEPARATOR;

    // Track init state
    bool initialized = false;

    // The init function inputs a list of owners and the number of signatures that
    //   are required before a transaction is executed.
    // Owners list must be in ascending address order.
    // Required sigs must be greater than 0 and less than or equal to number of owners.
    // Chain ID prevents replay across chains
    // This function can only be run one time
    function init(address[] memory _owners, uint _requiredSignatures, uint chainId) public {
        // Verify it can't be initialized again
        require(!initialized, "Init function can only be run once");
        initialized = true;

        // Verify the lengths of values being passed in
        require(_owners.length > 0 && _owners.length <= 10, "Owners List min is 1 and max is 10");
        require(
            _requiredSignatures > 0 && _requiredSignatures <= _owners.length,
            "Required signatures must be in the proper range"
        );

        // Verify the owners list is valid and in order
        // No 0 addresses or duplicates
        address lastAdd = address(0);
        for (uint i = 0; i < _owners.length; i++) {
            require(_owners[i] > lastAdd, "Owner addresses must be unique and in order");
            ownersMap[_owners[i]] = true;
            lastAdd = _owners[i];
        }

        // Save off owner list and required sig.
        owners = _owners;
        requiredSignatures = _requiredSignatures;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(EIP712DOMAINTYPE_HASH,
            NAME_HASH,
            VERSION_HASH,
            chainId,
            address(this),
            SALT)
        );
    }

    /**
     * This function is adapted from the OpenZeppelin libarary but instead of passing in bytes
     * array, it already has the sig fields broken down.
     *
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * (.note) This call _does not revert_ if the signature is invalid, or
     * if the signer is otherwise unable to be retrieved. In those scenarios,
     * the zero address is returned.
     *
     * (.warning) `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise)
     * be too long), and then calling `toEthSignedMessageHash` on it.
     */
    function safeRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * Once the owners of the multisig have signed across the payload, they can submit it to this function.
     * This will verify enough signatures were aggregated and then broadcast the transaction.
     * It can be used to send ETH or trigger a function call against another address (or both).
     *
     * Signatures must be in the correct ascending order (according to associated addresses)
     */
    function submit(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address destination,
        uint value,
        bytes memory data
    ) public returns (bool)
    {
        // Verify initialized
        require(initialized, "Initialization must be complete");

        // Verify signature lengths
        require(sigR.length == sigS.length && sigR.length == sigV.length, "Sig arrays not the same lengths");
        require(sigR.length == requiredSignatures, "Signatures list is not the expected length");

        // EIP712 scheme: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
        // Note that the nonce is always included from the contract state to prevent replay attacks
        // Note that tx.origin is included to ensure only a predetermined account can broadcast
        bytes32 txInputHash = keccak256(abi.encode(TXTYPE_HASH, destination, value, keccak256(data), nonce, tx.origin));
        bytes32 totalHash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, txInputHash));

        // Add in the ETH specific prefix
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, totalHash));

        // Iterate and verify signatures are from owners
        address lastAdd = address(0); // cannot have address(0) as an owner
        for (uint i = 0; i < requiredSignatures; i++) {

            // Recover the address from the signature - if anything is wrong, this will return 0
            address recovered = safeRecover(prefixedHash, sigV[i], sigR[i], sigS[i]);

            // Ensure the signature is from an owner address and there are no duplicates
            // Also verifies error of 0 returned
            require(ownersMap[recovered], "Signature must be from an owner");
            require(recovered > lastAdd, "Signature must be unique");
            lastAdd = recovered;
        }

        // Increment the nonce before making external call
        nonce = nonce + 1;
        (bool success, ) = address(destination).call{value: value}(data);
        if(success) {
            emit Execution(nonce, destination, value, data);
        } else {
            emit ExecutionFailure(nonce, destination, value, data);
        }

        return success;
    }

    // Allow ETH to be sent to this contract
    receive () external payable {
        emit Deposit(msg.sender, msg.value);
    }

}

// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Administratable.sol

pragma solidity 0.6.12;


/**
This contract allows a list of administrators to be tracked.  This list can then be enforced
on functions with administrative permissions.  Only the owner of the contract should be allowed
to modify the administrator list.
 */
contract Administratable is Ownable {

    // The mapping to track administrator accounts - true is reserved for admin addresses.
    mapping (address => bool) public administrators;

    // Events to allow tracking add/remove.
    event AdminAdded(address indexed addedAdmin, address indexed addedBy);
    event AdminRemoved(address indexed removedAdmin, address indexed removedBy);

    /**
    Function modifier to enforce administrative permissions.
     */
    modifier onlyAdministrator() {
        require(isAdministrator(msg.sender), "Calling account is not an administrator.");
        _;
    }

    /**
    Determine if the message sender is in the administrators list.
     */
    function isAdministrator(address addressToTest) public view returns (bool) {
        return administrators[addressToTest];
    }

    /**
    Add an admin to the list.  This should only be callable by the owner of the contract.
     */
    function addAdmin(address adminToAdd) public onlyOwner {
        // Verify the account is not already an admin
        require(administrators[adminToAdd] == false, "Account to be added to admin list is already an admin");

        // Set the address mapping to true to indicate it is an administrator account.
        administrators[adminToAdd] = true;

        // Emit the event for any watchers.
        emit AdminAdded(adminToAdd, msg.sender);
    }

    /**
    Remove an admin from the list.  This should only be callable by the owner of the contract.
     */
    function removeAdmin(address adminToRemove) public onlyOwner {
        // Verify the account is an admin
        require(administrators[adminToRemove] == true, "Account to be removed from admin list is not already an admin");

        // Set the address mapping to false to indicate it is NOT an administrator account.
        administrators[adminToRemove] = false;

        // Emit the event for any watchers.
        emit AdminRemoved(adminToRemove, msg.sender);
    }
}

// File: contracts/Proxy.sol

pragma solidity 0.6.12;

contract Proxy {
    
    // Code position in storage is:
    // keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    uint256 constant PROXIABLE_SLOT = 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;

    constructor(address contractLogic) public {
        // Verify a valid address was passed in
        require(contractLogic != address(0), "Contract Logic cannot be 0x0");

        // save the code address
        assembly { // solium-disable-line
            sstore(PROXIABLE_SLOT, contractLogic)
        }
    }

    fallback() external payable {
        assembly { // solium-disable-line
            let contractLogic := sload(PROXIABLE_SLOT)
            let ptr := mload(0x40)
            calldatacopy(ptr, 0x0, calldatasize())
            let success := delegatecall(gas(), contractLogic, ptr, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(ptr, 0, retSz)
            switch success
            case 0 {
                revert(ptr, retSz)
            }
            default {
                return(ptr, retSz)
            }
        }
    }
}

// File: contracts/LiteSigFactory.sol

pragma solidity 0.6.12;




/**
 * LiteSig Factory creates new instances of the proxy class pointing to the multisig 
 * contract and triggers an event for listeners to see the new contract.
 */
contract LiteSigFactory is Administratable {

  // Event to track deployments
  event Deployed(address indexed deployedAddress);

  // Address where LiteSig logic contract lives
  address public liteSigLogicAddress;

  // Constructor for the factory
  constructor(address _liteSigLogicAddress) public {
    // Add the deployer as an admin by default
    Administratable.addAdmin(msg.sender);

    // Save the logic address
    liteSigLogicAddress = _liteSigLogicAddress;
  }

  /**
   * Function called by external addresses to create a new multisig contract
   * Caller must be whitelisted as an admin - this is to prevent someone from sniping the address
   * (the standard approach to locking in the sender addr into the salt was not chosen in case a long time
   * passes before the contract is created and a new deployment account is required for some unknown reason)
   */
  function createLiteSig(bytes32 salt, address[] memory _owners, uint _requiredSignatures, uint chainId)
    public onlyAdministrator returns (address) {
    // Track the address for the new contract
    address payable deployedAddress;

    // Get the creation code from the Proxy class
    bytes memory code = type(Proxy).creationCode;

    // Pack the constructor arg for the proxy initialization
    bytes memory deployCode = abi.encodePacked(code, abi.encode(liteSigLogicAddress));

    // Drop into assembly to deploy with create2
    assembly {
      deployedAddress := create2(0, add(deployCode, 0x20), mload(deployCode), salt)
      if iszero(extcodesize(deployedAddress)) { revert(0, 0) }
    }

    // Initialize the contract with this master's address
    LiteSig(deployedAddress).init(_owners, _requiredSignatures, chainId);

    // Trigger the event for any listeners
    emit Deployed(deployedAddress);

    // Return address back to caller if applicable
    return deployedAddress;
  }
}