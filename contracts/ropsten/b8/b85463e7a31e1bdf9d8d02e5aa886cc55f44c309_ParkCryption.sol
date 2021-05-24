/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

pragma solidity 0.6.0;

contract ParkCryption {
  //global variables
  string private _symbol;
  string private _name;
  uint8 private _decimals;
  uint256 private _totalSupply;
  address public _owner;
  
  //Creates mapping arrays for storing all balances and allowed 3rd party sellers
  mapping (address => uint256) public _balances;
  mapping (address => mapping (address => uint256)) public _allowed;
  
  //generate a blockchain event to broadcast a transfer
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );
  
  //generate a blockchain event to broadcast an approval
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
  
  //function modifier to restrict function call to only contract owner
  modifier onlyOwner() {
    require(isOwner());
    _;
  }
  
  //assign contract owner and mint genesis tokens
  constructor() public {
    _name = "ParkCryption";
    _symbol = "PARK";
    _decimals = 18;
    _totalSupply = 1000000000000000000000000000;
    _owner = msg.sender;
    _mint(msg.sender, _totalSupply);
  }
  
  //external balanceof function to allow checks of balances 
  function balanceOf(address owner) external view returns (uint256) {
    return _balances[owner];
  }
  
  //restrict functions to be only called by contract owner
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }
  
  //external token transfer function
  function transfer(address to, uint256 value) external returns (bool success) {
    _transfer(msg.sender, to, value);
    return true;
  }
  
  //approve + transferFrom are to authorise a 3rd party transfer such as an exchange,
  //to sell and transfer tokens on behalf of token contract owner.
  //Token Contract Owner would use function approve(exchange, amount) then
  //Token Buyer would execute trade on the Exchange then
  //Exchange would call transferFrom(TokenContractOwnerAddress, BuyerAddress, TokenAmount)
  function transferFrom(address from, address to, uint256 value)
    external
    returns (bool success)
  {
    require(value <= _allowed[from][msg.sender]);
    _allowed[from][msg.sender] -= value; //Deduct value amount from 3rd Party token allowance
    _transfer(from, to, value);
    return true;
  }
  
  // Internal transfer, can only be called by this contract
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));
    _balances[from] -= value;
    _balances[to] += value;
    emit Transfer(from, to, value);
  }
  
  //approve + transferFrom are for a 3rd party transfer such as an exchange
  function approve(address spender, uint256 value) external onlyOwner returns (bool success) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }
  
  //Retrieve token allowance allocated to a seller i.e. a crypto exchange
  function allowance(address owner, address spender) external onlyOwner view returns (uint256) {
    return _allowed[owner][spender];
  }
  
  //increase the amount of tokens that an owner allowed to a seller.
  //spender - the address allowed to sell the tokens.
  //addedValue - the amount of tokens to increase the allowance by.
  function increaseAllowance(address spender, uint256 addedValue)
    external
    onlyOwner
    returns (bool)
  {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender] + addedValue);
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  //Decrease the amount of tokens that owner allowed to a spender.
  //spender - the address allowed to sell the tokens ie an exchange
  //subtractedValue - the amount of tokens to decrease the allowance by.
  function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    onlyOwner
    returns (bool)
  {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender] - subtractedValue);
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
  
  //Set totalSupply and assign all genesis tokens to contract owner
  function _mint(address account, uint256 value) internal {
    require(account != address(0));
    _balances[account] = value;
    emit Transfer(address(0), account, value);
  }
  
}