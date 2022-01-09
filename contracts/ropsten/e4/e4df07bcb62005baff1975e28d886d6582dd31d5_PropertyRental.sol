/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract PropertyRental {
    
    // --------------------------- Declaraciones ---------------------------

    // struct con los datos de la propiedad
    struct Property {
        bytes32 id;
        address ownerAddres;
        string propertyAddress;
        string city;
        string country;
        uint256 monthlyRent;
        bool available; 
    }

    // mapping que relaciona un usuario con una lista de propiedades
    mapping(address => Property[]) PropertyOwners;

    // Lista de propiedades
    Property[] propertiesList;

    // struct para aplicar a rentar una propiedad
    struct Applicant {
        address add;
        string name;
        uint amountContributed;
        bool status;
        bool wantToleave;
    }

    // Relacion de personas con una solicitud de renta
     mapping(bytes32 => Applicant[]) ApplicantsList;

    // este seria el contrato de arrendamiento 
    // y el numConfirmations la cantidad de confirmaciones necesarias para cancelarlo (eliminarlo)
    struct PropertyRented {
        address lessorAddress;
        uint256 numConfirmations; // Todos los inquilinos mas el propietario
        bytes32 propertyId;
        bool wantToleave;
        Applicant applicant;
    }
    PropertyRented[] propertyRentedList;

    mapping(bytes32 => mapping(address => PropertyRented)) LeasingContracts;

    // --------------------------- Eventos ---------------------------

    event NewPropertyAvailabe(string _propertyAddress, string _city, string _country, uint _monthlyRent, bytes32 id);
    event NewapplyForRenta(string _propertyAddress, string _city, string _country, uint _monthlyRent, bytes32 id);


    // --------------------------- Modificadores ---------------------------

    // Se asegura que no se repitan las misamas propiedades
    modifier noRepeatProperty(string memory _propertyAddress, string memory _city, string memory _country) {
        bool isEqual = false;
        for(uint i=0; i<propertiesList.length; i++) {
            if(keccak256(abi.encodePacked(propertiesList[i].propertyAddress))== keccak256(abi.encodePacked(_propertyAddress))  
            && keccak256(abi.encodePacked(propertiesList[i].city)) == keccak256(abi.encodePacked(_city))
            && keccak256(abi.encodePacked(propertiesList[i].country))  == keccak256(abi.encodePacked(_country)) 
            ){
                isEqual = true;
            }
        }
        require (isEqual == false, "property al ready exist");
        _;
    }

    // Se asegura que la propiedad este disponible
    modifier isAvailableProperty(bytes32 _propertyId) {
        bool isRented = false;
        for(uint i=0; i<propertiesList.length; i++) {
            if(propertiesList[i].id == _propertyId && propertiesList[i].available) {
                isRented = true;
            }
        }
        require(isRented == true, "Property is not available");
        _;
    }

    // Se asegura que sea mi propiedad
    modifier isMyProperty(bytes32 _propertyId) {
        bool isMy = false;
         for(uint i=0; i<propertiesList.length; i++) {
             if( propertiesList[i].id == _propertyId &&  propertiesList[i].ownerAddres == msg.sender) {
                 isMy = true;
             }
         }
        require(isMy, "It is not your property");
        _;
    }

     // --------------------------- Funciones ---------------------------

    // Regresa la lista de propiedades
    function returnPropertiesList() public view returns(Property[] memory) {
        return propertiesList;
    }

    // Agrega una nueva propiedad
    function submitPropertyToList(string memory _propertyAddress, string memory _city, string memory _country, uint256 _monthlyRent) 
    public 
    noRepeatProperty(_propertyAddress,  _city, _country) 
    {
        bytes32 id = keccak256(abi.encodePacked(_propertyAddress, _city, _country));
        Property memory newProperty = Property(id, msg.sender, _propertyAddress, _city, _country, _monthlyRent, true);
        propertiesList.push(newProperty);
        PropertyOwners[msg.sender].push(newProperty);
        emit NewPropertyAvailabe(_propertyAddress, _city, _country, _monthlyRent, id);
    }

    // Funcion para ver la lista de mis propiedades
    function myProperties() public view returns (Property[] memory) {
        return PropertyOwners[msg.sender];
    }

    // Se agrega un aplicante a la lisa de aplicantes para una renta
    function applyForRentalProperty(bytes32 _propertyId, string memory _name, uint _amountContributed) 
    public 
    isAvailableProperty(_propertyId)
    {
        ApplicantsList[_propertyId].push(Applicant(msg.sender, _name, _amountContributed, false, false));
    }

    // Regresa la lista de aplicantes para mi propiedad
    function obtainApliesForMyProperty(bytes32 _propertyId) public view isMyProperty(_propertyId) returns(Applicant[] memory)  {
        return ApplicantsList[_propertyId];
    }

    // Aprueba un aplicante a la propiedad (solo el propietario de la propiedad puede aprovar)
    // Y llama a un metodo que si el costo de renta y la suma del aporte de cada participante es igual se celebra el contrato
    function approveApplicantForMyProperty(bytes32 _propertyId, address _add) public isMyProperty(_propertyId) {
        for(uint i=0; i<ApplicantsList[_propertyId].length; i++) {
            if(ApplicantsList[_propertyId][i].add == _add) {
                ApplicantsList[_propertyId][i].status = true;
            }
        }

        uint256 monthlyRent;
         for(uint i=0; i<PropertyOwners[msg.sender].length; i++) {
             if(PropertyOwners[msg.sender][i].id == _propertyId) {
                 monthlyRent = PropertyOwners[msg.sender][i].monthlyRent;
             }
         }
        

        // LLamado a metodo para verificar el costo de renta es igual al aportado y cambia el estado de la propiedad
        if(checkIfCostIsTheRent(ApplicantsList[_propertyId], monthlyRent) &&  changePropertyToNotAvailable(_propertyId)) {
            //LLamado a celebrar el contrato
            setPropertyRented(_propertyId);
            // Se elimina el registro del mapping de applies
            delete ApplicantsList[_propertyId];
        }

    }

    // Funcion que un struct (PropertyRented) que es el contrato de arrendamiento
    function setPropertyRented(bytes32 _propertyId) internal  {
       
        for(uint i=0; i<ApplicantsList[_propertyId].length; i++) {
            LeasingContracts[_propertyId][ApplicantsList[_propertyId][i].add] = PropertyRented(msg.sender, ApplicantsList[_propertyId].length+1, _propertyId, false, ApplicantsList[_propertyId][i]);
            ApplicantsList[_propertyId][i];
            propertyRentedList.push(PropertyRented(msg.sender, ApplicantsList[_propertyId].length+1, _propertyId, false, ApplicantsList[_propertyId][i]));
        }


    }

    // Funcion que revisa si el costo de renta y la suma de todos los participantes
    function checkIfCostIsTheRent(Applicant[] memory _applicants, uint256 _monthlyRent) pure internal returns(bool) {
        uint256 ammount;
        bool flag = true;
        for(uint i=0; i<_applicants.length; i++) {
            ammount += _applicants[i].amountContributed;
            if(!_applicants[i].status) {
                flag = false;
            }
        }
        // if(flag == false) {
        //     return false;
        // }else 
        if(_monthlyRent > ammount || !flag) {
            return false;
        } else  {
            // TODO: Incrementar el costo de la renta si es mayor
            return true;
        } 
        // else if(_monthlyRent == ammount) {
        //     return true;
    }

    // Eliminar un registro en el mapping ApplicantsList para
    function deleteApplicantList(bytes32 _propertyId) internal isMyProperty(_propertyId) returns(bool) {
        delete ApplicantsList[_propertyId];
        return true;
    }

    // Cambiar el estado (availabel) de una propiedad a true
    function changePropertyToAvailable(bytes32 _propertyId) internal isMyProperty(_propertyId) returns(bool) {
        for(uint i=0; i<PropertyOwners[msg.sender].length; i++){
            if(PropertyOwners[msg.sender][i].id == _propertyId) {
                PropertyOwners[msg.sender][i].available = true;
            }
        }
         for(uint i=0; i<propertiesList.length; i++) {
             if(propertiesList[i].id == _propertyId) {
                propertiesList[i].available = true;
             }
         }
         return true;
    }
    // Cambiar el estado (availabel) de una propiedad a false
    function changePropertyToNotAvailable(bytes32 _propertyId) internal isMyProperty(_propertyId) returns(bool) {
        for(uint i=0; i<PropertyOwners[msg.sender].length; i++){
            if(PropertyOwners[msg.sender][i].id == _propertyId) {
                PropertyOwners[msg.sender][i].available = false;
            }
        }
         for(uint i=0; i<propertiesList.length; i++) {
             if(propertiesList[i].id == _propertyId) {
                propertiesList[i].available = false;
             }
         }
         return true;
    }

    // ---------------------------     Para multi-firma     ---------------------------

    event NewSubmitForLeave(bytes32 _propertyId, address _addres);

    // Se asegura que el usuario quien llama esté en el la lista del contrato y que no pueda llamar mas de una vez
    modifier onlyLessorOrLeassingAndDontTwoTime(bytes32 _propertyId) {
        bool tmp = false;
        for(uint i=0; i<propertyRentedList.length; i++) {
           
            if(propertyRentedList[i].propertyId == _propertyId && propertyRentedList[i].lessorAddress == msg.sender && !propertyRentedList[i].wantToleave) {
                tmp = true;
                break;
            }else if(propertyRentedList[i].propertyId == _propertyId && propertyRentedList[i].applicant.add == msg.sender && !propertyRentedList[i].applicant.wantToleave) {
                tmp = true;
                break;
            }
        }
        require(tmp);
        _;
    }

    // Se asegura que sean participantes del contrato
    modifier onlyLessorOrLeassing(bytes32 _propertyId) {
        bool tmp = false;
        for(uint i=0; i<propertyRentedList.length; i++) {
           
            if(propertyRentedList[i].propertyId == _propertyId && propertyRentedList[i].lessorAddress == msg.sender) {
                tmp = true;
                break;
            }else if(propertyRentedList[i].propertyId == _propertyId && propertyRentedList[i].applicant.add == msg.sender) {
                tmp = true;
                break;
            }
        }
        require(tmp, "Only lessor or leassing");
        _;
    }

    // Verifica si todos los participantes quieren dejar la propiedad
    modifier allWantedLeave(bytes32 _propertyId) {
        bool tmp = false;
       
        uint256 count = 0;
        uint256 _numConfirmations;
        for(uint i=0; i<propertyRentedList.length; i++) {
            if(propertyRentedList[i].propertyId == _propertyId) {
                _numConfirmations = propertyRentedList[i].numConfirmations;
                break;
            } 
        }
        for(uint i=0; i<propertyRentedList.length; i++) {
             if(propertyRentedList[i].propertyId == _propertyId && propertyRentedList[i].wantToleave) {
                count = count + 1;
            }else if(propertyRentedList[i].propertyId == _propertyId && propertyRentedList[i].applicant.wantToleave) {
                count = count + 1;
            }
        }

        require(count >= _numConfirmations-1, "No all wanted leave");
        _;
    }

    // Cambia el estado de wantToleave para notificar que quieren dejar la propiedad
    function submitDeleteLeasingContracts(bytes32 _propertyId) public onlyLessorOrLeassingAndDontTwoTime(_propertyId) {
        for(uint i=0; i<propertyRentedList.length; i++) {
            if(propertyRentedList[i].lessorAddress == msg.sender) {
                propertyRentedList[i].wantToleave = true;
                emit NewSubmitForLeave(propertyRentedList[i].propertyId, msg.sender);
            } else if(propertyRentedList[i].applicant.add == msg.sender) {
                propertyRentedList[i].applicant.wantToleave = true;
                emit NewSubmitForLeave(propertyRentedList[i].propertyId, msg.sender);
            }
        }


    }

    // Elimina el contrato de arrendamiento si todos los participantes estan de acuerdo
    function deleteLeasingContract(bytes32 _propertyId) public allWantedLeave(_propertyId) onlyLessorOrLeassing(_propertyId) {
         for(uint i=0; i<propertyRentedList.length; i++) {
             if(propertyRentedList[i].propertyId == _propertyId) {
                delete propertyRentedList[i];
                delete LeasingContracts[_propertyId][propertyRentedList[i].applicant.add];
             }
            
         }
         
         changePropertyToAvailable(_propertyId);
    }

    function returnsPropertyRented() public view returns(PropertyRented[] memory) {
        return propertyRentedList;
    }

    // Retorna mi contrto de arrendamiento
    function returnMyLeasingContract(bytes32 _propertyId) public view onlyLessorOrLeassing(_propertyId) returns(address, uint256, bool, uint256)  {
        address _add;
        uint256 _numConfirmations; 
        uint256 _lesasingWantLeave =0; 
        bool _wantToleave;
        for(uint i=0; i<propertyRentedList.length; i++) {
            
            if(propertyRentedList[i].propertyId == _propertyId && propertyRentedList[i].lessorAddress == msg.sender) {
                _wantToleave = propertyRentedList[i].wantToleave;
                _add = propertyRentedList[i].lessorAddress;
                _numConfirmations = propertyRentedList[i].numConfirmations;
            } else if(propertyRentedList[i].propertyId == _propertyId && propertyRentedList[i].applicant.add == msg.sender) {
                _wantToleave = propertyRentedList[i].wantToleave;
                _add = propertyRentedList[i].lessorAddress;
                _numConfirmations = propertyRentedList[i].numConfirmations;
            }
        }
         for(uint i=0; i<propertyRentedList.length; i++) {
             if(propertyRentedList[i].applicant.wantToleave) {
             _lesasingWantLeave++;
             }
         }

        return (_add, _numConfirmations, _wantToleave, _lesasingWantLeave);
    }

}