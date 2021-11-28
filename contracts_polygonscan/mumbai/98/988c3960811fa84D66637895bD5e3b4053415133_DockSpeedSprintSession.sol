// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract DockSpeedSprintSession is Ownable{

    IERC20 public Speed;
    Session[] public SessionDictionary;

    mapping(uint256 => mapping(address => uint256)) private playerIndexInASession;

    mapping(uint256 => mapping(address => bool)) public IsplayerFinishedASession;

    uint256 public totalSessions;

    struct Session{
        uint256 id;
        address[] racers;
        uint32[] raceTime;
        bool live;
        uint256 poolPrize;
        uint256 endBlock;
    }

    event SessionCreated(uint256 indexed id,uint256 indexed poolPrize, uint256 indexed endBlock);

    event PlayerSession(address indexed racer,uint256 sessionID ,uint32 indexed Racetime);

    event SessionFinished(uint256 indexed id,uint256 indexed winner,uint256 indexed EndBlock);

    constructor(IERC20 _Speed){
        Speed =_Speed;
    }

    function createSession(uint256 _amount)public onlyOwner(){
        Session memory newSession =  Session({
            id : totalSessions,
            racers: new address[](0),
            raceTime: new uint32[](0),
            live: true,
            poolPrize: _amount,
            endBlock: block.number + 1 days
        });
        SessionDictionary.push(newSession);
        totalSessions++;
       emit SessionCreated(totalSessions - 1 , _amount, block.number + 1 days);
    }

    function joinSession(uint256 _sessionId)public{
        require(SessionDictionary[_sessionId].live,"Cant join a finished race");
        require(playerIndexInASession[_sessionId][msg.sender] == 0,"CANT ENTER TWO TIMES IN A RACE");
        SessionDictionary[_sessionId].racers.push(msg.sender);
        SessionDictionary[_sessionId].raceTime.push(0);
        uint256 index = SessionDictionary[_sessionId].racers.length - 1;
        playerIndexInASession[_sessionId][msg.sender] = index;
    }

    function finishSession(uint256 _sessionId,uint32 _finishSession)public{
        require(SessionDictionary[_sessionId].live,"Cant join a finished race");
        require(IsplayerFinishedASession[_sessionId][msg.sender],"Still GameManager doesnt approve your request");

        uint256 index = playerIndexInASession[_sessionId][msg.sender];
        SessionDictionary[_sessionId].raceTime[index] = _finishSession;

        emit PlayerSession(msg.sender, _sessionId , _finishSession);
    }

    function playerFinished(uint256 _sessionId,address racer)public onlyOwner{
        IsplayerFinishedASession[_sessionId][racer] = true;
    }

    function FinishASession(uint256 _sessionID,uint32 playerIndex)public onlyOwner{
        Speed.approve(address(this), SessionDictionary[_sessionID].poolPrize);
        Speed.transfer(SessionDictionary[_sessionID].racers[playerIndex], SessionDictionary[_sessionID].poolPrize);

        SessionDictionary[_sessionID].live = false;
        SessionDictionary[_sessionID].endBlock = block.number;
    }

    function sessionRacersInfo(uint256 _sessionId)public view returns(address[] memory,uint32[]memory){
        return (SessionDictionary[_sessionId].racers,SessionDictionary[_sessionId].raceTime);
    }

    function setSpeed(IERC20 _speed)public onlyOwner{
        Speed = _speed;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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