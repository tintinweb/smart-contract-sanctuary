// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RecordInterface.sol";
import "./UserStorage.sol";
import "./OrderStorage.sol";

abstract contract ReentrancyGuardRecord {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

library CountersRecord {
    struct Counter {
        uint256 _value;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        {
            if (counter._value == 0) {
                counter._value = 10000;
            }
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        {
            counter._value = value - 1;
        }
    }
}

interface TokenTransfer {
    function transfer(address recipient, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
}

contract RecordStorage is Ownable, ReentrancyGuardRecord {
    using CountersRecord for CountersRecord.Counter;

    string constant P_COIN = "WMOVR";

    mapping(string => address) coinTypeMaping;
    uint256 merchantNeedCount = 0.1 * (10**18);
    uint256 witnessNeedCount = 1 * (10**18);
    uint256 congressNeedCount = 10 * (10**18);
    uint256 appealFee = 0.01 * (10**18);
    uint256 appealFeeFinal = 0.1 * (10**18);
    uint256 canWithdrawToTime = 28;
    uint256 subWitFee = 0.01 * (10**18);
    uint256 subWitCredit = 10;
    uint256 witnessHandleReward = 0.01 * (10**18);
    uint256 observerHandleReward = 0.1 * (10**18);
    uint256 witnessHandleCredit = 1;
    uint256 observerHandleCredit = 1;
    bool openTrade = false;
    uint256 tradeCredit = 1;
    uint256 subTCredit = 10;

    mapping(address => uint256) witnessFlag;
    mapping(address => uint256) congressFlag;

    function setWitnessFlag(address _addr, uint256 _flag) external onlyOwner {
        witnessFlag[_addr] = _flag;
        if (_flag == 1) {
            uint256 _amt = availableTotal[_addr][P_COIN];
            require(_amt >= witnessNeedCount, "coin not enough");
            _userStorage.updateUserRole(_addr, 1);
        } else {
            _userStorage.updateUserRole(_addr, 0);
        }
    }

    function getWitnessFlag(address _addr) public view returns (uint256) {
        return witnessFlag[_addr];
    }

    function setCongressFlag(address _addr, uint256 _flag) external onlyOwner {
        congressFlag[_addr] = _flag;
        if (_flag == 1) {
            uint256 _amt = availableTotal[_addr][P_COIN];
            require(_amt >= congressNeedCount, "coin not enough");
            _userStorage.updateUserRole(_addr, 2);
        } else {
            _userStorage.updateUserRole(_addr, 0);
        }
    }

    function getCongressFlag(address _addr) public view returns (uint256) {
        return congressFlag[_addr];
    }

    function setCoinTypeMapping(
        string calldata _coinType,
        address _coinTypeAddr
    ) external onlyOwner {
        coinTypeMaping[_coinType] = _coinTypeAddr;
    }

    function getCoinTypeMapping(string calldata _coinType)
        public
        view
        returns (address)
    {
        return coinTypeMaping[_coinType];
    }

    function setMerchantNeedCount(uint256 _count) external onlyOwner {
        merchantNeedCount = _count;
    }

    function getMerchantNeedCount() public view returns (uint256) {
        return merchantNeedCount;
    }

    function setWitnessNeedCount(uint256 _count) external onlyOwner {
        witnessNeedCount = _count;
    }

    function getWitnessNeedCount() public view returns (uint256) {
        return witnessNeedCount;
    }

    function setCongressNeedCount(uint256 _count) external onlyOwner {
        congressNeedCount = _count;
    }

    function getCongressNeedCount() public view returns (uint256) {
        return congressNeedCount;
    }

    function setAppealFee(uint256 _count) external onlyOwner {
        appealFee = _count;
    }

    function getAppealFee() public view returns (uint256) {
        return appealFee;
    }

    function setAppealFeeFinal(uint256 _count) external onlyOwner {
        appealFeeFinal = _count;
    }

    function getAppealFeeFinal() public view returns (uint256) {
        return appealFeeFinal;
    }

    function setCanWithdrawToTime(uint256 _days) external onlyOwner {
        canWithdrawToTime = _days;
    }

    function getCanWithdrawToTime() public view returns (uint256) {
        return canWithdrawToTime;
    }

    function setSubWitFee(uint256 _c) external onlyOwner {
        subWitFee = _c;
    }

    function getSubWitFee() public view returns (uint256) {
        return subWitFee;
    }

    function setSubWitCredit(uint256 _c) external onlyOwner {
        subWitCredit = _c;
    }

    function getSubWitCredit() public view returns (uint256) {
        return subWitCredit;
    }

    function setWitnessHandleReward(uint256 _c) external onlyOwner {
        witnessHandleReward = _c;
    }

    function getWitnessHandleReward() public view returns (uint256) {
        return witnessHandleReward;
    }

    function setObserverHandleReward(uint256 _c) external onlyOwner {
        observerHandleReward = _c;
    }

    function getObserverHandleReward() public view returns (uint256) {
        return observerHandleReward;
    }

    function setWitnessHandleCredit(uint256 _c) external onlyOwner {
        witnessHandleCredit = _c;
    }

    function getWitnessHandleCredit() public view returns (uint256) {
        return witnessHandleCredit;
    }

    function setObserverHandleCredit(uint256 _c) external onlyOwner {
        observerHandleCredit = _c;
    }

    function getObserverHandleCredit() public view returns (uint256) {
        return observerHandleCredit;
    }

    function setOpenTrade(bool _c) external onlyOwner {
        openTrade = _c;
    }

    function getOpenTrade() public view returns (bool) {
        return openTrade;
    }

    function setTradeCredit(uint256 _c) external onlyOwner {
        tradeCredit = _c;
    }

    function getTradeCredit() public view returns (uint256) {
        return tradeCredit;
    }

    function setSubTCredit(uint256 _c) external onlyOwner {
        subTCredit = _c;
    }

    function getSubTCredit() public view returns (uint256) {
        return subTCredit;
    }

    function punishPerson(
        address _from,
        address _to,
        uint256 _count
    ) external onlyOwner {
        require(_from != address(0) && _to != address(0));
        UserStorage.User memory _user = _userStorage.searchUser(_from);
        require(_user.userFlag == 1 || _user.userFlag == 2, "can't punish");

        uint256 _ava = availableTotal[_from][P_COIN];
        uint256 _toavailab = availableTotal[_to][P_COIN];
        if (_ava >= _count) {
            availableTotal[_from][P_COIN] = SafeMath.sub(_ava, _count);
            availableTotal[_to][P_COIN] = SafeMath.add(_toavailab, _count);
        } else {
            availableTotal[_from][P_COIN] = 0;

            uint256 _draing = withdrawingTotal[_from][P_COIN];
            if (SafeMath.add(_ava, _draing) >= _count) {
                withdrawingTotal[_from][P_COIN] = SafeMath.sub(
                    _draing,
                    SafeMath.sub(_count, _ava)
                );
                availableTotal[_to][P_COIN] = SafeMath.add(_toavailab, _count);
            } else {
                withdrawingTotal[_from][P_COIN] = 0;
                availableTotal[_to][P_COIN] = SafeMath.add(
                    _toavailab,
                    SafeMath.add(_ava, _draing)
                );
            }
        }
        chanRole(_from);
        chanRole(_to);
    }

    UserInterface private _userStorage;
    OrderInterface private _orderStorage;
    struct Record {
        uint256 recordNo;
        address userAddr;
        string tradeHash;
        string coinType;
        uint256 hostCount;
        uint256 hostStatus;
        uint256 hostType;
        uint256 hostDirection;
        uint256 hostTime;
        uint256 updateTime;
    }

    CountersRecord.Counter private _recordNoCounter;
    mapping(uint256 => Record) public records;
    mapping(uint256 => uint256) public recordIndex;

    Record[] public recordList;

    mapping(address => mapping(string => uint256)) public availableTotal;

    mapping(address => mapping(string => uint256)) public frozenTotal;

    mapping(address => mapping(string => uint256)) public unfrozenTotal;

    mapping(address => uint256) lastWithdrawTime;

    mapping(address => mapping(uint256 => uint256)) lastWithdrawAmount;

    mapping(address => mapping(string => uint256)) public withdrawingTotal;

    mapping(address => mapping(uint256 => uint256)) orderSubFrozenList;

    constructor(
        address _usdtAddress,
        address _usdcAddress,
        address _coinAddress
    ) {
        coinTypeMaping["USDT"] = _usdtAddress;
        coinTypeMaping["USDC"] = _usdcAddress;
        coinTypeMaping[P_COIN] = _coinAddress;
        _recordNoCounter.increment();
    }

    function getERC20Address(string memory _coinType)
        public
        view
        returns (TokenTransfer)
    {
        address _remoteAddr = coinTypeMaping[_coinType];
        require(_remoteAddr != address(0));

        TokenTransfer _tokenTransfer = TokenTransfer(_remoteAddr);
        return _tokenTransfer;
    }

    event RecordAdd(
        uint256 _recordNo,
        address _addr,
        string _tradeHash,
        string _coinType,
        uint256 _hostCount,
        uint256 _hostStatus,
        uint256 _hostType,
        uint256 _hostDirection
    );
    event RecordApplyUnfrozen(address _addr, uint256 _amt);
    event UnfrozenTotalTransfer(
        address _addr,
        string _coinType,
        uint256 _lastAmount
    );
    event RecordUpdate(
        address _addr,
        uint256 _recordNo,
        string _hash,
        uint256 _hostStatus
    );

    address _userAddr;
    address _restCAddr;
    address _orderCAddr;
    address _appealCAddr;

    modifier onlyAuthFromAddr() {
        require(_userAddr != address(0), "Invalid address call user");
        require(_restCAddr != address(0), "Invalid address call rest");
        require(_orderCAddr != address(0), "Invalid address call order");
        require(_appealCAddr != address(0), "Invalid address call appeal");
        _;
    }

    function authFromContract(
        address _fromUser,
        address _fromRest,
        address _fromOrder,
        address _fromAppeal
    ) external onlyOwner {
        _userAddr = _fromUser;
        _restCAddr = _fromRest;
        _orderCAddr = _fromOrder;
        _appealCAddr = _fromAppeal;
        _userStorage = UserInterface(_userAddr);
        _orderStorage = OrderInterface(_orderCAddr);
    }

    function _insert(
        address _addr,
        string memory _tradeHash,
        string memory _coinType,
        uint256 _hostCount,
        uint256 _hostStatus,
        uint256 _hostType,
        uint256 _hostDirection
    ) internal nonReentrant returns (uint256 recordNo) {
        require(_addr != address(0), "address null");
        require(bytes(_coinType).length != 0, "coinType null");
        require(_hostCount != uint256(0), "hostCount null");
        require(_hostType != uint256(0), "hostType null");
        require(_hostDirection != uint256(0), "hostDirection null");

        uint256 _recordNo = _recordNoCounter.current();
        require(records[_recordNo].recordNo == uint256(0), "order exist");

        Record memory _record = Record({
            recordNo: _recordNo,
            userAddr: _addr,
            tradeHash: _tradeHash,
            coinType: _coinType,
            hostCount: _hostCount,
            hostStatus: _hostStatus,
            hostType: _hostType,
            hostDirection: _hostDirection,
            hostTime: block.timestamp,
            updateTime: 0
        });

        records[_recordNo] = _record;

        recordList.push(_record);
        recordIndex[_recordNo] = recordList.length - 1;

        _recordNoCounter.increment();
        emit RecordAdd(
            _recordNo,
            _addr,
            _tradeHash,
            _coinType,
            _hostCount,
            _hostStatus,
            _hostType,
            _hostDirection
        );
        return _recordNo;
    }

    function tokenEscrow(string memory _coinType, uint256 _amt) external {
        require(_amt > 0, "invalid");
        require(
            availableTotal[msg.sender][_coinType] + _amt >
                availableTotal[msg.sender][_coinType],
            "Invalid transfer amount"
        );

        availableTotal[msg.sender][_coinType] = SafeMath.add(
            availableTotal[msg.sender][_coinType],
            _amt
        );

        uint256 _hostType = 1;
        if (
            keccak256(abi.encodePacked(_coinType)) ==
            keccak256(abi.encodePacked(P_COIN))
        ) {
            _hostType = 2;
            UserStorage.User memory _user = _userStorage.searchUser(msg.sender);

            _changeUserMorgageStats(
                msg.sender,
                availableTotal[msg.sender][_coinType]
            );

            if (
                _user.userFlag == 0 &&
                availableTotal[msg.sender][_coinType] >= merchantNeedCount
            ) {
                _userStorage.updateUserRole(msg.sender, 3);
            }
        }
        _insert(msg.sender, "", _coinType, _amt, 2, _hostType, 1);

        TokenTransfer _tokenTransfer = getERC20Address(_coinType);
        _tokenTransfer.transferFrom(msg.sender, address(this), _amt);
    }

    function addRecord(
        address _addr,
        string memory _tradeHash,
        string memory _coinType,
        uint256 _hostCount,
        uint256 _hostStatus,
        uint256 _hostType,
        uint256 _hostDirection
    ) public onlyAuthFromAddr {
        require(
            msg.sender == _restCAddr || msg.sender == _orderCAddr,
            "RedocrdStorage:Invalid from contract address"
        );

        frozenTotal[_addr][_coinType] = SafeMath.add(
            frozenTotal[_addr][_coinType],
            _hostCount
        );
        _insert(
            _addr,
            _tradeHash,
            _coinType,
            _hostCount,
            _hostStatus,
            _hostType,
            _hostDirection
        );
    }

    function addAvailableTotal(
        address _addr,
        string memory _coinType,
        uint256 _amt
    ) public onlyAuthFromAddr {
        require(
            msg.sender == _restCAddr || msg.sender == _orderCAddr,
            "Invalid address"
        );
        require(_amt > 0, "invalid");
        uint256 _aBalance = getErcBalance(_coinType, address(this));
        require(_aBalance >= _amt, "not enough");
        require(frozenTotal[_addr][_coinType] >= _amt, "insufficient");
        require(
            SafeMath.sub(frozenTotal[_addr][_coinType], _amt) <=
                frozenTotal[_addr][_coinType],
            "Invalid amount"
        );
        frozenTotal[_addr][_coinType] = SafeMath.sub(
            frozenTotal[_addr][_coinType],
            _amt
        );

        TokenTransfer _tokenTransfer = getERC20Address(_coinType);
        _tokenTransfer.transfer(_addr, _amt);
    }

    function getAvailableTotal(address _addr, string memory _coinType)
        public
        view
        returns (uint256)
    {
        return availableTotal[_addr][_coinType];
    }

    function subFrozenTotal(uint256 _orderNo, address _addr)
        public
        onlyAuthFromAddr
    {
        require(
            msg.sender == _orderCAddr || msg.sender == _appealCAddr,
            "Invalid call"
        );
        OrderStorage.Order memory _order = _orderStorage.searchOrder(_orderNo);
        require(_order.orderNo != uint256(0), "not exist");
        address _seller = _order.orderDetail.sellerAddr;
        string memory _coinType = _order.orderDetail.coinType;

        uint256 _subAmount = orderSubFrozenList[_seller][_orderNo];
        require(_subAmount == 0);

        uint256 _frozen = frozenTotal[_seller][_coinType];
        uint256 _orderCount = _order.coinCount;
        require(_frozen >= _orderCount);
        require(SafeMath.sub(_frozen, _orderCount) <= _frozen);

        frozenTotal[_seller][_coinType] = SafeMath.sub(_frozen, _orderCount);
        orderSubFrozenList[_seller][_orderNo] = _orderCount;

        TokenTransfer _tokenTransfer = getERC20Address(_coinType);
        _tokenTransfer.transfer(_addr, _orderCount);
    }

    function subAvaAppeal(
        address _from,
        address _to,
        AppealStorage.Appeal memory _al,
        uint256 _amt,
        uint256 _t,
        uint256 _self
    ) public onlyAuthFromAddr {
        require(msg.sender == _appealCAddr, "Invalid call");

        uint256 _available = getAvailableTotal(_from, P_COIN);
        uint256 _need = 0;
        address _opt = _t == 1 ? _al.witness : _al.detail.observerAddr;
        if (_available >= _amt) {
            _need = _amt;
        } else {
            _need = _available;
        }

        if (
            (_t == 1 && _self == 0) ||
            (_t == 2 && _al.detail.finalAppealAddr != _from)
        ) {
            availableTotal[_from][P_COIN] = SafeMath.sub(
                availableTotal[_from][P_COIN],
                _need
            );
            availableTotal[_to][P_COIN] = SafeMath.add(
                availableTotal[_to][P_COIN],
                _need
            );
            _changeUserMorgageStats(_from, availableTotal[_from][P_COIN]);
            _changeUserMorgageStats(_to, availableTotal[_to][P_COIN]);
        }

        availableTotal[_opt][P_COIN] = SafeMath.add(
            availableTotal[_opt][P_COIN],
            _amt
        );
        _changeUserMorgageStats(_opt, availableTotal[_opt][P_COIN]);
        chanRole(_from);
        chanRole(_to);
        chanRole(_opt);

        UserStorage.User memory _user = _userStorage.searchUser(_opt);
        if (_t == 1) {
            _user.credit = _user.credit + witnessHandleCredit;
        } else if (_t == 2) {
            _user.credit = _user.credit + observerHandleCredit;
        }
        UserStorage.TradeStats memory _tradeStats = _user.tradeStats;
        _userStorage.updateTradeStats(_opt, _tradeStats, _user.credit);
    }

    function _changeUserMorgageStats(address _addr, uint256 _amt) internal {
        UserStorage.User memory _user = _userStorage.searchUser(_addr);
        UserStorage.MorgageStats memory _morgageStats = _user.morgageStats;
        _morgageStats.mortgage = _amt;
        _userStorage.updateMorgageStats(_addr, _morgageStats);
    }

    function subWitnessAvailable(address _addr) public onlyAuthFromAddr {
        require(msg.sender == _appealCAddr, "Invalid call");
        require(_addr != address(0), "address null");
        uint256 _availableTotal = availableTotal[_addr][P_COIN];
        uint256 _need = 0;
        uint256 subFromDraing = 0;
        if (_availableTotal >= subWitFee) {
            _need = subWitFee;
            availableTotal[_addr][P_COIN] = SafeMath.sub(
                _availableTotal,
                _need
            );
        } else {
            availableTotal[_addr][P_COIN] = 0;

            uint256 _draing = withdrawingTotal[_addr][P_COIN];
            if (SafeMath.add(_availableTotal, _draing) >= subWitFee) {
                _need = subWitFee;
                subFromDraing = SafeMath.sub(subWitFee, _availableTotal);
                withdrawingTotal[_addr][P_COIN] = SafeMath.sub(
                    _draing,
                    subFromDraing
                );
            } else {
                _need = SafeMath.add(_draing, _availableTotal);
                withdrawingTotal[_addr][P_COIN] = 0;
            }
        }
        chanRole(_addr);

        UserStorage.User memory _user = _userStorage.searchUser(_addr);
        _user.credit = _user.credit >= subWitCredit
            ? (_user.credit - subWitCredit)
            : 0;
        UserStorage.TradeStats memory _tradeStats = _user.tradeStats;
        _userStorage.updateTradeStats(_addr, _tradeStats, _user.credit);

        TokenTransfer _tokenTransfer = getERC20Address(P_COIN);
        _tokenTransfer.transfer(owner(), _need);
    }

    function getFrozenTotal(address _addr, string memory _coinType)
        public
        view
        returns (uint256)
    {
        return frozenTotal[_addr][_coinType];
    }

    function applyUnfrozen(uint256 _amt) external returns (uint256) {
        require(_amt > 0);
        require(availableTotal[msg.sender][P_COIN] >= _amt, "Invalid amount");
        require(
            SafeMath.sub(availableTotal[msg.sender][P_COIN], _amt) <
                availableTotal[msg.sender][P_COIN],
            "Invalid amount 2"
        );

        lastWithdrawTime[msg.sender] = block.timestamp;
        lastWithdrawAmount[msg.sender][lastWithdrawTime[msg.sender]] = _amt;
        availableTotal[msg.sender][P_COIN] = SafeMath.sub(
            availableTotal[msg.sender][P_COIN],
            _amt
        );
        withdrawingTotal[msg.sender][P_COIN] = SafeMath.add(
            withdrawingTotal[msg.sender][P_COIN],
            _amt
        );

        chanRole(msg.sender);

        _insert(msg.sender, "", P_COIN, _amt, 3, 3, 2);

        emit RecordApplyUnfrozen(msg.sender, _amt);

        return getAvailableTotal(msg.sender, P_COIN);
    }

    function chanRole(address _addr) internal {
        uint256 _avail = availableTotal[_addr][P_COIN];

        UserStorage.User memory _user = _userStorage.searchUser(_addr);

        _changeUserMorgageStats(_addr, _avail);

        if (
            _user.userFlag == 2 &&
            _avail < congressNeedCount &&
            _avail >= merchantNeedCount
        ) {
            _userStorage.updateUserRole(_addr, 3);
        }

        if (
            _user.userFlag == 1 &&
            _avail < witnessNeedCount &&
            _avail >= merchantNeedCount
        ) {
            _userStorage.updateUserRole(_addr, 3);
        }

        if (_user.userFlag == 0 && _avail >= merchantNeedCount) {
            _userStorage.updateUserRole(_addr, 3);
        }

        if (_avail < merchantNeedCount) {
            _userStorage.updateUserRole(_addr, 0);
        }
    }

    function unApplyUnfrozen(address _addr) external onlyOwner {
        uint256 _drawing = withdrawingTotal[_addr][P_COIN];
        require(_drawing > 0, "sufficient");
        withdrawingTotal[_addr][P_COIN] = 0;
        availableTotal[_addr][P_COIN] = SafeMath.add(
            availableTotal[_addr][P_COIN],
            _drawing
        );
        chanRole(_addr);
    }

    function applyWithdraw(uint256 _recordNo) public {
        Record memory _record = records[_recordNo];

        require(_record.recordNo != uint256(0), "record not exist");
        require(_record.userAddr == msg.sender, "record user not exist");

        require(_record.hostStatus == 3, "status error");

        require(
            withdrawingTotal[msg.sender][P_COIN] >= _record.hostCount,
            "sufficient"
        );

        require(
            block.timestamp >= (_record.hostTime + canWithdrawToTime * 1 days),
            "can't withdraw"
        );

        withdrawingTotal[msg.sender][P_COIN] = SafeMath.sub(
            withdrawingTotal[msg.sender][P_COIN],
            _record.hostCount
        );
        unfrozenTotal[msg.sender][P_COIN] = SafeMath.add(
            unfrozenTotal[msg.sender][P_COIN],
            _record.hostCount
        );

        _record.hostStatus = 4;
        _record.updateTime = block.timestamp;
        records[_recordNo] = _record;
        recordList[recordIndex[_recordNo]] = _record;
        emit RecordUpdate(msg.sender, _recordNo, _record.tradeHash, 4);

        TokenTransfer _tokenTransfer = getERC20Address(P_COIN);
        _tokenTransfer.transfer(msg.sender, _record.hostCount);
    }

    function unfrozenTotalSearch(address _addr, string memory _coinType)
        public
        view
        returns (uint256)
    {
        require(_addr != address(0), "user address is null");

        return unfrozenTotal[_addr][_coinType];
    }

    function getUnfrozenTotal(address _addr, string memory _coinType)
        external
        view
        returns (uint256)
    {
        return unfrozenTotal[_addr][_coinType];
    }

    function getWithdrawingTotal(address _addr, string memory _coinType)
        public
        view
        returns (uint256)
    {
        return withdrawingTotal[_addr][_coinType];
    }

    function getErcBalance(string memory _coinType, address _addr)
        public
        view
        returns (uint256)
    {
        TokenTransfer _tokenTransfer = getERC20Address(_coinType);
        return _tokenTransfer.balanceOf(_addr);
    }

    function _updateInfo(
        address _addr,
        uint256 _recordNo,
        string memory _hash,
        uint256 _hostStatus
    ) internal returns (bool) {
        Record storage _record = records[_recordNo];
        require(_record.userAddr == _addr);
        require(_hostStatus == 1 || _hostStatus == 2, "invalid status");

        if (_hostStatus != uint256(0)) {
            _record.hostStatus = _hostStatus;
        }
        if (bytes(_hash).length != 0) {
            _record.tradeHash = _hash;
        }

        _record.updateTime = block.timestamp;

        emit RecordUpdate(_addr, _recordNo, _hash, _hostStatus);
        return true;
    }

    function updateInfo(
        address _addr,
        uint256 _recordNo,
        string memory _hash,
        uint256 _hostStatus
    ) external returns (bool) {
        return _updateInfo(_addr, _recordNo, _hash, _hostStatus);
    }

    function searchRecord(uint256 _recordNo)
        external
        view
        returns (Record memory record)
    {
        return records[_recordNo];
    }

    function searchRecordList() external view returns (Record[] memory) {
        return recordList;
    }
}