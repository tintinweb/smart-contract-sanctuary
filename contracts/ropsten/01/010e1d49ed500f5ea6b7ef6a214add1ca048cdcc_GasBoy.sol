pragma solidity ^0.4.24;

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

// File: openzeppelin-solidity/contracts/ownership/Claimable.sol

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// File: contracts/GasBoy.sol

/*
  GasBoy proxy contract that executes meta transactions for etherless accounts.

  How it works:
  1) An etherless account crafts a meta transaction and signs it
  2) An approved relay account submits the transaction to the GasBoy and pays the gas
  3) If the meta transaction is valid AND the etherless account has approved GasBoy to 
    transferFrom() CUSD on its behalf, the transaction is executed and the relayer 
    is paid in CUSD from the signer

  Inspired by:
    @austintgriffith - https://github.com/austintgriffith/bouncer-proxy
    @avsa - https://www.youtube.com/watch?v=qF2lhJzngto found this later: https://github.com/status-im/contracts/blob/73-economic-abstraction/contracts/identity/IdentityGasRelay.sol
    @mattgcondon - https://twitter.com/mattgcondon/status/1022287545139449856 && https://twitter.com/mattgcondon/status/1021984009428107264
    @owocki - https://twitter.com/owocki/status/1021859962882908160
    @danfinlay - https://twitter.com/danfinlay/status/1022271384938983424
    @PhABCD - https://twitter.com/PhABCD/status/1021974772786319361
    gnosis-safe
    uport-identity
*/


/**
* @dev GasBoy proxy contract that executes meta transactions for etherless accounts.
*/ 
contract GasBoy is Claimable {

  /** @dev STORAGE stores signer transaction nonces to prevent replay attacks **/
  mapping(address => uint) public nonce;

  /** @dev STORAGE stores approved relayers who can call GasBoy::forward() **/
  mapping(address => bool) public relayers;

  constructor() public {
    updateRelayer(msg.sender, true);
  }

  /** FALLBACK FUNCTION **/
  // copied from https://github.com/uport-project/uport-identity/blob/develop/contracts/Proxy.sol
  function () public payable { emit Received(msg.sender, msg.value); }


  /** MODIFIERS **/
  modifier onlyRelayer() {
    require(relayers[msg.sender], "sender is not an approved relayer");
    _;
  }

  /** EVENTS **/
  event UpdateRelayers(address indexed _account, bool _status);
  event Received (address indexed sender, uint value);
  event Forwarded (bytes sig, address indexed signer, address indexed destination, uint value, bytes data,address rewardToken, uint rewardAmount,bytes32 _hash);


  /** PAYABLE ACTIONS */

  /**
  * @dev Toggle relayer _account ability to forward metatransactions to GasBoy 
  * @param _account pending relayer account
  */
  function updateRelayer(address _account, bool _status) public onlyOwner {
   relayers[_account] = _status;
   emit UpdateRelayers(_account, _status);
  }

  // original forward function copied from https://github.com/uport-project/uport-identity/blob/develop/contracts/Proxy.sol
  /**
  * @dev Forward signer&#39;s signed metatransaction from relayer to GasBoy
  * @param sig signature of transaction
  * @param signer signer of transaction
  * @param destination transaction is sent to this contract
  * @param value amount of ETH contained in transaction
  * @param data transaction data to send
  * @param rewardToken address of token to pay relayer in
  * @param rewardAmount amount of token to pay relayer in
  */
  function forward(bytes sig, address signer, address destination, uint value, bytes data, address rewardToken, uint rewardAmount) public onlyRelayer {
      bytes32 _hash = getHash(signer, destination, value, data, rewardToken, rewardAmount);
      //increment the hash so this tx can&#39;t run again
      nonce[signer]++;
      address _signer = recoverHashSigner(_hash, sig);
      require(_signer == signer, "signer did not sign transaction as claimed");

      // Compensate Relayer in CUSD for spending ETH on behalf of signer
      if(rewardAmount>0){
          require(rewardToken != address(0), "reward token address not specified");
          require((StandardToken(rewardToken)).allowance(_signer, address(this)) >= rewardAmount, "GasBoy::forward Signer did not approve GasBoy to transferFrom");
          require((StandardToken(rewardToken)).transferFrom(signer, msg.sender, rewardAmount), "StandardToken::transferFrom reverted");
      }

      require(executeCall(destination, value, data), "GasBoy::forward executeCall forwarded metatransaction failed");
      emit Forwarded(sig, signer, destination, value, data, rewardToken, rewardAmount, _hash);
  }

  /** CALLABLE/NONPAYABLE ACTIONS **/

  /**
  * @dev Return hash containing all metatransaction information
  * @param signer signer of transaction
  * @param destination transaction is sent to this contract
  * @param value amount of ETH contained in transaction
  * @param data transaction data to send
  * @param rewardToken address of token to pay relayer in
  * @param rewardAmount amount of token to pay relayer in
  * @return bytes32 hash
  */
  function getHash(
    address signer, 
    address destination, 
    uint value, 
    bytes data, 
    address rewardToken, 
    uint rewardAmount
  ) public view returns(bytes32){
    return keccak256(abi.encodePacked(
      address(this), 
      signer, 
      destination, 
      value, 
      data, 
      rewardToken, 
      rewardAmount, 
      nonce[signer]
    ));
  }

  /** INTERNAL HELPER FUNCTIONS **/

  // copied from https://github.com/uport-project/uport-identity/blob/develop/contracts/Proxy.sol
  // which was copied from GnosisSafe
  // https://github.com/gnosis/gnosis-safe-contracts/blob/master/contracts/GnosisSafe.sol
  /**
  * @dev Broadcast signed metatransaction to EVM
  * @param to transaction is sent to this contract
  * @param value amount of ETH contained in transaction
  * @param data transaction data to send
  * @return True if successful False otherwise
  */
  function executeCall(address to, uint256 value, bytes data) internal returns (bool success) {
    assembly {
       success := call(gas, to, value, add(data, 0x20), mload(data), 0, 0)
    }
  }

  //borrowed from OpenZeppelin&#39;s ESDA:
  //https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/cryptography/ECDSA.sol
  /**
  * @dev Recover signer address from a message by using their signature
  * @param _hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
  * @param _signature bytes signature, the signature is generated using web3.eth.sign()
  * @return address of hash signer
  */
  function recoverHashSigner(bytes32 _hash, bytes _signature) internal view returns (address){
    bytes32 r;
    bytes32 s;
    uint8 v;

    require(_signature.length == 65, "invalid signature length");

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(_signature, 32))
      s := mload(add(_signature, 64))
      v := byte(0, mload(add(_signature, 96)))
    }
    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }
    require(v == 27 || v == 28, "signature.v(ersion) should be 27 or 28");
    return ecrecover(keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
    ), v, r, s);
  }
}

contract StandardToken {
  function transferFrom(address _from, address _to,uint256 _value) public returns (bool) {}
  function allowance(address _owner,address _spender) public view returns (uint256) {}
}