/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/*
Authors:
    romanow.org
    defismart
*/

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

interface ILotteryWeeklyTracker {
    function updateAccount(address account, uint256 amount) external;
    function removeAccount(address account) external;
    function isActiveAccount(address account) external view returns(bool);
}

contract LotteryWeeklyTracker is Ownable, ILotteryWeeklyTracker {
    struct ParticipantInfo {
        uint256 index;
        uint256 balance;
    }



    IBEP20 public rewardToken;

    uint256 public accumulatedBalance;
    uint256[] private  _participantsEntries;
    mapping (address => ParticipantInfo) private _participantBalance;
    address[] private _participants;
    uint256 private _nextDrawTime;

    uint256 currentDeleteIndex;
    uint256 public currentLotteryIndex;

    address public lambotteryContract;
    modifier onlyLambottery () {
        require(msg.sender == lambotteryContract, "Not allowed");
        _;
    }

    constructor(address _rewardToken) {
        rewardToken = IBEP20(_rewardToken);

    }


    function dropAllPreviousEntries() external onlyOwner {
        uint256 len =  _participants.length;
        uint256 iter;
        uint256 index = currentDeleteIndex;
        while (index < len && iter < 10000) {
            delete _participantBalance[_participants[index]];
            index++;
            iter++;
        }
        currentDeleteIndex = index;

        if (currentDeleteIndex == len - 1) {
            delete _participantsEntries;
            delete _participants;
            currentDeleteIndex = 0;
        }
    }

    function isActiveAccount(address account) external override view returns(bool){
        return _participantBalance[account].balance > 0;
    }

    function updateAccount(address account, uint256 amount) external override onlyLambottery {
        if (currentDeleteIndex > 0) {
            return;
        }

        if (_participantBalance[account].balance == 0) {
            _participantBalance[account].index = _participants.length;
            _participants.push(account);
            _participantsEntries.push(amount);
        } else {
            _participantsEntries[_participantBalance[account].index] += amount;
        }

        _participantBalance[account].balance += amount;
        accumulatedBalance += amount;
        emit UpdateAccountEntries(account, amount, _participantBalance[account].balance);
    }

    function removeAccount(address account) external override onlyLambottery {
        if (currentDeleteIndex > 0) {
            return;
        }

        accumulatedBalance -= _participantBalance[account].balance;
        uint256 indexOfDel = _participantBalance[account].index;
        uint256 indexLast = _participants.length - 1;
        _participants[indexOfDel] = _participants[indexLast];
        _participantsEntries[indexOfDel] = _participantsEntries[indexLast];

        _participantBalance[_participants[indexLast]].index = indexOfDel;
        _participants.pop();
        _participantsEntries.pop();
        delete _participantBalance[account];
        emit UpdateAccountEntries(account, 0, 0);

    }

    function getActiveParticipantAddresses() external view returns(address[] memory) {
        return _participants;
    }

    function getActiveParticipantEntries() external view returns(uint256[] memory) {
        return _participantsEntries;
    }

    function sendToWinner(address winner, uint256 busdAmount) external onlyOwner {
        rewardToken.transfer(winner, busdAmount);
    }

    function getAccumulatedRewardTokensOnContract() external view returns(uint256) {
        return rewardToken.balanceOf(address(this));
    }

    function getNextDrawTime() external view returns(uint256) {
        return _nextDrawTime;
    }

    function setNextDrawTime(uint256 time) external onlyOwner {
        currentLotteryIndex++;
        if (time > 0 && time > block.timestamp + 5 days) {
            _nextDrawTime = time;
            return;
        }
        _nextDrawTime = block.timestamp + 7 days;
    }

    function setLambotteryContract(address _lambotteryContract) external onlyOwner {
        lambotteryContract = _lambotteryContract;
    }

    function withdrawStuckTokens(address token) external onlyOwner {
        require(token != address(rewardToken), "Reward token");
        uint256 balance = IBEP20(token).balanceOf(address(this));
        IBEP20(token).transfer(owner(), balance);
    }

    event UpdateAccountEntries(address account, uint256 increaseAmount, uint256 accountBalance);
}