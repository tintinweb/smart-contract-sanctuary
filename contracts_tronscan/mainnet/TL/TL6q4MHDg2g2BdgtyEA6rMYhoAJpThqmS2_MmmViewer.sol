//SourceUnit: Datasets.sol

pragma solidity ^0.5.0;

library Datasets {
    enum PlayerType {
        NEW,
        NORMAL,
        MANAGER,
        DIRECTOR
    }

    enum OrderType {
        MAVRO,
        WITHDRAW,
        RACE,
        P_HELP,
        P_WHOLE,
        DEPOSIT,
        WITHDRAW_MAVRO
    }

    struct Player {
        uint64 pid;
        uint64 nid;
        uint64 laff;
        uint64 regTime;
        uint16 level;
        uint16 lrnd;
        uint64 reqCnt;
        uint64 mavro;
        uint64 mavroUsed;
        uint64 totalOrder;
        PlayerType pType;
        uint64 last;
        uint64 locked;
        uint8 wrongOrder;
    }

    struct PlayerDetail {
        bytes32 email;
        bytes32 birthday;
        bytes32 country;
        bytes32 tel;
        bytes32 skype;
        string postaddr;
    }

    struct Order {
        uint64 req;
        uint64 strt;
        address addr;
        uint64 nid;
        uint64 paid;
        uint64 payTime;
        bool isAward;
        uint64 race;
    }

    struct DLList {
        uint64 Id;
        uint256 prev;
        uint256 next;
    }

    struct ArrayList {
        uint64[] id;
        uint256 index;
    }

    struct OrderList {
        uint64 orderId;
        address playerAddr;
        uint256 prev;
        uint256 next;
    }

    struct PlayerOrder {
        address playerAddr;
        uint64 releaseTime;
        uint64 unlockTime;
        bool isLetter;
        bool isFirst;
        OrderType oType;
    }

    struct MavroToken {
        uint64 mavroSold;
        uint64 mavroUsed;
    }

    struct Ipfs {
        string title;
        string hash;
        uint64 orderId;
        uint64 strt;
    }

    struct Round {
        uint64 total;
        uint64 wait;
        uint64 waitCnt;
        uint64 topPrize;
        uint64 raceAwardNum;
        uint64 raceAwardAmount;
        uint64 strt;
        uint64 endTime;
        uint64 raceEnd;
        uint64 raceOrderId;
        uint64 unlockday;
        bool isTopPrizeEnd;
    }

    struct GlobalData {
        uint64 award;
        uint64 founder;
        uint64 donate;
        uint64 awardWithdraw;
        uint64 founderWithdraw;
        uint64 donateWithdraw;
        uint64 gas;
        uint64 gasWithdraw;
    }

    struct PlayerVault {
        uint64 gen;
        uint64 interest;
        uint64 lock;
        uint64 laff;
        uint64 maff;
        uint64 daff;
        uint64 award;
        uint64 over;
        uint64 old;
        uint64 race;
        uint64 incomplete;
        uint64 withdraw;
    }

    struct DailyInfo {
        uint64 lastDayAmount;
        uint64 released;
        uint64 withdraw;
    }

    struct Name {
        uint64 nid;
        bool isUsed;
    }

    struct Exam {
        uint256 score;
        uint64 strt;
    }

    struct AwardInfo {
        uint64 first;
        uint64 second;
        uint64 third;
        uint64 awardPool;
        bool collected;
    }

    struct OrderDLList {
        DLList[] waitPay;
    }

    struct OrderArray {
        ArrayList unrelease;
        ArrayList unreleaseNew;
        ArrayList waitUpdate;
        ArrayList race;
        ArrayList waitCalcRest;
        ArrayList waitAward;
        ArrayList raceAward;
        ArrayList withdraw;
        ArrayList pHelp;
    }

    struct PlayerOrderArray {
        ArrayList newOrder;
        ArrayList finished;
        ArrayList history;
    }

    struct Charity {
        address charityAddress;
        bytes32 name;
        uint64 moneyAmount;
        uint256 time;
    }
}

//SourceUnit: ExtraInterface.sol

pragma solidity ^0.5.0;

import "./Datasets.sol";

