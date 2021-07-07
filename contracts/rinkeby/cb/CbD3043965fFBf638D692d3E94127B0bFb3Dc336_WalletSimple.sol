// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

/**
 * Contract that exposes the needed erc20 token functions
*/

abstract contract ERC20Interface {

  /*
  * @dev Send _value amount of tokens to address _to
  * @param _to The destination address
  * @param _value The amount to sent
  */
  function transfer(address _to, uint256 _value) public virtual returns (bool success);

  /*
  * @dev Get the account balance of another account with address _owner
  * @param _owner The address owner
  */
  function balanceOf(address _owner) public virtual view returns (uint256 balance);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

/**
 * Contract that exposes the needed erc721 token functions
*/

abstract contract ERC721Interface {

    /*
    * @dev Send _tokenId token to address _to
    * @param _from The address where the token is assigned
    * @param _to The destination address of the token
    * @param _tokenId The token id
    */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public virtual;

    /*
    * @dev Get the balance of this contract of address owner
    * @param _owner The address where we want to know the balance
    */
    function balanceOf(address _owner) public virtual view returns (uint256 balance);

    /*
    * @dev Returns a token ID owned by owner at a given index of its token list. Use along with balanceOf to enumerate all of owner's tokens.
    * @param _owner The owner address
    * @param _index The index of the token (related to balanceOf)
    */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public virtual view returns (uint256 tokenId);

    /*
    * @dev Returns if the operator is allowed to manage all of the assets of owner.
    * @param _owner The owner address
    * @param _operator The operator address
    */
    function isApprovedForAll(address _owner, address _operator) public virtual view returns (bool approved);

    /*
    * @dev Approve or remove operator as an operator for the caller. Operators can call transferFrom or safeTransferFrom for any token owned by the caller.
    * @param _owner The operator address
    * @param _approved Flag is approved or not
    */
    function setApprovalForAll(address _operator, bool _approved) public virtual;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import './GenuIERC721Receiver.sol';
import './ERC20Interface.sol';
import './ERC721Interface.sol';

/**
 * Contract that will forward any incoming Ether to the creator of the contract
 *
*/
contract Forwarder is GenuIERC721Receiver {
  /*
   * Constants
  */

  bytes4 private constant ERC721_RECEIVED = 0x150b7a02; // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`

  uint256 internal constant SECONDS_IN_A_DAY = 86400;

  /*
   * Data Structures and value
  */

  address public _parentAddress; // Address to which any funds sent to this contract will be forwarded

  /*
   * Events
  */

  event ForwarderDeposited(address from, uint256 value, bytes data);
  event ForwarderDepositedERC721(address indexed from, uint256[] indexed tokenIds, uint256 indexed time);

  /*
   * Modifiers
  */

  /*
   * @dev Modifier that will execute internal code block only if the sender is the parent address
  */
  modifier onlyParent {
    require(msg.sender == _parentAddress, 'Only Parent');
    _;
  }

  /**
   * @dev Modifier that will execute internal code block only if the contract has not been initialized yet
  */
  modifier onlyUninitialized {
    require(_parentAddress == address(0x0), 'Already initialized');
    _;
  }

  /*
   * Payable functions
  */

  /*
   * @dev Default function; Gets called when data is sent but does not match any other function
  */
  fallback() external payable {
    flush();
  }

  /*
   * @dev Default function; Gets called when Ether is deposited with no data, and forwards it to the parent address
  */
  receive() external payable {
    flush();
  }

  /*
   * @dev Initialize the contract, and sets the destination address to that of the creator
   * @param _parentAddress
  */
  function init(address parentAddress) external onlyUninitialized {
    _parentAddress = parentAddress;
    uint256 _value = address(this).balance;

    if (_value == 0) {
      return;
    }

    (bool _success, ) = _parentAddress.call{ value: _value }('');
    require(_success, 'Flush failed');
    // NOTE: since we are forwarding on initialization,
    // we don't have the context of the original sender.
    // We still emit an event about the forwarding but set
    // the sender to the forwarder itself
    emit ForwarderDeposited(address(this), _value, msg.data);
  }

  /**
   * @dev Execute a token transfer of the full balance from the forwarder token to the parent address
   * @param tokenContractAddress the address of the erc20 token contract
  */
  function flushTokens(address tokenContractAddress) external onlyParent {
    ERC20Interface _instance = ERC20Interface(tokenContractAddress);
    address _forwarderAddress = address(this);
    uint256 _forwarderBalance = _instance.balanceOf(_forwarderAddress);
    if (_forwarderBalance == 0) {
      return;
    }

    TransferHelper.safeTransfer(
      tokenContractAddress,
      _parentAddress,
      _forwarderBalance
    );
  }

  /**
   * @dev Execute a token transfer of the full balance from the forwarder token to the parent address
   * @param tokenContractAddress the address of the erc721 token contract
  */
  function flushTokensERC721(address tokenContractAddress) external onlyParent {
    ERC721Interface _instance = ERC721Interface(tokenContractAddress);
    address _forwarderAddress = address(this);
    uint256 _forwarderBalance = _instance.balanceOf(_forwarderAddress);
    if (_forwarderBalance == 0) {
      return;
    }

    if (_instance.isApprovedForAll(_forwarderAddress, _parentAddress) == false) {
      _instance.setApprovalForAll(_parentAddress, true);
    }

    uint256[] memory _tokenIds = new uint256[](_forwarderBalance);

    for(uint256 i = 0; i < _forwarderBalance; i++) {
      uint256 _tokenId = _instance.tokenOfOwnerByIndex(_forwarderAddress, 0);
      _instance.safeTransferFrom(_forwarderAddress, _parentAddress, _tokenId);
      _tokenIds[i] = _tokenId;
    }
    emit ForwarderDepositedERC721(_forwarderAddress, _tokenIds, block.timestamp - (block.timestamp % SECONDS_IN_A_DAY));
  }

  /**
   * @dev Execute a token transfer of the full balance from the forwarder token to the parent address
   * @param tokenContractAddress the address of the erc721 token contract
   * @param quantity the quantity to move
  */
  function flushTokensERC721(address tokenContractAddress, uint256 quantity) external onlyParent {
    ERC721Interface _instance = ERC721Interface(tokenContractAddress);
    address _forwarderAddress = address(this);
    uint256 _forwarderBalance = _instance.balanceOf(_forwarderAddress);
    require(quantity <= _forwarderBalance, "The quantity cannot be greater than current balance");
    if (_forwarderBalance == 0) {
      return;
    }

    if (!_instance.isApprovedForAll(_forwarderAddress, _parentAddress)) {
      _instance.setApprovalForAll(_parentAddress, true);
    }

    uint256[] memory _tokenIds = new uint256[](_forwarderBalance);

    for(uint256 i = 0; i < quantity; i++) {
      uint256 _tokenId = _instance.tokenOfOwnerByIndex(_forwarderAddress, 0);
      _instance.safeTransferFrom(_forwarderAddress, _parentAddress, _tokenId);
      _tokenIds[i] = _tokenId;
    }
    emit ForwarderDepositedERC721(_forwarderAddress, _tokenIds, block.timestamp - (block.timestamp % SECONDS_IN_A_DAY));
  }

  /**
   * @dev Flush the entire balance of the contract to the parent address.
  */
  function flush() public {
    uint256 _value = address(this).balance;

    if (_value == 0) {
      return;
    }

    (bool _success, ) = _parentAddress.call{ value: _value }('');
    require(_success, 'Flush failed');
    emit ForwarderDeposited(msg.sender, _value, msg.data);
  }

  /**
   * @dev Override, this function is a hook and it is called before each token transfer.
   * @param operator The address operator
   * @param from The address from
   * @param tokenId The token id
   * @param data The data
  */
  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
    return ERC721_RECEIVED;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface GenuIERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import './Forwarder.sol';
import './ERC20Interface.sol';
import './GenuIERC721Receiver.sol';
import './ERC721Interface.sol';

/**
 *
 * WalletSimple
 * ============
 *
 * Basic multi-signer wallet designed for use in a co-signing environment where 2 signatures are required to move funds.
 * Typically used in a 2-of-3 signing configuration. Uses ecrecover to allow for 2 signatures in a single transaction.
 *
 * The first signature is created on the operation hash (see Data Formats) and passed to sendMultiSig/sendMultiSigToken
 * The signer is determined by verifyMultiSig().
 *
 * The second signature is created by the submitter of the transaction and determined by msg.signer.
 *
 * Data Formats
 * ============
 *
 * The signature is created with ethereumjs-util.ecsign(operationHash).
 * Like the eth_sign RPC call, it packs the values as a 65-byte array of [r, s, v].
 * Unlike eth_sign, the message is not prefixed.
 *
 * The operationHash the result of keccak256(prefix, toAddress, value, data, expireTime).
 * For ether transactions, `prefix` is "ETHER".
 * For token transaction, `prefix` is "ERC20" and `data` is the tokenContractAddress.
 *
 *
 */
contract WalletSimple is GenuIERC721Receiver {
  // Events
  event Deposited(address from, uint256 value, bytes data);
  event SafeModeActivated(address msgSender);
  event Transacted(
    address msgSender, // Address of the sender of the message initiating the transaction
    address otherSigner, // Address of the signer (second signature) used to initiate the transaction
    bytes32 operation, // Operation hash (see Data Formats)
    address toAddress, // The address the transaction was sent to
    uint256 value, // Amount of Wei sent to the address
    bytes data // Data sent when invoking the transaction
  );

  event TransactedERC721(address msgSender, // Address of the sender of the message initiating the transaction
    bytes32 operation, // Operation hash (see Data Formats)
    address toAddress, // The address the transaction was sent to
    uint256[] tokenIds // The tokenIds sent to toAddress
  );
  event BatchTransfer(address sender, address recipient, uint256 value);
  // this event shows the other signer and the operation hash that they signed
  // specific batch transfer events are emitted in Batcher
  event BatchTransacted(
    address msgSender, // Address of the sender of the message initiating the transaction
    address otherSigner, // Address of the signer (second signature) used to initiate the transaction
    bytes32 operation // Operation hash (see Data Formats)
  );

  // Public fields
  mapping(address => bool) public signers; // The addresses that can co-sign transactions on the wallet
  bool public safeMode = false; // When active, wallet may only send to signer addresses
  bool public initialized = false; // True if the contract has been initialized

  // Internal fields
  uint256 private constant MAX_SEQUENCE_ID_INCREASE = 10000;
  uint256 constant SEQUENCE_ID_WINDOW_SIZE = 10;
  uint256[SEQUENCE_ID_WINDOW_SIZE] recentSequenceIds;

  bytes4 private constant ERC721_RECEIVED = 0x150b7a02; // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`

  /**
   * Set up a simple multi-sig wallet by specifying the signers allowed to be used on this wallet.
   * 2 signers will be required to send a transaction from this wallet.
   * Note: The sender is NOT automatically added to the list of signers.
   * Signers CANNOT be changed once they are set
   *
   * @param allowedSigners An array of signers on the wallet
   */
  function init(address[] calldata allowedSigners) external onlyUninitialized {
    require(allowedSigners.length == 3, 'Invalid number of signers');

    for (uint8 i = 0; i < allowedSigners.length; i++) {
      require(allowedSigners[i] != address(0), 'Invalid signer');
      signers[allowedSigners[i]] = true;
    }
    initialized = true;
  }

  /**
   * Get the network identifier that signers must sign over
   * This provides protection signatures being replayed on other chains
   * This must be a virtual function because chain-specific contracts will need
   *    to override with their own network ids. It also can't be a field
   *    to allow this contract to be used by proxy with delegatecall, which will
   *    not pick up on state variables
   */
  function getNetworkId() internal virtual pure returns (string memory) {
    return 'ETHER';
  }

  /**
   * Get the network identifier that signers must sign over for token transfers
   * This provides protection signatures being replayed on other chains
   * This must be a virtual function because chain-specific contracts will need
   *    to override with their own network ids. It also can't be a field
   *    to allow this contract to be used by proxy with delegatecall, which will
   *    not pick up on state variables
   */
  function getTokenNetworkId() internal virtual pure returns (string memory) {
    return 'ERC20';
  }

  /**
   * Get the network identifier that signers must sign over for batch transfers
   * This provides protection signatures being replayed on other chains
   * This must be a virtual function because chain-specific contracts will need
   *    to override with their own network ids. It also can't be a field
   *    to allow this contract to be used by proxy with delegatecall, which will
   *    not pick up on state variables
   */
  function getBatchNetworkId() internal virtual pure returns (string memory) {
    return 'ETHER-Batch';
  }

  /**
   * Determine if an address is a signer on this wallet
   * @param signer address to check
   * returns boolean indicating whether address is signer or not
   */
  function isSigner(address signer) public view returns (bool) {
    return signers[signer];
  }

  /**
   * Modifier that will execute internal code block only if the sender is an authorized signer on this wallet
   */
  modifier onlySigner {
    require(isSigner(msg.sender), 'Non-signer in onlySigner method');
    _;
  }

  /**
   * Modifier that will execute internal code block only if the contract has not been initialized yet
   */
  modifier onlyUninitialized {
    require(!initialized, 'Contract already initialized');
    _;
  }

  /**
   * Gets called when a transaction is received with data that does not match any other method
   */
  fallback() external payable {
    if (msg.value > 0) {
      // Fire deposited event if we are receiving funds
      Deposited(msg.sender, msg.value, msg.data);
    }
  }

  /**
   * Gets called when a transaction is received with ether and no data
   */
  receive() external payable {
    if (msg.value > 0) {
      // Fire deposited event if we are receiving funds
      Deposited(msg.sender, msg.value, msg.data);
    }
  }

  /**
   * Execute a multi-signature transaction from this wallet using 2 signers: one from msg.sender and the other from ecrecover.
   * Sequence IDs are numbers starting from 1. They are used to prevent replay attacks and may not be repeated.
   *
   * @param toAddress the destination address to send an outgoing transaction
   * @param value the amount in Wei to be sent
   * @param data the data to send to the toAddress when invoking the transaction
   * @param expireTime the number of seconds since 1970 for which this transaction is valid
   * @param sequenceId the unique sequence id obtainable from getNextSequenceId
   * @param signature see Data Formats
   */
  function sendMultiSig(
    address toAddress,
    uint256 value,
    bytes calldata data,
    uint256 expireTime,
    uint256 sequenceId,
    bytes calldata signature
  ) external onlySigner {
    // Verify the other signer
    bytes32 operationHash = keccak256(
      abi.encodePacked(
        getNetworkId(),
        toAddress,
        value,
        data,
        expireTime,
        sequenceId
      )
    );

    address otherSigner = verifyMultiSig(
      toAddress,
      operationHash,
      signature,
      expireTime,
      sequenceId
    );

    // Success, send the transaction
    (bool success, ) = toAddress.call{ value: value }(data);
    require(success, 'Call execution failed');

    emit Transacted(
      msg.sender,
      otherSigner,
      operationHash,
      toAddress,
      value,
      data
    );
  }

  /**
   * Execute a batched multi-signature transaction from this wallet using 2 signers: one from msg.sender and the other from ecrecover.
   * Sequence IDs are numbers starting from 1. They are used to prevent replay attacks and may not be repeated.
   * The recipients and values to send are encoded in two arrays, where for index i, recipients[i] will be sent values[i].
   *
   * @param recipients The list of recipients to send to
   * @param values The list of values to send to
   * @param expireTime the number of seconds since 1970 for which this transaction is valid
   * @param sequenceId the unique sequence id obtainable from getNextSequenceId
   * @param signature see Data Formats
   */
  function sendMultiSigBatch(
    address[] calldata recipients,
    uint256[] calldata values,
    uint256 expireTime,
    uint256 sequenceId,
    bytes calldata signature
  ) external onlySigner {
    require(recipients.length != 0, 'Not enough recipients');
    require(
      recipients.length == values.length,
      'Unequal recipients and values'
    );
    require(recipients.length < 256, 'Too many recipients, max 255');

    // Verify the other signer
    bytes32 operationHash = keccak256(
      abi.encodePacked(
        getBatchNetworkId(),
        recipients,
        values,
        expireTime,
        sequenceId
      )
    );

    // the first parameter (toAddress) is used to ensure transactions in safe mode only go to a signer
    // if in safe mode, we should use normal sendMultiSig to recover, so this check will always fail if in safe mode
    require(!safeMode, 'Batch in safe mode');
    address otherSigner = verifyMultiSig(
      address(0x0),
      operationHash,
      signature,
      expireTime,
      sequenceId
    );

    batchTransfer(recipients, values);
    emit BatchTransacted(msg.sender, otherSigner, operationHash);
  }

  /**
   * Transfer funds in a batch to each of recipients
   * @param recipients The list of recipients to send to
   * @param values The list of values to send to recipients.
   *  The recipient with index i in recipients array will be sent values[i].
   *  Thus, recipients and values must be the same length
   */
  function batchTransfer(
    address[] calldata recipients,
    uint256[] calldata values
  ) internal {
    for (uint256 i = 0; i < recipients.length; i++) {
      require(address(this).balance >= values[i], 'Insufficient funds');

      (bool success, ) = recipients[i].call{ value: values[i] }('');
      require(success, 'Call failed');

      emit BatchTransfer(msg.sender, recipients[i], values[i]);
    }
  }

  /**
   * Execute a multi-signature token transfer from this wallet using 2 signers: one from msg.sender and the other from ecrecover.
   * Sequence IDs are numbers starting from 1. They are used to prevent replay attacks and may not be repeated.
   *
   * @param toAddress the destination address to send an outgoing transaction
   * @param value the amount in tokens to be sent
   * @param tokenContractAddress the address of the erc20 token contract
   * @param expireTime the number of seconds since 1970 for which this transaction is valid
   * @param sequenceId the unique sequence id obtainable from getNextSequenceId
   * @param signature see Data Formats
   */
  function sendMultiSigToken(
    address toAddress,
    uint256 value,
    address tokenContractAddress,
    uint256 expireTime,
    uint256 sequenceId,
    bytes calldata signature
  ) external onlySigner {
    // Verify the other signer
    bytes32 operationHash = keccak256(
      abi.encodePacked(
        getTokenNetworkId(),
        toAddress,
        value,
        tokenContractAddress,
        expireTime,
        sequenceId
      )
    );

    verifyMultiSig(toAddress, operationHash, signature, expireTime, sequenceId);

    TransferHelper.safeTransfer(tokenContractAddress, toAddress, value);
  }

  /**
   * Execute a multi-signature token ERC721 transfer from this wallet using 2 signers: one from msg.sender and the other from ecrecover.
   * Sequence IDs are numbers starting from 1. They are used to prevent replay attacks and may not be repeated.
   *
   * @param toAddress the destination address to send an outgoing transaction
   * @param tokenIds the tokens to transfer
   * @param tokenContractAddress the address of the erc20 token contract
   * @param expireTime the number of seconds since 1970 for which this transaction is valid
   * @param sequenceId the unique sequence id obtainable from getNextSequenceId
   * @param signature see Data Formats
   */
  function sendMultiSigTokenERC721(
    address toAddress,
    uint256[] calldata tokenIds,
    address tokenContractAddress,
    uint256 expireTime,
    uint256 sequenceId,
    bytes calldata signature
  ) external onlySigner {
    require(tokenIds.length > 0, "tokenIds must be an array of length greater than zero.");

    // Verify the other signer
    bytes32 operationHash = keccak256(
      abi.encodePacked(
        getTokenNetworkId(),
        toAddress,
        tokenIds,
        tokenContractAddress,
        expireTime,
        sequenceId
      )
    );

    verifyMultiSig(toAddress, operationHash, signature, expireTime, sequenceId);
    ERC721Interface _instance = ERC721Interface(tokenContractAddress);
    address _contractAddress = address(this);
    require(_instance.balanceOf(_contractAddress) > 0, "The balance is equal to zero. No items found for this contract address.");

    if (_instance.isApprovedForAll(_contractAddress, toAddress) == false) {
      _instance.setApprovalForAll(toAddress, true);
    }

    for(uint256 i = 0; i < tokenIds.length; i++) {
      _instance.safeTransferFrom(_contractAddress, toAddress, tokenIds[i]);
    }

    emit TransactedERC721(
      msg.sender,
      operationHash,
      toAddress,
      tokenIds
    );
  }

  /**
   * Execute a token flush from one of the forwarder addresses. This transfer needs only a single signature and can be done by any signer
   *
   * @param forwarderAddress the address of the forwarder address to flush the tokens from
   * @param tokenContractAddress the address of the erc20 token contract
   */
  function flushForwarderTokens(
    address payable forwarderAddress,
    address tokenContractAddress
  ) external onlySigner {
    Forwarder forwarder = Forwarder(forwarderAddress);
    forwarder.flushTokens(tokenContractAddress);
  }

  /**
   * Execute a token flush from one of the forwarder addresses. This transfer needs only a single signature and can be done by any signer
   *
   * @param forwarderAddress the address of the forwarder address to flush the tokens from
   * @param tokenContractAddress the address of the erc20 token contract
  */
  function flushForwarderTokensERC721(address payable forwarderAddress, address tokenContractAddress) external onlySigner {
    Forwarder _forwarder = Forwarder(forwarderAddress);
    _forwarder.flushTokensERC721(tokenContractAddress);
  }

  /**
   * Execute a token flush from one of the forwarder addresses. This transfer needs only a single signature and can be done by any signer
   *
   * @param forwarderAddress the address of the forwarder address to flush the tokens from
   * @param tokenContractAddress the address of the erc20 token contract
   * @param quantity the quantity to move
  */
  function flushForwarderTokensERC721(address payable forwarderAddress, address tokenContractAddress, uint256 quantity) external onlySigner {
    require(quantity > 0, "The quantity must be greater than zero");
    Forwarder _forwarder = Forwarder(forwarderAddress);
    _forwarder.flushTokensERC721(tokenContractAddress, quantity);
  }

  /**
   * Do common multisig verification for both eth sends and erc20token transfers
   *
   * @param toAddress the destination address to send an outgoing transaction
   * @param operationHash see Data Formats
   * @param signature see Data Formats
   * @param expireTime the number of seconds since 1970 for which this transaction is valid
   * @param sequenceId the unique sequence id obtainable from getNextSequenceId
   * returns address that has created the signature
   */
  function verifyMultiSig(
    address toAddress,
    bytes32 operationHash,
    bytes calldata signature,
    uint256 expireTime,
    uint256 sequenceId
  ) private returns (address) {
    address otherSigner = recoverAddressFromSignature(operationHash, signature);

    // Verify if we are in safe mode. In safe mode, the wallet can only send to signers
    require(!safeMode || isSigner(toAddress), 'External transfer in safe mode');

    // Verify that the transaction has not expired
    require(expireTime >= block.timestamp, 'Transaction expired');

    // Try to insert the sequence ID. Will revert if the sequence id was invalid
    tryInsertSequenceId(sequenceId);

    require(isSigner(otherSigner), 'Invalid signer');

    require(otherSigner != msg.sender, 'Signers cannot be equal');

    return otherSigner;
  }

  /**
   * Irrevocably puts contract into safe mode. When in this mode, transactions may only be sent to signing addresses.
   */
  function activateSafeMode() external onlySigner {
    safeMode = true;
    SafeModeActivated(msg.sender);
  }

  /**
   * @dev Get the balance of this contract related to token ERC721 contract address passed as argument
   * @param tokenContractAddress The contract address
  */
  function balanceOfERC721(address tokenContractAddress) public view onlySigner returns(uint256) {
    ERC721Interface _instance = ERC721Interface(tokenContractAddress);
    address _contractAddress = address(this);
    uint256 _balance = _instance.balanceOf(_contractAddress);
    return _balance;
  }

  /**
   * @dev Get the balance of this contract related to token ERC20 contract address passed as argument
   * @param tokenContractAddress The contract address
  */
  function balanceOfERC20(address tokenContractAddress) public view onlySigner returns(uint256) {
    ERC20Interface _instance = ERC20Interface(tokenContractAddress);
    address _contractAddress = address(this);
    uint256 _balance = _instance.balanceOf(_contractAddress);
    return _balance;
  }

  /**
   * Gets signer's address using ecrecover
   * @param operationHash see Data Formats
   * @param signature see Data Formats
   * returns address recovered from the signature
   */
  function recoverAddressFromSignature(
    bytes32 operationHash,
    bytes memory signature
  ) private pure returns (address) {
    require(signature.length == 65, 'Invalid signature - wrong length');

    // We need to unpack the signature, which is given as an array of 65 bytes (like eth.sign)
    bytes32 r;
    bytes32 s;
    uint8 v;

    // solhint-disable-next-line
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := and(mload(add(signature, 65)), 255)
    }
    if (v < 27) {
      v += 27; // Ethereum versions are 27 or 28 as opposed to 0 or 1 which is submitted by some signing libs
    }

    // protect against signature malleability
    // S value must be in the lower half orader
    // reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/051d340171a93a3d401aaaea46b4b62fa81e5d7c/contracts/cryptography/ECDSA.sol#L53
    require(
      uint256(s) <=
      0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
      "ECDSA: invalid signature 's' value"
    );

    // note that this returns 0 if the signature is invalid
    // Since 0x0 can never be a signer, when the recovered signer address
    // is checked against our signer list, that 0x0 will cause an invalid signer failure
    return ecrecover(operationHash, v, r, s);
  }

  /**
   * Verify that the sequence id has not been used before and inserts it. Throws if the sequence ID was not accepted.
   * We collect a window of up to 10 recent sequence ids, and allow any sequence id that is not in the window and
   * greater than the minimum element in the window.
   * @param sequenceId to insert into array of stored ids
   */
  function tryInsertSequenceId(uint256 sequenceId) private onlySigner {
    // Keep a pointer to the lowest value element in the window
    uint256 lowestValueIndex = 0;
    // fetch recentSequenceIds into memory for function context to avoid unnecessary sloads
    uint256[SEQUENCE_ID_WINDOW_SIZE] memory _recentSequenceIds = recentSequenceIds;
    for (uint256 i = 0; i < SEQUENCE_ID_WINDOW_SIZE; i++) {
      require(_recentSequenceIds[i] != sequenceId, 'Sequence ID already used');

      if (_recentSequenceIds[i] < _recentSequenceIds[lowestValueIndex]) {
        lowestValueIndex = i;
      }
    }

    // The sequence ID being used is lower than the lowest value in the window
    // so we cannot accept it as it may have been used before
    require(
      sequenceId > _recentSequenceIds[lowestValueIndex],
      'Sequence ID below window'
    );

    // Block sequence IDs which are much higher than the lowest value
    // This prevents people blocking the contract by using very large sequence IDs quickly
    require(
      sequenceId <=
      (_recentSequenceIds[lowestValueIndex] + MAX_SEQUENCE_ID_INCREASE),
      'Sequence ID above maximum'
    );

    recentSequenceIds[lowestValueIndex] = sequenceId;
  }

  /**
   * Gets the next available sequence ID for signing when using executeAndConfirm
   * returns the sequenceId one higher than the highest currently stored
  */
  function getNextSequenceId() public view returns (uint256) {
    uint256 highestSequenceId = 0;
    for (uint256 i = 0; i < SEQUENCE_ID_WINDOW_SIZE; i++) {
      if (recentSequenceIds[i] > highestSequenceId) {
        highestSequenceId = recentSequenceIds[i];
      }
    }
    return highestSequenceId + 1;
  }

  /**
   * @dev Override
   * @param operator The address operator
   * @param from The address from
   * @param tokenId The token id
   * @param data The data
  */
  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
    return ERC721_RECEIVED;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}