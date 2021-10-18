/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// SPDX-License-Identifier: MIT
// Specificeer versie voor compiler
pragma solidity ^0.8.6;

// Hoofdletter 
/// @title ERC20 Contract
contract Stokenall{
    
    // Mapping gebruikt key-value paren, key = address in dit geval 
    // en value = tokens in wallet
    // Het addres  van een holder geeft een uint terug 
    // die staat voor het aantal tokens in zijn bezit
    // 0x3Dg93767C3E66 => 23 
    mapping(address => uint256) public balanceOf;
    // Hoeveel de spender mag spenden
    mapping(address => mapping(address => uint256)) public allowance;
    
    // Events houden gebruikers op de hoogte van wat er gebeurd
    // Slaan data niet op: 'fire and forget'
    // The content is niet zichtbaar
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // Dit zijn de toestandsvariabelen, deze staan vast op blockchain 
    // Integer een gegevenstype dat geheeltallige informatie bevat 
    // 1,16,201
    uint256 public decimals;
    // Unsigned integer betekent dat de integer niet negatief kan zijn, 
    // minimum value van 0; maximum value van 2^256-1
    uint256 public totalSupply;
    // String is een waarde die beschouwd wordt als tekst
    string public name;
    string public symbol;
    
   // In de constructor data kan data gezet worden
    // De Local variables (arguments binnen function) gelijk stellen aan toestandsvariabelen
    // Hierdoor waardes ingesteld worden als contract gecreëerd
    // Garandeert dat creatie altijd met juiste waardes verloopt
    constructor(uint _decimals, uint _totalSupply, string memory _name, string memory _symbol) {
        decimals = _decimals;
        totalSupply = _totalSupply; 
        name = _name;
        symbol = _symbol;
        // Het balans in de wallet van de deployer van contract wordt gezien als totalSupply
        balanceOf[msg.sender] = totalSupply;
    
    }
    
    // Function die bepaalde hoeveelheid tokens naar een bepaald address overmaakt
    /// param _from = msg.sender, verzender token
    /// return boolean value, vereiste ERC-20
    /// return true, succes als token naar ander account getransfered
     function transfer(address _to, uint256 _value) external returns (bool success) {
        // require function zorgt dat msg.sender daadwerkelijk genoeg tokens in account heeft
        require(balanceOf[msg.sender] >= _value, 'balance too low');
        _transfer(msg.sender, _to, _value);
        return true;
     }
    
    
    /// @param _from, verzender token
    /// @param _to ontvanger token
    ///param _value, hoeveelheid van token die verzonden wordt
    // Internal function zorgt dat Transfer function alleen vanuit dit contract opgeroepen kan worden
    function _transfer(address _from, address _to, uint256 _value) internal {
        // Verzending naar geldig address
        // 0x0-address kan voor burnen gebruikt worden
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        // emit event
        emit Transfer(_from, _to, _value);
    }
   
    // Als gelist op exchange gebruik van transferFrom
    // Tranfer door goedgekeurde persoon van originele address binnen het goedgekeurde limiet
    /// param _from, address sender en hoeveelheid verzonden tokens
    /// param _to, ontvanger token
    /// param _value, waarde van de hoeveelheid verzonden tokens
    /// return boolean value, vereiste ERC-20
    /// return true, succes als tokens uit originele account getransfered
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool succes) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        // emit event
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    // Als gelist op exchange gebruik van approve
    // Goedkeuring dat anderen namens jou tokens spenden
    // Sta _spender toe om namens jou tot _value te spenden
    /// param _spender, degene die toegestaan is te spenden en hoeveel maximaal 
    /// param _value, waarde van hoeveelheid verzonden tokens
    /// return true, success als address goedgekeurd
    function approve(address _spender, uint256 _value) external returns (bool succes) {
        // Verzending naar geldig address
        // 0x0-address kan voor burnen gebruikt worden
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        // emit event
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}