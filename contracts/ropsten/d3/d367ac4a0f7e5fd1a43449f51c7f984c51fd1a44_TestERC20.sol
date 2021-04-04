/**
 *Submitted for verification at Etherscan.io on 2021-04-04
*/

// SPDX-License-Identifier: gpl-3.0
pragma solidity >= 0.8.0 < 0.9.0;


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


contract owned {
    address payable public owner;
    
    constructor () {
        owner = payable(msg.sender);
    }
    
    modifier onlyOwner (){
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address payable newOwner) onlyOwner external {
        owner = newOwner;
    }
}

contract TestERC20 is IERC20, owned {
    address payable public immutable ownedUser;
    
    string private constant ERR_NOTOWNEDOWNER = "101";
    
    string public override name;
    string public override symbol;
    uint8 public override immutable decimals = 18;
    uint256 public override totalSupply;
    
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    
    constructor(string memory _name, string memory _symbol, uint256 create) {
        ownedUser = payable(tx.origin);
        name = _name;
        symbol = _symbol;
        totalSupply = create;
        balances[tx.origin] = create;
    }
    
    modifier onlyOwnedUser() {
        require(tx.origin == ownedUser, ERR_NOTOWNEDOWNER);
        _;
    }
    
    function destruct() onlyOwner external {
        selfdestruct(ownedUser);
    }
    
    function balanceOf(address tgt) external override view returns (uint256) {
        return balances[tgt];
    }
    
    function allowance(address tgt, address spender) external override view returns (uint256) {
        return allowed[tgt][spender];
    }
    function approve(address spender, uint256 value) external onlyOwnedUser override returns (bool) {
        allowed[msg.sender][spender] = value;
        return true;
    }
    
    function transfer(address to, uint256 value) external onlyOwnedUser override returns (bool) {
        balances[msg.sender] -= value;
        balances[to] += value;
        return true;
    }
    function transferFrom(address from, address to, uint256 value) external onlyOwnedUser override returns (bool){
        allowed[from][msg.sender] -= value;
        
        balances[from] -= value;
        
        
        if (to == address(0)) {
            totalSupply -= value;
            emit Burn(from, value);
        } else {
            balances[to] += value;
        }
        
        return true;
    }
    
    event Burn(address indexed owner, uint256 value);
    event Mint(address indexed owner, uint256 value);
    
    function mint(address to, uint256 value) external onlyOwnedUser {
        balances[to] += value;
        totalSupply += value;
        emit Mint(to, value);
    }
}