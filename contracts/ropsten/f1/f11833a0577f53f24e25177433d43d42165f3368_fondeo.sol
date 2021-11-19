/**
 *Submitted for verification at Etherscan.io on 2021-11-18
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

contract fondeo {
    IERC20 Mytok;
    
    uint public capital;
    address public owner;
    address[] public users;
    
    mapping (address => uint) public cuentas;
    
    constructor() {
        owner = 0x4D3BFd632914f789236C5B16be641823593736c3;
        address mtaddres = 0x4558930Ea8630b93A5aBA376EEe8202c7001046a;
        Mytok = IERC20(mtaddres);
    }
    
    modifier Onlyowner {
        require(owner == msg.sender);
        _;
    }
    
    function deposito() public payable {
        cuentas[msg.sender] += msg.value;
        users.push(msg.sender);
        capital += msg.value;
    }
    
    function getsupply() public view returns(uint) {
        return Mytok.totalSupply();
    }

    function withdraw() public payable Onlyowner {
        payable(owner).transfer(address(this).balance);
        for (uint index=0; index < users.length; index++) {
            address indice = users[index];
            Mytok.transfer(indice, 1);
            cuentas[indice] = 0;
            
        }
        users = new address[](0);
        capital = 0;
        
    }
}