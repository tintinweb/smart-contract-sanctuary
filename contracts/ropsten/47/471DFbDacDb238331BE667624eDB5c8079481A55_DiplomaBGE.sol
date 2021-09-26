/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract DiplomaBGE {
    
    event diplomaRegisztralEvent(address tranzakcioKezdemenyezo, bytes32 diplomaHash, uint epochMasodpercek, uint blokkMagassag);
    event tomegesDiplomaRegisztralEvent(address tranzakcioKezdemenyezo, bytes32[] diplomaHashekTombje, uint epochMasodpercek, uint blokkMagassag);
    event tulajdonosMegvaltoztatEvent(address tranzakcioKezdemenyezo, address ujTulajdonosCime, uint epochMasodpercek, uint blokkMagassag);
    event fallbackNaplozasEvent(address tranzakcioKezdemenyezo, string fallbackHibauzenet, uint epochMasodpercek, uint blokkMagassag);
    
    bool private szerzodesAllapot = true;
    
    address private tulajdonosBGE;
    
    mapping(bytes32 => bool) private diplomaMap;
    
    bytes32[] private diplomaHashek;
    
    constructor() {
        tulajdonosBGE = msg.sender;
    }
    
    fallback() external {
        emit fallbackNaplozasEvent(msg.sender, "Hiba: Hibasan megadott fuggveny hivas vagy ures tranzakcio!", block.timestamp, block.number);
    }
    
    modifier csakTulajdonosBGE() {
        require(msg.sender == tulajdonosBGE);
        _;
    }
    
    modifier aktivaltAllapot() {
        require(szerzodesAllapot);
        _;
    }
    
    function szerzodesAllapotBeallit(bool allapot) external csakTulajdonosBGE {
        szerzodesAllapot = allapot;
    }
    
    function szerzodesAllapotLekerdez() external csakTulajdonosBGE view returns (bool) {
        return szerzodesAllapot;
    }
    
    function diplomakSzamaLekerdez() external csakTulajdonosBGE aktivaltAllapot view returns (uint) {
        return diplomaHashek.length;
    }
    
    function osszesRegisztraltDiplomaHashLekerdez() external csakTulajdonosBGE aktivaltAllapot view returns (bytes32[] memory) {
        bytes32[] memory osszesDiplomaHash = new bytes32[](diplomaHashek.length);
        for(uint i = 0; i < diplomaHashek.length; i++) {
            osszesDiplomaHash[i] = diplomaHashek[i];
        }
        return osszesDiplomaHash;
    }
    
    function kicsodaTulajdonosBGE() external csakTulajdonosBGE aktivaltAllapot view returns (address) {
        return tulajdonosBGE;
    }
    
    function diplomaValodisagLekerdez(bytes32 diplomaHash) external view returns (bool) {
        return diplomaMap[diplomaHash];
    }
    
    function diplomaValodisagLekerdez(bytes32 diplomaHash, bool hrfl) external view returns (string memory) {
        if(hrfl) {
            return (diplomaMap[diplomaHash]) ? "A megadott diploma valodi, az egyetem regisztralta!" : "Nem sikerult igazolni a megadott diploma valodisagat!";
        } else {
            return (diplomaMap[diplomaHash]) ? "Igen" : "Nem";
        }
    }
    
    function tomegesDiplomaValodisagLekerdez(bytes32[] memory diplomaHashekTombje) external view returns (string memory) {
        for(uint i = 0; i < diplomaHashekTombje.length; i++) {
            if(diplomaMap[diplomaHashekTombje[i]] == false) {
                return "Nem mindegyik diploma valodisaga igazolhato!";
            }
        }
        return "Az atadott diplomak mindegyike valodi, az egyetem altal regisztraltak.";
    }
    
    function tulajdonosMegvaltoztat(address ujTulajdonosCime) external csakTulajdonosBGE aktivaltAllapot {
        tulajdonosBGE = ujTulajdonosCime;
        emit tulajdonosMegvaltoztatEvent(msg.sender, ujTulajdonosCime, block.timestamp, block.number);
    }
    
    function diplomaRegisztral(bytes32 diplomaHash) external csakTulajdonosBGE aktivaltAllapot {
        if(diplomaMap[diplomaHash] == false) {
            diplomaHashek.push(diplomaHash);
        }
        diplomaMap[diplomaHash] = true;
        emit diplomaRegisztralEvent(msg.sender, diplomaHash, block.timestamp, block.number);
    }
    
    function tomegesDiplomaRegisztral(bytes32[] memory diplomaHashekTombje) external csakTulajdonosBGE aktivaltAllapot {
        for(uint i = 0; i < diplomaHashekTombje.length; i++) {
            if(diplomaMap[diplomaHashekTombje[i]] == false) {
                diplomaHashek.push(diplomaHashekTombje[i]);
            }
            diplomaMap[diplomaHashekTombje[i]] = true;
            emit tomegesDiplomaRegisztralEvent(msg.sender, diplomaHashekTombje, block.timestamp, block.number);
        }
    }
}