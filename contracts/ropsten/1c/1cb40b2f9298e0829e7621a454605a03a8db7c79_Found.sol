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


contract Found {
    
    IERC20 mitoken;
    
    uint public capital;
    address[] public clientes;
    address private owner;
    
    mapping(address => uint) public cuentas;
    
    constructor() {
        owner = msg.sender;
        address mtok = 0x81275c43E82b495063c0AD671b205343293C1e68;
        mitoken = IERC20(mtok);
    }
    
    modifier OnlyOwner {
        require(owner == msg.sender);
        _;
    }
    
    function deposito() public payable {
        cuentas[msg.sender] += msg.value;
        clientes.push(msg.sender);
        capital += msg.value;
        //address recivier = clientes.length - 1;
        mitoken.transfer(msg.sender, 1);
    }
    
    function withdraw() public payable OnlyOwner {
        payable(owner).transfer(address(this).balance);
        for (uint index = 0; index < clientes.length; index++) {
            address indice = clientes[index];
            cuentas[indice] = 0;
            
        }
        clientes = new address[](0);
        capital = 0;
        
    }
    
    
}