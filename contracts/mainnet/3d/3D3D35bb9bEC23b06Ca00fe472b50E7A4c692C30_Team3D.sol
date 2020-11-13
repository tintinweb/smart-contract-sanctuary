pragma solidity ^0.5.17;

/*
  _______                   ____  _____  
 |__   __|                 |___ \|  __ \ 
    | | ___  __ _ _ __ ___   __) | |  | |
    | |/ _ \/ _` | '_ ` _ \ |__ <| |  | |
    | |  __/ (_| | | | | | |___) | |__| |
    |_|\___|\__,_|_| |_| |_|____/|_____/ 
    
*/
interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint tokens, address token, bytes calldata data) external;
}


contract Presale {
    mapping (address => uint256) public balances;
    address[] public keys;
    uint public initialTokens;
}


contract Team3D is ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    string public constant name  = "Vidya";
    string public constant symbol = "VIDYA";
    uint8 public constant decimals = 18;

    address owner;
    bool initialized;
    uint256 startBlock;
    uint256 _totalSupply = 50000000 * (10 ** 18);
    Presale presale;

    modifier fairStart() {
        require(block.number > startBlock + 5);
        if (block.number < startBlock + 10) {
            require(tx.gasprice <= 2000000000000);
        }
        _;
    }

    function initialize(address _presaleAddr) public {
        require(!initialized);
        owner = tx.origin;
        presale = Presale(_presaleAddr);
        balances[tx.origin] = presale.initialTokens();
        balances[msg.sender] =  _totalSupply - presale.initialTokens();
        
        startBlock = block.number;
        initialized = true;

        emit Transfer(address(0), tx.origin, presale.initialTokens());
        emit Transfer(address(0), msg.sender, _totalSupply - presale.initialTokens());
    }

    function distributePresale(uint _min, uint _max) public {
        require(msg.sender==owner);
        for (uint i=_min; i < _max; i++) {
            address _addr = presale.keys(i);
            transfer(_addr, presale.balances(_addr));
            }
        }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address addr) public view returns (uint256) {
        return balances[addr];
    }

    function allowance(address addr, address spender) public view returns (uint256) {
        return allowed[addr][spender];
    }

    function transfer(address to, uint256 value) public fairStart returns (bool) {
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

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}