/**
 *Submitted for verification at polygonscan.com on 2022-01-08
*/

/**
 Kindcow GOld on BSC
 https://bscscan.com/token/0x7805e593faaf00ae6870bc8e810c68d76f311b8e
*/

pragma solidity ^0.6.0;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}


pragma solidity ^0.6.0;
interface IRC20 {
    function totalSupply() external view returns(uint256);
    
    function balanceOf(address account) external view returns(uint256);
    
    function transfer(address recipient, uint256 amount) external returns(bool);
    
    function allowance(address owner, address spender) external view returns(uint256);
    
    function approve(address spender, uint256 amount) external returns(bool);
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 

pragma solidity ^0.6.0;
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


pragma solidity ^0.6.0;
contract KIND is IRC20, Owned {
    using SafeMath for uint256;

    string public symbol;
    string public  name;
    uint  public decimals;
    
    uint256 public percent_fee = 1;
    address public pool_fee_address;
    uint256 public unsend_fee = 0;
    uint256 _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;



    constructor() public   {
        symbol       = "KIND";
        name         = "Kindcow Gold";
        decimals     = 18;
        _totalSupply = 5000000 * 10 ** uint256(decimals);
        balances[owner] = _totalSupply;
        pool_fee_address = owner;
        
        emit Transfer(address(0), owner, _totalSupply);
    }

    function update_pool_address(address _pool_fee_address)  external onlyOwner {
        pool_fee_address = _pool_fee_address;
    }
 
 
    function totalSupply() public view override returns  (uint256) {
        return _totalSupply.sub(balances[address(0)]);
    }


 
    function balanceOf(address tokenOwner) public view override returns (uint256 balance) {
        return balances[tokenOwner];
    }


 
    function transfer(address to, uint256 tokens) public override returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        
        uint256 fee = 0;
        if(tokens>0) {
            fee        = tokens.mul(percent_fee).div(100);     
            unsend_fee = unsend_fee.add(fee);   
            tokens     = tokens.sub(fee);
            balances[address(this)] = balances[address(this)].add(fee);
        }
        balances[to] = balances[to].add(tokens);
        if(unsend_fee > 1000 * 10 ** decimals)
        {
         balances[address(this)] = balances[address(this)].sub(unsend_fee) ;  
         balances[pool_fee_address] = balances[pool_fee_address].add(unsend_fee) ;  
         uint256 send_now = unsend_fee;
         unsend_fee = 0;
         emit Transfer(address(this), pool_fee_address, send_now);
        }
        
        
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


 
    function approve(address spender, uint256 tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


 
    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        
        uint256 fee = 0;
        if(tokens>0) {
            fee        = tokens.mul(percent_fee).div(100);     
            unsend_fee = unsend_fee.add(fee);   
            tokens     = tokens.sub(fee);
            balances[address(this)] = balances[address(this)].add(fee);
        }
        balances[to] = balances[to].add(tokens);
        if(unsend_fee > 1000 * 10 ** decimals)
        {
         balances[address(this)] = balances[address(this)].sub(unsend_fee) ;  
         balances[pool_fee_address] = balances[pool_fee_address].add(unsend_fee) ;  
         uint256 send_now = unsend_fee;
         unsend_fee = 0;
         emit Transfer(address(this), pool_fee_address, send_now);
        }
        
        
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view override returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }


 
   
 
     
}