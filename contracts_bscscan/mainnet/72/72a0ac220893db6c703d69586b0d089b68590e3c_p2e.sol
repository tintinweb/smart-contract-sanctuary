/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

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

/**
 * @dev Partial interface of the ERC20 standard according to the needs of the e2p contract.
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract p2e is Ownable {
    event GamePlayed(uint256 gameId, address userAddress, bool win, uint256 endTime);

    uint256 _withdrawTax = 30; // base tax for withdraw in percents
    uint256 _withdrawTaxResetPeriod = 15 days; // period in seconds for tax resetting to 0 (since last game)
    uint256 _gameCounter; // counter of all games played
    uint256 _gamePerPeriodNumber = 7; // number of free games per 24 hours or for extra games after payment
    uint256 _gamePrice; // price for extra games
    uint256 _withdrawTaxes; // tax for ETNA withdraw (decreased in time if user don't play)
    uint256 _winToWithdraw; // Amount of ETNA won dy users and not withdrawn yet
    uint256[] _winAmounts; // Win amounts for different levels
    uint256[] _depletion; // Strength depletion per game for different levels
    uint256[] _thresholds; // Strength thresholds for different levels

    address _manager; // address for sending playGame transactions

    mapping (address => uint256) _gameNumber; // User's played game number
    mapping (address => uint256) _lastGameTime; // User's last played game time
    mapping (address => uint256) _paidGameNumber; // User's paid game number left to play
    mapping (address => uint256) _gamePayment; // User's unspent payment
    mapping (address => uint256) _userWin; // User's wins that can be withdrawn
    mapping (address => uint256) _withdrawTaxResetTime; // Time for tax decreasing calculation

    struct Game {
        uint256 characterId;
        uint256 level;
        uint256 endTime;
        address playerAddress;
        bool win;
    }
    mapping (uint256 => Game) _games;
    IERC20 ETNA;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyManager() {
        require(_manager == _msgSender(), "Caller is not the manager");
        _;
    }

    constructor (
        address tokenAddress,
        address newOwner,
        address newManager,
        uint256 newGamePrice,
        uint256[] memory newWinAmounts,
        uint256[] memory newDepletion,
        uint256[] memory newThresholds) {
        require(tokenAddress != address(0), 'Token address can not be zero');
        require(newManager != address(0), 'Manager address can not be zero');
        require(newOwner != address(0), 'Owner address can not be zero');
        require(newGamePrice > 0, 'Game price should be greater than zero');
        require(newWinAmounts.length == newDepletion.length, 'Level number should be the same for win amount and depletion');
        require(newWinAmounts.length == newThresholds.length, 'Level number should be the same for win amount and thresholds');
        for (uint256 i; i < newWinAmounts.length; i ++) {
            require(newWinAmounts[i] > 0, 'Any win amount should be greater than zero');
            require(newThresholds[i] > 0, 'Any threshold amount should be greater than zero');
            _winAmounts.push(newWinAmounts[i]);
            _depletion.push(newDepletion[i]);
            _thresholds.push(newThresholds[i]);
        }
        ETNA = IERC20(tokenAddress);
        transferOwnership(newOwner);
        _manager = newManager;
        _gamePrice = newGamePrice;
    }

    function payForGame () external returns (bool) {
        require(_gamePayment[msg.sender] == 0, 'Your have already paid for a game');
        require(ETNA.transferFrom(msg.sender, address(this), _gamePrice),
            'ETNA payment failed, please check ETNA balance and allowance for this contract address');
        _gamePayment[msg.sender] = _gamePrice;
        return true;
    }

    function getPayment (address userAddress) external view returns (uint256) {
        return _gamePayment[userAddress];
    }

    function playGame (
        address userAddress,
        uint256 level,
        uint256 number,
        uint256 strength,
        uint256 characterId
    ) external onlyManager returns (bool) {
        if (_lastGameTime[userAddress] < block.timestamp - 86400) {
            _gameNumber[userAddress] = 1;
        } else {
            _gameNumber[userAddress] += 1;
        }

        if (_gameNumber[userAddress] > _gamePerPeriodNumber) {
            if (_paidGameNumber[userAddress] > 0) {
                _paidGameNumber[userAddress] -= 1;
            } else {
                require(_gamePayment[userAddress] > 0, 'This account hit 24 hours limit.');
                _gamePayment[userAddress] = 0;
                _paidGameNumber[userAddress] += (_gamePerPeriodNumber - 1);
            }
        }
        _lastGameTime[userAddress] = block.timestamp;

        uint256 _winAmount = _winAmounts[level - 1];
        require(_winAmount > 0, 'Invalid level');
        _withdrawTaxResetTime[userAddress] = block.timestamp;
        _gameCounter ++;
        Game memory newGame = Game({
            characterId: characterId,
            level: level,
            endTime: block.timestamp,
            playerAddress: userAddress,
            win: getGameResult(number, strength)
        });
        _games[_gameCounter] = newGame;

        if (newGame.win) {
            _userWin[userAddress] += _winAmount;
            _winToWithdraw += _winAmount;
        }
        emit GamePlayed(_gameCounter, userAddress, newGame.win, block.timestamp);
        return true;
    }

    function getGameResult (uint256 number, uint256 strength) internal pure returns (bool) {
        return number <= strength;
    }

    function setPrice (uint256 newGamePrice) external onlyOwner returns (bool) {
        require(newGamePrice > 0, 'Game price should be greater than zero');
        _gamePrice = newGamePrice;
        return true;
    }

    function getPrice () external view returns (uint256) {
        return _gamePrice;
    }

    function setManager (address newManager) external onlyOwner returns (bool) {
        require (newManager != address(0), 'Manager address can not be zero');
        _manager = newManager;
        return true;
    }

    function getManager () public view returns (address) {
        return _manager;
    }

    function setGameData (
        uint256[] calldata newWinAmounts,
        uint256[] calldata newDepletion,
        uint256[] calldata newThresholds) external onlyOwner returns (bool) {
        require(newWinAmounts.length == newDepletion.length, 'Level number should be the same for win amount and depletion');
        require(newWinAmounts.length == newThresholds.length, 'Level number should be the same for win amount and thresholds');
        delete _winAmounts;
        delete _depletion;
        delete _thresholds;
        for (uint256 i; i < newWinAmounts.length; i ++) {
            require(newWinAmounts[i] > 0, 'Any win amount should be greater than zero');
            require(newThresholds[i] > 0, 'Any threshold amount should be greater than zero');
            _winAmounts.push(newWinAmounts[i]);
            _depletion.push(newDepletion[i]);
            _thresholds.push(newThresholds[i]);
        }
        return true;
    }

    function getGameData () external view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        return (_winAmounts, _depletion, _thresholds);
    }

    function getLastGameId () external view returns (uint256) {
        return _gameCounter;
    }

    function getGame (uint256 gameId) external view returns (address, uint256, uint256, uint256, bool) {
        Game memory game = _games[gameId];
        return (game.playerAddress, game.characterId, game.level, game.endTime, game.win);
    }

    function getUserWin (address userAddress) external view returns (uint256) {
        return _userWin[userAddress];
    }

    function withdrawWin (uint256 amount) external returns (bool) {
        require(amount <= _userWin[msg.sender], 'Amount exceeds total winning');
        require(amount > 0, 'Amount should be greater than zero');
        uint256 tax = getCurrentWithdrawTax(msg.sender); // % value multiplied by 100
        uint256 deductable = amount * tax / 10000;
        _withdrawTaxes += deductable;
        _winToWithdraw -= amount;
        _userWin[msg.sender] -= amount;
        require(ETNA.transfer(msg.sender, amount - deductable),
            'Not enough ETNA balance');
        return true;
    }

    function getCurrentWithdrawTax (address userAddress) public view returns (uint256) {
        if (_withdrawTax == 0) return 0;
        uint256 timePassed = block.timestamp - _withdrawTaxResetTime[userAddress];
        if (timePassed >= _withdrawTaxResetPeriod) return 0;
        return _withdrawTax * 100 * (_withdrawTaxResetPeriod - timePassed) / _withdrawTaxResetPeriod;
    }

    function withdrawAmount (uint256 amount) external onlyOwner returns (bool) {
        uint256 balance = ETNA.balanceOf(address(this));
        require(balance >= _winToWithdraw && amount <= balance - _winToWithdraw, 'Amount exceeded safe amount to withdraw');
        require(ETNA.transfer(owner(), amount),
            'Not enough ETNA balance');
        return true;
    }

    function withdraw () external onlyOwner returns (bool) {
        uint256 balance = ETNA.balanceOf(address(this));
        require(ETNA.transfer(owner(), balance - _winToWithdraw),
            'Not enough ETNA balance');
        return true;
    }

    function forceWithdraw (uint256 amount) external onlyOwner returns (bool) {
        uint256 balance = ETNA.balanceOf(address(this));
        require(amount <= balance, 'Amount exceeded contract balance');
        require(ETNA.transfer(owner(), amount),
            'Not enough ETNA balance');
        return true;
    }

    function setGamePerPeriodNumber (uint256 newGamePerPeriodNumber) external onlyOwner returns (bool) {
        require(newGamePerPeriodNumber > 0, 'Games per period should be greater than zero');
        _gamePerPeriodNumber = newGamePerPeriodNumber;
        return true;
    }

    function getGamePerPeriodNumber () external view returns (uint256) {
        return _gamePerPeriodNumber;
    }

    function setWithdrawTax (uint256 newTax) external onlyOwner returns (bool) {
        _withdrawTax = newTax;
        return true;
    }

    function getWithdrawTax () external view returns (uint256) {
        return _withdrawTax;
    }

    function setWithdrawTaxResetPeriod (uint256 newTaxResetPeriod) external onlyOwner returns (bool) {
        require(newTaxResetPeriod > 0, 'Tax reset period should be greater than zero');
        _withdrawTaxResetPeriod = newTaxResetPeriod;
        return true;
    }

    function getWithdrawTaxResetPeriod () external view returns (uint256) {
        return _withdrawTaxResetPeriod;
    }

    function getWithdrawTaxes () external view returns (uint256) {
        return _withdrawTaxes;
    }

    function getPaidGameNumber (address userAddress) external view returns (uint256) {
        return _paidGameNumber[userAddress];
    }

    function getGameNumber (address userAddress) external view returns (uint256) {
        return _gameNumber[userAddress];
    }

    function getLastGameTime (address userAddress) external view returns (uint256) {
        return _lastGameTime[userAddress];
    }

    function getWinToWithdraw () external view returns (uint256) {
        return _winToWithdraw;
    }
}