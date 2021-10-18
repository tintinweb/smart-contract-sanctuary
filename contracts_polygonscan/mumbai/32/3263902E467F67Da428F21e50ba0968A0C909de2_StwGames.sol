/**
 *Submitted for verification at polygonscan.com on 2021-10-17
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/4_StGames.sol

//Always use latest.
pragma solidity ^0.8.9;


contract StwGames is Pausable{

    struct Player {
        string email;
        uint tickets;
        uint lives;
        uint[] badges;
        uint currentBadge;
        uint currentGame;
    }
    
    mapping (address => Player) players;
    address[] public playerAccts;
    
    function createPlayer(address _address, string memory _email, uint _tickets, uint _lives, uint[] memory _badges, uint _currentBadge, uint _currentGame) public whenNotPaused {
        Player memory player = Player(_email, _tickets, _lives, _badges, _currentBadge, _currentGame);
        players[_address] = player;

        player.email = _email;
        player.tickets = _tickets;
        player.lives = _lives;
        player.badges = _badges;
        player.currentBadge = _currentBadge;
        player.currentGame = _currentGame;
        
        playerAccts.push(_address);
        playerAccts.length -1;

    }
    
    function getPlayers() view public whenNotPaused returns(address[] memory) {
        return playerAccts;
    }
    
    function getPlayer(address _address) view public  whenNotPaused returns (string memory, uint, uint, uint[] memory, uint, uint) {
        return (players[_address].email, players[_address].tickets, players[_address].lives, players[_address].badges, players[_address].currentBadge, players[_address].currentGame);
    }
    
    function countPlayers() view public whenNotPaused returns (uint) {
        return playerAccts.length;
    }
}