interface IExtra {
    function registerName(bytes32 _newName) external returns (uint64);
    function modifyName(uint64 _nameId, bytes32 _newName) external returns (uint64);
    function addList(uint8 _listType, uint64 _orderId, string calldata _title, string calldata _hash) external;
    function addLetterList(uint16 _currentRound, address _playerAddr, uint64 _orderId, string calldata _hash) external;
    function editList(uint8 _listType, uint64 _listId, string calldata _title, string calldata _hash) external;
    function deleteList(uint8 _listType, uint64 _listId) external;
    function setListTop(uint8 _listType, uint64 _listId, bool _isTop) external;
    function saveMyDream(uint64 _orderId, string calldata _dream) external;
    function setGame(address _gameAddr) external;

    function getName(uint64 _nameId) external view returns (bytes32);
    function getRandNid(uint64 _nameId) external view returns (uint64);
    function getList(uint8 _listType, uint256 _cursor, uint256 _pageSize) external view returns (uint64[] memory, uint256, uint256);
    function getListInfo(uint64 _listId) external view returns (string memory, string memory, uint64, uint64);
    function getLetterInfoXOid(uint64 _orderId) external view returns (string memory, string memory, uint64);
    function getMyDream(uint64 _orderId) external view returns (string memory);
    function getLetterList(uint16 _currentRound, address _playerAddr, uint256 _cursor, uint256 _pageSize) external view returns (uint64[] memory, uint256, uint256);
    function setViewer(address _viewerAddr) external;
    function nameIsUsed(bytes32 _name) external view returns (bool);
}

//SourceUnit: ITRC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface ITRC20 {
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

    function burn(uint256 amount) external returns (bool);

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


//SourceUnit: MMMInterface.sol

pragma solidity ^0.5.0;

interface IMMM {
    function getIndexOrder(uint64 _orderId) external view returns (uint64 _req, uint64 _strt, bytes32 _name);
    function getLastPHelp(uint256 _cursor, uint256 _pageSize) external view returns (uint64[] memory, uint256, uint256);
}

//SourceUnit: OrderInterface.sol

pragma solidity ^0.5.0;

import "./Datasets.sol";

interface IOrder {
    function newBuyMavroOrder(uint64 _moneyAmount, uint64 _now) external returns (uint64);
    function newPHelpOrder(uint64 _nameId, uint64 _moneyAmount, uint64 _now) external returns (uint64);
    function newWholeOrder(uint64 _nameId, uint64 _orderId) external returns (uint64, uint64);
    function newRaceOrder(uint64 _nameId, uint64 _moneyAmount, uint64 _now) external returns (uint64);
    function newWithdrawOrder(uint64 _nameId, address _playerAddr, uint64 _moneyAmount, uint64 _now) external returns (uint64);
    function newDepositMavroOrder(uint64 _moneyAmount, uint64 _now) external returns (uint64);

    function handleOrder(uint64 _orderId, Datasets.OrderType _oType, bool _addAward, uint64 _now) external returns (uint64, uint64);
    function handleDepositOrder(uint64 _orderId, uint64 _now) external returns (uint64);
    function saveSharingLetter(uint64 _orderId, string calldata _hash) external returns (uint64);
    function transferMavro(address _toAddr, uint64 _mavroAmount) external;
    function processWithdraw(address _playerAddr) external returns (uint64);
    function payToPlayer(uint64 _orderId) external returns (uint64);
    function dayCut(uint64 _day) external returns (uint64);
    function openAward(uint64 _orderId, Datasets.OrderType _oType) external;
    function receiveAward(uint64 _orderId, Datasets.OrderType _oType) external returns (uint64);
    function processRaceAward(uint64 _orderId, Datasets.OrderType _oType) external returns (uint64, uint16, bool);
    function consumeVault(address _playerAddr, uint64 _gen, uint64 _interest, uint64 _laff, uint64 _maff, uint64 _daff, uint64 _over, uint64 _award, uint64 _race) external returns (uint64, bool);
    function setRace() external;
    function setGame(address _gameAddr) external;

