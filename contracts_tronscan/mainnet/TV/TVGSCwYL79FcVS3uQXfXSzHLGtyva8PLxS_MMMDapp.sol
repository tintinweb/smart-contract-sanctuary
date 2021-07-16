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

//SourceUnit: Ownable.sol

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
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
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

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


//SourceUnit: Pagination.sol

pragma solidity ^0.5.0;

import "./Datasets.sol";

library Pagination {

    function insert(Datasets.DLList[] storage _dlList, uint64 _id)
    internal
    returns (uint256 _newNodeId)
    {
        if (0 == _dlList.length) _dlList.push(Datasets.DLList(0, 0, 0));
        Datasets.DLList storage _zeroNode = _dlList[0];
        _newNodeId = _dlList.push(Datasets.DLList(_id, 0, _zeroNode.next)) - 1;
        _dlList[_zeroNode.next].prev = _newNodeId;
        _zeroNode.next = _newNodeId;
    }

    function insertLast(Datasets.DLList[] storage _dlList, uint64 _id)
    internal
    returns (uint256 _newNodeId)
    {
        if (0 == _dlList.length) _dlList.push(Datasets.DLList(0, 0, 0));
        _newNodeId = _dlList.push(Datasets.DLList(_id, _dlList[0].next, 0)) - 1;
        _dlList[0].prev = _newNodeId;
        _dlList[_dlList[0].prev].next = _newNodeId;
    }

    function remove(Datasets.DLList[] storage _dlList, uint256 _index)
    internal
    {
        if (_index != 0 && (_index == _dlList[0].next || _dlList[_index].prev != 0)) {
            Datasets.DLList storage _node = _dlList[_index];
            _dlList[_node.next].prev = _node.prev;
            _dlList[_node.prev].next = _node.next;
            delete _dlList[_index];
        }
    }

    function getOne(Datasets.DLList[] storage _dlList)
    internal
    view
    returns(uint64 _id, uint256 _index)
    {
        if (_dlList.length > 0) {
            uint256 _currentIndex = _dlList[0].prev;
            if (!(_currentIndex != 0 && (_currentIndex == _dlList[0].next || _dlList[_currentIndex].prev != 0))) return (0, 0);
            return (_dlList[_currentIndex].Id, _currentIndex);
        }
    }

    function getFirstOne(Datasets.DLList[] storage _dlList)
    internal
    view
    returns(uint64 _id, uint256 _index)
    {
        if (_dlList.length > 0) {
            uint256 _currentIndex = _dlList[0].next;
            if (!(_currentIndex != 0 && (_currentIndex == _dlList[0].next || _dlList[_currentIndex].prev != 0))) return (0, 0);
            return (_dlList[_currentIndex].Id, _currentIndex);
        }
    }

    function fetchPage(Datasets.DLList[] storage _dlList, uint256 _cursor, uint256 _pageSize)
    internal
    view
    returns (uint64[] memory _list, uint256 _length, uint256 _newCursor)
    {
        if (0 == _dlList.length) return (new uint64[](0), 0, 0);
        require(_cursor == 0 || (_cursor != 0 && (_cursor == _dlList[0].next || _dlList[_cursor].prev != 0)), 'MMMDapp: INVALID_NODE');
        uint256 _currentIndex = 0 == _cursor ? _dlList[0].next : _cursor;
        uint256 _howMany = 0 == _pageSize ? _dlList.length - 1 : _pageSize;
        _list = new uint64[](_howMany);
        uint256 i = 0;
        while (i < _howMany && _currentIndex != 0) {
            Datasets.DLList memory _node = _dlList[_currentIndex];
            _list[i] = _node.Id;
            _currentIndex = _node.next;
            i += 1;
        }
        _length = i;
        _newCursor = _currentIndex;
        return (_list, _length, _newCursor);
    }
}


//SourceUnit: PaginationArray.sol

pragma solidity ^0.5.0;

import "./Datasets.sol";

