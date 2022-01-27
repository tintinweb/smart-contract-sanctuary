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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Verifier is Ownable{

    struct CliffInfo {
        uint256 timeCliff;
        uint256  percentage; // % = percentage / 10000
    }
    uint256 constant public ONE_HUNDRED_PERCENT = 10000;
    CliffInfo[] public cliffInfo;
    bool public isSettingClaim = false;
    address public operator;
    // address => claim times => true/false
    mapping(address => mapping(uint => bool)) public status;

    modifier isSetting() {
        require(!isSettingClaim, "");
        _;
        isSettingClaim = true;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Only operator can use function");
        _;
    }

    constructor(address _operator) {
        operator = _operator;
    }

    function setOperator(address _newOperator) public onlyOwner {
        require(_newOperator != address(0), "Address must be different zero");
        operator = _newOperator;
    }

    function setCliffInfo(uint256[] memory _timeCliff, uint256[] memory _percentage) public onlyOperator isSetting {
        require(_timeCliff.length == _percentage.length, "Length must be equal");
        uint256 sum;
        for(uint256 i = 0; i < _timeCliff.length; i ++) {
            require(_percentage[i] <= ONE_HUNDRED_PERCENT, "percentage over 100 %");
            CliffInfo memory _cliffInfo;
            _cliffInfo.percentage = _percentage[i];
            _cliffInfo.timeCliff = _timeCliff[i];
            cliffInfo.push(_cliffInfo);
            sum += _percentage[i];
        }
        require(sum == ONE_HUNDRED_PERCENT, "total percentage is not 100%");
    }

    function approveClaim(address _user, uint256 _times) public onlyOperator {
        require(_times < cliffInfo.length, "times overflow");
        status[_user][_times] = true;
    }

    function verify(address _user, uint256 _totalToken, uint256 _claimTimes) public view returns (uint amountClaim, bool finish) {
        require(status[_user][_claimTimes] || _claimTimes == 0, "Verifier: User can not claim this time");
        require(_claimTimes < cliffInfo.length, "Verifier: times overflow");
        require(cliffInfo[_claimTimes].timeCliff <= block.timestamp, "Verifier: Can not claim this time");
        amountClaim = cliffInfo[_claimTimes].percentage * _totalToken / ONE_HUNDRED_PERCENT;
        finish = false;
        if(_claimTimes == cliffInfo.length - 1) {
            finish = true;
        }
    }
}