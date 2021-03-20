/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.2.;
// pragma abicoder v2;

contract DigitalID {
    
    
    /* -------------------- Utility functions : ---------------------- */

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {// (!) Gas requirement: infinite
        // require(bytes(source).length <= 32); // causes error, but string have to be max 32 chars

        // https://ethereum.stackexchange.com/questions/9603/understanding-mload-assembly-function
        // http://solidity.readthedocs.io/en/latest/assembly.html
        // this converts every char to its byte representation
        // see hex codes on http://www.asciitable.com/ (7 > 37, a > 61, z > 7a)
        // "az7" > 0x617a370000000000000000000000000000000000000000000000000000000000
        assembly {
            result := mload(add(source, 32))
        }
    }

    // see also:
    // https://ethereum.stackexchange.com/questions/2519/how-to-convert-a-bytes32-to-string
    // https://ethereum.stackexchange.com/questions/1081/how-to-concatenate-a-bytes32-array-to-a-string
    // 0x617a370000000000000000000000000000000000000000000000000000000000 > "az7"
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory){ // (!) Gas requirement: infinite
        // string memory str = string(_bytes32);
        // TypeError: Explicit type conversion not allowed from "bytes32" to "string storage pointer"
        // thus we should convert bytes32 to bytes (to dynamically-sized byte array)
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
    

    /* -------------------- Data : ---------------------- */


    struct PublicKeyCertificateStruct {
        string name; // first and last name 
        uint8 birthdaateYear;
        uint8 birthdaateMonth;
        uint8 birthdaateDay;
        string nationality;
        string nationalIdNumber;
        uint verificationAddedOn;
        uint revokedOn;
    }
    
    struct Verification {
        address verifiedBy; // 
        uint verifiedOn; // Unix time
        uint verificationRevocedOn; // Unix time
        
    }
    
    mapping (address => PublicKeyCertificateStruct) public PublicKeyCertificate;
    mapping(address => mapping(address=>Verification)) public Verifications;
    
    /* -------------------- functions : ---------------------- */
    
    function addPublicKeyCertificate (
        string memory name,
        uint8 birthdaateYear,
        uint8 birthdaateMonth,
        uint8 birthdaateDay,
        string memory nationality,
        string memory nationalIdNumber
        
        ) public returns (bool success) {
            
            PublicKeyCertificate[msg.sender].name = name;
            PublicKeyCertificate[msg.sender].birthdaateYear = birthdaateYear;
            PublicKeyCertificate[msg.sender].birthdaateMonth = birthdaateMonth;
            PublicKeyCertificate[msg.sender].birthdaateDay = birthdaateDay;
            PublicKeyCertificate[msg.sender].nationality = nationality;
            PublicKeyCertificate[msg.sender].nationalIdNumber = nationalIdNumber;
            
            return true;
            
        }
        
        function getPUblicKeyCertificate (address certificateAddress) public view returns (PublicKeyCertificateStruct memory) {
            return PublicKeyCertificate[certificateAddress];
        }
    
    
}