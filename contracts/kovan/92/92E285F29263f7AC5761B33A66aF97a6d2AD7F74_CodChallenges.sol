pragma solidity >=0.6.0 <0.9.0;
//SPDX-License-Identifier: MIT

/**
 * 
 * @author @viken33 and @famole
 * @title This contract is used to place and handle Bets (or Challenges) for the CodBets Dapp
 * It allows players to place bets against each other which are settled in a trustless fashion
 * A player can place a bet sending value to the contract, including his Call of Duty gamertag,
 * his opponent gamertag and eth address.
 * CodBets searches for the next match they play together, and settles the bet automatically
 * based on a Chainlink Oracle API Request.
 *
 * @dev We use Open Zeppelin SafeMath and Ownable and Chainlink Client
 */


import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/math/SafeMath.sol";

contract CodChallenges is Ownable {
    
    using SafeMath for uint256;
    
    
    struct Challenge {
        address payable player1;
        string gamertag1;
        address payable player2;
        string gamertag2;
        uint256 amount;
        bool accepted;
        bool settled;
        string winner;
        uint acceptedOn;
        uint startOn;
        uint finishOn;
        uint gameMode;
    }
    // gameMode { 1: MP challenge, 2: WZ challenge, 3: WZ kill race }
    
    uint256 public challengeCount;                           // generate challengeIds by counting
    mapping(uint256 => Challenge) public challenges;         // challengeId => Challenge Struct
    mapping(address => uint256[]) public userChallenges;     // maps player => placed challengeIds 
    mapping(bytes32 => uint256) public matches;              // requests => challengeIds
    mapping(address => uint256[]) public receivedChallenges; // maps player => received challengeIds
    
    /** 
    * @dev challenge related Events
    */
    event NewChallenge(
        address indexed _player1,
        uint256 indexed _challengeId,
        address _player2,
        string _gamertag1,
        string _gamertag2,
        uint256 _amount,
        uint _gameMode, 
        uint _startOn,
        uint _finishOn
        );
        
        
    event RemoveChallenge(uint256 indexed _challengeId);
    event ChallengeAccepted(uint256 indexed _challengeId);
    event ChallengeSettled(uint256 indexed _challengeId, string _winner);
    
    /** 
    * @dev constructor defines Chainlink params
    */
    constructor() public {
        challengeCount = 0;
    }

    /** 
    * @notice Sets the challenge Struct linking addresses to gamertags and bet amount with msg.value
    * Returns a challengeId and maps it to player address
    * @param _gamertag1 refers to players in-game id
    * @param _gamertag2 refers to opponent in-game id
    * @param _player2 refers to opponent address
    * @param _amount bet/challenge amount
    * @return challengeid
    */
    
    function placeChallenge(string memory _gamertag1, string memory _gamertag2, address payable _player2, uint256 _amount, uint _gameMode, uint _startOn, uint _finishOn) public payable returns(uint256) {
       
        require(_amount == msg.value, "amount != msg.value");
        require(_amount > 0, "amount invalid");
        
        Challenge memory chall = Challenge({
            player1 : msg.sender,
            gamertag1 : _gamertag1,
            player2 : _player2,
            gamertag2 : _gamertag2,
            amount : _amount,
            accepted : false,
            settled : false,
            winner : "_",
            acceptedOn : 0,
            startOn: _startOn,
            finishOn: _finishOn,
            gameMode: _gameMode });
            
            challengeCount = challengeCount.add(1); // challengeId based on count
            challenges[challengeCount] = chall;
            userChallenges[msg.sender].push(challengeCount);
            receivedChallenges[_player2].push(challengeCount);
            emit NewChallenge(msg.sender, challengeCount, _player2, _gamertag1, _gamertag2, _amount, chall.gameMode, chall.startOn, chall.finishOn);
            return challengeCount;
    }
    
    /** 
    * @notice Removes a challenge, its must be created by the player
    * @param _challengeId challenge Id to be removed
    */

    function removeChallenge(uint256 _challengeId) public {
        require(challenges[_challengeId].player1 == msg.sender, "challenge doesn't belong to player");
        require(challenges[_challengeId].accepted == false, "challenge already accepted");

        for (uint i = 0; i < userChallenges[msg.sender].length; i++) {
            if (userChallenges[msg.sender][i] == _challengeId) {
                userChallenges[msg.sender][i] = 0;
            }
        }
        challenges[_challengeId].player1.transfer(challenges[_challengeId].amount);
        delete challenges[_challengeId];
        emit RemoveChallenge(_challengeId);
        
    }
    
    /** 
    * @notice Accepts a challenge, only the challenged player can accept it
    * it must pay the bet amount along in tx value
    * @param _challengeId challenge to be accepted
    */

    function acceptChallenge(uint256 _challengeId) public payable {
        require(challenges[_challengeId].player2 == msg.sender, "wrong player2");
        require(challenges[_challengeId].amount == msg.value, "wrong amount");
        challenges[_challengeId].amount = challenges[_challengeId].amount.add(msg.value);
        challenges[_challengeId].accepted = true;
        challenges[_challengeId].acceptedOn = block.timestamp;
        emit ChallengeAccepted(_challengeId);
        
    }

    /** 
    * @notice view function to retrieve placed challenges of player
    * @param _addr address of player
    */

    function viewChallenges(address _addr) public view returns(uint256[] memory _userChallenges) {
        return userChallenges[_addr];
    }

    /** 
    * @notice view function to retrieve incoming challenges of player
    * @param _addr address of player
    */

    function viewReceivedChallenges(address _addr) public view returns(uint256[] memory _receivedChallenges) {
        return receivedChallenges[_addr];
    }

    function settle(uint256 _challengeId, address _winner) public onlyOwner {
        // call with challenge Id and address of winner, in case of draw should be called address 0 as winner
        
        Challenge storage chall = challenges[_challengeId];
        require(chall.accepted, "challenge not accepted");
        require(!chall.settled, "challenge already settled");

        if (chall.player1 == _winner) {
            chall.player1.transfer(chall.amount);
            chall.winner = chall.gamertag1;
        } else if (chall.player2 == _winner) {
            chall.player2.transfer(chall.amount);
            chall.winner = chall.gamertag2;
        } else if (_winner == msg.sender) {
            chall.player1.transfer(chall.amount.div(2));
            chall.player2.transfer(chall.amount.div(2));
        } else revert("winner not found in challenge") ;

        chall.settled = true;
        
        emit ChallengeSettled(_challengeId, chall.winner);
    }
    
     
    function cancelChallenge(uint256 _challengeId) public onlyOwner {
        require(challenges[_challengeId].settled == false, "challenge is settled");

        if (challenges[_challengeId].accepted == false) {

        for (uint i = 0; i < userChallenges[challenges[_challengeId].player1].length; i++) {
            if (userChallenges[challenges[_challengeId].player1][i] == _challengeId) {
                userChallenges[challenges[_challengeId].player1][i] = 0;
            }
        }
        challenges[_challengeId].player1.transfer(challenges[_challengeId].amount);
        
        }

        if (challenges[_challengeId].accepted == true) {

        for (uint i = 0; i < userChallenges[challenges[_challengeId].player1].length; i++) {
            if (userChallenges[challenges[_challengeId].player1][i] == _challengeId) {
                userChallenges[challenges[_challengeId].player1][i] = 0;
            }
        }

        for (uint i = 0; i < receivedChallenges[challenges[_challengeId].player2].length; i++) {
            if (receivedChallenges[challenges[_challengeId].player2][i] == _challengeId) {
                receivedChallenges[challenges[_challengeId].player2][i] = 0;
            }
        }
        challenges[_challengeId].player1.transfer(challenges[_challengeId].amount.div(2));
        challenges[_challengeId].player2.transfer(challenges[_challengeId].amount.div(2));
        
        }

        delete challenges[_challengeId];
        emit RemoveChallenge(_challengeId);
    }
    
      
   
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract Ownable is Context {
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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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

