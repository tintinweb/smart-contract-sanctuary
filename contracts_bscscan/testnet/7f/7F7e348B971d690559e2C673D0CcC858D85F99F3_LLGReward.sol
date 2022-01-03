/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-30
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

pragma solidity 0.8.5;

interface ILLG {
    function balanceOf(address _user) external view returns (uint256);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
    function approve(address _sender, uint256 _amount) external returns (bool);
    function transfer(address _recipient, uint256 _amount) external returns (bool);
}


contract LLGReward is Ownable {
    ILLG public llgContract;
    
    uint256 public taxPercent = 5;
    address public taxWallet = 0xEB74663BD160d8b2082c00B730F7ab0e282cEE1A;
    address public bonusWallet = 0x3F54E24c3E67179FcAb0367bac76F179cdc83f90;
    
    uint256 private passport;

    mapping(uint256 => uint256) private deposits;

    uint256 public startTimeOfDay = 1514764800;
    mapping(address => uint) private numConsecutiveWins;

    struct RandomMatch {
        uint256 startDateTime;
    }

    mapping(address => RandomMatch) private randomMatches;


    constructor(address _llg) {
        llgContract = ILLG(_llg);
    }

    function getLLGBalanceOf(address _user) external view returns (uint256) {
        return llgContract.balanceOf(_user);
    }

    function getDeposits(uint256 _room) external view returns (uint256) {
        return deposits[_room];
    }

    function getNumOfConsecutiveWins(address _playerAddr) external view returns (uint) {
        return numConsecutiveWins[_playerAddr];
    }

    function issuePassport(uint256 _passport) external onlyOwner {
        passport = _passport;
    }

    function setTaxPercent(uint _taxPercent) external onlyOwner {
        taxPercent = _taxPercent;
    }

    function setTaxWallet(address _address) external onlyOwner {
        taxWallet = _address;
    }

    function setStartTimeOfDay(uint256 _dateTimeInMillis) external onlyOwner {
        startTimeOfDay = _dateTimeInMillis;
    }

    // function depositeApprove(address _playerAddr, uint256 _funds) external {
    //         llgContract.approve(_playerAddr, _funds * 10**9);
    // }

    function deposit(uint256 _room, address _playerAddr, uint256 _funds) external returns (bool) {
            llgContract.transferFrom(_playerAddr, address(this), _funds * 10**9);
            deposits[_room] += _funds;
            return true;
    }

    // function getRewards(uint256 _funds) external {
    //         llgContract.transfer(taxWallet, _funds * 10**9);
    // }


    function offerWinningReward(uint256 _room, uint256 _passport, address _winnerAddr, bool isFriendMatch) external returns (uint) {
        require(passport == _passport, "Not authorized player");
        require(deposits[_room] > 0, "Insuffient deposit amount");
        
        uint256 rewardAmount = deposits[_room] * 10**9 * (100 - taxPercent) / 100;
        uint256 fee = deposits[_room] * 10**9 * taxPercent / 100;

        llgContract.transfer(_winnerAddr, rewardAmount);
        llgContract.transfer(taxWallet, fee);

        if(!isFriendMatch) {
            if((block.timestamp - startTimeOfDay) / (24*60*60) >= 1) {
                startTimeOfDay += ((block.timestamp - startTimeOfDay) / (24*60*60))*24*60*60;
                numConsecutiveWins[_winnerAddr] = 1;
            } else {
                randomMatches[_winnerAddr].startDateTime = block.timestamp;
                numConsecutiveWins[_winnerAddr]++;
            }
        }

        deposits[_room] = 0;
        return numConsecutiveWins[_winnerAddr];
    }

    function refund(uint256 _room, uint256 _passport, address _playerAddr, uint _amount) external {
        require(deposits[_room] > 0, "Insuffient deposit amount");
        require(deposits[_room] <= _amount, "Can't refund such amount");
        require(passport == _passport, "Not authorized player");
        
        llgContract.transfer(_playerAddr, _amount * 10**9);

        deposits[_room] -= _amount;
    } 

    function giveBonusReward(address _playerAddr, uint256 _passport) external {
        require(passport == _passport, "Not authorized player");

        if(numConsecutiveWins[_playerAddr] == 3) llgContract.transferFrom(bonusWallet, _playerAddr, 50 * 10**9);
        else if(numConsecutiveWins[_playerAddr] == 5) llgContract.transferFrom(bonusWallet, _playerAddr, 100 * 10**9);
        else if(numConsecutiveWins[_playerAddr] == 10) llgContract.transferFrom(bonusWallet, _playerAddr, 300 * 10**9);
        
    }
}