// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AuthorityGranter.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract CustomWagers is AuthorityGranter {
    using SafeMath for uint256;

    struct Wager {
        uint256 endTime;
        uint256 reportingEndTime;            
        uint256 origValue;
        uint256 winningValue;        
        uint256 makerChoice;
        uint256 takerChoice;
        uint256 odds;
        uint256 makerWinnerVote;
        uint256 takerWinnerVote;
        address payable maker;
        address payable taker;
        address payable judge;        
        address payable winner;         
        bool makerCancelRequest;
        bool takerCancelRequest;       
        bool settled;        
    }

    mapping (bytes32 => bool) private cancelled;   
    mapping (bytes32 => Wager) private wagersMap;
    mapping (address => mapping (bytes32 => bool)) private recdRefund;
    mapping  (bytes32 => uint256) private judgesVote;

    
    function makeWager (
        bytes32 wagerId,
        uint256 endTime,
        uint256 reportingEndTime,          
        uint256 origValue,
        uint256 winningValue,        
        uint256 makerChoice,
        uint256 takerChoice,
        uint256 odds,
        uint256 makerWinnerVote,
        uint256 takerWinnerVote,
        address payable maker
        
        )
            external
            onlyAuth             
        {
        Wager memory thisWager = Wager (
            endTime,
            reportingEndTime,
            origValue,
            winningValue,
            makerChoice,
            takerChoice,
            odds,
            makerWinnerVote,
            takerWinnerVote,
            maker,
            payable(address(0)),
            payable(address(0)),
            payable(address(0)),                                       
            false,
            false,                                        
            false
        );
        wagersMap[wagerId] = thisWager;       
    }

    function addJudge (bytes32 wagerId, address payable judge) external onlyAuth {
        wagersMap[wagerId].judge = judge;
    }

    function setCancelled (bytes32 wagerId) external onlyAuth {
        cancelled[wagerId] = true;
    }    

    function setSettled (bytes32 wagerId) external onlyAuth {
        wagersMap[wagerId].settled = true;
    }

    function setMakerWinVote (bytes32 id, uint256 winnerVote) external onlyAuth {
        wagersMap[id].makerWinnerVote = winnerVote;
    }

    function setTakerWinVote (bytes32 id, uint256 winnerVote) external onlyAuth {
        wagersMap[id].takerWinnerVote = winnerVote;
    }

    function setRefund (address bettor, bytes32 wagerId) external onlyAuth {
        recdRefund[bettor][wagerId] = true;
    }

    function setMakerCancelRequest (bytes32 id) external onlyAuth {
        wagersMap[id].makerCancelRequest = true;
    }

    function setTakerCancelRequest (bytes32 id) external onlyAuth {
        wagersMap[id].takerCancelRequest = true;
    }

    function setTaker (bytes32 wagerId, address payable taker) external onlyAuth {
        wagersMap[wagerId].taker = taker;
    }

    function setWinner (bytes32 id, address payable winner) external onlyAuth {
        wagersMap[id].winner = winner;        
    }

    function setJudgesVote (bytes32 id, uint256 vote) external onlyAuth {
        judgesVote[id] = vote;
    }

    // function setLoser (bytes32 id, address loser) external onlyAuth {
    //     wagersMap[id].loser = loser;
    // }

    function setWinningValue (bytes32 wagerId, uint256 value) external onlyAuth {
        wagersMap[wagerId].winningValue = value;
    }

    function getCancelled (bytes32 wagerId) external view returns (bool) {
        return cancelled[wagerId];
    }

    function getEndTime (bytes32 wagerId) external view returns (uint256) {
        return wagersMap[wagerId].endTime;
    } 

    function getReportingEndTime (bytes32 wagerId) external view returns (uint256) {
        return wagersMap[wagerId].reportingEndTime;
    }   

    function getLocked (bytes32 id) external view returns (bool) {
        if (wagersMap[id].taker == address(0)) {
            return false;
        } else {
            return true;
        }
    }

    function getSettled (bytes32 id) external view returns (bool) {
        return wagersMap[id].settled;
    }

    function getMaker(bytes32 wagerId) external view returns (address payable) {
        return wagersMap[wagerId].maker;
    }

    function getTaker(bytes32 wagerId) external view returns (address payable) {
        return wagersMap[wagerId].taker;
    }

    function getMakerChoice (bytes32 wagerId) external view returns (uint256) {
        return wagersMap[wagerId].makerChoice;
    }

    function getTakerChoice (bytes32 wagerId) external view returns (uint256) {
        return wagersMap[wagerId].takerChoice;
    }

    function getMakerCancelRequest (bytes32 wagerId) external view returns (bool) {
        return wagersMap[wagerId].makerCancelRequest;
    }

    function getTakerCancelRequest (bytes32 wagerId) external view returns (bool) {
        return wagersMap[wagerId].takerCancelRequest;
    }

    function getMakerWinVote (bytes32 wagerId) external view returns (uint256) {
        return wagersMap[wagerId].makerWinnerVote;
    }
    
    function getTakerWinVote (bytes32 wagerId) external view returns (uint256) {
        return wagersMap[wagerId].takerWinnerVote;
    }

    function getRefund (address bettor, bytes32 wagerId) external view returns (bool) {
        return recdRefund[bettor][wagerId];
    }    

    function getOdds (bytes32 wagerId) external view returns (uint256) {
        return wagersMap[wagerId].odds;
    }

    function getOrigValue (bytes32 wagerId) external view returns (uint256) {
        return wagersMap[wagerId].origValue;
    }

    function getWinningValue (bytes32 wagerId) external view returns (uint256) {
        return wagersMap[wagerId].winningValue;
    }

    function getWinner (bytes32 wagerId) external view returns (address payable) {
        return wagersMap[wagerId].winner;
    } 
    
    function getLoser (bytes32 wagerId) external view returns (address payable) {
        address payable winner = wagersMap[wagerId].winner;
        address payable maker = wagersMap[wagerId].maker;
        address payable taker = wagersMap[wagerId].taker;
        if (winner == taker) {
            return maker;
        } else if  (winner == maker) {
            return taker;
        } else {
            return payable(address(0));
        }
    }

    function getJudge (bytes32 wagerId) external view returns (address payable) {
        return wagersMap[wagerId].judge;
    }

    function getJudgesVote (bytes32 wagerId) external view returns (uint256) {
        return judgesVote[wagerId];
    }

   


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AuthorityGranter is Ownable {

    mapping (address => bool) internal isAuthorized;  

    modifier onlyAuth () {
        require(isAuthorized[msg.sender], "Only authorized sender will be allowed");               
        _;
    }

    function grantAuthority (address nowAuthorized) external onlyOwner {
        require(isAuthorized[nowAuthorized] == false, "Already granted");
        isAuthorized[nowAuthorized] = true;
    }

    function removeAuthority (address unauthorized) external onlyOwner {
        require(isAuthorized[unauthorized] == true, "Already unauthorized");
        isAuthorized[unauthorized] = false;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  }
}