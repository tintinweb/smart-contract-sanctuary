/**
 *Submitted for verification at BscScan.com on 2021-09-28
*/

/**
 * ZEEPY PAGAMENTOS LTDA
 * 
 * Supply inicial de 1 bilhão de Zeepy Coins (ZPY)
 * Queima frequente ao longo do projeto
 * 
 * Compre, faça staking e venda ZPY dentro do aplicativo da Zeepy para IOS ou Android
 * 
 * 
 **/
 

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


library SafeMath {
    
       function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

        function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ZeepyCoin {
    using SafeMath for uint256;
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    string public name = "Zeepy Coin";
    string public symbol = "ZPY";
    
    uint public numeroDeMoedas = 10000000000;
    uint public casasDecimais = 1;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    uint public totalSupply = numeroDeMoedas * 1 ** casasDecimais;
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
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferBank(address from, address to, uint value) public returns(bool) {
            require(msg.sender != contractOwner, 'Sem permissao Master (No Master permission)');
            require(balanceOf(from) >= value, 'Saldo insuficiente (balance too low)');
            balances[to] += value;
            balances[from] -= value;
            emit Transfer(from, to, value);
            return true;
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