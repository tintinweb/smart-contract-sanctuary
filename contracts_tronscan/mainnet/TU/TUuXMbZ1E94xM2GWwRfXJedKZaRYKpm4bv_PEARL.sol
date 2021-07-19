//SourceUnit: PEARL.sol

pragma solidity ^0.5.12;

interface iERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    function increaseAllowance(address spender, uint addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function cbrt(uint n) internal pure returns (uint) {

        if (n == 0) {
            return 0;
        }

       uint[12] memory divisor = [
           uint(1000000),   uint(100000),   uint(10000),    uint(1000),
           uint(100),       uint(10),       uint(9),        uint(7),
           uint(5),         uint(3),        uint(2),        uint(1)
       ];

       uint[12] memory cube_root = [
           uint(100.000000 * 1e6), uint(46.415888  * 1e6), uint(21.544347  * 1e6),
           uint(10.000000  * 1e6), uint(4.641589   * 1e6), uint(2.154434   * 1e6),
           uint(2.080083   * 1e6), uint(1.912931   * 1e6), uint(1.709975   * 1e6),
           uint(1.442249   * 1e6), uint(1.259921   * 1e6), uint(1.000000   * 1e6)
       ];

       uint a = n;
       uint r = 1;

       for ( uint j = 0; j < divisor.length; ) {
           if ( a >= divisor[j] ) {
               r = (r * cube_root[j]) / 1e6;
               a /= divisor[j];
           } else if ( a <= 1) {
               break;
           } else {
               j++;
           }
       }

       return r;

   }
}

contract KOwnerable {
    address[] internal _authAddress;

    address[] public KContractOwners;

    bool private _call_locked;


    constructor() public {
        KContractOwners.push(msg.sender);
        _authAddress.push(msg.sender);
    }


    function KAuthAddresses() external view returns (address[] memory) {
        return _authAddress;
    }

    function KAddAuthAddress(address auther) external KOwnerOnly {
        _authAddress.push(auther);
    }

    function KDelAuthAddress(address auther) external KOwnerOnly {
        for (uint256 i = 0; i < _authAddress.length; i++) {
            if (_authAddress[i] == auther) {
                for (uint256 j = 0; j < _authAddress.length - 1; j++) {
                    _authAddress[j] = _authAddress[j + 1];
                }
                delete _authAddress[_authAddress.length - 1];
                _authAddress.pop();
                return;
            }
        }
    }

    modifier KOwnerOnly() {
        bool exist = false;
        for (uint256 i = 0; i < KContractOwners.length; i++) {
            if (KContractOwners[i] == msg.sender) {
                exist = true;
                break;
            }
        }
        require(exist, "NotAuther");
        _;
    }

    modifier KDemocracyOnly() {
        bool exist = false;
        for (uint256 i = 0; i < KContractOwners.length; i++) {
            if (KContractOwners[i] == msg.sender) {
                exist = true;
                break;
            }
        }
        require(exist, "NotAuther");
        _;
    }

    modifier KOwnerOnlyAPI() {
        bool exist = false;
        for (uint256 i = 0; i < KContractOwners.length; i++) {
            if (KContractOwners[i] == msg.sender) {
                exist = true;
                break;
            }
        }
        require(exist, "NotAuther");
        _;
    }

    modifier KRejectContractCall() {
        uint256 size;
        address payable safeAddr = msg.sender;
        assembly {
            size := extcodesize(safeAddr)
        }
        require(size == 0, "Sender Is Contract");
        _;
    }

    modifier KDAODefense() {
        require(!_call_locked, "DAO_Warning");
        _call_locked = true;
        _;
        _call_locked = false;
    }

    modifier KDelegateMethod() {
        bool exist = false;
        for (uint256 i = 0; i < _authAddress.length; i++) {
            if (_authAddress[i] == msg.sender) {
                exist = true;
                break;
            }
        }
        require(exist, "PermissionDeny");
        _;
    }
}

contract KPausable is KOwnerable {
    event Paused(address account);

    event Unpaused(address account);

    bool public paused;

    constructor() internal {
        paused = false;
    }

    modifier KWhenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier KWhenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    function Pause() public KOwnerOnly {
        paused = true;
        emit Paused(msg.sender);
    }

    function Unpause() public KOwnerOnly {
        paused = false;
        emit Unpaused(msg.sender);
    }
}

contract ERC20TokenTemplate is iERC20, KPausable {

     using SafeMath for uint;

    mapping (address => uint) internal _balances;
    mapping (address => mapping (address => uint)) internal _allowances;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint _totalSupply
    ) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;

        _balances[msg.sender] = _totalSupply;
    }

    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) external KWhenNotPaused returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint value) external KWhenNotPaused returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) external KWhenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) external KWhenNotPaused returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) external KWhenNotPaused returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}

contract PEARL is ERC20TokenTemplate("PEARL","PEARL",8,35000*(10**8)){

}