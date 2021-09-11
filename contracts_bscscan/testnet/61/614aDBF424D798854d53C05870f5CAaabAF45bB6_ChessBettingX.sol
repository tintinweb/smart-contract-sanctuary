/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

// SPDX-License-Identifier: MIT
// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/utils/Strings.sol



pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: openzeppelin-solidity/contracts/utils/Context.sol



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

// File: contracts/ChessBettingX.sol



pragma solidity ^0.8.0;




contract ChessBettingX is Context {
    mapping(uint => Game) public games;
    address public owner;
    IERC20 private _token;
    uint constant STATUS_PENDING = 0;
    uint constant STATUS_STARTED = 1;
    uint constant STATUS_COMPLETED = 2;
    uint constant STATUS_SETELED = 2;

    struct Game {
        uint256 betAmount;
        uint level;
        uint status;
        address originator;
        address taker;
        address winner;
    }

    modifier isOwner() 
    {
        require(msg.sender == owner,'only owner can do it');
        _;
    }

    function initialize(IERC20 token) public {
        __Context_init_unchained();
        _token = token;
       owner = msg.sender;
    }
 
 function initialized() public {
        __Context_init_unchained();
       owner = msg.sender;
    }

    function __Context_init_unchained() internal {

    }
     
    function createBet(uint _gameId, uint _level, uint _fees) public payable {
        uint fees = validatedFees(_level, _fees);
        require(fees >= 0, "fees not good"); 
        address from = msg.sender;
        if (_fees > 0) {
          _token.transferFrom(from, address(this), _fees);
        }
        games[_gameId] = Game(fees, _level, STATUS_PENDING, from, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000);
        
    }
    
    function takeBet(uint _gameId, uint _level, uint _fees) public payable { 
        //requires the taker to make the same bet amount     
        require(_fees == games[_gameId].betAmount, "bet not valid");
        uint fees = validatedFees(_level, _fees);
        require(fees >= 0, "bet not valid");
        require(games[_gameId].taker == 0x0000000000000000000000000000000000000000, "bet already started");
        address from = msg.sender;
        _token.transferFrom(from, address(this), _fees);
        games[_gameId].taker = from;
        games[_gameId].status = STATUS_STARTED;
        
    }
    
    function getBetAmount(uint _gameId) public view returns (uint) {
      checkPermissions(_gameId, msg.sender);
      return games[_gameId].betAmount;
    }

     function getGamelevel(uint _gameId) public view returns (uint) {
       checkPermissions(_gameId, msg.sender);
       return games[_gameId].level;
     }

     function setWinner(uint _gameId, address addr) external isOwner {
       checkPermissions(_gameId, addr);
       require(games[_gameId].winner == 0x0000000000000000000000000000000000000000, "Winner already selected");
       require(games[_gameId].status == STATUS_STARTED,  Strings.toString(games[_gameId].status));
       games[_gameId].status = STATUS_COMPLETED;
       games[_gameId].winner = addr;
       if(games[_gameId].betAmount > 0) {
       uint bet = games[_gameId].betAmount * 2;
       uint burn = bet / 100 * 20;
       _token.transferFrom(address(this), 0x0000000000000000000000000000000000000000, burn);
       _token.transferFrom(address(this), addr, bet - burn);
     }
      
     }

     function getWinner(uint _gameId) public view returns (address) {
       checkPermissions(_gameId ,msg.sender);
       return games[_gameId].winner;
     }

     
     function checkPermissions(uint _gameId, address sender) private view {
     //only the originator or taker can call this function
        require(sender == games[_gameId].originator || sender == games[_gameId].taker, "address not good" );  
    }

    function validatedFees(uint level, uint fees) private pure returns (uint) {
        if (level == 1) {
            return 0;
        } if (level == 2 && fees == 2 || (level == 3 && fees == 4)) {
            return fees;
        } if (level == 4 && fees == 8 || (level == 5 && fees == 16)) {
            return fees;
        } if (level == 6 && fees == 32 || (level == 7 && fees == 1)) {
            return fees;
        } if (level == 8 && fees == 1 || (level == 9 && fees > 0)) {
            return fees;
        }
         
        return uint(9999999999999);

    }
    
     //returns - [<description>, 'originator', <originator status>, 'taker', <taker status>]
     function getBetStatus(uint _gameId) public view returns
     (string memory description, address originator, string memory originatorStatus, address taker, string memory takerStatus) 
     {
       description =  string(abi.encodePacked("Bet for ", Strings.toString(games[_gameId].betAmount)));
          
        if (games[_gameId].status == STATUS_COMPLETED) {
          description = string(abi.encodePacked(description, "completed and won by ", games[_gameId].winner));
        } else {
            if (games[_gameId].status == STATUS_PENDING) {
             description = string(abi.encodePacked(description, "pending waiting for player"));
           } else if (games[_gameId].status == STATUS_STARTED) {
             description = string(abi.encodePacked(description, " started"));
           } else {
             description = string(abi.encodePacked(description, games[_gameId].status));
           }
        }
        originator = games[_gameId].originator;
        originatorStatus = originator == games[_gameId].winner ? "Won" : "Lost";
        taker = games[_gameId].taker;
        takerStatus = taker == games[_gameId].winner ? "Won" : "Lost";
     }

}