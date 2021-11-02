/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-26
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
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

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

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

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

    function decimals() external view returns (uint256);

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


contract TimeMachine {
    using SafeMath for uint256;
    using Math for uint256;

    uint256 public maxBoxReward = 10000;
    uint256 public minBoxReward = 5000;
    uint256 private _outIndex = 0;
    address public stakeToken;
    address public boxToken;
    address admin;
    address first;

    struct item {
        uint256 month;
        uint256 rate;
    }

    struct book {
        uint8 itemIndex;
        uint256 stakeTime;
        uint256 endTime;
        uint256 interestTime;
        uint256 amount;
        uint256 remainInterest;
        uint256 getInterest;
        uint256 bookIndex;
        uint256 extraInterest;
        bool status;
    }

    struct box {
        uint256 reward;
        uint256 openTime;
        uint256 boxIndex;
    }

    // 矿池收益记录
    struct rewardLog {
        uint256 rewardTime;
        uint256 amount;
    }

    // 推荐奖励记录
    struct pushRewardLog {
        uint256 rewardTime;
        uint256 amount;
        address subAddress;
    }

    // 取出记录
    struct outLog {
        bool status;
        uint256 outTime;
        uint256 amount;
        address user;
    }


    uint256[] _rewardRate = [15, 10, 8, 5, 2, 2, 2, 2, 2, 2, 10, 8, 5, 3, 2, 1, 1, 1, 1, 1];
    address[] _stakeUsers;
    item[] items;
    outLog[] _outs;

    mapping(address => uint256) private _getReward;  // 上级获取的奖励数量
    mapping(address => uint256) private _totalInterest;  // 已领取奖励
    mapping(address => uint256) private _teamCount;  // 团队人数
    mapping(address => uint256) private _totalBoxReward;  // 盲盒累计奖励
    mapping(address => uint256) private _activeTime; // 激活时间
    mapping(address => address) private _supers;
    mapping(address => address[]) private _directMembers;  // 直推列表
    mapping(address => bool) private _userStake;
    mapping(address => book[]) _userBooks;   // 用户质押
    mapping(address => box[]) _userBoxes;   // 用户盲盒
    mapping(address => rewardLog[]) _interest;  // 领取奖励记录
    mapping(address => pushRewardLog[]) _pushRewardLog;  // 推荐奖励记录
    mapping(address => uint256[]) private _signRecord;  // 奖励记录


    constructor(address _stakeToken, address _boxToken, address _first) {
        admin = msg.sender;
        first = _first;
        stakeToken = _stakeToken;
        boxToken = _boxToken;
        items.push(item(1, 18));
        items.push(item(3, 24));
        items.push(item(6, 30));
    }

    event Stake(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    modifier activate(){
        require(_supers[msg.sender] != address(0) || msg.sender == first, "Must activate first");
        _;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin, "Only admin can change items");
        _;
    }

    // 质押套餐
    function allItem() public view returns (item[] memory){
        return items;
    }

    // 修改质押套餐
    function changeItems(uint8 itemIndex, uint256 month, uint256 rate) public onlyAdmin {
        require(month > 0, "Must great than zero");
        require(rate > 0, "Must great than zero");
        if (itemIndex < items.length) {
            items[itemIndex] = item(month, rate);
        } else {
            items.push(item(month, rate));
        }
    }

    // 更换管理员
    function changeAdmin(address account) public onlyAdmin {
        require(account != address(0), "Can't set zero");
        admin = account;
    }

    // 修改盲盒奖励数量
    function changeBoxReward(uint256 minReward, uint256 maxReward) public onlyAdmin {
        require(minReward < maxReward, "Min must less than max");
        minBoxReward = minReward;
        maxBoxReward = maxReward;
    }

    // 激活，绑定上级
    function bindSuper(address account) public {
        require(account != address(0), "Super can't be zero address");
        require(account != msg.sender, "Can't activated by yourself");
        require(_supers[msg.sender] == address(0), "Already activated");
        require(_supers[account] != address(0) || account == first, "The account must activated");
        _supers[msg.sender] = account;
        _activeTime[msg.sender] = block.timestamp;
        _directMembers[account].push(msg.sender);
        while (account != address(0)) {
            _teamCount[account] = _teamCount[account] + 1;
            account = _supers[account];
        }
    }

    // 激活时间
    function timeOf(address account) public view returns (uint256){
        return _activeTime[account];
    }

    // 地址是否激活
    function isActive(address account) public view returns (bool){
        return _supers[account] != address(0) || account == first;
    }

    // 获取上级
    function superOf(address account) public view returns (address){
        return _supers[account];
    }

    // 直接人数
    function directCountOf(address account) public view returns (uint256){
        return _directMembers[account].length;
    }

    // 团队人数
    function teamCountOf(address account) public view returns (uint256){
        return _teamCount[account];
    }

    // 直接列表
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
                    dms[i] = ds[ds.length - 1 - from];
                    from++;
                    i++;
                }
            }
            return dms;
        }
        return new address[](0);
    }

    // 矿池质押
    function stake(uint8 itemIndex, uint256 amount) public activate {
        require(itemIndex < items.length, "Index error");
        uint256 decimal = IERC20(stakeToken).decimals();
        require(amount >= 100 * (10 ** decimal), "At least 100");
        item memory it = items[itemIndex];
        amount = amount.div(100 * (10 ** decimal)).mul(100 * (10 ** decimal));
        TransferHelper.safeTransferFrom(stakeToken, msg.sender, admin, amount);
        _userBooks[msg.sender].push(book(itemIndex, block.timestamp, block.timestamp.add(it.month.mul(2592000)), block.timestamp, amount, 0, 0, _userBooks[msg.sender].length, 0, true));
        if (_userStake[msg.sender] == false) {
            _stakeUsers.push(msg.sender);
            _userStake[msg.sender] = true;
        }

        emit Stake(msg.sender, amount);
    }

    // 质押次数
    function bookCountOf(address account) public view returns (uint256){
        return _userBooks[account].length;
    }

    // 用户的质押套餐
    function bookOf(address account, uint256 page, uint256 size) public view returns (book[] memory){
        require(page >= 1, "Page must great than 0");
        require(size >= 1, "Size must great than 0");
        book[] memory bs = _userBooks[account];
        uint256 from = (page - 1) * size;
        uint256 to = page * size;
        if (bs.length > 0 && from < bs.length) {
            if (to > bs.length) {
                to = bs.length;
            }
            size = to - from;
            book[] memory booksInfo = new book[](size);
            if (size > 0) {
                uint256 i = 0;
                while (from < to) {
                    booksInfo[i] = bs[bs.length - 1 - from];
                    from++;
                    i++;
                }
            }
            return booksInfo;
        }
        return new book[](0);
    }

    function addBook(uint8 itemIndex, uint256 end, uint256 amount, address account) public onlyAdmin {
        _userBooks[account].push(book(itemIndex, end.sub(items[itemIndex].month.mul(2592000)), end, block.timestamp, amount, 0, 0, _userBooks[account].length, 0, true));
        if (_userStake[account] == false) {
            _stakeUsers.push(account);
            _userStake[account] = true;
        }
    }

    // 总奖励
    function totalInterestOf(address account) public view returns (uint256){
        return _totalInterest[account].add(notInterestOf(account)).add(canInterestOf(account));
    }

    // 不可领取奖励
    function notInterestOf(address account) public view returns (uint256){
        return _notInterestOne(account, block.timestamp);
    }

    function _notInterestOne(address account, uint256 time) private view returns (uint256){
        book[] memory bs = _userBooks[account];
        if (bs.length < 0) {
            return 0;
        }
        uint256 amount = 0;
        for (uint256 i = 0; i < bs.length; i++) {
            book memory b = bs[i];
            if (b.status) {
                amount = amount.add(_notInterestOneBook(b, time));
            }
            amount = amount.add(b.extraInterest);
        }
        return amount;
    }

    function _notInterestOneBook(book memory b, uint256 time) private view returns (uint256){
        return (Math.min(b.endTime, time).sub(b.interestTime)).mul(b.amount).mul(items[b.itemIndex].rate).div(100).div(31536000);
    }

    function _superRewardOne(address account, uint256 amount) private view returns (uint256){
        uint256 i = 0;
        uint256 total = 0;
        account = _supers[account];
        while (account != address(0) && i < 20) {
            total = total.add(amount.mul(_rewardRate[i]).div(100));
            account = _supers[account];
            i++;
        }
        return total;
    }

    function calReward() public view returns (uint256){
        uint256 total = 0;
        uint256 amount = 0;
        for (uint i = 0; i < _stakeUsers.length; i++) {
            amount = _notInterestOne(_stakeUsers[i], block.timestamp);
            total = total.add(amount).add(_superRewardOne(_stakeUsers[i], amount));
        }
        return total;
    }

    // 可领取奖励
    function canInterestOf(address account) public view returns (uint256){
        book[] memory bs = _userBooks[account];
        if (bs.length < 0) {
            return 0;
        }
        uint256 amount = 0;
        for (uint256 i = 0; i < bs.length; i++) {
            book memory b = bs[i];
            amount = amount.add(b.remainInterest);
        }
        return amount;
    }

    // 领取奖励
    function takeTotalInterest() public activate {
        uint256 total = 0;
        for (uint i = 0; i < _userBooks[msg.sender].length; i++) {
            uint256 amount = _userBooks[msg.sender][i].remainInterest;
            if (amount > 0) {
                total = total.add(amount);
            }
        }
        if (total > 0) {
            TransferHelper.safeTransfer(stakeToken, msg.sender, total);
            _totalInterest[msg.sender] = _totalInterest[msg.sender].add(total);
            _interest[msg.sender].push(rewardLog(block.timestamp, total));
            for (uint256 i = 0; i < _userBooks[msg.sender].length; i++) {
                uint256 amount = _userBooks[msg.sender][i].remainInterest;
                if (amount > 0) {
                    _userBooks[msg.sender][i].remainInterest = 0;
                    _userBooks[msg.sender][i].getInterest = _userBooks[msg.sender][i].getInterest.add(amount);
                }
            }
            _superReward(total, msg.sender);
        }
    }

    // 已领取收益
    function getInterestOf(address account) public view returns (uint256){
        return _totalInterest[account];
    }

    // 收益记录
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
                    rls[i] = ds[ds.length - 1 - from];
                    from++;
                    i++;
                }
            }
            return rls;
        }
        return new rewardLog[](0);
    }

    // 发放上级奖励
    function _superReward(uint256 amount, address account) private {
        uint256 i = 0;
        address pri = account;
        account = _supers[account];
        while (account != address(0) && i < 20) {
            uint256 rAmount = amount.mul(_rewardRate[i]).div(100);
            if (rAmount > 0) {
                TransferHelper.safeTransfer(stakeToken, account, rAmount);
                _getReward[account] = _getReward[account].add(rAmount);
                _pushRewardLog[account].push(pushRewardLog(block.timestamp, rAmount, pri));
            }
            account = _supers[account];
            i++;
        }
    }

    // 上级奖励记录
    function pushRewardOf(address account, uint256 page, uint256 size) public view returns (pushRewardLog[] memory){
        require(page >= 1, "Page must great than 0");
        require(size >= 1, "Size must great than 0");
        uint256 from = (page - 1) * size;
        uint256 to = page * size;
        pushRewardLog[] memory bs = _pushRewardLog[account];
        if (bs.length > 0 && from < bs.length) {
            if (to > bs.length) {
                to = bs.length;
            }
            size = to - from;
            pushRewardLog[] memory boxInfo = new pushRewardLog[](size);
            if (size > 0) {
                uint256 i = 0;
                while (from < to) {
                    boxInfo[i] = bs[bs.length - 1 - from];
                    from++;
                    i++;
                }
            }
            return boxInfo;
        }
        return new pushRewardLog[](0);
    }

    // 上级奖励
    function pushRewardOf(address account) public view returns (uint256){
        return _getReward[account];
    }

    // 单条质押可赎回数量
    function canWithdrawAmount(uint256 bookIndex, address account) public view returns (uint256){
        require(bookIndex < _userBooks[account].length, "Index error");
        book memory b = _userBooks[account][bookIndex];
        if (b.status == false) {
            return 0;
        }
        uint256 amount = b.amount;
        if (block.timestamp < b.endTime) {
            amount = amount.sub(b.getInterest).sub(_superRewardOne(account, b.getInterest));
        }
        return amount;
    }

    // 赎回/领取 单条质押
    function withdraw(uint256 bookIndex) public activate {
        require(_userBooks[msg.sender][bookIndex].status == true, "Already back");
        uint256 amount = canWithdrawAmount(bookIndex, msg.sender);
        if (amount > 0) {
            //            TransferHelper.safeTransfer(stakeToken, msg.sender, amount);
            _outs.push(outLog(true, block.timestamp.add(86400), amount, msg.sender));
        }
        _userBooks[msg.sender][bookIndex].status = false;
        book memory b = _userBooks[msg.sender][bookIndex];
        if (block.timestamp >= b.endTime) {
            _userBooks[msg.sender][bookIndex].extraInterest = (b.endTime.sub(b.interestTime)).mul(b.amount).mul(items[b.itemIndex].rate).div(100).div(31536000);
        }
        emit Withdraw(msg.sender, amount);
    }

    // 全部可领取数量
    function allBackAmount(address account) public view returns (uint256){
        book[] memory bs = _userBooks[account];
        uint256 total = 0;
        for (uint256 i = 0; i < bs.length; i++) {
            book memory b = bs[i];
            if (b.status && block.timestamp >= b.endTime) {
                total = total.add(b.amount);
            }
        }
        return total;
    }

    // 领取全部
    function allBack() public activate {
        uint256 amount = allBackAmount(msg.sender);
        book[] memory bs = _userBooks[msg.sender];
        //        TransferHelper.safeTransfer(stakeToken, msg.sender, amount);
        _outs.push(outLog(true, block.timestamp.add(86400), amount, msg.sender));
        for (uint256 i = 0; i <= bs.length; i++) {
            book memory b = bs[i];
            if (b.status && block.timestamp >= b.endTime) {
                _userBooks[msg.sender][i].status = false;
                _userBooks[msg.sender][i].extraInterest = (b.endTime.sub(b.interestTime)).mul(b.amount).mul(items[b.itemIndex].rate).div(100).div(31536000);
            }
        }
    }

    // 待赎回取出总量
    function calBack(uint256 start, uint256 end) public view returns (uint256){
        uint256 total = 0;
        for (uint i = _outIndex; i < _outs.length; i++) {
            if (_outs[i].outTime >= start && _outs[i].outTime < end && _outs[i].status) {
                total = total.add(_outs[i].amount);
            }
        }
        return total;
    }

    // 发送取出和赎回的资金
    function doBack(uint256 end) public onlyAdmin {
        for (uint i = _outIndex; i < _outs.length; i++) {
            if (_outs[i].outTime < end && _outs[i].status) {
                TransferHelper.safeTransfer(stakeToken, _outs[i].user, _outs[i].amount);
                _outs[i].status = false;
                _outIndex = i;
            }
        }
    }

    // 转换可领取收益
    function releaseInterest() public onlyAdmin {
        uint256 l = _stakeUsers.length;
        if (l > 0) {
            uint256 i = 0;
            while (i < l) {
                address user = _stakeUsers[i];
                book[] memory ub = _userBooks[user];
                uint256 ubl = ub.length;
                if (ubl > 0) {
                    uint256 j = 0;
                    while (j < ubl) {
                        if (ub[j].status) {
                            uint256 intt = (Math.min(ub[j].endTime, block.timestamp).sub(ub[j].interestTime)).mul(ub[j].amount).mul(items[ub[j].itemIndex].rate).div(100).div(31536000);
                            if (intt > 0) {
                                _userBooks[user][j].remainInterest = _userBooks[user][j].remainInterest.add(intt);
                                _userBooks[user][j].interestTime = block.timestamp;
                            }
                        }
                        if (ub[j].extraInterest > 0) {
                            _userBooks[user][j].remainInterest = _userBooks[user][j].remainInterest.add(ub[j].extraInterest);
                            _userBooks[user][j].extraInterest = 0;
                        }
                        j++;
                    }
                }
                i++;
            }
        }
    }

    // 盲盒总数量
    function boxCountOf(address account) public view returns (uint256){
        return _userBoxes[account].length;
    }

    // 用户盲盒
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
                    boxInfo[i] = bs[bs.length - 1 - from];
                    from++;
                    i++;
                }
            }
            return boxInfo;
        }
        return new box[](0);
    }

    // 盲盒总奖励
    function boxRewardOf(address account) public view returns (uint256){
        return _totalBoxReward[account];
    }

    // 添加盲盒
    function addBox(address account) public onlyAdmin {
        _userBoxes[account].push(box(0, block.timestamp, _userBoxes[account].length));
    }

    // 开启盲盒
    function openBox(uint256 index) public activate returns (uint256) {
        require(index < _userBoxes[msg.sender].length, "Box index error");
        box memory b = _userBoxes[msg.sender][index];
        require(b.reward == 0, "Already opened");
        uint256 amount = _rand();
        if (amount > 0) {
            TransferHelper.safeTransfer(boxToken, msg.sender, amount);
            _userBoxes[msg.sender][index].openTime = block.timestamp;
            _userBoxes[msg.sender][index].reward = amount;
            _totalBoxReward[msg.sender] = _totalBoxReward[msg.sender].add(amount);
        }
        return amount;
    }

    function _rand() private view returns (uint256) {
        uint256 decimal = IERC20(boxToken).decimals();
        uint256 random = uint256(keccak256(abi.encodePacked(_stakeUsers.length, block.timestamp)));
        return random % ((maxBoxReward - minBoxReward) * (10 ** decimal)) + minBoxReward * (10 ** decimal);
    }
}