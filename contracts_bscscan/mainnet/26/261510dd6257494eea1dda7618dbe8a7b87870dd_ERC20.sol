/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

pragma solidity =0.8.0;

// SPDX-License-Identifier: SimPL-2.0

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    
    function approve(address spender, uint256 value) external returns(bool);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
}

abstract contract ContractOwner {
    address immutable public contractOwner = msg.sender;
    
    modifier onlyContractOwner {
        require(msg.sender == contractOwner, "only contract owner");
        _;
    }
}

contract ERC20 is IERC20, ContractOwner {
    string public override name;
    string public override symbol;
    uint8 public override decimals;
    
    uint256 public override totalSupply;
    uint256 public remainedSupply;
    
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    
    constructor(string memory _name, string memory _symbol,
        uint8 _decimals, uint256 _maxSupply) {
        
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        remainedSupply = _maxSupply;
    }
    
    function mint(address to, uint256 amount) external onlyContractOwner {
        require(to != address(0), "zero address");
        require(remainedSupply >= amount, "mint too much");
        
        remainedSupply -= amount;
        totalSupply += amount;
        balanceOf[to] += amount;
        
        emit Transfer(address(0), to, amount);
    }
    
    function _burn(address from, uint256 amount) private {
        require(balanceOf[from] >= amount, "balance not enough");
        
        balanceOf[from] -= amount;
        totalSupply -= amount;
        
        emit Transfer(from, address(0), amount);
    }
    
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
    
    function burnFrom(address from, uint256 amount) external {
        require(allowance[from][msg.sender] >= amount, "allowance not enough");
        
        allowance[from][msg.sender] -= amount;
        _burn(from, amount);
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(to != address(0), "zero address");
        require(balanceOf[from] >= amount, "balance not enough");
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        
        emit Transfer(from, to, amount);
    }
    
    function transfer(address to, uint256 amount) external override returns(bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount)
        external override returns(bool) {
        
        require(allowance[from][msg.sender] >= amount, "allowance not enough");
        
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        
        return true;
    }
    
    function approve(address spender, uint256 amount) external override returns(bool) {
        require(spender != address(0), "zero address");
        
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        
        return true;
    }
}