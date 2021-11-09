/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

pragma solidity >=0.8.0;
// SPDX-License-Identifier: Apache 2.0

library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        uint c = a - b;

        return c;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);

        return c;
    }

}

interface TRC20_Interface {

    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function transfer(address direccion, uint cantidad) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

abstract contract Context {

  constructor () { }

  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; 
    return msg.data;
  }
}

contract Ownable is Context {
  address payable public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor(){
    owner = payable(_msgSender());
  }
  modifier onlyOwner() {
    if(_msgSender() != owner)revert();
    _;
  }
  function transferOwnership(address payable newOwner) public onlyOwner {
    if(newOwner == address(0))revert();
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Admin is Context, Ownable{
  mapping (address => bool) public admin;

  event NewAdmin(address indexed admin);
  event AdminRemoved(address indexed admin);

  constructor(){
    admin[_msgSender()] = true;
  }

  modifier onlyAdmin() {
    if(!admin[_msgSender()])revert();
    _;
  }

  function makeNewAdmin(address payable _newadmin) public onlyOwner {
    if(_newadmin == address(0))revert();
    emit NewAdmin(_newadmin);
    admin[_newadmin] = true;
  }

  function makeRemoveAdmin(address payable _oldadmin) public onlyOwner {
    if(_oldadmin == address(0))revert();
    emit AdminRemoved(_oldadmin);
    admin[_oldadmin] = false;
  }

}

contract StakingPool is Context, Admin{
  using SafeMath for uint;

  TRC20_Interface CSC_Contract = TRC20_Interface(0x389ccc30de1d311738Dffd3F60D4fD6188970F45);

  TRC20_Interface OTRO_Contract = TRC20_Interface(0x389ccc30de1d311738Dffd3F60D4fD6188970F45);

  struct Usuario {
    uint participacion;

  }

  uint public MIN_DEPOSIT = 200 * 10**18;
  uint public TOTAL_POOL = 2085000 * 10**18;
  uint public CSC_WALLET_BALANCE;
  uint public TOTAL_PARTICIPACIONES;
  uint public inicio = 1636440200;
  uint public fin = inicio * 30 * 86400;
  
  uint public precision = 18;

  mapping (address => Usuario) public usuarios;

  constructor() { }

  function CSC_POOL_BALANCE() public view returns(uint){
      uint total;

      if(block.timestamp >= inicio ){
        uint till = block.timestamp > fin ? fin : block.timestamp;

        total = (TOTAL_POOL * (till - inicio)) / (fin-inicio) ;

      }

      return total;      
     

  }

  function CSC_PAY_BALANCE() public view returns (uint){
    return address(this).balance;
  }

  function RATE() public view returns (uint){

    if(TOTAL_PARTICIPACIONES == 0){
      return (CSC_WALLET_BALANCE.add(CSC_POOL_BALANCE()));
    }else{
      return (CSC_WALLET_BALANCE.add(CSC_POOL_BALANCE())).mul(10**precision).div( TOTAL_PARTICIPACIONES ) ;
    }

  }

  function ChangeToken(address _tokenTRC20) public onlyOwner returns (bool){

    CSC_Contract = TRC20_Interface(_tokenTRC20);

    return true;

  }

  function ChangeTokenOTRO(address _tokenTRC20) public onlyOwner returns (bool){

    OTRO_Contract = TRC20_Interface(_tokenTRC20);

    return true;

  }
  
  function staking(uint _value) public returns (uint) {

    if(block.timestamp < inicio || block.timestamp > fin)revert();
    if(_value < MIN_DEPOSIT)revert();
    if( CSC_Contract.balanceOf(msg.sender) < _value )revert();
    if( !CSC_Contract.transferFrom(msg.sender, address(this), _value) )revert();
      
    uint tmp = _value;

    _value = (_value.mul(10**precision)).div(RATE());
    Usuario storage usuario = usuarios[msg.sender];
    
    usuario.participacion += _value;
    TOTAL_PARTICIPACIONES += _value;
    
    CSC_WALLET_BALANCE += tmp;

    return _value;

  }

  function retiro(uint _participacion) public returns (uint256){

    if(block.timestamp < fin )revert();

    Usuario storage usuario = usuarios[msg.sender];

    if(usuario.participacion < _participacion)revert();
    
    uint pago = _participacion.mul(RATE());
    pago = pago.div(10**precision);

    if(CSC_WALLET_BALANCE.add(CSC_POOL_BALANCE()) < pago)revert();
    
    if( !CSC_Contract.transfer(msg.sender, pago) )revert();

    usuario.participacion -= _participacion;
    TOTAL_PARTICIPACIONES -= _participacion;
    TOTAL_POOL -= CSC_POOL_BALANCE();
    CSC_WALLET_BALANCE += CSC_POOL_BALANCE();
    CSC_WALLET_BALANCE -= pago;

    return pago;

  }

  function actualizarFechas(uint _inicio, uint _fin) public onlyOwner returns(bool){
    inicio = _inicio;
    if(_fin > 0){
      fin = _fin;
    }else{
      fin = inicio * 30 * 86400;
    }
    return true;
  }

  function asignarPerdida(uint _value) public onlyOwner returns(uint){

    CSC_WALLET_BALANCE -= _value;

    return _value;

  }

  function gananciaDirecta(uint _value) public onlyOwner returns(uint){

    CSC_WALLET_BALANCE += _value;

    return _value;

  }

  function redimCSC(uint _value) public onlyOwner returns (uint256) {

    if ( CSC_Contract.balanceOf(address(this)) < _value)revert();

    CSC_Contract.transfer(owner, _value);

    return _value;

  }

  function redimOTRO() public onlyOwner returns (uint256){

    uint256 valor = OTRO_Contract.balanceOf(address(this));

    OTRO_Contract.transfer(owner, valor);

    return valor;
  }

  function redimBNB() public onlyOwner returns (uint256){

    if ( address(this).balance == 0)revert();

    payable(owner).transfer( address(this).balance );

    return address(this).balance;

  }

  fallback() external payable {}

  receive() external payable {}

}