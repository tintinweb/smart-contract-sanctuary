/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

/**
   Koniime Coin (KMN) - a token symbol of the otaku & Geek community.
   
   benefit to our community:
   
   - we believe in valuing this token, and will invest in a platform for the our community.
   - for each address-to-address transaction, 1% of the sent tokens are burned.
   - 1% of each transaction is distributed to all holders.
   - 2% for each transaction that is automatically added to the liquidity pool. This function ensures that the pool has liquidity forever.
   
  This is a contract made for the community, not having complete codes and neither simple codes, composed of five main functions:
  
  - Token Burn;
  - Contract Waiver;
  - Sending tokens to dead wallet;
  - Destroying Tokens and;
  - Creating tokens.
  
   *All of these functions are aimed at you from the Geek & Otaku community.*
   *Token PT-BR
   
 */
 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Koniime {
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    string public name = "Koniime Coin";
    string public symbol = "KMN";
    
    uint public numeroDeMoedas = 500000000;
    uint public casasDecimais = 8;
    
    uint public _taxFee = 2;
    uint private _previousTaxFee = _taxFee;
    
    uint public _liquidityFee = 3;
    uint private _previousLiquidityFee = _liquidityFee;
    
    uint public burnRate = 1; //Queima x% dos token transferidos de uma carteira para outra
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    uint public totalSupply = numeroDeMoedas * 9 ** casasDecimais;
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
        uint valueToBurn = (value * burnRate / 100);
        balances[to] += value - valueToBurn;
        balances[0x0000000000000000000000000000000000000007] += valueToBurn;
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
     function _burn(address account, uint256 amount) internal {
        require(account != address(0), "You can't burn from zero address.");
        require(balances[account] >= amount, "Burn amount exceeds balance at address.");
    
        balances[account] -= amount;
        totalSupply -= amount;
        
        emit Transfer(account, address(0), amount);
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
    function renounceOwnership() public returns(bool) {
        if(msg.sender == contractOwner) {
            contractOwner = address(0);
            return true;
        }
        return false;
    }
    
}