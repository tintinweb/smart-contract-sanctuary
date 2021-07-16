//SourceUnit: Cash.sol


// File: contracts/SafeMath.sol

pragma solidity 0.4.25;


/// @dev Math operations with safety checks that revert on error
library SafeMath {
    /// @dev Multiplies two numbers, reverts on overflow.
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'MUL_ERROR');

        return c;
    }

    /// @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'DIVIDING_ERROR');
        uint256 c = a / b;
        return c;
    }

    /// @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SUB_ERROR');
        uint256 c = a - b;
        return c;
    }

    /// @dev Adds two numbers, reverts on overflow.
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'ADD_ERROR');
        return c;
    }

    /// @dev Divides two numbers and returns the remainder (unsigned integer modulo), reverts when dividing by zero.
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'MOD_ERROR');
        return a % b;
    }
}

// File: contracts/helpers/Claimable.sol

pragma solidity 0.4.25;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    function isOwner() public view returns (bool) {
        return (owner == msg.sender);
    }

    modifier onlyContractOwner() {
        require(isOwner(), 'Not a contract owner');
        _;
    }
}

contract Claimable is Ownable {
    address public pendingOwner;

    function transferOwnership(address _newOwner) public onlyContractOwner() {
        pendingOwner = _newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == pendingOwner, 'Not a pending owner');

        address previousOwner = owner;
        owner = msg.sender;
        pendingOwner = address(0);

        emit OwnershipTransferred(previousOwner, msg.sender);
    }
}

// File: contracts/helpers/Administrable.sol

pragma solidity 0.4.25;


contract Administrable is Claimable {
    mapping(address => bool) public isAdmin;

    event AdminAppointed(address admin);
    event AdminDismissed(address admin);

    constructor() public {
        isAdmin[owner] = true;

        emit AdminAppointed(owner);
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], 'NOT_AN_ADMIN');
        _;
    }

    function appointAdmin(address _newAdmin) public onlyContractOwner() returns (bool success) {
        if (isAdmin[_newAdmin] == false) {
            isAdmin[_newAdmin] = true;
        }

        emit AdminAppointed(_newAdmin);
        return true;
    }

    function dismissAdmin(address _admin) public onlyContractOwner() returns (bool success) {
        isAdmin[_admin] = false;

        emit AdminDismissed(_admin);
        return true;
    }
}

// File: contracts/TRC20.sol

pragma solidity 0.4.25;




interface ITRC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract TRC20 is ITRC20, Administrable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowed;

    uint256 private _totalSupply;

    uint256 private _totalBurnt;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function totalBurnt() public view returns (uint256) {
        return _totalBurnt;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), 'spender cannot be address(0)');

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), 'spender cannot be address(0)');

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), 'spender cannot be address(0)');

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), 'from cannot be address(0)');
        require(to != address(0), 'to cannot be address(0)');

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0), 'account cannot be address(0)');

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), 'account cannot be address(0)');

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);

        _totalBurnt = _totalBurnt.add(value);

        emit Transfer(account, address(0), value);
    }

    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
    }
}


contract TRC20Detailed is TRC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string name, string symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string) {
        return _name;
    }

    function symbol() public view returns (string) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: contracts/cash.sol

pragma solidity 0.4.25;




contract Cash is TRC20Detailed {
    address public riseContract;

    constructor(address _mintSaver) public TRC20Detailed('Centric CASH', 'CNS', 8) {
        _mint(_mintSaver, 0);
    }

    modifier onlyRise() {
        require(msg.sender == riseContract, 'CALLER_MUST_BE_RISE_CONTRACT_ONLY');
        _;
    }

    function setRiseContract(address _riseContractAddress) external onlyContractOwner() {
        require(_riseContractAddress != address(0), 'RISE_CONTRACT_CANNOTBE_NULL_ADDRESS');
        require(riseContract == address(0), 'RISE_CONTRACT_ADDRESS_IS_ALREADY_SET');
        riseContract = _riseContractAddress;
    }

    function mintFromRise(address to, uint256 value) external onlyRise returns (bool _success) {
        _mint(to, value);
        return true;
    }

    function burnFromRise(address tokensOwner, uint256 value)
        external
        onlyRise
        returns (bool _success)
    {
        _burn(tokensOwner, value);
        return true;
    }
}