/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;



// Part: IMinable

interface IMinable {
    function mint(address to, uint256 amount) external;
}

// Part: OpenZeppelin/[email protected]/Context

/*
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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/Ownable

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

// File: SimpleCoinStaking.sol

contract SimpleCoinStaking is Ownable {
    struct Pool {
        string name;
        address addr;
        uint256 totalRate;
        uint256 totalRate7th;
        uint256 threshold; // for dropping blind box
        uint256 boxKind;
        uint256 accUP;
        uint256 totalStakes;
        uint256 last;
    }

    struct User {
        uint256 stakes;
        uint256 accUP;
        uint256 cache;
        uint256 got;
        uint256 started; // effective started for dropping
    }

    address private _blin;
    address private _nft;
    mapping(uint256 => Pool) private _pools;
    uint256[] private _poolIndexes;
    mapping(uint256 => mapping(address => User)) private _users;
    uint256 private _secPerDrop;
    uint256 private _normal;
    uint256 private _normalTimestamp;
    uint256 private _block7th;
    bool private _emergency;
    uint256[11] private _points;
    uint256[11] private _profits = [
        3607500,
        3246750,
        2922075,
        2629867,
        2366880,
        2130192,
        1917173,
        1725456,
        1552910,
        1397619,
        1257857
    ];

    constructor(
        address blin_,
        address nft_,
        uint256 secPerDrop_,
        uint256[] memory indexes,
        string[] memory names,
        address[] memory addresses,
        uint256[] memory totalRates,
        uint256[] memory totalRate7ths,
        uint256[] memory thresholds,
        uint256[] memory boxes,
        uint256[11] memory points
    ) {
        _blin = blin_;
        _nft = nft_;
        _secPerDrop = secPerDrop_;
        _points = points;

        for (uint256 i = 0; i < indexes.length; i++) {
            uint256 index = indexes[i];
            _poolIndexes.push(index);

            Pool storage pool = _pools[index];
            pool.name = names[i];
            pool.addr = addresses[i];
            pool.totalRate = totalRates[i];
            pool.totalRate7th = totalRate7ths[i];
            pool.threshold = thresholds[i];
            pool.boxKind = boxes[i];
        }
    }

    function startNormal() public onlyOwner {
        require(_normal == 0, "already in normal");
        _normal = block.number;
        _normalTimestamp = block.timestamp;
        _block7th = _normal + 2;
        // _block7th = _normal + 28800 * 7;

        for (uint256 i = 0; i < _points.length; i++) {
            _points[i] += _normal;
        }
    }

    function normal() public view returns (uint256, uint256) {
        return (_normal, _normalTimestamp);
    }

    function setPool(
        uint256 index,
        string memory name,
        address addr,
        uint256 threshold,
        uint256 boxKind
    ) public onlyOwner {
        require(index > 0, "require index > 0");
        require(bytes(name).length > 0, "name required");

        Pool storage pool = _pools[index];
        pool.name = name;
        pool.addr = addr;
        pool.threshold = threshold;
        pool.boxKind = boxKind;

        for (uint256 i = 0; i < _poolIndexes.length; i++) {
            if (_poolIndexes[i] == index) {
                return;
            }
        }
        _poolIndexes.push(index);
    }

    function setPoolRates(
        uint256[] memory indexes,
        uint256[] memory totalRate,
        uint256[] memory totalRate7th
    ) public onlyOwner {
        for (uint256 i = 0; i < indexes.length; i++) {
            Pool storage pool = _pools[indexes[i]];
            if (
                pool.totalRate == totalRate[i] &&
                pool.totalRate7th == totalRate7th[i]
            ) {
                continue;
            }

            pool.accUP = _nowAccUP(pool);
            pool.last = block.number;
            pool.totalRate = totalRate[i];
            pool.totalRate7th = totalRate7th[i];
        }
    }

    function setProfits(uint256[11] memory profits_) public onlyOwner {
        for (uint256 i = 0; i < _poolIndexes.length; i++) {
            uint256 index = _poolIndexes[i];
            if (index == 0) {
                continue;
            }
            Pool storage pool = _pools[index];
            pool.accUP = _nowAccUP(pool);
            pool.last = block.number;
        }

        _profits = profits_;
    }

    function delPool(uint256 index) public onlyOwner {
        Pool storage pool = _pools[index];
        require(bytes(pool.name).length > 0, "pool not exists");

        delete _pools[index];
        for (uint256 i = 0; i < _poolIndexes.length; i++) {
            if (_poolIndexes[i] == index) {
                delete _poolIndexes[i];
            }
        }
    }

    function getPoolIndexes() public view returns (uint256[] memory) {
        return _poolIndexes;
    }

    function getPools(uint256[] memory indexes)
        public
        view
        returns (Pool[] memory)
    {
        Pool[] memory pools = new Pool[](indexes.length);
        for (uint256 i = 0; i < indexes.length; i++) {
            pools[i] = _pools[indexes[i]];
        }
        return pools;
    }

    function getPool(uint256 index) public view returns (Pool memory) {
        return _pools[index];
    }

    function stake(uint256 index, uint256 value) public payable {
        Pool storage pool = _pools[index];
        require(bytes(pool.name).length > 0, "pool not exists");

        if (pool.addr == address(0)) {
            value = msg.value;
        } else {
            IERC20(pool.addr).transferFrom(msg.sender, address(this), value);
        }

        require(value > 0, "requires value > 0");

        uint256 accUP = _nowAccUP(pool);
        User storage user = _users[index][msg.sender];
        user.cache += (user.stakes * (accUP - user.accUP)) / 10**24;
        user.stakes += value;
        user.accUP = accUP;

        pool.totalStakes += value;
        pool.accUP = accUP;
        pool.last = block.number;

        // for dropping
        if (
            _normal == 0 &&
            user.started == 0 &&
            pool.threshold > 0 &&
            pool.boxKind > 0 &&
            user.stakes >= pool.threshold
        ) {
            user.started = block.timestamp;
        }
    }

    function getUser(uint256 index, address account)
        public
        view
        returns (
            uint256 stakes,
            uint256 got,
            uint256 newReward,
            uint256 boxes
        )
    {
        User storage user = _users[index][account];
        Pool storage pool = _pools[index];
        stakes = user.stakes;
        got = user.got;
        newReward = _emergency
            ? 0
            : (user.stakes * (_nowAccUP(pool) - user.accUP)) /
                10**24 +
                user.cache;
        boxes = user.started == 0
            ? 0
            : ((_normal == 0 ? block.timestamp : _normalTimestamp) -
                user.started) / _secPerDrop;
    }

    function claimBoxes(uint256 index, uint256 n) public {
        User storage user = _users[index][msg.sender];
        Pool storage pool = _pools[index];
        require(pool.boxKind > 0, "no box associated");

        uint256 boxes =
            user.started == 0
                ? 0
                : ((_normal == 0 ? block.timestamp : _normalTimestamp) -
                    user.started) / _secPerDrop;
        require(n > 0 && n <= boxes, "param invalid");

        user.started += n * _secPerDrop;
        for (uint256 i = 0; i < n; i++) {
            IMinable(_nft).mint(msg.sender, pool.boxKind);
        }
    }

    function _nowAccUP(Pool storage pool) private view returns (uint256) {
        if (_normal == 0 || pool.totalStakes == 0) {
            return 0;
        }

        uint256 last = _normal > pool.last ? _normal : pool.last;
        uint256 stop = _points[_points.length - 1];
        if (stop > block.number) {
            stop = block.number;
        }

        uint256 profit = 0;
        for (uint256 i = 0; i < _points.length; i++) {
            uint256 point = _points[i];
            if (point <= last) {
                continue;
            }
            if (i == 0) {
                if (last < _block7th) {
                    if (stop <= _block7th) {
                        profit =
                            ((stop - last) * _profits[i] * pool.totalRate) /
                            100;
                        break;
                    } else {
                        profit =
                            ((_block7th - last) *
                                _profits[i] *
                                pool.totalRate) /
                            100;
                        last = _block7th;
                    }
                }
            }

            if (point >= stop) {
                profit +=
                    ((stop - last) * _profits[i] * pool.totalRate7th) /
                    100;
                break;
            }

            profit += ((point - last) * _profits[i] * pool.totalRate7th) / 100;
            last = point;
        }

        return pool.accUP + (profit * 10**24) / pool.totalStakes;
    }

    function reward(uint256 index) public {
        require(!_emergency, "in emergency");

        User storage user = _users[index][msg.sender];
        Pool storage pool = _pools[index];
        uint256 accUP = _nowAccUP(pool);
        uint256 amount =
            (user.stakes * (accUP - user.accUP)) / 10**24 + user.cache;
        require(amount > 0, "no reward");

        user.got += amount;
        user.cache = 0;
        user.accUP = accUP;

        pool.accUP = accUP;
        pool.last = block.number;

        IMinable(_blin).mint(msg.sender, amount);
    }

    function redeem(uint256 index) public {
        User storage user = _users[index][msg.sender];
        require(user.stakes > 0, "no stake");

        Pool storage pool = _pools[index];

        if (!_emergency) {
            uint256 accUP = _nowAccUP(pool);

            uint256 amount =
                (user.stakes * (accUP - user.accUP)) / 10**24 + user.cache;
            if (amount > 0) {
                IMinable(_blin).mint(msg.sender, amount);
            }
            pool.accUP = accUP;
            pool.last = block.number;
        }

        pool.totalStakes -= user.stakes;

        if (pool.addr == address(0)) {
            payable(msg.sender).transfer(user.stakes);
        } else {
            IERC20(pool.addr).transfer(msg.sender, user.stakes);
        }

        delete _users[index][msg.sender];
    }

    function setBlin(address blin_) public onlyOwner {
        _blin = blin_;
    }

    function getBlin() public view returns (address) {
        return _blin;
    }

    function setNFT(address nft_) public onlyOwner {
        _nft = nft_;
    }

    function getNFT() public view returns (address) {
        return _nft;
    }

    function setEmergency(bool value) public onlyOwner {
        _emergency = value;
    }

    function getEmergency() public view returns (bool) {
        return _emergency;
    }
}