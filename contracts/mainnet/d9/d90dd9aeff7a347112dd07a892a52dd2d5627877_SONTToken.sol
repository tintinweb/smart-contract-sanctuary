pragma solidity ^0.4.24;


library SafeMath {
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); 
    uint256 c = a / b;

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


contract IERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address who) public view returns (uint256);

  function allowance(address owner, address spender)
    public view returns (uint256);

  function transfer(address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value)
    public returns (bool);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

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

contract Ownable {
  address public _owner;
    
  event OwnershipTransferred( 
      address indexed previousOwner, address indexed newOwner
  );
    
  constructor() public {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }
  
  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }
  
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }
  
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract BasicStandartToken is IERC20 {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;
    
    mapping (address => mapping (address => uint256)) private _allowed;
    
    uint256 private _totalSupply;
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= _balances[msg.sender]);
    
        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 value
      )
        public
        returns (bool)
      {
        require(to != address(0));
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);
    
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }
    
    function allowance(
        address owner,
        address spender
       )
        public
        view
        returns (uint256)
      {
        return _allowed[owner][spender];
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
    
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function increaseAllowance(
        address spender,
        uint256 addedValue
      )
        public
        returns (bool)
      {
        require(spender != address(0));
    
        _allowed[msg.sender][spender] = (
          _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
      }
    
      function decreaseAllowance(
        address spender,
        uint256 subtractedValue
      )
        public
        returns (bool)
      {
        require(spender != address(0));
        uint oldValue = _allowed[msg.sender][spender];
    
        if (subtractedValue > oldValue) {
            _allowed[msg.sender][spender] = 0;
        } else {
            _allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }

    
        _allowed[msg.sender][spender] = (
          _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    
    function _mint(address account, uint256 value) internal {
        require(account != 0);
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }
}

contract SONTToken is BasicStandartToken, Ownable  {
    using SafeMath for uint;


    string constant public symbol = "SONT";
    string constant public name = "Sonata Coin";
    uint8 constant public decimals = 18;
    
    uint constant unlockTime = 1570492800; // Tuesday, October 8, 2019 12:00:00 AM   
    
    uint256 INITIAL_SUPPLY = 500000000e18;

    uint constant companyTokens = 225000000e18;
    uint constant crowdsaleTokens = 275000000e18;

    address crowdsale = 0x495dfc0eb9BD76cbed420a95485dA0F46081B6BF;
    address company = 0x2Fb67e6697c98cE5F96167A3980020abB24d3bf4;

    constructor() public {
        _mint(crowdsale, crowdsaleTokens);
        _mint(company, companyTokens);
    }
    

    function checkPermissions(address from) internal constant returns (bool) {

        if (from == company && now < unlockTime) {
            return false;
        }

        if (from == crowdsale) {
            return true;
        }
        
        return true;
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(checkPermissions(msg.sender));
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(checkPermissions(from));
        return super.transferFrom(from, to, value);
    }
    
}