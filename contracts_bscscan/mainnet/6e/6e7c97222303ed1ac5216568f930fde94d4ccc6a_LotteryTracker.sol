/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILotteryTracker {
    function isActiveAccount(address account) external view returns(bool);
    function getRewardToken() external view returns(address token);
    function getWinner(address account) external view returns(uint256 amount, uint256 time, address winner);
    function getNextDrawTime() external view returns(uint256);
    function getAccountBalance(address account) external returns(uint256);

    function updateAccount(address account, uint256 amount) external;
    function removeAccount(address account) external;
    function process(uint256 gas) external returns(bool);
    function setDrawThresholdInBUSD(uint256 threshold) external;
    function setNextDrawTime(uint256 nextDrawTime) external;
}
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;
    address public _lambo;

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
        require(owner() == _msgSender() || _lambo == _msgSender(), "Ownable: caller is not the owner");
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

abstract contract LotteryWinner {
    struct WinnerInfo {
        uint256 amount;
        uint256 time;
        address winner;
    }

    mapping(address => uint256) private _winnerIndexByAddress;

    WinnerInfo[] public _winners;

    constructor() {
        WinnerInfo memory zeroInfo = WinnerInfo(0, 0, address(0));
        _winners.push(zeroInfo);
    }

    function addWinner(address winner, uint256 amount, uint256 time) internal returns (uint256 index) {
        index = _winners.length;
        WinnerInfo memory winnerInfo = WinnerInfo(amount, time, winner);
        _winners.push(winnerInfo);
        _winnerIndexByAddress[winner] = index;
    }

    function getWinnerInfoByAddress(address winner) public view returns(WinnerInfo memory winnerInfo) {
        // if no address in map will get 0 index and zeroInfo.
        uint256 index = _winnerIndexByAddress[winner];
        return _winners[index];
    }

    function _getWinner() internal view returns(WinnerInfo memory winnerInfo) {
        require(_winners.length > 1, "No winner");
        winnerInfo = _winners[_winners.length - 1];
    }
}

