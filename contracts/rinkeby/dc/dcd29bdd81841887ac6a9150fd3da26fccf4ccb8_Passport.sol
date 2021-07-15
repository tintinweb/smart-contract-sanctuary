/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

pragma solidity >0.8.0;
contract Passport {
   struct Passport {
       string last_name;
       string first_name;
       string issuing_office;
       uint256 expiry_date;
       uint256 number;
       uint256 date;
   }
   mapping(bytes32 => Passport) public passport;
   event PassportGenerated(bytes32 _passportid);
   function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
                result := mload(add(source, 32))
        }
    }
   function generatePassport(
        string memory _id,
        string memory _last_name,
        string memory _first_name, 
        string memory _issuing_office, 
        uint256 _expiry_date, 
        uint256 _number,
        uint256 _date) public {
        bytes32 byte_id = stringToBytes32(_id);
        require(passport[byte_id].expiry_date == 0, "Passport with given id already exists");
        passport[byte_id] = Passport(_last_name, _first_name, _issuing_office, _expiry_date, _number, _date);
        emit PassportGenerated(byte_id);
    }
   
    function getData(string memory _id) public view returns(string memory, string memory, string memory, string memory,uint256,uint256,uint256) {
        bytes32 byte_id = stringToBytes32(_id);
        Passport memory temp = passport[byte_id];
        require(temp.expiry_date != 0, "No data exists");
    }
}