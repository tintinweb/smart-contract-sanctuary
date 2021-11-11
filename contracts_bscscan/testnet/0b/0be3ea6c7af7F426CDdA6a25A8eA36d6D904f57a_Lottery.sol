// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/IGateway.sol";
import "./interfaces/ILotteryPrize.sol";
import "./interfaces/IRandomNumberGenerator.sol";

/**
 * @title Lottery
 * @dev Implements noloss lottery and earn profit from deposit amount
 */
contract Lottery is PausableUpgradeable, OwnableUpgradeable {

    uint private constant TICKET_MULTIPLIER = 1e12;
    uint private constant MAX_TREE_LEAVES = 5;
    uint private constant ONE_HUNDRED_PERCENT = 10000; // 100%

    uint private constant LOTTERY_OPENED = 1;
    uint private constant LOTTERY_CLOSED = 2;

    uint public roundTime;
    uint public expirePrizeTime;
    address public operator;
    uint public systemFeePercent;
    address public prizePool;
    uint public fairplayTimelock;
    uint public penaltyFeePercent;
    uint public currentRound;
    uint public totalPoolWeight;
    uint public ticketPerBlock;
    address public rng;

    struct SortitionSumTree {
        uint k;
        uint[] stack;
        uint[] nodes;
        mapping(bytes32 => uint) nodeIndexes;
        mapping(uint => bytes32) nodeIds;
    }

    struct Prize {
        address erc20;
        uint amount;
    }

    struct PrizeType {
        uint percent;
        uint n; // number of prizes
        address[] winners;
    }

    struct Round {
        Prize[] prizes;
        PrizeType[] prizeTypes;
        uint status;
        uint startAt;
        uint prizeExpireIn;
        mapping(address => bool) isTaken;
    }

    struct Pool {
        IGateway gateway;
        string name;
        uint poolWeight;
        bool status; // true: enable, false: disable
        uint totalCBalance;
        uint totalPoint;
        uint accTicketPerPoint;
        uint lastTicketBlock;
    }

    struct User {
        uint balance;
        uint cBalance;
        uint depositAt;
        uint ticket;
        uint point;
        uint ticketDebt;
    }

    modifier onlyOperator() {
        require(_msgSender() == owner() || _msgSender() == operator, "Lottery: no permission");
        _;
    }

    Pool[] public pools;

    mapping(address => uint) public poolIds; // pool token => pool id

    mapping(uint => Round) private _rounds; // round id => round information;

    mapping(address => mapping(address => User)) public users; // pool token => user wallet => user information

    mapping(address => uint) public pendingPrizeAmounts;

    address[] private _prizeTokens;

    PrizeType[] private _prizeTypes;

    SortitionSumTree private _sumTree;

    event Initialize(address _operator, address _prizePool, uint _ticketPerBlock);
    event Withdraw(address _user, address _token, uint _amount);
    event Deposit(address _user, address _token, uint _amount);
    event AddPool(string _name, address _gateway, address _token, uint _weight);
    event UpdatePoolWeight(uint _poolId, uint _weight);
    event UpdatePoolStatus(uint _poolId, bool _status);
    event UpdateTicketPerBlock(uint _ticketPerBlock);
    event OpenRound(uint _roundId);
    event CalculatePrizes(uint _roundId);
    event HandleExpirePrize(uint _roundId);
    event ClaimPrize(address _user, uint _roundId);
    event SetOperator(address _operator);
    event SetRoundTime(uint _seconds);
    event SetExpirePrizeTime(uint _seconds);
    event SetFee(uint _systemFeePercent, uint _penaltyFeePercent);
    event SetFairplayTimelock(uint _seconds);
    event SetPrizeTokens(address[] _tokens);
    event SetPrizeTypes(uint[] percent, uint[] n);

    function initialize(address _operator, address _rng, address _prizePool, uint _ticketPerBlock) public initializer {
        __Ownable_init();

        currentRound++;

        roundTime = 1 weeks;
        expirePrizeTime = 14 days;

        operator = _operator;
        rng = _rng;
        prizePool = _prizePool;
        ticketPerBlock = _ticketPerBlock;

        _createSumTree();

        emit Initialize(_operator, _prizePool, _ticketPerBlock);
    }

    function withdrawableAmount(address _user, address _token) public view returns (uint) {
        Pool memory pool = pools[poolIds[_token] - 1];

        return users[_token][_user].cBalance * pool.gateway.getTotalLock() / pool.totalCBalance;
    }

    function withdrawableAmountAfterFee(address _user, address _token) public view returns (uint amount, uint penaltyFee) {
        amount = withdrawableAmount(_user, _token);

        penaltyFee = (block.timestamp - users[_token][_user].depositAt) >= fairplayTimelock ? 0 : penaltyFeePercent * amount / ONE_HUNDRED_PERCENT;

        amount -= penaltyFee;
    }

    function withdraw(address _token) public {
        uint poolId = poolIds[_token];

        Pool storage pool = pools[poolId - 1];

        address msgSender = _msgSender();

        User storage user = users[_token][msgSender];

        require(user.balance > 0, "Lottery: balance is zero");

        updateTicketPool(poolId);

        (uint amount, uint penaltyFee) = withdrawableAmountAfterFee(msgSender, _token);

        pool.gateway.withdraw(msgSender, amount, prizePool, penaltyFee);

        pool.totalCBalance -= user.cBalance;

        // Gets ticket rewards
        uint pendingTicket = _pointToTicket(user.point, pool.accTicketPerPoint) - user.ticketDebt;

        if (pendingTicket > 0) {
            user.ticket += pendingTicket;
        }

        pool.totalPoint -= user.point;

        if (user.ticket != 0 && pool.totalPoint != 0) {
            // Divides ticket to the remaining users
            pool.accTicketPerPoint += _ticketToPoint(user.ticket, pool.totalPoint);
        }

        delete users[_token][msgSender];

        _setSumTreeNode(0, getSumTreeNodeId(msgSender));

        emit Withdraw(msgSender, _token, amount);
    }

    function _ticketToPoint(uint _ticket, uint _ticketPerPoint) private pure returns (uint) {
        return (_ticket * TICKET_MULTIPLIER) / _ticketPerPoint;
    }

    function _pointToTicket(uint _point, uint _ticketPerPoint) private pure returns (uint) {
        return (_point * _ticketPerPoint) / TICKET_MULTIPLIER;
    }

    function massUpdateTicketPools() public {
        uint length = pools.length;

        for (uint i = 1; i <= length; i++) {
            updateTicketPool(i);
        }
    }

    function updateTicketPool(uint _poolId) public {
        Pool storage pool = pools[_poolId - 1];

        if (block.number <= pool.lastTicketBlock) {
            return;
        }

        uint totalPoint = pool.totalPoint;

        if (totalPoint == 0 || pool.poolWeight == 0) {
            pool.lastTicketBlock = block.number;
            return;
        }

        uint numTickets = (block.number - pool.lastTicketBlock) * ticketPerBlock * pool.poolWeight / totalPoolWeight;

        pool.accTicketPerPoint += _ticketToPoint(numTickets, totalPoint);
        pool.lastTicketBlock = block.number;
    }

    function deposit(address _token, uint _amount) public whenNotPaused { // token is approved to gateway contract
        require(_amount > 0, "Lottery: amount is zero");

        uint poolId = poolIds[_token];

        Pool storage pool = pools[poolId - 1];

        require(pool.status, "Lottery: pool is disabled");

        updateTicketPool(poolId);

        address msgSender = _msgSender();

        User storage user = users[_token][msgSender];

        user.depositAt = block.timestamp;
        user.balance += _amount;

        uint cBalance = pool.totalCBalance == 0 ? _amount : _amount * pool.totalCBalance / pool.gateway.getTotalLock();
        user.cBalance += cBalance;
        pool.totalCBalance += cBalance;

        if (user.point > 0) {
            // Gets ticket rewards
            uint pendingTicket = _pointToTicket(user.point, pool.accTicketPerPoint) - user.ticketDebt;

            if (pendingTicket > 0) {
                user.ticket += pendingTicket;
            }
        }

        uint point = pool.gateway.getTokenPrice(_amount);
        user.point += point;
        user.ticketDebt = _pointToTicket(user.point, pool.accTicketPerPoint);
        pool.totalPoint += point;

        pool.gateway.deposit(msgSender, _amount);

        _setSumTreeNode(user.point, getSumTreeNodeId(msgSender));

        emit Deposit(msgSender, _token, _amount);
    }

    function addPool(IGateway _gateway, string memory _name, uint _weight) public onlyOwner {
        address token = _gateway.erc20();

        require(poolIds[token] == 0, "Lottery: token has added");

        massUpdateTicketPools();

        pools.push(Pool({
            gateway: _gateway,
            name: _name,
            poolWeight: _weight,
            status: true,
            totalCBalance: 0,
            totalPoint: 0,
            accTicketPerPoint: 0,
            lastTicketBlock: block.number
        }));

        poolIds[token] = pools.length;

        totalPoolWeight += _weight;

        emit AddPool(_name, address(_gateway), token, _weight);
    }

    function getPools() public view returns (Pool[] memory) {
        return pools;
    }

    function updatePoolWeight(uint _poolId, uint _weight) public onlyOwner {
        Pool storage pool = pools[_poolId - 1];

        massUpdateTicketPools();

        totalPoolWeight = totalPoolWeight - pool.poolWeight + _weight;

        pool.poolWeight = _weight;

        emit UpdatePoolWeight(_poolId, _weight);
    }

    function updatePoolStatus(uint _poolId, bool _status) public onlyOwner {
        Pool storage pool = pools[_poolId - 1];

        pool.status = _status;

        emit UpdatePoolStatus(_poolId, _status);
    }

    function updateTicketPerBlock(uint _ticketPerBlock) public onlyOwner {
        massUpdateTicketPools();

        ticketPerBlock = _ticketPerBlock;

        emit UpdateTicketPerBlock(_ticketPerBlock);
    }

    function getTicket(address _user, address _token) public view returns (uint) {
        Pool memory pool = pools[poolIds[_token] - 1];

        User memory user = users[_token][_user];

        uint accTicketPerPoint = pool.accTicketPerPoint;

        if (block.number > pool.lastTicketBlock && pool.totalPoint != 0 && pool.poolWeight != 0) {
            uint numTickets = (block.number - pool.lastTicketBlock) * ticketPerBlock * pool.poolWeight / totalPoolWeight;

            accTicketPerPoint += _ticketToPoint(numTickets, pool.totalPoint);
        }

        return _pointToTicket(user.point, accTicketPerPoint) - user.ticketDebt + user.ticket;
    }

    function openRound() public onlyOperator {
        Round storage round = _rounds[currentRound];

        require(round.status == 0, "Lottery: current round is running");

        require(_prizeTokens.length > 0 && _prizeTypes.length > 0, "Lottery: prize tokens and prize types is required");

        for (uint i = 0; i < _prizeTokens.length; i++) {
            round.prizes.push(Prize(_prizeTokens[i], 0));
        }

        for (uint i = 0; i < _prizeTypes.length; i++) {
            round.prizeTypes.push(_prizeTypes[i]);
        }

        round.status = LOTTERY_OPENED;
        round.startAt = block.timestamp;
        round.prizeExpireIn = expirePrizeTime;

        emit OpenRound(currentRound);
    }

    function calculatePrizes() public onlyOperator {
        Round storage round = _rounds[currentRound];

        require(round.status == LOTTERY_OPENED, "Lottery: current round is not running");

        require(block.timestamp - round.startAt >= roundTime, "Lottery: not meet round time");

        _calculatePrizeAmount();

        _calculateWinners();

        round.status = LOTTERY_CLOSED;

        emit CalculatePrizes(currentRound);

        currentRound++;
    }

    function token2USD(address _token, uint _amount) public view returns(uint) {
        uint poolId = poolIds[_token];
        Pool memory pool = pools[poolId - 1];
        return pool.gateway.getTokenPrice(_amount);
    }

    function _calculatePrizeAmount() private {
        Round storage round = _rounds[currentRound];

        uint numPrizes = round.prizes.length;

        address[] memory erc20s;

        for (uint i = 0; i < numPrizes; i++) {
            erc20s[i] = round.prizes[i].erc20;
        }

        uint[] memory amounts = ILotteryPrize(prizePool).getTotalPrize(erc20s);

        for (uint i = 0; i < numPrizes; i++) {
            round.prizes[i].amount = amounts[i] - pendingPrizeAmounts[erc20s[i]];
        }
    }

    function _calculateWinners() private {
        Round storage round = _rounds[currentRound];

        IRandomNumberGenerator generator = IRandomNumberGenerator(rng);

        bytes32 requestId = generator.getRandomNumber();

        uint random = generator.randoms(requestId);

        PrizeType[] storage prizeTypes = round.prizeTypes;

        for (uint i = 0; i < prizeTypes.length; i++) {
            PrizeType storage prizeType = prizeTypes[i];

            for (uint j = 0; j < prizeType.n; j++) {
                random = uint(keccak256(abi.encode(random)));

                address winner = address(uint160(uint(_drawSumTree(random))));

                prizeType.winners.push(winner);
            }
        }
    }

    function isExpirePrize(uint _roundId) public view returns (bool) {
        Round storage round = _rounds[_roundId];

        return round.status == LOTTERY_CLOSED && block.timestamp - round.startAt > round.prizeExpireIn;
    }

    function handleExpirePrize(uint _roundId) public {
        require(isExpirePrize(_roundId), "Lottery: prize is not expired");

        Round storage round = _rounds[_roundId];

        Prize[] memory prizes = round.prizes;
        PrizeType[] memory prizeTypes = round.prizeTypes;

        for (uint i = 0; i < prizeTypes.length; i++) {
            PrizeType memory prizeType = prizeTypes[i];

            for (uint j = 0; j < prizeType.winners.length; j++) {
                if (round.isTaken[prizeType.winners[j]]) {
                    continue;
                }

                pendingPrizeAmounts[prizes[i].erc20] -= (prizeType.percent * prizes[i].amount / ONE_HUNDRED_PERCENT);
            }
        }

        emit HandleExpirePrize(_roundId);
    }

    function harvest(address _token) public {
        pools[poolIds[_token] - 1].gateway.harvest(prizePool, systemFeePercent);
    }

    function claimPrizes(uint[] memory _roundIds) public {
        address msgSender = _msgSender();

        for (uint index = 0; index < _roundIds.length; index++) {
            uint roundId = _roundIds[index];

            require(!isExpirePrize(roundId), "Lottery: prize is expired");

            Round storage round = _rounds[roundId];

            require(!round.isTaken[msgSender], "Lottery: claimed");

            Prize[] memory prizes = round.prizes;
            PrizeType[] memory prizeTypes = round.prizeTypes;

            address[] memory accounts;
            uint[] memory percents;

            for (uint i = 0; i < prizeTypes.length; i++) {
                PrizeType memory prizeType = prizeTypes[i];

                for (uint j = 0; j < prizeType.winners.length; j++) {
                    if (prizeType.winners[j] == msgSender) {
                        accounts[accounts.length] = msgSender;
                        percents[percents.length] = prizeType.percent;
                    }
                }
            }

            require(accounts.length > 0, "Lottery: not win this round");

            for (uint i = 0; i < prizes.length; i++) {
                for (uint j = 0; j < accounts.length; j++) {
                    uint amount = percents[j] * prizes[i].amount / ONE_HUNDRED_PERCENT;

                    IERC20(prizes[i].erc20).transferFrom(prizePool, accounts[j], amount);

                    pendingPrizeAmounts[prizes[i].erc20] -= amount;
                }
            }

            round.isTaken[msgSender] = true;

            emit ClaimPrize(msgSender, roundId);
        }
    }

    function setFee(uint _systemFeePercent, uint _penaltyFeePercent) public onlyOwner {
        systemFeePercent = _systemFeePercent;
        penaltyFeePercent = _penaltyFeePercent;

        emit SetFee(_systemFeePercent, _penaltyFeePercent);
    }

    function setOperator(address _operator) public onlyOwner {
        operator = _operator;

        emit SetOperator(_operator);
    }

    function setRoundTime(uint _seconds) public onlyOwner {
        roundTime = _seconds;

        emit SetRoundTime(_seconds);
    }

    function setExpirePrizeTime(uint _seconds) public onlyOwner {
        expirePrizeTime = _seconds;

        emit SetExpirePrizeTime(_seconds);
    }

    function setFairplayTimelock(uint _seconds) public onlyOwner {
        fairplayTimelock = _seconds;

        emit SetFairplayTimelock(_seconds);
    }

    function setPrizeTokens(address[] memory _tokens) public onlyOwner {
        delete _prizeTokens;

        for (uint i = 0; i < _tokens.length; i++) {
            require(_tokens[i] != address(0), "Lottery: address is invalid");

            _prizeTokens.push(_tokens[i]);
        }

        emit SetPrizeTokens(_tokens);
    }

    function setPrizeTypes(uint[] memory percent, uint[] memory n) public onlyOwner {
        delete _prizeTypes;

        for (uint i = 0; i < percent.length; i++) {
            require(percent[i] <= ONE_HUNDRED_PERCENT && n[i] > 0, "Lottery: params is invalid");

            PrizeType memory prizeType;
            prizeType.percent = percent[i];
            prizeType.n = n[i];

            _prizeTypes.push(prizeType);
        }

        emit SetPrizeTypes(percent, n);
    }

    function getPrizeTypes() public view returns(PrizeType[] memory) {
        return _prizeTypes;
    }

    function getPrizeTokens() public view returns(address[] memory) {
        return _prizeTokens;
    }

    function isTakenPrize(uint _roundId, address _user) public view returns(bool) {
        return _rounds[_roundId].isTaken[_user];
    }

    function getRound(uint roundId) public view returns(Prize[] memory, PrizeType[] memory, uint, uint, uint) {
        Round storage round = _rounds[roundId];

        return (round.prizes, round.prizeTypes, round.status, round.startAt, round.prizeExpireIn);
    }

    function getTotalPrizeOfCurrentRound() public view returns(uint[] memory _balances){
        Round storage round = _rounds[currentRound];
        uint numPrizes = round.prizes.length;

        address[] memory erc20s;

        for (uint i = 0; i < numPrizes; i++) {
            erc20s[i] = round.prizes[i].erc20;
        }

        uint[] memory amounts = ILotteryPrize(prizePool).getTotalPrize(erc20s);

        for (uint i = 0; i < numPrizes; i++) {
            _balances[i] = amounts[i] - pendingPrizeAmounts[erc20s[i]];
        }
    }

    function poolLength() public view returns(uint) {
        return pools.length;
    }

    function _createSumTree() private {
        _sumTree.k = MAX_TREE_LEAVES;
        _sumTree.stack = new uint[](0);
        _sumTree.nodes = new uint[](0);
        _sumTree.nodes.push(0);
    }

    function _setSumTreeNode(uint _value, bytes32 _id) private {
        uint treeIndex = Math.min(_sumTree.nodeIndexes[_id], _sumTree.nodes.length - 1);

        if (treeIndex == 0) {
            if (_value != 0) {
                if (_sumTree.stack.length == 0) {
                    treeIndex = _sumTree.nodes.length;

                    _sumTree.nodes.push(_value);

                    if (treeIndex != 1 && (treeIndex - 1) % _sumTree.k == 0) {
                        uint parentIndex = treeIndex / _sumTree.k;
                        bytes32 parentId = _sumTree.nodeIds[parentIndex];
                        uint newIndex = treeIndex + 1;

                        _sumTree.nodes.push(_sumTree.nodes[parentIndex]);

                        delete _sumTree.nodeIds[parentIndex];

                        _sumTree.nodeIndexes[parentId] = newIndex;
                        _sumTree.nodeIds[newIndex] = parentId;
                    }
                } else {
                    treeIndex = _sumTree.stack[_sumTree.stack.length - 1];

                    _sumTree.stack.pop();
                    _sumTree.nodes[treeIndex] = _value;
                }

                _sumTree.nodeIndexes[_id] = treeIndex;
                _sumTree.nodeIds[treeIndex] = _id;

                _updateSumTreeParentNodes(treeIndex, true, _value);
            }
        } else {
            if (_value == 0) {
                uint value = _sumTree.nodes[treeIndex];

                _sumTree.nodes[treeIndex] = 0;
                _sumTree.stack.push(treeIndex);

                delete _sumTree.nodeIndexes[_id];
                delete _sumTree.nodeIds[treeIndex];

                _updateSumTreeParentNodes(treeIndex, false, value);
            } else if (_value != _sumTree.nodes[treeIndex]) { // New, non zero value.
                bool plusOrMinus = _sumTree.nodes[treeIndex] <= _value;
                uint plusOrMinusValue = plusOrMinus ? _value - _sumTree.nodes[treeIndex] : _sumTree.nodes[treeIndex] - _value;

                _sumTree.nodes[treeIndex] = _value;

                _updateSumTreeParentNodes(treeIndex, plusOrMinus, plusOrMinusValue);
            }
        }
    }

    function _drawSumTree(uint _drawnNumber) private returns (bytes32 id) {
        uint treeIndex = 0;
        uint currentDrawnNumber = _drawnNumber % _sumTree.nodes[0];
        uint totalNodes = _sumTree.nodes.length;
        uint k = _sumTree.k;

        while ((k * treeIndex) + 1 < totalNodes) {
            for (uint i = 1; i <= k; i++) {
                uint nodeIndex = (k * treeIndex) + i;
                uint nodeValue = _sumTree.nodes[nodeIndex];

                if (currentDrawnNumber >= nodeValue) {
                    currentDrawnNumber -= nodeValue;
                } else {
                    treeIndex = nodeIndex;
                    break;
                }
            }
        }

        id = _sumTree.nodeIds[treeIndex];

        _sumTree.nodes[treeIndex] = 0;
    }

    function getSumTreeNodeValue(bytes32 _id) public view returns (uint value) {
        uint treeIndex = Math.min(_sumTree.nodeIndexes[_id], _sumTree.nodes.length - 1);

        if (treeIndex == 0) {
            value = 0;
        } else {
            value = _sumTree.nodes[treeIndex];
        }
    }

    function getSumTreeNodeId(address _account) public pure returns (bytes32 id) {
        id = bytes32(uint(uint160(_account)));
    }

    function _updateSumTreeParentNodes(uint _treeIndex, bool _plusOrMinus, uint _value) private {
        uint k = _sumTree.k;
        uint parentIndex = _treeIndex;

        while (parentIndex != 0) {
            parentIndex = (parentIndex - 1) / k;

            _sumTree.nodes[parentIndex] = _plusOrMinus ? _sumTree.nodes[parentIndex] + _value : _sumTree.nodes[parentIndex] - _value;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGateway {
    function deposit(address _from, uint _amount) external;
    function withdraw(address _account, uint _amount, address _prizePool, uint _penaltyFee) external;
    function getTotalLock() external view returns (uint);
    function getTokenPrice(uint _erc20Amount) external view returns (uint);
    function harvest(address _prizePool, uint _systemFeePercent) external;
    function erc20() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILotteryPrize {
    function getTotalPrize(address[] memory _erc20s) external view returns(uint[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRandomNumberGenerator {
    function getRandomNumber() external returns (bytes32);
    function randoms(bytes32 requestId) external returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}