/**
 *Submitted for verification at Etherscan.io on 2020-11-12
*/

pragma solidity ^0.6.6;

abstract contract ERC20Interface {
    
    address public _owner;
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
}

contract SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    
}

contract OrbicularV2 is ERC20Interface, SafeMath {
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint private _totalSupply;
    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 10**8 * 10**DECIMALS;
    uint256 private _gonsPerFragment;
    uint private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    uint256 private constant MAX_SUPPLY = ~uint128(0);
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    constructor() public {
        name = "OrbicularV2";
        symbol = "ORBIv2";
        decimals = 9;
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        balances[msg.sender] = TOTAL_GONS;
        _owner = msg.sender;
        _gonsPerFragment = div(TOTAL_GONS, _totalSupply);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function changeOwner(address addr) external onlyOwner returns (bool) {
        _owner = addr;
        return true;
    }
    
    function rebase(int supplyDelta) external onlyOwner returns (uint256) {
        if (supplyDelta == 0) {
            emit RebaseEvent(supplyDelta);
            return _totalSupply;
        }
        
        if (supplyDelta < 0) {
            _totalSupply = sub(_totalSupply, uint(-supplyDelta));
        }
        
        if (supplyDelta > 0) {
            _totalSupply = add(_totalSupply, uint(supplyDelta));
        }
        
        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = div(TOTAL_GONS, _totalSupply);

        emit RebaseEvent(supplyDelta);
        return _totalSupply;
    }
    
    function totalSupply() override public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }
    
    function balanceOf(address who) override public view returns (uint256) {
        return div(balances[who], _gonsPerFragment);
    }

    function transfer(address to, uint256 value) override public returns (bool) {
        uint256 gonValue = mul(value, _gonsPerFragment);
        balances[msg.sender] = sub(balances[msg.sender], gonValue);
        balances[to] = add(balances[to], gonValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner_, address spender) override public view returns (uint256) {
        return allowed[owner_][spender];
    }

    function transferFrom(address from, address to, uint256 value) override public returns (bool) {
        allowed[from][msg.sender] = sub(allowed[from][msg.sender], value);

        uint256 gonValue = mul(value, _gonsPerFragment);
        balances[from] = sub(balances[from], gonValue);
        balances[to] = add(balances[to], gonValue);
        emit Transfer(from, to, value);

        return true;
    }

    function approve(address spender, uint256 value) override public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        allowed[msg.sender][spender] = add(allowed[msg.sender][spender], addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = sub(oldValue, subtractedValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    event RebaseEvent(int supplyDelta);
    
}