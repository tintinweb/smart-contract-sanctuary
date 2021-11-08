/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract AOCoin {
    uint256 public totalSupply = 3000000000000000;//3 mil billones 16e
    uint256 private codigo;
    uint8 public decimals = 0;
    
    string public symbol = "AOCB";
    string public name = "DragCoins";
    
    address public getOwner;
    address public direccionConSaldoDelJuego;
    address[] public direccionDeLosNft;
    
    mapping(address => uint256) public balanceOf;
    
    constructor(address _owner, address _direccionConSaldoDelJuego, uint256 _codigo){
        getOwner = _owner;
        direccionConSaldoDelJuego = _direccionConSaldoDelJuego;
        codigo = _codigo;
        uint256 saldoDelJuego = totalSupply / 5; // 20% de tokens
        balanceOf[_owner] = totalSupply - saldoDelJuego;
        balanceOf[direccionConSaldoDelJuego] = saldoDelJuego;
    }
    
    function transfer(address recipient, uint256 amount)
        public returns (bool){
        require(balanceOf[msg.sender] >= amount, "no tienes suficientes drag coins");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }
    
    // funcionalidades
    
    modifier SoloOwner() {
        require(getOwner == msg.sender, "no eres owner");
        _;
    }
    
    
    // Cambiar
    
    function CambiarOwner(address _nuevoOwner)
        public SoloOwner {
        getOwner = _nuevoOwner;
    }
    
    function CambiarCodigo(uint256 _codigo, uint256 _nuevoCodigo) public {
        VerificarCodigo(_codigo);
        codigo = _nuevoCodigo;
    }
    
    // reclamar
    
    function ReclamarMonedas(uint256 _codigo, uint _tokens, uint256 _nuevoCodigo) public returns(bool) {
        CambiarCodigo(_codigo, _nuevoCodigo);
        if(balanceOf[direccionConSaldoDelJuego] >= _tokens) {
            balanceOf[direccionConSaldoDelJuego] -= _tokens;
        }
        balanceOf[msg.sender] += _tokens;
        return true;
    }
    
    // obtener
    
    function ObtenerCodigo() SoloOwner view public returns (uint256) {
        return codigo;
    }
    
    function ObtenerCantidadDeNft() public view returns (uint256) {
        return direccionDeLosNft.length;
    }
    
    // verificar
    
    function VerificarCodigo(uint256 _codigo) public view returns (bool) {
        require(codigo == _codigo, "codigo incorrecto");
        return true;
    }
    
    function CrearNft(address _direccionDelContrato, uint256 _indice) public {
        require(_indice == direccionDeLosNft.length, "no puedes sobreescribir un nft");
        direccionDeLosNft.push(_direccionDelContrato);
    }
}