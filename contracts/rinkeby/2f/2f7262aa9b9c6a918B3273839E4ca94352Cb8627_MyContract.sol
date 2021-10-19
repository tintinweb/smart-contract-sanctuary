/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
contract MyContract {

    struct projet {
        string projetCID;
        int256 lab;
        string[] protocoleCids;
        string[] experienceCids;
    }
    
    struct protocole {
        string protocoleCID;
        int256 lab;
        string[] experienceCids;
    }
    
    struct data {
        string experienceCID;
        string[] dataCids;
    }
    
    struct operation {
        string experienceCID;
        string[] operationCids;
    }
    
    
    projet[] private projetTable;
    
    protocole[] private protocoleTable;
    
    data[] private dataTable;
    
    operation[] private operationTable;
    
    
    function addData(string memory _experienceCID,string[] memory _dataCid)public{
        dataTable.push(data(_experienceCID,_dataCid));
    }
    
    function updateDataByExprience (string memory _experienceCID,string memory _dataCid)public {
        for (uint256 i = 0; i < dataTable.length; i++) {
            if (keccak256(abi.encodePacked((dataTable[i].experienceCID))) ==  keccak256(abi.encodePacked((_experienceCID)))) {
                dataTable[i].dataCids.push(_dataCid);
            }
        }
    }
    
    function addOperation(string memory _experienceCID,string[] memory _operationCid)public{
        operationTable.push(operation(_experienceCID,_operationCid));
    }
    
    function updateOperationByExprience (string memory _experienceCID,string memory _operationCid)public {
        for (uint256 i = 0; i < operationTable.length; i++) {
            if (keccak256(abi.encodePacked((operationTable[i].experienceCID))) ==  keccak256(abi.encodePacked((_experienceCID)))) {
                operationTable[i].operationCids.push(_operationCid);
            }
        }
    }
    
    function addProjet(string memory _projetCID,int256 _lab,string[] memory _protocoleCids,string[] memory _experienceCids)public{
        projetTable.push(projet(_projetCID,_lab,_protocoleCids,_experienceCids));
    }
    
    function addProtocole(string memory _protocoleCID,int256 _lab,string[] memory _experienceCids)public{
        protocoleTable.push(protocole(_protocoleCID,_lab,_experienceCids));
    }
    
    function addProtocoleToProjet (string memory _projetCID,string memory _protocoleCid)public{
         for (uint256 i = 0; i < projetTable.length; i++) {
            if (keccak256(abi.encodePacked((projetTable[i].projetCID))) ==  keccak256(abi.encodePacked((_projetCID)))) {
                projetTable[i].protocoleCids.push(_protocoleCid);
            }
        }
    }
    
    function addExperienceToProjet (string memory _projetCID,string memory _experienceCid)public{
         for (uint256 i = 0; i < projetTable.length; i++) {
            if (keccak256(abi.encodePacked((projetTable[i].projetCID))) ==  keccak256(abi.encodePacked((_projetCID)))) {
                projetTable[i].experienceCids.push(_experienceCid);
            }
        }
    }
    
    function addExperienceToProtocole (string memory _protocoleCID,string memory _experienceCid)public{
         for (uint256 i = 0; i < protocoleTable.length; i++) {
            if (keccak256(abi.encodePacked((protocoleTable[i].protocoleCID))) ==  keccak256(abi.encodePacked((_protocoleCID)))) {
                protocoleTable[i].experienceCids.push(_experienceCid);
            }
        }
    }
    
    function getAllProjetForLab (int256 _lab) public view returns (projet[] memory){
        uint256 count;
        for (uint256 i = 0; i < projetTable.length; i++) {
            if (projetTable[i].lab ==  _lab) {
                count++;
            }
        }
        projet [] memory res = new projet[](count);
        uint j;
        for (uint256 i = 0; i < projetTable.length; i++) {
            if (projetTable[i].lab ==  _lab) {
                res[j] = projetTable[i];
                j++;
            }    
        }
    return (res);
    }
    
    function getAllExperienceAndProtocoleOfProjet (string memory _projetCID) public view returns (projet memory project){
        for (uint256 i = 0; i < projetTable.length; i++) {
            if (keccak256(abi.encodePacked((projetTable[i].projetCID))) ==  keccak256(abi.encodePacked((_projetCID)))) {
                return projetTable[i];
            }
        }
    }
    
    function getAllProtocoleForLab (int256 _lab) public view returns (protocole[] memory){
        uint256 count;
        for (uint256 i = 0; i < protocoleTable.length; i++) {
            if (protocoleTable[i].lab ==  _lab) {
                count++;
            }
        }
        protocole [] memory res = new protocole[](count) ;
        uint j;
        for (uint256 i = 0; i < protocoleTable.length; i++) {
            if (protocoleTable[i].lab == _lab) {
                res[j] = protocoleTable[i];
                j++;
            }    
        }
    return (res);
    }
    
    function getAllExperienceOfProtocole (string memory _protocoleCID) public view returns (protocole memory protocol){
        for (uint256 i = 0; i < protocoleTable.length; i++) {
            if (keccak256(abi.encodePacked((protocoleTable[i].protocoleCID))) ==  keccak256(abi.encodePacked((_protocoleCID)))) {
                return protocoleTable[i];
            }
        }
    }
    
    function getProtocoleByExprience (string memory _experienceCid) public view returns (string memory protocoleOfExperinence){
        string memory  res;
        for (uint256 i = 0; i < protocoleTable.length; i++) {
            for (uint256 j = 0; j < protocoleTable[i].experienceCids.length; j++) {
                if (keccak256(abi.encodePacked((protocoleTable[i].experienceCids[j]))) ==  keccak256(abi.encodePacked((_experienceCid)))) {
                    return res =protocoleTable[i].protocoleCID;
                }
            }
        }
    }
    
    function getProjetByExprience (string memory _experienceCid) public view returns (string memory projetOfExperinence){
        string memory  res;
        for (uint256 i = 0; i < projetTable.length; i++) {
            for (uint256 j = 0; j < projetTable[i].experienceCids.length; j++) {
                if (keccak256(abi.encodePacked((projetTable[i].experienceCids[j]))) ==  keccak256(abi.encodePacked((_experienceCid)))) {
                    return res =projetTable[i].projetCID;
                }
            }
        }
    }
    
    function getDataByExprience (string memory _experienceCid) public view returns (string [] memory dataOfExperinence){
        for (uint256 i = 0; i < dataTable.length; i++) {
                if (keccak256(abi.encodePacked((dataTable[i].experienceCID))) ==  keccak256(abi.encodePacked((_experienceCid)))) {
                    return dataTable[i].dataCids;
                }
        }
    }
    
    function getOperationByExprience (string memory _experienceCid) public view returns (string [] memory OperationOfExperinence){
        for (uint256 i = 0; i < operationTable.length; i++) {
                if (keccak256(abi.encodePacked((operationTable[i].experienceCID))) ==  keccak256(abi.encodePacked((_experienceCid)))) {
                    return operationTable[i].operationCids;
                }
        }
    }
    
    function checkForDataOfExperience (string memory _experienceCid) public view returns (bool check){
        for (uint256 i = 0; i < dataTable.length; i++) {
                if (keccak256(abi.encodePacked((dataTable[i].experienceCID))) ==  keccak256(abi.encodePacked((_experienceCid)))) {
                    return true;
                }
        }
    }
    
    function checkForOperationOfExperience (string memory _experienceCid) public view returns (bool check){
        for (uint256 i = 0; i < operationTable.length; i++) {
                if (keccak256(abi.encodePacked((operationTable[i].experienceCID))) ==  keccak256(abi.encodePacked((_experienceCid)))) {
                    return true;
                }
        }
    }
    
}