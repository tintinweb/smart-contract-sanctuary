//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//contract and interface are fully satisfied by https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md

interface IERC20 {
    // getters
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    // functions
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ZepToken is IERC20 {
  mapping (address => uint256) public balances;
  // можно разрешить только одному контракту, ай йай
  mapping (address => mapping (address => uint256)) public allowed;

  string private _name = "KCNCtoken";
  string private _symbol = "KCNC";
  uint private _decimals = 18;
  uint256 private _totalSupply;
  address private _owner;
// cutted due to solidity-coverage error: 
// Error in plugin solidity-coverage: Error: Could not instrument: ZepToken.sol. (Please verify solc can compile this file without errors.) mismatched input '(' expecting {';', '='} (32:20)
  // error Unauthorized();

  constructor(uint256 _initialBalance){
    _owner = msg.sender;
    mint(msg.sender,_initialBalance);
  }


  

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function name() public view returns (string memory){
    return _name;
  }

  function decimals() public view returns (uint){
    return _decimals;
  }

  function symbol() public view returns (string memory){
    return _symbol;
  }

  function owner() public view returns (address){
    return _owner;
  }  
  function balanceOf(address person) public view override returns (uint256) {
    return balances[person];
  }

  function allowance(address person,address spender) public view override returns (uint256)
  {
    return allowed[person][spender];
  }

  function transfer(address to, uint256 value) public override returns (bool) {
    require(value <= balances[msg.sender], "Balance less then value");
    require(to != address(0),"'To' can't be zero");

    balances[msg.sender] -= value;
    balances[to] += value;
    emit Transfer(msg.sender, to, value);
    return true;
  }

  function approve(address spender, uint256 value) public override returns (bool) {
    require(spender != address(0),"'Spender' can't be zero");

    allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public override returns (bool){
    require(value <= balances[from],"Balance less then value");
    require(value <= allowed[from][msg.sender],"Unauthorised, please approve");
    require(to != address(0),"'To' can't be zero");

    balances[from] -= value;
    balances[to] += value;
    allowed[from][msg.sender] -= value;
    emit Transfer(from, to, value);
    return true;
  }

  function increaseAllowance(address spender,uint256 addedValue) public returns (bool){
    require(spender != address(0),"'Spender' can't be zero");

    allowed[msg.sender][spender] += addedValue;
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool){
    require(spender != address(0),"'Spender' can't be zero");

    allowed[msg.sender][spender] -= subtractedValue;
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  function mint(address account, uint256 amount) public onlyBy(_owner){
    require(account != address(0),"Account can't be zero");
    _totalSupply += amount;
    balances[account] += amount;
    emit Transfer(address(0), account, amount);
  }

  function burn(address account, uint256 amount) public onlyBy(_owner) {
    require(account != address(0),"Account can't be zero");
    require(amount <= balances[account],"Account doesn't own such amount");

    _totalSupply -= amount;
    balances[account] -= amount;
    emit Transfer(account, address(0), amount);
  }

  modifier onlyBy(address _account) {
    require(msg.sender == _account, "Unauthorized");
      // revert Unauthorized();
    _;
  }
}