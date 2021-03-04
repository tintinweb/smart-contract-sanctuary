/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

pragma solidity ^0.5.0;

//ERC-20, token uygulamak için Ethereum blok zincirindeki akıllı sözleşmeler için kullanılan teknik bir standarttır. 
// ERC20 Interface hazırdı. İçinde fonksiyonlar var. İşlevlerini aşağıda göreceğiz.
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

// Safe Math Library matematiksel işlemlerin doğruluğu için kullanılıyor.
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}

//ERC20Token contractında isim, sembol ve decimal değerlerini belirledim.
contract ERC20Token is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    
    uint256 public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
 
    constructor() public {
        name = "PurpleToken";
        symbol = "PRP";
        decimals = 18; //18 decimal önerilen değerdi. İzin verilen maksimum ondalık basamak sayısı 18'dir.
        //Token gönderirken göndermek istediğim miktarın yanına 18 tane 0 koyarak gönderiyorum.
        _totalSupply = 10000000000000000000000000;
        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    //Bu fonksiyon oluşturulan toplam ERC20 token sayısını belirtiyor.
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
    //Bu fonksiyon belirli bir adreste, contract sahibinin hesabında bulunan token sayısını döndürüyor.
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    //Bu fonksiyon kullanıcı gerekli sayıda tokena sahip değilse, işlemin iptal edilmesini sağlar.
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    //Bu fonksiyon tekrar kontrol amaçlı bir fonksiyondur. Contract sahibi onay verir.
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    //Bu fonksiyon, contract sahibinin tokeni başka bir adrese göndermesini sağlar.
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    //Bu fonksiyon belirli bir hesaba transferlerini otomatik olarak göndermeyi sağlar.
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}