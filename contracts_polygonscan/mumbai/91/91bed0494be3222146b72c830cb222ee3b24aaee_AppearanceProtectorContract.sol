/**
 *Submitted for verification at polygonscan.com on 2021-11-16
*/

// SPDX-License-Identifier: PlensyApp
pragma solidity >=0.4.22 <0.9.0;
contract AppearanceProtectorContract {
    address public AppearanceProtectoraddress;
    uint256 numapp; 
   mapping(uint256 => AppearanceProtector) AppearanceProtectors;
    struct AppearanceProtector {
        string AppNo;
        uint256 ContractDate;
        uint256 ContractEndDate;
        string ContractStatus;
        string price;
        string term; 
    }
 constructor() {
        AppearanceProtectoraddress = msg.sender;
    }

function CreateAppearanceProtector(
        string memory _AppNo,
        uint256 _ContractDate,
        uint256 _ContractEndDate,
         string memory _price,
        string memory  _term 
    ) public returns (string memory) {
        require(
           AppearanceProtectoraddress == msg.sender,
            "Not authorized to create new AppearanceProtector Contract."
        );
        uint256 TotalWind = 0;

        for (uint256 i = 0; i < numapp; i++) {
            if (
                keccak256(
                    abi.encodePacked(AppearanceProtectors[uint256(i)].AppNo)
                ) == keccak256(abi.encodePacked(_AppNo))
            ) {
                TotalWind = 1;
                break;
            }
        }
        require(TotalWind != 1, "WindshieldProtection Contract already exits");
        uint256 numappID = numapp++;

        AppearanceProtector storage r = AppearanceProtectors[numappID];
        r.AppNo = _AppNo;
        r.ContractDate = _ContractDate;
        r.ContractEndDate = _ContractEndDate;
        r.ContractStatus = "N";
         r.price = _price;
        r.term = _term;


       
        return ("AppearanceProtector Contract Created Successfully.");
    }
    
   
 function geAppearanceProtectorCreator() public view returns (address) {
        return AppearanceProtectoraddress;
    }

 function getAppearanceProtectorNum() public view returns (uint256) {
        return numapp;
    }

 function getAppearanceProtectorID(string memory _AppNo)
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
        for (i = 0; i < numapp; i++) {
            AppearanceProtector storage e = AppearanceProtectors[i];

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


 function UpdateAppearanceProtector(
        string memory _AppNo,
       
        uint256 _ContractDate,
        uint256 _ContractEndDate,
        
        //string memory _ContractStatus,
        string memory _price,
        string memory _term
    ) public returns (string memory) {
        require(
            AppearanceProtectoraddress == msg.sender,
            "Not authorized to AppearanceProtector Contract."
        );
        uint256 i = 0;
        for (i = 0; i < numapp; i++) {
            AppearanceProtector storage e = AppearanceProtectors[i];

            if (
                keccak256(abi.encodePacked(e.AppNo)) ==
                keccak256(abi.encodePacked(_AppNo))
            ) {
                e.ContractDate = _ContractDate;
                e.ContractEndDate = _ContractEndDate;
                e.ContractStatus = "N";
                e.price = _price;
                e.term = _term;
               

                return ("AppearanceProtector Contract Updated Successfully");
            }
        }
        return ("AppearanceProtector Contract Not Found");
    }
function CancelAppearanceProtector(
        string memory _AppNo,
       
       
        uint256 _ContractEndDate
        
       
      
    ) public returns (string memory) {
        require(
            AppearanceProtectoraddress == msg.sender,
            "Not authorized to Cancel AppearanceProtector Contract."
        );
        uint256 i = 0;
        for (i = 0; i < numapp; i++) {
            AppearanceProtector storage e = AppearanceProtectors[i];

            if (
                keccak256(abi.encodePacked(e.AppNo)) ==
                keccak256(abi.encodePacked(_AppNo))
            ) {
              
                e.ContractEndDate = _ContractEndDate;
                e.ContractStatus = "C";
             
               

                return ("AppearanceProtector Contract Cancelled Successfully");
            }
        }
        return ("AppearanceProtector Contract Not Found");
    }

}