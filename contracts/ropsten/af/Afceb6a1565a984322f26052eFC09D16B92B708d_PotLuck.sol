/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

// SPDX-License-Identifier: Unlicensed


pragma solidity 0.8.3;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
// abstract contract Context {
//     function _msgSender() internal view virtual returns (address) {
//         return msg.sender;
//     }

//     function _msgData() internal view virtual returns (bytes calldata) {
//         this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
//         return msg.data;
//     }
// }
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
// abstract contract Ownable is Context {
//     address private _owner;
//     address private _previousOwner;
//     uint256 private _lockTime;

//     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

//     constructor () {
//         address msgSender = _msgSender();
//         _owner = msgSender;
//         emit OwnershipTransferred(address(0), msgSender);
//     }

//     function owner() public view returns (address) {
//         return _owner;
//     }

//     modifier onlyOwner() {
//         require(_owner == _msgSender(), "Ownable: caller is not the owner");
//         _;
//     }

//     function renounceOwnership() public virtual onlyOwner {
//         _previousOwner = address(0);
//         emit OwnershipTransferred(_owner, address(0));
//         _owner = address(0);
//     }

//     function transferOwnership(address newOwner) public virtual onlyOwner {
//         require(newOwner != address(0), "Ownable: new owner is the zero address");
//         emit OwnershipTransferred(_owner, newOwner);
//         _owner = newOwner;
//     }
    
//     function geUnlockTime() public view returns (uint256) {
//         return _lockTime;
//     }

//     function lock(uint256 time) public virtual onlyOwner {
//         _previousOwner = _owner;
//         _owner = address(0);
//         _lockTime = block.timestamp + time;
//         emit OwnershipTransferred(_owner, address(0));
//     }

//     function unlock() public virtual {
//         require(_previousOwner == msg.sender, "You don't have permission to unlock");
//         require(block.timestamp > _lockTime , "Contract is locked until 0 days");
//         emit OwnershipTransferred(_owner, _previousOwner);
//         _owner = _previousOwner;
//     }
// }
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
contract PotLuck {
    using SafeMath for uint256;
    // EnumerableSet.AddressSet private players;
    mapping(address => uint256) private values;
    // event Received(address sender, uint256 amount);
    //event Bet(address sender, uint256 amount);
    struct TicketInfo {
        address player;
        uint256 amount;
    }
    address[] addresses;
    TicketInfo[] private players;
    uint256 public totalAmountInPot;
    uint256 public maximumBetAmount = 50000000000000000; // 0.05 ether
    uint256 public minimumBetAmount = 5000000000000000; // 0.005 ether
    address public adminWallet = payable(0xcC0c86e51124aF147Bf08dF080A38b58d0A485Fe);
    address public devWallet = payable(0xC9A9f5157592deCAB20EC204cF8355Aa29dF66C5);
    uint256 public winnerPercent = 60;
    event PickedWinner(address winner1, address winnner2, uint256 amount);
    event EnteredInPot(address player, uint256 amount);
    constructor() {
        
    }
    function play() public payable {
        require(msg.value < maximumBetAmount, "Amount should be less than maximum bet amount");
        require(msg.value.mod(minimumBetAmount) == 0, "Amount should be times of minimum bet amount");
        players.push(TicketInfo(msg.sender, msg.value));
        addresses.push(msg.sender);
        totalAmountInPot += msg.value;
        emit EnteredInPot(msg.sender, msg.value);
    }
    function random(uint256 number) public view returns(uint256){
         return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, number, addresses)));
    }
    function getPlayersCountInPot() public view returns(uint256)  {
        return players.length;
    }
    function getWinners() public view returns (uint256, uint256, uint256, uint256) {
        uint index = 1;
        uint256 winner1Index = random(index).mod(players.length);
        index = index.add(1);
        uint256 winner2Index = random(index).mod(players.length);
        while(winner1Index == winner2Index) {
            index = index.add(1);
            winner2Index = random(index).mod(players.length);
        }
        uint256 totalPotAmount = address(this).balance;
        uint256 winner1Amount = totalPotAmount.mul(winnerPercent).div(100).mul(players[winner1Index].amount).div(players[winner1Index].amount.add(players[winner2Index].amount));
        uint256 winner2Amount = totalPotAmount.mul(winnerPercent).div(100).mul(players[winner2Index].amount).div(players[winner1Index].amount.add(players[winner2Index].amount));
        return (winner1Index, winner2Index, winner1Amount, winner2Amount);
    }
    function pickWinner() public {
        require(players.length >= 2, "Should be two and more people in the pot");
        uint index = 1;
        uint256 winner1Index = random(index).mod(players.length);
        index = index.add(1);
        uint256 winner2Index = random(index).mod(players.length);
        while(winner1Index == winner2Index) {
            index = index.add(1);
            winner2Index = random(index).mod(players.length);
        }
        TicketInfo memory player1 = players[winner1Index];
        TicketInfo memory player2 = players[winner2Index];
        address winner1Addr = player1.player;
        address winner2Addr = player2.player;
        // uint256 adminFee = address(this).balance.mul(adminPercent).div(100);
        // adminWallet.call{value: adminFee.div(2)}("");
        // devWallet.call{value: adminFee.div(2)}("");
        uint256 totalPotAmount = address(this).balance;
        uint256 winner1Amount = totalPotAmount.mul(winnerPercent).div(100).mul(player1.amount).div(player1.amount.add(player1.amount));
        uint256 winner2Amount = totalPotAmount.mul(winnerPercent).div(100).mul(player2.amount).div(player2.amount.add(player2.amount));
        (bool success, ) = payable(winner1Addr).call{value: winner1Amount}("");
        (success, ) = payable(winner2Addr).call{value: winner2Amount}("");
        uint256 ownerFee = address(this).balance.div(2);
        (success, ) = adminWallet.call{value: ownerFee}("");
        (success, ) = devWallet.call{value: address(this).balance.sub(ownerFee)}("");
        // addresses = new address[](0);
        // addresses.length = 0;
        // players.length = 0;
        totalAmountInPot = 0;
        emit PickedWinner(player1.player, player2.player, totalPotAmount);
    }
    function resetPlayers() public {
        while (players.length > 0) {
            players.pop();
        }
        totalAmountInPot = 0;
        addresses = new address[](0);
    }
    // function Bet(uint256 amount) public {
        
    //     require(amount < maximumBetAmount, "Amount should be less than maximum bet amount");
    //     require(amount.mod(minimumBetAmount) == 0, "Amount should be times of minimum bet amount");
    //     players.push(TicketInfo(_msgSender(), amount));
    //     totalAmountInPot = totalAmountInPot.add(amount);
    // }
    // receive() external payable {
        
    //     emit Received(msg.sender, msg.value);
    // }
    
}