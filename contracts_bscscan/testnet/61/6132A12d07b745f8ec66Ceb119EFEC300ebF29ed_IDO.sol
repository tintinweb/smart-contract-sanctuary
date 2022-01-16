// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IKEY {
    function totalSupply() external returns(uint256);
    function burn(uint256 tokenId) external;
    function tokenHash(uint256 _keyId) external view returns(string memory hash);
}

contract IDO is Ownable {
    IKEY public key;
    struct PoolInfo {
        IERC20 idoToken;
        IERC20 idoToken2Buy;
        uint tokenBuy2IDOtoken;
        uint amount;
        uint totalAmount;
        uint remainAmount;
        address idoUnlock;
        string keyType;
        uint startTime;
        uint endTime;
        uint startTimeWL;
        uint endTimeWL;
        uint status; // 0 => Upcoming; 1 => register whitelist; 2 => in progress; 3 => completed
        bool isOverWhitelist;
    }
    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(uint => address[]) public whitelistArr;
    mapping(address => mapping(uint => bool)) public isWhitelist; // user => pid => is whitelist
    mapping(uint => address[]) public buyerArr;
    mapping(address => mapping(uint => bool)) public isBuyer; // user => pid => is buyers
    mapping(address => bool) public projects;
    uint public projectsLength;
    mapping(address => bool) public investors;
    uint public investorsLength;
    mapping(address => uint) public totalFundRaised;

    event Whitelist(address _user, uint _pid, uint _tokenId);
    event Buy(address _user, uint _pid, uint _tokenAmount);
    constructor(IKEY _key) {
        key = _key;
    }
    function getWhitelist(uint _pid) external view returns(address[] memory) {
        return whitelistArr[_pid];
    }
    function getBuyers(uint _pid) external view returns(address[] memory) {
        return buyerArr[_pid];
    }
    function whitelist(uint _pid, uint _tokenId) external {
        require(keccak256(bytes(key.tokenHash(_tokenId))) == keccak256(bytes(poolInfo[_pid].keyType)) , 'IDO: key invalid');
        if(poolInfo[_pid].isOverWhitelist) require(whitelistArr[_pid].length * poolInfo[_pid].amount < poolInfo[_pid].totalAmount, 'IDO: pool whitelist is full');
        key.burn(_tokenId);
        isWhitelist[_msgSender()][_pid] = true;
        whitelistArr[_pid].push(_msgSender());
        emit Whitelist(_msgSender(), _pid, _tokenId);
    }
    function buy(uint _pid) external {
        PoolInfo storage _pool = poolInfo[_pid];
        require(_pool.status == 2, 'IDO: pool not active');
        require(_pool.startTime <= block.timestamp && _pool.endTime > block.timestamp, 'IDO: pool not on time');
        require(isWhitelist[_msgSender()][_pid], 'IDO: buyer not whitelisted');
        require(_pool.remainAmount >= _pool.amount, 'IDO: over remain amount');
        uint buyAmount = _pool.amount * _pool.tokenBuy2IDOtoken / 1 ether;
        _pool.idoToken2Buy.transferFrom(_msgSender(), _pool.idoUnlock, buyAmount);
        isBuyer[_msgSender()][_pid] = true;
        buyerArr[_pid].push(_msgSender());
        _pool.remainAmount -= _pool.amount;
        if(!investors[_msgSender()]) {
            investors[_msgSender()] = true;
            investorsLength++;
        }
        totalFundRaised[address(_pool.idoToken2Buy)] += buyAmount;
        emit Buy(_msgSender(), _pid, _pool.amount);
    }
    function set(uint _pid, uint _amount, uint _status, bool _isOverWhitelist) external onlyOwner {
        require(_status > poolInfo[_pid].status && _status < 4, 'IDO: invalid status');
        poolInfo[_pid].amount = _amount;
        poolInfo[_pid].status = _status;
        poolInfo[_pid].isOverWhitelist = _isOverWhitelist;
    }
    function setKey(IKEY _key) external onlyOwner {
        key = _key;
    }
    function addPool(IERC20 _idoToken, IERC20 _idoToken2buy, uint _tokenBuy2IDOtoken, uint _amount, uint _totalAmount, address _idoUnlock, string memory _keyType, uint _startTime, uint _endTime, uint _startTimeWL, uint _endTimeWL, bool _isOverWhitelist) external onlyOwner {
        require(_idoUnlock != address(0), 'IDO: invalid unlock address');
        poolInfo.push(PoolInfo(_idoToken, _idoToken2buy, _tokenBuy2IDOtoken, _amount, _totalAmount, _totalAmount, _idoUnlock, _keyType, _startTime, _endTime, _startTimeWL, _endTimeWL, 0, _isOverWhitelist));
        if(!projects[address(_idoToken)]) {
            projects[address(_idoToken)] = true;
            projectsLength++;
        }
    }
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    /*
     * @notice View addresses all the uaers whitelist
     * @param cursor: cursor
     * @param size: size of the response
     */
    function viewWhitelists(uint _pid, uint256 cursor, uint256 size) external view returns (address[] memory _whitelistArr)
    {
        uint256 length = size;

        if (length > whitelistArr[_pid].length - cursor) {
            length = whitelistArr[_pid].length - cursor;
        }

        _whitelistArr = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            _whitelistArr[i] = whitelistArr[_pid][cursor + i];
        }
    }
    function getPool(uint _pid) external view returns(IERC20 idoToken, uint amount, uint totalAmount, uint status) {
        PoolInfo memory pool = poolInfo[_pid];
        idoToken = pool.idoToken;
        amount = pool.amount;
        totalAmount = pool.totalAmount;
        status = pool.status;
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