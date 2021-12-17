/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface ERC20Interface
{
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address indexed from, uint tokens);
    event Mint(address indexed to, uint tokens);
}

contract ElonShibask is ERC20Interface, Ownable
{
    string public name = "Elon Shibask";
    string public symbol = "ESHIBASK";
    uint public decimals = 18;
    uint public override totalSupply = 1000000000 * 10**18;
    
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    address[] public mintAllowed;
    
    constructor ()
    {
        balances[msg.sender] = totalSupply;
        
        mintAllowed.push(msg.sender);
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint balance)
    {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint tokens) public override returns (bool success)
    {
        require(balances[msg.sender] >= tokens, "Not enough tokens");
        require(tokens > 0, "Amount can't be zero");
        
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }
    
    function allowance(address tokenOwner, address spender) view public override returns(uint)
    {
        return allowed[tokenOwner][spender];
    }
    
     function approve(address spender, uint tokens) public override returns (bool success)
     {
         require(balances[msg.sender] >= tokens, "Select another token value");
         
         allowed[msg.sender][spender] = tokens;
         
         emit Approval(msg.sender, spender, tokens);
         return true;
     }
    
    function transferFrom(address from, address to, uint tokens) public override returns (bool success)
    {
        require(allowed[from][msg.sender] >= tokens);
        require(balances[from] >= tokens, "Not enough tokens");
        require(tokens > 0, "Amount can't be zero");
        
        balances[from] -= tokens;
        balances[to] += tokens;
        allowed[from][msg.sender] -= tokens;
        
        emit Transfer(from, to, tokens);
        
        return true;
    }
    
    function burn(uint tokens) public returns (bool success)
    {
        require(balances[msg.sender] >= tokens, "Not enough tokens");
        require(tokens > 0, "Amount can't be zero");
        
        balances[msg.sender] -= tokens;
        totalSupply -= tokens;
        
        emit Burn(msg.sender, tokens);
        
        return true;
    }
    
    function burnFrom(address from, uint tokens) public returns (bool success)
    {
        require(allowed[from][msg.sender] >= tokens, "Not enough tokens");
        require(balances[from] >= tokens, "Not enough tokens");
        require(tokens > 0, "Amount can't be zero");
        
        balances[from] -= tokens;
        totalSupply -= tokens;
        allowed[from][msg.sender] -= tokens;
        
        emit Burn(from, tokens);
        
        return true;
    }
    
    function mint(uint tokens) public returns (bool success)
    {
        require(tokens > 0, "Amount can't be zero");

        (uint index, bool finded) = findAddress(msg.sender);
        
        require(finded, "The address isn't in this list");
        
        balances[msg.sender] += tokens;
        totalSupply += tokens;
        
        emit Mint(msg.sender, tokens);
        
        return true;
    }
    
    function allowMint(address allowedAddress) public onlyOwner returns (bool success)
    {
        mintAllowed.push(allowedAddress);
        
        return true;
    }
    
    function denyMint(address deniedAddress) public onlyOwner returns (bool success)
    {
        (uint index, bool finded) = findAddress(deniedAddress);

        require(finded, "The address isn't in this list");

        mintAllowed[index] = mintAllowed[mintAllowed.length-1];
        
        mintAllowed.pop();
        
        return true;
    }

    function findAddress(address addressToFind) private view returns (uint index, bool finded)
    {      
        for (uint i; i< mintAllowed.length; i++)
        {
          if (mintAllowed[i] == addressToFind) return (i, true);
        }
    }
}