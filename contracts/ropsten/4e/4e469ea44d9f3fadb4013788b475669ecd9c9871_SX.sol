pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: solidity-rlp/contracts/RLPReader.sol

/*
* @author Hamdi Allam <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="771f161a131e59161b1b161a4e4037101a161e1b5914181a">[email&#160;protected]</a>
* Please reach out with any questions or concerns
*/
pragma solidity ^0.4.24;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START  = 0xb8;
    uint8 constant LIST_SHORT_START   = 0xc0;
    uint8 constant LIST_LONG_START    = 0xf8;

    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

    /*
    * @param item RLP encoded bytes
    */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        if (item.length == 0) 
            return RLPItem(0, 0);

        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
    * @param item RLP encoded list in bytes
    */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory result) {
        require(isList(item));

        uint items = numItems(item);
        result = new RLPItem[](items);

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr); 
            memPtr = memPtr + dataLen;
        }
    }

    /*
    * Helpers
    */

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) internal pure returns (uint) {
        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
           currPtr = currPtr + _itemLength(currPtr); // skip over an item
           count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint memPtr) internal pure returns (uint len) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            return 1;
        
        else if (byte0 < STRING_LONG_START)
            return byte0 - STRING_SHORT_START + 1;

        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte
                
                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                len := add(dataLen, add(byteLen, 1))
            }
        }

        else if (byte0 < LIST_LONG_START) {
            return byte0 - LIST_SHORT_START + 1;
        } 

        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                len := add(dataLen, add(byteLen, 1))
            }
        }
    }

    // @return number of bytes until the data
    function _payloadOffset(uint memPtr) internal pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) 
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)  // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes) {
        bytes memory result = new bytes(item.len);
        
        uint ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1, "Invalid RLPItem. Booleans are encoded in 1 byte");
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix according to RLP spec
        require(item.len <= 21, "Invalid RLPItem. Addresses are encoded in 20 bytes or less");

        return address(toUint(item));
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;
        uint memPtr = item.memPtr + offset;

        uint result;
        assembly {
            result := div(mload(memPtr), exp(256, sub(32, len))) // shift to the correct location
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes) {
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }


    /*
    * @param src Pointer to source
    * @param dest Pointer to destination
    * @param len Amount of memory to copy from the source
    */
    function copy(uint src, uint dest, uint len) internal pure {
        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

// File: contracts/BlockHashes.sol

contract BlockHashes {
    using SafeMath for uint256;
    using RLPReader for RLPReader.RLPItem;

    mapping (uint256 => bytes32) private _blockHashes;
    mapping (uint256 => bool) private _requiredBlockHashes;

    event BlockHashAssigned(
        uint256 indexed blockNumber,
        bytes32 indexed blockHash
    );

    function blockhashes(uint256 blockNumber) public view returns(bytes32) {
        if (blockNumber.add(256) > block.number) {
            return blockhash(blockNumber);
        }

        return _blockHashes[blockNumber];
    }

    function addRequiredBlockHash(uint256 blockNumber) public {
        _requiredBlockHashes[blockNumber] = true;
    }

    function rememberAllRequiredBlockHashes() public {
        for (uint i = 1; i <= 256; i++) {
            if (_requiredBlockHashes[block.number - i]) {
                if (_rememberBlockHash(block.number - i)) {
                    return;
                }
            }
        }
    }

    function addBlocks(uint256 blockNumber, bytes blocksData, uint256[] starts) public {
        require(starts.length > 0 && starts[starts.length - 1] == blocksData.length, "Wrong starts argument");

        bytes32 expectedHash = blockhashes(blockNumber);
        for (uint i = 0; i < starts.length - 1; i++) {
            uint256 offset = starts[i];
            uint256 length = starts[i + 1].sub(starts[i]);
            bytes32 result;
            uint256 ptr;
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                ptr := add(add(blocksData, 0x20), offset)
                result := keccak256(ptr, length)
            }

            require(result == expectedHash, "Blockhash didn&#39;t match");
            expectedHash = bytes32(RLPReader.RLPItem({len: length, memPtr: ptr}).toList()[0].toUint());
        }
        
        uint256 index = blockNumber.add(1).sub(starts.length);
        if (_blockHashes[index] == 0) {
            _blockHashes[index] = expectedHash;
            emit BlockHashAssigned(index, expectedHash);
        }
    }

    // Returns true if blockNumber is already saved.
    // Keep it internal to avoid someone randomly remeber block hashes,
    // this will brake rememberAllRequiredBlockHashes method loop
    function _rememberBlockHash(uint blockNumber) internal returns(bool) {
        bytes32 blockHash = blockhash(blockNumber);
            
        if (_blockHashes[blockNumber] == 0 && blockHash != 0) {
            _blockHashes[blockNumber] = blockHash;
            if (_requiredBlockHashes[blockNumber]) {
                _requiredBlockHashes[blockNumber] = false;
            }
            emit BlockHashAssigned(blockNumber, blockHash);
            return false;
        }

        return _blockHashes[blockNumber] != 0;
    }
}

