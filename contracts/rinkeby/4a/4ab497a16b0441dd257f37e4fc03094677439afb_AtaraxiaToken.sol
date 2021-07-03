/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

// SPDX-License-Identifier: MIT
//pragma solidity >=0.4.22 <0.9.0;
pragma solidity ^0.5.3;

contract AtaraxiaToken {
    string public name = "Ataraxia Token";
    string public symbol = "ATR";
    string public standard = "Ataraxia Token v1.0";
    uint256 public totalSupply;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    //constructor
    constructor(uint256 _initialSupply) public {
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
        //asignar la cantidad inicial
    }
    //transferencias
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        //excepción si la cuenta no tiene suficiente
        require(balanceOf[msg.sender] >= _value);
        //transferir el balance
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        //emitir evento
        emit Transfer(msg.sender, _to, _value);
        //retorna booleano
        return true;
    }

    //transferencias delegadas

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        //excepción si la cuenta _from no tiene suficiente
        require(_value <= balanceOf[_from]);
        //excepción si la asignación no es suficiente
        require(_value <= allowance[_from][msg.sender]);
        //cambiar el balance
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        //actualizar asignación
        allowance[_from][msg.sender] -= _value;
        //emitir evento
        emit Transfer(_from, _to, _value);
        //retorna booleano
        return true;
    }
}

contract AtaraxiaTokenVenta {
    //address payable public admin;
    address payable public admin;
    AtaraxiaToken public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;

    event Sell(address _buyer, uint256 _amount);

   constructor(
       AtaraxiaToken _tokenContract, 
       uint256 _tokenPrice
       //address payable _admin
       ) public{        
       // admin = _admin;       
        admin=msg.sender;     
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
      require(msg.value == multiply(_numberOfTokens, tokenPrice));
        require(tokenContract.balanceOf(address(this)) >= _numberOfTokens);
       require(tokenContract.transfer(msg.sender, _numberOfTokens));

        tokensSold += _numberOfTokens;

        emit Sell(msg.sender, _numberOfTokens);
    }

    function endSale() public{      
        require(msg.sender == admin);
        require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))));
        // Transferir el balance al admin       
        admin.transfer(address(this).balance);
    }
}