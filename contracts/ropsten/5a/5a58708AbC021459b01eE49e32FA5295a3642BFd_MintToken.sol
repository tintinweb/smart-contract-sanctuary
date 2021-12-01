// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MintToken {
    address internal owner;
    string public name = "Mint Token";
    string public symbol = "MIN";
    string public standard = "MIN v1.0";
    // da creare tutte le volte.
    uint256 public totalSupply;

    // evento che indicizza i trasferimento
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // indicizza le aprovazioni dei contratti
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    //bilancio del utente
    mapping(address => uint256) public balanceOf;
    // sarebbe lo swap
    mapping(address => mapping(address => uint256)) public allowance;

    //settiamo i parametri iniziali
    constructor() {
        owner = msg.sender;
    }

    modifier OnlyOwner() {
        require(msg.sender == owner, "non hai i diritti di minting");
        _;
    }

    // set proprietario
    function setOwner(address _addr) public OnlyOwner {
        owner = _addr;
    }

    // funzione di minting e creazione supply.
    function minting(address _addr, uint256 _value) external OnlyOwner {
        totalSupply += _value;
        balanceOf[_addr] += _value;
    }

    // funzione di burning token e supply.
    function burning(address _addr, uint256 _value) external OnlyOwner {
        require(
            balanceOf[_addr] >= _value,
            "non hai abbastanza mint token da bruciare"
        );
        balanceOf[_addr] -= _value;
        totalSupply -= _value;
    }

    // funzione trasferimento da richiamante a _to
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        approve(_to, _value);
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    // funzione d'approvazione distaccata da quella di trasferimento en on so perche
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    // trasferimento fra 2 utenti
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function GetBalanceERC20(address _addr) public view returns (uint256) {
        return balanceOf[_addr];
    }
}