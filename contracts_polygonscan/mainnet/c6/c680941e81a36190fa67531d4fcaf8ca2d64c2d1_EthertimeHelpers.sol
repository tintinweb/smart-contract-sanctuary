/**
 *Submitted for verification at polygonscan.com on 2021-08-08
*/

pragma solidity >=0.5.16 <0.6.0;
pragma experimental ABIEncoderV2;
contract Ethertime {
    using SafeMath for *;
    uint256 constant None = uint256(0);
    uint256 constant private FULL_PART = 10000;
    uint256 constant private FEE = 1150;
    enum OrderStatus {
        Open,
        Closed
    }
    struct Order {
        uint256 id;
        uint256 part;
        uint256 sum;
        uint256 expiredDate;
        address admin;
        address recipient;
        OrderStatus status;
    }
    address private _owner;
    uint256 private _totalFee;
    address[] private _admins;
    mapping (address => uint256) private _adminsParts;
    mapping (uint256 => uint256) private _reservedFee;
    mapping (uint256 => Order) private _orders;
    uint256 _lastOrderId;
    mapping (uint256 => EthertimeCommon.Lottery) private _lotteries;
    uint256 _lastLotteryId;
    mapping (uint256 => EthertimeCommon.Player[]) private _players;
    mapping (address => mapping (uint256 => uint256[])) private _lotteryParticipationIndexes;
    mapping (address => mapping (uint256 => bool)) private _payoutsCompletion;
    uint256[] _openLotteries;
    event BuyTicketEvent(
        address indexed from,
        uint256 indexed lotteryId
    );
    event NewLotteryEvent(
        uint256 indexed lotteryId
    );
    event FinishedLotteryEvent(
        uint256 indexed lotteryId
    );
    event PayOutEvent(
        address indexed playerAddress,
        uint256 amount
    );
    event DeleteLotteryEvent(
        uint256 indexed lotteryId
    );
    event TransferAdminPartEvent(
        address indexed from,
        address indexed to,
        uint256 indexed part
    );
    event TransferOwnershipEvent(
        address indexed from,
        address indexed to
    );
    event DividendEvent(
        address indexed admin,
        uint256 indexed sum
    );
    event NewOrderEvent(
        uint256 indexed orderId,
        address indexed admin,
        address indexed recipient
    );
    event ConfirmOrderEvent(
        uint256 indexed orderId
    );
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
    modifier onlyAdmin() {
        require(checkIsAdmin(msg.sender));
        _;
    }
    constructor() public {
        _owner = msg.sender;
        _admins.push(_owner);
        _adminsParts[_owner] = FULL_PART;
    }
    function transferOwnership(address addr) public onlyOwner {
        _owner = addr;
        emit TransferOwnershipEvent(msg.sender, addr);
    }
    function transferAdminPart(address addr, uint256 part)
        public
        onlyAdmin
    {
        require(part <= _adminsParts[msg.sender]);
        distributeDividend();
        if (!checkIsAdmin(addr)) {
            _admins.push(addr);
        }
        _adminsParts[msg.sender] = _adminsParts[msg.sender].sub(part);
        _adminsParts[addr] = _adminsParts[addr].add(part);
        if (_adminsParts[msg.sender] == 0) {
            removeAdmin(msg.sender);
        }
        emit TransferAdminPartEvent(msg.sender, addr, part);
    }
    function distributeDividend() public onlyAdmin {
        if (_totalFee == 0)
            return;
        uint256 totalSum = _totalFee;
        for (uint256 i = 0; i < _admins.length; i++) {
            address payable addr = address(uint160(_admins[i]));
            uint256 sum = totalSum.mul(_adminsParts[addr]).div(FULL_PART);
            if (sum > 0) {
                _totalFee = _totalFee.sub(sum);
                addr.transfer(sum);
                emit DividendEvent(addr, sum);
            }
        }
    }
    function createLottery(
        string memory name,
        uint256 price,
        uint256 begin,
        uint256 end,
        EthertimeCommon.LotteryPrizeType prizeType,
        bool withDiscount
    )
        public
        onlyOwner
    {
        require(begin < end);
        _lastLotteryId = _lastLotteryId.add(1);
        _lotteries[_lastLotteryId] = EthertimeCommon.Lottery({
            id: _lastLotteryId,
            name: name,
            owner: msg.sender,
            price: price,
            begin: begin,
            end: end,
            number: 1,
            pot: 0,
            status: EthertimeCommon.LotteryStatus.Open,
            prizeType: prizeType,
            rootId: _lastLotteryId,
            parentId: None,
            childId: None,
            isContinued: true,
            winNumber: 0,
            middlePlayerBlockNumber: 0,
            middlePlayerBlockHash: 0x0,
            previousBlockNumber: 0,
            previousBlockHash: 0x0,
            withDiscount: withDiscount,
            winningsCount: None,
            uniquePlayersCount: 0,
            remainder: 0
         });
        _openLotteries.push(_lastLotteryId);
        emit NewLotteryEvent(_lastLotteryId);
    }
    function buyTicket(uint256 lotteryId) public payable {
        require(lotteryId <= _lastLotteryId);
        finalizeLottery(_lotteries[lotteryId].rootId);
        uint256 actualLotteryId = EthertimeHelpers.getActualLotteryId(
            lotteryId, _lotteries, _openLotteries
        );
        require(actualLotteryId != None);
        EthertimeCommon.Lottery storage lottery = _lotteries[actualLotteryId];
        uint256 actualPrice = EthertimeHelpers.getActualLotteryPrice(
            lottery.withDiscount,
            lottery.price,
            lottery.begin,
            lottery.end
        );
        require(msg.value >= actualPrice);
        incUniquePlayersCount(lottery.id, msg.sender);
        addPlayerToLottery(lottery, actualPrice, msg.sender);
        uint256 feeSum = actualPrice.mul(FEE).div(FULL_PART);
        lottery.pot = lottery.pot.add(actualPrice.sub(feeSum));
        _reservedFee[lottery.id] = _reservedFee[lottery.id].add(feeSum);
        uint256 remainder = msg.value.sub(actualPrice);
        if (remainder > 0)
            msg.sender.transfer(remainder);
        emit BuyTicketEvent(msg.sender, actualLotteryId);
    }
    function finalizeLottery(uint256 lotteryRootId) public {
        for (uint256 i = 0; i < _openLotteries.length; i++) {
            uint256 lotteryId = _openLotteries[i];
            EthertimeCommon.Lottery storage lottery = _lotteries[lotteryId];
            if (lottery.rootId == lotteryRootId) {
                if (lottery.end < now) {
                    finishLottery(lottery);
                }
                break;
            }
        }
    }
    function payOut(uint256 lotteryId) public returns (uint256) {
        EthertimeCommon.Lottery storage lottery = _lotteries[lotteryId];
        require(lottery.status == EthertimeCommon.LotteryStatus.Finished);
        require(lottery.pot > 0);        require(_lotteryParticipationIndexes[msg.sender][lotteryId].length > 0);
        require(!_payoutsCompletion[msg.sender][lotteryId]);
        uint256 playerTotalPrize = 0;
        for (uint256 i = 0; i < _lotteryParticipationIndexes[msg.sender][lotteryId].length; i++) {
            uint256 lotteryParticipationIndex = _lotteryParticipationIndexes[msg.sender][lotteryId][i];
            uint256 playerIndexInWinnings = 0;
            if (lotteryParticipationIndex >= lottery.winNumber) {
                playerIndexInWinnings = lotteryParticipationIndex.sub(lottery.winNumber);
            }
            else {
                playerIndexInWinnings = lotteryParticipationIndex.add(_players[lotteryId].length).sub(lottery.winNumber);
            }
            if (playerIndexInWinnings < lottery.winningsCount) {
                uint256 prize = EthertimeHelpers.getSingleShareOfWinnings(                    lottery.prizeType,
                    lottery.winningsCount,
                    playerIndexInWinnings
                ).mul(lottery.pot).div(EthertimeCommon.MAX_PERCENTS());
                playerTotalPrize = playerTotalPrize.add(prize);
            }
        }
        require(playerTotalPrize > 0);
        _payoutsCompletion[msg.sender][lotteryId] = true;
        lottery.remainder = lottery.remainder.sub(playerTotalPrize);
        msg.sender.transfer(playerTotalPrize);
        emit PayOutEvent(msg.sender, playerTotalPrize);
        return playerTotalPrize;
    }
    function deleteLottery(uint256 lotteryId) public onlyOwner {
        require(lotteryId <= _lastLotteryId);
        EthertimeCommon.Lottery storage lottery = _lotteries[lotteryId];
        require(lottery.status == EthertimeCommon.LotteryStatus.Open);
        require(lottery.isContinued);
        lottery.isContinued = false;
        emit DeleteLotteryEvent(lotteryId);
    }
    function createOrder(
        address recipient,
        uint256 part,
        uint256 sum,
        uint256 expiredDate
    )
        public
        onlyAdmin
    {
        require(_adminsParts[msg.sender] >= part);
        require(expiredDate > now);
        _lastOrderId = _lastOrderId.add(1);
        _orders[_lastOrderId] = Order({
            id: _lastOrderId,
            admin: msg.sender,
            recipient: recipient,
            part: part,
            sum: sum,
            expiredDate: expiredDate,
            status: OrderStatus.Open
         });
        emit NewOrderEvent(_lastOrderId, msg.sender, recipient);
    }
    function confirmOrder(uint256 orderId) public payable {
        require(orderId <= _lastOrderId);
        Order storage order = _orders[orderId];
        require(msg.sender == order.recipient);
        require(order.expiredDate > now);
        require(order.status == OrderStatus.Open);
        require(msg.value >= order.sum);
        require(order.part <= _adminsParts[order.admin]);
        if (!checkIsAdmin(msg.sender)) {
            _admins.push(msg.sender);
        }
        distributeDividend();
        _adminsParts[order.admin] = _adminsParts[order.admin].sub(order.part);
        _adminsParts[msg.sender] = _adminsParts[msg.sender].add(order.part);
        if (_adminsParts[order.admin] == 0) {
            removeAdmin(order.admin);
        }
        address payable addr = address(uint160(order.admin));
        addr.transfer(order.sum);
        uint256 remainder = msg.value.sub(order.sum);
        if (remainder > 0)
            msg.sender.transfer(remainder);
        order.status = OrderStatus.Closed;
        emit ConfirmOrderEvent(order.id);
    }
    function() external payable {
        require(msg.value > 0);
        uint256 lotteryId = None;
        uint256 price = 0;
        for (uint256 i = 0; i < _openLotteries.length; i++) {
            uint256 openLotteryId = _openLotteries[i];
            uint256 openLotteryPrice = _lotteries[openLotteryId].price;
            if (msg.value >= openLotteryPrice && openLotteryPrice > price) {
                lotteryId = openLotteryId;
                price = openLotteryPrice;
            }
        }
        if (lotteryId != None) {
            buyTicket(lotteryId);
        } else {
            revert();
        }
    }
    function getOwner() public view returns (address) {
        return _owner;
    }
    function getTotalFee() public view returns (uint256) {
        return _totalFee;
    }
    function getAdmins() public view returns (address[] memory) {
        return _admins;
    }
    function getAdminPartByAddress(address addr) public view returns (uint256) {
        return _adminsParts[addr];
    }
    function getLotteryInfo(uint256 id)
        public
        view
        returns (
            uint256 price,
            uint256 begin,
            uint256 end,
            uint256 number,
            uint256 pot,
            uint256 rootId,
            uint256 parentId,
            string memory name,
            EthertimeCommon.LotteryStatus status,
            EthertimeCommon.LotteryPrizeType prizeType,
            bool withDiscount,
            bool isContinued
        )
    {
        EthertimeCommon.Lottery memory lottery = _lotteries[id];
        return (
            lottery.price,
            lottery.begin,
            lottery.end,
            lottery.number,
            lottery.pot,
            lottery.rootId,
            lottery.parentId,
            lottery.name,
            lottery.status,
            lottery.prizeType,
            lottery.withDiscount,
            lottery.isContinued
        );
    }
    function getFinishedLotteryInfo(uint256 id)
        public
        view
        returns (
            uint256 winNumber,
            uint256 middlePlayerBlockNumber,
            uint256 previousBlockNumber,
            uint256 totalPlayers,
            uint256 winningsCount,
            bytes32 middlePlayerBlockHash,
            bytes32 previousBlockHash,
            bool middlePlayerBlockReachable
        )
    {
        EthertimeCommon.Lottery memory lottery = _lotteries[id];
        require(lottery.status == EthertimeCommon.LotteryStatus.Finished);
        uint256 middlePlayerIndex = EthertimeHelpers.getMiddlePlayerIndex(_players[id].length);
        middlePlayerBlockReachable = (
            _players[id][middlePlayerIndex].blockNumber == lottery.middlePlayerBlockNumber
        );
        return (
            lottery.winNumber,
            lottery.middlePlayerBlockNumber,
            lottery.previousBlockNumber,
            _players[id].length,
            lottery.winningsCount,
            lottery.middlePlayerBlockHash,
            lottery.previousBlockHash,
            middlePlayerBlockReachable
        );
    }
    function getLotteryPlayers(uint256 lotteryId)
        public
        view
        returns (
            address[] memory addresses,
            uint256[] memory blockNumbers,
            uint256[] memory sums
        )
    {
        require(lotteryId <= _lastLotteryId);
        EthertimeCommon.Player[] memory players = _players[lotteryId];
        addresses = new address[](players.length);
        blockNumbers = new uint256[](players.length);
        sums = new uint256[](players.length);
        for (uint256 i = 0; i < players.length; i++) {
            addresses[i] = players[i].addr;
            blockNumbers[i] = players[i].blockNumber;
            sums[i] = players[i].sum;
        }
        return (addresses, blockNumbers, sums);
    }
    function getLotteryPrizes(uint256 lotteryId)
        public
        view
        returns (uint256[] memory prizes)
    {
        EthertimeCommon.Lottery storage lottery = _lotteries[lotteryId];
        return EthertimeHelpers.getLotteryPrizes(
            lottery, _players[lottery.id].length
        );
    }
    function getOpenedLotteries() public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](_openLotteries.length);
        for (uint256 i = 0; i < _openLotteries.length; i++) {
            result[i] = _openLotteries[i];
        }
        return result;
    }
    function getPlayerLotteries(address addr)
        public
        view
        returns (
            uint256[] memory ids,
            uint256[] memory rootIds,
            uint256[] memory ends,
            uint256[] memory winNumbers,
            EthertimeCommon.LotteryStatus[] memory statuses,
            uint256[][] memory playerNumbers
        )
    {
        return EthertimeHelpers.getPlayerLotteries(
            addr, _lastLotteryId, _lotteries, _lotteryParticipationIndexes
        );
    }
    function getPlayerLotteryDetails(
        address addr,
        uint256 lotteryId
    )
        public
        view
        returns (
            uint256 totalPrize,
            bool paidOut,
            bool won
        )
    {
        require(_lotteries[lotteryId].status == EthertimeCommon.LotteryStatus.Finished);
        require(_lotteryParticipationIndexes[addr][lotteryId].length > 0);
        return EthertimeHelpers.getPlayerLotteryDetails(
            _lotteries[lotteryId],
            _players[lotteryId],
            _lotteryParticipationIndexes[addr][lotteryId],
            _payoutsCompletion[addr][lotteryId]
        );
    }
    function getFinishedLotteries()
        public
        view
        returns (uint256[] memory ids)
    {
        return EthertimeHelpers.getFinishedLotteries(_lastLotteryId, _lotteries);
    }
    function getUniquePlayersCount(
        uint256 lotteryId
    )
        public
        view
        returns (uint256)
    {
        return _lotteries[lotteryId].uniquePlayersCount;
    }
    function getOrderInfo(uint256 id)
        public
        view
        returns (
            address admin,
            address recipient,
            uint256 part,
            uint256 sum,
            uint256 expiredDate,
            OrderStatus status
        )
    {
        Order memory order = _orders[id];
        return (
            order.admin,
            order.recipient,
            order.part,
            order.sum,
            order.expiredDate,
            order.status
        );
    }
    function checkIsAdmin(address addr) private view returns (bool) {
        bool isAdmin = false;
        for (uint256 i = 0; i < _admins.length; i++) {
            if (addr == _admins[i]) {
                isAdmin = true;
                break;
            }
        }
        return isAdmin;
    }
    function removeAdmin(address addr) private {
        require(checkIsAdmin(addr));
        require(_adminsParts[addr] == 0);
        uint256 index;
        for (uint256 i = 0; i < _admins.length; i++) {
            if (_admins[i] == addr) {
                index = i;
                break;
            }
        }
        for (uint256 i = index; i < _admins.length.sub(1); i++) {
            _admins[i] = _admins[i.add(1)];
        }
        _admins.pop();
    }
    function addPlayerToLottery(
        EthertimeCommon.Lottery memory lottery,
        uint256 sum,
        address addr
    ) private {
        require(lottery.begin <= now && lottery.end >= now);
        require(lottery.status == EthertimeCommon.LotteryStatus.Open);
        EthertimeCommon.Player memory player = EthertimeCommon.Player({
            addr: addr,
            blockNumber: block.number,
            sum: sum
        });
        _lotteryParticipationIndexes[addr][lottery.id].push(_players[lottery.id].length);
        _players[lottery.id].push(player);
    }
    function createChildLottery(EthertimeCommon.Lottery storage parentLottery) private {
        if (!parentLottery.isContinued)
            return;
        uint256 period = parentLottery.end.sub(parentLottery.begin);
        uint256 begin = parentLottery.end;
        uint256 end = begin.add(period);
        if (end < now)
            (begin, end) = EthertimeHelpers.getPeriodBorders(begin, end, now);
        _lastLotteryId = _lastLotteryId.add(1);
        _lotteries[_lastLotteryId] = EthertimeCommon.Lottery({
            id: _lastLotteryId,
            name: parentLottery.name,
            owner: msg.sender,
            price: parentLottery.price,
            begin: begin,
            end: end,
            number: parentLottery.number.add(1),
            pot: 0,
            status: EthertimeCommon.LotteryStatus.Open,
            prizeType: parentLottery.prizeType,
            rootId: parentLottery.rootId,
            parentId: parentLottery.id,
            childId: None,
            isContinued: parentLottery.isContinued,
            winNumber: 0,
            middlePlayerBlockNumber: 0,
            middlePlayerBlockHash: 0x0,
            previousBlockNumber: 0,
            previousBlockHash: 0x0,
            withDiscount: parentLottery.withDiscount,
            winningsCount: None,
            uniquePlayersCount: 0,
            remainder: 0
         });
        parentLottery.childId = _lastLotteryId;
        _openLotteries.push(_lastLotteryId);
        emit NewLotteryEvent(_lastLotteryId);
    }
    function finishLottery(EthertimeCommon.Lottery storage lottery) private {
        beforeFinishLottery(lottery);
        uint256 count = lottery.uniquePlayersCount;
        if (count == 0) {
            finishEmptyLottery(lottery);
        } else if (count == 1) {
            finishOnePlayerLottery(lottery);
        } else {
            finishNotEmptyLottery(lottery);
        }
        afterFinishLottery(lottery);
    }
    function beforeFinishLottery(EthertimeCommon.Lottery storage lottery) private {
        lottery.status = EthertimeCommon.LotteryStatus.Finished;
        removeLotteryIdFromArray(lottery.id, _openLotteries);
    }
    function afterFinishLottery(EthertimeCommon.Lottery storage lottery) private {
        emit FinishedLotteryEvent(lottery.id);
        if (lottery.isContinued)
            createChildLottery(lottery);
    }
    function finishEmptyLottery(EthertimeCommon.Lottery storage lottery) private {
        lottery.status = EthertimeCommon.LotteryStatus.DidNotHappen;
    }
    function finishOnePlayerLottery(EthertimeCommon.Lottery storage lottery) private {
        require(_players[lottery.id].length > 0);
        uint256 sum = 0;
        sum = sum.add(lottery.pot);
        sum = sum.add(_reservedFee[lottery.id]);
        _reservedFee[lottery.id] = 0;
        address payable addr = address(uint160(_players[lottery.id][0].addr));
        addr.transfer(sum);
        lottery.status = EthertimeCommon.LotteryStatus.DidNotHappen;
    }
    function finishNotEmptyLottery(EthertimeCommon.Lottery storage lottery) private {
        require(lottery.end < now);
        require(_players[lottery.id].length > 1);
        (
            lottery.winNumber,
            lottery.middlePlayerBlockNumber,
            lottery.middlePlayerBlockHash,
            lottery.previousBlockNumber,
            lottery.previousBlockHash
        ) = EthertimeHelpers.getWinNumber(_players[lottery.id]);
        lottery.winningsCount = EthertimeHelpers.getWinningsCount(
            lottery.prizeType,
            _players[lottery.id].length
        );
        lottery.remainder = lottery.pot;
        _totalFee = _totalFee.add(_reservedFee[lottery.id]);
    }
    function incUniquePlayersCount(uint256 lotteryId, address addr) private {
        EthertimeCommon.Lottery storage lottery = _lotteries[lotteryId];
        if (_lotteryParticipationIndexes[addr][lotteryId].length == 0)
           lottery.uniquePlayersCount = lottery.uniquePlayersCount.add(1);
    }
    function removeLotteryIdFromArray(
        uint256 lotteryId,
        uint256[] storage array
    ) private {
        bool exists = false;
        uint256 index;
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == lotteryId) {
                index = i;
                exists = true;
                break;
            }
        }
        require(exists);
        for (uint256 i = index; i < array.length.sub(1); i++) {
            array[i] = array[i.add(1)];
        }
        array.pop();
    }
}pragma solidity >=0.5.16 <0.6.0;
library EthertimeCommon {
   function MAX_PERCENTS() internal pure returns (uint256) {
      return 1000000000;
   }
    enum LotteryPrizeType {
        T10,        T30,        T50,        All,        First,        Three    }
    enum LotteryStatus {
        Open,        Finished,        DidNotHappen    }
    struct Player {
        address addr;
        uint256 blockNumber;
        uint256 sum;
    }
    struct Lottery {
        uint256 id;
        string name;
        uint256 price;
        uint256 begin;
        uint256 end;
        uint256 number;
        uint256 pot;
        uint256 rootId;
        uint256 parentId;
        uint256 childId;
        uint256 winNumber;
        uint256 middlePlayerBlockNumber;
        uint256 previousBlockNumber;
        uint256 winningsCount;
        uint256 remainder;
        uint256 uniquePlayersCount;
        bytes32 middlePlayerBlockHash;
        bytes32 previousBlockHash;
        address owner;
        LotteryStatus status;
        LotteryPrizeType prizeType;
        bool withDiscount;
        bool isContinued;
    }
}pragma solidity >=0.5.16 <0.6.0;
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}pragma solidity >=0.5.16 <0.6.0;
library EthertimeHelpers {
    using SafeMath for *;
    uint256 constant MAX_RECENT_BLOCK_NUMBER = 250;
    function getShareOfWinnings(EthertimeCommon.LotteryPrizeType prizeType, uint256 n)
        public
        pure
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](n);
        if (prizeType == EthertimeCommon.LotteryPrizeType.Three) {
            require(n == 1 || n == 3);
            if (n == 1) {
                result[0] = EthertimeCommon.MAX_PERCENTS();
            } else {
                result[0] = EthertimeCommon.MAX_PERCENTS().mul(50).div(100);
                result[1] = EthertimeCommon.MAX_PERCENTS().mul(35).div(100);
                result[2] = EthertimeCommon.MAX_PERCENTS().mul(15).div(100);
            }
        } else {
            uint256 divider = n.mul(n.add(1));
            for (uint256 k = 0; k < n; k++) {
                uint256 p = (n.sub(k)).mul(EthertimeCommon.MAX_PERCENTS().mul(2));
                p = p.div(divider);
                result[k] = p;
            }
        }
        return result;
    }
    function getSingleShareOfWinnings(EthertimeCommon.LotteryPrizeType prizeType, uint256 n, uint256 i)
        public
        pure
        returns (uint256 result)
    {
        require(i < n);
        if (prizeType == EthertimeCommon.LotteryPrizeType.Three) {
            require(n == 1 || n == 3);
            if (n == 1) {
                result = EthertimeCommon.MAX_PERCENTS();
            } else {                if (i == 0) {
                    result = EthertimeCommon.MAX_PERCENTS().mul(50).div(100);
                }
                else if (i == 1) {
                    result = EthertimeCommon.MAX_PERCENTS().mul(35).div(100);
                }
                else {
                    result = EthertimeCommon.MAX_PERCENTS().mul(15).div(100);
                }
            }
        } else {
            uint256 divider = n.mul(n.add(1));
            result = (n.sub(i)).mul(EthertimeCommon.MAX_PERCENTS().mul(2)).div(divider);
        }
        return result;
    }
    function splitPeriod(uint256 begin, uint256 end)
        internal
        pure
        returns (uint256, uint256, uint256)
    {
        require(begin < end);
        uint256 step = (end.sub(begin)).div(4);
        uint256 b1 = begin.add(step);
        uint256 b2 = b1.add(step);
        uint256 b3 = b2.add(step);
        return (b1, b2, b3);
    }
    function getMiddlePlayerIndex(uint256 playersCount)
        internal
        pure
        returns (uint256)
    {
        return playersCount.add(1).div(2);
    }
    function getWinNumber(EthertimeCommon.Player[] storage lotteryPlayers)
        external
        view
        returns (uint256, uint256, bytes32, uint256, bytes32)
    {
        uint256 playersCount = lotteryPlayers.length;
        uint256 middlePlayerIndex = getMiddlePlayerIndex(playersCount);
        uint256 middlePlayerBlockNumber = lotteryPlayers[middlePlayerIndex].blockNumber;
        if (block.number.sub(middlePlayerBlockNumber) > MAX_RECENT_BLOCK_NUMBER)
            middlePlayerBlockNumber = block.number.sub(
                MAX_RECENT_BLOCK_NUMBER
            ).add(
                playersCount.mod(MAX_RECENT_BLOCK_NUMBER.sub(1))
            );
        bytes32 middlePlayerBlockHash = blockhash(middlePlayerBlockNumber);
        uint256 previousBlockNumber = block.number.sub(1);
        bytes32 previousBlockHash = blockhash(previousBlockNumber);
        return (
            uint256(keccak256(
                abi.encodePacked(middlePlayerBlockHash ^ previousBlockHash)
            )).mod(playersCount),
            middlePlayerBlockNumber,
            middlePlayerBlockHash,
            previousBlockNumber,
            previousBlockHash
        );
    }
    function getPeriodBorders(uint256 begin, uint256 end, uint256 currentTime)
        external
        pure
        returns (uint256, uint256)
    {
        if (end < currentTime) {
            uint256 period = end.sub(begin);
            uint256 n = currentTime.sub(end);
            n = n.div(period);
            n = n.add(1);
            uint256 delta = n.mul(period);
            return (begin.add(delta), end.add(delta));
        }
        return (begin, end);
    }
    function getWinningsCount(
        EthertimeCommon.LotteryPrizeType prizeType,
        uint256 playersCount
    )
        public
        pure
        returns (uint256)
    {
        uint256 result;
        if (prizeType == EthertimeCommon.LotteryPrizeType.Three) {
            if (playersCount < 3)
                result = 1;
            else
                result = 3;
        } else {
            uint256 remainder = 0;
            if (prizeType == EthertimeCommon.LotteryPrizeType.First) {
                result = 1;
            } else if (prizeType == EthertimeCommon.LotteryPrizeType.All) {
                result = playersCount;
            } else if (prizeType == EthertimeCommon.LotteryPrizeType.T10) {
                remainder = playersCount.mod(10);
                result = playersCount.div(10);
            } else if (prizeType == EthertimeCommon.LotteryPrizeType.T30) {
                result = playersCount.mul(30);
                remainder = result.mod(100);
                result = result.div(100);
            } else if (prizeType == EthertimeCommon.LotteryPrizeType.T50) {
                result = playersCount.mul(50);
                remainder = result.mod(100);
                result = result.div(100);
            } else {
                revert();
            }
            if (remainder > 0 && result < playersCount) {
                result = result.add(1);
            }
        }
        return result;
    }
    function getActualLotteryPrice(
        bool withDiscount,
        uint256 price,
        uint256 begin,
        uint256 end
    )
        external
        view
        returns (uint256)
    {
        if (!withDiscount)
            return price;
        uint256 discount = 0;
        uint256 percent = 0;
        (uint256 b1, uint256 b2, uint256 b3) = splitPeriod(begin, end);
        if (begin <= now && now < b1) {
            percent = EthertimeCommon.MAX_PERCENTS().mul(3).div(100);
        } else if (b1 <= now && now < b2) {
            percent = EthertimeCommon.MAX_PERCENTS().mul(2).div(100);
        } else if (b2 <= now && now < b3) {
            percent = EthertimeCommon.MAX_PERCENTS().mul(1).div(100);
        }
        discount = price.mul(percent).div(EthertimeCommon.MAX_PERCENTS());
        return price.sub(discount);
    }
    function getPlayerLotteries(
        address addr,
        uint256 lastLotteryId,
        mapping (uint256 => EthertimeCommon.Lottery) storage _lotteries,
        mapping (address => mapping (uint256 => uint256[])) storage _lotteryParticipationIndexes
    )
        external
        view
        returns (
            uint256[] memory ids,
            uint256[] memory rootIds,
            uint256[] memory ends,
            uint256[] memory winNumbers,
            EthertimeCommon.LotteryStatus[] memory statuses,
            uint256[][] memory playerNumbers
        )
    {
        uint256 participationCount = 0;
        for (uint256 id = 1; id <= lastLotteryId; id++) {
            if (_lotteryParticipationIndexes[addr][id].length > 0){
                participationCount = participationCount.add(1);
            }
        }
        ids = new uint256[](participationCount);
        rootIds = new uint256[](participationCount);
        ends = new uint256[](participationCount);
        winNumbers = new uint256[](participationCount);
        statuses = new EthertimeCommon.LotteryStatus[](participationCount);
        playerNumbers = new uint256[][](participationCount);
        uint256 row = 0;
        for (uint256 id = 1; id <= lastLotteryId; id++) {
            if (_lotteryParticipationIndexes[addr][id].length > 0) {
                EthertimeCommon.Lottery storage lottery = _lotteries[id];
                ids[row] = id;
                rootIds[row] = lottery.rootId;
                ends[row] = lottery.end;
                winNumbers[row] = lottery.winNumber;
                statuses[row] = lottery.status;
                playerNumbers[row] = _lotteryParticipationIndexes[addr][id];
                row = row.add(1);
            }
        }
        return (ids, rootIds, ends, winNumbers, statuses, playerNumbers);
    }
    function getPlayerLotteryDetails(
        EthertimeCommon.Lottery storage lottery,
        EthertimeCommon.Player[] storage players,
        uint256[] storage lotteryParticipationIndexes,
        bool payoutComplete
    )
        external
        view
        returns (
            uint256 totalPrize,
            bool paidOut,
            bool won
        )
    {
        uint256[] memory shareOfWinnings = getShareOfWinnings(
            lottery.prizeType, lottery.winningsCount
        );
        for (uint256 i = 0; i < lotteryParticipationIndexes.length; i++) {
            uint256 lotteryParticipationIndex = lotteryParticipationIndexes[i];
            uint256 playerIndexInWinnings = 0;
            if (lotteryParticipationIndex >= lottery.winNumber) {
                playerIndexInWinnings = lotteryParticipationIndex.sub(lottery.winNumber);
            }
            else {
                playerIndexInWinnings = lotteryParticipationIndex.add(players.length).sub(lottery.winNumber);
            }
            if (playerIndexInWinnings < lottery.winningsCount) {
                won = true;
                totalPrize = totalPrize
                    .add(shareOfWinnings[playerIndexInWinnings]
                    .mul(lottery.pot)
                    .div(EthertimeCommon.MAX_PERCENTS()));
            }
        }
        return (totalPrize, payoutComplete, won);
    }
    function getFinishedLotteries(
        uint256 lastLotteryId,
        mapping (uint256 => EthertimeCommon.Lottery) storage _lotteries
    )
        public
        view
        returns (uint256[] memory ids)
    {
        uint256 finishedLotteriesCount = 0;
        for (uint256 id = 1; id <= lastLotteryId; id++) {
            EthertimeCommon.Lottery memory lottery = _lotteries[id];
            if (lottery.status != EthertimeCommon.LotteryStatus.Open) {
                finishedLotteriesCount = finishedLotteriesCount.add(1);
            }
        }
        ids = new uint256[](finishedLotteriesCount);
        uint256 r = 0;
        for (uint256 id = 1; id <= lastLotteryId; id++) {
            EthertimeCommon.Lottery memory lottery = _lotteries[id];
            if (lottery.status != EthertimeCommon.LotteryStatus.Open) {
                ids[r] = id;
                r = r.add(1);
            }
        }
        return ids;
    }
    function getLotteryPrizes(
        EthertimeCommon.Lottery storage lottery,
        uint256 playersCount
    )
        public
        view
        returns (uint256[] memory prizes)
    {
        uint256 winningsCount = getWinningsCount(lottery.prizeType, playersCount);
        prizes = new uint256[](winningsCount);
        uint256[] memory shareOfWinnings = getShareOfWinnings(
            lottery.prizeType, winningsCount
        );
        for (uint256 i = 0; i < shareOfWinnings.length; i++) {
            prizes[i] = shareOfWinnings[i].mul(lottery.pot).div(EthertimeCommon.MAX_PERCENTS());
        }
        return prizes;
    }
    function getActualLotteryId(
        uint256 lotteryId,
        mapping (uint256 => EthertimeCommon.Lottery) storage _lotteries,
        uint256[] storage _openLotteries
    )
        public
        view
        returns (uint256)
    {
        EthertimeCommon.Lottery memory lottery = _lotteries[lotteryId];
        if (lottery.status == EthertimeCommon.LotteryStatus.Open) {
            return lottery.id;        } else {
            for (uint256 i = 0; i < _openLotteries.length; i++) {
                EthertimeCommon.Lottery memory openLottery = (
                    _lotteries[_openLotteries[i]]
                );
                if (openLottery.rootId == lottery.rootId) {
                    return openLottery.id;
                }
            }
        }
        revert();
    }
}