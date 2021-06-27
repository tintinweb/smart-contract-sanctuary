/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

pragma solidity 0.8.4;

 

interface ERC20Interface{
    
    function totalSupply() external view returns (uint256);
function balanceOf(address tokenOwner) external view returns (uint);
function allowance(address tokenOwner, address spender)
external view returns (uint);
function transfer(address to, uint tokens) external returns (bool);
function approve(address spender, uint tokens)  external returns (bool);
function transferFrom(address from, address to, uint tokens) external returns (bool);

event Approval(address indexed tokenOwner, address indexed spender,
 uint tokens);
event Transfer(address indexed from, address indexed to,
 uint tokens);
}

contract Saubaan is ERC20Interface{
     string public symbol;
    string public  name;
    uint8 public decimals;
    uint public  _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

     constructor() public {
        symbol = "SAU";
        name = "Saubaan";
        decimals = 2;
        _totalSupply = 19000000000;
        balances[0x9fC33138878450a7475ff8b83028277a6BBc60DB] = _totalSupply;
        emit Transfer(address(0), 0x9fC33138878450a7475ff8b83028277a6BBc60DB, _totalSupply);
     }
         function totalSupply() public view override returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner];
    }
     function transfer(address to, uint tokens) public override returns (bool ) {
         require(tokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
     }
     function approve(address spender, uint tokens) public override returns (bool ) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
      function transferFrom(address from, address to, uint tokens) public override returns (bool ) {
          require(tokens <= balances[from]);
          require(tokens <= allowed[from][msg.sender]);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to] + tokens;
        emit Transfer(from, to, tokens);
        return true;
    }
      function allowance(address tokenOwner, address spender) public override view returns (uint ) {
        return allowed[tokenOwner][spender];
    }
     using SafeMath for uint;

}
library SafeMath{
    function sub(uint a, uint b) internal pure returns(uint){
        assert(b <= a);
        return a - b;
    }
    function add(uint a, uint b) internal pure returns(uint){
        uint c = a + b;
        assert(c >= a);
        return c;
    }
    
}