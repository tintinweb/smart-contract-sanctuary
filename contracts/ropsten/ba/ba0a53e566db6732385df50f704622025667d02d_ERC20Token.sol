/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------

//Hazır ERC20 interfaceidir.
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library 
// ----------------------------------------------------------------------------

//Tüm matematiksel işlemleri bu kütüphaneyle yapabiliriz.
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; 
        
    } 
    function safeMul(uint a, uint b) public pure returns (uint c) { 
        c = a * b; require(a == 0 || c / a == b); 
        
    } 
    function safeDiv(uint a, uint b) public pure returns (uint c) { 
        require(b > 0);
        c = a / b;
    }
}


contract ERC20Token is ERC20Interface, SafeMath {
    
    //Bir tokenin ismi ve sembolü olmalı, bu yüzden bunları tanımlıyoruz.
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    
    uint256 public _totalSupply;
    
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        
        //Tokenımın ismini ve sembolünü belirledim.
        name = "LimitToken";
        symbol = "LMT";
        
        //Yollamak istediğim miktarın yanına 18 tane 0 koyarak gönderiyorum. 18 decimal önerilen sayıdır.
        decimals = 18;
        
        _totalSupply = 100000000000000000000000000;
        
        //Gönderenin token miktarı totalsupply ile belirlendi.
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    //oluşturulan toplam ERC-20 token sayısını belirtir. 
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
    //belirli bir adreste, contract sahibinin hesabında bulunan token sayısını döndürür.
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    //kullanıcının işlemi yapmak için gereken minimum miktarda tokena sahip olup olmadığını kontrol eder.
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    //bakiye kontrol edildikten sonra onaylama işlemi için kullanılmaktadır.
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    //tüm kontroller yapıldıktan sonra, token sahibi transfer için bu fonksiyonu kullanabilir.
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    //belirli bir hesaba payment transferlerini otomatik ödemeye döndürmeyi sağlar.
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}