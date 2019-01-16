pragma solidity 0.4.25;


library SafeMath {

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);
        uint256 c = _a / _b;

        return c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
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

contract ERC20 is IERC20 {
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

  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
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
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
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

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  function _mint(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }
}

contract TEMOR is ERC20 {

    string private _name = "Timur Balmukhanov";
    string private _symbol = "BTM";
    uint8 private _decimals = 1;
    string _owner;
    mapping (uint => string) _avto;
    uint index;
    mapping (uint => string) friend;

    constructor() public {
        _mint(address(this), 138);
        newAvto("krisa blyat");
        newAvto("VW Jetta");
        friend[0] = "RUSEK";
        friend[1] = "ALBERTO";
        friend[2] = "VANO";
        friend[3] = "ALBERTLAR";
        friend[4] = "GAFUR";
        newOwner("Anya");
    }

    function newAvto(string _shit) public {
        index++;
        _avto[index] = _shit;
    }

    function newOwner(string _newOwner) public {
        _owner = _newOwner;
    }

    function name() public view returns(string) {
      return _name;
    }

    function symbol() public view returns(string) {
      return _symbol;
    }

    function decimals() public view returns(uint8) {
      return _decimals;
    }

    function _0_name(uint _) public view returns(string) {
      return _name;
    }

    function _4_owner() external view returns(string) {
        return _owner;
    }

    function _1_vozrast() external view returns(uint256) {
        return (now - 879638400) / 365 days;
    }

    function _2_nation() external pure returns(string) {
        return "KAZAKH";
    }

    function _2_education() external pure returns(string) {
        return "YURIST";
    }

    function _3_orientation() external pure returns(string) {
        return "goluboy";
    }

    function _5_avto(uint _number) external view returns(string) {
        return _avto[_number];
    }

    function _6_friends() external view returns(string, string, string, string, string) {
        return(friend[0], friend[1], friend[2], friend[3], friend[4]);
    }

    function _7_russkayaRuletka() external view returns(string) {
        return friend[block.timestamp % 5];
    }

    function _8_poluchaetLesha() external pure returns(bool) {
        return true;
    }

    function _9_dataSmerti() external pure returns(uint) {
        return 3498984000;
    }

    function _91_MR() external pure returns(string) {
        return "KABLUK";
    }

    function _95_ebetSmartContracti() external pure returns(bool) {
        return true;
    }
}