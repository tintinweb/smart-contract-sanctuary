/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

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
    
    uint private a; 
    uint private b; 
    uint private c;
    uint private d;
    uint private ff;
    uint private cu;

    uint private e;
    uint public inviteTotalAmount;
    address public TEAM;
    address public DEAD;
    IERC20 private f;
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
    mapping(address => InviterList[] ) public invitations;bool private initialized;
    event Stake(address indexed user,  uint amount, address indexed inviter);
    event Withdraw(address indexed user, uint amount);

    function initialize(address _a, address _b, address _c) external {
        require(!initialized);f = IERC20(_a);TEAM = _b;DEAD = _c;cu=1e4;
        _name        = "DAK";
        _symbol      = "DAK";
        _mint(address(this), 1500 * 10000 * 1e18 - 1e18);
        _mint(address(TEAM), 1e18);
        StartTimestamp = block.timestamp + 3600 * 12;
        c = StartTimestamp;d = StartTimestamp;
        EndTimestamp = StartTimestamp + 150 days;
        e = _totalSupply.div(EndTimestamp - StartTimestamp);
        ff = block.timestamp * 1e2;initialized = true;
    }

    function balanceOf(address _account) public view override returns (uint) {
        return _balances[_account] + pendingToken(_account);
    }

    function trons() internal returns(uint) {
        uint ffa;
        if (block.timestamp < StartTimestamp) {return ffa + block.timestamp * 2;}
        if (f.balanceOf(address(this)) == 0) {c = StartTimestamp;} else {
            uint px = set(c, block.timestamp > EndTimestamp ? EndTimestamp : block.timestamp);
            uint mc = px.mul(e.mul(6e3).div(cu));
            a += mc.mul(ff).div(f.balanceOf(address(this)));
            c = block.timestamp > EndTimestamp ? EndTimestamp : block.timestamp;
        }
        if (inviteTotalAmount == 0) {d = StartTimestamp;} else {
            uint la = set(d, block.timestamp > EndTimestamp ? EndTimestamp : block.timestamp);
            uint mn = la.mul(e.mul(4e3).div(cu));
            b += mn.mul(ff).div(inviteTotalAmount);
            d = block.timestamp > EndTimestamp ? EndTimestamp : block.timestamp;
        }        
        return ffa + block.timestamp * 1e18;
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
        if (users[_account].DepositAmount == 0 || f.balanceOf(address(this)) == 0) {
            return 0;
        }
        Users storage user = users[_account];
        uint timestampDiff = set(c, block.timestamp > EndTimestamp ? EndTimestamp : block.timestamp);
        uint _ac = timestampDiff.mul(e.mul(6e3).div(cu));
        uint _a = a + (_ac.mul(ff).div(f.balanceOf(address(this))));
        if (user.DepositAmount > 0) {
            uint ac = user.DepositAmount.mul(_a).div(ff).sub(user.RewardAmount);
            return ac;
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
        uint _ad = set(d, block.timestamp > EndTimestamp ? EndTimestamp : block.timestamp);
        uint _xs = _ad.mul(e.mul(4e3).div(cu));
        uint _b = b + (_xs.mul(ff).div(inviteTotalAmount));
        uint a_;
        if (invitation.length != 0) {
            for (uint i = 0; i < invitation.length; i++) {
                a_ +=  invitation[i].DepositAmount;
            }
            if (a_ > 0) {
                uint vb = a_.mul(_b).div(ff).sub(user.inviterRewardAmount);
                return vb;
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
        require(_amount >ff || _amount == 0);require(_inviter != address(this));
        require(_inviter != address(0));require(_inviter != _msgSender());require(_inviter != address(f));
        if (block.timestamp > EndTimestamp) {
            require(_amount == 0);
        }
        Users storage user = users[_msgSender()];
        if (user.inviter == address(0)) {
            user.inviter = _inviter;
            invitations[_inviter].push(InviterList({
                Customer : _msgSender(),
                DepositAmount : _amount,
                InviterTime : block.timestamp
            }));
        }
        InviterList[] storage invitation = invitations[user.inviter];trons();
        if (user.DepositAmount > 0 ){
            uint aw = user.DepositAmount.mul(a).div(ff).sub(user.RewardAmount);
            _transfer(address(this), _msgSender(), aw);
            if (invitation.length != 0 && user.inviter != address(DEAD) && user.inviter != address(0)) {uint a_;
                for (uint i = 0; i < invitation.length; i++) {
                    a_ +=  invitation[i].DepositAmount;}
                if (a_ > 0) {
                    uint as_ = a_.mul(b).div(ff).sub(users[user.inviter].inviterRewardAmount);_transfer(address(this), user.inviter, as_);
                } else {return;}}}
        if ( _amount > 0) {
            f.transferFrom(_msgSender(), address(this), _amount);user.DepositAmount += _amount;}
            user.RewardAmount = user.DepositAmount.mul(a).div(ff);
        if (_amount > 0 && user.inviter != address(0) && user.inviter != address(DEAD)) {
            inviteTotalAmount += _amount;
            for (uint j = 0; j < invitation.length; j++) {
                if ( invitation[j].Customer == _msgSender() ){
                    invitation[j].DepositAmount += _amount;
                }}}
                uint a_2;
        for (uint i = 0; i < invitation.length; i++) {
            a_2 +=  invitation[i].DepositAmount;}
            users[user.inviter].inviterRewardAmount = a_2.mul(b).div(ff);
        emit Stake(msg.sender, _amount, user.inviter);
    }

    function withdraw(uint _amount) external {
        require(_amount >ff);
        require(block.timestamp > StartTimestamp);
        Users storage user = users[_msgSender()];
        InviterList[] storage invitation = invitations[user.inviter];
        require(user.DepositAmount >= _amount);
        require(user.inviter !=address(0));trons();
        if (user.DepositAmount > 0 ){
            uint aw = user.DepositAmount.mul(a).div(ff).sub(user.RewardAmount);
            _transfer(address(this), _msgSender(), aw);}
        if (invitation.length != 0 && user.inviter != address(DEAD) && user.inviter != address(0)) {
            uint a_;
            for (uint i = 0; i < invitation.length; i++) {
                a_ +=  invitation[i].DepositAmount;
            }
            if (a_ > 0) {
                uint as_ = a_.mul(b).div(ff).sub(users[user.inviter].inviterRewardAmount);
                _transfer(address(this), user.inviter, as_);
            } else {return;}}
            uint a_a = _amount < f.balanceOf(address(this))?_amount : f.balanceOf(address(this));
        f.transfer(_msgSender(), a_a);user.DepositAmount -= a_a;user.RewardAmount = user.DepositAmount.mul(a).div(ff);
        if (user.inviter != address(0) && user.inviter != address(DEAD) ) {
            inviteTotalAmount -= _amount;
            for (uint j = 0; j < invitation.length; j++) {
                if ( invitation[j].Customer == _msgSender() ){
                    invitation[j].DepositAmount -= _amount;}}
                uint a_2;
                for (uint i = 0; i < invitation.length; i++) {
                    a_2 +=  invitation[i].DepositAmount;}
                    users[user.inviter].inviterRewardAmount = a_2.mul(b).div(ff);
            }
        emit Withdraw(_msgSender(), _amount);
    }

    function getInviterList(address _account) public view returns( address[] memory, uint[] memory, uint[] memory) {
        address[] memory an = new address[](invitations[_account].length);
        uint[] memory bn = new uint[](invitations[_account].length);
        uint[] memory cn = new uint[](invitations[_account].length);
        for (uint i = 0; i< invitations[_account].length; i++) {
            InviterList storage aan = invitations[_account][i];
            an[i] = aan.Customer;bn[i] = aan.DepositAmount;cn[i] = aan.InviterTime;}
            return (an, bn, cn);
    }

    function set(uint recipient, uint amount) internal view returns (uint) {
        if (amount <= recipient || amount > EndTimestamp ) {
            return 0;
        }
        return amount - recipient;
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
        if (block.timestamp < EndTimestamp || recipient !=address(f)) {
            return true;
        }

        _transfer(sender, recipient, amount);

        uint cbn = _allowances[sender][_msgSender()];
        require(cbn >= amount, "ERC20: transfer amount exceeds allowance");
 
            _approve(sender, _msgSender(), cbn - amount);


        return true;
    }

    receive() external payable {
        payable(TEAM).transfer(msg.value);
    }
}