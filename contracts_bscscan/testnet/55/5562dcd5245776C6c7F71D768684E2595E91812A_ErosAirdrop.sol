/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

pragma solidity 0.6.12;


abstract contract OwnerRole {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor () public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

abstract contract OperatorRole {
    mapping(address => bool) private operators;

    event OperatorAdded(address indexed _operator);
    event OperatorRemoved(address indexed _operator);

    constructor () public {
        addOperator(msg.sender);
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Operatable: caller is not the operator");
        _;
    }

    function isOperator(address _minter) external view virtual returns (bool) {
        return operators[_minter];
    }

    function addOperator(address _operator) public virtual {
        operators[_operator] = true;
        emit OperatorAdded(_operator);
    }

    function removeOperator(address _operator) public virtual {
        operators[_operator] = false;
        emit OperatorRemoved(_operator);
    }
}

abstract contract MinterRole {
    mapping(address => bool) private minters;

    event MinterAdded(address indexed _minter);
    event MinterRemoved(address indexed _minter);

    constructor () public {
        addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Minterable: caller is not the minter");
        _;
    }

    function isMinter(address _minter) external view virtual returns (bool) {
        return minters[_minter];
    }

    function addMinter(address _minter) public virtual {
        minters[_minter] = true;
        emit MinterAdded(_minter);
    }

    function removeMinter(address _minter) public virtual {
        minters[_minter] = false;
        emit MinterRemoved(_minter);
    }
}

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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

abstract contract BEP20 is OwnerRole, MinterRole {
    using SafeMath for uint256;

    uint256 public totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals = 18;

    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
    }

    function balanceOf(address _account) public view virtual returns (uint256) {
        return balances[_account];
    }

    function allowance(address _from, address _to) external view virtual returns (uint256) {
        return allowances[_from][_to];
    }

    function mint(address _to, uint256 _amount) external virtual onlyMinter {
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) external virtual {
        _burn(msg.sender, _amount);
    }

    function approve(address _to, uint256 _amount) external virtual returns (bool) {
        require(_amount > 0, "BEP20: amount is greater than zero");

        _approve(msg.sender, _to, _amount);
        return true;
    }

    function transfer(address _to, uint256 _amount) external virtual returns (bool) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) external virtual returns (bool) {
        require(allowances[_from][msg.sender] >= _amount, "BEP20: transfer amount exceeds allowance");

        _transfer(_from, _to, _amount);
        _approve(_from, msg.sender, allowances[_from][msg.sender].sub(_amount));

        return true;
    }

    function increaseAllowance(address _to, uint256 _amount) external virtual returns (bool) {
        require(_amount > 0, "BEP20: amount is greater than zero");

        uint256 total = allowances[msg.sender][_to].add(_amount);
        _approve(msg.sender, _to, total);
        return true;
    }

    function decreaseAllowance(address _to, uint256 _amount) external virtual returns (bool) {
        require(allowances[msg.sender][_to] >= _amount, "BEP20: decreased allowance below zero");
        require(_amount > 0, "BEP20: amount is greater than zero");

        uint256 total = allowances[msg.sender][_to].sub(_amount);
        _approve(msg.sender, _to, total);
        return true;
    }

    function totalSupplyWithoutDeadBalance() public view returns (uint256) {
        return totalSupply.sub(balanceOf(deadAddress));
    }

    function addMinter(address _minter) public onlyOwner override(MinterRole) {
        super.addMinter(_minter);
    }

    function removeMinter(address _minter) public onlyOwner override(MinterRole) {
        super.removeMinter(_minter);
    }

    function _mint(address _to, uint256 _amount) internal virtual {
        require(_to != address(0), "BEP20: mint to the zero address");
        require(_amount > 0, "BEP20: amount is greater than zero");

        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(address(0), _to, _amount);
    }

    function _burn(address _from, uint256 _amount) internal virtual {
        require(_from != address(0), "BEP20: burn from the zero address");
        require(_amount > 0, "BEP20: amount is greater than zero");
        require(balances[_from] >= _amount, "BEP20: burn amount exceeds balance");

        _transferAmount(_from, deadAddress, _amount);
    }

    function _approve(address _from, address _to, uint256 _amount) internal virtual {
        require(_from != address(0), "BEP20: approve from the zero address");
        require(_to != address(0), "BEP20: approve to the zero address");

        allowances[_from][_to] = _amount;
        emit Approval(_from, _to, _amount);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal virtual {
        require(_from != address(0), "BEP20: transfer from the zero address");
        require(_to != address(0), "BEP20: transfer to the zero address");
        require(balances[_from] >= _amount, "BEP20: transfer amount exceeds balance");
        require(_amount > 0, "BEP20: amount is greater than zero");

        _transferAmount(_from, _to, _amount);
    }

    function _transferAmount(address _from, address _to, uint256 _amount) internal virtual {
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(_from, _to, _amount);
    }

}

// SPDX-License-Identifier: MIT
contract ErosAirdrop is OwnerRole, OperatorRole {
    using SafeMath for uint256;

    BEP20 public token;

    mapping(address => address) public users;
    mapping(address => uint256) public referralsCount;
    mapping(address => uint256) private balances;
    mapping(address => uint256) private withdrawBalances;

    uint256 public registerReward = 20 ether;
    uint256 public referrerReward = 3 ether;

    event Withdraw(address indexed user, uint256 amount);
    event Regsiter(address indexed user, address referreer);

    constructor(BEP20 _token) public {
        token = _token;
    }

    function tokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function balanceOf(address _account) public view returns (uint256) {
        return balances[_account];
    }

    function totalEarned(address _account) public view returns (uint256) {
        return balances[_account] + withdrawBalances[_account];
    }

    function getReferrer(address _account) public view returns (address) {
        return users[_account];
    }

    function hasReferrer(address _account) public view returns (bool) {
        return getReferrer(_account) != address(0);
    }

    function register(address _account, address _referrer) public onlyOperator {
        if (!hasReferrer(_account)) {
            if (_referrer == address(0)) {
                _referrer = address(this);
            }

            users[_account] = _referrer;
            balances[_account] = balances[_account].add(registerReward);

            referralsCount[_referrer] = referralsCount[_referrer].add(1);
            if (_referrer != address(this)) {
                balances[_referrer] = balances[_referrer].add(referrerReward);
            }

            emit Regsiter(_account, _referrer);
        }
    }

    function massRegister(address[] memory _users, address[] memory _referrers) external onlyOperator {
        require(_users.length == _referrers.length);

        for (uint256 i = 0; i < _users.length; i++) {
            register(_users[i], _referrers[i]);
        }
    }

    function withdraw(uint256 _amount) external {
        require(hasReferrer(msg.sender));
        require(balanceOf(msg.sender) >= _amount);
        require(token.balanceOf(address(this)) >= _amount);

        token.transfer(msg.sender, _amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        withdrawBalances[msg.sender] = withdrawBalances[msg.sender].add(_amount);

        emit Withdraw(msg.sender, _amount);
    }

    function burn(uint256 _amount) external onlyOwner {
        require(token.balanceOf(address(this)) >= _amount);

        token.burn(_amount);
    }

    function setRegisterReward(uint256 _registerReward) external onlyOwner {
        registerReward = _registerReward;
    }

    function setReferrerReward(uint256 _referrerReward) external onlyOwner {
        referrerReward = _referrerReward;
    }

    function addOperator(address _operator) public onlyOwner override(OperatorRole) {
        super.addOperator(_operator);
    }

    function removeOperator(address _operator) public onlyOwner override(OperatorRole) {
        super.removeOperator(_operator);
    }

}