/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity ^0.4.26;

//Nós precisamos trilhar um caminho novo, dinamitar toda uma estrutura falida, 
//perpetuada de uma forma cruel para que alguns tenham muito, outros tenham alguma coisa 
//e muitos não tenham nada. Frear a ilusão do ter é acima de tudo uma questão de sobrevivência. 
//Não podemos mais negar que precisamos refletir muito a respeito ou a Terra 
//vai continuar existindo sem os seres humanos, se é que ainda somos."

//BLW HUMANITARIAN INNOVATION Token se destina a promover uma Inovação Humanitaria.
//Diferente do Green New Deal a Inovação Humitária que propomos tem como objetivo principal
//ajudar na reconstrução da humanidade, reflorestando o planeta, combatendo a fome, gerando
//oportunidade de trabalho digno, incentivando a educação independe de gênero, etnia ou classe
//ecoômica, combatendo o racismo, o discurso de ódio, a misoginia, todas as formas de violência
//contra as mulheres e crianças, entre outras tantas causas necessárias para a transformação da 
//sociedade que vivemos. É preciso uma sociedade mais justa, mais humana, mais fraterna e conectada
//com a sobrevivência do planeta que vivemos. O conceito de inovação humanitária que defendemos
//é o da brasileira Monica Gonçalves, sócia da BLW GAME BR.

// We need to take a new path, dynamite a whole failed structure,
// perpetuated in a cruel way so that some have a lot, others have something
// and many have nothing. Stopping the illusion of having is above all a question of survival.
// We can no longer deny that we need to reflect a lot about it or the Earth
// it will continue to exist without human beings, if we still are. "

// BLW HUMANITARIAN INNOVATION Token is intended to promote Humanitarian Innovation.
// Unlike the Green New Deal, the Humanitarian Innovation we propose has as its main objective
// help in the reconstruction of humanity, reforesting the planet, fighting hunger, generating
// decent work opportunity, encouraging education regardless of gender, ethnicity or class
// economics, fighting racism, hate speech, misogeny, all forms of violence
// against women and children, among many other causes necessary for the transformation of
// society we live in. A more just, more humane, more fraternal and connected society is needed
// with the survival of the planet we live on. The concept of humanitarian innovation that we defend
// is that of Brazilian Monica Gonçalves, partner at BLW GAME BR. 

// ----------------------------------------------------------------------------
// 'BLW HUMANITARIAN INNOVATION' token and crowdsale Contract
//
// Deployed to : 0x5fc1ea89624b3a88969e9d6dc94c9d671a5c41bb
// Symbol      : BLWHINN
// Name        : BLW HUMANITARIAN INNOVATION
// Total supply: 36000000000000
// Decimals    : 18
//Version: 0.1

//-----------------------------------------------------------------------------
// (c) Thank you: Moritz Neto with BokkyPooBah / Bok Consulting Pty Ltd Au 2017. The MIT Licence.
//Edited by BLW GAME BR
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------

contract Owned {
    
    address public owner;
    address public newOwner;
    uint receiveAmount;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Own() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    
     function receive() public payable  {  
        receiveAmount = msg.value;  
    }  
    
       function getOwnerBalance() constant public returns (uint) {
        return owner.balance;
     
}
     function getTotalAmount() public view returns (uint) {
        return receiveAmount;
    }  
    
  function withdrawAmount(uint256 amount) public {
        require(owner == msg.sender);
        require(address(this).balance >= amount);
        msg.sender.transfer(amount);
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------

contract BLW is ERC20Interface, Owned, SafeMath {
   
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


// ------------------------------------------------------------------------
// Constructor
// ------------------------------------------------------------------------
   
    constructor() public {
        
        symbol = "BLWHINN";
        name = "BLW HUMANITARIAN INNOVATION";
        _totalSupply = 36000000000000000000000000000000;
        decimals = 18;
         balances[0x38e479217a00E2c8Aa673d4A5bB02E561c265dF5] = _totalSupply;
        emit Transfer(address(0), 0x38e479217a00E2c8Aa673d4A5bB02E561c265dF5 , _totalSupply);
        
    }

// ------------------------------------------------------------------------
// Total supply
// ------------------------------------------------------------------------
    
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

// ------------------------------------------------------------------------
// Get the token balance for account `tokenOwner`
// ------------------------------------------------------------------------
   
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

// ------------------------------------------------------------------------
// Transfer the balance from token owner's account to `to` account
// - Owner's account must have sufficient balance to transfer
// - 0 value transfers are allowed
// ------------------------------------------------------------------------
   
    function transfer(address to, uint tokens) public returns (bool success) {
        
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

// ------------------------------------------------------------------------
// Token owner can approve for `spender` to transferFrom(...) `tokens`
// from the token owner's account
//
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// recommends that there are no checks for the approval double-spend attack
// as this should be implemented in user interfaces
// ------------------------------------------------------------------------
    
    function approve(address spender, uint tokens) public returns (bool success) {
        
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

// ------------------------------------------------------------------------
// Transfer `tokens` from the `from` account to the `to` account
//
// The calling account must already have sufficient tokens approve(...)-d
// for spending from the `from` account and
// - From account must have sufficient balance to transfer
// - Spender must have sufficient allowance to transfer
// - 0 value transfers are allowed
// ------------------------------------------------------------------------
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
       
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
       emit  Transfer(from, to, tokens);
        return true;
    }

// ------------------------------------------------------------------------
// Returns the amount of tokens approved by the owner that can be
// transferred to the spender's account
// ------------------------------------------------------------------------
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

// ------------------------------------------------------------------------
// Token owner can approve for `spender` to transferFrom(...) `tokens`
// from the token owner's account. The `spender` contract function
// `receiveApproval(...)` is then executed
// ------------------------------------------------------------------------
   
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

// ------------------------------------------------------------------------
//  BLWHINN per 0.00005ETH
// ------------------------------------------------------------------------
    
    function() public payable {
 
        require(msg.value >= 0.00005 ether);
        uint tokens;
        tokens = msg.value * 1;
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        _totalSupply = safeAdd(_totalSupply, tokens);
        emit Transfer(address(0), msg.sender, tokens);
        owner.transfer(msg.value);
    }

// --------------------------------------------------------------------------------------------------------
// Owner can transfer out any accidentally sent ERC20 tokens accidentally sent back to his contract address
// --------------------------------------------------------------------------------------------------------
    
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

 }