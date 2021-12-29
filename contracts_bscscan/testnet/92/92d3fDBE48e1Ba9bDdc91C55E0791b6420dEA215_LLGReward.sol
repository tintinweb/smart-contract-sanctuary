/**
 *Submitted for verification at BscScan.com on 2021-12-29
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

    uint256 public taxPercent = 10;
    address public devWallet = 0x09964eAB43f1bd45Ab98416Dd94d16C8b76AB5Aa;

    mapping(uint256 => uint256) public deposits;
    mapping(uint256 => uint256) public passports;

    bool public APPROVED;

    constructor(address _llg) {
        llgContract = ILLG(_llg);
    }

    function getLLGBalanceOf(address _user) external view returns (uint256) {
        return llgContract.balanceOf(_user);
    }

    function setTaxPercent(uint _taxPercent) external onlyOwner {
        taxPercent = _taxPercent;
    }

    function setDevWallet(address _address) external onlyOwner {
        devWallet = _address;
    }

    function getDevWallet() external view returns (address) {
        return devWallet;
    }

    function depositForRoom(uint256 _roomId, address _playerAddr, uint256 _funds) external returns (bool) {
        if(llgContract.approve(_playerAddr, _funds)) {
            // llgContract.transferFrom(_playerAddr, devWallet, _funds);
            // llgContract.transfer(devWallet, _funds);
            deposits[_roomId] += _funds;
            APPROVED = true;
            return true;
        } else {
            APPROVED = false;
            return false;
        }
    }

    function issuePassport(uint256 _roomId, uint256 _passport) external {
        passports[_roomId] = _passport;
    }

    function offerWinningReward(uint256 _roomId, uint256 _passport, address _winnerAddr) external returns (uint256) {
        if(deposits[_roomId] > 0 && passports[_roomId] == _passport) {
            uint256 rewardAmount = deposits[_roomId] * (100 - taxPercent) / 100;
            llgContract.transferFrom(devWallet, _winnerAddr, rewardAmount);
            deposits[_roomId] = 0;
            return rewardAmount;
        } else {
            return 0;
        }
    } 
}