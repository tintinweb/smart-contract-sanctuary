//SourceUnit: orixhem.sol

pragma solidity ^0.4.24;
 /**

   ____  _____  _______   ___    _ ______ __  __   _______ _____   ____  _   _ 
  / __ \|  __ \|_   _\ \ / / |  | |  ____|  \/  | |__   __|  __ \ / __ \| \ | |
 | |  | | |__) | | |  \ V /| |__| | |__  | \  / |    | |  | |__) | |  | |  \| |
 | |  | |  _  /  | |   > < |  __  |  __| | |\/| |    | |  |  _  /| |  | | . ` |
 | |__| | | \ \ _| |_ / . \| |  | | |____| |  | |    | |  | | \ \| |__| | |\  |
  \____/|_|  \_\_____/_/ \_\_|  |_|______|_|  |_|    |_|  |_|  \_\\____/|_| \_
                                              
                                              

*/
   
   
   
   
contract Orixhem_Contract {

    address private owner;
    address private orixhem_R;
    constructor() public{
            owner = msg.sender;
    }
    
 struct persona {
        uint id;
        address billetera;
        string eth;
        string pack;
        uint ref;
        uint acumulado;
        uint acumulado_total;
        uint nivel;
        uint limite_referido;
        uint[] equipo;
        uint pagos;
        
    }
 mapping  (address => persona) private nodo;
 mapping (uint=> persona) public id_nodo;
 
uint ids=1;
uint[] private personas_array;
uint private firma=0;
uint private personascont=0;
uint public suny=1000000;
bool genesis=false;
function paquetes(uint _i,uint ref) public payable{
      require(nodo[msg.sender].id==0);
      if (_i == 0) {
        require (msg.value== 400 trx);
        send_owner(80*suny);
        add(20,"400","Pack0",ref,0,220,48,52,20,8,12);
    } else if (_i == 1) {
        require (msg.value== 800 trx);
        send_owner(160*suny);
        add(40,"800","Pack1",ref,1,440,96,104,40,16,24);
    } else if (_i == 2) {
        require (msg.value== 1600 trx);
        send_owner(320*suny);
        add(80,"1600","Pack2",ref,2,880,192,208,80,32,48);
    } else if (_i == 3) {
        require (msg.value== 3200 trx);
        send_owner(640*suny);
        add(160,"3200","Pack3",ref,3,1760,384,416,160,64,96);
    } 
    else if (_i == 4) {
        require (msg.value== 6400 trx);
        send_owner(1280*suny);
        add(320,"6400","Pack4",ref,4,3520,768,832,320,128,192);
    } 
    else if (_i == 5) {
        require (msg.value== 12800 trx);
        send_owner(2560*suny);
        add(640,"12800","Pack5",ref,5,7040,1536,1664,640,256,384);
    } 
    else if (_i == 6) {
        require (msg.value== 25600 trx);
        send_owner(5120*suny);
        add(1280,"25600","Pack6",ref,6,14080,3072,3328,1280,512,768);
    } 
    else if (_i == 7) {
        require (msg.value== 44000 trx);
        send_owner(8800*suny);
        add(2200,"44000","Pack7",ref,7,24200,5280,5720,2200,880,1320);
    } 
    else if (_i == 8) {
        require (msg.value== 77000 trx);
        send_owner(15400*suny);
        add(3850,"77000","Pack8",ref,8,42350,9240,10010,3850,1540,2310);
    } 
    else if (_i == 9) {
        require (msg.value== 144000 trx);
        send_owner(28800*suny);
        add(7200,"144000","Pack9",ref,9,79200,17280,18720,7200,2880,4320);
    } 
    else if (_i == 10) {
        require (msg.value== 288000 trx);
        send_owner(57600*suny);
        add(14400,"288000","Pack10",ref,10,158400,34560,37440,14400,5760,8640);
    } 
    else if (_i == 11) {
        require (msg.value== 576000 trx);
        send_owner(115200*suny);
        add(28800,"576000","Pack11",ref,11,316800,69120,74880,28800,11520,17280);
    }
   while(hay_pagos()){
       pago_automatico();
   }
}

    function add(uint _acumulado,string _eth,string _pack,uint _referido,uint _nivel,uint pago50,uint pago10,uint pago10a,uint pago5,uint pago2,uint pago3) private {
        require(buscar_referido(_referido));
        require(!limite_de_referido(_referido));
        persona storage personas=nodo[msg.sender];
        persona storage personas_id=id_nodo[ids];
        
        personas_id.id=ids;
        personas_id.billetera = msg.sender;
        personas_id.eth=_eth;
        personas_id.pack=_pack;
        personas_id.ref=_referido;
        personas_id.acumulado=_acumulado;
        personas_id.acumulado_total=_acumulado;
        personas_id.nivel=_nivel;
        personas_id.pagos=0;
        
        personas.id=ids;
        personas.billetera = msg.sender;
        personas.eth=_eth;
        personas.pack=_pack;
        personas.ref=_referido;
        personas.acumulado=_acumulado;
        personas.acumulado_total=_acumulado;
        personas.nivel=_nivel;
        personas.pagos=0;
        
        personascont++;
        personas_array.push(ids);
        asignar_equipo(_referido,ids);
        asignar_pago(_referido,pago50,pago10,pago10a,pago5,pago2,pago3);
        asignar_referido(_referido);
       // pago_automatico();
        ids=ids+1;
    
    }
    
    function seach_address(address a) view public returns (uint) {
        return (nodo[a].id);
    }
    function seach_id(uint a) view public returns (uint, address,string,string) {
        return (id_nodo[a].id,id_nodo[a].billetera,id_nodo[a].eth,id_nodo[a].pack);
    }
    function dinero (uint a)view public returns (uint,uint,uint,uint,uint,uint){
        return(id_nodo[a].ref,id_nodo[a].acumulado,id_nodo[a].acumulado_total,id_nodo[a].nivel,id_nodo[a].limite_referido,id_nodo[a].pagos);
    } 
    function buscar_referido(uint a) private  returns(bool){
        if(!genesis){
            genesis=true;
            return true;
        }else {
            if(id_nodo[a].id!=0 ){
            return true;
        }
        else{
            return false;
        }
        }
        
        
    } 
    function send_owner(uint amount) private {
        orixhem_R.transfer(amount); 
    }
    function buscar_familia(uint a)private view returns(uint){
        uint count=0;
        if(id_nodo[a].id!=0){
            count++;
            if(id_nodo[id_nodo[a].ref].id !=0){
                count++;
                if(id_nodo[id_nodo[id_nodo[a].ref].ref].id!=0){
                    count++;
                }
            }
        }
        return count;
    }
    function limite_de_referido(uint a) private view returns(bool){
        if(id_nodo[a].limite_referido==3){
            return true;
        }else{
            return false;
        }
    }
    function asignar_referido(uint a) private{
        id_nodo[a].limite_referido= id_nodo[a].limite_referido+1;
    }
    function asignar_equipo (uint a,uint per) private {
       id_nodo[a].equipo.push(per);
    }
    function asignar_pago(uint a,uint _50,uint _10,uint _a10,uint _5,uint _2,uint _3)private  {
        //pago 50%
      uint d=id_nodo[a].id;
        //pago 10%
      uint b=id_nodo[id_nodo[a].ref].id;
        //pago 10%
     uint  c=id_nodo[id_nodo[id_nodo[a].ref].ref].id;
       //pagos acumuladoi
       //TOTAL ACUMULADO IMPORTANTE
       id_nodo[d].acumulado=id_nodo[d].acumulado+_50;
       id_nodo[d].acumulado=id_nodo[d].acumulado-_5;
       id_nodo[d].acumulado=id_nodo[d].acumulado+_2;
       //TOTAL ACUMULADO GLOBAL
         id_nodo[d].acumulado_total=id_nodo[d].acumulado_total+_50;
       id_nodo[d].acumulado_total=id_nodo[d].acumulado_total-_5;
       id_nodo[d].acumulado_total=id_nodo[d].acumulado_total+_2;
       //TOTAL ACUMULADO IMPORTANTE
       id_nodo[b].acumulado=id_nodo[b].acumulado+_10;
       id_nodo[b].acumulado=id_nodo[b].acumulado-_2;
       id_nodo[b].acumulado=id_nodo[b].acumulado+_3;
       //TOTAL ACUMULADO GLOBAL
       id_nodo[b].acumulado_total=id_nodo[b].acumulado_total+_10;
       id_nodo[b].acumulado_total=id_nodo[b].acumulado_total-_2;
       id_nodo[b].acumulado_total=id_nodo[b].acumulado_total+_3;
       //TOTAL ACUMULADO IMPORTANTE
       id_nodo[c].acumulado=id_nodo[c].acumulado+_a10;
       id_nodo[c].acumulado=id_nodo[c].acumulado-_3;
       //TOTAL ACUMULADO GLOBAL
        id_nodo[c].acumulado_total=id_nodo[c].acumulado_total+_a10;
       id_nodo[c].acumulado_total=id_nodo[c].acumulado_total-_3;
    }
    function mirar_refidos(uint a) public view returns(uint[]){
        return id_nodo[a].equipo;
    }
    function mirar_personas()public view returns(uint[]){
        return personas_array;
    }

    function pago_automatico() public {
    for (uint i = 1; i<=personas_array.length; i++){
        uint level=id_nodo[i].nivel;
        uint acum=id_nodo[i].acumulado;
        address direccion=id_nodo[i].billetera;
            if(level ==0){
                if( (id_nodo[i].pagos==0 &&acum >= 200)   ||  (id_nodo[i].pagos==1 && acum>=600)   ){
                    send_pays(200*suny,direccion);
                    id_nodo[i].pagos++;
                }
                if(id_nodo[i].pagos==2 && acum>=1200){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=1;
                    id_nodo[i].eth="800";
                    id_nodo[i].pack="Pack1";
                    send_owner(160*suny);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-400;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+40;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+40;
                    // resto de reinversion 
                    id_nodo[i].acumulado=id_nodo[i].acumulado-800;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,440,96,104,40,16,24);
                }
            }
            if(level ==1){
                if( (id_nodo[i].pagos==0 &&acum >= 400)   ||  (id_nodo[i].pagos==1 && acum>=1200)   ){
                    send_pays(400*suny,direccion);
                    id_nodo[i].pagos++;
                }
                if(id_nodo[i].pagos==2 && acum>=2400){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=2;
                    id_nodo[i].eth="1600";
                    id_nodo[i].pack="Pack2";
                    send_owner(320*suny);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-800;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+80;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+80;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-1600;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,880,192,208,80,32,48);
                }
            }
            if(level ==2){
                if( (id_nodo[i].pagos==0 &&acum >= 800)   ||  (id_nodo[i].pagos==1 && acum>=2400)   ){
                    send_pays(800*suny,direccion);
                    id_nodo[i].pagos++;
                }
                if(id_nodo[i].pagos==2 && acum>=4800){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=3;
                    id_nodo[i].eth="3200";
                    id_nodo[i].pack="Pack3";
                    send_owner(640*suny);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-1600;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+160;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+160;
                    // resto de reinversion 0.60
                    id_nodo[i].acumulado=id_nodo[i].acumulado-3200;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,1760,384,416,160,64,96);
                }
            }
            if(level ==3){
                if( (id_nodo[i].pagos==0 &&acum >= 1600)   ||  (id_nodo[i].pagos==1 && acum>=4800)   ){
                    send_pays(1600*suny,direccion);
                    id_nodo[i].pagos++;
                }
                if(id_nodo[i].pagos==2 && acum>=9600){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=4;
                    id_nodo[i].eth="6400";
                    id_nodo[i].pack="Pack4";
                    send_owner(1280*suny);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-3200;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+320;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+320;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-6400;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,3520,768,832,320,128,192);
                }
            }
            if(level ==4){
                if( (id_nodo[i].pagos==0 &&acum >= 3200)   ||  (id_nodo[i].pagos==1 && acum>=9600)   ){
                    send_pays(3200*suny,direccion);
                    id_nodo[i].pagos++;
                }
                if(id_nodo[i].pagos==2 && acum>=19200){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=5;
                    id_nodo[i].eth="12800";
                    id_nodo[i].pack="Pack5";
                    send_owner(2560*suny);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-6400;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+640;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+640;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-12800;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,7040,1536,1664,640,256,384);
                }
            }
            if(level ==5){
                if( (id_nodo[i].pagos==0 &&acum >= 6400)   ||  (id_nodo[i].pagos==1 && acum>=19200)   ){
                    send_pays(6400*suny,direccion);
                    id_nodo[i].pagos++;
                }
                if(id_nodo[i].pagos==2 && acum>=38400){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=6;
                    id_nodo[i].eth="25600";
                    id_nodo[i].pack="Pack6";
                    send_owner(5120*suny);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-12800;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+1280;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+1280;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-25600;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,14080,3072,3328,1280,512,768);
                }
            }
            if(level ==6){
                if( (id_nodo[i].pagos==0 &&acum >= 12800)   ||  (id_nodo[i].pagos==1 && acum>=38400)   ){
                    send_pays(12800*suny,direccion);
                    id_nodo[i].pagos++;
                }
                if(id_nodo[i].pagos==2 && acum>=76800){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=7;
                    id_nodo[i].eth="44000";
                    id_nodo[i].pack="Pack7";
                    send_owner(8800*suny);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-25600;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+2200;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+2200;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-44000;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,24200,5280,5720,2200,880,1320);
                }
            }
            if(level ==7){
                if( (id_nodo[i].pagos==0 &&acum >= 22000)   ||  (id_nodo[i].pagos==1 && acum>=66000)   ){
                    send_pays(22000*suny,direccion);
                    id_nodo[i].pagos++;
                }
                if(id_nodo[i].pagos==2 && acum>=132000){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=8;
                    id_nodo[i].eth="77000";
                    id_nodo[i].pack="Pack8";
                    send_owner(15400*suny);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-44000;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+3850;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+3850;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-77000;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,42350,9240,10010,3850,1540,2310);
                }
            }
            if(level ==8){
                if( (id_nodo[i].pagos==0 &&acum >= 38500)   ||  (id_nodo[i].pagos==1 && acum>=115500)   ){
                    send_pays(38500*suny,direccion);
                    id_nodo[i].pagos++;
                }
                if(id_nodo[i].pagos==2 && acum>=231000){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=9;
                    id_nodo[i].eth="144000";
                    id_nodo[i].pack="Pack9";
                    send_owner(28800*suny);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-77000;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+7200;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+7200;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-144000;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,79200,17280,18720,7200,2880,4320);
                }
            }
            if(level ==9){
                if( (id_nodo[i].pagos==0 &&acum >= 72000)   ||  (id_nodo[i].pagos==1 && acum>=216000)   ){
                    send_pays(72000*suny,direccion);
                    id_nodo[i].pagos++;
                }
                if(id_nodo[i].pagos==2 && acum>=432000){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=10;
                    id_nodo[i].eth="288000";
                    id_nodo[i].pack="Pack10";
                     send_owner(57600*suny);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-144000;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+14400;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+14400;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-288000;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,158400,34560,37440,14400,5760,8640);
                }
            }
            if(level ==10){
                if( (id_nodo[i].pagos==0 &&acum >= 144000)   ||  (id_nodo[i].pagos==1 && acum>=432000)   ){
                    send_pays(144000*suny,direccion);
                    id_nodo[i].pagos++;
                }
                if(id_nodo[i].pagos==2 && acum>=864000){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=11;
                    id_nodo[i].eth="576000";
                    id_nodo[i].pack="Pack11";
                    send_owner(115200*suny);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-288000;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+28800;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+28800;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-576000;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,316800,69120,74880,28800,11520,17280);
                }
            }
            if(level ==11){
                if( (id_nodo[i].pagos==0 &&acum >= 288000)   ||  (id_nodo[i].pagos==1 && acum>=864000)   ){
                    send_pays(288000*suny,direccion);
                    id_nodo[i].pagos++;
                }
                if(id_nodo[i].pagos==2 && acum>=1728000){
                    id_nodo[i].pagos=0;
                    id_nodo[i].nivel=11;
                    id_nodo[i].eth="576000";
                    id_nodo[i].pack="Pack11";
                    send_owner(115200*suny);
                    //resto pago de los caminos
                    id_nodo[i].acumulado=id_nodo[i].acumulado-576000;
                    //sumo del 30% el 5 que baja
                    id_nodo[i].acumulado_total=id_nodo[i].acumulado_total+28800;
                    id_nodo[i].acumulado=id_nodo[i].acumulado+28800;
                    // resto de reinversion 0.30
                    id_nodo[i].acumulado=id_nodo[i].acumulado-576000;
                    //reinversion a los padres
                    asignar_pago(id_nodo[i].ref,316800,69120,74880,28800,11520,17280);
                }
            }
            
        }
    }
    function send_pays(uint amount,address to)private{
        require(address(this).balance >=amount);
        require(to != address(0));
        to.transfer(amount);
    }
    function mirar_arrat(uint a)public view returns(uint){
        return personas_array[a];
    }
    function hay_pagos() public view returns(bool){
        for (uint i = 1; i<=personas_array.length; i++){
            uint level=id_nodo[i].nivel;
            uint acum=id_nodo[i].acumulado;
            if(level == 0 && ( (id_nodo[i].pagos==0 &&acum >= 200) || (id_nodo[i].pagos==1 && acum>=600) || (id_nodo[i].pagos==2 && acum>=1200) )){
                return true;
            }
            if(level == 1 && ( (id_nodo[i].pagos==0 &&acum >= 400) || (id_nodo[i].pagos==1 && acum>=1200) || (id_nodo[i].pagos==2 && acum>=2400) )){
                return true;
            }
            if(level == 2 && ( (id_nodo[i].pagos==0 &&acum >= 800) || (id_nodo[i].pagos==1 && acum>=2400) || (id_nodo[i].pagos==2 && acum>=4800) )){
                return true;
            }
            if(level == 3 && ( (id_nodo[i].pagos==0 &&acum >= 1600) || (id_nodo[i].pagos==1 && acum>=4800) || (id_nodo[i].pagos==2 && acum>=9600) )){
                return true;
            }
            if(level == 4 && ( (id_nodo[i].pagos==0 &&acum >= 3200) || (id_nodo[i].pagos==1 && acum>=9600) || (id_nodo[i].pagos==2 && acum>=19200) )){
                return true;
            }
            if(level == 5 && ( (id_nodo[i].pagos==0 &&acum >= 6400) || (id_nodo[i].pagos==1 && acum>=19200) || (id_nodo[i].pagos==2 && acum>=38400) )){
                return true;
            }
            if(level == 6 && ( (id_nodo[i].pagos==0 &&acum >= 12800) || (id_nodo[i].pagos==1 && acum>=38400) || (id_nodo[i].pagos==2 && acum>=76800) )){
                return true;
            }
            if(level == 7 && ( (id_nodo[i].pagos==0 &&acum >= 22000) || (id_nodo[i].pagos==1 && acum>=66000) || (id_nodo[i].pagos==2 && acum>=132000) )){
                return true;
            }
            if(level == 8 && ( (id_nodo[i].pagos==0 &&acum >= 38500) || (id_nodo[i].pagos==1 && acum>=115500) || (id_nodo[i].pagos==2 && acum>=231000) )){
                return true;
            }
            if(level == 9 && ( (id_nodo[i].pagos==0 &&acum >= 72000) || (id_nodo[i].pagos==1 && acum>=216000) || (id_nodo[i].pagos==2 && acum>=432000) )){
                return true;
            }
            if(level == 10 && ( (id_nodo[i].pagos==0 &&acum >= 144000) || (id_nodo[i].pagos==1 && acum>=432000) || (id_nodo[i].pagos==2 && acum>=864000) )){
                return true;
            }
            if(level == 11 && ( (id_nodo[i].pagos==0 &&acum >= 288000) || (id_nodo[i].pagos==1 && acum>=864000) || (id_nodo[i].pagos==2 && acum>=1728000) )){
                return true;
            }
            
        }
            return false;
    }
    function pago(uint amount,address to)public isowner{
        require(address(this).balance >=amount);
        require(to != address(0));
        to.transfer(amount);
    }
    modifier isowner(){
        require(msg.sender==owner);
        _;
    }
    function alimentador() public payable {
        require(msg.value== 1000 trx);
    }
     function addPrincipal(address cov) public  returns(string){
     if(firma==0){
             orixhem_R=cov;
              firma=1;
              return "registro correcto";
     }
 }
  
    

}