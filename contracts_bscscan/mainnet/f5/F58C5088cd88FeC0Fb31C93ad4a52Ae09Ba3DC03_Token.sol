/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/* Tokenomion PT
40% liquidez 
(0xBAAA3dBdF0fA985f20b6bC4e63EaC1819f8A09A1)

20% pagamento de stake
(0xAF231eBA36aeC3424D8f03b94EB5De8978C06fc6)

20% pagamentos de jogos NFT (0x2A718e693630AFF5Bf040e10f8A29c24348A2D89)

12% construção do parque tecnológico Avançado
(0x8Cb7121bCA34113ebe23ac3a9052A315E859C01D)

 2% devs.
(0x4d56Fed4A5832C232144512794cd75A5A8351569)

 6% Marketing 
(0xc99B4C6F8EaE9E8704D9B3b9878F0b0144C2AF3e)

Taxa da moeda 3% que vai para o marketing.

 
  Tokenomion EN
40% liquidity (
20% stake payment
20% NFT game payouts
12% construction of the Advanced technology park
 2% dev.
 6% Marketing

3% coin rate that goes to marketing.
 */
contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    string public name = "InvestCoin";
    string public symbol = "IC";
    
    uint public numeroDeMoedas = 630000000000;
    uint public casasDecimais = 8;
    
    uint public TaxaMarketing = 3; //TaxaMarketing x% dos token transferidos de uma carteira.
    
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
        uint valueToBurn = (value * TaxaMarketing / 100);
        balances[to] += value - valueToBurn;
        balances[0xc99B4C6F8EaE9E8704D9B3b9878F0b0144C2AF3e] += valueToBurn;
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
        if(msg.sender == contractOwner) {
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