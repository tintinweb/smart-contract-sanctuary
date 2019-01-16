pragma solidity ^0.4.17;


// crear otra que nuestre las entidades

contract juegoSillaConsensys01{

//creator : Gustavo Chiappe ,Argentina 
//<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="82e1eaebe3f2f2e7e5f7f1c2e5efe3ebeeace1edef">[email&#160;protected]</a>

	address public manager;
	address public oraculoSorteos;


   /* ver si necesitas que el players sea publico   78.9999   89.9999 */

   address []  private players;

   address []  private Entidadesdonaciones;

   mapping(address=>uint) private TokensGus;


   mapping(address=>uint) private Pozo_total;



   uint private Pozo_porcentaje;

   //

   uint private dineroFundacion;

   uint private valorManager;

   uint private valorcopa;

   uint private pozo;

   uint private valorcopaJugador;

        //uint private valorDefJugador ;

    uint private porcentajetranferirJ;



    mapping(address=>uint) private gananciaJugador;

    //ver si al token EntidadesDonacion poner otro nombre

    mapping(address=>uint) private TEntidadesDonacion;



   modifier restricted(){
        //se copia lo que se va a repetir
        require(msg.sender==manager);
        _;
    }


    modifier oraculoAsignado(){
        //se copia lo que se va a repetir
        require(msg.sender==oraculoSorteos);
        _;
    }


    function juegoSillaConsensys01(address _oraculoSorteos) public  {

    	manager = msg.sender;

    	require (manager != _oraculoSorteos);

    	oraculoSorteos = _oraculoSorteos;
        

    }







    function entradaJugador(uint _gananciaJugador) public payable{

      require(msg.value == 1 ether);

      require(_gananciaJugador<=95 && _gananciaJugador>=1 );

      //no participan ni el oraculo y el owned , tampoco entidad

     require(msg.sender!= manager && msg.sender!= oraculoSorteos );


     require(exiteJugador(msg.sender)==false );

      //NO PUEDE SER ENTIDAD

      require(exiteEntidad(msg.sender)==false);

      players.push(msg.sender);


       TokensGus[msg.sender] = msg.value;

       Pozo_total[manager] += msg.value;

       Pozo_porcentaje += _gananciaJugador;

       gananciaJugador[msg.sender]=_gananciaJugador;

   }

   



  function cantEntidades() public view returns(uint){

  	return Entidadesdonaciones.length;

  }



  function eliminarEntidades(uint index) private  {

        require(index < Entidadesdonaciones.length);
       // if (index >= Entidadesdonaciones.length) return;
       TEntidadesDonacion[Entidadesdonaciones[index]]=0;

       for (uint i = index; i<Entidadesdonaciones.length-1; i++){

       	Entidadesdonaciones[i] = Entidadesdonaciones[i+1];

       }

       Entidadesdonaciones.length--;
    }



   function exiteJugador(address jugador) private view returns(bool)  {

   	if(TokensGus[jugador]>0) return true;

   	return false;
   }



   /*Jugadores */

   function verPlayer() public  view returns (address[]){
   	return players;
   }

 /* entidades  */
   function verEntidades() public  view returns (address[]){
   	return Entidadesdonaciones;
   }




    function EnterEntidadesdonaciones(address _entidades) public  restricted {



        /*=====================================================================
        =            chequear que no sea el onwer ni el oraculo :)            =
        =====================================================================*/
        require(manager!=_entidades);
        require(oraculoSorteos!=_entidades);     
        /*=====  End of chequear que no sea el onwer ni el oraculo :)  ======*/




        /*============================================================
        =            require no se repita ni sea jugador             =
        ============================================================*/
        require(exiteJugador(_entidades)==false);

        require(exiteEntidad(_entidades)==false);

        /*=====  End of require no se repita ni sea jugador   ======*/

        Entidadesdonaciones.push(_entidades);

        TEntidadesDonacion[_entidades] += 1;

    }







   /** para chequear que ya la entidad existe **/

    function exiteEntidad(address _entidades) private view returns(bool)  {

   	if(TEntidadesDonacion[_entidades]>0) return true;

   	return false;
   }




   function random() private view returns (uint){

   	return uint( keccak256(block.difficulty, now,players));

   }





    function thisbalanceETH() public view returns (uint) {

    	return  this.balance/1000000000000000000 ;

    }



	function rondaSilla()   public oraculoAsignado {


       // verificamos que haya como minimo 2 jugadores

       require (Entidadesdonaciones.length>=2);

       require (players.length>=2);

       // verificamos que haya hasta el 95% del pozo
       if( Pozo_porcentaje<= 95) {

       	darPremio();

       }
       
       else {

       	/* se va un jugador */

       	uint eliminado = random()% players.length;

       	eliminarjugador(eliminado);

       	if(players.length==1) {

       		darPremio();

       	}

       	else {

       		rondaSilla();
       	}
       }                                   
   }



   function eliminarjugador(uint index) private  {

   	require(index < players.length);

       // if (index >= Entidadesdonaciones.length) return;

       Pozo_porcentaje -= gananciaJugador[players[index]];

       gananciaJugador[players[index]]=0;

       TokensGus[players[index]]=0;

       for (uint i = index; i<players.length-1; i++){

       	players[i] = players[i+1];

       }

       players.length--;

    }



   function darPremio() private {

   	pozo =uint (Pozo_total[manager]);

   	valorcopa =  uint((pozo *( Pozo_porcentaje)/100));

   	valorManager = uint (pozo /100);

   	dineroFundacion =  pozo - valorcopa - valorManager;


   	for (uint i = 0; i<players.length; i++){

   		valorcopaJugador = gananciaJugador[players[i]];

   		porcentajetranferirJ = uint ((pozo * valorcopaJugador) / 100);

   		players[i].transfer(porcentajetranferirJ);


   	}


   	manager.transfer(valorManager);

   	uint index_entidades = random()% Entidadesdonaciones.length;

   	Entidadesdonaciones[index_entidades].transfer(dineroFundacion);

        // aca limpia :
    for( i =0; i<players.length;i++){

        //delete TokensGus[players[i]]=0;

        delete TokensGus[players[i]];
       delete gananciaJugador[players[i]];

       delete TokensGus[players[i]];

        }

    players =new address[](0);

    Pozo_total[manager]=0;

    Pozo_porcentaje=0;

    }





}