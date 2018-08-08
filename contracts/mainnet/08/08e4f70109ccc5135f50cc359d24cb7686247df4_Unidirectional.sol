pragma solidity ^0.4.19;




/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
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



/// @title Unidirectional Ether payment channels contract.
contract Unidirectional {
    using SafeMath for uint256;

    struct PaymentChannel {
        address sender;
        address receiver;
        uint256 value; // Total amount of money deposited to the channel.

        uint32 settlingPeriod; // How many blocks to wait for the receiver to claim her funds, after sender starts settling.
        uint256 settlingUntil; // Starting with this block number, anyone can settle the channel.
    }

    mapping (bytes32 => PaymentChannel) public channels;

    event DidOpen(bytes32 indexed channelId, address indexed sender, address indexed receiver, uint256 value);
    event DidDeposit(bytes32 indexed channelId, uint256 deposit);
    event DidClaim(bytes32 indexed channelId);
    event DidStartSettling(bytes32 indexed channelId);
    event DidSettle(bytes32 indexed channelId);

    /*** ACTIONS AND CONSTRAINTS ***/

    /// @notice Open a new channel between `msg.sender` and `receiver`, and do an initial deposit to the channel.
    /// @param channelId Unique identifier of the channel to be created.
    /// @param receiver Receiver of the funds, counter-party of `msg.sender`.
    /// @param settlingPeriod Number of blocks to wait for receiver to `claim` her funds after the sender starts settling period (see `startSettling`).
    /// After that period is over anyone could call `settle`, and move all the channel funds to the sender.
    function open(bytes32 channelId, address receiver, uint32 settlingPeriod) public payable {
        require(isAbsent(channelId));

        channels[channelId] = PaymentChannel({
            sender: msg.sender,
            receiver: receiver,
            value: msg.value,
            settlingPeriod: settlingPeriod,
            settlingUntil: 0
        });

        DidOpen(channelId, msg.sender, receiver, msg.value);
    }

    /// @notice Ensure `origin` address can deposit money into the channel identified by `channelId`.
    /// @dev Constraint `deposit` call.
    /// @param channelId Identifier of the channel.
    /// @param origin Caller of `deposit` function.
    function canDeposit(bytes32 channelId, address origin) public view returns(bool) {
        PaymentChannel memory channel = channels[channelId];
        bool isSender = channel.sender == origin;
        return isOpen(channelId) && isSender;
    }

    /// @notice Add more money to the contract.
    /// @param channelId Identifier of the channel.
    function deposit(bytes32 channelId) public payable {
        require(canDeposit(channelId, msg.sender));

        channels[channelId].value += msg.value;

        DidDeposit(channelId, msg.value);
    }

    /// @notice Ensure `origin` address can start settling the channel identified by `channelId`.
    /// @dev Constraint `startSettling` call.
    /// @param channelId Identifier of the channel.
    /// @param origin Caller of `startSettling` function.
    function canStartSettling(bytes32 channelId, address origin) public view returns(bool) {
        PaymentChannel memory channel = channels[channelId];
        bool isSender = channel.sender == origin;
        return isOpen(channelId) && isSender;
    }

    /// @notice Sender initiates settling of the contract.
    /// @dev Actually set `settlingUntil` field of the PaymentChannel structure.
    /// @param channelId Identifier of the channel.
    function startSettling(bytes32 channelId) public {
        require(canStartSettling(channelId, msg.sender));

        PaymentChannel storage channel = channels[channelId];
        channel.settlingUntil = block.number + channel.settlingPeriod;

        DidStartSettling(channelId);
    }

    /// @notice Ensure one can settle the channel identified by `channelId`.
    /// @dev Check if settling period is over by comparing `settlingUntil` to a current block number.
    /// @param channelId Identifier of the channel.
    function canSettle(bytes32 channelId) public view returns(bool) {
        PaymentChannel memory channel = channels[channelId];
        bool isWaitingOver = isSettling(channelId) && block.number >= channel.settlingUntil;
        return isSettling(channelId) && isWaitingOver;
    }

    /// @notice Move the money to sender, and close the channel.
    /// After the settling period is over, and receiver has not claimed the funds, anyone could call that.
    /// @param channelId Identifier of the channel.
    function settle(bytes32 channelId) public {
        require(canSettle(channelId));
        PaymentChannel storage channel = channels[channelId];
        channel.sender.transfer(channel.value);

        delete channels[channelId];
        DidSettle(channelId);
    }

    /// @notice Ensure `origin` address can claim `payment` amount on channel identified by `channelId`.
    /// @dev Check if `signature` is made by sender part of the channel, and is for payment promise (see `paymentDigest`).
    /// @param channelId Identifier of the channel.
    /// @param payment Amount claimed.
    /// @param origin Caller of `claim` function.
    /// @param signature Signature for the payment promise.
    function canClaim(bytes32 channelId, uint256 payment, address origin, bytes signature) public view returns(bool) {
        PaymentChannel memory channel = channels[channelId];
        bool isReceiver = origin == channel.receiver;
        bytes32 hash = recoveryPaymentDigest(channelId, payment);
        bool isSigned = channel.sender == ECRecovery.recover(hash, signature);

        return isReceiver && isSigned;
    }

    /// @notice Claim the funds, and close the channel.
    /// @dev Can be claimed by channel receiver only. Guarded by `canClaim`.
    /// @param channelId Identifier of the channel.
    /// @param payment Amount claimed.
    /// @param signature Signature for the payment promise.
    function claim(bytes32 channelId, uint256 payment, bytes signature) public {
        require(canClaim(channelId, payment, msg.sender, signature));

        PaymentChannel memory channel = channels[channelId];

        if (payment >= channel.value) {
            channel.receiver.transfer(channel.value);
        } else {
            channel.receiver.transfer(payment);
            channel.sender.transfer(channel.value.sub(payment));
        }

        delete channels[channelId];

        DidClaim(channelId);
    }

    /*** CHANNEL STATE ***/

    /// @notice Check if the channel is present: in open or settling state.
    /// @param channelId Identifier of the channel.
    function isPresent(bytes32 channelId) public view returns(bool) {
        return !isAbsent(channelId);
    }

    /// @notice Check if the channel is not present.
    /// @param channelId Identifier of the channel.
    function isAbsent(bytes32 channelId) public view returns(bool) {
        PaymentChannel memory channel = channels[channelId];
        return channel.sender == 0;
    }

    /// @notice Check if the channel is in settling state: waits till the settling period is over.
    /// @dev It is settling, if `settlingUntil` is set to non-zero.
    /// @param channelId Identifier of the channel.
    function isSettling(bytes32 channelId) public view returns(bool) {
        PaymentChannel memory channel = channels[channelId];
        return channel.settlingUntil != 0;
    }

    /// @notice Check if the channel is open: present and not settling.
    /// @param channelId Identifier of the channel.
    function isOpen(bytes32 channelId) public view returns(bool) {
        return isPresent(channelId) && !isSettling(channelId);
    }

    /*** PAYMENT DIGEST ***/

    /// @return Hash of the payment promise to sign.
    /// @param channelId Identifier of the channel.
    /// @param payment Amount to send, and to claim later.
    function paymentDigest(bytes32 channelId, uint256 payment) public view returns(bytes32) {
        return keccak256(address(this), channelId, payment);
    }

    /// @return Actually signed hash of the payment promise, considering "Ethereum Signed Message" prefix.
    /// @param channelId Identifier of the channel.
    /// @param payment Amount to send, and to claim later.
    function recoveryPaymentDigest(bytes32 channelId, uint256 payment) internal view returns(bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(prefix, paymentDigest(channelId, payment));
    }
}