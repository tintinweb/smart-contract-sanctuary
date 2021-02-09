/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

pragma solidity 0.6.0;

interface IERC20 {

function totalSupply() external view returns (uint256);
function balanceOf(address account) external view returns (uint256);
function allowance(address owner, address spender) external view returns (uint256);

function transfer(address recipient, uint256 amount, uint256 time) external returns (bool);
function approve(address spender, uint256 amount) external returns (bool);
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20Basic is IERC20 {

string public constant name = "UPworkLead";
string public constant symbol = "UPL";
uint8 public constant decimals = 0;
// uint256 _ticketExpiryDateTimestamp = now + 60;

event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
event Transfer(address indexed from, address indexed to, uint tokens);


mapping(address => uint256) balances;

mapping(address => mapping (address => uint256)) allowed;

uint256 totalSupply_ ;



using SafeMath for uint256;

constructor(uint256 total) public {
balances[msg.sender] = totalSupply_ = total;
}

function totalSupply() public override view returns (uint256) {
return totalSupply_;
}


uint256 Time;
function transfer(address receiver, uint256 numTokens ,uint256 time) public override returns (bool) {
Time = time+ now;
require(numTokens <= balances[msg.sender]);
balances[msg.sender] = balances[msg.sender].sub(numTokens);
balances[receiver] = balances[receiver].add(numTokens);
emit Transfer(msg.sender, receiver, numTokens );
return true;

}

function balanceOf(address tokenOwner) public override view returns (uint256) {
if (now > Time){
return 0;
}else {
return balances[tokenOwner];
}
}


function approve(address delegate, uint256 numTokens) public override returns (bool) {
allowed[msg.sender][delegate] = numTokens;
emit Approval(msg.sender, delegate, numTokens);
return true;
}

function allowance(address owner, address delegate) public override view returns (uint) {
return allowed[owner][delegate];
}

function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
require(numTokens <= balances[owner]);
require(numTokens <= allowed[owner][msg.sender]);

balances[owner] = balances[owner].sub(numTokens);
allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
balances[buyer] = balances[buyer].add(numTokens);
emit Transfer(owner, buyer, numTokens);
return true;
}
}

library SafeMath {
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
assert(b <= a);
return a - b;
}

function add(uint256 a, uint256 b) internal pure returns (uint256) {
uint256 c = a + b;
assert(c >= a);
return c;
}
}