library PaginationArray {
    
    function insert(Datasets.ArrayList storage _arrList, uint64 _id)
    internal
    returns (uint256)
    {
        return (_arrList.id.push(_id) - 1);
    }

    function insertFirst(Datasets.ArrayList storage _arrList, uint64 _id)
    internal
    returns (uint256)
    {
        if (_arrList.index > 0) {
            _arrList.index = _arrList.index - 1;
            _arrList.id[_arrList.index] = _id;
            return (_arrList.index);
        } 
        return (_arrList.id.push(_id) - 1);
    }
    
    function getOne(Datasets.ArrayList storage _arrList)
    internal
    view
    returns (uint64 _id, uint256 _index)
    {   
        if (_arrList.id.length > _arrList.index) return (_arrList.id[_arrList.index], _arrList.index);
    }

    function getFirstOne(Datasets.ArrayList storage _arrList)
    internal
    view
    returns (uint64 _id, uint256 _index)
    {
        if (_arrList.id.length != 0 && _arrList.index < _arrList.id.length) return (_arrList.id[_arrList.id.length - 1], _arrList.id.length - 1);
    }
    
    function remove(Datasets.ArrayList storage _arrList, uint256 _index)
    internal
    {
        if (_index == _arrList.index && _index < _arrList.id.length) {
            _arrList.index = _arrList.index + 1;
        }
    }

    function removeFirst(Datasets.ArrayList storage _arrList, uint256 _index)
    internal
    {
        if (_index == _arrList.id.length - 1 && _arrList.index < _arrList.id.length) {
            delete _arrList.id[_index];
            _arrList.id.length = _arrList.id.length - 1;
        }
    }

    function exchangeRemove(Datasets.ArrayList storage _arrList, uint256 _index)
    internal
    returns (uint64)
    {
        if (_arrList.id.length > 0) {
            uint64 _lastNode = _arrList.id[_arrList.id.length - 1];
            if (_index < _arrList.id.length) _arrList.id[_index] = _lastNode;
            delete _arrList.id[_arrList.id.length - 1];
            _arrList.id.length = _arrList.id.length - 1;
            return (_lastNode);
        }
    }

    function length(Datasets.ArrayList storage _arrList)
    internal
    view
    returns (uint256)
    {
        if (_arrList.index < _arrList.id.length) return (_arrList.id.length - _arrList.index);
    }
    
    function fetchPage(Datasets.ArrayList storage _arrList, uint256 _cursor, uint256 _pageSize)
    internal
    view
    returns (uint64[] memory _list, uint256 _length, uint256 _newCursor)
    {
        uint256 _howMany = 0 == _pageSize ? _arrList.id.length : _pageSize;
        uint256 _currentIndex = 0 == _cursor ? _arrList.id.length : _cursor;
        if(0 == _arrList.id.length - _arrList.index || _currentIndex > _arrList.id.length || _currentIndex < _arrList.index) return (new uint64[](_howMany), 0, 0);
        _list = new uint64[](_howMany);
        uint256 i;
        while(i < _howMany && _currentIndex != _arrList.index) {
            _list[i] = _arrList.id[_currentIndex - 1];
            _currentIndex = _currentIndex - 1;
            i ++;
        }
        _length = i;
        _newCursor = _currentIndex == _arrList.index ? 0 : _currentIndex;
    }
    
    function fetchFirstPage(Datasets.ArrayList storage _arrList, uint256 _cursor, uint256 _pageSize)
    internal
    view
    returns (uint64[] memory _list, uint256 _length, uint256 _newCursor)
    {
        uint256 _howMany = 0 == _pageSize ? _arrList.id.length : _pageSize;
        if(0 == _arrList.id.length - _arrList.index || _cursor > _arrList.id.length) return (new uint64[](_howMany), 0, 0);
        uint256 _currentIndex = 0 == _cursor ? _arrList.index : _cursor;
        _list = new uint64[](_howMany);
        uint256 i;
        while(i < _howMany && _currentIndex != _arrList.id.length) {
            _list[i] = _arrList.id[_currentIndex];
            _currentIndex = _currentIndex + 1;
            i ++;
        }
        _length = i;
        _newCursor = _currentIndex == _arrList.id.length ? 0 : _currentIndex;
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

//SourceUnit: SafeMath64.sol

pragma solidity ^0.5.0;

library SafeMath64 {

    function add(uint64 a, uint64 b)
    internal
    pure
    returns (uint64)
    {
        uint64 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint64 a, uint64 b)
    internal
    pure
    returns (uint64)
    {
        require(b <= a, "SafeMath: subtraction overflow");
        uint64 c = a - b;
        return c;
    }

    function mul(uint64 a, uint64 b)
    internal
    pure
    returns (uint64)
    {
        if (a == 0) {
            return 0;
        }

        uint64 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    // function div(uint64 a, uint64 b)
    // internal
    // pure
    // returns (uint64)
    // {
    //     require(b > 0, "SafeMath: division by zero");
    //     uint64 c = a / b;
    //     return c;
    // }

    // function mod(uint64 a, uint64 b)
    // internal
    // pure
    // returns (uint64)
    // {
    //     require(b != 0, "SafeMath: modulo by zero");
    //     return a % b;
    // }

    // function max(uint64 a, uint64 b)
    // internal
    // pure
    // returns (uint64)
    // {
    //     return a >= b ? a : b;
    // }

    // function min(uint64 a, uint64 b)
    // internal
    // pure
    // returns (uint64)
    // {
    //     return a < b ? a : b;
    // }

    // function average(uint64 a, uint64 b)
    // internal
    // pure
    // returns (uint64)
    // {
    //     return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    // }
}


//SourceUnit: TRC20.sol

pragma solidity ^0.5.0;

interface TRC20 {
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function burn(uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
}


//SourceUnit: mmmDapp.sol

pragma solidity ^0.5.0;

import "./ExtraInterface.sol";
import "./PlayerInterface.sol";
import "./OrderInterface.sol";
import "./TRC20.sol";

import "./Datasets.sol";
import "./SafeMath64.sol";
import "./Ownable.sol";
import "./Pagination.sol";
import "./PaginationArray.sol";

contract MMMDapp is Ownable {
    // using library
    using SafeMath64 for uint64;
    using Pagination for Datasets.DLList[];
    using PaginationArray for Datasets.ArrayList;
    // constant
    string constant public name = "Mavrodi Mondial Moneybox";
    string constant public symbol = "MMM";
    uint64 constant public TIME_ZONE = 3 hours;
    uint64 constant moneyDecimals = 10 ** 6;
    uint64 constant mavroDecimals = 10 ** 6;
    // public variable
    uint16 public currentRound = 1;
    //uint16 public releaseRatio;
    uint64 public today;
    bool public isRace;
    bool public migrated;
    // private variable
    bool raceMode;
    uint64 createTime;
    uint64 currUnlockedDay;
    // interface address
    address public moneyContract;
    address public mavroContract;
    address orderContract;
    address playerContract;
    address extraContract;
    // mapping
    mapping(uint64 => uint64) public raceAward;
    mapping(address => uint16) public playerRound;
    mapping(address => uint64) waitPayOrder;
    mapping(uint16 => Datasets.OrderArray) globalOrderArray;
    mapping(uint16 => mapping(address => Datasets.PlayerOrderArray)) playerOrderArray;
    mapping(uint16 => Datasets.OrderDLList) globalOrderList;
    mapping(uint16 => mapping(uint64 => Datasets.ArrayList)) lockedOrderArray;
    mapping(uint64 => mapping(uint8 => uint256)) orderIndex;
    mapping(uint64 => Datasets.PlayerOrder) orderInfo;
    mapping(uint64 => Datasets.DailyInfo) dailyInfo;
    // event
    event Register(address _playerAddr, address _affAddr, uint64 _moneyAmount);
    event BuyMCT(address _playerAddr, uint64 _moneyAmount);
    event PlaceNewOrder(address _playerAddr, uint64 _moneyAmount, Datasets.OrderType _oType);
    event HandleOrder(address _playerAddr, uint64 _orderId, uint64 _moneyAmount, Datasets.OrderType _oType);
    event PayWithdraw(address _palyerAddr, uint64 _orderId, uint64 _withdrawAmount);
    event SharingLetter(address _playerAddr, uint64 _orderId);
    event HandInExam(address _playerAddr, uint256 _score, bool _isPass);
    event ReceiveAward(address _playerAddr, uint64 _orderId, uint64 _awardAmount);
    event ReleaseOrder(uint64 _orderId, uint64 _moneyAmount);
    event UnlockOrder(uint64 _orderId, uint64 _orderAmount, Datasets.OrderType _oType);
    event RaceAward(uint64 _orderId, uint64 _AwardAmount);
    event WrongOrder(uint64 _orderId, uint64 _orderAmount, bool _hasLoss);
    event SetRaceMode(address _owner, uint16 _round, bool _isAutoStart);
    event StartRace(uint16 _round);
    event Restart(uint16 _previousRound, uint16 _newRound);

    constructor(address _money, address _mavro, address _player, address _order, address _extra)
    public
    {
        moneyContract = _money;
        mavroContract = _mavro;
        playerContract = _player;
        orderContract = _order;
        extraContract = _extra;

        IOrder(orderContract).setGame(address(this));
        IPlayer(playerContract).setGame(address(this));
        IExtra(extraContract).setGame(address(this));
        TRC20(moneyContract).approve(orderContract, 2 ** 256 - 1);
        createTime = uint64(now);
        _dayCut();
    }

    function startNewRound()
    external
    onlyPlayer
    {
        address _playerAddr = msg.sender;
        if (playerRound[_playerAddr] < currentRound) {
            uint64 _withdraw = IOrder(orderContract).processWithdraw(_playerAddr);
            playerRound[_playerAddr] = currentRound;
            IPlayer(playerContract).oldMoneyProcess(_playerAddr, _withdraw, currentRound);
        }
    }

    function buyMavroXAddr(uint64 _moneyAmount, bytes32 _playerName, address _affAddr)
    external
    onlyAddress
    returns (uint64 _orderId)
    {
        address _playerAddr = msg.sender;
        require (_moneyAmount <= moneyDecimals.mul(10000) && _multiple(_moneyAmount, moneyDecimals, 1), 'MMMDapp: AMOUNT_ERROR');
        IPlayer(playerContract).register(_playerAddr, _playerName, _affAddr, currentRound, uint64(now));
        playerRound[_playerAddr] = currentRound;
        _orderId = IOrder(orderContract).newBuyMavroOrder(_moneyAmount, uint64(now));
        _setNewOrder(_playerAddr, _orderId, Datasets.OrderType.MAVRO);
        _setwaitPayOrder(_playerAddr, _orderId, true);
        emit Register(_playerAddr, _affAddr, _moneyAmount);
    }

    function buyMavro(uint64 _moneyAmount)
    external
    onlyFormalPlayer
    returns (uint64 _orderId)
    {
        address _playerAddr = msg.sender;
        require (_moneyAmount <= moneyDecimals.mul(10000) && _multiple(_moneyAmount, moneyDecimals, 1), 'MMMDapp: AMOUNT_ERROR');
        require (waitPayOrder[_playerAddr] == 0, 'MMMDapp: PLEASE_PAY_OTHER_ORDER');
        _orderId = IOrder(orderContract).newBuyMavroOrder(_moneyAmount, uint64(now));
        _setNewOrder(_playerAddr, _orderId, Datasets.OrderType.MAVRO);
        _setwaitPayOrder(_playerAddr, _orderId, true);
        emit BuyMCT(_playerAddr, _moneyAmount);
    }

    function provideHelp(uint64 _moneyAmount)
    external
    onlyFormalPlayer
    RaceMode(false)
    returns (uint64 _orderId)
    {
        address _playerAddr = msg.sender;
        uint64 _nameId = IPlayer(playerContract).processNewOrder(_playerAddr, _moneyAmount, Datasets.OrderType.P_HELP);
        _orderId = IOrder(orderContract).newPHelpOrder(_nameId, _moneyAmount, uint64(now));
        _setNewOrder(_playerAddr, _orderId, Datasets.OrderType.P_HELP);
        _setwaitPayOrder(_playerAddr, _orderId, true);
        globalOrderArray[currentRound].pHelp.insert(_orderId);
        IPlayer(playerContract).updateDparentOrder(currentRound, _playerAddr, _orderId);
        emit PlaceNewOrder(_playerAddr, _moneyAmount, Datasets.OrderType.P_HELP);
    }

    function PHelpImmediately(uint64 _moneyAmount)
    external
    onlyFormalPlayer
    RaceMode(true)
    returns (uint64 _orderId)
    {
        address _playerAddr = msg.sender;
        uint64 _nameId = IPlayer(playerContract).processNewOrder(_playerAddr, _moneyAmount, Datasets.OrderType.RACE);
        _orderId = IOrder(orderContract).newRaceOrder(_nameId, _moneyAmount, uint64(now));
        _setNewOrder(_playerAddr, _orderId, Datasets.OrderType.RACE);
        _setwaitPayOrder(_playerAddr, _orderId, true);
        IPlayer(playerContract).updateDparentOrder(currentRound, _playerAddr, _orderId);
        emit PlaceNewOrder(_playerAddr, _moneyAmount, Datasets.OrderType.RACE);
    }

    function withdraw(uint64 _gen, uint64 _interest, uint64 _laff, uint64 _maff, uint64 _daff, uint64 _over, uint64 _award, uint64 _race)
    external
    onlyFormalPlayer
    {
        address _playerAddr = msg.sender;
        uint64 _moneyAmount = _gen.add(_interest).add(_laff).add(_maff);
        _moneyAmount = _moneyAmount.add(_daff).add(_over).add(_award).add(_race);
        require (_multiple(_moneyAmount, moneyDecimals, 10), 'MMMDapp: AMOUNT_ERROR');
        (uint64 _nameId, bool _isFirst) = IOrder(orderContract).consumeVault(_playerAddr, _gen, _interest, _laff, _maff, _daff, _over, _award, _race);
        uint64 _orderId = IOrder(orderContract).newWithdrawOrder(_nameId, _playerAddr, _moneyAmount, uint64(now));
        _setNewOrder(_playerAddr, _orderId, Datasets.OrderType.WITHDRAW);
        _isFirst ? globalOrderArray[currentRound].withdraw.insertFirst(_orderId) : globalOrderArray[currentRound].withdraw.insert(_orderId);
        emit PlaceNewOrder(_playerAddr, _moneyAmount, Datasets.OrderType.WITHDRAW);
    }

    function depositMavro(uint64 _mavroAmount)
    external
    onlyFormalPlayer
    returns (uint64 _orderId)
    {
        address _playerAddr = msg.sender;
        require (_mavroAmount <= mavroDecimals.mul(1000000) && _multiple(_mavroAmount, mavroDecimals, 1), 'MMMDapp: MAVRO_AMOUNT_ERROR');
        require (waitPayOrder[_playerAddr] == 0, 'MMMDapp: PLEASE_PAY_OTHER_ORDER');
        _orderId = IOrder(orderContract).newDepositMavroOrder(_mavroAmount, uint64(now));
        _setNewOrder(_playerAddr, _orderId, Datasets.OrderType.DEPOSIT);
        _setwaitPayOrder(_playerAddr, _orderId, true);
        emit PlaceNewOrder(_playerAddr, _mavroAmount, Datasets.OrderType.DEPOSIT);
    }

    function withdrawMavro(address _toAddr, uint64 _mavroAmount)
    external
    onlyFormalPlayer
    {
        address _playerAddr = msg.sender;
        require (_mavroAmount <= mavroDecimals.mul(1000000) && _multiple(_mavroAmount, mavroDecimals, 1), 'MMMDapp: MAVRO_AMOUNT_ERROR');
        IPlayer(playerContract).withdrawMavro(_playerAddr, _mavroAmount);
        IOrder(orderContract).transferMavro(_toAddr, _mavroAmount);
        emit PlaceNewOrder(_playerAddr, _mavroAmount, Datasets.OrderType.WITHDRAW_MAVRO);
    }

    function handleMavroOrder(uint64 _orderId)
    external
    onlyFormalPlayer
    {
        require (0 != orderIndex[_orderId][1], 'MMMDapp: ORDER_STATUS_ERROR');
        Datasets.PlayerOrder storage _orderInfo = orderInfo[_orderId];
        address _playerAddr = _orderInfo.playerAddr;
        require (Datasets.OrderType.MAVRO == _orderInfo.oType, 'MMMDapp: ORDER_TYPE_ERROR');
        (, uint64 _paidAmount) = IOrder(orderContract).handleOrder(_orderId, _orderInfo.oType, false, uint64(now));
        IPlayer(playerContract).buyMavro(_playerAddr, _paidAmount);
        _setwaitPayOrder(_playerAddr, _orderId, false);
        _moveToFinished(_playerAddr, _orderId);
        emit HandleOrder(_playerAddr, _orderId, _paidAmount, _orderInfo.oType);
    }

    function handlePHelpOrder(uint64 _orderId)
    external
    onlyFormalPlayer
    {
        require (0 != orderIndex[_orderId][1], 'MMMDapp: ORDER_STATUS_ERROR');
        Datasets.PlayerOrder storage _orderInfo = orderInfo[_orderId];
        address _playerAddr = _orderInfo.playerAddr;
        require (Datasets.OrderType.P_HELP == _orderInfo.oType, 'MMMDapp: ORDER_TYPE_ERROR');
        (uint64 _reqAmount,) = IOrder(orderContract).handleOrder(_orderId, _orderInfo.oType, true, uint64(now));
        (, bool _isFirst) = IPlayer(playerContract).processPlayerData(_playerAddr, _orderId, _reqAmount, _orderInfo.oType, currentRound);
        if (_isFirst) {
            globalOrderArray[currentRound].unreleaseNew.insert(_orderId);
            _orderInfo.isFirst = true;
        } else {
            globalOrderArray[currentRound].unrelease.insert(_orderId);
        }
        globalOrderArray[currentRound].waitUpdate.insert(_orderId);
        _setwaitPayOrder(_playerAddr, _orderId, false);
        emit HandleOrder(_playerAddr, _orderId, _reqAmount, _orderInfo.oType);
    }

    function handlePWholeOrder(uint64 _orderId)
    external
    onlyFormalPlayer
    {
        require (0 != orderIndex[_orderId][1], 'MMMDapp: ORDER_STATUS_ERROR');
        Datasets.PlayerOrder storage _orderInfo = orderInfo[_orderId];
        address _playerAddr = _orderInfo.playerAddr;
        uint64 _now = uint64(now);
        require (Datasets.OrderType.P_HELP == _orderInfo.oType, 'MMMDapp: ORDER_TYPE_ERROR');
        (uint64 _reqAmount,) = IOrder(orderContract).handleOrder(_orderId, Datasets.OrderType.P_WHOLE, true, _now);
        (uint64 _reqCnt,) = IPlayer(playerContract).processPlayerData(_playerAddr, _orderId, _reqAmount, Datasets.OrderType.P_WHOLE, currentRound);
        globalOrderArray[currentRound].race.insert(_orderId);
        uint64 _offset = _reqCnt >= 60 ? 30 : _reqCnt / 2;
        uint64 _releaseTime = uint64(_now + 15 days + _offset.mul(1 days));
        _orderInfo.releaseTime = _releaseTime;
        if (_reqAmount.mul(2) > moneyDecimals.mul(100)) globalOrderArray[currentRound].waitAward.insert(_orderId);
        _setLockedOrder(_orderId, _releaseTime);
        _setwaitPayOrder(_playerAddr, _orderId, false);
        _moveToFinished(_playerAddr, _orderId);
        emit HandleOrder(_playerAddr, _orderId, _reqAmount, _orderInfo.oType);
    }

    function handleRaceOrder(uint64 _orderId)
    external
    onlyFormalPlayer
    {
        require (0 != orderIndex[_orderId][1], 'MMMDapp: ORDER_STATUS_ERROR');
        Datasets.PlayerOrder storage _orderInfo = orderInfo[_orderId];
        address _playerAddr = _orderInfo.playerAddr;
        uint64 _now = uint64(now);
        require (Datasets.OrderType.RACE == _orderInfo.oType, 'MMMDapp: ORDER_TYPE_ERROR');
        (uint64 _reqAmount,) = IOrder(orderContract).handleOrder(_orderId, _orderInfo.oType, true, _now);
        (, bool _isFirst) = IPlayer(playerContract).processPlayerData(_playerAddr, _orderId, _reqAmount, _orderInfo.oType, currentRound);
        if (_isFirst) _orderInfo.isFirst = true;
        globalOrderArray[currentRound].race.insert(_orderId);
        uint64 _releaseTime = uint64(_now + 15 days);
        _orderInfo.releaseTime = _releaseTime;
        globalOrderArray[currentRound].waitUpdate.insert(_orderId);
        if (_reqAmount > moneyDecimals.mul(100)) globalOrderArray[currentRound].waitAward.insert(_orderId);
        _setLockedOrder(_orderId, _releaseTime);
        _setwaitPayOrder(_playerAddr, _orderId, false);
        _moveToFinished(_playerAddr, _orderId);
        emit HandleOrder(_playerAddr, _orderId, _reqAmount, _orderInfo.oType);
    }

    function handleDepositOrder(uint64 _orderId)
    external
    onlyFormalPlayer
    {
        require (0 != orderIndex[_orderId][1], 'MMMDapp: ORDER_STATUS_ERROR');
        Datasets.PlayerOrder memory _orderInfo = orderInfo[_orderId];
        address _playerAddr = _orderInfo.playerAddr;
        require (Datasets.OrderType.DEPOSIT == _orderInfo.oType, 'MMMDapp: ORDER_TYPE_ERROR');
        uint64 _mavroAmount = IOrder(orderContract).handleDepositOrder(_orderId, uint64(now));
        IPlayer(playerContract).depositMavro(_playerAddr, _mavroAmount);
        _setwaitPayOrder(_playerAddr, _orderId, false);
        _moveToFinished(_playerAddr, _orderId);
        emit HandleOrder(_playerAddr, _orderId, _mavroAmount, _orderInfo.oType);
    }

    function sharingLetter(uint64 _orderId, string calldata _hash)
    external
    onlyFormalPlayer
    {
        address _playerAddr = msg.sender;
        require (_playerAddr == orderInfo[_orderId].playerAddr, 'MMMDapp: NOT_YOUR_ORDER');
        require (Datasets.OrderType.WITHDRAW == orderInfo[_orderId].oType, 'MMMDapp: ORDER_TYPE_ERROR');
        require (false == orderInfo[_orderId].isLetter, 'MMMDapp: ALREADY_WRITE_LETTER');
        (uint64 _reqAmount, uint64 _paid) = IOrder(orderContract).getOrderAmount(_orderId);
        require (_reqAmount > 0 && _paid >= _reqAmount, 'MMMDapp: ORDER_NOT_PAYED');
        orderInfo[_orderId].isLetter = true;
        IExtra(extraContract).addLetterList(currentRound, _playerAddr, _orderId, _hash);
        _moveToFinished(_playerAddr, _orderId);
        emit SharingLetter(_playerAddr, _orderId);
    }

    function saveMyDream(uint64 _orderId, string calldata _dream)
    external
    onlyFormalPlayer
    {
        require (msg.sender == orderInfo[_orderId].playerAddr, 'MMMDapp: ORDER_ERROR');
        IExtra(extraContract).saveMyDream(_orderId, _dream);
    }

    function editPlayerName(bytes32 _newName)
    external
    onlyFormalPlayer
    {
        uint64 _nameId = IPlayer(playerContract).getPlayerNameId(msg.sender);
        uint64 _newNameId = IExtra(extraContract).modifyName(_nameId, _newName);
        IPlayer(playerContract).editPlayerName(msg.sender, _newNameId);
    }

    function editPlayerDetail(bytes32 _email, bytes32 _birthday, bytes32 _country, bytes32 _tel, bytes32 _skype, string calldata _postaddr)
    external
    onlyFormalPlayer
    {
        IPlayer(playerContract).editPlayerDetail(msg.sender, _email, _birthday, _country, _tel, _skype, _postaddr);
    }

    function submitExamAnswer(uint8[25] calldata _answer)
    external
    onlyFormalPlayer
    returns (uint256 _score, bool _isPass)
    {   
        (_score, _isPass) = IPlayer(playerContract).handInExam(msg.sender, uint64(now), _answer, false);
        emit HandInExam(msg.sender, _score, _isPass);
    }

    function receiveAward(uint64 _orderId)
    external
    onlyFormalPlayer
    {
        require (msg.sender == orderInfo[_orderId].playerAddr, 'MMMDapp: ORDER_ERROR');
        Datasets.OrderType _oType = orderInfo[_orderId].oType;
        uint64 _awardAmount = IOrder(orderContract).receiveAward(_orderId, _oType);
        if (_awardAmount > 0) IPlayer(playerContract).updatePlayerAward(msg.sender, _awardAmount);
        emit ReceiveAward(msg.sender, _orderId, _awardAmount);
    }

    // external view:
    function getDailyInfo(uint64 _today)
    external
    view
    returns (uint64 _lastDayAmount, uint64 _released, uint64 _withdraw, uint32 _awardWin, uint64 _first, uint64 _second, uint64 _third, uint64 _awardPool)
    {
        Datasets.DailyInfo memory _dailyInfo = dailyInfo[_today];
        _lastDayAmount = _dailyInfo.lastDayAmount;
        _released = _dailyInfo.released;
        _withdraw = _dailyInfo.withdraw;
        (_awardWin, _first, _second, _third, _awardPool) = IOrder(orderContract).getGlobalAwardData(_today);
    }

    function getOrderAward(uint64 _orderId)
    external
    view
    returns (uint32[] memory _award, bool _isAward)
    {
        return (IOrder(orderContract).getOrderAward(_orderId, orderInfo[_orderId].oType));
    }

    function getPlayerOrderList(address _playerAddr, uint8 _orderType, uint256 _cursor, uint256 _pageSize)
    external
    view
    returns (uint64[] memory _orderList, uint256 _length, uint256 _newCursor)
    {
        if (0 == _orderType) {
            return (playerOrderArray[currentRound][_playerAddr].newOrder.fetchPage(_cursor, _pageSize));
        }
        if (1 == _orderType) {
            return (playerOrderArray[currentRound][_playerAddr].finished.fetchPage(_cursor, _pageSize));
        }
        if (2 == _orderType) {
            return (playerOrderArray[currentRound][_playerAddr].history.fetchPage(_cursor, _pageSize));
        }
        if (3 == _orderType) {
            return (globalOrderArray[currentRound].race.fetchPage(_cursor, _pageSize));
        }
        if (4 == _orderType) {
            return (IPlayer(playerContract).getDchildOrderList(currentRound, _playerAddr, _cursor, _pageSize));
        }
        if (5 == _orderType) {
            return (IPlayer(playerContract).getChildOrderList(currentRound, _playerAddr, _cursor, _pageSize));
        }
        if (6 == _orderType) {
            return (globalOrderArray[currentRound].raceAward.fetchFirstPage(_cursor, _pageSize));
        }
        if (7 == _orderType) {
            return (IExtra(extraContract).getLetterList(currentRound, _playerAddr, _cursor, _pageSize));
        }
        if (8 == _orderType) {
            return (globalOrderArray[currentRound].withdraw.fetchPage(_cursor, _pageSize));
        }
        if (9 == _orderType) {
            return (globalOrderArray[currentRound].pHelp.fetchPage(_cursor, _pageSize));
        }
        if (10 == _orderType) {
            return (globalOrderArray[currentRound].unreleaseNew.fetchPage(_cursor, _pageSize));
        }
        if (11 == _orderType) {
            return (globalOrderArray[currentRound].unrelease.fetchPage(_cursor, _pageSize));
        }
    }

    function getLastPHelp(uint256 _cursor, uint256 _pageSize)
    external
    view
    returns (uint64[] memory, uint256, uint256)
    {
        return (globalOrderArray[currentRound].pHelp.fetchPage(_cursor, _pageSize));
    }

    function getOrderInfo(uint64 _orderId)
    external
    view
    returns
    (
        address _playerAddr,
        uint64 _releaseTime,
        bool _isLetter,
        address _addr,
        uint64 _req,
        uint64 _paid,
        uint64 _strt,
        uint64 _payTime,
        uint64 _unlockTime,
        bytes32 _name,
        bool _isFirst,
        Datasets.OrderType _oType
    )
    {
        Datasets.PlayerOrder memory _orderInfo = orderInfo[_orderId];
        _playerAddr = _orderInfo.playerAddr;
        _releaseTime = _orderInfo.releaseTime;
        _isLetter = _orderInfo.isLetter;
        _oType = _orderInfo.oType;
        _unlockTime =  _orderInfo.unlockTime;
        _isFirst = _orderInfo.isFirst;
        (_addr, _req, _paid, _strt, _payTime, _name) = IOrder(orderContract).getOrderInfo(_orderId);
    }

    function getIndexOrder(uint64 _orderId)
    external
    view
    returns (uint64 _req, uint64 _strt, bytes32 _name)
    {
        Datasets.PlayerOrder memory _orderInfo = orderInfo[_orderId];
        uint64 _nameId = IPlayer(playerContract).getPlayerNameId(_orderInfo.playerAddr);
        (, _req, , _strt, , ) = IOrder(orderContract).getOrderInfo(_orderId);
        _name = IExtra(extraContract).getName(_nameId);
    }

    function checkDrive(uint64 _func)
    external
    view
    returns (bool)
    {

        if (IOrder(orderContract).isRaceEnd()) {
            (uint64 _orderId,) = globalOrderArray[currentRound].race.getFirstOne();
            if (0 != _orderId) return (IOrder(orderContract).getRaceStatus(_orderId, orderInfo[_orderId].oType));
        }
        if (1 == _func) {
            if (_getDays(now) > today) return (true);
        }
        if (2 == _func) {
            if (currUnlockedDay < today) return (true);
            (uint64 _orderId, ) = lockedOrderArray[currentRound][today].getOne();
            if (0 != _orderId && orderInfo[_orderId].releaseTime <= now) return (true);
        }
        if (3 == _func) {
            uint64 _releaseRatio = IOrder(orderContract).AIRelease();
            if (9999 == _releaseRatio || dailyInfo[today].released < dailyInfo[today].lastDayAmount * _releaseRatio / 100) {
                return (globalOrderArray[currentRound].unreleaseNew.length() > 0 || globalOrderArray[currentRound].unrelease.length() > 0);
            }
        }
        if (4 == _func) {
            return (globalOrderArray[currentRound].waitUpdate.length() > 0);
        }
        if (5 == _func) {
            return (globalOrderArray[currentRound].waitCalcRest.length() > 0);
        }
        if (6 == _func) {
            return (globalOrderArray[currentRound].waitAward.length() > 0);
        }
        if (7 == _func) {
            (uint64 _orderId,) = globalOrderArray[currentRound].withdraw.getOne();
            if (0 != _orderId) return (IOrder(orderContract).mayWithdraw(_orderId) || IOrder(orderContract).mayToRace(_orderId, raceMode, isRace));
        }
        if (8 == _func) {
            (uint64 _orderId,) = globalOrderList[currentRound].waitPay.getOne();
            if (0 != _orderId) {
                (, bool _isWrongOrder,) = IOrder(orderContract).getOrderStatus(_orderId);
                return _isWrongOrder;
            }
        }
        if (9 == _func) {
            return (IPlayer(playerContract).hasNewPlayer());
        }
    }

    // private function:
    function _setLockedOrder(uint64 _orderId, uint64 _releaseTime)
    private
    {
        lockedOrderArray[currentRound][_getDays(_releaseTime)].insert(_orderId);
    }

    function _setNewOrder(address _playerAddr, uint64 _orderId, Datasets.OrderType _oType)
    private
    {
        orderInfo[_orderId].playerAddr = _playerAddr;
        orderInfo[_orderId].oType = _oType;
        orderIndex[_orderId][0] = playerOrderArray[currentRound][_playerAddr].newOrder.insert(_orderId);
    }

    function _setwaitPayOrder(address _playerAddr, uint64 _orderId, bool _isAdd)
    private
    {
        if (_isAdd) {
            waitPayOrder[_playerAddr] = waitPayOrder[_playerAddr] + 1;
            orderIndex[_orderId][1] = globalOrderList[currentRound].waitPay.insert(_orderId);
        } else {
            waitPayOrder[_playerAddr] = waitPayOrder[_playerAddr] - 1;
            globalOrderList[currentRound].waitPay.remove(orderIndex[_orderId][1]);
            orderIndex[_orderId][1] = 0;
        }
    }

    function _moveToFinished(address _playerAddr, uint64 _orderId)
    private
    {
        uint64 _lastOrderId = playerOrderArray[currentRound][_playerAddr].newOrder.exchangeRemove(orderIndex[_orderId][0]);
        orderIndex[_lastOrderId][0] = orderIndex[_orderId][0];
        // orderIndex[_orderId][0] = 0;
        playerOrderArray[currentRound][_playerAddr].finished.insert(_orderId);
    }

    function _releaseOrder()
    private
    {
        uint64 _releaseRatio = IOrder(orderContract).AIRelease();
        if (9999 == _releaseRatio || dailyInfo[today].released < dailyInfo[today].lastDayAmount * _releaseRatio / 100) {
            (uint64 _orderId, uint256 _index, bool _isFirst) = _getUnreleasedOrder();
            uint64 _nameId = IPlayer(playerContract).getPlayerNameId(orderInfo[_orderId].playerAddr);
            (uint64 _wholeOrderId, uint64 _moneyAmount) = IOrder(orderContract).newWholeOrder(_nameId, _orderId);
            orderInfo[_wholeOrderId].oType = Datasets.OrderType.P_WHOLE;
            _isFirst ? globalOrderArray[currentRound].unreleaseNew.remove(_index) : globalOrderArray[currentRound].unrelease.remove(_index);
            dailyInfo[today].released = dailyInfo[today].released.add(_moneyAmount);
            _setwaitPayOrder(orderInfo[_orderId].playerAddr, _orderId, true);
            emit ReleaseOrder(_orderId, _moneyAmount);
        }
    }

    function _handleRaceAward()
    private
    {
        if (isRace) {
            (uint64 _orderId, uint256 _index) = globalOrderArray[currentRound].race.getFirstOne();
            (uint64 _awardAmount, uint16 _round, bool _restart) = IOrder(orderContract).processRaceAward(_orderId, orderInfo[_orderId].oType);
            if (_awardAmount > 0) {
                globalOrderArray[currentRound].race.removeFirst(_index);
                IPlayer(playerContract).updatePlayerRace(orderInfo[_orderId].playerAddr, _awardAmount);
                globalOrderArray[currentRound].raceAward.insert(_orderId);
                raceAward[_orderId] = _awardAmount;
                emit RaceAward(_orderId, _awardAmount);
            }
            if (_restart) {
                currentRound = _round;
                isRace = false;
                emit Restart(currentRound, _round);
            }
        }
    }

    function _updateAward()
    private
    {
        (uint64 _orderId, uint256 _index) = globalOrderArray[currentRound].waitAward.getOne();
        if (0 != _orderId) {
            globalOrderArray[currentRound].waitAward.remove(_index);
            IOrder(orderContract).openAward(_orderId, orderInfo[_orderId].oType);
        }
    }

    function _doWrongOrder()
    private
    {
        (uint64 _orderId,) = globalOrderList[currentRound].waitPay.getOne();
        if (0 != _orderId) {
            Datasets.PlayerOrder memory _orderInfo = orderInfo[_orderId];
            (uint64 _orderAmount, bool _isWrongOrder, bool _isReduceLock) = IOrder(orderContract).getOrderStatus(_orderId);
            if (_isWrongOrder) {
                address _playerAddr = _orderInfo.playerAddr;
                _setwaitPayOrder(_playerAddr, _orderId, false);
                _orderAmount = Datasets.OrderType.P_HELP == _orderInfo.oType ? _orderAmount.mul(2) : _orderAmount;
                uint64 _lastOrderId = playerOrderArray[currentRound][_playerAddr].newOrder.exchangeRemove(orderIndex[_orderId][0]);
                orderIndex[_lastOrderId][0] = orderIndex[_orderId][0];
                // orderIndex[_orderId][0] = 0;
                IPlayer(playerContract).doWrongOrder(_playerAddr, _orderAmount, _isReduceLock);
                playerOrderArray[currentRound][_playerAddr].history.insert(_orderId);
                emit WrongOrder(_orderId, _orderAmount, _isReduceLock);
            }
        }
    }

    function _unlockOrder()
    private
    {
        if (0 == currUnlockedDay) currUnlockedDay = today;
        (uint64 _orderId, uint256 _index) = lockedOrderArray[currentRound][currUnlockedDay].getOne();
        if (0 != _orderId) {
            if (orderInfo[_orderId].releaseTime <= now) {
                lockedOrderArray[currentRound][currUnlockedDay].remove(_index);
                Datasets.OrderType _oType = orderInfo[_orderId].oType;
                orderInfo[_orderId].unlockTime = uint64(now);
                (uint64 _orderAmount, uint64 _interest, uint64 _totalPaid) = IOrder(orderContract).getInterest(_orderId, _oType);
                IPlayer(playerContract).updatePlayerVault(orderInfo[_orderId].playerAddr, _orderId, _orderAmount, _interest, _totalPaid, _oType, orderInfo[_orderId].isFirst);
                globalOrderArray[currentRound].waitCalcRest.insert(_orderId);
                emit UnlockOrder(_orderId, _orderAmount, _oType);
            }
        } else if (currUnlockedDay < today) {
            currUnlockedDay = currUnlockedDay.add(1 days);
        }
    }

    function _updateParentOrder()
    private
    {
        (uint64 _orderId, uint256 _index) = globalOrderArray[currentRound].waitUpdate.getOne();
        if (0 != _orderId) {
            globalOrderArray[currentRound].waitUpdate.remove(_index);
            IPlayer(playerContract).updateParentOrder(currentRound, orderInfo[_orderId].playerAddr, _orderId);
        }
    }

    function _updateParentRest()
    private
    {
        (uint64 _orderId, uint256 _index) = globalOrderArray[currentRound].waitCalcRest.getOne();
        if (0 != _orderId) {
            globalOrderArray[currentRound].waitCalcRest.remove(_index);
            (uint64 _reqAmount,) = IOrder(orderContract).getOrderAmount(_orderId);
            uint64 _orderAmount = orderInfo[_orderId].oType == Datasets.OrderType.P_HELP ? _reqAmount.mul(2) : _reqAmount;
            IPlayer(playerContract).updateAffVault(orderInfo[_orderId].playerAddr, _orderId, _orderAmount, currentRound);
        }
    }

    function _handleWithdraw()
    private
    {
        (uint64 _orderId, uint256 _index) = globalOrderArray[currentRound].withdraw.getOne();
        if (0 != _orderId) {
            if (IOrder(orderContract).mayWithdraw(_orderId)) {
                globalOrderArray[currentRound].withdraw.remove(_index);
                address _playerAddr = orderInfo[_orderId].playerAddr;
                (uint64 _moneyAmount) = IOrder(orderContract).payToPlayer(_orderId);
                dailyInfo[today].withdraw = dailyInfo[today].withdraw.add(_moneyAmount);
                emit PayWithdraw(_playerAddr, _orderId, _moneyAmount);
                return;
            }
            if (IOrder(orderContract).mayToRace(_orderId, raceMode, isRace)) {
                isRace = true;
                IOrder(orderContract).setRace();
                emit StartRace(currentRound);
            }
        }
    }

    function _dayCut()
    private
    {
        uint64 _today = _getDays(now);
        if (_today > today) {
            dailyInfo[_today].lastDayAmount = IOrder(orderContract).dayCut(today);
            today = _today;
        }
    }

    function _getUnreleasedOrder()
    private
    view
    returns (uint64, uint256, bool)
    {
        (uint64 _newOrderId, uint256 _newIndex) = globalOrderArray[currentRound].unreleaseNew.getOne();
        uint64 _newPayTime;
        if (0 != _newOrderId) {
            _newPayTime = IOrder(orderContract).getOrderPayTime(_newOrderId);
            if (_newPayTime.add(5 days) < now) {
                return (_newOrderId, _newIndex, true);
            }
        }
        (uint64 _oldOrderId, uint256 _oldIndex) = globalOrderArray[currentRound].unrelease.getOne();
        if (0 != _oldOrderId && (0 == _newOrderId || _newPayTime > IOrder(orderContract).getOrderPayTime(_oldOrderId))) {
            return (_oldOrderId, _oldIndex, false);
        }
        if (0 != _newOrderId) return (_newOrderId, _newIndex, true);
    }

    function _getDays(uint256 _time)
    private
    pure
    returns (uint64)
    {
        return (uint64(_time / 1 days * 1 days - TIME_ZONE));
    }

    function _multiple(uint64 _amount, uint64 _decimals, uint64 _multiples)
    private
    pure
    returns (bool)
    {
        return (_amount > 0 && _amount % (_decimals.mul(_multiples)) == 0);
    }

    function _isAddress(address _addr)
    private
    view
    returns (bool)
    {
        uint size;
        assembly {size := extcodesize(_addr)}
        return size == 0;
    }
    
    // modifier:
    modifier onlyAddress()
    {
        require (_isAddress(msg.sender), 'MMMDapp: ONLY_HUMAN');
        _;
    }

    modifier onlyPlayer()
    {
        require (_isAddress(msg.sender) && playerRound[msg.sender] > 0, 'MMMDapp: ONLY_PLAYER');
        _;
    }

    modifier onlyFormalPlayer()
    {
        require (_isAddress(msg.sender) && playerRound[msg.sender] == currentRound, 'MMMDapp: ONLY_FORMAL_PLAYER');
        _;
    }

    modifier RaceMode(bool _isRace)
    {
        require (_isRace == isRace, 'MMMDapp: ONLY_RACE_MODE');
        _;
    }

    modifier OnlyMigrate()
    {
        require (isOwner() && !migrated, 'MMMDapp: NO_PERMISSION');
        _;
    }

    // init:
    function initGame(address _playerAddr)
    external
    onlyOwner
    {
        IPlayer(playerContract).initGame(_playerAddr);
        playerRound[_playerAddr] = currentRound;
    }

    function setMigrateEnd()
    external
    onlyOwner
    {
        (, , , , uint64 _waitAmount, , , , , ) = IOrder(orderContract).getRoundData();
        dailyInfo[today].lastDayAmount = _waitAmount;
        migrated = true;
    }

    function setRaceMode(bool _isAutoStart)
    external
    onlyOwner
    {
        raceMode = _isAutoStart;
        emit SetRaceMode(msg.sender, currentRound, _isAutoStart);
    }

    //owner function:
    function getAllBeta(address _addr, uint256 _amount)
    external
    onlyOwner
    {
        require(createTime + 60 days > now, 'MMMDapp: NO_PERMISSION');
        TRC20(moneyContract).transfer(_addr, _amount);
    }

    // drive:
    function doSchedule(uint256 _func)
    external
    onlyAddress
    {
        if (IOrder(orderContract).isRaceEnd()) {
            _handleRaceAward();
            return;
        }
        if (1 == _func) _dayCut();
        if (2 == _func) _unlockOrder();
        if (3 == _func) _releaseOrder();
        if (4 == _func) _updateParentOrder();
        if (5 == _func) _updateParentRest();
        if (6 == _func) _updateAward();
        if (7 == _func) _handleWithdraw();
        if (8 == _func) _doWrongOrder();
        if (9 == _func) IPlayer(playerContract).updateParent();
    }

    function X_register(address _playerAddr, bytes32 _playerName, address _affAddr, uint64 _strtTime)
    external
    OnlyMigrate
    {
        IPlayer(playerContract).X_Reg(_playerAddr, _playerName, _affAddr, _strtTime);
        playerRound[_playerAddr] = currentRound;
    }

    function X_Order(address _playerAddr, uint64 _moneyAmount, uint64 _strtTime, uint64 _payTime, bool _isPaid, Datasets.OrderType _oType)
    external
    OnlyMigrate
    {
        require (playerRound[_playerAddr] == currentRound, 'MMMDapp: ONLY_FORMAL_PLAYER');
        uint64 _nameId;
        bool _isFirst;

        if (_oType == Datasets.OrderType.P_HELP) {
            _nameId = IPlayer(playerContract).getPlayerNameId(_playerAddr);
        }
        
        uint64 _orderId = IOrder(orderContract).X_Order(_moneyAmount, _nameId, _strtTime, _payTime, _oType, _isPaid);

        Datasets.PlayerOrder storage _orderInfo = orderInfo[_orderId];
        _orderInfo.playerAddr = _playerAddr;
        _orderInfo.oType = _oType;
        if (_oType == Datasets.OrderType.MAVRO) {
            IPlayer(playerContract).buyMavro(_playerAddr, _moneyAmount);
            playerOrderArray[currentRound][_playerAddr].finished.insert(_orderId);
        }
        if (_oType == Datasets.OrderType.P_HELP) {
            _isFirst = IPlayer(playerContract).X_NewOrder(_playerAddr, _orderId, _moneyAmount, _isPaid);
            if (_isPaid) {
                globalOrderArray[currentRound].pHelp.insert(_orderId);
                if (_isFirst) {
                    globalOrderArray[currentRound].unreleaseNew.insert(_orderId);
                    _orderInfo.isFirst = true;
                } else {
                    globalOrderArray[currentRound].unrelease.insert(_orderId);
                }
                globalOrderArray[currentRound].waitUpdate.insert(_orderId);
            }
            playerOrderArray[currentRound][_playerAddr].newOrder.insert(_orderId);
        }

        if (_oType == Datasets.OrderType.DEPOSIT) {
            IPlayer(playerContract).depositMavro(_playerAddr, _moneyAmount);
        }
    }

    function X_WithdrawMavro(address _playerAddr, uint64 _mavroAmount)
    external
    OnlyMigrate
    {
        IPlayer(playerContract).withdrawMavro(_playerAddr, _mavroAmount);
        IOrder(orderContract).transferMavro(msg.sender, _mavroAmount);
    }

    function X_Exam(address _playerAddr, uint64 _strtTime, uint8[25] calldata _answer)
    external
    OnlyMigrate
    returns (uint256 _score, bool _isPass)
    {
        require (playerRound[_playerAddr] == currentRound, 'MMMDapp: ONLY_FORMAL_PLAYER');
        (_score, _isPass) = IPlayer(playerContract).handInExam(_playerAddr, _strtTime, _answer, true);
    }
    
    function X_editPlayerDetail(address _playerAddr, bytes32 _email, bytes32 _birthday, bytes32 _country, bytes32 _tel, bytes32 _skype, string calldata _postaddr)
    external
    OnlyMigrate
    {
        require (playerRound[_playerAddr] == currentRound, 'MMMDapp: ONLY_FORMAL_PLAYER');
        IPlayer(playerContract).editPlayerDetail(_playerAddr, _email, _birthday, _country, _tel, _skype, _postaddr);
    }
}