    function wholeOrder(uint64 _orderId) external view returns (uint64);
    function getOrderAmount(uint64 _orderId) external view returns (uint64, uint64);
    function getOrderInfo(uint64 _orderId) external view returns (address, uint64, uint64, uint64, uint64, bytes32);
    function getOrderStatus(uint64 _orderId) external view returns (uint64, bool, bool);
    function getInterest(uint64 _orderId, Datasets.OrderType _oType) external view returns (uint64, uint64, uint64);
    function getRoundData() external view returns(uint64, uint64, uint64, uint64, uint64, uint64, uint64, uint64, uint64, uint64);
    function getOrderAward(uint64 _orderId, Datasets.OrderType _oType) external view returns (uint32[] memory, bool);
    function getGlobalAwardData(uint64 _day) external view returns (uint32, uint64, uint64, uint64, uint64);
    function getRaceStatus(uint64 _orderId, Datasets.OrderType _oType) external view returns (bool);
    function mayWithdraw(uint64 _orderId) external view returns (bool);
    function mayToRace(uint64 _orderId, bool _raceMode, bool _isRace) external view returns (bool);
    function isRaceEnd() external view returns (bool);
    function getPlayerVault(address _playerAddr) external view returns (uint64, uint64, uint64, uint64, uint64, uint64, uint64, uint64, uint64, uint64);
    function getCharityFund() external view returns (uint64, uint64);
    function getCharityList(uint256 _index) external view returns (address, bytes32, uint64, uint256);
    function getOrderPayTime(uint64 _orderId) external view returns (uint64);
    function AIRelease() external view returns (uint64);

    function X_Order(uint64 _moneyAmount, uint64 _nameId, uint64 _strtTime, uint64 _payTime, Datasets.OrderType _oType, bool _isPaid) external returns (uint64);
}

