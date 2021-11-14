pragma solidity 0.8.0;
// SPDX-License-Identifier: Unlicensed

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SquidWarsLib.sol";

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function mint(address account) external;
    function balanceOf(address owner) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom( address _from, address _to, uint256 _value ) external returns (bool success);
}

interface ISquidWarsRandomCallback {
    function callback(bytes32 requestId, uint256 roudom)
        external
        returns (bool);
}

interface ISquidWarsUtils {
    function getRandomResult(bytes32 requestId) external returns (uint256);

    function getRandomNumber(address callback)
        external
        returns (bytes32 requestId);
}

contract SquidWarsPair is Ownable, Pausable, ISquidWarsRandomCallback {

    event PlayEvent(address indexed account,uint indexed tikects);

    event GameBegin(uint curEndpoint_,uint finishtime_);

    //用户信息
    mapping(address => UsersInfo) private _usersInfo;

    //总计关卡数
    uint256 constant endpoint = 2;
    //没关时长
    uint256 public constant duration = 86400;

    //结束的时间
    uint256 public finishtime;

    uint256 public prefinishtime;

    //当局关卡数
    uint256 public curEndpoint;

    uint256 public immutable _ticketPirce;

    struct GameLevels {
        uint16 rate;
        uint32 duration;
        uint32 lowerBound;
        uint32 upperBound;
        uint64 numOfAccounts;
    }

    mapping(uint256 => GameLevels) public _gameLevels;

    //鱿鱼游戏的通证
    IERC20 public immutable _squidWars;

    //角色NFT，创建合约时初始化
    IERC721 public immutable _squidWarsNftActor;

    ISquidWarsUtils public immutable _util;

    IERC20 public constant _squidWarsPreSales = IERC20(0x80A0fb1dBF9cda00a4886cE3Ba1E5C0c9c78B35e);

    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    ///
    /// 手续费
    ///

    //奖金的10% 用于下一轮的
    uint256 public constant _bonusFee = 100;
    //运营费用
    uint256 public constant _tipFee = 100;

    uint256 public tip;

    uint256 public bonus;

    uint256 public numOfTikects;

    uint256 public numOfAccounts;

    uint256 private _range;

    constructor(
        address squidWars_,
        address squidWarsNftActor_,
        uint256 ticketPirce_,
        address util_
    ) {
        _squidWars = IERC20(squidWars_);
        _squidWarsNftActor = IERC721(squidWarsNftActor_);
        _ticketPirce = ticketPirce_;
        _util = ISquidWarsUtils(util_);
    }
    
    /** Game Controll */
    function play(uint256 tickets)
        public
        whenNotPaused
        returns (bool)
    {
        require(curEndpoint <= 1, "game has started");
        uint256 blocktime_ = block.timestamp;
        if (curEndpoint == 0) {
            //如果游戏未开始则，开始游戏
            curEndpoint = 1;
            finishtime = blocktime_ + _gameLevels[curEndpoint].duration;
        }
        //支持预售票数
        uint numOfPreTikects = _squidWarsPreSales.balanceOf(msg.sender);
        require(numOfPreTikects > 0 || tickets > 0);
        UsersInfo storage usersInfo = _usersInfo[msg.sender];
        require(usersInfo.blocktime <= prefinishtime, "wait next round");
        usersInfo.endpoint = 1;
        usersInfo.blocktime = uint64(blocktime_);
        usersInfo.num = 0;


        if(tickets > 0) {
            buyTikects(msg.sender, tickets);
            usersInfo.tickets = uint128(tickets);
        }else{
            _squidWarsPreSales.transferFrom(msg.sender,deadAddress, numOfPreTikects);
            usersInfo.tickets = uint128(numOfPreTikects);
        } 
        return true;
    }

    address public _referee;

    mapping(bytes32 => bool) private _orders;

    function next(bytes memory signature)
        public
        whenNotPaused
        returns (bool)
    {
        UsersInfo storage userInfo = _usersInfo[msg.sender];
        require(curEndpoint == userInfo.endpoint, "revert for endpoint");
        require(userInfo.blocktime > prefinishtime, "game is over");
        require(userInfo.num == 0, "num error");
        bytes32 hash = SquidWarsLib.hashToVerify(msg.sender, userInfo);
        require(!_orders[hash], "signature hash expired"); 
        require(
            SquidWarsLib.verify(_referee, hash, signature),
            "Signature not valid."
        );
        userInfo.num = uint32(++numOfAccounts);
        _orders[hash] = true;
        if (finishtime < block.timestamp) {
            //结束当前关卡
            _nextSession();
        }
        return true;
    }

    function hasNext() public returns (bool) {
        UsersInfo storage userInfo = _usersInfo[msg.sender];
        GameLevels memory level = _gameLevels[userInfo.endpoint];
        require(userInfo.endpoint == curEndpoint - 1, "Waiting for God's Hand");
        require(
            (userInfo.num >= level.lowerBound &&
                userInfo.num < level.upperBound) ||
                (userInfo.num + level.numOfAccounts >= level.lowerBound &&
                    userInfo.num + level.numOfAccounts < level.upperBound)
        );
        if (++userInfo.endpoint > endpoint) {
            numOfTikects += userInfo.tickets;
        }
        userInfo.num = 0;
        return true;
    }

    /**
     * Requests randomness
     */
    function _nextSession() internal {
        if (!paused()) {
            _pause();
        }
        _util.getRandomNumber(address(this));
    }

    function nextSession() public onlyOwner {
        require(block.timestamp > finishtime);
        _nextSession();
    }

    function callback(bytes32 requestId, uint256 randomness)
        external
        override
        returns (bool)
    {
        require(msg.sender == address(_util) || true);
        // randomResult = randomness;
        //计算这一关的通过概率
        GameLevels storage level = _gameLevels[curEndpoint];
        uint256 num = (numOfAccounts * level.rate) / 1000;
        level.lowerBound = uint32(randomness % numOfAccounts) + 1;
        level.upperBound = level.lowerBound + uint32(num == 0 ? 1: num);
        level.numOfAccounts = uint64(numOfAccounts);

        //尝试开启下一关
        curEndpoint++;
        GameLevels memory nlevel = _gameLevels[curEndpoint];
        finishtime += nlevel.duration;
        numOfAccounts = 0;

        if (paused()) {
            _unpause();
        }
        return true;
    }

    function buyTikects(address account_, uint256 tickets)
        internal
        returns (uint256 amount_)
    {
        amount_ = _ticketPirce * tickets;
        require(_squidWars.transferFrom(account_, address(this), amount_));
    }

    function getReward() public {
        UsersInfo memory usersInfo = _usersInfo[msg.sender];
        require(usersInfo.endpoint > endpoint);
        uint256 balance = _squidWars.balanceOf(address(this));
        balance -= tip + bonus;
        uint256 numOfTikects_ = numOfTikects;
        uint256 reward = (((balance * usersInfo.tickets) / numOfTikects) *
            (_tipFee + _bonusFee)) / 1000;
        numOfTikects_ -= usersInfo.tickets;
        (uint256 bonusFee_, uint256 tipFee_, uint256 amount_) = SquidWarsLib
            .getFee(reward, _bonusFee, _tipFee);
        (uint256 fee_, uint256 ramount_) = SquidWarsLib.getWithdrawFee(
            amount_,
            finishtime
        );
        tip += fee_ + tipFee_;
        bonus += bonusFee_;
        delete _usersInfo[msg.sender];
        _squidWars.transfer(msg.sender, ramount_);
        if (numOfTikects_ == 0) {
            _reset();
        }
    }

    function getUsersInfo(address account)
        public
        view
        returns (UsersInfo memory)
    {
        return _usersInfo[account];
    }

    function reset() public onlyOwner {
        // require(block.timestamp - finishtime > 86400 * 30);
        _reset();
    }

    function _reset() internal {
        numOfTikects = 0;
        curEndpoint = 0;
        prefinishtime = finishtime;
        numOfAccounts = 0;
    }

    function setGameLevels(
        uint256 i,
        uint16 rate,
        uint32 duration_
    ) external onlyOwner {
        require(rate != 0 && duration_ != 0, "Invalid level");
        GameLevels storage level = _gameLevels[i];
        level.rate = rate;
        level.duration = duration_;
    }

    function setReferee(address referee_) public onlyOwner {
        _referee = referee_;
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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

pragma solidity 0.8.0;
// SPDX-License-Identifier: Unlicensed

//用户数据结构
struct UsersInfo {
    uint32 endpoint;
    uint32 num;
    uint64 blocktime;
    uint128 tickets;
}

library SquidWarsLib {
    function getFee(uint256 amount,uint _bonusFee,uint _tipFee)
        public
        pure
        returns (
            uint256 fee_,
            uint256 tip_,
            uint256 amount_
        )
    {
        fee_ = (amount * _bonusFee) / 1000;
        tip_ = (amount * _tipFee) / 1000;
        amount_ -= fee_ + tip_;
    }

    function getWithdrawFee(uint256 amount,uint finishtime)
        public
        view
        returns (uint256 fee_, uint256 amount_)
    {
        uint256 r = (block.timestamp + finishtime) / 86400;
        if (r > 25) {
            r = 25;
        }
        amount_ = (amount * (r + 75)) / 100;
        fee_ = amount - amount_;
    }

    function hashUsersInfo(
        address tokenId,UsersInfo memory info
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    tokenId,
                    info.endpoint,
                    info.num,
                    info.blocktime,
                    info.tickets,
                    address(this)
                )
            );
    }

    function hashToSign(address tokenId, uint32 endpoint_, uint32 num, uint64 blocktime, uint128 tickets ) public view returns (bytes32) {
        UsersInfo memory info = UsersInfo(endpoint_, num, blocktime, tickets);
        return hashUsersInfo(tokenId,info);
    }

    function hashToVerify(address tokenId,
        UsersInfo memory info
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    hashUsersInfo(tokenId,info)
                )
            );
    }

    function verify(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) public pure returns (bool) {
        require(signer != address(0));
        require(signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28);

        return signer == ecrecover(hash, v, r, s);
    }
}