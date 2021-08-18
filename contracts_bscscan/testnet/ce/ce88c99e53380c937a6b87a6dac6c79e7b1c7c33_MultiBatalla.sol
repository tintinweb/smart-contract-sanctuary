/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;
interface interfaceNFT {
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function getZoan(uint256 _tokenId) external view returns (uint256,uint256,uint8,uint256,uint256,uint256);
}

contract MultiBatalla {

    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event Received(address sender, uint amount);

    modifier isOwner() {
        require(msg.sender == owner, "No puedes llamar a esta funcion");
        _;
    }

    struct Token {
        uint256 id;
        uint256 rareza;
        uint256 ataques;
    }

    struct Jugador {
        bool activo;
        uint256 numeroAtaques;
        uint256 numeroTokens;
        Token[] tokens;
    }

    mapping(address => Jugador) internal jugadores;

    address payable private owner;
    address private nft = 0x8BbE571b381EE58Dd8f2335A8f0A5B42E83bdcfa;
    address private fight = 0xF70c08a428F300c7F3E3f09217211D21f7A50410;

    constructor() {
        owner = payable(msg.sender);
        emit OwnerSet(address(0), owner);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        emit Received(msg.sender, msg.value);
    }

    function combatirMonstruos(uint8 _nivel) public {
        if ( !jugadores[msg.sender].activo ) revert("Debes guardar la informacion de tus tokens antes de combatir.");
        uint8 nivelMonstruo = _nivel - 1;
        //combatir(nivelMonstruo);
        if ( jugadores[msg.sender].numeroTokens > 0 ) {
            a(nivelMonstruo);
        }
    }

    function a(uint8 _nivelMonstruo) internal {
        for ( uint256 i = 0; i < jugadores[msg.sender].numeroTokens; i++ ) {
            uint256 tokenid = jugadores[msg.sender].tokens[i].id;
            uint256 tokenataques = jugadores[msg.sender].tokens[i].ataques;
            for ( uint256 j = 0; j < tokenataques; j++) {
                (bool success, ) = address(fight).call(abi.encodeWithSignature("battle(uint256,uint8)", tokenid, _nivelMonstruo));
                if ( success) {}
            }
        }
    }

    function guardar() public isOwner {
        interfaceNFT _nft = interfaceNFT(nft);
        jugadores[msg.sender].activo = false;
        jugadores[msg.sender].numeroAtaques = 0;
        jugadores[msg.sender].numeroTokens = 0;
        if ( jugadores[msg.sender].tokens.length > 0 ) delete jugadores[msg.sender].tokens;
        uint256 usuarioAtaques = 0;
        uint256 usuarioTokens = _nft.balanceOf(msg.sender);
        for ( uint256 i = 0; i < usuarioTokens; i++ ) {
            uint256 usuarioToken = _nft.tokenOfOwnerByIndex(msg.sender, i);
            ( , , , , uint256 dna, ) = _nft.getZoan(usuarioToken);
            uint256 rareza = calcularRareza(dna);
            Token memory token = Token({
                id: usuarioToken,
                rareza: rareza,
                ataques: rareza
            });
            jugadores[msg.sender].tokens.push(token);
            jugadores[msg.sender].numeroTokens++;
            usuarioAtaques = usuarioAtaques + rareza;
        }
        if ( jugadores[msg.sender].tokens.length == usuarioTokens && usuarioTokens == jugadores[msg.sender].numeroTokens ) {
            jugadores[msg.sender].activo = true;
            jugadores[msg.sender].numeroAtaques = usuarioAtaques;
        }
    }

    function calcularRareza(uint256 _dna) internal pure returns (uint256) {
        if (_dna == 0) return 0;
        uint256 rareParser = _dna / 10**26;
        if (rareParser < 5225) {
            return 1;
        } else if (rareParser < 7837) {
            return 2;
        } else if (rareParser < 8707) {
            return 3;
        } else if (rareParser < 9360) {
            return 4;
        } else if (rareParser < 9708) {
            return 5;
        } else {
            return 6;
        }
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getContracts() external view returns (address, address) {
        return (nft, fight);
    }

    function obtenerInformacion() external view returns (Jugador memory) {
        return jugadores[msg.sender];        
    }

    function cambiarContratos(address _newNFTContract, address _newBattleContract) public isOwner {
        nft = _newNFTContract;
        fight = _newBattleContract;
    }

    function changeOwner(address _newOwner) public isOwner {
        emit OwnerSet(owner, _newOwner);
        owner = payable(_newOwner);
    }

    function retirar() public payable isOwner {
        (bool success, ) = msg.sender.call{value:address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function destruir() public payable isOwner {
        selfdestruct(payable(msg.sender));
    }





}