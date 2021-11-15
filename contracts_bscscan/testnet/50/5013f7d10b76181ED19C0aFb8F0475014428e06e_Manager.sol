pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
contract Manager is Ownable  {
    mapping(address => bool) public battlefields;
    mapping(address => bool) public trainingfields;
    mapping(address => bool) public farmOwners;
    mapping(address => bool) public markets;
    mapping(address => bool) public evolvers;
    mapping(uint256 => uint256) public timesBattle;

    uint256 constant public feeEvolve = 500 * 10 ** 18;
    uint256 constant public priceEgg = 15000 * 10 ** 18;
    uint256 constant public feeMarketRate = 15;
    uint256 constant public generation = 0;

    uint256 public feeChangeTribe = 350 * 10**6 * 10**18;

    uint256 public timeLimitBattle = 2 * 60 * 60;
    uint256 public rateBattleReward = 3 * 10 ** 18;
    uint256 public rateBattleExp = 3 * 10 ** 18;
    uint256 public rateBattleLoseRate = 7;

    address public feeAddress;
    event ChangeTimeLimitBatlle(uint256 _value);
    event ChangeTimesBattle(uint256 _index, uint256 _value);
    event ChangeRateBattleReward(uint256 _value);
    event ChangeRateBattleExp(uint256 _value);
    event ChangeChangeTribe(uint256 _value);
    event ChangeFeeAddress(address _address);

    event setEvolversAddr(address _address, bool _status);
    event setTrainingFieldsAddr(address _address, bool _status);
    event setBattleFieldsAddr(address _address, bool _status);
    event setMarketsAddr(address _address, bool _status);
    event setFarmOwnersAddr(address _address, bool _status);

    constructor() {
        timesBattle[0] = 0;
        timesBattle[1] = 1;
        timesBattle[2] = 1;
        timesBattle[3] = 2;
        timesBattle[4] = 2;
        timesBattle[5] = 3;
        timesBattle[6] = 4;
    }

    function setfeeChangeTribe(uint256 _value) public onlyOwner {
        require(_value >= 200000 * 10 ** 18, "low value");
        feeChangeTribe = _value;
        emit ChangeChangeTribe(_value);

    }

    function settimesBattle(uint256 _index, uint256 _value) public onlyOwner {
        require(_value > 0, "error zero");
        timesBattle[_index] = _value;
        emit ChangeTimesBattle(_index, _value);
    }

    function setfeeAddress(address _addr) public onlyOwner {
        feeAddress = _addr;
        emit ChangeFeeAddress(_addr);
    }

    function setTimeLimitBattle(uint256 _value) public onlyOwner {
        require(_value <= 21600, "over 6hours");
        timeLimitBattle = _value;
        emit ChangeTimeLimitBatlle(_value);
    }

    function setRateBattleReward(uint256 _value) public onlyOwner {
        require(_value > 0, "error zero");
        rateBattleReward = _value;
        emit ChangeRateBattleReward(_value);
    }
    
    function setRateBattleExp(uint256 _value) public onlyOwner {
        require(_value > 0, "error zero");
        rateBattleExp = _value;
        emit ChangeRateBattleExp(_value);
    }

    function setMarkets(address _address, bool _value) public onlyOwner {
        markets[_address] = _value;
        emit setMarketsAddr(_address, _value);
    }
    
    function setFarmOwners(address _address, bool _value) public onlyOwner {
        farmOwners[_address] = _value;
        emit setFarmOwnersAddr(_address, _value);

    }
    
    function setBattleFields(address _address, bool _value) public onlyOwner {
        battlefields[_address] = _value;
        emit setBattleFieldsAddr(_address, _value);
    }

    function setTrainingFields(address _address, bool _value) public onlyOwner {
        trainingfields[_address] = _value;
        emit setTrainingFieldsAddr(_address, _value);
    }
    
    function setEvolvers(address _address, bool _value) public onlyOwner {
        evolvers[_address] = _value;
        emit setEvolversAddr(_address, _value);
    }
}

// SPDX-License-Identifier: MIT

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

