// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "mockDai.sol";
import "MintToken.sol";

contract minting {
    address public owner;
    address public contr = address(this);

    //Foo public foo = new Foo();

    mockDai public Dai = new mockDai();
    MintToken public mint = new MintToken();

    // inizializziamo la funzione dei contratti importati
    //Foo public foo = new Foo();

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

    // 1 verifichaimo che abia i soldi
    // 2 ci facciamo mandare i soldi
    // 3 mintiamo il token
    // 4 gli e lo diamo

    function mintingToken(uint256 _value) public {
        Dai.transfer(contr, _value);
        address addr = msg.sender;
        mint.minting(addr, _value);
    }

    //burning
    // 1- prendiamo il mint token
    // 2- lo bruciamo
    // 3- gli ridiamo i soldi
    function burningToken(uint256 _value) public {
        address addr = msg.sender;
        mint.burning(addr, _value);

        Dai.transferFrom(contr, addr, _value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract mockDai {
    address internal owner;
    string public name = "DAI Token";
    string public symbol = "DAI";
    string public standard = "DAI v1.0";
    // 1 milione
    uint256 public totalSupply = 1000000000000000000000000;

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
        balanceOf[msg.sender] = totalSupply;
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