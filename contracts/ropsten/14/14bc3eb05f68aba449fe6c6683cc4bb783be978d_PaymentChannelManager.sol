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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts/utils/parsers/BytesParserLib.sol

library BytesParserLib {
    function toUint(bytes self, uint8 start, uint8 len) public pure returns(uint res) {
        uint base = 256;
        uint mask = base**len-1;
        assembly{
            res := and(mload(add(self,add(start,len))),mask)
        }
    }

    function toInt(bytes self, uint8 start, uint8 len) public pure returns(int res) {
        return int(toUint(self, start, len));
    }

    function toBool(bytes self, uint position) public pure returns(bool) {
        if (self[position] == 0) {
            return false;
        } else {
            return true;
        }
    }

    function toBytes32(bytes self, uint8 start) public pure returns (bytes32) {
        uint res = toUint(self,start,32);
        return bytes32(res);
    }

    function slice(bytes self, uint8 start, uint8 length) public pure returns (bytes) {
        bytes memory res = new bytes(length);
        for (uint8 i = 0; i < length; i++) {
            res[i] = self[start+i];
        }

        return res;
    }

    function toAddress(bytes self, uint8 start) public pure returns (address) {
        uint res = toUint(self, start, 20);
        return address(res);
    }
}

// File: contracts/utils/parsers/ReceiptParserLib.sol

