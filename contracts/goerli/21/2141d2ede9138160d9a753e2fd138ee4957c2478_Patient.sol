/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface ILicensedDoctors {
    function isLicensed(address doctor) external view returns(bool);
}

contract Patient {
    // Initialisierung
    address private owner;
    address[] private listDoctors; //Adresse von Contract des Arztes bzw. von Arzt (nicht Contract, weil wir den weglassen)
    address private licensedDoctorsContract = 0x166C8F20261566fd8bB607D776717295A74abB14;
    
    //Event:
    // - Arzt Zugriff erteilen/ entziehen
    event addedAccess(address doctor);
    event removedAccess(address doctor);
    // - Arzt liest Daten
    event readedData(address doctor);
    // - Arzt verändert Daten/ Patientenhistorie
    event addedData(address doctor);
    event changedData(address doctor);
    event removedData(address doctor);
    

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    //Funktionen:
    // - Freigabe: Patient (nur Owner) erteilt Arzt (Lese-/Schreib-)Freigabe indem Listeneintrag ergänzt wird (und schreibt Listeneintrag in Arzt-Contract (Name + Adresse))
    function release(address doctor) public isOwner {
        require(ILicensedDoctors(licensedDoctorsContract).isLicensed(doctor), "Doctor is not licensed");
        if(!search(doctor)){
            listDoctors.push(doctor);
            emit addedAccess(doctor);
        }
    }

    // - Freigabe entziehen
    function removeRelease(address doctor) public isOwner {
        for(uint i=0; i<listDoctors.length; i++){
            if(listDoctors[i] == doctor){
                listDoctors[i] = listDoctors[listDoctors.length-1];
                listDoctors.pop();
                emit removedAccess(doctor);
            }
        }
    }  

    // - Aufgerufen von Arzt, ob er Zugriff auf Patient hat;  Event Arzt mit ID will Zugriff auf Daten
    function inList() public returns(bool){
        if(search(msg.sender)){
            //emit hasAccess(msg.sender);
            return true;
        }
        return false;
    }

    // - Dokumentation/Protokollierung der Zugriffe als Event 
    function readData() public returns(bool){
        emit readedData(msg.sender);
        return true;
    }
    function addData() public returns(bool){
        emit addedData(msg.sender);
        return true;
    }
    function changeData() public returns(bool){
        emit changedData(msg.sender);
        return true;
    }
    function removeData() public returns(bool){
        emit removedData(msg.sender);
        return true;
    }

    // - Hilfsfunktion; sucht Wert in Liste
    function search(address a) private view returns(bool){
        for(uint i=0; i<listDoctors.length; i++){
            if(listDoctors[i] == a){
                return true;
            }
        }
        return false;
    }

}