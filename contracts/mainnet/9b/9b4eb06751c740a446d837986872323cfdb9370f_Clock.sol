/**

 ______     __         ______     ______     __  __        ______   __     __   __     ______     __   __     ______     ______    
/\  ___\   /\ \       /\  __ \   /\  ___\   /\ \/ /       /\  ___\ /\ \   /\ "-.\ \   /\  __ \   /\ "-.\ \   /\  ___\   /\  ___\   
\ \ \____  \ \ \____  \ \ \/\ \  \ \ \____  \ \  _"-.     \ \  __\ \ \ \  \ \ \-.  \  \ \  __ \  \ \ \-.  \  \ \ \____  \ \  __\   
 \ \_____\  \ \_____\  \ \_____\  \ \_____\  \ \_\ \_\     \ \_\    \ \_\  \ \_\\"\_\  \ \_\ \_\  \ \_\\"\_\  \ \_____\  \ \_____\ 
  \/_____/   \/_____/   \/_____/   \/_____/   \/_/\/_/      \/_/     \/_/   \/_/ \/_/   \/_/\/_/   \/_/ \/_/   \/_____/   \/_____/ 
                                                                                                                                   
                                                                                                                                                              
*/

pragma solidity ^0.5.0;

// Standar ERC Token Interface
contract ERC20Interface {
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
   
    function approve(address spender, uint tokens) public returns (bool success);
    function totalSupply() public view returns (uint);
   
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
     
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    
}

// ----------------------------------------------------------------------------
// Safe Math Library 
// ----------------------------------------------------------------------------
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
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}


contract Clock is ERC20Interface {
    
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals; // 18 standard decimal place
    
    uint256 public basePercent = 100;
    uint256 public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        name = "clock.finance";
        symbol = "CLK";
        decimals = 18;
        _totalSupply = 10000000000000000000000;
        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function findBurnPercent(uint256 value) public view returns (uint256)  {
        uint256 roundValue = value.ceil(basePercent);
        uint256 onePercent = roundValue.mul(basePercent).div(30000); // 3 percent burn
        return onePercent;
      }
    
    function transfer(address to, uint value) public returns (bool success) {
        // balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        // balances[to] = safeAdd(balances[to], tokens);
        // emit Transfer(msg.sender, to, tokens);
        // return true;
        
        require(value <= balances[msg.sender]);
        require(to != address(0));
    
        uint256 tokensToBurn = findBurnPercent(value);
        uint256 tokensToTransfer = value.sub(tokensToBurn);
    
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(tokensToTransfer);
    
        _totalSupply = _totalSupply.sub(tokensToBurn);
    
        emit Transfer(msg.sender, to, tokensToTransfer);
        emit Transfer(msg.sender, address(0), tokensToBurn);
        return true;
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
}