library ReceiptParserLib {
    using BytesParserLib for bytes;

    uint public constant CHANNEL_RECEIPT_LENGTH = 95;
    uint public constant TRADE_RECEIPT_LENGTH = 166;
    uint public constant RESULT_RECEIPT_LENGTH = 191;

    struct ChannelReceipt {
        address account;
        uint channelNumber;
        uint nonce;
        int tokensRelative;
        uint fee;
        bool close;
    }

    struct TradeReceipt {
        bytes32 gameHash;
        uint beta;
        uint tokensCommited;
        uint rangeSelected;
    }

    struct ResultReceipt {
        bytes32 tradeReceiptHash;
        uint tokensWon;
        uint feePaid;
    }

    function parseChannel(bytes receipt) internal pure returns(ChannelReceipt) {
        require(receipt.length == CHANNEL_RECEIPT_LENGTH || receipt.length == TRADE_RECEIPT_LENGTH || receipt.length == RESULT_RECEIPT_LENGTH);

        address account = receipt.toAddress(0);
        uint channelNumber = receipt.toUint(20, 5);
        uint nonce = receipt.toUint(25, 5);
        int tokensRelative = receipt.toInt(30, 32);
        uint fee = receipt.toUint(62, 32);
        bool close = receipt.toBool(94);

        return ChannelReceipt(
            account,
            channelNumber,
            nonce,
            tokensRelative,
            fee,
            close
        );
    }

    function parseTrade(bytes receipt) internal pure returns(TradeReceipt) {
        require(receipt.length == TRADE_RECEIPT_LENGTH);

        bytes32 gameHash = receipt.toBytes32(95);
        uint beta = receipt.toUint(127, 5);
        uint tokensCommited = receipt.toUint(132, 32);
        uint rangeSelected = receipt.toUint(164, 2);

        return TradeReceipt(
            gameHash,
            beta,
            tokensCommited,
            rangeSelected
        );
    }

    function parseResult(bytes receipt) internal pure returns(ResultReceipt) {
        require(receipt.length == RESULT_RECEIPT_LENGTH);

        bytes32 tradeReceiptHash = receipt.toBytes32(95);
        uint tokensWon = receipt.toUint(127, 32);
        uint feePaid = receipt.toUint(159, 32);

        return ResultReceipt(tradeReceiptHash, tokensWon, feePaid);
    }

    function parseChannelCompatible(bytes receipt) public pure returns(
        address account,
        uint channelNumber,
        uint nonce,
        int tokensRelative,
        uint fee,
        bool close)
    {
        ChannelReceipt memory result = parseChannel(receipt);

        return (result.account, result.channelNumber, result.nonce, result.tokensRelative, result.fee, result.close);
    }

    function parseTradeCompatible(bytes receipt) public pure returns(
        bytes32 gameHash,
        uint beta,
        uint tokensCommited,
        uint rangeSelected)
    {
        TradeReceipt memory result = parseTrade(receipt);

        return(result.gameHash, result.beta, result.tokensCommited, result.rangeSelected);
    }

    function parseResultCompatible(bytes receipt) public pure returns(
        bytes32 tradeReceiptHash,
        uint tokensWon,
        uint feePaid)
    {
        ResultReceipt memory result = parseResult(receipt);

        return (result.tradeReceiptHash, result.tokensWon, result.feePaid);
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

// File: contracts/utils/math/SafeMathInt.sol

library SafeMathInt {
    using SafeMath for uint256;

    function addInt(uint256 a, int256 b) public pure returns(uint256) {
        if (b < 0) {
            return a.sub(uint(b * -1));
        } else {
            return a.add(uint(b));
        }
    }
}

// File: contracts/PaymentChannelManager.sol

contract PaymentChannelManager {
    using SafeMathInt for uint256;
    using SafeMath for uint256;
    using ECRecovery for bytes32;
    using ReceiptParserLib for bytes;

    enum ChannelState { NOT_EXIST, OPEN, CLOSED, WITHDRAWN }

    struct Channel {
        uint tokensPaid;
        uint tokensToWithdraw;
        uint fee;
        ChannelState state;
        uint nonce;
        uint closedDate;
    }

    uint public withdrawAfterTimeout;
    address public serverAddress;
    address public feeBeneficiary;
    mapping(address => Channel[]) public channels;
    ERC20 token;

    event ChannelOpen(address account, uint channelNumber);
    event ChannelFill(address account, uint channelNumber, uint tokens);
    event ChannelClose(address account, uint channelNumber, uint nonce);
    event ChannelChallenge(address account, uint channelNumber, uint nonce);
    event ChannelWithdraw(address account, uint channelNumber);

    constructor(
        ERC20 _token,
        address _serverAddress,
        address _feeBeneficiary,
        uint _closingTimeout
    ) public
    {
        token = _token;
        serverAddress = _serverAddress;
        feeBeneficiary = _feeBeneficiary;
        withdrawAfterTimeout = _closingTimeout;
    }

    function addFunds(uint _tokens) public {
        require(_tokens > 0);
        token.transferFrom(msg.sender, address(this), _tokens);
        uint channelCount = channels[msg.sender].length;

        if (channelCount == 0) {
            openChannel();
        }

        fillChannel(_tokens);
    }

    function closeChannel(bytes _receipt, bytes _clientSignature, bytes _serverSignature) public {
        ReceiptParserLib.ChannelReceipt memory receiptStruct = getVerifiedReceipt(_receipt, _clientSignature, _serverSignature);
        Channel storage channel = channels[receiptStruct.account][receiptStruct.channelNumber];
        require(channel.state == ChannelState.OPEN);

        channel.closedDate = now;
        channel.tokensToWithdraw = channel.tokensPaid.addInt(receiptStruct.tokensRelative);
        channel.fee = receiptStruct.fee;
        channel.nonce = receiptStruct.nonce;

        openChannel();

        if (receiptStruct.close) {
            processWithdrawal(channel, receiptStruct.account, receiptStruct.channelNumber);
        } else {
            channel.state = ChannelState.CLOSED;
            emit ChannelClose(receiptStruct.account, receiptStruct.channelNumber, receiptStruct.nonce);
        }
    }

    function closeChannelWithoutReceipt() public {
        uint channelNumber = channels[msg.sender].length-1;
        Channel storage channel = channels[msg.sender][channelNumber];
        require(channel.state == ChannelState.OPEN);
        require(channel.tokensPaid > 0);

        channel.closedDate = now;
        channel.tokensToWithdraw = channel.tokensPaid;

        openChannel();

        channel.state = ChannelState.CLOSED;
        emit ChannelClose(msg.sender, channelNumber, 0);
    }

    function challengeChannel(bytes _receipt, bytes _clientSignature, bytes _serverSignature) public {
        ReceiptParserLib.ChannelReceipt memory receiptStruct = getVerifiedReceipt(_receipt, _clientSignature, _serverSignature);
        Channel storage channel = channels[receiptStruct.account][receiptStruct.channelNumber];
        require(channel.state == ChannelState.CLOSED);
        require(receiptStruct.nonce > channel.nonce);

        channel.tokensToWithdraw = channel.tokensPaid.addInt(receiptStruct.tokensRelative);
        channel.fee = receiptStruct.fee;
        channel.nonce = receiptStruct.nonce;

        emit ChannelChallenge(receiptStruct.account, receiptStruct.channelNumber, receiptStruct.nonce);

        if (receiptStruct.close) {
            processWithdrawal(channel, receiptStruct.account, receiptStruct.channelNumber);
        }
    }

    function withdrawChannel(address _clientAddress, uint _channelCounter) public onlyClientOrServer(_clientAddress) {
        Channel storage channel = channels[_clientAddress][_channelCounter];
        require(channel.state == ChannelState.CLOSED);
        require(channel.closedDate + withdrawAfterTimeout < now);

        processWithdrawal(channel, _clientAddress, _channelCounter);
    }

    function withdrawAllChannels(address _clientAddress) public onlyClientOrServer(_clientAddress) {
        uint count = userChannelsCount(_clientAddress);
        for (uint i = 0; i < count; i++) {
            if (
                channels[_clientAddress][i].state == ChannelState.CLOSED &&
                channels[_clientAddress][i].closedDate + withdrawAfterTimeout < now
            ) {
                processWithdrawal(channels[_clientAddress][i], _clientAddress, i);
            }

            if (gasleft() < 100000) {
                return;
            }
        }
    }

    function userChannelsCount(address _owner) public view returns(uint) {
        return channels[_owner].length;
    }

    function getVerifiedReceipt(bytes _receipt, bytes _clientSignature, bytes _serverSignature)
        private view returns (ReceiptParserLib.ChannelReceipt)
    {
        ReceiptParserLib.ChannelReceipt memory receiptStruct = _receipt.parseChannel();
        checkSignatures(
            _receipt,
            _clientSignature,
            _serverSignature,
            receiptStruct.account
        );
        require(msg.sender == receiptStruct.account || msg.sender == serverAddress);

        return receiptStruct;
    }

    function checkSignatures(
        bytes _receipt,
        bytes _clientSignature,
        bytes _serverSignature,
        address _clientAddress
    ) private view
    {
        bytes32 receiptHash = keccak256(_receipt).toEthSignedMessageHash();
        require(receiptHash.recover(_clientSignature) == _clientAddress);
        require(receiptHash.recover(_serverSignature) == serverAddress);
    }

    function processWithdrawal(Channel storage _channel, address _clientAddress, uint _channelCounter) private {
        _channel.state = ChannelState.WITHDRAWN;
        if (_channel.tokensToWithdraw > 0) {
            token.transfer(_clientAddress, _channel.tokensToWithdraw);
        }
        if (_channel.fee > 0) {
            token.transfer(feeBeneficiary, _channel.fee);
        }


        emit ChannelWithdraw(_clientAddress, _channelCounter);
    }

    function fillChannel(uint _tokens) private {
        uint lastChannelNumber = channels[msg.sender].length - 1;
        require(lastChannelNumber >= 0);
        require(channels[msg.sender][lastChannelNumber].state == ChannelState.OPEN);

        channels[msg.sender][lastChannelNumber].tokensPaid = channels[msg.sender][lastChannelNumber].tokensPaid.add(_tokens);

        emit ChannelFill(msg.sender, lastChannelNumber, _tokens);
    }

    function openChannel() private {
        Channel memory channel = Channel(
            0,
            0,
            0,
            ChannelState.OPEN,
            0,
            0
        );
        channels[msg.sender].push(channel);

        emit ChannelOpen(msg.sender, channels[msg.sender].length-1);
    }

    modifier onlyClientOrServer(address _client) {
        require(msg.sender == _client || msg.sender == serverAddress);
        _;
    }
}