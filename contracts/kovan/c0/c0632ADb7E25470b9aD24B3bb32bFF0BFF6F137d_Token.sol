/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Token{
    //currency name
    string public name;//="Akira";
    //cuurency symbol
    string public symbol;//="AKA";
    //1 ether = 10^18 wei
    //why? https://ethereum.stackexchange.com/questions/363/why-is-ether-divisible-to-18-decimal-places
    uint public decimals;//=18;
    //max supply for my crypto.
    uint public totalSupply;//=1000000000000000000000000;

    //keeping the track of balences and allowences approved
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    //Events
    event Transfer(address indexed from,address indexed to ,uint value);
    event Approval(address indexed owner,address indexed spender , uint value);

    constructor(string memory _name,string memory _symbol,uint _decimals,uint _totalSupply){
        name=_name;
        symbol=_symbol;
        decimals=_decimals;
        totalSupply=_totalSupply;
        //msg.sender is the address of the token creator
        //assigning all intaial token to the creator.
        balanceOf[msg.sender]=totalSupply;
    }

    function trasfer(address _to,uint value) external returns(bool success){
        //if the balance of sender is greater or equal proceed
            require(balanceOf[msg.sender] >= value,"Not Enough Funds to Transfer!");
            _transfer(msg.sender,_to,value);
            return true;
    }

    //trasfer method that can be reused

    function _transfer(address _from,address _to, uint value) internal {
        //checking _to is an valid address
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - value;
        balanceOf[_to] = balanceOf[_to] + value;
        emit Transfer(_from,_to,value);
    }

    //Approve others to spend on your behalf eg an exchange 

    function approve(address _spender,uint value) external returns(bool){
        //checking _spender is an valid address
        require(_spender != address(0));
        allowance[msg.sender][_spender] = value;
        emit Approval(msg.sender,_spender,value);
        return true;
    }

    function trasferFrom(address _from, address _to,uint value) external returns(bool){
        require( balanceOf[_from]  >=  value);
        require( allowance[_from][msg.sender] >= value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - value;
        _transfer(_from,_to,value);
        return true;

    }
}


//0x617F2E2fD72FD9D5503197092aC168c91465E7f2