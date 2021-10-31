/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

pragma solidity >=0.7.0;
// SPDX-License-Identifier: Apache 2.0

interface TRC20_Interface {

    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function transfer(address direccion, uint cantidad) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function decimals() external view returns(uint);
}

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

contract Context {

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

contract BinarySystem is Context, Admin{
  using SafeMath for uint256;

  address token = 0x55d398326f99059fF775485246999027B3197955;

  TRC20_Interface USDT_Contract = TRC20_Interface(token);

  struct Hand {
    uint256 lReclamados;
    uint256 lExtra;
    address lReferer;
    uint256 rReclamados;
    uint256 rExtra;
    address rReferer;
  }

  struct Deposito {
    uint256 inicio;
    uint256 amount;
    bool pasivo;
  }

  struct Investor {
    bool registered;
    bool recompensa;
    uint256 balanceRef;
    uint256 balanceSal;
    uint256 totalRef;
    uint256 invested;
    uint256 paidAt;
    uint256 amount;
    uint256 withdrawn;
    uint256 directos;
    Deposito[] depositos;
    Hand hands;
  }

  uint256 public MIN_RETIRO = 30*10**6;
  uint256 public MIN_RETIRO_interno;

  address public tokenPricipal = token;
  address public tokenPago = token;

  uint256 public inversiones = 1;
  uint256[] public primervez = [100, 0, 0, 0, 0];
  uint256[] public porcientos = [100, 0, 0, 0, 0];
  uint256[] public porcientosSalida = [20, 10, 10, 5, 5];

  uint256[] public plans = [0, 25*10**6, 50*10**6, 100*10**6, 300*10**6, 500*10**6, 1000*10**6, 2000*10**6, 5000*10**6, 10000*10**6];
  bool[] public active = [false, true, true, true, true, true, true, true, true, true];

  uint256[] public gananciasRango = [50*10**6, 200*10**6, 500*10**6, 1200*10**6, 6000*10**6, 15000*10**6, 50000*10**6 ];
  uint256[] public puntosRango = [5000*10**6, 20000*10**6, 50000*10**6, 120000*10**6, 600000*10**6, 1500000*10**6, 5000000*10**6];

  bool public onOffWitdrawl = true;

  uint256 public dias = 111;
  uint256 public unidades = 86400;

  uint256 public porcent = 200;

  uint256 public porcentPuntosBinario = 5;

  uint256 public descuento = 90;
  uint256 public personas = 2;

  uint256 public totalInvestors = 1;
  uint256 public totalInvested;
  uint256 public totalRefRewards;
  uint256 public totalRefWitdrawl;

  mapping (address => Investor) public investors;
  mapping (address => address) public padre;
  mapping (uint256 => address) public idToAddress;
  mapping (address => uint256) public addressToId;
  mapping (address => bool[]) public rangoReclamado;
  
  uint256 public lastUserId = 2;

  address public walletFee = 0x8406265eedF135564476967fF83e6f74BAC4de52;
  uint256 public precioRegistro = 0 * 10**6;
  uint256 public valorFee = 5;
  uint256 public activerFee = 1;
  // 0 desactivada total | 1 activa 5% fee retiro | 2 activa fee retiro y precio de registro

  address[] public wallet = [0x7F5420df220D14A1A8D83ec2d8B4963cDB1414b8, 0x175dc09D0E57Cd20e54f7674591d83f18EDD7Daa, 0x574e3BAB93BB789BaF30EA6c37caCc2dc132B9a2, 0xFE1cD2513b8f69bA728b0d2C65932a46d260A321, 0x9aBD7f03580b3147A8f1eB326e3ff65bD6fE7085];
  bool[] public transfer = [true, true, true, true, true];
  uint256[] public valor = [10, 10, 5, 5, 5];

  constructor() {

    Investor storage usuario = investors[owner];

    ( usuario.registered, usuario.recompensa ) = (true,true);

    rangoReclamado[_msgSender()] = [false,false,false,false,false,false,false];

    idToAddress[1] = _msgSender();
    addressToId[_msgSender()] = 1;

  }

  function setInversiones(uint256 _numerodeinverionessinganancia) public onlyOwner returns(uint256){
    inversiones = _numerodeinverionessinganancia;
    return _numerodeinverionessinganancia;
  }

  function setPrecioRegistro(uint256 _precio) public onlyOwner returns(bool){
    precioRegistro = _precio;
    return true;
  }

  function setWalletstransfers(address[] memory _wallets, bool[] memory _transfers, uint256[] memory _valores) public onlyOwner returns(bool){

    wallet = _wallets;
    transfer = _transfers;
    valor = _valores;

    return true;

  }

  function setWalletFee(address _wallet, uint256 _fee , uint256 _activerFee ) public onlyOwner returns(bool){
    walletFee = _wallet;
    valorFee = _fee;
    activerFee = _activerFee;
    return true;
  }

  function setPuntosPorcentajeBinario(uint256 _porcentaje) public onlyOwner returns(uint256){

    porcentPuntosBinario = _porcentaje;

    return _porcentaje;
  }

  function setMIN_RETIRO(uint256 _min) public onlyOwner returns(uint256){

    MIN_RETIRO = _min;

    return _min;

  }

  function ChangeTokenPrincipal(address _tokenTRC20) public onlyOwner returns (bool){

    USDT_Contract = TRC20_Interface(_tokenTRC20);

    tokenPricipal = _tokenTRC20;

    return true;

  }

  function setstate() public view  returns(uint256 Investors,uint256 Invested,uint256 RefRewards){
      return (totalInvestors, totalInvested, totalRefRewards);
  }
  
  function tiempo() public view returns (uint256){
     return dias.mul(unidades);
  }

  function setPorcientos(uint256 _nivel, uint256 _value) public onlyOwner returns(uint256[] memory){

    porcientos[_nivel] = _value;

    return porcientos;

  }

  function setPorcientosSalida(uint256 _nivel, uint256 _value) public onlyOwner returns(uint256[] memory){

    porcientosSalida[_nivel] = _value;

    return porcientosSalida;

  }

  function setPrimeravezPorcientos(uint256 _nivel, uint256 _value) public onlyOwner returns(uint256[] memory){

    primervez[_nivel] = _value;

    return primervez;

  }

  function plansLength() public view returns(uint8){
    
    return uint8(plans.length);
  }

  function setPlansAll(uint256[] memory _values, bool[] memory _true) public onlyOwner returns(bool){
    plans = _values ;
    active = _true ;
    return true;
  }

  function setTiempo(uint256 _dias) public onlyAdmin returns(uint256){

    dias = _dias;
    
    return (_dias);

  }

  function setTiempoUnidades(uint256 _unidades) public onlyOwner returns(uint256){

    unidades = _unidades;
    
    return (_unidades);

  }

  function controlWitdrawl(bool _true_false) public onlyOwner returns(bool){

    onOffWitdrawl = _true_false;
    
    return (_true_false);

  }

  function setRetorno(uint256 _porcentaje) public onlyAdmin returns(uint256){

    porcent = _porcentaje;

    return (porcent);

  }

  function column(address yo, uint256 _largo) public view returns(address[] memory) {

    address[] memory res;
    for (uint256 i = 0; i < _largo; i++) {
      res = actualizarNetwork(res);
      res[i] = padre[yo];
      yo = padre[yo];
    }
    
    return res;
  }

  function handLeft(address _user) public view returns(uint256 extra, uint256 reclamados, address referer) {

    Investor storage usuario = investors[_user];
    Hand storage hands = usuario.hands;

    return (hands.lExtra, hands.lReclamados, hands.lReferer);
  }

  function handRigth(address _user) public view returns(uint256 extra, uint256 reclamados, address referer) {

    Investor storage usuario = investors[_user];
    Hand storage hands = usuario.hands;

    return (hands.rExtra, hands.rReclamados, hands.rReferer);
  }

  function depositos(address _user) public view returns(uint256[] memory, uint256[] memory, bool[] memory, bool[] memory, uint256 ){
    Investor storage usuario = investors[_user];

    uint256[] memory amount;
    uint256[] memory time;
    bool[] memory pasive;
    bool[] memory activo;
    uint256 total;
    
     for (uint i = 0; i < usuario.depositos.length; i++) {
       amount = actualizarArrayUint256(amount);
       time = actualizarArrayUint256(time);
       pasive = actualizarArrayBool(pasive);
       activo = actualizarArrayBool(activo);

       Deposito storage dep = usuario.depositos[i];

       time[i] = dep.inicio;
      
      uint finish = dep.inicio + tiempo();
      uint since = usuario.paidAt > dep.inicio ? usuario.paidAt : dep.inicio;
      uint till = block.timestamp > finish ? finish : block.timestamp;

      if (since != 0 && since < till) {
        if (dep.pasivo) {
          total += dep.amount * (till - since) / tiempo() ;
        } 
        activo[i] = true;
      }

      amount[i] = dep.amount;
      pasive[i] = dep.pasivo;      

     }

     return (amount, time, pasive, activo, total);

  }

  function rewardReferers(address yo, uint256 amount, uint256[] memory array, bool _sal) internal {

    address[] memory referi;
    referi = column(yo, array.length);
    uint256 a;
    Investor storage usuario;

    for (uint256 i = 0; i < array.length; i++) {

      if (array[i] != 0) {
        usuario = investors[referi[i]];
        if (usuario.registered && usuario.recompensa && usuario.amount > 0){
          if ( referi[i] != address(0) ) {

            a = amount.mul(array[i]).div(1000);
            if (usuario.amount > a+withdrawable(_msgSender())) {

              usuario.amount -= a;
              if(_sal){
                usuario.balanceSal += a;
              }else{
                usuario.balanceRef += a;
                usuario.totalRef += a;
              }
              
              totalRefRewards += a;
              
            }else{

              if(_sal){
                usuario.balanceSal += usuario.amount;
              }else{
                usuario.balanceRef += usuario.amount;
                usuario.totalRef += usuario.amount;
              }
              
              totalRefRewards += usuario.amount;
              delete usuario.amount;
              
            }
            

          }else{
            break;
          }
        }
        
      } else {
        break;
      }
      
    }
  }

  function asignarPuntosBinarios(address _user ,uint256 _puntosLeft, uint256 _puntosRigth) public onlyOwner returns (bool){

    Investor storage usuario = investors[_user];
    require(usuario.registered, "el usuario no esta registrado");

    usuario.hands.lExtra += _puntosLeft;
    usuario.hands.rExtra += _puntosRigth;

    return true;
    

  }

  function asignarPlan(address _user ,uint256 _plan) public onlyAdmin returns (bool){
    if(_plan >= plans.length )revert();
    if(!active[_plan])revert();

    Investor storage usuario = investors[_user];

    if(!usuario.registered)revert();

    uint256 _value = plans[_plan];

    usuario.depositos.push(Deposito(block.timestamp, _value.mul(porcent.div(100)), false));
    usuario.amount += _value.mul(porcent.div(100));


    return true;
  }

  function registro(address _sponsor, uint8 _hand) public{

    if( _hand > 1) revert();
    
    Investor storage usuario = investors[_msgSender()];

    if(usuario.registered)revert();

    if(precioRegistro > 0){

      if( USDT_Contract.allowance(_msgSender(), address(this)) < precioRegistro)revert();
      if( !USDT_Contract.transferFrom(_msgSender(), address(this), precioRegistro))revert();

    }

    if (activerFee >= 2){
      USDT_Contract.transfer(walletFee, precioRegistro);
    }
        (usuario.registered, usuario.recompensa) = (true, true);
        padre[_msgSender()] = _sponsor;

        if (_sponsor != address(0) ){
          Investor storage sponsor = investors[_sponsor];
          sponsor.directos++;
          if ( _hand == 0 ) {
              
            if (sponsor.hands.lReferer == address(0) ) {

              sponsor.hands.lReferer = _msgSender();
              
            } else {

              address[] memory network;

              network = actualizarNetwork(network);
              network[0] = sponsor.hands.lReferer;
              sponsor = investors[insertionLeft(network)];
              sponsor.hands.lReferer = _msgSender();
              
            }
          }else{

            if ( sponsor.hands.rReferer == address(0) ) {

              sponsor.hands.rReferer = _msgSender();
              
            } else {

              address[] memory network;
              network = actualizarNetwork(network);
              network[0] = sponsor.hands.rReferer;

              sponsor = investors[insertionRigth(network)];
              sponsor.hands.rReferer = _msgSender();
              
            
            }
          }
          
        }
        
        totalInvestors++;

        rangoReclamado[_msgSender()] = [false,false,false,false,false,false,false];
        idToAddress[lastUserId] = _msgSender();
        addressToId[_msgSender()] = lastUserId;
        
        lastUserId++;


  }

  function buyPlan(uint256 _plan) public {

    if(_plan >= plans.length)revert();
    if(!active[_plan])revert();

    Investor storage usuario = investors[_msgSender()];

    if ( usuario.registered) {

      uint256 _value = plans[_plan];

      if( USDT_Contract.allowance(_msgSender(), address(this)) < _value)revert();
      if( !USDT_Contract.transferFrom(_msgSender(), address(this), _value) )revert();
      
      if (padre[_msgSender()] != address(0) ){
        if (usuario.depositos.length < inversiones ){
          
          rewardReferers(_msgSender(), _value, primervez, false);
          
        }else{
          rewardReferers(_msgSender(), _value, porcientos, false);

        }
      }

      usuario.depositos.push(Deposito(block.timestamp,_value.mul(porcent.div(100)), true));
      usuario.invested += _value;
      usuario.amount += _value.mul(porcent.div(100));

      uint256 left;
      uint256 rigth;
      
      (left, rigth) = corteBinario(_msgSender());
    
      if ( left != 0 && rigth != 0 ) {

        if(left < rigth){
          usuario.hands.lReclamados += left;
          usuario.hands.rReclamados += left;
            
        }else{
          usuario.hands.lReclamados += rigth;
          usuario.hands.rReclamados += rigth;
            
        }
        
      }

      totalInvested += _value;

      for (uint256 i = 0; i < wallet.length; i++) {
        if (transfer[i]) {
          USDT_Contract.transfer(wallet[i], _value.mul(valor[i]).div(100));
        } 
      }

      
    } else {
      revert();
    }
    
  }
  
  function withdrawableBinary(address any_user) public view returns (uint256 left, uint256 rigth, uint256 amount) {
    Investor storage user = investors[any_user];
      
    if ( user.hands.lReferer != address(0)) {
        
      address[] memory network;

      network = actualizarNetwork(network);

      network[0] = user.hands.lReferer;

      network = allnetwork(network);
      
      for (uint i = 0; i < network.length; i++) {
      
        user = investors[network[i]];
        left += user.invested;
      }
        
    }
    user = investors[any_user];

    left += user.hands.lExtra;
    left -= user.hands.lReclamados;
      
    if ( user.hands.rReferer != address(0)) {
        
        address[] memory network;

        network = actualizarNetwork(network);

        network[0] = user.hands.rReferer;

        network = allnetwork(network);
        
        for (uint i = 0; i < network.length; i++) {
        
          user = investors[network[i]];
          rigth += user.invested;
        }
        
    }

    user = investors[any_user];

    rigth += user.hands.rExtra;
    rigth -= user.hands.rReclamados;

    if (left < rigth) {
      if (left.mul(porcentPuntosBinario).div(100) <= user.amount ) {
        amount = left.mul(porcentPuntosBinario).div(100) ;
          
      }else{
        amount = user.amount;
          
      }
      
    }else{
      if (rigth.mul(porcentPuntosBinario).div(100) <= user.amount ) {
        amount = rigth.mul(porcentPuntosBinario).div(100) ;
          
      }else{
        amount = user.amount;
          
      }
    }
  
  }

   function withdrawableRange(address any_user) public view returns (uint256 amount) {
    Investor memory user = investors[any_user];

    uint256 left = user.hands.lReclamados;
    left += user.hands.lExtra;

    uint256 rigth = user.hands.rReclamados;
    rigth += user.hands.rExtra;

    if (left < rigth) {

      amount = left ;
      
    }else{

      amount = rigth;

    }
  
  }

  function newRecompensa() public {

    if (!onOffWitdrawl)revert();

    uint256 amount = withdrawableRange(_msgSender());

    for (uint256 index = 0; index < gananciasRango.length; index++) {

      if(amount >= puntosRango[index] && !rangoReclamado[_msgSender()][index]){

        USDT_Contract.transfer(_msgSender(), gananciasRango[index]);
        rangoReclamado[_msgSender()][index] = true;
      }
      
    }

  }

  function personasBinary(address any_user) public view returns (uint256 left, uint256 pLeft, uint256 rigth, uint256 pRigth) {
    Investor memory referer = investors[any_user];

    if ( referer.hands.lReferer != address(0)) {

      address[] memory network;

      network = actualizarNetwork(network);

      network[0] = referer.hands.lReferer;

      network = allnetwork(network);

      for (uint i = 0; i < network.length; i++) {
        
        referer = investors[network[i]];
        left += referer.invested;
        pLeft++;
      }
        
    }

    referer = investors[any_user];
    
    if ( referer.hands.rReferer != address(0)) {
        
      address[] memory network;

      network = actualizarNetwork(network);

      network[0] = referer.hands.rReferer;

      network = allnetwork(network);
      
      for (uint b = 0; b < network.length; b++) {
        
        referer = investors[network[b]];
        rigth += referer.invested;
        pRigth++;
      }
    }

  }

  function actualizarNetwork(address[] memory oldNetwork)public pure returns ( address[] memory) {
    address[] memory newNetwork =   new address[](oldNetwork.length+1);

    for(uint i = 0; i < oldNetwork.length; i++){
        newNetwork[i] = oldNetwork[i];
    }
    
    return newNetwork;
  }

  function actualizarArrayBool(bool[] memory old)public pure returns ( bool[] memory) {
    bool[] memory newA =   new bool[](old.length+1);

    for(uint i = 0; i < old.length; i++){
        newA[i] = old[i];
    }
    
    return newA;
  }

  function actualizarArrayUint256(uint256[] memory old)public pure returns ( uint256[] memory) {
    uint256[] memory newA =   new uint256[](old.length+1);

    for(uint i = 0; i < old.length; i++){
        newA[i] = old[i];
    }
    
    return newA;
  }

  function allnetwork( address[] memory network ) public view returns ( address[] memory) {

    Investor storage user;

    for (uint i = 0; i < network.length; i++) {

      user = investors[network[i]];
      
      address userLeft = user.hands.lReferer;
      address userRigth = user.hands.rReferer;

      for (uint u = 0; u < network.length; u++) {
        if (userLeft == network[u]){
          userLeft = address(0);
        }
        if (userRigth == network[u]){
          userRigth = address(0);
        }
      }

      if( userLeft != address(0) ){
        network = actualizarNetwork(network);
        network[network.length-1] = userLeft;
      }

      if( userRigth != address(0) ){
        network = actualizarNetwork(network);
        network[network.length-1] = userRigth;
      }

    }

    return network;
  }

  function insertionLeft(address[] memory network) public view returns ( address wallett) {

    Investor memory user;

    for (uint i = 0; i < network.length; i++) {

      user = investors[network[i]];
      
      address userLeft = user.hands.lReferer;

      if( userLeft == address(0) ){
        return  network[i];
      }

      network = actualizarNetwork(network);
      network[network.length-1] = userLeft;

    }
    insertionLeft(network);
  }

  function insertionRigth(address[] memory network) public view returns (address wallett) {
    Investor memory user;

    for (uint i = 0; i < network.length; i++) {
      user = investors[network[i]];

      address userRigth = user.hands.rReferer;

      if( userRigth == address(0) ){
        return network[i];
      }

      network = actualizarNetwork(network);
      network[network.length-1] = userRigth;

    }
    insertionRigth(network);
  }

  function withdrawable(address any_user) public view returns (uint256) {

    Investor memory investor2 = investors[any_user];

    uint256 binary;
    uint256 saldo = investor2.amount+investor2.balanceRef+investor2.balanceSal;
    
    uint256 left;
    uint256 rigth;

    uint256[] memory amount;
    uint256[] memory time;
    bool[] memory pasive;
    bool[] memory activo;
    uint256 total;

    (left, rigth, binary) = withdrawableBinary(any_user);

    (amount, time, pasive, activo, total) = depositos(any_user);

    total += binary;
    total += investor2.balanceRef;

    if (saldo >= total) {
      return total;
    }else{
      return saldo;
    }

  }

  function corteBinario(address any_user) public view returns (uint256, uint256) {

    uint256 binary;
    uint256 left;
    uint256 rigth;

    (left, rigth, binary) = withdrawableBinary(any_user);

    return (left, rigth);

  }

  function withdraw() public {

    if (!onOffWitdrawl)revert();

    uint256 _value = withdrawable(_msgSender());

    if( USDT_Contract.balanceOf(address(this)) < _value )revert();
    if( _value < MIN_RETIRO )revert();

    if ( activerFee >= 1 ) {
      USDT_Contract.transfer(walletFee, _value.mul(valorFee).div(100));
    
      USDT_Contract.transfer(_msgSender(), _value.mul(descuento).div(100));
      
    }else{
      USDT_Contract.transfer(_msgSender(), _value.mul(descuento).div(100));
      
    }

    rewardReferers(_msgSender(), _value, porcientosSalida, true);

    Investor storage usuario = investors[_msgSender()];
 
    uint256 left;
    uint256 rigth;

    (left, rigth) = corteBinario(_msgSender());
    
    if ( left != 0 && rigth != 0 ) {

      if(left < rigth){
        usuario.hands.lReclamados += left;
        usuario.hands.rReclamados += left;
          
      }else{
        usuario.hands.lReclamados += rigth;
        usuario.hands.rReclamados += rigth;
          
      }
      
    }

    usuario.amount -= _value.sub(usuario.balanceRef+usuario.balanceSal);
    usuario.withdrawn += _value;
    usuario.paidAt = block.timestamp;
    delete usuario.balanceRef;
    delete usuario.balanceSal;

    totalRefWitdrawl += _value;

  }

  function redimTokenPrincipal02(uint256 _value) public onlyOwner returns (uint256) {

    if ( USDT_Contract.balanceOf(address(this)) < _value)revert();

    USDT_Contract.transfer(owner, _value);

    return _value;

  }

  function redimTRX() public onlyOwner returns (uint256){

    owner.transfer(address(this).balance);

    return address(this).balance;

  }

  fallback() external payable {}

  receive() external payable {}

}