/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-2.0-or-later
//wei	1  wei	1
//Kwei (babbage)	1e3 wei	1,000
//Mwei (lovelace)	1e6 wei	1,000,000
//Gwei (shannon)	1e9 wei	1,000,000,000
//microether (szabo)	1e12 wei	1,000,000,000,000
//milliether (finney)	1e15 wei	1,000,000,000,000,000
//ether	1e18 wei	1,000,000,000,000,000,000

//0.0041625
//0.004.162.500.000.000.000

contract rifa {
    
    string public emisor = "jszwako.loopring.eth";
    string public premio = "300.000 satochis";
    string public aviso = "Solo segwit para pago";
    uint public altura = block.number+1+21600; //1 min
    //uint public _altura = block.number + 172800; //(60/3)*60*24*6 -- 6 dias
    uint public objetivo = 333*1e15;
    uint public precio = 4162500*1e9;
    bytes20 public hashGanador;
    bytes20 UltimoHash;

    uint public contador = 0;
    mapping (uint => address) public jugadores;
    mapping (address => bool) public ya_jugo;
    address  public dueno;
    
    constructor()
    {
        dueno = msg.sender;
    }
    
    modifier SoloSiTermino() 
    {
        require(block.number>=altura,"Blocknumber < altura");
        require(ya_jugo[msg.sender] || msg.sender==dueno,"No tiene permisos para terminar");
        _;
    }
  
    modifier SoloSiNOTermino() 
    {
        require(block.number<altura,"Ya termino");
        _;
    }
 
    
 
    function resultado() public view returns (bytes20,address)
    {
        require(hashGanador!=bytes20(0),"No ha terminado");
        uint _diff = 2**160; //numero muy grande para comenzar
        uint _ganadorID = 0;
        uint _x = 0;
        for(uint i=1;i<=contador;i++){
            _x = ver_si_gana(i);
            if(_x<_diff) 
            {
                _ganadorID = i;
                _diff=_x;
            }
        }
        return (hashGanador,jugadores[_ganadorID]) ;
    }
    
    function ver_si_gana(uint x) internal view returns (uint160)
    {
        bytes20 _resultadoByte = 
        
            hashGanador//TX_hash del bloque de decision
            ^ 
            bytes20(jugadores[x]); // direccion del un jugador cualquiera
        
        uint160 _resultadoUint = uint160(_resultadoByte);
        return _resultadoUint;
    }
    
    function jugar() internal 
    {
        jugadores[++contador] = msg.sender;
        ya_jugo[msg.sender]=true;
        UltimoHash = bytes20(keccak256(abi.encode(block.timestamp,abi.encode(UltimoHash))));
        if(msg.value>precio) 
        {
            payable(msg.sender).transfer(msg.value - precio);
        }
    }
    
    function terminar() SoloSiTermino public 
    {
        hashGanador = bytes20(keccak256((abi.encode(block.number,abi.encode(UltimoHash)))));
    }
    
    function verAltura() public view returns(uint)
    {
        return block.number;
    }
    
    receive() external payable 
    {
        require(msg.value>=precio,"Valor menor al precio");
        require(!ya_jugo[msg.sender],"No se puede jugar dos veces");
        jugar();
    }
    
}