/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

pragma solidity ^0.6.0;

contract EcommToken {
    string  public name = "Ecommerce Token";
    string  public symbol = "ECTK";
    string  public standard = "Ecommerce Token v1.0";
    uint256 private totalSupply = 100;
    uint256 public leftSupply = 100;
    uint256 public tokenPrice = 1;
    address payable public contractOwner;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public whoPaid;


    // Crea il token e assegna alle variabili "name", "symbol" e "totalSupply"
    // i loro valori che definiscono il contratto
    constructor () public {
        balanceOf[address(this)] = totalSupply;
        contractOwner = 0x0cbdC5cFfE55D6E2dB656123607F78c80Ba86C3D;
    }

    // Funzione per trasferire i token a un indirizzo
    // è richiesto solo che il balance del mittente sia superiore a quanto vuole trasferire
    function transfer(address _to, uint256 _value) private {
        
        require(leftSupply >= _value);
        //balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(address(this), _to, _value);
    }
    
    // Funzione dedicata all'acquisto dei token da parte degli utenti
    // ogni utente compra "n-token" che poi vengono salavati sul proprio wallet personale
    function buyToken(uint256 _numberOfTokens) payable public {
        require(msg.value == _numberOfTokens);
        transfer(msg.sender, _numberOfTokens);
        whoPaid[msg.sender] = msg.value;
        contractOwner.send(msg.value);
        leftSupply -= _numberOfTokens;
    }

    // Approva il trasferimento a un inidirizzo "xy"
    function approve(address _spender, uint256 _value) payable public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Funzioni che servono a "delegre" il trasferimento dei token
    function transferFrom(address _from, address _to, uint256 _value) payable public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}