/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Mytoken is IERC20 {
    
    string public name;
    string public symbol;
    uint8 private decimales;
    uint256 private suply;
    address owner;
    
    mapping(address => uint) balances;
    mapping(address => mapping (address => uint256)) allowed;

    constructor() {
        name = "Peso";
        symbol = "ARS";
        decimales = 0;
        suply = 500;
        
        owner = msg.sender;
        balances[owner] = suply;
    }
    
    modifier OnlyOwner {
        require(owner == msg.sender);
        _;
    }
    
    function totalSupply() public view override returns (uint256) {
        return suply;
    }
    
    function balanceOf(address _account) public view override returns (uint256) {
        return balances[_account];
    }
    
    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address _owner, address delegate) public override view returns (uint) {
        return allowed[_owner][delegate];
    }

    function transferFrom(address _owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[_owner]);    
        require(numTokens <= allowed[_owner][msg.sender]);
        balances[_owner] -= numTokens;
        allowed[_owner][msg.sender] -= numTokens;
        balances[buyer] += numTokens;
        emit Transfer(_owner, buyer, numTokens);
        return true;
    }
}