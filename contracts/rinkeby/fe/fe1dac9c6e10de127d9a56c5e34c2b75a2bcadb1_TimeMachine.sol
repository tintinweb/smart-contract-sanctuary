/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

pragma solidity ^0.8.0;

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

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
}

library TransferHelper {
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}

interface IERC20 {
    function decimals() external view returns (uint256);
}


contract TimeMachine {
    using SafeMath for uint256;
    using Math for uint256;

    uint256 _maxReward = 10;
    address stakeToken;
    address boxToken;
    address admin;
    address first;

    struct item {
        uint256 month;
        uint256 rate;
    }

    struct book {
        uint256 stakeTime;
        uint256 endTime;
        uint256 amount;
        uint256 getInterest;
        uint256 rate;
        bool status;
    }

    struct box {
        uint256 reward;
        uint256 openTime;
    }

    struct rewardLog {
        uint256 rewardTime;
        uint256 amount;
    }


    uint256[] _rewardRate = [15, 10, 8, 5, 2, 2, 2, 2, 2, 2, 10, 8, 5, 3, 2, 1, 1, 1, 1, 1];
    item[] items;

    mapping(address => uint256) private _getReward;
    mapping(address => uint256) private _remainReward;
    mapping(address => uint256) private _deduceReward;
    mapping(address => uint256) private _totalInterest;
    mapping(address => uint256) public signTimes;
    mapping(address => uint256) private _checkPoints;
    mapping(address => uint256) private _teamCount;
    mapping(address => address) private _supers;
    mapping(address => address[]) private _directMembers;
    mapping(address => book[]) _userBooks;
    mapping(address => box[]) _userBoxes;
    mapping(address => rewardLog[]) _rewards;
    mapping(address => rewardLog[]) _interest;


    constructor(address _stakeToken, address _boxToken) {
        admin = msg.sender;
        first = msg.sender;
        stakeToken = _stakeToken;
        boxToken = _boxToken;
        items.push(item(1, 18));
        items.push(item(3, 24));
        items.push(item(6, 30));
    }

    event Stake(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event GetReward(address indexed user, uint256 amount);


    modifier activate(){
        require(_supers[msg.sender] != address(0), "Must activate first");
        _;
    }

    function allItem() public view returns (item[] memory){
        return items;
    }

    function superOf(address account) public view returns (address){
        return _supers[account];
    }

    function interestOf(uint256 bookIndex, address account) public view returns (uint256){
        require(bookIndex < _userBooks[account].length, "Book index error");
        book memory b = _userBooks[account][bookIndex];
        if (b.status) {
            return Math.min(block.timestamp, b.endTime).sub(b.stakeTime).div(86400).mul(b.amount.mul(b.rate).div(100).div(b.endTime.sub(b.stakeTime).div(86400))).sub(b.getInterest);
        }
        return 0;
    }

    function interestTotalOf(address account) public view returns (uint256){
        uint256 total = 0;
        for (uint i = 0; i <= _userBooks[account].length; i++) {
            total += interestOf(i, account);
        }
        return total;
    }

    function rewardOf(address account) public view returns (uint256){
        return _remainReward[account].add(_getReward[account]);
    }

    function remainRewardOf(address account) public view returns (uint256){
        return _remainReward[account];
    }

    function bookCountOf(address account) public view returns (uint256){
        return _userBooks[account].length;
    }

    function bookOf(address account, uint256 page, uint256 size) public view returns (book[] memory){
        require(page >= 1, "Page must great than 0");
        require(size >= 1, "Size must great than 0");
        uint256 from = (page - 1) * size;
        uint256 to = page * size;
        book[] memory bs = _userBooks[account];
        if (bs.length > 0 && from < bs.length) {
            if (to > bs.length) {
                to = bs.length;
            }
            size = to - from;
            book[] memory booksInfo = new book[](size);
            if (size > 0) {
                uint256 i = 0;
                while (from < to) {
                    booksInfo[i] = bs[from];
                    from++;
                    i++;
                }
            }
            return booksInfo;
        }
        return new book[](0);
    }

    function boxCountOf(address account) public view returns (uint256){
        return _userBoxes[account].length;
    }

    function boxOf(address account, uint256 page, uint256 size) public view returns (box[] memory){
        require(page >= 1, "Page must great than 0");
        require(size >= 1, "Size must great than 0");
        uint256 from = (page - 1) * size;
        uint256 to = page * size;
        box[] memory bs = _userBoxes[account];
        if (bs.length > 0 && from < bs.length) {
            if (to > bs.length) {
                to = bs.length;
            }
            size = to - from;
            box[] memory boxInfo = new box[](size);
            if (size > 0) {
                uint256 i = 0;
                while (from < to) {
                    boxInfo[i] = bs[from];
                    from++;
                    i++;
                }
            }
            return boxInfo;
        }
        return new box[](0);
    }

    function directCountOf(address account) public view returns (uint256){
        return _directMembers[account].length;
    }

    function teamCountOf(address account) public view returns (uint256){
        return _teamCount[account];
    }

    function directMemberOf(address account, uint256 page, uint256 size) public view returns (address[] memory){
        require(page >= 1, "Page must great than 0");
        require(size >= 1, "Size must great than 0");
        uint256 from = page.sub(1).mul(size);
        uint256 to = page.mul(size);
        address[] memory ds = _directMembers[account];
        if (ds.length > 0 && from < ds.length) {
            if (to > ds.length) {
                to = ds.length;
            }
            size = to - from;
            address[] memory dms = new address[](size);
            if (size > 0) {
                uint256 i = 0;
                while (from < to) {
                    dms[i] = ds[from];
                    from++;
                    i++;
                }
            }
            return dms;
        }
        return new address[](0);
    }

    function rewardLogOf(address account, uint256 page, uint256 size) public view returns (rewardLog[] memory){
        require(page >= 1, "Page must great than 0");
        require(size >= 1, "Size must great than 0");
        uint256 from = page.sub(1).mul(size);
        uint256 to = page.mul(size);
        rewardLog[] memory ds = _rewards[account];
        if (ds.length > 0 && from < ds.length) {
            if (to > ds.length) {
                to = ds.length;
            }
            size = to - from;
            rewardLog[] memory rls = new rewardLog[](size);
            if (size > 0) {
                uint256 i = 0;
                while (from < to) {
                    rls[i] = ds[from];
                    from++;
                    i++;
                }
            }
            return rls;
        }
        return new rewardLog[](0);
    }

    function totalInterestOf(address account) public view returns (uint256){
        return _totalInterest[account];
    }

    function interestLogOf(address account, uint256 page, uint256 size) public view returns (rewardLog[] memory){
        require(page >= 1, "Page must great than 0");
        require(size >= 1, "Size must great than 0");
        uint256 from = page.sub(1).mul(size);
        uint256 to = page.mul(size);
        rewardLog[] memory ds = _interest[account];
        if (ds.length > 0 && from < ds.length) {
            if (to > ds.length) {
                to = ds.length;
            }
            size = to - from;
            rewardLog[] memory rls = new rewardLog[](size);
            if (size > 0) {
                uint256 i = 0;
                while (from < to) {
                    rls[i] = ds[from];
                    from++;
                    i++;
                }
            }
            return rls;
        }
        return new rewardLog[](0);
    }

    function canSign(address account) public view returns (bool){
        return block.timestamp.sub(_checkPoints[account]) > 43200;
    }

    function changeAdmin(address account) public {
        require(account != address(0), "Can't set zero");
        require(msg.sender == admin, "Only admin can change");
        admin = account;
    }

    function changeItems(uint8 itemIndex, uint256 month, uint256 rate) public {
        require(month > 0, "Must great than zero");
        require(rate > 0, "Must great than zero");
        require(msg.sender == admin, "Only admin can change items");
        if (itemIndex < items.length) {
            items[itemIndex] = item(month, rate);
        } else {
            items.push(item(month, rate));
        }
    }

    function bindSuper(address account) public {
        require(account != address(0), "Super can't be zero address");
        require(account != msg.sender, "Can't activated by yourself");
        require(_supers[msg.sender] == address(0), "Already activated");
        require(_supers[account] != address(0) || account == first, "The account must activated");
        _supers[msg.sender] = account;
        _directMembers[account].push(msg.sender);
        while (account != address(0)) {
            _teamCount[account] = _teamCount[account] + 1;
            account = _supers[account];
        }
    }

    function stake(uint8 itemIndex, uint256 amount) public activate {
        require(itemIndex < items.length, "Index error");
        uint256 decimal = IERC20(stakeToken).decimals();
        require(amount > 100 * (10 ** decimal), "At least 100");
        item memory it = items[itemIndex];
        amount = amount.div(100 * (10 ** decimal)).mul(100 * (10 ** decimal));
        TransferHelper.safeTransferFrom(stakeToken, msg.sender, admin, amount);
        _userBooks[msg.sender].push(book(block.timestamp, block.timestamp.add(it.month.mul(2592000)), amount, 0, it.rate, true));
        emit Stake(msg.sender, amount);
    }

    function takeInterest(uint256 bookIndex) public activate {
        uint256 amount = interestOf(bookIndex, msg.sender);
        require(amount > 0, "No remain interest");
        TransferHelper.safeTransfer(stakeToken, msg.sender, amount);
        _userBooks[msg.sender][bookIndex].getInterest = _userBooks[msg.sender][bookIndex].getInterest.add(amount);
        _interest[msg.sender].push(rewardLog(block.timestamp, amount));
        _totalInterest[msg.sender] = _totalInterest[msg.sender].add(amount);
        _superReward(amount, msg.sender);
    }


    function takeTotalInterest() public activate {
        uint256 total = 0;
        for (uint i = 0; i <= _userBooks[msg.sender].length; i++) {
            uint256 amount = interestOf(i, msg.sender);
            if (amount > 0) {
                total += amount;
                TransferHelper.safeTransfer(stakeToken, msg.sender, amount);
                _userBooks[msg.sender][i].getInterest = _userBooks[msg.sender][i].getInterest.add(amount);
                _totalInterest[msg.sender] = _totalInterest[msg.sender].add(amount);
                _interest[msg.sender].push(rewardLog(block.timestamp, amount));
                _superReward(amount, msg.sender);
            }
        }
    }

    function takeReward() public activate {
        uint256 amount = _remainReward[msg.sender];
        require(amount > 0, "No remain reward");
        TransferHelper.safeTransfer(stakeToken, msg.sender, amount);
        _remainReward[msg.sender] = 0;
        _getReward[msg.sender] = _getReward[msg.sender].add(amount);
        _rewards[msg.sender].push(rewardLog(block.timestamp, amount));
        emit GetReward(msg.sender, amount);
    }

    function withdraw(uint256 bookIndex) public activate {
        require(bookIndex < _userBooks[msg.sender].length, "Index error");
        book memory b = _userBooks[msg.sender][bookIndex];
        require(b.status == true, "Already take out");
        uint256 amount;
        if (block.timestamp > b.endTime.add(86400)) {
            amount = b.amount;
        } else {
            amount = b.amount.sub(b.getInterest);
            uint256 deduce = _getReward[msg.sender].sub(_deduceReward[msg.sender]);
            if (amount > deduce) {
                amount = amount.sub(deduce);
                _deduceReward[msg.sender] = _deduceReward[msg.sender].add(deduce);
            } else {
                amount = 0;
            }
        }
        if (amount > 0) {
            TransferHelper.safeTransfer(stakeToken, msg.sender, amount);
        }
        _userBooks[msg.sender][bookIndex].status = false;
        emit Withdraw(msg.sender, amount);
    }

    function sign() public activate {
        uint256 duration = block.timestamp.sub(_checkPoints[msg.sender]);
        require(duration > 43200, "Already sign today");
        if (duration > 86400) {
            signTimes[msg.sender] = 1;
        } else {
            signTimes[msg.sender] = signTimes[msg.sender] + 1;
            if (signTimes[msg.sender] == 10) {
                _userBoxes[msg.sender].push(box(0, 0));
                signTimes[msg.sender] = 0;
            }
        }
        _checkPoints[msg.sender] = block.timestamp;
    }

    function openBox(uint256 index) public activate returns (uint256) {
        require(index < _userBoxes[msg.sender].length, "Box index error");
        box memory b = _userBoxes[msg.sender][index];
        require(b.openTime == 0, "Already opened");
        uint256 decimal = IERC20(boxToken).decimals();
        uint256 amount = _rand(_maxReward ** decimal);
        if (amount > 0) {
            TransferHelper.safeTransfer(boxToken, msg.sender, amount);
            _userBoxes[msg.sender][index].openTime = block.timestamp;
            _userBoxes[msg.sender][index].reward = amount;
        }
        return amount;
    }

    function _superReward(uint256 amount, address account) private {
        uint256 i = 0;
        account = _supers[account];
        while (account != address(0) && i < 20) {
            _remainReward[account] = _remainReward[account].add(amount.mul(_rewardRate[i]).div(100));
            account = _supers[account];
            i++;
        }
    }

    function _rand(uint256 _length) private view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return random % _length;
    }
}