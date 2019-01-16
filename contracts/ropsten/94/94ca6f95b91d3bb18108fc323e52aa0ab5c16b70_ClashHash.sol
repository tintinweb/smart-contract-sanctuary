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

// File: solidity-rlp/contracts/RLPReader.sol

/*
* @author Hamdi Allam <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c6aea7aba2afe8a7aaaaa7abfff186a1aba7afaae8a5a9ab">[email&#160;protected]</a>
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

// File: contracts/BetStorage.sol

/**
 * @title ClashHash
 * This product is protected under license.  Any unauthorized copy, modification, or use without
 * express written consent from the creators is prohibited.
 */




contract BetStorage is Ownable {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) public bets;
    mapping(address => uint256) public betsSumByOption;
    mapping(address => uint256) public betsSumByUser;
    address public wonOption;

    event BetAdded(address indexed user, address indexed option, uint256 value);
    event Finalized(address indexed option);
    event RewardClaimed(address indexed user, uint256 reward);
    
    function addBet(address user, address option) public payable onlyOwner {
        require(msg.value > 0, "Empty bet is not allowed");
        require(betsSumByUser[user] > 0 || bets[user][option] == 0, "Deny different bets for single user");

        bets[user][option] = bets[user][option].add(msg.value);
        betsSumByOption[option] = betsSumByOption[option].add(msg.value);
        betsSumByUser[user] = betsSumByUser[user].add(msg.value);
        emit BetAdded(user, option, msg.value);
    }

    function finalize(address option, uint256 fee) public onlyOwner {
        require(wonOption == address(0), "Finalization could be called only once");
        require(option != address(0), "Won option should not be zero");

        wonOption = option;
        emit Finalized(option);

        if (betsSumByOption[option] > 0) {
            msg.sender.transfer(address(this).balance.mul(fee).div(100));
            return;
        }
        
        selfdestruct(msg.sender);
    }

    function rewardFor(address user) public view returns(uint256 reward) {
        if (wonOption != address(0)) {
            reward = address(this).balance
                .mul(bets[user][wonOption])
                .div(betsSumByOption[wonOption]);
        }
    }

    function claimReward(address user) public onlyOwner {
        require(wonOption != address(0), "Round not yet finalized");

        uint256 reward = rewardFor(user);
        require(reward > 0, "Reward was claimed previously or never existed");
        betsSumByOption[wonOption] = betsSumByOption[wonOption].sub(bets[user][wonOption]);
        bets[user][wonOption] = 0;
        user.transfer(reward);
        emit RewardClaimed(user, reward);

        if (betsSumByOption[wonOption] == 0) {
            selfdestruct(msg.sender);
        }
    }
}

// File: contracts/ClashHash.sol

/**
 * @title ClashHash
 * This product is protected under license.  Any unauthorized copy, modification, or use without
 * express written consent from the creators is prohibited.
 */





contract ClashHash {
    using SafeMath for uint256;
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;
    
    struct Round {
        BetStorage records;
        uint256 usersCount;
        uint256 betsCount;
        uint256 totalReward;
        address winner;
        bool suicided;
    }

    uint256 constant public MIN_BLOCKS_BEFORE_ROUND = 10;
    uint256 constant public MIN_BLOCKS_AFTER_ROUND = 10;
    uint256 constant public MAX_BLOCKS_AFTER_ROUND = 256;

    uint256 constant public ADMIN_FEE = 5;
    uint256 constant public JACKPOT_FEE = 10;
    uint256 constant public ADMIN_FEE_NOONE_WON = 10;
    uint256 constant public JACKPOT_FEE_NOONE_WON = 90;

    mapping(uint256 => Round) public rounds;
    address private _allowedSender;
    address private _admin = msg.sender;

    //

    event RoundCreated(uint256 indexed blockNumber, address contractAddress);
    event RoundBetAdded(uint256 indexed blockNumber, address indexed user, address indexed option, uint256 value);
    event RoundFinalized(uint256 indexed blockNumber, address indexed option);
    event RewardClaimed(uint256 indexed blockNumber, address indexed user, uint256 reward);

    //

    function () public payable {
        require(msg.sender == _allowedSender, "Do not send ETH directly to the contract");
    }

    function addBet(uint256 blockNumber, address option) public payable {
        require(block.number <= blockNumber.sub(MIN_BLOCKS_BEFORE_ROUND), "It&#39;s too late");

        Round storage round = rounds[blockNumber];
        if (round.records == address(0)) {
            round.records = new BetStorage();
            emit RoundCreated(blockNumber, round.records);
        }

        if (round.records.betsSumByUser(msg.sender) == 0) {
            round.usersCount += 1;
        }
        round.betsCount += 1;
        round.totalReward = round.totalReward.add(msg.value);
        round.records.addBet.value(msg.value)(msg.sender, option);

        emit RoundBetAdded(
            blockNumber,
            msg.sender,
            option,
            msg.value
        );
    }

    function claimRewardWithBlockData(uint256 blockNumber, bytes blockData) public {
        if (blockData.length > 0 && rounds[blockNumber].winner == address(0)) {
            addBlockData(blockNumber, blockData);
        }

        claimRewardForUser(blockNumber, msg.sender);
    }

    function claimRewardForUser(uint256 blockNumber, address user) public {
        Round storage round = rounds[blockNumber];
        require(round.winner != address(0), "Round not yet finished");

        if (!round.suicided) {
            uint256 reward = round.records.rewardFor(user);
            round.records.claimReward(user);
            emit RewardClaimed(blockNumber, user, reward);
        }
    }

    function read(bytes data, uint i) public pure returns(uint) {
        RLPReader.RLPItem[] memory items = data.toRlpItem().toList();
        return items[i].toUint();
    }

    function addBlockData(uint256 blockNumber, bytes blockData) public {
        Round storage round = rounds[blockNumber];
        
        require(round.winner == address(0), "Winner was already submitted");
        require(block.number <= blockNumber.add(MAX_BLOCKS_AFTER_ROUND), "It&#39;s too late, 256 blocks gone");
        require(block.number >= blockNumber.add(MIN_BLOCKS_AFTER_ROUND), "Wait at least 10 blocks");
        require(keccak256(blockData) == blockhash(blockNumber), "Block data isn&#39;t valid");

        RLPReader.RLPItem[] memory items = blockData.toRlpItem().toList();
        address blockBeneficiary = items[2].toAddress();

        round.winner = blockBeneficiary;
        emit RoundFinalized(blockNumber, blockBeneficiary);
        bool noOneWon = (round.records.betsSumByOption(blockBeneficiary) == 0);
        round.suicided = noOneWon;
        uint256 roundBalance = address(round.records).balance;
        
        _allowedSender = round.records;
        round.records.finalize(blockBeneficiary, ADMIN_FEE.add(JACKPOT_FEE));
        delete _allowedSender;

        if (noOneWon) {
            _admin.transfer(roundBalance.mul(ADMIN_FEE_NOONE_WON).div(100));
        } else {
            _admin.transfer(roundBalance.mul(ADMIN_FEE).div(100));
        }
    }
}