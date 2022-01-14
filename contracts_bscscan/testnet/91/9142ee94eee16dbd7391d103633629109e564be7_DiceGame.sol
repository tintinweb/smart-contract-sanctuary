/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-10
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/diceGame.sol


pragma solidity ^0.8.7;


interface IRandomGenerator {
         function random() external  returns(uint256);
    }
 
contract DiceGame is  Ownable {

    

    enum GameState { noGame, playing, hasReward }
    struct Game {
        address player;
        uint256 amount;
        uint256 result;
        GameState gameState;
    }
    address RandomGenerator;
    bool public paused = true;
    bytes32 internal keyHash;
    uint256 internal fee;
    mapping(address=>Game) GameResults;// map user to game
    uint256 internal min = 1;
    uint256 internal max = 1000000000000000000;
    event throwDiceEvent (address player, uint256 amount);
    event sendRewardEvent (address player, uint256 reward,  uint256 amount);
    //
    event checkResultEvent(address, uint256, uint256, GameState);
    event winnner(uint256 reward, address winner, uint256 houseFee);
    event tryAgain(uint256 reward, address player);

    constructor() 
    {
    }
    

    function throwDice() public payable  {
        require(msg.value> min && msg.value < max, "Out of range ");
        require(!paused, "game is paused");
        GameResults[msg.sender].gameState = GameState.playing;
        GameResults[msg.sender].player = msg.sender;
        GameResults[msg.sender].amount = msg.value;
        GameResults[msg.sender].result = IRandomGenerator(RandomGenerator).random();
        GameResults[msg.sender].gameState = GameState.hasReward;
        emit throwDiceEvent(GameResults[msg.sender].player,GameResults[msg.sender].amount);
    }   


    function checkResult(address _player) public {
        emit checkResultEvent( GameResults[_player].player, GameResults[_player].amount, GameResults[_player].result, GameResults[_player].gameState);
    }

    function unPauseGame () public onlyOwner {
        paused = false;
    }

    function pauseGame () public onlyOwner {
        paused = true;
    }




    function ClaimReward() public {
        require(!paused, "game is paused");
        require(GameResults[msg.sender].gameState == GameState.hasReward, "No reward yet ");
        uint256 reward; 
        uint256 houseFee;

        uint256 _result = GameResults[msg.sender].result;
        uint256 _amount =  GameResults[msg.sender].amount;

        for(uint256 i=1; i <= 6; i++  ) {

            if(_result == i && _result !=6 ) {
                reward = (_amount / 10) * i;
                houseFee = (reward / 10);
                reward -= houseFee; 
                _safeTransferTo(msg.sender, reward);
                _safeTransferTo(owner(), houseFee);
                emit tryAgain( reward, msg.sender );
                emit sendRewardEvent (msg.sender,reward, GameResults[msg.sender].amount );
            }
            if(_result == 6 ) {
                reward = _amount * 3;
                houseFee = (reward / 10);
                reward -= houseFee; 
                _safeTransferTo(msg.sender, reward);
                _safeTransferTo(owner(), houseFee);
                emit winnner( reward, msg.sender, houseFee);
                emit sendRewardEvent (msg.sender, reward, GameResults[msg.sender].amount );
            }
            
        }
        GameResults[msg.sender].gameState = GameState.noGame;
    }


    function _safeTransferTo(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "Transfer Failed");
    }

    function FundsInject() external payable onlyOwner {
    }

    function FundsExtract(uint256 value) external onlyOwner {
        _safeTransferTo(owner(), value);
    }

    function getDiceVault() public view returns(uint256 balance){
      return (address(this).balance);
    }
    function setRandomGenerator(address _RandomGenerator) public onlyOwner {
      RandomGenerator = _RandomGenerator;
   }

}