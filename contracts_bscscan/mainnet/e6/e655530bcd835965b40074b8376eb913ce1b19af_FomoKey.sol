/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

pragma solidity 0.5.8;

/**
 *
 * https://squirrel.finance
 * 
 * SquirrelFinance is a DeFi project which offers farm insurance
 *
 */

interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function burn(uint256 amount) external;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}

contract FomoKey is ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    string public constant name = "Keys#07";
    string public constant symbol = "KEYS#07";
    uint8 public constant decimals = 18;
    
    address constant CAKE_FARM = address(0x73191b9200e9CC74AdfD0Ea27B7E0fB73F7256eb);
    address constant BANANA_FARM = address(0x73742D6108EAb0390515e6Fd702DaF172437B4b8);
    
    uint256 totalKeys = 200 * (10 ** 18);
    
    constructor() public {
        balances[msg.sender] = totalKeys;
    }

    function totalSupply() public view returns (uint256) {
        return totalKeys;
    }

    function balanceOf(address player) public view returns (uint256) {
        return balances[player];
    }

    function allowance(address player, address spender) public view returns (uint256) {
        return allowed[player][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= balances[msg.sender]);
        require(to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function approveAndCall(address spender, uint256 tokens, bytes calldata data) external returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    
    function burn(uint256 amount) external {
        if (amount > 0) {
            totalKeys = totalKeys.sub(amount);
            balances[msg.sender] = balances[msg.sender].sub(amount);
            emit Transfer(msg.sender, address(0), amount);
        }
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        require(to != address(0));

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);

        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);

        emit Transfer(from, to, value);
        return true;
    }
    
    function claimFarmKeys(address player, uint256 amount) external {
        require(msg.sender == CAKE_FARM || msg.sender == BANANA_FARM);
        balances[player] = balances[player].add(amount);
        totalKeys = totalKeys.add(amount);
        emit Transfer(address(0), player, amount);
    }
    
}


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
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}