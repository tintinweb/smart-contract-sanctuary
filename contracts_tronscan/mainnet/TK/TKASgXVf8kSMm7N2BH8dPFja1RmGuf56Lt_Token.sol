//SourceUnit: DFTToken.sol

pragma solidity ^0.5.9;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Context {
    constructor () internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;

    mapping(address => uint) private _balances;

    mapping(address => mapping(address => uint)) private _allowances;

    mapping(address => bool) internal whiteUser;

    uint private _totalSupply;

    uint public totalMax = 99999 * 10 ** 6;

    address public fundAccount;
    address public pool1;
    address public pool2;


    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }

    function getRate(uint256 _amount) public pure returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 rate = _amount.mul(10).div(100);

        uint256 fund = rate.mul(10).div(100);
        uint256 black = rate.mul(20).div(100);
        uint256 one = rate.mul(30).div(100);
        uint256 two = rate.mul(40).div(100);

        return (rate, fund, black, one, two);
    }

    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount, true);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount, false);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint amount, bool en) internal {
        require(amount > 0, "ERC20: transfer from the zero amount");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");

        if (!whiteUser[recipient] && !whiteUser[sender] && en) {
            amount = updateAmount(amount);
        }

        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function updateAmount(uint amount) internal returns(uint) {
        (,uint256 _fund,uint256 _black,uint256 _one,uint256 _two) = getRate(amount);
        if (_totalSupply > totalMax) {
            if (_totalSupply.sub(_black) < totalMax) {
                _black = _totalSupply.sub(totalMax);
            }
            amount = amount.sub(_black);
            _totalSupply = _totalSupply.sub(_black);
            _balances[address(0)] = _balances[address(0)].add(_black);
            emit Transfer(address(this), address(0), _black);
        }
        if(fundAccount != address(0)) {
            amount = amount.sub(_fund);

            _balances[fundAccount] = _balances[fundAccount].add(_fund);
            emit Transfer(address(this), fundAccount, _fund);
        }
        if(pool1 != address(0)) {
            amount = amount.sub(_one);

            _balances[pool1] = _balances[pool1].add(_one);
            emit Transfer(address(this), pool1, _one);
        }
        if(pool2 != address(0)) {
            amount = amount.sub(_two);

            _balances[pool2] = _balances[pool2].add(_two);
            emit Transfer(address(this), pool2, _two);
        }
        return amount;
    }

    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
}

contract Token is ERC20, ERC20Detailed {

    address public owner;

    constructor () public ERC20Detailed("DFH", "DFH", 6) {
        owner = msg.sender;
        super._mint(owner, 9999999 * 10 ** 6);

        whiteUser[owner] = true;
    }

    function updateAddress(address _fund, address _pool1, address _pool2) public {
        require(msg.sender == owner);
        if(_fund != address(0)) {
            fundAccount = _fund;
        }
        if(_pool1 != address(0)) {
            pool1 = _pool1;
        }
        if(_pool2 != address(0)) {
            pool2 = _pool2;
        }
    }

    function updateOwner(address _owner) public {
        require(msg.sender == owner);
        owner = _owner;
    }

    function updateTotalMax(uint256 _max) public {
        require(msg.sender == owner);
        totalMax = _max;
    }

    function setWhiteUser(address account, bool enable) public {
        require(msg.sender == owner);
        whiteUser[account] = enable;
    }

}