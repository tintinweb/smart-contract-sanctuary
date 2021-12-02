/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

pragma solidity ^0.4.24;

contract ERC20{
    
    string public name = "Elliptic Coin";
    string public symbol = "ELPT";
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
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
    
    
    
    //LA PRIMER FUNCION QUE EJECUTA LA EVM AL DESPLEGAR EL TOKEN
    
    constructor(uint256 _initialSupply)public {
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
    }
    
    function transfer(address _to, uint256 _value) public returns(bool success){
        
        require(balanceOf[msg.sender] >= _value);
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        
        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success){
        //Validar que lo que quiere mandar es menor a su saldo
        require(_value <= balanceOf[_from]);
        
        //Validar que le permitieron gastar lo suficiente
        require(_value <= allowance[_from][msg.sender]);
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint _value) public returns(bool success){
        allowance[msg.sender][_spender] = _value;
        
        // Ejecutamos el evento como approval
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
}