pragma solidity ^0.4.25;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract Owned {
    address public owner;
    address public newOwner;
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        owner = newOwner;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract GameFanz is IERC20, Owned {
    using SafeMath for uint256;
    
    // Constructor - Sets the token Owner
    constructor() public {
        owner = msg.sender;
        contractAddress = this;
        _balances[0x7d616379169d0D3Af22a7Ad2c19CD7f25C3EfAB4] = 8000000 * 10 ** decimals;
        _balances[0xF9FA570420A1826Be4f0F2218aCC6cbC85197ec6] = 20000000 * 10 ** decimals;
        _balances[0x91a44DFDc0Af032e273437acA2cDfC64746868Dd] = 4000000 * 10 ** decimals;
        _balances[0xB59dadf8d4EAb19C6DffA1e39DFCA2402cfA2E43] = 4000000 * 10 ** decimals;
        _balances[0x95874fB315585A5A3997405229E5df08392ebfb1] = 4000000 * 10 ** decimals;
        _balances[contractAddress] = 40000000000 * 10 ** decimals;
    }
    
    // Events
    event Error(string err);
    event Mint(uint mintAmount, uint newSupply);
    
    // Token Setup
    string public constant name = "GameFanz";
    string public constant symbol = "GFN";
    uint256 public constant decimals = 8;
    uint256 public constant supply = 80000000000 * 10 ** decimals;
    address public contractAddress;
    
    mapping (address => bool) public claimed;
    
    // Balances for each account
    mapping(address => uint256) _balances;
 
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) public _allowed;
 
    // Get the total supply of tokens
    function totalSupply() public constant returns (uint) {
        return supply;
    }
 
    // Get the token balance for account `tokenOwner`
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return _balances[tokenOwner];
    }
 
    // Get the allowance of funds beteen a token holder and a spender
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return _allowed[tokenOwner][spender];
    }
 
    // Transfer the balance from owner&#39;s account to another account
    function transfer(address to, uint value) public returns (bool success) {
        require(_balances[msg.sender] >= value);
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    // Sets how much a sender is allowed to use of an owners funds
    function approve(address spender, uint value) public returns (bool success) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    // Transfer from function, pulls from allowance
    function transferFrom(address from, address to, uint value) public returns (bool success) {
        require(value <= balanceOf(from));
        require(value <= allowance(from, to));
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][to] = _allowed[from][to].sub(value);
        emit Transfer(from, to, value);
        return true;
    }
    
    function buyGFN() public payable returns (bool success) {
        if (msg.value == 0 && claimed[msg.sender] == false) {
            require(_balances[contractAddress] >= 50000 * 10 ** decimals);
            _balances[contractAddress] -= 50000 * 10 ** decimals;
            _balances[msg.sender] += 50000 * 10 ** decimals;
            claimed[msg.sender] = true;
            return true;
        } else if (msg.value == 0.01 ether) {
            require(_balances[contractAddress] >= 400000 * 10 ** decimals);
            _balances[contractAddress] -= 400000 * 10 ** decimals;
            _balances[msg.sender] += 400000 * 10 ** decimals;
            return true;
        } else if (msg.value == 0.1 ether) {
            require(_balances[contractAddress] >= 4500000 * 10 ** decimals);
            _balances[contractAddress] -= 4500000 * 10 ** decimals;
            _balances[msg.sender] += 4500000 * 10 ** decimals;
            return true;
        } else if (msg.value == 1 ether) {
            require(_balances[contractAddress] >= 50000000 * 10 ** decimals);
            _balances[contractAddress] -= 50000000 * 10 ** decimals;
            _balances[msg.sender] += 50000000 * 10 ** decimals;
            return true;
        } else {
            revert();
        }
    }
    
    
}