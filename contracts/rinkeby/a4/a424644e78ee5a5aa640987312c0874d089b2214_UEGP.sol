/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

pragma solidity ^0.5.0;
// interface
interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address add) external view returns (uint256);
  //function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function releaseFor(address to) external returns (bool);
 // function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  event NewRequest  (address driversAdd, uint256 amount , uint256  date);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract ERC20Detailed is IERC20 {

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract Ownable {
    address public pto;
    mapping(address => bool) drivers;
    mapping(address => bool) pfo;
    mapping(address => bool) poo;
   

    constructor() public {
    pto = msg.sender;
  }

    modifier onlyPTO() {
        require(msg.sender == pto);
        _;
    }
  
    modifier onlyDriver() {
        require(drivers[msg.sender] == true );
        _;
    }
    
    modifier onlyPFO() {
        require(pfo[msg.sender] == true );
        _;
    }

    modifier onlyPOO() {
        require(poo[msg.sender] == true );
        _;
    }
    
    function addPFO(address userAddress) public onlyPTO {
            require(!pfo[userAddress]);             
            pfo[userAddress] = true;    

    }
    
     function removePFO(address userAddress) public onlyPTO {
            require(pfo[userAddress]);             
            pfo[userAddress] = false;    
    }
    
    function addPOO(address userAddress) public onlyPFO {
            require(!poo[userAddress]);             
            poo[userAddress] = true;    

    }
    
     function removePOO(address userAddress) public onlyPFO {
            require(poo[userAddress]);             
            poo[userAddress] = false;    
    }

    function transferOwnership(address newOwner) public onlyPTO {
        if (newOwner != address(0)) {
            pto = newOwner;
        }
    }
    
    function isPFO(address add) public view  returns (bool) {
    return pfo[add];
  }
  
  function isPOO(address add) public view  returns (bool) {
    return poo[add];
  }
    
    function addDriver(address userAddress) public onlyPFO {
            require(!drivers[userAddress]);             
            drivers[userAddress] = true;    

    }
    
     function removeDriver(address userAddress) public onlyPFO {
            require(drivers[userAddress]);             
            drivers[userAddress] = false;    
    }

    
    function isDriver(address add) public view  returns (bool) {
    return drivers[add];
  }
  
  
}


contract UEGP is ERC20Detailed,Ownable {

  struct DriverRequest {
    address driverAdd;
    uint256 amount;
    uint256 date;
  }
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => DriverRequest) private _requests;

  string constant tokenName = "UBEREGP";
  string constant tokenSymbol = "UEGP";
  uint8  constant tokenDecimals = 2;
  uint256 _totalSupply = 5000*100;

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {}

  function createRequest
  (uint256 amount) 
  public onlyDriver returns (bool) {
      require(_requests[msg.sender].amount==0);
    _requests[msg.sender].driverAdd = msg.sender;
    _requests[msg.sender].amount = amount;
    _requests[msg.sender].date= block.timestamp ;
 emit NewRequest(
         msg.sender, 
         _requests[msg.sender].amount,
          _requests[msg.sender].date
          );
         
      return true;
  }
  

 function viewRequest(address id) public onlyPFO view  returns (address add,uint256 amount,uint256  date) {
     
    return(
      _requests[id].driverAdd, 
      _requests[id].amount, 
      _requests[id].date
     
      );
  }

    function totalSupply() public view  returns (uint256) {
    return _totalSupply;
     }
 
    function balanceOf(address add) public view  returns (uint256) {
    return _balances[add];
  }
  
    function releaseFor(address to) public onlyPFO returns (bool) {
    require(to != address(0));
    require(_requests[to].amount != 0);
    _balances[msg.sender] = _balances[msg.sender].sub(_requests[to].amount);
    _balances[to] = _balances[to].add(_requests[to].amount);
    _requests[to].amount = 0;
    _requests[to].date = block.timestamp;
    emit Transfer(msg.sender, to, _requests[to].amount);
    return true;
  }

  function transfer(address to, uint256 value) public onlyPTO returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);

    emit Transfer(msg.sender, to, value);
    return true;
  }

  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public onlyPTO {
            for (uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], amounts[i]);
    }
  }

  function transferFrom(address from, address to, uint256 value) public onlyPTO returns (bool) {
            require(value <= _balances[from]);
            require(to != address(0));

    _balances[from] = _balances[from].sub(value);


    _balances[to] = _balances[to].add(value);


    emit Transfer(from, to, value);

    return true;
  }

  function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(account, address(0), amount);
  }

  function mintTo(address account, uint256 amount) external onlyPTO {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burnFrom(address account, uint256 amount) external onlyPTO{
    burn(account, amount);
  }
}