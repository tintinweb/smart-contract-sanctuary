// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library Math {

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library PotConstant {
    enum PotState {
        Opened,
        Closed,
        Cooked
    }

    struct PotInfo {
        uint potId;
        PotState state;
        uint supplyCurrent;
        uint supplyDonation;
        uint rewards;
        uint minAmount;
        uint maxAmount;
        uint avgOdds;
        uint startedAt;
    }

    struct PotInfoMe {
        uint wTime;
        uint wCount;
        uint wValue;
        uint odds;
        uint available;
        uint lastParticipatedPot;
        uint depositedAt;
    }

    struct PotHistory {
        uint potId;
        uint users;
        uint rewardPerWinner;
        uint date;
        address[] winners;
    }
}

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IVenusStrategy {
    function withdraw(uint256 amountUnderlying, address to) external;

    function deposit(uint256 _amount) external;

    function currentInvestedUnderlyingBalance() external returns (uint256);

    function claimAll(address to) external returns (uint256);
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

library SortitionSumTreeFactory {

    struct SortitionSumTree {
        uint K;
        uint[] stack;
        uint[] nodes;
        mapping(bytes32 => uint) IDsToNodeIndexes;
        mapping(uint => bytes32) nodeIndexesToIDs;
    }

    /* ========== STATE VARIABLES ========== */

    struct SortitionSumTrees {
        mapping(bytes32 => SortitionSumTree) sortitionSumTrees;
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function createTree(SortitionSumTrees storage self, bytes32 _key, uint _K) public {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        require(_K > 1, "K must be greater than one.");
        tree.K = _K;
        tree.stack = new uint[](0);
        tree.nodes = new uint[](0);
        tree.nodes.push(0);
    }

    function set(SortitionSumTrees storage self, bytes32 _key, uint _value, bytes32 _ID) public {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = Math.min(tree.IDsToNodeIndexes[_ID], tree.nodes.length - 1);

        if (treeIndex == 0) {
            if (_value != 0) {
                if (tree.stack.length == 0) {
                    treeIndex = tree.nodes.length;
                    tree.nodes.push(_value);

                    if (treeIndex != 1 && (treeIndex - 1) % tree.K == 0) {
                        uint parentIndex = treeIndex / tree.K;
                        bytes32 parentID = tree.nodeIndexesToIDs[parentIndex];
                        uint newIndex = treeIndex + 1;
                        tree.nodes.push(tree.nodes[parentIndex]);
                        delete tree.nodeIndexesToIDs[parentIndex];
                        tree.IDsToNodeIndexes[parentID] = newIndex;
                        tree.nodeIndexesToIDs[newIndex] = parentID;
                    }
                } else {
                    treeIndex = tree.stack[tree.stack.length - 1];
                    tree.stack.pop();
                    tree.nodes[treeIndex] = _value;
                }

                tree.IDsToNodeIndexes[_ID] = treeIndex;
                tree.nodeIndexesToIDs[treeIndex] = _ID;

                updateParents(self, _key, treeIndex, true, _value);
            }
        } else {
            if (_value == 0) {
                uint value = tree.nodes[treeIndex];
                tree.nodes[treeIndex] = 0;

                tree.stack.push(treeIndex);

                delete tree.IDsToNodeIndexes[_ID];
                delete tree.nodeIndexesToIDs[treeIndex];

                updateParents(self, _key, treeIndex, false, value);
            } else if (_value != tree.nodes[treeIndex]) {// New, non zero value.
                bool plusOrMinus = tree.nodes[treeIndex] <= _value;
                uint plusOrMinusValue = plusOrMinus ? _value - tree.nodes[treeIndex] : tree.nodes[treeIndex] - _value;
                tree.nodes[treeIndex] = _value;

                updateParents(self, _key, treeIndex, plusOrMinus, plusOrMinusValue);
            }
        }
    }

    function draw(SortitionSumTrees storage self, bytes32 _key, uint _drawnNumber) public returns (bytes32 ID) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = 0;
        uint currentDrawnNumber = _drawnNumber % tree.nodes[0];

        while ((tree.K * treeIndex) + 1 < tree.nodes.length)
            for (uint i = 1; i <= tree.K; i++) {
                uint nodeIndex = (tree.K * treeIndex) + i;
                uint nodeValue = tree.nodes[nodeIndex];

                if (currentDrawnNumber >= nodeValue) currentDrawnNumber -= nodeValue;
                else {
                    treeIndex = nodeIndex;
                    break;
                }
            }

        ID = tree.nodeIndexesToIDs[treeIndex];
        tree.nodes[treeIndex] = 0;
    }

    function stakeOf(SortitionSumTrees storage self, bytes32 _key, bytes32 _ID) public view returns (uint value) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = Math.min(tree.IDsToNodeIndexes[_ID], tree.nodes.length - 1);
        if (treeIndex == 0) value = 0;
        else value = tree.nodes[treeIndex];
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function updateParents(SortitionSumTrees storage self, bytes32 _key, uint _treeIndex, bool _plusOrMinus, uint _value) private {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        uint parentIndex = _treeIndex;
        while (parentIndex != 0) {
            parentIndex = (parentIndex - 1) / tree.K;
            tree.nodes[parentIndex] = _plusOrMinus ? tree.nodes[parentIndex] + _value : tree.nodes[parentIndex] - _value;
        }
    }
}

contract Whitelist is Ownable {
    mapping(address => bool) private _whitelist;
    bool private _disable;                      // default - false means whitelist feature is working on. if true no more use of whitelist

    event Whitelisted(address indexed _address, bool whitelist);
    event EnableWhitelist();
    event DisableWhitelist();

    modifier onlyWhitelisted {
        require(_disable || _whitelist[msg.sender], "Whitelist: caller is not on the whitelist");
        _;
    }

    function isWhitelist(address _address) public view returns (bool) {
        return _whitelist[_address];
    }

    function setWhitelist(address _address, bool _on) external onlyOwner {
        _whitelist[_address] = _on;

        emit Whitelisted(_address, _on);
    }

    function disableWhitelist(bool disable) external onlyOwner {
        _disable = disable;
        if (disable) {
            emit DisableWhitelist();
        } else {
            emit EnableWhitelist();
        }
    }
}

contract PotController is Whitelist {
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;

    /* ========== CONSTANT ========== */

    uint constant private MAX_TREE_LEAVES = 5;

    /* ========== STATE VARIABLES ========== */

    SortitionSumTreeFactory.SortitionSumTrees private _sortitionSumTree;

    uint internal _randomness;
    uint public potId;
    uint public startedAt;


    /* ========== INTERNAL FUNCTIONS ========== */

    function createTree(bytes32 key) internal {
        _sortitionSumTree.createTree(key, MAX_TREE_LEAVES);
    }

    function getWeight(bytes32 key, bytes32 _ID) internal view returns (uint) {
        return _sortitionSumTree.stakeOf(key, _ID);
    }

    function setWeight(bytes32 key, uint weight, bytes32 _ID) internal {
        _sortitionSumTree.set(key, weight, _ID);
    }

    function draw(bytes32 key, uint randomNumber) internal returns (address) {
        return address(uint(_sortitionSumTree.draw(key, randomNumber)));
    }


}

contract PotOraiLover is PotController {//Valcontroller
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANT ========== */

    IBEP20 public stakingToken;
    IVenusStrategy public VENUS_STRATEGY;
    uint private constant WEIGHT_BASE = 1000;
    uint public WINNER_COUNT = 1;
    /* ========== STATE VARIABLES ========== */

    PotConstant.PotState public state;
    uint public pid = 0;
    uint public minAmount;
    uint public maxAmount;
    uint public burnRatio;
    uint private _totalSupply;  // total principal
    uint private _currentSupply;
    uint private _donateSupply;
    uint private _totalHarvested;
    uint private _totalWeight;  // for select winner
    uint private _currentUsers;

    mapping(address => uint) private _available;
    mapping(address => uint) private _donation;
    mapping(address => uint) private _depositedAt;
    mapping(address => uint) private _participateCount;
    mapping(address => uint) private _lastParticipatedPot;
    mapping(uint => PotConstant.PotHistory) private _histories;

    bytes32 private _treeKey;
    uint private _boostDuration;

    /* ========== MODIFIERS ========== */

    modifier onlyValidState(PotConstant.PotState _state) {
        require(state == _state, "BunnyPot: invalid pot state");
        _;
    }

    modifier onlyValidDeposit(uint amount) {
        require(_available[msg.sender] == 0 || _depositedAt[msg.sender] >= startedAt, "BunnyPot: cannot deposit before claim");
        require(amount >= minAmount && amount.add(_available[msg.sender]) <= maxAmount, "BunnyPot: invalid input amount");
        if (_available[msg.sender] == 0) {
            _participateCount[msg.sender] = _participateCount[msg.sender].add(1);
            _currentUsers = _currentUsers.add(1);
        }
        _;
    }

    /* ========== EVENTS ========== */

    event Deposited(address indexed user, uint amount);
    event Claimed(address indexed user, uint amount);

    /* ========== INITIALIZER ========== */

    constructor(IBEP20 _stakingToken, IVenusStrategy _strategy, uint256 _min, uint256 _max) public {
        stakingToken = _stakingToken;
        VENUS_STRATEGY = _strategy;
        stakingToken.safeApprove(address(VENUS_STRATEGY), uint(- 1));
        burnRatio = 10;
        state = PotConstant.PotState.Cooked;
        _boostDuration = 4 hours;
        minAmount = _min;
        maxAmount = _max;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function availableOf(address account) public view returns (uint) {
        return _available[account];
    }

    function weightOf(address _account) public view returns (uint, uint, uint) {
        return (_timeWeight(_account), _countWeight(_account), _valueWeight(_account));
    }

    function depositedAt(address account) public view returns (uint) {
        return _depositedAt[account];
    }

    function winnersOf(uint _potId) public view returns (address[] memory) {
        return _histories[_potId].winners;
    }
    //Đã xóa mấy cái vớ vẩn tính theo giá USD
    function potInfoOf(address _account) public view returns (PotConstant.PotInfo memory, PotConstant.PotInfoMe memory) {

        PotConstant.PotInfo memory info;
        info.potId = potId;
        info.state = state;
        info.supplyCurrent = _currentSupply;
        info.supplyDonation = _donateSupply;
        info.rewards = _totalHarvested.mul(100 - burnRatio).div(100);
        info.minAmount = minAmount;
        info.maxAmount = maxAmount;
        info.avgOdds = _totalWeight > 0 && _currentUsers > 0 ? _totalWeight.div(_currentUsers).mul(100e18).div(_totalWeight) : 0;
        info.startedAt = startedAt;

        PotConstant.PotInfoMe memory infoMe;
        infoMe.wTime = _timeWeight(_account);
        infoMe.wCount = _countWeight(_account);
        infoMe.wValue = _valueWeight(_account);
        infoMe.odds = _totalWeight > 0 ? _calculateWeight(_account).mul(100e18).div(_totalWeight) : 0;
        infoMe.available = availableOf(_account);
        infoMe.lastParticipatedPot = _lastParticipatedPot[_account];
        infoMe.depositedAt = depositedAt(_account);
        return (info, infoMe);
    }

    function potHistoryOf(uint _potId) public view returns (PotConstant.PotHistory memory) {
        return _histories[_potId];
    }

    function boostDuration() external view returns (uint) {
        return _boostDuration;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    //Đã sửa theo VENUS
    function deposit(uint amount) public onlyValidState(PotConstant.PotState.Opened) onlyValidDeposit(amount) {
        address account = msg.sender;
        VENUS_STRATEGY.deposit(amount);
        _currentSupply = _currentSupply.add(amount);
        _available[account] = _available[account].add(amount);
        _lastParticipatedPot[account] = potId;
        _depositedAt[account] = block.timestamp;

        bytes32 accountID = bytes32(uint256(account));
        uint weightBefore = getWeight(_getTreeKey(), accountID);
        uint weightCurrent = _calculateWeight(account);
        _totalWeight = _totalWeight.sub(weightBefore).add(weightCurrent);
        setWeight(_getTreeKey(), weightCurrent, accountID);

        emit Deposited(account, amount);
    }
    //Giữ lại hết
    function stepToNext() public onlyValidState(PotConstant.PotState.Opened) {
        address account = msg.sender;
        uint amount = _available[account];
        require(amount > 0 && _lastParticipatedPot[account] < potId, "BunnyPot: is not participant");

        uint available = Math.min(maxAmount, amount);

        address[] memory winners = potHistoryOf(_lastParticipatedPot[account]).winners;
        for (uint i = 0; i < winners.length; i++) {
            if (winners[i] == account) {
                revert("BunnyPot: winner can't step to next");
            }
        }

        _participateCount[account] = _participateCount[account].add(1);
        _currentUsers = _currentUsers.add(1);
        _currentSupply = _currentSupply.add(available);
        _lastParticipatedPot[account] = potId;
        _depositedAt[account] = block.timestamp;

        bytes32 accountID = bytes32(uint256(account));

        uint weightCurrent = _calculateWeight(account);
        _totalWeight = _totalWeight.add(weightCurrent);
        setWeight(_getTreeKey(), weightCurrent, accountID);

        if (amount > available) {
            VENUS_STRATEGY.withdraw(amount.sub(available), account);
        }
    }
    //Đã sửa theo VENUS
    function withdrawAll() public {
        address account = msg.sender;
        uint amount = _available[account];

        require(amount > 0 && _lastParticipatedPot[account] < potId, "OraiPot: is not participant");
        VENUS_STRATEGY.withdraw(amount, account);
        delete _available[account];
        emit Claimed(account, amount);
    }
    //Đã sửa theo VENUS
    function depositDonation(uint amount) public onlyWhitelisted {
        VENUS_STRATEGY.deposit(amount);
        _donateSupply = _donateSupply.add(amount);
        _donation[msg.sender] = _donation[msg.sender].add(amount);
    }

    function withdrawDonation() public onlyWhitelisted {
        address account = msg.sender;
        uint amount = _donation[account];
        _donateSupply = _donateSupply.sub(amount);
        delete _donation[account];
        VENUS_STRATEGY.withdraw(amount, account);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setAmountMinMax(uint _min, uint _max) external onlyOwner onlyValidState(PotConstant.PotState.Cooked) {
        minAmount = _min;
        maxAmount = _max;
    }

    function setWinnerCount(uint256 _winnerCount) external onlyOwner onlyValidState(PotConstant.PotState.Cooked) {
        WINNER_COUNT = _winnerCount;
    }


    function openPot() external onlyOwner onlyValidState(PotConstant.PotState.Cooked) {
        state = PotConstant.PotState.Opened;
        _overCook();

        potId = potId + 1;
        startedAt = block.timestamp;

        _totalWeight = 0;
        _currentSupply = 0;
        _totalHarvested = 0;
        _currentUsers = 0;

        _treeKey = bytes32(potId);
        createTree(_treeKey);
    }

    function closePot() external onlyOwner onlyValidState(PotConstant.PotState.Opened) {
        state = PotConstant.PotState.Closed;
    }

    function overCook(uint _externalRandomNumber) external onlyOwner onlyValidState(PotConstant.PotState.Closed) {
        state = PotConstant.PotState.Cooked;
        _getRandomNumber(_externalRandomNumber);
    }

    function setBurnRatio(uint _burnRatio) external onlyOwner {
        require(_burnRatio <= 100, "BunnyPot: invalid range");
        burnRatio = _burnRatio;
    }


    function setBoostDuration(uint duration) external onlyOwner {
        _boostDuration = duration;
    }

    function setStrategy(IBEP20 _stakingToken, IVenusStrategy _strategy) external onlyOwner {
        stakingToken = _stakingToken;
        VENUS_STRATEGY = _strategy;
    }

    function _getRandomNumber(uint _externalRandomNumber) private {
        bytes32 _structHash;
        bytes32 _blockhash = blockhash(block.number - 1);
        uint gasLeft = gasleft();
        _randomness = _externalRandomNumber;
        //1
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                _currentUsers,
                gasLeft,
                _randomness
            )
        );
        _randomness = uint256(_structHash);
        // 2
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                _totalSupply,
                gasLeft,
                _randomness
            )
        );
        _randomness = uint256(_structHash);
        // 3
        uint lastTimeStamp = block.timestamp;
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                lastTimeStamp,
                gasLeft,
                _randomness
            )
        );
        _randomness = uint256(_structHash);

        // 4
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                gasLeft,
                _randomness
            )
        );
        _randomness = uint256(_structHash);
    }

    function _overCook() private {
        if (_totalWeight == 0) return;
        uint winnerCount = Math.min(WINNER_COUNT, _currentUsers);
        _totalHarvested = VENUS_STRATEGY.claimAll(address(this));

        uint buyback = _totalHarvested.mul(burnRatio).div(100);
        _totalHarvested = _totalHarvested.sub(buyback);
        if (_totalHarvested > 0) {
            VENUS_STRATEGY.deposit(_totalHarvested);
        }
        PotConstant.PotHistory memory history;
        history.potId = potId;
        history.users = _currentUsers;
        history.rewardPerWinner = winnerCount > 0 ? _totalHarvested.div(winnerCount) : 0;
        history.date = block.timestamp;
        history.winners = new address[](winnerCount);

        for (uint i = 0; i < winnerCount; i++) {
            uint rn = uint256(keccak256(abi.encode(_randomness, i))).mod(_totalWeight);
            address selected = draw(_getTreeKey(), rn);

            _available[selected] = _available[selected].add(_totalHarvested.div(winnerCount));
            history.winners[i] = selected;
            delete _participateCount[selected];
        }
        _histories[potId] = history;
    }

    //Giữ lại hết
    function _calculateWeight(address account) private view returns (uint) {
        if (_depositedAt[account] < startedAt) return 0;

        uint wTime = _timeWeight(account);
        uint wCount = _countWeight(account);
        uint wValue = _valueWeight(account);
        return wTime.mul(wCount).mul(wValue).div(100);
    }

    //Giữ lại hết
    function _timeWeight(address account) private view returns (uint) {
        if (_depositedAt[account] < startedAt) return 0;

        uint timestamp = _depositedAt[account].sub(startedAt);
        if (timestamp < _boostDuration) {
            return 28;
        } else if (timestamp < _boostDuration.mul(2)) {
            return 24;
        } else if (timestamp < _boostDuration.mul(3)) {
            return 20;
        } else if (timestamp < _boostDuration.mul(4)) {
            return 16;
        } else if (timestamp < _boostDuration.mul(5)) {
            return 12;
        } else {
            return 8;
        }
    }

    //Giữ lại hết
    function _countWeight(address account) private view returns (uint) {
        uint count = _participateCount[account];
        if (count >= 13) {
            return 40;
        } else if (count >= 9) {
            return 30;
        } else if (count >= 5) {
            return 20;
        } else {
            return 10;
        }
    }

    //Giữ lại hết
    function _valueWeight(address account) private view returns (uint) {
        uint amount = _available[account];
        uint denom = Math.max(minAmount, 1);
        return Math.min(amount.mul(10).div(denom), maxAmount.mul(10).div(denom));
    }

    //Giữ lại hết
    function _getTreeKey() private view returns (bytes32) {
        return _treeKey == bytes32(0) ? keccak256("Orai/MultipleWinnerPot") : _treeKey;
    }
}