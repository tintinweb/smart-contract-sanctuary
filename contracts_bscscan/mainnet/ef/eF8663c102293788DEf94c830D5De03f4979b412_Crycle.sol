// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../interfaces/IKeplerFactory.sol';
import '../interfaces/IKeplerToken.sol';
import '../interfaces/IKeplerPair.sol';
import '../interfaces/IMasterChef.sol';
import '../interfaces/IUser.sol';

contract Crycle is Ownable {
    using SafeMath for uint256;

    event NewCrycle(address creator, string title, string mainfest, string telegram, uint256 timestamp);
    event NewTitle(address creator, string oldTitle, string newTitle, uint256 timestamp);
    event NewMainfest(address creator, string oldMainfest, string newMainfest, uint256 timestamp);
    event NewTelegram(address creator, string oldTelegram, string newTelegram, uint256 timestamp);
    event NewUser(address user, address creator, uint256 userNum, uint256 timestamp);
    event NewVoteInfo(uint256 voteId, uint256 beginAt, uint256 countAt, uint256 finishAt, uint256 reward);
    event NewVote(uint256 voteId, address user, address crycle, uint256 num, uint totalSended, uint totalReceived);

    IUser public user;
    IMasterChef public masterChef;
    IKeplerPair[] public pairs;
    IERC20 public busd;
    IKeplerToken public sds;
    IKeplerFactory public factory;

    uint256 constant public MIN_LOCK_AMOUNT = 100 * 1e18;
    uint256 constant public MIN_INVITER_AMOUNT = 1000 * 1e18;

    struct CrycleInfo {
        address creator;
        string title;
        string mainfest;
        string telegram;
        uint256 userNum;
    }
    mapping(address => CrycleInfo) public crycles;
    mapping(address => address) public userCrycle;
    mapping(uint256 => mapping(address => uint256)) public userVote;
    mapping(uint256 => mapping(address => uint256)) public crycleVote;
    mapping(uint256 => address[]) public voteWiners;
    mapping(uint256 => mapping(address => uint256)) public voteReward;

    function addPair(IKeplerPair pair) external onlyOwner {
        pairs.push(pair);
    }

    function removePair(uint index) external onlyOwner {
        require(index < pairs.length, "illegal index");
        if (index < pairs.length - 1) {
            pairs[index] = pairs[pairs.length - 1];
        }
        pairs.pop();
    }


    constructor(IUser _user, IMasterChef _masterChef, IKeplerPair _pair, IERC20 _busd, IKeplerToken _sds, IKeplerFactory _factory) {
        user = _user;
        masterChef = _masterChef;
        pairs.push(_pair);
        busd = _busd;
        sds = _sds;
        factory = _factory;
    }

    function getPairTokenPrice(IKeplerPair _pair, IERC20 token) internal view returns(uint price) {
        address token0 = _pair.token0();
        address token1 = _pair.token1();
        require(token0 == address(token) || token1 == address(token), "illegal token");
        (uint reserve0, uint reserve1,) = _pair.getReserves();
        if (address(token) == token0) {
            if (reserve0 != 0) {
                return IERC20(token0).balanceOf(address(_pair)).mul(1e18).div(reserve0);
            }
        } else if (address(token) == token1) {
            if (reserve1 != 0) {
                return IERC20(token1).balanceOf(address(_pair)).mul(1e18).div(reserve1);
            }
        }
        return 0;
    }

    function canCreateCrycle(address _user) public view returns (bool) {
        uint totalUser = 0;
        uint totalInviter = 0;
        for (uint i = 0; i < pairs.length; i ++) {
            uint price = getPairTokenPrice(pairs[i], busd);
            uint balanceUser = masterChef.getUserAmount(pairs[i], _user, 3);
            uint balanceInviter = masterChef.getInviterAmount(pairs[i], _user);
            totalUser = totalUser.add(balanceUser.mul(price).div(1e18));
            totalInviter = totalInviter.add(balanceInviter.mul(price).div(1e18));
        }
        if (totalUser >= MIN_LOCK_AMOUNT || totalInviter >= MIN_INVITER_AMOUNT) {
            return true;
        } else {
            return false;
        }
    }

    function createCrycle(string memory title, string memory mainfest, string memory telegram) external {
        require(bytes(title).length <= 32, "title too long");
        require(bytes(mainfest).length <= 1024, "mainfest too long");
        require(bytes(telegram).length <= 256, "mainfest too long");
        require(canCreateCrycle(msg.sender), "at lease lock 200 BUSD and SDS or invite 2000 BUSD and SDS");
        require(crycles[msg.sender].creator == address(0), "already create crycle");
        require(userCrycle[msg.sender] == address(0), "already in crycle");
        crycles[msg.sender] = CrycleInfo({
            creator: msg.sender,
            title: title,
            mainfest: mainfest,
            telegram: telegram,
            userNum: 0
        });
        userCrycle[msg.sender] = msg.sender;
        crycles[msg.sender].userNum = crycles[msg.sender].userNum + 1;
        emit NewUser(msg.sender, msg.sender, crycles[msg.sender].userNum, block.timestamp);
        emit NewCrycle(msg.sender, title, mainfest, telegram, block.timestamp);
    }

    function setTitle(string memory title) external {
        require(bytes(title).length <= 32, "title too long");
        require(crycles[msg.sender].creator != address(0), "crycle not create");
        string memory oldTitle = crycles[msg.sender].title;
        crycles[msg.sender].title = title;
        emit NewTitle(msg.sender, oldTitle, title, block.timestamp);
    }

    function setMainfest(string memory mainfest) external {
        require(bytes(mainfest).length <= 1024, "mainfest too long");
        require(crycles[msg.sender].creator != address(0), "crycle not create");
        string memory oldMainfest = crycles[msg.sender].mainfest;
        crycles[msg.sender].mainfest = mainfest;
        emit NewMainfest(msg.sender, oldMainfest, mainfest, block.timestamp);
    }

    function setTelegram(string memory telegram) external {
        require(bytes(telegram).length <= 256, "mainfest too long");
        require(crycles[msg.sender].creator != address(0), "crycle not create");
        string memory oldTelegram = crycles[msg.sender].telegram;
        crycles[msg.sender].telegram = telegram;
        emit NewTelegram(msg.sender, oldTelegram, telegram, block.timestamp);
    }

    function addCrycle(address creator) external {
        require(msg.sender != creator, "can not add yourself");
        require(user.userExists(msg.sender), "user not registe");
        require(crycles[creator].creator != address(0), "crycle not exists");
        require(userCrycle[msg.sender] == address(0), "already joined crycle");
        userCrycle[msg.sender] = creator;
        crycles[creator].userNum = crycles[creator].userNum + 1;
        emit NewUser(msg.sender, creator, crycles[creator].userNum, block.timestamp);
    }

    struct VoteInfo {
        uint beginAt;
        uint countAt;
        uint finishAt;
        uint reward;
    }
    
    VoteInfo[] public voteInfo;

    function getVoteId() external view returns (uint) {
        return voteInfo.length;
    }

    function startVote(uint256 beginAt, uint256 countAt, uint256 finishAt) external onlyOwner {
        if (voteInfo.length > 0) { //check if last vote finish
            require(block.timestamp > voteInfo[voteInfo.length - 1].finishAt, "last vote not finish");
        }

        voteInfo.push(VoteInfo({
            beginAt: beginAt,
            countAt: countAt,
            finishAt: finishAt,
            reward: sds.balanceOf(address(this))
        }));
        uint _currentVoteId = voteInfo.length;
        masterChef.createSnapshot(_currentVoteId);
        sds.createSnapshot(_currentVoteId);
        for (uint i = 0; i < pairs.length; i ++) {
            factory.createSnapshot(address(pairs[i]), _currentVoteId);
        }
        emit NewVoteInfo(_currentVoteId, beginAt, countAt, finishAt, sds.balanceOf(address(this)));
    }

    function voteNum(address _user) public view returns (uint256) {
        uint totalVotes = sds.getUserSnapshot(_user);
        for (uint i = 0; i < pairs.length; i ++) {
            (uint price0, uint price1) = factory.getSnapshotPrice(pairs[i]);
            uint price = address(sds) == pairs[i].token0() ? price0 : price1;
            uint pairVotes = factory.getSnapshotBalance(pairs[i], msg.sender);
            uint lockVotes = masterChef.getUserSnapshot(pairs[i], msg.sender);
            totalVotes = totalVotes.add(price.mul(pairVotes.div(1e18))).add(price.mul(lockVotes).div(1e18)).div(1e16);
        }
        return totalVotes;
    }

    function doVote(uint num) external {
        uint voteId = voteInfo.length;
        require(voteId > 0, "vote not begin");
        VoteInfo memory _voteInfo = voteInfo[voteInfo.length - 1];
        require(block.timestamp >= _voteInfo.beginAt && block.timestamp < _voteInfo.countAt, "not the right time");
        require(userCrycle[msg.sender] != address(0), "illegal user vote");
        userVote[voteId][msg.sender] = userVote[voteId][msg.sender].add(num);
        crycleVote[voteId][userCrycle[msg.sender]] = crycleVote[voteId][userCrycle[msg.sender]].add(num);
        require(userVote[voteId][msg.sender] <= voteNum(msg.sender), "illegal vote num");
        emit NewVote(voteId, msg.sender, userCrycle[msg.sender], num, userVote[voteId][msg.sender], crycleVote[voteId][userCrycle[msg.sender]]);
    }

    function doCount(address[] memory _crycles) external onlyOwner {
        uint voteId = voteInfo.length;
        if (voteId == 0) {
            return;
        }
        VoteInfo memory _voteInfo = voteInfo[voteId - 1];
        if (block.timestamp < _voteInfo.countAt && block.timestamp >= _voteInfo.finishAt) {
            return;
        }
        voteWiners[voteId] = _crycles;
        if (_crycles.length == 0) {
            return;
        }
        for (uint i = 0; i < _crycles.length; i ++) {
            voteReward[voteId][_crycles[i]] = _voteInfo.reward.div(_crycles.length); 
        }
    }

    function claim(uint _voteId, address _user) external {
        if (voteReward[_voteId][_user] > 0) {
            sds.transfer(_user, voteReward[_voteId][_user]);
        }
        voteReward[_voteId][_user] = 0;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import './IKeplerPair.sol';

interface IKeplerFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function expectPairFor(address token0, address token1) external view returns (address);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external pure returns (bytes32);

    function getTransferFee(address[] memory tokens) external view returns (uint[] memory);

    function _beforeTokenTransfer(address token0, address token1, address from, address to, uint256 amount) external;

    function createSnapshot(address pair, uint256 id) external;

    function getUserSnapshot(IKeplerPair pair, address user) external view returns (uint256);

    function getSnapshotPrice(IKeplerPair pair) external view returns(uint price0, uint price1);

    function getSnapshotBalance(IKeplerPair pair, address user) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

interface IKeplerPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import './IKeplerPair.sol';

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IKeplerToken is IERC20 {

    function createSnapshot(uint256 id) external;

    function getUserSnapshot(address user) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IKeplerPair.sol';

interface IMasterChef {

    function getUserAmount(IKeplerPair pair, address user, uint lockType) external view returns (uint);

    function getInviterAmount(IKeplerPair pair, address inviter) external view returns (uint);

    function createSnapshot(uint256 id) external;

    function getUserSnapshot(IKeplerPair pair, address _user) external view returns (uint256);

    function doMiner(IKeplerPair pair, IERC20 token, uint256 amount) external;

    function deposit(IKeplerPair _pair, uint256 _amount, uint256 _lockType) external;

    function depositFor(IKeplerPair _pair, uint256 _amount, uint256 _lockType, address to) external;

    function getPoolInfo(IKeplerPair _pair) external view returns (uint256 totalShares, uint256 token0AccPerShare, uint256 token1AccPerShare);

    function getUserInfo(IKeplerPair _pair, address _user) external view returns (uint256 amount, uint256 shares, uint256 token0Debt, uint256 token1Debt, uint256 token0Pending, uint256 token1Pending);

    function getInvitePoolInfo(IKeplerPair _pair) external view returns (uint256 totalShares, uint256 token0AccPerShare, uint256 token1AccPerShare);

    function getInviteUserInfo(IKeplerPair _pair, address _user) external view returns (uint256 amount, uint256 shares, uint256 token0Debt, uint256 token1Debt, uint256 token0Pending, uint256 token1Pending);

    function doInviteMiner(IKeplerPair pair, IERC20 token, uint256 amount) external;

    function userLockNum(IKeplerPair _pair, address user) external view returns (uint256);

    function userLockInfo(IKeplerPair _pair, address _user, uint256 id) external view returns (uint256, uint256, uint256, uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

interface IUser {

    function inviter(address user) external view returns (address);

    function inviteNume(address user) external view returns (uint256);

    function userNum() external view returns (uint256);

    function registe(address _inviter) external;

    function userExists(address user) external view returns (bool);
}