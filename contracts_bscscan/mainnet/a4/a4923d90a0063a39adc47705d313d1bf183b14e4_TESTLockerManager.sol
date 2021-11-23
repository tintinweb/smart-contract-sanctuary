// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        _setOwner(initialOwner);
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
        require(owner() == msg.sender, "TESTLocker: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "TESTLocker: new owner cannot be the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract TESTLocker is Ownable {
    uint256 public startTimestamp;
    uint256 public unlockTimestamp;

    uint256 public lockedTokenAmount;

    IERC20 token;
    
    constructor() Ownable(address(0)) {}

    function setup(uint256 unlockEpoch, address owner, address baseToken, uint256 amount) public {
        _setOwner(owner);
        token = IERC20(baseToken);
        
        if(token.balanceOf(address(this)) != amount) {
            revert("TESTLocker: incorrect token balance");
        }
        
        lockedTokenAmount = amount;
        
        startTimestamp = block.timestamp;
        unlockTimestamp = unlockEpoch;
    }

    function withdraw() public onlyOwner {
        require(block.timestamp >= unlockTimestamp, "TESTLocker: token is not unlocked yet");
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "TESTLocker: token balance is zero");

        token.transfer(msg.sender, balance);
        
        selfdestruct(payable(msg.sender));
    }

    function withdrawSurplus() public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > lockedTokenAmount, "TESTLocker: balance equals locked amount");

        token.transfer(msg.sender, balance - lockedTokenAmount);
    }
}

contract TESTLockerManager {
    address public base;

    uint256[] lockerTypes;

    Locker[] public lockers;
    mapping(address => uint256) lockerIndices;

    uint256 public lockerCount;

    struct Locker {
        address owner;
        address lockerAddress;
        uint256 startTimestamp;
        uint256 unlockTimestamp;
        uint256 lockedAmount;
    }

    constructor(address baseToken) {
        base = baseToken;

        lockerTypes.push(3 minutes);
        lockerTypes.push(5 minutes);
        lockerTypes.push(10 minutes);
        lockerTypes.push(15 minutes);
    }

    function getLockerByAddress(address lockerAddress) public view returns (Locker memory) {
        return lockers[lockerIndices[lockerAddress]];
    }

    function createLocker(uint256 lockerType, uint256 amount) public {
        uint256 unlockTime = block.timestamp + lockerTypes[lockerType];
                
        TESTLocker locker = new TESTLocker();

        IERC20(base).transferFrom(msg.sender, address(locker), amount);
        locker.setup(unlockTime, msg.sender, base, amount);

        lockers.push(Locker(msg.sender, address(locker), block.timestamp, unlockTime, amount));
        lockerIndices[address(locker)] = lockers.length - 1;
        lockerCount++;
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