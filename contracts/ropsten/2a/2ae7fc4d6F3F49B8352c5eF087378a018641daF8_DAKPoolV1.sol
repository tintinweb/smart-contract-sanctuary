// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
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

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract ERC20 is IERC20 {
    mapping(address => uint) internal _balances;
    mapping(address => mapping(address => uint)) internal _allowances;
    uint internal _totalSupply;
    string internal _name;
    string internal _symbol;

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public virtual returns (bool) {
        uint currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

            _approve(_msgSender(), spender, currentAllowance - subtractedValue);


        return true;
    }

    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        _approve(sender, _msgSender(), currentAllowance - amount);


        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint amount
    ) internal virtual {
        require(sender != address(0), "DAK ERC20: transfer from the zero address");
        require(recipient != address(0), "DAK ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "DAK ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint amount) internal virtual {
        require(account != address(0), "DAK ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

            _balances[account] = accountBalance - amount;

        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal virtual {}
}

contract DAKPoolV1 is ERC20 {
    using SafeMath for uint;
    using Address for address;

    uint public StartTimestamp;
    uint public EndTimestamp;
    
    uint public accTokenPerShare; 
    uint public inviterAccTokenPerShare; 
    uint public lastRewardTimestamp;
    uint public inviterLastRewardTimestamp;

    uint public MintPerSecond; 
    uint public inviteTotalAmount; // LP邀请存款总数
    address public TEAM;
    address public DEAD;
    IERC20 public LP;
    IERC20 public RewardCoin;
    struct Users {
        uint DepositAmount;
        uint RewardAmount;
        uint inviterRewardAmount;
        address inviter;
    }

    struct InviterList {
        address Customer;
        uint DepositAmount;
        uint InviterTime;
    }

    mapping(address => Users) public users;
    mapping(address => InviterList[] ) public invitations;
    bool internal initialized;    
    event Stake(address indexed user,  uint amount);
    event Withdraw(address indexed user, uint amount);

    function initialize(address _lp, address _team, address _dead) external payable {        
        require(!initialized, "Initialization is completed");
        LP = IERC20(_lp);
        TEAM = _team;
        DEAD = _dead;
        _name        = "DAK";
        _symbol      = "DAK";
        //_totalSupply = 1500 * 10000 * 1e18; 这里不能设定，因为_mint铸造的新币会增加totalSupply导致下面的挖矿数据不准确
        _mint(address(this), 1500 * 10000 * 1e18);

        StartTimestamp = block.timestamp + 5;
        lastRewardTimestamp = StartTimestamp;
        inviterLastRewardTimestamp = StartTimestamp;
        // EndTimestamp = StartTimestamp + 150 days;
        EndTimestamp = StartTimestamp + 150 days;
        MintPerSecond = _totalSupply.div(EndTimestamp - StartTimestamp);
        RewardCoin = IERC20(address(this));
        initialized = true;
    }

    function balanceOf(address _account) public view override returns (uint) {
        return _balances[_account] + pendingToken(_account);
    }

    function updatePool() internal {
        if (block.timestamp < StartTimestamp) {
            return;
        }

        if (LP.balanceOf(address(this)) == 0) {
            // lastRewardTimestamp = StartTimestamp; 
            lastRewardTimestamp = block.timestamp;
        } else {
            uint timestampDiff = getTimestampDiff(lastRewardTimestamp, block.timestamp > EndTimestamp ? EndTimestamp : block.timestamp);
            uint _thisReward = timestampDiff.mul(MintPerSecond).mul(6000).div(10000);
            accTokenPerShare += _thisReward.mul(1e12).div(LP.balanceOf(address(this)));
            lastRewardTimestamp = block.timestamp > EndTimestamp ? EndTimestamp : block.timestamp;
        }

    }

    function updatePool2() internal {
        if (block.timestamp < StartTimestamp) {
            return;
        }

        if (inviteTotalAmount == 0) {
            // inviterLastRewardTimestamp = StartTimestamp; 
            inviterLastRewardTimestamp = block.timestamp; 
        } else {
            uint timestampDiff2 = getTimestampDiff(inviterLastRewardTimestamp, block.timestamp > EndTimestamp ? EndTimestamp : block.timestamp);
            uint _thisReward2 = timestampDiff2.mul(MintPerSecond).mul(4000).div(10000);
            inviterAccTokenPerShare += _thisReward2.mul(1e12).div(inviteTotalAmount);
            inviterLastRewardTimestamp = block.timestamp > EndTimestamp ? EndTimestamp : block.timestamp;
        }
    }

    function pendingToken(address _account) public view returns (uint) {
        if (block.timestamp <= StartTimestamp) {
            return 0;
        }

        return mintPendingToken(_account) + inviterPendingToken(_account);
    }

    function mintPendingToken(address _account) public view returns (uint) {
        if (block.timestamp <= StartTimestamp) {
            return 0;
        }

        if (users[_account].DepositAmount == 0 || LP.balanceOf(address(this)) == 0) {
            return 0;
        }

        Users storage user = users[_account];
        //LP.balanceOf(address(this));

        // 默认LP有人不取出来，所以LP总额不是0，所以不再判断LP余额等于0的情况
        uint timestampDiff = getTimestampDiff(lastRewardTimestamp, block.timestamp > EndTimestamp ? EndTimestamp : block.timestamp);
        uint _thisReward = timestampDiff.mul(MintPerSecond).mul(6000).div(10000);
        uint _accTokenPerShare = accTokenPerShare + (_thisReward.mul(1e12).div(LP.balanceOf(address(this))));

        if (user.DepositAmount > 0) {
            uint userReward = user.DepositAmount.mul(_accTokenPerShare).div(1e12).sub(user.RewardAmount);

            return userReward;
        } else {
            return 0;
        }
    }

    function inviterPendingToken(address _account) public view returns (uint) {
        if (block.timestamp <= StartTimestamp) {
            return 0;
        }

        if (invitations[_account].length == 0 || inviteTotalAmount == 0) {
            return 0;
        }

        Users storage user = users[_account];
        InviterList[] storage invitation = invitations[_account];
        
        uint timestampDiff = getTimestampDiff(inviterLastRewardTimestamp, block.timestamp > EndTimestamp ? EndTimestamp : block.timestamp);
        uint _thisReward = timestampDiff.mul(MintPerSecond).mul(4000).div(10000);
        uint _inviterAccTokenPerShare = inviterAccTokenPerShare + (_thisReward.mul(1e12).div(inviteTotalAmount));
        
        // 计算下属的存款数量
        uint _leaderTotalDepositAmount;
        if (invitation.length != 0) {
            for (uint i = 0; i < invitation.length; i++) {
                _leaderTotalDepositAmount +=  invitation[i].DepositAmount;
            }

            if (_leaderTotalDepositAmount > 0) {
                uint userReward = _leaderTotalDepositAmount.mul(_inviterAccTokenPerShare).div(1e12).sub(user.inviterRewardAmount);
                return userReward;
            } else {
                return 0;
            }

        } else {
            return 0;
        }
    }

    function getInvitationsLength(address _account) public view returns(uint, uint) {
        InviterList[] storage invitation = invitations[_account];
        return (invitations[_account].length, invitation.length);
    }

    function stake(uint _amount, address _inviter) external {
        require(_amount > 1e12, "Error : Stake Amount too low");
        require(_inviter != address(this), "Error : Inviter can't be LP Contract");
        require(_inviter != address(0), "Error : Inviter can't be LP Contract");
        require(_inviter != _msgSender(), "Error : Inviter can't be Yourself");
        require(_inviter != address(LP), "Error : Inviter can't be LP");
        if (block.timestamp > EndTimestamp) {
            require(_amount == 0 , "Error : Mint END, Withdraw only");
        }

        Users storage user = users[_msgSender()];
        uint _accTokenPerShare = accTokenPerShare; // 使用没更新前的才可以
        uint _inviterAccTokenPerShare = inviterAccTokenPerShare;  // 使用没更新前的才可以

        if (user.inviter == address(0)) {
            user.inviter = _inviter;
            //InviterList[] storage invitation = invitations[user.inviter];// 他上头的邀请表,存完才能再查询
            invitations[_inviter].push(InviterList({
                Customer : _msgSender(),
                DepositAmount : _amount,
                InviterTime : block.timestamp // 仅仅前端查询用，不影响结算
            }));
        }

        InviterList[] storage invitation = invitations[user.inviter]; // 他上头的邀请表,存完才能再查询
        updatePool();

        // 真实邀请才刷新邀请池的2个参数
        Users storage _user = users[_msgSender()];// 重读
        if(_user.inviter != address(0) && _user.inviter != address(DEAD)) {updatePool2();}
        // 结算存款奖励,_accTokenPerShare == 0 就不结算本次存款奖励

        // 上次存款大于0才结算奖励
        if (user.DepositAmount > 0 && _accTokenPerShare != 0){
            uint thisMintPending = user.DepositAmount.mul(_accTokenPerShare).div(1e12).sub(user.RewardAmount);            
            _transfer(address(this), _msgSender(), thisMintPending);
        }

        // 给他上头团长结算邀请奖励而已，不是mint奖励
        InviterList[] storage _invitation = invitations[user.inviter]; // 重读
        if ( _user.inviter != address(DEAD) && _user.inviter != address(0)) {
            uint _leaderTotalDepositAmount;
            for (uint i = 0; i < _invitation.length; i++) {
                _leaderTotalDepositAmount +=  _invitation[i].DepositAmount;
            }

            // 给他上头团长结算邀请奖励,用老user，所以下次才能结算邀请奖励
            if (user.DepositAmount > 0 && _leaderTotalDepositAmount > 0 && _inviterAccTokenPerShare != 0) {
                uint thisInviterPending = _leaderTotalDepositAmount.mul(_inviterAccTokenPerShare).div(1e12).sub(users[user.inviter].inviterRewardAmount);
                _transfer(address(this), user.inviter, thisInviterPending);
            }
            users[users[_msgSender()].inviter].inviterRewardAmount = _leaderTotalDepositAmount.mul(inviterAccTokenPerShare).div(1e12);//算最新奖励一定用最新的acc
        }

        // 取走他的LP 并记录已经领走的奖励
        if ( _amount > 0) {
            LP.transferFrom(_msgSender(), address(this), _amount);
            user.DepositAmount += _amount;
            // 刷新矿池后，立马记录，这个必须记录在这里，第一次存，立马记录当前矿池的RewardDebt算是他已经领取走的
            user.RewardAmount = user.DepositAmount.mul(accTokenPerShare).div(1e12);
        }

        // 他上头的团长数据加上
        if (_amount > 0 && _user.inviter != address(0) && _user.inviter != address(DEAD)) {
            inviteTotalAmount += _amount;
            for (uint j = 0; j < invitation.length; j++) {
                if ( invitation[j].Customer == _msgSender() ){
                    invitation[j].DepositAmount += _amount;
                }
            }
        }

        emit Stake(_msgSender(), _amount);
    }

    function withdraw(uint _amount) external {
        require(_amount >1e12, "Error : WithDraw Amount Too Little");
        require(block.timestamp > StartTimestamp, "Mint Not Start");
        
        Users storage user = users[_msgSender()];
        InviterList[] storage invitation = invitations[user.inviter]; // 他的上级邀请表，提款要更新

        uint _accTokenPerShare = accTokenPerShare; // 使用没更新前的才可以
        uint _inviterAccTokenPerShare = inviterAccTokenPerShare;  // 使用没更新前的才可以

        require(user.DepositAmount >= _amount, "ERROR: Withdraw Too Many");
        require(user.inviter !=address(0), "Inviter can't equal BlackHole");

        updatePool();
        // 真实邀请才刷新邀请的2个参数
        if(user.inviter != address(0) && user.inviter != address(DEAD)) {updatePool2();}

        // 结算存款奖励
        if (user.DepositAmount > 0 && _accTokenPerShare != 0){
            uint thisMintPending = user.DepositAmount.mul(_accTokenPerShare).div(1e12).sub(user.RewardAmount);
            _transfer(address(this), _msgSender(), thisMintPending);
        }

        // 给他上头团长结算邀请奖励而已，不结算团长的mint奖励
        if (invitation.length != 0 && user.inviter != address(DEAD) && user.inviter != address(0)) {
            uint _leaderTotalDepositAmount;
            for (uint i = 0; i < invitation.length; i++) {
                _leaderTotalDepositAmount +=  invitation[i].DepositAmount;
            }
            // 给他上头团长结算邀请奖励
            if (_leaderTotalDepositAmount > 0 && _inviterAccTokenPerShare !=0) {
                uint thisInviterPending = _leaderTotalDepositAmount.mul(_inviterAccTokenPerShare).div(1e12).sub(users[user.inviter].inviterRewardAmount);
                _transfer(address(this), user.inviter, thisInviterPending);
                
            } 
            users[users[_msgSender()].inviter].inviterRewardAmount = _leaderTotalDepositAmount.mul(inviterAccTokenPerShare).div(1e12);
        }

        // 给他LP
        uint _minAmount = _amount < LP.balanceOf(address(this))?_amount : LP.balanceOf(address(this));
        LP.transfer(_msgSender(), _minAmount);
        user.DepositAmount -= _minAmount;
        // 他就算不存，也要记录已领取
        user.RewardAmount = user.DepositAmount.mul(accTokenPerShare).div(1e12); // 计算Reward用老的acc

        // 他上头的团长数据减去
        if (user.inviter != address(0) && user.inviter != address(DEAD) ) {
            inviteTotalAmount -= _amount;
            for (uint j = 0; j < invitation.length; j++) {
                if ( invitation[j].Customer == _msgSender() ){
                    invitation[j].DepositAmount -= _amount;
                }
            }
        }

        emit Withdraw(_msgSender(), _amount);
    }

    function getInviterList(address _account) public view returns( address[] memory, uint[] memory, uint[] memory) {
        address[] memory Customers = new address[](invitations[_account].length);
        uint[] memory DepositAmounts = new uint[](invitations[_account].length);
        uint[] memory InviterTimes = new uint[](invitations[_account].length);
        for (uint i = 0; i< invitations[_account].length; i++) {
            InviterList storage _userlist = invitations[_account][i];
            Customers[i] = _userlist.Customer;
            DepositAmounts[i] = _userlist.DepositAmount;
            InviterTimes[i] = _userlist.InviterTime;
        }

        return (Customers, DepositAmounts, InviterTimes);
    }

    function getTimestampDiff(uint _lowerTimestamp, uint _upperTimestamp) internal view returns (uint) {
        if (_upperTimestamp <= _lowerTimestamp || _upperTimestamp > EndTimestamp ) {
            return 0;
        }
        return _upperTimestamp - _lowerTimestamp;
    }

    function transfer(address recipient, uint amount) public override returns (bool) {
        if (block.timestamp < EndTimestamp || _msgSender() != address(this) || _msgSender() != address(TEAM)) {
            return false;
        }
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) public override returns (bool) {
        if (block.timestamp < EndTimestamp || recipient !=address(LP)) {
            return true;
        }

        _transfer(sender, recipient, amount);

        uint currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
 
            _approve(sender, _msgSender(), currentAllowance - amount);


        return true;
    }

    receive() external payable {}

}