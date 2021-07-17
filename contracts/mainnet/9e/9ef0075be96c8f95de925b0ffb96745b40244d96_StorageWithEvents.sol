/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

pragma solidity >=0.7.0 <0.9.0;

contract StorageWithEvents {

    uint256 number;
    string name;
    
    event NumberChanged (uint256 _old_number, uint256 _new_number);
    event NameChanged (string _old_name, string _new_name);

    function storeNumber (uint256 _number) public {
        emit NumberChanged (number, _number);
        number = _number;
    }
    
    function storeName (string memory _name) public {
        emit NameChanged (name, _name);
        name = _name;
    }

    function getNumber() public view returns (uint256) {
        return number;
    }
    
    function getName() public view returns (string memory) {
        return name;
    }
}