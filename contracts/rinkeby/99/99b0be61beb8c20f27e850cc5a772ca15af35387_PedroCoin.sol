/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

pragma solidity >=0.7.0 <0.9.0;


contract PedroCoin{

//VARIABLES

address _ContractOwner;
uint256 _totalSupply;
mapping(address=> uint256) _balances;
mapping(address => mapping(address => uint256)) _allowances;
string nombre ="PedroCoin";
string ticker = "PETER";


//Eventos
event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);




//CONSTRUCTOR
 constructor() public {
     _totalSupply = 100000000000;
     _ContractOwner = msg.sender; // el dueño soy yo
 }
 
modifier onlyowner {require (msg.sender==_ContractOwner,"No sos pedro");_; }

//Banco central
function mint(address _to,uint256 _value) public onlyowner {//Solo yo puedo imprimir billetes
    _totalSupply += _value;
    _balances[_to] += _value;
}

//info de la moneda
function name() public view returns (string memory){return nombre;}
function symbol() public view returns (string memory){return ticker;}
function decimals() public view returns (uint8){return 8;}


function totalSupply() public view returns (uint256){return _totalSupply;}
function balanceOf(address _owner) public view returns (uint256 balance){return (_balances[_owner]);}
function transfer(address _to, uint256 _value) public returns (bool success){ 
    require(_balances[msg.sender]>=_value,"no tenes guita jefe");
    _balances[_to]+=_value;
    _balances[msg.sender]-=_value;
    emit Transfer(msg.sender,_to,_value);
    return true;
}
    //FUNCIONES
function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
    require(_allowances[_from][msg.sender]>=_value,"no tas aprovado pa");
    _balances[_from]-=_value;
    _balances[_to]+=_value;
    emit Transfer(_from,_to,_value);
    return true;
}
function approve(address _spender, uint256 _value) public returns (bool success) {
    _allowances[msg.sender][_spender]=_value;
    emit Approval (msg.sender,_spender,_value);
    return true;
}
function allowance(address _owner, address _spender) public view returns (uint256 remaining){return _allowances[_owner][_spender];}

}