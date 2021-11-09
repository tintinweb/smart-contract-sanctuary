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
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    constructor(address _owner, address _direccionConSaldoDelJuego, uint256 _codigo){
        getOwner = _owner;
        direccionConSaldoDelJuego = _direccionConSaldoDelJuego;
        codigo = _codigo;
        uint256 saldoDelJuego = totalSupply / 5; // 20% de tokens
        uint256 saldoDelOwner = totalSupply - saldoDelJuego;
        balanceOf[getOwner] = saldoDelOwner;
        balanceOf[direccionConSaldoDelJuego] = saldoDelJuego;
        emit Transfer(address(0), getOwner, saldoDelOwner);
        emit Transfer(address(0), direccionConSaldoDelJuego, saldoDelJuego);
    }
    
    function transfer(address recipient, uint256 amount)
        public returns (bool){
        require(balanceOf[msg.sender] >= amount, "no tienes suficientes drag coins");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferMultiple(address[] memory _direcciones, uint256[] memory _tokens) public {
        uint256 length = _direcciones.length;
        require(length == _tokens.length, "no coinciden la cantidad de direcciones con la de los tokens");
        for(uint256 i = 0; i < length; i++) {
            uint256 tokensIndice = _tokens[i];
            if(balanceOf[msg.sender] >= tokensIndice) {
                address toIndice = _direcciones[i];
                balanceOf[msg.sender] -= tokensIndice;
                balanceOf[toIndice] += tokensIndice;
                emit Transfer(msg.sender, toIndice, tokensIndice);
            }
        }
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
        require(balanceOf[direccionConSaldoDelJuego] > 0, "no hay tokens para reclamar");
        CambiarCodigo(_codigo, _nuevoCodigo);
        if(balanceOf[direccionConSaldoDelJuego] < _tokens) {
            _tokens = balanceOf[direccionConSaldoDelJuego];
        }
        balanceOf[direccionConSaldoDelJuego] -= _tokens;
        balanceOf[msg.sender] += _tokens;
        emit Transfer(direccionConSaldoDelJuego, msg.sender, _tokens);
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