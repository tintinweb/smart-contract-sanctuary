pragma solidity ^0.5.2;

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


contract BITFRIENDZ is IERC20, Owned {
    using SafeMath for uint256;
    
    // Constructor - Sets the token Owner
    constructor() public {
        owner = msg.sender;
        _balances[0x14fBA4aa05AEeC42336CB75bc30bF78dbC6b3f9F] = 2000000000 * 10 ** decimals;
        emit Transfer(address(0), 0x14fBA4aa05AEeC42336CB75bc30bF78dbC6b3f9F, 2000000000 * 10 ** decimals);
        _balances[0xdA78d97Fb07d945691916798CFF57324770a6C34] = 2000000000 * 10 ** decimals;
        emit Transfer(address(0), 0xdA78d97Fb07d945691916798CFF57324770a6C34, 2000000000 * 10 ** decimals);
        _balances[0xF07e6A0EAbF18A3D8bB10e6E63c2E9e2d101C160] = 1000000000 * 10 ** decimals;
        emit Transfer(address(0), 0xF07e6A0EAbF18A3D8bB10e6E63c2E9e2d101C160, 1000000000 * 10 ** decimals);
        _balances[address(this)] = 15000000000 * 10 ** decimals;
        emit Transfer(address(0), address(this), 15000000000 * 10 ** decimals);
    }
    
    // Events
    event Error(string err);
    
    // Token Setup
    string public constant name = "BITFRIENDZ";
    string public constant symbol = "BFRN";
    uint256 public constant decimals = 18;
    uint256 public supply = 20000000000 * 10 ** decimals;
    
    uint256 public tokenPrice = 50000000000;
    
    // Balances for each account
    mapping(address => uint256) _balances;
 
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) public _allowed;
 
    // Get the total supply of tokens
    function totalSupply() public view returns (uint) {
        return supply;
    }
 
    // Get the token balance for account `tokenOwner`
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return _balances[tokenOwner];
    }
 
    // Get the allowance of funds beteen a token holder and a spender
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return _allowed[tokenOwner][spender];
    }
 
    // Transfer the balance from owner&#39;s account to another account
    function transfer(address to, uint value) public returns (bool success) {
        require(_balances[msg.sender] >= value);
        if (to == address(this) || to == address(0)) {
            burn(value);
            return true;
        } else {
            _balances[msg.sender] = _balances[msg.sender].sub(value);
            _balances[to] = _balances[to].add(value);
            emit Transfer(msg.sender, to, value);
            return true;
        }
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
    
    function () external payable {
        require(msg.value >= tokenPrice);
        uint256 amount = (msg.value * 10 ** decimals) / tokenPrice;
        uint256 bonus = 0;
        if (msg.value >= 1 ether && msg.value < 2 ether) {
            bonus = (((amount * 100) + (amount * 25)) / 100);
        } else if (msg.value >= 2 ether && msg.value < 4 ether) {
            bonus = (((amount * 100) + (amount * 50)) / 100);
        } else if (msg.value >= 4 ether && msg.value < 5 ether) {
            bonus = (((amount * 10000) + (amount * 5625)) / 10000);
        } else if (msg.value >= 5 ether) {
            bonus = (((amount * 100) + (amount * 75)) / 100);
        }
        if (_balances[address(this)] < amount + bonus) {
            revert();
        }
        _balances[address(this)] = _balances[address(this)].sub(amount + bonus);
        _balances[msg.sender] = _balances[msg.sender].add(amount + bonus);
        emit Transfer(address(this), msg.sender, amount + bonus);
    }
    
    function BuyTokens() public payable {
        require(msg.value >= tokenPrice);
        uint256 amount = (msg.value * 10 ** decimals) / tokenPrice;
        uint256 bonus = 0;
        if (msg.value >= 1 ether && msg.value < 2 ether) {
            bonus = (((amount * 100) + (amount * 25)) / 100);
        } else if (msg.value >= 2 ether && msg.value < 4 ether) {
            bonus = (((amount * 100) + (amount * 50)) / 100);
        } else if (msg.value >= 4 ether && msg.value < 5 ether) {
            bonus = (((amount * 10000) + (amount * 5625)) / 10000);
        } else if (msg.value >= 5 ether) {
            bonus = (((amount * 100) + (amount * 75)) / 100);
        }
        if (_balances[address(this)] < amount + bonus) {
            revert();
        }
        _balances[address(this)] = _balances[address(this)].sub(amount + bonus);
        _balances[msg.sender] = _balances[msg.sender].add(amount + bonus);
        emit Transfer(address(this), msg.sender, amount + bonus);
    }
    
    function endICO() public onlyOwner {
        _balances[msg.sender] = _balances[msg.sender].sub(_balances[address(this)]);
        msg.sender.transfer(address(this).balance);
    }
    
    function burn(uint256 amount) public {
        require(_balances[msg.sender] >= amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        supply = supply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
    }
}