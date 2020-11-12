//"SPDX-License-Identifier: UNLICENSED"

pragma solidity ^0.5.0;

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

interface IERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function approve(address spender, uint tokens) external returns (bool success);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function totalSupply() external view returns (uint);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}
contract ERC20 is IERC20, Owned {
    
    using SafeMath for uint;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint private tokenTotalSupply;
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    
    event Burn(address indexed burner, uint256 value);
    
    constructor(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol; 
        decimals = 18;
        tokenTotalSupply = 30000000000000000000000000;
        balances[0x89aa711B9F2C677aeFc79F15612597A57B0D6a93] = tokenTotalSupply;
        emit Transfer(address(0x0), 0x89aa711B9F2C677aeFc79F15612597A57B0D6a93, tokenTotalSupply);
    }
    
    modifier canApprove(address spender, uint value) {
        require(spender != msg.sender, 'Cannot approve self');
        require(spender != address(0x0), 'Cannot approve a zero address');
        require(balances[msg.sender] >= value, 'Cannot approve more than available balance');
        _;
    }
        
    function transfer(address to, uint value) external returns(bool success) {
        require(balances[msg.sender] >= value);
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) external returns(bool success) {
        uint allowance = allowed[from][msg.sender];
        require(balances[from] >= value && allowance >= value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) external canApprove(spender, value) returns(bool approved) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) external view returns(uint) {
        return allowed[owner][spender];
    }

    function balanceOf(address owner) external view returns(uint) {
        return balances[owner];
    }
    
    function totalSupply() external view returns(uint) {
        return tokenTotalSupply;
    }
    
    function burn(address _who, uint _value) external returns(bool success) {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who].sub(_value);
        tokenTotalSupply = tokenTotalSupply.sub(_value);
        emit Burn(_who, _value);
        return true;
    }
    
    function burnFrom(address _from, uint _value) external returns(bool success) {
        require(balances[_from] >= _value);                
        require(_value <= allowed[_from][msg.sender]); 
        balances[_from] =  balances[_from].sub(_value);                        
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);             
        tokenTotalSupply = tokenTotalSupply.sub(_value);                             
        emit Burn(_from, _value);
        return true;
    }
    
    function transferAnyERC20Token(address _tokenAddress, uint _amount) external onlyOwner returns(bool success) {
        IERC20(_tokenAddress).transfer(owner, _amount);
        return true;
    }
}