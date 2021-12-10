// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IKEY {
    function totalSupply() virtual external returns(uint256);
    function mint(uint256 _type, address _to, uint256 _tokenId) virtual external;
    function types(uint256 _keyId) virtual external view returns(string memory name, string memory hash, uint256 maxSupply, uint256 remain);
}
contract bitcityzLaunchpool is Ownable {
    IKEY public key;
    uint public earlyUnstakePanaltyPercent = 100; // 1% = 10
    uint public totalInvester;
    uint public totalStaked;
    struct PoolInfo {
        string name;
        IERC20 lockingToken;
        uint minLockingAmount;
        uint lockingTime;
        uint keyType;
        bool status;
    }
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 startTime; // Reward debt. See explanation below.
    }
    mapping (uint => mapping (address => UserInfo)) public userInfo; // pid => user => amount
    mapping(address => bool) public isStaked;
    event Stake(address indexed user, uint256 indexed pid, uint256 amount);
    event Unstake(address indexed user, uint256 indexed pid, uint256 amount);
    constructor(IKEY _key) {
        key = _key;
    }
    function unstake(uint _pid) public {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];
        require(user.amount > 0, 'bitcityzlaunchpad: not staked');
        uint fee;
        if(block.timestamp - user.startTime < pool.lockingTime) {
            fee = user.amount * earlyUnstakePanaltyPercent / 100;
            pool.lockingToken.transfer(owner(), fee);
        } else {
            uint _tokenId = key.totalSupply() + 1;
            key.mint(pool.keyType, _msgSender(), _tokenId);
        }
        pool.lockingToken.transfer(_msgSender(), user.amount - fee);
        user.amount = 0;
        emit Unstake(_msgSender(), _pid, user.amount);
    }
    function stake(uint _pid, uint _amount) public {
        PoolInfo memory pool = poolInfo[_pid];
        require(poolInfo[_pid].status, 'bitcityzlaunchpad: pool disabled');
        UserInfo storage user = userInfo[_pid][_msgSender()];
        require(user.amount == 0, 'bitcityzlaunchpad: already staked');
        require(_amount >= poolInfo[_pid].minLockingAmount, 'bitcityzlaunchpad: invalid amount');
        pool.lockingToken.transferFrom(_msgSender(), address(this), _amount);
        user.amount += _amount;
        user.startTime = block.timestamp;

        if(!isStaked[_msgSender()]) {
            totalInvester++;
            isStaked[_msgSender()] = true;
        }
        totalStaked += _amount;
        emit Stake(_msgSender(), _pid, _amount);
    }
    function set(uint _pid, uint _minLockingAmount, uint _lockingTime, bool _status) public onlyOwner {
        poolInfo[_pid].minLockingAmount = _minLockingAmount;
        poolInfo[_pid].lockingTime = _lockingTime;
        poolInfo[_pid].status = _status;
    }
    function config(uint _earlyUnstakePanaltyPercent) public onlyOwner {
        earlyUnstakePanaltyPercent = _earlyUnstakePanaltyPercent;
    }
    function addPool(string memory _name, IERC20 _lockingToken, uint _minLockingAmount, uint _lockingTime, uint _keyType) public onlyOwner {
        poolInfo.push(PoolInfo(_name, _lockingToken, _minLockingAmount, _lockingTime, _keyType, true));
    }
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly {chainId := chainid()}
        return chainId;
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