// File: contracts/Jackpot.sol

contract Jackpot is Ownable {
    using SafeMath for uint256;

    struct Range {
        uint256 end;
        address player;
    }

    uint256 constant public NO_WINNER = uint256(-1);
    uint256 constant public BLOCK_STEP = 100; // Every 100 blocks
    uint256 constant public PROBABILITY = 1000; // 1/1000

    uint256 public winnerOffset = NO_WINNER;
    uint256 public totalLength;
    mapping (uint256 => Range) public ranges;
    mapping (address => uint256) public playerLengths;

    function () public payable onlyOwner {
    }

    function addRange(address player, uint256 length) public onlyOwner returns(uint256 begin, uint256 end) {
        begin = totalLength;
        end = begin.add(length);

        playerLengths[player] += length;
        ranges[begin] = Range({
            end: end,
            player: player
        });

        totalLength = end;
    }

    function candidateBlockNumberHash() public view returns(uint256) {
        uint256 blockNumber = block.number.sub(1).div(BLOCK_STEP).mul(BLOCK_STEP);
        return uint256(blockhash(blockNumber));
    }

    function shouldSelectWinner() public view returns(bool) {
        return (candidateBlockNumberHash() ^ uint256(this)) % PROBABILITY == 0;
    }

    function selectWinner() public onlyOwner returns(uint256) {
        require(winnerOffset == NO_WINNER, "Winner was selected");
        require(shouldSelectWinner(), "Winner could not be selected now");

        winnerOffset = (candidateBlockNumberHash() / PROBABILITY) % totalLength;
        return winnerOffset;
    }

    function payJackpot(uint256 begin) public onlyOwner {
        Range storage range = ranges[begin];
        require(winnerOffset != NO_WINNER, "Winner was not selected");
        require(begin <= winnerOffset && winnerOffset < range.end, "Not winning range");

        selfdestruct(range.player);
    }
}

// File: contracts/SX.sol

