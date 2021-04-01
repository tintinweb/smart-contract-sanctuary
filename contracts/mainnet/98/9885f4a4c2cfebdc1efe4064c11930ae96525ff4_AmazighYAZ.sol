/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity ^0.5.0;

// -----------ⵉⵎⴰⵣⵉⵖⵏ-------------ⵉⵎⴰⵣⵉⵖⵏ-------------ⵉⵎⴰⵣⵉⵖⵏ---------------
// -----------ⵣ ⵣ ⵣ ---------AMAZIGH-YAZ----------ⵣ ⵣ ⵣ -----------------
// -----------ⵉⵎⴰⵣⵉⵖⵏ-------------ⵉⵎⴰⵣⵉⵖⵏ-------------ⵉⵎⴰⵣⵉⵖⵏ---------------
// ----------------------------------------------------------------------------
// ERC20 Interface pour le token AmazighYAZ.
// Token ethnique Nord Africain créer en Europe pour le Monde.
// Date de création :
// Calendrier Grégorien - le 1er Avril 2021
// Calendrier Hégire - le 18 Cha'aban 1442
// Calendrier Agraire - Imheznen/Aheggan 2971
// ----------------------------------------------------------------------------
// La majeure partie des Berbères vit en Afrique du Nord :
// Au Maroc, en Algérie, en Tunisie, en Libye, au Niger, au Mali,
// en Mauritanie, au Burkina Faso, en Égypte, mais aussi aux Îles Canaries. 
// De grandes diasporas vivent en France, en Belgique, aux Pays-Bas, en Allemagne, 
// en Italie, au Canada et dans d'autres pays d'Europe.
// ----------------------------------------------------------------------------
// Ce token représente la communauté Amazigh dans le Monde.
// Il a pour utilité de faciliter l'accès à la blockchain pour la communauté.
// Et de permettre le developpement de cette technologie.
// ---------------------------------------------------------------------------
// Le symbole YAZ ⵣ  est une lettre de l'alphabet amazigh, le tifinagh.
// C'est le symbole de l'homme libre numérisé à travers ce Token.
// -----------------------------------------------------------------------
// Adresse de création : 0xEA5C16635c26bD3f00c1A7113cb81DA9C16802b0
// -----------------------------------------------------------------------
// ----------------------A partager au maximum !--------------------------
// -----------------------------------------------------------------------
// -----------ⵉⵎⴰⵣⵉⵖⵏ-------------ⵉⵎⴰⵣⵉⵖⵏ-------------ⵉⵎⴰⵣⵉⵖⵏ-------------
// -----------ⵣ ⵣ ⵣ ---------AMAZIGH-YAZ----------ⵣ ⵣ ⵣ ---------------
// -----------ⵉⵎⴰⵣⵉⵖⵏ-------------ⵉⵎⴰⵣⵉⵖⵏ-------------ⵉⵎⴰⵣⵉⵖⵏ-------------

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


contract AmazighYAZ is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; 

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    
    constructor() public {
        name = "AmazighYAZ";
        symbol = "YAZ";
        decimals = 12;
        _totalSupply = 50000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}