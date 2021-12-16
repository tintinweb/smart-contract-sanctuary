// Coin Fantasy Game
// SPDX-License-Identifier: CoinFantasy.io

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EnjinStaking.sol";

contract MultiGame is Ownable, ReentrancyGuard {

    struct Player {
        address player;
        uint256[] coins;
        uint256[] weightage;
    }

    enum Status {
        Activated,
        Live,
        Completed,
        Expired
    }

    struct GameInfo {
        address gameOwner;
        uint256 curNumPlayers;
        uint256 numCoins;
        uint256 gameTime;
        uint256 waitTime;
        uint256 entryAmt;
        uint256[] winnerWeights;
        uint256 numPlayers;
        Status gameStatus;
        uint256 createdTime;
        uint256 startTime;
        mapping(uint256 => Player) players;
    }
    uint public currentGameId;
    mapping(uint => GameInfo) public gameList;
    address public orgAddress;

    EnjinStaking enjinStaking;

    constructor(address _orgAddress){
        orgAddress = _orgAddress;
    }

    modifier onlyOrgAddress {
        require(_msgSender() == orgAddress, "only the organization can handle the game");
        _;
    }

    function updateEnjinStakingContract(address _enjinStaking) public onlyOwner {
        enjinStaking = EnjinStaking(_enjinStaking);
    }

    function updateOrgAddress(address _orgAddress) public onlyOwner {
        orgAddress = _orgAddress;
    }

    function pseudoConstructor(
        uint256 _numCoins,//                    -1
        uint256 _gameTime,//                    -2
        uint256 _waitTime,//                    -3
        uint256 _numPlayers,//                  -4
        uint256 _numWinners,//                  -5
        uint256[] memory _winnerWeights,//      -6
        uint256 _lockIn,//                      -8
        uint256 _entryAmt//           -9
    ) public nonReentrant {
        require(
            _numWinners == _winnerWeights.length,
            "Number of winners doesn't match with the weightage of winners"
        );
        currentGameId++;
        GameInfo storage newGame = gameList[currentGameId];

        newGame.gameOwner = _msgSender();
        newGame.winnerWeights = _winnerWeights;
        newGame.numPlayers = _numPlayers;
        newGame.curNumPlayers = 0;
        newGame.numCoins = _numCoins;
        newGame.gameTime = _gameTime;
        newGame.waitTime = _waitTime;
        newGame.entryAmt = _entryAmt;
        newGame.gameStatus = Status.Activated;
        newGame.createdTime = block.timestamp;

        enjinStaking.initiateGame(_msgSender(), _lockIn, _entryAmt, _entryAmt * _numPlayers, currentGameId);
    }
   
    function joinGame(uint256[] memory _coins, uint256[] memory _weightage, uint256 _gameId)
        public nonReentrant
        returns (uint256)
    {
        GameInfo storage currentGame = gameList[_gameId];
        require(currentGame.gameStatus == Status.Activated, "The game is not active for joining");
        require(currentGame.curNumPlayers < currentGame.numPlayers, "The player count reached!");
        require(_coins.length >= currentGame.numCoins, "You have to choose at least 7 coins");
        require(_weightage.length == _coins.length, "Weightage for all coins is not present");

        uint256 totalWeightage = 0;
        for (uint256 i = 0; i < _weightage.length; i++) {
            totalWeightage += _weightage[i];
        }

        require(totalWeightage > 0 && totalWeightage < 100, "Weightage is not proper");

        Player storage newPlayer = currentGame.players[currentGame.curNumPlayers++];
        newPlayer.player = _msgSender();
        newPlayer.coins = _coins;
        newPlayer.weightage = _weightage;

        enjinStaking.joinGame(_msgSender(), _gameId);

        return _gameId;
    }

     function startGame(uint256 _gameId) public nonReentrant onlyOrgAddress {
        GameInfo storage currentGame = gameList[_gameId];
        require(currentGame.gameStatus == Status.Activated, "The game is not active");
        require(currentGame.curNumPlayers == currentGame.numPlayers, "Mismatch in number of players.");
        require(block.timestamp - currentGame.createdTime <= currentGame.waitTime*1);
        currentGame.gameStatus = Status.Live;
        currentGame.startTime = block.timestamp;
    }

    function expiredGame(uint256 _gameId) public nonReentrant onlyOrgAddress {
        GameInfo storage currentGame = gameList[_gameId];
        require(currentGame.gameStatus != Status.Activated, "The game is not active");
        require(currentGame.gameStatus != Status.Expired, "The game already expired");
        require(currentGame.curNumPlayers < currentGame.numPlayers, "Player count reached");
        require(block.timestamp - currentGame.createdTime > currentGame.waitTime*1);
        currentGame.gameStatus = Status.Expired;
        enjinStaking.cancelGame(_gameId);
    }

    function endGame(uint256 _gameId) public nonReentrant onlyOrgAddress returns (bool) {
        GameInfo storage currentGame = gameList[_gameId];
        require(currentGame.gameStatus == Status.Live, "The game is not live");
        require(block.timestamp - currentGame.startTime > currentGame.gameTime * 1, "Game is still in progress");

        currentGame.gameStatus = Status.Completed;
        return true;
    }

    function distributePrize(uint256 _gameId, address[] memory _winners) public nonReentrant onlyOrgAddress {
        GameInfo storage currentGame = gameList[_gameId];
        require(_winners.length == currentGame.winnerWeights.length, "Mismatch in number of winners");
        require(currentGame.gameStatus == Status.Completed, "The game has not been completed");
        require(block.timestamp - currentGame.startTime > currentGame.gameTime * 1, "Game is still in progress");

        enjinStaking.distributeReward(_gameId, _winners, currentGame.winnerWeights);

        
    }

    function getGameState(uint256 _gameId)
        public
        view
        returns (
            address,// gameOwner,               -1
            uint256,// gamePool,                -2
            uint256,// numPlayers,              -3
            uint256,// numCoins,                -4
            //gameTime - should be in seconds
            uint256,// gameTime,                -5
            uint256,// numWinners,              -6
            uint256,// entryAmt       -7
            uint256,//startTime                 -8
            uint256//ends in                    -9
        )
    {
        GameInfo storage currentGame = gameList[_gameId];
        require(currentGame.gameStatus != Status.Activated, "The game is not activated");
        return (
            currentGame.gameOwner,
            currentGame.entryAmt * currentGame.numPlayers,
            currentGame.curNumPlayers,
            currentGame.numCoins,
            currentGame.gameTime,
            currentGame.winnerWeights.length,
            currentGame.entryAmt,
            currentGame.startTime,
            currentGame.gameTime * 1 - (block.timestamp - currentGame.startTime)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

// Coin Fantasy Game
// SPDX-License-Identifier: CoinFantasy.io

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/access/Ownable.sol";


contract EnjinStaking is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  struct StakeInfo {
    uint256 stakedAmt;
    uint256 activeAmt;
  }

  struct GameInfo {
    address gameOwner;
    uint256 entryAmt;
    uint256 lockAmt;
    uint256 totalAmt;
    address[] userList;
    mapping (address => bool) participants;
  }

  struct LockInfo {
    uint256 timeLock;
    uint256 amt;
  }

  mapping (address => StakeInfo) public stakingInfo;
  mapping (uint => GameInfo) public gameInfo;
  mapping (address => LockInfo[]) public lockInfo;
  mapping (address => bool) whiteListedCreators;
  
  address private coinGameAddress;

  IERC20 public EnjinToken;

  constructor(address _enjin) {
    EnjinToken = IERC20(_enjin);
  }

  modifier onlyCoinGameContract {
    require(_msgSender() == coinGameAddress, "Only CoinGame contract can manage this contract");
    _;
  }

  modifier onlyWhiteListedUser {
    require(whiteListedCreators[_msgSender()] == true, "Only White-listed users can add liqudity to this contract");
    _;
  }

  function updateCoinGameAddress(address _coingame) public onlyOwner {
    coinGameAddress = _coingame;
  }

  function addWhiteListedCreator(address _creator) public onlyOwner {
    whiteListedCreators[_creator] = true;
  }

  function removeWhiteListedCreator(address _creator) public onlyOwner {
    whiteListedCreators[_creator] = false;
  }
  
  function initiateGame(address _gameOwner, uint256 _lockAmount, uint256 _entryAmount, uint256 _totalAmount, uint256 _gameId) public nonReentrant onlyCoinGameContract {
    if( !whiteListedCreators[_gameOwner] ) {
      StakeInfo storage currentInfo = stakingInfo[_gameOwner];
      require(currentInfo.activeAmt >= _lockAmount, "Insufficient credit in the address");
      currentInfo.activeAmt -= _lockAmount;
    }
    require(_entryAmount > 0, "No free game");
    GameInfo storage _currentInfo = gameInfo[_gameId];
    _currentInfo.entryAmt = _entryAmount;
    _currentInfo.gameOwner = _gameOwner;
    _currentInfo.totalAmt = _totalAmount;
    _currentInfo.lockAmt = _lockAmount;
  }

  function stakeEnjin(uint256 _amount) public nonReentrant {
    require(EnjinToken.allowance(_msgSender(), address(this)) >= _amount, "Allowance amount is insufficient");
    require(EnjinToken.balanceOf(_msgSender()) >= _amount, "Insufficient enjin token in the address");
    EnjinToken.safeTransferFrom(_msgSender(), address(this), _amount);
    StakeInfo storage _currentInfo = stakingInfo[_msgSender()];
    _currentInfo.stakedAmt += _amount;
    _currentInfo.activeAmt += _amount;
  }

  function joinGame(address _user, uint256 _gameId) public nonReentrant onlyCoinGameContract {
    StakeInfo storage _currentInfo = stakingInfo[_user];
    GameInfo storage _currentGame = gameInfo[_gameId];
    require(!_currentGame.participants[_user], "User already joined the game");
    require(_currentInfo.activeAmt >= _currentGame.entryAmt, "User does not have enough Enjin token");
    _currentInfo.activeAmt -= _currentGame.entryAmt;
    _currentGame.participants[_user] = true;
    _currentGame.userList.push(_user);
  }

  function cancelGame(uint256 _gameId) public nonReentrant onlyCoinGameContract {
    GameInfo storage _currentGame = gameInfo[_gameId];
    address[] memory userList = _currentGame.userList;
    for (uint256 index = 0; index < userList.length; index++) {
      StakeInfo storage _currentInfo = stakingInfo[userList[index]];
      _currentInfo.activeAmt += _currentGame.entryAmt;
    }
  }

  function distributeReward(uint256 _gameId, address[] memory _winners, uint256[] memory _winnerWeights) public nonReentrant onlyCoinGameContract {
    GameInfo storage _currentGame = gameInfo[_gameId];
    uint256 totalAmt = _currentGame.totalAmt;
    uint256 rewardOwner = _currentGame.lockAmt * 2;
    for (uint256 index = 0; index < _winners.length; index++) {
      require(totalAmt >= _winnerWeights[index], "Insufficient reward amount");
      totalAmt -= _winnerWeights[index];
      stakingInfo[_winners[index]].stakedAmt += rewardOwner;
    }
    if(!whiteListedCreators[_currentGame.gameOwner]) {
      require(totalAmt >= rewardOwner, "Insufficient reward amount");
      stakingInfo[_currentGame.gameOwner].stakedAmt += rewardOwner;
    }
  }

  function claimUnstakedEnjin() public nonReentrant {
    uint256 claimableAmt = 0;
    LockInfo[] storage _userLock = lockInfo[_msgSender()];
    require(_userLock.length > 0, "Nothing to claim");
    for (uint256 index = _userLock.length - 1; index >= 0 ; index--) {
      if (_userLock[index].timeLock < block.timestamp) {
        claimableAmt += _userLock[index].amt;
        _userLock[index] = _userLock[_userLock.length - 1];
        _userLock.pop();
      }
    }
    require(claimableAmt > 0, "Nothing to claim");
    EnjinToken.safeTransferFrom(address(this), _msgSender(), claimableAmt);
  }

  function unstakeEnjin(uint256 _amount) public nonReentrant {
    StakeInfo storage _currentInfo = stakingInfo[_msgSender()];
    require(_currentInfo.stakedAmt >= _amount, "Insufficient amount to unstake");
    LockInfo memory _newLock;
    _newLock.amt = _amount;
    _newLock.timeLock = block.timestamp + 7 days;
    _currentInfo.stakedAmt -= _amount;
    if (_currentInfo.activeAmt > _amount) {
      _currentInfo.activeAmt -= _amount;
    } else {
      _currentInfo.activeAmt = 0;
    }
    LockInfo[] storage _userLock = lockInfo[_msgSender()];
    _userLock.push(_newLock);
  }
  
  function claimAll() public nonReentrant onlyOwner {
    EnjinToken.safeTransferFrom(address(this), _msgSender(), EnjinToken.balanceOf(address(this)));
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}