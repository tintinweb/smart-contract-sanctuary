// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 < 0.7.0;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";


// contrato 0x5a457b86a9003bd392373c1f13fff55957ff0498
// direccion del propietario 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// direccion de sofia 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// direccion de marcos 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c

//Interface de nuestro token ERC20
interface IERC20{
    
    // Devuelve la cantidad de tokens en existencia
    function totalSupply() external view returns (uint256);

    // Devuelve la cantidad de tokens para una dirección indicada por parámetro
    function balanceOf(address account) external view returns (uint256);

    // Devuelve la cantidad de tokens del owner del contrato
    function balanceOwner() external view returns (uint256);

    // Devuelve la cantidad de tokens de la direccion del solitiante
    function balanceMyAdress() external view returns (uint256);


    // Devuelve el número de token que el spender podrá gastar en nombre del propietario (owner)
    function allowance(address owner, address spender) external view returns (uint256);

    // Devuelve un valor booleano resultado de la operación indicada
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Devuelve un valor booleano con el resultado de la operación de gasto
    function approve(address spender, uint256 amount) external returns (bool);

    // Devuelve un valor booleano con el resultado de la operación de paso de una cantidad de tokens usando el método allowance()
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    // Evento que se debe emitir cuando una cantidad de tokens pase de un origen a un destino
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Evento que se debe emitir cuando se establece una asignación con el mmétodo allowance()
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//Implementación de las funciones del token ERC20
contract ERC20Basic is IERC20{

    string public constant name = "BalooCoin";
    string public constant symbol = "Baloo";
    uint8 public constant decimals =6;
    address _owner;

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed owner, address indexed spender, uint256 tokens);


    using SafeMath for uint256;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint256 totalSupply_;

    constructor (uint256 initialSupply) public{
        _owner = msg.sender;
        totalSupply_ = initialSupply;
        balances[msg.sender] = totalSupply_;
    }

    modifier Unicamente(address _direccion) {
        require(_direccion==_owner, "no tienes permisos para ejecutar esta funcion");
        _;
    }

    function totalSupply() public override view returns (uint256){
        return totalSupply_;
    }

    function increaseTotalSupply(uint newTokensAmount) public Unicamente(msg.sender) {
        totalSupply_ += newTokensAmount;
        balances[msg.sender] += newTokensAmount;
    }

    function balanceMyAdress() public override view returns (uint256) {
        return balances[msg.sender];
    }
    
    function balanceOwner() public override view returns (uint256) {
        return balances[_owner];
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function allowance(address owner, address delegate) public override view returns (uint256){
        return allowed[owner][delegate];
    }

    function transfer(address recipient, uint256 numTokens) public override returns (bool){
        require(numTokens <= balances[msg.sender], "el numero de tokens es superior a los que dispone el emisor");
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[recipient] = balances[recipient].add(numTokens);
        emit Transfer(msg.sender, recipient, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender], "el numero de tokens es superior a los que dispone el emisor");
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool){
        require(numTokens <= balances[owner], "el numero de tokens es superior al balance del propietario");
        require(numTokens <= allowed[owner][msg.sender], "el numero de tokens es superior al permitido por el propietario");

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}