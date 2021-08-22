/**
 *Submitted for verification at BscScan.com on 2021-08-21
*/

pragma solidity =0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external;
    function transfer(address recipient, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
}

contract IrynkaCoin is IBEP20 {
    string _name;
    string _symbol;
    address _owner;
    uint8 _decimals = 18;
    uint256 _totalSupply;
    mapping(address => uint256) _balance;
    mapping(address => mapping(address => uint256)) _allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(string memory name, string memory symbol, uint totalSupply) {
        _name = name;
        _symbol = symbol;
        _owner = msg.sender;
        _totalSupply = totalSupply;
        _balance[msg.sender] = totalSupply;
    }
    
    function name() public view returns(string memory) {
        return _name;
    }
    
    function symbol() public view returns(string memory) {
        return _symbol;
    }
    
    function owner() public view returns(address) {
        return _owner;
    }
    
    function decimals() public override view returns(uint8) {
        return _decimals;
    }
    
    function totalSupply() public override view returns(uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address owner) external override view returns(uint256) {
        return _balance[owner];
    }
    
    function allowance(address owner, address spender) public override view returns(uint256) {
        return _allowance[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override {
        _allowance[msg.sender][spender] = amount;
        
        emit Approval(msg.sender, spender, amount);
    }
    
    function transfer(address to, uint256 amount) public override {
        require(_balance[msg.sender] >= amount, "IrynkaCoin: Not enough balance");
        
        _balance[msg.sender] -= amount;
        _balance[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
    }
    
    function transferFrom(address _from, address _to, uint256 amount) public override {
        require(_allowance[_from][_to] >= amount, "IrynkaCoin: Not allowed");
        require(_balance[_from] >= amount, "IrynkaToken: Not enough balance");
        
        _balance[_from] -= amount;
        _balance[_to] += amount;
        _allowance[_from][_to] -= amount; 
        
        emit Transfer(_from, _to, amount);
    }

}