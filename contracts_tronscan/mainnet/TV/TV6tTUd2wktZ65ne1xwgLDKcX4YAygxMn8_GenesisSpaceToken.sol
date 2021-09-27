//SourceUnit: BaseTRC20.sol

pragma solidity ^0.5.8;

import "./ITRC20.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract BaseTRC20 is Context, ITRC20, Ownable {
    using SafeMath for uint;

    mapping(address => uint) private _balances;

    mapping(address => mapping(address => uint)) internal _allowances;

    uint private _totalSupply;//发行总量
    uint private _totalFlow;//流通总量
    uint private _totalMine;//矿场大小
    uint private _totalMining;//已挖出数量
    uint private _totalBurn;//销毁数量
    uint private _lastBurn;//剩余销毁数量
    bool private _canBurn;//是否销毁
    uint private _totalReward;//分红数量
    uint private _burnProportion;//手续费比例
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _rewardAddress;


    constructor (string memory name, string memory symbol, uint8 decimals, uint burnProportion, address rewardAddress) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _burnProportion = burnProportion;
        _rewardAddress = rewardAddress;
        _totalSupply = 2000000 * 10 ** 8;
        _totalMine = 1600000 * 10 ** 8;
        _lastBurn = 180000 * 10 ** 8;
        _canBurn = true;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function totalFlow() public view returns (uint) {
        return _totalFlow;
    }

    function totalMine() public view returns (uint) {
        return _totalMine;
    }

    function totalMining() public view returns (uint) {
        return _totalMining;
    }

    function totalBurn() public view returns (uint) {
        return _totalBurn;
    }

    function lastBurn() public view returns (uint) {
        return _totalSupply.sub(_lastBurn);
    }

    function canBurn() public view returns (bool) {
        return _canBurn;
    }

    function totalReward() public view returns (uint) {
        return _totalReward;
    }

    function burnProportion() public view returns (uint) {
        return _burnProportion;
    }

    function rewardAddress() public view returns (address) {
        return _rewardAddress;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "TRC20: transfer amount exceeds balance");

        if (isAdmin()) {
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        } else {
            if (_canBurn) {
                //销毁总量
                uint remainAmount = amount.mul(_burnProportion).div(100);
                //接收额度
                uint receiveAmount = amount.sub(remainAmount);
                //销毁额度
                uint burnAmount = remainAmount.mul(3).div(5);
                //奖励额度
                uint rewardAmount = remainAmount.sub(burnAmount);

                if (_totalSupply.sub(_lastBurn) < burnAmount) {
                    burnAmount = _totalSupply.sub(_lastBurn);
                    rewardAmount = remainAmount.sub(burnAmount);
                    _canBurn = false;
                }

                _balances[recipient] = _balances[recipient].add(receiveAmount);
                _balances[_rewardAddress] = _balances[_rewardAddress].add(rewardAmount);

                _totalBurn = _totalBurn.add(burnAmount);
                _totalFlow = _totalFlow.sub(burnAmount);
                _totalReward = _totalReward.add(rewardAmount);
                _totalSupply = _totalSupply.sub(burnAmount);
                emit Transfer(sender, recipient, receiveAmount);
                emit Transfer(sender, _rewardAddress, rewardAmount);
                emit Transfer(sender, address(0), burnAmount);
                emit TransferBurn(sender, recipient, amount, remainAmount, receiveAmount, burnAmount, rewardAmount);
            } else {
                _balances[recipient] = _balances[recipient].add(amount);
                emit Transfer(sender, recipient, amount);
            }
        }
    }

    function _mint(address account, uint amount) internal {
        _mint(account, amount, false);
    }


    function _mint(address account, uint amount, bool isFirst) internal {
        require(account != address(0), "TRC20: mint to the zero address");
        require(_totalMine.sub(_totalMining) > 0, "TRC20: mint amount zero");
        if (_totalMine.sub(_totalMining.add(amount)) <= 0) {
            amount = _totalMine.sub(_totalMining);
        }

        _totalFlow = _totalFlow.add(amount);
        if (!isFirst)
            _totalMining = _totalMining.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    //从矿池销毁
    function _burn(uint amount) internal {
        require(_totalSupply.sub(_lastBurn) > 0 && _canBurn, "TRC20: no need burn");
        require(_totalMine - _totalMining > 0, "TRC20: burn-mint amount zero");
        if (_totalSupply.sub(_lastBurn) < amount) {
            amount = _totalSupply.sub(_lastBurn);
            _canBurn = false;
        }
        if (_totalMine < (_totalMining.add(amount))) {
            amount = _totalMine.sub(_totalMining);
        }

        _totalMining = _totalMining.add(amount);
        _totalBurn = _totalBurn.add(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(address(this), address(0), amount);
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0), "TRC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "TRC20: burn amount exceeds balance");
        _totalFlow = _totalFlow.sub(amount);
        _totalBurn = _totalBurn.add(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

//SourceUnit: Context.sol

pragma solidity ^0.5.8;

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

//SourceUnit: GenesisSpaceToken.sol

pragma solidity ^0.5.8;

import "./Context.sol";
import "./ITRC20.sol";
import "./BaseTRC20.sol";

contract GenesisSpaceToken is BaseTRC20 {
    constructor(address gr, address rewardAddress) public BaseTRC20("Genesis space", "GST", 8, 1, rewardAddress){
        require(gr != address(0), "GenesisSpaceToken：invalid gr");
        require(rewardAddress != address(0), "GenesisSpaceToken：invalid rewardAddress");
        mint(gr, 400000 * 10 ** 8, true);
    }

    //挖矿
    function mint(address account, uint amount) public onlyOwner returns (bool){
        _mint(account, amount);
        return true;
    }

    //挖矿
    function mint(address account, uint amount, bool isFirst) public onlyOwner returns (bool) {
        _mint(account, amount, isFirst);
        return true;
    }

    //销毁
    function burn(address account, uint amount) public onlyOwner returns (bool) {
        _burn(account, amount);
        return true;
    }

    //从矿池销毁
    function burn(uint amount) public onlyOwner returns (bool){
        _burn(amount);
        return true;
    }

    //转账
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "KIMIToken: transfer amount exceeds allowance"));
        return true;
    }

    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }


    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "KIMIToken: decreased allowance below zero"));
        return true;
    }

}

