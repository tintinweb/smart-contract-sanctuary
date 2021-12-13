// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract mockDai {
    address internal owner;
    string public name = "mockDAI ";
    string public symbol = "mDAI";
    string public standard = "mockDAI token v1.0";
    uint256 public totalSupply = 1000000 * (10**18);

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

    function Getaddress() public view returns (address) {
        return address(this);
    }
}