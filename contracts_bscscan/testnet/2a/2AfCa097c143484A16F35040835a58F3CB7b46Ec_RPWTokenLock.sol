pragma solidity ^0.8.5;
// SPDX-License-Identifier: Unlicensed

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IRPWTokenLock.sol";


contract RPWTokenLock is Context, Ownable, IRPWTokenLock{
    mapping (address => bool) private _lockPermission;
    mapping (address => uint[]) private _lockRecord;
    mapping (address => mapping (uint => uint)) private _lockTime;
    mapping (address => mapping (uint => uint)) private _lockAmount;    
    mapping (address => bool) private _operatorList;

    IERC20 private _tokenContract;

    uint public stdLockTimeInDays = 180;
    string private _name;
    string private _symbol;

    constructor( string memory name_, 
        string memory symbol_,
        address tokenContractAddress)
    {
        _name = name_;
        _symbol = symbol_;        
        _operatorList[_msgSender()] = true;
        _operatorList[tokenContractAddress] = true;
        _tokenContract = IERC20(tokenContractAddress);      
        emit SetTokenContract(tokenContractAddress);
    }

    function setStdLockTimeInDays(uint dayNum) external override onlyOwner {
        stdLockTimeInDays = dayNum;
        emit SetStdLockTimeInDays(dayNum);
    }

    function changeTokenContract(address contractAddress) external override onlyOwner {
        _tokenContract = IERC20(contractAddress);
        emit SetTokenContract(contractAddress);
    }

    function addOperator(address operator) external override onlyOwner {
        require(!_operatorList[operator], "RPWTokenLock: Already an operator");
        _operatorList[operator] = true;
        emit AddOperator(operator);
    }

    function removeOperator(address operator) external onlyOwner {
        require(_operatorList[operator], "RPWTokenLock: Not an operator");
        delete _operatorList[operator];
        emit RemoveOperator(operator);
    }

    function isAnOperator(address account) external view override returns (bool) {
        return _operatorList[account];
    }

    function hasLockPermission(address account) public view returns (bool) {
        return _lockPermission[account];
    }

    function enableLockPermission(address account) external override {
        require(_operatorList[_msgSender()], "RPWTokenLock: Not an operator");
        _lockPermission[account] = true;
    }

    function disableLockPermission(address account) external override {
        require(_operatorList[_msgSender()], "RPWTokenLock: Not an operator");
        _lockPermission[account] = false;
    }

    /**
     * @dev accumulate the total locked token, and return nearest time to unlock
     */
    function getLockedToken(address account) external view override returns (uint, uint)
    {
        require(_operatorList[_msgSender()], "RPWTokenLock: Not an operator");

        uint lockId;
        uint lockedAmount;
        uint unlockTime;
        for (uint i = 0; i < _lockRecord[account].length; i++){
            lockId = _lockRecord[account][i];
            lockedAmount += _lockAmount[account][lockId];
            if(unlockTime > _lockTime[account][lockId] || unlockTime == 0){
                unlockTime = _lockTime[account][lockId];
            }
        }
        return (lockedAmount, unlockTime);
    }

    function claimLockedToken(address tokenOwnerAddress) external override returns (bool) {
        require(_operatorList[_msgSender()], "RPWTokenLock: Not an operator");
        uint lockId = 0;
        uint unlockAmount = 0;
        for (uint i = 0; i < _lockRecord[tokenOwnerAddress].length; i++){
            lockId = _lockRecord[tokenOwnerAddress][i];
            if(lockId != 0 && block.timestamp >= _lockTime[tokenOwnerAddress][lockId]){
                unlockAmount = _lockAmount[tokenOwnerAddress][lockId];
                _tokenContract.transfer(tokenOwnerAddress, unlockAmount);
                delete _lockAmount[tokenOwnerAddress][lockId];
                delete _lockTime[tokenOwnerAddress][lockId];
                _lockRecord[tokenOwnerAddress][i] = 0;
                emit ClaimToken(tokenOwnerAddress, lockId, unlockAmount);
            }
        }
        return true;
    }

    function transferNLock(
        address sender, 
        address receipient,
        uint amount) external override 
    {      
        _transferNLock(
            sender, 
            receipient, 
            amount, 
            stdLockTimeInDays, 
            0);

    }

    // TODO: make sure RPW fee is disable when call the function. 
    function customTransferNLock(
        address sender, 
        address receipient, 
        uint amount, 
        uint lockTimeInDays, 
        uint startTime) external override onlyOwner
    {
        _transferNLock(
            sender, 
            receipient, 
            amount, 
            lockTimeInDays, 
            startTime);
    }

    function _transferNLock(
        address sender, 
        address receipient, 
        uint amount, 
        uint lockTimeInDays, 
        uint startTime) private 
    {
        require(_operatorList[_msgSender()], "RPWTokenLock: Not an operator");
        require(hasLockPermission(sender), "RPWTokenLock: No lock permision");         
        _tokenContract.transferFrom(sender, address(this), amount);
        uint lockId = block.timestamp;
        
        if(startTime != 0){
            lockId = startTime;
        }

        uint lockTime = lockId + 86400 * lockTimeInDays;
        _lockToken(receipient, lockId, amount, lockTime);
        emit LockToken(receipient, lockId, amount, lockTime);
    }

    function _lockToken(address tokenOwner, uint lockId, uint amount, uint lockTime) private {
        _lockRecord[tokenOwner].push(lockId);
        _lockTime[tokenOwner][lockId] = lockTime; 
        _lockAmount[tokenOwner][lockId] = amount;        
    }
}

pragma solidity ^0.8.5;
// SPDX-License-Identifier: Unlicensed

interface IRPWTokenLock {
    event AddOperator(address operator);
    event RemoveOperator(address operator);
    event SetTokenContract(address contractAddress);
    event ClaimToken(address tokenOwner, uint lockId, uint amount);
    event LockToken(address tokenOwner, uint lockId, uint amount, uint lockTime); 
    event SetStdLockTimeInDays(uint dayNum);

    function changeTokenContract(address contractAddress) external;
    function setStdLockTimeInDays(uint dayNum) external;
    function addOperator(address operator) external;
    function removeOperator(address operator) external;
    function isAnOperator(address account) external returns (bool);
    function enableLockPermission(address account) external;
    function disableLockPermission(address account) external ;
    function getLockedToken(address account) external view returns (uint, uint);
    function claimLockedToken(address tokenOwnerAddress) external returns (bool);
    function transferNLock(address sender, address receipient, uint amount) external;
    function customTransferNLock(address sender, address receipient, uint amount, uint lockTimeInDays, uint startTime) external;
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