contract SX is Ownable, BlockHashes {
    using SafeMath for uint256;

    uint256 public adminFeePercent = 1; // 1%
    uint256 public jackpotFeePercent = 2; // 2%
    uint256 public minValue = 0.01 ether;
    uint256 public maxValue = 3 ether;
    
    struct Game {
        address player;
        uint256 blockNumber;
        uint256 value;
        uint256 combinations;
        uint256 answer;
    }

    Game[] public games;
    uint256 public gamesFinished;
    uint256 public totalWeisInGame;
    
    Jackpot public nextJackpot;
    Jackpot[] public prevJackpots;

    event GameStarted(
        address indexed player,
        uint256 indexed blockNumber,
        uint256 indexed index,
        uint256 combinations,
        uint256 answer,
        uint256 value
    );
    event GameFinished(
        address indexed player,
        uint256 indexed blockNumber,
        uint256 value,
        uint256 combinations,
        uint256 answer,
        uint256 result
    );

    event JackpotRangeAdded(
        address indexed jackpot,
        address indexed player,
        uint256 indexed begin,
        uint256 end
    );
    event JackpotWinnerSelected(
        address indexed jackpot,
        uint256 offset
    );
    event JackpotRewardPayed(
        address indexed jackpot,
        address indexed player,
        uint256 begin,
        uint256 end,
        uint256 winnerOffset,
        uint256 value
    );

    constructor() public {
        nextJackpot = new Jackpot();
    }

    function () public payable {
        // Coin flip
        uint256 prevBlockHash = uint256(blockhash(block.number - 1));
        play(2, 1 << (prevBlockHash % 2));
    }

    function gamesLength() public view returns(uint256) {
        return games.length;
    }

    function prevJackpotsLength() public view returns(uint256) {
        return prevJackpots.length;
    }

    function updateState() public {
        finishAllGames();

        // Update 256 latest block hashes
        rememberAllRequiredBlockHashes();

        if (nextJackpot.shouldSelectWinner()) {
            nextJackpot.selectWinner();
            emit JackpotWinnerSelected(nextJackpot, nextJackpot.winnerOffset());

            prevJackpots.push(nextJackpot);
            nextJackpot = new Jackpot();
        }
    }

    function playAndFinishJackpot(
        uint256 combinations,
        uint256 answer,
        Jackpot jackpot,
        uint256 begin
    ) 
        public
        payable
    {
        if (jackpot != address(0) && address(jackpot).balance > 0) {
            finishJackpot(jackpot, begin);
        }
        play(combinations, answer);
    }

    function play(uint256 combinations, uint256 answer) public payable {
        uint256 answerSize = _countBits(answer);
        uint256 possibleReward = msg.value.mul(combinations).div(answerSize);
        require(minValue <= possibleReward && possibleReward <= maxValue, "Possible reward value out of range");
        require(answer > 0 && answer < (1 << combinations) - 1, "Answer should not contain all bits set");
        require(2 <= combinations && combinations <= 100, "Combinations value is invalid");

        // Update
        updateState();

        // Play game
        uint256 blockNumber = block.number + 1;
        emit GameStarted(
            msg.sender,
            blockNumber,
            games.length,
            combinations,
            answer,
            msg.value
        );
        addRequiredBlockHash(blockNumber);
        games.push(Game({
            player: msg.sender,
            blockNumber: blockNumber,
            value: msg.value,
            combinations: combinations,
            answer: answer
        }));

        (uint256 begin, uint256 end) = nextJackpot.addRange(msg.sender, msg.value);
        emit JackpotRangeAdded(
            nextJackpot,
            msg.sender,
            begin,
            end
        );

        totalWeisInGame = totalWeisInGame.add(msg.value.mul(combinations));
        require(totalWeisInGame <= address(this).balance, "Not enough balance");
    }

    function finishAllGames() public returns(uint256 count) {
        while (finishNextGame()) {
            count += 1;
        }
    }

    function finishNextGame() public returns(bool) {
        if (gamesFinished >= games.length) {
            return false;
        }

        Game storage game = games[gamesFinished];
        uint256 hash = uint256(blockhashes(game.blockNumber));
        if (hash == 0) {
            return false;
        }

        uint256 answerSize = _countBits(game.answer);
        uint256 reward = game.value.mul(game.combinations).div(answerSize);
        uint256 adminFee = reward.mul(adminFeePercent).div(100);
        uint256 jackpotFee = reward.mul(jackpotFeePercent).div(100);
        
        uint256 result = 1 << (hash % game.combinations);
        if ((result & game.answer) != 0) {
            owner().send(adminFee);                                 // solium-disable-line security/no-send
            address(nextJackpot).send(jackpotFee);                  // solium-disable-line security/no-send
            game.player.send(reward.sub(adminFee).sub(jackpotFee)); // solium-disable-line security/no-send
        }

        emit GameFinished(
            game.player,
            game.blockNumber,
            game.value,
            game.combinations,
            game.answer,
            result
        );
        totalWeisInGame = totalWeisInGame.sub(reward);
        gamesFinished += 1;
        return true;
    }

    function finishJackpot(Jackpot jackpot, uint256 begin) public {
        (uint256 end, address player) = jackpot.ranges(begin);
        uint256 winnerOffset = jackpot.winnerOffset();
        uint256 value = address(jackpot).balance;
        jackpot.payJackpot(begin);
        emit JackpotRewardPayed(
            jackpot,
            player,
            begin,
            end,
            winnerOffset,
            value
        );
    }

    // Admin methods

    function setAdminFeePercent(uint256 feePercent) public onlyOwner {
        require(feePercent <= 2, "Should be <= 2%");
        adminFeePercent = feePercent;
    }

    function setJackpotFeePercent(uint256 feePercent) public onlyOwner {
        require(feePercent <= 3, "Should be <= 3%");
        jackpotFeePercent = feePercent;
    }

    function setMinValue(uint256 value) public onlyOwner {
        minValue = value;
    }

    function setMaxValue(uint256 value) public onlyOwner {
        maxValue = value;
    }

    function putToBank() public payable onlyOwner {
    }

    function getFromBank(uint256 value) public onlyOwner {
        msg.sender.transfer(value);
        require(totalWeisInGame <= address(this).balance, "Not enough balance");
    }

    function _countBits(uint256 arg) internal pure returns(uint256 count) {
        uint256 value = arg;
        while (value != 0) {
            value &= value - 1; // clear the least significant bit set
            count++;
        }
    }
}