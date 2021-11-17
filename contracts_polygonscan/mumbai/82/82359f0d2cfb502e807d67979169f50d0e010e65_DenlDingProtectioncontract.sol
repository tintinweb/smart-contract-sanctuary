/**
 *Submitted for verification at polygonscan.com on 2021-11-16
*/

// SPDX-License-Identifier: PlensyApp
pragma solidity >=0.4.22 <0.9.0;

contract DenlDingProtectioncontract{
    address public DenlDingProtectionaddress;
    uint256 numDenl; 
   mapping(uint256 => DenlDingProtection) DenlDingProtections;
    struct DenlDingProtection {
        string AppNo;
        uint256 ContractDate;
        uint256 ContractEndDate;
        string ContractStatus;
        string price;
        string term; 
    }
 constructor() {
        DenlDingProtectionaddress = msg.sender;
    }

function CreateDenlDingProtectionContract(
        string memory _AppNo,
        uint256 _ContractDate,
        uint256 _ContractEndDate,
         string memory _price,
        string memory  _term 
    ) public returns (string memory) {
        require(
            DenlDingProtectionaddress == msg.sender,
            "Not authorized to create new DenlDingProtection Contract."
        );
        uint256 Totaltheft = 0;

        for (uint256 i = 0; i < numDenl; i++) {
            if (
                keccak256(
                    abi.encodePacked(DenlDingProtections[uint256(i)].AppNo)
                ) == keccak256(abi.encodePacked(_AppNo))
            ) {
                Totaltheft = 1;
                break;
            }
        }
        require(Totaltheft != 1, "DenlDingProtection Contract already exits");
        uint256 numTheftID = numDenl++;

        DenlDingProtection storage r = DenlDingProtections[numTheftID];
        r.AppNo = _AppNo;
        r.ContractDate = _ContractDate;
        r.ContractEndDate = _ContractEndDate;
        r.ContractStatus = "N";
         r.price = _price;
        r.term = _term;


       
        return ("DenlDingProtection Contract Created Successfully.");
    }
    
   
 function getDenlDingProtectionCreator() public view returns (address) {
        return DenlDingProtectionaddress;
    }

 function getDenlDingProtectionNum() public view returns (uint256) {
        return numDenl;
    }

 function getDenlDingProtectionID(string memory _AppNo)
        public
        view
        returns (
            string memory,
            uint256,
            uint256,
            string memory,
            string memory,
            string memory
        )
    {
        uint256 i;
        // require(PlensyLedgerCreator ==  msg.sender, "Not authorized to create new certificate.");
        for (i = 0; i < numDenl; i++) {
            DenlDingProtection storage e = DenlDingProtections[i];

            if (

                keccak256(abi.encodePacked(e.AppNo)) ==
                keccak256(abi.encodePacked(_AppNo))
            ) {
                return (
                    e.AppNo,
                    e.ContractDate,
                    e.ContractEndDate,
                    e.ContractStatus,
                    e.price,
                    e.term
                    
                );
            }
        }
        return ("Not Found", 0, 0, "Not Found", "Not Found", "Not Found");
    }


 function UpdateDenlDingProtection(
        string memory _AppNo,
       
        uint256 _ContractDate,
        uint256 _ContractEndDate,
        
        //string memory _ContractStatus,
        string memory _price,
        string memory _term
    ) public returns (string memory) {
        require(
            DenlDingProtectionaddress == msg.sender,
            "Not authorized to UpdateDenlDingProtectionaddress Contract."
        );
        uint256 i = 0;
        for (i = 0; i < numDenl; i++) {
            DenlDingProtection storage e = DenlDingProtections[i];

            if (
                keccak256(abi.encodePacked(e.AppNo)) ==
                keccak256(abi.encodePacked(_AppNo))
            ) {
                e.ContractDate = _ContractDate;
                e.ContractEndDate = _ContractEndDate;
                e.ContractStatus = "N";
                e.price = _price;
                e.term = _term;
               

                return ("DenlDingProtection Contract Updated Successfully");
            }
        }
        return ("DenlDingProtection Contract Not Found");
    }
function CancelDenlDingProtection(
        string memory _AppNo,
       
       
        uint256 _ContractEndDate
        
       
      
    ) public returns (string memory) {
        require(
            DenlDingProtectionaddress == msg.sender,
            "Not authorized to Cancel DenlDingProtection Contract."
        );
        uint256 i = 0;
        for (i = 0; i < numDenl; i++) {
            DenlDingProtection storage e = DenlDingProtections[i];

            if (
                keccak256(abi.encodePacked(e.AppNo)) ==
                keccak256(abi.encodePacked(_AppNo))
            ) {
              
                e.ContractEndDate = _ContractEndDate;
                e.ContractStatus = "C";
             
               

                return ("DenlDingProtection Contract Cancelled Successfully");
            }
        }
        return ("DenlDingProtection Contract Not Found");
    }

}