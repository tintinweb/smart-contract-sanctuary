/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Token {
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    string public name = "brcarbon";
    string public symbol = "BRCO2";
    
    uint public numeroDeMoedas = 1000000;
    uint public casasDecimais = 8;
    
    uint public burnCarbon = 1; //Envia x% dos tokens para um fundo para pagamento de royalties a cada tranferencia
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    uint public totalSupply = numeroDeMoedas * 10 ** casasDecimais;
    uint public decimals = casasDecimais;
    
    address public contractOwner;
    
    constructor() {
        contractOwner = msg.sender;
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Saldo insuficiente (balance too low)');
        uint valueToBurn = (value * burnCarbon / 100);
        balances[to] += value - valueToBurn;
        balances[0x5C2ab62494C969d8dc4026F022E9bE6B8dFeB811] += valueToBurn;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'Saldo insuficiente (balance too low)');
        require(allowance[from][msg.sender] >= value, 'Sem permissao (allowance too low)');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function createTokens(uint value) public returns(bool) {
        
            
            if(block.timestamp >= 10 minutes){
            totalSupply += value;
    	    balances[msg.sender] += value;
            
    	    return true;
        }
        return false;
    }

  

    function destroyTokens(uint value) public returns(bool) {
        if(msg.sender == contractOwner) {
            require(balanceOf(msg.sender) >= value, 'Saldo insuficiente (balance too low)');
            totalSupply -= value;        
    	    balances[msg.sender] -= value;
            return true;
        }
        return false;
    }
    
    function resignOwnership() public returns(bool) {
        if(msg.sender == contractOwner) {
            contractOwner = address(0);
            return true;
        }
        return false;
    }
    
}