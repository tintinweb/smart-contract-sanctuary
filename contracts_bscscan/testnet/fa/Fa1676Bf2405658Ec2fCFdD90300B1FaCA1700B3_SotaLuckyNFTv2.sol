//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract SotaLuckyNFTv2 is Ownable {
    using SafeMath for uint256;
    struct Round {
        uint256 start;
        uint256 end;
        uint256 specialPrize;
        uint256 firstPrize;
        uint256 secondPrize;
        uint256 thirdPrize;
        uint256 drawTime;
        uint256 roundRandom;
    }
    mapping(uint256 => Round) private rounds;
    mapping(uint256 => address[]) private addressDraw;
    mapping(uint256 => uint256[]) private fourthPrize;
    mapping(uint256 => uint256[]) private fifthPrize;
    uint256 public totalRound;
    mapping(address => bool) isOperator;
    mapping(bytes32 => uint256[]) private lotteryNumbers; 

    constructor() public {
        isOperator[msg.sender] = true;
    }

    function whitelistOperator(address _operator, bool _whitelist)
        external
        onlyOwner
    {
        isOperator[_operator] = _whitelist;
    }

    function getRoundResult(uint256 _roundId)
        public
        view
        returns (
            Round memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        return (rounds[_roundId], fourthPrize[_roundId], fifthPrize[_roundId]);
    }

    function getAddressByIndexAndRound(uint256 _roundId, uint256 _number) public view returns (address) {
        require(_roundId <= totalRound, "Invalid-round-id");
        Round memory round = rounds[_roundId];
        require(_number >= round.start  && _number <= round.end, "Invalid-number");
        if (addressDraw[_roundId].length < _number - round.start + 1) {
            return address(0);
        }
        return (addressDraw[_roundId][_number - round.start]);
    }

    function getLotteryNumber(uint256 _roundId, address _address)
        public
        view
        returns (
            uint256[] memory
        )
    {
        return lotteryNumbers[keccak256(abi.encodePacked(_roundId, _address))];
    }

    function operatorLuckyDraw(uint256 _start, uint256 _end, address[] calldata _addressDraw) external {
        require(isOperator[msg.sender], "Only-operator");
        require(_start > 0 && _end > _start && (_addressDraw.length <= _end - _start + 1), "Invalid-start-end");
        Round memory newRound;
        totalRound = totalRound.add(1);
        newRound.start = _start;
        newRound.end = _end;
        addressDraw[totalRound] = _addressDraw;
        newRound.drawTime = now;
        for (uint256 index = 0; index < _addressDraw.length; index++) {
            lotteryNumbers[keccak256(abi.encodePacked(totalRound, _addressDraw[index]))].push(index + _start);
        }
        
        uint256 randomNumber = uint(keccak256(abi.encodePacked(block.difficulty, now, msg.sender)));
        newRound.roundRandom = randomNumber;
        rounds[totalRound] = newRound;
        calculateResult(totalRound, randomNumber);
    }

    function calculateResult(uint256 _roundId, uint256 randomNumber)
        private
        returns (uint256)
    {
        Round memory round = rounds[_roundId];
        for (uint256 i = 0; i < 10; i++) {
            fifthPrize[_roundId].push(
                randomNumber.div(i + 1).mod(round.end - round.start + 1) +
                    round.start
            );
        }
        for (uint256 i = 0; i < 5; i++) {
            fourthPrize[_roundId].push(
                randomNumber.div((i + 1).mul(fifthPrize[_roundId][i])).mod(
                    round.end - round.start + 1
                ) + round.start
            );
        }
        round.thirdPrize =
            randomNumber.div(3).div(fourthPrize[_roundId][3]).mod(
                round.end - round.start + 1
            ) +
            round.start;
        round.secondPrize =
            randomNumber.div(round.thirdPrize).mod(
                round.end - round.start + 1
            ) +
            round.start;
        round.firstPrize =
            randomNumber.div(round.secondPrize).mod(
                round.end - round.start + 1
            ) +
            round.start;
        round.specialPrize =
            randomNumber.div(8888).mod(round.end - round.start + 1) +
            round.start;
        rounds[_roundId] = round;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

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