//SourceUnit: OwnableMulti.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract OwnableMulti {
    address private _owner;
    address private _newsManager;
    address private _letterManager;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SetNewsManager(address indexed previousNewsManager, address indexed newNewsManager);
    event SetLetterManager(address indexed previousLetterManager, address indexed newLetterManager);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyNewsManager() {
        require(isNewsManager(), "Ownable: caller is not the news manager");
        _;
    }

    modifier onlyLetterManager() {
        require(isLetterManager(), "Ownable: caller is not the letter manager");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function isNewsManager() public view returns (bool) {
        return (msg.sender == _newsManager || msg.sender == _owner);
    }

    function isLetterManager() public view returns (bool) {
        return (msg.sender == _letterManager || msg.sender == _owner);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function setNewsManager(address newsManager) public onlyOwner {
        emit SetNewsManager(_newsManager, newsManager);
        _newsManager = newsManager;
    }

    function setLetterManager(address LetterManager) public onlyOwner {
        emit SetLetterManager(_letterManager, LetterManager);
        _letterManager = LetterManager;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


//SourceUnit: PlayerInterface.sol

pragma solidity ^0.5.0;

import "./Datasets.sol";

interface IPlayer {
    function initGame(address _playerAddr) external;
    function register(address _playerAddr, bytes32 _playerName, address _affAddr, uint16 _currentRound, uint64 _now) external;
    function withdrawMavro(address _playerAddr, uint64 _mavroAmount) external;
    function buyMavro(address _playerAddr, uint64 _orderAmount) external;
    function depositMavro(address _playerAddr, uint64 _mavroAmount) external;
    function processPlayerData(address _playerAddr, uint64 _orderId, uint64 _moneyAmount, Datasets.OrderType _oType, uint16 _currentRound) external returns (uint64, bool);
    function handInExam(address _playerAddr, uint64 _strt, uint8[25] calldata _answer, bool _isMigrate) external returns (uint256, bool);
    function editPlayerDetail(address _playerAddr, bytes32 _email, bytes32 _birthday, bytes32 _country, bytes32 _tel, bytes32 _skype, string calldata _postaddr) external;
    function editPlayerName(address _playerAddr, uint64 _newNameId) external;
    function doWrongOrder(address _playerAddr, uint64 _moneyAmount, bool _isReduceLock) external;
    function resetPlayerVault(address _playerAddr, uint16 _newRound) external;
    function updatePlayerVault(address _playerAddr, uint64 _orderId, uint64 _reqAmount, uint64 _interest, uint64 _paidAmount, Datasets.OrderType _oType, bool _isFirst) external;
    function consumeVault(address _playerAddr, uint64 _gen, uint64 _interest, uint64 _laff, uint64 _maff, uint64 _daff, uint64 _over, uint64 _award, uint64 _race) external returns (uint64);
    function updateDparentOrder(uint16 _currentRound, address _playerAddr, uint64 _orderId) external;
    function updateParentOrder(uint16 _currentRound, address _playerAddr, uint64 _orderId) external;
    function updateParent() external;
    function updateAffVault(address _playerAddr, uint64 _orderId, uint64 _orderAmount, uint16 _currentRound) external;
    function updatePlayerAward(address _playerAddr, uint64 _moneyAmount) external;
    function updatePlayerRace(address _playerAddr, uint64 _moneyAmount) external;
    function oldMoneyProcess(address _playerAddr, uint64 _withdrawAmount, uint16 _currentRound) external;
    function unlockPlayer(address _playerAddr) external;
    function setGame(address _gameContract) external;
    function setOrder(address _orderContract) external;

    function getPlayerVault(address _playerAddr, uint64 _residueAmount) external view returns (uint64, uint64, uint64, uint64, uint64, uint64, uint64, uint64, uint64, uint64);
    function getPlayerDChild(uint64 _playerId, uint256 _cursor, uint256 _pageSize) external view returns (uint64[] memory _playerList, uint256 _length, uint256 _newCursor);
    function getMavroInfo() external view returns (uint64, uint64, uint64);
    function getPlayerId(address _playerAddr) external view returns (uint64);
    function getPlayerNameId(address _playerAddr) external view returns (uint64);
    function getPlayerAddr(uint64 _playerId) external view returns (address);
    function getPlayerLevel(address _playerAddr) external view returns (uint64, uint16);
    function getPlayerRound(address _playerAddr) external view returns (uint16);
    function getPlayerMavro(address _playerAddr) external view returns(uint64, uint64);
    function getPlayerInfo(address _playerAddr) external view returns (uint64, uint64, uint64, uint64, uint64, uint16, uint64, bytes32, uint64, uint8, Datasets.PlayerType);
    function getPlayerByPid(uint64 _playerId) external view returns (address, uint64, uint64, uint64, uint16, uint64, bytes32, Datasets.PlayerType);
    function getPlayerDetail(address _playerAddr) external view returns (bytes32, bytes32, bytes32, bytes32, bytes32, string memory);
    function getParent(address _playerAddr) external view returns (address[] memory);
    function getPlayerRest(address _playerAddr, uint64 _orderId) external view returns (uint64);
    function isPlayer(address _playerAddr) external view returns (bool);
    function getPlayerCount() external view returns (uint256);
    function getPlayerType(address _playerAddr) external view returns (Datasets.PlayerType);
    function getExamPool(address _playerAddr) external view returns (uint8[25] memory);
    function getChildOrderList(uint16 _currentRound, address _playerAddr, uint256 _cursor, uint256 _pageSize) external view returns (uint64[] memory, uint256, uint256);
    function getDchildOrderList(uint16 _currentRound, address _playerAddr, uint256 _cursor, uint256 _pageSize) external view returns (uint64[] memory, uint256, uint256);
    function getPlayerExamAward(address _playerAddr, uint8 _level) external view returns (uint256, uint64);
    function processNewOrder(address _playerAddr, uint64 _moneyAmount, Datasets.OrderType _oType) external returns (uint64
    
    );
    function getLastPHelp(uint256 _cursor, uint256 _pageSize) external view returns (uint64[] memory, uint256, uint256);
    function hasNewPlayer() external view returns (bool);
    function playerChildCount(address _playerAddr) external view returns (uint64);
    function X_Reg(address _playerAddr, bytes32 _playerName, address _affAddr, uint64 _now) external;
    function X_NewOrder(address _playerAddr, uint64 _orderId, uint64 _moneyAmount, bool _isPaid) external returns (bool);
}

//SourceUnit: SafeMath.sol

pragma solidity ^0.5.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


//SourceUnit: TRC20.sol

pragma solidity ^0.5.0;

import "./ITRC20.sol";
import "./SafeMath.sol";

/**
 * @dev Implementation of the {ITRC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {TRC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-TRC20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of TRC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {ITRC20-approve}.
 */
contract TRC20 is ITRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {ITRC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {ITRC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {ITRC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {ITRC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {ITRC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {ITRC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {TRC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "TRC20: transfer amount exceeds allowance"));
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ITRC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ITRC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "TRC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "TRC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "TRC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "TRC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "TRC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount, "TRC20: burn amount exceeds allowance"));
    }
}


//SourceUnit: mmmViewer.sol

pragma solidity ^0.5.0;

import "./ExtraInterface.sol";
import "./PlayerInterface.sol";
import "./OrderInterface.sol";
import "./MMMInterface.sol";
import "./TRC20.sol";
import "./Datasets.sol";
import "./OwnableMulti.sol";

contract MmmViewer is OwnableMulti {

    address moneyContract;
    address orderContract;
    address playerContract;
    address founderContract;
    address extraContract;
    address mmmContract;

    constructor(address _money, address _player, address _order, address _extra, address _mmm)
    public
    {
        moneyContract = _money;
        playerContract = _player;
        orderContract = _order;
        extraContract = _extra;
        mmmContract = _mmm;
        IExtra(extraContract).setViewer(address(this));
    }

    function getCharityList(uint256 _index)
    external
    view
    returns (address _charityAddress, bytes32 _name, uint64 _moneyAmount, uint256 _time)
    {
        return (IOrder(orderContract).getCharityList(_index));
    }

    function getPlayerExamAward(address _playerAddr, uint8 _level)
    external
    view
    returns (uint256 _score, uint64 _strt)
    {
        return IPlayer(playerContract).getPlayerExamAward(_playerAddr, _level);
    }

    function getMyDream(uint64 _orderId)
    external
    view
    returns (string memory _dream)
    {
        return (IExtra(extraContract).getMyDream(_orderId));
    }

    function getWholeOrder(uint64 _orderId)
    external
    view
    returns (uint64 _fullOrderId)
    {
        _fullOrderId = IOrder(orderContract).wholeOrder(_orderId);
    }

    function getOrderRest(address _playerAddr, uint64 _orderId)
    external
    view
    returns (uint64 _restAmount)
    {
        return (IPlayer(playerContract).getPlayerRest(_playerAddr, _orderId));
    }

    function getMavroInfo()
    external
    view
    returns (uint64 _mavroSold, uint64 _mavroDestroyed, uint64 _mavroPrice)
    {
        return (IPlayer(playerContract).getMavroInfo());
    }

    function getExamTopic()
    external
    view
    returns (uint8[25] memory)
    {
        address _playerAddr = msg.sender;
        return (IPlayer(playerContract).getExamPool(_playerAddr));
    }

    function getPlayerChildCount(address _playerAddr)
    external
    view
    returns (uint64)
    {
        return (IPlayer(playerContract).playerChildCount(_playerAddr));
    }

    function getRoundData()
    external
    view
    returns
    (
        uint64 _total,
        uint64 _topPrize,
        uint64 _principal,
        uint64 _award,
        uint64 _wait,
        uint64 _waitCnt,
        uint64 _raceOrderId,
        uint64 _strt,
        uint64 _endTime,
        uint64 _raceEnd
    )
    {
        return (IOrder(orderContract).getRoundData());
    }

    function getPlayerInfo(address _playerAddr)
    external
    view
    returns
    (
        uint64 _pid,
        uint64 _locked,
        uint64 _laff,
        uint64 _last,
        uint64 _reqCnt,
        uint16 _level,
        uint64 _regTime,
        bytes32 _name,
        uint64 _totalOrder,
        uint8 _wrongOrder,
        Datasets.PlayerType _pType
    )
    {
        return (IPlayer(playerContract).getPlayerInfo(_playerAddr));
    }

    function getPlayerByPid(uint64 _playerId)
    external
    view
    returns
    (
        address _addr,
        uint64 _laff,
        uint64 _last,
        uint64 _reqCnt,
        uint16 _level,
        uint64 _regTime,
        bytes32 _name,
        Datasets.PlayerType _pType
    )
    {
        return (IPlayer(playerContract).getPlayerByPid(_playerId));
    }

    function getPlayerDetail(address _playerAddr)
    external
    view
    returns
    (
        bytes32 _email,
        bytes32 _birthday,
        bytes32 _country,
        bytes32 _tel,
        bytes32 _skype,
        string memory _postaddr
    )
    {
        return (IPlayer(playerContract).getPlayerDetail(_playerAddr));
    }

    function getCharityFund()
    external
    view
    returns (uint64 _charityFund, uint64 _withdrawn)
    {
        return (IOrder(orderContract).getCharityFund());
    }

    function getPlayerVault(address _playerAddr)
    external
    view
    returns
    (
        uint64 _gen,
        uint64 _interest,
        uint64 _lock,
        uint64 _laff,
        uint64 _maff,
        uint64 _daff,
        uint64 _over,
        uint64 _award,
        uint64 _old,
        uint64 _race
    )
    {
        return (IOrder(orderContract).getPlayerVault(_playerAddr));
    }

    function getPlayerMavro(address _playerAddr)
    external
    view
    returns (uint64 _mavro, uint64 _mavroUsed)
    {
        return (IPlayer(playerContract).getPlayerMavro(_playerAddr));
    }

    function getPlayerDChild(uint64 _playerId, uint256 _cursor, uint256 _pageSize)
    external
    view
    returns (uint64[] memory _playerList, uint256 _length, uint256 _newCursor)
    {
        return (IPlayer(playerContract).getPlayerDChild(_playerId, _cursor, _pageSize));
    }

    function getTotalPlayers()
    external
    view
    returns (uint256)
    {
        return (IPlayer(playerContract).getPlayerCount());
    }

    function getOrderInfo(uint64 _orderId)
    external
    view
    returns (uint64 _req, uint64 _strt, bytes32 _name)
    {
        (_req, _strt, _name) = IMMM(mmmContract).getIndexOrder(_orderId);
    }

    function getLastPHelp(uint256 _cursor, uint256 _pageSize)
    external
    view
    returns(uint64[] memory _orderList, uint256 _length, uint256 _newCursor)
    {
        return (IMMM(mmmContract).getLastPHelp(_cursor, _pageSize));
    }

    function getExtraList(uint8 _listType, uint256 _cursor, uint256 _pageSize)
    external
    view
    returns (uint64[] memory _orderList, uint256 _length, uint256 _newCursor)
    {
        return (IExtra(extraContract).getList(_listType, _cursor, _pageSize));
    }

    function getExtraInfo(uint64 _Id)
    external
    view
    returns (string memory _title, string memory _hash, uint64 _strt, uint64 _orderId)
    {
        return (IExtra(extraContract).getListInfo(_Id));
    }

    function getLetterInfoXOid(uint64 _orderId)
    external
    view
    returns (string memory _title, string memory _hash, uint64 _strt)
    {
        return (IExtra(extraContract).getLetterInfoXOid(_orderId));
    }

    function getMMMBalance()
    external
    view
    returns (uint256)
    {
        return (TRC20(moneyContract).balanceOf(mmmContract));
    }

    function checkBalance(address _mainContract, address _contractAddr)
    external
    view
    returns (uint256)
    {
        return TRC20(_mainContract).balanceOf(_contractAddr);
    }

    function nameIsUsed(bytes32 _name)
    external
    view
    returns (bool)
    {
        return (IExtra(extraContract).nameIsUsed(_name));
    }

    function addIpfsList(uint8 _listType, string calldata _title, string calldata _hash)
    external
    onlyNewsManager
    {
        IExtra(extraContract).addList(_listType, 0, _title, _hash);
    }

    function editIpfsList(uint8 _listType, uint64 _listId, string calldata _title, string calldata _hash)
    external
    onlyNewsManager
    {
        IExtra(extraContract).editList(_listType, _listId, _title, _hash);
    }

    function deleteExtraList(uint8 _listType, uint64 _id)
    external
    onlyNewsManager
    {
        IExtra(extraContract).deleteList(_listType, _id);
    }

    function setExtraListTop(uint8 _listType, uint64 _listId, bool _isTop)
    external
    onlyNewsManager
    {
        require(_listType != 2 && _listType != 3, 'MMMDapp: LIST_TYPE_ERROR');
        IExtra(extraContract).setListTop(_listType, _listId, _isTop);
    }

    function setLetterTop(uint8 _listType, uint64 _listId, bool _isTop)
    external
    onlyLetterManager
    {
        require(_listType == 2 || _listType == 3, 'MMMDapp: LIST_TYPE_ERROR');
        IExtra(extraContract).setListTop(_listType, _listId, _isTop);
    }
}