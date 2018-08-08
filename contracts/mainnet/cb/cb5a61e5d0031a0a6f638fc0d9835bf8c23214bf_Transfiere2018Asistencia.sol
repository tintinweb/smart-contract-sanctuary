pragma solidity ^0.4.20;

/*************************************************************************************
*
* Transfiere 2018 Database
* Property of FYCMA
* Powered by TICsmart
* Description: 
* Smart Contract of attendance at the event and forum Transfiere 2018
* C&#243;digo: C&#243;digo Hash impreso en el diploma facilitado por Transfiere 2018
*
**************************************************************************************/

contract Transfiere2018Asistencia {
    struct Organization {
        string codigo;
    }

    Organization[] internal availableOrgs;
    address public owner = msg.sender;

    function addOrg(string _codigo) public {
        require(msg.sender == owner);
        
        for (uint i = 0; i < availableOrgs.length; i++) {
            if (keccak256(availableOrgs[i].codigo) == keccak256(_codigo)) {
                return;
            }
        }
        
        availableOrgs.push(Organization(_codigo));
    }

    function deleteOrg(string _codigo) public {
        require(msg.sender == owner);

        for (uint i = 0; i < availableOrgs.length; i++) {
            if (keccak256(availableOrgs[i].codigo) == keccak256(_codigo)) {
                delete availableOrgs[i];
                availableOrgs.length--;
                return;
            }
        }
    }
    
    function checkCode(string _codigo) public view returns (string, string) {
        for (uint i = 0; i < availableOrgs.length; i++) {
            if (keccak256(availableOrgs[i].codigo) == keccak256(_codigo)) {
                return (_codigo,"El c&#243;digo es v&#225;lido.");
            }
        }
    
        return (_codigo,"El c&#243;digo no existe.");
    }
    
    function destroy() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}