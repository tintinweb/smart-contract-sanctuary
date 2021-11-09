/**
 *Submitted for verification at polygonscan.com on 2021-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

contract JN_test01 {

	//string private mensaje = "Probando Nov07-01 ...";
	//uint private limiteBucle = 10;
	string private version;
	uint private limiteBucle;

    constructor(){
        	version = "Nov07-vT2 ...";
	        limiteBucle = 10;
    }

	function setVersion(string memory pVersion) public {version = pVersion;}
	function getVersion() public view returns(string memory) {return version;}

	function setLimiteBucle(uint pLimite) public {
		limiteBucle = pLimite;
	}

	function getLimiteBucle() public view returns(uint) {
		return limiteBucle;
	}

	function executeContract(string memory pp) public view returns(uint) {

		//Accion 01
		//ToDo

		//Bucle
		uint contadorWhile = 0;
		while (contadorWhile < limiteBucle) {
			//pausado
			//cortaEjecucion = true;
			contadorWhile++;
		}

		//Accion 02
		return contadorWhile;

	}

}