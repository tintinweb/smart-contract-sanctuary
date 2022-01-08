// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IKEY {
    function totalSupply() external returns(uint256);
    function burn(uint256 tokenId) external;
    function types(uint256 _keyId) external view returns(string memory name, string memory hash);
}
interface IUnlockIDO {
    function isAvailableUnlock(address _user) external view returns(bool _isAvailable, uint _amount);
}
contract IDO is Ownable {
    IKEY public key;
    struct PoolInfo {
        IERC20 idoToken;
        IERC20 idoToken2Buy;
        uint tokenBuy2IDOtoken;
        uint minAmount;
        uint maxAmount;
        uint totalAmount;
        uint remainAmount;
        address idoUnlock;
        string keyType;
        uint startTime;
        uint endTime;
        bool status;
    }
    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => mapping(uint => bool)) public isWhitelist; // user => pid => is whitelist
    mapping(address => mapping(uint => uint)) public buyAmount; // user => pid => buy amount

    event Whitelist(address _user, uint _pid, uint _tokenId);
    event Buy(address _user, uint _pid, uint _tokenAmount);
    constructor(IKEY _key) {
        key = _key;
    }
    function whitelist(uint _pid, uint _tokenId) external {
        string memory _hash;
        (,_hash) = key.types(_tokenId);
//        require(keccak256(bytes(_hash)) == keccak256(bytes(poolInfo[_pid].keyType)) , 'IDO: key invalid');
//        key.burn(_tokenId);
        isWhitelist[_msgSender()][_pid] = true;
        emit Whitelist(_msgSender(), _pid, _tokenId);
    }
    function buy(uint _pid, uint _tokenAmount) external {
        PoolInfo storage _pool = poolInfo[_pid];
        require(_pool.status == true, 'IDO: pool not active');
        require(_pool.startTime <= block.timestamp && _pool.endTime > block.timestamp, 'IDO: pool not on time');
        require(_pool.minAmount <= _tokenAmount && _pool.maxAmount >= _tokenAmount, 'IDO: invalid token amount');
        require(isWhitelist[_msgSender()][_pid], 'IDO: buyer not whitelisted');
        require(buyAmount[_msgSender()][_pid] + _tokenAmount <= _pool.maxAmount, 'IDO: over max amount');
        require(_pool.remainAmount >= _tokenAmount, 'IDO: over remain amount');
        _pool.idoToken2Buy.transferFrom(_msgSender(), _pool.idoUnlock, _tokenAmount * _pool.tokenBuy2IDOtoken);
        _pool.idoToken.transfer(_msgSender(), _tokenAmount);
        buyAmount[_msgSender()][_pid] += _tokenAmount;
        _pool.remainAmount -= _tokenAmount;
        emit Buy(_msgSender(), _pid, _tokenAmount);
    }
    function set(uint _pid, uint _minAmount, uint _maxAmount, bool _status) external onlyOwner {
        poolInfo[_pid].minAmount = _minAmount;
        poolInfo[_pid].maxAmount = _maxAmount;
        poolInfo[_pid].status = _status;
    }
    function addPool(IERC20 _idoToken, IERC20 _idoToken2buy, uint _tokenBuy2IDOtoken, uint _minAmount, uint _maxAmount, uint _totalAmount, address _idoUnlock, string memory _keyType, uint _startTime, uint _endTime) external onlyOwner {
        require(_idoUnlock != address(0), 'IDO: invalid unlock address');
        poolInfo.push(PoolInfo(_idoToken, _idoToken2buy, _tokenBuy2IDOtoken, _minAmount, _maxAmount, _totalAmount, _totalAmount, _idoUnlock, _keyType, _startTime, _endTime, true));
    }
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
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