contract LotteryTracker is ILotteryTracker, LotteryWinner, Ownable {

    struct ParticipantInfo {
        uint256 index;
        uint256 balance;
    }

    string _name;
    
    uint256 public winNumber;
    uint256 public lastProcessedIndex;
    uint256 private accToWinNumber;

    bool internal inProcess;
    bool internal foundWinner;

    address[] internal _findParticipants;
    uint256 currentLotteryIndex;
    uint256 accumulatedBalance;

    // currentLotteryIndex -> address -> balance
    mapping (uint256 => mapping(address => ParticipantInfo)) internal _participantBalance;
    address[] internal _participants;


    IBEP20 internal _rewardToken;


    uint256 internal _nextDrawTime;
    uint256 internal _drawThresholdInBUSD = 10 ** 17;
    uint256 immutable public _drawInterval;

    constructor(address rewardToken,  uint256 drawInterval, string memory contractName) {
        _name = contractName;
        _rewardToken = IBEP20(rewardToken);
        _drawInterval = drawInterval;
    }

    function name() external view returns (string memory) { return _name; }

    function getNextDrawTime() external view override returns(uint256) {
        return _nextDrawTime;
    }

    function getRandomInRange(uint256 max) internal view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return random % max;
    }

    function resetSearching() private {
        // lastProcessedIndex = 0;
        accToWinNumber = 0;
        foundWinner = true;
    }

    function setDrawThresholdInBUSD(uint256 threshold) external override onlyOwner {
        emit UpdateDrawThresholdInBUSD(_drawThresholdInBUSD, threshold);
        _drawThresholdInBUSD = threshold;
    }

    function setNextDrawTime(uint256 nextDrawTime) external override onlyOwner {
        require(_nextDrawTime == 0, "Lottery already started");
        _nextDrawTime = nextDrawTime;
    }

    function isActiveAccount(address account) external view override returns(bool){
        return _participantBalance[currentLotteryIndex][account].balance > 0;
    }

    function updateAccount(address account, uint256 amount) external override onlyOwner {
        if (_participantBalance[currentLotteryIndex][account].balance == 0) {
            _participantBalance[currentLotteryIndex][account].index = _participants.length;
            _participants.push(account);
        }

        _participantBalance[currentLotteryIndex][account].balance += amount;
        accumulatedBalance += amount;
        emit UpdateAccountEntries(account, amount, _participantBalance[currentLotteryIndex][account].balance);
    }

    function removeAccount(address account) external override onlyOwner {
        if (_participantBalance[currentLotteryIndex][account].balance == 0) {
            return;
        }
        accumulatedBalance -= _participantBalance[currentLotteryIndex][account].balance;
        uint256 indexOfDel = _participantBalance[currentLotteryIndex][account].index;
        uint256 indexLast = _participants.length - 1;
        _participants[indexOfDel] = _participants[indexLast];
        _participantBalance[currentLotteryIndex][_participants[indexLast]].index = indexOfDel;
        _participants.pop();
        delete _participantBalance[currentLotteryIndex][account];
        emit UpdateAccountEntries(account, 0, 0);
    }

    function startNewDraw() internal returns(bool) {
        _findParticipants = _participants;
        delete _participants;
        inProcess = true;
        foundWinner = false;
        currentLotteryIndex++;
        winNumber = getRandomInRange(accumulatedBalance);
        emit StartNewDraw(_findParticipants.length, currentLotteryIndex, winNumber, accumulatedBalance);
        accumulatedBalance = 0;
        return true;
    }

    function getNextTime(uint256 start, uint256 interval) internal view returns(uint256) {
        uint256 diff = (block.timestamp - start) / interval + 1;
        return start + (diff * interval);
    }


    // can call anyone to speed up process
    // returning value means is anything processed
    function process(uint256 gas) external override onlyOwner returns(bool) {
        emit Process(currentLotteryIndex, lastProcessedIndex, _findParticipants.length, accToWinNumber, winNumber);
        if (_nextDrawTime < block.timestamp && _nextDrawTime != 0) {
            _nextDrawTime = getNextTime(_nextDrawTime, _drawInterval);
            if (_rewardToken.balanceOf(address(this)) > _drawThresholdInBUSD && !inProcess) {
                startNewDraw();
            }
        }


        if (!inProcess) {
            return false;
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();
        uint256 len = _findParticipants.length;

        while(gasUsed < gas && _lastProcessedIndex < len) {
            _lastProcessedIndex++;

            address account = _findParticipants[_lastProcessedIndex];

            if (!foundWinner) {
                accToWinNumber += _participantBalance[currentLotteryIndex - 1][account].balance;
                if (accToWinNumber >= winNumber) {
                    uint256 prize = _rewardToken.balanceOf(address(this));
                    addWinner(account, prize, block.timestamp);
                    _rewardToken.transfer(account, prize);
                    resetSearching();
                }
            }

            delete _participantBalance[currentLotteryIndex - 1][account];




            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed += gasLeft - newGasLeft;
            }

            gasLeft = newGasLeft;
        }
        emit ProcessedNumber(_lastProcessedIndex - lastProcessedIndex);
        lastProcessedIndex = _lastProcessedIndex;

        if (_lastProcessedIndex + 1 == len) {
            inProcess = false;
            emit ProcessEnded(currentLotteryIndex);
        }

        return true;
    }

    function getRewardToken() external view override returns(address token) {
        return address(_rewardToken);
    }


    function getWinner(address account) external view override returns(uint256 amount, uint256 time, address winner) {
        WinnerInfo memory win;
        if (account == address(0)) {
            win = _getWinner();
        } else {
            win = getWinnerInfoByAddress(account);
        }

        amount = win.amount;
        time = win.time;
        winner = win.winner;
    }

    function getAccountBalance(address account) public view override returns (uint256) {
        return _participantBalance[currentLotteryIndex][account].balance;
    }

    function setLambo(address lambo) external onlyOwner {
        _lambo = lambo;
        emit UpdateLambotteryAddress(lambo);
    }

    event ProcessedNumber(uint256 processed);
    event UpdateDrawThresholdInBUSD(uint256 oldValue, uint256 newValue);
    event UpdateAccountEntries(address account, uint256 increaseAmount, uint256 accountBalance);
    event StartNewDraw(uint256 participantsNumber, uint256 currentLotteryIndex, uint256 winNumber, uint256 accumulatedBalance);
    event Process(uint256 currentLotteryIndex, uint256 lastProcessedIndex, uint256 findParticipantsNumber, uint256 accToWinNumber, uint256 winNumber);
    event ProcessEnded(uint256 currentLotteryIndex);
    event UpdateLambotteryAddress(address lambottery);
}