//SourceUnit: ITRC20.sol

pragma solidity ^0.5.8;
import "./TRC20Events.sol";

contract ITRC20 is TRC20Events {
    function totalSupply() public view returns (uint);

    function balanceOf(address guy) public view returns (uint);

    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);

    function transfer(address dst, uint wad) public returns (bool);

    function transferFrom(
        address src, address dst, uint wad
    ) public returns (bool);
}




//SourceUnit: Ownable.sol

pragma solidity ^0.5.8;

contract Ownable {

    address private _owner;
    address[] private _admins;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        _admins.push(msg.sender);
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function addAdmin(address _address) public onlyOwner {
        require(_address != address(0), "Ownable: new admin is the zero address");
        bool x = false;
        for (uint i = 0; i < _admins.length; i++) {
            if (_admins[i] == _address) {
                x = true;
            }
        }
        if (!x)
            _admins.push(_address);
    }

    function delAdmin(address _address) public onlyOwner {
        require(_address != address(0), "Ownable: delete admin is the zero address");
        uint index = 0;
        for (uint i = 0; i < _admins.length; i++) {
            if (_admins[i] == _address) {
                index = i;
                break;
            }
        }

        delete _admins[index];
    }

    function isAdmin() public view returns (bool) {
        for (uint i = 0; i < _admins.length; i++) {
            if (_admins[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }


    // function renounceOwnership() public onlyOwner {
    //     emit OwnershipTransferred(_owner, address(0));
    //     _owner = address(0);
    // }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
}


//SourceUnit: TRC20Events.sol

pragma solidity ^0.5.8;

contract TRC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event TransferBurn(address indexed src, address indexed dst, uint wad, uint remainAmount, uint receiveAmount, uint burnAmount, uint rewardAmount);
}