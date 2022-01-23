// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import "@openzeppelin/contracts/security/Pausable.sol";

import "./ORACLE/IPriceOracle.sol";
import "./interface/IDuckNFT.sol";


interface ISmartChefNFT {

    function getUserStakedExpAmount(address _user) external view returns(uint);

}

contract MainDuckGame is Ownable, AccessControl ,Pausable ,ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public duckToken;
    IERC20 public usdtToken;
    IDuckNFT public duckNFT;
    IPriceOracle public oracle;
    ISmartChefNFT public SmartChefNFT;

    struct RewardToken {
        address token;
        uint256 rewardInUSD;
        uint256 rewardInToken;
    }

    struct PlayerContract{
        uint32 duration; //in seconds
        uint256 priceInUSD;
        bool enable; //true: enabled; false: disabled
    }

    struct Game {
        uint256 minExpAmount;
        uint256 minStakeAmount; //min stake amount (in masterChef and autoBsw) to be available to play game
        uint256 minLevel; // level token
        uint chanceToWin; //base 10000
        RewardToken[] rewardTokens;
        string name;
        bool enable; //true - enable; false - disable
    }

    struct UserInfo {
        uint busBalance;
        uint allowedBusBalance;
        uint secToNextBus; //how many seconds are left until the next bus
        uint playerBalance;
        uint allowedSeatsInBuses;
        uint availableSEAmount;
        uint totalSEAmount;
        uint stakedAmount;
        uint duckBalance;
        RewardToken[] rewardBalance;
        uint currentFee;
    }

    struct GameInfo {
        uint index;
        Game game;
        bool level;//level
        bool expStake;
        bool expAmount;
    }

    uint constant MAX_WITHDRAWAL_FEE = 5000;

    uint public decreaseWithdrawalFeeByDay; //150: -1,5% by day
    uint public withdrawalFee; //2700: 27%
    uint public recoveryTime; // 48h = 172800 for lock tokens after game play

    address public treasuryAddress;

    Game[] public games;
    PlayerContract[] public playerContracts;
    address[] rewardTokens;
    mapping(address => uint) public withdrawTimeLock; //user address => block.timestamp; To calc withdraw fee
    mapping(address => uint) public firstGameCountdownSE; //user address => block.timestamp Grace period after this - SEDecrease enabled
    mapping(address => mapping(address => uint256)) userBalances; //user balances: user address => token address => amount

    event GameAdded(uint gameIndex);
    event GameDisable(uint gameIndex);
    event GameEnable(uint gameIndex);
    event GamePlay(address indexed user, uint indexed gameIndex, bool userWin, address[] rewardTokens, uint256[] rewardAmount);
    event Withdrew(address indexed user, RewardToken[] _rewardBalance);
    event RewardTokenChanged(uint gameIndex);
    event GameSetNewGameParam(uint gameIndex);

    //Initialize function --------------------------------------------------------------------------------------------
    constructor(
        IERC20 _usdtToken,
        IERC20 _duckToken,
        IDuckNFT _duckNFT,
        IPriceOracle _oracle,
        ISmartChefNFT _masterChef,
        address _treasuryAddress,
        uint _recoveryTime) 
        {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        duckToken = _duckToken;
        usdtToken = _usdtToken;
        duckNFT = _duckNFT;
        oracle = _oracle;
        SmartChefNFT = _masterChef;
        treasuryAddress = _treasuryAddress;
        recoveryTime = _recoveryTime;
    }


    //Modifiers -------------------------------------------------------------------------------------------------------

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    //External functions --------------------------------------------------------------------------------------------

    function addPlayerContract(PlayerContract calldata _playerContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        playerContracts.push(_playerContract);
    }

    function playerContractState(uint _pcIndex, uint256 newPrice, bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_pcIndex < playerContracts.length, "Wrong index out of bound");
        playerContracts[_pcIndex].priceInUSD = newPrice;
        playerContracts[_pcIndex].enable = _state;
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_treasuryAddress != address(0), "Address cant be zero");
        treasuryAddress = _treasuryAddress;
    }

    function addNewGame(Game calldata _game) external onlyRole(DEFAULT_ADMIN_ROLE) {
        games.push(_game);
        for (uint i = 0; i < _game.rewardTokens.length; i++) {
            if (!_tokenInArray(_game.rewardTokens[i].token)) {
                rewardTokens.push(_game.rewardTokens[i].token);
            }
        }
        emit GameAdded(games.length);
    }

    function disableGame(uint _gameIndex) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_gameIndex < games.length, "Index out of bound");
        games[_gameIndex].enable = false;
        emit GameDisable(_gameIndex);
    }

    function enableGame(uint _gameIndex) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_gameIndex < games.length, "Index out of bound");
        games[_gameIndex].enable = true;
        emit GameEnable(_gameIndex);
    }

    function setGameParameters(uint _gameIndex, uint256 _minExpAmount, uint256 _minLevel, uint256 _minStakeAmount, uint _chanceToWin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Game storage _game = games[_gameIndex];
        _game.minStakeAmount = _minStakeAmount;//stake exp at nft staking
        _game.minExpAmount = _minExpAmount; // exp at token
        _game.minLevel = _minLevel; // level token
        _game.chanceToWin = _chanceToWin;
        emit GameSetNewGameParam(_gameIndex);
    }

    function setRewardTokensToGame(uint _gameIndex, RewardToken[] calldata _rewardTokens) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_gameIndex < games.length, "Index out of bound");
        delete games[_gameIndex].rewardTokens;
        for(uint i = 0; i < _rewardTokens.length; i++){
            games[_gameIndex].rewardTokens.push(_rewardTokens[i]);
        }
        Game memory _game = games[_gameIndex];
        for (uint i = 0; i < _game.rewardTokens.length; i++) {
            if (!_tokenInArray(_game.rewardTokens[i].token)) {
                rewardTokens.push(_game.rewardTokens[i].token);
            }
        }
        emit RewardTokenChanged(_gameIndex);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setWithdrawalFee(uint _decreaseWithdrawalFeeByDay, uint _withdrawalFee)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        //MSG-02
        require(_withdrawalFee <= MAX_WITHDRAWAL_FEE, "Incorrect value withdrawal Fee");
        withdrawalFee = _withdrawalFee;
        decreaseWithdrawalFeeByDay = _decreaseWithdrawalFeeByDay;
    }

    function setRecoveryTime(uint _newRecoveryTime) external onlyRole(DEFAULT_ADMIN_ROLE) {
        recoveryTime = _newRecoveryTime;
    }


    //Public functions ----------------------------------------------------------------------------------------------

    function playGame(uint _gameIndex, uint[] calldata _playersId) public notContract whenNotPaused nonReentrant {
        require(_gameIndex < games.length, "Index out of bound");
        Game memory _game = games[_gameIndex];
        require(_game.enable, "Game is disabled");
        //require(_checkBusAndPlayersAmount(msg.sender), "Check bus and players falls");
        require(_checkMinStakeAmount(msg.sender, _gameIndex), "Need more stake in pools");
        if (firstGameCountdownSE[msg.sender] == 0) {
            firstGameCountdownSE[msg.sender] = block.timestamp;
        }
        uint256 totalexp;
        for (uint i = 0; i < _playersId.length; i++) {
            totalexp = duckNFT.lockTokens(_playersId, uint256(block.timestamp + recoveryTime), msg.sender);
        }        
        require(totalexp >= _game.minExpAmount, "Not enough EXP amount");
        bool userWin = _getRandomForWin(_gameIndex);
        address[] memory _rewardTokens = new address[](_game.rewardTokens.length);
        uint256[] memory _rewardAmount = new uint256[](_game.rewardTokens.length);
        if (userWin) {
            for (uint i = 0; i < _game.rewardTokens.length; i++) {
                _rewardAmount[i] = _game.rewardTokens[i].rewardInToken == 0 ?
                _getPriceInToken(_game.rewardTokens[i].token, _game.rewardTokens[i].rewardInUSD) :
                _game.rewardTokens[i].rewardInToken;
                _rewardTokens[i] = _game.rewardTokens[i].token;
            }
            _balanceIncrease(msg.sender, _rewardTokens, _rewardAmount);
        }
        emit GamePlay(msg.sender, _gameIndex, userWin, _rewardTokens, _rewardAmount);
    }

    function withdrawReward() public notContract whenNotPaused nonReentrant {
        require(withdrawTimeLock[msg.sender] > 0, "Withdraw not allowed");
        uint calcFee;
        uint multipl = (block.timestamp - withdrawTimeLock[msg.sender]) / 86400;
        calcFee = (multipl * decreaseWithdrawalFeeByDay) >= withdrawalFee
        ? 0
        : withdrawalFee - (multipl * decreaseWithdrawalFeeByDay);

        RewardToken[] memory _rewardBalance = new RewardToken[](rewardTokens.length);
        for (uint i = 0; i < rewardTokens.length; i++) {
            address currentToken = rewardTokens[i];
            uint256 currentBalance = userBalances[msg.sender][currentToken];
            _rewardBalance[i].token = currentToken;
            _rewardBalance[i].rewardInToken = userBalances[msg.sender][currentToken];
            delete userBalances[msg.sender][currentToken];
            if (currentBalance > 0) {
                uint fee = (currentBalance * calcFee) / 10000;
                IERC20(currentToken).safeTransfer(treasuryAddress, fee);
                IERC20(currentToken).safeTransfer(msg.sender, currentBalance - fee);
            }
        }
        //MSG-03
        delete withdrawTimeLock[msg.sender];
        emit Withdrew(msg.sender, _rewardBalance);
    }

    function buyContracts(uint[] memory _tokensId, uint _contractIndex) public notContract whenNotPaused nonReentrant {
        require(_tokensId.length > 0, "Cant by contracts without tokensId");
        require(_contractIndex < playerContracts.length, "Wrong index out of bound");
        uint priceInBSW = _getPriceInDuck(playerContracts[_contractIndex].priceInUSD);
        uint totalCost = priceInBSW * _tokensId.length;
        IERC20(duckToken).safeTransferFrom(msg.sender, treasuryAddress, totalCost);
        duckNFT.setPlayerContract(_tokensId, uint32(block.timestamp + playerContracts[_contractIndex].duration), msg.sender);
    }

    // function checkGameRequirements(address _user) public view returns(bool busAndPlayersAmount){
    //     busAndPlayersAmount = _checkBusAndPlayersAmount(_user);

    // }

    function userInfo(address _user) public view returns (UserInfo memory) {
        UserInfo memory _userInfo;

        _userInfo.stakedAmount = SmartChefNFT.getUserStakedExpAmount(_user);
        _userInfo.duckBalance = IERC20(duckToken).balanceOf(_user);
        RewardToken[] memory _rewardBalance = new RewardToken[](rewardTokens.length);
        for(uint i = 0; i < rewardTokens.length; i++){
            _rewardBalance[i].token = rewardTokens[i];
            _rewardBalance[i].rewardInToken = userBalances[_user][rewardTokens[i]];
        }
        _userInfo.rewardBalance = _rewardBalance;
        uint calcFee;
        uint multipl = (block.timestamp - withdrawTimeLock[_user]) / 1 days;
        calcFee = (multipl * decreaseWithdrawalFeeByDay) >= withdrawalFee
        ? 0
        : withdrawalFee - (multipl * decreaseWithdrawalFeeByDay);
        _userInfo.currentFee = calcFee;
        return (_userInfo);
    }

    function getUserRewardBalances(address _user) public view returns (address[] memory, uint256[] memory) {
        uint256[] memory balances = new uint256[](rewardTokens.length);
        for (uint i = 0; i < balances.length; i++) {
            balances[i] = userBalances[_user][rewardTokens[i]];
        }
        return (rewardTokens, balances);
    }

    function getGameCount() public view returns(uint count){
        count = games.length;
    }

    function getGameInfo(address _user, uint _tokenId) public view returns(GameInfo[] memory){
        GameInfo[] memory gamesInfo = new GameInfo[](games.length);
        //bool playerAndBusAmount = _user != address(0) ?  _checkBusAndPlayersAmount(_user) : false;
        for(uint i = 0; i < games.length; i++){
            bool expStake = _user != address(0) ?  _checkMinStakeAmount(_user, i) : false;
            bool expAmount = _user != address(0) ? duckNFT.getHeroesNumber(_tokenId).exp >= games[i].minExpAmount : false;
            bool levelcheck = _user != address(0) ? duckNFT.getHeroesNumber(_tokenId).level >= games[i].minLevel : false;
            gamesInfo[i].index = i;
            gamesInfo[i].game = games[i]; 
            gamesInfo[i].level = levelcheck;
            gamesInfo[i].expStake = expStake;
            gamesInfo[i].expAmount = expAmount;

            for(uint j = 0; j < gamesInfo[i].game.rewardTokens.length; j++){
                gamesInfo[i].game.rewardTokens[j].rewardInToken = gamesInfo[i].game.rewardTokens[j].rewardInToken == 0 ?
                _getPriceInToken(gamesInfo[i].game.rewardTokens[j].token, gamesInfo[i].game.rewardTokens[j].rewardInUSD) :
                gamesInfo[i].game.rewardTokens[j].rewardInToken;
            }
        }
        return(gamesInfo);
    }


    //Internal functions --------------------------------------------------------------------------------------------

    function _checkMinStakeAmount(address _user, uint _gameIndex) internal view returns (bool) {
        require(_gameIndex < games.length, "Game index out of bound");
        uint MaxEXPBalance = SmartChefNFT.getUserStakedExpAmount(_user);
        return MaxEXPBalance >= games[_gameIndex].minStakeAmount;
    }

    function _checkBusAndPlayersAmount(uint _tokenID) internal view returns (uint) {
        return duckNFT.getHeroesNumber(_tokenID).level;
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function _getPriceInDuck(uint _amount) internal view returns (uint) {
        return oracle.getDUCKbyUSD(_amount);
    }

    function _getPriceInToken(address _token, uint _amount) internal view returns (uint256) {
         uint256 price;
         if (_token == address(duckToken) ){
            price = oracle.getDUCKbyUSD(_amount);
        }else if(_token == address(usdtToken)){
            price = oracle.getBNBbyUSD(_amount);
            }
        return uint256(price);
    }

    function _tokenInArray(address _token) internal view returns (bool) {
        for (uint i = 0; i < rewardTokens.length; i++) {
            if (_token == rewardTokens[i]) return true;
        }
        return false;
    }

    //Private functions --------------------------------------------------------------------------------------------

    function _getRandomForWin(uint _gameIndex) private view returns (bool) {
        uint random = (uint(keccak256(abi.encodePacked(blockhash(block.number - 1), gasleft()))) % 10000) + 1;
        return random < games[_gameIndex].chanceToWin;
    }

    function _balanceIncrease(address _user, address[] memory _token, uint256[] memory _amount) private {
        require(_token.length == _amount.length, "Wrong arrays length");
        if(withdrawTimeLock[_user] == 0) withdrawTimeLock[_user] = block.timestamp;
        for(uint i = 0; i < _token.length; i++){
            userBalances[_user][_token[i]] +=  _amount[i];
        }
    }

    function _balanceDecrease(address _user, address[] memory _token, uint256[] memory _amount) private {
        require(_token.length == _amount.length);
        for(uint i = 0; i < _token.length; i++){
            require(userBalances[_user][_token[i]] >=  _amount[i], "Insufficient balance");
            userBalances[_user][_token[i]] -=  _amount[i];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IPriceOracle {
    // Views

    function getBNBbyUSD(uint256 usd) external view returns (uint256);

    function getDUCKbyUSD(uint256 usd) external view returns (uint256);

    function getPPOLLbyUSD(uint256 usd) external view returns (uint256);
    
    //function getTokenPrice() external view returns (uint256);

    function getTokenPrice() external view returns (uint256 DUCK, uint256 PPOLL, uint256 DUCK1USD, uint256 PPOLL1USD);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IDuckNFT {
    struct DuckInfo {uint256 heroesNumber; string name; string category; string rarity; uint256 exp; uint256 level; uint256 contractEndTimestamp; uint256 busyTo; uint createTimestamp; bool stakeFreeze;}
    function getHeroesNumber(uint256 _tokenId) external view returns (DuckInfo memory);
    function addDuckNumber(uint256 tokenId, uint256 _heroesNumber, string memory name, string memory category, string memory rarity, uint256 exp, uint256 level, uint256 contractEndTimestamp, uint256 busyTo, uint createTimestamp, bool stakeFreeze) external;
    function lockTokens(uint[] calldata tokenId, uint256 busyTo,  address user) external returns (uint256);
    function setPlayerContract(uint[] calldata tokenId, uint32 contractEndTimestamp, address user) external;
    function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint tokenId);
    function balanceOf(address owner) external view returns (uint balance);
    function ownerOf(uint tokenId) external view returns (address owner);


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}