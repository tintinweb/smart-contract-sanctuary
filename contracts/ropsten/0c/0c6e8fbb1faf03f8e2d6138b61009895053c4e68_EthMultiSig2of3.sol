/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;

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


/**
 * Contract that exposes the needed erc20 token functions
 */
//抽象的erc20接口
abstract contract ERC20Interface {
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value)
    public
    virtual
    returns (bool success);

    // Get the account balance of another account with address _owner
    function balanceOf(address _owner)
    public
    virtual
    view
    returns (uint256 balance);
}


/**
 *
 * EthMultiSig2of3
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
contract EthMultiSig2of3 {

    
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

  /**
   * Set up a simple multi-sig wallet by specifying the signers allowed to be used on this wallet.
   * 2 signers will be required to send a transaction from this wallet.
   * Note: The sender is NOT automatically added to the list of signers.
   * Signers CANNOT be changed once they are set
   *
   * @param allowedSigners An array of signers on the wallet
   */
  function init(address[] calldata allowedSigners) external onlyUninitialized {
  //要求signers的地址为3个
    require(allowedSigners.length == 3, 'Invalid number of signers');

    //初始化
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
      emit Deposited(msg.sender, msg.value, msg.data);
    }
  }

  /**
   * Gets called when a transaction is received with ether and no data
   */
  receive() external payable {
    if (msg.value > 0) {
      // Fire deposited event if we are receiving funds
     emit Deposited(msg.sender, msg.value, msg.data);
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
    //通过operationhash 和 signature 得到另外的一个签名者
    address otherSigner = recoverAddressFromSignature(operationHash, signature);

    //判断是不是在安全模式下 如果在安全模式下的话  那么任何资金都只能转发到合约地址中的一个
    // Verify if we are in safe mode. In safe mode, the wallet can only send to signers
    require(!safeMode || isSigner(toAddress), 'External transfer in safe mode');

    // Verify that the transaction has not expired
    require(expireTime >= block.timestamp, 'Transaction expired');

    //尝试插入序列id  如果序列id不合法的话 revert
    // Try to insert the sequence ID. Will revert if the sequence id was invalid
    tryInsertSequenceId(sequenceId);

    //判断另外的一个签名者是不是合法的
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

  /**验证sequenceId 在插入之前没有被使用过 。 如果不接受序列id的话 那么抛出异常
   * Verify that the sequence id has not been used before and inserts it. Throws if the sequence ID was not accepted.
   我们最多收集最近10个序列id的窗口, 允许不在窗口中  并且大于窗口中的最小元素的序列id
   * We collect a window of up to 10 recent sequence ids, and allow any sequence id that is not in the window and
   * greater than the minimum element in the window.
   * @param sequenceId to insert into array of stored ids
   */
  function tryInsertSequenceId(uint256 sequenceId) private onlySigner {
    // Keep a pointer to the lowest value element in the window
    uint256 lowestValueIndex = 0;
    // fetch recentSequenceIds into memory for function context to avoid unnecessary sloads
    uint256[SEQUENCE_ID_WINDOW_SIZE] memory _recentSequenceIds = recentSequenceIds;
    //遍历序列窗口
    for (uint256 i = 0; i < SEQUENCE_ID_WINDOW_SIZE; i++) {
      //序列id不能出现过 否则就说明这个序列id已经被使用过了
      require(_recentSequenceIds[i] != sequenceId, 'Sequence ID already used');
      //找出窗口中最小的sequenceId
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

    //防止人们使用非常大的序列id 阻止合同
    // Block sequence IDs which are much higher than the lowest value
    // This prevents people blocking the contract by using very large sequence IDs quickly
    require(
      sequenceId <=
        (_recentSequenceIds[lowestValueIndex] + MAX_SEQUENCE_ID_INCREASE),
      'Sequence ID above maximum'
    );

    //更新最小的序列id
    recentSequenceIds[lowestValueIndex] = sequenceId;
  }

  /** 获取窗口中最大的序列id + 1
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
}