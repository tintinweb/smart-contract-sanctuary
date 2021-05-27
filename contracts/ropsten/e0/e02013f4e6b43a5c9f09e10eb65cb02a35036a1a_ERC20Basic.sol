/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity ^0.5.10;

contract ERC20Basic {

    // [!!!] muss vor dem Kompilieren ausgefuellt werden.  
    string public constant name = "VentureGateToken";
    string public constant symbol = "VG";
    uint8 public constant decimals = 0;  

    // [info] Events dienen als Rückantwort für Apps zur besseren Darstellung der Vorgaenge
    // --> optional
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    // [info] In diesem Mapping werden die Token-Guthaben aller beteiligten Wallet-Adressen gespeichert. 
    mapping(address => uint256) balances;
    
    // [info] Betrifft die Funktionen "allowance" und "transferFrom".
    // [info] In diesem Mapping wird gespeichert welche Wallet gegenueber einer anderen Wallet
    // eine Freigabe zur Token-Uebernahme erteilt hat und in welche Anzahl an Token freigegeben wurde. 
    mapping(address => mapping (address => uint256)) allowed;
    
    // [info] In "totalSupply_" wird die Gesamtanzahl der Token gespeichert.
    uint256 totalSupply_;

    // [info] Verknuepfung mit "library SafeMath" (siehe unten)
    using SafeMath for uint256;

    // [!!!] kurz vor dem Deployment muss noch die gewuenschte Token-Gesamtanzahl angegeben werden. 
    // --> Alle Token werden dann zu Beginn der Wallet gutgeschrieben, von der aus der Contract in die Blockchain legt wurde. 
   constructor(uint256 total) public {  
	totalSupply_ = total;
	balances[msg.sender] = totalSupply_;
    }  
    
    // [info] zeigt die Token-Gesamtanzahl an
    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    
    // [info] zeigt das Token-Guthaben einer Wallet an.
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    // [info] ermoeglicht die Uebertragung der Token von der eigenen (aufrufenden) Wallet zu einer anderen Wallet 
    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    // [info] ermoeglicht die Freigabe von Token-Guthaben gegenueber eine anderen Wallet 
    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    
    // [info] zeigt die Hoehe des freigegeben Token-Guthabens zwischen zwei Wallets an.
    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    // [info] ermoeglicht die Uebernahmen des zuvor freigegeben Token-Guthabens (siehe Funktion "approve")
    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

    // [info] Zusatzfunktionen zur korrekten Druchfuehrung von Rechenoperationen
library SafeMath { 
    // ... stellt sicher, dass das Ergebnis nicht kleiner als 0 ausfallen kann. 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    // ... stellt sicher, dass das Summenergebnis groeßer ist als der Ausgangswert.
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}