/**
 *Submitted for verification at BscScan.com on 2021-10-06
*/

//  SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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





pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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




pragma solidity 0.6.12;

interface IERC20Mint {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




pragma solidity 0.6.12;

library ECDSA {
  function isMessageValid(bytes memory message) public pure returns (bool) {
    return message.length == 136;
  }

  function formMessage(address from, address to, uint amount, uint nonce) external pure
    returns (bytes32)
  {
    bytes32 message = keccak256(abi.encodePacked(
      from,
      to,
      amount,
      nonce
    ));
    return message;
  }

  /**
   * Accepts the (v,r,s) signature and the message and returns the
   * address that signed the signature. It accounts for malleability issue
   * with the native ecrecover.
   */
  function getSigner(
    bytes32 message,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) private pure returns (address) {
    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
    // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
    //
    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
    // these malleable signatures as well.
    require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value");
    require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

    // If the signature is valid (and not malleable), return the signer address
    address signer = ecrecover(hashMessage(message), v, r, s);
    require(signer != address(0), "ECDSA:invalid signature");

    return signer;
  }

  function hashMessage(bytes32 message) internal pure returns (bytes32) {
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    return keccak256(abi.encodePacked(prefix, message));
  }

  /**
    * @dev Returns the address that signed a hashed message (`hash`) with
    * `signature`. This address can then be used for verification purposes.
    *
    * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
    * this function rejects them by requiring the `s` value to be in the lower
    * half order, and the `v` value to be either 27 or 28.
    *
    * IMPORTANT: `hash` _must_ be the result of a hash operation for the
    * verification to be secure: it is possible to craft signatures that
    * recover to arbitrary addresses for non-hashed data. A safe way to ensure
    * this is by receiving a hash of the original message (which may otherwise
    * be too long), and then calling {toEthSignedMessageHash} on it.
    */
  function recoverAddress(
    bytes32 message,
    bytes memory signature
  ) external view returns (address) {
    // Check the signature length
    require(signature.length == 65, "ECDSA: invalid signature length");

    // Divide the signature in r, s and v variables
    bytes32 r;
    bytes32 s;
    uint8 v;

    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solhint-disable-next-line no-inline-assembly
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    return getSigner(message, v, r, s);
  }

  // layout of message :: bytes:
  // offset  0: 32 bytes :: uint256 - message length
  // offset 32: 20 bytes :: address - recipient address
  // offset 52: 32 bytes :: uint256 - value
  // offset 84: 32 bytes :: bytes32 - transaction hash
  // offset 116: 32 bytes :: uint256 - nonce
  // offset 136: 20 bytes :: address - contract address to prevent double spending

  // mload always reads 32 bytes.
  // so we can and have to start reading recipient at offset 20 instead of 32.
  // if we were to read at 32 the address would contain part of value and be corrupted.
  // when reading from offset 20 mload will read 12 bytes (most of them zeros) followed
  // by the 20 recipient address bytes and correctly convert it into an address.
  // this saves some storage/gas over the alternative solution
  // which is padding address to 32 bytes and reading recipient at offset 32.
  // for more details see discussion in:
  // https://github.com/paritytech/parity-bridge/issues/61
  function parseMessage(bytes memory message) internal view returns (
    address recipient,
    uint256 amount,
    uint256 txHash,
    uint256 nonce,
    address contractAddress
  ) {
    require(isMessageValid(message), "ECDSA: parse error invalid message");

    assembly {
      recipient := mload(add(message, 20))
      amount := mload(add(message, 52))
      txHash := mload(add(message, 84))
      nonce := mload(add(message, 116))
      contractAddress := mload(add(message, 136))
    }
  }
}




pragma solidity 0.6.12;




abstract contract BaseBridge is Ownable {
    /**
       @dev Interface for DAO token
        Since tokens are going to be minted and burned on BSC,
        Interface is expended with burn and mint functions
        @notice an interface for dao token
     */
    IERC20Mint public token;
    //address public otherChainBridgeAddress;

    /**
        @notice Mapping for storing addresses transaction nonce
        @notice Each nonce count is personal for each address
     */
    mapping(address => uint256) public transactionId;

    /**
        @notice Mapping for storing processed nonces
        @notice Required for contract in order not to process the same transaction twice
     */
    mapping(address => mapping(uint256 => bool)) public processedTransactions;

    /**
        @notice Enum for checking transaction step in an event
        @notice LOCK for sending tokens to contract
        @notice UNLOCK for sending tokens from contract
     */
    enum Step {LOCK, UNLOCK}

    /**
        @notice This event will be listened by API bridge
     */
    event TransferRequested(
        address indexed from,
        address to,
        uint256 amount,
        uint256 date,
        uint256 indexed transactionId,
        bytes signature,
        Step indexed step
    );

    /**
        @notice Constructor sets address for DAO token interface
        @param _token Address of DAO token
     */
    constructor(address _token) public {
        token = IERC20Mint(_token);
    }

    /**
        @notice Function for getting caller's actual transaction nonce
        @notice This nonce must be used in order to make transaction
        @return Caller's actual nonce
     */
    function GetTransactionId() external view returns (uint256) {
        return transactionId[_msgSender()];
    }
}




pragma solidity 0.6.12;


contract BscBridge is BaseBridge {
    constructor(address _token) public BaseBridge(_token) {}

    /**
        @notice This function is called in order to send tokens from Binance Smart Chain
        to Ethereum
        @notice Sender doesn't need to approve tokens to contract in order to send them, but
        a valid amount of tokens must be on user's account
        @notice If function call is successful, an event is emitted and bridge API
        sends tokens on Ethereum
        @notice Can be called by anyone
        @param _to A receiver address on Ethereum
        @param _amount Amount of tokens to burn on BSC and unlock on Ethereum
        @param _signature A message, signed by sender, required in order to make transaction
        secure
     */
    function sendTokens(
        address _to,
        uint256 _amount,
        bytes memory _signature
    ) external {
        bytes32 message = keccak256(abi.encodePacked(_msgSender(), _to, _amount, transactionId[_msgSender()]));
        require(ECDSA.recoverAddress(message, _signature) == _msgSender(), "Signature mismatch");
        emit TransferRequested(
            _msgSender(),
            _to,
            _amount,
            block.timestamp,
            transactionId[_msgSender()],
            _signature,
            Step.LOCK
        );
        transactionId[_msgSender()]++;

        token.burn(_msgSender(), _amount);
    }

    /**
        @notice This function can called only by Bridge API
        @notice Once an event is emitted on Ethereum, pointing that transaction is requested,
        some amount of tokens are locked on Ethereum and minted on BSC
        @param _from An address on Ethereum which sent a transaction. Required in order to check
        that transaction is valid
        @param _to A receiver address on Binance Smart Chain
        @param _amount Amount of tokens to be minted
        @param  ETHTransactionId Transaction nonce, required to check that transaction is valid
        @param _signature A message, signed by sender, required in order to make transaction
        secure
     */
    function unlockTokens(
        address _from,
        address _to,
        uint256 _amount,
        uint256 ETHTransactionId,
        bytes memory _signature
    ) external onlyOwner {
        require(!processedTransactions[_from][ETHTransactionId], "Transaction already processed");
        bytes32 message = keccak256(abi.encodePacked(_from, _to, _amount, ETHTransactionId));
        require(ECDSA.recoverAddress(message, _signature) == _from, "Signature mismatch");
        processedTransactions[_from][ETHTransactionId] = true;
        emit TransferRequested(_from, _to, _amount, block.timestamp, ETHTransactionId, _signature, Step.UNLOCK);

        token.mint(_to, _amount);
    }
}