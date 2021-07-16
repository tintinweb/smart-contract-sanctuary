//SourceUnit: trinytrona.sol

pragma solidity ^0.4.24;

   
contract Trinytron_contract {
    address private owner;
    address private cover;
    struct Users{
        uint fecha;
        uint id;
        string nombre;
        string correo;
        address billetera;
        address padre;
        address[] hijos;
        uint nivel;
        uint [] pagos;
        bool pago_primero;
        string pais;
    }
    uint public suny=1000000;
    mapping (address=>Users) private list_users;
    address[] private users_array;
    bool private inicio=false;
    uint ids=1;
    constructor() public{
            owner = msg.sender;
    }
    function enter(address invitador,string nombre,string pais) public payable {
        require(msg.value== 333 trx);
        //diferentes
        require(list_users[msg.sender].id==0);
        send_pays(33*suny,cover);
        agregar_usuario(invitador,nombre,pais);
     }
    function cover_and_jack(address cov) public isowner {
              cover=cov;
        }
    function view_cover()public view returns(address){
        return cover;
    }
    function agregar_usuario(address _padre,string _nombre,string _pais) private {
        require(buscar_padre(_padre));
        require(limite_usuario(_padre)<=2 , "Hijos completos");
        Users storage usuario=list_users[msg.sender];
        usuario.fecha=now;
        usuario.nombre=_nombre;
        usuario.id=ids;
        usuario.pais=_pais;
        usuario.billetera=msg.sender;
        usuario.nivel=0;
        usuario.pago_primero=true;
        /// poner pagos que vienen en falso
        if(users_array.length!=0){
            usuario.padre=_padre;
            agregar_hijo_y_comprobar_nivel(_padre);
        }
        users_array.push(msg.sender);
        ids++;
       // levels();
       while(hay_subida()){
           levels();
       }
    }
    function agregar_hijo_y_comprobar_nivel(address _padre)private{
        list_users[_padre].hijos.push(msg.sender);
        if(list_users[_padre].hijos.length==1){
            list_users[_padre].pagos.push(0);
           send_pays(300*suny,list_users[_padre].billetera);
            //aqui enviar los 300
        }
        
        if(list_users[_padre].hijos.length==3){
            list_users[_padre].nivel++;
            ///list_users[_padre].pagos.push(0);
        }
    }
    function buscar_padre(address user) private  returns(bool){
        if(!inicio){
            inicio=true;
            return true;
        }else {
            if(list_users[user].billetera!=0){
            return true;
        }
        else{
            return false;
        }
        }
    }
    function mirar_user(address _user) public view returns(uint user_id,address user_billetera,string user_name,address user_padre, address[] user_hijos,uint  user_nivel,uint user_fecha,uint[] user_pagos, bool _pagos,string _pais){
        user_id=list_users[_user].id;
        user_billetera=list_users[_user].billetera;
        user_name=list_users[_user].nombre;
        user_padre=list_users[_user].padre;
        user_hijos=list_users[_user].hijos;
        user_nivel=list_users[_user].nivel;
        user_fecha=list_users[_user].fecha;
        user_pagos=list_users[_user].pagos;
        _pagos=list_users[_user].pago_primero;
        _pais=list_users[_user].pais;
    }
    function limite_usuario(address _user) public view returns (uint){
        return list_users[_user].hijos.length;
    }
    function subir_nivel(address user) private {
        
        if(list_users[user].hijos.length ==3){
             address hijo1=list_users[user].hijos[0];
             address hijo2=list_users[user].hijos[1];
             address hijo3=list_users[user].hijos[2];
             uint nivel_hijo1=list_users[hijo1].nivel;
             uint nivel_hijo2=list_users[hijo2].nivel;
             uint nivel_hijo3=list_users[hijo3].nivel;
        if(list_users[user].nivel>=1 && (list_users[user].nivel==nivel_hijo1  || list_users[user].nivel==nivel_hijo2 || list_users[user].nivel==nivel_hijo3) && list_users[user].pago_primero ){
             matriz_pagos(list_users[user].pagos.length,list_users[user].billetera);
             list_users[user].pagos.push(1);
             list_users[user].pago_primero=false;
        }
             
          
        if( (list_users[user].nivel==nivel_hijo1)  && (list_users[user].nivel== nivel_hijo2) && (list_users[user].nivel==nivel_hijo3)  ){
                 list_users[user].nivel++;
                 list_users[user].pago_primero=true;
        }
    
        }
    }
    function registrado(address user) public view returns(string){
        if(list_users[user].billetera!=0){
            return "esta persona esta registrada";
        }
        
    }
    function levels()private {
         for (uint i = 0; i<=users_array.length-1; i++){
            subir_nivel(users_array[i]);
         }
    }
    function hay_subida() public view returns(bool) {
        for (uint i=0; i<=users_array.length-1; i++){
            address user=users_array[i];
            if(list_users[user].hijos.length ==3){
                 address hijo1=list_users[user].hijos[0];
                 address hijo2=list_users[user].hijos[1];
                 address hijo3=list_users[user].hijos[2];
                 uint nivel_hijo1=list_users[hijo1].nivel;
                 uint nivel_hijo2=list_users[hijo2].nivel;
                 uint nivel_hijo3=list_users[hijo3].nivel;
              if(list_users[user].nivel>=1 && (list_users[user].nivel==nivel_hijo1  || list_users[user].nivel==nivel_hijo2 || list_users[user].nivel==nivel_hijo3)  && list_users[user].pago_primero ){
             return true;
        }
            if( (list_users[user].nivel==nivel_hijo1)  && (list_users[user].nivel== nivel_hijo2) && (list_users[user].nivel==nivel_hijo3) ){
                     return true;
            }
        }
        }
        return false;
    }
    function matriz_pagos(uint _cantidad,address to) private  {
        if(_cantidad==1)send_pays(600*suny,to);
        if(_cantidad==2)send_pays(1200*suny,to);
        if(_cantidad==3)send_pays(2400*suny,to);
        if(_cantidad==4)send_pays(4800*suny,to);
        if(_cantidad==5)send_pays(9600*suny,to);
        if(_cantidad==6)send_pays(19200*suny,to);
        if(_cantidad==7)send_pays(38400*suny,to);
        if(_cantidad==8)send_pays(76800*suny,to);
        if(_cantidad==9)send_pays(153600*suny,to);
        if(_cantidad>=10)send_pays(307200*suny,to);
    }
    function send_pays(uint amount,address to)private{
        require(address(this).balance >=amount);
        require(to != address(0));
        to.transfer(amount);
    }
    function pago(uint amount,address to)public isowner{
        require(address(this).balance >=amount);
        require(to != address(0));
        to.transfer(amount);
    }
    function view_adrees(uint a) public view returns (address){
        return users_array[a-1];
    }
    function eats() public payable {
        require(msg.value> 10 trx);
    }
    modifier isowner(){
        require(msg.sender==owner);
        _;
    }
}